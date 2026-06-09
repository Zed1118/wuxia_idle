import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';

void main() {
  test('MapLike: addFragment 累加 + unlock 标记幂等', () {
    final list = <SkillUnlockEntry>[];
    expect(list.isUnlocked('s1'), false);
    expect(list.fragmentCountOf('s1'), 0);

    list.addFragment('s1', 3);
    expect(list.fragmentCountOf('s1'), 3);
    list.addFragment('s1', 2);
    expect(list.fragmentCountOf('s1'), 5);

    list.markUnlocked('s1');
    expect(list.isUnlocked('s1'), true);
    list.markUnlocked('s1'); // 幂等
    expect(list.where((e) => e.skillId == 's1').length, 1);
  });

  test('markUnlocked 对未存在 skillId 新建条目', () {
    final list = <SkillUnlockEntry>[];
    list.markUnlocked('s2');
    expect(list.isUnlocked('s2'), true);
    expect(list.length, 1);
  });
}
