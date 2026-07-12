import 'dart:convert';
import 'dart:io';
import 'dart:math';

class CoverageSummary {
  const CoverageSummary({required this.coveredLines, required this.totalLines});

  final int coveredLines;
  final int totalLines;

  double get percentage => coveredLines * 100 / totalLines;

  bool meetsMinimum(double minimum) => percentage + 1e-9 >= minimum;
}

bool isGeneratedCoveragePath(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

CoverageSummary parseLcov(String source) {
  final hitsBySourceLine = <String, int>{};
  String? currentSource;

  for (final rawLine in const LineSplitter().convert(source)) {
    if (rawLine.startsWith('SF:')) {
      currentSource = rawLine.substring(3).trim();
      continue;
    }
    if (!rawLine.startsWith('DA:') ||
        currentSource == null ||
        isGeneratedCoveragePath(currentSource)) {
      continue;
    }

    final fields = rawLine.substring(3).split(',');
    if (fields.length < 2) {
      throw FormatException('Invalid LCOV DA record: $rawLine');
    }
    final line = int.tryParse(fields[0]);
    final hits = int.tryParse(fields[1]);
    if (line == null || hits == null || line <= 0 || hits < 0) {
      throw FormatException('Invalid LCOV DA record: $rawLine');
    }

    final key = '$currentSource\u0000$line';
    hitsBySourceLine[key] = max(hitsBySourceLine[key] ?? 0, hits);
  }

  if (hitsBySourceLine.isEmpty) {
    throw const FormatException('LCOV contains no eligible Dart source lines');
  }

  return CoverageSummary(
    coveredLines: hitsBySourceLine.values.where((hits) => hits > 0).length,
    totalLines: hitsBySourceLine.length,
  );
}

Future<void> main(List<String> args) async {
  final lcovPath = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final baselinePath = args.length > 1
      ? args[1]
      : '.github/coverage-ratchet.json';

  try {
    final lcov = await File(lcovPath).readAsString();
    final baseline = jsonDecode(await File(baselinePath).readAsString());
    if (baseline is! Map<String, dynamic>) {
      throw const FormatException('Coverage baseline must be a JSON object');
    }
    final minimumValue = baseline['lineCoverageMinimum'];
    if (minimumValue is! num || !minimumValue.isFinite || minimumValue < 0) {
      throw const FormatException(
        'lineCoverageMinimum must be a non-negative finite number',
      );
    }

    final summary = parseLcov(lcov);
    final minimum = minimumValue.toDouble();
    stdout.writeln(
      'Line coverage: ${summary.coveredLines}/${summary.totalLines} '
      '(${summary.percentage.toStringAsFixed(2)}%), '
      'minimum=${minimum.toStringAsFixed(2)}%',
    );
    if (!summary.meetsMinimum(minimum)) {
      stderr.writeln(
        'Coverage ratchet failed: ${summary.percentage.toStringAsFixed(2)}% '
        '< ${minimum.toStringAsFixed(2)}%',
      );
      exitCode = 1;
    }
  } on Object catch (error) {
    stderr.writeln('Coverage ratchet error: $error');
    exitCode = 1;
  }
}
