// ignore_for_file: avoid_print
//
// Ch6 通关后纯挂机 → Ch7 门槛（二流·启蒙 = 绝对境界层 15 = 显示级 Lv141）
// 墙钟时长模拟 · 只读分析工具（零生产改动）。
//
// 起点 = 「Ch1-6 + 塔 + 轻功 + 群战 + 心魔 + 72h 闭关 + 24h 离线 + 三枚经验丹」
// 全内容参考路线实测终态（与
// test/features/cultivation/application/progression_release_budget_test.dart
// 同口径复现 → Lv91 / 绝对层 10 / 层内余量 15 EXP）。
// 终点 = stages.yaml stage_07_01 requiredRealm erLiu（二流 = 绝对层 15 = Lv141）。
//
// 所有速率走真实生产配置路径（"接线"= 读 production yaml + 调生产纯函数）：
//   - SeclusionService.computeOutputs（numbers.yaml retreat.maps / cap_hours /
//     realm_scale_per_tier；72h cap 后 computeSettlement 转 passive_idle）
//   - OfflinePassiveService.compute（numbers.yaml passive_idle，无 cap）
//   - 经验丹 = 当前层 ETL × items.yaml layer_fraction（ItemUseService 同公式）
//   - 商店购丹 = shop.yaml price_layer_fraction 动态标价（buyRatio 恒定 6 银/EXP）
//   - 桃花岛丹房酿凝神丹 = numbers.yaml taohua_island（rate×level，72h cap）
//   - 百草岭远征 = 复用 test/support/joint_economy_model.dart（联合经济探针口径，
//     expeditions.yaml base_exp_per_battle）
//
// 跑法：flutter test test/tools/progression_idle_horizon_simulation_test.dart
// 输出仅 print（数字人工转录进 plan，不落 CSV —— test/tools/output 误提交历史坑）。

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/application/progression_gate_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart'
    show ExpeditionPolicy;
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../support/joint_economy_model.dart';
import '../support/test_data.dart';

/// 显示级里程碑（Lv100 = abs10 90%、Lv120 = abs12 90%、Lv141 = abs15 到达）。
const _milestones = [100, 120, 141];

/// 目标显示级（Ch7 门槛 = 二流·启蒙）。
const _targetLevel = 141;

