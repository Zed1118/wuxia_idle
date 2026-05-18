import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';
import '../domain/codex_entry.dart';

/// P1 #42 Phase 2 §10 P1.z 机制百科条目详情(沿 NarrativeReaderScreen 文字风格)。
class CodexEntryDetail extends StatelessWidget {
  const CodexEntryDetail({super.key, required this.entry});

  final CodexEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: Text(
          entry.title,
          style: const TextStyle(color: WuxiaColors.resultHighlight),
        ),
        iconTheme: const IconThemeData(color: WuxiaColors.resultHighlight),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        itemCount: entry.paragraphs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (context, i) => Text(
          entry.paragraphs[i],
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 15,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
