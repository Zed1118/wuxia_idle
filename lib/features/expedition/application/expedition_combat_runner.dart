import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/battle_state.dart';
import '../domain/expedition_node.dart';
import 'expedition_battle_runner.dart';
import 'expedition_combat.dart';

/// Production [ExpeditionCombat] implementation.
///
/// The player baseline reuses the mainline setup path and current expedition
/// vitals are injected for each node. Enemy teams and depth scaling come only
/// from the loaded expedition configuration. Combat resolution remains owned
/// by the expedition settlement boundary.
///
/// [memberCaps] must be called before [fight] so the cached baseline contains
/// every dispatched member before later fights use the surviving subset.
class ExpeditionCombatRunner implements ExpeditionCombat {
  ExpeditionCombatRunner(this._isar);

  final Isar _isar;

  List<BattleCharacter>? _baseTeam;

  Future<List<BattleCharacter>> _base(List<int> ids) async => _baseTeam ??=
      await StageBattleSetup(isar: _isar).buildPlayerTeamForCharacters(ids);

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) async {
    final base = await _base(ids);
    return {
      for (final c in base)
        c.characterId: ExpeditionMemberCaps(maxHp: c.maxHp, maxQi: c.maxQi),
    };
  }

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
  }) async {
    final base = await _base(memberStates.keys.toList());
    final players = <BattleCharacter>[
      for (final c in base)
        if (memberStates.containsKey(c.characterId))
          c.copyWith(
            currentHp: memberStates[c.characterId]!.hp,
            currentQi: memberStates[c.characterId]!.qi,
          ),
    ];
    final config = GameRepository.instance.expeditionConfig!;
    final enemyDefs = config.enemiesForNode(
      nodeIndex: node.index,
      nodeSeed: nodeSeed,
      elite: node.type == ExpeditionNodeType.xianGuan,
    );
    final enemies = StageBattleSetup.buildEnemyTeam(enemyDefs);
    final result = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: players,
      enemyTeam: enemies,
      numbers: GameRepository.instance.numbers,
      nodeSeed: nodeSeed,
    );
    return ExpeditionNodeOutcome(
      leftWin: result.leftWin,
      survivorHp: result.survivorHp,
      survivorQi: result.survivorQi,
    );
  }
}
