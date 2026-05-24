import 'package:isar_community/isar.dart';

import '../../../data/numbers_config.dart';
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
}
