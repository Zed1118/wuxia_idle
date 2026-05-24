import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/battle_providers.dart' show numbersConfigProvider;
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../domain/reputation.dart';
import 'npc_relation_service.dart';
import 'reputation_service.dart';

part 'jianghu_providers.g.dart';

/// [ReputationService] provider(P1.2 §3)。
/// Isar 未 init / GameRepository 未 load → null,caller 兜底文案不抛错。
@riverpod
ReputationService? reputationService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  if (!GameRepository.isLoaded) return null;
  final numbers = ref.watch(numbersConfigProvider);
  return ReputationService(isar, numbers);
}

/// [NpcRelationService] provider(P1.2 §3)。
@riverpod
NpcRelationService? npcRelationService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  if (!GameRepository.isLoaded) return null;
  final numbers = ref.watch(numbersConfigProvider);
  return NpcRelationService(isar, numbers);
}

/// 当前玩家(Demo 单 save · playerId=1)的所有 reputation 行。
/// UI ReputationPanelScreen ListView 用 · invalidate 时机:applyDelta 之后
/// (encounter resolve / stage_boss_kill hook caller 端负责)。
@riverpod
Future<List<Reputation>> reputationsForCurrentPlayer(Ref ref) async {
  final svc = ref.watch(reputationServiceProvider);
  if (svc == null) return const [];
  return svc.allFor(1);
}
