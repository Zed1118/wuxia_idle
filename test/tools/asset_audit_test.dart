// 资产缺图审计 + allowlist guard。
// 跑法:flutter test test/tools/asset_audit_test.dart
// 产出:test/tools/output/asset_audit.md + asset_audit_missing.txt
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import 'asset_audit.dart';

const String _outputDir = 'test/tools/output';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('收集到各类别资产引用', () {
    final refs = collectAssetRefs();
    expect(refs, isNotEmpty);
    expect(refs.any((r) => r.category == AssetCategory.enemy), isTrue);
    expect(refs.any((r) => r.category == AssetCategory.equipment), isTrue);
  });

  test('生成 asset_audit.md + asset_audit_missing.txt', () {
    final refs = collectAssetRefs();
    Directory(_outputDir).createSync(recursive: true);
    File('$_outputDir/asset_audit.md').writeAsStringSync(buildReport(refs));
    File('$_outputDir/asset_audit_missing.txt')
        .writeAsStringSync('${missingPaths(refs).join('\n')}\n');
  });

  test('guard 1: 无 allowlist 外的缺图(防新增坏引用)', () {
    final missing = missingPaths(collectAssetRefs()).toSet();
    final allow = loadAllowlist();
    final offenders = missing.difference(allow).toList()..sort();
    expect(offenders, isEmpty,
        reason: '以下引用指向缺图且不在 allowlist(新增坏引用?):\n${offenders.join('\n')}');
  });

  test('guard 2: allowlist 无已补齐残留(补齐即清账)', () {
    final fixed = loadAllowlist().where(assetExists).toList()..sort();
    expect(fixed, isEmpty,
        reason: '以下已存在于磁盘,请从 allowlist 删除:\n${fixed.join('\n')}');
  });
}
