import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 审计 C-F4 · 全游戏招式 powerMultiplier ≤ 8000 红线测（GDD §5.4）。
///
/// 此前该上限只在 `_enforceEncounterSkillRedLines` 的 encounterSkillIds 循环内
/// 校验，普通心法招（skills.yaml）越界会静默 load。修复后改为对全部 skillDefs
/// 统一校验。本测族写约束语义（production 自洽）+ broken loader 验 fail-fast。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  Future<String> Function(String) makeLoader(
    String targetPath,
    String Function(String original) transform,
  ) {
    Future<String> loader(String path) async {
      final original = await File(path).readAsString();
      if (path == targetPath) return transform(original);
      return original;
    }

    return loader;
  }

  test('production 全量自洽：所有招式 powerMultiplier ≤ 8000', () {
    final repo = GameRepository.instance;
    expect(repo.skillDefs, isNotEmpty);
    for (final s in repo.skillDefs.values) {
      expect(s.powerMultiplier, lessThanOrEqualTo(8000),
          reason: '${s.id} powerMultiplier=${s.powerMultiplier} 越 §5.4 红线');
    }
  });

  test('broken loader：普通 skill powerMultiplier > 8000 → loadAllDefs 抛 StateError',
      () async {
    // 把 skills.yaml 第一处 powerMultiplier: 500（基础普攻）注成 9999 越界。
    // 旧逻辑下普通招无全局校验会静默 load；修复后全局 ≤8000 校验 fail-fast。
    String inject(String s) =>
        s.replaceFirst('powerMultiplier: 500', 'powerMultiplier: 9999');
    expect(
      GameRepository.loadAllDefs(
        loader: makeLoader('data/skills.yaml', inject),
      ),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('> 8000'),
      )),
    );
  });
}
