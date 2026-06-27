import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_prep_advice_service.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_providers.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_prep_advice.dart';
import 'package:wuxia_idle/features/zangjuange/application/zangjuange_providers.dart';
import 'package:wuxia_idle/features/zangjuange/domain/archive_clue.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('prep advice carries severity and source clue', () {
    const advice = IslandPrepAdvice(
      kind: IslandPrepAdviceKind.bossCycle,
      title: '备破招',
      body: '此 Boss 常以真气蓄势，建议整备破招材料。',
      sourceId: 'boss:stage_05_05#cycle2',
      priority: IslandPrepAdvicePriority.high,
    );

    expect(advice.kind, IslandPrepAdviceKind.bossCycle);
    expect(advice.priority, IslandPrepAdvicePriority.high);
    expect(advice.sourceId, 'boss:stage_05_05#cycle2');
  });

  test('equipment clue maps to equipment prep advice', () {
    const clue = ArchiveClue(
      category: ArchiveClueCategory.equipment,
      title: '兵器缺口',
      summary: '某件兵器尚未收录。',
      targetKind: ArchiveClueTargetKind.stage,
      targetId: 'stage_04_03',
    );

    final advice = IslandPrepAdviceService.fromClues([clue]);

    expect(advice.single.kind, IslandPrepAdviceKind.equipment);
    expect(advice.single.title, UiStrings.islandPrepEquipmentTitle);
    expect(advice.single.sourceId, 'stage_04_03');
  });

  test('fragment and boss cycle clues map to read-only prep advice', () {
    final advice = IslandPrepAdviceService.fromClues([
      const ArchiveClue(
        category: ArchiveClueCategory.skillFragment,
        title: '残页缺口',
        summary: '尚有残页未齐。',
      ),
      const ArchiveClue(
        category: ArchiveClueCategory.bossCycle,
        title: '异势未破',
        summary: '尚有周目异势待破。',
        targetKind: ArchiveClueTargetKind.bossRecord,
        targetId: 'boss:stage_05_05#cycle2',
      ),
    ]);

    expect(advice.map((item) => item.kind), [
      IslandPrepAdviceKind.skillFragment,
      IslandPrepAdviceKind.bossCycle,
    ]);
    expect(advice.first.priority, IslandPrepAdvicePriority.normal);
    expect(advice.last.priority, IslandPrepAdvicePriority.high);
    expect(advice.last.title, UiStrings.islandPrepBossCycleTitle);
  });

  test('island prep advice provider maps zangjuange clues', () async {
    final container = ProviderContainer(
      overrides: [
        zangjuangeCluesProvider.overrideWith(
          (ref) async => const [
            ArchiveClue(
              category: ArchiveClueCategory.bossCycle,
              title: '异势未破',
              summary: '尚有周目异势待破。',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    final advice = await container.read(islandPrepAdviceProvider.future);

    expect(advice, hasLength(1));
    expect(advice.single.kind, IslandPrepAdviceKind.bossCycle);
    expect(advice.single.priority, IslandPrepAdvicePriority.high);
  });

  test(
    'island prep advice provider falls back to empty on clue errors',
    () async {
      final container = ProviderContainer(
        overrides: [
          zangjuangeCluesProvider.overrideWith((ref) async {
            throw StateError('clue source unavailable');
          }),
        ],
      );
      addTearDown(container.dispose);

      final advice = await container.read(islandPrepAdviceProvider.future);

      expect(advice, isEmpty);
    },
  );
}
