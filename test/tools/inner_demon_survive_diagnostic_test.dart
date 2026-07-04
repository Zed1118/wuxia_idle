// ignore_for_file: avoid_print
import 'dart:io';
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
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart' show RealmUtils;
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';

/// 终局机制型 Boss 批次3 · Task 5：心魔·真（stage_inner_demon_07）survive
/// 限时生存 winCondition 双通道诊断 + N 校准。
///
/// 07 是纯 +40% 镜像（无脆弱窗口——那是 05/06 专属，Task4 已锚）。
///
/// ── 诊断驱动的关键实测结论（非拍脑袋，全部来自本文件实跑）──────────────
///
/// 1. **架构性发现：crit/evasion 归零后，纯镜像对左（玩家）队恒胜，与 build
///    强度无关**。原因链：
///      - [InnerDemonService._mirror] 只缩放 maxHp/maxInternalForce/
///        totalEquipmentAttack，**不缩放 speed**——镜像 speed 与玩家原样一致。
///      - [DefaultGroundStrategy._actorOrder] 破平局顺序是
///        `actionPoint desc → speed desc → teamSide asc → slotIndex asc`。
///      - 玩家 3 人与镜像 3 人 speed 两两相等 → 每次 AP 触顶都是全员 6 人
///        整批同时入队 → teamSide asc 平手规则让**左队全员必定排在右队全员
///        之前** → 玩家每轮都能对镜像打出「3 连击不还手」，且这个先手优势
///        每轮复利。实测跨越 attack 186→7276（39× 量级）、maxHp 11728→20000
///        （§5.4 玩家血红线 clamp）等极端配置，10/10 seed 100% leftWin，
///        0 例外（本文件 test 2 直接断言这一发现）。
///    → **(c) 「脆皮应有真实败率」在 crit/evasion=0 的确定性方法论下不可达**
///      ——这不是本诊断遗漏，是可复现的架构事实，已按 escalation 指引
///      在任务报告里如实上报（非静默弱化 assertion）。
///
/// 2. **N=40（spec 起点）在此机制下形同虚设**：即使故意堆到远超真实装备建议
///    的「乌龟流」build（xunChang 最低阶装备 + 极端加点体质），纯镜像下自然
///    TTK 上限也只有 ~23 tick（HP 撞 §5.4 血红线 clamp 后无法再拖长）——
///    battle 恒在 tick<30 内通过 defeat 通道结束，40 永远不会真正触发。
///    **已下调 N=15**（stages.yaml 同步改），使其：
///      - 明显低于「超模」build 的自然了结 tick（~4），击败通道稳定可达；
///      - 明显低于「on-level」build 的自然了结 tick（~18），使 survive
///        通道能在战斗真正打完之前被 15-tick 边界抢先触发（tick=15 时
///        leftAlive 且 rightTeam 未团灭——非巧合式「刚好在 15 团灭」）。
///
/// 3. crit/evasion 非零（真实 agility 分布）时会引入一个与 build 强度**无关**
///    的均匀 ~10% 战败噪声（早期未归零 crit/evasion 时 3 档 build 全部
///    9/10，无差异）——同样不是「脆皮更容易败」，是 RNG 噪声地板，已弃用
///    该方案（会制造「脆皮有败率」的假象，掩盖真实架构发现）。
///
/// 结论：本诊断如实验证 (a) 击败通道 + (b) 生存通道 + (d) 恒定式 全部成立，
/// N 已按实测下调到 15；(c) 按 escalation 指引不强行伪造，改为显式断言并
/// 记录发现 2 供 spec owner 决策（是否需要额外机制让镜像在 07 获得真实
/// 胜率，或接受「07 生存是节奏/仪式性关卡而非真实淘汰机制」的现状）。

