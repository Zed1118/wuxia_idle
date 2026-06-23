import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../application/milestone_equipment_grant_service.dart';

/// F1 里程碑装备 post-victory hook(镜像 runDiscipleJoinHookAfterVictory)。
///
/// 群战/心魔关首通终点关(stage_mass_battle_05 / stage_inner_demon_07)→ 按
/// numbers.yaml `milestone_equipment_grants` 映射授予 special 装备进背包。
/// F1 范围内静默入袋,无授予特效(授予提示/动画归 D 体验批)。

/// tag → 来历串。新增里程碑装备时在此补一行。
String _obtainedFromForTag(String tag) {
  switch (tag) {
    case 'mass_battle_merit':
      return UiStrings.dropSourceMassBattleMerit;
    case 'inner_demon_reward':
      return UiStrings.dropSourceInnerDemonReward;
    case 'ascension_reward':
      return UiStrings.dropSourceAscensionReward;
    default:
      return UiStrings.dropSourceStageDefault;
  }
}

/// 纯逻辑(可单测):若 [clearedStageId] 是里程碑触发关,按映射 tag 授予装备。
/// 返回新授予 defId(非里程碑关 / 已授予过 / repo 未载 → 空)。
Future<List<String>> grantMilestoneForClearedStage({
  required Isar isar,
  required String clearedStageId,
}) async {
  if (!GameRepository.isLoaded) return const [];
  final tag =
      GameRepository.instance.numbers.milestoneEquipmentGrants[clearedStageId];
  if (tag == null) return const [];
  final svc = MilestoneEquipmentGrantService(isar: isar);
  return svc.grantForTag(tag, obtainedFrom: _obtainedFromForTag(tag));
}

/// post-victory hook 包装。Isar 未 ready → no-op 不阻塞胜利流。
Future<void> runMilestoneGrantHookAfterVictory({
  required String stageId,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  await grantMilestoneForClearedStage(isar: isar, clearedStageId: stageId);
}
