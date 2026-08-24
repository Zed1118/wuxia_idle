import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../application/phase0a/phase0a_battle_snapshot_factory.dart';
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
        assetPath: WuxiaUi.battleFounderFallback,
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
  /// 委托 [fromCombatants](D10 typed 合同),输出口径不变。
  factory Phase0aVisualRoster.fromMapping(Phase0aStageMapping mapping) =>
      Phase0aVisualRoster.fromCombatants(
        playerId: mapping.initialState.player.id,
        combatants: mapping.combatants,
      );

  /// D10 动态视觉名册合同:在 runtime 状态变化前为全量 [combatants]
  /// (含 reserve / warning / active)各构造恰一个视觉。
  ///
  /// 玩家沿用 [WuxiaUi.battleFounderFallback](正式立绘绑定留美术批);
  /// 敌人直接取 snapshot `iconPath`(零口径复制自 EnemyDef)。
  /// 空 asset、重复 actor id、玩家缺失/重复均稳定 fail closed。
  factory Phase0aVisualRoster.fromCombatants({
    required String playerId,
    required List<Phase0aCombatantInput> combatants,
    Map<String, String>? assetPathByActorId,
  }) {
    if (playerId.trim().isEmpty) {
      throw StateError('Phase0a roster requires a non-empty player id');
    }
    final seen = <String>{};
    var playerFound = false;
    final visuals = <String, Phase0aActorVisual>{};
    for (final combatant in combatants) {
      final actorId = combatant.actorId;
      if (actorId.trim().isEmpty) {
        throw StateError('Phase0a roster requires a non-empty actor id');
      }
      if (!seen.add(actorId)) {
        throw StateError(
          'Phase0a roster received a duplicate actor id: $actorId',
        );
      }
      final isPlayer = actorId == playerId;
      if (isPlayer) {
        playerFound = true;
      }
      final assetPath = isPlayer
          ? WuxiaUi.battleFounderFallback
          : assetPathByActorId?[actorId] ?? combatant.snapshot.iconPath;
      if (assetPath == null || assetPath.trim().isEmpty) {
        throw StateError(
          'Phase0a roster requires a non-empty asset: '
          'actor ${combatant.actorId}',
        );
      }
      visuals[actorId] = Phase0aActorVisual(
        name: combatant.snapshot.name,
        assetPath: assetPath,
        isElite: combatant.snapshot.isBoss,
      );
    }
    if (!playerFound) {
      throw StateError('Phase0a roster is missing the player: $playerId');
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
