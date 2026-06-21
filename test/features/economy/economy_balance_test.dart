import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 材料经济节奏 balance 验证(确定性算式,非战斗模拟)。
/// balance_simulator 只模拟战斗 winRate/伤害,不建模挂机银两收入 → 经济节奏
/// (日收入 vs 消费锚 / 无套利)用本确定性算式单测验证。锚定 design 意图,数值
/// 在区间内即可(不钉死单点,数值仍可 balance 微调)。
///
/// 设计锚(docs/spec/2026-06-21-p4-material-economy-balance-design.md):
/// - 基调「适度规划取舍」:强化一件主力装备到 +15 ≈ 2–3 天日常挂机(闭关8h+打本)负担。
/// - 闭关为主(占 65–75%)+ 关卡掉落补(25–35%)。
/// - 经验丹动态标价防套利(银两→经验兑换率 ≈ 挂机隐含率,scale 约掉全境界成立)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('材料经济节奏 balance(确定性算式)', () {
    test('闭关 silver_per_hour 随解锁境界梯度单调不减', () {
      final maps = GameRepository.instance.seclusionMaps;
      final sorted = [...maps]
        ..sort((a, b) => a.requiredRealm.index.compareTo(b.requiredRealm.index));
      for (var i = 1; i < sorted.length; i++) {
        expect(
          sorted[i].silverPerHour,
          greaterThanOrEqualTo(sorted[i - 1].silverPerHour),
          reason: '高境界解锁图银两产出不应低于低境界图(梯度单调)',
        );
      }
    });

    test('二流 on-level 闭关日收入 = 强化到+15 消费锚的 1/3.0~1/4.5(关卡掉落补到 2-3 天)', () {
      final r = GameRepository.instance;
      // 二流主力收入图 = 悬崖瀑布(唯一 requiredRealm == erLiu 图)。
      final xuanya = r.seclusionMaps
          .firstWhere((m) => m.requiredRealm == RealmTier.erLiu);
      // 最终银两/h = silverPerHour × realmScale^境界index(seclusion_service 真实公式)。
      final scale = math
          .pow(r.numbers.retreat.realmScalePerTier, RealmTier.erLiu.index)
          .toDouble();
      final dailySeclusion = xuanya.silverPerHour * scale * 8; // 8h/天

      // 消费锚:强化一件主力装备到 +15 累计磨剑石 × 固定标价。
      var mojianshiTo15 = 0;
      for (var lv = 1; lv <= 15; lv++) {
        mojianshiTo15 += r.numbers.enhancement.mojianshiCostFor(lv);
      }
      final mojianshiPrice = r.shopItemDefs['shop_mojianshi']!.price!;
      final consumeAnchor = mojianshiTo15 * mojianshiPrice;

      final daysSeclusionOnly = consumeAnchor / dailySeclusion;
      expect(
        daysSeclusionOnly,
        inInclusiveRange(3.0, 4.5),
        reason: '闭关单独应 3–4.5 天买齐一条养成线,配关卡掉落(25–35%)补到 2–3 天锚;'
            '现状 consumeAnchor=$consumeAnchor dailySeclusion=$dailySeclusion',
      );
    });

    test('经验丹动态标价无套利:买丹银两单价 ≥ 挂机隐含银两单价(全境界 scale 约掉)', () {
      final r = GameRepository.instance;
      // 挂机隐含「银两/经验」单价 = silverPerHour / baseExpPerHour。用最高产图最严格。
      final maxSilverPerHour =
          r.seclusionMaps.map((m) => m.silverPerHour).reduce(math.max);
      final baseExp = r.numbers.passiveIdle.baseExpPerHour;
      final idleRatio = maxSilverPerHour / baseExp; // 挂机银两/经验

      for (final pair in const [
        ['shop_jingyandan_small', 'item_jingyandan_small'],
        ['shop_jingyandan_mid', 'item_jingyandan_mid'],
      ]) {
        final shopDef = r.shopItemDefs[pair[0]]!;
        final itemDef = r.itemDefs[pair[1]]!;
        // 买丹「银两/经验」单价 = priceLayerFraction / layerFraction
        // (标价=etl×priceFraction,增益=etl×layerFraction,etl 约掉)。
        final buyRatio = shopDef.priceLayerFraction! / itemDef.layerFraction!;
        expect(
          buyRatio,
          greaterThanOrEqualTo(idleRatio),
          reason: '${pair[1]} 买丹银两单价($buyRatio)应≥挂机隐含单价($idleRatio),'
              '否则后期用银两 carry 经验套利,破坏 §5.5 挂机为主',
        );
      }
    });
  });
}
