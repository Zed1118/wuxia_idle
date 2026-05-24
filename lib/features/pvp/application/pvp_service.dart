import 'dart:math';

import '../../../data/numbers_config.dart';
import '../../battle/domain/battle_state.dart';
import '../../battle/domain/strategy/battle_strategy.dart';
import '../domain/pvp_record.dart';
import '../domain/strategy/pvp_strategy.dart';
import 'pvp_elo.dart';
import 'pvp_sync_service.dart';

/// PVP 单场对决 application service(1.0 P3.3 §12.3,spec p3_3_pvp_spec_2026-05-24 §4)。
///
/// **流程**:
///   1. [PvpSyncService.findOpponent] 拉对手阵容(Noop = 本地 mirror / Supabase = 远端快照)
///   2. 构造 [PvpStrategy] + 初始 BattleState,委派 DefaultGroundStrategy 跑完整场
///   3. 按胜负 + ELO 标准公式算 delta(K factor 从 numbers.yaml `pvp.elo.k_factor` 取)
///   4. 装 [PvpRecord] + 上传(Noop 阶段 0 副作用)
///
/// **数值取值**(spec §9 决议):
///   - 本 Phase 走 `numbers.raw['pvp']` dynamic map 取值,**不加 PvpDef 强类型化**,
///     避 T13/T14 双线撞 `numbers_config.dart` cherry-pick conflict;Phase 4+ 升强
///     类型时统一做(memory `feedback_avoid_over_engineer_abstraction`)。
///
/// **测试 seam**:[strategyFactory] 可选注入,默认 `PvpStrategy.new`;R5 测族里
/// 注 stub strategy 控制胜负不必跑真战斗,沿 mass_battle_strategy_test 体例。
class PvpService {
  final PvpSyncService sync;
  final NumbersConfig numbers;

  /// 测试 seam:给定对手 team 返战斗 strategy 实例。默认 [PvpStrategy.new]。
  final BattleStrategy Function(List<BattleCharacter> opponentTeam)
      strategyFactory;

  PvpService({
    required this.sync,
    required this.numbers,
    BattleStrategy Function(List<BattleCharacter>)? strategyFactory,
  }) : strategyFactory = strategyFactory ??
            ((opponentTeam) => PvpStrategy(opponentTeam: opponentTeam));

  /// 单场异步对决主入口。
  ///
  /// [playerId]:本地玩家 character id(写 [PvpRecord.playerId])
  /// [playerElo]:战前玩家 ELO(写 [PvpRecord.playerEloBefore])
  /// [playerTeam]:玩家出战阵容(注入 BattleState.leftTeam)
  /// [rng]:测试可注入种子;默认 [Random.new]
  ///
  /// 返带 ELO delta + winnerId 的 [PvpRecord](unsaved,caller 决定是否入 Isar)。
  Future<PvpRecord> match({
    required int playerId,
    required int playerElo,
    required List<BattleCharacter> playerTeam,
    Random? rng,
  }) async {
    final pvpCfg = pvpCfgFor(numbers);
    final matchRange = pvpCfg['match_range'] as Map;
    final eloWindow = (matchRange['elo_window'] as num).toInt();

    final opponentTeam = await sync.findOpponent(
      playerElo: playerElo,
      eloWindow: eloWindow,
    );

    final strategy = strategyFactory(opponentTeam);
    final initial = BattleState.initial(
      leftTeam: playerTeam,
      rightTeam: opponentTeam,
    );
    final finalState =
        strategy.runToEnd(initial, numbers, rng: rng ?? Random());

    final result = finalState.result ?? BattleResult.draw;
    final actual = _actualScoreOf(result);

    final eloCfg = pvpCfg['elo'] as Map;
    final kFactor = (eloCfg['k_factor'] as num).toInt();
    // Noop 阶段对手 ELO = 玩家 ELO(mirror 同段);Phase 5 真接入时从快照拿
    // opponent.snapshotElo 真值。本 Phase 简化体例确定不引入新字段。
    final opponentElo = playerElo;

    final delta = eloDelta(
      selfElo: playerElo,
      oppElo: opponentElo,
      actualScore: actual,
      kFactor: kFactor,
    );

    final record = PvpRecord()
      ..matchId = _newMatchId(rng)
      ..playerId = playerId
      ..opponentSnapshotId = 0
      ..leftSnapshotId = 0
      ..winnerId = _winnerIdFromResult(result, playerTeam, opponentTeam)
      ..playerEloBefore = playerElo
      ..playerEloAfter = playerElo + delta
      ..eloDelta = delta
      ..timestamp = DateTime.now();

    await sync.uploadResult(record);
    return record;
  }

  /// numbers.raw['pvp'] dynamic map 取值(spec §9 简化路径,避撞 numbers_config 强类型)。
  ///
  /// 公开 static 便测试直接断言 dynamic 读路径合法,Phase 4+ 强类型化时统一替换。
  static Map pvpCfgFor(NumbersConfig n) {
    final pvp = n.raw['pvp'];
    if (pvp is! Map) {
      throw StateError(
        'numbers.yaml 缺 pvp 段(P3.3 Phase 2 schema 应已落)',
      );
    }
    return pvp;
  }

  /// BattleResult → ELO actual score(GDD §5.4 三态):leftWin=1.0 / rightWin=0.0 / draw=0.5。
  ///
  /// 约定 leftTeam = 玩家方(沿 stage_battle_setup / mass_battle 体例)。
  static double _actualScoreOf(BattleResult r) {
    switch (r) {
      case BattleResult.leftWin:
        return 1.0;
      case BattleResult.rightWin:
        return 0.0;
      case BattleResult.draw:
        return 0.5;
    }
  }

  /// PvpRecord.winnerId(GDD §5.5):leader = team[0].characterId;draw → null。
  static int? _winnerIdFromResult(
    BattleResult r,
    List<BattleCharacter> left,
    List<BattleCharacter> right,
  ) {
    switch (r) {
      case BattleResult.leftWin:
        return left.isEmpty ? null : left.first.characterId;
      case BattleResult.rightWin:
        return right.isEmpty ? null : right.first.characterId;
      case BattleResult.draw:
        return null;
    }
  }

  /// 战例唯一 id 生成器。Phase 5+ Supabase 接入时可换 uuid pkg(`uuid: ^4.x`);
  /// Demo Noop 阶段用 timestamp + rand 后缀够用(单端 + 0 网,collision 概率忽略)。
  String _newMatchId(Random? rng) {
    final r = rng ?? Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final suffix = r.nextInt(0xffffff).toRadixString(16).padLeft(6, '0');
    return '$ts-$suffix';
  }
}
