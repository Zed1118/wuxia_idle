import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/battle_replay_record_service.dart';
import 'package:wuxia_idle/features/battle/domain/battle_replay.dart';
import 'package:wuxia_idle/features/battle/domain/battle_replay_record.dart';

/// 半手动战斗 P0 步骤5:重放落盘 service。
///
/// 手动通关写 `{battleKey, seed, ops}` → 「已手动通关」query 命中 → 读出
/// seed + 解码 ops 供 `BattleNotifier.replay` 重演。每 battleKey 单行,重复
/// 通关覆盖为最新。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;
  late BattleReplayRecordService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_replay_rec_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    service = BattleReplayRecordService(isar: IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const ops = [
    BattleReplayOp(anchor: 1, charId: 1, skillId: 'sk_a', targetId: -2),
    BattleReplayOp(anchor: 3, charId: 2, skillId: 'sk_b'),
  ];

  test('battleKey 构造:stage / tower(默认 cycle=1)', () {
    expect(BattleReplayRecordService.stageBattleKey('stage_01_01'),
        'stage#stage_01_01#1');
    expect(BattleReplayRecordService.towerBattleKey(10), 'tower#10#1');
    expect(BattleReplayRecordService.stageBattleKey('stage_01_01', cycle: 2),
        'stage#stage_01_01#2');
  });

  test('未通关 → isManuallyCleared false / find null', () async {
    final key = BattleReplayRecordService.stageBattleKey('stage_01_01');
    expect(await service.isManuallyCleared(key), isFalse);
    expect(await service.find(key), isNull);
  });

  test('record 后 isManuallyCleared true + 读出 seed + 解码 ops', () async {
    final key = BattleReplayRecordService.stageBattleKey('stage_01_01');
    await service.record(battleKey: key, seed: 24680, ops: ops);

    expect(await service.isManuallyCleared(key), isTrue);
    final rec = await service.find(key);
    expect(rec, isNotNull);
    expect(rec!.seed, 24680);
    expect(BattleReplayOp.decodeList(rec.opsJson), equals(ops));
  });

  test('同 battleKey 重复 record → 单行,覆盖为最新 seed+ops', () async {
    final key = BattleReplayRecordService.stageBattleKey('stage_01_01');
    await service.record(battleKey: key, seed: 111, ops: ops);
    const ops2 = [BattleReplayOp(anchor: 2, charId: 3, skillId: 'sk_c')];
    await service.record(battleKey: key, seed: 222, ops: ops2);

    final all = await IsarSetup.instance.battleReplayRecords.where().findAll();
    expect(all.where((r) => r.battleKey == key), hasLength(1),
        reason: '每 battleKey 单行');
    final rec = await service.find(key);
    expect(rec!.seed, 222, reason: '覆盖为最新 seed');
    expect(BattleReplayOp.decodeList(rec.opsJson), equals(ops2));
  });

  test('不同 battleKey 各自独立(stage vs tower / 不同 cycle)', () async {
    final k1 = BattleReplayRecordService.stageBattleKey('stage_01_01');
    final k2 = BattleReplayRecordService.towerBattleKey(10);
    final k3 = BattleReplayRecordService.stageBattleKey('stage_01_01', cycle: 2);
    await service.record(battleKey: k1, seed: 1, ops: const []);

    expect(await service.isManuallyCleared(k1), isTrue);
    expect(await service.isManuallyCleared(k2), isFalse);
    expect(await service.isManuallyCleared(k3), isFalse,
        reason: '同关不同周目独立解锁');
  });

  test('落盘 close → reopen 持久化读出', () async {
    final key = BattleReplayRecordService.stageBattleKey('stage_02_03');
    await service.record(battleKey: key, seed: 999, ops: ops, clearedAt: DateTime(2026, 6, 13));
    await IsarSetup.close();

    await IsarSetup.init(directory: tempDir, inspector: false);
    final svc2 = BattleReplayRecordService(isar: IsarSetup.instance);
    final rec = await svc2.find(key);
    expect(rec, isNotNull);
    expect(rec!.seed, 999);
    expect(rec.clearedAt, DateTime(2026, 6, 13));
    expect(BattleReplayOp.decodeList(rec.opsJson), equals(ops));
  });
}
