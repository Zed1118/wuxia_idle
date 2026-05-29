import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_provider.dart';
import 'insight_exchange_service.dart';

part 'insight_exchange_service_providers.g.dart';

/// [InsightExchangeService] provider(根因A 2026-05-29)。
///
/// 沿 nullable propagation 链:isar 为 null 时 service 也为 null,widget 端
/// `service == null` 短路返回(沿 dispel_service_providers.dart 体例)。
@riverpod
InsightExchangeService? insightExchangeService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : InsightExchangeService(isarInstance);
}
