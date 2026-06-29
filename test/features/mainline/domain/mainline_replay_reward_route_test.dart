import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_replay_reward_route.dart';

void main() {
  StageDef stage({
    String id = 'stage_test',
    String name = '试剑坡',
    bool isBossStage = false,
    List<DropEntry> dropTable = const [],
    String? dropSkillManualId,
    String? dropSkillFragmentId,
    List<EnemyDef> enemies = const [],
  }) {
    return StageDef(
      id: id,
      name: name,
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: enemies,
      isBossStage: isBossStage,
      dropTable: dropTable,
      dropSkillManualId: dropSkillManualId,
      dropSkillFragmentId: dropSkillFragmentId,
      baseExpReward: 100,
      difficultyMultiplier: 1,
    );
  }

  const chargeEnemy = EnemyDef(
    id: 'enemy_charge',
    name: '蓄势刀客',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 1000,
    baseAttack: 120,
    baseSpeed: 100,
    skillIds: ['skill_normal', 'skill_charge'],
    iconPath: '',
    chargeSkillId: 'skill_charge',
  );

  test('equipment drops create equipment replay route', () {
    final route = MainlineReplayRewardRoute.fromStage(
      stage(
        dropTable: const [
          EquipmentDrop(equipmentDefId: 'weapon_test', dropChance: 0.3),
        ],
      ),
    );

    expect(route.kinds, contains(MainlineReplayRewardKind.equipment));
    expect(route.kinds, isNot(contains(MainlineReplayRewardKind.material)));
  });

  test('repeatable item drops create material route but scrolls do not', () {
    final route = MainlineReplayRewardRoute.fromStage(
      stage(
        dropTable: const [
          ItemDrop(
            inventoryItemDefId: 'item_mojianshi',
            quantityMin: 1,
            quantityMax: 2,
            dropChance: 1,
          ),
          ItemDrop(
            inventoryItemDefId: 'item_scroll_gangmeng_menpai',
            quantityMin: 1,
            quantityMax: 1,
            dropChance: 1,
          ),
        ],
      ),
    );

    expect(route.kinds, contains(MainlineReplayRewardKind.material));
  });

  test('skill drops and charge enemies create proficiency route', () {
    final manualRoute = MainlineReplayRewardRoute.fromStage(
      stage(dropSkillManualId: 'skill_manual_test'),
    );
    final fragmentRoute = MainlineReplayRewardRoute.fromStage(
      stage(dropSkillFragmentId: 'skill_fragment_test'),
    );
    final chargeRoute = MainlineReplayRewardRoute.fromStage(
      stage(enemies: const [chargeEnemy]),
    );

    expect(manualRoute.kinds, contains(MainlineReplayRewardKind.proficiency));
    expect(fragmentRoute.kinds, contains(MainlineReplayRewardKind.proficiency));
    expect(chargeRoute.kinds, contains(MainlineReplayRewardKind.proficiency));
  });

  test('route order is stable equipment material proficiency', () {
    final route = MainlineReplayRewardRoute.fromStage(
      stage(
        dropTable: const [
          ItemDrop(
            inventoryItemDefId: 'item_mojianshi',
            quantityMin: 1,
            quantityMax: 1,
            dropChance: 1,
          ),
          EquipmentDrop(equipmentDefId: 'weapon_test', dropChance: 0.3),
        ],
        enemies: const [chargeEnemy],
      ),
    );

    expect(route.kinds, const [
      MainlineReplayRewardKind.equipment,
      MainlineReplayRewardKind.material,
      MainlineReplayRewardKind.proficiency,
    ]);
  });

  test('chapter farm spots stay hidden until the whole chapter is cleared', () {
    final spots = MainlineChapterFarmSpotSelector.fromEntries([
      (
        def: stage(
          id: 'stage_01_01',
          dropTable: const [
            EquipmentDrop(equipmentDefId: 'weapon_test', dropChance: 0.3),
          ],
        ),
        status: StageStatus.cleared,
      ),
      (def: stage(id: 'stage_01_02'), status: StageStatus.available),
    ]);

    expect(spots, isEmpty);
  });

  test('chapter farm spots are capped at two high-value replay routes', () {
    final materialStage = stage(
      id: 'stage_01_01',
      name: '山门之外',
      dropTable: const [
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1,
        ),
      ],
    );
    final equipmentStage = stage(
      id: 'stage_01_02',
      name: '荒山野店',
      dropTable: const [
        EquipmentDrop(equipmentDefId: 'weapon_test', dropChance: 0.3),
      ],
    );
    final bossStage = stage(
      id: 'stage_01_05',
      name: '风雨渡口',
      isBossStage: true,
      dropTable: const [
        EquipmentDrop(equipmentDefId: 'weapon_boss', dropChance: 0.3),
        ItemDrop(
          inventoryItemDefId: 'item_xinxue_jiejing',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1,
        ),
      ],
      dropSkillManualId: 'skill_manual_test',
    );

    final spots = MainlineChapterFarmSpotSelector.fromEntries([
      (def: materialStage, status: StageStatus.cleared),
      (def: equipmentStage, status: StageStatus.cleared),
      (def: bossStage, status: StageStatus.cleared),
    ]);

    expect(spots, hasLength(2));
    expect(spots.first.stage.id, 'stage_01_05');
    expect(spots.first.route.kinds, const [
      MainlineReplayRewardKind.equipment,
      MainlineReplayRewardKind.material,
      MainlineReplayRewardKind.proficiency,
    ]);
    expect(spots.map((spot) => spot.stage.id), contains('stage_01_02'));
  });
}
