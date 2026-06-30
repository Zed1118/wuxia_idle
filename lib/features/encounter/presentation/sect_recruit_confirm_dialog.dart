import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

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
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final maxWidth = (size.width - 32).clamp(320.0, 460.0).toDouble();
      return Dialog(
        backgroundColor: WuxiaColors.panel,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: WuxiaColors.border),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  UiStrings.sectEncounterRecruitConfirmTitle,
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _CandidateInfo(candidate: candidate),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PlaqueButton(
                      label: UiStrings.sectEncounterRecruitDecline,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                    PlaqueButton(
                      label: UiStrings.sectEncounterRecruitAccept,
                      primary: true,
                      autofocus: true,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidate.portraitPath != null) ...[
            Center(
              child: PortraitFrame(
                portraitPath: candidate.portraitPath,
                size: 88,
                borderColor: schoolColor,
              ),
            ),
            const SizedBox(height: 14),
          ],
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
                value: ap.constitution,
              ),
              _AttrChip(
                label: UiStrings.recruitmentAttrEnlightenmentLabel,
                value: ap.enlightenment,
              ),
              _AttrChip(
                label: UiStrings.recruitmentAttrAgilityLabel,
                value: ap.agility,
              ),
              _AttrChip(
                label: UiStrings.recruitmentAttrFortuneLabel,
                value: ap.fortune,
              ),
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
