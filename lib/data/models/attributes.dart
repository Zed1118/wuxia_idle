import 'package:isar/isar.dart';

/// 四项基础属性（data_schema.md §3.1 / GDD §4.1）。
///
/// 出生时按规则生成，单项 1-10、总和 16-24，不可重 roll。
/// 生涯总加成上限 +5（奇遇微弱后天弥补）。
@embedded
class Attributes {
  int constitution = 5;   // 根骨：影响血量上限
  int enlightenment = 5;  // 悟性：影响修炼速度、武学领悟概率
  int agility = 5;        // 身法：影响出手速度、闪避
  int fortune = 5;        // 机缘：影响奇遇触发率、商店折扣

  int get total => constitution + enlightenment + agility + fortune;
}
