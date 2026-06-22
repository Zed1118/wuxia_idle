import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

void main() {
  test('非关键帧 → 用 profile hitStop', () {
    expect(playbackHoldMs(isKey: false, profileHitStopMs: 120, keyMomentHoldMs: 400), 120);
  });
  test('关键帧 → 取 profile 与 keyMomentHold 的大者', () {
    expect(playbackHoldMs(isKey: true, profileHitStopMs: 120, keyMomentHoldMs: 400), 400);
    expect(playbackHoldMs(isKey: true, profileHitStopMs: 500, keyMomentHoldMs: 400), 500);
  });
}
