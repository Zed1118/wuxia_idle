import 'package:isar_community/isar.dart';

import '../features/battle/domain/battle_state.dart';
import '../data/defs/stage_def.dart';
import '../features/tower/domain/tower_floor_def.dart';
import '../data/game_repository.dart';
import '../core/domain/character.dart';
import '../core/domain/enums.dart';
import '../core/domain/equipment.dart';
import '../core/domain/save_data.dart';
import '../core/domain/technique.dart';

/// 关卡战斗准备（Phase 3 T37，对应 PROGRESS #22 销账）。
///
/// 负责把「持久化角色 + stage.enemyTeam」装配成 (左队, 右队) 两组
/// [BattleCharacter] 快照，可直接喂给 `BattleNotifier.startBattle`。
///
/// - 左队（玩家）：从 Isar 拉 [SaveData.activeCharacterIds]，每个角色用
///   [BattleCharacter.fromCharacter] 接装备 + 主修；最少 1 人。
/// - 右队（敌人）：[StageDef.enemyTeam] 每个 [EnemyDef] 用 [_enemyToBattle]
///   构造（不接 yaml 装备/心法，纯走 EnemyDef.base* 数值）。
///
/// **negative id 约定**：敌人 [BattleCharacter.characterId] 用 `-(slotIndex+1)`，
/// 避免与玩家 Isar autoIncrement id 冲突。
class StageBattleSetup {
  const StageBattleSetup({required this.isar});

  final Isar isar;

  /// 拼装 (left, right) 战斗双方，准备调 `startBattle`（主线关卡版）。
  Future<(List<BattleCharacter>, List<BattleCharacter>)> buildTeams(
    StageDef stage,
  ) async {
    final left = await _buildPlayerTeam();
    final right = buildEnemyTeam(stage.enemyTeam);
    return (left, right);
  }

  /// 拼装 (left, right) 战斗双方，准备调 `startBattle`（爬塔版）。
  ///
  /// 左队装配逻辑与 [buildTeams] 完全一致；右队用 [TowerFloorDef.enemyTeam]。
  Future<(List<BattleCharacter>, List<BattleCharacter>)> buildTeamsForTower(
    TowerFloorDef floor,
  ) async {
    final left = await _buildPlayerTeam();
    final right = buildEnemyTeam(floor.enemyTeam);
    return (left, right);
  }

  /// 将 [EnemyDef] 列表装配为右队 [BattleCharacter] 列表（最多 3 人）。
  ///
  /// 主线 [buildTeams] 与爬塔 [buildTeamsForTower] 共用，避免重复。纯函数,保持 static。
  static List<BattleCharacter> buildEnemyTeam(List<EnemyDef> enemies) {
    final right = <BattleCharacter>[];
    for (var i = 0; i < enemies.length && i < 3; i++) {
      right.add(_enemyToBattle(enemy: enemies[i], slotIndex: i));
    }
    return right;
  }

  /// 从 Isar 拉玩家方（左队）：优先 activeCharacterIds，空则兜底 findFirst。
  Future<List<BattleCharacter>> _buildPlayerTeam() async {
    final save = await isar.saveDatas.get(0);
    final ids = save?.activeCharacterIds ?? const [];
    final players = <Character>[];
    for (final cid in ids) {
      final c = await isar.characters.get(cid);
      if (c != null) players.add(c);
    }
    if (players.isEmpty) {
      // 兜底：Phase 2 P1 种子是 id=1 单人，没设 activeCharacterIds
      final fallback = await isar.characters.where().findFirst();
      if (fallback == null) {
        throw StateError(
          'StageBattleSetup: Isar 没有任何 Character（先跑 P1 种子）',
        );
      }
      players.add(fallback);
    }
    final left = <BattleCharacter>[];
    for (var i = 0; i < players.length && i < 3; i++) {
      left.add(await _playerToBattle(
        character: players[i],
        slotIndex: i,
      ));
    }
    return left;
  }

  Future<BattleCharacter> _playerToBattle({
    required Character character,
    required int slotIndex,
  }) async {
    final equipped = <Equipment>[];
    for (final id in [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ]) {
      if (id == null) continue;
      final e = await isar.equipments.get(id);
      if (e != null) equipped.add(e);
    }

    if (character.mainTechniqueId == null) {
      throw StateError(
        'StageBattleSetup: 角色 ${character.name} 未修主修，无法进入战斗',
      );
    }
    final mainTech = await isar.techniques.get(character.mainTechniqueId!);
    if (mainTech == null) {
      throw StateError(
        'StageBattleSetup: 角色 ${character.name} mainTechniqueId='
        '${character.mainTechniqueId} 在 Isar 中找不到',
      );
    }

    return BattleCharacter.fromCharacter(
      character: character,
      equipped: equipped,
      mainTechnique: mainTech,
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: slotIndex,
    );
  }

  /// EnemyDef → BattleCharacter。
  ///
  /// 敌人不持装备/心法，全靠 yaml `baseHp / baseAttack / baseSpeed`：
  /// - `maxInternalForce / currentInternalForce` 默认 1000（中等大招池）
  /// - `mainCultivationLayer` 默认 [CultivationLayer.daCheng]（中等加成）
  /// - `criticalRate / evasionRate` 默认 0.05（基础值）
  /// - `totalEquipmentAttack` = `baseAttack`（直接当装备攻击灌入伤害公式）
  /// - `characterId` 用 `-(slotIndex+1)` 避免与玩家 Isar id 冲突
  static BattleCharacter _enemyToBattle({
    required EnemyDef enemy,
    required int slotIndex,
  }) {
    final skills = enemy.skillIds
        .map((id) => GameRepository.instance.getSkill(id))
        .toList(growable: false);
    return BattleCharacter(
      characterId: -(slotIndex + 1),
      name: enemy.name,
      realmTier: enemy.realmTier,
      realmLayer: enemy.realmLayer,
      school: enemy.school,
      maxHp: enemy.baseHp,
      currentHp: enemy.baseHp,
      maxInternalForce: 1000,
      currentInternalForce: 1000,
      speed: enemy.baseSpeed,
      criticalRate: 0.05,
      evasionRate: 0.05,
      totalEquipmentAttack: enemy.baseAttack,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: skills,
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
    );
  }
}
