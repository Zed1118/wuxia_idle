import '../../../shared/strings.dart';
import '../domain/battle_state.dart';
import '../domain/enum_localizations.dart';

/// 第七阶段批二 ①：Boss 转阶段题字文本派生（纯函数，便于单测）。
///
/// 非转阶段动作（`bossPhaseTransitionTo == null`）→ 返回 null（调用方据此跳过表现）。
/// 否则：优先用 [BattleAction.bossPhaseTitleKey] 经 [UiStrings.bossPhaseTitle] 解析；
/// key 为 null / 未知（映射空串）→ 回落 [EnumL10n.bossPhaseTransition] 通用文案。
///
/// 纯读 action 元数据 + bossName，不写 BattleState、不参与战斗结算（守 §5.4）。
String? bossPhaseTitleFor(BattleAction action, String bossName) {
  final phase = action.bossPhaseTransitionTo;
  if (phase == null) return null;
  final mapped = UiStrings.bossPhaseTitle(action.bossPhaseTitleKey);
  if (mapped.isNotEmpty) return mapped;
  return EnumL10n.bossPhaseTransition(bossName, phase);
}
