import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_map_list_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_setup_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T49 · 闭关 UI widget 测试。
///
/// 覆盖：
///   1. SeclusionMapListScreen 列表渲染 5 张地图
///   2. locked 卡片无 onTap 响应（学徒点古剑冢不导航）
///   3. SeclusionSetupScreen 显示地图名 + 时长选择按钮
///
/// 不依赖 Isar：FutureBuilder 的 getActiveSession future 会在 pump 后完成
/// 并以 snap.hasError 静默处理（active = null）。
/// SeclusionSetupScreen 直接注入 mapDef，无需 Isar。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Future<void> pumpMapList(
    WidgetTester tester, {
    RealmTier charRealmTier = RealmTier.xueTu,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SeclusionMapListScreen(
            charRealmTier: charRealmTier,
            characterId: 1,
          ),
        ),
      ),
    );
    // 一次 pump 触发 FutureBuilder 初始构建，getActiveSession 错误被 snap.error 静默捕获
    await tester.pump();
  }

  // ─── Test 1 ───────────────────────────────────────────────────────────────

  testWidgets('列表渲染 5 张地图', (tester) async {
    await pumpMapList(tester);

    expect(find.text('山林'), findsOneWidget);
    expect(find.text('古剑冢'), findsOneWidget);
    expect(find.text('藏经阁'), findsOneWidget);
    expect(find.text('悬崖瀑布'), findsOneWidget);
    expect(find.text('断崖绝壁'), findsOneWidget);
  });

  // ─── Test 2 ───────────────────────────────────────────────────────────────

  testWidgets('locked 卡片无 onTap 响应（学徒点古剑冢不导航）', (tester) async {
    await pumpMapList(tester, charRealmTier: RealmTier.xueTu);

    // 古剑冢需三流境界，学徒无法进入 → _MapCard.onTap == null
    await tester.tap(find.text('古剑冢'));
    await tester.pump();

    // 仍在地图列表
    expect(find.byType(SeclusionSetupScreen), findsNothing);
    expect(find.text(UiStrings.seclusionTitle), findsOneWidget);
  });

  // ─── Test 3 ───────────────────────────────────────────────────────────────
  // SeclusionSetupScreen 直接注入 mapDef（不依赖 Isar 的导航流）

  testWidgets('SeclusionSetupScreen 显示地图名和时长选择按钮', (tester) async {
    final def = GameRepository.instance.getSeclusionMap(RetreatMapType.shanLin);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SeclusionSetupScreen(
            mapDef: def,
            charRealmTier: RealmTier.xueTu,
            characterId: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    // AppBar 标题为地图名
    expect(find.text(def.mapName), findsWidgets);
    // 时长选择按钮（3 档：1h / 4h / 12h）
    final durations = GameRepository.instance.numbers.retreat.durationHours;
    for (final h in durations) {
      expect(
        find.text(UiStrings.seclusionDurationLabel(h)),
        findsOneWidget,
        reason: '${h}h 时长按钮应可见',
      );
    }
    // 开始按钮可见
    expect(find.text(UiStrings.seclusionSetupStartButton), findsOneWidget);
  });

  // ─── Test 4（任务9·A 方案）─────────────────────────────────────────────────
  // locked 卡显示真实境界门槛 + 当前境界对比；闭关入图仅境界一维门控,
  // 不显示伪造的章节/材料门槛。

  testWidgets('locked 卡显示需要境界与当前境界对比', (tester) async {
    await pumpMapList(tester, charRealmTier: RealmTier.xueTu);

    final guJian = GameRepository.instance.getSeclusionMap(
      RetreatMapType.guJianZhong,
    );
    final expected = UiStrings.seclusionRequiredRealmWithCurrent(
      EnumL10n.realmTier(guJian.requiredRealm),
      EnumL10n.realmTier(RealmTier.xueTu),
    );

    expect(find.text(expected), findsWidgets);
    expect(find.textContaining('当前 '), findsWidgets);
  });

  testWidgets('locked 卡不显示伪造的章节/材料门槛', (tester) async {
    await pumpMapList(tester, charRealmTier: RealmTier.xueTu);

    // 闭关入图实际只有境界门控（canEnterMap 仅比 realm）,不得编造章节/材料条件。
    expect(find.textContaining('第一章通关后开放'), findsNothing);
    expect(find.textContaining('无额外消耗'), findsNothing);
    expect(find.textContaining('章节：'), findsNothing);
    expect(find.textContaining('材料：'), findsNothing);
  });

}
