import 'inner_demon_def.dart';

/// 心魔通关全局进度(P0-3 ③)。数据单一真相源 = MainlineProgress.clearedStageIds,
/// 本类只做派生计算,不另存状态。
class InnerDemonProgress {
  /// 已通关心魔关数(clearedStageIds 中 stage_inner_demon_* 计数)。
  final int clearedCount;

  /// 心魔关总数(派生自 innerDemonDef.requiredRealmLayer,不硬编码 7)。
  final int totalCount;

  /// 已通关 stage id 全集(供解析器复算拦截)。
  final Set<String> clearedStageIds;

  /// 按 stage_inner_demon_01..NN 顺序第一个未通关关(null = 全通)。
  final String? nextUnclearedStageId;

  const InnerDemonProgress({
    required this.clearedCount,
    required this.totalCount,
    required this.clearedStageIds,
    required this.nextUnclearedStageId,
  });

  static const String _prefix = 'stage_inner_demon_';

  factory InnerDemonProgress.from({
    required InnerDemonDef innerDemonDef,
    required Set<String> clearedStageIds,
  }) {
    final demonStages = innerDemonDef.requiredRealmLayer.keys
        .where((k) => k.startsWith(_prefix))
        .toList()
      ..sort();
    final cleared = demonStages.where(clearedStageIds.contains).length;
    String? next;
    for (final s in demonStages) {
      if (!clearedStageIds.contains(s)) {
        next = s;
        break;
      }
    }
    return InnerDemonProgress(
      clearedCount: cleared,
      totalCount: demonStages.length,
      clearedStageIds: clearedStageIds,
      nextUnclearedStageId: next,
    );
  }
}
