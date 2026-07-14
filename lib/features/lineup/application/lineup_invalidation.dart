import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/application/character_providers.dart';
import 'lineup_providers.dart';

/// 编成变更后统一失效的 provider 集合(沿 `post_combat_invalidation` 体例:
/// 参数 `void Function(ProviderOrFamily)`,生产传 `ref.invalidate`,
/// 测试传 `container.invalidate`)。
///
/// 最小集三项:
/// 1. [activeCharacterIdsProvider] —— 唯一真相源读方(battle setup /
///    character_panel TabBar / 门派谱当代兜底等 40+ 消费点的上游);
/// 2. [characterByIdProvider] —— isActive 镜像变更后角色快照需重读;
/// 3. [lineupReserveProvider] —— 替补池自身。
///
/// lineageCodexProvider / lineageInfoProvider 均 watch 上述上游,自动级联,
/// 不需点名。
void invalidateAfterLineupChange(void Function(ProviderOrFamily) invalidate) {
  invalidate(activeCharacterIdsProvider);
  invalidate(characterByIdProvider);
  invalidate(lineupReserveProvider);
}
