import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/battle_strategy.dart';
import 'package:wuxia_idle/features/pvp/application/pvp_elo.dart';
import 'package:wuxia_idle/features/pvp/application/pvp_service.dart';
import 'package:wuxia_idle/features/pvp/application/pvp_sync_service.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_record.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_snapshot.dart';

/// PvpService + PvpElo + NoopPvpSync R5 单测
/// (spec p3_3_pvp_spec_2026-05-24 §7 R1 + R3 8 测):
///
///   R1.1 PvpSnapshot 字段 placeholder 体例(Phase 3 不真序列化 BattleCharacter)
///   R3.1 expectedScore 同分 / 高 +400 / 低 -400 三锚
///   R3.2 eloDelta K=32 同分 win/loss/draw 三态(±16 / 0)
///   R3.3 eloDelta K=32 高分 vs 低分(+400 win=+3 / loss=-29 标准 ELO 锚)
///   R3.4 NoopPvpSync.findOpponent 返 3 角色 mirror team(长度 + 字段 sanity)
///   R3.5 PvpService.match 整链 e2e(stub strategy 注 winner → PvpRecord 字段全设
///        + eloDelta 三态正确 + sync.uploadResult 被调)
///   R3.6 §5.4 红线:PvpStrategy 不引入 attackPowerMultiplier
///        (pvp_strategy_test R2.1 已覆盖,本测族补 PvpService 层不引段位 buff)
///   R3.8 numbers.yaml `pvp` 段真加载校验(k_factor=32 / initial=1200 / elo_window=100)
///
/// 不测 Isar 实体真持久化(memory `feedback_isar_autoincrement_test_id_collision`),
/// PvpRecord/PvpSnapshot 都用 unsaved instance 断言字段。
void main() {
  late NumbersConfig numbersCfg;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    numbersCfg = repo.numbers;
  });

  group('R1 schema · PvpSnapshot 字段 placeholder 体例', () {
    test('R1.1 snapshotJson 占位字符串(Phase 3 不真序列化,Phase 5 codec 接入)', () {
      final snap = PvpSnapshot()
        ..snapshotJson = '{"version":1,"placeholder":true}'
        ..snapshotElo = 1200
        ..takenAt = DateTime(2026, 5, 24);

      expect(snap.snapshotJson, contains('"placeholder":true'));
      expect(snap.snapshotElo, 1200);
      expect(snap.takenAt, DateTime(2026, 5, 24));
    });
  });

  group('R3 ELO · expectedScore 标准公式 (R3.1)', () {
    test('R3.1.a 同分 → 0.5', () {
      expect(expectedScore(1500, 1500), closeTo(0.5, 1e-9));
    });

    test('R3.1.b 高 +400 → ≈ 0.91(1 / (1 + 10^-1))', () {
      expect(expectedScore(1500, 1100), closeTo(0.9090909, 1e-6));
    });

    test('R3.1.c 低 -400 → ≈ 0.09(1 / (1 + 10^1))', () {
      expect(expectedScore(1500, 1900), closeTo(0.0909090, 1e-6));
    });
  });

  group('R3 ELO · eloDelta K=32 同分三态 (R3.2)', () {
    test('R3.2.a 同分 win → +16', () {
      expect(
        eloDelta(selfElo: 1500, oppElo: 1500, actualScore: 1.0, kFactor: 32),
        16,
      );
    });

    test('R3.2.b 同分 loss → -16', () {
      expect(
        eloDelta(selfElo: 1500, oppElo: 1500, actualScore: 0.0, kFactor: 32),
        -16,
      );
    });

    test('R3.2.c 同分 draw → 0', () {
      expect(
        eloDelta(selfElo: 1500, oppElo: 1500, actualScore: 0.5, kFactor: 32),
        0,
      );
    });
  });

  group('R3 ELO · eloDelta K=32 高分 vs 低分 (R3.3 标准锚)', () {
    test('R3.3.a 高分 (+400) win → +3 (32 * (1 - 0.909) ≈ 2.9 → round 3)', () {
      expect(
        eloDelta(selfElo: 1500, oppElo: 1100, actualScore: 1.0, kFactor: 32),
        3,
      );
    });

    test('R3.3.b 高分 (+400) loss → -29 (32 * (0 - 0.909) ≈ -29.1 → round -29)',
        () {
      expect(
        eloDelta(selfElo: 1500, oppElo: 1100, actualScore: 0.0, kFactor: 32),
        -29,
      );
    });
  });

  group('R3 NoopPvpSync.findOpponent 本地 mirror team (R3.4)', () {
    test('R3.4 返 3 角色 + 字段 sanity 合 §5.4 红线', () async {
      final sync = NoopPvpSync(rng: Random(42));
      final opp = await sync.findOpponent(playerElo: 1200, eloWindow: 100);

      expect(opp.length, 3, reason: '3v3 阵容');
      // §5.4 红线 sanity:每角色字段都在合理范围内
      for (final c in opp) {
        expect(c.maxHp, lessThanOrEqualTo(20000), reason: '§5.4 玩家血量上限');
        expect(c.maxInternalForce, lessThanOrEqualTo(15000),
            reason: '§5.4 内力上限');
        expect(c.totalEquipmentAttack, lessThanOrEqualTo(2000),
            reason: '§5.4 装备攻击上限');
        expect(c.criticalRate, inInclusiveRange(0.0, 0.95),
            reason: 'clamp 红线');
        expect(c.evasionRate, inInclusiveRange(0.0, 0.95),
            reason: 'clamp 红线');
        expect(c.defenseRate, inInclusiveRange(0.0, 0.95),
            reason: 'clamp 红线');
        expect(c.teamSide, 1, reason: '对手永远 teamSide=1');
        expect(c.isAlive, isTrue);
      }
      // 3 流派轮换(gangMeng/lingQiao/yinRou)
      expect(
        opp.map((c) => c.school).toSet().length,
        3,
        reason: '3 流派轮换(对应 GDD §4.4 三流派克制)',
      );
    });
  });

  group('R3 PvpService.match 整链 e2e(stub strategy 控制胜负)(R3.5)', () {
    test('R3.5.a 玩家胜 → eloDelta > 0 + PvpRecord 字段全设 + sync.uploadResult 调用',
        () async {
      final sync = _RecordingSync();
      final svc = PvpService(
        sync: sync,
        numbers: numbersCfg,
        strategyFactory: (_) => const _StubStrategy(result: BattleResult.leftWin),
      );

      final record = await svc.match(
        playerId: 100,
        playerElo: 1500,
        playerTeam: [_makeChar(characterId: 100, teamSide: 0)],
      );

      expect(record.playerId, 100);
      expect(record.playerEloBefore, 1500);
      expect(record.eloDelta, 16,
          reason: 'mirror 同 ELO + K=32 + win → +16(R3.2.a 锚)');
      expect(record.playerEloAfter, 1516);
      expect(record.winnerId, 100, reason: 'leftWin → leader=玩家');
      expect(record.matchId, isNotEmpty);
      expect(record.opponentSnapshotId, 0,
          reason: 'Phase 3 Noop 未真持久化 snapshot,占位 0');
      expect(sync.uploadResultCalls, 1,
          reason: '副作用单次上传(Noop 阶段 0 网,只验调用)');
      expect(sync.findOpponentCalls, 1);
    });

    test('R3.5.b 玩家负 → eloDelta < 0 + winnerId = 对手 leader', () async {
      final sync = _RecordingSync();
      final svc = PvpService(
        sync: sync,
        numbers: numbersCfg,
        strategyFactory: (_) => const _StubStrategy(result: BattleResult.rightWin),
      );

      final record = await svc.match(
        playerId: 100,
        playerElo: 1500,
        playerTeam: [_makeChar(characterId: 100, teamSide: 0)],
      );

      expect(record.eloDelta, -16, reason: '同 ELO + loss → -16');
      expect(record.playerEloAfter, 1484);
      expect(record.winnerId, isNot(100),
          reason: 'rightWin → leader=对手(NoopPvpSync 生成的负 id)');
      expect(record.winnerId, lessThan(0), reason: '对手 id 为负数(NoopPvpSync 体例)');
    });

    test('R3.5.c 平局 → eloDelta = 0 + winnerId = null', () async {
      final sync = _RecordingSync();
      final svc = PvpService(
        sync: sync,
        numbers: numbersCfg,
        strategyFactory: (_) => const _StubStrategy(result: BattleResult.draw),
      );

      final record = await svc.match(
        playerId: 100,
        playerElo: 1500,
        playerTeam: [_makeChar(characterId: 100, teamSide: 0)],
      );

      expect(record.eloDelta, 0);
      expect(record.playerEloAfter, 1500);
      expect(record.winnerId, isNull);
    });
  });

  group('R3.6 §5.4 红线 · PvpStrategy/PvpService 0 段位 buff 入战斗', () {
    test('NoopPvpSync.findOpponent 生成的 mirror BattleCharacter '
        'attackPowerMultiplier 默认 1.0(无 ELO buff 加成)', () async {
      final sync = NoopPvpSync();
      final opp = await sync.findOpponent(playerElo: 1500, eloWindow: 100);
      for (final c in opp) {
        expect(c.attackPowerMultiplier, closeTo(1.0, 1e-9),
            reason: 'R3.6 §5.4 红线:PVP 不引入段位 buff');
      }
    });
  });

  group('R3.8 numbers.yaml pvp 段真加载(Phase 2 schema 锚 + dynamic 取值路径)', () {
    test('pvp.elo.k_factor=32 / initial=1200 / draw_factor=0.5', () {
      final pvp = PvpService.pvpCfgFor(numbersCfg);
      final elo = pvp['elo'] as Map;
      expect((elo['k_factor'] as num).toInt(), 32);
      expect((elo['initial'] as num).toInt(), 1200);
      expect((elo['draw_factor'] as num).toDouble(), closeTo(0.5, 1e-9));
    });

    test('pvp.match_range.elo_window=100 / fallback_window=300', () {
      final pvp = PvpService.pvpCfgFor(numbersCfg);
      final mr = pvp['match_range'] as Map;
      expect((mr['elo_window'] as num).toInt(), 100);
      expect((mr['fallback_window'] as num).toInt(), 300);
    });

    test('pvp.sync.impl=noop / snapshot_ttl_hours=168', () {
      final pvp = PvpService.pvpCfgFor(numbersCfg);
      final sync = pvp['sync'] as Map;
      expect(sync['impl'], 'noop',
          reason: 'Phase 3 NoopPvpSync · Phase 5 切 supabase');
      expect((sync['snapshot_ttl_hours'] as num).toInt(), 168);
    });
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Test fixtures
// ───────────────────────────────────────────────────────────────────────────

BattleCharacter _makeChar({
  required int characterId,
  required int teamSide,
  int slotIndex = 0,
}) =>
    BattleCharacter(
      characterId: characterId,
      name: teamSide == 0 ? '玩家' : '对手',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.jingTong,
      school: TechniqueSchool.gangMeng,
      maxHp: 8000,
      currentHp: 8000,
      maxInternalForce: 5000,
      currentInternalForce: 5000,
      speed: 200,
      criticalRate: 0.10,
      evasionRate: 0.05,
      defenseRate: 0.20,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
    );

/// Stub BattleStrategy:runToEnd 直接返指定 result,不跑真战斗。
///
/// 用于 R3.5 三态(leftWin/rightWin/draw)控制 eloDelta 符号 + winnerId,
/// 避免引入完整 GameRepository skill 库的 e2e 战斗 dep。
class _StubStrategy implements BattleStrategy {
  final BattleResult result;

  const _StubStrategy({required this.result});

  @override
  BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  }) =>
      initial.copyWith(result: result);

  @override
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) =>
      state.copyWith(result: result);

  @override
  BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate,
  ) =>
      state;
}

