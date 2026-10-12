import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R5 奇遇击杀账口径:击杀只来自结算快照中实际被击败的敌人,
/// 不得再按关卡配置的 enemyTeam 人头计。
void main() {
  test('encounter kill ledger never derives kills from enemyTeam', () {
    final offenders = <String>[];
    var settlementFed = 0;
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (file) =>
                  file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
            )) {
      final source = file.readAsStringSync();
      for (final match in RegExp(
        r'defeatedSchools:\s*([^,;]*)',
      ).allMatches(source)) {
        final argument = match.group(1)!;
        if (argument.contains('enemyTeam')) offenders.add(file.path);
        if (argument.contains('defeatedEnemySchools')) settlementFed++;
      }
    }

    expect(offenders, isEmpty);
    // 主线结算、主线可见重打钩子、爬塔钩子三处记账点。
    expect(settlementFed, 3);
  });
}
