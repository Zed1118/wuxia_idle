import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../save_slot/presentation/save_select_screen.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 启动闪屏(M4 PoC #46 美术 Stage 2 W6 收官 `landscape_loading.png` 9.5/10 接入)。
///
/// 启动期间显示水墨渔舟远山 + 应用标题,期间跑 [GameRepository.loadAllDefs](与槽
/// 无关的配置)。**不再**在此 init Isar / onboard——多存档槽(spec B)启动先进
/// [SaveSelectScreen] 选档,选中后才 switchSlot 开对应 db + onboarding。离线收益在
/// 进入槽位后由 OfflinePassiveService 照常应用。
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minDisplay = const Duration(milliseconds: 2200),
  });

  /// 最短停留时长——加载过快时也让开场画面驻留,避免一闪而过。测试传 [Duration.zero]。
  final Duration minDisplay;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _loaded = false; // 资源加载完成
  bool _minElapsed = false; // 最短停留时长已过
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    Future<void>.delayed(widget.minDisplay, () {
      if (!mounted) return;
      setState(() => _minElapsed = true);
      _maybeNavigate();
    });
  }

  Future<void> _bootstrap() async {
    final repo = await GameRepository.loadAllDefs();
    if (kDebugMode) {
      debugPrint(
        '[GameRepository] 已加载 ${repo.realms.length} 行境界 / '
        '${repo.equipmentDefs.length} 件装备 / '
        '${repo.techniqueDefs.length} 本心法 / '
        '${repo.skillDefs.length} 招招式 / '
        '${repo.stageDefs.length} 个关卡 '
        '(numbers v${repo.numbers.version})',
      );
    }
    // 多存档槽(spec B):不在此 init Isar / onboard——交由 SaveSelectScreen 选档后
    // switchSlot 开对应 db + ensureFoundingMasters(幂等)。
    if (!mounted) return;
    setState(() => _loaded = true);
    _maybeNavigate();
  }

  // 加载完成且最短停留已过 → 自动进入。
  void _maybeNavigate() {
    if (_loaded && _minElapsed) _go();
  }

  // 加载完成后玩家轻触屏幕,可跳过剩余停留立即进入。
  void _onTapSkip() {
    if (_loaded) _go();
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const SaveSelectScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTapSkip,
      child: Scaffold(
        backgroundColor: WuxiaColors.background,
        // 开场整体淡入,告别硬切入。
        body: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(opacity: t, child: child),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WuxiaImage(
                'assets/ui/landscape_loading.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: WuxiaColors.background,
                ),
              ),
              // 半透明渐变让标题文字可读
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 64),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          UiStrings.appTitle,
                          style: TextStyle(
                            color: WuxiaColors.resultHighlight,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SplashFooter(loaded: _loaded),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部状态区:加载中显纺锤 +「正在展卷……」;加载完显「轻触继续」。
class _SplashFooter extends StatelessWidget {
  const _SplashFooter({required this.loaded});

  final bool loaded;

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return const Text(
        UiStrings.splashTapToContinue,
        style: TextStyle(
          color: WuxiaColors.textSecondary,
          fontSize: 13,
          letterSpacing: 4,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: InkLoadingIndicator(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          UiStrings.splashLoadingHint,
          style: TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 12,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}
