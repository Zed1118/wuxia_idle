import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/ink_empty_state.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders title body icon and optional action', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      host(
        InkEmptyState(
          variant: InkEmptyStateVariant.empty,
          title: '暂无资源',
          body: '此处尚无可显示内容',
          icon: Icons.inventory_2_outlined,
          actionLabel: '重试',
          onAction: () => tapped++,
        ),
      ),
    );

    expect(find.text('暂无资源'), findsOneWidget);
    expect(find.text('此处尚无可显示内容'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    expect(tapped, 1);
  });

  testWidgets('locked variant defaults to lock icon when icon is omitted', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const InkEmptyState(
          variant: InkEmptyStateVariant.locked,
          title: '待解锁',
          body: '修行未至',
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('待解锁'), findsOneWidget);
    expect(find.text('修行未至'), findsOneWidget);
  });

  testWidgets(
    'unavailable variant renders without action when action omitted',
    (tester) async {
      await tester.pumpWidget(
        host(
          const InkEmptyState(
            variant: InkEmptyStateVariant.unavailable,
            title: '暂不可用',
            body: '数据暂未备妥',
          ),
        ),
      );

      expect(find.byIcon(Icons.hourglass_empty_outlined), findsOneWidget);
      expect(find.text('暂不可用'), findsOneWidget);
      expect(find.text('数据暂未备妥'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    },
  );
}
