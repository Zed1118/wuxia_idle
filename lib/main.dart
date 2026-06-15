import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'data/isar_setup.dart';
import 'features/debug/application/visual_route.dart';
import 'features/debug/presentation/visual_route_host.dart';
import 'features/settings/application/audio_settings_service.dart';
import 'features/settings/application/display_settings_providers.dart';
import 'features/settings/application/display_settings_service.dart';
import 'features/settings/application/window_controller.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'shared/audio/audio_players_backend.dart';
import 'shared/audio/sound_manager.dart';
import 'shared/strings.dart';
import 'shared/theme/wuxia_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SoundManager.instance = SoundManager(AudioPlayersBackend());
  await SoundManager.instance.applySettings(await AudioSettingsService().load());

  // 视觉验收直达:--dart-define=VISUAL_ROUTE=<id>。debug + profile 均生效
  // (profile 下 kDebugMode=false → 隐藏 debug chrome,出干净 Steam 截图);
  // release / 无参数 → 短路(kReleaseMode),走下方正常启动,零影响。
  if (!kReleaseMode) {
    final route = visualRouteFromEnv();
    if (route != null) {
      runApp(VisualRouteApp(route: route));
      return;
    }
  }

  // L1 显示设置:初始化 window_manager 并应用保存的窗口模式/分辨率。
  // 放 visual-route 短路之后 → 验收模式（VISUAL_WINDOW_W/H 锁尺寸）不受干扰。
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    await const WindowManagerController().apply(
      await DisplaySettingsService().load(),
    );
  }

  // M4 PoC #46 美术 Stage 2 收官:启动初始化迁入 SplashScreen,
  // 期间显示 landscape_loading.png + 并行跑 GameRepository + IsarSetup。
  runApp(const ProviderScope(child: WuxiaApp()));
}

class WuxiaApp extends ConsumerStatefulWidget {
  const WuxiaApp({super.key});

  @override
  ConsumerState<WuxiaApp> createState() => _WuxiaAppState();
}

class _WuxiaAppState extends ConsumerState<WuxiaApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // M2 范围 B：离开瞬间(隐藏/失活/退出)记 lastOnlineAt，重开算离线时长。
    _lifecycle = AppLifecycleListener(
      onHide: _recordOnline,
      onInactive: _recordOnline,
      onDetach: _recordOnline,
    );
  }

  void _recordOnline() {
    // fire-and-forget；未 init 时 instance 抛错，catchError 兜底避免 lifecycle 崩溃。
    unawaited(IsarSetup.touchOnlineNow().catchError((_) {}));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // F11(Windows/Linux 惯例);macOS 的 F11 被系统「显示桌面」吞掉
        // (Codex 验收 L1-3),故补 Alt+Enter(macOS 不被系统占,游戏全屏惯例)。
        SingleActivator(LogicalKeyboardKey.f11): _ToggleFullscreenIntent(),
        SingleActivator(LogicalKeyboardKey.enter, alt: true):
            _ToggleFullscreenIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ToggleFullscreenIntent: CallbackAction<_ToggleFullscreenIntent>(
            onInvoke: (_) {
              _toggleFullscreen(ref);
              return null;
            },
          ),
        },
        child: MaterialApp(
          title: UiStrings.appTitle,
          theme: ThemeData.dark(useMaterial3: true),
          debugShowCheckedModeBanner: false,
          builder: _wuxiaTextScaleBuilder,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// F11 全屏切换:读当前设置 → toggle → 刷新 provider（端机偏好,SharedPreferences）。
Future<void> _toggleFullscreen(WidgetRef ref) async {
  final current = await ref.read(displaySettingsProvider.future);
  await ref.read(displaySettingsControllerProvider).toggleFullscreen(current);
  ref.invalidate(displaySettingsProvider);
}

class _ToggleFullscreenIntent extends Intent {
  const _ToggleFullscreenIntent();
}

Widget _wuxiaTextScaleBuilder(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(
      textScaler: const TextScaler.linear(WuxiaUi.textScale),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}
