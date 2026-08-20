import '../../../../shared/strings.dart';
import '../../application/phase0a/phase0a_stage_content_mapper.dart';

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

  /// Phase 1 纵切实机接线(拍板 α 灰度门):从主线内容映射结果装配真实 roster。
  ///
  /// 玩家=单主角续传(D3)灰盒立绘,沿 [debugBattle] 已验证的祖师战斗图;
  /// 正式立绘绑定留美术批。敌人直接取 [mapping] combatant 的 iconPath
  /// (零口径复制自 EnemyDef);iconPath 空串 fail-fast,不静默降级。
  factory Phase0aVisualRoster.fromMapping(Phase0aStageMapping mapping) {
    const playerBattleAsset = 'assets/characters/battle_founder_v2.png';
    final playerId = mapping.initialState.player.id;
    final visuals = <String, Phase0aActorVisual>{};
    for (final combatant in mapping.combatants) {
      final isPlayer = combatant.actorId == playerId;
      final assetPath = isPlayer
          ? playerBattleAsset
          : combatant.character.iconPath;
      if (assetPath == null || assetPath.isEmpty) {
        throw StateError(
          'Phase0a roster requires a non-empty asset: '
          'actor ${combatant.actorId}',
        );
      }
      visuals[combatant.actorId] = Phase0aActorVisual(
        name: combatant.character.name,
        assetPath: assetPath,
        isElite: combatant.character.isBoss,
      );
    }
    return Phase0aVisualRoster(visuals: visuals);
  }

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
