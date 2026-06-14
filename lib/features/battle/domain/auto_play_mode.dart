/// 战斗进入模式(战斗交互重做 Phase 3,2026-06-14)。
///
/// 旧「半手动单步 / 录制回放」四态已废弃(spec §B:战斗永远自动连续播放,
/// 不再二分「自动 vs 手动」)。新模型二元:战斗永远 Timer 自动流转,本枚举
/// 只决定玩家「能否随时拖招干预」。真实入口(`_StageBattleHost` /
/// `_TowerBattleHost`)进战斗前由 [resolveAutoPlayMode] 算出本场模式 →
/// BattleScreen 据此决定是否挂拖招层(Phase 4 拖招交互消费)。
enum AutoPlayMode {
  /// 纯挂机自动:Timer 自动连续播放,不挂拖招层(纯挂机体验)。
  auto,

  /// 允许拖招:仍自动连续播放,但挂拖招干预层(Phase 4 玩家可随时拖招)。
  interactive,
}

/// 入口决策。`autoWanted = override ?? globalDefault`(true = 纯挂机自动)。
///
/// - [override]:per-stage 每关记忆(SharedPreferences,语义重定义:`true`=纯
///   挂机自动 / `false`=允许拖招 / `null`=随全局)。
/// - [globalDefault]:全局 `GameplaySettings.autoPlayDefault`(默认 true)。
AutoPlayMode resolveAutoPlayMode({
  required bool? override,
  required bool globalDefault,
}) =>
    (override ?? globalDefault) ? AutoPlayMode.auto : AutoPlayMode.interactive;
