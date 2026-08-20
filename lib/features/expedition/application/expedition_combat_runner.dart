import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../battle/application/enemy_battle_character_assembler.dart';
import '../../battle/application/player_battle_character_assembler.dart';
import '../../battle/domain/battle_state.dart';
import '../domain/expedition_node.dart';
import 'expedition_battle_runner.dart';
import 'expedition_combat.dart';

/// [ExpeditionCombat] 的生产实装。
///
/// 玩家基线复用主线出战装配路径，逐节点注入当前远征生命/真气；敌方队伍
/// 与深度缩放只来自已加载的远行配置；战斗结算仍归远征结算边界所有。
///
/// 必须先调 [memberCaps] 再调 [fight]：缓存基线须先收录全部出战成员，
/// 后续战斗才按存活子集取用。
class ExpeditionCombatRunner implements ExpeditionCombat {
  ExpeditionCombatRunner(this._isar);

  final Isar _isar;

  List<BattleCharacter>? _baseTeam;

  Future<List<BattleCharacter>> _base(List<int> ids) async => _baseTeam ??=
      await PlayerBattleCharacterAssembler(isar: _isar).loadExactRoster(ids);

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
    required int cycleIndex,
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
    // 批 B：远征属境界段推进入口（spec 拍板 #5），cycle≥2 敌境界整体抬升；
    // 深度 hp/atk 缩放（enemiesForNode 内）照旧叠加。
    final enemies = EnemyBattleCharacterAssembler.assembleAll(
      enemyDefs,
      cycleIndex: cycleIndex,
      advanceRealmPerCycle: true,
    );
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