const int _n = 15; // = data/stages.yaml stage_inner_demon_07.winCondition.ticks（实测下调，见文件头发现2）
const int _maxTicks = 400;
const List<int> _seeds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

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
  const layer = RealmLayer.dengFeng; // stage_inner_demon_07 required_realm_layer 锚点
  const school = TechniqueSchool.gangMeng;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = (realmDef.absoluteLevel * enhancePct / 100).round();

  // 默认走该 tier 装备上限；显式传入更低 [equipTier] 模拟「刚够
  // required_realm_layer 门槛但装备远未跟上」的欠配边缘玩家。
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
    equipped.add(Equipment.create(
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
    ));
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

  final built = BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTech,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: true,
  );
  // 确定性诊断：crit/evasion 归零（否则 agility=6 + founder buff 会派生非零
  // crit/evasion rate，引入与 build 强度无关的噪声，掩盖 build 差异本身
  // 及文件头「发现1」的架构性信号）。[InnerDemonService._mirror] 不改
  // criticalRate/evasionRate 字段，此处归零后镜像同步归零。
  return built.copyWith(criticalRate: 0.0, evasionRate: 0.0);
}

List<BattleCharacter> _team(
  GameRepository repo,
  String techId,
  int enhancePct,
  int constitution, {
  EquipmentTier? equipTier,
}) =>
    [
      for (var slot = 0; slot < 3; slot++)
        _buildPlayer(repo, techId,
            slot: slot,
            isFounder: slot == 0,
            enhancePct: enhancePct,
            constitution: constitution,
            equipTier: equipTier),
    ];

/// 单场确定性战斗。返回 (result, tick, rightAllDead, leftAnyAlive)。
(BattleResult?, int, bool, bool) _run(
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
  while (!s.isFinished && i < _maxTicks) {
    s = BattleEngine.tick(s, repo.numbers, rng: rng);
    i++;
  }
  final rightAllDead = s.rightTeam.every((c) => !c.isAlive);
  final leftAnyAlive = s.leftTeam.any((c) => c.isAlive);
  return (s.result, s.tick, rightAllDead, leftAnyAlive);
}

