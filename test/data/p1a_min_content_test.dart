import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  test('3 主线章末 Boss 配 dropSkillManualId 且 id 在 skills.yaml', () {
    final repo = GameRepository.instance;
    for (final sid in ['stage_01_05', 'stage_02_05', 'stage_03_05']) {
      final m = repo.stageDefs[sid]!.dropSkillManualId;
      expect(m, isNotNull, reason: '$sid 应配真解');
      expect(repo.skillDefs[m], isNotNull, reason: '$sid 真解 id=$m 应在 skills.yaml');
    }
    expect(repo.stageDefs['stage_02_05']!.dropSkillManualId,
        'skill_qingshan_qingfeng');
  });

  test('真解/破势/青锋绝 配 proficiency.effects', () {
    final repo = GameRepository.instance;
    expect(repo.skillDefs['skill_qingshan_qingfeng']!.proficiency, isNotNull);
    expect(repo.skillDefs['skill_po_shi']!.proficiency, isNotNull);
    expect(repo.skillDefs['skill_yinrou_mingjia_ult']!.proficiency, isNotNull);
    expect(repo.skillDefs['skill_gangmeng_mingjia_ult']!.proficiency, isNotNull);
  });
}
