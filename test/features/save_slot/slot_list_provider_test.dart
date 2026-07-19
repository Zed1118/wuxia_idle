import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/save_slot/application/slot_list_provider.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `slotListProvider` 行为测（2026-07-19 夜批 coverage 补强，基线 0/2 行）。
///
/// 真 Isar 多槽目录 + 真 ProviderContainer 读 provider（生产入口 =
/// 存档选择屏 watch 本 provider；invalidate 触发 `IsarSetup.listSlots()` 重读），
/// 钉两条行为语义：
///   - 全新目录 → 3 槽摘要全 empty（provider 直通 listSlots 无自有过滤）
///   - slot1 开派建档 → 槽1 非空且 isMostRecent；renameSlot 后 invalidate
///     重读反映新档名（选择屏「新开/删除后刷新」路径）
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_slot_list_provider_',
    );
  });

  tearDown(() async {
    for (final n in [1, 2, 3]) {
      final inst = Isar.getInstance('wuxia_save_slot$n');
      if (inst != null) await inst.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('全新目录：3 槽摘要全 empty', () async {
    await IsarSetup.init(slotId: 1, directory: tempDir, inspector: false);
    final container = makeContainer();

    final slots = await container.read(slotListProvider.future);

    expect(slots.length, 3);
    expect(slots.map((s) => s.slotId), [1, 2, 3]);
    expect(
      slots.every((s) => s.isEmpty),
      isTrue,
      reason: '未 onboarding 的新目录无任何建档',
    );
  });

  test('开派建档后槽1非空且 isMostRecent；invalidate 重读反映改名', () async {
    await IsarSetup.init(slotId: 1, directory: tempDir, inspector: false);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    final container = makeContainer();
    // 持订阅保活（autoDispose），随后 invalidate 才走「重读」而非「重建」。
    final sub = container.listen(slotListProvider.future, (_, _) {});
    addTearDown(sub.close);

    var slots = await container.read(slotListProvider.future);
    expect(slots[0].isEmpty, isFalse, reason: 'slot1 已有祖师建档');
    expect(slots[0].founderName, isNotNull);
    expect(slots[0].isMostRecent, isTrue, reason: '唯一有档槽恒为最近');
    expect(slots[1].isEmpty, isTrue);
    expect(slots[2].isEmpty, isTrue);

    await IsarSetup.renameSlot(1, '夜雨档', directory: tempDir);
    container.invalidate(slotListProvider);
    slots = await container.read(slotListProvider.future);
    expect(slots[0].slotName, '夜雨档', reason: 'invalidate 后重读 listSlots');
  });
}
