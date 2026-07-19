import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/dispel/application/dispel_service_providers.dart';

import '../../support/isar_test_support.dart';

/// `dispelServiceProvider` nullable propagation 行为测（2026-07-19 夜批
/// coverage 补强，基线 0/3 行）。
///
/// 真 Isar init/close + ProviderContainer 真读（生产入口 = widget 端
/// `ref.watch(dispelServiceProvider)` 后 `service == null` 短路），钉链路语义：
///   - Isar 未 init → service 为 null（widget 短路返回）
///   - init + invalidate(isarProvider) → service 非 null（watch 链传导）
///   - close（删当前档路径）→ 回 null（选择屏 guard 生效）
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_dispel_providers_');
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('null → init 非 null → close 回 null 的全链路传导', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(dispelServiceProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      container.read(dispelServiceProvider),
      isNull,
      reason: 'Isar 未 init:widget 端 null 短路',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(
      container.read(dispelServiceProvider),
      isNotNull,
      reason: 'init 后 watch 链传导出真 service',
    );

    await IsarSetup.close();
    container.invalidate(isarProvider);
    expect(
      container.read(dispelServiceProvider),
      isNull,
      reason: '删当前档/close 后回 null(spec §4 guard)',
    );
  });
}
