import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

/// 健康报告 #3 收口（2026-06-25）：encounter_skills.yaml 池中**每一招**都必须
/// 被至少一个 encounter 的 `unlockSkill` outcome 引用——否则玩家无任何路径解锁
/// (唯一解锁路径 = encounter unlockSkill → SaveData.skillUnlockProgress)。
///
/// 此前 40 招池仅 29 招接线,11 招搁浅不可达(漏接非预留,详
/// docs/spec/2026-06-25-wire-11-encounter-skills-design.md)。本测红线锁死
/// 「池全接线」,防止再有招式创作完却无 encounter 解锁。
///
/// 不依赖 Isar(纯 GameRepository.loadAllDefs 路径)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('encounter_skills 池全部招式都被某 encounter unlockSkill outcome 引用(0 搁浅)',
      () {
    final repo = GameRepository.instance;
    final pool = repo.encounterSkillIds.toSet();
    final referenced = <String>{
      for (final enc in repo.allEncounters)
        for (final outcome in enc.outcomeMapping.values)
          if (outcome.type == OutcomeType.unlockSkill && outcome.skillId != null)
            outcome.skillId!,
    };
    final stranded = pool.difference(referenced);
    expect(
      stranded,
      isEmpty,
      reason: '以下 encounter skill 无任何 encounter 解锁(玩家不可达,内容搁浅):'
          '$stranded —— 需补 encounter unlockSkill outcome 或裁池',
    );
  });
}
