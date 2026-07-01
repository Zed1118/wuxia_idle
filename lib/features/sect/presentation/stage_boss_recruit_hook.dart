import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/narrative_loader.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng.dart';
import '../../../shared/utils/rng_provider.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import 'sect_recruit_handler.dart';

typedef StageBossRecruitFlow =
    Future<void> Function({
      required BuildContext context,
      required WidgetRef? ref,
      required Isar isar,
      required SectCandidateDef candidate,
      required Future<void> Function() onMarkTriggered,
      required Future<void> Function()? onFallback,
      required String successSnackBar,
      required String capFullSnackBar,
      required String noSectSnackBar,
    });

typedef StageBossNarrativeLoader = Future<NarrativeContent> Function(String id);

/// 1.1 · Boss 战败后收降 hook(stageBossFailRecoverProb 0.30)。
///
/// 触发链:`stage_entry_flow` defeat 路径末段（defeat narrative 之后、return 之前）。
/// 守卫 / 防刷 / candidate 解 / recruit flow 与 victory hook 同源,仅概率不同:
///   - victory: `bossRecruit.baseProbability`(per-stage · 默认 0.40)
///   - defeat:  `numbers.sectManagement.recruit.stageBossFailRecoverProb`(全局 0.30)
/// 共用 `triggeredBossRecruitStageIds` 防刷(victory/defeat 互斥 · 先触发的 mark)。
Future<void> runStageBossFailRecoverHookAfterDefeat({
  required BuildContext context,
  WidgetRef? ref,
  required StageDef stage,
  Rng? rng,
  StageBossRecruitFlow? recruitFlow,
  StageBossNarrativeLoader? loadNarrative,
}) async {
  assert(ref != null || rng != null, 'ref or rng is required');
  if (!stage.isBossStage || stage.bossRecruit == null) return;

  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;

  final save = await _currentSaveData(isar);
  if (save == null) return;
  if (save.triggeredBossRecruitStageIds.contains(stage.id)) return;

  final probability = GameRepository
      .instance
      .numbers
      .sectManagement
      .recruit
      .stageBossFailRecoverProb;
  final Rng rollRng = rng ?? ref!.read(rngProvider);
  if (rollRng.nextDouble() >= probability) return;

  final candidate =
      GameRepository.instance.sectCandidates[stage.bossRecruit!.candidateRef];
  if (candidate == null) {
    debugPrint(
      'stage_boss_fail_recover_hook: candidate not loaded: '
      '${stage.bossRecruit!.candidateRef}',
    );
    return;
  }

  final narrativeId = '${stage.id}_boss_fail_recover';
  final narrative = await (loadNarrative ?? NarrativeLoader.load)(narrativeId);
  if (!narrative.isPlaceholder) {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: narrative,
          fallbackTitle: UiStrings.stageBossFailRecoverFallbackTitle(
            stage.name,
          ),
        ),
      ),
    );
  }

  if (!context.mounted) return;
  if (recruitFlow != null) {
    await recruitFlow(
      context: context,
      ref: ref,
      isar: isar,
      candidate: candidate,
      onMarkTriggered: () async {
        await isar.writeTxn(() async {
          final s = await _currentSaveData(isar);
          if (s == null) return;
          s.triggeredBossRecruitStageIds = [
            ...s.triggeredBossRecruitStageIds,
            stage.id,
          ];
          await isar.saveDatas.put(s);
        });
      },
      onFallback: null,
      successSnackBar: UiStrings.stageBossFailRecoverSuccess(candidate.name),
      capFullSnackBar: UiStrings.stageBossFailRecoverCapFull(candidate.name),
      noSectSnackBar: UiStrings.stageBossFailRecoverNoSect(candidate.name),
    );
    return;
  }
  if (ref == null) return;
  await runSectRecruitFlow(
    context: context,
    ref: ref,
    isar: isar,
    candidate: candidate,
    onMarkTriggered: () async {
      await isar.writeTxn(() async {
        final s = await _currentSaveData(isar);
        if (s == null) return;
        s.triggeredBossRecruitStageIds = [
          ...s.triggeredBossRecruitStageIds,
          stage.id,
        ];
        await isar.saveDatas.put(s);
      });
    },
    onFallback: null,
    successSnackBar: UiStrings.stageBossFailRecoverSuccess(candidate.name),
    capFullSnackBar: UiStrings.stageBossFailRecoverCapFull(candidate.name),
    noSectSnackBar: UiStrings.stageBossFailRecoverNoSect(candidate.name),
  );
}

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
  WidgetRef? ref,
  required StageDef stage,
  Rng? rng,
  StageBossRecruitFlow? recruitFlow,
  StageBossNarrativeLoader? loadNarrative,
}) async {
  assert(ref != null || rng != null, 'ref or rng is required');
  if (!stage.isBossStage || stage.bossRecruit == null) return;

  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;

  // Q8=A 防刷 1 次性
  final save = await _currentSaveData(isar);
  if (save == null) return;
  if (save.triggeredBossRecruitStageIds.contains(stage.id)) return;

  // Q2=B rng pick(默认 40% · bossRecruit.baseProbability 可 stages.yaml 单 stage override)
  final probability = stage.bossRecruit!.baseProbability;
  final Rng rollRng = rng ?? ref!.read(rngProvider);
  if (rollRng.nextDouble() >= probability) return;

  // 解 candidate(红线 `_enforceBossRecruitRedLines` 已校 candidateRef 必存,
  // 此处保险 fallback)
  final candidate =
      GameRepository.instance.sectCandidates[stage.bossRecruit!.candidateRef];
  if (candidate == null) {
    debugPrint(
      'stage_boss_recruit_hook: candidate not loaded: ${stage.bossRecruit!.candidateRef}',
    );
    return;
  }

  // 展示招降叙事(data/narratives/stages/<stageId>_boss_recruit.yaml)
  final narrativeId = '${stage.id}_boss_recruit';
  final narrative = await (loadNarrative ?? NarrativeLoader.load)(narrativeId);
  if (!narrative.isPlaceholder) {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: narrative,
          fallbackTitle: UiStrings.stageBossRecruitFallbackTitle(stage.name),
        ),
      ),
    );
  }

  if (!context.mounted) return;
  if (recruitFlow != null) {
    await recruitFlow(
      context: context,
      ref: ref,
      isar: isar,
      candidate: candidate,
      onMarkTriggered: () async {
        await isar.writeTxn(() async {
          final s = await _currentSaveData(isar);
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
    return;
  }
  if (ref == null) return;
  await runSectRecruitFlow(
    context: context,
    ref: ref,
    isar: isar,
    candidate: candidate,
    onMarkTriggered: () async {
      await isar.writeTxn(() async {
        final s = await _currentSaveData(isar);
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

Future<SaveData?> _currentSaveData(Isar isar) => isar.saveDatas.get(0);
