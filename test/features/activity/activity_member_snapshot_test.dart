import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';

void main() {
  test('成员快照默认值安全，保留 id 列表可写', () {
    final m = ActivityMemberSnapshot()
      ..characterId = 7
      ..reservedEquipmentIds = [11, 12]
      ..reservedTechniqueIds = [3]
      ..currentHp = 500
      ..currentQi = 40
      ..isDowned = false;
    expect(m.characterId, 7);
    expect(m.reservedEquipmentIds, [11, 12]);
    expect(m.reservedTechniqueIds, [3]);
    expect(ActivityMemberSnapshot().isDowned, isFalse);
  });
}
