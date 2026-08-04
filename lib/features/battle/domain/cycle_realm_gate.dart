import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/numbers_config.dart';

/// 批 B 周目解锁门槛（spec 2026-08-01-tower-extension 拍板 #5：
/// 「周目解锁绑玩家境界门槛」，防低境界玩家撞差 3 阶硬墙）。
///
/// 纯函数层，4 个支线入口（轻功对决 / 群战守城 / 断魂庄 / 远征）共用；
/// 主线周目不推进境界故不套此门槛，爬塔走扩层（拍板 #3）不经此处。
///
/// 语义：可挑战周目上限 = 顺序解锁（通了 cycle N−1 才可开 N，主线体例的
/// 自由回选——已解锁的低周目永远可选）∩ 配置上限 [RealmAdvanceConfig.maxCycle]
/// ∩ 境界门槛（cycle ≥ 2 须出战最高境界 ≥ 推进后敌最高境界 − margin）。
class CycleRealmGate {
  const CycleRealmGate._();

  /// cycle 的境界门槛判定。
  ///
  /// [playerMaxTier] 出战编成中最高境界；[baseEnemyMaxTier] 该入口敌人
  /// yaml 原值最高境界（静态锚，推进前）。
  static bool meetsRealmGate({
    required int cycle,
    required RealmTier playerMaxTier,
    required RealmTier baseEnemyMaxTier,
    required RealmAdvanceConfig ra,
  }) {
    if (cycle <= 1) return true; // cycle1 无门槛（既有内容不回锁）
    final advancedIndex = baseEnemyMaxTier.index + ra.tiersFor(cycle);
    final effIndex = advancedIndex >= RealmTier.wuSheng.index
        ? RealmTier.wuSheng.index
        : advancedIndex;
    return playerMaxTier.index >= effIndex - ra.unlockRealmMargin;
  }

  /// 可挑战周目上限（1..maxCycle）。
  ///
  /// [clearedCyclesMax] 该入口已全通的最高周目（0 = 未通过 cycle1）。
  /// 逐级判定：cycle N 可选 ⇔ 已通 N−1 且过境界门槛；任一级不满足即封顶。
  static int unlockedCycleCap({
    required int clearedCyclesMax,
    required RealmTier playerMaxTier,
    required RealmTier baseEnemyMaxTier,
    required RealmAdvanceConfig ra,
  }) {
    var cap = 1;
    for (var c = 2; c <= ra.maxCycle; c++) {
      if (clearedCyclesMax < c - 1) break; // 顺序解锁
      if (!meetsRealmGate(
        cycle: c,
        playerMaxTier: playerMaxTier,
        baseEnemyMaxTier: baseEnemyMaxTier,
        ra: ra,
      )) {
        break;
      }
      cap = c;
    }
    return cap;
  }

  /// 远征深度里程碑 → 「已通周目」等价值（2026-08-04 拍板：远征无终点，
  /// `baicaoMaxDepth ≥ milestones[i]` 视作已通 cycle i+1，可开 cycle i+2）。
  /// 折算值直接喂 [unlockedCycleCap] 的 clearedCyclesMax，复用顺序+境界门槛。
  static int expeditionClearedEquivalent({
    required int maxDepth,
    required List<int> milestones,
  }) {
    var cleared = 0;
    for (final m in milestones) {
      if (maxDepth >= m) {
        cleared++;
      } else {
        break;
      }
    }
    return cleared;
  }

  /// 入口敌人 yaml 原值最高境界（静态锚，供 [meetsRealmGate] 的
  /// baseEnemyMaxTier；空集返学徒）。
  static RealmTier maxEnemyTierOf(Iterable<EnemyDef> enemies) {
    var max = RealmTier.xueTu;
    for (final e in enemies) {
      if (e.realmTier.index > max.index) max = e.realmTier;
    }
    return max;
  }
}
