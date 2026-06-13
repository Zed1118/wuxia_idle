import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/battle_replay_record_service.dart';
import 'package:wuxia_idle/features/battle/application/manual_clear_recorder.dart';
import 'package:wuxia_idle/features/battle/domain/auto_play_mode.dart';
import 'package:wuxia_idle/features/battle/domain/battle_replay.dart';

/// 半手动战斗 P0 步骤5-D:手动场胜利后录制 helper。
///
/// 不变量:**只有手动模式**(manualFirstClear / manualReplay)才写 record;
/// 自动模式(autoReplay / autoFallback)绝不录制(否则会用重放结果污染原记录)。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;
  late BattleReplayRecordService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_manual_rec_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    service = BattleReplayRecordService(isar: IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  const ops = [BattleReplayOp(anchor: 2, charId: 1, skillId: 'sk_x', targetId: -1)];
  const key = 'stage#stage_01_03#1';

  test('manualFirstClear → 录制 seed+ops, 返 true', () async {
    final did = await recordManualClearIfNeeded(
      mode: AutoPlayMode.manualFirstClear,
      battleKey: key,
      seed: 4242,
      ops: ops,
      service: service,
    );
    expect(did, isTrue);
    final rec = await service.find(key);
    expect(rec!.seed, 4242);
    expect(BattleReplayOp.decodeList(rec.opsJson), equals(ops));
  });

  test('manualReplay → 覆盖录制, 返 true', () async {
    final did = await recordManualClearIfNeeded(
      mode: AutoPlayMode.manualReplay,
      battleKey: key,
      seed: 7,
      ops: const [],
      service: service,
    );
    expect(did, isTrue);
    expect((await service.find(key))!.seed, 7);
  });

  test('autoReplay → 不录制, 返 false', () async {
    final did = await recordManualClearIfNeeded(
      mode: AutoPlayMode.autoReplay,
      battleKey: key,
      seed: 1,
      ops: ops,
      service: service,
    );
    expect(did, isFalse);
    expect(await service.find(key), isNull, reason: '自动重放不得污染原记录');
  });

  test('autoFallback → 不录制, 返 false', () async {
    final did = await recordManualClearIfNeeded(
      mode: AutoPlayMode.autoFallback,
      battleKey: key,
      seed: 1,
      ops: ops,
      service: service,
    );
    expect(did, isFalse);
    expect(await service.find(key), isNull);
  });
}
