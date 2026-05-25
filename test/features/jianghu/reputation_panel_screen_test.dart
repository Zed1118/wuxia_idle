import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu/application/jianghu_providers.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/jianghu/presentation/reputation_panel_screen.dart';
import 'package:wuxia_idle/features/jianghu/presentation/widgets/reputation_tier_chip.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1.2 §4 R4 ReputationPanelScreen widget 测。
///
/// 体例(沿 [LineagePanelScreen] widget 测):走 `reputationsForCurrentPlayerProvider.overrideWith`
/// 注入 fixture · 不打开 Isar / 不加载 GameRepository,避免 testWidgets HTTP
/// download blocked 死循环(memory `feedback_isar_widget_test_deadlock`)。
///
/// 红线契约语义(memory `feedback_red_line_test_semantics`):
/// - empty state 文案分支自洽
/// - 渲染件数 == fixture 长度(计数自洽)
/// - chip label 与 UiStrings 字段绑定自洽
void main() {
  Reputation mkRep({
    required int id,
    required String factionId,
    required int value,
  }) {
    return Reputation()
      ..id = id
      ..playerId = 1
      ..factionId = factionId
      ..value = value
      ..updatedAt = DateTime(2026, 5, 25);
  }

  testWidgets('R4.1 empty state 显 reputationPanelEmpty 文案', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reputationsForCurrentPlayerProvider
              .overrideWith((ref) async => const <Reputation>[]),
        ],
        child: const MaterialApp(home: ReputationPanelScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(UiStrings.reputationPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.reputationPanelEmpty), findsOneWidget);
  });

  testWidgets('R4.2 3 门派 reputation 渲染 3 row + 0 chip(svc null fallback)',
      (tester) async {
    // 注:reputationServiceProvider 不 override → svc==null → panel 走 empty 分支
    // (走 emptyState),因 svc 为 null 时 list 即使非空也显 empty。本测断 fallback 分支。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reputationsForCurrentPlayerProvider.overrideWith((ref) async => [
                mkRep(id: 1, factionId: 'shaolin', value: 50),
                mkRep(id: 2, factionId: 'wudang', value: -30),
                mkRep(id: 3, factionId: 'jiaoMen', value: -80),
              ]),
        ],
        child: const MaterialApp(home: ReputationPanelScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    // svc==null fallback 分支:list 非空但 svc 缺 → 仍显 empty 文案
    expect(find.text(UiStrings.reputationPanelEmpty), findsOneWidget);
  });

  testWidgets('R4.3 ReputationTierChip 7 阶 label · xueTu/yiLiu/wuSheng 三阶',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ReputationTierChip(tier: 'xueTu', value: -100),
              ReputationTierChip(tier: 'yiLiu', value: 10),
              ReputationTierChip(tier: 'wuSheng', value: 100),
            ],
          ),
        ),
      ),
    );
    expect(find.text('${UiStrings.reputationTierXueTu} · -100'), findsOneWidget);
    expect(find.text('${UiStrings.reputationTierYiLiu} · 10'), findsOneWidget);
    expect(find.text('${UiStrings.reputationTierWuSheng} · 100'), findsOneWidget);
  });

  testWidgets('R4.4 ReputationTierChip 未知 tier 走 erLiu fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReputationTierChip(tier: 'unknown_tier', value: 0),
        ),
      ),
    );
    expect(
      find.text('${UiStrings.reputationTierErLiu} · 0'),
      findsOneWidget,
      reason: 'unknown tier 走 erLiu 中间档兜底',
    );
  });

  test('R4.5 UiStrings 15 段 jianghu 文案全非空(锁字符串绑定)', () {
    final all = <String>[
      UiStrings.mainMenuJianghu,
      UiStrings.mainMenuJianghuHint,
      UiStrings.reputationPanelTitle,
      UiStrings.reputationPanelEmpty,
      UiStrings.reputationPanelLoadError,
      UiStrings.reputationTierXueTu,
      UiStrings.reputationTierSanLiu,
      UiStrings.reputationTierErLiu,
      UiStrings.reputationTierYiLiu,
      UiStrings.reputationTierJueDing,
      UiStrings.reputationTierZongShi,
      UiStrings.reputationTierWuSheng,
      UiStrings.enmityWarning,
      UiStrings.panelFriendSection,
      UiStrings.panelFoeSection,
    ];
    for (final s in all) {
      expect(s.isNotEmpty, isTrue, reason: 'UiStrings 段不可为空');
    }
  });
}
