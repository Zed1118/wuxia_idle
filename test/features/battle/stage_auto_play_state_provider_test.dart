import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/battle_replay_providers.dart';
import 'package:wuxia_idle/features/battle/application/battle_replay_record_service.dart';

/// 半手动战斗 P0 步骤5-G3:选关屏 per-stage 开关读 `autoPlayOverride` 的
/// family provider。验证三态映射 + hasRecord 派生。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;
  late BattleReplayRecordService service;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_autoplay_state_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    service = BattleReplayRecordService(isar: IsarSetup.instance);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const key = 'stage#stage_01_01#1';

  test('无记录(未通关/迁移豁免)→ hasRecord=false, overrideMode=null', () async {
    final state = await container.read(stageAutoPlayStateProvider(key).future);
    expect(state.hasRecord, isFalse);
    expect(state.overrideMode, isNull);
  });

  test('手动通关后无 override → hasRecord=true, overrideMode=null(跟随全局)', () async {
    await service.record(battleKey: key, seed: 7, ops: const []);
    final state = await container.read(stageAutoPlayStateProvider(key).future);
    expect(state.hasRecord, isTrue);
    expect(state.overrideMode, isNull);
  });

  test('setAutoPlayOverride(false) + invalidate → overrideMode=false', () async {
    await service.record(battleKey: key, seed: 7, ops: const []);
    await container.read(stageAutoPlayStateProvider(key).future);
    await service.setAutoPlayOverride(key, false);
    container.invalidate(stageAutoPlayStateProvider(key));
    final state = await container.read(stageAutoPlayStateProvider(key).future);
    expect(state.hasRecord, isTrue);
    expect(state.overrideMode, isFalse);
  });
}
