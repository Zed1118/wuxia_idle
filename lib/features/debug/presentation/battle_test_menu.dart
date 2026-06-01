import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/battle_state.dart';
import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../core/application/battle_providers.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

// ─── 场景数据工厂（内存构造，不写 Isar）───────────────────────────────────────

class BattleScenarioData {
  BattleScenarioData._();

  static SkillDef _normal(String id, String name) => SkillDef(
    id: id,
    name: name,
    description: '',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    parentTechniqueDefId: null,
    visualEffect: '',
  );

  /// PM=0 的纯武器斩击，专用于场景 C 隔离装备影响（排除 IF / 招式倍率干扰）。
  static SkillDef _weaponStrike(String id) => SkillDef(
    id: id,
    name: '武器斩',
    description: '',
    type: SkillType.normalAttack,
    powerMultiplier: 0,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    parentTechniqueDefId: null,
    visualEffect: '',
  );

  static SkillDef _power(
    String id,
    String name, {
    int pm = 1200,
    int cost = 1000,
    int cd = 3,
  }) => SkillDef(
    id: id,
    name: name,
    description: '',
    type: SkillType.powerSkill,
    powerMultiplier: pm,
    internalForceCost: cost,
    cooldownTurns: cd,
    requiresManualTrigger: false,
    parentTechniqueDefId: null,
    visualEffect: '',
  );

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

  static BattleCharacter _char({
    required int id,
    required String name,
    required RealmTier tier,
    required RealmLayer layer,
    required TechniqueSchool school,
    required int maxHp,
    required int maxIf,
    required int speed,
    required double critRate,
    required int eqAtk,
    required CultivationLayer cultivation,
    required List<SkillDef> skills,
    required int teamSide,
    required int slotIndex,
  }) => BattleCharacter(
    characterId: id,
    name: name,
    realmTier: tier,
    realmLayer: layer,
    school: school,
    maxHp: maxHp,
    currentHp: maxHp,
    maxInternalForce: maxIf,
    currentInternalForce: maxIf,
    speed: speed,
    criticalRate: critRate,
    evasionRate: 0.05,
    defenseRate: 0.10,
    totalEquipmentAttack: eqAtk,
    mainCultivationLayer: cultivation,
    availableSkills: skills,
    skillCooldowns: const {},
    activeBuffs: const [],
    actionPoint: 0,
    isAlive: true,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );

  // ── 场景 A：二流·圆熟 3v3 同流派同装备，纯比速度 ────────────────────────────
  //
  // 目标伤害：普攻 ≈ 5330（不暴击），暴击 ≈ 7995，全在 2000-8000 区间。
  // 公式：(2200×0.4 + 350×8 + 500) × 1.50 × (1-0.15) = 4180 × 1.275 ≈ 5330
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioA() {
    final skills = [
      _normal('a_normal', '刚猛拳'),
      _ultimate('a_ult', '山岳崩', 2000),
    ];
    BattleCharacter c(int id, String name, int speed, int side, int slot) =>
        _char(
          id: id,
          name: name,
          tier: RealmTier.erLiu,
          layer: RealmLayer.yuanShu,
          school: TechniqueSchool.gangMeng,
          maxHp: 10000,
          maxIf: 3000,
          speed: speed,
          critRate: 0.05,
          eqAtk: 350,
          cultivation: CultivationLayer.daCheng,
          skills: skills,
          teamSide: side,
          slotIndex: slot,
        );

    return (
      [c(1, '铁拳王', 210, 0, 0), c(2, '岩虎', 250, 0, 1), c(3, '烈山', 230, 0, 2)],
      [
        c(11, '碎石拳', 240, 1, 0),
        c(12, '踏地熊', 220, 1, 1),
        c(13, '横扫', 260, 1, 2),
      ],
    );
  }

