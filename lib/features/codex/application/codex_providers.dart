import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../domain/codex_entry.dart';
import '../domain/codex_index.dart';

part 'codex_providers.g.dart';

/// P1 #42 Phase 2 §10 P1.z 全 19 条机制百科 + 江湖背景条目(对齐 [CodexIndex.entries])。
///
/// 顺序固定按 [CodexIndex.entries] 登记顺序(8 档机制 → 4 A 组机制补充阅读 → 7 B 组 lore)。
/// 未加载到 md 的条目以 placeholder 形式返回(null entry),caller 端机制段显灰显
/// 「待解锁」(永久可见 + 占位条目可见);lore 段缺 md 视为 hidden(实际 P2 已落齐 11)。
@riverpod
List<CodexListItem> codexListItems(Ref ref) {
  if (!GameRepository.isLoaded) return const [];
  final loaded = GameRepository.instance.codexEntries;
  return [
    for (final indexEntry in CodexIndex.entries)
      CodexListItem(indexEntry: indexEntry, entry: loaded[indexEntry.id]),
  ];
}

/// 当前已解锁的「机制档数」(对齐 GDD §10.1 8 档解锁节奏)。
///
/// 分子 ∈ [0, 8] = `tutorialStep` clamp 到 [0, 8];A 组 4 补充阅读虽挂相同档,
/// 但**不增加分子**(8 档节奏是核心叙事,A 组只是档下扩展条目);lore 永远可查不计入。
/// 用于 UI 顶部「已解锁 X / 8」chip 展示;分母固定 8。
@riverpod
Future<int> unlockedCodexCount(Ref ref) async {
  final step = await ref.watch(currentTutorialStepProvider.future);
  return step.clamp(0, 8);
}

/// 列表项:登记元数据 + 已加载 entry(null = md 缺失,UI 仍显占位)。
class CodexListItem {
  final CodexIndexEntry indexEntry;
  final CodexEntry? entry;

  const CodexListItem({required this.indexEntry, required this.entry});

  bool get isLoaded => entry != null;
}
