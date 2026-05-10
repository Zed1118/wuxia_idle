import 'package:isar/isar.dart';

import 'enums.dart';

/// 开锋槽位（data_schema.md §3.2 / GDD §6.5）。
///
/// 每件装备恒为 3 个槽，分别在强化 +10 / +15 / +19 解锁。第 3 槽允许
/// type=specialSkill，此时 specialSkillId 指向招式 defId。
@embedded
class ForgingSlot {
  int slotIndex = 1;

  @Enumerated(EnumType.name)
  ForgingSlotType? type;

  bool unlocked = false;
  int bonusValue = 0;
  String? specialSkillId;
}
