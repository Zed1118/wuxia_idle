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
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_dialog.dart';

/// 上下文帮助系统 · ContextHelpButton 行为契约（2026-06-19 改：三态全部可点）。
///
/// 三态:① 无 codex 条目 → 点击弹短释义浮层;② 已解锁 → 点击跳百科;
/// ③ 未解锁 → 灰显 + 点击弹「阅历未至」反馈。点击热区 ≥ 36px。
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

  testWidgets('codexEntryId == null（属性 topic）→ hover tooltip + 点击弹短释义浮层', (tester) async {
    await pump(tester, topic: HelpTopic.constitution, step: 8);

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    final tip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tip.message, UiStrings.glossaryConstitution);

    // 三态全部可点：无 codex → 点击弹释义。
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.byType(PaperDialog), findsOneWidget);
    expect(find.text(UiStrings.glossaryConstitution), findsWidgets);
  });

  testWidgets('codex topic 已解锁（step=8）→ 可点击跳 CodexEntryDetail', (tester) async {
    await pump(tester, topic: HelpTopic.realm, step: 8);

    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.byType(CodexEntryDetail), findsOneWidget);
  });

  testWidgets('codex topic 未解锁（step=0）→ 灰显 + 点击弹「阅历未至」反馈', (tester) async {
    await pump(tester, topic: HelpTopic.realm, step: 0);

    final tip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tip.message, UiStrings.contextHelpLocked);

    // 未解锁也可点：给反馈而非死按钮。
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.byType(PaperDialog), findsOneWidget);
    expect(find.text(UiStrings.contextHelpLocked), findsWidgets);
  });

  testWidgets('点击热区 ≥ 36px（原仅图标 ~18px 太难命中）', (tester) async {
    await pump(tester, topic: HelpTopic.constitution, step: 8);

    final size = tester.getSize(find.byType(InkWell));
    expect(size.width, greaterThanOrEqualTo(36));
    expect(size.height, greaterThanOrEqualTo(36));
  });
}
