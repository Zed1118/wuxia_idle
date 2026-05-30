import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../dispel/application/dispel_service.dart';
import '../../dispel/application/dispel_service_providers.dart';
import '../../cultivation/application/insight_exchange_service.dart';
import '../../cultivation/application/insight_exchange_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
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
      body: SafeArea(
        child: chAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (c) {
            if (c == null) {
              return const Center(
                child: Text(
                  '角色不存在',
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            return techsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: SelectableText(
                  'load error: $e',
                  style: const TextStyle(color: WuxiaColors.hpLow),
                ),
              ),
              data: (techs) => _Body(character: c, techniques: techs),
            );
          },
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final tier in sortedTiers) ...[
            // M4 Stage 3 美术(2026-05-21):tier section 起手 7 阶卷轴 cover banner。
            // 约定路径 assets/techniques/tier_<name>.png,无图走 errorBuilder shrink
            // (widget test 不加载 pubspec assets,memory feedback_image_asset_error_builder)。
            Image.asset(
              'assets/techniques/tier_${tier.name}.png',
              width: double.infinity,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                EnumL10n.techniqueTier(tier),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

class _TechniqueTile extends ConsumerWidget {
  const _TechniqueTile({required this.character, required this.technique});

  final Character character;
  final Technique technique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMain = technique.role == TechniqueRole.main;
    final schoolColor = WuxiaColors.schoolColor(technique.school);
    final borderColor =
        isMain ? schoolColor : schoolColor.withValues(alpha: 0.6);
    final progress = technique.cultivationProgressToNext == 0
        ? 0.0
        : (technique.cultivationProgress / technique.cultivationProgressToNext)
            .clamp(0.0, 1.0)
            .toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
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
              Text(
                EnumL10n.cultivationLayer(technique.cultivationLayer),
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: WuxiaColors.barTrack,
            valueColor: AlwaysStoppedAnimation<Color>(schoolColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                UiStrings.cultivationProgress(
                  technique.cultivationProgress,
                  technique.cultivationProgressToNext,
                ),
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              // W12 fix: 视觉验收 debug 字段——skillUsage 累计总数
              // progress 只反映主修升层节奏，看不到「这场战斗到底累了几次 skill」
              Text(
                'skillUsage: ${technique.skillUsageCount.fold<int>(0, (s, e) => s + e.count)}',
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 11,
                ),
              ),
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
    final mainTech =
        await ref.read(techniqueByIdProvider(mainId).future);
    if (mainTech == null) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DispelConfirmDialog(
        character: character,
        mainTech: mainTech,
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(UiStrings.dispelSuccess)),
    );
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiStrings.refineInsightTitle),
        content: Text(UiStrings.refineInsightBody(points)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(UiStrings.commonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: WuxiaColors.resultHighlight,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(UiStrings.refineInsightConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final svc = ref.read(insightExchangeServiceProvider);
    if (svc == null) return; // 测试旁路:未 init Isar
    final result =
        await svc.refine(characterId: character.id, insightSpend: points);
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
