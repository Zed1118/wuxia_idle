import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/battle_state.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/enums.dart';
import '../../battle/application/battle_providers.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../battle/presentation/battle_visual_roster.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';

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
        c(
          21,
          '刚猛甲',
          TechniqueSchool.gangMeng,
          0,
          0,
          'assets/enemies/thug_a.png',
        ),
        c(
          22,
          '灵巧乙',
          TechniqueSchool.lingQiao,
          0,
          1,
          'assets/enemies/ruffian_a.png',
        ),
        c(
          23,
          '阴柔丙',
          TechniqueSchool.yinRou,
          0,
          2,
          'assets/enemies/bandit_b.png',
        ),
      ],
      [
        c(
          31,
          '阴柔甲',
          TechniqueSchool.yinRou,
          1,
          0,
          'assets/enemies/you_hufa.png',
        ),
        c(
          32,
          '刚猛乙',
          TechniqueSchool.gangMeng,
          1,
          1,
          'assets/enemies/shidi_b.png',
        ),
        c(
          33,
          '灵巧丙',
          TechniqueSchool.lingQiao,
          1,
          2,
          'assets/enemies/xiliangboss.png',
        ),
      ],
    );
  }

  /// B2 Boss 边框验收:同 scenarioB 但右队首位标 Boss。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioBoss() {
    BattleCharacter c(
      int id,
      String name,
      TechniqueSchool school,
      int side,
      int slot, {
      bool isBoss = false,
      String? icon,
    }) => _char(
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
        _normal('boss_normal_$id', '普攻'),
        _power('boss_power_$id', '重击', pm: 1200, cost: 1000, cd: 3),
      ],
      teamSide: side,
      slotIndex: slot,
      isBoss: isBoss,
      iconPath: icon,
    );
    // 冻结帧直接使用透明战斗立绘，避免旧头像纸底在全人物舞台上
    // 显露矩形边缘。Boss 位保留塔主体量与金边验收语义。
    return (
      [
        c(
          21,
          '刚猛甲',
          TechniqueSchool.gangMeng,
          0,
          0,
          icon: WuxiaUi.battleFounderFallback,
        ),
        c(
          22,
          '灵巧乙',
          TechniqueSchool.lingQiao,
          0,
          1,
          icon: WuxiaUi.battleFirstDiscipleFallback,
        ),
        c(
          23,
          '阴柔丙',
          TechniqueSchool.yinRou,
          0,
          2,
          icon: WuxiaUi.battleSecondDiscipleFallback,
        ),
      ],
      [
        c(
          31,
          '西凉霸主',
          TechniqueSchool.yinRou,
          1,
          0,
          isBoss: true,
          icon: WuxiaUi.battleTowerBoss20Standee,
        ),
        c(
          32,
          '刚猛乙',
          TechniqueSchool.gangMeng,
          1,
          1,
          icon: WuxiaUi.battleBanditBladeStandee,
        ),
        c(
          33,
          '灵巧丙',
          TechniqueSchool.lingQiao,
          1,
          2,
          icon: WuxiaUi.battleBanditArcherStandee,
        ),
      ],
    );
  }

  /// 破招 UI 静态验收:青衫剑客正蓄「青锋绝」(chargeTicksRemaining=2),
  /// 玩家主控带「破势」且就绪(内力满 + 不在 CD)。配合 BattleScreen(autoStart:false)
  /// 画面冻结在此 seed 态 —— Boss 头像显蓄力条 + flash 图标,底栏破招按钮金色高亮。
  ///
  /// 数值照 stages.yaml stage_02_05 青衫剑客调校值(HP9500/攻900/灵巧/sanLiu·yuanShu)。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioChargeBreak() {
    final repo = GameRepository.instance;
    final qingfeng = repo.getSkill('skill_qingshan_qingfeng'); // 青锋绝(蓄力大招)
    final poShi = repo.getSkill('skill_po_shi'); // 破势(玩家破招技)

    // ── 左队(玩家):主控带破势 + 基础招,内力满、破势不在 CD → 破招按钮 ready+高亮。
    BattleCharacter player(
      int id,
      String name,
      int slot,
      List<SkillDef> skills,
    ) => _char(
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
    ).copyWith(actionPoint: 1);

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
      // 弟子甲 seed 成中内伤态 → 头像上显内伤读秒环(SteppedCountdownRing·暗绛),
      // 让本验收路由一帧同显三类读秒环(蓄力/破绽/内伤)。
      player(2, '弟子甲', 1, [_normal('cb_normal_2', '基础招')]).copyWith(
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
      ),
      player(3, '弟子乙', 2, [_normal('cb_normal_3', '基础招')]),
    ];

    // ── 右队(敌):首位青衫剑客 seed 成「正蓄青锋绝」态;另 2 小怪普通。
    final qingshan =
        _char(
          id: 11,
          name: '青衫剑客',
          tier: RealmTier.sanLiu,
          layer: RealmLayer.yuanShu,
          school: TechniqueSchool.lingQiao,
          maxHp: 9500,
          maxIf: 4000,
          speed: 175,
          critRate: 0.05,
          eqAtk: 900,
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
      // 巷口杀手 seed 成破绽态 → 头像上显破绽读秒环(BeatCountdownRing·暖金机会色),
      // 呼应路由名「ChargeBreak」应同显蓄力(青衫)+破绽(此)两态。
      mob(
        12,
        '巷口杀手',
        1,
        'assets/enemies/killer_a.png',
      ).copyWith(staggerTicksRemaining: 2),
      mob(13, '巷尾杀手', 2, 'assets/enemies/killer_b.png'),
    ];

    return (left, right);
  }

  /// 两段点选交互真玩/验收专用(battle_tap_live / battle_tap_preview 路由)。
  ///
  /// 配合 ScenarioLauncher(allowPlayerIntervention:true, autoStart:true):战斗自动
  /// 播放、点选干预层已挂。**给足时间操作**是核心:
  ///   - 主控**只带普攻 + 两个大招(ultimate)**,不带 powerSkill —— AI `_pickSkill`
  ///     会自动连放 ready 的 powerSkill 造成瞬间 burst;ultimate **只走 pending
  ///     手动触发**(点按才放),所以自动战斗只剩弱普攻 chip,战斗持续很久。
  ///   - 敌人**超高血(40000) + 低攻低速** → 普攻 chip 啃半天不死、也不秒玩家。
  /// 主控 single 大招(点敌头像指定目标)+ aoe 大招(点技能即对全体触发)演示两种交互。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioDragLive() {
    // 主控:IF 够放几次大招;eqAtk 低 → 普攻只是弱 chip(不 burst)。
    // school 默认刚猛(主控保持刚猛,不影响 single 指定目标的震伤观感);
    // 弟子甲改灵巧 → 敌方阴柔命中其头像即触发内伤,供「内伤」标签 hover 复验。
    BattleCharacter player(
      int id,
      String name,
      int slot,
      List<SkillDef> skills, {
      TechniqueSchool school = TechniqueSchool.gangMeng,
      String? iconPath,
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
      iconPath: iconPath,
    );

    final left = [
      player(1, UiStrings.battleSampleFounder, 0, [
        _normal('dl_normal_1', '基础招'),
        // 七枚非普攻签固定对应 2026-07-15 黄金样板；id 保持稳定，沿用待发预览接线。
        const SkillDef(
          id: 'dl_single_1',
          name: UiStrings.battleSampleSkillOpenMountain,
          description: '',
          type: SkillType.powerSkill,
          powerMultiplier: 1200,
          internalForceCost: 20,
          cooldownTurns: 3,
          requiresManualTrigger: true,
          visualEffect: '',
        ),
        const SkillDef(
          id: 'dl_aoe_1',
          name: UiStrings.battleSampleSkillBreakCurrent,
          description: '',
          type: SkillType.powerSkill,
          powerMultiplier: 1000,
          internalForceCost: 30,
          cooldownTurns: 5,
          requiresManualTrigger: true,
          visualEffect: '',
          canInterrupt: true,
          style: TechniqueSchool.gangMeng,
        ),
        const SkillDef(
          id: 'dl_single_2',
          name: UiStrings.battleSampleSkillSnowStep,
          description: '',
          type: SkillType.ultimate,
          powerMultiplier: 2600,
          internalForceCost: 35,
          cooldownTurns: 2,
          requiresManualTrigger: true,
          visualEffect: '',
          targetType: TargetType.aoe,
        ),
        const SkillDef(
          id: 'dl_aoe_2',
          name: UiStrings.battleSampleSkillReturnOne,
          description: '',
          type: SkillType.ultimate,
          powerMultiplier: 3200,
          internalForceCost: 60,
          cooldownTurns: 4,
          requiresManualTrigger: true,
          visualEffect: '',
        ),
        const SkillDef(
          id: 'dl_single_3',
          name: UiStrings.battleSampleSkillSwallowReturn,
          description: '',
          type: SkillType.jointSkill,
          powerMultiplier: 4500,
          internalForceCost: 15,
          cooldownTurns: 6,
          requiresManualTrigger: true,
          visualEffect: '',
        ),
        const SkillDef(
          id: 'dl_single_4',
          name: UiStrings.battleSampleSkillMeridianCut,
          description: '',
          type: SkillType.ultimate,
          powerMultiplier: 2800,
          internalForceCost: 25,
          cooldownTurns: 3,
          requiresManualTrigger: true,
          visualEffect: '',
          source: SkillSource.encounter,
        ),
        const SkillDef(
          id: 'dl_single_5',
          name: UiStrings.battleSampleSkillHiddenEdge,
          description: '',
          type: SkillType.powerSkill,
          powerMultiplier: 1800,
          internalForceCost: 30,
          cooldownTurns: 5,
          requiresManualTrigger: true,
          visualEffect: '',
          canInterrupt: true,
          style: TechniqueSchool.gangMeng,
        ),
      ]).copyWith(
        maxHp: 4982,
        currentHp: 4982,
        maxQi: 100,
        currentQi: 68,
        skillCooldowns: const {'dl_single_2': 2},
      ),
      player(
        2,
        UiStrings.battleSampleFirstDisciple,
        1,
        [_normal('dl_normal_2', '基础招')],
        school: TechniqueSchool.lingQiao,
        iconPath: WuxiaUi.battleSampleFirstDiscipleStandee,
      ).copyWith(maxHp: 3564, currentHp: 3564, maxQi: 100, currentQi: 55),
      player(3, UiStrings.battleSampleSecondDisciple, 2, [
        _normal('dl_normal_3', '基础招'),
      ]).copyWith(maxHp: 3781, currentHp: 3781, maxQi: 100, currentQi: 50),
    ];

    // 敌人:超高血(久撑) + 低攻击/低速(不秒玩家)→ 战斗拖很长,从容点选。
    BattleCharacter tankMob(int id, String name, int slot, String icon) =>
        _char(
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

    final elder =
        tankMob(
          11,
          UiStrings.battleSampleHiddenElder,
          0,
          WuxiaUi.battleSampleHiddenElderStandee,
        ).copyWith(
          isBoss: true,
          maxHp: 7820,
          currentHp: 7820,
          maxQi: 100,
          currentQi: 90,
        );
    final elderCharge = elder.availableSkills.first;
    final right = [
      elder.copyWith(
        chargeSkillId: elderCharge.id,
        chargingSkill: elderCharge,
        chargeTicksRemaining: 2,
      ),
      tankMob(
        12,
        UiStrings.battleSampleBanditBlade,
        1,
        WuxiaUi.battleSampleBanditBladeStandee,
      ).copyWith(maxHp: 3126, currentHp: 3126, maxQi: 100, currentQi: 45),
      tankMob(
        13,
        UiStrings.battleSampleBanditArcher,
        2,
        WuxiaUi.battleSampleBanditArcherStandee,
      ).copyWith(maxHp: 2894, currentHp: 2894, maxQi: 100, currentQi: 50),
    ];

    return (left, right);
  }

  /// 多敌同拍蓄势的确定性视觉审查帧。复用黄金样板人物与技能，
  /// 只更改已有 [BattleCharacter] 蓄势字段，不改战斗规则或配置。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioV2MultiCharge() {
    final (left, right) = scenarioDragLive();
    final chargeSkill = right.first.chargingSkill!;
    const remaining = [3, 1, 2];
    return (
      left,
      [
        for (var i = 0; i < right.length; i++)
          right[i].copyWith(
            chargingSkill: chargeSkill,
            chargeTicksRemaining: remaining[i],
          ),
      ],
    );
  }

  /// 战斗人物素材角色门禁验收：有档案肖像、但尚无专用透明站姿的弟子，
  /// 在正式战场只显示同流派透明身份剪影，绝不把带背景肖像铺进人物位。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioIdentitySilhouette() {
    final (leftTemplates, right) = scenarioDragLive();
    final sources = [
      (name: '竹影', path: 'assets/characters/sect_candidate_bamboo.png'),
      (name: '砺锋', path: 'assets/characters/sect_candidate_blacksmith.png'),
      (name: '流沙', path: 'assets/characters/sect_candidate_desert.png'),
    ];
    final left = [
      for (var i = 0; i < leftTemplates.length; i++)
        leftTemplates[i].copyWith(
          name: sources[i].name,
          iconPath: sources[i].path,
        ),
    ];
    return (left, right);
  }

  /// V2 S10：首发敌人一击阵亡，第四人按击杀日志递补进同一视觉槽。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioV2CasualtyReplacement() {
    final (leftTemplates, rightTemplates) = scenarioDragLive();
    final left = [
      leftTemplates.first.copyWith(actionPoint: 1000, speed: 1000),
      ...leftTemplates.skip(1),
    ];
    final right = <BattleCharacter>[
      rightTemplates[0].copyWith(currentHp: 1, characterId: 310),
      rightTemplates[1].copyWith(characterId: 311),
      rightTemplates[2].copyWith(characterId: 312),
      rightTemplates[0].copyWith(
        characterId: 313,
        slotIndex: 3,
        currentHp: rightTemplates[0].maxHp,
      ),
    ];
    return (left, right);
  }

  /// V2 S11：AI 首动释放群体强力技，同 tick 生成至少两条伤害动作。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioV2FastForwardPeak() {
    final (leftTemplates, right) = scenarioDragLive();
    const aoe = SkillDef(
      id: 'v2_fast_forward_aoe',
      name: '横江式',
      description: '',
      type: SkillType.powerSkill,
      powerMultiplier: 1200,
      internalForceCost: 100,
      cooldownTurns: 3,
      requiresManualTrigger: false,
      visualEffect: '',
      targetType: TargetType.aoe,
    );
    final first = leftTemplates.first.copyWith(
      availableSkills: [leftTemplates.first.availableSkills.first, aoe],
      currentQi: 500,
      actionPoint: 1000,
      speed: 1000,
    );
    return ([first, ...leftTemplates.skip(1)], right);
  }

  /// V2 S12：固定在一名残血敌人、玩家下一 action 即可取胜的前一拍。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioV2PreResult() {
    final (leftTemplates, rightTemplates) = scenarioDragLive();
    final left = [
      leftTemplates.first.copyWith(actionPoint: 1000, speed: 1000),
      ...leftTemplates.skip(1),
    ];
    final right = [rightTemplates.first.copyWith(currentHp: 1, maxHp: 1)];
    return (left, right);
  }

  /// V2 S7：同一执招者一签冷却，另一签因真气不足不可用。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioV2ResourcePressure() {
    final (leftTemplates, right) = scenarioDragLive();
    final first = leftTemplates.first.copyWith(
      currentQi: 10,
      skillCooldowns: const {'dl_single_1': 2},
    );
    return ([first, ...leftTemplates.skip(1)], right);
  }

  /// A 案动态证据：前两名我方角色各带一枚 AI 可自动使用的签。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioV2AutoRotation() {
    final (leftTemplates, right) = scenarioDragLive();
    const firstSkill = SkillDef(
      id: 'v2_auto_rotation_first',
      name: '崩山式',
      description: '',
      type: SkillType.powerSkill,
      powerMultiplier: 900,
      internalForceCost: 100,
      cooldownTurns: 2,
      requiresManualTrigger: false,
      visualEffect: '',
    );
    const secondSkill = SkillDef(
      id: 'v2_auto_rotation_second',
      name: '穿云式',
      description: '',
      type: SkillType.powerSkill,
      powerMultiplier: 850,
      internalForceCost: 100,
      cooldownTurns: 2,
      requiresManualTrigger: false,
      visualEffect: '',
    );
    final first = leftTemplates[0].copyWith(
      availableSkills: [leftTemplates[0].availableSkills.first, firstSkill],
      currentQi: 500,
      actionPoint: 1000,
      speed: 1000,
    );
    final second = leftTemplates[1].copyWith(
      availableSkills: [leftTemplates[1].availableSkills.first, secondSkill],
      currentQi: 500,
      actionPoint: 1000,
      speed: 900,
    );
    return ([first, second, leftTemplates[2]], right);
  }

  /// 群战舞台静态验收：当前三名主战敌 + 四名后续敌军墨影。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioMassBattleStage() {
    final (leftTemplates, templates) = scenarioDragLive();
    // 只供 !kReleaseMode visual route 动态验收：所有字段仍守正式红线上限。
    // 左队耐久拉满、右队压低输出以保证能打到队尾；左队输出保持中段，
    // 给四名后备敌军是否实际递补留下可观察窗口。
    final left = [
      for (final c in leftTemplates)
        c.copyWith(
          maxHp: 20000,
          currentHp: 20000,
          internalForce: 3000,
          totalEquipmentAttack: 500,
        ),
    ];
    final right = [
      for (var i = 0; i < 7; i++)
        templates[i % templates.length].copyWith(
          characterId: 200 + i,
          slotIndex: i,
          maxHp: 12000,
          currentHp: 12000,
          attackPowerMultiplier: 0.05,
          isAlive: true,
        ),
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

  // ── 场景 护法结界：真 floor30 终局塔队(九霄魔尊 + 左使/右使)vs 宗师 on-level ──
  //
  // 右队 = **真 towers.yaml floor30 敌队**(不合成),Boss 的 guardianWard(0.15 /
  // guardianIds=[左使,右使])随 EnemyDef 经 buildEnemyTeam 原样接线:两护法存活
  // → Boss 头像旁「护法结界」护罩 pill(WuxiaColors.internalForce)+ boss 金边 +
  // 流派克制标同屏堆叠(多 tag 验收)。startPaused 起手冻结在护罩生效帧供静态截图;
  // 手动步进清完两护法 → 破界题字「结界破！」+ 破界闪白(复用相位通道)动效可看。
  //
  // 左队 = 3 宗师 dengFeng on-level(2 刚猛[boss 吃 ×1.25]+ 1 灵巧),真能逐步清护法
  // 演出破界,不被秒杀也不打不动。纯展示 scenario·零碰 numbers/结算(承伤仍走真管线)。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioGuardianWard() {
    // 真 floor30 塔层(towerFloors 按 floorIndex 升序,索引 29 = 第 30 层)。
    final floor30 = GameRepository.instance.towerFloors[29];
    final right = StageBattleSetup.buildEnemyTeam(
      floor30.enemyTeam,
      isTower: true,
    );

    BattleCharacter player(
      int id,
      String name,
      int slot,
      TechniqueSchool school,
    ) => _char(
      id: id,
      name: name,
      tier: RealmTier.zongShi,
      layer: RealmLayer.dengFeng,
      school: school,
      maxHp: 18000,
      maxIf: 10000,
      speed: 240,
      critRate: 0.15,
      eqAtk: 1500,
      cultivation: CultivationLayer.yuanMan,
      skills: [
        _normal('gw_normal_$id', '基础招'),
        _power('gw_power_$id', '重击', pm: 2400, cost: 800, cd: 3),
        _ultimate('gw_ult_$id', '绝命式', 2000),
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

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor13() => scenarioTowerFloorStandeeAudit(13);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor14() => scenarioTowerFloorStandeeAudit(14);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor19() => scenarioTowerFloorStandeeAudit(19);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor22() => scenarioTowerFloorStandeeAudit(22);

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0102() =>
      scenarioStageStandeeAudit('stage_01_02');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0103() =>
      scenarioStageStandeeAudit('stage_01_03');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0104() =>
      scenarioStageStandeeAudit('stage_01_04');

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor02() => scenarioTowerFloorStandeeAudit(2);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor03() => scenarioTowerFloorStandeeAudit(3);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor08() => scenarioTowerFloorStandeeAudit(8);

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0401() =>
      scenarioStageStandeeAudit('stage_04_01');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0402() =>
      scenarioStageStandeeAudit('stage_04_02');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0403() =>
      scenarioStageStandeeAudit('stage_04_03');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0404() =>
      scenarioStageStandeeAudit('stage_04_04');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0405() =>
      scenarioStageStandeeAudit('stage_04_05');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0501() =>
      scenarioStageStandeeAudit('stage_05_01');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0502() =>
      scenarioStageStandeeAudit('stage_05_02');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0503() =>
      scenarioStageStandeeAudit('stage_05_03');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0504() =>
      scenarioStageStandeeAudit('stage_05_04');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0505() =>
      scenarioStageStandeeAudit('stage_05_05');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0601() =>
      scenarioStageStandeeAudit('stage_06_01');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0602() =>
      scenarioStageStandeeAudit('stage_06_02');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0603() =>
      scenarioStageStandeeAudit('stage_06_03');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0604() =>
      scenarioStageStandeeAudit('stage_06_04');

  static (List<BattleCharacter>, List<BattleCharacter>) scenarioStage0605() =>
      scenarioStageStandeeAudit('stage_06_05');

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor06() => scenarioTowerFloorStandeeAudit(6);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor07() => scenarioTowerFloorStandeeAudit(7);

  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloor12() => scenarioTowerFloorStandeeAudit(12);

  /// 敌人立绘逐关验收：右队读取真主线关卡，左队只提供稳定的三人尺度参照。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioStageStandeeAudit(String stageId) {
    final stage = GameRepository.instance.getStage(stageId);
    final right = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
    final (left, _) = scenarioGuardianWard();
    return (left, right);
  }

  /// 敌人立绘逐层验收：右队读取真塔层，左队只提供稳定的三人尺度参照。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioTowerFloorStandeeAudit(int floorIndex) {
    final floor = GameRepository.instance.towerFloors[floorIndex - 1];
    final right = StageBattleSetup.buildEnemyTeam(
      floor.enemyTeam,
      isTower: true,
    );
    final (left, _) = scenarioGuardianWard();
    return (left, right);
  }

  /// 敌人立绘逐关次验收（断魂庄）：右队读真 `boss_gauntlets.yaml`，左队同上作尺度参照。
  ///
  /// 断魂庄敌队独立于 `stageDefs`（`GameRepository._enforceGauntletEnemyRedLines`
  /// 头注已注明），故这里按 `stages[i].enemyTeamId` 查 `enemyTeams`，
  /// 与生产 `gauntlet_entry_flow` 走同一条 `StageBattleSetup.buildEnemyTeam`
  /// （不传 `isTower`，与生产一致）。
  static (List<BattleCharacter>, List<BattleCharacter>)
  scenarioGauntletStandeeAudit(int stageOrdinal) {
    final config = GameRepository.instance.bossGauntletConfig;
    if (config == null) {
      throw StateError('boss_gauntlets.yaml 未加载，断魂庄立绘验收无从取敌队');
    }
    final stage = config.stages[stageOrdinal - 1];
    final defs = config.enemyTeams[stage.enemyTeamId];
    if (defs == null) {
      throw StateError(
        'boss_gauntlets: 关次 $stageOrdinal 的 enemy_team_id='
        '${stage.enemyTeamId} 在 enemy_teams 里不存在',
      );
    }
    final right = StageBattleSetup.buildEnemyTeam(defs);
    final (left, _) = scenarioGuardianWard();
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

const int battleV2VisualSeed = 20260719;

enum VisualBattleReadyTarget {
  initialized,
  casualtyReplacement,
  fastForwardPeak,
  preResult,
  resourcePressure,
  autoRotationFirst,
  autoRotationSecond,
}

class VisualBattleReplayResult {
  const VisualBattleReplayResult({
    required this.state,
    required this.steps,
    required this.summary,
  });

  final BattleState state;
  final int steps;
  final String summary;
}

/// 固定 seed 推进到视觉目标；只调用既有 [BattleNotifier]，不改规则或持久化。
class VisualBattleReplay {
  const VisualBattleReplay._();

  static VisualBattleReplayResult run({
    required BattleNotifier notifier,
    required BattleState Function() readState,
    required (List<BattleCharacter>, List<BattleCharacter>) teams,
    required int seed,
    required VisualBattleReadyTarget target,
  }) {
    final (left, right) = teams;
    notifier.startBattle(left, right, seed: seed);
    var state = readState();
    var steps = 0;
    while (!matches(target, state) && !state.isFinished && steps < 2000) {
      notifier.advanceOneAction();
      state = readState();
      steps++;
    }
    if (!matches(target, state)) {
      throw StateError(
        'V2 visual target ${target.name} not reached '
        '(seed=$seed, tick=${state.tick}, steps=$steps, '
        'result=${state.result?.name})',
      );
    }
    return VisualBattleReplayResult(
      state: state,
      steps: steps,
      summary: summary(target, state, steps: steps, seed: seed),
    );
  }

  static bool matches(VisualBattleReadyTarget target, BattleState state) =>
      switch (target) {
        VisualBattleReadyTarget.initialized =>
          state.leftTeam.length == 3 &&
              state.rightTeam.length == 3 &&
              state.actionLog.isEmpty &&
              !state.isFinished,
        VisualBattleReadyTarget.casualtyReplacement => _hasCasualtyReplacement(
          state,
        ),
        VisualBattleReadyTarget.fastForwardPeak => _peakActionCount(state) >= 2,
        VisualBattleReadyTarget.preResult =>
          !state.isFinished &&
              state.rightTeam.where((c) => c.isAlive).length == 1 &&
              state.rightTeam.where((c) => c.isAlive).single.currentHp == 1,
        VisualBattleReadyTarget.resourcePressure => _hasResourcePressure(state),
        VisualBattleReadyTarget.autoRotationFirst => _autoRotationActors(
          state,
        ).isNotEmpty,
        VisualBattleReadyTarget.autoRotationSecond =>
          _autoRotationActors(state).length >= 2,
      };

  static List<int> _autoRotationActors(BattleState state) {
    final playerIds = state.leftTeam.map((actor) => actor.characterId).toSet();
    final actors = <int>[];
    for (final action in state.actionLog) {
      final skill = action.skill;
      if (!playerIds.contains(action.actorId) ||
          skill == null ||
          skill.type == SkillType.normalAttack ||
          skill.requiresManualTrigger) {
        continue;
      }
      if (!actors.contains(action.actorId)) actors.add(action.actorId);
    }
    return actors;
  }

  static bool _hasCasualtyReplacement(BattleState state) {
    if (state.rightTeam.length <= 3) return false;
    final openingIds = state.rightTeam
        .take(3)
        .map((c) => c.characterId)
        .toSet();
    final roster = BattleVisualRoster.fromState(state);
    return state.actionLog.any(
          (action) =>
              action.defeatedTarget && openingIds.contains(action.targetId),
        ) &&
        roster.rightSlots.whereType<int>().any(
          (characterId) => !openingIds.contains(characterId),
        );
  }

  static int _peakActionCount(BattleState state) {
    if (state.actionLog.isEmpty) return 0;
    final last = state.actionLog.last;
    return state.actionLog
        .where(
          (action) =>
              action.tick == last.tick &&
              action.actorId == last.actorId &&
              action.skill?.id == last.skill?.id &&
              action.attackResult != null,
        )
        .length;
  }

  static bool _hasResourcePressure(BattleState state) {
    if (state.leftTeam.isEmpty) return false;
    final focus = state.leftTeam.first;
    final hasCooldown = focus.skillCooldowns.values.any((turns) => turns > 0);
    final hasQiShortage = focus.availableSkills.any(
      (skill) =>
          skill.qiCost > focus.currentQi &&
          (focus.skillCooldowns[skill.id] ?? 0) == 0,
    );
    return hasCooldown && hasQiShortage;
  }

  static String summary(
    VisualBattleReadyTarget target,
    BattleState state, {
    required int steps,
    required int seed,
  }) {
    final leftAlive = state.leftTeam.where((c) => c.isAlive).length;
    final rightAlive = state.rightTeam.where((c) => c.isAlive).length;
    final extras = switch (target) {
      VisualBattleReadyTarget.casualtyReplacement =>
        ' slots=${BattleVisualRoster.fromState(state).rightSlots.join(',')}',
      VisualBattleReadyTarget.fastForwardPeak =>
        ' peakActions=${_peakActionCount(state)}',
      VisualBattleReadyTarget.autoRotationFirst ||
      VisualBattleReadyTarget.autoRotationSecond =>
        ' rotationActors=${_autoRotationActors(state).join(',')}'
            ' activeActor=${state.actionLog.last.actorId}'
            ' activeSkill=${state.actionLog.last.skill?.id}',
      _ => '',
    };
    return 'seed=$seed tick=${state.tick} steps=$steps '
        'leftAlive=$leftAlive rightAlive=$rightAlive '
        'target=${target.name} actions=${state.actionLog.length}$extras';
  }
}

/// 将指定场景的 teams 推入 [BattleNotifier] 并渲染 [BattleScreen]。
///
/// 结束后通过 [BattleScreen.onBattleEnd] 回 pop 到 [BattleTestMenu]。
class ScenarioLauncher extends ConsumerStatefulWidget {
  final (List<BattleCharacter>, List<BattleCharacter>) Function() teamsFactory;
  final String? hint;

  /// 出版美术验收:传给 BattleScreen 渲染场景背景 + scrim。null = 无背景。
  final String? sceneBackgroundPath;

  /// 特殊战斗舞台模式由 BGM 轨道同源派生（心魔/轻功/群战）。
  final BgmTrack bgmTrack;

  /// 透传给 BattleScreen.autoStart(默认 true 现有用法不变);
  /// false 时画面冻结在 startBattle seed 态,用于静态截蓄力/破招帧。
  final bool autoStart;

  /// 战斗随机种子(确定性验收):null = 不传(seed 自动生成)。
  final int? seed;

  /// 透传给 BattleScreen.allowPlayerIntervention(默认 false 现有静态验收用法不变);
  /// true 时挂干预层(技能按钮点选 + 引导高亮),供 battle_tap_live 路由真玩/Codex 验证。
  final bool allowPlayerIntervention;

  /// 静态验收预览专用:纯 presentation 初始待发态,不写 BattleState。
  final int? previewPendingCharacterId;
  final String? previewPendingSkillId;
  final List<BattlePouchPreviewItem> previewPouchItems;
  final bool previewHeaderControls;

  /// 透传给 BattleScreen.startPaused(默认 false 现有用法不变);true 时起手暂停,
  /// 战斗冻结 seed 初态 + 顶栏出「单步」键供验收者逐步推进操作点选。
  final bool startPaused;

  /// V2 验收 route 专用：由固定 seed 回放控制器命中目标状态后才允许 READY。
  final VisualBattleReadyTarget? readyTarget;
  final ValueChanged<String>? onTargetReady;

  const ScenarioLauncher({
    required this.teamsFactory,
    required this.hint,
    this.sceneBackgroundPath,
    this.bgmTrack = BgmTrack.battle,
    this.autoStart = true,
    this.seed,
    this.allowPlayerIntervention = false,
    this.previewPendingCharacterId,
    this.previewPendingSkillId,
    this.previewPouchItems = const [],
    this.previewHeaderControls = false,
    this.startPaused = false,
    this.readyTarget,
    this.onTargetReady,
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
      final teams = widget.teamsFactory();
      final target = widget.readyTarget;
      if (target == null) {
        final (left, right) = teams;
        ref
            .read(battleProvider.notifier)
            .startBattle(left, right, seed: widget.seed);
        return;
      }
      final result = VisualBattleReplay.run(
        notifier: ref.read(battleProvider.notifier),
        readState: () => ref.read(battleProvider),
        teams: teams,
        seed: widget.seed ?? battleV2VisualSeed,
        target: target,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onTargetReady?.call(result.summary);
      });
    });
  }

  @override
  Widget build(BuildContext context) => BattleScreen(
    hint: widget.hint,
    sceneBackgroundPath: widget.sceneBackgroundPath,
    bgmTrack: widget.bgmTrack,
    playback: BattleScreenPlaybackConfig(
      autoStart: widget.autoStart,
      allowPlayerIntervention: widget.allowPlayerIntervention,
      startPaused: widget.startPaused,
      previewPouchItems: widget.previewPouchItems,
      previewHeaderControls: widget.previewHeaderControls,
    ),
    previewPendingCharacterId: widget.previewPendingCharacterId,
    previewPendingSkillId: widget.previewPendingSkillId,
    onSurrender: widget.previewHeaderControls
        ? () => Navigator.of(context).maybePop()
        : null,
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
