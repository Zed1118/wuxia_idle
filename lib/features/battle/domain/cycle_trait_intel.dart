import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';

class CycleTraitIntelEntry {
  const CycleTraitIntelEntry({
    required this.id,
    required this.name,
    required this.shortText,
    required this.detailText,
  });

  final String id;
  final String name;
  final String shortText;
  final String detailText;
}

class CycleTraitIntel {
  const CycleTraitIntel._();

  static List<CycleTraitIntelEntry> entriesFor({
    required CycleEvolutionConfig config,
    required int cycle,
    required bool isBoss,
    required bool isTower,
  }) {
    final ids =
        config
            .traitsFor(cycle: cycle, isBoss: isBoss, isTower: isTower)
            .toList()
          ..sort();
    return [
      for (final id in ids)
        CycleTraitIntelEntry(
          id: id,
          name: UiStrings.cycleTraitName(id),
          shortText: _shortText(config, cycle, id),
          detailText: _detailText(config, cycle, id),
        ),
    ];
  }

  static String summaryLabel(int cycle, List<CycleTraitIntelEntry> entries) {
    return UiStrings.cycleTraitSummary(
      cycle,
      entries.map((e) => e.name).toList(growable: false),
    );
  }

  static String _shortText(CycleEvolutionConfig config, int cycle, String id) {
    return switch (id) {
      'yuti' => UiStrings.cycleTraitShortYuti(
        UiStrings.percent(_yutiBonus(config, cycle)),
      ),
      'zhenqi' => UiStrings.cycleTraitShortZhenqi(
        UiStrings.percent(config.traits.zhenqi.internalForcePct),
      ),
      'fanzhen' => UiStrings.cycleTraitShortFanzhen,
      'shipo' => UiStrings.cycleTraitShortShipo,
      'ningjia' => UiStrings.cycleTraitShortNingjia,
      _ => UiStrings.cycleTraitShortUnknown(id),
    };
  }

  static String _detailText(CycleEvolutionConfig config, int cycle, String id) {
    return switch (id) {
      'yuti' => UiStrings.cycleTraitDetailYuti(
        UiStrings.percent(_yutiBonus(config, cycle)),
      ),
      'zhenqi' => UiStrings.cycleTraitDetailZhenqi(
        UiStrings.percent(config.traits.zhenqi.internalForcePct),
      ),
      'fanzhen' => UiStrings.cycleTraitDetailFanzhen(
        config.traits.fanzhen.ticks,
        config.traits.fanzhen.damagePerTick,
      ),
      'shipo' => UiStrings.cycleTraitDetailShipo,
      'ningjia' => UiStrings.cycleTraitDetailNingjia(
        UiStrings.percent(1 - config.traits.ningjia.critDamageTakenMult),
      ),
      _ => UiStrings.cycleTraitDetailUnknown(id),
    };
  }

  static double _yutiBonus(CycleEvolutionConfig config, int cycle) {
    return cycle >= 3
        ? config.traits.yuti.defenseRateBonusC3
        : config.traits.yuti.defenseRateBonusC2;
  }
}
