import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/tutorial/domain/tutorial_hint_def.dart';

/// P1 #42 Phase 2 §10 P1.y · TutorialHintDef 表驱动红线契约。
///
/// 验证(memory `feedback_red_line_test_semantics`):
/// - all 升序覆盖 step 3/5/6/7/8(§5.7 合规:仅「新系统解锁锚点」,跳过 1/2/4 纯进度)
/// - title / body 非空 + 长度落 GDD §10.2 50-100 字"短介绍"语义
/// - byStep 命中有 def 的 step,无 def 的 step 返回 null(widget 端兜底跳过渲染)
void main() {
  test('TutorialHintDef.all 升序覆盖 step 3/5/6/7/8(§5.7 系统解锁锚点)', () {
    expect(TutorialHintDef.all.length, 5);
    expect(TutorialHintDef.all.map((d) => d.step).toList(), [3, 5, 6, 7, 8]);
  });

  test('每条 hint 必有 title + body + iconData', () {
    for (final def in TutorialHintDef.all) {
      expect(def.title, isNotEmpty, reason: 'step ${def.step} title 不应空');
      expect(def.body, isNotEmpty, reason: 'step ${def.step} body 不应空');
      expect(def.iconData, isA<IconData>());
    }
  });

  test('body 长度 30-120 字(GDD §10.2 50-100 字短介绍范围,放宽 ±20)', () {
    for (final def in TutorialHintDef.all) {
      expect(def.body.length, greaterThanOrEqualTo(30),
          reason: 'step ${def.step} body 太短');
      expect(def.body.length, lessThanOrEqualTo(120),
          reason: 'step ${def.step} body 太长');
    }
  });

  test('byStep(3/5/6/7/8) 命中', () {
    expect(TutorialHintDef.byStep(3)?.step, 3);
    expect(TutorialHintDef.byStep(5)?.step, 5);
    expect(TutorialHintDef.byStep(6)?.step, 6);
    expect(TutorialHintDef.byStep(7)?.step, 7);
    expect(TutorialHintDef.byStep(8)?.step, 8);
  });

  test('byStep 无 def 的 step(1/2/4/9/0/-1)→ null', () {
    expect(TutorialHintDef.byStep(1), isNull);
    expect(TutorialHintDef.byStep(2), isNull);
    expect(TutorialHintDef.byStep(4), isNull);
    expect(TutorialHintDef.byStep(9), isNull);
    expect(TutorialHintDef.byStep(0), isNull);
    expect(TutorialHintDef.byStep(-1), isNull);
  });

  test('step3/5/6/7/8 const-canonical 单例(byStep 返回同实例)', () {
    expect(identical(TutorialHintDef.byStep(3), TutorialHintDef.step3), isTrue);
    expect(identical(TutorialHintDef.byStep(5), TutorialHintDef.step5), isTrue);
    expect(identical(TutorialHintDef.byStep(6), TutorialHintDef.step6), isTrue);
    expect(identical(TutorialHintDef.byStep(7), TutorialHintDef.step7), isTrue);
    expect(identical(TutorialHintDef.byStep(8), TutorialHintDef.step8), isTrue);
  });
}
