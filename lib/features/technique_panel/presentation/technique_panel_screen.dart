import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../dispel/application/dispel_service.dart';
import '../../dispel/application/dispel_service_providers.dart';
import '../../cultivation/application/insight_exchange_service.dart';
import '../../cultivation/application/insight_exchange_service_providers.dart';
import '../../cultivation/application/skill_proficiency_formatter.dart';
import '../domain/technique_equip_suggestion.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import 'dispel_dialog.dart';

/// 心法面板（phase2_tasks.md T31 §468-490 + T32 #22b writeTxn 补漏）。
///
/// 单角色版面，按 characterId 取数。布局：
/// - AppBar 标题 [UiStrings.techniquePanelTitle]
/// - 已学心法按 [TechniqueTier] 高→低 分组，每组一段 section header
/// - 每条心法 tile：流派色条 / 主修-辅修标签 / 流派 / cultivationLayer / 进度条 / 数值
/// - 辅修 tile 尾部带「设为主修」按钮 → 弹 [DispelConfirmDialog] 二确 →
///   `DispelService.dispel(...)` + [DispelService.persistResult] writeTxn 落地 +
///   invalidate 4 个 provider + SnackBar 反馈
///
/// **测试旁路**：widget test FakeAsync 不兼容真 Isar 异步 IO；未 init Isar
/// 时 persistResult 跳过。真落地由 `test/services/dispel_persist_test.dart` 覆盖。
class TechniquePanelScreen extends ConsumerWidget {
  const TechniquePanelScreen({super.key, required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chAsync = ref.watch(characterByIdProvider(characterId));
    final techsAsync = ref.watch(characterAllTechniquesProvider(characterId));

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.panel,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.techniquePanelTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/ui/lotus_icon.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: WuxiaPaperPanel(
        child: SafeArea(
          child: chAsync.when(
            loading: () => const Center(child: InkLoadingIndicator()),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(characterByIdProvider(characterId)),
            ),
            data: (c) {
              if (c == null) {
                return const Center(
                  child: Text(
                    UiStrings.characterNotFound,
                    style: TextStyle(color: WuxiaColors.textMuted),
                  ),
                );
              }
              return techsAsync.when(
                loading: () => const Center(child: InkLoadingIndicator()),
                error: (e, _) => ErrorFallback(
                  error: e,
                  onRetry: () => ref.invalidate(
                    characterAllTechniquesProvider(characterId),
                  ),
                ),
                data: (techs) => _Body(character: c, techniques: techs),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.character, required this.techniques});

  final Character character;
  final List<Technique> techniques;

  @override
  Widget build(BuildContext context) {
    if (techniques.isEmpty) {
      return const Center(
        child: Text(
          UiStrings.techniquePanelEmpty,
          style: TextStyle(color: WuxiaColors.textMuted),
        ),
      );
    }

    final byTier = <TechniqueTier, List<Technique>>{};
    for (final t in techniques) {
      byTier.putIfAbsent(t.tier, () => []).add(t);
    }
    final sortedTiers = byTier.keys.toList()
      ..sort((a, b) => b.index.compareTo(a.index));

    Technique? mainTech;
    for (final t in techniques) {
      if (t.role == TechniqueRole.main) {
        mainTech = t;
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MeridianOverviewPanel(
            character: character,
            techniques: techniques,
            mainTech: mainTech,
          ),
          const SizedBox(height: 16),
          if (mainTech != null) ...[
            _MainTechniqueHero(mainTech: mainTech),
            const SizedBox(height: 16),
          ],
          _SchoolRelationPanel(mainSchool: mainTech?.school),
          const SizedBox(height: 16),
          for (final tier in sortedTiers) ...[
            // M4 Stage 3 美术(2026-05-21):tier section 起手 7 阶卷轴 cover banner。
            // 约定路径 assets/techniques/tier_<name>.png,无图走 errorBuilder shrink
            // (widget test 不加载 pubspec assets,memory feedback_image_asset_error_builder)。
            // 卷轴 cover 完整居中呈现(含织锦/金框装帧 = 7 阶梯度所在),
            // 不用 height 60 + BoxFit.cover(会裁掉上下边框令梯度消失)。
            // 图 1952×608(≈3.21:1);maxWidth 480 → 高约 150。无图走 errorBuilder shrink。
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AspectRatio(
                  aspectRatio: 1952 / 608,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/techniques/tier_${tier.name}.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      // 卷轴故意无字(避伪书法红线),阶名以墨色叠在卷轴中央。
                      Center(
                        child: Text(
                          EnumL10n.techniqueTier(tier),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: WuxiaUi.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final t in byTier[tier]!) ...[
              _TechniqueTile(character: character, technique: t),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MeridianOverviewPanel extends StatelessWidget {
  const _MeridianOverviewPanel({
    required this.character,
    required this.techniques,
    required this.mainTech,
  });

  final Character character;
  final List<Technique> techniques;
  final Technique? mainTech;

  @override
  Widget build(BuildContext context) {
    final mainSchool = mainTech?.school;
    final accent = mainSchool == null
        ? WuxiaColors.resultHighlight
        : WuxiaColors.schoolColor(mainSchool);
    final assistCount = math.min(
      3,
      techniques.where((t) => t.role == TechniqueRole.assist).length,
    );
    var highest = techniques.first.cultivationLayer;
    for (final technique in techniques.skip(1)) {
      if (technique.cultivationLayer.index > highest.index) {
        highest = technique.cultivationLayer;
      }
    }
    final mainText = mainSchool == null
        ? UiStrings.techniqueSchoolMatrixUnset
        : EnumL10n.school(mainSchool);
    final items = [
      _MeridianOverviewItem(
        icon: Icons.auto_stories_outlined,
        label: UiStrings.techniqueMeridianMain(mainText),
        color: accent,
      ),
      _MeridianOverviewItem(
        icon: Icons.hub_outlined,
        label: UiStrings.techniqueMeridianAssist(assistCount, 3),
        color: WuxiaUi.qing,
      ),
      _MeridianOverviewItem(
        icon: Icons.tips_and_updates_outlined,
        label: UiStrings.techniqueMeridianInsight(character.insightPoints),
        color: WuxiaUi.gold,
      ),
      _MeridianOverviewItem(
        icon: Icons.local_fire_department_outlined,
        label: UiStrings.techniqueMeridianHighest(
          EnumL10n.cultivationLayer(highest),
          techniques.length,
        ),
        color: WuxiaUi.jiang,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.inkPanelBottom.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.spa_outlined, color: accent, size: 18),
                const SizedBox(width: 8),
                const Text(
                  UiStrings.techniqueMeridianOverviewTitle,
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 56,
                  height: 1,
                  color: accent.withValues(alpha: 0.62),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items) _MeridianOverviewChip(item: item),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MeridianOverviewItem {
  const _MeridianOverviewItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class _MeridianOverviewChip extends StatelessWidget {
  const _MeridianOverviewChip({required this.item});

  final _MeridianOverviewItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: item.color.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 15),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                color: item.color == WuxiaUi.gold
                    ? WuxiaColors.textPrimary
                    : item.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolRelationPanel extends StatelessWidget {
  const _SchoolRelationPanel({required this.mainSchool});

  final TechniqueSchool? mainSchool;

  @override
  Widget build(BuildContext context) {
    final current = mainSchool == null
        ? UiStrings.techniqueSchoolMatrixUnset
        : EnumL10n.school(mainSchool!);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WuxiaColors.inkPanelTop, WuxiaColors.inkPanelBottom],
        ),
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                UiStrings.techniqueSchoolMatrixTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${UiStrings.techniqueSchoolMatrixCurrentPrefix} · $current',
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            UiStrings.techniqueSchoolMatrixHint,
            style: TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 158,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const nodeWidth = 104.0;
                const nodeHeight = 58.0;
                final width = constraints.maxWidth;
                final gang = Offset((width - nodeWidth) / 2, 0);
                final ling = const Offset(8, 92);
                final yin = Offset(width - nodeWidth - 8, 92);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SchoolRelationPainter(
                          gangCenter:
                              gang +
                              const Offset(nodeWidth / 2, nodeHeight / 2),
                          lingCenter:
                              ling +
                              const Offset(nodeWidth / 2, nodeHeight / 2),
                          yinCenter:
                              yin + const Offset(nodeWidth / 2, nodeHeight / 2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: gang.dx,
                      top: gang.dy,
                      child: _SchoolNode(
                        school: TechniqueSchool.gangMeng,
                        effect: UiStrings.techniqueSchoolEffectGangMeng,
                        active: mainSchool == TechniqueSchool.gangMeng,
                      ),
                    ),
                    Positioned(
                      left: ling.dx,
                      top: ling.dy,
                      child: _SchoolNode(
                        school: TechniqueSchool.lingQiao,
                        effect: UiStrings.techniqueSchoolEffectLingQiao,
                        active: mainSchool == TechniqueSchool.lingQiao,
                      ),
                    ),
                    Positioned(
                      left: yin.dx,
                      top: yin.dy,
                      child: _SchoolNode(
                        school: TechniqueSchool.yinRou,
                        effect: UiStrings.techniqueSchoolEffectYinRou,
                        active: mainSchool == TechniqueSchool.yinRou,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolNode extends StatelessWidget {
  const _SchoolNode({
    required this.school,
    required this.effect,
    required this.active,
  });

  final TechniqueSchool school;
  final String effect;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = WuxiaColors.schoolColor(school);
    return Container(
      width: 104,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.24 : 0.12),
        border: Border.all(
          color: active
              ? WuxiaColors.resultHighlight
              : color.withValues(alpha: 0.84),
          width: active ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: active
            ? [
                BoxShadow(
                  color: WuxiaColors.resultHighlight.withValues(alpha: 0.24),
                  blurRadius: 8,
                ),
              ]
            : const [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            EnumL10n.school(school),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? WuxiaColors.resultHighlight : color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            effect,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolRelationPainter extends CustomPainter {
  const _SchoolRelationPainter({
    required this.gangCenter,
    required this.lingCenter,
    required this.yinCenter,
  });

  final Offset gangCenter;
  final Offset lingCenter;
  final Offset yinCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WuxiaColors.textMuted.withValues(alpha: 0.42)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawArrow(canvas, paint, gangCenter, yinCenter);
    _drawArrow(canvas, paint, yinCenter, lingCenter);
    _drawArrow(canvas, paint, lingCenter, gangCenter);
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset from, Offset to) {
    final direction = to - from;
    final length = direction.distance;
    if (length == 0) return;
    final unit = direction / length;
    final start = from + unit * 54;
    final end = to - unit * 54;
    canvas.drawLine(start, end, paint);

    final angle = math.atan2(unit.dy, unit.dx);
    const arrowSize = 7.0;
    final left =
        end -
        Offset(
          math.cos(angle - math.pi / 6) * arrowSize,
          math.sin(angle - math.pi / 6) * arrowSize,
        );
    final right =
        end -
        Offset(
          math.cos(angle + math.pi / 6) * arrowSize,
          math.sin(angle + math.pi / 6) * arrowSize,
        );
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(left.dx, left.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(right.dx, right.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SchoolRelationPainter oldDelegate) {
    return gangCenter != oldDelegate.gangCenter ||
        lingCenter != oldDelegate.lingCenter ||
        yinCenter != oldDelegate.yinCenter;
  }
}

class _TechniqueTile extends ConsumerWidget {
  const _TechniqueTile({required this.character, required this.technique});

  final Character character;
  final Technique technique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMain = technique.role == TechniqueRole.main;
    final schoolColor = WuxiaColors.schoolColor(technique.school);
    final borderColor = isMain
        ? schoolColor
        : schoolColor.withValues(alpha: 0.6);
    final progress = technique.cultivationProgressToNext == 0
        ? 0.0
        : (technique.cultivationProgress / technique.cultivationProgressToNext)
              .clamp(0.0, 1.0)
              .toDouble();

    // P1b: 修炼度五要素接入 StageProgressRow（统一进度规范，复用 character_panel
    // 同款「当前层伤害倍率 / 下一层倍率」计算）。
    final mult = GameRepository.instance.numbers.cultivationMultiplier;
    final layer = technique.cultivationLayer;
    final curMult = mult[layer] ?? 1.0;
    final layers = CultivationLayer.values;
    final layerIdx = layers.indexOf(layer);
    final isMaxLayer = layerIdx >= layers.length - 1;
    final nextMultText = isMaxLayer
        ? UiStrings.cultivationMaxLayer
        : UiStrings.cultivationNextDamageMult(
            mult[layers[layerIdx + 1]] ?? curMult,
          );
    final techDef = GameRepository.instance.techniqueDefs[technique.defId];
    final skillUsage = {
      for (final entry in technique.skillUsageCount) entry.skillId: entry.count,
    };
    final skillSummary = SkillProficiencyFormatter.bestSkillSummaryForTechnique(
      skills: [
        for (final id in techDef?.skillIds ?? const <String>[])
          if (GameRepository.instance.skillDefs.containsKey(id))
            GameRepository.instance.getSkill(id),
      ],
      usage: skillUsage,
      cfg: GameRepository.instance.numbers.skillProficiency,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill.withValues(alpha: 0.82),
        border: Border.all(color: borderColor, width: isMain ? 2 : 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 4, height: 24, color: schoolColor),
              const SizedBox(width: 8),
              Text(
                isMain
                    ? UiStrings.techniqueRoleMain
                    : UiStrings.techniqueRoleAssist,
                style: TextStyle(
                  color: isMain ? schoolColor : WuxiaColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isMain ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                EnumL10n.school(technique.school),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _SealBadge(layer: technique.cultivationLayer),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: WuxiaColors.textMuted.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // P1b: LinearProgressIndicator → StageProgressRow（MeridianBar +
          // 当前/下一阶伤害倍率五要素；层名仍由上方 _SealBadge 印章强调，
          // 故 stageName 文字与印章并存——印章是视觉徽章、文字带术语释义）。
          StageProgressRow(
            stageName: EnumL10n.cultivationLayer(technique.cultivationLayer),
            glossaryDefinition: UiStrings.glossaryCultivation,
            ratio: progress,
            currentEffect: UiStrings.cultivationDamageMult(curMult),
            nextEffect: nextMultText,
            progressText: UiStrings.cultivationProgress(
              technique.cultivationProgress,
              technique.cultivationProgressToNext,
            ),
          ),
          if (skillSummary != null) ...[
            const SizedBox(height: 8),
            StageProgressRow(
              title: UiStrings.skillProficiencyBestSkillTitle(
                skillSummary.skill.name,
              ),
              stageName: skillSummary.stageName,
              ratio: skillSummary.ratio,
              currentEffect: skillSummary.currentEffect,
              nextEffect: skillSummary.nextEffect,
              progressText: skillSummary.progressText,
            ),
          ],
          _TechniqueEquipSuggestionPanel(
            currentCharacter: character,
            technique: technique,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // W12 视觉验收 debug 字段(skillUsage 累计)——仅 debug build 显,
              // release 不向玩家暴露(§12.8 release 无 debug · Phase A 出版美术 hygiene)。
              if (kDebugMode) ...[
                const SizedBox(width: 12),
                Text(
                  'skillUsage: ${technique.skillUsageCount.fold<int>(0, (s, e) => s + e.count)}',
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
              const Spacer(),
              if (!isMain && character.mainTechniqueId != null)
                TextButton(
                  onPressed: () => _onSetAsMain(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: schoolColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: const Text(UiStrings.setAsMainButton),
                ),
              // 根因A:主修可凝练领悟点(闭关挂机攒的 insightPoints)兑换修炼度。
              // H1 批3:入口常驻显点数,0 点时灰显不可点(原靠点击后 SnackBar
              // 才知,§5.7 让玩家先感知状态)。
              if (isMain)
                TextButton(
                  onPressed: character.insightPoints > 0
                      ? () => _onRefineInsight(context, ref)
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: schoolColor,
                    disabledForegroundColor: WuxiaColors.textMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    character.insightPoints > 0
                        ? UiStrings.refineInsightButtonWithPoints(
                            character.insightPoints,
                          )
                        : UiStrings.refineInsightButtonEmpty,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSetAsMain(BuildContext context, WidgetRef ref) async {
    final mainId = character.mainTechniqueId;
    if (mainId == null) return;
    final mainTech = await ref.read(techniqueByIdProvider(mainId).future);
    if (mainTech == null) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          DispelConfirmDialog(character: character, mainTech: mainTech),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final n = ref.read(numbersConfigProvider);
    final result = DispelService.dispel(
      ch: character,
      mainTech: mainTech,
      newMainTech: technique,
      n: n,
    );
    if (!result.success) return;

    // T32 #22b（Phase 5 W6-S2 重构）：落地 Isar putAll ch/oldMain/newMain。
    // 测试旁路：未 init Isar 时 service 为 null,短路。
    final dispelSvc = ref.read(dispelServiceProvider);
    if (dispelSvc != null) {
      await dispelSvc.persistResult(
        ch: character,
        mainTech: mainTech,
        newMainTech: technique,
      );
    }

    ref.invalidate(characterByIdProvider(character.id));
    ref.invalidate(characterAllTechniquesProvider(character.id));
    ref.invalidate(techniqueByIdProvider(mainTech.id));
    ref.invalidate(techniqueByIdProvider(technique.id));

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(UiStrings.dispelSuccess)));
  }

  /// 根因A:凝练领悟点 → 主修修炼度。0 点时提示「闭关挂机可得」,>0 时弹
  /// 二确 dialog「全部凝练」→ [InsightExchangeService.refine] → invalidate + SnackBar。
  Future<void> _onRefineInsight(BuildContext context, WidgetRef ref) async {
    final points = character.insightPoints;
    if (points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.refineInsightNoPoints)),
      );
      return;
    }

    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.refineInsightTitle,
      body: RefineInsightDialogBody(points: points),
      actions: [
        PlaqueButton(
          label: UiStrings.commonCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
        PlaqueButton(
          label: UiStrings.refineInsightConfirm,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final svc = ref.read(insightExchangeServiceProvider);
    if (svc == null) return; // 测试旁路:未 init Isar
    final result = await svc.refine(
      characterId: character.id,
      insightSpend: points,
    );
    if (result.status != InsightRefineStatus.success) return;

    ref.invalidate(characterByIdProvider(character.id));
    ref.invalidate(characterAllTechniquesProvider(character.id));
    ref.invalidate(techniqueByIdProvider(technique.id));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          UiStrings.refineInsightSuccess(
            result.progressGained,
            leveledUp: result.didLevelUp,
          ),
        ),
      ),
    );
  }
}

class _TechniqueEquipSuggestionPanel extends ConsumerWidget {
  const _TechniqueEquipSuggestionPanel({
    required this.currentCharacter,
    required this.technique,
  });

  final Character currentCharacter;
  final Technique technique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!GameRepository.isLoaded) return const SizedBox.shrink();
    final def = GameRepository.instance.techniqueDefs[technique.defId];
    if (def == null) return const SizedBox.shrink();

    final idsAsync = ref.watch(activeCharacterIdsProvider);
    final ids = idsAsync.asData?.value ?? [currentCharacter.id];
    final characters = <Character>[];
    final learnedByCharacter = <int, List<Technique>>{};

    for (final id in ids) {
      final character = ref.watch(characterByIdProvider(id)).asData?.value;
      if (character == null) continue;
      characters.add(character);
      learnedByCharacter[id] =
          ref.watch(characterAllTechniquesProvider(id)).asData?.value ??
          const <Technique>[];
    }

    if (characters.isEmpty) {
      return const SizedBox.shrink();
    }

    final suggestions = TechniqueEquipSuggestionService.buildSuggestions(
      technique: def,
      characters: characters,
      learnedTechniquesByCharacter: learnedByCharacter,
      learningCost: ref.watch(numbersConfigProvider).learningCost,
    );
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: WuxiaColors.inkPanelBottom.withValues(alpha: 0.48),
          border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              UiStrings.techniqueEquipSuggestionTitle,
              style: TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (final suggestion in suggestions) ...[
              _TechniqueEquipSuggestionRow(suggestion: suggestion),
              if (suggestion != suggestions.last) const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }
}

class _TechniqueEquipSuggestionRow extends StatelessWidget {
  const _TechniqueEquipSuggestionRow({required this.suggestion});

  final TechniqueEquipSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final statusColor = suggestion.isEquipable
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            suggestion.character.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _statusText(suggestion.status),
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            _detailText(suggestion),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  static String _statusText(TechniqueEquipSuggestionStatus status) {
    return switch (status) {
      TechniqueEquipSuggestionStatus.alreadyMain =>
        UiStrings.techniqueEquipSuggestionAlreadyMain,
      TechniqueEquipSuggestionStatus.alreadyAssist =>
        UiStrings.techniqueEquipSuggestionAlreadyAssist,
      TechniqueEquipSuggestionStatus.readyForMain =>
        UiStrings.techniqueEquipSuggestionReadyMain,
      TechniqueEquipSuggestionStatus.readyForAssist =>
        UiStrings.techniqueEquipSuggestionReadyAssist,
      TechniqueEquipSuggestionStatus.realmLocked =>
        UiStrings.techniqueEquipSuggestionRealmLocked,
      TechniqueEquipSuggestionStatus.assistSlotsFull =>
        UiStrings.techniqueEquipSuggestionAssistFull,
      TechniqueEquipSuggestionStatus.insufficientInsight =>
        UiStrings.techniqueEquipSuggestionInsightLocked,
    };
  }

  static String _detailText(TechniqueEquipSuggestion suggestion) {
    if (suggestion.status == TechniqueEquipSuggestionStatus.realmLocked) {
      return UiStrings.techniqueEquipBlockRealm(
        EnumL10n.techniqueTier(suggestion.currentCap),
        EnumL10n.techniqueTier(suggestion.requiredTier),
      );
    }
    if (suggestion.status ==
        TechniqueEquipSuggestionStatus.insufficientInsight) {
      return UiStrings.techniqueEquipBlockInsight(
        suggestion.character.insightPoints,
        suggestion.requiredInsight,
      );
    }
    final reasons = suggestion.reasons
        .map(_reasonText)
        .where((s) => s.isNotEmpty)
        .toList();
    if (reasons.isEmpty) return UiStrings.techniqueEquipNoReason;
    return reasons.join(UiStrings.codexValueSeparator);
  }

  static String _reasonText(TechniqueEquipSuggestionReason reason) {
    return switch (reason) {
      TechniqueEquipSuggestionReason.sameSchool =>
        UiStrings.techniqueEquipReasonSameSchool,
      TechniqueEquipSuggestionReason.fillsMainSlot =>
        UiStrings.techniqueEquipReasonFillsMain,
      TechniqueEquipSuggestionReason.fillsAssistSlot =>
        UiStrings.techniqueEquipReasonFillsAssist,
      TechniqueEquipSuggestionReason.tierFitsRealm =>
        UiStrings.techniqueEquipReasonTierFits,
      TechniqueEquipSuggestionReason.highEnlightenment =>
        UiStrings.techniqueEquipReasonHighEnlightenment,
      TechniqueEquipSuggestionReason.alreadyPracticed =>
        UiStrings.techniqueEquipReasonAlreadyPracticed,
    };
  }
}

class RefineInsightDialogBody extends StatelessWidget {
  const RefineInsightDialogBody({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 86,
          child: CeremonyImagePanel(
            assetPath: WuxiaUi.ceremonyTechniqueScroll,
            padding: EdgeInsets.zero,
            imageOpacity: 0.54,
            paperVeilOpacity: 0.34,
            child: SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          UiStrings.refineInsightBody(points),
          style: const TextStyle(
            color: WuxiaUi.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _RefineInsightLine(
          icon: Icons.tips_and_updates_outlined,
          text: UiStrings.refineInsightSpendLine(points),
        ),
        const SizedBox(height: 6),
        const _RefineInsightLine(
          icon: Icons.auto_stories_outlined,
          text: UiStrings.refineInsightTargetLine,
        ),
        const SizedBox(height: 10),
        const Text(
          UiStrings.refineInsightCeremonyHint,
          style: TextStyle(color: WuxiaUi.ink2, fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _RefineInsightLine extends StatelessWidget {
  const _RefineInsightLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: WuxiaUi.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: WuxiaColors.resultHighlight, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// B4 主修 hero 区（出版美术 · 样图 03）：meditation 打坐图 + 内丹克制金光点
/// （§0.6 关键节点适度彩光，不做大光效）+ 主修段位阶梯（[_LayerLadder]）。
class _MainTechniqueHero extends StatelessWidget {
  const _MainTechniqueHero({required this.mainTech});

  final Technique mainTech;

  @override
  Widget build(BuildContext context) {
    final schoolColor = WuxiaColors.schoolColor(mainTech.school);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WuxiaColors.inkPanelTop, WuxiaColors.inkPanelBottom],
        ),
        border: Border.all(color: schoolColor, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/ui/meditation_icon.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.self_improvement,
                    size: 52,
                    color: schoolColor,
                  ),
                ),
                // 内丹：克制金光点（§0.6 关键节点适度彩光）。
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WuxiaColors.resultHighlight,
                      boxShadow: [
                        BoxShadow(
                          color: WuxiaColors.resultHighlight.withValues(
                            alpha: 0.6,
                          ),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UiStrings.techniquePanelMainHeroLabel,
                  style: TextStyle(
                    color: schoolColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  EnumL10n.cultivationLayer(mainTech.cultivationLayer),
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _LayerLadder(
                  current: mainTech.cultivationLayer,
                  schoolColor: schoolColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// B5 段位进度阶梯（出版美术 · 样图 03）：9 层 [CultivationLayer] 横向分段，
/// 已过=流派色 / 当前=金 / 未到=灰，下方金徽章显当前层名 + n/9 进度。
class _LayerLadder extends StatelessWidget {
  const _LayerLadder({required this.current, required this.schoolColor});

  final CultivationLayer current;
  final Color schoolColor;

  @override
  Widget build(BuildContext context) {
    final layers = CultivationLayer.values;
    final curIdx = current.index;
    // D：修炼度五要素「当前/下一阶效果」= 当前层 / 下一层伤害倍率。
    final mult = GameRepository.instance.numbers.cultivationMultiplier;
    final curMult = mult[current] ?? 1.0;
    final isMaxLayer = curIdx >= layers.length - 1;
    final nextMultText = isMaxLayer
        ? UiStrings.cultivationMaxLayer
        : UiStrings.cultivationNextDamageMult(
            mult[layers[curIdx + 1]] ?? curMult,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < layers.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < curIdx
                        ? schoolColor
                        : i == curIdx
                        ? WuxiaColors.resultHighlight
                        : WuxiaColors.barTrack,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: WuxiaColors.resultHighlight.withValues(alpha: 0.15),
                border: Border.all(color: WuxiaColors.resultHighlight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                EnumL10n.cultivationLayer(current),
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              UiStrings.layerProgressLabel(curIdx + 1, layers.length),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // D：层名徽章下一行伤害倍率（当前效果 · 下一阶效果）。
        Text(
          '${UiStrings.cultivationDamageMult(curMult)} · $nextMultText',
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// B3 秘籍质感（出版美术）：seal_red 绛红印章叠 [CultivationLayer] 层名，
/// 替代原裸文字。印章图缺失（widget test）走 shrink，退化为纯层名文字。
class _SealBadge extends StatelessWidget {
  const _SealBadge({required this.layer});

  final CultivationLayer layer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/ui/seal_red.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          Text(
            EnumL10n.cultivationLayer(layer),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
