import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/jianghu/application/npc_relation_service.dart';
import 'package:wuxia_idle/features/jianghu/application/reputation_service.dart';
import 'package:wuxia_idle/features/jianghu/domain/npc_relation.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1.2 R5 江湖恩怨 + 声望 红线契约族(spec §7)。
///
/// 与既有 B2 reputation_service_test / npc_relation_service_test 互补,不重复
/// 已覆盖项(R5.1 7 阶 21 测点 + R5.2 enmity 阈值 5 测已 ship)。
///
/// 本测族 focus:
/// - R5.3 §5.4 普伤 ≤8000 红线(enmity 1.25 fixture 单维度 · 引 T20 audit 契约)
/// - R5.4 trigger 数值 e2e(stage_boss_kill_delta + rival_delta + encounter delta clamp)
/// - R5.5 §5.2 七阶 label 锁 + numbers.yaml tier 顺序
/// - R5.6 P3.4 隔离 schema 断言(Reputation 不撞 Sect/SectEvent)
/// - R5.7 bakeEnmityMultipliers helper 对等 SET + max-across-enemies + noop fallback
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_jianghu_r5_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ── R5.3 §5.4 红线 ────────────────────────────────────────────────────────

  group('R5.3 §5.4 普伤红线 ≤ 8000(enmity APM 1.25 fixture)', () {
    test('enmity_combat_modifier.clamp_max ≤ 1.25(spec 契约 · 引 T20 R5.8 audit)',
        () {
      final emc = GameRepository.instance.numbers.jianghu.enmityCombatModifier;
      expect(emc.clampMax, lessThanOrEqualTo(1.25),
          reason: 'P1.2 spec §2:enmity APM clamp_max 不可超 1.25 · §5.4 红线兜底');
      expect(emc.severeMult, lessThanOrEqualTo(emc.clampMax),
          reason: 'severe_mult ≤ clamp_max:单 mult 不可越上限');
      expect(emc.playerAttackPowerMult, lessThanOrEqualTo(emc.clampMax),
          reason: 'player_attack_power_mult ≤ clamp_max:阶 1 mult 不可越上限');
    });

    test('enemy_attack_power_mult == player_attack_power_mult 双向对等', () {
      final emc = GameRepository.instance.numbers.jianghu.enmityCombatModifier;
      expect(emc.enemyAttackPowerMult, equals(emc.playerAttackPowerMult),
          reason: 'spec §2:双向对等 · 玩家敌人享同 mult');
    });

    test('attackPowerMultFor level=-100 返 ≤ clamp_max(实测 clamp 路径)',
        () async {
      final svc =
          NpcRelationService(isar, GameRepository.instance.numbers);
      await svc.upsert(
        sourceCharacterId: 1,
        targetCharacterId: 100,
        type: 'foe',
        level: -100,
      );
      final mult = await svc.attackPowerMultFor(1, 100);
      final cap =
          GameRepository.instance.numbers.jianghu.enmityCombatModifier.clampMax;
      expect(mult, lessThanOrEqualTo(cap),
          reason: 'attackPowerMultFor 返值受 clamp_max 兜底');
    });
  });

  // ── R5.4 trigger 数值 e2e ──────────────────────────────────────────────────

  group('R5.4 trigger 数值 e2e', () {
    test('stage_boss_kill_delta = 5(spec §3 触发数值锁)', () {
      final t = GameRepository.instance.numbers.jianghu.triggers;
      expect(t.stageBossKillDelta, 5,
          reason: '击杀有派别 boss · 该派 -5');
    });

    test('stage_boss_kill_rival_delta = 3(敌对派联动 + delta)', () {
      final t = GameRepository.instance.numbers.jianghu.triggers;
      expect(t.stageBossKillRivalDelta, 3,
          reason: '击杀有派别 boss · 敌对派 +3');
    });

    test('encounter_npc_delta_min/max = ±8(encounter resolve delta 范围契约)',
        () {
      final t = GameRepository.instance.numbers.jianghu.triggers;
      expect(t.encounterNpcDeltaMin, -8);
      expect(t.encounterNpcDeltaMax, 8);
    });

    test('applyDelta 累积 ReputationService · stage_boss_kill 模拟', () async {
      final repSvc =
          ReputationService(isar, GameRepository.instance.numbers);
      final t = GameRepository.instance.numbers.jianghu.triggers;
      // 模拟玩家击杀 shaolin boss × 2 + 敌对 jiaoMen +rival delta
      await repSvc.applyDelta(1, 'shaolin', -t.stageBossKillDelta);
      await repSvc.applyDelta(1, 'shaolin', -t.stageBossKillDelta);
      await repSvc.applyDelta(1, 'jiaoMen', t.stageBossKillRivalDelta);
      expect(await repSvc.valueFor(1, 'shaolin'), -10);
      expect(await repSvc.valueFor(1, 'jiaoMen'), 3);
    });
  });

  // ── R5.5 §5.2 七阶 label 锁 ───────────────────────────────────────────────

  group('R5.5 §5.2 七阶 label 锁(防 GDD 偏移)', () {
    test('reputation_tiers 7 阶顺序 + tier name 锁', () {
      final tiers =
          GameRepository.instance.numbers.jianghu.reputationTiers;
      expect(tiers.length, 7);
      expect(
        tiers.map((t) => t.tier).toList(),
        ['xueTu', 'sanLiu', 'erLiu', 'yiLiu', 'jueDing', 'zongShi', 'wuSheng'],
        reason: '七阶顺序沿 GDD §5.2,不可乱序 / 不可换名',
      );
    });

    test('reputation_tiers 7 阶 label 锁(UiStrings 同步)', () {
      final tiers =
          GameRepository.instance.numbers.jianghu.reputationTiers;
      final byTier = {for (final t in tiers) t.tier: t.label};
      expect(byTier['xueTu'], UiStrings.reputationTierXueTu);
      expect(byTier['sanLiu'], UiStrings.reputationTierSanLiu);
      expect(byTier['erLiu'], UiStrings.reputationTierErLiu);
      expect(byTier['yiLiu'], UiStrings.reputationTierYiLiu);
      expect(byTier['jueDing'], UiStrings.reputationTierJueDing);
      expect(byTier['zongShi'], UiStrings.reputationTierZongShi);
      expect(byTier['wuSheng'], UiStrings.reputationTierWuSheng);
    });

    test('reputation_tiers 区间无 gap + 全覆盖 [-100, +100]', () {
      final tiers =
          GameRepository.instance.numbers.jianghu.reputationTiers;
      expect(tiers.first.min, -100, reason: '左端贴 -100');
      expect(tiers.last.max, 100, reason: '右端贴 +100');
      for (var i = 1; i < tiers.length; i++) {
        expect(tiers[i].min, tiers[i - 1].max + 1,
            reason: '相邻 tier 区间无 gap(${tiers[i - 1].tier}→${tiers[i].tier})');
      }
    });
  });

  // ── R5.6 P3.4 隔离 schema 断言 ─────────────────────────────────────────────

  group('R5.6 schema 隔离(Reputation vs SectEvent)', () {
    test('ReputationSchema name 不为 SectReputation 或 Sect', () {
      expect(ReputationSchema.name, isNot(equals('SectReputation')),
          reason: 'P3.4 隔离:Reputation 与 Sect.sectReputation 字段不撞 collection name');
      expect(ReputationSchema.name, isNot(equals('Sect')),
          reason: 'Reputation 是独立 collection 不撞 Sect');
      expect(ReputationSchema.name, equals('Reputation'),
          reason: 'collection name 锁 Reputation');
    });

    test('NpcRelationSchema name 独立(不撞 Character / Sect)', () {
      expect(NpcRelationSchema.name, equals('NpcRelation'));
      expect(NpcRelationSchema.name, isNot(equals('Character')));
      expect(NpcRelationSchema.name, isNot(equals('Sect')));
    });

    test('Reputation + NpcRelation 双 collection 共存 · 不互沾', () async {
      // 同 Isar 实例并行写两表,各自 count 独立
      await isar.writeTxn(() async {
        await isar.reputations.put(Reputation()
          ..playerId = 1
          ..factionId = 'shaolin'
          ..value = 30
          ..updatedAt = DateTime(2026, 5, 25));
        await isar.npcRelations.put(NpcRelation()
          ..sourceCharacterId = 1
          ..targetCharacterId = 100
          ..type = 'foe'
          ..level = -50
          ..updatedAt = DateTime(2026, 5, 25));
      });
      expect(await isar.reputations.count(), 1);
      expect(await isar.npcRelations.count(), 1);
    });
  });

  // ── R5.7 bakeEnmityMultipliers helper ─────────────────────────────────────

  group('R5.7 bakeEnmityMultipliers helper(P1.2 §5 战斗烘焙契约)', () {
    BattleCharacter mkBC({
      required int id,
      required int teamSide,
      double apm = 1.0,
    }) {
      return BattleCharacter(
        characterId: id,
        name: 'C$id',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 1000,
        currentHp: 1000,
        maxInternalForce: 500,
        currentInternalForce: 500,
        speed: 100,
        criticalRate: 0.05,
        evasionRate: 0.05,
        defenseRate: 0.2,
        totalEquipmentAttack: 100,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const [],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: 0,
        attackPowerMultiplier: apm,
      );
    }

    test('双向对等 · 单 enemy enmity → 玩家 + enemy 同 mult SET', () async {
      final svc = NpcRelationService(isar, GameRepository.instance.numbers);
      // 玩家 vs enemyId=10 enmity -50 → 1.15
      await svc.upsert(
        sourceCharacterId: 1,
        targetCharacterId: 10,
        type: 'foe',
        level: -50,
      );
      final (left, right) = await bakeEnmityMultipliers(
        npcService: svc,
        leftTeam: [mkBC(id: 1, teamSide: 0)],
        rightTeam: [mkBC(id: 10, teamSide: 1)],
      );
      expect(left.first.attackPowerMultiplier, 1.15,
          reason: '双向对等:player 同 mult');
      expect(right.first.attackPowerMultiplier, 1.15,
          reason: '双向对等:enemy 同 mult');
    });

    test('max-across-enemies · 多 enemy 不同 enmity → player 取 max', () async {
      final svc = NpcRelationService(isar, GameRepository.instance.numbers);
      await svc.upsert(
        sourceCharacterId: 1,
        targetCharacterId: 10,
        type: 'foe',
        level: -50,
      ); // mult 1.15
      await svc.upsert(
        sourceCharacterId: 1,
        targetCharacterId: 11,
        type: 'foe',
        level: -80,
      ); // mult 1.25
      final (left, right) = await bakeEnmityMultipliers(
        npcService: svc,
        leftTeam: [mkBC(id: 1, teamSide: 0)],
        rightTeam: [mkBC(id: 10, teamSide: 1), mkBC(id: 11, teamSide: 1)],
      );
      expect(left.first.attackPowerMultiplier, 1.25,
          reason: 'player 取 max(1.15, 1.25) = 1.25');
      expect(right[0].attackPowerMultiplier, 1.15);
      expect(right[1].attackPowerMultiplier, 1.25);
    });

    test('noop · 无 enmity → 原 list 不变 mult=1.0', () async {
      final svc = NpcRelationService(isar, GameRepository.instance.numbers);
      final (left, right) = await bakeEnmityMultipliers(
        npcService: svc,
        leftTeam: [mkBC(id: 1, teamSide: 0)],
        rightTeam: [mkBC(id: 10, teamSide: 1)],
      );
      expect(left.first.attackPowerMultiplier, 1.0);
      expect(right.first.attackPowerMultiplier, 1.0);
    });

    test('player negative id (EnemyDef placeholder) → noop fallback', () async {
      final svc = NpcRelationService(isar, GameRepository.instance.numbers);
      // playerCharId 负 → 早返(EnemyDef 占位 stage 兜底)
      final (left, right) = await bakeEnmityMultipliers(
        npcService: svc,
        leftTeam: [mkBC(id: -1, teamSide: 0)],
        rightTeam: [mkBC(id: 10, teamSide: 1)],
      );
      expect(left.first.attackPowerMultiplier, 1.0);
      expect(right.first.attackPowerMultiplier, 1.0);
    });

    test('empty teams → noop return(防 first crash)', () async {
      final svc = NpcRelationService(isar, GameRepository.instance.numbers);
      final (left, right) = await bakeEnmityMultipliers(
        npcService: svc,
        leftTeam: const [],
        rightTeam: const [],
      );
      expect(left, isEmpty);
      expect(right, isEmpty);
    });
  });
}
