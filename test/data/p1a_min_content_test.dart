import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  test('当前发布阶 2 本主线真解挂载，高阶真解暂不投放', () {
    final repo = GameRepository.instance;
    for (final sid in ['stage_01_05', 'stage_02_05']) {
      final m = repo.stageDefs[sid]!.dropSkillManualId;
      expect(m, isNotNull, reason: '$sid 应配真解');
      expect(
        repo.skillDefs[m],
        isNotNull,
        reason: '$sid 真解 id=$m 应在 skills.yaml',
      );
    }
    expect(
      repo.stageDefs['stage_02_05']!.dropSkillManualId,
      'skill_qingshan_qingfeng',
    );
    expect(repo.stageDefs['stage_03_05']!.dropSkillManualId, isNull);
  });

  test('真解/破势/青锋绝 配 proficiency.effects', () {
    final repo = GameRepository.instance;
    expect(repo.skillDefs['skill_qingshan_qingfeng']!.proficiency, isNotNull);
    expect(repo.skillDefs['skill_po_shi']!.proficiency, isNotNull);
    expect(repo.skillDefs['skill_yinrou_mingjia_ult']!.proficiency, isNotNull);
    expect(
      repo.skillDefs['skill_gangmeng_mingjia_ult']!.proficiency,
      isNotNull,
    );
  });
}
