import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

/// 多存档槽(spec B §3.1/§5):IsarSetup switchSlot / slotHasSave / listSlots /
/// deleteSlot 隔离与生命周期。多 db 方案 → 切 db = 切全部数据,无串档。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_slots_test_');
  });

  tearDown(() async {
    for (final n in [1, 2, 3]) {
      final inst = Isar.getInstance('wuxia_save_slot$n');
      if (inst != null) await inst.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('switchSlot 隔离:slot1 写 → slot2 全新 → slot1 不受影响', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    expect(IsarSetup.currentSlotId, 1);
    final s1Count =
        (await IsarSetup.instance.characters.where().findAll()).length;
    expect(s1Count, greaterThan(0), reason: 'slot1 已 onboard 有祖师');

    await IsarSetup.switchSlot(2, directory: tempDir);
    expect(IsarSetup.currentSlotId, 2);
    final s2Count =
        (await IsarSetup.instance.characters.where().findAll()).length;
    expect(s2Count, 0, reason: 'slot2 是独立新 db,未 onboard');

    await IsarSetup.switchSlot(1, directory: tempDir);
    expect(IsarSetup.currentSlotId, 1);
    final s1Again =
        (await IsarSetup.instance.characters.where().findAll()).length;
    expect(s1Again, s1Count, reason: 'slot1 数据切回仍在(无串档)');
  });

  test('slotHasSave / listSlots:混合有档+空槽摘要正确 + 无句柄泄漏', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.close();

    expect(await IsarSetup.slotHasSave(1, directory: tempDir), true);
    expect(await IsarSetup.slotHasSave(3, directory: tempDir), false);

    final summaries = await IsarSetup.listSlots(directory: tempDir);
    expect(summaries.length, 3);
    expect(summaries[0].slotId, 1);
    expect(summaries[0].isEmpty, false);
    expect(summaries[0].founderName, isNotNull);
    expect(summaries[0].realmDisplay, isNotNull);
    expect(summaries[2].isEmpty, true, reason: 'slot3 无 db → 空槽');

    // 读完只读实例必 close,无句柄泄漏。
    expect(Isar.getInstance('wuxia_save_slot1'), isNull);
    expect(Isar.getInstance('wuxia_save_slot3'), isNull);
  });

  test('listSlots 当前已打开槽直接读不重开/不关', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    // slot1 当前打开:list 后 slot1 仍打开(不被 list 关掉)。
    final summaries = await IsarSetup.listSlots(directory: tempDir);
    expect(summaries[0].isEmpty, false);
    expect(Isar.getInstance('wuxia_save_slot1'), isNotNull,
        reason: '当前槽 list 后仍打开');
  });

  test('deleteSlot:删非当前槽 → slotHasSave=false + 文件移除', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.close();
    expect(await IsarSetup.slotHasSave(1, directory: tempDir), true);

    await IsarSetup.deleteSlot(1, directory: tempDir);
    expect(await IsarSetup.slotHasSave(1, directory: tempDir), false);
    expect(
      await File('${tempDir.path}/wuxia_save_slot1.isar').exists(),
      false,
    );
  });

  test('deleteSlot 当前槽:先 close 再删,实例置空', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.deleteSlot(1, directory: tempDir); // 删当前槽
    expect(IsarSetup.instanceOrNull, isNull, reason: '删当前档后实例置空');
    expect(await IsarSetup.slotHasSave(1, directory: tempDir), false);
  });
}
