import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:yaml/yaml.dart';

import '../support/test_data.dart';

void main() {
  tearDownAll(GameRepository.resetForTest);

  test('skills 207 + encounter skills 40 = merged SkillDef 247', () async {
    Set<String> idsFrom(String path, String rootKey) {
      final yaml = loadYaml(File(path).readAsStringSync()) as YamlMap;
      final rows = yaml[rootKey] as YamlList;
      final ids = rows.map((row) => (row as YamlMap)['id'] as String).toList();
      expect(ids.toSet().length, ids.length, reason: '$path 内部 skill id 必须唯一');
      return ids.toSet();
    }

    final genericIds = idsFrom('data/skills.yaml', 'skills');
    final encounterIds = idsFrom(
      'data/encounter_skills.yaml',
      'encounter_skills',
    );
    final overlap = genericIds.intersection(encounterIds);

    expect(genericIds, hasLength(207));
    expect(encounterIds, hasLength(40));
    expect(
      overlap,
      isEmpty,
      reason: 'skills.yaml 与 encounter_skills.yaml 不得重用 id',
    );

    final repo = await loadTestGameRepository();
    final mergedIds = genericIds.union(encounterIds);
    expect(mergedIds, hasLength(247));
    expect(repo.skillDefs.keys.toSet(), mergedIds);
    expect(repo.encounterSkillIds, encounterIds);

    final gdd = File('GDD.md').readAsStringSync();
    expect(gdd, contains('| 通用 / 战斗招式（skills.yaml） | 207 招 |'));
    expect(gdd, contains('| 奇遇专属武学领悟招式（encounter_skills.yaml） | 40 招 |'));
    expect(gdd, contains('| 招式总池（SkillDef） | 247 招（207 + 40） |'));
  });
}
