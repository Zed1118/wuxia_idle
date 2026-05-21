import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import 'founder_buff_service.dart';

part 'founder_buff_providers.g.dart';

/// 祖师爷 buff 激活态 provider(P1.1 A1 E.5)。
///
/// caller 端 `ref.watch(founderBuffActiveProvider)` 拿 bool,传给
/// `CharacterDerivedStats.*` 的 `founderBuffActive` 可选参数。
///
/// invalidate 时机:
/// - 主菜单进入战斗时(无需主动 invalidate,nullable propagation 自然)
/// - 收徒 dialog 关闭时 → 已 invalidate(影响显示但不影响 buff trigger)
///
/// **R3 风险**:active 列表变化时(玩家未来切弟子上场)需 invalidate;
/// 本 P1.1 阶段 active 始终是初始 3 角色(祖师 + 大弟子 + 二弟子),不会动态变。
@riverpod
Future<bool> founderBuffActive(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return false;
  if (!GameRepository.isLoaded) return false;
  final svc = FounderBuffService(isar);
  return svc.computeBuffActive(GameRepository.instance.numbers);
}
