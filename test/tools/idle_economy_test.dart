// ignore_for_file: avoid_print
//
// 根因A 挂机经济曲线验证 · idle_economy(2026-05-29)
//
// 量化 72h 挂机(cap)vs 主动战斗在根因A 三维成长速度,断言"可观但不冲淡主动
// 战斗"平衡带。numbers tune 改动若破带 → 红灯(drift 雷达)。
//
//   B1 共鸣度:挂机 resonance.seclusion_battle_count_per_hour/h
//             vs 实战 +1/胜(battle_resolution.dart:136)
//             默契阈值 = resonanceStages.firstWhere(unlocksJointSkill).minBattleCount
//   B2 EXP:   挂机 exp_per_hour × h × realmScaleFor(tier)
//             tier-fair = 喂真 CharacterAdvancementService.applyExperience 数 layersGained
//             设计锚 = 二流 xuanYaPuBu 72h ≈ 3-4 个 Ch3 大Boss(stage_03_05 baseExpReward)
//   B3 凝练:  挂机 base_technique_learn_per_hour × technique_learn_rate × h × scale
//             → insightPoints × insight_to_cultivation_ratio → 修炼度 progress
//             vs cultivationProgressToNext[chuKui](初窥→小成)
//
// 口径基线:solarBonus / ziShi / zhengWu 均取 1.0(节气/子时/正午只会增益,不减),
// 玩家境界 = 各图 requiredRealm(刚解锁该图的保守地板)。
//
// 纯 config 算术 + 真实 applyExperience 升层逻辑。Isar-free(GameRepository
// .loadAllDefs File loader,沿 balance_simulator_test 体例)。
// 输出 test/tools/output/idle_economy_2026-05-29.md。
//
// 跑法:flutter test test/tools/idle_economy_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';

const String _outputDir = 'test/tools/output';

