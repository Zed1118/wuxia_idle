import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// M2 范围 B 被动离线告知卡渲染测试。
///
/// 验证：展示产量数字 + 无「前去收功/领取」等留存诱导按钮（守 §5.1）。
void main() {
  testWidgets('被动卡展示产量 + 仅一个关闭按钮(无领取)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineRecapCard.passive(
            mojianshi: 2,
            experience: 250,
            awayHours: 10,
            settledHours: 10,
            isCapped: false,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 标题含「精进」字样（passiveRecapTitle）
    expect(find.textContaining('精进'), findsOneWidget);

    // 正文含产量数字
    expect(find.textContaining('磨剑石'), findsWidgets);
    expect(find.textContaining('2'), findsWidgets);
    expect(find.textContaining('250'), findsWidgets);
    expect(find.textContaining('银两：0'), findsOneWidget);
    expect(find.textContaining('掉落：无'), findsOneWidget);

    // 无「前去收功/领取」等留存诱导按钮（守 §5.1）
    expect(find.textContaining('收功'), findsNothing);
    expect(find.textContaining('领取'), findsNothing);
    expect(find.textContaining('前去'), findsNothing);

    // 只有一个关闭按钮（passiveRecapDismiss = '甚好'）
    expect(find.text(UiStrings.passiveRecapDismiss), findsOneWidget);
  });

  testWidgets('被动卡点「甚好」触发 onDismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineRecapCard.passive(
            mojianshi: 5,
            experience: 100,
            awayHours: 3,
            settledHours: 3,
            isCapped: false,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.passiveRecapDismiss));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('被动卡不含 offlineRecapTitle（归来）——与范围A卡文案隔离', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineRecapCard.passive(
            mojianshi: 3,
            experience: 80,
            awayHours: 6,
            settledHours: 6,
            isCapped: false,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 范围 B 卡标题应与范围 A「归来」不同
    expect(find.text(UiStrings.offlineRecapTitle), findsNothing);
    // 范围 B 卡展示 passiveRecapTitle
    expect(find.text(UiStrings.passiveRecapTitle), findsOneWidget);
  });

  testWidgets('被动卡显示封顶截断原因', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineRecapCard.passive(
            mojianshi: 18,
            experience: 1800,
            awayHours: 100,
            settledHours: 72,
            isCapped: true,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('离线时长：100 小时'), findsOneWidget);
    expect(find.textContaining('有效结算：72 小时'), findsOneWidget);
    expect(
      find.textContaining(UiStrings.offlineRecapLimitSystemCap),
      findsOneWidget,
    );
  });

  testWidgets('被动卡零收益仍有明细兜底', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineRecapCard.passive(
            mojianshi: 0,
            experience: 0,
            awayHours: 0.1,
            settledHours: 0.1,
            isCapped: false,
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('材料：无'), findsOneWidget);
    expect(find.textContaining('经验：0'), findsOneWidget);
    expect(
      find.text(UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapNoDrop)),
      findsOneWidget,
    );
  });
}
