import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/realm_def.dart';

/// 角色境界推进服务(W15 #30 第 3 期 experiencePoints 消费层)。
///
/// 把闭关 / 主线 victory / 塔 victory 三贡献源累加到 [Character.experience],
/// 然后 while-loop 消费成 layer/tier 升层。升层后从 [RealmDef] 拉新
/// `internalForceMax` / `experienceToNextLayer`;**不动 attributes**,
/// **不回血 `internalForce`**(GDD §5.1 反留存焦虑,升层奖励不"回血"。
/// 玩家若需补内力走闭关 + 内力维度,设计闭环)。
///
/// 顶级 `wuSheng.dengFeng` 的 `experienceToNext: 0` 在 yaml 表示满级。
/// 命中后 EXP 仍可累加(数据无破坏)但不再扣减不再升层。
class CharacterAdvancementService {
  CharacterAdvancementService._();

  /// 累加 [delta] EXP 并 while-loop 升层至剩余 EXP 不足或满级。
  ///
  /// [realmLookup] 注入便于 test(生产路径走
  /// `GameRepository.instance.getRealm`)。
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
  }) {
    final tierBefore = ch.realmTier;
    final layerBefore = ch.realmLayer;
    final maxBefore = ch.internalForceMax;

    if (delta <= 0) {
      return AdvancementResult(
        layersGained: 0,
        tierBefore: tierBefore,
        layerBefore: layerBefore,
        tierAfter: tierBefore,
        layerAfter: layerBefore,
        internalForceMaxBefore: maxBefore,
        internalForceMaxAfter: maxBefore,
      );
    }

    ch.experience += delta;
    int layersGained = 0;

    while (true) {
      if (ch.experienceToNextLayer <= 0) break; // wuSheng.dengFeng 满级
      if (ch.experience < ch.experienceToNextLayer) break;

      final next = nextLayer(ch.realmTier, ch.realmLayer);
      if (next == null) break; // 安全网:experienceToNextLayer=0 已 break

      ch.experience -= ch.experienceToNextLayer;
      ch.realmTier = next.tier;
      ch.realmLayer = next.layer;
      final def = realmLookup(next.tier, next.layer);
      ch.internalForceMax = def.internalForceMax;
      ch.experienceToNextLayer = def.experienceToNext;
      layersGained++;
    }

    return AdvancementResult(
      layersGained: layersGained,
      tierBefore: tierBefore,
      layerBefore: layerBefore,
      tierAfter: ch.realmTier,
      layerAfter: ch.realmLayer,
      internalForceMaxBefore: maxBefore,
      internalForceMaxAfter: ch.internalForceMax,
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

  const AdvancementResult({
    required this.layersGained,
    required this.tierBefore,
    required this.layerBefore,
    required this.tierAfter,
    required this.layerAfter,
    required this.internalForceMaxBefore,
    required this.internalForceMaxAfter,
  });

  bool get didAdvance => layersGained > 0;
}
