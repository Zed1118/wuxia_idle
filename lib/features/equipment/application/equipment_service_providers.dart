import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/isar_provider.dart';
import 'enhancement_service.dart';
import 'forging_service.dart';

part 'equipment_service_providers.g.dart';

// =========================================================================
// 装备系 service providers（Phase 5 #3 第 5 批 C 任务从 isar_provider 抽离）
//
// 沿 nullable propagation 链:isar 为 null 时 service 也为 null,widget 端
// `service == null` 短路。从 isar_provider.dart 迁来,理由是基础设施层
// (providers/)不应反向 import 应用层(features/equipment/application/)。
// =========================================================================

/// [EnhancementService] provider。Isar 未 init 时为 null,widget 端 `_persist`
/// 用 `service == null` 短路（替代旧的 `Isar.getInstance(_isarInstanceName)` guard）。
@riverpod
EnhancementService? enhancementService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : EnhancementService(isar: isarInstance);
}

/// [ForgingService] provider。同 [enhancementServiceProvider] 模式。
@riverpod
ForgingService? forgingService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : ForgingService(isar: isarInstance);
}
