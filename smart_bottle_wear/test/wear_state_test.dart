import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bottle_wear/models/wear_sync_state.dart';

void main() {
  test('wear state computes liters and progress', () {
    final state = WearSyncState.initial().copyWith(
      levelPercent: 50,
      todayDrankLiters: 1.0,
      goalLiters: 2.0,
    );
    expect(state.levelLiters, 1.0);
    expect(state.goalProgress, 0.5);
  });
}
