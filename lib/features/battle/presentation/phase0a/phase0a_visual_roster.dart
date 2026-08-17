import '../../../../shared/strings.dart';

final class Phase0aActorVisual {
  const Phase0aActorVisual({
    required this.name,
    required this.assetPath,
    required this.isElite,
  });

  final String name;
  final String assetPath;
  final bool isElite;
}

final class Phase0aVisualRoster {
  Phase0aVisualRoster({required Map<String, Phase0aActorVisual> visuals})
    : _visuals = Map.unmodifiable(visuals);

  factory Phase0aVisualRoster.debugBattle() => Phase0aVisualRoster(
    visuals: const {
      'player': Phase0aActorVisual(
        name: UiStrings.battleSampleFounder,
        assetPath: 'assets/characters/battle_founder_v2.png',
        isElite: false,
      ),
      'wave1_blade': Phase0aActorVisual(
        name: UiStrings.battleSampleBanditBlade,
        assetPath: 'assets/enemies/battle_bandit_blade.png',
        isElite: false,
      ),
      'wave1_archer': Phase0aActorVisual(
        name: UiStrings.battleSampleBanditArcher,
        assetPath: 'assets/enemies/battle_bandit_archer.png',
        isElite: false,
      ),
      'wave2_bandit_b': Phase0aActorVisual(
        name: UiStrings.phase0aDebugBanditB,
        assetPath: 'assets/enemies/battle_bandit_b.png',
        isElite: false,
      ),
      'wave2_bandit_c': Phase0aActorVisual(
        name: UiStrings.phase0aDebugBanditC,
        assetPath: 'assets/enemies/battle_bandit_c.png',
        isElite: false,
      ),
      'wave2_elite': Phase0aActorVisual(
        name: UiStrings.battleSampleHiddenElder,
        assetPath: 'assets/enemies/battle_hidden_elder.png',
        isElite: true,
      ),
    },
  );

  final Map<String, Phase0aActorVisual> _visuals;

  Phase0aActorVisual visualFor(String actorId) {
    final visual = _visuals[actorId];
    if (visual == null) {
      throw StateError('Missing Phase0a visual for actor: $actorId');
    }
    return visual;
  }

  String nameOf(String actorId) => visualFor(actorId).name;
}
