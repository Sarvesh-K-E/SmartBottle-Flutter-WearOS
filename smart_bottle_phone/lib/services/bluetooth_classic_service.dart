import 'dart:async';
import 'dart:convert';

import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

import '../models/app_connection_status.dart';
import '../models/smart_bottle_reading.dart';
import 'arduino_line_parser.dart';

class BluetoothClassicService {
  BluetoothClassicService({
    ArduinoLineParser? lineParser,
    BufferedLineSplitter? lineSplitter,
  }) : _lineParser = lineParser ?? ArduinoLineParser(),
       _lineSplitter = lineSplitter ?? BufferedLineSplitter();

  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();
  final ArduinoLineParser _lineParser;
  final BufferedLineSplitter _lineSplitter;

  final _connectionController =
      StreamController<AppConnectionStatus>.broadcast();
  final _readingController = StreamController<SmartBottleReading>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<AppConnectionStatus> get connectionStream =>
      _connectionController.stream;
  Stream<SmartBottleReading> get readingStream => _readingController.stream;
  Stream<String> get errorStream => _errorController.stream;

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<BluetoothData>? _dataSub;
  Timer? _reconnectTimer;
  Timer? _healthTimer;
  static const Duration _noDataTimeoutBeforeFirstPacket = Duration(seconds: 40);
  static const Duration _noDataTimeoutAfterPackets = Duration(seconds: 35);

  String? _targetAddress;
  bool _disposed = false;
  bool _manualDisconnect = false;
  bool _isConnected = false;
  bool _hasSeenValidReadingSinceConnect = false;
  bool _isReconnectInProgress = false;
  DateTime? _lastValidReadingAt;
  DateTime? _lastDataChunkAt;
  DateTime? _connectedSince;
  AppConnectionStatus? _lastEmittedStatus;

  String? get currentTargetAddress => _targetAddress;

  Future<bool> isBluetoothEnabled() => _bluetooth.isBluetoothEnabled();

