// 美术/色彩基调审计：扫描 lib/ 下 Material 默认色、硬编码色与高饱和色。
// 跑法见 art_tone_audit_test.dart。
import 'dart:io';
import 'dart:math' as math;

enum ArtToneIssueKind {
  materialDefaultTheme,
  materialDefaultColor,
  hardcodedColor,
  saturatedHardcodedColor,
}

enum ArtToneSeverity { high, medium, low, info }

class ArtToneIssue {
  const ArtToneIssue({
    required this.path,
    required this.line,
    required this.kind,
    required this.severity,
    required this.snippet,
    required this.message,
    this.colorHex,
    this.saturation,
    this.value,
  });

  final String path;
  final int line;
  final ArtToneIssueKind kind;
  final ArtToneSeverity severity;
  final String snippet;
  final String message;
  final String? colorHex;
  final double? saturation;
  final double? value;
}

const _tokenSinkPaths = {
  'lib/shared/theme/colors.dart',
  'lib/shared/theme/wuxia_tokens.dart',
  'lib/shared/theme/wuxia_app_theme.dart',
  'lib/shared/theme/tier_colors.dart',
};

const _neutralMaterialColors = {
  'black',
  'black12',
  'black26',
  'black38',
  'black45',
  'black54',
  'black87',
  'transparent',
  'white',
  'white10',
  'white12',
  'white24',
  'white30',
  'white38',
  'white54',
  'white60',
  'white70',
};

const _defaultHueMaterialColors = {
  'amber',
  'blue',
  'blueAccent',
  'brown',
  'cyan',
  'cyanAccent',
  'deepOrange',
  'deepOrangeAccent',
  'deepPurple',
  'deepPurpleAccent',
  'green',
  'greenAccent',
  'indigo',
  'indigoAccent',
  'lightBlue',
  'lightBlueAccent',
  'lightGreen',
  'lime',
  'limeAccent',
  'orange',
  'orangeAccent',
  'pink',
  'pinkAccent',
  'purple',
  'purpleAccent',
  'red',
  'redAccent',
  'teal',
  'tealAccent',
  'yellow',
  'yellowAccent',
};

List<ArtToneIssue> scanLibArtTone([String root = 'lib']) {
  final sources = <String, String>{};
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      sources[_normalizePath(entity.path)] = entity.readAsStringSync();
    }
  }
  return scanArtToneSources(sources);
}

List<ArtToneIssue> scanArtToneSources(Map<String, String> sources) {
  final issues = <ArtToneIssue>[];
  for (final entry in sources.entries) {
    final path = _normalizePath(entry.key);
    final lines = entry.value.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;
      issues.addAll(_scanTheme(path, lineNumber, line));
      issues.addAll(_scanMaterialColors(path, lineNumber, line));
      issues.addAll(_scanHardcodedColors(path, lineNumber, line));
    }
  }
  issues.sort((a, b) {
    final severity = a.severity.index.compareTo(b.severity.index);
    if (severity != 0) return severity;
    final path = a.path.compareTo(b.path);
    if (path != 0) return path;
    return a.line.compareTo(b.line);
  });
  return issues;
}

String buildArtToneReport(List<ArtToneIssue> issues) {
  final buf = StringBuffer();
  buf.writeln('# 美术基调审计报告');
  buf.writeln();
  buf.writeln(
    '> 工具生成，勿手改。跑法：`flutter test test/tools/art_tone_audit_test.dart`',
  );
  buf.writeln();
  buf.writeln('## 汇总');
  buf.writeln();
  buf.writeln('| 严重度 | 数量 |');
  buf.writeln('|---|---:|');
  for (final severity in ArtToneSeverity.values) {
    final count = issues.where((i) => i.severity == severity).length;
    buf.writeln('| ${severity.name} | $count |');
  }
  buf.writeln('| **合计** | **${issues.length}** |');
  buf.writeln();
  buf.writeln('## 分类');
  buf.writeln();
  buf.writeln('| 类型 | 数量 |');
  buf.writeln('|---|---:|');
  for (final kind in ArtToneIssueKind.values) {
    final count = issues.where((i) => i.kind == kind).length;
    buf.writeln('| ${kind.name} | $count |');
  }
  buf.writeln();
  buf.writeln('## 问题清单');
  if (issues.isEmpty) {
    buf.writeln();
    buf.writeln('未发现问题。');
    return buf.toString();
  }
  for (final issue in issues) {
    final metrics = issue.saturation == null
        ? ''
        : ' saturation=${issue.saturation!.toStringAsFixed(2)}, value=${issue.value!.toStringAsFixed(2)}';
    buf.writeln();
    buf.writeln(
      '- `${issue.severity.name}` `${issue.kind.name}` '
      '`${issue.path}:${issue.line}`${issue.colorHex == null ? '' : ' `${issue.colorHex}`'}$metrics',
    );
    buf.writeln('  - ${issue.message}');
    buf.writeln('  - `${issue.snippet}`');
  }
  return buf.toString();
}

