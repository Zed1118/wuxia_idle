import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng_provider.dart';
import 'sect_recruit_handler.dart';

/// P4.1 1.1 Q6B · Boss 战胜后招降 hook(spec
/// `p4_1_q6b_stage_boss_recruit_spec_2026-05-26.md` §3.2)。
///
/// 触发链:`stage_entry_flow:182` victory 流末段(`runEncounterHookAfterVictory` 之后)
/// 调本 hook → isBossStage + bossRecruit 非 null 守 → markTriggered 1 次性守(防刷)
/// → rng pick(`numbers.yaml stage_boss_recruit_prob` 默认 0.40)→ candidate 解 →
/// `runSectRecruitFlow` 共用 flow(Sect lazy-init + confirm dialog + writeTxn)。
///
/// **静默策略**(Q7=A · Q8=A):
///   - 玩家拒绝 → 不 markTriggered(可重战重遇)· onFallback=null 静默无 banner
///   - cap 满 → SnackBar cap full · 不 markTriggered · onFallback=null
///   - rng 不命中 → 不弹 dialog · 不 markTriggered
///   - success → markTriggered 追加 `SaveData.triggeredBossRecruitStageIds`
Future<void> runStageBossRecruitHookAfterVictory({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
}) async {
  if (!stage.isBossStage || stage.bossRecruit == null) return;

  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;

  // Q8=A 防刷 1 次性
  final save = await isar.saveDatas.get(IsarSetup.currentSlotId);
  if (save == null) return;
  if (save.triggeredBossRecruitStageIds.contains(stage.id)) return;

  // Q2=B rng pick(默认 40% · bossRecruit.baseProbability 可 stages.yaml 单 stage override)
  final probability = stage.bossRecruit!.baseProbability;
  if (ref.read(rngProvider).nextDouble() >= probability) return;

  // 解 candidate(红线 `_enforceBossRecruitRedLines` 已校 candidateRef 必存,
  // 此处保险 fallback)
  final candidate =
      GameRepository.instance.sectCandidates[stage.bossRecruit!.candidateRef];
  if (candidate == null) {
    debugPrint(
        'stage_boss_recruit_hook: candidate not loaded: ${stage.bossRecruit!.candidateRef}');
    return;
  }

  if (!context.mounted) return;
  await runSectRecruitFlow(
    context: context,
    ref: ref,
    isar: isar,
    candidate: candidate,
    onMarkTriggered: () async {
      await isar.writeTxn(() async {
        final s = await isar.saveDatas.get(IsarSetup.currentSlotId);
        if (s == null) return;
        s.triggeredBossRecruitStageIds = [
          ...s.triggeredBossRecruitStageIds,
          stage.id,
        ];
        await isar.saveDatas.put(s);
      });
    },
    onFallback: null, // Q7=A · Boss 招降无 fallback outcome(玩家拒 / cap 满静默)
    successSnackBar: UiStrings.stageBossRecruitSuccess(candidate.name),
    capFullSnackBar: UiStrings.stageBossRecruitCapFull(candidate.name),
    noSectSnackBar: UiStrings.stageBossRecruitNoSect(candidate.name),
  );
}
