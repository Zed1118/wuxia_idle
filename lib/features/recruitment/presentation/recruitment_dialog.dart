import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/recruit_candidate_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/ink_empty_state.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/application/tutorial_service.dart';
import '../application/recruitment_providers.dart';
import '../application/recruitment_service.dart';

/// 收徒弹窗(P1.1 A1 E.1,GDD §7.1)。
///
/// audit doc `p1_1_a1_recruitment_audit_2026-05-21.md` 方案 3 + 5 决策:
/// - T1 主角境界突破到一流 → tutorial step 6 banner 点击触发 → push 本 dialog
/// - N1 3 候选 NPC 来自 `data/recruit_candidates.yaml`
/// - I2 inactive 池语义,active 上限不动
/// - D2.b 3 NPC 横向卡 (刚猛 / 灵巧 / 平衡)
/// - D3.a 一次性 only(拜师或谢绝都 markOffered=true 不可重触)
/// - D4.b 完整 UI(portrait + 4 属性 + 流派 chip + 起手心法/装备 + lore)
///
/// **导航语义**:全屏 push(不是 showDialog),沿 LineagePanelScreen 体例;
/// 退出走 Navigator.pop 返回 MainMenu。
///
/// **副作用**:
/// 1. 拜师成功 → 弹 confirm → service.acceptCandidate(isar.writeTxn 内)→
///    pop + 主线 invalidate(recruitmentOfferedProvider) + snack
/// 2. 谢绝 → 弹 confirm → service.declineRecruitment(isar.writeTxn 内)→
///    pop + 主线 invalidate + snack
class RecruitmentDialog extends ConsumerStatefulWidget {
  const RecruitmentDialog({super.key});

  @override
  ConsumerState<RecruitmentDialog> createState() => _RecruitmentDialogState();
}

