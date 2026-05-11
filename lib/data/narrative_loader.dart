import 'package:flutter/services.dart' show rootBundle;

import 'yaml_loader.dart';

/// 主线/章节剧情内容（Phase 3 T36，对应 `data/narratives/<id>.yaml`）。
///
/// 数据 ↔ 文案隔离原则（GDD §8.1）：StageDef 数值在 stages.yaml；剧情文本
/// 在 narratives/，通过 `narrativeOpeningId` / `narrativeVictoryId` 联结。
///
/// **schema**（DeepSeek 端按此填写，详见 `docs/NARRATIVE_SCHEMA.md`）：
/// ```yaml
/// id: mainline_test_01_opening   # 必须等于文件名（不含 .yaml）
/// title: 山道试剑                 # 可空
/// paragraphs:
///   - 山雾未散，你立于青石之上……
///   - 三道身影自林中涌出。
/// ```
class NarrativeContent {
  final String id;
  final String? title;
  final List<String> paragraphs;

  /// 缺文件 / 解析失败时的兜底标记。UI 可显示弱提示。
  final bool isPlaceholder;

  const NarrativeContent({
    required this.id,
    this.title,
    required this.paragraphs,
    required this.isPlaceholder,
  });

  factory NarrativeContent.placeholder(String id) => NarrativeContent(
        id: id,
        title: null,
        paragraphs: ['[剧情待补：$id]'],
        isPlaceholder: true,
      );

  factory NarrativeContent.fromYaml(Map<String, dynamic> y) {
    return NarrativeContent(
      id: y['id'] as String,
      title: y['title'] as String?,
      paragraphs: List<String>.from(
        (y['paragraphs'] as List? ?? const []).map((e) => e.toString()),
      ),
      isPlaceholder: false,
    );
  }
}

/// 主线剧情加载器（Phase 3 T36）。
///
/// **缺文件 / 解析失败兜底**：返回 [NarrativeContent.placeholder]，单段
/// 「[剧情待补：$id]」。**不抛异常**——区别于 [GameRepository] 的 fail-fast：
/// 那是数值/配置层；narratives 是文案层，DeepSeek 异步补，运行期不能挂。
class NarrativeLoader {
  NarrativeLoader._();

  /// 从 `data/narratives/<narrativeId>.yaml` 加载内容；缺文件兜底。
  ///
  /// `loader` 注入用于测试；生产走 [rootBundle.loadString]。
  static Future<NarrativeContent> load(
    String narrativeId, {
    Future<String> Function(String)? loader,
  }) async {
    try {
      final raw = await (loader ?? rootBundle.loadString)(
        'data/narratives/$narrativeId.yaml',
      );
      final y = parseYamlMap(raw);
      return NarrativeContent.fromYaml(y);
    } catch (_) {
      return NarrativeContent.placeholder(narrativeId);
    }
  }
}
