import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
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
            return Column(
              children: [
                if (active != null) _ActiveBanner(session: active),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                        onTap: canEnter || isActive
                            ? () => _onMapTap(context, def)
                            : null,
                      );
                    },
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

  const _ActiveBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final elapsed =
        DateTime.now().difference(session.startedAt).inMinutes;
    final planned = session.durationHours * 60;
    final remaining = (planned - elapsed).clamp(0, planned);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: WuxiaColors.panel,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  UiStrings.seclusionMapActive,
                  style: TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  remaining > 0
                      ? '剩余 ${remaining ~/ 60}h${remaining % 60}min'
                      : '已完成，可收功',
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
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
    final borderColor = isActive
        ? WuxiaColors.resultHighlight
        : locked
            ? WuxiaColors.border
            : WuxiaColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: locked ? WuxiaColors.panel.withValues(alpha: 0.5) : WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (def.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    def.imagePath!,
                    width: 96,
                    height: 64,
                    fit: BoxFit.cover,
                    color: locked
                        ? Colors.black.withValues(alpha: 0.5)
                        : null,
                    colorBlendMode: locked ? BlendMode.darken : null,
                    errorBuilder: (_, _, _) => Container(
                      width: 96,
                      height: 64,
                      color: WuxiaColors.background,
                      child: const Icon(
                        Icons.landscape,
                        color: WuxiaColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          def.mapName,
                          style: TextStyle(
                            color: locked
                                ? WuxiaColors.textSecondary
                                : WuxiaColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: WuxiaColors.resultHighlight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              UiStrings.seclusionMapActive,
                              style: TextStyle(
                                color: WuxiaColors.resultHighlight,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locked
                          ? UiStrings.seclusionRequiredRealm(
                              EnumL10n.realmTier(def.requiredRealm),
                            )
                          : _outputSummary(),
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!locked)
                Icon(
                  isActive ? Icons.arrow_forward_ios : Icons.login,
                  color: WuxiaColors.textSecondary,
                  size: 16,
                ),
            ],
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