class _RecruitmentDialogState extends ConsumerState<RecruitmentDialog> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final candidates = RecruitmentService.getCandidates();
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.recruitmentDialogTitle),
        leading: BackButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      UiStrings.recruitmentDialogIntro,
                      style: TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                  if (candidates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: InkEmptyState(
                        variant: InkEmptyStateVariant.unavailable,
                        title: UiStrings.recruitmentCandidatesMissingTitle,
                        body: UiStrings.recruitmentCandidatesMissingBody,
                        icon: Icons.person_search_outlined,
                      ),
                    )
                  else
                    for (var i = 0; i < candidates.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _CandidateCard(
                        candidate: candidates[i],
                        onAccept: _submitting
                            ? null
                            : () => _onAccept(candidates[i]),
                      ),
                    ],
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PlaqueButton(
                      label: UiStrings.recruitmentDeclineButton,
                      disabled: _submitting,
                      onTap: _submitting ? null : _onDecline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept(RecruitCandidateDef candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PaperDialog(
        title: UiStrings.recruitmentConfirmTitle,
        body: Text(UiStrings.recruitmentConfirmBody(candidate.name)),
        actions: [
          PlaqueButton(
            label: UiStrings.recruitmentConfirmNo,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          PlaqueButton(
            label: UiStrings.recruitmentConfirmYes,
            primary: true,
            autofocus: true,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    setState(() => _submitting = true);
    try {
      final svc = RecruitmentService(isar);
      await isar.writeTxn(() => svc.acceptCandidate(candidate.id));
      // tutorial step 6 banner 同步关闭(markHintRead)
      final tutorialSvc = TutorialService(isar);
      await isar.writeTxn(() => tutorialSvc.markHintRead(6));
      ref.invalidate(recruitmentOfferedProvider);
      ref.invalidate(recruitedDiscipleIdsProvider);
      ref.invalidate(currentTutorialHintsReadProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UiStrings.recruitmentSuccessSnack(candidate.name)),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PaperDialog(
        title: UiStrings.recruitmentDeclineConfirmTitle,
        body: const Text(UiStrings.recruitmentDeclineConfirmBody),
        actions: [
          PlaqueButton(
            label: UiStrings.recruitmentConfirmNo,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          PlaqueButton(
            label: UiStrings.recruitmentConfirmYes,
            primary: true,
            autofocus: true,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    setState(() => _submitting = true);
    try {
      final svc = RecruitmentService(isar);
      await isar.writeTxn(() => svc.declineRecruitment());
      final tutorialSvc = TutorialService(isar);
      await isar.writeTxn(() => tutorialSvc.markHintRead(6));
      ref.invalidate(recruitmentOfferedProvider);
      ref.invalidate(currentTutorialHintsReadProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.recruitmentDeclineSnack)),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, this.onAccept});

  final RecruitCandidateDef candidate;
  final VoidCallback? onAccept;

  String _schoolLabel(TechniqueSchool? s) {
    switch (s) {
      case TechniqueSchool.gangMeng:
        return UiStrings.recruitmentSchoolGangMengLabel;
      case TechniqueSchool.lingQiao:
        return UiStrings.recruitmentSchoolLingQiaoLabel;
      case TechniqueSchool.yinRou:
        return UiStrings.recruitmentSchoolYinRouLabel;
      case null:
        return UiStrings.recruitmentSchoolNoneLabel;
    }
  }

  String _techName(String id) {
    if (!GameRepository.isLoaded) return id;
    return GameRepository.instance.techniqueDefs[id]?.name ?? id;
  }

  String _equipName(String id) {
    if (!GameRepository.isLoaded) return id;
    return GameRepository.instance.equipmentDefs[id]?.name ?? id;
  }

  Color? _equipTierColor(String id) {
    if (!GameRepository.isLoaded) return null;
    final def = GameRepository.instance.equipmentDefs[id];
    if (def == null) return null;
    return tierColorForEquipment(def.tier);
  }

  @override
  Widget build(BuildContext context) {
    final schoolColor = candidate.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(candidate.school!);
    final schoolLabel = _schoolLabel(candidate.school);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final portraitSize = compact ? 84.0 : 96.0;
        final portrait = PortraitFrame(
          portraitPath: candidate.portraitPath,
          size: portraitSize,
          borderColor: schoolColor,
          placeholderText: candidate.name,
        );
        final summary = _CandidateSummary(
          candidate: candidate,
          schoolColor: schoolColor,
          schoolLabel: schoolLabel,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            border: Border.all(color: WuxiaColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: portrait),
                    const SizedBox(height: 12),
                    summary,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    portrait,
                    const SizedBox(width: 14),
                    Expanded(child: summary),
                  ],
                ),
              const SizedBox(height: 12),
              _ChipRow(
                label: UiStrings.recruitmentStartingTechniqueLabel,
                items: candidate.startingTechniqueIds.isEmpty
                    ? const [UiStrings.recruitmentNoStartingTechnique]
                    : candidate.startingTechniqueIds.map(_techName).toList(),
                itemColor: schoolColor,
              ),
              const SizedBox(height: 6),
              _ChipRow(
                label: UiStrings.recruitmentStartingEquipmentLabel,
                items: candidate.startingEquipmentIds.map(_equipName).toList(),
                itemColors: candidate.startingEquipmentIds
                    .map(_equipTierColor)
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(
                candidate.lore,
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 112),
                  child: PlaqueButton(
                    label: UiStrings.recruitmentAcceptButton,
                    primary: true,
                    disabled: onAccept == null,
                    onTap: onAccept,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CandidateSummary extends StatelessWidget {
  const _CandidateSummary({
    required this.candidate,
    required this.schoolColor,
    required this.schoolLabel,
  });

  final RecruitCandidateDef candidate;
  final Color schoolColor;
  final String schoolLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              candidate.name,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: schoolColor),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                schoolLabel,
                style: TextStyle(color: schoolColor, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AttrRow(profile: candidate.attributeProfile),
      ],
    );
  }
}

class _AttrRow extends StatelessWidget {
  const _AttrRow({required this.profile});

  // ignore: library_private_types_in_public_api
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _AttrItem(
          label: UiStrings.recruitmentAttrConstitutionLabel,
          value: profile.constitution,
        ),
        _AttrItem(
          label: UiStrings.recruitmentAttrEnlightenmentLabel,
          value: profile.enlightenment,
        ),
        _AttrItem(
          label: UiStrings.recruitmentAttrAgilityLabel,
          value: profile.agility,
        ),
        _AttrItem(
          label: UiStrings.recruitmentAttrFortuneLabel,
          value: profile.fortune,
        ),
      ],
    );
  }
}

class _AttrItem extends StatelessWidget {
  const _AttrItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          TextSpan(
            text: '$value',
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.items,
    this.itemColor,
    this.itemColors,
  });

  final String label;
  final List<String> items;
  final Color? itemColor;
  final List<Color?>? itemColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var i = 0; i < items.length; i++)
                _Chip(
                  text: items[i],
                  color: itemColors != null && i < itemColors!.length
                      ? itemColors![i]
                      : itemColor,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? WuxiaColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: TextStyle(color: c, fontSize: 11)),
    );
  }
}
