import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen_config.dart';

void main() {
  test(
    'default playback config preserves the current BattleScreen behavior',
    () {
      const config = BattleScreenPlaybackConfig();

      expect(config.autoStart, isTrue);
      expect(config.allowPlayerIntervention, isFalse);
      expect(config.startPaused, isFalse);
      expect(config.startFastForward, isFalse);
      expect(config.readablePacing, isFalse);
      expect(config.autoStartOnMount, isFalse);
    },
  );

  test('sweep preset starts fast-forward playback for a preloaded battle', () {
    const config = BattleScreenPlaybackConfig.sweep();

    expect(config.autoStart, isTrue);
    expect(config.allowPlayerIntervention, isFalse);
    expect(config.startPaused, isFalse);
    expect(config.startFastForward, isTrue);
    expect(config.readablePacing, isFalse);
    expect(config.autoStartOnMount, isTrue);
  });
}
