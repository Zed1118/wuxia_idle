import '../../combat/battle_state.dart';
import '../../data/defs/skill_def.dart';
import '../../data/models/enums.dart';

/// T14 静态布局目测用的 mock [BattleState]（不依赖 GameRepository）。
///
/// **不走 [BattleCharacter.fromCharacter]**——那个工厂需要 Isar 实体 + 心法定义；
/// T14 只验布局，直接用构造函数填字段更轻。覆盖 4 项验收：
///   - 左 3 右 3 对称
///   - HP 比例不同（满血 / 中血 / 残血）
///   - 三个流派颜色都出现
///   - 死亡角色（右队 #2）变灰
class BattleDemo {
  BattleDemo._();

  static SkillDef _ultimate(String id, String name, int cost) => SkillDef(
        id: id,
        name: name,
        description: '',
        type: SkillType.ultimate,
        powerMultiplier: 5000,
        internalForceCost: cost,
        cooldownTurns: 5,
        requiresManualTrigger: true,
        parentTechniqueDefId: null,
        visualEffect: '',
      );

  static BattleCharacter _make({
    required int id,
    required String name,
    required RealmTier tier,
    required RealmLayer layer,
    required TechniqueSchool school,
    required int maxHp,
    required int currentHp,
    required int maxIf,
    required int currentIf,
    required int teamSide,
    required int slotIndex,
    bool isAlive = true,
    bool withUltimate = true,
  }) {
    return BattleCharacter(
      characterId: id,
      name: name,
      realmTier: tier,
      realmLayer: layer,
      school: school,
      maxHp: maxHp,
      currentHp: currentHp,
      maxInternalForce: maxIf,
      currentInternalForce: currentIf,
      speed: 200,
      criticalRate: 0.2,
      evasionRate: 0.05,
      totalEquipmentAttack: 800,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: withUltimate
          ? [_ultimate('demo_ult_$id', '示例大招', 800)]
          : const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: isAlive,
      teamSide: teamSide,
      slotIndex: slotIndex,
    );
  }

  static BattleState build() {
    final left = [
      _make(
        id: 1,
        name: '萧夜寒',
        tier: RealmTier.yiLiu,
        layer: RealmLayer.huaJing,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxIf: 6000,
        currentIf: 5400,
        teamSide: 0,
        slotIndex: 0,
      ),
      _make(
        id: 2,
        name: '柳青衫',
        tier: RealmTier.erLiu,
        layer: RealmLayer.jingTong,
        school: TechniqueSchool.lingQiao,
        maxHp: 8000,
        currentHp: 4200,
        maxIf: 4500,
        currentIf: 1800,
        teamSide: 0,
        slotIndex: 1,
      ),
      _make(
        id: 3,
        name: '苏锦书',
        tier: RealmTier.erLiu,
        layer: RealmLayer.shuLian,
        school: TechniqueSchool.yinRou,
        maxHp: 7500,
        currentHp: 1500,
        maxIf: 5000,
        currentIf: 600,
        teamSide: 0,
        slotIndex: 2,
      ),
    ];
    final right = [
      _make(
        id: 11,
        name: '黑风寨主',
        tier: RealmTier.yiLiu,
        layer: RealmLayer.yuanShu,
        school: TechniqueSchool.gangMeng,
        maxHp: 14000,
        currentHp: 9800,
        maxIf: 5500,
        currentIf: 3200,
        teamSide: 1,
        slotIndex: 0,
      ),
      _make(
        id: 12,
        name: '影刺',
        tier: RealmTier.erLiu,
        layer: RealmLayer.dengFeng,
        school: TechniqueSchool.lingQiao,
        maxHp: 6500,
        currentHp: 2100,
        maxIf: 4000,
        currentIf: 1200,
        teamSide: 1,
        slotIndex: 1,
      ),
      _make(
        id: 13,
        name: '毒娘子',
        tier: RealmTier.erLiu,
        layer: RealmLayer.ruMen,
        school: TechniqueSchool.yinRou,
        maxHp: 6000,
        currentHp: 0,
        maxIf: 3500,
        currentIf: 0,
        teamSide: 1,
        slotIndex: 2,
        isAlive: false,
      ),
    ];
    return BattleState.initial(leftTeam: left, rightTeam: right);
  }
}
