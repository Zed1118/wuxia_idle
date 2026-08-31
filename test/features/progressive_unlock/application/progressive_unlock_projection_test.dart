import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/progressive_unlock/application/progressive_unlock_projection.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  Character character({
    int id = 1,
    RealmTier tier = RealmTier.xueTu,
    RealmLayer layer = RealmLayer.ruMen,
  }) => Character()
    ..id = id
    ..realmTier = tier
    ..realmLayer = layer;

  ProgressiveUnlockSnapshot project({
    Set<String> cleared = const {},
    bool journeyOpen = false,
    List<Character>? activeCharacters,
  }) {
    final repository = GameRepository.instance;
    return projectCurrentProgressiveUnlocks(
      save: SaveData()
        ..slotId = 1
        ..activeCharacterIds = [
          for (final entry in activeCharacters ?? [character()]) entry.id,
        ]
        ..jianghuJourneyUnlocked = journeyOpen,
      mainlineProgress: MainlineProgress()
        ..saveDataId = 1
        ..clearedStageIds = cleared.toList(),
      activeCharacters: activeCharacters ?? [character()],
      lightFoot: repository.numbers.lightFoot,
      massBattle: repository.numbers.massBattle,
      innerDemon: repository.numbers.innerDemon,
    );
  }

  test(
    'fresh current gates project without inventing new chapter thresholds',
    () {
      final snapshot = project();
      expect(snapshot[ProgressiveUnlockId.tower], ProgressiveUnlockState.open);
      expect(
        snapshot[ProgressiveUnlockId.discipleScheduling],
        ProgressiveUnlockState.open,
      );
      expect(
        snapshot[ProgressiveUnlockId.lightFoot],
        ProgressiveUnlockState.heard,
      );
      expect(
        snapshot[ProgressiveUnlockId.massBattle],
        ProgressiveUnlockState.heard,
      );
      expect(
        snapshot[ProgressiveUnlockId.expedition],
        ProgressiveUnlockState.hidden,
      );
      expect(
        snapshot[ProgressiveUnlockId.gauntlet],
        ProgressiveUnlockState.hidden,
      );
      expect(
        snapshot[ProgressiveUnlockId.innerDemon],
        ProgressiveUnlockState.hidden,
      );
    },
  );

  test(
    'existing persisted facts alone advance their current production gates',
    () {
      final lightRoot = GameRepository
          .instance
          .numbers
          .lightFoot
          .unlockTriggers
          .keys
          .firstWhere((id) => !id.startsWith('stage_light_foot_'));
      final massRoot = GameRepository
          .instance
          .numbers
          .massBattle
          .unlockTriggers
          .keys
          .firstWhere((id) => !id.startsWith('stage_mass_battle_'));
      expect(massRoot, lightRoot, reason: '测试从生产配置证明当前两模式共用门槛');

      final firstInnerNode = GameRepository
          .instance
          .numbers
          .innerDemon
          .requiredRealmLayer
          .values
          .reduce((a, b) {
            final aIndex =
                a.tier.index * RealmLayer.values.length + a.layer.index;
            final bIndex =
                b.tier.index * RealmLayer.values.length + b.layer.index;
            return aIndex <= bIndex ? a : b;
          });
      final snapshot = project(
        cleared: {lightRoot},
        journeyOpen: true,
        activeCharacters: [
          character(tier: firstInnerNode.tier, layer: firstInnerNode.layer),
        ],
      );

      expect(
        snapshot[ProgressiveUnlockId.lightFoot],
        ProgressiveUnlockState.open,
      );
      expect(
        snapshot[ProgressiveUnlockId.massBattle],
        ProgressiveUnlockState.open,
      );
      expect(
        snapshot[ProgressiveUnlockId.expedition],
        ProgressiveUnlockState.open,
      );
      expect(
        snapshot[ProgressiveUnlockId.gauntlet],
        ProgressiveUnlockState.open,
      );
      expect(
        snapshot[ProgressiveUnlockId.innerDemon],
        ProgressiveUnlockState.open,
      );
    },
  );

  test(
    'missing active character fails closed instead of downgrading receipts',
    () {
      expect(
        () => projectCurrentProgressiveUnlocks(
          save: SaveData()
            ..slotId = 1
            ..activeCharacterIds = [99],
          mainlineProgress: MainlineProgress()
            ..saveDataId = 1
            ..clearedStageIds = [],
          activeCharacters: [character(id: 1)],
          lightFoot: GameRepository.instance.numbers.lightFoot,
          massBattle: GameRepository.instance.numbers.massBattle,
          innerDemon: GameRepository.instance.numbers.innerDemon,
        ),
        throwsStateError,
      );
    },
  );
}
