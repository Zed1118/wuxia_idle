import '../../battle/domain/battle_state.dart';
import 'npc_relation_service.dart';

/// 江湖恩怨与战斗快照之间的装配层。
///
/// 只负责把已存在的 [NpcRelationService] 状态烘焙到进场快照，不改持久化关系。
class EnmityBattleModifier {
  EnmityBattleModifier._();

  /// 为 `StageDef.npcId` 生成稳定的战斗/关系 target id。
  ///
  /// 使用独立负数空间，避免与玩家 Isar 正 id 以及普通 EnemyDef slot id
  /// (-1/-2/-3) 冲突。该 id 是 schema bridge，不是战斗数值。
  static int targetIdForNpcId(String npcId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in npcId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return -1000000 - hash;
  }

  /// P1.2 §5 江湖恩怨 attackPowerMultiplier 烘焙。
  ///
  /// SET 语义：不叠乘已有 APM，直接把江湖恩怨档位写入快照；双方对等。
  /// - enemy 端按 (player -> enemy) 各自 SET。
  /// - player 端取 `max(across enemies)`，任一敌人有恩怨即享最高档。
  /// - `NpcRelationService.attackPowerMultFor` 已按 numbers.yaml clamp 上限。
  static Future<(List<BattleCharacter>, List<BattleCharacter>)>
  bakeMultipliers({
    required NpcRelationService npcService,
    required List<BattleCharacter> leftTeam,
    required List<BattleCharacter> rightTeam,
  }) async {
    if (leftTeam.isEmpty || rightTeam.isEmpty) return (leftTeam, rightTeam);
    final playerCharId = leftTeam.first.characterId;
    if (playerCharId < 0) return (leftTeam, rightTeam);

    var maxMult = 1.0;
    final newRight = <BattleCharacter>[];
    for (final enemy in rightTeam) {
      final mult = await npcService.attackPowerMultFor(
        playerCharId,
        enemy.characterId,
      );
      if (mult > 1.0) {
        newRight.add(
          enemy.copyWith(
            attackPowerMultiplier: mult,
            attackPowerMultiplierSource:
                AttackPowerMultiplierSource.jianghuEnmity,
          ),
        );
        if (mult > maxMult) maxMult = mult;
      } else {
        newRight.add(enemy);
      }
    }

    if (maxMult <= 1.0) return (leftTeam, newRight);
    final newLeft = <BattleCharacter>[
      leftTeam.first.copyWith(
        attackPowerMultiplier: maxMult,
        attackPowerMultiplierSource: AttackPowerMultiplierSource.jianghuEnmity,
      ),
      ...leftTeam.skip(1),
    ];
    return (newLeft, newRight);
  }
}
