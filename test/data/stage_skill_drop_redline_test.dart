import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  tearDown(GameRepository.resetForTest);

  Future<String> Function(String) makeStagesLoader(
      String Function(String original) transform) {
    Future<String> loader(String path) async {
      final original = await File(path).readAsString();
      if (path == 'data/stages.yaml') return transform(original);
      return original;
    }
    return loader;
  }

  test('正例:production stages 无非法 dropSkill → 不抛', () async {
    await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    expect(GameRepository.isLoaded, true);
  });

  test('① 非 Boss 关配 dropSkillManualId → 抛 StateError(isBossStage=false)', () async {
    // stage_01_01 非 Boss · dropEquipmentDefIds: [armor_xunchang_bu_yi] unique 锚
    String inject(String s) => s.replaceFirst(
          'dropEquipmentDefIds: [armor_xunchang_bu_yi]',
          'dropSkillManualId: skill_qingshan_qingfeng\n    '
              'dropEquipmentDefIds: [armor_xunchang_bu_yi]',
        );
    expect(
      GameRepository.loadAllDefs(loader: makeStagesLoader(inject)),
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', contains('isBossStage=false'))),
    );
  });

  test('② Boss 关配不存在的 dropSkillManualId → 抛 StateError(id 未在 skills.yaml)',
      () async {
    // stage_01_05 是 Boss(candidateRef: bamboo_swordsman unique 锚),旁注入幽灵 skill id
    // stage_01_05 现配 dropSkillManualId: skill_yinrou_mingjia_ult(D1);替为幽灵 id。
    String inject(String s) => s.replaceFirst(
          'dropSkillManualId: skill_yinrou_mingjia_ult',
          'dropSkillManualId: ghost_skill_not_loaded',
        );
    expect(
      GameRepository.loadAllDefs(loader: makeStagesLoader(inject)),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('ghost_skill_not_loaded'))),
    );
  });
}
