import '../../../shared/strings.dart';
import 'offline_passive_service.dart';
import 'offline_recap_service.dart';

class OfflineRecapDetail {
  const OfflineRecapDetail({
    required this.groups,
    required this.experience,
    required this.silver,
    required this.materialQuantity,
    required this.techniqueLearnPoints,
    required this.skillProficiencyPoints,
    required this.equipmentDropCount,
    required this.equipmentDropPending,
  });

  final List<OfflineRecapDetailGroup> groups;
  final int experience;
  final int silver;
  final int materialQuantity;
  final int techniqueLearnPoints;
  final int skillProficiencyPoints;
  final int equipmentDropCount;
  final bool equipmentDropPending;

  List<String> get rows => [for (final group in groups) ...group.rows];
}

class OfflineRecapDetailGroup {
  const OfflineRecapDetailGroup({required this.title, required this.rows});

  final String title;
  final List<String> rows;
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
    final settlementRows = [
      UiStrings.offlineRecapAwayDetail(_formatHours(recap.awayHours)),
      UiStrings.offlineRecapSettledDetail(_formatHours(recap.settledHours)),
      _limitReasonText(recap.limitReason),
      UiStrings.offlineRecapParityDetail,
    ];
    final cultivationRows = _nonEmptyRows([
      recap.estimatedExperience > 0
          ? UiStrings.offlineRecapExperienceDetail(recap.estimatedExperience)
          : null,
      recap.estimatedTechniqueLearnPoints > 0
          ? UiStrings.offlineRecapTechniqueLearnDetail(
              recap.estimatedTechniqueLearnPoints,
            )
          : null,
    ]);
    final materialRows = _nonEmptyRows([
      recap.estimatedSilver > 0
          ? UiStrings.offlineRecapSilverDetail(recap.estimatedSilver)
          : null,
      materialQuantity > 0
          ? UiStrings.offlineRecapMaterialDetail(
              _materialText(
                mojianshi: recap.estimatedMojianshi,
                itemRewards: recap.estimatedItemRewards,
                itemNameOf: itemNameOf,
              ),
            )
          : null,
    ]);
    final gainGroups = _gainGroups(
      cultivationRows: cultivationRows,
      materialRows: materialRows,
      emptyGroupTitle: UiStrings.offlineRecapRetreatGainGroupTitle,
    );
    final detail = OfflineRecapDetail(
      experience: recap.estimatedExperience,
      silver: recap.estimatedSilver,
      materialQuantity: materialQuantity,
      techniqueLearnPoints: recap.estimatedTechniqueLearnPoints,
      skillProficiencyPoints: 0,
      equipmentDropCount: 0,
      equipmentDropPending: true,
      groups: [
        OfflineRecapDetailGroup(
          title: UiStrings.offlineRecapSettlementGroupTitle,
          rows: settlementRows,
        ),
        ...gainGroups,
        OfflineRecapDetailGroup(
          title: UiStrings.offlineRecapCollectGroupTitle,
          rows: [
            UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapDropPending),
          ],
        ),
      ],
    );
    return detail;
  }

  static OfflineRecapDetail forPassive(PassiveYield yield_) {
    final cultivationRows = _nonEmptyRows([
      yield_.experience > 0
          ? UiStrings.offlineRecapExperienceDetail(yield_.experience)
          : null,
    ]);
    final materialRows = _nonEmptyRows([
      yield_.mojianshi > 0
          ? UiStrings.offlineRecapMaterialDetail(
              _materialText(mojianshi: yield_.mojianshi),
            )
          : null,
    ]);
    final gainGroups = _gainGroups(
      cultivationRows: cultivationRows,
      materialRows: materialRows,
      emptyGroupTitle: UiStrings.offlineRecapPassiveGainGroupTitle,
    );
    final detail = OfflineRecapDetail(
      experience: yield_.experience,
      silver: 0,
      materialQuantity: yield_.mojianshi,
      techniqueLearnPoints: 0,
      skillProficiencyPoints: 0,
      equipmentDropCount: 0,
      equipmentDropPending: false,
      groups: [
        OfflineRecapDetailGroup(
          title: UiStrings.offlineRecapSettlementGroupTitle,
          rows: [
            UiStrings.offlineRecapAwayDetail(_formatHours(yield_.awayHours)),
            UiStrings.offlineRecapSettledDetail(
              _formatHours(yield_.settledHours),
            ),
            yield_.isCapped
                ? UiStrings.offlineRecapLimitSystemCap
                : UiStrings.offlineRecapLimitInProgress,
            UiStrings.offlineRecapParityDetail,
          ],
        ),
        ...gainGroups,
      ],
    );
    return detail;
  }

  static List<OfflineRecapDetailGroup> _gainGroups({
    required List<String> cultivationRows,
    required List<String> materialRows,
    required String emptyGroupTitle,
  }) {
    if (cultivationRows.isEmpty && materialRows.isEmpty) {
      return [
        OfflineRecapDetailGroup(
          title: emptyGroupTitle,
          rows: [UiStrings.offlineRecapNoGainsDetail],
        ),
      ];
    }
    return [
      if (cultivationRows.isNotEmpty)
        OfflineRecapDetailGroup(
          title: UiStrings.offlineRecapRetreatGainGroupTitle,
          rows: cultivationRows,
        ),
      if (materialRows.isNotEmpty)
        OfflineRecapDetailGroup(
          title: UiStrings.offlineRecapMaterialGroupTitle,
          rows: materialRows,
        ),
    ];
  }

  static List<String> _nonEmptyRows(List<String?> rows) =>
      rows.whereType<String>().toList();

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
      if (entry.value <= 0) continue;
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
