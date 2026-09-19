import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';

import '../support/test_data.dart';

void main() {
  tearDown(GameRepository.resetForTest);

  test('生产奇遇的 92 处属性增量全部通过加载期红线', () async {
    final repo = await GameRepository.loadAllDefs(loader: loadTestAsset);
    final outcomes = repo.encounterDefs.values
        .expand((encounter) => encounter.outcomeMapping.values)
        .where((outcome) => outcome.type == OutcomeType.attributeBonus)
        .toList();
    expect(outcomes, hasLength(92));
    for (final outcome in outcomes) {
      expect(outcome.attributeDelta, inInclusiveRange(1, 3));
    }
  });

  for (final delta in [5, 0]) {
    test('加载期拒绝属性增量 $delta 并报告奇遇编号与增量', () async {
      final encounters = parseYamlMap(
        await loadTestAsset('data/encounters.yaml'),
      );
      final encounter = (encounters['encounters'] as List)
          .cast<Map>()
          .firstWhere(
            (entry) => (entry['outcomeMapping'] as Map).values.any(
              (outcome) => outcome['type'] == 'attributeBonus',
            ),
          );
      final outcome =
          (encounter['outcomeMapping'] as Map).values.firstWhere(
                (outcome) => outcome['type'] == 'attributeBonus',
              )
              as Map;
      outcome['attributeDelta'] = delta;
      await expectLater(
        GameRepository.loadAllDefs(
          loader: (path) async => path == 'data/encounters.yaml'
              ? jsonEncode(encounters)
              : loadTestAsset(path),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            '错误信息',
            allOf(contains(encounter['id']), contains('attributeDelta=$delta')),
          ),
        ),
      );
    });
  }

  for (final key in ['bonus_per_event_min', 'bonus_per_event_max']) {
    test('奇遇属性范围缺少 $key 时立即抛错', () {
      final numbers = loadTestNumbersSection([]);
      final range =
          (numbers['character'] as Map)['adventure_attribute_bonus'] as Map;
      range.remove(key);
      expect(() => NumbersConfig.fromYaml(numbers), throwsArgumentError);
    });
  }

  for (final range in [(0, 3), (4, 3)]) {
    test('拒绝非法奇遇属性范围 $range', () {
      final numbers = loadTestNumbersSection([]);
      final bonus =
          (numbers['character'] as Map)['adventure_attribute_bonus'] as Map;
      bonus['bonus_per_event_min'] = range.$1;
      bonus['bonus_per_event_max'] = range.$2;
      expect(() => NumbersConfig.fromYaml(numbers), throwsArgumentError);
    });
  }

  for (final change in [
    ('bonus_per_event_min', 2),
    ('bonus_per_event_max', 1),
  ]) {
    test('加载期校验真读取 ${change.$1} 的变更', () async {
      final numbers = loadTestNumbersSection([]);
      final bonus =
          (numbers['character'] as Map)['adventure_attribute_bonus'] as Map;
      bonus[change.$1] = change.$2;
      await expectLater(
        GameRepository.loadAllDefs(
          loader: (path) async => path == 'data/numbers.yaml'
              ? jsonEncode(numbers)
              : loadTestAsset(path),
        ),
        throwsA(isA<StateError>()),
      );
    });
  }
}
