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

/// 第七阶段批三 · Task 12: 队伍成长 e2e — 全弧线验证
///
/// 单人开局 → 过 stage_06_05(全主线终局)→ 同关一并拜入大弟子+小弟子 (3 人满队)
/// 同时验证 founder↔disciple 双向绑定正确写入。(spec A:弟子拜入后移至终局)
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_team_growth_e2e_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('单人开局 → 过 06_05 → 一关两弟子拜入 → 满队 3 人', () async {
    // Step 1: 单人开局 — 仅祖师
    await OnboardingService(isar: isar).ensureFoundingMasters();
    final saveAfterOnboard = await isar.saveDatas.get(0);
    expect(saveAfterOnboard, isNotNull);
    expect(saveAfterOnboard!.activeCharacterIds.length, 1,
        reason: '单人开局应仅有祖师一人在队');

    final svc = DiscipleJoinService(isar: isar);

    // Step 2: 过 stage_06_05(全主线终局)→ 同关连续拜入 senior + junior → 满队
    final joined = await svc.joinForClearedStage('stage_06_05');
    expect(joined.length, 2, reason: '终局关一并拜入两弟子');
    expect(joined[0].lineageRole, LineageRole.senior, reason: 'senior 先');
    expect(joined[1].lineageRole, LineageRole.junior, reason: 'junior 后');

    final saveFinal = await isar.saveDatas.get(0);
    expect(saveFinal!.activeCharacterIds.length, 3,
        reason: '两弟子拜入后队伍应为 3 人(满队)');
    expect(
      saveFinal.triggeredDiscipleJoinStageIds,
      contains('stage_06_05'),
      reason: '终局触发关应记录在防重集中',
    );
  });

  test('founder↔disciple 双向绑定: founder.discipleIds 含两弟子 + 弟子 masterId = founder', () async {
    await OnboardingService(isar: isar).ensureFoundingMasters();
    final save0 = await isar.saveDatas.get(0);
    final founderId = save0!.founderCharacterId!;

    final svc = DiscipleJoinService(isar: isar);
    final joined = await svc.joinForClearedStage('stage_06_05');
    final senior =
        joined.firstWhere((c) => c.lineageRole == LineageRole.senior);
    final junior =
        joined.firstWhere((c) => c.lineageRole == LineageRole.junior);

    final founder = await isar.characters.get(founderId);
    expect(founder, isNotNull);
    expect(
      founder!.discipleIds,
      containsAll([senior.id, junior.id]),
      reason: 'founder.discipleIds 应包含大弟子和小弟子',
    );
    expect(senior.masterId, founderId,
        reason: '大弟子的 masterId 应指向 founder');
    expect(junior.masterId, founderId,
        reason: '小弟子的 masterId 应指向 founder');
  });
}
