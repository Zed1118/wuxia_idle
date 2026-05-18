import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../domain/codex_entry.dart';
import '../domain/codex_index.dart';

part 'codex_providers.g.dart';

/// P1 #42 Phase 2 §10 P1.z 全 8 条机制百科条目(对齐 [CodexIndex.entries])。
///
/// 顺序固定按 [CodexIndex.entries] step 1→8 排列。
/// 未加载到 md 的条目以 placeholder 形式返回(null entry),caller 端
/// 显灰显「待解锁」(永久可见 + 占位条目可见)。
@riverpod
List<CodexListItem> codexListItems(Ref ref) {
  if (!GameRepository.isLoaded) return const [];
  final loaded = GameRepository.instance.codexEntries;
  return [
    for (final indexEntry in CodexIndex.entries)
      CodexListItem(indexEntry: indexEntry, entry: loaded[indexEntry.id]),
  ];
}

/// 当前已解锁条目数(对齐当前 tutorialStep)。
///
/// 仅用于 UI 顶部「已解锁 X / 8」chip 展示;锁/已解锁判定由 caller 端逐条 watch
/// [currentTutorialStepProvider] 派生(避免依赖反向)。
@riverpod
Future<int> unlockedCodexCount(Ref ref) async {
  final step = await ref.watch(currentTutorialStepProvider.future);
  final items = ref.watch(codexListItemsProvider);
  return items.where((it) => it.indexEntry.step <= step).length;
}

/// 列表项:登记元数据 + 已加载 entry(null = md 缺失,UI 仍显占位)。
class CodexListItem {
  final CodexIndexEntry indexEntry;
  final CodexEntry? entry;

  const CodexListItem({required this.indexEntry, required this.entry});

  bool get isLoaded => entry != null;
}
