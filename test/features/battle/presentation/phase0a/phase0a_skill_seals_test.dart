import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_skill_seals.dart';

const _gatherKey = ValueKey('phase0a_seal_gather');
const _clearKey = ValueKey('phase0a_seal_clear');

Phase0aSkillSlot _slot(
  String slot, {
  double cooldownRemaining = 0,
  int qiCost = 5,
  Phase0aSkillAvailability availability = Phase0aSkillAvailability.ready,
}) => Phase0aSkillSlot(
  slot: slot,
  cooldownRemaining: cooldownRemaining,
  qiCost: qiCost,
  availability: availability,
);

Widget _harness({
  Phase0aSkillSlot? gather,
  Phase0aSkillSlot? clear,
  int qiCurrent = 10,
  VoidCallback? onGather,
  VoidCallback? onClear,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: Phase0aSkillSeals(
        gatherSlot: gather ?? _slot('gather'),
        clearSlot: clear ?? _slot('clear'),
        qiCurrent: qiCurrent,
        onGather: onGather ?? () {},
        onClear: onClear ?? () {},
      ),
    ),
  ),
);

void main() {
  group('Phase0aSkillSeals 结构', () {
    testWidgets('gather/clear 两枚印章存在且尺寸相等', (tester) async {
      await tester.pumpWidget(_harness());

      expect(find.byKey(_gatherKey), findsOneWidget);
      expect(find.byKey(_clearKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(_gatherKey)),
        equals(tester.getSize(find.byKey(_clearKey))),
      );
    });
  });

  group('ready 态', () {
    testWidgets('两枚 ready 印均 enabled 且鼠标点击触发回调', (tester) async {
      var gatherTaps = 0;
      var clearTaps = 0;
      await tester.pumpWidget(
        _harness(onGather: () => gatherTaps++, onClear: () => clearTaps++),
      );

      await tester.tap(find.byKey(_gatherKey));
      await tester.pump();
      expect(gatherTaps, 1);
      expect(clearTaps, 0);

      await tester.tap(find.byKey(_clearKey));
      await tester.pump();
      expect(clearTaps, 1);
    });

    testWidgets('ready 印 Semantics enabled', (tester) async {
      await tester.pumpWidget(_harness());

      expect(
        tester.getSemantics(find.byKey(_gatherKey)),
        matchesSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(_clearKey)),
        matchesSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
    });
  });

  group('cooldown 态', () {
    testWidgets('显示剩余秒数、禁用、点击不触发', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          gather: _slot(
            'gather',
            cooldownRemaining: 4.5,
            availability: Phase0aSkillAvailability.cooldown,
          ),
          onGather: () => taps++,
        ),
      );

      expect(find.textContaining('4.5'), findsOneWidget);

      await tester.tap(find.byKey(_gatherKey));
      await tester.pump();
      expect(taps, 0);

      expect(
        tester.getSemantics(find.byKey(_gatherKey)),
        matchesSemantics(isButton: true, isEnabled: false),
      );
    });
  });

  group('qi 态', () {
    testWidgets('显示当前/所需真气、禁用、点击不触发', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          qiCurrent: 2,
          gather: _slot(
            'gather',
            qiCost: 5,
            availability: Phase0aSkillAvailability.qi,
          ),
          onGather: () => taps++,
        ),
      );

      expect(find.textContaining('2/5'), findsOneWidget);

      await tester.tap(find.byKey(_gatherKey));
      await tester.pump();
      expect(taps, 0);

      expect(
        tester.getSemantics(find.byKey(_gatherKey)),
        matchesSemantics(isButton: true, isEnabled: false),
      );
    });
  });

  group('casting / down 态', () {
    testWidgets('casting 有明确文案且禁用', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          gather: _slot(
            'gather',
            availability: Phase0aSkillAvailability.casting,
          ),
          onGather: () => taps++,
        ),
      );

      expect(find.textContaining('施放'), findsOneWidget);

      await tester.tap(find.byKey(_gatherKey));
      await tester.pump();
      expect(taps, 0);

      expect(
        tester.getSemantics(find.byKey(_gatherKey)),
        matchesSemantics(isButton: true, isEnabled: false),
      );
    });

    testWidgets('down 有明确文案且禁用', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          gather: _slot('gather', availability: Phase0aSkillAvailability.down),
          onGather: () => taps++,
        ),
      );

      expect(find.textContaining('倒地'), findsOneWidget);

      await tester.tap(find.byKey(_gatherKey));
      await tester.pump();
      expect(taps, 0);

      expect(
        tester.getSemantics(find.byKey(_gatherKey)),
        matchesSemantics(isButton: true, isEnabled: false),
      );
    });
  });

  group('键盘交互', () {
    testWidgets('Tab 焦点顺序 gather → clear,Enter 激活当前焦点', (tester) async {
      var gatherTaps = 0;
      var clearTaps = 0;
      await tester.pumpWidget(
        _harness(onGather: () => gatherTaps++, onClear: () => clearTaps++),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(gatherTaps, 1);
      expect(clearTaps, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(gatherTaps, 1);
      expect(clearTaps, 1);
    });

    testWidgets('Space 激活焦点印', (tester) async {
      var gatherTaps = 0;
      await tester.pumpWidget(_harness(onGather: () => gatherTaps++));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(gatherTaps, 1);
    });

    testWidgets('禁用印不可聚焦激活(Tab 跳过/Enter 不触发)', (tester) async {
      var gatherTaps = 0;
      var clearTaps = 0;
      await tester.pumpWidget(
        _harness(
          gather: _slot(
            'gather',
            cooldownRemaining: 3,
            availability: Phase0aSkillAvailability.cooldown,
          ),
          onGather: () => gatherTaps++,
          onClear: () => clearTaps++,
        ),
      );

      // 第一个 Tab 应直接落到 clear(gather 被禁用跳过)。
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(gatherTaps, 0);
      expect(clearTaps, 1);
    });
  });
}
