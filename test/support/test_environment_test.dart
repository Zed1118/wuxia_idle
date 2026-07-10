import 'package:flutter_test/flutter_test.dart';

import 'isar_test_support.dart';
import 'test_data.dart';

void main() {
  test('生产配置测试加载器可复用同一仓储实例', () async {
    final first = await loadTestGameRepository();
    final second = await loadTestGameRepository();

    expect(second, same(first));
    expect(first.stageDefs, isNotEmpty);
  });

  test('Isar Core 初始化可重复调用', () async {
    await initializeTestIsarCore();
    await initializeTestIsarCore();
  });
}
