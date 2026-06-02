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
}
