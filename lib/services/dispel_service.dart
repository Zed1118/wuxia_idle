import 'package:isar_community/isar.dart';

import '../core/domain/character.dart';
import '../core/domain/enums.dart';
import '../core/domain/technique.dart';
import '../data/numbers_config.dart';

/// 散功结果（phase2_tasks T25）。
///
/// `outcome` 区分校验失败与成功：
///   - [DispelOutcome.success]：所有副作用已写到 [Character] / [Technique]
///   - 其余 3 类失败：调用前后状态完全未变（fail-fast，未触发任何字段写入）
class DispelResult {
  final DispelOutcome outcome;

  final int internalForceBefore;
  final int internalForceAfter;

  /// 散功前的 cultivationLayer（即 [TechniqueDispersion.disperse] 调用前的 layer，
  /// disperse 本身不动 layer，所以也 = disperse 后立即查到的 layer）。
  final CultivationLayer oldLayer;
  final CultivationLayer newLayer;
  final int layersRolledBack;
  final int progressAfter;
  final int progressToNextAfter;

  /// 旧主修是否因为辅修槽满 3 被剔除回背包（true = 没塞进 assistTechniqueIds）。
  final bool oldTechniqueDiscarded;

  const DispelResult({
    required this.outcome,
    this.internalForceBefore = 0,
    this.internalForceAfter = 0,
    this.oldLayer = CultivationLayer.chuKui,
    this.newLayer = CultivationLayer.chuKui,
    this.layersRolledBack = 0,
    this.progressAfter = 0,
    this.progressToNextAfter = 0,
    this.oldTechniqueDiscarded = false,
  });

  bool get success => outcome == DispelOutcome.success;
}

enum DispelOutcome {
  success,
  oldMainTechIsNotMain,            // mainTech.role != main
  newMainTechNotOwnedByCharacter,  // newMainTech.ownerCharacterId != ch.id
  newMainTechIsNotAssist,          // newMainTech.role != assist（必须从已学辅修挑）
}

/// Boss 战败被动散功结果（Phase 4 W10）。
///
/// 与 [DispelResult] 区别：
///   - **不换主修**：mainTech.role 保持 main，wasMainBeforeReset 不动
///   - **无 outcome enum**：调用方只对「有 mainTech 的参战角色」调用，无 fail-fast 分支
///   - **chuKui+progress=0 仍调用**：算 ×0.5 后仍为 0，layersRolledBack=0，无副作用
class DefeatPenaltyResult {
  final int internalForceBefore;
  final int internalForceAfter;

  /// applyDefeatPenalty 调用前的 cultivationLayer。
  final CultivationLayer oldLayer;

  /// progress ×0.5 + layer 反向重算后的 cultivationLayer。
  final CultivationLayer newLayer;

  /// 反向重算回退了几层（0 表示没回退）。
  final int layersRolledBack;

  final int progressBefore;
  final int progressAfter;
  final int progressToNextAfter;

  const DefeatPenaltyResult({
    required this.internalForceBefore,
    required this.internalForceAfter,
    required this.oldLayer,
    required this.newLayer,
    required this.layersRolledBack,
    required this.progressBefore,
    required this.progressAfter,
    required this.progressToNextAfter,
  });

  bool get didRollback => layersRolledBack > 0;
}

/// 散功服务（GDD §6 散功代价 / §4.3，phase2_tasks T25 §297-321）。
///
/// 双重惩罚（design 底线）：
///   - 内力 ×0.5（floor）
///   - 旧主修 cultivationProgress ×0.5（由 [TechniqueDispersion.disperse] 内执行）
///   - **额外**：cultivationLayer 反向重算（算法 A，progress 直接继承到回退后的 layer）
///
/// 副作用全部 in-place 写到 [Character] / [Technique]：
///   - 旧 mainTech: progress ×0.5 + role=assist + layer 回退
///   - 新 newMainTech: role=main
///   - Character: internalForce ×0.5 / mainTechniqueId / assistTechniqueIds 更新
///
/// **辅修槽满 3 处理**：旧主修挪回 assistTechniqueIds 时若槽已满 3，
/// 旧主修不入槽（[DispelResult.oldTechniqueDiscarded] = true，调用方决定是否回背包）。
///
/// **GameEvent 触发**：服务**不直接写 GameEvent**，由调用方根据 [DispelResult]
/// 自行触发（与 EnhancementService / TechniqueLearningService 一致：服务返回结果，
/// 副作用之 Isar 写入 / 事件流归 caller）。
class DispelService {
  const DispelService({required this.isar});

  final Isar isar;

