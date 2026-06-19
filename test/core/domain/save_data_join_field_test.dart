import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';

void main() {
  test('SaveData.triggeredDiscipleJoinStageIds 默认空 + 可追加', () {
    final s = SaveData();
    expect(s.triggeredDiscipleJoinStageIds, isEmpty);
    s.triggeredDiscipleJoinStageIds = [...s.triggeredDiscipleJoinStageIds, 'stage_01_02'];
    expect(s.triggeredDiscipleJoinStageIds, ['stage_01_02']);
  });
}
