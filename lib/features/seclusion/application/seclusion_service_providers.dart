import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../encounter/application/encounter_service.dart';
import 'seclusion_service.dart';

part 'seclusion_service_providers.g.dart';

/// [SeclusionService] provider(Phase 5 #3 第 5 批 I 任务从 isar_provider 抽离)。
///
/// C-W14-2:同时注入 [EncounterService],让 [SeclusionService.completeRetreat]
/// 在 actualHours 完成后能喂 biome/weather 累计分钟给奇遇系统。跨 feature
/// 引用 encounter/application/encounter_service 在应用层是允许的(应用层间互引 OK)。
@riverpod
SeclusionService? seclusionService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  if (isarInstance == null) return null;
  return SeclusionService(
    isar: isarInstance,
    encounterService: EncounterService(
      isar: isarInstance,
      attributeGainCap:
          GameRepository.instance.numbers.adventureAttributeLifetimeCap,
      fortuneSensitivity:
          GameRepository.instance.numbers.encounterFortuneSensitivity,
    ),
  );
}
