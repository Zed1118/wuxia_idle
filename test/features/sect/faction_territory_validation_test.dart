import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 外部审查 #4:factions/territories 缺 fail-fast 引用/自洽校验(对比 equipment↔lore
/// `_validatePresetLoreReferences` / encounters↔events `_validateEncounterEventReferences`)。
/// `_validateFactionTerritoryReferences` 在 `loadAllDefs` 末尾补三类启动期强校验。
/// 仿 encounter_event_validation_test 的 loader 注入体例,不依赖 Isar。
void main() {
  Future<String> realLoad(String path) => File(path).readAsString();

  group('#4 门派/领地加载层强校验', () {
    test('stages/encounters 引的 factionId 不在 factions.yaml → 抛 StateError (声望 wire 静默兜底防线)',
        () async {
      // 只留 wudang(合法 alignment,过 ① 枚举校验),其余 factionId(shaolin/jiaoMen…)
      // 引用落空 → ② 引用校验抛错。
      Future<String> missingFactionLoader(String path) {
        if (path == 'data/factions.yaml') {
          return Future.value('''
factions:
  - id: wudang
    name: "武当派"
    alignment: orthodox
    npc_ids: []
''');
        }
        return realLoad(path);
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: missingFactionLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('不在 factions.yaml'),
        )),
      );
    });

    test('faction alignment 非 orthodox/neutral/evil → 抛 StateError', () async {
      Future<String> badAlignmentLoader(String path) {
        if (path == 'data/factions.yaml') {
          return Future.value('''
factions:
  - id: test_faction
    name: "测试门派"
    alignment: chaotic
    npc_ids: []
''');
        }
        return realLoad(path);
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: badAlignmentLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('alignment'), contains('非法')),
        )),
      );
    });

    test('territory baseDefenseLevel 越界 [1,7] → 抛 StateError', () async {
      Future<String> badTerritoryLoader(String path) {
        if (path == 'data/territories.yaml') {
          return Future.value('''
- id: test_territory
  name: "测试山头"
  description: "测试"
  baseDefenseLevel: 99
  initialOwnerSectId: null
''');
        }
        return realLoad(path);
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: badTerritoryLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('baseDefenseLevel'), contains('越界')),
        )),
      );
    });

    test('真实 factions/territories 现状对齐 → loadAllDefs 不抛 (回归守门)', () async {
      await GameRepository.loadAllDefs(loader: realLoad);
      // factions.yaml Demo 6 门派;全部 alignment 合法、被 stages/encounters 正确引用。
      expect(GameRepository.instance.factionAlignments.length, 6);
      expect(GameRepository.instance.territoryDefs, isNotEmpty);
    });
  });
}
