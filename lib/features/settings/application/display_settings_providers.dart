import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/display_settings.dart';
import 'display_settings_controller.dart';
import 'display_settings_service.dart';
import 'window_controller.dart';

/// L1 显示设置 providers（裸 provider 体例,照搬 gameplay_settings_provider,
/// 免 build_runner）。

final displaySettingsServiceProvider = Provider<DisplaySettingsService>(
  (ref) => DisplaySettingsService(),
);

/// 窗口副作用层;测试 override 为 fake 即不碰 platform channel。
final windowControllerProvider = Provider<WindowController>(
  (ref) => const WindowManagerController(),
);

final displaySettingsControllerProvider = Provider<DisplaySettingsController>(
  (ref) => DisplaySettingsController(
    ref.watch(displaySettingsServiceProvider),
    ref.watch(windowControllerProvider),
  ),
);

/// 当前显示设置（异步 load + 缓存）。改动后 `ref.invalidate` 刷新。
final displaySettingsProvider = FutureProvider<DisplaySettings>(
  (ref) => ref.watch(displaySettingsServiceProvider).load(),
);