/// 模拟上限（防死循环安全网）：3 年墙钟。
const _maxHours = 24 * 365 * 3;

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('锚点对账：参考路线终态 Lv106/abs11/余量715，缺口 6635 EXP', () {
    final ch = _referenceRouteEnd(repo);
    expect(
      _displayLevel(repo, ch),
      109,
      reason: '对账 progression_release_budget_test Lv109 锚点',
    );
    final realm = repo.getRealm(ch.realmTier, ch.realmLayer);
    expect(realm.absoluteLevel, 11, reason: 'Lv109 = 三流·圆熟(abs11) 层内段');
    expect(ch.experience, 1079, reason: '参考路线三丹后层内余量');
    expect(_expToDisplayLevel(repo, ch, 100), 0);
    expect(_expToDisplayLevel(repo, ch, 120), 1611);
    expect(
      _expToDisplayLevel(repo, ch, _targetLevel),
      6271,
      reason: 'Lv109→Lv141 纯挂机经验缺口',
    );
  });

  test('配置锚点：挂机产出链路真实取值（漂移即红）', () {
    final retreat = repo.numbers.retreat;
    final passive = repo.numbers.passiveIdle;
    expect(retreat.capHours, 72, reason: '72h cap 后转 passive_idle 溢出');
    expect(retreat.realmScaleFor(RealmTier.sanLiu), closeTo(1.3, 1e-9));
    expect(
      retreat.experienceRealmScaleFor(RealmTier.sanLiu),
      closeTo(1.65, 1e-9),
    );
    expect(passive.baseExpPerHour, 3.0);
    expect(passive.realmScaleFor(RealmTier.sanLiu), closeTo(1.6, 1e-9));

    // 三流可达最优经验图：藏经阁/山林并列 3.0 EXP/h；175/h 的悬崖瀑布要二流——
    // 恰好是要挂到的目标境界，中段不可用（关键结构性事实）。
    final enterable = repo.seclusionMaps
        .where(
          (m) => SeclusionService.canEnterMap(
            mapType: m.mapType,
            charRealmTier: RealmTier.sanLiu,
            maps: repo.seclusionMaps,
          ),
        )
        .toList();
    final bestRate = enterable
        .map((m) => m.experiencePerHour)
        .fold<double>(0, (a, b) => a > b ? a : b);
    expect(bestRate, 3.0, reason: '三流可达地图最高经验产出');
    final puBu = repo.seclusionMaps.firstWhere(
      (m) => m.mapType == RetreatMapType.xuanYaPuBu,
    );
    expect(puBu.experiencePerHour, 175.0);
    expect(puBu.requiredRealm, RealmTier.erLiu, reason: '瀑布图要二流——缺口段内不可用');

    // 与 budget 测试同源锚点：三流 72h 藏经阁 = 356 EXP；24h 离线 = 115 EXP。
    final ch = _newSanLiuCharacter(repo);
    expect(_retreatExp(repo, ch, RetreatMapType.cangJingGe, 72), 356);
    expect(_passiveExp(repo, ch.realmTier, 24), 115);

    // 关卡门槛与发布上限：目标可达。
    expect(
      repo.stageDefs['stage_07_01']!.requiredRealm,
      RealmTier.erLiu,
      reason: 'Ch7 首关推荐境界 = 二流 = Lv141',
    );
    expect(
      repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel,
      greaterThanOrEqualTo(15),
      reason: '发布上限 17 ≥ 目标 abs15，缺口段不被 cap 拦',
    );

    // 经验丹与购丹汇率（buyRatio = 0.6/0.1 = 6 银/EXP 恒定）。
    expect(repo.itemDefs['item_jingyandan_small']!.layerFraction, 0.1);
    expect(repo.shopItemDefs['shop_jingyandan_small']!.priceLayerFraction, 0.6);

    // 桃花岛丹房酿凝神丹：药草园同级供给恰好覆盖消耗（6/h vs 6×1/h×级）；
    // 丹房升级境界 gate [0,1,2,3] → 三流最高 L3。
    final island = repo.numbers.taohuaIsland;
    final danFang = island.buildingOf(BuildingType.danFang);
    final brew = danFang.recipeById('brew_ningshen')!;
    expect(brew.outputItem, 'item_jingyandan_small');
    expect(brew.ratePerHour, 1.0);
    expect(brew.inputPerOutput, 6.0);
    final herb = island.buildingOf(BuildingType.caoYaoYuan);
    expect(
      herb.baseRatePerHour,
      greaterThanOrEqualTo(brew.inputPerOutput * brew.ratePerHour),
      reason: '药草园同级自供给成立（凝神丹产线不断料）',
    );
    var maxLevelAtSanLiu = 1;
    for (var lv = 1; lv < danFang.maxLevel; lv++) {
      if (danFang.upgradeRealmFor(lv) <= RealmTier.sanLiu.index) {
        maxLevelAtSanLiu = lv + 1;
      }
    }
    expect(maxLevelAtSanLiu, 3, reason: '三流丹房上限 L3（L3→4 需二流）');

    // 江湖远行（百草岭远征）解锁里程碑 = abs10，起点恰已满足。
    expect(
      repo
              .getRealm(
                _referenceRouteEnd(repo).realmTier,
                _referenceRouteEnd(repo).realmLayer,
              )
              .absoluteLevel >=
          10,
      isTrue,
      reason: '起点 abs10 ≥ 江湖远行解锁线 abs10',
    );
  });

  test('三场景：最优闭关连续挂 / 普通离线挂 / 混合典型', () {
    final s1 = _runCycleDriven(
      repo,
      name: 'A 最优闭关连续挂（藏经阁72h循环收功）',
      cycleHours: 72,
      cycleExp: (tier, h) =>
          _retreatExpAtHour(repo, tier, RetreatMapType.cangJingGe, h),
    );
    final s2 = _runCycleDriven(
      repo,
      name: 'B 普通离线挂（passive_idle 每日结算）',
      cycleHours: 24,
      cycleExp: (tier, h) => _passiveExp(repo, tier, h),
    );
    final s3 = _runCycleDriven(
      repo,
      name: 'C 混合典型（闭关常开·每7天收一次）',
      cycleHours: 168,
      cycleExp: (tier, h) =>
          _retreatExpAtHour(
            repo,
            tier,
            RetreatMapType.cangJingGe,
            h < 72 ? h : 72,
          ) +
          (h > 72 ? _passiveExp(repo, tier, h - 72) : 0),
    );

    for (final s in [s1, s2, s3]) {
      _printResult(s);
      _assertMonotonic(s);
      _assertConservation(repo, s);
    }
    // 关键发现：三流段 passive(4.8/h) > 最优闭关图(3.9/h) → 纯离线反快于挂闭关。
    expect(
      s1.totalHours,
      lessThan(s2.totalHours),
      reason: '1A 修复后最优闭关图快于纯离线(2026-07-19)',
    );
    expect(s1.totalHours, lessThan(s3.totalHours));
    expect(s3.totalHours, lessThan(s2.totalHours));
    // Ch14 缺口 6635→6271 后 s1 实测 52.9 天,下沿 55→50 同步重校(节奏带随内容扩张单调收窄·2026-07-23)。
    expect(s1.days, inInclusiveRange(50.0, 120.0));
    expect(s2.days, inInclusiveRange(45.0, 100.0));
    expect(s3.days, inInclusiveRange(50.0, 110.0));
  });

  test('加速通道：百草岭远征 / 桃花岛丹房 / 闭关+银两购丹', () {
    // D 专挂百草岭远征（联合经济探针同口径：一站到底方针·代表深度20·24h满挂）。
    final baseExp = repo.expeditionConfig!.baseExpPerBattle;
    final y = baicaoHourlyYield(
      policy: ExpeditionPolicy.yiZhanLiXing,
      avgDepth: 20,
      baseExpPerBattle: baseExp,
    );
    final gap = 6271; // 锚点测已钉（2026-07-23 Ch14 扩后重校·全内容终态 Lv106→109·缺口 -364）
    final s4Days = daysToTraverse(totalExp: gap, expPerHour: y.expPerHour);
    // 交叉对账：同口径 abs10→17 应 ≈ 18 天（expeditions.yaml 注释锚点）。
    final fullRangeDays = daysToTraverse(
      totalExp: expToTraverseAbsLevels(
        realmByAbs: repo.getRealmByAbsoluteLevel,
        fromAbs: 10,
        toAbs: 17,
      ),
      expPerHour: y.expPerHour,
    );
    expect(
      fullRangeDays,
      inInclusiveRange(14.0, 24.0),
      reason: '对账 yaml 注释「Lv100→170 ~18天专挂」',
    );
    print(
      'D 专挂百草岭远征: ${y.expPerHour.toStringAsFixed(2)} EXP/h → '
      'Lv141 ${(gap / y.expPerHour).toStringAsFixed(0)}h = ${s4Days.toStringAsFixed(1)} 天'
      '（对账 abs10→17 = ${fullRangeDays.toStringAsFixed(1)} 天）',
    );

    // E 桃花岛丹房酿凝神丹（药草园同级自供给；丹即产即用）。
    final e1 = _runIslandPills(repo, name: 'E1 丹房L1 酿凝神丹', danFangLevel: 1);
    final e3 = _runIslandPills(
      repo,
      name: 'E3 丹房L3 酿凝神丹（三流上限）',
      danFangLevel: 3,
    );
    for (final s in [e1, e3]) {
      _printResult(s);
      _assertMonotonic(s);
      _assertConservation(repo, s);
    }

    // F 闭关 + 银两全购小丹（藏经阁72h循环，银两即时换丹）。
    final f = _runCycleDriven(
      repo,
      name: 'F 闭关+银两购丹（藏经阁72h循环）',
      cycleHours: 72,
      cycleExp: (tier, h) =>
          _retreatExpAtHour(repo, tier, RetreatMapType.cangJingGe, h),
      cycleSilver: (tier, h) =>
          _retreatSilverAtHour(repo, tier, RetreatMapType.cangJingGe, h),
      shopPills: true,
    );
    _printResult(f);
    _assertMonotonic(f);
    _assertConservation(repo, f);

    // 全链路排序（常驻冒烟）：丹房 < 远征 < 购丹混合 < 离线 < 7天收 < 闭关循环。
    expect(e1.totalHours, lessThan((gap / y.expPerHour).ceil()));
    expect((gap / y.expPerHour).ceil(), lessThan(f.totalHours));
    expect(f.totalHours, lessThan(1730), reason: '购丹混合快于纯离线(1730h·三场景测钉)');
    expect(
      e1.days,
      inInclusiveRange(1.0, 3.5),
    ); // 2026-07-23 Ch14 扩后缺口 6271·E1 下沿随缺口重校
    expect(s4Days, inInclusiveRange(7.0, 14.0));
    // Ch14 缺口重校后 f 实测 33.5 天,下沿 35→30 同步(同 s1 口径·2026-07-23)。
    expect(f.days, inInclusiveRange(30.0, 65.0));
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 参考路线终态（与 progression_release_budget_test 同口径）
// ─────────────────────────────────────────────────────────────────────────────

const _allInnerDemonStages = {
  'stage_inner_demon_01',
  'stage_inner_demon_02',
  'stage_inner_demon_03',
  'stage_inner_demon_04',
  'stage_inner_demon_05',
  'stage_inner_demon_06',
  'stage_inner_demon_07',
};

Character _referenceRouteEnd(GameRepository repo) {
  final ch = _newSanLiuRouteCharacter(repo);
  final combatRewards = <int>[
    ..._stageRewards(repo, StageType.mainline),
    ...repo.towerFloors.map((floor) => floor.baseExpReward),
    ..._stageRewards(repo, StageType.lightFoot),
    ..._stageRewards(repo, StageType.massBattle),
    ..._stageRewards(repo, StageType.innerDemon),
  ];
  for (final reward in combatRewards) {
    _applyExperience(repo, ch, reward);
  }
  _applyExperience(
    repo,
    ch,
    _retreatExp(repo, ch, RetreatMapType.cangJingGe, 72),
  );
  _applyExperience(repo, ch, _passiveExp(repo, ch.realmTier, 24));
  for (final id in const [
    'item_jingyandan_small',
    'item_jingyandan_mid',
    'item_jingyandan_large',
  ]) {
    _consumePill(repo, ch, id);
  }
  return ch;
}

Character _newSanLiuRouteCharacter(GameRepository repo) =>
    _newCharacter(repo, RealmTier.xueTu, RealmLayer.qiMeng);

Character _newSanLiuCharacter(GameRepository repo) =>
    _newCharacter(repo, RealmTier.sanLiu, RealmLayer.qiMeng);

Character _newCharacter(GameRepository repo, RealmTier tier, RealmLayer layer) {
  final realm = repo.getRealm(tier, layer);
  return Character.create(
    name: 'idle_horizon_probe',
    realmTier: tier,
    realmLayer: layer,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 7, 14),
    internalForceMax: realm.internalForceMax,
    experienceToNextLayer: realm.experienceToNext,
  );
}

void _applyExperience(GameRepository repo, Character ch, int exp) {
  CharacterAdvancementService.applyExperience(
    ch,
    exp,
    realmLookup: repo.getRealm,
    isLayerLocked: (tier, layer) => ProgressionGateService.isLayerLocked(
      nextTier: tier,
      nextLayer: layer,
      releaseCap: repo.numbers.progressionReleaseCap,
      realmLookup: repo.getRealm,
      innerDemonDef: repo.numbers.innerDemon,
      clearedStageIds: _allInnerDemonStages,
    ),
  );
}

void _consumePill(GameRepository repo, Character ch, String defId) {
  final fraction = repo.itemDefs[defId]!.layerFraction!;
  final threshold = repo.getRealm(ch.realmTier, ch.realmLayer).experienceToNext;
  _applyExperience(repo, ch, (threshold * fraction).round());
}

List<int> _stageRewards(GameRepository repo, StageType type) {
  final stages =
      repo.stageDefs.values.where((stage) => stage.stageType == type).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return stages.map((stage) => stage.baseExpReward).toList(growable: false);
}

int _displayLevel(GameRepository repo, Character ch) {
  final realm = repo.getRealm(ch.realmTier, ch.realmLayer);
  return RealmProgressDisplay.fromSnapshot(
    absoluteRealmLevel: realm.absoluteLevel,
    experience: ch.experience,
    experienceToNext: realm.experienceToNext,
    hasNextRealmLayer:
        CharacterAdvancementService.nextLayer(ch.realmTier, ch.realmLayer) !=
        null,
  ).level;
}

/// 从当前状态推进到显示级 [targetLevel] 还需的 EXP（纯查表，不 mutate）。
int _expToDisplayLevel(GameRepository repo, Character ch, int targetLevel) {
  var abs = repo.getRealm(ch.realmTier, ch.realmLayer).absoluteLevel;
  var exp = ch.experience;
  var needed = 0;
  while (true) {
    final def = repo.getRealmByAbsoluteLevel(abs);
    final threshold = def.experienceToNext;
    final seg = (exp * 10 ~/ threshold).clamp(0, 9);
    final level = (abs - 1) * 10 + seg + 1;
    if (level >= targetLevel) return needed;
    final targetAbs = (targetLevel - 1) ~/ 10 + 1;
    final targetSeg = (targetLevel - 1) % 10;
    if (abs == targetAbs) {
      final targetExp = (targetSeg * threshold + 9) ~/ 10;
      return needed + (targetExp > exp ? targetExp - exp : 0);
    }
    needed += threshold - exp;
    abs += 1;
    exp = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 生产纯函数速率取样
// ─────────────────────────────────────────────────────────────────────────────

int _retreatExpAtHour(
  GameRepository repo,
  RealmTier tier,
  RetreatMapType map,
  int hours,
) {
  final startedAt = DateTime(2026, 7, 1, 10); // 非节气日（对齐 budget 测试口径）
  final session = RetreatSession()
    ..saveDataId = 1
    ..mapType = map
    ..realmTierAtStart = tier
    ..startedAt = startedAt;
  return SeclusionService.computeOutputs(
    session: session,
    charRealmTier: tier,
    config: repo.numbers.retreat,
    maps: repo.seclusionMaps,
    now: startedAt.add(Duration(hours: hours)),
  ).experiencePoints;
}

int _retreatSilverAtHour(
  GameRepository repo,
  RealmTier tier,
  RetreatMapType map,
  int hours,
) {
  final startedAt = DateTime(2026, 7, 1, 10);
  final session = RetreatSession()
    ..saveDataId = 1
    ..mapType = map
    ..realmTierAtStart = tier
    ..startedAt = startedAt;
  return SeclusionService.computeOutputs(
    session: session,
    charRealmTier: tier,
    config: repo.numbers.retreat,
    maps: repo.seclusionMaps,
    now: startedAt.add(Duration(hours: hours)),
  ).silver;
}

int _retreatExp(
  GameRepository repo,
  Character ch,
  RetreatMapType map,
  int hours,
) => _retreatExpAtHour(repo, ch.realmTier, map, hours);

int _passiveExp(GameRepository repo, RealmTier tier, int hours) =>
    OfflinePassiveService.compute(
      awayHours: hours.toDouble(),
      realmTier: tier,
      config: repo.numbers.passiveIdle,
    ).experience;

// ─────────────────────────────────────────────────────────────────────────────
// 场景引擎
// ─────────────────────────────────────────────────────────────────────────────

class _HorizonResult {
  _HorizonResult(this.name, this.character);
  final String name;
  final Character character;
  final milestoneHours = <int, int>{};
  final layerHours = <int, int>{};
  var totalHours = 0;
  var appliedExp = 0;
  double get days => totalHours / 24.0;
}

/// 周期结算引擎：每周期内按真实服务累计（floor 语义与收功一致），
/// 小时粒度推进并记录里程碑。[cycleSilver] 非空时累计银两，
/// [shopPills] 为真则银两即时全购小丹消费（ItemUseService 同公式）。
_HorizonResult _runCycleDriven(
  GameRepository repo, {
  required String name,
  required int cycleHours,
  required int Function(RealmTier tier, int hourInCycle) cycleExp,
  int Function(RealmTier tier, int hourInCycle)? cycleSilver,
  bool shopPills = false,
}) {
  final result = _HorizonResult(name, _referenceRouteEnd(repo));
  final ch = result.character;
  var takenExp = 0;
  var takenSilver = 0;
  var silverPool = 0;
  var hourInCycle = 0;

  void applyExp(int e) {
    result.appliedExp += e;
    _applyExperience(repo, ch, e);
  }

  while (_displayLevel(repo, ch) < _targetLevel &&
      result.totalHours < _maxHours) {
    result.totalHours++;
    hourInCycle++;
    if (hourInCycle > cycleHours) {
      hourInCycle = 1;
      takenExp = 0;
      takenSilver = 0;
    }
    final tier = ch.realmTier;
    final avail = cycleExp(tier, hourInCycle);
    final delta = avail - takenExp;
    if (delta > 0) {
      takenExp = avail;
      applyExp(delta);
    }
    if (cycleSilver != null) {
      final availS = cycleSilver(tier, hourInCycle);
      final ds = availS - takenSilver;
      if (ds > 0) {
        takenSilver = availS;
        silverPool += ds;
      }
    }
    if (shopPills) {
      final shopDef = repo.shopItemDefs['shop_jingyandan_small']!;
      final pillDef = repo.itemDefs['item_jingyandan_small']!;
      while (true) {
        final etl = repo.getRealm(ch.realmTier, ch.realmLayer).experienceToNext;
        final price = (etl * shopDef.priceLayerFraction!).round();
        if (price <= 0 || silverPool < price) break;
        silverPool -= price;
        applyExp((etl * pillDef.layerFraction!).round());
      }
    }
    _record(repo, result);
  }
  return result;
}

/// 桃花岛丹房产丹引擎：凝神丹即产即用（丹=0.1 当前层 ETL），
/// 药草园同级自供给（配置锚点测已断言不断料）。
_HorizonResult _runIslandPills(
  GameRepository repo, {
  required String name,
  required int danFangLevel,
}) {
  final result = _HorizonResult(name, _referenceRouteEnd(repo));
  final ch = result.character;
  final brew = repo.numbers.taohuaIsland
      .buildingOf(BuildingType.danFang)
      .recipeById('brew_ningshen')!;
  final pillDef = repo.itemDefs['item_jingyandan_small']!;
  final pillsPerHour = brew.ratePerHour * danFangLevel; // 无灵泉协同加成基线
  var stock = 0.0;

  while (_displayLevel(repo, ch) < _targetLevel &&
      result.totalHours < _maxHours) {
    result.totalHours++;
    stock += pillsPerHour;
    while (stock >= 1.0 && _displayLevel(repo, ch) < _targetLevel) {
      stock -= 1.0;
      final etl = repo.getRealm(ch.realmTier, ch.realmLayer).experienceToNext;
      final gain = (etl * pillDef.layerFraction!).round();
      result.appliedExp += gain;
      _applyExperience(repo, ch, gain);
    }
    _record(repo, result);
  }
  return result;
}

void _record(GameRepository repo, _HorizonResult r) {
  final ch = r.character;
  final lv = _displayLevel(repo, ch);
  for (final m in _milestones) {
    if (!r.milestoneHours.containsKey(m) && lv >= m) {
      r.milestoneHours[m] = r.totalHours;
    }
  }
  final abs = repo.getRealm(ch.realmTier, ch.realmLayer).absoluteLevel;
  for (var a = 11; a <= 15; a++) {
    if (!r.layerHours.containsKey(a) && abs >= a) {
      r.layerHours[a] = r.totalHours;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 自洽断言与报告
// ─────────────────────────────────────────────────────────────────────────────

void _assertMonotonic(_HorizonResult r) {
  final hours = [for (final m in _milestones) r.milestoneHours[m]!];
  for (var i = 1; i < hours.length; i++) {
    expect(hours[i], greaterThan(hours[i - 1]), reason: '${r.name}: 里程碑小时单调递增');
  }
  expect(r.totalHours, hours.last, reason: '${r.name}: 总时长 = 达 Lv141 时刻');
}

void _assertConservation(GameRepository repo, _HorizonResult r) {
  final ch = r.character;
  expect(
    repo.getRealm(ch.realmTier, ch.realmLayer).absoluteLevel,
    15,
    reason: '${r.name}: 终点 = 二流·启蒙(abs15)',
  );
  expect(
    r.appliedExp,
    6271 + ch.experience,
    reason: '${r.name}: 经验守恒 = 缺口 6271 + 终点层内余量',
  );
}

void _printResult(_HorizonResult r) {
  String h(int? hours) => hours == null ? '-' : hours.toString();
  String d(int? hours) =>
      hours == null ? '-' : (hours / 24.0).toStringAsFixed(1);
  print(r.name);
  print(
    '  Lv100 ${h(r.milestoneHours[100])}h (${d(r.milestoneHours[100])}天) · '
    'Lv120 ${h(r.milestoneHours[120])}h (${d(r.milestoneHours[120])}天) · '
    'Lv141 ${r.totalHours}h (${r.days.toStringAsFixed(1)}天)',
  );
  print(
    '  逐层(abs11→15)小时: '
    '${[for (var a = 11; a <= 15; a++) h(r.layerHours[a])].join(" / ")}',
  );
}
