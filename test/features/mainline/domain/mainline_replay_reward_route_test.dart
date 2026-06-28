import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_replay_reward_route.dart';

void main() {
  StageDef stage({
    List<DropEntry> dropTable = const [],
    String? dropSkillManualId,
    String? dropSkillFragmentId,
    List<EnemyDef> enemies = const [],
  }) {
    return StageDef(
      id: 'stage_test',
      name: '试剑坡',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: enemies,
      isBossStage: false,
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
}
