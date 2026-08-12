import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_route_isar_directory.dart';

/// 视觉路由 Isar 目录隔离守卫(派单 A,BACKLOG 二#12)。
///
/// 背景:`visual_route_host.dart` 曾裸调 `IsarSetup.init()`(不传
/// directory),视觉路由直接打开玩家真实存档 slot 1——打开即可能迁移
/// saveVersion 顶到未来版本(main 构建再也打不开),且 seed 的
/// `_clearAll()` 会清掉角色/装备/心法/道具/事件全部业务表。修复 =
/// 每条视觉路由改用 [visualRouteIsarDirectory] 提供的隔离空库。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String normalize(String path) {
    var p = path.replaceAll('\\', '/');
    while (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  bool isWithin(String parent, String child) =>
      normalize(child).startsWith('${normalize(parent)}/');

  group('visualRouteIsarDirectory 目录语义', () {
    test('返回路径位于 Directory.systemTemp 之下,且绝不在 app documents 目录之下', () async {
      // 给 path_provider 的 method channel 挂 mock:若实现退化为
      // getApplicationDocumentsDirectory()(玩家真实存档),这里能拿到一个
      // 已知的哨兵路径,下面的断言必然红。
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final fakeDocsDir =
          '${Directory.systemTemp.path}/fake_app_documents_sentinel';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return fakeDocsDir;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final dir = await visualRouteIsarDirectory();

      expect(
        isWithin(Directory.systemTemp.path, dir.path),
        isTrue,
        reason: '隔离目录必须落在 systemTemp 之下,实际:${dir.path}',
      );
      expect(
        normalize(dir.path),
        isNot(normalize(fakeDocsDir)),
        reason: '隔离目录不得等于 app documents 目录',
      );
      expect(
        isWithin(fakeDocsDir, dir.path),
        isFalse,
        reason: '隔离目录不得位于 app documents 目录之下',
      );
      expect(dir.existsSync(), isTrue, reason: '返回的目录必须已创建');
    });
  });

  group('visualRouteIsarDirectory 清空语义', () {
    test('目标目录已存在内容时,调用后哨兵文件被清除(每次启动都是干净空库)', () async {
      final dir = Directory(
        '${Directory.systemTemp.path}'
        '${Platform.pathSeparator}$visualRouteIsarDirName',
      );
      await dir.create(recursive: true);
      final sentinel = File('${dir.path}${Platform.pathSeparator}sentinel.txt');
      await sentinel.writeAsString('leftover from previous route');
      final sentinelSubDir = Directory(
        '${dir.path}${Platform.pathSeparator}stale_subdir',
      );
      await sentinelSubDir.create();
      expect(sentinel.existsSync(), isTrue);
      expect(sentinelSubDir.existsSync(), isTrue);

      final result = await visualRouteIsarDirectory();

      expect(sentinel.existsSync(), isFalse, reason: '调用必须递归清空旧内容,哨兵文件不应残留');
      expect(
        sentinelSubDir.existsSync(),
        isFalse,
        reason: '递归删除必须覆盖子目录,哨兵子目录不应残留',
      );
      expect(result.existsSync(), isTrue, reason: '清空后必须重建空目录');
      expect(result.listSync(), isEmpty, reason: '重建后的目录必须为空库(无旧 fixture 残留)');
    });
  });

  group('visual_route_host Isar 初始化接线守卫(静态)', () {
    test('IsarSetup.init 必须传 directory,且目录来源是 visualRouteIsarDirectory', () {
      final source = File(
        'lib/features/debug/presentation/visual_route_host.dart',
      ).readAsStringSync();

      final allInits = RegExp(r'IsarSetup\.init\(').allMatches(source).toList();
      expect(
        allInits,
        isNotEmpty,
        reason: 'visual_route_host.dart 应保留 IsarSetup.init 调用点',
      );

      final withDirectory = RegExp(
        r'IsarSetup\.init\(\s*directory\s*:',
      ).allMatches(source).toList();
      expect(
        withDirectory.length,
        allInits.length,
        reason:
            'visual_route_host.dart 存在不传 directory 的 IsarSetup.init() '
            '裸调用——视觉路由将打开玩家真实存档。共 ${allInits.length} 处 init,'
            '仅 ${withDirectory.length} 处传了 directory。',
      );

      expect(
        source.contains('visualRouteIsarDirectory('),
        isTrue,
        reason:
            'IsarSetup.init 的 directory 必须来自 visualRouteIsarDirectory()'
            '(systemTemp 下的隔离空库),不得换用其它目录来源',
      );
    });
  });
}
