import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';

/// P4.1 1.1 Q6A · encounter-triggered 门派招收 confirm dialog。
///
/// 触发路径:`encounter_hook` 玩家选 `accept_recruit` outcome → 弹本 dialog
/// 二次确认是否真招入(spec §4 Q4=C confirm dialog 体例)。
///
/// 沿 `RecruitmentDialog._onAccept` AlertDialog 2 按钮 confirm pattern(P1.1
/// 体例)·返 bool? true=招入 / false=婉拒 / null=dismiss(同 false)。
Future<bool> showSectRecruitConfirmDialog(
  BuildContext context,
  SectCandidateDef candidate,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      backgroundColor: WuxiaColors.panel,
      title: const Text(
        UiStrings.sectEncounterRecruitConfirmTitle,
        style: TextStyle(color: WuxiaColors.textPrimary),
      ),
      content: _CandidateInfo(candidate: candidate),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(UiStrings.sectEncounterRecruitDecline),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: WuxiaColors.resultHighlight,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(UiStrings.sectEncounterRecruitAccept),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _CandidateInfo extends StatelessWidget {
  const _CandidateInfo({required this.candidate});

  final SectCandidateDef candidate;

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

  @override
  Widget build(BuildContext context) {
    final schoolColor = candidate.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(candidate.school!);
    final ap = candidate.attributeProfile;
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidate.portraitPath != null) ...[
            PortraitFrame(
              portraitPath: candidate.portraitPath,
              size: 96,
              borderColor: schoolColor,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Text(
                candidate.name,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: schoolColor),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _schoolLabel(candidate.school),
                  style: TextStyle(color: schoolColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _AttrChip(
                  label: UiStrings.recruitmentAttrConstitutionLabel,
                  value: ap.constitution),
              _AttrChip(
                  label: UiStrings.recruitmentAttrEnlightenmentLabel,
                  value: ap.enlightenment),
              _AttrChip(
                  label: UiStrings.recruitmentAttrAgilityLabel,
                  value: ap.agility),
              _AttrChip(
                  label: UiStrings.recruitmentAttrFortuneLabel,
                  value: ap.fortune),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            candidate.lore,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
            ),
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
