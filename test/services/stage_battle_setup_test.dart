import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/save_data.dart';
import 'package:wuxia_idle/services/phase2_seed_service.dart';
import 'package:wuxia_idle/services/stage_battle_setup.dart';

/// T37 StageBattleSetup 真 Isar 落地测试。
///
/// 沿用 phase2_seed_service_test 的 setUp 套路。Phase 2 P1 种子（id=1 角色 +
/// +0 利器装备 + 主修 + 心法）天然适配；EnemyDef 用 stages.yaml 真 fixture。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_battle_setup_test_');
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

  test('P3 种子（含主修）+ stage_01_01 → 左队 1 人 + 右队 3 名敌人',
      () async {
    await Phase2SeedService.seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup.buildTeams(stage);

    expect(left.length, 1, reason: 'P3 种子单角色');
    expect(left.first.characterId, 1);
    expect(left.first.teamSide, 0);
    expect(left.first.slotIndex, 0);

    expect(right.length, 3, reason: 'stage_01_01 三敌');
    expect(right[0].name, '流民甲');
    expect(right[1].name, '流民乙');
    expect(right[2].name, '流民丙');
  });

  test('敌人 BattleCharacter 字段映射：baseHp/Attack/Speed → maxHp/EqAtk/speed',
      () async {
    await Phase2SeedService.seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (_, right) = await StageBattleSetup.buildTeams(stage);

    // stage_01_01 流民甲：baseHp 1500 / baseAttack 80 / baseSpeed 100
    expect(right[0].maxHp, 1500);
    expect(right[0].currentHp, 1500);
    expect(right[0].totalEquipmentAttack, 80);
    expect(right[0].speed, 100);
    expect(right[0].isAlive, isTrue);
    expect(right[0].activeBuffs, isEmpty);
  });

  test('敌人 characterId 用负数防冲突（-1/-2/-3）', () async {
    await Phase2SeedService.seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup.buildTeams(stage);

    expect(left.first.characterId, greaterThan(0),
        reason: '玩家 isar id 是正数');
    expect(right[0].characterId, -1);
    expect(right[1].characterId, -2);
    expect(right[2].characterId, -3);
  });

  test('SaveData.activeCharacterIds 显式指定 → 取该列表，不走 fallback',
      () async {
    await Phase2SeedService.seedP3();
    // 显式写 activeCharacterIds
    await IsarSetup.instance.writeTxn(() async {
      final s = await IsarSetup.instance.saveDatas.get(0);
      s!.activeCharacterIds = [1];
      await IsarSetup.instance.saveDatas.put(s);
    });
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup.buildTeams(stage);
    expect(left.length, 1);
    expect(left.first.characterId, 1);
  });

  test('Isar 没任何 Character → throw StateError', () async {
    final stage = GameRepository.instance.getStage('stage_01_01');

    await expectLater(
      StageBattleSetup.buildTeams(stage),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('没有任何 Character'),
      )),
    );
  });

  test('P1 种子（无主修心法）→ buildTeams throw 「未修主修」', () async {
    // P1 fixture 只有装备 + 物料，不创建心法（参考 phase2_seed_service.dart:35-53）
    await Phase2SeedService.seedP1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    await expectLater(
      StageBattleSetup.buildTeams(stage),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('未修主修'),
      )),
    );
  });

  test('stage_03_05 章末大 Boss：右队 3 名 + isBossStage=true 不影响转换',
      () async {
    await Phase2SeedService.seedP3();
    final stage = GameRepository.instance.getStage('stage_03_05');
    expect(stage.isBossStage, isTrue);
    expect(stage.narrativeDefeatId, 'stage_03_05_defeat');

    final (_, right) = await StageBattleSetup.buildTeams(stage);
    expect(right.length, 3);
    expect(right[0].name, '灰衣人');
    expect(right[0].maxHp, 11000); // baseHp from yaml
  });
}
