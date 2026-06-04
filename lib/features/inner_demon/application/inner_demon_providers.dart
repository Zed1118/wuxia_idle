import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../mainline/application/mainline_providers.dart';
import '../domain/inner_demon_progress.dart';

part 'inner_demon_providers.g.dart';

/// 心魔通关全局进度(P0-3 ③)。从 [mainlineProgressProvider] 派生,
/// recordVictory → invalidate(mainlineProgressProvider) 后级联刷新。
@riverpod
Future<InnerDemonProgress> innerDemonProgress(Ref ref) async {
  final progress = await ref.watch(mainlineProgressProvider.future);
  return InnerDemonProgress.from(
    innerDemonDef: GameRepository.instance.numbers.innerDemon,
    clearedStageIds: progress.clearedStageIds.toSet(),
  );
}
