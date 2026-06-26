// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final command = args.isEmpty ? 'checklist' : args.first;
  final options = _Options.parse(args.skip(1).toList());

  switch (command) {
    case 'routes':
      final ids = visualAcceptanceRouteIds(options.suite);
      switch (options.format) {
        case 'ids':
          for (final id in ids) {
            print(id);
          }
        case 'json':
          print(jsonEncode(ids));
        case 'markdown':
          print(visualAcceptanceChecklistMarkdown(options.suite));
        default:
          throw ArgumentError.value(
            options.format,
            'format',
            'expected: ids|json|markdown',
          );
      }
    case 'checklist':
    case 'dry-run':
      print(visualAcceptanceChecklistMarkdown(options.suite));
    default:
      _printUsage();
      throw ArgumentError.value(
        command,
        'command',
        'expected: routes|checklist|dry-run',
      );
  }
}

void _printUsage() {
  print('''
视觉验收计划生成器

Usage:
  flutter pub run tool/visual_acceptance.dart routes [--suite smoke|full] [--format ids|json|markdown]
  flutter pub run tool/visual_acceptance.dart checklist [--suite smoke|full]
  flutter pub run tool/visual_acceptance.dart dry-run [--suite smoke|full]

Examples:
  flutter pub run tool/visual_acceptance.dart routes --suite smoke
  flutter pub run tool/visual_acceptance.dart checklist --suite full
  tools/visual_capture/visual_capture.sh --dry-run --suite smoke
''');
}

class _Options {
  const _Options({required this.suite, required this.format});

  final VisualAcceptanceSuite suite;
  final String format;

  static _Options parse(List<String> args) {
    var suite = VisualAcceptanceSuite.smoke;
    var format = 'ids';

    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--suite':
          i++;
          if (i >= args.length) {
            throw ArgumentError('--suite requires smoke|full');
          }
          suite = VisualAcceptanceSuite.parse(args[i]);
        case '--format':
          i++;
          if (i >= args.length) {
            throw ArgumentError('--format requires ids|json|markdown');
          }
          format = args[i];
        default:
          throw ArgumentError.value(args[i], 'option', 'unknown option');
      }
    }

    return _Options(suite: suite, format: format);
  }
}
