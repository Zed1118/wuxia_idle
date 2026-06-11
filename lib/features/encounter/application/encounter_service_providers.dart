import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/isar_provider.dart';
import '../domain/encounter_progress.dart';
import 'encounter_service.dart';

part 'encounter_service_providers.g.dart';

/// [EncounterService] provider(Phase 4 W14-1,Phase 5 #3 第 5 批 I 抽离)。
@riverpod
EncounterService? encounterService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  if (isarInstance == null) return null;
  final n = GameRepository.instance.numbers;
  return EncounterService(
    isar: isarInstance,
    attributeGainCap: n.adventureAttributeLifetimeCap,
    fortuneSensitivity: n.encounterFortuneSensitivity,
  );
}

/// 当前存档 [EncounterProgress] 行(C-W14-3-A,I 抽离)。
///
/// UI 装备奇遇 skill 面板用,装/卸后 caller 调
/// `ref.invalidate(currentEncounterProgressProvider)` 刷新。返回 null 表示
/// Isar 未 init 或 getOrCreate 未跑过(应由 caller 兜底文案,不抛错)。
@riverpod
Future<EncounterProgress?> currentEncounterProgress(Ref ref) async {
  final isarInstance = ref.watch(isarProvider);
  if (isarInstance == null) return null;
  return isarInstance.encounterProgress
      .filter()
      .saveDataIdEqualTo(IsarSetup.currentSlotId)
      .findFirst();
}

/// 波A A4 来源统一:已解锁招式 id 集,单一真相源 =
/// `SaveData.skillUnlockProgress`(奇遇/真解/残页全走此池)。
/// 解锁类操作后 caller 调 `ref.invalidate(unlockedSkillIdSetProvider)` 刷新。
@riverpod
Future<Set<String>> unlockedSkillIdSet(Ref ref) async {
  final isarInstance = ref.watch(isarProvider);
  if (isarInstance == null) return const {};
  final save = await isarInstance.saveDatas.get(0);
  if (save == null) return const {};
  return {
    for (final e in save.skillUnlockProgress)
      if (e.unlocked) e.skillId,
  };
}
