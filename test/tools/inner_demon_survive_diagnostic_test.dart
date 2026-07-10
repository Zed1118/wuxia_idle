// ignore_for_file: avoid_print
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import '../support/test_data.dart';

/// 终局机制型 Boss 批次3 · Task 5（修订）：心魔·真（stage_inner_demon_07）
/// 「脆弱窗口 + survive 双通道」诊断 + N 重校准。
///
/// ── 修订背景 ─────────────────────────────────────────────────────────────
/// 初版把 07 配成**纯高 buff 镜像 + survive**，并如实发现：无脆弱窗口时先手
/// 结构优势（镜像 speed==玩家 + `_actorOrder` teamSide asc 让左队每轮先手）
/// 使玩家恒胜、survive 形同虚设、N 只能下调到 15 且在自然斩杀前才勉强触发。
///
/// spec owner 据此决策：**给 07 也加脆弱窗口（同 05/06 机制）**，让窗口 gate
/// 玩家爆发 → 击杀镜像变难 → survive 撑关成为真实「熬过去」通道，且
/// 高爆发 build 会像 05/06 一样被翻盘（真实败率）。07 由此成为「窗口 + survive」
/// 双重叠加的终关（最难）。
///
/// ── 数据驱动实测（本文件实跑，非拍脑袋）────────────────────────────────────
/// 加窗口后（Task4 的注入是数据驱动：把 07 写进 numbers.yaml
/// `mirror_vulnerability_per_stage` 即自动给 07 镜像注入 vulnerabilityMult +
/// 蓄力技，无需改注入代码），07 窗口外承伤 = 0.14：
///
///   1. **窗口真开 (a)**：镜像 AI 每 seed 都可靠选中蓄力技进蓄力态
///      （chargingSkill != null），窗口在 07 上是活的。
///   2. **击败通道 (c)**：在位满配 on-level（门派绝学 25% 强化）在窗口内爆发
///      斩杀镜像，全 seed tick≤11 团灭右队取胜（tick<N=20，defeat 通道稳定可达）。
///   3. **survive 通道 (b)**：龟缩/耐战 build（门派绝学 + 寻常货装 + 体质 40）
///      伤害被窗口 gate 到打不穿 +25% 镜像，但自身足够
///      硬扛过 20 tick → 全 seed 在 tick=20 撑满存活、右队**尚未团灭**取胜
///      （真正 survive 边界触发，非巧合式「刚好在 20 团灭」的 defeat 重复计数）。
///   4. **真实难度 (d)**：高爆发 BiS（传说神功 60% 强化，一击可秒 20k HP）在
///      窗口下窗口外免疫 + 镜像反打 → glass cannon 被翻盘，死于 tick<20
///      （survive 无法救活已团灭的队伍）。这证明
///      窗口 + survive 门在 07 上**不是**初版「恒胜 no-op」，而是真实淘汰机制。
///
/// 结论：加窗口后 07 的 survive 从「仪式性」升级为真实第二通道；(a)-(e) 全部
/// 以真 crit/evasion 分布 + 确定性 seed 成立。**不再**归零 crit/evasion（初版
/// 归零是为在纯镜像下做确定性架构验证，但也抹掉了窗口带来的真实败率）——
/// 本修订保留真实 agility 派生的 crit/evasion（同 Task4 vulnerability 诊断），
/// 每 seed 经 Random(seed) 确定性，断言锚在固定 seed 集上的聚合胜负数。
///
/// 最终校准值：07 outOfWindowDamageMult = 0.14，winCondition.ticks (N) = 20。
/// 实测：蓄力率 20/20；survive 通道 20/20（turtle）；defeat 通道 20/20（on-level）；
/// BiS 高爆发败率 10/20（=50%）。

const int _n = 20; // = data/stages.yaml stage_inner_demon_07.winCondition.ticks
const int _maxTicks = 400;
const int _seeds = 20; // seeds 0..19，同 Task4 vulnerability 诊断

