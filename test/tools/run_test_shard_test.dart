import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/run_test_shard.dart';

void main() {
  test('四组文件分片穷尽全集且无交集', () {
    final files = List.generate(19, (index) => 'test/file_$index.dart');
    final shards = [
      for (var index = 0; index < 4; index++)
        selectTestShard(files, totalShards: 4, shardIndex: index),
    ];
    final combined = shards.expand((shard) => shard).toList();
    expect(combined, unorderedEquals(files));
    expect(combined.toSet(), hasLength(combined.length));
    expect(shards.map((shard) => shard.length), [5, 5, 5, 4]);
  });

  test('文件遍历顺序不改变分片归属', () {
    const files = ['test/z.dart', 'test/a.dart', 'test/m.dart', 'test/b.dart'];
    for (var index = 0; index < 4; index++) {
      expect(
        selectTestShard(files, totalShards: 4, shardIndex: index),
        selectTestShard(files.reversed, totalShards: 4, shardIndex: index),
      );
    }
  });

  test('分片不足一组时不重复分配文件', () {
    expect(selectTestShard(['test/a.dart'], totalShards: 4, shardIndex: 0), [
      'test/a.dart',
    ]);
    expect(
      selectTestShard(['test/a.dart'], totalShards: 4, shardIndex: 3),
      isEmpty,
    );
  });

  test('非法分片参数与重复文件均拒绝', () {
    for (final (total, index) in [(0, 0), (-1, 0), (4, -1), (4, 4)]) {
      expect(
        () => selectTestShard([], totalShards: total, shardIndex: index),
        throwsArgumentError,
      );
    }
    expect(
      () => selectTestShard(['a', 'a'], totalShards: 4, shardIndex: 0),
      throwsArgumentError,
    );
  });

  String report(List<String> files, {bool success = true}) => [
    for (final file in files)
      jsonEncode({
        'type': 'suite',
        'suite': {'path': file},
      }),
    jsonEncode({'type': 'done', 'success': success}),
  ].join('\n');

  test('实际测试报告完整覆盖本片文件才接受成功', () {
    const files = ['test/a_test.dart', 'test/b_test.dart'];
    expect(() => verifyTestShardReport(files, report(files)), returnsNormally);
  });

  test('测试报告漏文件或跨片文件均拒绝', () {
    const files = ['test/a_test.dart', 'test/b_test.dart'];
    expect(
      () => verifyTestShardReport(files, report(files.take(1).toList())),
      throwsStateError,
    );
    expect(
      () =>
          verifyTestShardReport(files, report([...files, 'test/c_test.dart'])),
      throwsStateError,
    );
  });

  test('测试报告缺少成功结束事件时拒绝', () {
    const files = ['test/a_test.dart'];
    expect(
      () => verifyTestShardReport(files, report(files, success: false)),
      throwsStateError,
    );
    expect(() => verifyTestShardReport(files, ''), throwsStateError);
  });
}
