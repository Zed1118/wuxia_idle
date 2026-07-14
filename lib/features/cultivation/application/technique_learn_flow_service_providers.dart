import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_provider.dart';
import 'technique_learn_flow_service.dart';

part 'technique_learn_flow_service_providers.g.dart';

/// [TechniqueLearnFlowService] provider（心法学习闭环 · 2026-07-14）。
///
/// 沿 nullable propagation 链：isar 为 null 时 service 也为 null，widget 端
/// `service == null` 短路返回（沿 insight_exchange_service_providers.dart 体例）。
@riverpod
TechniqueLearnFlowService? techniqueLearnFlowService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : TechniqueLearnFlowService(isarInstance);
}
