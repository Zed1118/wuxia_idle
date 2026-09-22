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

  test(
    'recorded seconds are immutable and empty never revives legacy turns',
    () {
      final member = ActivityMemberSnapshot()
        ..skillCooldownKeys = ['old-skill']
        ..skillCooldownTurns = [3]
        ..phase0aCooldownsRecorded = true
        ..phase0aCooldownKeys = ['gather', 'phase0a_skill_1']
        ..phase0aCooldownSeconds = [2.8, 0.125];
      final snapshot = member.phase0aCooldownSnapshot();
      member.phase0aCooldownKeys.clear();
      member.phase0aCooldownSeconds.clear();
      expect(snapshot, {'gather': 2.8, 'phase0a_skill_1': 0.125});
      expect(() => snapshot['gather'] = 0, throwsUnsupportedError);
      expect(member.phase0aCooldownSnapshot(), isEmpty);
      expect(member.skillCooldownKeys, ['old-skill']);
      expect(member.skillCooldownTurns, [3]);
    },
  );

  test(
    'malformed persisted seconds fail closed instead of clearing cooldowns',
    () {
      final invalid = [
        ActivityMemberSnapshot()..phase0aCooldownKeys = ['gather'],
        ActivityMemberSnapshot()..phase0aCooldownSeconds = [2.8],
        ActivityMemberSnapshot()
          ..phase0aCooldownsRecorded = true
          ..phase0aCooldownKeys = ['gather'],
        ActivityMemberSnapshot()
          ..phase0aCooldownsRecorded = true
          ..phase0aCooldownSeconds = [2.8],
        ActivityMemberSnapshot()
          ..phase0aCooldownsRecorded = true
          ..phase0aCooldownKeys = ['gather', 'gather']
          ..phase0aCooldownSeconds = [2.8, 1.1],
        for (final seconds in [0.0, -0.1, double.nan, double.infinity])
          ActivityMemberSnapshot()
            ..phase0aCooldownsRecorded = true
            ..phase0aCooldownKeys = ['gather']
            ..phase0aCooldownSeconds = [seconds],
        ActivityMemberSnapshot()
          ..phase0aCooldownsRecorded = true
          ..phase0aCooldownKeys = [' ']
          ..phase0aCooldownSeconds = [1.1],
      ];
      for (final member in invalid) {
        expect(member.phase0aCooldownSnapshot, throwsStateError);
      }
    },
  );
}