  // ── 场景 B：一流·启蒙 3v3，左队全面克制右队 ─────────────────────────────────
  //
  // 左：刚猛/灵巧/阴柔，右：阴柔/刚猛/灵巧
  // 克制倍率 1.25 vs 被克制 0.75，比值 1.667。
  // 公式（克制）：(3500×0.4 + 550×8 + 500) × 1.15 × 1.25 × (1-0.20) = 7245
  // 公式（被克）：(3500×0.4 + 550×8 + 500) × 1.15 × 0.75 × (1-0.20) = 4347
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioB() {
    BattleCharacter c(
      int id,
      String name,
      TechniqueSchool school,
      int side,
      int slot,
    ) => _char(
      id: id,
      name: name,
      tier: RealmTier.yiLiu,
      layer: RealmLayer.qiMeng,
      school: school,
      maxHp: 12000,
      maxIf: 4000,
      speed: 200,
      critRate: 0.05,
      eqAtk: 550,
      cultivation: CultivationLayer.xiaoCheng,
      skills: [
        _normal('b_normal_$id', '普攻'),
        _power('b_power_$id', '重击', pm: 1200, cost: 1000, cd: 3),
      ],
      teamSide: side,
      slotIndex: slot,
    );

    return (
      [
        c(21, '刚猛甲', TechniqueSchool.gangMeng, 0, 0),
        c(22, '灵巧乙', TechniqueSchool.lingQiao, 0, 1),
        c(23, '阴柔丙', TechniqueSchool.yinRou, 0, 2),
      ],
      [
        c(31, '阴柔甲', TechniqueSchool.yinRou, 1, 0),
        c(32, '刚猛乙', TechniqueSchool.gangMeng, 1, 1),
        c(33, '灵巧丙', TechniqueSchool.lingQiao, 1, 2),
      ],
    );
  }

  // ── 场景 C：二流·圆熟 1v1，装备对比 ─────────────────────────────────────────
  //
  // 左：基础攻400 × 强化1.60 × 默契1.20 = 768
  // 右：基础攻400（裸装）
  //
  // 注意：装备攻击系数已平衡为 1.0（GDD 原值 8），故 IF 和招式倍率会稀释比值。
  // 本场景用 IF=0 + PM=0 隔离纯武器影响，伤害直接 = eqAtk × 倍率：
  //   左：768 × 1.75 × 0.85 ≈ 1141
  //   右：400 × 1.75 × 0.85 ≈ 594
  //   比值 = 768/400 = 1.92（即 +12强化×默契共鸣的完整加成）
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioC() {
    final leftEqAtk = (400 * 1.6 * 1.20).toInt(); // +12强化 × 默契共鸣 = 768
    const rightEqAtk = 400;

    return (
      [
        _char(
          id: 41,
          name: '持剑者（+12默契）',
          tier: RealmTier.erLiu,
          layer: RealmLayer.yuanShu,
          school: TechniqueSchool.gangMeng,
          maxHp: 12000,
          maxIf: 0,
          speed: 200,
          critRate: 0.0,
          eqAtk: leftEqAtk,
          cultivation: CultivationLayer.yuanMan,
          skills: [_weaponStrike('c_ws_l')],
          teamSide: 0,
          slotIndex: 0,
        ),
      ],
      [
        _char(
          id: 51,
          name: '持剑者（裸装）',
          tier: RealmTier.erLiu,
          layer: RealmLayer.yuanShu,
          school: TechniqueSchool.gangMeng,
          maxHp: 12000,
          maxIf: 0,
          speed: 200,
          critRate: 0.0,
          eqAtk: rightEqAtk,
          cultivation: CultivationLayer.yuanMan,
          skills: [_weaponStrike('c_ws_r')],
          teamSide: 1,
          slotIndex: 0,
        ),
      ],
    );
  }

