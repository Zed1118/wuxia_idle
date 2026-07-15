import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../data/isar_provider.dart';
import 'lineup_service.dart';

part 'lineup_providers.g.dart';

/// [LineupService] provider(出战编成批 · 2026-07-14)。
///
/// 沿 nullable propagation 链:isar 为 null 时 service 也为 null,widget 端
/// `service == null` 短路返回(沿 technique_learn_flow_service_providers 体例)。
@riverpod
LineupService? lineupService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : LineupService(isarInstance);
}

/// 替补池 provider:全部可上场的 inactive 角色(口径见
/// [LineupService.loadReserve] doc)。编成写路径后由
/// `invalidateAfterLineupChange` 统一失效。
@riverpod
Future<List<Character>> lineupReserve(Ref ref) async {
  final service = ref.watch(lineupServiceProvider);
  if (service == null) return const [];
  return service.loadReserve();
}
