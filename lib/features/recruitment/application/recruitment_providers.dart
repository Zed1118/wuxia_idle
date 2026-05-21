import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_provider.dart';
import 'recruitment_service.dart';

part 'recruitment_providers.g.dart';

/// 收徒 service nullable propagation(沿 [tutorialServiceProvider] 体例)。
/// Isar 未 init 时返回 null,caller 端 null-coalesce 跳过(test 路径自然 skip)。
@riverpod
RecruitmentService? recruitmentService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return RecruitmentService(isar);
}

/// 收徒提议是否已发出(默认 false)。
///
/// tutorial step 6 banner 点击时读本 provider 决定:
///   - false → push RecruitmentDialog
///   - true → 直接 markHintRead 关闭 banner(已收过弟子,只是补关闭操作)
///
/// dialog dismiss 后 `ref.invalidate(recruitmentOfferedProvider)` 触发 banner 隐藏。
@riverpod
Future<bool> recruitmentOffered(Ref ref) async {
  final svc = ref.watch(recruitmentServiceProvider);
  if (svc == null) return false;
  return svc.hasOffered();
}

/// 已收徒弟 Character id 列表(默认空 list)。
///
/// LineagePanelScreen inactive 段渲染时读本 provider,与 activeCharacterIds 联合
/// 判定 active vs inactive 弟子。
@riverpod
Future<List<int>> recruitedDiscipleIds(Ref ref) async {
  final svc = ref.watch(recruitmentServiceProvider);
  if (svc == null) return const [];
  return svc.getRecruitedIds();
}
