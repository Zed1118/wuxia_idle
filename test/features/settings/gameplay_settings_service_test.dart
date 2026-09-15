import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_service.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';

/// 半手动战斗 P0 步骤5-B:全局玩法设置(自动战斗总开关)。
///
/// 设置≠存档(与 Isar 隔离,走 SharedPreferences,沿 AudioSettingsService 体例)。
/// 已通关关卡是否默认自动战斗的全局默认值,用户拍板#3 默认 true。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('默认 autoPlayDefault=true; save→load 往返', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = GameplaySettingsService();

    expect(
      (await svc.load()).autoPlayDefault,
      isTrue,
      reason: '用户拍板#3:已通关默认走自动战斗',
    );

    await svc.save(
      const GameplaySettings(
        autoPlayDefault: false,
        battlePlaybackSpeed: BattlePlaybackSpeed.brisk,
        textDensity: TextDensityPreference.compact,
        reduceFlashing: true,
        reduceEffects: true,
        showBackgroundCrowds: false,
      ),
    );
    final read = await svc.load();
    expect(read.autoPlayDefault, isFalse, reason: '关闭后持久化读回');
    expect(read.battlePlaybackSpeed, BattlePlaybackSpeed.brisk);
    expect(read.textDensity, TextDensityPreference.compact);
    expect(read.reduceFlashing, isTrue);
    expect(read.reduceEffects, isTrue);
    expect(read.showBackgroundCrowds, isFalse);
    await svc.save(read.copyWith(reduceFlashing: false));
    final updated = await svc.load();
    expect(updated.reduceEffects, isTrue);
    expect(updated.showBackgroundCrowds, isFalse);
  });

  test('新增舒适性选项默认值保持现状', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await GameplaySettingsService().load();

    expect(s.battlePlaybackSpeed, BattlePlaybackSpeed.normal);
    expect(s.textDensity, TextDensityPreference.standard);
    expect(s.reduceFlashing, isFalse);
    expect(s.reduceEffects, isFalse);
    expect(s.showBackgroundCrowds, isTrue);
    expect(s.scaledBattleIntervalMs(1000), 1000);
  });

  test('旧偏好缺少背景人群键时显示；开关往返保留其他偏好', () async {
    SharedPreferences.setMockInitialValues({
      'gameplay.autoPlayDefault': false,
      'gameplay.battlePlaybackSpeed': 'brisk',
      'gameplay.textDensity': 'compact',
      'gameplay.reduceFlashing': true,
      'gameplay.reduceEffects': true,
    });
    expect(const GameplaySettings().showBackgroundCrowds, isTrue);
    final service = GameplaySettingsService();
    final legacy = await service.load();
    expect(legacy.showBackgroundCrowds, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('gameplay.showBackgroundCrowds'), isFalse);

    for (final show in [false, true]) {
      final changed = legacy.copyWith(showBackgroundCrowds: show);
      expect(legacy.showBackgroundCrowds, isTrue);
      expect(changed.copyWith().showBackgroundCrowds, show);
      await service.save(changed);
      final restored = await GameplaySettingsService().load();
      expect(restored.showBackgroundCrowds, show);
      expect(prefs.getBool('gameplay.showBackgroundCrowds'), show);
      expect(restored.autoPlayDefault, isFalse);
      expect(restored.battlePlaybackSpeed, BattlePlaybackSpeed.brisk);
      expect(restored.textDensity, TextDensityPreference.compact);
      expect(restored.reduceFlashing, isTrue);
      expect(restored.reduceEffects, isTrue);
    }
  });
}
