import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../domain/ascension_models.dart';
import 'ascend_service.dart';

part 'ascend_service_providers.g.dart';

/// [AscendService] 工厂 provider(P2.3 飞升 · spec p2_3_ascension_spec_2026-05-24)。
///
/// Isar 未 init / GameRepository 未加载 → 返 null(caller 端 if-null guard)。
/// 沿 [founderBuffService] 等 service factory 体例(nullable propagation 主干)。
@riverpod
AscendService? ascendService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  if (!GameRepository.isLoaded) return null;
  return AscendService(isar, GameRepository.instance.numbers);
}

/// 飞升 eligibility async provider(LineagePanel 飞升按钮 enable 判定)。
///
/// 5 子条件聚合(spec §3 + Q4d):founder inActive + realmAtPeak +
/// innerDemon07Cleared + mainline0605Cleared + hasDiscipleTarget。
///
/// invalidate 时机(caller 责任):
/// - SaveData.activeCharacterIds 改(收徒 / 切阵容 / 飞升完成)
/// - founder.realmTier/Layer 突破(advancement_service 升层)
/// - MainlineProgress.clearedStageIds 追加(stage_inner_demon_07 / stage_06_05
///   victory)
/// - Character/Disciple alive/lineageRole 改(本 Demo 不会动)
@riverpod
Future<AscensionEligibility> ascensionEligibility(Ref ref) async {
  final svc = ref.watch(ascendServiceProvider);
  if (svc == null) return AscensionEligibility.blocked;
  return svc.computeEligibility();
}

/// founder 装备候选列表(AscensionScreen 选件 UI 源)。
///
/// 接 founderId family,允 test 多 founder fixture。生产路径 caller 用
/// `ref.watch(heritageCandidatesProvider(save.founderCharacterId!))`。
/// Isar 未 init / founder 不存在 → 空 list。
@riverpod
Future<List<Equipment>> heritageCandidates(Ref ref, int founderId) async {
  final svc = ref.watch(ascendServiceProvider);
  if (svc == null) return const [];
  return svc.listHeritageCandidates(founderId);
}

/// 可继承 disciple 目标列表(AscensionScreen 下拉源)。
///
/// active 中 lineageRole 属弟子(disciple/senior/junior · isDiscipleRole) && isAlive=true 的弟子。order 按
/// SaveData.activeCharacterIds 顺序(UI 默认选第 1 个 = 大弟子语义)。
@riverpod
Future<List<Character>> ascensionDiscipleTargets(Ref ref) async {
  final svc = ref.watch(ascendServiceProvider);
  if (svc == null) return const [];
  return svc.listDiscipleTargets();
}
