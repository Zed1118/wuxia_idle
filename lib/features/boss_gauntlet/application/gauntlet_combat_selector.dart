import 'phase0a_gauntlet_gate.dart';

/// 断魂庄战斗路径（§7.4 路线 C 终态替换的前置灰度分叉口径）。
///
/// - [legacy3v3]：删除前的紧急回退路径。
/// - [phase0a]：路线 C 默认的 Phase 0A 单角色续传。
enum GauntletCombatPath { legacy3v3, phase0a }

/// 断魂庄战斗路径选择器（供主线消费）。
///
/// 生产默认仅单成员会话选 [GauntletCombatPath.phase0a]。历史
/// 2–3 人在途会话由入口恢复事务先行退役；本选择器仅在旧引擎
/// 删除前保留可逆回退契约。
///
/// [memberCount] 须 ∈ [1,3]（断魂庄队伍约束，见 `GauntletService.enter`）；
/// 非法成员数 fail-fast（`StateError`），不静默回落旧路径。选择器不持有
/// runner/Isar，只产出路径枚举供调用方装配实际战斗协作者。
GauntletCombatPath gauntletCombatPathFor({required int memberCount}) {
  if (memberCount < 1 || memberCount > 3) {
    throw StateError('断魂庄战斗路径：队伍须 1-3 人，got $memberCount');
  }
  return Phase0aGauntletGate.shouldUsePhase0a(memberCount: memberCount)
      ? GauntletCombatPath.phase0a
      : GauntletCombatPath.legacy3v3;
}
