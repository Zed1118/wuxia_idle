import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';

void main() {
  test('新 SaveData 的江湖远行永久进度字段取安全默认', () {
    final save = SaveData();
    expect(save.jianghuJourneyUnlocked, isFalse);
    expect(save.baicaoMaxDepth, 0);
    expect(save.expeditionRunSerial, 0);
    expect(save.clearedGauntletIds, isEmpty);
    expect(save.duanhunFirstClearedAt, isNull);
    expect(save.grantedTicketMilestoneIds, isEmpty);
  });
}
