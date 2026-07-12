import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_ratchet.dart';

void main() {
  test('parseLcov 按手写源码行统计覆盖率', () {
    final summary = parseLcov('''
SF:lib/a.dart
DA:1,1
DA:2,0
end_of_record
''');

    expect(summary.totalLines, 2);
    expect(summary.coveredLines, 1);
    expect(summary.percentage, 50);
  });

  test('同一源码行重复出现时取最高 hits 且不重复计数', () {
    final summary = parseLcov('''
SF:lib/a.dart
DA:7,0
end_of_record
SF:lib/a.dart
DA:7,3
DA:8,0
end_of_record
''');

    expect(summary.totalLines, 2);
    expect(summary.coveredLines, 1);
  });

  test('生成文件不进入覆盖率分母', () {
    final summary = parseLcov('''
SF:lib/a.g.dart
DA:1,0
SF:lib/b.freezed.dart
DA:2,0
SF:lib/c.mocks.dart
DA:3,0
SF:lib/handwritten.dart
DA:4,2
end_of_record
''');

    expect(summary.totalLines, 1);
    expect(summary.coveredLines, 1);
    expect(summary.percentage, 100);
  });

  test('没有可统计的手写源码行时 fail-fast', () {
    expect(
      () => parseLcov('SF:lib/a.g.dart\nDA:1,0\nend_of_record\n'),
      throwsFormatException,
    );
  });

  test('meetsMinimum 在边界通过，低于边界失败', () {
    const summary = CoverageSummary(coveredLines: 81, totalLines: 100);

    expect(summary.meetsMinimum(81), isTrue);
    expect(summary.meetsMinimum(81.01), isFalse);
  });
}
