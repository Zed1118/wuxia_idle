import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'strings.dart';
import 'theme/colors.dart';
import 'widgets/wuxia_ui/paper_dialog.dart';
import 'widgets/wuxia_ui/plaque_button.dart';

/// 退出游戏的统一入口(桌面标配)。
///
/// 主菜单右上角退出键与设置面板「退出游戏」项共用此处,保证确认文案与行为一致。
/// 退出前弹二次确认;确认后执行 [quit](默认 `exit(0)`,测试可覆盖以免杀进程)。
class AppExit {
  AppExit._();

  /// 实际退出动作。默认进程级 `exit(0)`(发布目标 Windows 桌面无 window_manager,
  /// 直接退出到桌面)。web 无 `dart:io exit`,守卫跳过。测试可覆盖记录调用。
  @visibleForTesting
  static void Function() quit = _defaultQuit;

  static void _defaultQuit() {
    if (!kIsWeb) exit(0);
  }

  /// 弹确认对话框,确认则退出。进度已实时落盘 + 离线照常挂机,故退出无损。
  static Future<void> confirmAndQuit(BuildContext context) async {
    final shouldQuit = await PaperDialog.show<bool>(
      context,
      title: UiStrings.quitConfirmTitle,
      body: const Text(
        UiStrings.quitConfirmMessage,
        style: TextStyle(color: WuxiaColors.textSecondary, height: 1.5),
      ),
      actions: [
        Builder(
          builder: (ctx) => PlaqueButton(
            label: UiStrings.quitCancelAction,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
        ),
        Builder(
          builder: (ctx) => PlaqueButton(
            label: UiStrings.quitConfirmAction,
            destructive: true,
            autofocus: true,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ),
      ],
    );
    if (shouldQuit == true) quit();
  }
}
