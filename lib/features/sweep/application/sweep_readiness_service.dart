import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../domain/sweep_readiness.dart';

class SweepReadinessService {
  const SweepReadinessService({required this.isar, required this.config});

  final Isar isar;
  final SweepReadinessConfig config;

  Future<SweepReadinessState> getStatus({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final save = await _requireSaveData();
    final state = _normalize(save, at);
    if (_needsPersist(save, state)) {
      await isar.writeTxn(() async {
        save.sweepReadinessPoints = state.points;
        save.sweepReadinessLastRecoveredAt = state.lastRecoveredAt;
        await isar.saveDatas.put(save);
      });
    }
    return state;
  }

  Future<bool> trySpendMainlineStages(int stageCount, {DateTime? now}) async {
    final cost = config.mainlineSweepCostFor(stageCount);
    if (cost <= 0) return true;
    final at = now ?? DateTime.now();
    return isar.writeTxn(() async {
      final save = await _requireSaveData();
      final state = _normalize(save, at);
      if (!state.canSweepMainlineStages(stageCount)) {
        save.sweepReadinessPoints = state.points;
        save.sweepReadinessLastRecoveredAt = state.lastRecoveredAt;
        await isar.saveDatas.put(save);
        return false;
      }
      final next = state.spendMainlineStages(stageCount);
      save.sweepReadinessPoints = next.points;
      save.sweepReadinessLastRecoveredAt = next.lastRecoveredAt;
      await isar.saveDatas.put(save);
      return true;
    });
  }

  Future<SaveData> _requireSaveData() async {
    final save = await isar.saveDatas.get(0);
    if (save == null) {
      throw StateError('SaveData not initialized');
    }
    return save;
  }

  SweepReadinessState _normalize(SaveData save, DateTime now) {
    return SweepReadinessState.normalize(
      points: save.sweepReadinessPoints,
      lastRecoveredAt: save.sweepReadinessLastRecoveredAt,
      now: now,
      config: config,
    );
  }

  bool _needsPersist(SaveData save, SweepReadinessState state) {
    return save.sweepReadinessPoints != state.points ||
        save.sweepReadinessLastRecoveredAt != state.lastRecoveredAt;
  }
}
