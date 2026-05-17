import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

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
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

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
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (_, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    // stage_01_01 流民甲：baseHp 1500 / baseAttack 80 / baseSpeed 100
    expect(right[0].maxHp, 1500);
    expect(right[0].currentHp, 1500);
    expect(right[0].totalEquipmentAttack, 80);
    expect(right[0].speed, 100);
    expect(right[0].isAlive, isTrue);
    expect(right[0].activeBuffs, isEmpty);
  });

  test('敌人 characterId 用负数防冲突（-1/-2/-3）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left.first.characterId, greaterThan(0),
        reason: '玩家 isar id 是正数');
    expect(right[0].characterId, -1);
    expect(right[1].characterId, -2);
    expect(right[2].characterId, -3);
  });

  test('SaveData.activeCharacterIds 显式指定 → 取该列表，不走 fallback',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    // 显式写 activeCharacterIds
    await IsarSetup.instance.writeTxn(() async {
      final s = await IsarSetup.instance.saveDatas.get(0);
      s!.activeCharacterIds = [1];
      await IsarSetup.instance.saveDatas.put(s);
    });
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
    expect(left.length, 1);
    expect(left.first.characterId, 1);
  });

  test('Isar 没任何 Character → throw StateError', () async {
    final stage = GameRepository.instance.getStage('stage_01_01');

    await expectLater(
      StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('没有任何 Character'),
      )),
    );
  });

  test('P1 种子（无主修心法）→ buildTeams throw 「未修主修」', () async {
    // P1 fixture 只有装备 + 物料，不创建心法（参考 phase2_seed_service.dart:35-53）
    await Phase2SeedService(isar: IsarSetup.instance).seedP1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    await expectLater(
      StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('未修主修'),
      )),
    );
  });

  test('stage_03_05 章末大 Boss：右队 3 名 + isBossStage=true 不影响转换',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_03_05');
    expect(stage.isBossStage, isTrue);
    expect(stage.narrativeDefeatId, 'stage_03_05_defeat');

    final (_, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
    expect(right.length, 3);
    expect(right[0].name, '灰衣人');
    expect(right[0].maxHp, 11000); // baseHp from yaml
  });

  // ── W18-A1.2 心法相生 6 字段注入(defensePct 加法叠加 defenseRate) ──────

  test('VC18-A1 A·阴阳 BattleCharacter defenseRate = realm base + synergy defensePct',
      () async {
    // VC18-A1 fixture:A·阴阳(组合 1 阴阳调和)= schoolPair gangMeng+yinRou
    // multipliers:hpPct 0.20 / defensePct 0.10(W18-A1.2 新增)
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) =
        await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    // 玩家方前 3 角色 = A·阴阳 / B·刚柔 / C·阴影(seed activeIds [1,2,3,4,5]
    // 前 3 进战)
    final a = left[0]; // A·阴阳
    final b = left[1]; // B·刚柔
    final c = left[2]; // C·阴影

    // yiLiu base defenseRate = 0.20(numbers.yaml realms.tiers[yiLiu].defense_rate)
    // A·阴阳 命中相生 → +0.10 加法 → 0.30(< clamp 0.95 上限)
    expect(a.defenseRate, closeTo(0.30, 1e-9),
        reason: 'A·阴阳 相生 defensePct=0.10 加法叠加 yiLiu base 0.20 → 0.30');
    // B·刚柔 命中相生 但 multipliers 无 defensePct → 仍 base 0.20
    expect(b.defenseRate, closeTo(0.20, 1e-9),
        reason: 'B·刚柔 相生 multipliers 无 defensePct,defenseRate 保持 base');
    // C·阴影 同理(组合 3 阴影迅捷只有 attack/speed)
    expect(c.defenseRate, closeTo(0.20, 1e-9),
        reason: 'C·阴影 相生 multipliers 无 defensePct,defenseRate 保持 base');
  });

  test('Codex 视觉验收 A:B:C maxHp ratio 回归(7992 / 6660 / 6660)',
      () async {
    // W18-A1 Codex 视觉验收(closeout `codex_w18_a1_synergy_visual_check_2026-05-17.md`)
    // 实测 A:B = 7992 / 6660 = 1.20 精准命中 hpPct=0.20。本回归 test 锚定
    // 此数字防 base maxHp 派生公式 / hpPct 注入计算漂移。
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) =
        await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left[0].maxHp, 7992,
        reason: 'A·阴阳 maxHp = base 6660 × 1.20 = 7992(Codex 实测锚)');
    expect(left[1].maxHp, 6660,
        reason: 'B·刚柔 无 hpPct,maxHp = base(1000 + 3800×0.7 + 6×500 = 6660)');
    expect(left[2].maxHp, 6660,
        reason: 'C·阴影 同 B,无 hpPct');
  });
}
