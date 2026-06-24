import 'package:flutter/services.dart' show rootBundle;

import '../../../data/yaml_loader.dart';
import '../../../shared/strings.dart';

/// 奇遇文案 `events/[id].yaml`(DeepSeek 维护)按需加载器(Phase 4 W14-1)。
///
/// schema:
/// ```yaml
/// id: bamboo_listen_rain
/// title: 听雨悟剑
/// opening: |
///   竹叶上水珠成串而下,雨声渐密 ...
/// choices:
///   - text: 闭目静听
///     outcome_id: insight_success
///     body: |
///       雨声更重,剑意更轻 ...
/// ```
///
/// 缺文件 / 解析失败:返回 [EncounterContent.placeholder](沿用 narrative
/// 体例,运行期不抛)。**启动期**则由 `GameRepository._validateEncounterEventReferences`
/// 对 placeholder / id 不自洽 / 越界 outcome_id fail-fast(GDD §8.1),
/// 二者互补:运行期优雅兜底 + 启动期强校验拦截 build 期数据失联。
class EncounterContent {
  final String id;
  final String? title;
  final String opening;
  final List<EncounterChoice> choices;
  final bool isPlaceholder;

  const EncounterContent({
    required this.id,
    this.title,
    required this.opening,
    required this.choices,
    required this.isPlaceholder,
  });

  factory EncounterContent.placeholder(String id) => EncounterContent(
        id: id,
        title: null,
        opening: '[文案待补:$id]',
        choices: const [
          EncounterChoice(
            text: UiStrings.encounterPlaceholderChoice,
            outcomeId: 'skip',
            body: '',
          ),
        ],
        isPlaceholder: true,
      );

  factory EncounterContent.fromYaml(Map<String, dynamic> y) {
    return EncounterContent(
      id: y['id'] as String,
      title: y['title'] as String?,
      opening: (y['opening'] as String?)?.trim() ?? '',
      choices: ((y['choices'] as List?) ?? const [])
          .map((e) =>
              EncounterChoice.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      isPlaceholder: false,
    );
  }
}

class EncounterChoice {
  final String text;
  final String outcomeId;
  final String body;

  const EncounterChoice({
    required this.text,
    required this.outcomeId,
    required this.body,
  });

  factory EncounterChoice.fromYaml(Map<String, dynamic> y) {
    return EncounterChoice(
      text: (y['text'] as String?)?.trim() ?? '',
      outcomeId: y['outcome_id'] as String,
      body: (y['body'] as String?)?.trim() ?? '',
    );
  }
}

/// 按需加载器,沿用 [NarrativeLoader] 体例:单一路径 + placeholder 兜底。
class EncounterEventLoader {
  EncounterEventLoader._();

  static Future<EncounterContent> load(
    String encounterId, {
    Future<String> Function(String)? loader,
  }) async {
    final fn = loader ?? rootBundle.loadString;
    try {
      final raw = await fn('data/events/$encounterId.yaml');
      final y = parseYamlMap(raw);
      return EncounterContent.fromYaml(y);
    } catch (_) {
      return EncounterContent.placeholder(encounterId);
    }
  }
}
