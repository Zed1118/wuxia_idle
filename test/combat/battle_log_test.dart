import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/combat/battle_engine.dart';
import 'package:wuxia_idle/combat/battle_log.dart';
import 'package:wuxia_idle/combat/battle_state.dart';
import 'package:wuxia_idle/combat/damage_calculator.dart';
import 'package:wuxia_idle/combat/enum_localizations.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/technique.dart';

/// BattleLog + EnumL10n 单元测试（phase1_tasks.md T13 §746-748 验收）。
///
/// 覆盖：
/// 1. EnumL10n 各 enum 中文化（不出现拼音 / 全枚举值有映射）。
/// 2. formatAction 5 类分支：普通 / 暴击 / 闪避 / 流派克制（克方 + 被克方）/ 击杀。
/// 3. formatSummary 含胜负 + 总 tick + 最高伤害角色 + 被击杀名单。
/// 4. **集成验收（§747）**：跑一场完整战斗，formatAllActions + formatSummary
///    输出覆盖 行动顺序 / 伤害数字 / 胜负 / 不出现 enum 拼音。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  // ────────────────────────────────────────────────────────────────────────
  // EnumL10n
  // ────────────────────────────────────────────────────────────────────────

  group('EnumL10n', () {
    test('TechniqueSchool 全 3 值中文化', () {
      expect(EnumL10n.school(TechniqueSchool.gangMeng), '刚猛');
      expect(EnumL10n.school(TechniqueSchool.lingQiao), '灵巧');
      expect(EnumL10n.school(TechniqueSchool.yinRou), '阴柔');
    });

    test('BattleResult 全 3 值中文化', () {
      expect(EnumL10n.battleResult(BattleResult.leftWin), '左队胜');
      expect(EnumL10n.battleResult(BattleResult.rightWin), '右队胜');
      expect(EnumL10n.battleResult(BattleResult.draw), '平局');
    });

    test('RealmTier 全 7 值中文化（GDD §3.1）', () {
      expect(EnumL10n.realmTier(RealmTier.xueTu), '学徒');
      expect(EnumL10n.realmTier(RealmTier.sanLiu), '三流');
      expect(EnumL10n.realmTier(RealmTier.erLiu), '二流');
      expect(EnumL10n.realmTier(RealmTier.yiLiu), '一流');
      expect(EnumL10n.realmTier(RealmTier.jueDing), '绝顶');
      expect(EnumL10n.realmTier(RealmTier.zongShi), '宗师');
      expect(EnumL10n.realmTier(RealmTier.wuSheng), '武圣');
    });

    test('RealmLayer 全 7 值中文化', () {
      for (final v in RealmLayer.values) {
        final s = EnumL10n.realmLayer(v);
        expect(s.length, greaterThan(0));
        expect(s, isNot(contains(v.name)),
            reason: 'RealmLayer.${v.name} 不应出现拼音原值');
      }
    });

    test('SkillType 全 4 值中文化', () {
      for (final v in SkillType.values) {
        final s = EnumL10n.skillType(v);
        expect(s.length, greaterThan(0));
        expect(s, isNot(contains(v.name)));
      }
    });

    test('attackEffect 已知 3 值映射 + 未知 fallback 原样', () {
      expect(EnumL10n.attackEffect('extra_quake_dmg'), '附带震伤');
      expect(EnumL10n.attackEffect('crit_rate_+0.20'), '暴击率 +20%');
      expect(EnumL10n.attackEffect('internal_injury'), '施加内伤');
      // 未知 → 原样兜底，日志层不抛错
      expect(EnumL10n.attackEffect('unknown_xyz'), 'unknown_xyz');
    });

    test('realm(tier, layer) 拼接', () {
      expect(EnumL10n.realm(RealmTier.wuSheng, RealmLayer.dengFeng), '武圣登峰');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BattleLog.formatAction 分支
  // ────────────────────────────────────────────────────────────────────────

  group('BattleLog.formatAction', () {
    test('普通命中：含 tick / 双方名 / 招式名 / 伤害数', () {
      final s = _twoCharState();
      final action = BattleAction(
        tick: 12,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult: _normalHit(damage: 826),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('[第 12 tick]'));
      expect(str, contains('左0'));
      expect(str, contains('右0'));
      expect(str, contains('直拳'));
      expect(str, contains('826'));
      expect(str, contains('伤害'));
      expect(str, isNot(contains('暴击')));
      expect(str, isNot(contains('击杀')));
    });

    test('暴击命中：含「暴击造成」标识', () {
      final s = _twoCharState();
      final action = BattleAction(
        tick: 5,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_skill'),
        attackResult: _normalHit(damage: 1500, isCritical: true),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('暴击'));
      expect(str, contains('1500'));
    });

    test('闪避：含「被闪避」与百分比', () {
      final s = _twoCharState();
      final action = BattleAction(
        tick: 8,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult:
            AttackResult.dodged(evasionRate: 0.12, breakdown: 'DODGED'),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('被闪避'));
      expect(str, contains('12%'));
      expect(str, isNot(contains('伤害')));
    });

    test('流派克制 — 攻方克制：刚猛 vs 阴柔，含「刚猛克阴柔」与倍率', () {
      // 阴柔 defender 用 yinRou tech；attacker 用 gangMeng（默认）
      final left = _mkBC(charId: 1, teamSide: 0, school: TechniqueSchool.gangMeng);
      final right = _mkBC(
        charId: 11,
        teamSide: 1,
        school: TechniqueSchool.yinRou,
        techDefId: 'tech_yinrou_jichu',
        techTier: TechniqueTier.ruMenGong,
      );
      final s = BattleState.initial(leftTeam: [left], rightTeam: [right]);
      final action = BattleAction(
        tick: 3,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult: _normalHit(
          damage: 1200,
          schoolMult: 1.25,
          appliedEffects: const ['extra_quake_dmg'],
        ),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('刚猛克阴柔'));
      expect(str, contains('1.25'));
      expect(str, contains('附带震伤'));
      expect(str, isNot(contains('gangMeng')));
      expect(str, isNot(contains('yinRou')));
    });

    test('流派克制 — 攻方被克：阴柔 vs 刚猛，含「刚猛克阴柔」（克方主语）', () {
      final left = _mkBC(
        charId: 1,
        teamSide: 0,
        school: TechniqueSchool.yinRou,
        techDefId: 'tech_yinrou_jichu',
        techTier: TechniqueTier.ruMenGong,
      );
      final right = _mkBC(charId: 11, teamSide: 1, school: TechniqueSchool.gangMeng);
      final s = BattleState.initial(leftTeam: [left], rightTeam: [right]);
      final action = BattleAction(
        tick: 4,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_yinrou_jichu_basic'),
        attackResult: _normalHit(damage: 600, schoolMult: 0.75),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      // attacker=阴柔, defender=刚猛, 倍率 < 1.0 → "刚猛克阴柔"（克方主语）
      expect(str, contains('刚猛克阴柔'));
      expect(str, contains('0.75'));
    });

    test('击杀：target 已死亡 → 含「击杀」', () {
      final left = _mkBC(charId: 1, teamSide: 0);
      final dead = _mkBC(charId: 11, teamSide: 1).copyWith(
        currentHp: 0,
        isAlive: false,
      );
      final s = BattleState.initial(leftTeam: [left], rightTeam: [dead]);
      final action = BattleAction(
        tick: 47,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult: _normalHit(damage: 980),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('击杀'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BattleLog.formatSummary
  // ────────────────────────────────────────────────────────────────────────

  group('BattleLog.formatSummary', () {
    test('胜负 + 总 tick + 最高伤害 + 击杀名单', () {
      final left = _mkBC(charId: 1, teamSide: 0);
      final dead = _mkBC(charId: 11, teamSide: 1).copyWith(
        currentHp: 0,
        isAlive: false,
      );
      final s = BattleState(
        leftTeam: [left],
        rightTeam: [dead],
        tick: 87,
        result: BattleResult.leftWin,
        actionLog: [
          BattleAction(
            tick: 10,
            actorId: 1,
            targetId: 11,
            skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
            attackResult: _normalHit(damage: 500),
            description: '',
          ),
          BattleAction(
            tick: 30,
            actorId: 1,
            targetId: 11,
            skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_skill'),
            attackResult: _normalHit(damage: 8420, isCritical: true),
            description: '',
          ),
        ],
      );
      final str = BattleLog.formatSummary(s);
      expect(str, contains('左队胜'));
      expect(str, contains('87 tick'));
      expect(str, contains('8420'));
      expect(str, contains('左0'));
      expect(str, contains('被击杀'));
      expect(str, contains('右0'));
    });

    test('未结束 → "未结束" 占位 / 无攻击 → 不输出最高伤害', () {
      final left = _mkBC(charId: 1, teamSide: 0);
      final right = _mkBC(charId: 11, teamSide: 1);
      final s = BattleState.initial(leftTeam: [left], rightTeam: [right]);
      final str = BattleLog.formatSummary(s);
      expect(str, contains('未结束'));
      expect(str, contains('0 tick'));
      expect(str, isNot(contains('最高单次伤害')));
      expect(str, isNot(contains('被击杀')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 集成验收（phase1_tasks T13 §747）
  // ────────────────────────────────────────────────────────────────────────

  test('集成：跑一场完整战斗，日志覆盖 行动/伤害/胜负 + 不出现 enum 拼音', () {
    final left = List.generate(
      3,
      (i) => _mkBC(charId: 1 + i, teamSide: 0, slotIndex: i),
    );
    final right = List.generate(
      3,
      (i) => _mkBC(charId: 11 + i, teamSide: 1, slotIndex: i),
    );
    final s0 = BattleState.initial(leftTeam: left, rightTeam: right);
    final sFinal = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 500,
      rng: Random(42),
    );

    expect(sFinal.isFinished, true);
    expect(sFinal.actionLog, isNotEmpty);

    final allLogs = BattleLog.formatAllActions(sFinal);
    final summary = BattleLog.formatSummary(sFinal);
    final combined = '$allLogs\n$summary';

    // 行动顺序：每条以 [第 N tick] 开头
    expect(allLogs.split('\n').every((line) => line.startsWith('[第 ')), true,
        reason: 'formatAllActions 每行应以 tick 标记开头');
    // 含伤害数字
    expect(combined, matches(RegExp(r'\d+ 伤害')));
    // 含胜负
    expect(
      combined,
      anyOf(contains('左队胜'), contains('右队胜'), contains('平局')),
    );
    // 不出现 enum 拼音（验收 §748 钉死）
    final pinyinHits = [
      'gangMeng',
      'lingQiao',
      'yinRou',
      'leftWin',
      'rightWin',
      'normalAttack',
      'powerSkill',
    ];
    for (final p in pinyinHits) {
      expect(combined, isNot(contains(p)),
          reason: '日志不应出现 enum 拼音 "$p"');
    }
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// fixture
// ─────────────────────────────────────────────────────────────────────────────

BattleState _twoCharState() {
  final left = _mkBC(charId: 1, teamSide: 0);
  final right = _mkBC(charId: 11, teamSide: 1);
  return BattleState.initial(leftTeam: [left], rightTeam: [right]);
}

/// 构造一个 AttackResult，便于精准注入到 BattleAction（绕开 DamageCalculator
/// 的随机性，让日志测试与战斗公式解耦）。
AttackResult _normalHit({
  required int damage,
  bool isCritical = false,
  double schoolMult = 1.0,
  List<String> appliedEffects = const [],
}) {
  return AttackResult(
    finalDamage: damage,
    isCritical: isCritical,
    isDodged: false,
    schoolCounterMultiplier: schoolMult,
    realmDiffAttackerMod: 1.0,
    realmDiffDefenderMod: 1.0,
    cultivationMultiplier: 1.0,
    criticalMultiplier: isCritical ? 1.5 : 1.0,
    defenseRate: 0.0,
    evasionRate: 0.0,
    appliedEffects: appliedEffects,
    formulaBreakdown: 'test = $damage',
  );
}

BattleCharacter _mkBC({
  required int charId,
  required int teamSide,
  int slotIndex = 0,
  TechniqueSchool school = TechniqueSchool.gangMeng,
  String techDefId = 'tech_gangmeng_mingjia',
  TechniqueTier techTier = TechniqueTier.mingJiaGong,
}) {
  final c = Character.create(
    name: '${teamSide == 0 ? "左" : "右"}$slotIndex',
    realmTier: RealmTier.erLiu,
    realmLayer: RealmLayer.yuanShu,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 3000,
    school: school,
  )..id = charId;
  final eq = Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: 580,
  );
  final tech = Technique.create(
    defId: techDefId,
    ownerCharacterId: charId,
    tier: techTier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: CultivationLayer.zhongCheng,
  );
  return BattleCharacter.fromCharacter(
    character: c,
    equipped: [eq],
    mainTechnique: tech,
    numbers: GameRepository.instance.numbers,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );
}
