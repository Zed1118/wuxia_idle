import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/codex/domain/codex_category.dart';
import 'package:wuxia_idle/features/codex/domain/codex_index.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_entry_detail.dart';
import 'package:wuxia_idle/features/codex/application/codex_providers.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_tab.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1 #42 Phase 2 §10 P1.z CodexTab 红线契约。
///
/// P2 扩段后:8 档机制(P1.z 8 + A 组 4 = 12 条)+ 江湖背景 7 lore = 19 条。
/// 机制条目按 tutorialStep gating;lore 永远 unlocked(GDD §10.2 永久可查)。
void main() {
  // 语义化断言依赖动态计数,不写死 12/7 防止 P3+ 扩段后 break。
  final mechanicCount = CodexIndex.entries
      .where((e) => e.category.isMechanic)
      .length;
  final loreCount = CodexIndex.entries.where((e) => e.category.isLore).length;

  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Future<void> pumpCodexTab(
    WidgetTester tester, {
    required int step,
    Size surfaceSize = const Size(800, 3000),
  }) async {
    // 扩 viewport 让 21 行 ListView 全部渲染(默认 800x600 装不下);
    // memory feedback_listview_widget_test_viewport。
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith((ref) async => step),
        ],
        child: const MaterialApp(home: Scaffold(body: CodexTab())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('全锁(step=0):机制段全显「待解锁」+ lore 段永远可查 + 已解锁 0 / 8', (tester) async {
    await pumpCodexTab(tester, step: 0);
    expect(find.text(UiStrings.codexLockedTitle), findsNWidgets(mechanicCount));
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(mechanicCount));
    expect(find.text(UiStrings.codexUnlockedHint(0, 8)), findsOneWidget);
    expect(find.text(UiStrings.codexMechanicSectionTitle), findsOneWidget);
    expect(find.text(UiStrings.codexMechanicSectionSubtitle), findsOneWidget);
    expect(
      find.text(UiStrings.codexLockedStatus),
      findsNWidgets(mechanicCount),
    );
    // lore 段永远 unlocked,SectionHeader 渲染
    expect(find.text(UiStrings.codexLoreSectionTitle), findsOneWidget);
    expect(find.text(UiStrings.codexLoreSectionSubtitle), findsOneWidget);
  });

  testWidgets('部分解锁(step=5):机制 1-5 档解锁 + 6/7/8 档灰显 + lore 段不受 step 影响', (
    tester,
  ) async {
    await pumpCodexTab(tester, step: 5);
    // 机制条目按 step gating:6/7/8 档 3 条灰显(每档 1 条机制条目,A 组无挂这 3 档)
    final lockedMechanic = CodexIndex.entries
        .where((e) => e.category.isMechanic && (e.step ?? 0) > 5)
        .length;
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(lockedMechanic));
    expect(find.text(UiStrings.codexUnlockedHint(5, 8)), findsOneWidget);
    expect(find.text(UiStrings.codexLoreSectionTitle), findsOneWidget);
  });

  testWidgets('全解锁(step=8):机制段 0 灰显 + lore 段全显 + 已解锁 8 / 8', (tester) async {
    await pumpCodexTab(tester, step: 8);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text(UiStrings.codexUnlockedHint(8, 8)), findsOneWidget);
    expect(find.text(UiStrings.codexUnlockedStatus), findsWidgets);
    expect(find.text(UiStrings.codexLoreSectionTitle), findsOneWidget);
  });

  testWidgets('点击解锁条目 → push CodexEntryDetail', (tester) async {
    await pumpCodexTab(tester, step: 1);
    // step=1 → realm.md「境界」解锁
    expect(find.text('境界'), findsOneWidget);
    await tester.tap(find.text('境界'));
    await tester.pumpAndSettle();
    expect(find.byType(CodexEntryDetail), findsOneWidget);
  });

  testWidgets('顶部 chip 渲染「已解锁 N / 8」', (tester) async {
    await pumpCodexTab(tester, step: 3);
    expect(find.text(UiStrings.codexUnlockedHint(3, 8)), findsOneWidget);
  });

  // ── P2 扩段新增 ─────────────────────────────────────────────────────────────

  testWidgets('P2:lore 段 SectionHeader 在机制段后渲染', (tester) async {
    await pumpCodexTab(tester, step: 8);
    final sectionFinder = find.text(UiStrings.codexLoreSectionTitle);
    expect(sectionFinder, findsOneWidget);
    // SectionHeader Y 坐标应大于第一个机制条目(realm「境界」)的 Y 坐标
    final sectionY = tester.getTopLeft(sectionFinder).dy;
    final firstMechY = tester.getTopLeft(find.text('境界')).dy;
    expect(sectionY, greaterThan(firstMechY));
  });

  testWidgets('P2:lore 段 7 条全永远 unlocked(step=0 时也可见 + 可点击)', (tester) async {
    await pumpCodexTab(tester, step: 0);
    // lore 条目「暗器与毒」永远 unlocked,显标题 + 预览
    expect(find.text('暗器与毒'), findsOneWidget);
    await tester.tap(find.text('暗器与毒'));
    await tester.pumpAndSettle();
    expect(find.byType(CodexEntryDetail), findsOneWidget);
  });

  testWidgets('P2:chip 分母固定 8(不受 lore 段影响)', (tester) async {
    expect(loreCount, greaterThan(0)); // 防 P2 扩段意外被裁
    await pumpCodexTab(tester, step: 4);
    // 即使 lore 段 7 条都显,chip 分母仍是 8,不是 8+7=15
    expect(find.text(UiStrings.codexUnlockedHint(4, 8)), findsOneWidget);
    expect(find.text(UiStrings.codexUnlockedHint(4, 15)), findsNothing);
  });

  // ── T05 Nightshift 边界 case ──────────────────────────────────────────────

  testWidgets('矩阵 step=2:chip「已解锁 2 / 8」+ lock 数=step>2 机制条目数', (tester) async {
    await pumpCodexTab(tester, step: 2);
    expect(find.text(UiStrings.codexUnlockedHint(2, 8)), findsOneWidget);
    final locked = CodexIndex.entries
        .where((e) => e.category.isMechanic && (e.step ?? 0) > 2)
        .length;
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(locked));
  });

  testWidgets('矩阵 step=4:chip「已解锁 4 / 8」+ lock 数=step>4 机制条目数', (tester) async {
    await pumpCodexTab(tester, step: 4);
    expect(find.text(UiStrings.codexUnlockedHint(4, 8)), findsOneWidget);
    final locked = CodexIndex.entries
        .where((e) => e.category.isMechanic && (e.step ?? 0) > 4)
        .length;
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(locked));
  });

  testWidgets('step=10 超出 clamp 至 8:chip「已解锁 8 / 8」无锁图标', (tester) async {
    await pumpCodexTab(tester, step: 10);
    expect(find.text(UiStrings.codexUnlockedHint(8, 8)), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('全锁 step=0:每条 locked 机制条目显示 codexLockedBody 文案', (tester) async {
    await pumpCodexTab(tester, step: 0);
    expect(find.text(UiStrings.codexLockedBody), findsNWidgets(mechanicCount));
  });

  testWidgets('step=1:step≤1 机制条目解锁,其余锁定 + chip「已解锁 1 / 8」', (tester) async {
    await pumpCodexTab(tester, step: 1);
    expect(find.text(UiStrings.codexUnlockedHint(1, 8)), findsOneWidget);
    final locked = CodexIndex.entries
        .where((e) => e.category.isMechanic && (e.step ?? 0) > 1)
        .length;
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(locked));
  });

  testWidgets('lore SectionHeader 不受 step 影响(step=1 时也渲染)', (tester) async {
    await pumpCodexTab(tester, step: 1);
    expect(find.text(UiStrings.codexLoreSectionTitle), findsOneWidget);
  });

  testWidgets('provider error fallback:step=0 不崩溃 + 机制全锁', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith(
            (ref) async => throw Exception('test error'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CodexTab())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.codexUnlockedHint(0, 8)), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(mechanicCount));
  });

  testWidgets('A 组补充阅读不计入 chip 分母(step=8 分母固定 8 非 mechanicCount)', (
    tester,
  ) async {
    await pumpCodexTab(tester, step: 8);
    expect(find.text(UiStrings.codexUnlockedHint(8, 8)), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    // A 组 4 条挂机制 category,mechanicCount > 8;分母不随 A 组增加
    if (mechanicCount != 8) {
      expect(
        find.text(UiStrings.codexUnlockedHint(mechanicCount, mechanicCount)),
        findsNothing,
      );
    }
  });

  testWidgets(
    'chip 走 [unlockedCodexCountProvider]:override provider → 5,step=2 时 chip 仍显「5 / 8」',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTutorialStepProvider.overrideWith((ref) async => 2),
            unlockedCodexCountProvider.overrideWith((ref) async => 5),
          ],
          child: const MaterialApp(home: Scaffold(body: CodexTab())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.codexUnlockedHint(5, 8)), findsOneWidget);
      // mechanic gating 仍走 step=2(provider 不影响 lock 数)
      final locked = CodexIndex.entries
          .where((e) => e.category.isMechanic && (e.step ?? 0) > 2)
          .length;
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(locked));
    },
  );

  testWidgets('viewport 800×3000:末尾 lore entry title 在渲染树中可 find', (
    tester,
  ) async {
    await pumpCodexTab(tester, step: 8);
    final lastLoreEntry = CodexIndex.entries.lastWhere(
      (e) => e.category.isLore,
    );
    final title = GameRepository.instance.codexEntries[lastLoreEntry.id]?.title;
    expect(title, isNotNull, reason: '末尾 lore md 未加载,P2 应已落齐');
    expect(find.text(title!), findsOneWidget);
  });

  testWidgets('lore 渲染顺序 = CodexIndex 登记顺序(前两条 Y 坐标升序)', (tester) async {
    await pumpCodexTab(tester, step: 8);
    final loreEntries = CodexIndex.entries
        .where((e) => e.category.isLore)
        .toList();
    if (loreEntries.length >= 2) {
      final firstTitle =
          GameRepository.instance.codexEntries[loreEntries.first.id]?.title;
      final secondTitle =
          GameRepository.instance.codexEntries[loreEntries[1].id]?.title;
      if (firstTitle != null && secondTitle != null) {
        final firstY = tester.getTopLeft(find.text(firstTitle)).dy;
        final secondY = tester.getTopLeft(find.text(secondTitle)).dy;
        expect(firstY, lessThan(secondY));
      }
    }
  });

  testWidgets('desktop smoke 1280×720:卷宗结构首屏可见且无 overflow', (tester) async {
    await pumpCodexTab(tester, step: 8, surfaceSize: const Size(1280, 720));
    expect(find.text(UiStrings.codexMechanicSectionTitle), findsOneWidget);
    expect(find.text(UiStrings.codexMechanicSectionSubtitle), findsOneWidget);
    expect(find.text('境界'), findsOneWidget);
  });
}
