import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../core/domain/enums.dart';
import '../application/seclusion_service_providers.dart';
import '../../../ui/strings.dart';
import '../../../shared/theme/colors.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'retreat_result_screen.dart';

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

      if (!mounted) return;
      // 同 setup：active 用 pushReplacement → result 接管路由槽位。result
      // 关闭时 pop(true) 经 pushReplacement 链回到 list 的 push<bool>(setup)。
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => RetreatResultScreen(
            mapDef: widget.mapDef,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收功失败：$e')),
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

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.activeRetreatTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 地图名
              Text(
                def.mapName,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 时间范围
              Text(
                '$startStr → $endStr（${session.durationHours}h）',
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: WuxiaColors.barTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    done ? WuxiaColors.resultHighlight : WuxiaColors.internalForce,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                done ? '已完成' : '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color:
                      done ? WuxiaColors.resultHighlight : WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              // 收功按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCollecting ? null : _onCollect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        done ? WuxiaColors.resultHighlight : WuxiaColors.gangMeng,
                    foregroundColor: WuxiaColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: WuxiaColors.buttonDisabled,
                  ),
                  child: Text(
                    _isCollecting
                        ? '请稍候…'
                        : done
                            ? UiStrings.activeRetreatCollect
                            : UiStrings.activeRetreatEarlyCollect,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
