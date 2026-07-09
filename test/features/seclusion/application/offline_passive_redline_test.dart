// M2 范围 B Task 7：被动离线挂机产出红线复评（balance_simulator 同口径）。
//
// 被动只产经验 / 磨剑石，**不直接进伤害公式**（CLAUDE.md §5.4 两层语义）——
// 故不碰硬红线（装备攻击 / 血量 / 内力 / Boss 血）也不直接碰软红线（实战伤害不进百万）。
// 本测守护的是**养成速度**这条间接风险线：满 72h 被动涓流不得把低境界玩家
// 推到碾压跨阶内容的量级。
//
// 锚定结论（2026-07-09 复评，修正高境界离线失能）：
//   被动经验 = 闭关同时长 × 50%（base_exp 50 / 入门山林图 100）。
//   被动磨剑石 = 闭关同时长 × 25%（base_moji 0.25 / 入门山林图 1.0）。
//   闭关 B2 finding（numbers.yaml retreat shanLin 注释）已确认「满挂 72h 二流 16 层→三流
//   12 层·对 Ch1 学徒差 1 阶不碾压」；被动经验补到闭关 1/2，磨剑石仍保持
//   1/4 涓流。本测以**实数据**钉死分维度锚 + 各境界 72h 产出上界量级。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('被动 72h 学徒产出按经验 50% / 磨剑石 25% 锚定（实数据，±容差）', () {
    final cfg = repo.numbers.passiveIdle;
    // 入门山林图：required_realm xueTu，闭关产率锚点的基准图。
    final entryMap = repo.numbers.retreat.maps.firstWhere(
      (m) => m.requiredRealm == RealmTier.xueTu,
    );

    final passive = OfflinePassiveService.compute(
      awayHours: 72,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );

    // 闭关入门图 72h 学徒（scale 1.0）裸产出（不含时辰 / 节气加成）。
    final retreatExp72h = entryMap.experiencePerHour * 72;
    final retreatMoji72h = entryMap.mojianshiPerHour * 72;

    // 被动经验补到闭关 50%，磨剑石仍按 25% 涓流。容差吸收 floor 取整。
    expect(
      passive.experience,
      closeTo(retreatExp72h * 0.50, 50),
      reason: '被动 72h exp 应 ≈ 入门闭关 72h × 50%（${retreatExp72h * 0.50}）',
    );
    expect(
      passive.mojianshi,
      closeTo(retreatMoji72h * 0.25, 2),
      reason: '被动 72h 磨剑石应 ≈ 入门闭关 72h × 25%（${retreatMoji72h * 0.25}）',
    );

    // 入门图当前 100 exp/h、1.0 moji/h → 3600 exp、18 moji。锚死防 yaml 漂移。
    expect(passive.experience, 3600);
    expect(passive.mojianshi, 18);
  });

  test('被动 72h 各境界产出量级 + 不进异常量级（涓流远低于硬红线）', () {
    final cfg = repo.numbers.passiveIdle;

    final xueTu = OfflinePassiveService.compute(
      awayHours: 72,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );
    final erLiu = OfflinePassiveService.compute(
      awayHours: 72,
      realmTier: RealmTier.erLiu,
      config: cfg,
    );
    final wuSheng = OfflinePassiveService.compute(
      awayHours: 72,
      realmTier: RealmTier.wuSheng,
      config: cfg,
    );

    // 实测锚（scale = 1.6^index）：
    //   学徒 idx0 ×1.00 → exp 3600  / moji 18
    //   二流 idx2 ×2.56 → exp 9216  / moji 46
    //   武圣 idx6 ×16.78 → exp 60397 / moji 301（满 72h × 满境界 = 被动绝对天花板）
    expect(xueTu.experience, 3600);
    expect(erLiu.experience, 9216);
    expect(wuSheng.experience, 60397);
    expect(xueTu.mojianshi, 18);
    expect(erLiu.mojianshi, 46);
    expect(wuSheng.mojianshi, 301);

    // 单调性：高境界产出更高（scale 复用闭关锚点，符合预期）。
    expect(erLiu.experience, greaterThan(xueTu.experience));
    expect(wuSheng.experience, greaterThan(erLiu.experience));

    // 不进异常量级：武圣 72h 被动经验约等于满级前单层需求的个位数百分比，
    // 磨剑石仍是慢速补料，不直接冲掉闭关收益定位。
    expect(
      wuSheng.experience,
      lessThan(80000),
      reason: '被动绝对天花板（武圣 72h）经验须 < 80000，避免离线直接跳级',
    );
    expect(
      wuSheng.mojianshi,
      lessThan(400),
      reason: '被动绝对天花板（武圣 72h）磨剑石须 < 400',
    );
  });
}
