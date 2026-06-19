import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/battle_state.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
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
    bool isBoss = false,
    String? iconPath,
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
    isBoss: isBoss,
    iconPath: iconPath,
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
      String icon,
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
      iconPath: icon,
    );

    // 真敌人立绘验收:左右队各注入真实 assets/enemies/*.png(2026-06-04
    // Codex 验收发现 battle_scene 路由用测试角色无 iconPath 全落首字 fallback)。
    return (
      [
        c(21, '刚猛甲', TechniqueSchool.gangMeng, 0, 0,
            'assets/enemies/thug_a.png'),
        c(22, '灵巧乙', TechniqueSchool.lingQiao, 0, 1,
            'assets/enemies/ruffian_a.png'),
        c(23, '阴柔丙', TechniqueSchool.yinRou, 0, 2,
            'assets/enemies/bandit_b.png'),
      ],
      [
        c(31, '阴柔甲', TechniqueSchool.yinRou, 1, 0,
            'assets/enemies/you_hufa.png'),
        c(32, '刚猛乙', TechniqueSchool.gangMeng, 1, 1,
            'assets/enemies/shidi_b.png'),
        c(33, '灵巧丙', TechniqueSchool.lingQiao, 1, 2,
            'assets/enemies/xiliangboss.png'),
      ],
    );
  }

  /// B2 Boss 边框验收:同 scenarioB 但右队首位标 Boss。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioBoss() {
    BattleCharacter c(int id, String name, TechniqueSchool school, int side,
            int slot,
            {bool isBoss = false, String? icon}) =>
        _char(
          id: id, name: name,
          tier: RealmTier.yiLiu, layer: RealmLayer.qiMeng,
          school: school, maxHp: 12000, maxIf: 4000, speed: 200,
          critRate: 0.05, eqAtk: 550, cultivation: CultivationLayer.xiaoCheng,
          skills: [
            _normal('boss_normal_$id', '普攻'),
            _power('boss_power_$id', '重击', pm: 1200, cost: 1000, cd: 3),
          ],
          teamSide: side, slotIndex: slot, isBoss: isBoss, iconPath: icon,
        );
    // Boss 位注入真实 boss 立绘(xiliangboss)验金边;其余真敌人图。
    return (
      [
        c(21, '刚猛甲', TechniqueSchool.gangMeng, 0, 0,
            icon: 'assets/enemies/thug_a.png'),
        c(22, '灵巧乙', TechniqueSchool.lingQiao, 0, 1,
            icon: 'assets/enemies/ruffian_a.png'),
        c(23, '阴柔丙', TechniqueSchool.yinRou, 0, 2,
            icon: 'assets/enemies/bandit_b.png'),
      ],
      [
        c(31, '西凉霸主', TechniqueSchool.yinRou, 1, 0,
            isBoss: true, icon: 'assets/enemies/xiliangboss.png'),
        c(32, '刚猛乙', TechniqueSchool.gangMeng, 1, 1,
            icon: 'assets/enemies/you_hufa.png'),
        c(33, '灵巧丙', TechniqueSchool.lingQiao, 1, 2,
            icon: 'assets/enemies/shidi_b.png'),
      ],
    );
  }

  /// 破招 UI 静态验收:青衫剑客正蓄「青锋绝」(chargeTicksRemaining=2),
  /// 玩家主控带「破势」且就绪(内力满 + 不在 CD)。配合 BattleScreen(autoStart:false)
  /// 画面冻结在此 seed 态 —— Boss 头像显蓄力条 + flash 图标,底栏破招按钮金色高亮。
  ///
  /// 数值照 stages.yaml stage_02_05 青衫剑客调校值(HP9500/攻1150/灵巧/sanLiu·yuanShu)。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioChargeBreak() {
    final repo = GameRepository.instance;
    final qingfeng = repo.getSkill('skill_qingshan_qingfeng'); // 青锋绝(蓄力大招)
    final poShi = repo.getSkill('skill_po_shi'); // 破势(玩家破招技)

    // ── 左队(玩家):主控带破势 + 基础招,内力满、破势不在 CD → 破招按钮 ready+高亮。
    BattleCharacter player(int id, String name, int slot, List<SkillDef> skills) =>
        _char(
          id: id,
          name: name,
          tier: RealmTier.sanLiu,
          layer: RealmLayer.yuanShu,
          school: TechniqueSchool.gangMeng,
          maxHp: 8000,
          maxIf: 600, // ≥ 主控全技能 cost(破势120/强力150/共鸣200/大招250)→ 全 ready
          speed: 180,
          critRate: 0.05,
          eqAtk: 400,
          cultivation: CultivationLayer.daCheng,
          skills: skills,
          teamSide: 0,
          slotIndex: slot,
        );

    final left = [
      player(1, '主控', 0, [
        _normal('cb_normal_1', '基础招'),
        // T1 指令台验收:主控带满 强力/破招/共鸣/大招 四组,让验收能看到分组指令台
        // 全貌 + 不溢出(破势仍 canInterrupt → 敌蓄力时自动焦点落主控,破招高亮)。
        _power('cb_power_1', '崩山式', pm: 1600, cost: 150, cd: 2), // 强力
        poShi, // 破势:canInterrupt → 破招按钮取此技
        const SkillDef(
          id: 'cb_joint_1',
          name: '人剑合一',
          description: '',
          type: SkillType.jointSkill,
          powerMultiplier: 4500,
          internalForceCost: 200,
          cooldownTurns: 4,
          requiresManualTrigger: false,
          visualEffect: '',
        ), // 共鸣
        _ultimate('cb_ult_1', '裂空斩', 250), // 大招
      ]),
      player(2, '弟子甲', 1, [_normal('cb_normal_2', '基础招')]),
      player(3, '弟子乙', 2, [_normal('cb_normal_3', '基础招')]),
    ];

    // ── 右队(敌):首位青衫剑客 seed 成「正蓄青锋绝」态;另 2 小怪普通。
    final qingshan = _char(
      id: 11,
      name: '青衫剑客',
      tier: RealmTier.sanLiu,
      layer: RealmLayer.yuanShu,
      school: TechniqueSchool.lingQiao,
      maxHp: 9500,
      maxIf: 4000,
      speed: 175,
      critRate: 0.05,
      eqAtk: 1150,
      cultivation: CultivationLayer.daCheng,
      skills: [_normal('cb_qs_normal', '青锋斩'), qingfeng],
      teamSide: 1,
      slotIndex: 0,
      isBoss: true,
      iconPath: 'assets/enemies/qingshan_main.png',
    ).copyWith(
      // 关键:seed 成已蓄力 → BattleScreen 显蓄力条 + 底栏破招高亮。
      chargeSkillId: 'skill_qingshan_qingfeng',
      chargingSkill: qingfeng,
      chargeTicksRemaining: 2,
    );

    BattleCharacter mob(int id, String name, int slot, String icon) => _char(
      id: id,
      name: name,
      tier: RealmTier.sanLiu,
      layer: RealmLayer.yuanShu,
      school: TechniqueSchool.yinRou,
      maxHp: 7500,
      maxIf: 2000,
      speed: 160,
      critRate: 0.05,
      eqAtk: 1000,
      cultivation: CultivationLayer.daCheng,
      skills: [_normal('cb_mob_$id', '杀招')],
      teamSide: 1,
      slotIndex: slot,
      iconPath: icon,
    );

    final right = [
      qingshan,
      mob(12, '巷口杀手', 1, 'assets/enemies/killer_a.png'),
      mob(13, '巷尾杀手', 2, 'assets/enemies/killer_b.png'),
    ];

    return (left, right);
  }

  /// 拖招交互真玩/验收专用(battle_drag_live 路由)。
  ///
  /// 配合 ScenarioLauncher(allowPlayerIntervention:true, autoStart:true):战斗自动
  /// 播放、拖招干预层已挂。**给足时间拖**是核心:
  ///   - 主控**只带普攻 + 两个大招(ultimate)**,不带 powerSkill —— AI `_pickSkill`
  ///     会自动连放 ready 的 powerSkill 造成瞬间 burst;ultimate **只走 pending
  ///     手动触发**(拖/点才放),所以自动战斗只剩弱普攻 chip,战斗拖得很长。
  ///   - 敌人**超高血(40000) + 低攻低速** → 普攻 chip 啃半天不死、也不秒玩家。
  /// 主控 single 大招(拖到敌头像指定目标)+ aoe 大招(长按拖下发，松手即对全体触发)演示两种交互。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioDragLive() {
    // 主控:IF 够放几次大招;eqAtk 低 → 普攻只是弱 chip(不 burst)。
    // school 默认刚猛(主控保持刚猛,不影响 single 拖招的震伤观感);
    // 弟子甲改灵巧 → 敌方阴柔命中其头像即触发内伤,供「内伤」标签 hover 复验。
    BattleCharacter player(
      int id,
      String name,
      int slot,
      List<SkillDef> skills, {
      TechniqueSchool school = TechniqueSchool.gangMeng,
    }) => _char(
      id: id,
      name: name,
      tier: RealmTier.erLiu,
      layer: RealmLayer.yuanShu,
      school: school,
      maxHp: 12000,
      maxIf: 1500,
      speed: 180,
      critRate: 0.05,
      eqAtk: 200,
      cultivation: CultivationLayer.daCheng,
      skills: skills,
      teamSide: 0,
      slotIndex: slot,
    );

    final left = [
      player(1, '主控', 0, [
        _normal('dl_normal_1', '基础招'),
        // single 大招:拖到敌头像指定目标(ultimate → 只手动触发,不自动 burst)。
        const SkillDef(
          id: 'dl_single_1',
          name: '裂石指',
          description: '',
          type: SkillType.ultimate,
          powerMultiplier: 3000,
          internalForceCost: 250,
          cooldownTurns: 3,
          requiresManualTrigger: true,
          visualEffect: '',
        ),
        // aoe 大招:长按拖下发，松手即对全体触发(targetType.aoe)。
        const SkillDef(
          id: 'dl_aoe_1',
          name: '万钧裂空',
          description: '',
          type: SkillType.ultimate,
          powerMultiplier: 5000,
          internalForceCost: 250,
          cooldownTurns: 5,
          requiresManualTrigger: true,
          visualEffect: '',
          targetType: TargetType.aoe,
        ),
      ]),
      player(
        2,
        '弟子甲',
        1,
        [_normal('dl_normal_2', '基础招')],
        school: TechniqueSchool.lingQiao,
      ),
      player(3, '弟子乙', 2, [_normal('dl_normal_3', '基础招')]),
    ];

    // 敌人:超高血(久撑) + 低攻击/低速(不秒玩家)→ 战斗拖很长,从容拖招。
    BattleCharacter tankMob(int id, String name, int slot, String icon) => _char(
      id: id,
      name: name,
      tier: RealmTier.erLiu,
      layer: RealmLayer.yuanShu,
      school: TechniqueSchool.yinRou,
      maxHp: 40000,
      maxIf: 300,
      speed: 110,
      critRate: 0.05,
      eqAtk: 150,
      cultivation: CultivationLayer.daCheng,
      skills: [_normal('dl_mob_$id', '缠斗')],
      teamSide: 1,
      slotIndex: slot,
      iconPath: icon,
    );

    final right = [
      tankMob(11, '铁布衫客', 0, 'assets/enemies/qingshan_main.png'),
      tankMob(12, '巷口杀手', 1, 'assets/enemies/killer_a.png'),
      tankMob(13, '巷尾杀手', 2, 'assets/enemies/killer_b.png'),
    ];

    return (left, right);
  }

  /// 第七阶段批二目检专用（battle_boss_phase 路由）。
  ///
  /// 真 stage_01_05「撑伞高人」Boss 队（经 [StageBattleSetup.buildEnemyTeam] 建，
  /// bossPhases / schoolDamageTakenMult / 蓄力技全真），Boss HP 抬到 16000 给两阶段
  /// 留足演出步数；配一支**刻意压低 DPS**（chuKui 修炼度 ×1.0 / 低 eqAtk·IF）的玩家队，
  /// 让普攻是「啃」的 chip 而非秒杀——配合路由 startPaused，逐步看清每个动效。
  ///
  /// 看点：① 跌破 50% → 背水一击转阶段题字 + 闪白 + 立绘抖动 + 蓄力反扑；
  /// ② 刚猛（gangMeng）队员打 yinRou Boss → 弱点 ×1.25 会心 glyph；
  /// ③ 灵巧（lingQiao）队员打 Boss → 抗性 ×0.75（伤害偏低，无会心）。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioBossPhase() {
    // ── 右队：真 stage_01_05 敌队；Boss（slot 0）HP 抬高给两阶段演出步数。
    final stage = GameRepository.instance.getStage('stage_01_05');
    final realEnemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
    final right = [
      for (var i = 0; i < realEnemies.length; i++)
        i == 0
            ? realEnemies[i].copyWith(maxHp: 16000, currentHp: 16000)
            : realEnemies[i],
    ];

    // ── 左队：2 刚猛（会心来源）+ 1 灵巧（示抗性）。**压低 DPS** 是关键：
    // chuKui 修炼度 ×1.0（daCheng 是 ×1.5）+ 低 eqAtk/IF → 普攻 ~950（弱点）/~570（抗性），
    // 配 16000 Boss + startPaused 单步 → 战斗够长、每个动效看得清，不被秒杀冲过去。
    BattleCharacter player(
      int id,
      String name,
      int slot,
      TechniqueSchool school,
    ) => _char(
      id: id,
      name: name,
      tier: RealmTier.xueTu,
      layer: RealmLayer.dengFeng,
      school: school,
      maxHp: 9000,
      maxIf: 500,
      speed: 165,
      critRate: 0.05,
      eqAtk: 150,
      cultivation: CultivationLayer.chuKui,
      skills: [
        _normal('bp_normal_$id', '基础招'),
        _power('bp_power_$id', '重击', pm: 1200, cost: 400, cd: 3),
      ],
      teamSide: 0,
      slotIndex: slot,
    );

    final left = [
      player(1, '主控', 0, TechniqueSchool.gangMeng),
      player(2, '弟子甲', 1, TechniqueSchool.gangMeng),
      player(3, '弟子乙', 2, TechniqueSchool.lingQiao),
    ];

    return (left, right);
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
  final String? hint;

  /// 出版美术验收:传给 BattleScreen 渲染场景背景 + scrim。null = 无背景。
  final String? sceneBackgroundPath;

  /// 透传给 BattleScreen.autoStart(默认 true 现有用法不变);
  /// false 时画面冻结在 startBattle seed 态,用于静态截蓄力/破招帧。
  final bool autoStart;

  /// 战斗随机种子(确定性验收):null = 不传(seed 自动生成)。
  final int? seed;

  /// 透传给 BattleScreen.allowPlayerIntervention(默认 false 现有静态验收用法不变);
  /// true 时挂拖招干预层(技能按钮长按拖 + 引导线 + drop 命中),供 battle_drag_live
  /// 路由真玩/Codex 验拖招手势。
  final bool allowPlayerIntervention;

  /// 透传给 BattleScreen.debugDragPreview(拖招表现层静态验收预置态)。
  final BattleDragPreview? debugDragPreview;

  /// 透传给 BattleScreen.startPaused(默认 false 现有用法不变);true 时起手暂停,
  /// 战斗冻结 seed 初态 + 顶栏出「单步」键供验收者逐步推进操作拖招。
  final bool startPaused;

  const ScenarioLauncher({
    required this.teamsFactory,
    required this.hint,
    this.sceneBackgroundPath,
    this.autoStart = true,
    this.seed,
    this.allowPlayerIntervention = false,
    this.debugDragPreview,
    this.startPaused = false,
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
      ref
          .read(battleProvider.notifier)
          .startBattle(left, right, seed: widget.seed);
    });
  }

  @override
  Widget build(BuildContext context) => BattleScreen(
    hint: widget.hint,
    sceneBackgroundPath: widget.sceneBackgroundPath,
    autoStart: widget.autoStart,
    allowPlayerIntervention: widget.allowPlayerIntervention,
    debugDragPreview: widget.debugDragPreview,
    startPaused: widget.startPaused,
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
