import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const script = 'tools/audit_paper_text_contrast.py';

  Future<ProcessResult> runAudit(Directory root) {
    return Process.run('python3', [
      script,
      '--root',
      root.path,
    ], workingDirectory: Directory.current.path);
  }

  Directory createFixture(String source) {
    final dir = Directory.systemTemp.createTempSync('paper_text_audit_');
    final libDir = Directory('${dir.path}/lib')..createSync();
    File('${libDir.path}/fixture.dart').writeAsStringSync(source);
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    return dir;
  }

  test('reports dark-surface text token inside PaperPanel', () async {
    final root = createFixture(r'''
class PaperPanel {
  const PaperPanel({required this.child});
  final Object child;
}
class Text {
  const Text(String value, {Object? style});
}
class TextStyle {
  const TextStyle({Object? color});
}
class WuxiaColors {
  static const textSecondary = Object();
}
final widget = PaperPanel(
  child: Text(
    'bad',
    style: TextStyle(color: WuxiaColors.textSecondary),
  ),
);
''');

    final result = await runAudit(root);

    expect(result.exitCode, 1);
    expect(result.stdout.toString(), contains('PaperPanel'));
    expect(result.stdout.toString(), contains('WuxiaColors.textSecondary'));
  });

  test('passes paper-surface text when WuxiaUi ink token is used', () async {
    final root = createFixture(r'''
class PaperPanel {
  const PaperPanel({required this.child});
  final Object child;
}
class Text {
  const Text(String value, {Object? style});
}
class TextStyle {
  const TextStyle({Object? color});
}
class WuxiaUi {
  static const ink = Object();
}
final widget = PaperPanel(
  child: Text(
    'good',
    style: TextStyle(color: WuxiaUi.ink),
  ),
);
''');

    final result = await runAudit(root);

    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains('paper text contrast findings: 0'),
    );
  });

  test('allows documented dark overlay exceptions', () async {
    final root = createFixture(r'''
class Container {
  const Container({Object? color, required this.child});
  final Object child;
}
class Text {
  const Text(String value, {Object? style});
}
class TextStyle {
  const TextStyle({Object? color});
}
class WuxiaUi {
  static const paper = Object();
}
class WuxiaColors {
  static const textPrimary = Object();
}
final widget = Container(
  color: WuxiaUi.paper,
  child: Text(
    'overlay',
    style: TextStyle(
      // paper-text-audit: allow nested dark overlay keeps dark-surface text token
      color: WuxiaColors.textPrimary,
    ),
  ),
);
''');

    final result = await runAudit(root);

    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains('paper text contrast findings: 0'),
    );
  });
}