void main() {
  late GameRepository repo;
  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString());
  });

  test('前置：真 stages.yaml stage_inner_demon_07 winCondition 已配置', () {
    final stage = repo.getStage('stage_inner_demon_07');
    expect(stage.winCondition, isNotNull, reason: '07 应配 surviveTicks winCondition');
    expect(stage.winCondition!.type, StageWinConditionType.surviveTicks);
    expect(stage.winCondition!.surviveTicksRequired, _n);

    // 07 无脆弱窗口条目（与 05/06 分叉，Task4 已锚）。
    final id = repo.numbers.innerDemon;
    expect(id.mirrorVulnerabilityPerStage.containsKey('stage_inner_demon_07'), isFalse);
    expect(id.mirrorBuffPerStage['stage_inner_demon_07'], 0.40);
  });

  test('stage_inner_demon_07 survive 双通道诊断：击败(a) / 生存(b) / 恒定式(d)', () {
    final winCondition = repo.getStage('stage_inner_demon_07').winCondition!;
    final def = repo.numbers.innerDemon;

    // 「超模」：传说神功 + 60% 强化 → 高爆发提前斩杀镜像（击败通道 a）。
    final overpowered = _team(repo, 'tech_gangmeng_chuanshuo', 60, 6);
    // 「on-level」：门派绝学 + 中档强化/体质/装备 → 打不过但耗时够长，
    // N=15 边界会在其自然了结（~18 tick）之前抢先触发 survive-win（通道 b）。
    final onLevel = _team(repo, 'tech_gangmeng_menpai', 10, 30,
        equipTier: EquipmentTier.haoJiaHuo);

    final profiles = {
      'overpowered': overpowered,
      'onLevel': onLevel,
    };

    final outcomes = <String, List<(BattleResult?, int, bool, bool)>>{};
    for (final entry in profiles.entries) {
      final results = <(BattleResult?, int, bool, bool)>[];
      for (final seed in _seeds) {
        final mirrors = InnerDemonService.buildMirrorEnemyTeam(
          playerTeam: entry.value,
          stageId: 'stage_inner_demon_07',
          innerDemonDef: def,
        );
        results.add(_run(entry.value, mirrors, repo, winCondition, seed));
      }
      outcomes[entry.key] = results;
      final wins = results.where((r) => r.$1 == BattleResult.leftWin).length;
      final avgTick = results.map((r) => r.$2).reduce((a, b) => a + b) / results.length;
      print('${entry.key}: wins=$wins/${_seeds.length} avgTick=${avgTick.toStringAsFixed(1)} '
          'ticks=${results.map((r) => r.$2).toList()} '
          'results=${results.map((r) => r.$1?.name).toList()}');
    }

    // (d) KEY INVARIANT：对全部 profile × 全部 seed 恒成立。
    for (final entry in outcomes.entries) {
      for (final r in entry.value) {
        final (result, tick, rightAllDead, _) = r;
        if (result == BattleResult.leftWin) {
          expect(tick >= _n || rightAllDead, isTrue,
              reason: '${entry.key} leftWin 但既未撑满 N=$_n（tick=$tick）也未团灭右队');
        }
      }
    }

    // (a) 击败通道：超模应在 tick<N 前提前斩杀镜像取胜（全部 seed，确定性）。
    final opEarlyKills = outcomes['overpowered']!
        .where((r) => r.$1 == BattleResult.leftWin && r.$2 < _n && r.$3)
        .length;
    expect(opEarlyKills, _seeds.length,
        reason: '超模应全部 seed 提前斩杀镜像取胜（击败通道可达且确定性）；'
            '实测 ${outcomes['overpowered']}');

    // (b) 生存通道：on-level 应撑满 N tick、存活、且**尚未团灭右队**取胜
    // （区别于巧合式「刚好在 N tick 团灭」——证明 survive 边界确实抢在
    // defeat 之前触发，是真正的第二条胜利通道，非 defeat 的重复计数）。
    final onLevelSurvives = outcomes['onLevel']!
        .where((r) =>
            r.$1 == BattleResult.leftWin && r.$2 >= _n && r.$4 && !r.$3)
        .length;
    expect(onLevelSurvives, _seeds.length,
        reason: 'on-level 应全部 seed 撑满 N=$_n tick、存活、且右队尚未团灭'
            '（真正 survive 通道触发，非 defeat 重复计数）；'
            '实测 ${outcomes['onLevel']}');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('架构性发现：crit/evasion=0 时纯镜像(07)对左队恒胜，与 build 强度无关（不伪造 (c) 败率）', () {
    final winCondition = repo.getStage('stage_inner_demon_07').winCondition!;
    final def = repo.numbers.innerDemon;

    // 刻意构造「远低于真实装备建议」的欠配边缘玩家：最低阶装备 + 零强化 +
    // 最低体质——比 onLevel 弱一个数量级（atk ~186 vs onLevel ~1000+ 量级）。
    final underGeared = _team(repo, 'tech_gangmeng_menpai', 0, 1,
        equipTier: EquipmentTier.xunChang);

    final results = <(BattleResult?, int, bool, bool)>[];
    for (final seed in _seeds) {
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: underGeared,
        stageId: 'stage_inner_demon_07',
        innerDemonDef: def,
      );
      results.add(_run(underGeared, mirrors, repo, winCondition, seed));
    }
    final wins = results.where((r) => r.$1 == BattleResult.leftWin).length;
    print('underGeared(最弱边缘玩家): wins=$wins/${_seeds.length} '
        'ticks=${results.map((r) => r.$2).toList()} '
        'results=${results.map((r) => r.$1?.name).toList()}');

    // 如实断言实测行为：即便是刻意构造的最弱边缘玩家，纯镜像(07)下也是
    // 全 seed leftWin（0 例外）。这是 [InnerDemonService._mirror] 不缩放
    // speed + [DefaultGroundStrategy._actorOrder] teamSide asc 平手规则
    // 共同导致的架构性质（见文件头「发现1」），非本诊断遗漏——
    // 已按 escalation 指引在任务报告中如实上报，不在此处伪造 rightWin。
    expect(wins, _seeds.length,
        reason: '架构性发现：即使最弱边缘玩家，crit/evasion=0 下纯镜像(07)仍恒胜'
            '（0 败率，验证「(c) 脆皮应有真实败率」在当前 combat engine 下'
            '不可通过 build 强度差异达成）；实测 $results');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
