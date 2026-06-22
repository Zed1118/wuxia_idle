import 'package:flutter/material.dart';

import '../../encounter/domain/encounter_def.dart';
import '../../encounter/domain/encounter_event_loader.dart';
import '../application/encounter_codex_provider.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';

/// 奇缘录详情屏(Task 3)。
///
/// 从奇遇录 tab(Task 4)点亮卡片推入,回看一段已际遇奇遇的 opening 故事。
/// 类型标(领悟/奇缘/节庆)由 [def] 同步导出(不依赖 async);title + opening
/// 经 [EncounterEventLoader.load] 异步载入,缺文件走 placeholder 兜底不崩。
///
/// 纯只读展示,不读 provider / 不写库。
class EncounterDetailScreen extends StatelessWidget {
  const EncounterDetailScreen({super.key, required this.def});

  final EncounterDef def;

  /// 类型标文案,归类规则共用 [encounterGroupKindOf](节庆优先于 type)。
  String get _typeLabel => labelForEncounterGroupKind(encounterGroupKindOf(def));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.encounterCodexDetailTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: PaperPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: FutureBuilder<EncounterContent>(
              future: EncounterEventLoader.load(def.id),
              builder: (context, snapshot) {
                final content = snapshot.data;
                final loading =
                    snapshot.connectionState != ConnectionState.done;
                final heading = (content?.title?.isNotEmpty ?? false)
                    ? content!.title!
                    : def.id;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TypeTag(label: _typeLabel),
                    const SizedBox(height: 12),
                    SectionHeader(heading),
                    const SizedBox(height: 4),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: WuxiaUi.jiang,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        content!.opening,
                        style: const TextStyle(
                          color: WuxiaUi.ink,
                          fontSize: 15,
                          height: 1.7,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 类型标(水墨小章):绛红描边 + 墨字,即刻可见不等 async。
class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: WuxiaUi.jiang, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WuxiaUi.jiang,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
