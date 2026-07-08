import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_readiness_service.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_readiness.dart';

void main() {
  late Directory tempDir;

  const config = SweepReadinessConfig(
    enabled: true,
    maxPoints: 60,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 1,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_sweep_ready_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  SweepReadinessService service() =>
      SweepReadinessService(isar: IsarSetup.instance, config: config);

  test('旧档 null 字段首读补满并持久化', () async {
    final now = DateTime(2026, 7, 8, 12);

    final state = await service().getStatus(now: now);
    final save = await IsarSetup.currentSaveData();

    expect(state.points, 60);
    expect(save!.sweepReadinessPoints, 60);
    expect(save.sweepReadinessLastRecoveredAt, now);
  });

  test('spend 成功扣除并持久化', () async {
    final now = DateTime(2026, 7, 8, 12);
    await service().getStatus(now: now);

    final spent = await service().trySpendMainlineStages(5, now: now);
    final save = await IsarSetup.currentSaveData();

    expect(spent, isTrue);
    expect(save!.sweepReadinessPoints, 55);
  });

  test('spend 不足时返回 false 且不为负', () async {
    final now = DateTime(2026, 7, 8, 12);
    final save = await IsarSetup.currentSaveData();
    await IsarSetup.instance.writeTxn(() async {
      save!
        ..sweepReadinessPoints = 2
        ..sweepReadinessLastRecoveredAt = now;
      await IsarSetup.instance.saveDatas.put(save);
    });

    final spent = await service().trySpendMainlineStages(3, now: now);
    final after = await IsarSetup.currentSaveData();

    expect(spent, isFalse);
    expect(after!.sweepReadinessPoints, 2);
  });

  test('真实时间恢复后再扣除', () async {
    final save = await IsarSetup.currentSaveData();
    await IsarSetup.instance.writeTxn(() async {
      save!
        ..sweepReadinessPoints = 10
        ..sweepReadinessLastRecoveredAt = DateTime(2026, 7, 8, 10, 15);
      await IsarSetup.instance.saveDatas.put(save);
    });

    final spent = await service().trySpendMainlineStages(
      2,
      now: DateTime(2026, 7, 8, 12, 45),
    );
    final after = await IsarSetup.currentSaveData();

    expect(spent, isTrue);
    expect(after!.sweepReadinessPoints, 10);
    expect(after.sweepReadinessLastRecoveredAt, DateTime(2026, 7, 8, 12, 15));
  });
}
