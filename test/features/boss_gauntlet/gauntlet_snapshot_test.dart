import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';

/// 断魂庄 C1.2：三关之间的关次边界白名单快照（§4.2/§5.5）。
///
/// 只继承 当前生命/当前真气/阵亡/技能冷却；行动条、临时 buff/debuff 等**无路径**进快照。
/// reserved 装备/心法为入场占用冻结，来自上一关 `before` 而非战斗 finalState。
BattleCharacter _pc({
  required int id,
  required int hp,
  required int qi,
  required bool alive,
  Map<String, int> cooldowns = const {},
  List<String> buffs = const [],
  int actionPoint = 0,
}) => BattleCharacter(
  characterId: id,
  name: 'c$id',
  realmTier: RealmTier.yiLiu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 1000,
  currentHp: hp,
  internalForce: 100,
  maxQi: 140,
  currentQi: qi,
  speed: 100,
  criticalRate: 0.0,
  evasionRate: 0.0,
  defenseRate: 0.0,
  totalEquipmentAttack: 100,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: cooldowns,
  activeBuffs: buffs,
  actionPoint: actionPoint,
  isAlive: alive,
  teamSide: 0,
  slotIndex: id - 1,
);

ActivityMemberSnapshot _before(
  int id, {
  List<int> eq = const [],
  List<int> tech = const [],
}) => ActivityMemberSnapshot()
  ..characterId = id
  ..reservedEquipmentIds = eq
  ..reservedTechniqueIds = tech
  ..currentHp = 12345 // 哨兵：应被 finalState 覆盖
  ..currentQi = 12345
  ..isDowned = false;

BattleState _stateOf(List<BattleCharacter> left) =>
    BattleState.initial(leftTeam: left, rightTeam: const []);

void main() {
  group('GauntletController.snapshotAfterStage · 关次边界白名单（§4.2/§5.5）', () {
    test('继承 生命/真气/阵亡/技能冷却(仅>0)，并保留 reserved 装备/心法', () {
      final before = [
        _before(1, eq: [10, 11], tech: [20]),
        _before(2, eq: [12]),
      ];
      final finalState = _stateOf([
        _pc(id: 1, hp: 300, qi: 58, alive: true, cooldowns: {
          'skill_a': 3,
          'skill_b': 0, // CD=0 不入快照
        }),
        _pc(id: 2, hp: 0, qi: 0, alive: false),
      ]);

      final after = GauntletController.snapshotAfterStage(
        before: before,
        finalState: finalState,
      );

      // 生命/真气/阵亡 从 finalState 覆盖 before 哨兵
      expect(after[0].currentHp, 300);
      expect(after[0].currentQi, 58);
      expect(after[0].isDowned, false);
      expect(after[1].currentHp, 0);
      expect(after[1].currentQi, 0);
      expect(after[1].isDowned, true);

      // 技能冷却继承，仅保留 >0 项（§5.5 冷却不重置）
      expect(after[0].skillCooldownKeys, ['skill_a']);
      expect(after[0].skillCooldownTurns, [3]);
      expect(after[1].skillCooldownKeys, isEmpty);
      expect(after[1].skillCooldownTurns, isEmpty);

      // reserved 装备/心法来自入场 before，不被战斗覆盖（占用冻结）
      expect(after[0].reservedEquipmentIds, [10, 11]);
      expect(after[0].reservedTechniqueIds, [20]);
      expect(after[1].reservedEquipmentIds, [12]);
    });

    test('临时态无路径进快照：仅 activeBuffs/actionPoint 不同的两战末态产出相同快照', () {
      final plain = _stateOf([
        _pc(id: 1, hp: 300, qi: 58, alive: true, cooldowns: {'x': 2}),
      ]);
      final withTemp = _stateOf([
        _pc(
          id: 1,
          hp: 300,
          qi: 58,
          alive: true,
          cooldowns: {'x': 2},
          buffs: ['charge_up', 'shield'],
          actionPoint: 77,
        ),
      ]);

      final a = GauntletController.snapshotAfterStage(
        before: [_before(1)],
        finalState: plain,
      ).single;
      final b = GauntletController.snapshotAfterStage(
        before: [_before(1)],
        finalState: withTemp,
      ).single;

      // 白名单挡住临时态 → 逐字段相同
      expect(b.currentHp, a.currentHp);
      expect(b.currentQi, a.currentQi);
      expect(b.isDowned, a.isDowned);
      expect(b.skillCooldownKeys, a.skillCooldownKeys);
      expect(b.skillCooldownTurns, a.skillCooldownTurns);
    });
  });
}
