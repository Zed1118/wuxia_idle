import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../shared/utils/rng_provider.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../application/encounter_service.dart';
import '../domain/encounter_def.dart';
import '../domain/encounter_event_loader.dart';
import 'encounter_dialog.dart';

/// 战斗 victory 后的奇遇触发统一 hook(Phase 4 W14-2)。
///
/// stage_entry_flow / tower_entry_flow victory 路径都调一次,共享同一逻辑:
///   1. recordKill:按敌人 school +1
///   2. evaluateTriggers:取主角 fortune,base * (1 + fortune/20) 软概率
///   3. roll 中 → markTriggered + load events 文案 + 弹 dialog
///   4. 玩家选 outcome → applyOutcome + SnackBar 摘要
///
/// 任何异常(Isar 未 ready / 无 character / 空 encounters)静默返回 +
/// debugPrint(W13 教训),不破坏 victory narrative 流。
Future<void> runEncounterHookAfterVictory({
  required BuildContext context,
  required WidgetRef ref,
  required List<TechniqueSchool> defeatedSchools,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  if (defeatedSchools.isEmpty) return;

  final encounters = GameRepository.instance.allEncounters;
  if (encounters.isEmpty) return;

  final svc = EncounterService(isar: isar);
  // W13 教训:race 防御,ensure getOrCreate
  await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
  try {
    await svc.recordKill(
      saveDataId: IsarSetup.currentSlotId,
      defeatedSchools: defeatedSchools,
    );
  } catch (e, st) {
    debugPrint('EncounterService.recordKill 失败:$e\n$st');
    return;
  }

  // 取主角(slot 0,SaveData.activeCharacterIds.first)的 fortune
  final save = await isar.saveDatas.get(0);
  final founderId = save?.activeCharacterIds.isNotEmpty == true
      ? save!.activeCharacterIds.first
      : null;
  if (founderId == null) return;
  final founder = await isar.characters.get(founderId);
  if (founder == null) return;

  EncounterDef? triggered;
  try {
    triggered = await svc.evaluateTriggers(
      saveDataId: IsarSetup.currentSlotId,
      attributes: founder.attributes,
      encounters: encounters,
      rng: ref.read(rngProvider),
      festivalToday: ref.read(todayFestivalProvider),
    );
  } catch (e, st) {
    debugPrint('EncounterService.evaluateTriggers 失败:$e\n$st');
    return;
  }
  if (triggered == null) return;

  await svc.markTriggered(
    saveDataId: IsarSetup.currentSlotId,
    encounterId: triggered.id,
  );

  if (!context.mounted) return;
  final content = await EncounterEventLoader.load(triggered.id);
  if (!context.mounted) return;
  final outcomeId = await showEncounterDialog(
    context: context,
    def: triggered,
    content: content,
  );
  if (outcomeId == null) return;

  // T24 · P1.2 §3 EncounterIntegration:reputation hook 接 caller。
  // reputationService null(Isar / GameRepository 未 ready)→ 不传 applier,
  // service 端 null guard 跳过 reputation 应用(向后兼容老路径)。
  final reputationService = ref.read(reputationServiceProvider);
  final applied = await svc.applyOutcome(
    saveDataId: IsarSetup.currentSlotId,
    encounter: triggered,
    outcomeId: outcomeId,
    // P1 #42 Phase 2:GameEvent 写入 caller-provided 上下文。
    founderCharacterId: founderId,
    encounterTitle: content.title ?? triggered.id,
    skillNameLookup: (sid) =>
        GameRepository.instance.skillDefs[sid]?.name ?? sid,
    reputationApplier:
        reputationService?.deltaApplierFromRng(ref.read(rngProvider)),
    reputationPlayerId: reputationService == null ? null : 1,
  );
  if (!context.mounted) return;
  showEncounterOutcomeBanner(context: context, applied: applied);
}
