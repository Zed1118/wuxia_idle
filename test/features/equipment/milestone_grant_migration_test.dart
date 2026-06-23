import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';

void main() {
  test('SaveData.grantedMilestoneEquipmentIds 默认空集', () {
    final s = SaveData();
    expect(s.grantedMilestoneEquipmentIds, isEmpty);
  });
}
