import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../home_feed/presentation/home_feed_screen.dart';

/// 启动闪屏(M4 PoC #46 美术 Stage 2 W6 收官 `landscape_loading.png` 9.5/10 接入)。
///
/// 启动期间显示水墨渔舟远山 + 应用标题,期间并行跑 [GameRepository.loadAllDefs]
/// 和 [IsarSetup.init]。完成后 pushReplacement 进 [HomeFeedScreen]。
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
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
    if (!kIsWeb) {
      await IsarSetup.init();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeFeedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
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
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          WuxiaColors.resultHighlight.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
