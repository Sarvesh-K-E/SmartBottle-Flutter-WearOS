import '../models/smart_bottle_reading.dart';

class ArduinoLineParser {
  static final RegExp _levelPattern = RegExp(
    r'level\s*:\s*([+-]?\d+(?:[.,]\d+)?)\s*%',
    caseSensitive: false,
  );
  static final RegExp _tempPattern = RegExp(
    r'temp\s*:\s*([+-]?\d+(?:[.,]\d+)?)\s*(?:\u00B0?\s*c)',
    caseSensitive: false,
  );
  static final RegExp _tdsPattern = RegExp(
    r'tds\s*:\s*([+-]?\d+(?:[.,]\d+)?)\s*ppm',
    caseSensitive: false,
  );

  static final RegExp _fallbackPattern = RegExp(
    r'([+-]?\d+(?:[.,]\d+)?)\s*%\s*\|\s*([+-]?\d+(?:[.,]\d+)?)\s*(?:\u00B0?\s*c)\s*\|\s*([+-]?\d+(?:[.,]\d+)?)\s*ppm',
    caseSensitive: false,
  );

  SmartBottleReading? tryParse(String rawLine) {
    final sanitized = rawLine.replaceAll(
      RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'),
      '',
    );
    final line = sanitized.trim();
    if (line.isEmpty) return null;

    int? level;
    double? temp;
    int? tds;

    final levelMatch = _levelPattern.firstMatch(line);
    final tempMatch = _tempPattern.firstMatch(line);
    final tdsMatch = _tdsPattern.firstMatch(line);

    if (levelMatch != null && tempMatch != null && tdsMatch != null) {
      level = _parseFlexibleDouble(levelMatch.group(1)!)?.round();
      temp = _parseFlexibleDouble(tempMatch.group(1)!);
      tds = _parseFlexibleDouble(tdsMatch.group(1)!)?.round();
    } else {
      final fallbackMatch = _fallbackPattern.firstMatch(line);
      if (fallbackMatch != null) {
        level = _parseFlexibleDouble(fallbackMatch.group(1)!)?.round();
        temp = _parseFlexibleDouble(fallbackMatch.group(2)!);
        tds = _parseFlexibleDouble(fallbackMatch.group(3)!)?.round();
      }
    }

    if (level == null || temp == null || tds == null) return null;
    if (level < 0 || level > 100 || temp < -50 || temp > 150 || tds < 0) {
      return null;
    }

    return SmartBottleReading(
      levelPercent: level,
      temperatureC: temp,
      tdsPpm: tds,
      timestamp: DateTime.now(),
    );
  }

  double? _parseFlexibleDouble(String input) {
    return double.tryParse(input.replaceAll(',', '.'));
  }
}

class BufferedLineSplitter {
  final StringBuffer _buffer = StringBuffer();
  static const int _maxBufferedChars = 4096;
  static final RegExp _packetPattern = RegExp(
    r'level\s*:\s*[+-]?\d+(?:[.,]\d+)?\s*%\s*\|\s*temp\s*:\s*[+-]?\d+(?:[.,]\d+)?\s*(?:\u00B0?\s*c)\s*\|\s*tds\s*:\s*[+-]?\d+(?:[.,]\d+)?\s*ppm',
    caseSensitive: false,
  );

  List<String> addChunk(String chunk) {
    if (chunk.isEmpty) return const [];
    _buffer.write(chunk);
    final text = _buffer.toString();
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final parts = normalized.split('\n');
    final extracted = <String>[];

    if (parts.length > 1) {
      for (final completePart in parts.take(parts.length - 1)) {
        _appendCompleteSegment(completePart, extracted);
      }
    }

    var remainder = parts.isEmpty ? normalized : parts.last;
    remainder = _consumeInlinePacketsFromRemainder(remainder, extracted);
    if (remainder.length > _maxBufferedChars) {
      remainder = remainder.substring(remainder.length - _maxBufferedChars);
    }

    _buffer
      ..clear()
      ..write(remainder);

    return extracted;
  }

  String? flushRemainder() {
    final remaining = _buffer.toString().trim();
    _buffer.clear();
    if (remaining.isEmpty) return null;
    return remaining;
  }

  void clear() {
    _buffer.clear();
  }

  void _appendCompleteSegment(String segment, List<String> output) {
    final normalized = segment.trim();
    if (normalized.isEmpty) return;

    final matches = _packetPattern.allMatches(normalized).toList();
    if (matches.isEmpty) {
      output.add(normalized);
      return;
    }

    for (final match in matches) {
      output.add(normalized.substring(match.start, match.end).trim());
    }
  }

  String _consumeInlinePacketsFromRemainder(
    String remainder,
    List<String> output,
  ) {
    if (remainder.trim().isEmpty) {
      return remainder;
    }

    final matches = _packetPattern.allMatches(remainder).toList();
    if (matches.isEmpty) {
      return remainder;
    }

    for (final match in matches) {
      output.add(remainder.substring(match.start, match.end).trim());
    }

    return remainder.substring(matches.last.end);
  }
}