/// Ch3 大Boss(stage_03_05)baseExpReward — B2 设计锚的折算单位。
/// 验证主体从 stages.yaml 读真值,此处仅作 reason 注释参照。
const int _ch3BossExpRef = 6000;

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('根因A 挂机经济曲线 · B1/B2/B3 平衡验证', () {
    final n = repo.numbers;
    final retreat = n.retreat;
    final hours = retreat.capHours.toDouble(); // 72(cap)

    // ── B1 共鸣度(map-independent) ──
    final perHourBC = n.resonanceSeclusionBattleCountPerHour; // 5
    final jointThreshold = n.resonanceStages
        .firstWhere((s) => s.unlocksJointSkill)
        .minBattleCount; // 默契下界 300
    final idleBC = (perHourBC * hours).floor(); // 72h × 5 = 360
    final hoursToJoint = jointThreshold / perHourBC; // 60h

    // ── B2 / B3 逐图 ──
    final ratio = n.insightToCultivationRatio; // 1.0
    final baseLearn = retreat.baseTechniqueLearnPerHour; // 0.5
    final earlyLayer = n.cultivationProgressToNext[CultivationLayer.chuKui]!;
    // Ch3 大Boss baseExpReward(从 stages.yaml 真值读,非 hardcode)
    final ch3Boss = repo.stageDefs['stage_03_05']!.baseExpReward;

    final rows = <_Row>[];
    for (final map in repo.seclusionMaps) {
      final tier = map.requiredRealm;
      final scale = retreat.realmScaleFor(tier);

      // B2: idle EXP + tier-fair layersGained(真 applyExperience)+ 落点境界
      final idleExp = (map.experiencePerHour * hours * scale).floor();
      final probe = _layersFromIdleExp(repo, tier, idleExp);
      final layersGained = probe.layers;
      final finalTier = probe.finalTier;
      final bossEq = idleExp / ch3Boss;

      // B3: insightPoints → 凝练修炼度 progress
      final insight =
          (baseLearn * map.techniqueLearnRate * hours * scale).floor();
      final cultProgress = (insight * ratio).floor();
      final cultEarlyLayers = cultProgress / earlyLayer;

      rows.add(_Row(
        mapName: map.mapName,
        mapType: map.mapType.name,
        tier: tier.name,
        scale: scale,
        idleExp: idleExp,
        layersGained: layersGained,
        finalTier: finalTier,
        bossEq: bossEq,
        insight: insight,
        cultProgress: cultProgress,
        cultEarlyLayers: cultEarlyLayers,
      ));
    }

    _writeSummary(rows,
        hours: hours,
        perHourBC: perHourBC,
        idleBC: idleBC,
        jointThreshold: jointThreshold,
        hoursToJoint: hoursToJoint,
        ch3Boss: ch3Boss,
        earlyLayer: earlyLayer,
        ratio: ratio,
        baseLearn: baseLearn);

    // ───────────────────────── 断言:平衡带 ─────────────────────────

    // B1:72h 挂机跨默契阈值(人剑合一离线/中期可及,根因A 核心承诺)。
    expect(idleBC, greaterThanOrEqualTo(jointThreshold),
        reason: 'B1: 72h 挂机 battleCount=$idleBC 应 ≥ 默契阈值 $jointThreshold '
            '(人剑合一离线可及)');
    // 但 trickle 要慢:到默契需多日挂机(24-72h),不秒解锁(idle << 实战 +1/胜)。
    expect(hoursToJoint, inInclusiveRange(24.0, hours),
        reason: 'B1: 挂机到默契需 ${hoursToJoint.toStringAsFixed(0)}h,'
            '应 ∈ [24, $hours](可及但需多日投入,不冲淡实战)');

    // B2 设计锚:二流 xuanYaPuBu 72h 挂机 EXP ≈ 3-4 个 Ch3 大Boss(原 1.4)。
    final xuanYa = rows.firstWhere((r) => r.mapType == 'xuanYaPuBu');
    expect(xuanYa.bossEq, inInclusiveRange(3.0, 4.5),
        reason: 'B2 设计锚: 二流 xuanYaPuBu 72h EXP 折 Boss=${xuanYa.bossEq.toStringAsFixed(1)} '
            '应 ∈ [3, 4.5]($_ch3BossExpRef/Boss · 根因A ×2.5 目标 3-4)');

    // B2 通用:每张图 72h 挂机都应"可观"(≥1 层)但不"爆"(< 一个大境界 7 层
    // 的 3 倍 = 21 层,挡住低 tier EXP×2.5 失控)。
    for (final r in rows) {
      expect(r.layersGained, greaterThanOrEqualTo(1),
          reason: 'B2 ${r.mapType}: 72h 挂机应至少推进 1 层,实际 ${r.layersGained}');
      expect(r.layersGained, lessThanOrEqualTo(21),
          reason: 'B2 ${r.mapType}: 72h 挂机推进 ${r.layersGained} 层 > 21(3 个大境界),'
              'EXP 失控冲淡主动战斗');
    }

    // B2 finding 修正回归守(2026-05-29):学徒可进的图(requiredRealm==xueTu,
    // 即新手开局就能挂的山林)满挂 72h,落点境界不得进入二流(erLiu)。否则回头
    // 打 Ch1 学徒敌差 2 阶 → 守方 0.3/攻方 2.5 碾压,毁早期难度爬升仪式感。
    // 低 tier 挂机 EXP 回 ×1.0 后落点 ≤ 三流(差 1 阶,轻微不碾压)。
    // 语义守(非瞬时层数):未来谁把低 tier exp 调回 ×2.5 推到二流即红灯。
    final lowTier = rows.where((r) => r.tier == RealmTier.xueTu.name);
    for (final r in lowTier) {
      expect(r.finalTier.index, lessThan(RealmTier.erLiu.index),
          reason: 'B2 finding: 学徒图 ${r.mapType} 满挂落点 ${r.finalTier.name} '
              '不得进二流(对 Ch1 学徒敌差 2 阶碾压)· 低 tier 挂机 EXP 应保 ×1.0');
    }

    // B3:每张图 72h 凝练修炼度折早期层 ∈ [0.3, 3.0]
    //    (死钱包变有意义 sink,但不破修炼度曲线 — 修炼度主路仍是实战招式使用)。
    for (final r in rows) {
      expect(r.cultEarlyLayers, inInclusiveRange(0.3, 3.0),
          reason: 'B3 ${r.mapType}: 72h 凝练 ${r.cultProgress} progress '
              '≈ ${r.cultEarlyLayers.toStringAsFixed(2)} 早期层,应 ∈ [0.3, 3.0]');
    }
  });
}

/// 喂真 [CharacterAdvancementService.applyExperience]:构造 (tier, 启蒙) 内存
/// 角色,从 0 EXP 喂 [idleExp],数升了几层(走真升层 while-loop)+ 落点境界。
/// 无 isLayerLocked(非 wuSheng 路径不触发心魔关拦截)。
({int layers, RealmTier finalTier}) _layersFromIdleExp(
    GameRepository repo, RealmTier tier, int idleExp) {
  final firstLayer = RealmLayer.values.first; // qiMeng 启蒙
  final def = repo.getRealm(tier, firstLayer);
  final ch = Character.create(
    name: 'idle_probe',
    realmTier: tier,
    realmLayer: firstLayer,
    attributes: Attributes(),
    rarity: RarityTier.values.first,
    lineageRole: LineageRole.values.first,
    createdAt: DateTime(2026, 5, 29),
    internalForceMax: def.internalForceMax,
    experience: 0,
    experienceToNextLayer: def.experienceToNext,
  );
  final r = CharacterAdvancementService.applyExperience(
    ch,
    idleExp,
    realmLookup: repo.getRealm,
  );
  return (layers: r.layersGained, finalTier: ch.realmTier);
}

