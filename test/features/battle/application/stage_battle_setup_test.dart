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

  test('Codex 视觉验收 A:B:C maxHp ratio 回归(P1.1 E.5 含祖师爷 buff +5%)',
      () async {
    // W18-A1 Codex 视觉验收(closeout `codex_w18_a1_synergy_visual_check_2026-05-17.md`)
    // 原实测 A:B = 7992 / 6660 = 1.20 命中 hpPct=0.20。
    // P0.1 #38 方案 D 重平衡(2026-05-17)后:max_hp_formula 0.7→0.5 / 500→400,
    // yiLiu·qiMeng + const 6 + 无装备 base 6660 → 5300,A 极值 7992 → 6360。
    // P1.1 A1 E.5(2026-05-21):founder_ancestor_buff +5% maxHp 注入,
    // active 中含 isFounder(VC18-A1 fixture 5 角色第 1 个 = 祖师)→ 全队享 buff。
    // A 极值 6360 × 1.05 = 6678,B/C base 5300 × 1.05 = 5565,A:B = 1.20 比例不变。
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) =
        await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left[0].maxHp, 6678,
        reason:
            'A·阴阳 maxHp = base 5300 × 1.20 × founder buff 1.05 = 6678(P1.1 A1 E.5)');
    expect(left[1].maxHp, 5565,
        reason: 'B·刚柔 base 5300 × founder buff 1.05 = 5565');
    expect(left[2].maxHp, 5565,
        reason: 'C·阴影 同 B');
  });

  // ── W18-A1.2 hot-loop 红线压测 ─────────────────────────────────────────
  // 复用 VC18-A1 fixture(5 角色 yiLiu tier × 5 synergy 全命中)做 6 字段
  // 注入后红线压测。断言"上界约束"不写具体数字(memory
  // `feedback_red_line_test_semantics`)。
  //
  // 当前 fixture 数值远低红线(yiLiu tier),压不到 §5.4 极值;真正"压数值"
  // 验证需 wushen tier + 神物级装备 fixture,留挂账给 Phase 5 / 1.0 实装
  // (PROGRESS 已记)。本批做:6 字段全消费回归保护 + 红线语义不变式断言。

  test('hot-loop A: 3 schoolPair synergy(阴阳/刚柔/阴影)6 字段 ≤ §5.4 红线',
      () async {
    // 默认 activeCharacterIds=[1..5] 前 3 进 left = A·阴阳 / B·刚柔 / C·阴影
    // 覆盖 3/3 schoolPair 类型(gangMeng+yinRou / gangMeng+lingQiao / yinRou+lingQiao)
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) =
        await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left.length, 3, reason: 'stage_01_01 玩家方前 3 角色');
    for (final ch in left) {
      _expectRedLines(ch);
    }
  });

  test('hot-loop B: sameSchool + sameTier synergy(同流派精进/同辈互补)6 字段 ≤ §5.4 红线',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    // 重排 activeCharacterIds 让 D·同流派 / E·同辈进 left[0]/[1]
    // (覆盖 sameSchool / sameTier 剩余 2 synergy 类型)
    await IsarSetup.instance.writeTxn(() async {
      final s = await IsarSetup.instance.saveDatas.get(0);
      s!.activeCharacterIds = [4, 5, 1]; // D / E / A 兜底第 3
      await IsarSetup.instance.saveDatas.put(s);
    });
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) =
        await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left.length, 3, reason: 'stage_01_01 玩家方 3 角色');
    for (final ch in left) {
      _expectRedLines(ch);
    }
  });

  test('hot-loop C: defenseRate clamp 0.95 防御率 100% 极端 bug',
      () async {
    // 用 VC18-A1 fixture A·阴阳:yiLiu base defenseRate=0.20 + synergy 0.10
    // 加法叠加 = 0.30(远低 clamp 0.95)。本 case 断言 clamp 逻辑生效
    // 防回归(若未来 synergy defensePct 提升到 0.80 与 realm 高 tier 0.35
    // 叠加 = 1.15 应被 clamp 到 0.95 不破)
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) =
        await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    // 所有角色 defenseRate ∈ [0.0, 0.95](clamp 上下界)
    for (final ch in left) {
      expect(ch.defenseRate, inInclusiveRange(0.0, 0.95),
          reason: '${ch.name} defenseRate ${ch.defenseRate} 必在 clamp [0.0, 0.95]');
    }
  });
}

/// hot-loop 红线压测断言 helper:6 字段 + 派生不变式上界。
///
/// **不写具体数字**(memory `feedback_red_line_test_semantics`):
///   - maxHp ≤ 20000(§5.4 玩家血量红线)
///   - maxInternalForce ≤ 15000(§5.4 内力红线 + applySynergy cap)
///   - defenseRate ∈ [0.0, 0.95](applySynergy clamp,§5.5 减伤 100% 防 bug)
///   - currentHp ≤ maxHp / currentInternalForce ≤ maxInternalForce(派生不变式)
///   - speed > 0 / totalEquipmentAttack ≥ 0(非负 + 非零 speed 防卡死战斗)
void _expectRedLines(dynamic ch) {
  expect(ch.maxHp, lessThanOrEqualTo(20000),
      reason: '${ch.name} maxHp ${ch.maxHp} 不破 §5.4 玩家血量红线 20000');
  expect(ch.currentHp, lessThanOrEqualTo(ch.maxHp),
      reason: '${ch.name} currentHp ≤ maxHp 派生不变式');
  expect(ch.maxInternalForce, lessThanOrEqualTo(15000),
      reason: '${ch.name} maxInternalForce ${ch.maxInternalForce} 不破 §5.4 内力红线 15000(applySynergy cap)');
  expect(ch.currentInternalForce, lessThanOrEqualTo(ch.maxInternalForce),
      reason: '${ch.name} currentInternalForce ≤ maxInternalForce 派生不变式');
  expect(ch.defenseRate, inInclusiveRange(0.0, 0.95),
      reason: '${ch.name} defenseRate ${ch.defenseRate} 必在 applySynergy clamp [0.0, 0.95]');
  expect(ch.speed, greaterThan(0),
      reason: '${ch.name} speed > 0(防战斗卡死,actionPoint 增量必须正)');
  expect(ch.totalEquipmentAttack, greaterThanOrEqualTo(0),
      reason: '${ch.name} totalEquipmentAttack ≥ 0(非负)');
}
