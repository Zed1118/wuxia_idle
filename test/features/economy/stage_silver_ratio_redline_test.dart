// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 关卡掉落银两「占总收入比例」雷达(确定性算式 · 长线平衡审计 2026-07-01)。
///
/// 背景:stages.yaml 40 关 item_silver 掉落全标「P1 占位,待 balance」,初值分阶
/// 递增([5,10]→[200,280])但从未与闭关银两锚交叉校准;economy_balance_test 只验
/// 闭关侧 + 无套利,未覆盖关卡侧占比。本测把 spec 设计锚固化成雷达(drift 雷达)。
///
/// 设计锚(docs/spec/2026-06-21-p4-material-economy-balance-design.md §D2/line 40-42):
/// - 收入构成:闭关为主(65-75%)+ 关卡掉落补(25-35%)。
/// - 二流校准示例:悬崖闭关 8h≈325 银两 + 关卡掉落补 ~100-150 = ~450/天。
///
/// 口径(显式假设·不钉死每日打本关数):不预设玩家每天打几关,改为反推
/// 「达成 30% 关卡占比所需的每日 on-level 打本关数 K30」,断言 K30 落人类每天
/// 打得动的合理带 [2, 12] 关。某阶关卡银两初值过低/过高 → K30 跳出带 → 暴露需
/// 校准的阶。梯度单调另作硬断言。数值在带内即可(可 balance 微调,不钉死单点)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // 主线关 id 形如 stage_01_01 ~ stage_06_05(用 map key 判定,不依赖 StageDef 字段名)。
  final mainlineRe = RegExp(r'^stage_\d\d_\d\d$');

  // 单关 item_silver 期望 = Σ (min+max)/2 × dropChance。
  double stageSilverExpectation(StageDef s) {
    var sum = 0.0;
    for (final d in s.dropTable) {
      if (d is ItemDrop && d.inventoryItemDefId == 'item_silver') {
        sum += (d.quantityMin + d.quantityMax) / 2.0 * d.dropChance;
      }
    }
    return sum;
  }

  Map<RealmTier, double> avgSilverByTier() {
    final r = GameRepository.instance;
    final byTier = <RealmTier, List<double>>{};
    for (final e in r.stageDefs.entries) {
      if (!mainlineRe.hasMatch(e.key)) continue;
      final exp = stageSilverExpectation(e.value);
      if (exp <= 0) continue;
      (byTier[e.value.requiredRealm] ??= <double>[]).add(exp);
    }
    return {
      for (final t in byTier.keys)
        t: byTier[t]!.reduce((a, b) => a + b) / byTier[t]!.length,
    };
  }

  group('关卡掉落银两占比雷达(长线平衡审计)', () {
    test('关卡 item_silver 期望随境界阶梯度单调不减', () {
      final avg = avgSilverByTier();
      final tiers = avg.keys.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      expect(tiers.length, greaterThan(1), reason: '应覆盖多个境界阶');
      for (var i = 1; i < tiers.length; i++) {
        expect(
          avg[tiers[i]]!,
          greaterThanOrEqualTo(avg[tiers[i - 1]]!),
          reason: '高阶主线关平均掉落银两不应低于低阶(梯度单调):'
              '${tiers[i - 1].name}=${avg[tiers[i - 1]]} '
              '${tiers[i].name}=${avg[tiers[i]]}',
        );
      }
    });

    test('达成 30% 关卡占比所需每日打本关数 K30 落合理带 [2,12](各 on-level 阶)', () {
      final r = GameRepository.instance;
      final avg = avgSilverByTier();
      final scalePer = r.numbers.retreat.realmScalePerTier;
      var checked = 0;
      for (final m in r.seclusionMaps) {
        final tier = m.requiredRealm;
        final avgStage = avg[tier];
        if (avgStage == null || avgStage <= 0) continue;
        final scale = math.pow(scalePer, tier.index).toDouble();
        final seclusionDaily = m.silverPerHour * scale * 8; // 闭关 8h/天
        // 占比 p = (avgStage×K) / (avgStage×K + seclusionDaily);解 p=0.30 得 K。
        final k30 = (0.30 / 0.70) * seclusionDaily / avgStage;
        // 学徒 onboarding:闭关 silverPerHour 特意压低(T6「提早期降门槛」),关卡银两
        // 相对偏高属有意新手引导(实测 K30≈1.8),下界放宽;稳态阶(三流+)严格 [2,12]。
        final lower = tier == RealmTier.xueTu ? 1.5 : 2.0;
        checked++;
        print(
          '[占比雷达] ${tier.name}: 单关期望=${avgStage.toStringAsFixed(1)} '
          '闭关日=${seclusionDaily.toStringAsFixed(0)} K30=${k30.toStringAsFixed(1)}关',
        );
        expect(
          k30,
          inInclusiveRange(lower, 12.0),
          reason: '${tier.name} 阶:达成 30% 关卡占比需每日打本 ${k30.toStringAsFixed(1)} 关,'
              '跳出合理带[\$lower,12]→该阶关卡银两初值需校准'
              '(单关期望=$avgStage 闭关日=$seclusionDaily)',
        );
      }
      expect(checked, greaterThan(0), reason: '至少一个 on-level 阶被校验');
    });
  });
}
