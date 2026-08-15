import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bottle_phone/services/arduino_line_parser.dart';

void main() {
  group('ArduinoLineParser', () {
    final parser = ArduinoLineParser();

    test('parses valid smart bottle line', () {
      final result = parser.tryParse('Level: 63% | Temp: 26.4C | TDS: 245 ppm');
      expect(result, isNotNull);
      expect(result!.levelPercent, 63);
      expect(result.temperatureC, 26.4);
      expect(result.tdsPpm, 245);
    });

    test('parses with extra spaces', () {
      final result = parser.tryParse(
        '  Level:   40%   | Temp: 25.9C | TDS: 230 ppm  ',
      );
      expect(result, isNotNull);
      expect(result!.levelPercent, 40);
      expect(result.temperatureC, 25.9);
      expect(result.tdsPpm, 230);
    });

    test('parses with degree symbol and comma decimals', () {
      final result = parser.tryParse(
        'Level: 100% | Temp: 26,4 \u00B0C | TDS: 245 ppm',
      );
      expect(result, isNotNull);
      expect(result!.levelPercent, 100);
      expect(result.temperatureC, 26.4);
      expect(result.tdsPpm, 245);
    });

    test('rejects malformed line', () {
      final result = parser.tryParse('Temp=25.9, level=40, tds=230');
      expect(result, isNull);
    });
  });

  group('BufferedLineSplitter', () {
    test('handles chunked lines safely', () {
      final splitter = BufferedLineSplitter();
      final first = splitter.addChunk('Level: 63% | Temp: 26.4C | TD');
      expect(first, isEmpty);

      final second = splitter.addChunk(
        'S: 245 ppm\nLevel: 40% | Temp: 25.9C | TDS: 230 ppm\n',
      );
      expect(second.length, 2);
      expect(second.first, 'Level: 63% | Temp: 26.4C | TDS: 245 ppm');
      expect(second.last, 'Level: 40% | Temp: 25.9C | TDS: 230 ppm');
    });

    test('extracts multiple packets even without newlines', () {
      final splitter = BufferedLineSplitter();
      final lines = splitter.addChunk(
        'Level: 80% | Temp: 27.1C | TDS: 260 ppmLevel: 79% | Temp: 27.0C | TDS: 258 ppm',
      );
      expect(lines.length, 2);
      expect(lines.first, 'Level: 80% | Temp: 27.1C | TDS: 260 ppm');
      expect(lines.last, 'Level: 79% | Temp: 27.0C | TDS: 258 ppm');
    });
  });
}
