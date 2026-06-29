import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/bgm_scope.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import '../application/seclusion_service.dart';
import '../application/seclusion_service_providers.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'active_retreat_screen.dart';
import 'seclusion_map_visuals.dart';
import 'seclusion_setup_screen.dart';

/// 闭关地图列表屏幕（Phase 3 T49）。
///
/// 显示 5 张地图三态：locked（境界不足）/ available（可进入）/ active（进行中）。
/// 顶部 banner 在有活跃 session 时显示地图名 + 剩余时间 +「收功/查看」按钮。
///
/// W15 Phase 5 #2:改 ConsumerStatefulWidget，走 seclusionServiceProvider 注入。
class SeclusionMapListScreen extends ConsumerStatefulWidget {
  /// 当前玩家境界（由上层注入，Demo 阶段固定 characterId=1）。
  final RealmTier charRealmTier;
  final int characterId;

  const SeclusionMapListScreen({
    super.key,
    required this.charRealmTier,
    required this.characterId,
  });

  @override
  ConsumerState<SeclusionMapListScreen> createState() =>
      _SeclusionMapListScreenState();
}

class _SeclusionMapListScreenState
    extends ConsumerState<SeclusionMapListScreen> {
  late Future<RetreatSession?> _activeFuture;

  Future<RetreatSession?> _fetchActive() {
    final svc = ref.read(seclusionServiceProvider);
    if (svc == null) return Future.value(null);
    return svc.getActiveSession(IsarSetup.currentSlotId);
  }

  @override
  void initState() {
    super.initState();
    _activeFuture = _fetchActive();
  }

  void _refresh() {
    setState(() {
      _activeFuture = _fetchActive();
    });
  }

  void _onMapTap(BuildContext context, SeclusionMapDef def) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final active = await _activeFuture;
    if (!mounted) return;

    if (active != null && active.mapType == def.mapType) {
      await nav.push<void>(
        MaterialPageRoute(
          builder: (_) => ActiveRetreatScreen(
            session: active,
            mapDef: def,
            characterId: widget.characterId,
            charRealmTier: widget.charRealmTier,
          ),
        ),
      );
      _refresh();
      return;
    }

    // 境界锁
    if (!SeclusionService.canEnterMap(
      mapType: def.mapType,
      charRealmTier: widget.charRealmTier,
      maps: GameRepository.instance.seclusionMaps,
    )) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            UiStrings.seclusionRequiredRealmWithCurrent(
              EnumL10n.realmTier(def.requiredRealm),
              EnumL10n.realmTier(widget.charRealmTier),
            ),
          ),
        ),
      );
      return;
    }

    // 可进入 → 推 SetupScreen
    final started = await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => SeclusionSetupScreen(
          mapDef: def,
          charRealmTier: widget.charRealmTier,
          characterId: widget.characterId,
          existingActiveSession: active,
        ),
      ),
    );
    if (started == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final maps = GameRepository.instance.seclusionMaps;

    return BgmScope(
      track: BgmTrack.seclusion,
      child: Scaffold(
        backgroundColor: WuxiaColors.background,
        appBar: AppBar(
          title: const Text(UiStrings.seclusionTitle),
          backgroundColor: WuxiaColors.sidebar,
          foregroundColor: WuxiaColors.textPrimary,
          actions: [
            const ContextHelpButton(topic: HelpTopic.seclusion),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: WuxiaImage(
                'assets/ui/meditation_icon.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<RetreatSession?>(
            future: _activeFuture,
            builder: (context, snap) {
              final active = snap.data;
              final activeDef = active == null
                  ? null
                  : GameRepository.instance.getSeclusionMap(active.mapType);
              return Column(
                children: [
                  if (active != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _ActiveBanner(session: active, mapDef: activeDef!),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 940 ? 2 : 1;
                        final cardHeight = columns == 2 ? 268.0 : 258.0;
                        final cardWidth =
                            (constraints.maxWidth - 32 - (columns - 1) * 14) /
                            columns;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: cardWidth / cardHeight,
                              ),
                          itemCount: maps.length,
                          itemBuilder: (context, i) {
                            final def = maps[i];
                            final isActive =
                                active != null && active.mapType == def.mapType;
                            final canEnter = SeclusionService.canEnterMap(
                              mapType: def.mapType,
                              charRealmTier: widget.charRealmTier,
                              maps: maps,
                            );
                            return _MapCard(
                              def: def,
                              isActive: isActive,
                              canEnter: canEnter,
                              activeSession: isActive ? active : null,
                              onTap: () => _onMapTap(context, def),
                              currentRealm: widget.charRealmTier,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBanner extends StatelessWidget {
  final RetreatSession session;
  final SeclusionMapDef mapDef;

  const _ActiveBanner({required this.session, required this.mapDef});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(session.startedAt).inMinutes;
    final planned = session.durationHours * 60;
    final remaining = (planned - elapsed).clamp(0, planned);

    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      paperOpacity: 0.28,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _MapImage(
              path: mapDef.imagePath,
              width: 86,
              height: 52,
              locked: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(color: WuxiaUi.ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${UiStrings.seclusionMapAtlasTitle} · ${mapDef.mapName}',
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    remaining > 0
                        ? UiStrings.seclusionMapActiveBannerRemaining(
                            UiStrings.retreatRemainingText(
                              remaining ~/ 60,
                              remaining % 60,
                            ),
                          )
                        : UiStrings.seclusionMapActiveBannerDone(),
                    style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: WuxiaUi.ink, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Card
// ─────────────────────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final SeclusionMapDef def;
  final bool isActive;
  final bool canEnter;
  final RetreatSession? activeSession;
  final VoidCallback? onTap;
  final RealmTier currentRealm;

  const _MapCard({
    required this.def,
    required this.isActive,
    required this.canEnter,
    required this.activeSession,
    required this.onTap,
    required this.currentRealm,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !canEnter && !isActive;
    final statusColor = isActive
        ? WuxiaColors.resultHighlight
        : locked
        ? WuxiaUi.muted
        : WuxiaUi.qing;
    final traitColor = SeclusionMapVisuals.primaryColor(def);
    final gateText = locked
        ? UiStrings.seclusionRequiredRealmWithCurrent(
            EnumL10n.realmTier(def.requiredRealm),
            EnumL10n.realmTier(currentRealm),
          )
        : UiStrings.seclusionRequiredRealm(
            EnumL10n.realmTier(def.requiredRealm),
          );
    final statusDetail = isActive
        ? _activeHint()
        : locked
        ? UiStrings.seclusionMapLocked
        : UiStrings.seclusionMapReadyHint;
    final statusLabel = isActive
        ? UiStrings.seclusionMapActive
        : locked
        ? UiStrings.seclusionMapLockedHint
        : UiStrings.seclusionMapReady;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: WuxiaUi.ink,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: isActive ? 1.8 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              if (isActive)
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.24),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MapImage(
                  path: def.imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  locked: locked,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: locked ? 0.14 : 0.02),
                        Colors.black.withValues(alpha: locked ? 0.76 : 0.5),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: WuxiaUi.paper.withValues(alpha: 0.38),
                        width: 5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  right: 10,
                  bottom: 10,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: traitColor.withValues(
                            alpha: locked ? 0.18 : 0.32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 12,
                  child: SeclusionMapTraitIcon(def: def, locked: locked),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: _MapStatusPill(label: statusLabel, color: statusColor),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 122,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.mapName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked
                              ? WuxiaColors.textSecondary
                              : WuxiaColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      SeclusionMapTraitStrip(
                        def: def,
                        locked: locked,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                    decoration: BoxDecoration(
                      color: WuxiaUi.paper.withValues(
                        alpha: locked ? 0.78 : 0.88,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: traitColor.withValues(
                          alpha: locked ? 0.2 : 0.42,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MapInfoLine(
                                label: UiStrings.seclusionMapRealmGateLabel,
                                value: gateText,
                                accent: statusColor,
                                locked: locked,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MapInfoLine(
                                label: UiStrings.seclusionMapStatusLabel,
                                value: statusDetail,
                                accent: statusColor,
                                locked: locked,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              isActive
                                  ? Icons.arrow_forward_ios
                                  : locked
                                  ? Icons.lock
                                  : Icons.login,
                              color: locked ? WuxiaUi.muted : statusColor,
                              size: 17,
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          UiStrings.seclusionMapExpectedOutputLabel,
                          style: TextStyle(
                            color: locked ? WuxiaUi.muted : WuxiaUi.ink2,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SeclusionMapOutputStrip(def: def, locked: locked),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _activeHint() {
    final session = activeSession;
    if (session == null) return UiStrings.seclusionMapActiveHint;
    final elapsed = DateTime.now().difference(session.startedAt).inMinutes;
    final planned = session.durationHours * 60;
    final remaining = (planned - elapsed).clamp(0, planned);
    if (remaining <= 0) return UiStrings.seclusionMapActiveDoneHint;
    return UiStrings.seclusionMapActiveRemainingHint(remaining);
  }
}

class _MapInfoLine extends StatelessWidget {
  const _MapInfoLine({
    required this.label,
    required this.value,
    required this.accent,
    required this.locked,
  });

  final String label;
  final String value;
  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: locked ? WuxiaUi.muted : accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: locked ? WuxiaUi.muted : WuxiaUi.ink,
            fontSize: 12,
            height: 1.18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MapImage extends StatelessWidget {
  const _MapImage({
    required this.path,
    required this.width,
    required this.height,
    required this.locked,
  });

  final String? path;
  final double width;
  final double height;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return _fallback();
    }
    return Image(
      image: ExactAssetImage(path!, bundle: DefaultAssetBundle.of(context)),
      width: width,
      height: height,
      fit: BoxFit.cover,
      color: locked ? Colors.black.withValues(alpha: 0.48) : null,
      colorBlendMode: locked ? BlendMode.darken : null,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: WuxiaColors.background,
      child: const Icon(Icons.landscape, color: WuxiaColors.textMuted),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
