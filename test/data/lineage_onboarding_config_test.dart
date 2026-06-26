import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('LineageOnboardingConfig 解析 2 个拜入触发(01_02→senior / 01_04→junior)', () {
    final cfg = LineageOnboardingConfig.fromYaml({
      'disciple_joins': [
        {
          'stage_id': 'stage_02_05',
          'master_slot_index': 1,
          'role': 'senior',
          'narrative_id': 'lineage_first_disciple_join',
        },
        {
          'stage_id': 'stage_03_05',
          'master_slot_index': 2,
          'role': 'junior',
          'narrative_id': 'lineage_second_disciple_join',
        },
      ],
    });
    expect(cfg.discipleJoins.length, 2);
    expect(cfg.discipleJoins[0].stageId, 'stage_02_05');
    expect(cfg.discipleJoins[0].masterSlotIndex, 1);
    expect(cfg.discipleJoins[0].role, LineageRole.senior);
    expect(cfg.discipleJoins[0].narrativeId, 'lineage_first_disciple_join');
    expect(cfg.discipleJoins[1].role, LineageRole.junior);
    expect(cfg.discipleJoins[1].narrativeId, 'lineage_second_disciple_join');
    expect(cfg.joinStageIds, {'stage_02_05', 'stage_03_05'});
  });

  test('null yaml → 空配置(default-safe)', () {
    final cfg = LineageOnboardingConfig.fromYaml(null);
    expect(cfg.discipleJoins, isEmpty);
  });
}
