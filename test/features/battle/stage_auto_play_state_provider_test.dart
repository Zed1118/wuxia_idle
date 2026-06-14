import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/battle/application/stage_auto_play_pref.dart';

/// 战斗交互重做 Phase 3:选关屏 per-stage override 的 family provider
/// (SharedPreferences-backed)。验证三态读 + setOverride + invalidate 刷新。
void main() {
  late ProviderContainer container;
  late StageAutoPlayPrefService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = StageAutoPlayPrefService();
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  const key = 'stage#stage_01_01#1';

  test('无 override → null(随全局)', () async {
    final v = await container.read(stageAutoPlayOverrideProvider(key).future);
    expect(v, isNull);
  });

  test('setOverride(false) + invalidate → false(允许拖招)', () async {
    await container.read(stageAutoPlayOverrideProvider(key).future);
    await service.setOverride(key, false);
    container.invalidate(stageAutoPlayOverrideProvider(key));
    final v = await container.read(stageAutoPlayOverrideProvider(key).future);
    expect(v, isFalse);
  });

  test('setOverride(true) → true(纯挂机自动)', () async {
    await service.setOverride(key, true);
    container.invalidate(stageAutoPlayOverrideProvider(key));
    final v = await container.read(stageAutoPlayOverrideProvider(key).future);
    expect(v, isTrue);
  });

  test('setOverride(null) 清除 → 回到 null(随全局)', () async {
    await service.setOverride(key, false);
    await service.setOverride(key, null);
    container.invalidate(stageAutoPlayOverrideProvider(key));
    final v = await container.read(stageAutoPlayOverrideProvider(key).future);
    expect(v, isNull);
  });

  test('不同 battleKey 互不影响', () async {
    await service.setOverride(key, true);
    final other =
        await container.read(stageAutoPlayOverrideProvider('tower#5#1').future);
    expect(other, isNull);
  });
}
