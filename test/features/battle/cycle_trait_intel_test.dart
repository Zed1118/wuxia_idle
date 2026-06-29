import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/cycle_trait_intel.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('cycle 1 主线无词条说明', () {
    final entries = CycleTraitIntel.entriesFor(
      config: GameRepository.instance.numbers.cycleEvolution,
      cycle: 1,
      isBoss: false,
      isTower: false,
    );

    expect(entries, isEmpty);
  });

  test('cycle 2 主线显示御体与真气说明', () {
    final entries = CycleTraitIntel.entriesFor(
      config: GameRepository.instance.numbers.cycleEvolution,
      cycle: 2,
      isBoss: false,
      isTower: false,
    );

    expect(entries.map((e) => e.id), ['yuti', 'zhenqi']);
    expect(entries.map((e) => e.name), ['御体', '真气']);
    expect(entries.first.shortText, contains('8%'));
    expect(entries.first.detailText, isNot(startsWith('御体：御体')));
    expect(
      entries.first.detailText,
      contains(UiStrings.combatTermLabel(CombatTerm.yuti)),
    );
    expect(entries.first.detailText, isNot(contains('玉体')));
    expect(entries.last.detailText, contains('多放一次大招'));
    expect(
      CycleTraitIntel.summaryLabel(2, entries),
      UiStrings.cycleTraitSummary(2, const ['御体', '真气']),
    );
  });

  test('cycle 3 主线显示反震与识破等升级词条', () {
    final entries = CycleTraitIntel.entriesFor(
      config: GameRepository.instance.numbers.cycleEvolution,
      cycle: 3,
      isBoss: false,
      isTower: false,
    );

    expect(entries.map((e) => e.id), ['fanzhen', 'shipo', 'yuti']);
    expect(entries.first.detailText, contains('内伤'));
    expect(entries[1].detailText, contains('蓄力反制'));
    expect(entries[2].shortText, contains('12%'));
  });
}
