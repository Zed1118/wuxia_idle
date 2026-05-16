import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';

void main() {
  group('MapLikeOnSkillUsage', () {
    test('increment 在不存在的 key 上应追加新条目', () {
      final list = <SkillUsageEntry>[];

      list.increment('skill_yi_jin_jing_3');

      expect(list, hasLength(1));
      expect(list.single.skillId, 'skill_yi_jin_jing_3');
      expect(list.single.count, 1);
    });

    test('increment 在已有 key 上应累加而非追加', () {
      final list = <SkillUsageEntry>[];

      list.increment('skill_a');
      list.increment('skill_a', 5);
      list.increment('skill_a');

      expect(list, hasLength(1));
      expect(list.single.count, 7);
    });

    test('increment 写入应回写到原 List 中的同一对象', () {
      final list = <SkillUsageEntry>[
        SkillUsageEntry()
          ..skillId = 'skill_a'
          ..count = 10,
      ];
      final original = list.first;

      list.increment('skill_a', 3);

      expect(list, hasLength(1));
      expect(identical(list.first, original), isTrue,
          reason: 'increment 必须修改原对象，而不是替换为 firstWhere orElse 的临时对象');
      expect(list.first.count, 13);
    });

    test('countOf 对不存在的 key 应返回 0', () {
      final list = <SkillUsageEntry>[
        SkillUsageEntry()
          ..skillId = 'skill_a'
          ..count = 42,
      ];

      expect(list.countOf('skill_a'), 42);
      expect(list.countOf('skill_does_not_exist'), 0);
    });
  });

  group('MapLikeOnRewards', () {
    test('quantityOf 命中已有 rewardKey 应返回数量', () {
      final list = <RewardEntry>[
        RewardEntry()
          ..rewardKey = 'item_mojianshi'
          ..quantity = 6,
        RewardEntry()
          ..rewardKey = 'exp'
          ..quantity = 1500,
      ];

      expect(list.quantityOf('item_mojianshi'), 6);
      expect(list.quantityOf('exp'), 1500);
    });

    test('quantityOf 对不存在的 rewardKey 应返回 0', () {
      final list = <RewardEntry>[
        RewardEntry()
          ..rewardKey = 'exp'
          ..quantity = 1500,
      ];

      expect(list.quantityOf('item_does_not_exist'), 0);
      expect(<RewardEntry>[].quantityOf('any'), 0);
    });
  });
}
