import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/item_usage.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../features/battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/ink_empty_state.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../inventory/application/item_usage_lookup_service.dart';
import '../application/island_action_service.dart';
import '../application/island_invalidation.dart';
import '../application/island_production_readability.dart';
import '../application/island_production_service.dart';
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
/// 操作后经 [invalidateAfterIslandInventoryMutation] 刷新岛务与库存 provider。
/// 中文全走 [UiStrings] / [EnumL10n]，不散写字面量（§5.6）。
/// Scaffold 必带 AppBar（踩坑记录：feedback_flutter_subscreen_appbar_audit）。
class TaohuaIslandScreen extends ConsumerWidget {
  const TaohuaIslandScreen({super.key, this.initialBuildingMenu});

  /// Debug visual route hook: when set, the screen opens the building menu
  /// after the first loaded frame. Production callers leave this null.
  final BuildingType? initialBuildingMenu;

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
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Center(
              child: SilverBalancePill(
                tone: CurrencyPillTone.dark,
                compact: true,
              ),
            ),
          ),
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
        error: (e, _) => ErrorFallback(
          message: UiStrings.errorFallbackMessage,
          error: e,
          onRetry: () => ref.invalidate(taohuaIslandViewProvider),
        ),
        data: (view) {
          if (view == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: InkEmptyState(
                  variant: InkEmptyStateVariant.unavailable,
                  title: UiStrings.errorNoSaveTitle,
                  body: UiStrings.taohuaIslandNoSave,
                  icon: Icons.menu_book_outlined,
                ),
              ),
            );
          }
          return _IslandBody(
            view: view,
            onRefresh: () =>
                invalidateAfterIslandInventoryMutation(ref.invalidate),
            initialBuildingMenu: initialBuildingMenu,
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
    invalidateAfterIslandInventoryMutation(ref.invalidate);
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

const _allBuildingTypes = [..._rawBuildingTypes, ..._workshopBuildingTypes];

const _taohuaIslandMapAsset = 'assets/maps/taohuaIsland.webp';

class _IslandBody extends StatefulWidget {
  const _IslandBody({
    required this.view,
    required this.onRefresh,
    this.initialBuildingMenu,
  });

  final IslandView view;
  final VoidCallback onRefresh;
  final BuildingType? initialBuildingMenu;

  @override
  State<_IslandBody> createState() => _IslandBodyState();
}

class _IslandBodyState extends State<_IslandBody> {
  BuildingType _selectedType = BuildingType.tieJiangChang;
  late DateTime _projectionStartedAt;
  late DateTime _liveNow;
  Timer? _ticker;
  bool _initialMenuOpened = false;

  @override
  void initState() {
    super.initState();
    _resetProjectionClock();
    _scheduleInitialMenu();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _liveNow = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant _IslandBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.view, widget.view)) {
      _resetProjectionClock();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _scheduleInitialMenu() {
    final type = widget.initialBuildingMenu;
    if (type == null || _initialMenuOpened) return;
    _initialMenuOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openBuildingMenu(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final liveBuildings = _projectedBuildings(cfg);
    final liveView = _viewWithBuildings(liveBuildings);
    final snapshot = _IslandSnapshot.from(liveView, cfg);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 760;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compactHeight ? 14 : 16,
            vertical: compactHeight ? 10 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _IslandSceneHub(
                  selectedType: _selectedType,
                  snapshot: snapshot,
                  states: liveBuildings,
                  cfg: cfg,
                  founderRealmIndex: liveView.founderRealmIndex,
                  onSelect: _openBuildingMenu,
                ),
              ),
              SizedBox(height: compactHeight ? 10 : 12),
              _IslandOneScreenSummary(
                snapshot: snapshot,
                prepAdvice: widget.view.prepAdvice
                    .take(compactHeight ? 1 : 2)
                    .toList(growable: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openBuildingMenu(BuildingType type) async {
    setState(() => _selectedType = type);
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final liveBuildings = _projectedBuildings(cfg);
    final liveView = _viewWithBuildings(liveBuildings);
    final bCfg = cfg.buildings[type]!;
    final state = _stateFor(type, liveBuildings);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: WuxiaIconButton(
                    icon: Icons.close,
                    tooltip: UiStrings.close,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: _BuildingCard(
                      type: type,
                      state: state,
                      bCfg: bCfg,
                      cfg: cfg,
                      view: liveView,
                      onRefresh: () {
                        widget.onRefresh();
                        if (Navigator.of(dialogContext).canPop()) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetProjectionClock() {
    final now = DateTime.now();
    _projectionStartedAt = now;
    _liveNow = now;
  }

  List<IslandBuildingState> _projectedBuildings(TaohuaIslandConfig cfg) {
    final elapsedHours =
        _liveNow.difference(_projectionStartedAt).inMilliseconds /
        Duration.millisecondsPerHour;
    return IslandProductionService.settle(
      states: widget.view.buildings,
      config: cfg,
      elapsedHours: elapsedHours,
      founderRealmIndex: widget.view.founderRealmIndex,
    );
  }

  IslandView _viewWithBuildings(List<IslandBuildingState> buildings) =>
      IslandView(
        buildings: buildings,
        founderRealmIndex: widget.view.founderRealmIndex,
        silver: widget.view.silver,
        materials: widget.view.materials,
        prepAdvice: widget.view.prepAdvice,
        injuredCharacterCount: widget.view.injuredCharacterCount,
        maxInjuryHoursRemaining: widget.view.maxInjuryHoursRemaining,
      );

  IslandBuildingState _stateFor(
    BuildingType type,
    List<IslandBuildingState> states,
  ) => states.firstWhere(
    (b) => b.type == type,
    orElse: () => IslandBuildingState()..type = type,
  );
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

// ── 场景式建筑热区 ─────────────────────────────────────────────────────────────

class _IslandSceneHub extends StatelessWidget {
  const _IslandSceneHub({
    required this.selectedType,
    required this.snapshot,
    required this.states,
    required this.cfg,
    required this.founderRealmIndex,
    required this.onSelect,
  });

  final BuildingType selectedType;
  final _IslandSnapshot snapshot;
  final List<IslandBuildingState> states;
  final TaohuaIslandConfig cfg;
  final int founderRealmIndex;
  final ValueChanged<BuildingType> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper2.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        border: Border.all(
          color: WuxiaUi.ink.withValues(alpha: 0.32),
          width: WuxiaUi.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    UiStrings.taohuaIslandSceneMapTitle,
                    style: TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Text(
                  UiStrings.taohuaIslandSceneMapSummary(
                    snapshot.rawStored,
                    snapshot.workshopStored,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: WuxiaUi.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactScene = constraints.maxWidth < 1500;
                  final aspectRatio = compactScene ? 2.12 : 2.0;
                  final sceneWidth = constraints.maxWidth;
                  final sceneHeight = sceneWidth / aspectRatio;
                  return FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: sceneWidth,
                      height: sceneHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(WuxiaUi.radius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            WuxiaImage(
                              _taohuaIslandMapAsset,
                              key: const Key('taohua_scene_map_asset'),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  CustomPaint(painter: _IslandScenePainter()),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: WuxiaUi.paper.withValues(alpha: 0.12),
                              ),
                            ),
                            for (final type in _allBuildingTypes)
                              _SceneBuildingHotspot(
                                type: type,
                                state: _stateFor(type),
                                bCfg: cfg.buildings[type]!,
                                progress: _HotspotProductionProgress.from(
                                  state: _stateFor(type),
                                  allStates: states,
                                  cfg: cfg,
                                  founderRealmIndex: founderRealmIndex,
                                ),
                                selected: type == selectedType,
                                compact: compactScene,
                                onTap: () => onSelect(type),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IslandBuildingState _stateFor(BuildingType type) => states.firstWhere(
    (b) => b.type == type,
    orElse: () => IslandBuildingState()..type = type,
  );
}

class _SceneBuildingHotspot extends StatelessWidget {
  const _SceneBuildingHotspot({
    required this.type,
    required this.state,
    required this.bCfg,
    required this.progress,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final BuildingType type;
  final IslandBuildingState state;
  final BuildingConfig bCfg;
  final _HotspotProductionProgress progress;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _BuildingSceneSpec.forType(type);
    final stored = state.stored.floor();
    final active =
        bCfg.kind == BuildingKind.source || state.activeRecipeId != null;
    final accent = selected
        ? WuxiaUi.jiang
        : (active ? WuxiaUi.qing : WuxiaUi.muted);
    final hotspotWidth = compact ? 152.0 : 176.0;
    final hotspotHeight = compact ? 94.0 : 108.0;
    return Align(
      alignment: spec.alignment,
      child: SizedBox(
        width: hotspotWidth,
        height: hotspotHeight,
        child: Tooltip(
          message: EnumL10n.buildingType(type),
          child: InkWell(
            key: Key('taohua_scene_hotspot_${type.name}'),
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 7 : 9,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? WuxiaUi.paper.withValues(alpha: 0.94)
                    : WuxiaUi.paper.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? WuxiaUi.jiang
                      : WuxiaUi.ink.withValues(alpha: 0.44),
                  width: selected ? 2.2 : 1.2,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: WuxiaUi.jiang.withValues(alpha: 0.20),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(spec.icon, size: compact ? 18 : 21, color: accent),
                      SizedBox(width: compact ? 5 : 6),
                      Flexible(
                        child: Text(
                          EnumL10n.buildingType(type),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? WuxiaUi.ink : WuxiaUi.ink2,
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HotspotMetaChip(
                        text: 'Lv.${state.level}',
                        color: accent,
                        strong: true,
                        compact: compact,
                      ),
                      const SizedBox(width: 6),
                      _HotspotMetaChip(
                        text: '$stored',
                        color: active ? WuxiaUi.ink2 : WuxiaUi.jiang,
                        compact: compact,
                      ),
                    ],
                  ),
                  _HotspotProgressBar(
                    key: Key('taohua_scene_progress_${type.name}'),
                    progress: progress,
                    compact: compact,
                  ),
                  Text(
                    active
                        ? UiStrings.taohuaIslandSceneProgressLabel
                        : UiStrings.taohuaIslandScenePausedShort,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? WuxiaUi.muted : WuxiaUi.jiang,
                      fontSize: compact ? 9.5 : 10.5,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingSceneSpec {
  const _BuildingSceneSpec({required this.alignment, required this.icon});

  final Alignment alignment;
  final IconData icon;

  static _BuildingSceneSpec forType(BuildingType type) => switch (type) {
    BuildingType.tieJiangChang => const _BuildingSceneSpec(
      alignment: Alignment(-0.78, 0.1),
      icon: Icons.local_fire_department_outlined,
    ),
    BuildingType.caoYaoYuan => const _BuildingSceneSpec(
      alignment: Alignment(-0.36, -0.48),
      icon: Icons.grass_outlined,
    ),
    BuildingType.muGongFang => const _BuildingSceneSpec(
      alignment: Alignment(0.06, 0.46),
      icon: Icons.forest_outlined,
    ),
    BuildingType.lingQuan => const _BuildingSceneSpec(
      alignment: Alignment(0.48, -0.5),
      icon: Icons.water_drop_outlined,
    ),
    BuildingType.daZaoTai => const _BuildingSceneSpec(
      alignment: Alignment(-0.18, 0.02),
      icon: Icons.handyman_outlined,
    ),
    BuildingType.danFang => const _BuildingSceneSpec(
      alignment: Alignment(0.36, 0.02),
      icon: Icons.science_outlined,
    ),
    BuildingType.zhuZaoTai => const _BuildingSceneSpec(
      alignment: Alignment(0.78, 0.32),
      icon: Icons.construction_outlined,
    ),
  };
}

class _HotspotMetaChip extends StatelessWidget {
  const _HotspotMetaChip({
    required this.text,
    required this.color,
    required this.compact,
    this.strong = false,
  });

  final String text;
  final Color color;
  final bool compact;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: strong ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.34), width: 0.8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 6,
          vertical: compact ? 1 : 2,
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: compact ? 11 : 12,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _HotspotProductionProgress {
  const _HotspotProductionProgress({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  factory _HotspotProductionProgress.from({
    required IslandBuildingState state,
    required List<IslandBuildingState> allStates,
    required TaohuaIslandConfig cfg,
    required int founderRealmIndex,
  }) {
    final intel = IslandProductionReadability.from(
      state: state,
      allStates: allStates,
      config: cfg,
      founderRealmIndex: founderRealmIndex,
    );
    final cap = cfg.buildingOf(state.type).capFor(state.level).toDouble();
    final stored = state.stored.clamp(0.0, cap).toDouble();
    final base = WuxiaUi.ink.withValues(alpha: 0.16);

    return switch (intel.pauseReason) {
      IslandProductionPauseReason.none => _HotspotProductionProgress(
        value: _fractionalProgress(stored),
        color: WuxiaUi.qing,
        backgroundColor: base,
      ),
      IslandProductionPauseReason.full => _HotspotProductionProgress(
        value: 1,
        color: WuxiaUi.gold,
        backgroundColor: base,
      ),
      IslandProductionPauseReason.realmLocked => _HotspotProductionProgress(
        value: 0,
        color: WuxiaUi.jiang,
        backgroundColor: WuxiaUi.jiang.withValues(alpha: 0.16),
      ),
      IslandProductionPauseReason.noRecipe ||
      IslandProductionPauseReason.noProgress => _HotspotProductionProgress(
        value: 0,
        color: WuxiaUi.muted,
        backgroundColor: base,
      ),
    };
  }

  static double _fractionalProgress(double stored) {
    final fractional = stored - stored.floorToDouble();
    if (fractional <= 1e-6) return 0;
    if (1 - fractional <= 1e-6) return 1;
    return fractional.clamp(0.0, 1.0);
  }
}

class _HotspotProgressBar extends StatelessWidget {
  const _HotspotProgressBar({
    super.key,
    required this.progress,
    required this.compact,
  });

  final _HotspotProductionProgress progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress.value,
        minHeight: compact ? 5 : 6,
        backgroundColor: progress.backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(progress.color),
      ),
    );
  }
}

class _IslandScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()..color = WuxiaUi.qing.withValues(alpha: 0.18);
    canvas.drawRect(Offset.zero & size, waterPaint);

    final islandPaint = Paint()..color = WuxiaUi.paper.withValues(alpha: 0.84);
    final island = Path()
      ..moveTo(size.width * 0.08, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.18,
        size.width * 0.46,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.1,
        size.width * 0.92,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.88,
        size.width * 0.5,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.88,
        size.width * 0.08,
        size.height * 0.6,
      )
      ..close();
    canvas.drawPath(island, islandPaint);

    final shorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = WuxiaUi.borderWidth
      ..color = WuxiaUi.ink.withValues(alpha: 0.22);
    canvas.drawPath(island, shorePaint);

    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = WuxiaUi.ink.withValues(alpha: 0.16);
    final trail = Path()
      ..moveTo(size.width * 0.18, size.height * 0.56)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.42,
        size.width * 0.47,
        size.height * 0.6,
        size.width * 0.62,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.3,
        size.width * 0.82,
        size.height * 0.44,
        size.width * 0.78,
        size.height * 0.66,
      );
    canvas.drawPath(trail, trailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IslandOneScreenSummary extends StatelessWidget {
  const _IslandOneScreenSummary({
    required this.snapshot,
    required this.prepAdvice,
  });

  final _IslandSnapshot snapshot;
  final List<IslandPrepAdvice> prepAdvice;

  @override
  Widget build(BuildContext context) {
    return LightPaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 260, child: _IslandOverviewHeader()),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatusPillar(
                        icon: Icons.grass_outlined,
                        title: UiStrings.taohuaIslandStatusRawTitle,
                        value: UiStrings.taohuaIslandStatusRawValue(
                          snapshot.rawStored,
                        ),
                        accent: WuxiaUi.qing,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _StatusPillar(
                        icon: Icons.local_fire_department_outlined,
                        title: UiStrings.taohuaIslandStatusWorkshopTitle,
                        value: UiStrings.taohuaIslandStatusWorkshopValue(
                          snapshot.workshopStored,
                          snapshot.activeProcessors,
                          snapshot.pausedProcessors,
                        ),
                        accent: WuxiaUi.jiang,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _StatusPillar(
                        icon: Icons.self_improvement_outlined,
                        title: UiStrings.taohuaIslandStatusHealingTitle,
                        value: snapshot.injuredCharacterCount > 0
                            ? UiStrings.taohuaIslandStatusHealingValue(
                                snapshot.injuredCharacterCount,
                                snapshot.maxInjuryHoursRemaining,
                              )
                            : UiStrings.taohuaIslandStatusHealingNone,
                        accent: WuxiaUi.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: WuxiaUi.ink.withValues(alpha: 0.16),
                  width: WuxiaUi.borderWidth,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 74, child: _DutySectionLabel()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 7,
                      children: [
                        const _CompactSceneChip(
                          icon: Icons.house_siding_outlined,
                          label: UiStrings.taohuaIslandSceneCave,
                          body: UiStrings.taohuaIslandSceneCaveBody,
                        ),
                        const _CompactSceneChip(
                          icon: Icons.spa_outlined,
                          label: UiStrings.taohuaIslandSceneField,
                          body: UiStrings.taohuaIslandSceneFieldBody,
                        ),
                        const _CompactSceneChip(
                          icon: Icons.handyman_outlined,
                          label: UiStrings.taohuaIslandSceneWorkshop,
                          body: UiStrings.taohuaIslandSceneWorkshopBody,
                        ),
                        const _CompactSceneChip(
                          icon: Icons.anchor_outlined,
                          label: UiStrings.taohuaIslandSceneDock,
                          body: UiStrings.taohuaIslandSceneDockBody,
                        ),
                        for (final item in prepAdvice)
                          _CompactPrepAdvice(item: item),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandOverviewHeader extends StatelessWidget {
  const _IslandOverviewHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          UiStrings.taohuaIslandOverviewTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: WuxiaUi.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),
        SizedBox(height: 5),
        Text(
          UiStrings.taohuaIslandOverviewBody,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: WuxiaUi.ink2,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _DutySectionLabel extends StatelessWidget {
  const _DutySectionLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      UiStrings.taohuaIslandSceneDutyTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: WuxiaUi.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        height: 1.35,
      ),
    );
  }
}

class _CompactSceneChip extends StatelessWidget {
  const _CompactSceneChip({
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 288,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: WuxiaUi.qing),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.3,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaUi.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPrepAdvice extends StatelessWidget {
  const _CompactPrepAdvice({required this.item});

  final IslandPrepAdvice item;

  @override
  Widget build(BuildContext context) {
    final accent = item.priority == IslandPrepAdvicePriority.high
        ? WuxiaUi.jiang
        : WuxiaUi.qing;
    return SizedBox(
      width: 330,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '${item.title}：${item.body}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPillar extends StatelessWidget {
  const _StatusPillar({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ],
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
    final productionIntel = IslandProductionReadability.from(
      state: state,
      allStates: view.buildings,
      config: cfg,
      founderRealmIndex: view.founderRealmIndex,
    );

    // 产物名
    String outputName = '';
    final outputItemId = productionIntel.outputItemId;
    if (outputItemId != null) {
      outputName = itemDefs[outputItemId]?.name ?? outputItemId;
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

    return LightPaperPanel(
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

          _ProductionQueueIntel(
            isProcessor: isProcessor,
            outputName: outputName,
            intel: productionIntel,
          ),
          const SizedBox(height: 12),

          _BuildingManualPanel(type: type, bCfg: bCfg, cfg: cfg),
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

class _ProductionQueueIntel extends StatelessWidget {
  const _ProductionQueueIntel({
    required this.isProcessor,
    required this.outputName,
    required this.intel,
  });

  final bool isProcessor;
  final String outputName;
  final IslandProductionReadability intel;

  @override
  Widget build(BuildContext context) {
    final usages = _outputUsages();
    final usage = _usageSummary(usages);
    final lines = [
      _IntelTile(
        icon: isProcessor ? Icons.receipt_long_outlined : Icons.grass_outlined,
        text: isProcessor
            ? outputName.isEmpty
                  ? UiStrings.taohuaIslandCurrentRecipeNone
                  : UiStrings.taohuaIslandCurrentRecipe(outputName)
            : UiStrings.taohuaIslandCurrentGathering(outputName),
        emphasized: true,
      ),
      _IntelTile(
        icon: Icons.hourglass_bottom_outlined,
        text: _nextOutputText(),
      ),
      _IntelTile(icon: Icons.inventory_2_outlined, text: _fullStorageText()),
      if (usage.isNotEmpty)
        _IntelTile(icon: Icons.call_split_outlined, text: usage),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper2.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        border: Border.all(
          color: WuxiaUi.ink.withValues(alpha: 0.16),
          width: WuxiaUi.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= 520;
            final tileWidth = twoColumn
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final line in lines)
                      SizedBox(width: tileWidth, child: line),
                  ],
                ),
                if (usage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _UsageTagWrap(usages: usages),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _nextOutputText() {
    if (intel.pauseReason == IslandProductionPauseReason.full) {
      return UiStrings.taohuaIslandNextOutputFull;
    }
    final hours = intel.hoursToNextItem;
    if (hours == null) return UiStrings.taohuaIslandNextOutputPaused;
    return UiStrings.taohuaIslandNextOutputIn(
      UiStrings.taohuaIslandDuration(hours),
    );
  }

  String _fullStorageText() {
    if (intel.pauseReason == IslandProductionPauseReason.full) {
      return UiStrings.taohuaIslandFullStorageNow;
    }
    final hours = intel.hoursToFull;
    if (hours == null) return UiStrings.taohuaIslandFullStorageUnknown;
    return UiStrings.taohuaIslandFullStorageIn(
      UiStrings.taohuaIslandDuration(hours),
    );
  }

  List<ItemUsage> _outputUsages() {
    final outputItemId = intel.outputItemId;
    if (outputItemId == null) return const [];
    return ItemUsageLookupService(
      GameRepository.instance,
    ).usagesFor(outputItemId);
  }

  String _usageSummary(List<ItemUsage> usages) {
    if (intel.outputItemId == null) return '';
    final summary = UiStrings.materialUsageSummary(usages);
    return summary.isEmpty
        ? UiStrings.taohuaIslandOutputUsageNone
        : UiStrings.taohuaIslandOutputUsage(summary);
  }
}

class _IntelTile extends StatelessWidget {
  const _IntelTile({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = emphasized ? WuxiaUi.jiang : WuxiaUi.qing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: emphasized ? 0.42 : 0.28),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: accent.withValues(alpha: emphasized ? 0.34 : 0.22),
          width: WuxiaUi.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: emphasized ? WuxiaUi.ink : WuxiaUi.ink2,
                  fontSize: 12,
                  fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageTagWrap extends StatelessWidget {
  const _UsageTagWrap({required this.usages});

  final List<ItemUsage> usages;

  @override
  Widget build(BuildContext context) {
    final labels = <String>{
      for (final usage in usages) UiStrings.taohuaIslandOutputUsageTag(usage),
    }..remove('');
    if (labels.isEmpty) {
      labels.add(UiStrings.taohuaIslandOutputUsageTagNone);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in labels)
          DecoratedBox(
            decoration: BoxDecoration(
              color: WuxiaUi.qing.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: WuxiaUi.qing.withValues(alpha: 0.32),
                width: WuxiaUi.borderWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              child: Text(
                label,
                style: const TextStyle(
                  color: WuxiaUi.ink2,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IntelLine extends StatelessWidget {
  const _IntelLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: WuxiaUi.qing),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildingManualPanel extends StatelessWidget {
  const _BuildingManualPanel({
    required this.type,
    required this.bCfg,
    required this.cfg,
  });

  final BuildingType type;
  final BuildingConfig bCfg;
  final TaohuaIslandConfig cfg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: WuxiaUi.ink.withValues(alpha: 0.16),
          width: WuxiaUi.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              UiStrings.taohuaIslandBuildingManualTitle,
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 7),
            _IntelLine(
              icon: Icons.inventory_2_outlined,
              text: _line(
                UiStrings.taohuaIslandBuildingManualProduces,
                _produces(),
              ),
            ),
            const SizedBox(height: 5),
            _IntelLine(
              icon: Icons.receipt_long_outlined,
              text: _line(
                UiStrings.taohuaIslandBuildingManualConsumes,
                _consumes(),
              ),
            ),
            const SizedBox(height: 5),
            _IntelLine(
              icon: Icons.call_split_outlined,
              text: _line(
                UiStrings.taohuaIslandBuildingManualSynergy,
                _synergies(),
              ),
            ),
            const SizedBox(height: 5),
            _IntelLine(
              icon: Icons.route_outlined,
              text: _line(UiStrings.taohuaIslandBuildingManualUsage, _usage()),
            ),
          ],
        ),
      ),
    );
  }

  String _line(String label, String value) =>
      UiStrings.taohuaIslandBuildingManualLine(label, value);

  String _produces() {
    if (bCfg.kind == BuildingKind.source) {
      return UiStrings.taohuaIslandBuildingManualGatherRate(
        _itemName(bCfg.outputItem),
      );
    }
    final outputs = <String>{
      for (final recipe in bCfg.recipes) _itemName(recipe.outputItem),
    };
    return UiStrings.taohuaIslandBuildingManualRecipeOutputs(
      outputs.join(' / '),
    );
  }

  String _consumes() {
    if (bCfg.kind == BuildingKind.source) {
      return UiStrings.taohuaIslandBuildingManualUpgradeMaterial(
        _itemName(bCfg.upgradeMaterialItem),
      );
    }
    final lines = <String>[];
    for (final recipe in bCfg.recipes) {
      final parts = [
        '${_itemName(bCfg.inputItem)} ×${_formatAmount(recipe.inputPerOutput)}',
        if (recipe.secondaryInputPerOutput > 0)
          '${_itemName(bCfg.secondaryInputItem)} ×${_formatAmount(recipe.secondaryInputPerOutput)}',
      ];
      lines.add(
        UiStrings.taohuaIslandBuildingManualRecipeCost(
          _itemName(recipe.outputItem),
          parts.join(' · '),
        ),
      );
    }
    return lines.join(' / ');
  }

  String _synergies() {
    final parts = <String>[];
    if (bCfg.kind == BuildingKind.source) {
      for (final rule in cfg.synergies.rules) {
        if (rule.sourceBuilding != type) continue;
        parts.add(
          UiStrings.taohuaIslandBuildingManualSynergyTarget(
            EnumL10n.buildingType(rule.targetBuilding),
            (rule.rateBonusPerSourceLevel * 100).round(),
          ),
        );
      }
    } else {
      for (final rule in cfg.synergies.rulesForTarget(type)) {
        parts.add(
          UiStrings.taohuaIslandBuildingManualSynergySource(
            EnumL10n.buildingType(rule.sourceBuilding),
            (rule.rateBonusPerSourceLevel * 100).round(),
          ),
        );
      }
    }
    return parts.isEmpty
        ? UiStrings.taohuaIslandBuildingManualNone
        : parts.join(' / ');
  }

  String _usage() {
    final usageLines = <String>[];
    final outputIds = bCfg.kind == BuildingKind.source
        ? [if (bCfg.outputItem != null) bCfg.outputItem!]
        : [for (final recipe in bCfg.recipes) recipe.outputItem];
    for (final itemId in outputIds) {
      final usage = UiStrings.materialUsageSummary(
        ItemUsageLookupService(GameRepository.instance).usagesFor(itemId),
      );
      usageLines.add(
        UiStrings.taohuaIslandBuildingManualOutputUsage(
          _itemName(itemId),
          usage.isEmpty ? UiStrings.taohuaIslandBuildingManualUsageNone : usage,
        ),
      );
    }
    return usageLines.join(' / ');
  }

  String _itemName(String? itemId) {
    if (itemId == null || itemId.isEmpty) {
      return UiStrings.taohuaIslandBuildingManualNone;
    }
    return GameRepository.instance.itemDefs[itemId]?.name ?? itemId;
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
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
