import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';

/// 终局机制型 Boss 批次3 · Task 4 Part A：镜像脆弱窗口 + 蓄力技注入单元。
///
/// 验注入逻辑本身：**在 mirror_vulnerability_per_stage 映射中**的关注入
/// vulnerabilityMult + chargeSkillId + 蓄力技进 availableSkills；不在映射中的关
/// 保持纯镜像（三者全空/null）。本单元用合成 def（此处只配 05/06）驱动，故下方
/// 「未配」指该合成 def 未列的关（如 01-04）；生产真实数据 05/06/07 均配窗口
/// （见 numbers.yaml `mirror_vulnerability_per_stage`），别据本合成 def 反推生产。

InnerDemonDef _vulnDef() => InnerDemonDef.fromYaml(<String, dynamic>{
  'mirror_buff_per_stage': {
    'stage_inner_demon_01': 0.10,
    'stage_inner_demon_05': 0.18,
    'stage_inner_demon_06': 0.20,
    'stage_inner_demon_07': 0.40,
  },
  'mirror_vulnerability_per_stage': {
    'stage_inner_demon_05': {'outOfWindowDamageMult': 0.12},
    'stage_inner_demon_06': {'outOfWindowDamageMult': 0.10},
  },
  'mirror_charge_skill_id': 'skill_inner_demon_charge',
});

const SkillDef _chargeSkill = SkillDef(
  id: 'skill_inner_demon_charge',
  name: '心魔·运劲',
  description: 'test stub',
  type: SkillType.powerSkill,
  powerMultiplier: 4000,
  internalForceCost: 200,
  cooldownTurns: 4,
  requiresManualTrigger: false,
  visualEffect: 'inner_demon_charge_surge',
  style: TechniqueSchool.gangMeng,
);

BattleCharacter _mockPlayer({
  int slotIndex = 0,
  int characterId = 100,
  String name = '玩家',
}) => BattleCharacter(
  characterId: characterId,
  name: name,
  realmTier: RealmTier.wuSheng,
  realmLayer: RealmLayer.huaJing,
  school: TechniqueSchool.gangMeng,
  maxHp: 12000,
  currentHp: 12000,
  maxInternalForce: 10000,
  currentInternalForce: 10000,
  speed: 250,
  criticalRate: 0.15,
  evasionRate: 0.05,
  defenseRate: 0.35,
  totalEquipmentAttack: 1500,
  mainCultivationLayer: CultivationLayer.jiJing,
  availableSkills: const <SkillDef>[
    SkillDef(
      id: 'skill_player_power',
      name: '玩家强力技',
      description: 'stub',
      type: SkillType.powerSkill,
      powerMultiplier: 300,
      internalForceCost: 100,
      cooldownTurns: 2,
      requiresManualTrigger: false,
      visualEffect: 'x',
    ),
  ],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 0,
  slotIndex: slotIndex,
  iconPath: 'assets/portraits/player.png',
);

List<BattleCharacter> _team() => [
  _mockPlayer(slotIndex: 0, characterId: 100, name: '主角'),
  _mockPlayer(slotIndex: 1, characterId: 101, name: '徒弟甲'),
  _mockPlayer(slotIndex: 2, characterId: 102, name: '徒弟乙'),
];

void main() {
  group('buildMirrorEnemyTeam 脆弱窗口注入', () {
    test('Test1 stage 05/06 注入 vulnerabilityMult + chargeSkillId + 蓄力技', () {
      final def = _vulnDef();
      for (final (stage, mult) in [
        ('stage_inner_demon_05', 0.12),
        ('stage_inner_demon_06', 0.10),
      ]) {
        final mirrors = InnerDemonService.buildMirrorEnemyTeam(
          playerTeam: _team(),
          stageId: stage,
          innerDemonDef: def,
          mirrorChargeSkill: _chargeSkill,
        );
        expect(mirrors, hasLength(3), reason: stage);
        for (final m in mirrors) {
          expect(m.vulnerabilityMult, mult, reason: '$stage vulnerabilityMult');
          expect(
            m.chargeSkillId,
            'skill_inner_demon_charge',
            reason: '$stage chargeSkillId',
          );
          expect(
            m.availableSkills.any((s) => s.id == 'skill_inner_demon_charge'),
            isTrue,
            reason: '$stage availableSkills 含蓄力技',
          );
        }
      }
    });

    test('Test2 未配 vuln 的关（02，不在合成 def 映射）→ 纯镜像（三者全空/null）', () {
      // 注：生产 07 已配窗口；此处用合成 def 未列的 02 验「不在映射→不注入」，
      // 不再拿 07 当反例（曾误导，见文件头注）。
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: _team(),
        stageId: 'stage_inner_demon_02',
        innerDemonDef: _vulnDef(),
        mirrorChargeSkill: _chargeSkill,
      );
      for (final m in mirrors) {
        expect(m.vulnerabilityMult, isNull, reason: '02 无脆弱窗口');
        expect(m.chargeSkillId, isNull, reason: '02 无蓄力技 id');
        expect(
          m.availableSkills.any((s) => s.id == 'skill_inner_demon_charge'),
          isFalse,
          reason: '02 availableSkills 不含蓄力技',
        );
      }
    });

    test('Test3 stage 01 无 vuln → 同 02 纯镜像', () {
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: _team(),
        stageId: 'stage_inner_demon_01',
        innerDemonDef: _vulnDef(),
        mirrorChargeSkill: _chargeSkill,
      );
      for (final m in mirrors) {
        expect(m.vulnerabilityMult, isNull);
        expect(m.chargeSkillId, isNull);
        expect(
          m.availableSkills.any((s) => s.id == 'skill_inner_demon_charge'),
          isFalse,
        );
      }
    });

    test('Test4 mirrorChargeSkill 缺省 → 原子退化纯镜像（防永久免疫 footgun）', () {
      // 脆弱窗口是「vuln 减伤 + 蓄力开窗」耦合机制：无蓄力技 → 不注 vuln，
      // 否则镜像永不进蓄力态 = 永久免疫无解（balance R5.1 纯镜像 callsite 会踩）。
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: _team(),
        stageId: 'stage_inner_demon_05',
        innerDemonDef: _vulnDef(),
      );
      for (final m in mirrors) {
        expect(m.vulnerabilityMult, isNull, reason: '无蓄力技 → 不注 vuln（原子）');
        expect(m.chargeSkillId, isNull);
        expect(
          m.availableSkills.any((s) => s.id == 'skill_inner_demon_charge'),
          isFalse,
        );
      }
    });

    test('P1-12 镜像显式清空 iconPath,走首字降级', () {
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: _team(),
        stageId: 'stage_inner_demon_01',
        innerDemonDef: _vulnDef(),
      );

      expect(mirrors, hasLength(3));
      expect(
        mirrors.every((m) => m.iconPath == null),
        isTrue,
        reason: 'BattleCharacter.copyWith 必须允许 iconPath:null 覆盖玩家头像',
      );
    });
  });
}