  Future<void> setupListeners() async {
    _connectionSub?.cancel();
    _dataSub?.cancel();
    _healthTimer?.cancel();

    _connectionSub = _bluetooth.onConnectionChanged.listen(
      (event) {
        if (_disposed) return;
        if (event.isConnected) {
          _isConnected = true;
          _connectedSince ??= DateTime.now();
          if (_hasSeenValidReadingSinceConnect) {
            _emitStatus(AppConnectionStatus.connected);
          } else {
            _emitStatus(AppConnectionStatus.connecting);
          }
        } else {
          _isConnected = false;
          _hasSeenValidReadingSinceConnect = false;
          _connectedSince = null;
          _lastDataChunkAt = null;
          _lastValidReadingAt = null;
          _lineSplitter.clear();
          _emitStatus(AppConnectionStatus.disconnected);
          if (!_manualDisconnect) {
            _scheduleReconnect();
          }
        }
      },
      onError: (Object error) {
        _errorController.add('Connection stream error: $error');
        _emitStatus(AppConnectionStatus.error);
      },
    );

    _dataSub = _bluetooth.onDataReceived.listen(
      (event) {
        final chunk = _decodeChunk(event.data);
        if (chunk.isNotEmpty) {
          _lastDataChunkAt = DateTime.now();
        }
        final lines = _lineSplitter.addChunk(chunk);
        for (final line in lines) {
          final reading = _lineParser.tryParse(line);
          if (reading != null) {
            _lastValidReadingAt = DateTime.now();
            if (_isConnected && !_hasSeenValidReadingSinceConnect) {
              _hasSeenValidReadingSinceConnect = true;
              _emitStatus(AppConnectionStatus.connected);
            }
            _readingController.add(reading);
          }
        }
      },
      onError: (Object error) {
        _errorController.add('Data stream error: $error');
      },
    );

    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _runConnectionHealthCheck();
    });
  }

  String _decodeChunk(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return _bluetooth.getPairedDevices();
  }

  Future<bool> enableBluetooth() => _bluetooth.enableBluetooth();

  Future<bool> connect(String address) async {
    _manualDisconnect = false;
    _targetAddress = address;
    _isConnected = false;
    _hasSeenValidReadingSinceConnect = false;
    _lastDataChunkAt = null;
    _lastValidReadingAt = null;
    _connectedSince = DateTime.now();
    _lineSplitter.clear();
    _reconnectTimer?.cancel();
    _emitStatus(AppConnectionStatus.connecting);
    try {
      final ok = await _bluetooth.connect(address);
      if (ok) {
        _isConnected = true;
        _emitStatus(AppConnectionStatus.connecting);
      } else {
        _isConnected = false;
        _emitStatus(AppConnectionStatus.disconnected);
      }
      return ok;
    } catch (e) {
      _emitStatus(AppConnectionStatus.error);
      _errorController.add('Failed to connect: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _isConnected = false;
    _hasSeenValidReadingSinceConnect = false;
    _lastDataChunkAt = null;
    _lastValidReadingAt = null;
    _connectedSince = null;
    _targetAddress = null;
    _reconnectTimer?.cancel();
    _lineSplitter.clear();
    await _bluetooth.disconnect();
    _emitStatus(AppConnectionStatus.disconnected);
  }

  void _scheduleReconnect() {
    final address = _targetAddress;
    if (address == null || _manualDisconnect || _isReconnectInProgress) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () async {
      if (_disposed || _targetAddress == null || _manualDisconnect) return;
      if (_isReconnectInProgress) return;
      _isReconnectInProgress = true;
      _emitStatus(AppConnectionStatus.reconnecting);
      try {
        _lineSplitter.clear();
        final ok = await _bluetooth.connect(address);
        _isConnected = ok;
        _hasSeenValidReadingSinceConnect = false;
        _lastDataChunkAt = null;
        _connectedSince = ok ? DateTime.now() : null;
        _lastValidReadingAt = null;
        _emitStatus(
          ok
              ? AppConnectionStatus.connecting
              : AppConnectionStatus.disconnected,
        );
        if (!ok) {
          _scheduleReconnect();
        }
      } catch (e) {
        _errorController.add('Reconnect failed: $e');
        _emitStatus(AppConnectionStatus.error);
        _scheduleReconnect();
      } finally {
        _isReconnectInProgress = false;
      }
    });
  }

  Future<void> _runConnectionHealthCheck() async {
    if (_disposed ||
        _targetAddress == null ||
        !_isConnected ||
        _manualDisconnect) {
      return;
    }

    final now = DateTime.now();
    final staleSince =
        _lastDataChunkAt ?? _lastValidReadingAt ?? _connectedSince;
    if (staleSince == null) return;

    if (_lastDataChunkAt == null &&
        now.difference(staleSince) < _noDataTimeoutBeforeFirstPacket) {
      return;
    }
    if (_lastDataChunkAt != null &&
        now.difference(staleSince) < _noDataTimeoutAfterPackets) {
      return;
    }

    if (_isReconnectInProgress) return;
    _isReconnectInProgress = true;
    _emitStatus(AppConnectionStatus.reconnecting);
    _errorController.add(
      'No incoming HC-05 bytes for a while. Reconnecting...',
    );

    try {
      await _bluetooth.disconnect();
    } catch (_) {
      // Ignore disconnect failure before reconnect.
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final address = _targetAddress;
    if (address == null || _manualDisconnect) {
      _isReconnectInProgress = false;
      return;
    }

    try {
      final ok = await _bluetooth.connect(address);
      _isConnected = ok;
      _hasSeenValidReadingSinceConnect = false;
      _lastDataChunkAt = null;
      _connectedSince = ok ? DateTime.now() : null;
      _lastValidReadingAt = null;
      _emitStatus(
        ok ? AppConnectionStatus.connecting : AppConnectionStatus.disconnected,
      );
      if (!ok) {
        _scheduleReconnect();
      }
    } catch (e) {
      _isConnected = false;
      _errorController.add('Health-check reconnect failed: $e');
      _emitStatus(AppConnectionStatus.error);
      _scheduleReconnect();
    } finally {
      _isReconnectInProgress = false;
    }
  }

  void _emitStatus(AppConnectionStatus status) {
    if (_lastEmittedStatus == status) {
      return;
    }
    _lastEmittedStatus = status;
    _connectionController.add(status);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _healthTimer?.cancel();
    await _connectionSub?.cancel();
    await _dataSub?.cancel();
    await _bluetooth.disconnect();

    final remainder = _lineSplitter.flushRemainder();
    if (remainder != null) {
      final parsed = _lineParser.tryParse(remainder);
      if (parsed != null) {
        _readingController.add(parsed);
      }
    }

    await _connectionController.close();
    await _readingController.close();
    await _errorController.close();
  }
}
