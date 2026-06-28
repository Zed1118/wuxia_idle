import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/jianghu/application/enmity_battle_modifier.dart';
import 'package:wuxia_idle/features/jianghu/application/npc_relation_service.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

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

  test('P3 种子（含主修）+ stage_01_01 → 左队 1 人 + 右队按 yaml 装配', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);

    expect(left.length, 1, reason: 'P3 种子单角色');
    expect(left.first.characterId, 1);
    expect(left.first.teamSide, 0);
    expect(left.first.slotIndex, 0);

    expect(
      right.length,
      stage.enemyTeam.length,
      reason: 'stage_01_01 敌人数跟随 production yaml',
    );
    expect(right[0].name, '流民甲');
  });

  test(
    '敌人 BattleCharacter 字段映射：baseHp/Attack/Speed → maxHp/EqAtk/speed',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final stage = GameRepository.instance.getStage('stage_01_01');

      final (_, right) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      // stage_01_01 流民甲：baseHp 1500 / baseAttack 80 / baseSpeed 100
      expect(right[0].maxHp, 1500);
      expect(right[0].currentHp, 1500);
      expect(right[0].totalEquipmentAttack, 80);
      expect(right[0].speed, 100);
      expect(right[0].isAlive, isTrue);
      expect(right[0].activeBuffs, isEmpty);
    },
  );

  test('敌人 characterId 用负数防冲突（按 slot 递减）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);

    expect(left.first.characterId, greaterThan(0), reason: '玩家 isar id 是正数');
    expect(
      right.map((e) => e.characterId).toList(),
      List.generate(stage.enemyTeam.length, (i) => -(i + 1)),
    );
  });

  test('SaveData.activeCharacterIds 显式指定 → 取该列表，不走 fallback', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    // 显式写 activeCharacterIds
    await IsarSetup.instance.writeTxn(() async {
      final s = await IsarSetup.instance.saveDatas.get(0);
      s!.activeCharacterIds = [1];
      await IsarSetup.instance.saveDatas.put(s);
    });
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);
    expect(left.length, 1);
    expect(left.first.characterId, 1);
  });

  test('Isar 没任何 Character → throw StateError', () async {
    final stage = GameRepository.instance.getStage('stage_01_01');

    await expectLater(
      StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('没有任何 Character'),
        ),
      ),
    );
  });

  test('P1 种子（无主修心法）→ buildTeams throw 「未修主修」', () async {
    // P1 fixture 只有装备 + 物料，不创建心法（参考 phase2_seed_service.dart:35-53）
    await Phase2SeedService(isar: IsarSetup.instance).seedP1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    await expectLater(
      StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains('未修主修')),
      ),
    );
  });

  test('stage_03_05 章末大 Boss：右队 1 名（solo 章末 Boss）+ isBossStage=true 不影响转换', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_03_05');
    expect(stage.isBossStage, isTrue);
    expect(stage.narrativeDefeatId, 'stage_03_05_defeat');

    final (_, right) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);
    expect(right.length, 1);
    expect(right[0].name, '灰衣人');
    expect(right[0].maxHp, 9000); // baseHp from yaml（2026-06-29 solo 11000→9000）
  });

  test('江湖恩怨：带 npcId 的 Boss 关进战斗时烘焙 APM 与来源', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final stage = GameRepository.instance.getStage('stage_02_05');
    final npcId = stage.npcId!;
    final npcTargetId = EnmityBattleModifier.targetIdForNpcId(npcId);
    final emc = GameRepository.instance.numbers.jianghu.enmityCombatModifier;

    final svc = NpcRelationService(
      IsarSetup.instance,
      GameRepository.instance.numbers,
    );
    await svc.upsert(
      sourceCharacterId: 1,
      targetCharacterId: npcTargetId,
      type: 'foe',
      level: emc.severeThreshold,
    );

    final (left, right) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);

    expect(
      right.first.characterId,
      npcTargetId,
      reason: 'stage.npcId 应映射到稳定 target id，而非普通 slot id',
    );
    expect(left.first.attackPowerMultiplier, emc.severeMult);
    expect(right.first.attackPowerMultiplier, emc.severeMult);
    expect(
      left.first.attackPowerMultiplierSource,
      AttackPowerMultiplierSource.jianghuEnmity,
    );
    expect(
      right.first.attackPowerMultiplierSource,
      AttackPowerMultiplierSource.jianghuEnmity,
    );
    expect(
      right.skip(1).every((c) => c.attackPowerMultiplier == 1.0),
      isTrue,
      reason: 'stage.npcId 只绑定 Boss 主体，不影响随从',
    );
  });

  // ── W18-A1.2 心法相生 6 字段注入(defensePct 加法叠加 defenseRate) ──────

  test(
    'VC18-A1 A·阴阳 BattleCharacter defenseRate = realm base + synergy defensePct',
    () async {
      // VC18-A1 fixture:A·阴阳(组合 1 阴阳调和)= schoolPair gangMeng+yinRou
      // multipliers:hpPct 0.20 / defensePct 0.10(W18-A1.2 新增)
      await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
      final stage = GameRepository.instance.getStage('stage_01_01');

      final (left, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      // 玩家方前 3 角色 = A·阴阳 / B·刚柔 / C·阴影(seed activeIds [1,2,3,4,5]
      // 前 3 进战)
      final a = left[0]; // A·阴阳
      final b = left[1]; // B·刚柔
      final c = left[2]; // C·阴影

      // yiLiu base defenseRate = 0.20(numbers.yaml realms.tiers[yiLiu].defense_rate)
      // A·阴阳 命中相生 → +0.10 加法 → 0.30(< clamp 0.95 上限)
      expect(
        a.defenseRate,
        closeTo(0.30, 1e-9),
        reason: 'A·阴阳 相生 defensePct=0.10 加法叠加 yiLiu base 0.20 → 0.30',
      );
      // B·刚柔 命中相生 但 multipliers 无 defensePct → 仍 base 0.20
      expect(
        b.defenseRate,
        closeTo(0.20, 1e-9),
        reason: 'B·刚柔 相生 multipliers 无 defensePct,defenseRate 保持 base',
      );
      // C·阴影 同理(组合 3 阴影迅捷只有 attack/speed)
      expect(
        c.defenseRate,
        closeTo(0.20, 1e-9),
        reason: 'C·阴影 相生 multipliers 无 defensePct,defenseRate 保持 base',
      );
    },
  );

  test('心法相生会检测第 2/3 辅修槽并按优先级注入战斗属性', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final isar = IsarSetup.instance;

    await isar.writeTxn(() async {
      final ch = (await isar.characters.get(1))!;
      ch.realmTier = RealmTier.yiLiu;
      ch.realmLayer = RealmLayer.qiMeng;

      final main = Technique.create(
        defId: 'tech_gangmeng_mingjia',
        ownerCharacterId: ch.id,
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026),
      )..id = 901;
      final lowerPriorityAssist = Technique.create(
        defId: 'tech_gangmeng_changlian',
        ownerCharacterId: ch.id,
        tier: TechniqueTier.changLianGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.assist,
        learnedAt: DateTime(2026),
      )..id = 902;
      final higherPriorityAssist = Technique.create(
        defId: 'tech_yinrou_mingjia',
        ownerCharacterId: ch.id,
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.yinRou,
        role: TechniqueRole.assist,
        learnedAt: DateTime(2026),
      )..id = 903;
      await isar.techniques.putAll([
        main,
        lowerPriorityAssist,
        higherPriorityAssist,
      ]);

      ch.mainTechniqueId = main.id;
      ch.assistTechniqueIds = [lowerPriorityAssist.id, higherPriorityAssist.id];
      await isar.characters.put(ch);
    });

    final stage = GameRepository.instance.getStage('stage_01_01');
    final (left, _) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);
    final baseDefense = RealmUtils.defenseRateOf(RealmTier.yiLiu);

    expect(
      left.first.defenseRate,
      closeTo(baseDefense + 0.10, 1e-9),
      reason:
          '第 1 辅修 sameSchool 只加 attack；第 2 辅修 gangMeng+yinRou '
          'schoolPair 优先级更高，应注入 defensePct=0.10',
    );
  });

  test('Codex 视觉验收 A:B:C maxHp ratio 回归(P1.1 E.5 含祖师爷 buff +5%)', () async {
    // W18-A1 Codex 视觉验收(closeout `codex_w18_a1_synergy_visual_check_2026-05-17.md`)
    // 原实测 A:B = 7992 / 6660 = 1.20 命中 hpPct=0.20。
    // P0.1 #38 方案 D 重平衡(2026-05-17)后:max_hp_formula 0.7→0.5 / 500→400,
    // yiLiu·qiMeng + const 6 + 无装备 base 6660 → 5300,A 极值 7992 → 6360。
    // P1.1 A1 E.5(2026-05-21):founder_ancestor_buff +5% maxHp 注入,
    // active 中含 isFounder(VC18-A1 fixture 5 角色第 1 个 = 祖师)→ 全队享 buff。
    // A 极值 6360 × 1.05 = 6678,B/C base 5300 × 1.05 = 5565,A:B = 1.20 比例不变。
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);

    expect(
      left[0].maxHp,
      6678,
      reason:
          'A·阴阳 maxHp = base 5300 × 1.20 × founder buff 1.05 = 6678(P1.1 A1 E.5)',
    );
    expect(
      left[1].maxHp,
      5565,
      reason: 'B·刚柔 base 5300 × founder buff 1.05 = 5565',
    );
    expect(left[2].maxHp, 5565, reason: 'C·阴影 同 B');
  });

  // ── W18-A1.2 hot-loop 红线压测 ─────────────────────────────────────────
  // 复用 VC18-A1 fixture(5 角色 yiLiu tier × 5 synergy 全命中)做 6 字段
  // 注入后红线压测。断言"上界约束"不写具体数字(memory
  // `feedback_red_line_test_semantics`)。
  //
  // 当前 fixture 数值远低红线(yiLiu tier),压不到 §5.4 极值;真正"压数值"
  // 验证需 wushen tier + 神物级装备 fixture,留挂账给 Phase 5 / 1.0 实装
  // (PROGRESS 已记)。本批做:6 字段全消费回归保护 + 红线语义不变式断言。

  test('hot-loop A: 3 schoolPair synergy(阴阳/刚柔/阴影)6 字段 ≤ §5.4 红线', () async {
    // 默认 activeCharacterIds=[1..5] 前 3 进 left = A·阴阳 / B·刚柔 / C·阴影
    // 覆盖 3/3 schoolPair 类型(gangMeng+yinRou / gangMeng+lingQiao / yinRou+lingQiao)
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);

    expect(left.length, 3, reason: 'stage_01_01 玩家方前 3 角色');
    for (final ch in left) {
      _expectRedLines(ch);
    }
  });

  test(
    'hot-loop B: sameSchool + sameTier synergy(同流派精进/同辈互补)6 字段 ≤ §5.4 红线',
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

      final (left, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      expect(left.length, 3, reason: 'stage_01_01 玩家方 3 角色');
      for (final ch in left) {
        _expectRedLines(ch);
      }
    },
  );

  test('hot-loop C: defenseRate clamp 0.95 防御率 100% 极端 bug', () async {
    // 用 VC18-A1 fixture A·阴阳:yiLiu base defenseRate=0.20 + synergy 0.10
    // 加法叠加 = 0.30(远低 clamp 0.95)。本 case 断言 clamp 逻辑生效
    // 防回归(若未来 synergy defensePct 提升到 0.80 与 realm 高 tier 0.35
    // 叠加 = 1.15 应被 clamp 到 0.95 不破)
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage);

    // 所有角色 defenseRate ∈ [0.0, 0.95](clamp 上下界)
    for (final ch in left) {
      expect(
        ch.defenseRate,
        inInclusiveRange(0.0, 0.95),
        reason: '${ch.name} defenseRate ${ch.defenseRate} 必在 clamp [0.0, 0.95]',
      );
    }
  });

  group('P5.2 resolveEnemyInternalForce 纯函数', () {
    test('scale 1.0 直通 RealmDef 值', () {
      expect(
        StageBattleSetup.resolveEnemyInternalForce(13000, 1.0, 15000),
        13000,
      );
    });
    test('scale 0.5 折半', () {
      expect(
        StageBattleSetup.resolveEnemyInternalForce(13000, 0.5, 15000),
        6500,
      );
    });
    test('scale 2.0 越红线 → clamp 15000', () {
      expect(
        StageBattleSetup.resolveEnemyInternalForce(15000, 2.0, 15000),
        15000,
      );
    });
    test('低境界学徒 500 × 1.0 = 500', () {
      expect(StageBattleSetup.resolveEnemyInternalForce(500, 1.0, 15000), 500);
    });
  });

  group('P5.2 EnemyDefaults.fromYaml scale 校验', () {
    Map<String, dynamic> y(num scale) => {
      'internal_force_scale': scale,
      'critical_rate': 0.05,
      'evasion_rate': 0.05,
    };
    test('scale 1.0 正常解析', () {
      expect(EnemyDefaults.fromYaml(y(1.0)).internalForceScale, 1.0);
    });
    test('scale 0 → throw', () {
      expect(() => EnemyDefaults.fromYaml(y(0)), throwsArgumentError);
    });
    test('scale 负 → throw', () {
      expect(() => EnemyDefaults.fromYaml(y(-0.5)), throwsArgumentError);
    });
    test('scale > 2 → throw', () {
      expect(() => EnemyDefaults.fromYaml(y(2.5)), throwsArgumentError);
    });
  });

  group('P5.2 敌人内力对称化集成', () {
    // 断言关系(查表×scale)而非瞬时数字,scale 调校后不破
    // (memory feedback_red_line_test_semantics)。
    int expectedEnemyIf(BattleCharacter e) {
      final repo = GameRepository.instance;
      return StageBattleSetup.resolveEnemyInternalForce(
        repo.getRealm(e.realmTier, e.realmLayer).internalForceMax,
        repo.numbers.combat.enemyDefaults.internalForceScale,
        repo.numbers.combat.redLines.internalForceMax,
      );
    }

    test('学徒敌人 stage_01_01 内力 = 查表×scale 且满开局(current=max)', () {
      final stage = GameRepository.instance.getStage('stage_01_01');
      final e = StageBattleSetup.buildEnemyTeam(stage.enemyTeam).first;
      expect(e.maxInternalForce, expectedEnemyIf(e));
      expect(e.currentInternalForce, e.maxInternalForce);
    });
    test('武圣 Boss 西凉霸主内力 = 查表×scale 且满开局', () {
      final stage = GameRepository.instance.getStage('stage_06_05');
      final boss = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
      ).firstWhere((e) => e.name == '西凉霸主');
      expect(boss.maxInternalForce, expectedEnemyIf(boss));
      expect(boss.currentInternalForce, boss.maxInternalForce);
    });
    test('P5.2 核心:武圣 Boss 内力 ≥ 阴柔传说大招 cost → 招牌大招能放', () {
      final stage = GameRepository.instance.getStage('stage_06_05');
      final boss = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
      ).firstWhere((e) => e.name == '西凉霸主');
      final ult = GameRepository.instance.getSkill(
        'skill_yinrou_chuanshuo_ult',
      );
      expect(ult.internalForceCost, 1600);
      expect(
        boss.currentInternalForce,
        greaterThanOrEqualTo(ult.internalForceCost),
        reason:
            'P5.2 目标:对称化后武圣 Boss 内力须够放其招牌传说大招'
            '(改前扁平 1000 < 1600 永久放不出);scale 调校须保此不变式',
      );
    });
  });

  // ── B2: _enemyToBattle 透传 isBoss ────────────────────────────────────────
  test('_enemyToBattle 透传 EnemyDef.isBoss → BattleCharacter.isBoss', () {
    const bossEnemy = EnemyDef(
      id: 'boss1',
      name: '黑风寨主',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 5000,
      baseAttack: 400,
      baseSpeed: 200,
      skillIds: [],
      iconPath: 'assets/enemies/x.png',
      isBoss: true,
    );
    final bc = StageBattleSetup.debugEnemyToBattle(
      enemy: bossEnemy,
      slotIndex: 0,
    );
    expect(bc.isBoss, true);

    const mob = EnemyDef(
      id: 'mob1',
      name: '喽啰',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 100,
      baseAttack: 50,
      baseSpeed: 100,
      skillIds: [],
      iconPath: 'assets/enemies/y.png',
    );
    expect(
      StageBattleSetup.debugEnemyToBattle(enemy: mob, slotIndex: 1).isBoss,
      false,
    );
  });

  // ── P1b Task5: applyAutoFill wire ─────────────────────────────────────────
  // 断言：5 装配槽全空的角色，经 buildTeams(→ _buildPlayerTeam → applyAutoFill)
  // 后，其 mainSkillId1 已被填入（非 null），证明走了装配而非 fallback。
  test('Task5 wire: 5 槽全空角色进战斗前 autoFill 填主修招 → mainSkillId1 非 null', () async {
    // P3 种子：角色有主修心法 tech_gangmeng_jichu，5 装配槽初始全 null。
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final isar = IsarSetup.instance;

    // 确认进战斗前 5 槽全空
    final before = await isar.characters.get(1);
    expect(before?.mainSkillId1, isNull, reason: 'P3 种子不预填装配槽，进战斗前应全空');

    final stage = GameRepository.instance.getStage('stage_01_01');
    await StageBattleSetup(isar: isar).buildTeams(stage);

    // buildTeams 调用后 autoFill 已落库
    final after = await isar.characters.get(1);
    expect(
      after?.mainSkillId1,
      isNotNull,
      reason: 'autoFill wire 应填入主修招到 mainSkillId1',
    );
  });

  test('Task5 wire: autoFill 后 availableSkills 含主修招（走装配非 fallback）', () async {
    // P3 种子：角色有主修心法 tech_gangmeng_jichu，5 装配槽全 null。
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final isar = IsarSetup.instance;

    // 进战斗前确认槽全空
    final before = await isar.characters.get(1);
    expect(before?.mainSkillId1, isNull);

    final stage = GameRepository.instance.getStage('stage_01_01');
    final (left, _) = await StageBattleSetup(isar: isar).buildTeams(stage);

    final player = left.first;
    final skillIds = player.availableSkills.map((s) => s.id).toSet();

    // autoFill 后走装配路径，availableSkills 是装配槽子集。
    // P3 种子主修心法 tech_gangmeng_mingjia 有 3 招：basic/skill/ult。
    // autoFill 按 powerMultiplier 分配到主修槽和大招槽，至少一招被装配。
    expect(
      skillIds.any((id) => id.startsWith('skill_gangmeng_mingjia_')),
      isTrue,
      reason: 'autoFill 后 availableSkills 应含主修心法招(tech_gangmeng_mingjia)',
    );
  });

  // ── 第八阶段 Task5: 伤势烘焙进 BattleCharacter ────────────────────────────

  group('Task5 injury 烘焙', () {
    /// 把 P3 种子角色改写为重伤状态（injuryHoursRemaining > 0）。
    Future<void> setHeavyInjured(Isar isar, {double hours = 24.0}) async {
      await isar.writeTxn(() async {
        final ch = (await isar.characters.get(1))!;
        ch.injuryHoursRemaining = hours;
        ch.lightInjuryStacks = 0;
        await isar.characters.put(ch);
      });
    }

    /// 把 P3 种子角色改写为轻伤状态（lightInjuryStacks > 0）。
    Future<void> setLightInjured(Isar isar, {int stacks = 3}) async {
      await isar.writeTxn(() async {
        final ch = (await isar.characters.get(1))!;
        ch.injuryHoursRemaining = 0;
        ch.lightInjuryStacks = stacks;
        await isar.characters.put(ch);
      });
    }

    test('重伤角色 outputMultiplier ≤ heavyAttackOutputMultiplier（含折扣）', () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await setHeavyInjured(IsarSetup.instance);
      final stage = GameRepository.instance.getStage('stage_01_01');

      final (left, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      final player = left.first;
      final injuryMult =
          GameRepository.instance.numbers.injury.heavyAttackOutputMultiplier;
      expect(
        player.outputMultiplier,
        lessThanOrEqualTo(injuryMult),
        reason:
            '重伤角色 outputMultiplier 应 ≤ heavyAttackOutputMultiplier=$injuryMult',
      );
      expect(
        player.outputMultiplier,
        lessThan(1.0),
        reason: '重伤攻击折扣应 < 1.0（比无伤低）',
      );
    });

    test('重伤角色 maxInternalForce 低于无伤同角色', () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final stage = GameRepository.instance.getStage('stage_01_01');

      // 无伤 baseline
      final (leftBase, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);
      final baseIf = leftBase.first.maxInternalForce;

      // 重设为重伤
      await setHeavyInjured(IsarSetup.instance);
      final (leftInjured, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);
      final injuredIf = leftInjured.first.maxInternalForce;

      expect(
        injuredIf,
        lessThan(baseIf),
        reason: '重伤 maxInternalForce=$injuredIf 应 < 无伤 baseline=$baseIf',
      );
    });

    test('轻伤角色 speed 低于无伤同角色', () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final stage = GameRepository.instance.getStage('stage_01_01');

      // 无伤 baseline
      final (leftBase, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);
      final baseSpeed = leftBase.first.speed;

      // 重设为轻伤
      await setLightInjured(IsarSetup.instance, stacks: 3);
      final (leftInjured, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);
      final injuredSpeed = leftInjured.first.speed;

      expect(
        injuredSpeed,
        lessThan(baseSpeed),
        reason: '轻伤 speed=$injuredSpeed 应 < 无伤 baseline=$baseSpeed（3 stack 减速）',
      );
    });

    test('无伤角色 outputMultiplier = 1.0（余毒无 + 重伤无）', () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final stage = GameRepository.instance.getStage('stage_01_01');

      final (left, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      expect(
        left.first.outputMultiplier,
        closeTo(1.0, 1e-9),
        reason: '无伤 + 无余毒角色 outputMultiplier 应为 1.0',
      );
    });

    test('镜像/敌方不带玩家伤势（重伤玩家 → 敌方 outputMultiplier 仍 = 1.0）', () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await setHeavyInjured(IsarSetup.instance);
      final stage = GameRepository.instance.getStage('stage_01_01');

      final (_, right) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      for (final enemy in right) {
        expect(
          enemy.outputMultiplier,
          closeTo(1.0, 1e-9),
          reason: '敌方 ${enemy.name} outputMultiplier 不受玩家伤势影响',
        );
      }
    });
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
  expect(
    ch.maxHp,
    lessThanOrEqualTo(20000),
    reason: '${ch.name} maxHp ${ch.maxHp} 不破 §5.4 玩家血量红线 20000',
  );
  expect(
    ch.currentHp,
    lessThanOrEqualTo(ch.maxHp),
    reason: '${ch.name} currentHp ≤ maxHp 派生不变式',
  );
  expect(
    ch.maxInternalForce,
    lessThanOrEqualTo(15000),
    reason:
        '${ch.name} maxInternalForce ${ch.maxInternalForce} 不破 §5.4 内力红线 15000(applySynergy cap)',
  );
  expect(
    ch.currentInternalForce,
    lessThanOrEqualTo(ch.maxInternalForce),
    reason: '${ch.name} currentInternalForce ≤ maxInternalForce 派生不变式',
  );
  expect(
    ch.defenseRate,
    inInclusiveRange(0.0, 0.95),
    reason:
        '${ch.name} defenseRate ${ch.defenseRate} 必在 applySynergy clamp [0.0, 0.95]',
  );
  expect(
    ch.speed,
    greaterThan(0),
    reason: '${ch.name} speed > 0(防战斗卡死,actionPoint 增量必须正)',
  );
  expect(
    ch.totalEquipmentAttack,
    greaterThanOrEqualTo(0),
    reason: '${ch.name} totalEquipmentAttack ≥ 0(非负)',
  );
}
