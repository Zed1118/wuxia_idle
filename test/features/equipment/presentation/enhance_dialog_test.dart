import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/providers/rng_provider.dart';
import 'package:wuxia_idle/features/equipment/presentation/enhance_dialog.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// T29 EnhanceDialog widget 测试（phase2_tasks.md §433-434）。
///
/// 4 用例：
/// - 对话框打开 → 显示 +N → +N+1 预览
/// - mock Rng nextDouble=0.01 → success banner + eq.enhanceLevel +1（service in-place）
/// - mock Rng nextDouble=0.99 → failure banner + 「+1 心血结晶」+ eq 不变
/// - mojianshi=0 → 强化按钮 disabled
///
/// **T32 #22a 后写回 Isar 的真落地验证不在本文件**：testWidgets 默认 FakeAsync
/// 与真 Isar 异步 IO 不兼容（pumpAndSettle 在 AnimationController 不结束 +
/// Isar.findFirst 不前进），切换真 Isar 跑不通。Widget 层 [EnhanceDialog._persist]
/// 用 [Isar.getInstance] 探测，未初始化时 no-op；本测试保持 ProviderScope.override
/// 纯内存模式只验 UI + service in-place 改写，Isar 真落地由
/// `test/services/enhancement_persist_test.dart` 接 [EnhancementService.persistResult]
/// 覆盖（不依赖 Flutter binding）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Equipment mkEq({
    int enhanceLevel = 0,
    EquipmentTier tier = EquipmentTier.xunChang,
  }) {
    return Equipment.create(
      defId: 'test_eq',
      tier: tier,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      enhanceLevel: enhanceLevel,
    )..id = 1;
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Equipment eq,
    required int mojianshiQty,
    required int crystalQty,
    Rng? rng,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuantityByTypeProvider(ItemType.moJianShi).overrideWith(
            (ref) async => mojianshiQty,
          ),
          inventoryQuantityByTypeProvider(ItemType.xinXueJieJing).overrideWith(
            (ref) async => crystalQty,
          ),
          if (rng != null) rngProvider.overrideWithValue(rng),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: EnhanceDialog(equipment: eq)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('打开对话框 → 显示 +5 → +6 预览 + 成功率行', (tester) async {
    final eq = mkEq(enhanceLevel: 5);
    await pumpDialog(tester, eq: eq, mojianshiQty: 999, crystalQty: 0);

    expect(find.text('+5 → +6'), findsOneWidget);
    expect(find.text('成功率'), findsOneWidget);
    expect(find.text('材料'), findsOneWidget);
    expect(find.text('结晶'), findsOneWidget);
  });

  testWidgets('mock Rng nextDouble=0.01 → 强化成功 + 新 +N 显示', (tester) async {
    // +20 -> +21 fallback formula = max(0.30, 0.50 - 0.02*2) = 0.46
    // roll=0.01 < 0.46 → 成功
    final eq = mkEq(enhanceLevel: 20);
    await pumpDialog(
      tester,
      eq: eq,
      mojianshiQty: 999,
      crystalQty: 0,
      rng: _StubRng(0.01),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump();

    expect(eq.enhanceLevel, 21);
    expect(find.text('强化成功'), findsOneWidget);
    expect(find.text('+21'), findsWidgets);
  });

  testWidgets('mock Rng nextDouble=0.99 → 强化失败 + 「+1 心血结晶」 + +N 不变',
      (tester) async {
    // +20 -> +21 fallback formula = 0.46
    // roll=0.99 >= 0.46 → 失败（永不破防降级）
    final eq = mkEq(enhanceLevel: 20);
    await pumpDialog(
      tester,
      eq: eq,
      mojianshiQty: 999,
      crystalQty: 0,
      rng: _StubRng(0.99),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump();

    expect(eq.enhanceLevel, 20, reason: '失败永不破防降级');
    expect(find.text('强化失败'), findsOneWidget);
    expect(find.text('+1 心血结晶'), findsOneWidget);
  });

  testWidgets('mojianshi=0 → 强化按钮 disabled', (tester) async {
    final eq = mkEq(enhanceLevel: 3);
    await pumpDialog(tester, eq: eq, mojianshiQty: 0, crystalQty: 0);

    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull, reason: '材料 0 时强化按钮应 disabled');
  });

  testWidgets('传入 def → header 显示装备名（#24 fixup 验收）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
    final eq = Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: def.baseAttackMin,
      enhanceLevel: 0,
    )..id = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuantityByTypeProvider(ItemType.moJianShi).overrideWith(
            (ref) async => 1000,
          ),
          inventoryQuantityByTypeProvider(ItemType.xinXueJieJing).overrideWith(
            (ref) async => 100,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: EnhanceDialog(equipment: eq, def: def)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('龙泉剑'), findsOneWidget,
        reason: 'EnhanceDialog header 应渲染 def.name');
  });
}

/// 测试用 Rng：固定 nextDouble 返回值，nextInt/pick 兜底。
class _StubRng implements Rng {
  final double _value;
  _StubRng(this._value);

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => _value;

  @override
  T pick<T>(List<T> list) => list.first;
}
