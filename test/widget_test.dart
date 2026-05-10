import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/main.dart';

void main() {
  testWidgets('启动屏显示「启动成功」', (WidgetTester tester) async {
    await tester.pumpWidget(const WuxiaApp());
    expect(find.text('启动成功'), findsOneWidget);
  });
}
