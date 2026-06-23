/// F7（2026-06-23 掉落优化 子系统配置卫生）：dropTable 引用校验红线单测。
///
/// 直接调 [GameRepository.enforceDropTableReferences]（纯 static，接受 stageDefs Map
/// + towerFloors List + equipmentIds Set），与 enforceWeaknessRedLines 同模式。
///
/// 校验语义：
///   - EquipmentDrop.equipmentDefId 必须在 equipmentDefs（否则 runtime getEquipment 崩）
///   - ItemDrop.inventoryItemDefId 必须能被 ItemType.fromDefId 解析为非 miscMaterial
///     （miscMaterial 是兜底吞值桶 → 悬空/拼错的 defId 静默落入，fail-fast 拦下）
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

EnemyDef _enemy() => const EnemyDef(
      id: 'e1',
      name: '敌',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 1000,
      baseAttack: 100,
      baseSpeed: 50,
      skillIds: ['skill_x'],
      iconPath: 'x.png',
    );

StageDef _stage(String id, List<DropEntry> dropTable) => StageDef(
      id: id,
      name: '测试关',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.erLiu,
      enemyTeam: [_enemy()],
      isBossStage: false,
      dropTable: dropTable,
      baseExpReward: 100,
      difficultyMultiplier: 1.0,
    );

TowerFloorDef _floor(int idx, List<DropEntry> dropTable) => TowerFloorDef(
      floorIndex: idx,
      requiredRealm: RealmTier.erLiu,
      enemyTeam: [_enemy()],
      dropTable: dropTable,
    );

const _equipmentIds = {'weapon_real', 'armor_real'};

void enforce(Map<String, StageDef> stages, List<TowerFloorDef> floors) =>
    GameRepository.enforceDropTableReferences(
      stageDefs: stages,
      towerFloors: floors,
      equipmentIds: _equipmentIds,
    );

void main() {
  group('GameRepository.enforceDropTableReferences (F7)', () {
    test('合法 dropTable（真装备 + 各类已知物品）→ 不抛', () {
      final stages = {
        's1': _stage('s1', const [
          EquipmentDrop(equipmentDefId: 'weapon_real', dropChance: 0.5),
          ItemDrop(
              inventoryItemDefId: 'item_silver',
              quantityMin: 1,
              quantityMax: 1,
              dropChance: 1.0),
          ItemDrop(
              inventoryItemDefId: 'item_mojianshi',
              quantityMin: 1,
              quantityMax: 1,
              dropChance: 1.0),
          ItemDrop(
              inventoryItemDefId: 'item_scroll_kai_bei_shou',
              quantityMin: 1,
              quantityMax: 1,
              dropChance: 1.0),
          ItemDrop(
              inventoryItemDefId: 'item_jingyandan_large',
              quantityMin: 1,
              quantityMax: 1,
              dropChance: 1.0),
        ]),
      };
      final floors = [
        _floor(1, const [
          EquipmentDrop(equipmentDefId: 'armor_real', dropChance: 0.3),
        ]),
      ];
      expect(() => enforce(stages, floors), returnsNormally);
    });

    test('stage dropTable 悬空 equipmentDefId → 抛 StateError(含坏 id)', () {
      final stages = {
        's1': _stage('s1', const [
          EquipmentDrop(equipmentDefId: 'weapon_ghost_not_exist', dropChance: 0.5),
        ]),
      };
      expect(
        () => enforce(stages, const []),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('weapon_ghost_not_exist'))),
      );
    });

    test('stage dropTable 悬空 inventoryItemDefId（兜底 miscMaterial）→ 抛 StateError', () {
      final stages = {
        's1': _stage('s1', const [
          ItemDrop(
              inventoryItemDefId: 'item_typo_unknown',
              quantityMin: 1,
              quantityMax: 1,
              dropChance: 1.0),
        ]),
      };
      expect(
        () => enforce(stages, const []),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('item_typo_unknown'))),
      );
    });

    test('tower floor dropTable 悬空 equipmentDefId → 抛 StateError', () {
      final floors = [
        _floor(1, const [
          EquipmentDrop(equipmentDefId: 'armor_ghost_not_exist', dropChance: 0.3),
        ]),
      ];
      expect(
        () => enforce(const {}, floors),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('armor_ghost_not_exist'))),
      );
    });
  });
}
