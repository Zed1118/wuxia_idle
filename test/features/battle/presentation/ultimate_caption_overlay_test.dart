import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';

SkillDef _skill(SkillType type) => SkillDef(
      id: 't',
      name: '测试招',
      description: '',
      type: type,
      powerMultiplier: 100,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      parentTechniqueDefId: null,
      visualEffect: '',
    );

void main() {
  test('ultimate / jointSkill → true', () {
    expect(isUltimateCaptionSkill(_skill(SkillType.ultimate)), true);
    expect(isUltimateCaptionSkill(_skill(SkillType.jointSkill)), true);
  });

  test('normalAttack / powerSkill / null → false', () {
    expect(isUltimateCaptionSkill(_skill(SkillType.normalAttack)), false);
    expect(isUltimateCaptionSkill(_skill(SkillType.powerSkill)), false);
    expect(isUltimateCaptionSkill(null), false);
  });

  testWidgets('UltimateCaptionContent 显示招式名', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UltimateCaptionContent(name: '山岳崩', isEnemy: false),
      ),
    ));
    expect(find.text('山岳崩'), findsNWidgets(2));
  });

  testWidgets('overlay show() 显示 + 二次 show() 覆盖前者', (tester) async {
    final key = GlobalKey<UltimateCaptionOverlayState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: UltimateCaptionOverlay(key: key)),
    ));
    expect(find.byType(UltimateCaptionContent), findsNothing);

    key.currentState!.show('天问', isEnemy: false);
    await tester.pump();
    expect(find.text('天问'), findsNWidgets(2));

    key.currentState!.show('飞雪', isEnemy: true);
    await tester.pump();
    expect(find.text('飞雪'), findsNWidgets(2));
    expect(find.text('天问'), findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('敌方绛红态 + asset 缺失走 errorBuilder 不崩', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UltimateCaptionContent(name: '破！', isEnemy: true),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('破！'), findsNWidgets(2));
  });
}
