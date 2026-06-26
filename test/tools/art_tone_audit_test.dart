// 美术/色彩基调审计 + 报告生成。
// 跑法:flutter test test/tools/art_tone_audit_test.dart
// 产出:test/tools/output/art_tone_audit.md
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'art_tone_audit.dart';

const String _outputDir = 'test/tools/output';

void main() {
  test('扫描器能识别 Material 默认主题、默认色与高饱和硬编码色', () {
    final issues = scanArtToneSources({
      'lib/sample.dart': '''
import 'package:flutter/material.dart';

final theme = ThemeData.dark(useMaterial3: true);
final a = Colors.blue;
final b = const Color(0xFFFF00AA);
final c = const Color(0x33000000);
''',
    });

    expect(
      issues.any((i) => i.kind == ArtToneIssueKind.materialDefaultTheme),
      isTrue,
    );
    expect(
      issues.any((i) => i.kind == ArtToneIssueKind.materialDefaultColor),
      isTrue,
    );
    expect(
      issues.any((i) => i.kind == ArtToneIssueKind.saturatedHardcodedColor),
      isTrue,
    );
    expect(
      issues.any((i) => i.colorHex == '0x33000000'),
      isFalse,
      reason: '黑色半透明遮罩属于水墨 UI 常用压暗层，不作为色彩漂移问题。',
    );
  });

  test('主题 token 文件作为集中 sink 不报告硬编码色', () {
    final issues = scanArtToneSources({
      'lib/shared/theme/colors.dart': '''
import 'package:flutter/material.dart';

class WuxiaColors {
  static const Color danger = Color(0xFFB22222);
}
''',
    });

    expect(issues, isEmpty);
  });

  test('生成 art_tone_audit.md', () {
    final issues = scanLibArtTone();
    Directory(_outputDir).createSync(recursive: true);
    File(
      '$_outputDir/art_tone_audit.md',
    ).writeAsStringSync(buildArtToneReport(issues));

    expect(
      issues.where((i) => i.kind == ArtToneIssueKind.materialDefaultTheme),
      isEmpty,
      reason: '主 app / 视觉验收 app 不应再使用 ThemeData.dark/light 默认主题。',
    );
    expect(issues, isNotEmpty, reason: '当前代码库仍有历史硬编码色，报告应持续给出清单供后续小批量清账。');
  });
}
