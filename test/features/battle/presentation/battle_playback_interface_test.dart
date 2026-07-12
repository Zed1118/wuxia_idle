import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BattleScreen 只消费播放视图与状态，不读取动画资源', () async {
    final source = await File(
      'lib/features/battle/presentation/battle_screen.dart',
    ).readAsString();

    for (final forbidden in const [
      '.attackControllers',
      '.hitFlashControllers',
      '.hitFlashColors',
      '.activeTrails',
      '.activeEffects',
      '.popups',
      '.closeupCtrl',
      '.shakeCtrl',
      '.screenFlashKey',
      '.ultimateCaptionKey',
      '.impactGlyphKey',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }

    expect(source, contains('BattlePlaybackMotion('));
    expect(source, contains('BattlePlaybackField('));
    expect(source, contains('BattlePlaybackOverlays('));
  });
}