  /// 纯函数：dispel 不用 Isar,保持 static（方便 caller 不需 service instance）。
  static DispelResult dispel({
    required Character ch,
    required Technique mainTech,
    required Technique newMainTech,
    required NumbersConfig n,
  }) {
    if (mainTech.role != TechniqueRole.main) {
      return const DispelResult(outcome: DispelOutcome.oldMainTechIsNotMain);
    }
    if (newMainTech.ownerCharacterId != ch.id) {
      return const DispelResult(
        outcome: DispelOutcome.newMainTechNotOwnedByCharacter,
      );
    }
    if (newMainTech.role != TechniqueRole.assist) {
      return const DispelResult(outcome: DispelOutcome.newMainTechIsNotAssist);
    }

    final ifBefore = ch.internalForce;
    ch.internalForce =
        (ch.internalForce * (1 - n.dispersionInternalForcePenalty)).toInt();

    final layerBefore = mainTech.cultivationLayer;
    mainTech.disperse(n);

    final layersRolledBack = _recalcLayerByRollback(
      mainTech,
      n.cultivationProgressToNext,
    );

    if (mainTech.cultivationLayer != CultivationLayer.jiJing) {
      mainTech.cultivationProgressToNext =
          n.cultivationProgressToNext[mainTech.cultivationLayer]!;
    }

    newMainTech.role = TechniqueRole.main;

    ch.mainTechniqueId = newMainTech.id;
    ch.assistTechniqueIds.remove(newMainTech.id);

    bool oldDiscarded = false;
    if (ch.assistTechniqueIds.length < 3) {
      ch.assistTechniqueIds.add(mainTech.id);
    } else {
      oldDiscarded = true;
    }

    return DispelResult(
      outcome: DispelOutcome.success,
      internalForceBefore: ifBefore,
      internalForceAfter: ch.internalForce,
      oldLayer: layerBefore,
      newLayer: mainTech.cultivationLayer,
      layersRolledBack: layersRolledBack,
      progressAfter: mainTech.cultivationProgress,
      progressToNextAfter: mainTech.cultivationProgressToNext,
      oldTechniqueDiscarded: oldDiscarded,
    );
  }

  /// T32 #22b：将 [dispel] 的 in-place 改写（ch.internalForce / mainTechniqueId /
  /// assistTechniqueIds、mainTech.disperse、newMainTech.role=main）落地 Isar。
  /// writeTxn 内 putAll 3 个对象。无物料消耗（散功代价是数值代价，已写进对象内）。
  Future<void> persistResult({
    required Character ch,
    required Technique mainTech,
    required Technique newMainTech,
  }) async {
    await isar.writeTxn(() async {
      await isar.characters.put(ch);
      await isar.techniques.put(mainTech);
      await isar.techniques.put(newMainTech);
    });
  }

  /// Boss 战败被动散功（Phase 4 W10）。调用方对每个**有主修**的参战角色调用一次。
  ///
  /// 与 [dispel] 区别（同复用 [_recalcLayerByRollback] 算法 A）：
  ///   - **不换主修**：不动 mainTech.role / wasMainBeforeReset / ch.mainTechniqueId
  ///   - **不调 [TechniqueDispersion.disperse]**：disperse 会同时改 role=assist + wasMainBeforeReset=true，
  ///     这两步在战败被动场景**绝对不要**做（玩家本次没换主修，下次仍用同一本）
  ///   - **使用独立 penalty 系数**：n.defeatBoss\* 系列（语义独立于 dispersion）
  ///
  /// 副作用：in-place 写 ch.internalForce + mainTech.cultivationProgress + cultivationLayer +
  /// cultivationProgressToNext。Isar 持久化由 caller 负责（同 dispel 的体例）。
  static DefeatPenaltyResult applyDefeatPenalty({
    required Character ch,
    required Technique mainTech,
    required NumbersConfig n,
  }) {
    final ifBefore = ch.internalForce;
    final progressBefore = mainTech.cultivationProgress;
    final layerBefore = mainTech.cultivationLayer;

    ch.internalForce =
        (ch.internalForce * (1 - n.defeatBossInternalForcePenalty)).toInt();
    mainTech.cultivationProgress =
        (mainTech.cultivationProgress * (1 - n.defeatBossCultivationPenalty))
            .toInt();

    final layersRolledBack = _recalcLayerByRollback(
      mainTech,
      n.cultivationProgressToNext,
    );

    if (mainTech.cultivationLayer != CultivationLayer.jiJing) {
      mainTech.cultivationProgressToNext =
          n.cultivationProgressToNext[mainTech.cultivationLayer]!;
    }

    return DefeatPenaltyResult(
      internalForceBefore: ifBefore,
      internalForceAfter: ch.internalForce,
      oldLayer: layerBefore,
      newLayer: mainTech.cultivationLayer,
      layersRolledBack: layersRolledBack,
      progressBefore: progressBefore,
      progressAfter: mainTech.cultivationProgress,
      progressToNextAfter: mainTech.cultivationProgressToNext,
    );
  }

  /// 反向重算算法 A（Pen 拍板）：
  ///
  /// 散功后 progress ×0.5，layer 不变。然后向下回退直到
  /// `progress >= 上一层升当前层所需 progress_required`，progress 直接继承
  /// 到回退后的 layer（不加 prev_required）。
  ///
  /// 例：
  ///   yuanMan/1500 → disperse → progress=750
  ///   prevReq(daCheng→yuanMan)=900；750<900 → 回退 daCheng/750
  ///   prevReq(zhongCheng→daCheng)=500；750>=500 → 停，结果 (daCheng, 750)
  ///
  /// chuKui 已是最低层，无法再回退。
  static int _recalcLayerByRollback(
    Technique tech,
    Map<CultivationLayer, int> progressToNextMap,
  ) {
    var rolled = 0;
    while (tech.cultivationLayer != CultivationLayer.chuKui) {
      final prev =
          CultivationLayer.values[tech.cultivationLayer.index - 1];
      final prevReq = progressToNextMap[prev];
      if (prevReq == null) {
        throw StateError(
          'cultivationProgressToNext 缺 ${prev.name} 的 progress_required',
        );
      }
      if (tech.cultivationProgress >= prevReq) break;
      tech.cultivationLayer = prev;
      rolled += 1;
    }
    return rolled;
  }
}
