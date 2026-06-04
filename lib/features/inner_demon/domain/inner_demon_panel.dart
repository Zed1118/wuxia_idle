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
/// 优先级:非武圣 null > 全通 cleared > exp满且拦截 blocked > 其余 inProgress。
/// 不引新突破机制 —— 进阶仍自动(applyExperience),本解析仅决定展示态。
InnerDemonPanelData? resolveInnerDemonPanel({
  required Character character,
  required InnerDemonProgress progress,
  required InnerDemonDef innerDemonDef,
}) {
  if (character.realmTier != RealmTier.wuSheng) return null;

  final total = progress.totalCount;
  if (total > 0 && progress.clearedCount >= total) {
    return InnerDemonPanelData(
      state: InnerDemonPanelState.cleared,
      clearedCount: progress.clearedCount,
      totalCount: total,
    );
  }

  const layers = RealmLayer.values;
  final idx = layers.indexOf(character.realmLayer);
  final hasNext = idx >= 0 && idx < layers.length - 1;
  final nextLayer = hasNext ? layers[idx + 1] : null;
  final expFull = character.experience >= character.experienceToNextLayer;

  final locked = expFull &&
      nextLayer != null &&
      InnerDemonService.isLayerLocked(
        nextTier: RealmTier.wuSheng,
        nextLayer: nextLayer,
        innerDemonDef: innerDemonDef,
        clearedStageIds: progress.clearedStageIds,
      );

  if (locked) {
    String? blockingStageId;
    for (final e in innerDemonDef.requiredRealmLayer.entries) {
      if (e.value.tier == RealmTier.wuSheng &&
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
