import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/character.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/bgm_scope.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/error_fallback.dart';
import '../../ascension/application/ascend_service_providers.dart';
import '../../ascension/presentation/ascension_screen.dart';
import '../application/lineage_codex_provider.dart';
import 'lineage_character_detail_screen.dart';
import 'lineage_widgets.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 门派谱（门派谱1.1 Task4 · 纵向世代卷）。
///
/// 主菜单「师徒名单」按钮进入。`lineageCodexProvider` 派生历代传承，
/// 自顶向下（太祖在前）渲染每代：代标题 + 当代/已退隐标签 + 祖师卡 +
/// 门人列表 + 师承遗物列表。屏底保留飞升渡劫入口。
///
/// 点祖师 / 门人卡 → push [LineageCharacterDetailScreen]。
/// 纯展示层（不改数值/平衡），无中文字面量（全走 [UiStrings]/[EnumL10n]）。
class LineagePanelScreen extends ConsumerWidget {
  const LineagePanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lineageCodexProvider);
    return BgmScope(
      track: BgmTrack.lineage,
      child: Scaffold(
        backgroundColor: WuxiaColors.background,
        appBar: AppBar(
          backgroundColor: WuxiaColors.background,
          title: const Text(UiStrings.lineageCodexTitle),
          leading: Navigator.of(context).canPop()
              ? BackButton(onPressed: () => Navigator.of(context).pop())
              : null,
        ),
        body: SafeArea(
          child: async.when(
            loading: () => const Center(child: InkLoadingIndicator()),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(lineageCodexProvider),
            ),
            data: (gens) => _Body(generations: gens),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.generations});

  final List<LineageGeneration> generations;

  @override
  Widget build(BuildContext context) {
    final totalMembers = generations.fold<int>(
      0,
      (sum, g) => sum + g.disciples.length,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Image.asset(
              'assets/ui/scroll_vertical.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              UiStrings.lineageCodexProgress(
                generations.length,
                totalMembers,
              ),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          if (generations.isEmpty)
            const _EmptyText(UiStrings.lineagePanelNoFounder)
          else
            for (var i = 0; i < generations.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _GenerationSection(
                generation: generations[i],
                genIndex: i + 1,
              ),
            ],
          const SizedBox(height: 16),
          const _AscensionSection(),
        ],
      ),
    );
  }
}

/// 单代段：代标题行 + 当代/已退隐标签 + 祖师卡 + 门人 + 师承遗物。
class _GenerationSection extends StatelessWidget {
  const _GenerationSection({required this.generation, required this.genIndex});

  final LineageGeneration generation;
  final int genIndex;

  void _openDetail(BuildContext context, Character character) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LineageCharacterDetailScreen(
          character: character,
          generationIndex: genIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gen = generation;
    return LineagePanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LineageSectionTitle(
                UiStrings.lineageCodexGenerationLabel(genIndex),
              ),
              _GenerationTag(isCurrent: gen.isCurrent),
            ],
          ),
          const SizedBox(height: 8),
          _CharacterChip(
            character: gen.founder,
            portraitPath: gen.founder.portraitPath,
            onTap: () => _openDetail(context, gen.founder),
          ),
          const SizedBox(height: 12),
          const LineageSectionTitle(UiStrings.lineageCodexDiscipleSection),
          const SizedBox(height: 8),
          if (gen.disciples.isEmpty)
            const _EmptyText(UiStrings.lineageCodexNoDisciples)
          else
            for (var i = 0; i < gen.disciples.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _CharacterChip(
                character: gen.disciples[i],
                portraitPath: gen.disciples[i].portraitPath,
                onTap: () => _openDetail(context, gen.disciples[i]),
              ),
            ],
          const SizedBox(height: 12),
          const LineageSectionTitle(UiStrings.lineageCodexHeritageSection),
          const SizedBox(height: 8),
          if (gen.heritageEquipments.isEmpty)
            const _EmptyText(UiStrings.lineageCodexNoHeritage)
          else
            for (var i = 0; i < gen.heritageEquipments.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              LineageHeritageRow(equipment: gen.heritageEquipments[i]),
            ],
        ],
      ),
    );
  }
}

/// 当代 / 已退隐标签。
class _GenerationTag extends StatelessWidget {
  const _GenerationTag({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        isCurrent
            ? UiStrings.lineageCodexCurrentTag
            : UiStrings.lineageCodexRetiredTag,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

/// 飞升渡劫入口段(P2.3 §7.1 · spec p2_3_ascension_spec_2026-05-24)。
///
/// 5 子条件聚合判定(`ascensionEligibilityProvider`):
///   - 全 true → 「步入飞升」按钮 enable · 点击 push [AscensionScreen]
///   - 任一 false → disable · tooltip 显未达条件清单
class _AscensionSection extends ConsumerWidget {
  const _AscensionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ascensionEligibilityProvider);
    return LineagePanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LineageSectionTitle(UiStrings.ascensionPanelSection),
          const SizedBox(height: 4),
          const Text(
            UiStrings.ascensionPanelHint,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: InkLoadingIndicator(),
                ),
              ),
            ),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(ascensionEligibilityProvider),
            ),
            data: (e) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!e.canAscend && e.missingReasons.isNotEmpty) ...[
                  for (final r in e.missingReasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '· $r',
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: e.canAscend
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AscensionScreen(),
                            ),
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WuxiaColors.resultHighlight,
                      disabledBackgroundColor: WuxiaColors.buttonDisabled,
                    ),
                    child: Text(
                      e.canAscend
                          ? UiStrings.ascensionPanelButton
                          : UiStrings.ascensionPanelLocked,
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 角色卡片：阶色条/头像 + 名号 + 境界。可选 [onTap] 包 [InkWell] 使可点。
class _CharacterChip extends StatelessWidget {
  const _CharacterChip({
    required this.character,
    this.portraitPath,
    this.onTap,
  });

  final Character character;
  final String? portraitPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(character.school!);
    final inner = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (portraitPath == null)
            Container(width: 4, height: 28, color: schoolColor)
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: schoolColor, width: 1),
                color: WuxiaColors.avatarFill,
              ),
              child: Image.asset(
                portraitPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: WuxiaColors.avatarFill),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  EnumL10n.realm(character.realmTier, character.realmLayer),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return inner;
    return InkWell(onTap: onTap, child: inner);
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
    );
  }
}