/// 计调 sync 服务:R3.5 验证 findOpponent + uploadResult 真被调用。
///
/// uploadSnapshot 不验(本 Phase PvpService.match 不调,Phase 5 异步流程才调)。
class _RecordingSync implements PvpSyncService {
  int findOpponentCalls = 0;
  int uploadResultCalls = 0;
  int uploadSnapshotCalls = 0;

  @override
  Future<List<BattleCharacter>> findOpponent({
    required int playerElo,
    required int eloWindow,
  }) async {
    findOpponentCalls++;
    // 返一个固定 mirror 团(避走 NoopPvpSync 内部 _makeMirror,纯 service 层验证)
    return const [
      BattleCharacter(
        characterId: -10001,
        name: '对手#1',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.jingTong,
        school: TechniqueSchool.gangMeng,
        maxHp: 8000,
        currentHp: 8000,
        maxInternalForce: 5000,
        currentInternalForce: 5000,
        speed: 200,
        criticalRate: 0.10,
        evasionRate: 0.05,
        defenseRate: 0.20,
        totalEquipmentAttack: 1500,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: [],
        skillCooldowns: {},
        activeBuffs: [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: 0,
      ),
    ];
  }

  @override
  Future<void> uploadResult(PvpRecord record) async {
    uploadResultCalls++;
  }

  @override
  Future<void> uploadSnapshot(PvpSnapshot snapshot) async {
    uploadSnapshotCalls++;
  }
}
