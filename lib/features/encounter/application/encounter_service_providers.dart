import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_setup.dart';
import '../../../providers/isar_provider.dart';
import '../domain/encounter_progress.dart';
import 'encounter_service.dart';

part 'encounter_service_providers.g.dart';

/// [EncounterService] provider(Phase 4 W14-1,Phase 5 #3 第 5 批 I 抽离)。
@riverpod
EncounterService? encounterService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : EncounterService(isar: isarInstance);
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
