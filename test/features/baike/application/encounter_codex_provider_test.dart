import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/baike/application/encounter_codex_provider.dart';

EncounterDef _def(String id, EncounterType type, {Festival? festival}) =>
    EncounterDef(
      id: id,
      type: type,
      trigger: EncounterTrigger(festivalRequired: festival),
      baseProbability: 0.1,
      outcomeMapping: const {},
    );

void main() {
  group('groupEncounters', () {
    test('3 段分组：领悟/奇缘/节庆', () {
      final defs = [
        _def('a', EncounterType.techniqueInsight),
        _def('b', EncounterType.fortuneEvent),
        _def('c', EncounterType.fortuneEvent, festival: Festival.values.first),
      ];
      final groups = groupEncounters(
        defs: defs,
        triggeredIds: {'a'},
        titles: {'a': '听雨悟剑'},
      );
      expect(groups.length, 3);
      final insight =
          groups.firstWhere((g) => g.kind == EncounterGroupKind.insight);
      expect(insight.entries.single.def.id, 'a');
      expect(insight.entries.single.isTriggered, true);
      expect(insight.entries.single.title, '听雨悟剑');
      final festival =
          groups.firstWhere((g) => g.kind == EncounterGroupKind.festival);
      expect(festival.entries.single.def.id, 'c');
      final fortune =
          groups.firstWhere((g) => g.kind == EncounterGroupKind.fortune);
      expect(fortune.entries.single.isTriggered, false);
      expect(fortune.entries.single.title, isNull);
    });

    test('进度计数：总 + 段内', () {
      final defs = [
        _def('a', EncounterType.techniqueInsight),
        _def('b', EncounterType.techniqueInsight),
      ];
      final groups = groupEncounters(
        defs: defs,
        triggeredIds: {'a'},
        titles: {'a': 'X'},
      );
      final insight =
          groups.firstWhere((g) => g.kind == EncounterGroupKind.insight);
      expect(insight.triggeredCount, 1);
      expect(insight.entries.length, 2);
    });

    test('空段不产出(无该类奇遇时该段缺省)', () {
      final defs = [_def('a', EncounterType.techniqueInsight)];
      final groups = groupEncounters(
        defs: defs,
        triggeredIds: const {},
        titles: const {},
      );
      expect(groups.map((g) => g.kind), [EncounterGroupKind.insight]);
    });
  });
}
