import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/application/technique_learn_flow_service_providers.dart';

import '../../support/isar_test_support.dart';

/// `techniqueLearnFlowServiceProvider` nullable propagation 行为测
/// （2026-07-19 夜批 coverage 补强，基线 0/3 行）。
///
/// 真 Isar init/close + ProviderContainer 真读（生产入口 = 心法学习闭环 UI
/// `ref.watch(techniqueLearnFlowServiceProvider)` 后 `service == null` 短路），
/// 钉链路语义：未 init → null；init + invalidate → 非 null；close → 回 null。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_technique_learn_flow_providers_',
    );
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('null → init 非 null → close 回 null 的全链路传导', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(techniqueLearnFlowServiceProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      container.read(techniqueLearnFlowServiceProvider),
      isNull,
      reason: 'Isar 未 init:widget 端 null 短路',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(
      container.read(techniqueLearnFlowServiceProvider),
      isNotNull,
      reason: 'init 后 watch 链传导出真 service',
    );

    await IsarSetup.close();
    container.invalidate(isarProvider);
    expect(
      container.read(techniqueLearnFlowServiceProvider),
      isNull,
      reason: '删当前档/close 后回 null(spec §4 guard)',
    );
  });
}
