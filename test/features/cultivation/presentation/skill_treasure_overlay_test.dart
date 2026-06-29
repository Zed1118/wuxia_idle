import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_drop_result.dart';
import 'package:wuxia_idle/features/cultivation/presentation/skill_treasure_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

// ─── 测试用工厂 ────────────────────────────────────────────────────────────────

SkillDropResult _manualResult({String skillId = 'skill_abc'}) =>
    SkillDropResult(manualGranted: skillId);

SkillDropResult _fragmentResult({
  String skillId = 'skill_frag',
  int count = 5,
  int threshold = 5,
}) => SkillDropResult(
  fragmentSkillId: skillId,
  fragmentCount: count,
  fragmentThreshold: threshold,
  fragmentJustUnlocked: true,
);

SkillDropResult _minorFragmentResult() => const SkillDropResult(
  fragmentSkillId: 'skill_frag',
  fragmentCount: 2,
  fragmentThreshold: 5,
  fragmentJustUnlocked: false,
);

// 供测试直接 pump 的 SkillTreasureContent（公开的 testable widget）。
// 不依赖 GameRepository（skillName / imagePath 由调用方传入）。

void main() {
  // 让 Image.asset 触发 errorBuilder 而不是抛异常（测试环境无资产）。

  group('SkillTreasureContent 渲染', () {
    testWidgets('真解首通 — 显示招式名 + 真解题字', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillTreasureContent(
              skillName: '青锋斩',
              imagePath: null,
              isManual: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('青锋斩'), findsOneWidget);
      expect(find.text(UiStrings.skillTreasureManualCaption), findsOneWidget);
      expect(find.text(UiStrings.skillTreasureScrollLabel), findsOneWidget);
      expect(find.text(UiStrings.skillTreasureManualHint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('残页集齐 — 显示招式名 + 集齐题字', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillTreasureContent(
              skillName: '残云决',
              imagePath: null,
              isManual: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('残云决'), findsOneWidget);
      expect(find.text(UiStrings.skillTreasureFragmentCaption), findsOneWidget);
      expect(find.text(UiStrings.skillTreasureFragmentHint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('imagePath 为 null — 无异常、无布局崩溃', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillTreasureContent(
              skillName: '独孤剑',
              imagePath: null,
              isManual: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('独孤剑'), findsOneWidget);
      expect(find.text(UiStrings.skillTreasureFallbackGlyph), findsOneWidget);
    });

    testWidgets('imagePath 指向不存在资产 — errorBuilder 兜底无异常', (tester) async {
      // 加宽 viewport 防 overflow
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillTreasureContent(
              skillName: '神龙剑',
              imagePath: 'assets/fake_nonexistent.png',
              isManual: true,
            ),
          ),
        ),
      );
      // 让 Image.asset 尝试加载（会进 errorBuilder）
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('神龙剑'), findsOneWidget);
    });
  });

  group('SkillTreasureOverlay 动画 + 交互', () {
    const holdMs = 3200; // > 默认 3.0s，足以推进 auto-dismiss

    testWidgets('真解结果 — 渲染招式名 + 动画 + auto-dismiss', (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillTreasureOverlay(
              skillName: '真解招式',
              imagePath: null,
              isManual: true,
              onDone: () => doneCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('真解招式'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // auto-dismiss
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCalled, isTrue);
    });

    testWidgets('点击触发 onDone，timer 不二次调用（once-guard）', (tester) async {
      var doneCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillTreasureOverlay(
              skillName: '点击测试招',
              imagePath: null,
              isManual: false,
              onDone: () => doneCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SkillTreasureOverlay));
      await tester.pump();
      expect(doneCount, 1);

      // timer 到期，once-guard 拦下
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('timer 先触发，再点击不二次调用（对称 once-guard）', (tester) async {
      var doneCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillTreasureOverlay(
              skillName: '对称测试招',
              imagePath: null,
              isManual: true,
              onDone: () => doneCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCount, 1);

      await tester.tap(find.byType(SkillTreasureOverlay));
      await tester.pump();
      expect(doneCount, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('UiStrings 残页轻提示', () {
    test('skillFragmentGainedLine 格式正确', () {
      final line = UiStrings.skillFragmentGainedLine('神龙一式', 3, 5);
      expect(line, contains('神龙一式'));
      expect(line, contains('3'));
      expect(line, contains('5'));
    });

    test('skillFragmentGainedLine 满页（达阈值）包含招式名', () {
      final line = UiStrings.skillFragmentGainedLine('回望踏风', 5, 5);
      expect(line, contains('回望踏风'));
      expect(line, contains('5'));
    });
  });

  group('presentSkillTreasure 战后仪式触发(战后接线 seam)', () {
    testWidgets('major(真解首通)→ 展示 SkillTreasureContent 重仪式', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => presentSkillTreasure(ctx, _manualResult()),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkillTreasureContent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('isMinorFragment → no-op 不展示重仪式', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () =>
                    presentSkillTreasure(ctx, _minorFragmentResult()),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkillTreasureContent), findsNothing);
    });

    testWidgets('none → no-op 不展示重仪式', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () =>
                    presentSkillTreasure(ctx, SkillDropResult.none),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkillTreasureContent), findsNothing);
    });
  });

  group('skillFragmentLineFor 共享轻提示 helper（Task 11 DRY）', () {
    test('isMinorFragment → 返回包含 id + count + threshold 的行', () {
      final result =
          _minorFragmentResult(); // fragmentSkillId='skill_frag', count=2, threshold=5
      final line = skillFragmentLineFor(result);
      expect(line, isNotNull);
      // GameRepository 未加载 → fallback 用 id 字面量
      expect(line, contains('skill_frag'));
      expect(line, contains('2'));
      expect(line, contains('5'));
    });

    test('isMajor(真解首通) → 返回 null（走重仪式不走轻提示）', () {
      expect(skillFragmentLineFor(_manualResult()), isNull);
    });

    test('isMajor(残页集齐) → 返回 null', () {
      expect(skillFragmentLineFor(_fragmentResult()), isNull);
    });

    test('SkillDropResult.none → 返回 null', () {
      expect(skillFragmentLineFor(SkillDropResult.none), isNull);
    });

    test('fragmentSkillId 为 null 的 minor fragment → 返回 null', () {
      // isMinorFragment 要求 fragmentSkillId != null && count < threshold
      // 若 fragmentSkillId == null 则不可能 isMinorFragment，验证防御路径。
      const result = SkillDropResult(
        fragmentSkillId: null,
        fragmentCount: 2,
        fragmentThreshold: 5,
        fragmentJustUnlocked: false,
      );
      expect(skillFragmentLineFor(result), isNull);
    });
  });

  group('presentSkillTreasure non-major no-op', () {
    // SkillDropResult.none 和 isMinorFragment 的结果不应触发重仪式。
    // 验证 isMajor 的契约（域层测试，不需要 widget pump）。
    test('SkillDropResult.none.isMajor == false', () {
      expect(SkillDropResult.none.isMajor, isFalse);
    });

    test('isMinorFragment result.isMajor == false', () {
      expect(_minorFragmentResult().isMajor, isFalse);
    });

    test('manualGranted result.isMajor == true', () {
      expect(_manualResult().isMajor, isTrue);
    });

    test('fragmentJustUnlocked result.isMajor == true', () {
      expect(_fragmentResult().isMajor, isTrue);
    });
  });
}
