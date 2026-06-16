import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_entry_detail.dart';
import 'package:wuxia_idle/features/help/domain/help_topic.dart';
import 'package:wuxia_idle/features/help/presentation/context_help_button.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 上下文帮助系统 · ContextHelpButton 行为契约（2026-06-16）。
///
/// 三态:① 无 codex 条目 → 仅 tooltip;② 已解锁 → 可跳百科;③ 未解锁 → 灰显不可点。
/// 解锁 gating 走既有 `currentTutorialStepProvider`（override）+ `CodexIndex` step。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    required HelpTopic topic,
    required int step,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith((ref) async => step),
        ],
        child: MaterialApp(
          home: Scaffold(body: Center(child: ContextHelpButton(topic: topic))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('codexEntryId == null（属性 topic）→ 仅 tooltip，无导航 InkWell', (tester) async {
    await pump(tester, topic: HelpTopic.constitution, step: 8);

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    final tip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tip.message, UiStrings.glossaryConstitution);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('codex topic 已解锁（step=8）→ 可点击跳 CodexEntryDetail', (tester) async {
    await pump(tester, topic: HelpTopic.realm, step: 8);

    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.byType(CodexEntryDetail), findsOneWidget);
  });

  testWidgets('codex topic 未解锁（step=0）→ 灰显 + 阅历未至 tooltip + 不可点', (tester) async {
    await pump(tester, topic: HelpTopic.realm, step: 0);

    final tip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tip.message, UiStrings.contextHelpLocked);
    expect(find.byType(InkWell), findsNothing);
  });
}