BattleCharacter _buildPlayer(
  GameRepository repo,
  String techId, {
  required int slot,
  required bool isFounder,
  required int enhancePct,
  required int constitution,
  EquipmentTier? equipTier,
}) {
  const tier = RealmTier.wuSheng;
  const layer =
      RealmLayer.dengFeng; // stage_inner_demon_07 required_realm_layer 锚点
  const school = TechniqueSchool.gangMeng;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = (realmDef.absoluteLevel * enhancePct / 100).round();

  // 默认走该 tier 装备上限；显式传入更低 [equipTier] 模拟「刚够
  // required_realm_layer 门槛但装备远未跟上」的欠配/龟缩耐战玩家。
  final eqTierCap = equipTier ?? RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final wantSlot in [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final defs = repo.equipmentDefs.values;
    final EquipmentDef def = defs.firstWhere(
      (d) => d.tier == eqTierCap && d.slot == wantSlot,
      orElse: () => defs.firstWhere((d) => d.slot == wantSlot),
    );
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 7, 1),
        obtainedFrom: 'inner_demon_survive_diag',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: 400,
        forgingSlots: const [],
      ),
    );
  }

  final TechniqueDef techDef = repo.techniqueDefs[techId]!;
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 7, 1),
    cultivationLayer: CultivationLayer.daCheng,
  );

  final attributes = Attributes()
    ..constitution = constitution
    ..agility = 6
    ..enlightenment = 5
    ..fortune = 5;
  final character = Character.create(
    name: '玩家$slot',
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 7, 1),
    internalForce: realmDef.internalForceMax,
    internalForceMax: realmDef.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = 999 + slot;

  // 保留真实 agility=6 + 宗主 buff 派生的 crit/evasion（不归零）——这正是
  // 窗口带来真实败率的来源，同 Task4 vulnerability 诊断（初版归零抹掉了它）。
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTech,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: true,
  );
}

List<BattleCharacter> _team(
  GameRepository repo,
  String techId,
  int enhancePct,
  int constitution, {
  EquipmentTier? equipTier,
}) => [
  for (var slot = 0; slot < 3; slot++)
    _buildPlayer(
      repo,
      techId,
      slot: slot,
      isFounder: slot == 0,
      enhancePct: enhancePct,
      constitution: constitution,
      equipTier: equipTier,
    ),
];

/// 单场确定性战斗结果。
typedef _Outcome = ({
  BattleResult? result,
  int tick,
  bool rightAllDead,
  bool leftAlive,
  bool everCharged,
});

/// 单场确定性战斗（07 走真镜像注入路径 → 窗口注入）。
_Outcome _run(
  List<BattleCharacter> players,
  List<BattleCharacter> mirrors,
  GameRepository repo,
  StageWinCondition winCondition,
  int seed,
) {
  var s = BattleState.initial(
    leftTeam: players,
    rightTeam: mirrors,
    winCondition: winCondition,
  );
  final rng = Random(seed);
  var i = 0;
  var everCharged = false;
  while (!s.isFinished && i < _maxTicks) {
    s = BattleEngine.tick(s, repo.numbers, rng: rng);
    if (!everCharged) {
      for (final e in s.rightTeam) {
        if (e.chargingSkill != null) {
          everCharged = true;
          break;
        }
      }
    }
    i++;
  }
  return (
    result: s.result,
    tick: s.tick,
    rightAllDead: s.rightTeam.every((c) => !c.isAlive),
    leftAlive: s.leftTeam.any((c) => c.isAlive),
    everCharged: everCharged,
  );
}

/// 对某 profile 跑全 seed（07 真镜像注入 + 窗口 + survive winCondition）。
List<_Outcome> _sweep(
  GameRepository repo,
  List<BattleCharacter> players,
  StageWinCondition winCondition,
) {
  final def = repo.numbers.innerDemon;
  final charge = repo.getSkill('skill_inner_demon_charge');
  final out = <_Outcome>[];
  for (var seed = 0; seed < _seeds; seed++) {
    final mirrors = InnerDemonService.buildMirrorEnemyTeam(
      playerTeam: players,
      stageId: 'stage_inner_demon_07',
      innerDemonDef: def,
      mirrorChargeSkill: charge,
    );
    out.add(_run(players, mirrors, repo, winCondition, seed));
  }
  return out;
}

