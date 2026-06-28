import '../../../shared/strings.dart';
import 'offline_passive_service.dart';
import 'offline_recap_service.dart';

class OfflineRecapDetail {
  const OfflineRecapDetail({
    required this.rows,
    required this.experience,
    required this.silver,
    required this.materialQuantity,
    required this.techniqueLearnPoints,
    required this.skillProficiencyPoints,
    required this.equipmentDropCount,
    required this.equipmentDropPending,
  });

  final List<String> rows;
  final int experience;
  final int silver;
  final int materialQuantity;
  final int techniqueLearnPoints;
  final int skillProficiencyPoints;
  final int equipmentDropCount;
  final bool equipmentDropPending;
}

class OfflineRecapDetailFormatter {
  OfflineRecapDetailFormatter._();

  static OfflineRecapDetail forRetreat(
    OfflineRecap recap, {
    String Function(String defId)? itemNameOf,
  }) {
    final materialQuantity =
        recap.estimatedMojianshi +
        recap.estimatedItemRewards.values.fold<int>(0, (a, b) => a + b);
    final detail = OfflineRecapDetail(
      experience: recap.estimatedExperience,
      silver: recap.estimatedSilver,
      materialQuantity: materialQuantity,
      techniqueLearnPoints: recap.estimatedTechniqueLearnPoints,
      skillProficiencyPoints: 0,
      equipmentDropCount: 0,
      equipmentDropPending: true,
      rows: [
        UiStrings.offlineRecapAwayDetail(_formatHours(recap.awayHours)),
        UiStrings.offlineRecapSettledDetail(_formatHours(recap.settledHours)),
        UiStrings.offlineRecapExperienceDetail(recap.estimatedExperience),
        UiStrings.offlineRecapSilverDetail(recap.estimatedSilver),
        UiStrings.offlineRecapMaterialDetail(
          _materialText(
            mojianshi: recap.estimatedMojianshi,
            itemRewards: recap.estimatedItemRewards,
            itemNameOf: itemNameOf,
          ),
        ),
        UiStrings.offlineRecapTechniqueSkillDetail(
          recap.estimatedTechniqueLearnPoints,
          0,
        ),
        UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapDropPending),
        _limitReasonText(recap.limitReason),
      ],
    );
    return detail;
  }

  static OfflineRecapDetail forPassive(PassiveYield yield_) {
    final detail = OfflineRecapDetail(
      experience: yield_.experience,
      silver: 0,
      materialQuantity: yield_.mojianshi,
      techniqueLearnPoints: 0,
      skillProficiencyPoints: 0,
      equipmentDropCount: 0,
      equipmentDropPending: false,
      rows: [
        UiStrings.offlineRecapAwayDetail(_formatHours(yield_.awayHours)),
        UiStrings.offlineRecapSettledDetail(_formatHours(yield_.settledHours)),
        UiStrings.offlineRecapExperienceDetail(yield_.experience),
        UiStrings.offlineRecapSilverDetail(0),
        UiStrings.offlineRecapMaterialDetail(
          _materialText(mojianshi: yield_.mojianshi),
        ),
        UiStrings.offlineRecapTechniqueSkillDetail(0, 0),
        UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapNoDrop),
        yield_.isCapped
            ? UiStrings.offlineRecapLimitSystemCap
            : UiStrings.offlineRecapLimitInProgress,
      ],
    );
    return detail;
  }

  static String _formatHours(double hours) {
    final rounded = (hours * 10).round() / 10;
    if (rounded == rounded.truncateToDouble()) {
      return UiStrings.hoursAmountLabel('${rounded.toInt()}');
    }
    return UiStrings.hoursAmountLabel('$rounded');
  }

  static String _materialText({
    required int mojianshi,
    Map<String, int> itemRewards = const {},
    String Function(String defId)? itemNameOf,
  }) {
    final parts = <String>[];
    if (mojianshi > 0) {
      parts.add(UiStrings.offlineRecapMaterialPartMojianshi(mojianshi));
    }
    for (final entry in itemRewards.entries) {
      parts.add(
        UiStrings.offlineRecapMaterialPart(
          itemNameOf?.call(entry.key) ?? entry.key,
          entry.value,
        ),
      );
    }
    if (parts.isEmpty) return UiStrings.offlineRecapNoDrop;
    return parts.join(UiStrings.offlineRecapDetailSeparator);
  }

  static String _limitReasonText(OfflineRecapLimitReason reason) {
    switch (reason) {
      case OfflineRecapLimitReason.inProgress:
        return UiStrings.offlineRecapLimitInProgress;
      case OfflineRecapLimitReason.plannedDuration:
        return UiStrings.offlineRecapLimitPlanned;
      case OfflineRecapLimitReason.systemCap:
        return UiStrings.offlineRecapLimitSystemCap;
    }
  }
}
