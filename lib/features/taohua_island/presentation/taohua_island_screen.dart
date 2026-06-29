import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../features/battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/island_action_service.dart';
import '../application/island_providers.dart';
import '../application/island_settle_service.dart';
import '../domain/island_building_state.dart';
import '../domain/island_building_type.dart';
import '../domain/island_prep_advice.dart';
import '../domain/taohua_island_config.dart';
import 'island_recap_card.dart';

/// 桃花岛主屏：据点分区 + 升级 / 选配方 / 一并收取。
///
/// 数据全来自 [taohuaIslandViewProvider]（进屏 settle gate），
/// 操作后 `ref.invalidate(taohuaIslandViewProvider)` 刷新。
/// 中文全走 [UiStrings] / [EnumL10n]，不散写字面量（§5.6）。
/// Scaffold 必带 AppBar（踩坑记录：feedback_flutter_subscreen_appbar_audit）。
class TaohuaIslandScreen extends ConsumerWidget {
  const TaohuaIslandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncView = ref.watch(taohuaIslandViewProvider);

    return Scaffold(
      backgroundColor: WuxiaUi.paper,
      appBar: AppBar(
        backgroundColor: WuxiaUi.ink,
        foregroundColor: WuxiaUi.paper,
        title: const Text(
          UiStrings.taohuaIslandTitle,
          style: TextStyle(
            color: WuxiaUi.paper,
            fontSize: 17,
            letterSpacing: 4,
          ),
        ),
        actions: [
          asyncView.when(
            data: (view) => view == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PlaqueButton(
                      label: UiStrings.taohuaIslandHarvestAll,
                      primary: true,
                      onTap: () => _onHarvestAll(context, ref),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncView.when(
        loading: () =>
            const Center(child: InkLoadingIndicator(color: WuxiaUi.qing)),
        error: (e, _) => Center(
          child: Text(
            UiStrings.taohuaIslandLoadError(e),
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 14),
          ),
        ),
        data: (view) {
          if (view == null) {
            return const Center(
              child: Text(
                UiStrings.taohuaIslandNoSave,
                style: TextStyle(color: WuxiaUi.muted, fontSize: 14),
              ),
            );
          }
          return _IslandBody(
            view: view,
            onRefresh: () => ref.invalidate(taohuaIslandViewProvider),
          );
        },
      ),
    );
  }

  Future<void> _onHarvestAll(BuildContext context, WidgetRef ref) async {
    final save = await IsarSetup.currentSaveData();
    if (save == null) return;
    if (!context.mounted) return;
    final harvest = await IslandSettleService.harvest(save, DateTime.now());
    if (!context.mounted) return;
    await IslandRecapCard.show(context, harvest);
    ref.invalidate(taohuaIslandViewProvider);
  }
}

// ── 主体：据点分区滚动列 ─────────────────────────────────────────────────────

const _rawBuildingTypes = [
  BuildingType.tieJiangChang,
  BuildingType.caoYaoYuan,
  BuildingType.muGongFang,
  BuildingType.lingQuan,
];

const _workshopBuildingTypes = [
  BuildingType.daZaoTai,
  BuildingType.danFang,
  BuildingType.zhuZaoTai,
];

class _IslandBody extends StatelessWidget {
  const _IslandBody({required this.view, required this.onRefresh});

  final IslandView view;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final snapshot = _IslandSnapshot.from(view, cfg);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _IslandOverviewPanel(snapshot: snapshot),
        const SizedBox(height: 18),
        if (view.prepAdvice.isNotEmpty) ...[
          _PrepAdvicePanel(
            advice: view.prepAdvice.take(3).toList(growable: false),
          ),
          const SizedBox(height: 18),
        ],
        const _ProjectStelePanel(),
        const SizedBox(height: 18),
        _BuildingSection(
          label: UiStrings.taohuaIslandSectionRaw,
          body: UiStrings.taohuaIslandSectionRawBody,
          summary: UiStrings.taohuaIslandSectionRawSummary(snapshot.rawStored),
          types: _rawBuildingTypes,
          cfg: cfg,
          view: view,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 18),
        _BuildingSection(
          label: UiStrings.taohuaIslandSectionWorkshop,
          body: UiStrings.taohuaIslandSectionWorkshopBody,
          summary: UiStrings.taohuaIslandSectionWorkshopSummary(
            snapshot.workshopStored,
            snapshot.activeProcessors,
            snapshot.pausedProcessors,
          ),
          types: _workshopBuildingTypes,
          cfg: cfg,
          view: view,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 18),
        const _SectionHeader(
          label: UiStrings.taohuaIslandSectionDock,
          body: UiStrings.taohuaIslandSectionDockBody,
        ),
      ],
    );
  }
}

