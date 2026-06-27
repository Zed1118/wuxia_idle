import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/lineage/application/disciple_join_service.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

/// 第七阶段批三 · Task 6:[DiscipleJoinService.joinForClearedStage] 过关懒创建命名弟子。
///
/// 沿 onboarding_service_test 体例:tempDir + Isar.init + GameRepository.loadAllDefs,
/// SOLO seed(ensureFoundingMasters 默认 soloStart=true,仅祖师)。
void main() {
  late Directory tempDir;
  late Isar isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_disciple_join_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
    // SOLO 开局:仅祖师 id=1。
    await OnboardingService(isar: isar).ensureFoundingMasters();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('过主线终局关(06_05) → 懒创建 senior+junior 并入队 + 关级防重', () async {
    final svc = DiscipleJoinService(isar: isar);
    final joined = await svc.joinForClearedStage('stage_06_05');
    expect(joined.length, 2, reason: '06_05 命中两条 disciple_joins');
    expect(joined[0].lineageRole, LineageRole.senior, reason: 'senior 先');
    expect(joined[1].lineageRole, LineageRole.junior, reason: 'junior 后');
    final senior = joined[0];
    expect(senior.isActive, true);
    final save = await isar.saveDatas.get(0);
    expect(save!.activeCharacterIds.contains(senior.id), true);
    expect(save.activeCharacterIds.length, 3, reason: '祖师 + 两弟子满队');
    expect(save.triggeredDiscipleJoinStageIds.contains('stage_06_05'), true);
    final founder = await isar.characters.get(1);
    expect(founder!.discipleIds.contains(senior.id), true);
    expect(senior.masterId, 1);

    // 幂等:重战同关不再创建
    final again = await svc.joinForClearedStage('stage_06_05');
    expect(again, isEmpty);
    expect((await isar.characters.where().findAll()).length, 3); // founder + 2
  });

  test('旧触发关(02_05/03_05)不再拜入', () async {
    final svc = DiscipleJoinService(isar: isar);
    expect(await svc.joinForClearedStage('stage_02_05'), isEmpty);
    expect(await svc.joinForClearedStage('stage_03_05'), isEmpty);
    expect((await isar.characters.where().findAll()).length, 1); // 仅 founder
  });

  test('非 join 关 → 空列表无副作用', () async {
    final svc = DiscipleJoinService(isar: isar);
    expect(await svc.joinForClearedStage('stage_01_01'), isEmpty);
    expect((await isar.characters.where().findAll()).length, 1); // 仅 founder
  });

  test('旧档祖年化:已有 senior 的档过 06_05 → 不重建 senior,junior 正常补入',
      () async {
    final svc = DiscipleJoinService(isar: isar);
    // 先在 06_05 拜两人,再删 junior + 清关级标记,模拟「旧档只有 senior 在队」。
    final first = await svc.joinForClearedStage('stage_06_05');
    expect(first.length, 2);
    final juniorId =
        first.firstWhere((c) => c.lineageRole == LineageRole.junior).id;
    await isar.writeTxn(() async {
      await isar.characters.delete(juniorId);
      final s = await isar.saveDatas.get(0);
      s!
        ..activeCharacterIds =
            s.activeCharacterIds.where((id) => id != juniorId).toList()
        ..triggeredDiscipleJoinStageIds = []; // 清关级标记模拟旧档未按新关标记
      await isar.saveDatas.put(s);
    });
    // 再过 06_05:senior 已存在被角色级 guard 跳过,junior 补入。
    final second = await svc.joinForClearedStage('stage_06_05');
    expect(second.length, 1, reason: '仅补 junior');
    expect(second.first.lineageRole, LineageRole.junior);
    final seniors = (await isar.characters.where().findAll())
        .where((c) => c.lineageRole == LineageRole.senior)
        .toList();
    expect(seniors.length, 1, reason: 'senior 不重建');
  });
}
