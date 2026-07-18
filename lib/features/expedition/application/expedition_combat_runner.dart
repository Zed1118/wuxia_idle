import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/battle_state.dart';
import '../domain/expedition_node.dart';
import 'expedition_battle_runner.dart';
import 'expedition_combat.dart';

/// [ExpeditionCombat] 生产实装（B2.2b）。
///
/// - 玩家队：从 Isar 派遣成员经 [StageBattleSetup.buildPlayerTeamForCharacters]
///   装配（复用主线同一 autoFill/相生/祖师 buff/伤势路径，不分叉），满血基准队
///   构建一次复用，每节点按当前远征 HP/qi `copyWith` 注入、残阵只带存活者。
/// - 敌队：按节点**占位合成**（`TODO(batch3-probe)` 深度曲线待探针定案），经
///   [StageBattleSetup.buildEnemyTeam] 装配。
/// - 战斗：走 [ExpeditionBattleRunner]（headless 地面 3v3）。修炼/伤势结算归返程
///   事务（§4.6 战败按最深节点+倒下人数结伤），本 runner **不调 resolve**。
///
/// 注：[memberCaps] 应先于 [fight] 调用（[ExpeditionService.settle] 保证），
/// 以便满血基准队含全部成员后再按存活子集出战。
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
    // 残阵：只带仍存活（出现在 memberStates）的成员，注入当前远征 HP/qi。
    final players = <BattleCharacter>[
      for (final c in base)
        if (memberStates.containsKey(c.characterId))
          c.copyWith(
            currentHp: memberStates[c.characterId]!.hp,
            currentQi: memberStates[c.characterId]!.qi,
          ),
    ];
    final enemies = StageBattleSetup.buildEnemyTeam(_synthesizeEnemies(node));
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

  /// 占位敌队合成。
  ///
  /// **TODO(batch3-probe)**：敌人池来源与深度曲线由联合经济探针定案回填；此处仅
  /// 保证可跑 + 数值远低于 §5.4 红线，不作平衡承诺。占位敌 realm 取最低阶（学徒）
  /// 避免境界差距误伤，随节点深度线性抬升、险关加成。同一节点确定合成
  /// （node.index 稳定）。
  static List<EnemyDef> _synthesizeEnemies(ExpeditionNode node) {
    final elite = node.type == ExpeditionNodeType.xianGuan;
    final depth = node.index;
    return [
      EnemyDef(
        id: 'expedition_node_${node.index}',
        name: elite ? '瘴谷精英' : '百草岭伏兽',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        baseHp: (300 + depth * 15) * (elite ? 3 : 1),
        baseAttack: (25 + depth) * (elite ? 2 : 1),
        baseSpeed: 80,
        skillIds: const [],
        iconPath: '',
      ),
    ];
  }
}
