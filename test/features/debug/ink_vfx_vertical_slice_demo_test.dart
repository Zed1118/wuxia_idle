import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/presentation/ink_vfx_vertical_slice_demo.dart';

void main() {
  Future<void> pumpDemo(
    WidgetTester tester, {
    InkVfxSlice initialSlice = InkVfxSlice.light,
    Size size = const Size(1280, 720),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: InkVfxVerticalSliceDemo(
          initialSlice: initialSlice,
          autoReplay: false,
        ),
      ),
    );
    await tester.pump();
  }

  InkVfxEffectPainter painterFor(WidgetTester tester, InkVfxSlice slice) {
    final paint = tester.widget<CustomPaint>(
      find.byKey(ValueKey('ink_vfx_effect_${slice.name}')),
    );
    return paint.painter! as InkVfxEffectPainter;
  }

  testWidgets('三种样片可切换并重播', (tester) async {
    await pumpDemo(tester);

    expect(find.byKey(const ValueKey('ink_vfx_vertical_slice_demo')), findsOne);
    expect(find.byKey(const ValueKey('ink_vfx_selector_light')), findsOne);
    expect(find.byKey(const ValueKey('ink_vfx_selector_interrupt')), findsOne);
    expect(find.byKey(const ValueKey('ink_vfx_selector_domain')), findsOne);
    expect(find.byKey(const ValueKey('ink_vfx_effect_light')), findsOne);

    await tester.pump(const Duration(milliseconds: 180));
    expect(painterFor(tester, InkVfxSlice.light).progress, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('ink_vfx_replay')));
    await tester.pump();
    expect(painterFor(tester, InkVfxSlice.light).progress, closeTo(0, 0.001));

    await tester.tap(find.byKey(const ValueKey('ink_vfx_selector_interrupt')));
    await tester.pump();
    expect(find.byKey(const ValueKey('ink_vfx_effect_interrupt')), findsOne);

    await tester.tap(find.byKey(const ValueKey('ink_vfx_selector_domain')));
    await tester.pump();
    expect(find.byKey(const ValueKey('ink_vfx_effect_domain')), findsOne);
  });

  testWidgets('三个初始 route 样片均能构建', (tester) async {
    for (final slice in InkVfxSlice.values) {
      await pumpDemo(tester, initialSlice: slice);
      expect(find.byKey(ValueKey('ink_vfx_effect_${slice.name}')), findsOne);
      expect(tester.takeException(), isNull, reason: slice.name);
    }
  });

  testWidgets('常规桌面视口无布局异常', (tester) async {
    for (final size in const [Size(1280, 720), Size(1440, 900)]) {
      await pumpDemo(tester, initialSlice: InkVfxSlice.domain, size: size);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
