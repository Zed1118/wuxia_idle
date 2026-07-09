import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_image.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('缺图且未传 errorBuilder 时默认静默收起不抛异常', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 40,
          height: 40,
          child: WuxiaImage('assets/missing/wuxia_image_default.png'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('显式 errorBuilder 优先于默认缺图兜底', (tester) async {
    await tester.pumpWidget(
      host(
        WuxiaImage(
          'assets/missing/wuxia_image_custom.png',
          errorBuilder: (_, _, _) => const Text('custom fallback'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('custom fallback'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('imageDecodeCacheWidth 量化到 64px 桶，非法宽度不限制', () {
    expect(imageDecodeCacheWidth(10, 2), 64);
    expect(imageDecodeCacheWidth(65, 2), 192);
    expect(imageDecodeCacheWidth(double.infinity, 2), isNull);
    expect(imageDecodeCacheWidth(0, 2), isNull);
  });
}
