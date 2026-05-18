import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_entry_detail.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_tab.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1 #42 Phase 2 §10 P1.z CodexTab 红线契约。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Future<void> pumpCodexTab(WidgetTester tester, {required int step}) async {
    // 扩 viewport 让 9 行 ListView 全部渲染(默认 800x600 装不下)
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentTutorialStepProvider.overrideWith((ref) async => step),
      ],
      child: const MaterialApp(home: Scaffold(body: CodexTab())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('全锁(step=0):8 条全显「待解锁」+ 锁图标 + 已解锁 0 / 8', (tester) async {
    await pumpCodexTab(tester, step: 0);
    expect(find.text(UiStrings.codexLockedTitle), findsNWidgets(8));
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(8));
    expect(find.text(UiStrings.codexUnlockedHint(0, 8)), findsOneWidget);
  });

  testWidgets('部分解锁(step=5):前 5 条解锁 + 后 3 条灰显', (tester) async {
    await pumpCodexTab(tester, step: 5);
    // 已加载 7 条 md(档 8 缺),step=5 解锁 1-5 共 5 条 + 6/7/8 各 1 灰显
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
    expect(find.text(UiStrings.codexUnlockedHint(5, 8)), findsOneWidget);
  });

  testWidgets('全解锁(step=8):7 条 md 已加载条目全显 + 档 8 缺仍灰显', (tester) async {
    await pumpCodexTab(tester, step: 8);
    // 档 8 md (combat_advanced) DeepSeek 派单前缺失,仍走灰显占位
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text(UiStrings.codexUnlockedHint(8, 8)), findsOneWidget);
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
}