class _IslandSnapshot {
  const _IslandSnapshot({
    required this.rawStored,
    required this.workshopStored,
    required this.activeProcessors,
    required this.pausedProcessors,
    required this.injuredCharacterCount,
    required this.maxInjuryHoursRemaining,
  });

  final int rawStored;
  final int workshopStored;
  final int activeProcessors;
  final int pausedProcessors;
  final int injuredCharacterCount;
  final double maxInjuryHoursRemaining;

  factory _IslandSnapshot.from(IslandView view, TaohuaIslandConfig cfg) {
    var rawStored = 0;
    var workshopStored = 0;
    var activeProcessors = 0;
    var pausedProcessors = 0;

    for (final type in BuildingType.values) {
      final bCfg = cfg.buildings[type];
      if (bCfg == null) continue;
      final state = view.buildings.firstWhere(
        (b) => b.type == type,
        orElse: () => IslandBuildingState()..type = type,
      );
      final stored = state.stored.floor();
      if (bCfg.kind == BuildingKind.source) {
        rawStored += stored;
        continue;
      }
      workshopStored += stored;
      if (state.activeRecipeId == null) {
        pausedProcessors += 1;
      } else {
        activeProcessors += 1;
      }
    }

    return _IslandSnapshot(
      rawStored: rawStored,
      workshopStored: workshopStored,
      activeProcessors: activeProcessors,
      pausedProcessors: pausedProcessors,
      injuredCharacterCount: view.injuredCharacterCount,
      maxInjuryHoursRemaining: view.maxInjuryHoursRemaining,
    );
  }
}

class _IslandOverviewPanel extends StatelessWidget {
  const _IslandOverviewPanel({required this.snapshot});

  final _IslandSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            UiStrings.taohuaIslandOverviewTitle,
            style: TextStyle(
              color: WuxiaUi.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            UiStrings.taohuaIslandOverviewBody,
            style: TextStyle(color: WuxiaUi.ink2, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _StatusPillar(
                icon: Icons.grass_outlined,
                title: UiStrings.taohuaIslandStatusRawTitle,
                value: UiStrings.taohuaIslandStatusRawValue(snapshot.rawStored),
              ),
              _StatusPillar(
                icon: Icons.local_fire_department_outlined,
                title: UiStrings.taohuaIslandStatusWorkshopTitle,
                value: UiStrings.taohuaIslandStatusWorkshopValue(
                  snapshot.workshopStored,
                  snapshot.activeProcessors,
                  snapshot.pausedProcessors,
                ),
              ),
              _StatusPillar(
                icon: Icons.self_improvement_outlined,
                title: UiStrings.taohuaIslandStatusHealingTitle,
                value: snapshot.injuredCharacterCount > 0
                    ? UiStrings.taohuaIslandStatusHealingValue(
                        snapshot.injuredCharacterCount,
                        snapshot.maxInjuryHoursRemaining,
                      )
                    : UiStrings.taohuaIslandStatusHealingNone,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _IslandSceneLines(),
        ],
      ),
    );
  }
}

class _StatusPillar extends StatelessWidget {
  const _StatusPillar({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: WuxiaUi.qing),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: WuxiaUi.muted,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandSceneLines extends StatelessWidget {
  const _IslandSceneLines();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SceneLine(
          icon: Icons.house_siding_outlined,
          label: UiStrings.taohuaIslandSceneCave,
          body: UiStrings.taohuaIslandSceneCaveBody,
        ),
        _SceneDivider(),
        _SceneLine(
          icon: Icons.spa_outlined,
          label: UiStrings.taohuaIslandSceneField,
          body: UiStrings.taohuaIslandSceneFieldBody,
        ),
        _SceneDivider(),
        _SceneLine(
          icon: Icons.handyman_outlined,
          label: UiStrings.taohuaIslandSceneWorkshop,
          body: UiStrings.taohuaIslandSceneWorkshopBody,
        ),
        _SceneDivider(),
        _SceneLine(
          icon: Icons.anchor_outlined,
          label: UiStrings.taohuaIslandSceneDock,
          body: UiStrings.taohuaIslandSceneDockBody,
        ),
      ],
    );
  }
}