  // ── 场景 D：三流·登峰 3v3 vs 绝顶·启蒙 3v3 ──────────────────────────────────
  //
  // 境界差 = 3（sanLiu.index=1, jueDing.index=4）→ diff3+ 守方修正 0.05
  // 注意：equipment_attack_factor 已平衡为 1.0，所以内力是伤害的主要来源。
  //
  // 左打右（三流→绝顶）：
  //   basic = 3000×0.4 + 300 + 500 = 2000
  //   final = 2000 × 1.50 × (1-0.25) × 0.05 ≈ 113（100-300 区间）
  //
  // 右打左（绝顶→三流）：
  //   basic = 10000×0.4 + 700 + 500 = 5200
  //   final = 5200 × 1.50 × (1-0.10) × 1.0 = 7020（> 三流 maxHp 6000，一击必杀）
  //
  // （修正挂账 #5：phase1_tasks T17 笔误"差 2"，实际为差 3）
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioD() {
    BattleCharacter lo(int id, String name, int side, int slot) => _char(
      id: id,
      name: name,
      tier: RealmTier.sanLiu,
      layer: RealmLayer.dengFeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 6000,
      maxIf: 3000,
      speed: 180,
      critRate: 0.05,
      eqAtk: 300,
      cultivation: CultivationLayer.daCheng,
      skills: [_normal('d_normal_l_$id', '拙力一击')],
      teamSide: side,
      slotIndex: slot,
    );

    BattleCharacter hi(int id, String name, int side, int slot) => _char(
      id: id,
      name: name,
      tier: RealmTier.jueDing,
      layer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 15000,
      maxIf: 10000, // 高内力保证普攻一击必杀三流（7020 > 6000）
      speed: 230,
      critRate: 0.05,
      eqAtk: 700,
      cultivation: CultivationLayer.daCheng,
      skills: [
        _normal('d_normal_h_$id', '俯视苍生'),
        _power('d_power_h_$id', '降世神拳', pm: 1500, cost: 1200, cd: 3),
      ],
      teamSide: side,
      slotIndex: slot,
    );

    return (
      [lo(61, '三流甲', 0, 0), lo(62, '三流乙', 0, 1), lo(63, '三流丙', 0, 2)],
      [hi(71, '绝顶甲', 1, 0), hi(72, '绝顶乙', 1, 1), hi(73, '绝顶丙', 1, 2)],
    );
  }
}

// ─── 场景启动器 ────────────────────────────────────────────────────────────────

/// 将指定场景的 teams 推入 [BattleNotifier] 并渲染 [BattleScreen]。
///
/// 结束后通过 [BattleScreen.onBattleEnd] 回 pop 到 [BattleTestMenu]。
class ScenarioLauncher extends ConsumerStatefulWidget {
  final (List<BattleCharacter>, List<BattleCharacter>) Function() teamsFactory;
  final String hint;

  /// 出版美术验收:传给 BattleScreen 渲染场景背景 + scrim。null = 无背景。
  final String? sceneBackgroundPath;

  const ScenarioLauncher({
    required this.teamsFactory,
    required this.hint,
    this.sceneBackgroundPath,
    super.key,
  });

  @override
  ConsumerState<ScenarioLauncher> createState() => _ScenarioLauncherState();
}

class _ScenarioLauncherState extends ConsumerState<ScenarioLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final (left, right) = widget.teamsFactory();
      ref.read(battleProvider.notifier).startBattle(left, right);
    });
  }

  @override
  Widget build(BuildContext context) => BattleScreen(
    hint: widget.hint,
    sceneBackgroundPath: widget.sceneBackgroundPath,
    onBattleEnd: () => Navigator.of(context).pop(),
  );
}

// ─── 调试主菜单 ────────────────────────────────────────────────────────────────

/// T17 战斗测试场景入口（取代 [BattleDemoLauncher] 成为 main.dart 的 home）。
class BattleTestMenu extends StatelessWidget {
  const BattleTestMenu({super.key});

  void _launch(
    BuildContext context,
    (List<BattleCharacter>, List<BattleCharacter>) Function() factory,
    String hint,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScenarioLauncher(teamsFactory: factory, hint: hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  UiStrings.testMenuTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                _ScenarioButton(
                  label: UiStrings.scenarioA,
                  hint: UiStrings.hintA,
                  onTap: () => _launch(
                    context,
                    BattleScenarioData.scenarioA,
                    '[${UiStrings.scenarioA}] ${UiStrings.hintA}',
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioB,
                  hint: UiStrings.hintB,
                  onTap: () => _launch(
                    context,
                    BattleScenarioData.scenarioB,
                    '[${UiStrings.scenarioB}] ${UiStrings.hintB}',
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioC,
                  hint: UiStrings.hintC,
                  onTap: () => _launch(
                    context,
                    BattleScenarioData.scenarioC,
                    '[${UiStrings.scenarioC}] ${UiStrings.hintC}',
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioD,
                  hint: UiStrings.hintD,
                  onTap: () => _launch(
                    context,
                    BattleScenarioData.scenarioD,
                    '[${UiStrings.scenarioD}] ${UiStrings.hintD}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenarioButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _ScenarioButton({
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: WuxiaColors.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WuxiaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
