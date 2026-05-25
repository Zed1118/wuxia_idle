import 'package:isar_community/isar.dart';

import '../../../data/numbers_config.dart';
import '../../../shared/utils/rng.dart';
import '../../encounter/application/encounter_service.dart' show ReputationDeltaApplier;
import '../domain/reputation.dart';

/// 玩家对各门派的声望服务(P1.2 §3 GDD §12.2)。
///
/// 设计纪律(沿 [SectEventService] / [FounderBuffService] 体例):
/// - Isar + NumbersConfig 注入,无全局单例依赖(易测)
/// - applyDelta 唯一写路径,clamp [-100, +100] 入仓,防越红线
/// - tierOf 纯函数,查 numbers.yaml.jianghu.reputation_tiers 7 阶映射
/// - 无 yaml `jianghu` 段时 tierOf 返 `yiLiu`(中间区间 sane fallback)
class ReputationService {
  final Isar isar;
  final NumbersConfig numbers;

  ReputationService(this.isar, this.numbers);

  /// 累积 delta + clamp [-100, +100]。
  ///
  /// upsert 语义:同 (playerId, factionId) 已存在 → 累积;不存在 → 新建。
  /// composite unique index 保(playerId, factionId)唯一,并发安全靠 writeTxn。
  Future<void> applyDelta(int playerId, String factionId, int delta) async {
    await isar.writeTxn(() async {
      final existing = await isar.reputations
          .filter()
          .playerIdEqualTo(playerId)
          .factionIdEqualTo(factionId)
          .findFirst();
      if (existing == null) {
        final rep = Reputation()
          ..playerId = playerId
          ..factionId = factionId
          ..value = delta.clamp(-100, 100)
          ..updatedAt = DateTime.now();
        await isar.reputations.put(rep);
      } else {
        existing.value = (existing.value + delta).clamp(-100, 100);
        existing.updatedAt = DateTime.now();
        await isar.reputations.put(existing);
      }
    });
  }

  /// 查 tier(numbers.yaml.jianghu.reputation_tiers 7 阶映射 · 闭区间)。
  /// 空配置 / 未命中区间 → 返 `yiLiu`(中间档兜底)。
  String tierOf(int value) {
    for (final t in numbers.jianghu.reputationTiers) {
      if (value >= t.min && value <= t.max) return t.tier;
    }
    return 'yiLiu';
  }

  /// 拉指定 player 的所有 reputation 行(UI ListView 用)。
  Future<List<Reputation>> allFor(int playerId) async {
    return isar.reputations
        .filter()
        .playerIdEqualTo(playerId)
        .findAll();
  }

  /// 查单门派当前 value(未存在 → 0,sane fallback 中间档)。
  Future<int> valueFor(int playerId, String factionId) async {
    final r = await isar.reputations
        .filter()
        .playerIdEqualTo(playerId)
        .factionIdEqualTo(factionId)
        .findFirst();
    return r?.value ?? 0;
  }

  /// 构造 [ReputationDeltaApplier] 闭包,供 [EncounterService.applyOutcome]
  /// 端 `reputationApplier:` 注入(T24 P1.2 §3 EncounterIntegration 闭环)。
  ///
  /// 闭包内每次调用从 `[deltaMin, deltaMax]` inclusive 区间抽样,落到
  /// [applyDelta](位置参数 · clamp [-100,+100])。deltaMin == deltaMax 时
  /// 无随机分支(防 nextInt(0) 抛错)。
  ///
  /// 设计纪律:
  /// - 用项目 [Rng] 抽象而非 `dart:math.Random`(test 可注入 [DefaultRng] 种子)
  /// - 闭包构造统一在 service · caller 仅一行 wire · test 端易 fake
  ReputationDeltaApplier deltaApplierFromRng(Rng rng) {
    return ({
      required int playerId,
      required String factionId,
      required int deltaMin,
      required int deltaMax,
    }) async {
      final span = deltaMax - deltaMin;
      final delta = deltaMin + (span > 0 ? rng.nextInt(span + 1) : 0);
      await applyDelta(playerId, factionId, delta);
    };
  }
}
