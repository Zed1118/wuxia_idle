import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../baike/presentation/baike_screen.dart';
import '../../battle_record/presentation/battle_record_screen.dart';
import '../../character_panel/presentation/lineage_panel_screen.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import 'mainline_location_archive_screen.dart';
import 'pending_jianghu_affairs_screen.dart';

/// 二阶段 §11.1 “江湖纪事”一级 Hub。
///
/// 本页只负责六类档案的生产路由，不持有内容、解锁或待处理事项写入。
class JianghuChronicleHubScreen extends StatelessWidget {
  const JianghuChronicleHubScreen({
    super.key,
    required this.battleRecordUnlocked,
    required this.equipmentLoreUnlocked,
    @visibleForTesting this.routeObserverForTest,
  });

  final bool battleRecordUnlocked;
  final bool equipmentLoreUnlocked;
  final void Function(Widget screen)? routeObserverForTest;

  void _push(BuildContext context, Widget screen) {
    final observer = routeObserverForTest;
    if (observer != null) {
      observer(screen);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.jianghuChronicleTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                LightPaperPanel(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        UiStrings.jianghuChronicleSectionTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        UiStrings.jianghuChronicleSubtitle,
                        style: TextStyle(
                          color: WuxiaUi.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      WuxiaInkButton(
                        label: UiStrings.jianghuChronicleChapters,
                        hint: UiStrings.jianghuChronicleChaptersHint,
                        icon: Icons.menu_book_outlined,
                        thumbnailPath: WuxiaUi.entryMainline,
                        onTap: () => _push(context, const ChapterListScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.jianghuChronicleCharacters,
                        hint: UiStrings.jianghuChronicleCharactersHint,
                        icon: Icons.account_tree_outlined,
                        thumbnailPath: WuxiaUi.entryCharacter,
                        onTap: () => _push(context, const LineagePanelScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.jianghuChronicleLocations,
                        hint: UiStrings.jianghuChronicleLocationsHint,
                        icon: Icons.place_outlined,
                        thumbnailPath: WuxiaUi.entryJianghu,
                        onTap: () => _push(
                          context,
                          const MainlineLocationArchiveScreen(),
                        ),
                      ),
                      if (battleRecordUnlocked) ...[
                        const SizedBox(height: 12),
                        WuxiaInkButton(
                          label: UiStrings.jianghuChronicleEnemies,
                          hint: UiStrings.jianghuChronicleEnemiesHint,
                          icon: Icons.military_tech_outlined,
                          thumbnailPath: WuxiaUi.entryTower,
                          onTap: () =>
                              _push(context, const BattleRecordScreen()),
                        ),
                      ],
                      if (equipmentLoreUnlocked) ...[
                        const SizedBox(height: 12),
                        WuxiaInkButton(
                          label: UiStrings.jianghuChronicleEquipmentLore,
                          hint: UiStrings.jianghuChronicleEquipmentLoreHint,
                          icon: Icons.auto_stories_outlined,
                          thumbnailPath: WuxiaUi.entryCodex,
                          onTap: () =>
                              _push(context, const BaikeScreen(initialTab: 1)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.jianghuChroniclePendingAffairs,
                        hint: UiStrings.jianghuChroniclePendingAffairsHint,
                        icon: Icons.mark_unread_chat_alt_outlined,
                        thumbnailPath: WuxiaUi.entryCodex,
                        onTap: () =>
                            _push(context, const PendingJianghuAffairsScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
