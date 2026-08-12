import 'dart:io';

import 'package:flutter/foundation.dart';

/// 视觉路由专用 Isar 隔离目录名(固定于 [Directory.systemTemp] 之下)。
const visualRouteIsarDirName = 'wuxia_idle_visual_routes';

/// 解析视觉路由(`--visual-route=<id>` / `--dart-define=VISUAL_ROUTE=<id>`)
/// 专用的 Isar 目录,保证与生产存档完全隔离。
///
/// 为什么必须隔离:视觉路由只做美术/UI 验收,所有碰 Isar 的路由都自带
/// seed,没有任何路由读真实存档。若沿用默认目录
/// (`getApplicationDocumentsDirectory()`,即玩家真实存档):
/// - Isar 打开即可能触发 saveVersion 迁移,把生产档顶到分支上的未来版本,
///   main 构建将因 UnsupportedSaveVersionException 再也打不开;
/// - seed 服务的 `_clearAll()` 会清空角色/装备/心法/道具/事件表,把生产
///   Isar 实例递给它等于清掉玩家全部业务数据。
///
/// 语义:返回 `${Directory.systemTemp}/wuxia_idle_visual_routes`,且
/// **每次调用先递归删除再重建**——保证每条路由都是干净空库(部分路由的
/// seed 只增不清,复用同库会让上一条路由的 fixture 漏进下一条)。
/// 本函数绝不返回 `getApplicationDocumentsDirectory()`。
///
/// 并发限制:目录名固定,两个视觉路由进程同时跑会互相清库。当前截图管线
/// 串行执行,可接受;若未来需要并行截图,需引入 per-process 目录或加锁
/// (不在本函数职责内)。
Future<Directory> visualRouteIsarDirectory() async {
  final dir = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$visualRouteIsarDirName',
  );
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);
  debugPrint('VISUAL_ROUTE_ISAR_DIR: ${dir.path}');
  return dir;
}
