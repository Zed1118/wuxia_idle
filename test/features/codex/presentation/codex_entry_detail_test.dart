import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/codex/domain/codex_category.dart';
import 'package:wuxia_idle/features/codex/domain/codex_entry.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_entry_detail.dart';

/// 测试工厂：避免字面计数，paragraphs 由 paragraphCount 派生。
CodexEntry _makeEntry({
  String id = 'test_entry',
  int? step = 1,
  String title = '测试条目',
  CodexCategory category = CodexCategory.combat,
  List<String>? paragraphs,
  int paragraphCount = 2,
}) {
  final ps = paragraphs ?? List.generate(paragraphCount, (i) => '段落${i + 1}');
  return CodexEntry(id: id, step: step, title: title, category: category, paragraphs: ps);
}

void main() {
  // ── 原有 2 case ──────────────────────────────────────────────────────────────

  testWidgets('CodexEntryDetail title 渲染', (tester) async {
    const entry = CodexEntry(
      id: 'realm',
      step: 1,
      title: '境界',
      category: CodexCategory.combat,
      paragraphs: ['段落一', '段落二'],
    );
    await tester.pumpWidget(const MaterialApp(
      home: CodexEntryDetail(entry: entry),
    ));
    expect(find.text('境界'), findsOneWidget);
  });

  testWidgets('CodexEntryDetail 多段 paragraphs 全渲染', (tester) async {
    const entry = CodexEntry(
      id: 'retreat',
      step: 5,
      title: '闭关与时辰',
      category: CodexCategory.seclusion,
      paragraphs: ['第一段', '第二段', '第三段'],
    );
    await tester.pumpWidget(const MaterialApp(
      home: CodexEntryDetail(entry: entry),
    ));
    expect(find.text('第一段'), findsOneWidget);
    expect(find.text('第二段'), findsOneWidget);
    expect(find.text('第三段'), findsOneWidget);
  });

  // ── A. 单段渲染 ──────────────────────────────────────────────────────────────

  testWidgets('A. 单段 entry 正确渲染唯一段落', (tester) async {
    final entry = _makeEntry(paragraphs: ['唯此一段']);
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(find.text(entry.paragraphs.first), findsOneWidget);
    expect(entry.paragraphs.length, 1);
  });

  // ── B. 5 段全渲染(派生断言，不写字面计数) ────────────────────────────────────

  testWidgets('B. 5段 entry 每段均可独立找到', (tester) async {
    final entry = _makeEntry(paragraphCount: 5);
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    for (final p in entry.paragraphs) {
      expect(find.text(p), findsOneWidget);
    }
  });

  // ── C. 8+ 段——首段与末段可达 ─────────────────────────────────────────────────

  testWidgets('C. 8段 entry 首末段均在 ListView 中可找到', (tester) async {
    final entry = _makeEntry(paragraphCount: 8);
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(entry.paragraphs.length, greaterThanOrEqualTo(8));
    expect(find.text(entry.paragraphs.first), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.text(entry.paragraphs.last), findsOneWidget);
  });

  // ── D. 从路由跳入时 AppBar 显示返回按钮 ─────────────────────────────────────

  testWidgets('D. 路由跳入时 AppBar 含 BackButton', (tester) async {
    final entry = _makeEntry();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => CodexEntryDetail(entry: entry)),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });

  // ── E. 无跳过/快进按钮(纯浏览 ListView，无 NarrativeReader 导航控件) ─────────

  testWidgets('E. 纯浏览 widget 不含跳过或快进控件', (tester) async {
    final entry = _makeEntry(paragraphCount: 3);
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(find.text('跳过'), findsNothing);
    expect(find.text('快进'), findsNothing);
  });

  // ── F. 短标题(单字) ──────────────────────────────────────────────────────────

  testWidgets('F. 单字标题完整渲染', (tester) async {
    final entry = _makeEntry(title: '境');
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(find.text(entry.title), findsOneWidget);
  });

  // ── G. 长标题(≥ 10 字) ───────────────────────────────────────────────────────

  testWidgets('G. 长标题(≥10 字)AppBar 可完整渲染', (tester) async {
    final entry = _makeEntry(title: '刚猛流派克制关系详细说明');
    expect(entry.title.length, greaterThanOrEqualTo(10));
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(find.text(entry.title), findsOneWidget);
  });

  // ── H. CodexCategory 枚举全覆盖(9 值) ───────────────────────────────────────

  testWidgets('H. CodexCategory 所有枚举值均可 build widget 不 crash', (tester) async {
    expect(CodexCategory.values.length, 9); // 枚举集合自洽约束
    for (final cat in CodexCategory.values) {
      final entry = CodexEntry(
        id: 'cat_${cat.name}',
        step: cat.step,
        title: cat.name,
        category: cat,
        paragraphs: const ['测试段落'],
      );
      await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
      expect(
        find.text(cat.name),
        findsOneWidget,
        reason: 'category ${cat.name} 应能渲染 title',
      );
    }
  });

  // ── I. 空 paragraphs 不 crash ────────────────────────────────────────────────

  testWidgets('I. 空 paragraphs 不 crash，仅渲染标题', (tester) async {
    const entry = CodexEntry(
      id: 'empty_body',
      step: 1,
      title: '空条目',
      category: CodexCategory.combat,
      paragraphs: [],
    );
    await tester.pumpWidget(const MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(find.text(entry.title), findsOneWidget);
    expect(entry.paragraphs.isEmpty, isTrue);
  });

  // ── J. 小 viewport 下多段可 scroll，无 overflow ───────────────────────────────

  testWidgets('J. 小 viewport(400×400)下多段 entry 可 scroll 无 overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final entry = _makeEntry(paragraphCount: 10);
    await tester.pumpWidget(MaterialApp(home: CodexEntryDetail(entry: entry)));
    expect(find.byType(ListView), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    // 无 overflow 异常且末段可见 = pass
    expect(find.text(entry.paragraphs.last), findsOneWidget);
  });
}
