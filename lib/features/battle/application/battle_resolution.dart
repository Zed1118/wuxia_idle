import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/technique_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/utils/rng.dart';
import '../../combat_shared/application/combat_resolution_service.dart';
import '../../equipment/application/drop_service.dart';
import '../domain/battle_state.dart';

export '../../combat_shared/application/combat_resolution_service.dart'
    show BattleResolutionResult;

/// 旧 3v3 [BattleState] 到引擎中立结算快照的临时适配器。
///
/// Phase 0A 生产路径应直接调用 [CombatResolutionService]。本类只为
/// Windows Gate 前保留的紧急回退路径服务，会与旧引擎同批删除。
final class BattleResolutionService {
  const BattleResolutionService._();

  static BattleResolutionResult resolve({
    required BattleState finalState,
    required List<Character> participatingCharacters,
    required Map<int, List<Equipment>> equipmentsByCharacter,
    required Map<int, List<Technique>> techniquesByCharacter,
    required Rng rng,
    required Map<CultivationLayer, int> progressToNextMap,
    required TechniqueDef Function(String defId) techniqueDefLookup,
    required DropService dropService,
    StageDef? stageDef,
    NumbersConfig? numbersConfig,
    bool isHardFight = false,
    List<EquipmentDef> Function(EquipmentTier)? equipmentPoolByTier,
    EquipmentTier Function(RealmTier)? equipmentTierForRealm,
    int cycle = 1,
  }) => CombatResolutionService.resolveSnapshot(
    settlement: snapshotFromBattleState(finalState),
    participatingCharacters: participatingCharacters,
    equipmentsByCharacter: equipmentsByCharacter,
    techniquesByCharacter: techniquesByCharacter,
    rng: rng,
    progressToNextMap: progressToNextMap,
    techniqueDefLookup: techniqueDefLookup,
    dropService: dropService,
    stageDef: stageDef,
    numbersConfig: numbersConfig,
    isHardFight: isHardFight,
    equipmentPoolByTier: equipmentPoolByTier,
    equipmentTierForRealm: equipmentTierForRealm,
    cycle: cycle,
  );

  static CombatSettlementSnapshot snapshotFromBattleState(
    BattleState finalState,
  ) {
    var totalDamage = 0;
    var criticalCount = 0;
    final damageByCharacterId = <int, int>{};
    final skillCasts = <CombatSkillCastSnapshot>[];
    final countedSkillCasts = <String>{};
    for (final action in finalState.actionLog) {
      final attack = action.attackResult;
      if (attack != null) {
        totalDamage += attack.finalDamage;
        if (attack.isCritical) criticalCount += 1;
        damageByCharacterId.update(
          action.actorId,
          (damage) => damage + attack.finalDamage,
          ifAbsent: () => attack.finalDamage,
        );
      }
      final skillId = action.skill?.id;
      if (skillId != null) {
        if (action.targetId != null) {
          final castKey = '${action.tick}|${action.actorId}|$skillId';
          if (!countedSkillCasts.add(castKey)) continue;
        }
        skillCasts.add(
          CombatSkillCastSnapshot(
            tick: action.tick,
            characterId: action.actorId,
            skillId: skillId,
          ),
        );
      }
    }
    return CombatSettlementSnapshot(
      result: finalState.result,
      totalTicks: finalState.tick,
      hadActions: finalState.actionLog.isNotEmpty,
      participants: [
        for (final character in [
          ...finalState.leftTeam,
          ...finalState.rightTeam,
        ])
          CombatParticipantSnapshot(
            characterId: character.characterId,
            currentHp: character.currentHp,
            maxHp: character.maxHp,
          ),
      ],
      skillCasts: skillCasts,
      totalDamage: totalDamage,
      criticalCount: criticalCount,
      damageByCharacterId: damageByCharacterId,
    );
  }

  /// 过渡期兼容入口；新生产路径应直接依赖 [CombatResolutionService]。
  static BattleResolutionResult resolveSnapshot({
    required CombatSettlementSnapshot settlement,
    required List<Character> participatingCharacters,
    required Map<int, List<Equipment>> equipmentsByCharacter,
    required Map<int, List<Technique>> techniquesByCharacter,
    required Rng rng,
    required Map<CultivationLayer, int> progressToNextMap,
    required TechniqueDef Function(String defId) techniqueDefLookup,
    required DropService dropService,
    StageDef? stageDef,
    NumbersConfig? numbersConfig,
    bool isHardFight = false,
    List<EquipmentDef> Function(EquipmentTier)? equipmentPoolByTier,
    EquipmentTier Function(RealmTier)? equipmentTierForRealm,
    int cycle = 1,
  }) => CombatResolutionService.resolveSnapshot(
    settlement: settlement,
    participatingCharacters: participatingCharacters,
    equipmentsByCharacter: equipmentsByCharacter,
    techniquesByCharacter: techniquesByCharacter,
    rng: rng,
    progressToNextMap: progressToNextMap,
    techniqueDefLookup: techniqueDefLookup,
    dropService: dropService,
    stageDef: stageDef,
    numbersConfig: numbersConfig,
    isHardFight: isHardFight,
    equipmentPoolByTier: equipmentPoolByTier,
    equipmentTierForRealm: equipmentTierForRealm,
    cycle: cycle,
  );
}
