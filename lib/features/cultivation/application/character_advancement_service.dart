import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/realm_def.dart';
import '../domain/realm_progress_display.dart';

/// 角色境界推进服务(W15 #30 第 3 期 experiencePoints 消费层)。
///
/// 把闭关 / 主线 victory / 塔 victory 三贡献源累加到 [Character.experience],
/// 然后 while-loop 消费成 layer/tier 升层。升层后从 [RealmDef] 拉新
/// `internalForceMax` / `experienceToNextLayer`;**不动 attributes**,
/// **不回血 `internalForce`**(GDD §5.1 反留存焦虑,升层奖励不"回血"。
/// 玩家若需补内力走闭关 + 内力维度,设计闭环)。
///
/// 顶级 `wuSheng.dengFeng` 使用终局修为刻度派生 Lv481～490。
/// 命中刻度后 EXP 仍可累加，但 [nextLayer] 返回 null，不会扣减
/// 经验或产生第 50 个境界层。
class CharacterAdvancementService {
  CharacterAdvancementService._();

  /// 累加 [delta] EXP 并 while-loop 升层至剩余 EXP 不足或满级。
  ///
  /// [realmLookup] 注入便于 test(生产路径走
  /// `GameRepository.instance.getRealm`)。
  ///
  /// [isLayerLocked] 心魔关 unlock 拦截 hook(1.0 P2.2 §12.1,Batch 2.2.A)。
  /// 注入函数接 `(nextTier, nextLayer)` 返 true → 升层被拦,EXP 留账不消费
  /// (GDD §5.1 反留存焦虑 + spec §三 — 玩家挂机攒 EXP,过心魔关后立刻全部
  /// 消费多 layer)。null = 不拦截(test fixture / Batch 2.2.A 前 caller 默认)。
  /// 实装见 `lib/features/inner_demon/application/inner_demon_service.dart`
  /// `InnerDemonService.isLayerLocked`。
  ///
  /// **副作用(in-place 写 [ch])**:
  ///   - `ch.experience += delta`,while 内累减
  ///   - 升层时 `realmTier` / `realmLayer` 推下一档
  ///   - 升层时 `internalForceMax` / `experienceToNextLayer` 从下一档 [RealmDef] 刷新
  ///
  /// **不动**:`internalForce`(不回血) / `attributes`(根骨/身法/悟性/机缘
  /// 是 character base,升层不变)。
  static AdvancementResult applyExperience(
    Character ch,
    int delta, {
    required RealmDef Function(RealmTier, RealmLayer) realmLookup,
    bool Function(RealmTier, RealmLayer)? isLayerLocked,
  }) {
    final tierBefore = ch.realmTier;
    final layerBefore = ch.realmLayer;
    final maxBefore = ch.internalForceMax;
    final beforeDef = realmLookup(tierBefore, layerBefore);
    final progressBefore = RealmProgressDisplay.fromSnapshot(
      absoluteRealmLevel: beforeDef.absoluteLevel,
      experience: ch.experience,
      experienceToNext: beforeDef.experienceToNext,
      hasNextRealmLayer: nextLayer(tierBefore, layerBefore) != null,
    );

    if (delta <= 0) {
      return AdvancementResult(
        layersGained: 0,
        tierBefore: tierBefore,
        layerBefore: layerBefore,
        tierAfter: tierBefore,
        layerAfter: layerBefore,
        internalForceMaxBefore: maxBefore,
        internalForceMaxAfter: maxBefore,
        experienceGained: 0,
        progressChange: RealmProgressChange(
          before: progressBefore,
          after: progressBefore,
        ),
      );
    }

    var currentDef = beforeDef;
    ch.experience += delta;
    int layersGained = 0;

    while (true) {
      final threshold = currentDef.experienceToNext;
      if (threshold <= 0) break; // 损坏配置安全网
      if (ch.experience < threshold) break;

      final next = nextLayer(ch.realmTier, ch.realmLayer);
      if (next == null) break; // 终局刻度达成，EXP 保留且不产生第 50 层

      // 1.0 P2.2 §12.1 心魔关 unlock 拦截 hook(Batch 2.2.A):
      // 升入 wuSheng 各 layer 前查心魔关 cleared 集;未 cleared → break
      // (EXP 不归零,玩家攒着,过关后立刻全部消费多 layer)。
      if (isLayerLocked != null && isLayerLocked(next.tier, next.layer)) {
        break;
      }

      ch.experience -= threshold;
      ch.realmTier = next.tier;
      ch.realmLayer = next.layer;
      currentDef = realmLookup(next.tier, next.layer);
      ch.internalForceMax = currentDef.internalForceMax;
      layersGained++;
    }

    ch.experienceToNextLayer = currentDef.experienceToNext;

    final afterDef = realmLookup(ch.realmTier, ch.realmLayer);
    final progressAfter = RealmProgressDisplay.fromSnapshot(
      absoluteRealmLevel: afterDef.absoluteLevel,
      experience: ch.experience,
      experienceToNext: afterDef.experienceToNext,
      hasNextRealmLayer: nextLayer(ch.realmTier, ch.realmLayer) != null,
    );
    return AdvancementResult(
      layersGained: layersGained,
      tierBefore: tierBefore,
      layerBefore: layerBefore,
      tierAfter: ch.realmTier,
      layerAfter: ch.realmLayer,
      internalForceMaxBefore: maxBefore,
      internalForceMaxAfter: ch.internalForceMax,
      experienceGained: delta,
      progressChange: RealmProgressChange(
        before: progressBefore,
        after: progressAfter,
      ),
    );
  }

  /// 给定 (tier, layer) 返回升一档后的 (tier, layer);wuSheng.dengFeng 返回 null。
  ///
  /// dengFeng → 下一 tier 的 qiMeng;其他 layer → 同 tier 下一 layer。
  static ({RealmTier tier, RealmLayer layer})? nextLayer(
    RealmTier tier,
    RealmLayer layer,
  ) {
    if (layer != RealmLayer.dengFeng) {
      final layers = RealmLayer.values;
      final i = layers.indexOf(layer);
      return (tier: tier, layer: layers[i + 1]);
    }
    final tiers = RealmTier.values;
    final i = tiers.indexOf(tier);
    if (i == tiers.length - 1) return null;
    return (tier: tiers[i + 1], layer: RealmLayer.qiMeng);
  }
}

/// [CharacterAdvancementService.applyExperience] 返回值。
///
/// caller 用 [didAdvance] / [layersGained] 决定 UI 升层 banner;Before/After
/// 字段用于「突破至 XXX·XXX」摘要展示。
class AdvancementResult {
  final int layersGained;
  final RealmTier tierBefore;
  final RealmLayer layerBefore;
  final RealmTier tierAfter;
  final RealmLayer layerAfter;
  final int internalForceMaxBefore;
  final int internalForceMaxAfter;
  final int experienceGained;
  final RealmProgressChange progressChange;

  const AdvancementResult({
    required this.layersGained,
    required this.tierBefore,
    required this.layerBefore,
    required this.tierAfter,
    required this.layerAfter,
    required this.internalForceMaxBefore,
    required this.internalForceMaxAfter,
    this.experienceGained = 0,
    this.progressChange = RealmProgressChange.none,
  });

  bool get didAdvance => layersGained > 0;

  /// H2 C2:大境界突破 — 升层且跨越了境界 tier(三流→二流等)。
  /// UI 据此走全屏庆祝路径,区别于同境界内的小层升级。
  bool get crossedTier => didAdvance && tierAfter != tierBefore;
}
