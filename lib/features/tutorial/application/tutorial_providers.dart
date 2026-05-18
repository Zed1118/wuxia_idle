import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_provider.dart';
import 'tutorial_service.dart';

part 'tutorial_providers.g.dart';

/// nullable propagation(沿 [isarProvider] 体例):Isar 未 init 时返回 null,
/// caller 端 null-coalesce 跳过引导递增(test 路径自然 skip)。
@riverpod
TutorialService? tutorialService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return TutorialService(isar);
}

/// 当前新手引导步骤(默认 0)。
///
/// `recordVictory` 完成后 caller 端 `ref.invalidate(currentTutorialStepProvider)`
/// 触发 MainMenu 灰显刷新(沿 `mainlineProgressProvider` invalidate 体例)。
@riverpod
Future<int> currentTutorialStep(Ref ref) async {
  final svc = ref.watch(tutorialServiceProvider);
  if (svc == null) return 0;
  return svc.getCurrentStep();
}

/// 当前 banner 已读 step 集(P1.y · 默认 `[]`)。
///
/// `TutorialBannerCard.onTap` 调 markHintRead 后端 `ref.invalidate` 触发
/// MainMenu 顶部 banner 隐藏。
@riverpod
Future<List<int>> currentTutorialHintsRead(Ref ref) async {
  final svc = ref.watch(tutorialServiceProvider);
  if (svc == null) return const [];
  return svc.getHintsRead();
}
