import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';

void main() {
  Widget host(EquipmentTier tier, double t) => MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [Positioned.fill(child: TreasureGlowLayer(tier: tier, t: t))],
      ),
    ),
  );

  testWidgets('神物 tier 峰值 t=0.32 渲染辉光 + 金闪(tier-gate 启用)', (tester) async {
    await tester.pumpWidget(host(EquipmentTier.shenWu, 0.32));
    expect(find.byKey(TreasureGlowLayer.auraKey), findsOneWidget);
    // 金闪窗口 0.24 < t < 0.46,t=0.32 命中
    expect(find.byKey(TreasureGlowLayer.flashKey), findsOneWidget);
  });

  testWidgets('神物末态 t=1.0 仅辉光驻留(金闪已褪)', (tester) async {
    await tester.pumpWidget(host(EquipmentTier.shenWu, 1.0));
    expect(find.byKey(TreasureGlowLayer.auraKey), findsOneWidget);
    expect(find.byKey(TreasureGlowLayer.flashKey), findsNothing);
  });

  testWidgets('重器 tier 不启用金光(tier-gate 拦,神物专属)', (tester) async {
    await tester.pumpWidget(host(EquipmentTier.zhongQi, 0.32));
    expect(find.byKey(TreasureGlowLayer.auraKey), findsNothing);
    expect(find.byKey(TreasureGlowLayer.flashKey), findsNothing);
  });
}
