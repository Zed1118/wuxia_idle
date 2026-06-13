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

    expect((await svc.load()).autoPlayDefault, isTrue,
        reason: '用户拍板#3:已通关默认走自动战斗');

    await svc.save(const GameplaySettings(autoPlayDefault: false));
    expect((await svc.load()).autoPlayDefault, isFalse,
        reason: '关闭后持久化读回');
  });
}