class _Row {
  final String mapName;
  final String mapType;
  final String tier;
  final double scale;
  final int idleExp;
  final int layersGained;
  final RealmTier finalTier;
  final double bossEq;
  final int insight;
  final int cultProgress;
  final double cultEarlyLayers;

  _Row({
    required this.mapName,
    required this.mapType,
    required this.tier,
    required this.scale,
    required this.idleExp,
    required this.layersGained,
    required this.finalTier,
    required this.bossEq,
    required this.insight,
    required this.cultProgress,
    required this.cultEarlyLayers,
  });
}

void _writeSummary(
  List<_Row> rows, {
  required double hours,
  required int perHourBC,
  required int idleBC,
  required int jointThreshold,
  required double hoursToJoint,
  required int ch3Boss,
  required int earlyLayer,
  required double ratio,
  required double baseLearn,
}) {
  final buf = StringBuffer();
  buf.writeln('# 根因A 挂机经济曲线 · idle_economy 验证 · 2026-05-29');
  buf.writeln('');
  buf.writeln('挂机封顶 ${hours.toStringAsFixed(0)}h(`retreat.cap_hours`)· '
      '基线 solarBonus/ziShi/zhengWu = 1.0 · 玩家境界 = 各图 requiredRealm。');
  buf.writeln('');
  buf.writeln('## B1 共鸣度(人剑合一)');
  buf.writeln('');
  buf.writeln('- 挂机折算:`$perHourBC battleCount/h` × ${hours.toStringAsFixed(0)}h = '
      '**$idleBC** /件出战装备');
  buf.writeln('- 默契阈值(解锁人剑合一):**$jointThreshold**');
  buf.writeln('- 挂机到默契:**${hoursToJoint.toStringAsFixed(0)}h**');
  buf.writeln('- 实战对照:`+1 battleCount/胜`(battle_resolution.dart:136)→ '
      '挂机 1h ≈ 实战 $perHourBC 胜的共鸣推进(idle 是慢速涓流)');
  buf.writeln('- 判定:72h 挂机 $idleBC ≥ $jointThreshold ✅ 离线可达人剑合一;'
      '需 ${hoursToJoint.toStringAsFixed(0)}h 多日投入,不秒解锁');
  buf.writeln('');
  buf.writeln('## B2 EXP / B3 凝练修炼度(逐图)');
  buf.writeln('');
  buf.writeln('Ch3 大Boss(stage_03_05)baseExpReward = **$ch3Boss** · '
      '早期修炼层(初窥→小成)= **$earlyLayer** · '
      'insight→修炼比率 = **$ratio** · base_learn = **$baseLearn**/h');
  buf.writeln('');
  buf.writeln('| 图 | requiredRealm | scale | B2 idleEXP | 折Ch3Boss | tier-fair升层 | '
      'B3 insight | 凝练修炼度 | 折早期层 |');
  buf.writeln('|---|---|---|---|---|---|---|---|---|');
  for (final r in rows) {
    buf.writeln('| ${r.mapName}(${r.mapType}) | ${r.tier} | '
        '${r.scale.toStringAsFixed(2)} | ${r.idleExp} | '
        '${r.bossEq.toStringAsFixed(1)} | ${r.layersGained} | '
        '${r.insight} | ${r.cultProgress} | '
        '${r.cultEarlyLayers.toStringAsFixed(2)} |');
  }
  buf.writeln('');
  buf.writeln('## 平衡带断言');
  buf.writeln('');
  buf.writeln('- **B1**:72h 挂机 battleCount ≥ 默契阈值 ∧ 到阈值耗时 ∈ [24, ${hours.toStringAsFixed(0)}]h');
  buf.writeln('- **B2 设计锚**:二流 xuanYaPuBu 折 Boss ∈ [3, 4.5](根因A ×2.5 目标 3-4)');
  buf.writeln('- **B2 通用**:每图 tier-fair 升层 ∈ [1, 21](可观但不爆 3 个大境界)');
  buf.writeln('- **B3**:每图凝练折早期层 ∈ [0.3, 3.0](有意义 sink,不破修炼度主路)');
  buf.writeln('');
  buf.writeln('## 局限');
  buf.writeln('');
  buf.writeln('- 折Ch3Boss 仅在二流(Ch3 同期 tier)有意义;高 tier(宗师 duanYaJueBi)'
      '对 Ch3 Boss 折算失真,故 B2 通用断言改用 tier-fair 升层。');
  buf.writeln('- 不含装备 drop / 内力涨幅 / 心法相生增益(只验三批核心成长维度)。');
  buf.writeln('- 实战 EXP 用 stage.baseExpReward(全员 full 不平摊),挂机 vs 实战'
      '"成长速度"对比是每单位时间产出量级,非精确时薪。');
  File('$_outputDir/idle_economy_2026-05-29.md').writeAsStringSync(buf.toString());
}
