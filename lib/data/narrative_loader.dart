import 'package:flutter/services.dart' show rootBundle;

import 'yaml_loader.dart';

/// 主线/章节剧情内容（Phase 3 T36，对应 `data/narratives/<id>.yaml`
/// 或 `data/narratives/stages/<id>.yaml`）。
///
/// 数据 ↔ 文案隔离原则（GDD §8.1）：StageDef 数值在 stages.yaml；剧情文本
/// 在 narratives/，通过 `narrativeOpeningId` / `narrativeVictoryId` 联结。
///
/// **schema**（DeepSeek 端按此填写，详见 `docs/NARRATIVE_SCHEMA.md`）：
/// ```yaml
/// id: stage_01_01_opening   # 必须等于文件名（不含 .yaml）
/// title: 山门之外 · 启        # 可空
/// paragraphs:
///   - 山门已经看不见了。
///   - 三道身影自林中涌出。
/// ```
class NarrativeContent {
  final String id;
  final String? title;
  final List<String> paragraphs;

  /// 缺文件 / 解析失败时的兜底标记。UI 可显示弱提示。
  final bool isPlaceholder;

  /// P1 #42 Phase 2 §10 P1.x:强制引导剧情(不可跳过)。
  ///
  /// yaml `mandatory: true` → Reader Screen 隐藏「跳过」按钮。
  /// 缺省 false 向后兼容(现有 stage / tower 剧情不动)。
  final bool mandatory;

  const NarrativeContent({
    required this.id,
    this.title,
    required this.paragraphs,
    required this.isPlaceholder,
    this.mandatory = false,
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
      mandatory: y['mandatory'] as bool? ?? false,
    );
  }
}

/// 主线剧情加载器（Phase 3 T36；P1 #1 2026-05-12 加 stages/ 子目录扫描）。
///
/// **缺文件 / 解析失败兜底**：返回 [NarrativeContent.placeholder]，单段
/// 「[剧情待补：$id]」。**不抛异常**——区别于 [GameRepository] 的 fail-fast：
/// 那是数值/配置层；narratives 是文案层，DeepSeek 异步补，运行期不能挂。
class NarrativeLoader {
  NarrativeLoader._();

  /// 扫描顺序（固定契约）：
  /// 1. `data/narratives/<id>.yaml`（扁平，兼容旧 narrative）
  /// 2. `data/narratives/stages/<id>.yaml`（DeepSeek 拆分体系）
  /// 3. `data/narratives/ascension/<id>.yaml`(P2.3 飞升仪式 narrative · 2026-05-24)
  /// 都失败 → [NarrativeContent.placeholder]
  static const _scanPaths = [
    'data/narratives/',
    'data/narratives/stages/',
    'data/narratives/ascension/',
  ];

  /// 从扁平或 stages/ 子目录加载剧情内容；都缺则兜底。
  ///
  /// `loader` 注入用于测试；生产走 [rootBundle.loadString]。
  static Future<NarrativeContent> load(
    String narrativeId, {
    Future<String> Function(String)? loader,
  }) async {
    final fn = loader ?? rootBundle.loadString;
    for (final prefix in _scanPaths) {
      try {
        final raw = await fn('$prefix$narrativeId.yaml');
        final y = parseYamlMap(raw);
        return NarrativeContent.fromYaml(y);
      } catch (_) {
        // 继续尝试下一路径
      }
    }
    return NarrativeContent.placeholder(narrativeId);
  }
}
