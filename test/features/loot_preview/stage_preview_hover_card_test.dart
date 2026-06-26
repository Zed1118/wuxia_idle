import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/stage_preview_card.dart';

/// StagePreviewHoverCard 行为测:鼠标悬停弹浮层,且浮层 IgnorePointer 不拦指针。
///
/// 回归锚(2026-06-26 用户反馈):浮层向下盖住后续关卡行,若浮层吃鼠标,从本关
/// 下移到下一关时鼠标"进到浮层"→本关被拉回、下一关 enter 不到(切不动 + 卡顿)。
/// IgnorePointer 后浮层纯展示,鼠标穿透到下一关行 → 切换丝滑。
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: StagePreviewHoverCard(
              preview: Text('掉落预览内容'),
              child: SizedBox(
                key: ValueKey('hover_child'),
                width: 200,
                height: 40,
                child: Text('第一关'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('悬停 → 弹浮层 + 浮层被 IgnorePointer 包裹(不拦指针)', (tester) async {
    await pump(tester);

    // 初始未悬停 → 浮层不显。
    expect(find.text('掉落预览内容'), findsNothing);

    final gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('hover_child'))));
    await tester.pumpAndSettle();

    // 悬停 → 浮层显示。
    expect(find.text('掉落预览内容'), findsOneWidget);
    // 浮层内容被 ignoring:true 的 IgnorePointer 包裹 → 不拦鼠标(框架自带的
    // IgnorePointer 均 ignoring:false,精确匹配我们加的那个),移到下一关可正常切换。
    expect(
      find.ancestor(
        of: find.text('掉落预览内容'),
        matching:
            find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
      ),
      findsOneWidget,
      reason: '浮层须 IgnorePointer(ignoring:true) 纯展示,否则盖住下一关致切不动/卡顿',
    );

    // 移出 → 浮层收起。
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('掉落预览内容'), findsNothing);
  });
}
