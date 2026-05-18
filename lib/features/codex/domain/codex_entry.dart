import 'codex_category.dart';
import 'codex_index.dart';

/// P1 #42 Phase 2 §10 P1.z 机制百科条目(对齐 GDD §10.2 第 3 方式)。
///
/// 内容载体:`data/narratives/codex/<id>.md`(DeepSeek 领地)。
/// 解析规范见 [CodexEntry.fromMd]。
class CodexEntry {
  final String id;
  final int step;
  final String title;
  final CodexCategory category;
  final List<String> paragraphs;

  const CodexEntry({
    required this.id,
    required this.step,
    required this.title,
    required this.category,
    required this.paragraphs,
  });

  /// 段落总字数(含换行符,用于红线校验「200-550 字」)。
  int get totalChars => paragraphs.fold(0, (sum, p) => sum + p.length);

  /// 从 md 文本解析。
  ///
  /// **格式契约**:
  /// - 首个非空行必须为 `# <title>` 形式;否则抛 [FormatException]
  /// - title 行之后的内容按连续 2+ 换行 (`\n\s*\n`) 切段
  /// - 段内单换行保留(水墨基调允许内部断行)
  /// - 段落首尾空白 trim
  ///
  /// `indexEntry` 由 [CodexIndex.byId] 提供 step + category;**调用方负责校验 id
  /// 已登记**,否则抛 [StateError]。
  factory CodexEntry.fromMd({
    required String id,
    required String raw,
  }) {
    final indexEntry = CodexIndex.byId(id);
    if (indexEntry == null) {
      throw StateError('codex id "$id" not registered in CodexIndex.entries');
    }

    final lines = raw.split('\n');
    String? title;
    int titleLineIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('# ')) {
        title = line.substring(2).trim();
        titleLineIndex = i;
        break;
      } else {
        throw FormatException(
          'codex md "$id" first non-empty line must be `# <title>`, got: "$line"',
        );
      }
    }
    if (title == null || title.isEmpty) {
      throw FormatException('codex md "$id" missing or empty `# <title>` line');
    }

    final body = lines.sublist(titleLineIndex + 1).join('\n');
    final paragraphs = body
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    if (paragraphs.isEmpty) {
      throw FormatException('codex md "$id" has empty body after title');
    }

    return CodexEntry(
      id: id,
      step: indexEntry.step,
      title: title,
      category: indexEntry.category,
      paragraphs: paragraphs,
    );
  }
}
