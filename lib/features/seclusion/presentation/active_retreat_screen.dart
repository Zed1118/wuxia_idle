import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../core/domain/enums.dart';
import '../application/seclusion_service_providers.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'retreat_result_screen.dart';
import 'seclusion_gate.dart';
import 'seclusion_map_visuals.dart';

/// 闭关进行中屏幕（Phase 3 T49）。
///
/// 显示地图名、开始/结束时间、进度条（elapsed/durationHours）。
/// 不做实时 Timer；打开时计算一次，无自动刷新（Demo 足够）。
///
/// 「提前收功」/「收功」按钮 → confirm dialog → SeclusionService(isar: IsarSetup.instance).completeRetreat
/// → push RetreatResultScreen。
class ActiveRetreatScreen extends ConsumerStatefulWidget {
  final RetreatSession session;
  final SeclusionMapDef mapDef;
  final int characterId;
  final RealmTier charRealmTier;

  const ActiveRetreatScreen({
    super.key,
    required this.session,
    required this.mapDef,
    required this.characterId,
    required this.charRealmTier,
  });

  @override
  ConsumerState<ActiveRetreatScreen> createState() =>
      _ActiveRetreatScreenState();
}

class _ActiveRetreatScreenState extends ConsumerState<ActiveRetreatScreen> {
  bool _isCollecting = false;

  bool get _isDone {
    final elapsed = DateTime.now().difference(widget.session.startedAt);
    return elapsed.inSeconds >= widget.session.durationHours * 3600;
  }

  double get _progress {
    final elapsed =
        DateTime.now().difference(widget.session.startedAt).inSeconds /
        (widget.session.durationHours * 3600.0);
    return elapsed.clamp(0.0, 1.0);
  }

  Future<void> _onCollect() async {
    final dialogResult = _isDone
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: WuxiaColors.panel,
              title: const Text(
                UiStrings.activeRetreatConfirmTitle,
                style: TextStyle(color: WuxiaColors.textPrimary),
              ),
              content: const Text(
                UiStrings.activeRetreatConfirmBody,
                style: TextStyle(color: WuxiaColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    UiStrings.activeRetreatCancel,
                    style: TextStyle(color: WuxiaColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    UiStrings.activeRetreatConfirm,
                    style: TextStyle(color: WuxiaColors.gangMeng),
                  ),
                ),
              ],
            ),
          );

    if (dialogResult != true || !mounted) return;
    setState(() => _isCollecting = true);

    try {
      // C-W14-2:provider 注入 encounterService,让 completeRetreat 写产出后能喂
      // biome/weather 累计给奇遇系统。W15 Phase 5 #2 改 Consumer 化销 #28。
      final svc = ref.read(seclusionServiceProvider);
      if (svc == null) {
        throw StateError('seclusionServiceProvider unavailable (isar null)');
      }
      final result = await svc.completeRetreat(
        session: widget.session,
        characterId: widget.characterId,
        charRealmTier: widget.charRealmTier,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );
      ref.invalidate(activeRetreatSessionProvider);

      if (!mounted) return;
      // 大境界突破 jingle(沿胜利 dialog 体例):闭关收功跨 tier 才响。
      if (result.advancement?.crossedTier ?? false) {
        SoundManager.instance.playSfx(SfxId.realmAdvance);
      }
      // 同 setup：active 用 pushReplacement → result 接管路由槽位。result
      // 关闭时 pop(true) 经 pushReplacement 链回到 list 的 push<bool>(setup)。
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) =>
              RetreatResultScreen(mapDef: widget.mapDef, result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiStrings.retreatCollectFailed(e))),
      );
      setState(() => _isCollecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final def = widget.mapDef;
    final startStr = _formatTime(session.startedAt);
    final endStr = _formatTime(
      session.startedAt.add(Duration(hours: session.durationHours)),
    );
    final progress = _progress;
    final done = _isDone;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const _RetreatBackIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _RetreatCollectIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _RetreatBackIntent: CallbackAction<_RetreatBackIntent>(
            onInvoke: (_) {
              Navigator.maybePop(context);
              return null;
            },
          ),
          _RetreatCollectIntent: CallbackAction<_RetreatCollectIntent>(
            onInvoke: (_) {
              if (!_isCollecting) _onCollect();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: WuxiaColors.background,
            appBar: AppBar(
              title: const Text(UiStrings.activeRetreatTitle),
              backgroundColor: WuxiaColors.sidebar,
              foregroundColor: WuxiaColors.textPrimary,
              automaticallyImplyLeading: true,
            ),
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MapBackdrop(path: def.imagePath),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: PaperPanel(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                          paperOpacity: 0.42,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: SeclusionMapTraitIcon(def: def, size: 50),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const _StateSeal(),
                                        const SizedBox(height: 10),
                                        Text(
                                          def.mapName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: WuxiaUi.ink,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 9),
                                        SeclusionMapTraitStrip(def: def),
                                      ],
                                    ),
                                  ),
                                  _ProgressStamp(
                                    label: done
                                        ? UiStrings.activeRetreatDone
                                        : UiStrings.activeRetreatProgressPct(
                                            (progress * 100).round(),
                                          ),
                                    done: done,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _TimeRangePanel(
                                start: startStr,
                                end: endStr,
                                hours: session.durationHours,
                              ),
                              const SizedBox(height: 22),
                              const SectionHeader(
                                UiStrings.activeRetreatProgressTitle,
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 12,
                                  backgroundColor: WuxiaUi.muted.withValues(
                                    alpha: 0.22,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    done
                                        ? WuxiaUi.gold
                                        : SeclusionMapVisuals.primaryColor(def),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                done
                                    ? UiStrings.activeRetreatDoneHint
                                    : UiStrings.activeRetreatEarlyHint,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: done ? WuxiaUi.gold : WuxiaUi.ink2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Align(
                                alignment: Alignment.center,
                                child: PlaqueButton(
                                  label: _isCollecting
                                      ? UiStrings.seclusionStarting
                                      : done
                                      ? UiStrings.activeRetreatCollect
                                      : UiStrings.activeRetreatEarlyCollect,
                                  primary: true,
                                  disabled: _isCollecting,
                                  onTap: _onCollect,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  static String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _StateSeal extends StatelessWidget {
  const _StateSeal();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.jiang.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.jiang.withValues(alpha: 0.52)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          UiStrings.activeRetreatStateSeal,
          style: TextStyle(
            color: WuxiaUi.jiang,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProgressStamp extends StatelessWidget {
  const _ProgressStamp({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? WuxiaUi.gold : WuxiaUi.qing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.62)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TimeRangePanel extends StatelessWidget {
  const _TimeRangePanel({
    required this.start,
    required this.end,
    required this.hours,
  });

  final String start;
  final String end;
  final int hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaUi.muted.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: WuxiaUi.ink2, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              UiStrings.activeRetreatTimeRange(start, end, hours),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaUi.ink2,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) return _fallback();
    return Image(
      image: ExactAssetImage(path!, bundle: DefaultAssetBundle.of(context)),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Container(color: WuxiaColors.background);
}

class _RetreatBackIntent extends Intent {
  const _RetreatBackIntent();
}

class _RetreatCollectIntent extends Intent {
  const _RetreatCollectIntent();
}
