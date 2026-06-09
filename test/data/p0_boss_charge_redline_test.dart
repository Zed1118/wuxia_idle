import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// P0 破招 · Boss 蓄力技红线校验测族（spec §9.1）。
///
/// 覆盖维度:
/// - **正常**:production stages.yaml stage_02_05 青衫剑客 chargeSkillId ==
///   `skill_lingqiao_jichu_skill` 且在其 skillIds 内 → 不抛。
/// - **非法 chargeSkillId**:transform 把 Boss chargeSkillId 改成不在 skillIds 的 id
///   → `_enforceBossChargeRedLines` 抛 StateError。
/// - **chargeTicks 越界**:transform numbers.yaml boss_charge default_charge_ticks
///   改成 0 / 99 → 抛 StateError。
///
/// **fixture 策略**(沿 stage_boss_recruit_test brokenLoader 体例):读 production
/// yaml 后字符串 replace 1 处 inject 触发红线,不破其他 production 红线。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  /// transform 模式:对指定 path 应用 transform,其余 path 读原文。
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

  group('正常 · production stages.yaml stage_02_05 青衫剑客 chargeSkillId', () {
    test('chargeSkillId == skill_lingqiao_jichu_skill 且在 skillIds 内 → 不抛', () {
      final repo = GameRepository.instance;
      final stage = repo.stageDefs['stage_02_05'];
      expect(stage, isNotNull, reason: 'stage_02_05 应在 stages.yaml 中');
      final boss = stage!.enemyTeam
          .firstWhere((e) => e.id == 'enemy_sanLiu_qingshan_main');
      expect(boss.chargeSkillId, 'skill_lingqiao_jichu_skill',
          reason: 'spec §9.1 决策:招牌蓄力技用 powerSkill 不用 _ult');
      expect(boss.skillIds, contains(boss.chargeSkillId),
          reason: 'chargeSkillId 必在敌人 skillIds 内');
    });
  });

  group('非法 chargeSkillId · broken loader transform(stages.yaml)', () {
    test('青衫剑客 chargeSkillId 改成不在 skillIds 的 id → 抛 StateError', () async {
      String inject(String s) => s.replaceFirst(
            'chargeSkillId: skill_lingqiao_jichu_skill',
            'chargeSkillId: skill_ghost_not_in_skill_ids',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/stages.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('skill_ghost_not_in_skill_ids'),
        )),
      );
    });
  });

  group('chargeTicks 越界 · broken loader transform(numbers.yaml)', () {
    test('default_charge_ticks 改成 0 → 抛 StateError', () async {
      String inject(String s) => s.replaceFirst(
            'default_charge_ticks: 3',
            'default_charge_ticks: 0',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/numbers.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('defaultChargeTicks'),
        )),
      );
    });

    test('default_charge_ticks 改成 99 → 抛 StateError', () async {
      String inject(String s) => s.replaceFirst(
            'default_charge_ticks: 3',
            'default_charge_ticks: 99',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/numbers.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('defaultChargeTicks'),
        )),
      );
    });
  });
}
