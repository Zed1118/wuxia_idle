import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/codex/domain/codex_category.dart';
import 'package:wuxia_idle/features/codex/domain/codex_entry.dart';
import 'package:wuxia_idle/features/codex/presentation/codex_entry_detail.dart';

void main() {
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
}
