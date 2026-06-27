import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_setup.dart';
import '../../../data/slot_summary.dart';

part 'slot_list_provider.g.dart';

/// 存档槽摘要列表(存档选择屏用)。`ref.invalidate(slotListProvider)` 触发重读
/// 1..3 槽(新开/删除后刷新)。
@riverpod
Future<List<SlotSummary>> slotList(Ref ref) => IsarSetup.listSlots();
