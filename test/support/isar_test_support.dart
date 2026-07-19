import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';

Future<void>? _initialization;

/// IsarCore 初始化（全部 Isar 测试套件的唯一入口，调用点 130+ 处）。
///
/// 2026-07-19 并发隔离 flaky 根治：改用 isar_community_flutter_libs 随包
/// 发布的本地二进制（`libraries:` 显式路径），不再走 `download: true`。
/// 旧路径把库**非原子流写**进包根 `libisar.dylib`：新 checkout / CI 首跑
/// 并发套件时，后进进程 dlopen 到半截文件报「slice extends beyond end of
/// file」→ setUpAll [E] 偶红（全量并发偶红、单跑绿的隔离型 flaky 根因）；
/// 且包内 exists 检查不重下，半截文件会留毒后续每一次跑测（项目史上
/// 「fresh worktree dylib 截断，需从主仓手动 cp」即同一根因）。本地二进制
/// 只读共享，无下载、无竞争、无网络依赖，CI 每次新环境也稳定。
Future<void> initializeTestIsarCore() =>
    _initialization ??= Isar.initializeIsarCore(
      libraries: {Abi.current(): resolveBundledIsarCorePath()},
    );

/// 从 `isar_community_flutter_libs` 包内解析当前平台的 IsarCore 二进制路径
/// （与 `isar_community` 同版本发布；找不到包/文件即抛错，不静默降级）。
String resolveBundledIsarCorePath() {
  final packageConfigFile = File('.dart_tool/package_config.json');
  final packageConfigUri = packageConfigFile.absolute.uri;
  final packageConfig =
      jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = packageConfig['packages'] as List<dynamic>;

  Uri? packageRootUri;
  for (final package in packages) {
    final packageMap = package as Map<String, dynamic>;
    if (packageMap['name'] == 'isar_community_flutter_libs') {
      final rootUri = Uri.parse(packageMap['rootUri'] as String);
      packageRootUri = rootUri.isAbsolute
          ? rootUri
          : packageConfigUri.resolveUri(rootUri);
      break;
    }
  }

  if (packageRootUri == null) {
    throw StateError('isar_community_flutter_libs not found in package config');
  }
  packageRootUri = packageRootUri.replace(
    path: packageRootUri.path.endsWith('/')
        ? packageRootUri.path
        : '${packageRootUri.path}/',
  );

  final libraryPath = switch (Abi.current()) {
    Abi.macosArm64 || Abi.macosX64 => 'macos/libisar.dylib',
    Abi.linuxX64 => 'linux/libisar.so',
    Abi.windowsX64 || Abi.windowsArm64 => 'windows/libisar.dll',
    _ => throw UnsupportedError('Unsupported Isar test ABI: ${Abi.current()}'),
  };
  final libraryFile = File.fromUri(packageRootUri.resolve(libraryPath));
  if (!libraryFile.existsSync()) {
    throw StateError('Bundled IsarCore library not found: ${libraryFile.path}');
  }
  return libraryFile.path;
}
