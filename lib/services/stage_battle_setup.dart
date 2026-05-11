import 'package:isar/isar.dart';

import '../combat/battle_state.dart';
import '../data/defs/stage_def.dart';
import '../data/game_repository.dart';
import '../data/isar_setup.dart';
import '../data/models/character.dart';
import '../data/models/enums.dart';
import '../data/models/equipment.dart';
import '../data/models/save_data.dart';
import '../data/models/technique.dart';

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
  StageBattleSetup._();

  /// 拼装 (left, right) 战斗双方，准备调 `startBattle`。
  ///
  /// 玩家方：从 SaveData.activeCharacterIds 拿出战角色（≤3）；空时回退到
  /// `characters.where().findFirst()`（兜底单人，Phase 2 P1 fixture 路径）。
  static Future<(List<BattleCharacter>, List<BattleCharacter>)>
      buildTeams(StageDef stage) async {
    final isar = IsarSetup.instance;

    // ── 左队（玩家方）──
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
          'StageBattleSetup.buildTeams: Isar 没有任何 Character（先跑 P1 种子）',
        );
      }
      players.add(fallback);
    }
    final left = <BattleCharacter>[];
    for (var i = 0; i < players.length && i < 3; i++) {
      left.add(await _playerToBattle(
        isar: isar,
        character: players[i],
        slotIndex: i,
      ));
    }

    // ── 右队（敌人）──
    final right = <BattleCharacter>[];
    for (var i = 0; i < stage.enemyTeam.length && i < 3; i++) {
      right.add(_enemyToBattle(enemy: stage.enemyTeam[i], slotIndex: i));
    }

    return (left, right);
  }

  static Future<BattleCharacter> _playerToBattle({
    required Isar isar,
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