class _SceneLine extends StatelessWidget {
  const _SceneLine({
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: WuxiaUi.ink2),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            body,
            style: const TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SceneDivider extends StatelessWidget {
  const _SceneDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: WuxiaUi.borderWidth,
        color: WuxiaUi.ink.withValues(alpha: 0.18),
      ),
    );
  }
}

class _BuildingSection extends StatelessWidget {
  const _BuildingSection({
    required this.label,
    required this.body,
    required this.summary,
    required this.types,
    required this.cfg,
    required this.view,
    required this.onRefresh,
  });

  final String label;
  final String body;
  final String summary;
  final List<BuildingType> types;
  final TaohuaIslandConfig cfg;
  final IslandView view;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(label: label, body: body, summary: summary),
        const SizedBox(height: 10),
        for (final type in types) ...[
          IntrinsicHeight(
            child: _BuildingCard(
              type: type,
              state: view.buildings.firstWhere(
                (b) => b.type == type,
                orElse: () => IslandBuildingState()..type = type,
              ),
              bCfg: cfg.buildings[type]!,
              cfg: cfg,
              view: view,
              onRefresh: onRefresh,
            ),
          ),
          if (type != types.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.body, this.summary});

  final String label;
  final String? body;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            if (summary != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: WuxiaUi.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text(
            body!,
            style: const TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProjectStelePanel extends StatelessWidget {
  const _ProjectStelePanel();

  @override
  Widget build(BuildContext context) {
    return const PaperPanel(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            UiStrings.islandProjectSteleTitle,
            style: TextStyle(
              color: WuxiaUi.ink,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            UiStrings.islandProjectSteleLockedLine,
            style: TextStyle(color: WuxiaUi.ink2, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PrepAdvicePanel extends StatelessWidget {
  const _PrepAdvicePanel({required this.advice});

  final List<IslandPrepAdvice> advice;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            UiStrings.islandPrepSectionTitle,
            style: TextStyle(
              color: WuxiaUi.ink,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in advice) ...[
            _PrepAdviceRow(advice: item),
            if (item != advice.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PrepAdviceRow extends StatelessWidget {
  const _PrepAdviceRow({required this.advice});

  final IslandPrepAdvice advice;

  @override
  Widget build(BuildContext context) {
    final accent = advice.priority == IslandPrepAdvicePriority.high
        ? WuxiaUi.jiang
        : WuxiaUi.qing;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              advice.title,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              advice.body,
              style: const TextStyle(
                color: WuxiaUi.ink2,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 单建筑卡 ─────────────────────────────────────────────────────────────────

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({
    required this.type,
    required this.state,
    required this.bCfg,
    required this.cfg,
    required this.view,
    required this.onRefresh,
  });

  final BuildingType type;
  final IslandBuildingState state;
  final BuildingConfig bCfg;
  final TaohuaIslandConfig cfg;
  final IslandView view;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final itemDefs = GameRepository.instance.itemDefs;
    final level = state.level;
    final cap = bCfg.capFor(level);
    final stored = state.stored.floor();
    final isProcessor = bCfg.kind == BuildingKind.processor;
    final synergyLine = _synergyLine();

    // 产物名
    String outputName = '';
    if (!isProcessor) {
      outputName = itemDefs[bCfg.outputItem]?.name ?? (bCfg.outputItem ?? '');
    } else {
      final recipeId = state.activeRecipeId;
      if (recipeId != null) {
        final recipe = bCfg.recipeById(recipeId);
        if (recipe != null) {
          outputName = itemDefs[recipe.outputItem]?.name ?? recipe.outputItem;
        }
      }
    }

    // 升级可否判断（共用 IslandActionService.upgradeBlockReason 纯函数，消除 widget/service 双源）
    final matHave = view.materials[bCfg.upgradeMaterialItem] ?? 0;
    final upgradeCheck = IslandActionService.upgradeBlockReason(
      cfg: bCfg,
      level: level,
      founderRealmIndex: view.founderRealmIndex,
      silver: view.silver,
      material: matHave,
    );

    return PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 标题行 ──
          Row(
            children: [
              Text(
                EnumL10n.buildingType(type),
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                UiStrings.taohuaIslandLevelLabel(level),
                style: const TextStyle(color: WuxiaUi.muted, fontSize: 13),
              ),
              const Spacer(),
              // 生产状态标签（processor 专用）
              if (isProcessor)
                Text(
                  state.activeRecipeId != null
                      ? UiStrings.taohuaIslandIdleProducing
                      : UiStrings.taohuaIslandIdlePaused,
                  style: TextStyle(
                    color: state.activeRecipeId != null
                        ? WuxiaUi.qing
                        : WuxiaUi.muted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── 产物名 ──
          if (outputName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                UiStrings.taohuaIslandOutputPrefix(outputName),
                style: const TextStyle(color: WuxiaUi.ink2, fontSize: 13),
              ),
            ),

          // ── 仓储进度 ──
          Text(
            UiStrings.taohuaIslandStorageLabel(stored, cap),
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: cap > 0 ? (stored / cap).clamp(0.0, 1.0) : 0.0,
              backgroundColor: WuxiaUi.paper2,
              valueColor: const AlwaysStoppedAnimation<Color>(WuxiaUi.qing),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // ── 选配方（仅 processor）──
          if (isProcessor) ...[
            if (synergyLine != null) ...[
              Text(
                synergyLine,
                style: const TextStyle(
                  color: WuxiaUi.qing,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _RecipeSelector(
              type: type,
              state: state,
              bCfg: bCfg,
              founderRealmIndex: view.founderRealmIndex,
              onRefresh: onRefresh,
            ),
            const SizedBox(height: 10),
          ],

          // ── 升级按钮区 ──
          _UpgradeSection(
            type: type,
            view: view,
            bCfg: bCfg,
            level: level,
            upgradeCheck: upgradeCheck,
            onRefresh: onRefresh,
          ),
        ],
      ),
    );
  }

  String? _synergyLine() {
    if (bCfg.kind != BuildingKind.processor) return null;
    final parts = <String>[];
    for (final rule in cfg.synergies.rulesForTarget(type)) {
      final sourceCfg = cfg.buildings[rule.sourceBuilding];
      if (sourceCfg == null) continue;
      if (sourceCfg.realmUnlockIndex > view.founderRealmIndex) continue;
      IslandBuildingState? sourceState;
      for (final b in view.buildings) {
        if (b.type == rule.sourceBuilding) {
          sourceState = b;
          break;
        }
      }
      if (sourceState == null) continue;
      final percent = (sourceState.level * rule.rateBonusPerSourceLevel * 100)
          .round();
      if (percent <= 0) continue;
      parts.add(
        UiStrings.taohuaIslandSynergyPart(
          EnumL10n.buildingType(rule.sourceBuilding),
          percent,
        ),
      );
    }
    if (parts.isEmpty) return null;
    return UiStrings.taohuaIslandSynergyLine(parts);
  }
}

// ── 选配方组件（processor 专用）────────────────────────────────────────────────

class _RecipeSelector extends StatelessWidget {
  const _RecipeSelector({
    required this.type,
    required this.state,
    required this.bCfg,
    required this.founderRealmIndex,
    required this.onRefresh,
  });

  final BuildingType type;
  final IslandBuildingState state;
  final BuildingConfig bCfg;
  final int founderRealmIndex;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final itemDefs = GameRepository.instance.itemDefs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          UiStrings.taohuaIslandSelectRecipe,
          style: TextStyle(
            color: WuxiaUi.muted,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: bCfg.recipes.map((recipe) {
            final realmLocked = recipe.realmUnlockIndex > founderRealmIndex;
            final isActive = state.activeRecipeId == recipe.recipeId;
            final outputName =
                itemDefs[recipe.outputItem]?.name ?? recipe.outputItem;

            return Opacity(
              opacity: realmLocked ? 0.4 : 1.0,
              child: Tooltip(
                message: realmLocked ? UiStrings.taohuaIslandRealmLocked : '',
                child: GestureDetector(
                  onTap: realmLocked
                      ? null
                      : () => _onSelectRecipe(context, recipe.recipeId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? WuxiaUi.qing.withValues(alpha: 0.15)
                          : WuxiaUi.paper2.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActive
                            ? WuxiaUi.qing
                            : WuxiaUi.ink.withValues(alpha: 0.3),
                        width: WuxiaUi.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: WuxiaUi.qing,
                          ),
                        if (isActive) const SizedBox(width: 4),
                        Text(
                          outputName,
                          style: TextStyle(
                            color: isActive ? WuxiaUi.qing : WuxiaUi.ink2,
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _onSelectRecipe(BuildContext context, String recipeId) async {
    final save = await IsarSetup.currentSaveData();
    if (save == null) return;
    final result = await IslandActionService.selectRecipe(
      save: save,
      buildingType: type,
      recipeId: recipeId,
      founderRealmIndex: founderRealmIndex,
    );
    if (!context.mounted) return;
    final msg = switch (result) {
      SelectRecipeResult.ok => null,
      // notProcessor / recipeNotFound 为正常路径不可达（UI 已过滤），
      // 加通用文案守住意外分支（修 4：原 taohuaIslandIdlePaused 语义错）。
      SelectRecipeResult.notProcessor =>
        UiStrings.taohuaIslandSelectRecipeFailed,
      SelectRecipeResult.recipeNotFound =>
        UiStrings.taohuaIslandSelectRecipeFailed,
      SelectRecipeResult.realmLocked => UiStrings.taohuaIslandRealmLocked,
    };
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      // 修 3：失败路径不触发 refresh（仅 ok 时刷新）
      return;
    }
    onRefresh();
  }
}

// ── 升级按钮区 ───────────────────────────────────────────────────────────────

class _UpgradeSection extends StatelessWidget {
  const _UpgradeSection({
    required this.type,
    required this.view,
    required this.bCfg,
    required this.level,
    required this.upgradeCheck,
    required this.onRefresh,
  });

  final BuildingType type;
  final IslandView view;
  final BuildingConfig bCfg;
  final int level;

  /// null = 可升级；非 null = 阻止升级的原因（共用 [IslandActionService.upgradeBlockReason]，消除 widget/service 双源）。
  final UpgradeResult? upgradeCheck;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final itemDefs = GameRepository.instance.itemDefs;
    final matName =
        itemDefs[bCfg.upgradeMaterialItem]?.name ?? bCfg.upgradeMaterialItem;
    // 满级时无「下一级」成本：upgradeSilverFor/MaterialFor 仅对 level < maxLevel 有效
    // (节奏 B 银两为 per-level 数组，索引 level-1 在满级会越界)。费用文案本就在
    // maxLevelReached 时隐藏，故满级取 0 占位，不参与渲染。
    final atMax = level >= bCfg.maxLevel;
    final silverCost = atMax ? 0 : bCfg.upgradeSilverFor(level);
    final matCost = atMax ? 0 : bCfg.upgradeMaterialFor(level);

    final canUpgrade = upgradeCheck == null;

    // 提示文字
    final hint = switch (upgradeCheck) {
      UpgradeResult.ok => null,
      UpgradeResult.maxLevelReached => UiStrings.taohuaIslandMaxLevel,
      // 节奏 B：分阶 gate 提示具体所需境界（升 level→level+1 需 upgradeRealmFor(level)）。
      // 仅 realmLocked 分支到达此处，level < maxLevel，索引不越界。
      UpgradeResult.realmLocked => UiStrings.taohuaIslandRealmLockedFor(
        EnumL10n.realmTier(RealmTier.values[bCfg.upgradeRealmFor(level)]),
      ),
      UpgradeResult.notEnoughSilver => UiStrings.taohuaIslandNotEnoughSilver,
      UpgradeResult.notEnoughMaterial =>
        UiStrings.taohuaIslandNotEnoughMaterial,
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upgradeCheck != UpgradeResult.maxLevelReached)
          Text(
            UiStrings.taohuaIslandUpgradeCost(silverCost, matName, matCost),
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
          ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              hint,
              style: const TextStyle(color: WuxiaUi.jiang, fontSize: 11),
            ),
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: PlaqueButton(
            label: UiStrings.taohuaIslandUpgrade,
            disabled: !canUpgrade,
            onTap: canUpgrade ? () => _onUpgrade(context) : null,
          ),
        ),
      ],
    );
  }

  Future<void> _onUpgrade(BuildContext context) async {
    final save = await IsarSetup.currentSaveData();
    if (save == null) return;
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: type,
      founderRealmIndex: view.founderRealmIndex,
    );
    if (!context.mounted) return;
    final msg = switch (result) {
      UpgradeResult.ok => null,
      UpgradeResult.maxLevelReached => UiStrings.taohuaIslandMaxLevel,
      UpgradeResult.realmLocked => UiStrings.taohuaIslandRealmLocked,
      UpgradeResult.notEnoughSilver => UiStrings.taohuaIslandNotEnoughSilver,
      UpgradeResult.notEnoughMaterial =>
        UiStrings.taohuaIslandNotEnoughMaterial,
    };
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      // 修 3：失败路径不触发 refresh（仅 ok 时刷新）
      return;
    }
    onRefresh();
  }
}
