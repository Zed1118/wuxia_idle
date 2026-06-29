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
import '../../inventory/application/item_usage_lookup_service.dart';
import '../application/island_action_service.dart';
import '../application/island_production_readability.dart';
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

const _allBuildingTypes = [..._rawBuildingTypes, ..._workshopBuildingTypes];

class _IslandBody extends StatefulWidget {
  const _IslandBody({required this.view, required this.onRefresh});

  final IslandView view;
  final VoidCallback onRefresh;

  @override
  State<_IslandBody> createState() => _IslandBodyState();
}

class _IslandBodyState extends State<_IslandBody> {
  BuildingType _selectedType = BuildingType.tieJiangChang;

  @override
  Widget build(BuildContext context) {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final snapshot = _IslandSnapshot.from(widget.view, cfg);
    final selectedCfg = cfg.buildings[_selectedType]!;
    final selectedState = _stateFor(_selectedType);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _IslandOverviewPanel(snapshot: snapshot),
        const SizedBox(height: 18),
        _IslandSceneHub(
          selectedType: _selectedType,
          snapshot: snapshot,
          states: widget.view.buildings,
          cfg: cfg,
          onSelect: (type) => setState(() => _selectedType = type),
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          label: UiStrings.taohuaIslandSelectedBuildingTitle(
            EnumL10n.buildingType(_selectedType),
          ),
          body: UiStrings.taohuaIslandSelectedBuildingBody,
          summary: _selectedSummary(_selectedType, snapshot),
        ),
        const SizedBox(height: 10),
        _BuildingCard(
          type: _selectedType,
          state: selectedState,
          bCfg: selectedCfg,
          cfg: cfg,
          view: widget.view,
          onRefresh: widget.onRefresh,
        ),
        const SizedBox(height: 18),
        if (widget.view.prepAdvice.isNotEmpty) ...[
          _PrepAdvicePanel(
            advice: widget.view.prepAdvice.take(3).toList(growable: false),
          ),
          const SizedBox(height: 18),
        ],
        const _ProjectStelePanel(),
        const SizedBox(height: 18),
        const _SectionHeader(
          label: UiStrings.taohuaIslandSectionDock,
          body: UiStrings.taohuaIslandSectionDockBody,
        ),
      ],
    );
  }

  IslandBuildingState _stateFor(BuildingType type) =>
      widget.view.buildings.firstWhere(
        (b) => b.type == type,
        orElse: () => IslandBuildingState()..type = type,
      );

  String _selectedSummary(BuildingType type, _IslandSnapshot snapshot) {
    if (_rawBuildingTypes.contains(type)) {
      return UiStrings.taohuaIslandSectionRawSummary(snapshot.rawStored);
    }
    return UiStrings.taohuaIslandSectionWorkshopSummary(
      snapshot.workshopStored,
      snapshot.activeProcessors,
      snapshot.pausedProcessors,
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

// ── 场景式建筑热区 ─────────────────────────────────────────────────────────────

class _IslandSceneHub extends StatelessWidget {
  const _IslandSceneHub({
    required this.selectedType,
    required this.snapshot,
    required this.states,
    required this.cfg,
    required this.onSelect,
  });

  final BuildingType selectedType;
  final _IslandSnapshot snapshot;
  final List<IslandBuildingState> states;
  final TaohuaIslandConfig cfg;
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
            AspectRatio(
              aspectRatio: 2.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(WuxiaUi.radius),
                child: CustomPaint(
                  painter: _IslandScenePainter(),
                  child: Stack(
                    children: [
                      for (final type in _allBuildingTypes)
                        _SceneBuildingHotspot(
                          type: type,
                          state: _stateFor(type),
                          bCfg: cfg.buildings[type]!,
                          selected: type == selectedType,
                          onTap: () => onSelect(type),
                        ),
                    ],
                  ),
                ),
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
    required this.selected,
    required this.onTap,
  });

  final BuildingType type;
  final IslandBuildingState state;
  final BuildingConfig bCfg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _BuildingSceneSpec.forType(type);
    final stored = state.stored.floor();
    final active =
        bCfg.kind == BuildingKind.source || state.activeRecipeId != null;
    return Align(
      alignment: spec.alignment,
      child: FractionallySizedBox(
        widthFactor: 0.2,
        heightFactor: 0.28,
        child: Tooltip(
          message: EnumL10n.buildingType(type),
          child: InkWell(
            key: Key('taohua_scene_hotspot_${type.name}'),
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? WuxiaUi.paper.withValues(alpha: 0.92)
                    : WuxiaUi.paper.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? WuxiaUi.jiang
                      : WuxiaUi.ink.withValues(alpha: 0.38),
                  width: selected ? 2 : WuxiaUi.borderWidth,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: WuxiaUi.jiang.withValues(alpha: 0.16),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    spec.icon,
                    size: 22,
                    color: selected ? WuxiaUi.jiang : WuxiaUi.qing,
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: Text(
                      EnumL10n.buildingType(type),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? WuxiaUi.ink : WuxiaUi.ink2,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    UiStrings.taohuaIslandSceneHotspotMeta(state.level, stored),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? WuxiaUi.muted : WuxiaUi.jiang,
                      fontSize: 9,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper2.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: WuxiaUi.ink.withValues(alpha: 0.16),
          width: WuxiaUi.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntelLine(
              icon: isProcessor
                  ? Icons.receipt_long_outlined
                  : Icons.grass_outlined,
              text: isProcessor
                  ? outputName.isEmpty
                        ? UiStrings.taohuaIslandCurrentRecipeNone
                        : UiStrings.taohuaIslandCurrentRecipe(outputName)
                  : UiStrings.taohuaIslandCurrentGathering(outputName),
            ),
            const SizedBox(height: 5),
            _IntelLine(
              icon: Icons.hourglass_bottom_outlined,
              text: _nextOutputText(),
            ),
            const SizedBox(height: 5),
            _IntelLine(
              icon: Icons.inventory_2_outlined,
              text: _fullStorageText(),
            ),
            if (usage.isNotEmpty) ...[
              const SizedBox(height: 5),
              _IntelLine(icon: Icons.call_split_outlined, text: usage),
              const SizedBox(height: 7),
              _UsageTagWrap(usages: usages),
            ],
          ],
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
