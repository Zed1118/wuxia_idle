import 'package:isar/isar.dart';

/// 装备典故（data_schema.md §3.3 / GDD §6.6）。
///
/// 预设典故由 yaml 加载初始化，延续典故由战斗事件动态追加。
/// addedAt 默认值用 `DateTime(2000)`：`DateTime.now()` 作 isar 嵌入对象
/// 默认值在 isar_generator 偶发报错（phase1_tasks.md T03 提示），由调用方覆盖。
@embedded
class Lore {
  String text = '';
  bool isPreset = true;
  DateTime addedAt = DateTime(2000);
  String? triggerEventDesc;
}
