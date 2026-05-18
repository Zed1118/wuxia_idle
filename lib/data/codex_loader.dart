import 'package:flutter/services.dart' show rootBundle;

import '../features/codex/domain/codex_entry.dart';
import '../features/codex/domain/codex_index.dart';

/// P1 #42 Phase 2 §10 P1.z 机制百科加载器(沿 NarrativeLoader graceful 体例)。
///
/// **缺文件容忍**:`CodexIndex.entries` 里某条 id 对应 md 缺失时,跳过(不抛),
/// 由 GameRepository 红线校验汇总 warning。理由:档 8 `combat_advanced.md`
/// DeepSeek 派单前可能缺失,生产侧 UI 显「待解锁」即可,不阻塞主流程。
class CodexLoader {
  CodexLoader._();

  /// 扫 [CodexIndex.entries] 8 条登记的 id,加载到几条算几条。
  ///
  /// `loader` 注入用于测试;生产走 [rootBundle.loadString]。
  static Future<List<CodexEntry>> loadAll({
    Future<String> Function(String path)? loader,
  }) async {
    final fn = loader ?? rootBundle.loadString;
    final result = <CodexEntry>[];
    for (final indexEntry in CodexIndex.entries) {
      try {
        final raw = await fn('data/narratives/codex/${indexEntry.id}.md');
        result.add(CodexEntry.fromMd(id: indexEntry.id, raw: raw));
      } catch (_) {
        // graceful 跳过缺失或解析失败,由 GameRepository 红线 warn 汇总
      }
    }
    return result;
  }
}
