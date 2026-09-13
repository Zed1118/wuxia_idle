import 'dart:convert';
import 'dart:io';

/// Select whole files before Flutter loads suites. Native test sharding slices
/// tests within each suite and repeats most compilation/coverage setup per shard.
List<String> selectTestShard(
  Iterable<String> files, {
  required int totalShards,
  required int shardIndex,
}) {
  if (totalShards <= 0 || shardIndex < 0 || shardIndex >= totalShards) {
    throw ArgumentError(
      'Require totalShards > 0 and 0 <= shardIndex < totalShards',
    );
  }
  final sorted = files.toList()..sort();
  if (sorted.toSet().length != sorted.length) {
    throw ArgumentError('Test file paths must be unique');
  }
  return [
    for (var index = shardIndex; index < sorted.length; index += totalShards)
      sorted[index],
  ];
}

void verifyTestShardReport(Iterable<String> selected, String report) {
  final expected = selected.map((path) => File(path).absolute.path).toSet();
  final reported = <String>{};
  var completed = false;
  for (final line in const LineSplitter().convert(report)) {
    final event = jsonDecode(line) as Map<String, dynamic>;
    if (event['type'] == 'suite') {
      final suite = event['suite'] as Map<String, dynamic>;
      reported.add(File(suite['path'] as String).absolute.path);
    } else if (event['type'] == 'done') {
      completed = event['success'] == true;
    }
  }
  if (!completed ||
      expected.difference(reported).isNotEmpty ||
      reported.difference(expected).isNotEmpty) {
    throw StateError(
      'Shard report mismatch: completed=$completed, '
      'missing=${expected.difference(reported)}, '
      'unexpected=${reported.difference(expected)}',
    );
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 2 || args.any((arg) => int.tryParse(arg) == null)) {
    stderr.writeln('Usage: dart run tool/run_test_shard.dart <total> <index>');
    exitCode = 64;
    return;
  }
  final totalShards = int.parse(args[0]);
  final shardIndex = int.parse(args[1]);
  final files = Directory('test')
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => file.path.replaceAll('\\', '/'))
      .where((path) => path.endsWith('_test.dart'));
  final selected = selectTestShard(
    files,
    totalShards: totalShards,
    shardIndex: shardIndex,
  );
  if (selected.isEmpty) {
    stderr.writeln('Test shard $shardIndex/$totalShards is empty');
    exitCode = 1;
    return;
  }
  Directory('coverage').createSync(recursive: true);
  File('coverage/test-shard-manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'totalShards': totalShards,
      'shardIndex': shardIndex,
      'files': selected,
    }),
  );
  stdout.writeln(
    'Test shard $shardIndex/$totalShards: ${selected.length} files',
  );
  final process = await Process.start('flutter', [
    'test',
    '--coverage',
    '--no-pub',
    '--file-reporter=json:coverage/test-results.json',
    ...selected,
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
  if (exitCode != 0) return;
  verifyTestShardReport(
    selected,
    File('coverage/test-results.json').readAsStringSync(),
  );
  stdout.writeln(
    'Verified ${selected.length} test files in the successful report',
  );
}
