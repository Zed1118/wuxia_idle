import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/presentation/milestone_grant_hook.dart';

/// F1 里程碑授予 hook 纯逻辑测(stageId→tag→grant 映射)。
/// 不走 testWidgets(真 Isar writeTxn 不兼容 FakeAsync)。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_milestone_hook_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('首通 stage_mass_battle_05 授百战甲', () async {
    final granted = await grantMilestoneForClearedStage(
      isar: IsarSetup.instance,
      clearedStageId: 'stage_mass_battle_05',
    );
    expect(granted, contains('armor_special_bai_zhan_jia'));
  });

  test('首通 stage_inner_demon_07 授心魔珠', () async {
    final granted = await grantMilestoneForClearedStage(
      isar: IsarSetup.instance,
      clearedStageId: 'stage_inner_demon_07',
    );
    expect(granted, contains('accessory_special_xin_mo_zhu'));
  });

  test('非里程碑关 no-op', () async {
    final granted = await grantMilestoneForClearedStage(
      isar: IsarSetup.instance,
      clearedStageId: 'stage_01_01',
    );
    expect(granted, isEmpty);
  });

  test('群战非终点关(mass_battle_01)不授予', () async {
    final granted = await grantMilestoneForClearedStage(
      isar: IsarSetup.instance,
      clearedStageId: 'stage_mass_battle_01',
    );
    expect(granted, isEmpty);
  });
}
