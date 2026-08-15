import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bottle_phone/models/smart_bottle_reading.dart';
import 'package:smart_bottle_phone/services/sync_window_aggregator.dart';

void main() {
  test('mode aggregation with median tie fallback', () async {
    final aggregator = SyncWindowAggregator(window: const Duration(seconds: 1));
    final results = <SmartBottleReading>[];
    final sub = aggregator.resultStream.listen(results.add);

    aggregator.start();
    aggregator.addReading(
      SmartBottleReading(
        levelPercent: 60,
        temperatureC: 26.4,
        tdsPpm: 240,
        timestamp: DateTime.now(),
      ),
    );
    aggregator.addReading(
      SmartBottleReading(
        levelPercent: 60,
        temperatureC: 26.4,
        tdsPpm: 240,
        timestamp: DateTime.now(),
      ),
    );
    aggregator.addReading(
      SmartBottleReading(
        levelPercent: 58,
        temperatureC: 26.5,
        tdsPpm: 260,
        timestamp: DateTime.now(),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1300));

    expect(results, isNotEmpty);
    expect(results.first.levelPercent, 60);
    expect(results.first.tdsPpm, 240);

    await sub.cancel();
    await aggregator.dispose();
  });
}
