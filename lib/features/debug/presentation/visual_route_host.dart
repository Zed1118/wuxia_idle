import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../../sect/presentation/sect_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../application/phase2_seed_service.dart';
import '../application/visual_route.dart';

/// 出版美术验收入口 App。
/// Task 4 直接 `runApp(VisualRouteApp(route: route))` 调用。
class VisualRouteApp extends StatelessWidget {
  const VisualRouteApp({super.key, required this.route});

  final VisualRoute route;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: UiStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: VisualRouteHost(route: route),
      ),
    );
  }
}

/// 按 [VisualRoute] 做 seed + 导航到目标验收屏。
/// 首帧就绪后打印 `VISUAL_ROUTE_READY: <id>` 供截图脚本 grep。
class VisualRouteHost extends ConsumerStatefulWidget {
  const VisualRouteHost({super.key, required this.route});

  final VisualRoute route;

  @override
  ConsumerState<VisualRouteHost> createState() => _VisualRouteHostState();
}

class _VisualRouteHostState extends ConsumerState<VisualRouteHost> {
  Widget? _target;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      // 1. 照 splash bootstrap:加载 defs + 初始化 Isar
      await GameRepository.loadAllDefs();
      await IsarSetup.init();
      final isar = IsarSetup.instance;

      // 2. 按 route seed + 选目标屏
      Widget target;
      switch (widget.route) {
        case VisualRoute.mainMenu:
          await OnboardingService(isar: isar).ensureFoundingMasters();
          target = const MainMenu();

        case VisualRoute.techniquePanelTierAll:
          await Phase2SeedService(isar: isar).seedVisualMasterAllTiers();
          target = const TechniquePanelScreen(characterId: 1);

        case VisualRoute.techniquePanelHero:
          await Phase2SeedService(isar: isar).seedRefineInsight();
          target = const TechniquePanelScreen(characterId: 1);

        case VisualRoute.sectScreenNpc:
          await Phase2SeedService(isar: isar).seedSectWithFullNpc();
          target = const SectScreen();

        case VisualRoute.characterPanelProfile:
          // seedMasterDisciple 已 _clearAll + 建祖师(id=1)+大/二弟子(带 portraitPath)
          // + 写 activeCharacterIds → 档案头立绘 + 3 Tab 切弟子立绘可验。
          await Phase2SeedService(isar: isar).seedMasterDisciple();
          target = const CharacterPanelScreen(characterId: 1);
      }

      // 3. 挂载目标屏
      if (!mounted) return;
      setState(() => _target = target);

      // 4. 目标屏首帧后打就绪信号
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('VISUAL_ROUTE_READY: ${widget.route.id}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      debugPrint('VISUAL_ROUTE_ERROR: ${widget.route.id} :: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('VISUAL_ROUTE_ERROR: $_error'),
        ),
      );
    }
    return _target ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}
