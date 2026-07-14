import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../application/inner_demon_service.dart';
import 'inner_demon_def.dart';
import 'inner_demon_progress.dart';

/// 心魔面板渲染态(P0-3 ③)。
enum InnerDemonPanelState { cleared, blocked, inProgress }

/// 解析器产物 —— 渲染所需的纯数据(stage 名由 caller 用 stageDefs 解)。
class InnerDemonPanelData {
  final InnerDemonPanelState state;
  final int clearedCount;
  final int totalCount;

  /// blocked 态:拦截关 stage id(对应当前 layer)。
  final String? blockingStageId;

  /// inProgress 态:下一关 stage id(首个未通)。
  final String? nextStageId;

  const InnerDemonPanelData({
    required this.state,
    required this.clearedCount,
    required this.totalCount,
    this.blockingStageId,
    this.nextStageId,
  });
}

/// 角色 + 全局进度 + 心魔 def → 面板数据(null = 不显示 / shrink)。
///
/// 优先级:尚未到首节点 null > 全通 cleared > exp满且拦截 blocked > 其余 inProgress。
/// 不引新突破机制 —— 进阶仍自动(applyExperience),本解析仅决定展示态。
InnerDemonPanelData? resolveInnerDemonPanel({
  required Character character,
  required int experienceToNext,
  required InnerDemonProgress progress,
  required InnerDemonDef innerDemonDef,
}) {
  final total = progress.totalCount;
  // 无心魔配置(Demo / InnerDemonDef.empty)→ 无瓶颈可显,不出面板。
  if (total == 0) return null;
  final currentAbsoluteIndex = _absoluteIndex(
    character.realmTier,
    character.realmLayer,
  );
  final firstNodeAbsoluteIndex = innerDemonDef.requiredRealmLayer.values
      .map((coord) => _absoluteIndex(coord.tier, coord.layer))
      .reduce((a, b) => a < b ? a : b);
  if (currentAbsoluteIndex < firstNodeAbsoluteIndex) return null;
  if (progress.clearedCount >= total) {
    return InnerDemonPanelData(
      state: InnerDemonPanelState.cleared,
      clearedCount: progress.clearedCount,
      totalCount: total,
    );
  }

  final layerCount = RealmLayer.values.length;
  final maxAbsoluteIndex = RealmTier.values.length * layerCount - 1;
  final nextAbsoluteIndex = currentAbsoluteIndex < maxAbsoluteIndex
      ? currentAbsoluteIndex + 1
      : null;
  final nextTier = nextAbsoluteIndex == null
      ? null
      : RealmTier.values[nextAbsoluteIndex ~/ layerCount];
  final nextLayer = nextAbsoluteIndex == null
      ? null
      : RealmLayer.values[nextAbsoluteIndex % layerCount];
  final expFull =
      experienceToNext > 0 && character.experience >= experienceToNext;

  final locked =
      expFull &&
      nextTier != null &&
      nextLayer != null &&
      InnerDemonService.isLayerLocked(
        nextTier: nextTier,
        nextLayer: nextLayer,
        innerDemonDef: innerDemonDef,
        clearedStageIds: progress.clearedStageIds,
      );

  if (locked) {
    String? blockingStageId;
    for (final e in innerDemonDef.requiredRealmLayer.entries) {
      if (e.value.tier == character.realmTier &&
          e.value.layer == character.realmLayer) {
        blockingStageId = e.key;
        break;
      }
    }
    return InnerDemonPanelData(
      state: InnerDemonPanelState.blocked,
      clearedCount: progress.clearedCount,
      totalCount: total,
      blockingStageId: blockingStageId,
    );
  }

  return InnerDemonPanelData(
    state: InnerDemonPanelState.inProgress,
    clearedCount: progress.clearedCount,
    totalCount: total,
    nextStageId: progress.nextUnclearedStageId,
  );
}

int _absoluteIndex(RealmTier tier, RealmLayer layer) =>
    tier.index * RealmLayer.values.length + layer.index;
