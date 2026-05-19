import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/synergy_def.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// W18-A1.2 hot-loop 升级版红线压测(deterministic 程序化路径,绕 Isar)。
///
/// **本批补的硬阻塞**(基线 hot-loop case 在 yiLiu fixture 数值远低红线,
/// 压不到 §5.4 真值):覆盖 wushen tier + 神物级 base 极端值,真硬验证
/// [StageBattleSetup.applySynergy] 在最大 base × 最大 multiplier 下不破
/// §5.4 红线(maxHp ≤ 20000 / maxIf ≤ 15000 / defenseRate ≤ 0.95)。
///
/// **设计**:
///   - 7 tier × 5 synergy = 35 case 矩阵 + 4 极端 base case
///   - 不走 Isar(seedHotLoopWushen fixture 工作量 ~100 行,且数值平衡问题
///     本质在 base maxHp 派生公式,不在 applySynergy 层,详 PROGRESS 升级版段)
///   - applySynergy 是 static + @visibleForTesting,直接调用
///
/// **memory `feedback_red_line_test_semantics`**:断言上界约束不写具体数字。
/// **memory `feedback_layered_bugs`**:修上层 cap 后下层 base 派生公式破红线
/// 的潜在 bug 会陆续暴露,挂账 Phase 5 / 1.0 数值平衡(equipment.yaml +
/// numbers.yaml 重平衡保证 base maxHp ≤ 16667 让 hpPct 0.20 仍 ≤ 20000)。
void main() {
  group('W18-A1.2 hot-loop 升级版:applySynergy 红线 cap 压测', () {
    // 5 synergy multipliers(对应 data/synergies.yaml 5 组合,本测试不读 yaml
    // 文件以保 deterministic,与 yaml 数值同步靠 synergies_yaml_test 红线校验)
    const synergyMultipliers = <String, SynergyMultipliers>{
      '组合 1 阴阳调和': SynergyMultipliers(
        attackPct: 0.10, speedPct: 0.10, defensePct: 0.10, hpPct: 0.20,
      ),
      '组合 2 刚柔并济': SynergyMultipliers(speedPct: 0.25),
      '组合 3 阴影迅捷': SynergyMultipliers(attackPct: 0.15, speedPct: 0.15),
      '组合 4 同流派精进': SynergyMultipliers(attackPct: 0.20),
      '组合 5 同辈互补': SynergyMultipliers(
        internalForceMaxPct: 0.25, internalForceGrowthPct: 0.10,
      ),
    };

    // 7 tier base 数值矩阵:每 tier 用"该 tier 玩家可达 base maxHp 极值"
    // (P0.1 #38 方案 D 重平衡后:1000 + internalForce × 0.5 + constitution 10 × 400
    //  + 该 tier 装备 hp_max 满)。全 7 阶 base ≤ 16667 设计目标(spec §2),
    // hpPct 0.20 加成后 ≤ 20000 §5.4 红线,日常路径不再触发 cap。
    // 实测极值:wushen 16550 / zongshi 14750 / 全阶过红线(详 closeout 矩阵)。
    const tierBaseStats = <RealmTier, ({int baseMaxHp, int baseMaxIf, double baseDefRate})>{
      RealmTier.xueTu: (baseMaxHp: 5850, baseMaxIf: 1100, baseDefRate: 0.05),
      RealmTier.sanLiu: (baseMaxHp: 6700, baseMaxIf: 2000, baseDefRate: 0.10),
      RealmTier.erLiu: (baseMaxHp: 7950, baseMaxIf: 3500, baseDefRate: 0.15),
      RealmTier.yiLiu: (baseMaxHp: 9650, baseMaxIf: 5700, baseDefRate: 0.20),
      RealmTier.jueDing: (baseMaxHp: 12200, baseMaxIf: 9000, baseDefRate: 0.25),
      RealmTier.zongShi: (baseMaxHp: 14750, baseMaxIf: 12500, baseDefRate: 0.30),
      // wushen 满 base 16550 ≤ 16667 spec §2 目标 + hpPct 0.20 → 19860 ≤ 20000
      RealmTier.wuSheng: (baseMaxHp: 16550, baseMaxIf: 15000, baseDefRate: 0.35),
    };

    /// 极简 base BattleCharacter 构造 helper(填默认值,只接关键 6 字段)。
    BattleCharacter buildBase({
      required RealmTier tier,
      required int maxHp,
      required int maxIf,
      required double defRate,
      int speed = 200,
      int totalEqAtk = 6000, // 3 件神物级 attack 求和上界(2000 × 3)
      TechniqueSchool school = TechniqueSchool.gangMeng,
    }) {
      return BattleCharacter(
        characterId: 1,
        name: 'hot-loop',
        realmTier: tier,
        realmLayer: RealmLayer.qiMeng,
        school: school,
        maxHp: maxHp,
        currentHp: maxHp,
        maxInternalForce: maxIf,
        currentInternalForce: maxIf,
        speed: speed,
        criticalRate: 0.05,
        evasionRate: 0.05,
        defenseRate: defRate,
        totalEquipmentAttack: totalEqAtk,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const [],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );
    }

    /// 红线上界断言 helper(沿 stage_battle_setup_test.dart hot-loop case)。
    void expectRedLines(BattleCharacter ch, {required String label}) {
      expect(ch.maxHp, lessThanOrEqualTo(20000),
          reason: '$label maxHp ${ch.maxHp} 必 ≤ §5.4 玩家血量红线 20000');
      expect(ch.currentHp, lessThanOrEqualTo(ch.maxHp),
          reason: '$label currentHp ≤ maxHp 派生不变式');
      expect(ch.maxInternalForce, lessThanOrEqualTo(15000),
          reason: '$label maxIf ${ch.maxInternalForce} 必 ≤ §5.4 内力红线 15000');
      expect(ch.currentInternalForce, lessThanOrEqualTo(ch.maxInternalForce),
          reason: '$label currentIf ≤ maxIf');
      expect(ch.defenseRate, inInclusiveRange(0.0, 0.95),
          reason: '$label defenseRate ${ch.defenseRate} 必 ∈ [0.0, 0.95] clamp');
      expect(ch.speed, greaterThan(0),
          reason: '$label speed > 0(防战斗卡死)');
      expect(ch.totalEquipmentAttack, greaterThanOrEqualTo(0),
          reason: '$label totalEquipmentAttack ≥ 0(非负)');
    }

    // ── 7 tier × 5 synergy 矩阵(35 case)────────────────────────────────
    for (final tierEntry in tierBaseStats.entries) {
      for (final synEntry in synergyMultipliers.entries) {
        test('${tierEntry.key.name} × ${synEntry.key} → 6 字段 ≤ §5.4 红线',
            () {
          final stats = tierEntry.value;
          final base = buildBase(
            tier: tierEntry.key,
            maxHp: stats.baseMaxHp,
            maxIf: stats.baseMaxIf,
            defRate: stats.baseDefRate,
          );
          final result = StageBattleSetup.applySynergy(base, synEntry.value);
          expectRedLines(result, label: '${tierEntry.key.name}×${synEntry.key}');
        });
      }
    }

    // ── 4 极端 base case(暴露 cap 生效路径)──────────────────────────
    test('极端 1·历史回归:wushen 人造旧值 base maxHp 21800 + hpPct 0.20 → applySynergy cap 仍兜到 20000',
        () {
      // P0.1 #38 方案 D 重平衡(2026-05-17)后,wushen 真实 base 极值降到 16550
      // (详上文 tierBaseStats),日常路径不再触发 cap。本 case 用人造旧值 21800
      // (#38 重平衡前数值)模拟「未来若数值再次膨胀」或「装备强化/共鸣双乘后
      // 极值超 16667」场景,验证 cap 仍能作 second-line defense 兜底。
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 21800, // 人造极值,模拟 #38 前破红线 base
        maxIf: 15000,
        defRate: 0.35,
      );
      final result = StageBattleSetup.applySynergy(
        base,
        const SynergyMultipliers(hpPct: 0.20),
      );
      // 21800 × 1.20 = 26160,cap 后 20000
      expect(result.maxHp, 20000,
          reason: 'applySynergy maxHp cap 必须把 26160 截到 20000');
      expect(result.currentHp, 20000, reason: 'currentHp 跟 maxHp 同步 cap');
    });

    test('极端 1·新基线回归:wushen 真实极值 16550 + hpPct 0.20 → 19860 ≤ 20000 不触发 cap',
        () {
      // P0.1 #38 方案 D 收口锚点:wushen base 16550 自洽 ≤ 16667,
      // hpPct 0.20 加成后 19860 ≤ 20000 红线,validates spec §6
      // 「日常路径不再 trigger cap」(applySynergy cap 仅作 second-line defense)。
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 16550, // P0.1 #38 后 wushen 真实极值
        maxIf: 15000,
        defRate: 0.35,
      );
      final result = StageBattleSetup.applySynergy(
        base,
        const SynergyMultipliers(hpPct: 0.20),
      );
      // 16550 × 1.20 = 19860,< 20000 → 不触发 cap
      expect(result.maxHp, 19860,
          reason: 'P0.1 #38 后 wushen 极值 + hpPct 0.20 自然落在红线内,无须 cap');
      expect(result.maxHp, lessThan(20000),
          reason: 'spec §6:日常路径 base × hpPct ≤ 20000,不依赖 cap 兜底');
    });

    test('极端 2:wushen base maxIf 15000 + maxPct 0.25 → cap 15000',
        () {
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 18000,
        maxIf: 15000,
        defRate: 0.35,
      );
      final result = StageBattleSetup.applySynergy(
        base,
        const SynergyMultipliers(internalForceMaxPct: 0.25),
      );
      // 15000 × 1.25 = 18750,cap 后 15000
      expect(result.maxInternalForce, 15000,
          reason: 'applySynergy maxIf cap 必须把 18750 截到 15000');
    });

    test('极端 3:wushen base defRate 0.35 + 假想 synergy defensePct 0.80 → clamp 0.95',
        () {
      // 假想 synergy:future 数值膨胀情况下(本批 yaml 上限 0.10),clamp 兜底
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 18000,
        maxIf: 15000,
        defRate: 0.35,
      );
      final result = StageBattleSetup.applySynergy(
        base,
        const SynergyMultipliers(defensePct: 0.80),
      );
      // 0.35 + 0.80 = 1.15,clamp 后 0.95
      expect(result.defenseRate, 0.95,
          reason: 'applySynergy defenseRate clamp 必须把 1.15 截到 0.95');
    });

    test('极端 4:多字段同时撞 cap(maxHp + maxIf + defenseRate 三路 cap 同时生效)',
        () {
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 19500,
        maxIf: 14000,
        defRate: 0.50,
      );
      // 阴阳调和(hpPct=0.20 + defensePct=0.10)+ 假想强 maxPct + defensePct 极值
      final result = StageBattleSetup.applySynergy(
        base,
        const SynergyMultipliers(
          hpPct: 0.20,
          defensePct: 0.50,
          internalForceMaxPct: 0.20,
        ),
      );
      // maxHp:19500 × 1.20 = 23400 → cap 20000
      // maxIf:14000 × 1.20 = 16800 → cap 15000
      // defRate:0.50 + 0.50 = 1.00 → clamp 0.95
      expect(result.maxHp, 20000);
      expect(result.maxInternalForce, 15000);
      expect(result.defenseRate, 0.95);
    });

    // ── nightshift T01:+3 组合(5→8)红线 case ─────────────────────────
    // 对应 data/synergies.yaml 新增 6/7/8 组合,deterministic 直接构造
    // SynergyMultipliers(沿用本 test fixture 模式,不读 yaml),验证:
    //   ① multipliers 各维 ≤ 0.30 (SynergyMultipliers.isWithinRedLine getter)
    //   ② wushen base + new synergy → applySynergy 不破 §5.4 红线
    test('hot-loop C1:synergy_gang_yin_hu_zhi (def 0.15 + hp 0.15) 各维 ≤ 0.30 + 实战 ≤ §5.4 红线',
        () {
      const m = SynergyMultipliers(defensePct: 0.15, hpPct: 0.15);
      expect(m.defensePct, 0.15);
      expect(m.hpPct, 0.15);
      expect(m.isWithinRedLine, isTrue,
          reason: '6. 刚阴互制 各 multiplier ≤ 0.30');
      // wushen base defRate 0.35 + synergy 0.15 = 0.50 ≤ §5.5 红线 0.65
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 16550,
        maxIf: 15000,
        defRate: 0.35,
      );
      final result = StageBattleSetup.applySynergy(base, m);
      expectRedLines(result, label: 'wushen × 刚阴互制');
      expect(result.defenseRate, lessThanOrEqualTo(0.65),
          reason: '0.35 + 0.15 = 0.50 ≤ §5.5 防御率红线 0.65');
    });

    test('hot-loop C2:synergy_ling_gang_hui_liu (atk 0.10 + spd 0.20) 各维 ≤ 0.30 + 实战 ≤ §5.4 红线',
        () {
      const m = SynergyMultipliers(attackPct: 0.10, speedPct: 0.20);
      expect(m.attackPct, 0.10);
      expect(m.speedPct, 0.20);
      expect(m.isWithinRedLine, isTrue,
          reason: '7. 灵刚汇流 各 multiplier ≤ 0.30');
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 16550,
        maxIf: 15000,
        defRate: 0.35,
        school: TechniqueSchool.lingQiao,
      );
      final result = StageBattleSetup.applySynergy(base, m);
      expectRedLines(result, label: 'wushen × 灵刚汇流');
    });

    test('hot-loop C3:synergy_ling_yin_gui_yi (spd 0.10 + ifMax 0.20) 各维 ≤ 0.30 + 实战 ≤ §5.4 红线',
        () {
      const m = SynergyMultipliers(speedPct: 0.10, internalForceMaxPct: 0.20);
      expect(m.speedPct, 0.10);
      expect(m.internalForceMaxPct, 0.20);
      expect(m.isWithinRedLine, isTrue,
          reason: '8. 灵阴归一 各 multiplier ≤ 0.30');
      // wushen base maxIf 12500 × (1 + 0.20) = 15000 = §5.4 内力红线(=,不破)
      final base = buildBase(
        tier: RealmTier.wuSheng,
        maxHp: 16550,
        maxIf: 12500,
        defRate: 0.35,
        school: TechniqueSchool.lingQiao,
      );
      final result = StageBattleSetup.applySynergy(base, m);
      expectRedLines(result, label: 'wushen × 灵阴归一');
      expect(result.maxInternalForce, lessThanOrEqualTo(15000),
          reason: '12500 × 1.20 = 15000 = §5.4 内力红线');
    });
  });
}
