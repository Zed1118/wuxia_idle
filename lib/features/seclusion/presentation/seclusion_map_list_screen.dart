import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/seclusion_service.dart';
import '../application/seclusion_service_providers.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'active_retreat_screen.dart';
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
            UiStrings.seclusionRequiredRealm(
              EnumL10n.realmTier(def.requiredRealm),
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

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.seclusionTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (var i = 0; i < maps.length; i++) ...[
                        Builder(
                          builder: (context) {
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
                            );
                          },
                        ),
                        if (i != maps.length - 1) const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
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
                    '${mapDef.mapName} · ${UiStrings.seclusionMapActive}',
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    remaining > 0
                        ? '剩余 ${remaining ~/ 60}h${remaining % 60}min'
                        : '已完成，可收功',
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

  const _MapCard({
    required this.def,
    required this.isActive,
    required this.canEnter,
    required this.activeSession,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !canEnter && !isActive;
    final statusColor = isActive
        ? WuxiaColors.resultHighlight
        : locked
        ? WuxiaUi.muted
        : WuxiaColors.hpHigh;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: isActive ? 1.8 : 1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 154,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MapImage(
                        path: def.imagePath,
                        width: double.infinity,
                        height: 154,
                        locked: locked,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.62),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                def.mapName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: locked
                                      ? WuxiaColors.textSecondary
                                      : WuxiaColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _MapStatusPill(
                              label: isActive
                                  ? UiStrings.seclusionMapActive
                                  : locked
                                  ? UiStrings.seclusionMapLocked
                                  : UiStrings.seclusionMapAvailable,
                              color: statusColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                  color: locked
                      ? WuxiaColors.avatarFill.withValues(alpha: 0.72)
                      : WuxiaColors.panel,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          locked
                              ? UiStrings.seclusionRequiredRealm(
                                  EnumL10n.realmTier(def.requiredRealm),
                                )
                              : _outputSummary(),
                          style: TextStyle(
                            color: locked
                                ? WuxiaColors.textMuted
                                : WuxiaColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(
                        isActive ? Icons.arrow_forward_ios : Icons.login,
                        color: locked
                            ? WuxiaColors.textMuted
                            : WuxiaColors.textSecondary,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _outputSummary() {
    final parts = <String>[];
    if (def.equipmentDropRate > 1.0) parts.add('兵器掉率 +50%');
    if (def.techniqueLearnRate > 1.0) parts.add('心法领悟 +50%');
    if (def.internalForceGrowth > 1.0) parts.add('内力增长 +50%');
    if (parts.isEmpty) parts.add('综合产出');
    return parts.join('｜');
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
    return Image.asset(
      path!,
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
