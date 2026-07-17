import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';

/// C2.3a：断魂庄「快照 → 本关玩家队」纯装配（`GauntletController.stagePlayerTeam`）。
///
/// 满血基准队（`buildPlayerTeamForCharacters` 产出）+ 会话成员快照 → 本关出战队：
/// - 首关（member.maxHp==0 = enter 占位·无检查点）→ 满血基准全员进队，不覆盖；
/// - 关次间（maxHp>0 = 有战末检查点）→ 按快照覆盖当前生命/真气/技能冷却；
/// - 阵亡/血尽者剔除（残阵只带存活者·镜像 `ExpeditionCombatRunner.fight`）。
/// 纯函数·不碰 Isar。
const _normal = SkillDef(
  id: 'skill_stage_team_normal',
  name: '普攻',
  description: 'fixture',
  type: SkillType.normalAttack,
  powerMultiplier: 60,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'stub',
);

BattleCharacter _bc(
  int id, {
  int maxHp = 18000,
  int currentHp = 18000,
  int maxQi = 140,
  int currentQi = 80,
  Map<String, int> cooldowns = const {},
  bool isAlive = true,
}) => BattleCharacter(
  characterId: id,
  name: '玩家$id',
  realmTier: RealmTier.erLiu,
  realmLayer: RealmLayer.yuanShu,
  school: TechniqueSchool.gangMeng,
  maxHp: maxHp,
  currentHp: currentHp,
  internalForce: 3000,
  maxQi: maxQi,
  currentQi: currentQi,
  speed: 120,
  criticalRate: 0.1,
  evasionRate: 0.05,
  defenseRate: 0.15,
  totalEquipmentAttack: 1500,
  mainCultivationLayer: CultivationLayer.daCheng,
  availableSkills: const [_normal],
  skillCooldowns: cooldowns,
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: isAlive,
  teamSide: 0,
  slotIndex: id - 1,
);

ActivityMemberSnapshot _snap(
  int id, {
  int maxHp = 0,
  int currentHp = 0,
  int maxQi = 0,
  int currentQi = 0,
  bool downed = false,
  List<String> cdKeys = const [],
  List<int> cdTurns = const [],
}) => ActivityMemberSnapshot()
  ..characterId = id
  ..maxHp = maxHp
  ..currentHp = currentHp
  ..maxQi = maxQi
  ..currentQi = currentQi
  ..isDowned = downed
  ..skillCooldownKeys = cdKeys
  ..skillCooldownTurns = cdTurns;

void main() {
  test('首关（member.maxHp==0 占位）→ 满血基准全员进队·不覆盖', () {
    final base = [_bc(1), _bc(2), _bc(3)];
    final members = [_snap(1), _snap(2), _snap(3)]; // maxHp=0 = enter 占位
    final team = GauntletController.stagePlayerTeam(
      baseTeam: base,
      members: members,
    );
    expect(team.map((c) => c.characterId), [1, 2, 3]);
    expect(
      team.every((c) => c.currentHp == 18000),
      isTrue,
      reason: '首关无检查点·应保满血基准',
    );
    expect(team.every((c) => c.currentQi == 80), isTrue);
  });

  test('关次间（maxHp>0 检查点）→ 覆盖当前生命/真气', () {
    final base = [_bc(1)];
    final members = [
      _snap(1, maxHp: 18000, currentHp: 5000, maxQi: 140, currentQi: 30),
    ];
    final team = GauntletController.stagePlayerTeam(
      baseTeam: base,
      members: members,
    );
    expect(team.single.currentHp, 5000);
    expect(team.single.currentQi, 30);
    expect(team.single.maxHp, 18000, reason: '满血上界不变');
  });

  test('检查点技能冷却重建进 skillCooldowns', () {
    final base = [_bc(1)];
    final members = [
      _snap(
        1,
        maxHp: 18000,
        currentHp: 9000,
        cdKeys: ['skill_a', 'skill_b'],
        cdTurns: [2, 4],
      ),
    ];
    final team = GauntletController.stagePlayerTeam(
      baseTeam: base,
      members: members,
    );
    expect(team.single.skillCooldowns, {'skill_a': 2, 'skill_b': 4});
  });

  test('阵亡者（isDowned）剔除出本关队', () {
    final base = [_bc(1), _bc(2)];
    final members = [
      _snap(1, maxHp: 18000, currentHp: 6000),
      _snap(2, maxHp: 18000, currentHp: 0, downed: true),
    ];
    final team = GauntletController.stagePlayerTeam(
      baseTeam: base,
      members: members,
    );
    expect(team.map((c) => c.characterId), [1], reason: '倒下者不带入下一关');
  });

  test('血尽（currentHp<=0·未标 downed）也剔除', () {
    final base = [_bc(1), _bc(2)];
    final members = [
      _snap(1, maxHp: 18000, currentHp: 6000),
      _snap(2, maxHp: 18000, currentHp: 0),
    ];
    final team = GauntletController.stagePlayerTeam(
      baseTeam: base,
      members: members,
    );
    expect(team.map((c) => c.characterId), [1]);
  });

  test('baseTeam 中非会话成员（无对应 member）跳过', () {
    final base = [_bc(1), _bc(9)];
    final members = [_snap(1)]; // 只 1 是会话成员
    final team = GauntletController.stagePlayerTeam(
      baseTeam: base,
      members: members,
    );
    expect(team.map((c) => c.characterId), [1]);
  });
}
