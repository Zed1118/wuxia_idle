import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// C2 [审计 2026-06-24]:奇遇 events yaml 加载层强校验。
///
/// GDD §8.1 明文「id 必须严格相等且唯一,加载时若任一端缺失对应 id 直接抛错
/// 而非静默跳过」。此前 `EncounterEventLoader.load` catch 全吞返 placeholder,
/// 启动期从不校验 events 文件 → 缺文件显示「[文案待补]」、坏 outcome_id 静默
/// fallback `OutcomeType.none`(奖励无声丢失)。仿 lore `_validatePresetLoreReferences`
/// 在 `loadAllDefs` 末尾加启动期强校验,兑现文档承诺。
///
/// 不依赖 Isar(纯 `GameRepository.loadAllDefs` 路径)。
void main() {
  Future<String> realLoad(String path) => File(path).readAsString();

  group('C2 奇遇 events 加载层强校验', () {
    test('缺 events/<id>.yaml 时 loadAllDefs 抛 StateError (违 §8.1 任一端缺失直接抛错)',
        () async {
      Future<String> missingEventsLoader(String path) {
        if (path == 'data/events/bamboo_listen_rain.yaml') {
          throw const FileSystemException('simulated missing events file');
        }
        return realLoad(path);
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: missingEventsLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('bamboo_listen_rain'),
        )),
      );
    });

    test('events choice outcome_id 不在 outcomeMapping 时抛 StateError (防奖励静默丢失)',
        () async {
      Future<String> badOutcomeLoader(String path) {
        if (path == 'data/events/bamboo_listen_rain.yaml') {
          return Future.value('''
id: bamboo_listen_rain
title: 测试
opening: 测试开场
choices:
  - text: 越界选项
    outcome_id: nonexistent_outcome_id
''');
        }
        return realLoad(path);
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: badOutcomeLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('nonexistent_outcome_id'), contains('outcomeMapping')),
        )),
      );
    });

    test('events yaml 内 id 与 encounter id 不自洽时抛 StateError', () async {
      Future<String> idMismatchLoader(String path) {
        if (path == 'data/events/bamboo_listen_rain.yaml') {
          return Future.value('''
id: wrong_internal_id
title: 测试
opening: 测试开场
choices:
  - text: 跳过
    outcome_id: skip
''');
        }
        return realLoad(path);
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: idMismatchLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('不自洽'),
        )),
      );
    });

    test('真实 data/events 全 68 条对齐 → loadAllDefs 不抛 (回归守门 · 68/68 干净)',
        () async {
      // 真实 loader 全量加载,校验通过即不抛。
      await GameRepository.loadAllDefs(loader: realLoad);
      expect(GameRepository.instance.encounterDefs.length, 68);
    });
  });
}