void main() {
  late GameRepository repo;
  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('(0) 前置：07 winCondition surviveTicks=N + 生产路径镜像有脆弱窗口', () {
    final stage = repo.getStage('stage_inner_demon_07');
    expect(
      stage.winCondition,
      isNotNull,
      reason: '07 应配 surviveTicks winCondition',
    );
    expect(stage.winCondition!.type, StageWinConditionType.surviveTicks);
    expect(
      stage.winCondition!.surviveTicksRequired,
      _n,
      reason: '07 survive N 应 = $_n（校准值）',
    );

    // 07 现有脆弱窗口条目（修订：与 05/06 同机制，不再分叉）。
    final id = repo.numbers.innerDemon;
    final vuln = id.mirrorVulnerabilityPerStage['stage_inner_demon_07'];
    expect(vuln, isNotNull, reason: '07 应配 mirror_vulnerability_per_stage 条目');
    expect(
      vuln!.outOfWindowDamageMult,
      0.14,
      reason: '07 窗口外承伤应 = 0.14（保留高爆发攻略空间）',
    );
    expect(
      id.mirrorBuffPerStage['stage_inner_demon_07'],
      0.25,
      reason: '07 镜像 +25% buff 保留压迫但避免 BiS 硬墙',
    );
    expect(id.mirrorChargeSkillId, 'skill_inner_demon_charge');

    // 生产路径（buildMirrorEnemyTeam + 解析蓄力技）真的把窗口注到 07 镜像上。
    final players = _team(repo, 'tech_gangmeng_menpai', 25, 6);
    final mirrors = InnerDemonService.buildMirrorEnemyTeam(
      playerTeam: players,
      stageId: 'stage_inner_demon_07',
      innerDemonDef: id,
      mirrorChargeSkill: repo.getSkill('skill_inner_demon_charge'),
    );
    expect(
      mirrors.first.vulnerabilityMult,
      0.14,
      reason: '07 镜像应注入 vulnerabilityMult=0.14（窗口活）',
    );
    expect(mirrors.first.chargeSkillId, 'skill_inner_demon_charge');
    expect(
      mirrors.first.availableSkills.any(
        (s) => s.id == 'skill_inner_demon_charge',
      ),
      isTrue,
      reason: '蓄力技应进 availableSkills（AI 才选得到 → 开窗）',
    );
  });

  test(
    '(a)(c)(e) 击败通道 + 窗口真开 + 不变式：on-level 全 seed 窗口内斩杀取胜',
    () {
      final wc = repo.getStage('stage_inner_demon_07').winCondition!;
      // 在位满配 on-level：门派绝学 + 25% 强化（非传说 BiS）。
      final onLevel = _team(repo, 'tech_gangmeng_menpai', 25, 6);
      final outcomes = _sweep(repo, onLevel, wc);

      final charged = outcomes.where((o) => o.everCharged).length;
      final earlyKills = outcomes
          .where(
            (o) =>
                o.result == BattleResult.leftWin &&
                o.tick < _n &&
                o.rightAllDead,
          )
          .length;
      print(
        'on-level: charged=$charged/$_seeds earlyKills=$earlyKills/$_seeds '
        'ticks=${outcomes.map((o) => o.tick).toList()}',
      );

      // (a) 窗口真开：镜像每 seed 都至少蓄力一次（否则窗口永不开 = 永久免疫 no-op）。
      expect(charged, _seeds, reason: '07 镜像应每 seed 都蓄力开窗；实测 $charged/$_seeds');

      // (c) 击败通道：on-level 应全 seed 在 tick<N 团灭右队取胜（窗口内爆发斩杀）。
      expect(
        earlyKills,
        _seeds,
        reason:
            'on-level 应全 seed 提前斩杀镜像取胜（击败通道确定性可达）；'
            '实测 ${outcomes.map((o) => (o.result?.name, o.tick, o.rightAllDead)).toList()}',
      );

      // (e) 不变式：leftWin ⟹ (tick>=N || rightAllDead)。
      for (final o in outcomes) {
        if (o.result == BattleResult.leftWin) {
          expect(
            o.tick >= _n || o.rightAllDead,
            isTrue,
            reason: 'leftWin 却既未撑满 N=$_n 也未团灭右队（tick=${o.tick}）',
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    '(b)(e) survive 通道：龟缩耐战 build 全 seed 撑满 N 存活、右队未团灭取胜',
    () {
      final wc = repo.getStage('stage_inner_demon_07').winCondition!;
      // 龟缩/耐战：门派绝学 + 寻常货装（最低阶）+ 0 强化 + 体质 40。伤害被窗口
      // gate 到打不穿 +25% 镜像，但自身硬扛过 N=20。
      final turtle = _team(
        repo,
        'tech_gangmeng_menpai',
        0,
        40,
        equipTier: EquipmentTier.xunChang,
      );
      final outcomes = _sweep(repo, turtle, wc);

      final surviveWins = outcomes
          .where(
            (o) =>
                o.result == BattleResult.leftWin &&
                o.tick >= _n &&
                o.leftAlive &&
                !o.rightAllDead,
          )
          .length;
      print(
        'turtle: surviveWins=$surviveWins/$_seeds '
        'ticks=${outcomes.map((o) => o.tick).toList()} '
        'results=${outcomes.map((o) => o.result?.name).toList()}',
      );

      // (b) survive 通道：全 seed 在 tick>=N 撑满、存活、且右队**尚未团灭**取胜
      // ——证明 survive 边界确实抢在 defeat 之前触发（真正第二胜利通道，非
      // 巧合式「刚好在 N tick 团灭」的 defeat 重复计数）。
      expect(
        surviveWins,
        _seeds,
        reason:
            '龟缩耐战 build 应全 seed 撑满 N=$_n、存活、右队未团灭（survive 通道）；'
            '实测 ${outcomes.map((o) => (o.result?.name, o.tick, o.rightAllDead, o.leftAlive)).toList()}',
      );

      // (e) 不变式。
      for (final o in outcomes) {
        if (o.result == BattleResult.leftWin) {
          expect(o.tick >= _n || o.rightAllDead, isTrue);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    '(d)(e) 真实难度：高爆发 BiS 在窗口 + survive 下仍有非平凡战败率',
    () {
      final wc = repo.getStage('stage_inner_demon_07').winCondition!;
      // 高爆发 BiS：传说神功 60% 强化（一击可秒 20k HP 镜像）。窗口下窗口外免疫
      // + 镜像反打 → glass cannon 被翻盘，死于 tick<N（survive 救不活已
      // 团灭的队伍）。证明窗口 + survive 门**不是**初版「恒胜 no-op」。
      final bis = _team(repo, 'tech_gangmeng_chuanshuo', 60, 6);
      final outcomes = _sweep(repo, bis, wc);

      final wins = outcomes
          .where((o) => o.result == BattleResult.leftWin)
          .length;
      final losses = outcomes
          .where((o) => o.result == BattleResult.rightWin && !o.leftAlive)
          .length;
      print(
        'BiS: wins=$wins/$_seeds losses=$losses '
        'ticks=${outcomes.map((o) => o.tick).toList()} '
        'results=${outcomes.map((o) => o.result?.name).toList()}',
      );

      // (d) 非全胜（窗口对纯爆发 build 制造真难度，alpha-strike 无法碾过）。
      expect(
        wins,
        lessThan(_seeds),
        reason:
            'BiS 高爆发应有非平凡战败（窗口 + survive 门存在，非初版恒胜 no-op）；'
            '实胜 $wins/$_seeds',
      );
      // 但也非硬墙（BiS 仍可攻略，主要靠击败通道）。
      expect(
        wins,
        greaterThanOrEqualTo(10),
        reason: 'BiS 软门槛非硬墙（仍大体可攻略）；实胜 $wins/$_seeds',
      );
      // 战败确由「队伍团灭于 tick<N，survive 未触发」构成（机制正确性）。
      expect(
        losses,
        greaterThan(0),
        reason: '战败应由 tick<N 团灭构成（survive 无法救活已死队伍）；实败 $losses',
      );

      // (e) 不变式。
      for (final o in outcomes) {
        if (o.result == BattleResult.leftWin) {
          expect(o.tick >= _n || o.rightAllDead, isTrue);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