List<ArtToneIssue> _scanTheme(String path, int lineNumber, String line) {
  if (_tokenSinkPaths.contains(path)) return const [];
  if (!line.contains('ThemeData.dark') && !line.contains('ThemeData.light')) {
    return const [];
  }
  return [
    ArtToneIssue(
      path: path,
      line: lineNumber,
      kind: ArtToneIssueKind.materialDefaultTheme,
      severity: ArtToneSeverity.high,
      snippet: line.trim(),
      message:
          'ThemeData.dark/light 会继承 Material 默认强调色；请使用 wuxiaAppTheme 或显式 ColorScheme。',
    ),
  ];
}

List<ArtToneIssue> _scanMaterialColors(
  String path,
  int lineNumber,
  String line,
) {
  final matches = RegExp(r'\bColors\.([A-Za-z][A-Za-z0-9_]*)').allMatches(line);
  final issues = <ArtToneIssue>[];
  for (final match in matches) {
    final name = match.group(1)!;
    if (_neutralMaterialColors.contains(name)) continue;
    final isDefaultHue = _defaultHueMaterialColors.contains(name);
    issues.add(
      ArtToneIssue(
        path: path,
        line: lineNumber,
        kind: ArtToneIssueKind.materialDefaultColor,
        severity: isDefaultHue ? ArtToneSeverity.high : ArtToneSeverity.medium,
        snippet: line.trim(),
        message: isDefaultHue
            ? 'Material 默认色 Colors.$name 偏饱和，容易破坏水墨克制基调；优先改为 WuxiaColors/WuxiaUi token。'
            : '直接使用 Colors.$name，请确认不是 Material 默认色外溢，优先集中到主题 token。',
      ),
    );
  }
  return issues;
}

List<ArtToneIssue> _scanHardcodedColors(
  String path,
  int lineNumber,
  String line,
) {
  if (_tokenSinkPaths.contains(path)) return const [];
  final matches = RegExp(
    r'\b(?:const\s+)?Color\((0x[0-9A-Fa-f]{8})\)',
  ).allMatches(line);
  final issues = <ArtToneIssue>[];
  for (final match in matches) {
    final hex = match.group(1)!;
    final tone = _toneFromHex(hex);
    if (_isNeutralOverlay(tone)) continue;
    final saturated = tone.saturation >= 0.62 && tone.value >= 0.68;
    issues.add(
      ArtToneIssue(
        path: path,
        line: lineNumber,
        kind: saturated
            ? ArtToneIssueKind.saturatedHardcodedColor
            : ArtToneIssueKind.hardcodedColor,
        severity: saturated ? ArtToneSeverity.medium : ArtToneSeverity.low,
        snippet: line.trim(),
        message: saturated
            ? '硬编码高饱和色；若确属武侠点缀色，请迁入 WuxiaColors/WuxiaUi 并命名用途。'
            : '硬编码 UI 色；优先复用或补充集中 theme token，避免页面各自漂移。',
        colorHex: hex,
        saturation: tone.saturation,
        value: tone.value,
      ),
    );
  }
  return issues;
}

bool _isNeutralOverlay(_Tone tone) {
  final isNearBlackWhite = tone.saturation <= 0.04;
  final isMostlyTransparent = tone.alpha <= 0.35;
  return isNearBlackWhite || isMostlyTransparent;
}

_Tone _toneFromHex(String hex) {
  final value = int.parse(hex.substring(2), radix: 16);
  final alpha = ((value >> 24) & 0xFF) / 255.0;
  final red = ((value >> 16) & 0xFF) / 255.0;
  final green = ((value >> 8) & 0xFF) / 255.0;
  final blue = (value & 0xFF) / 255.0;
  final maxChannel = math.max(red, math.max(green, blue));
  final minChannel = math.min(red, math.min(green, blue));
  final delta = maxChannel - minChannel;
  final saturation = maxChannel == 0 ? 0.0 : delta / maxChannel;
  return _Tone(alpha: alpha, saturation: saturation, value: maxChannel);
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

class _Tone {
  const _Tone({
    required this.alpha,
    required this.saturation,
    required this.value,
  });

  final double alpha;
  final double saturation;
  final double value;
}
