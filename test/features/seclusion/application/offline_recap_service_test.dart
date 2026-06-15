import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_recap_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

/// M2 离线收益汇总「欢迎回来」卡 · 纯函数计算层测试。
///
/// [OfflineRecapService.buildRecap] 复用 [SeclusionService.computeOutputs]
/// 的产出口径,只负责「是否该弹卡 + 展示数据」。不碰 Isar(session 手动构造)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  RetreatSession mkSession({
    RetreatMapType mapType = RetreatMapType.shanLin,
    int durationHours = 4,
    required DateTime startedAt,
    RetreatStatus status = RetreatStatus.active,
  }) {
    return RetreatSession()
      ..saveDataId = 1
      ..mapType = mapType
      ..durationHours = durationHours
      ..startedAt = startedAt
      ..status = status;
  }

  group('OfflineRecapService.buildRecap', () {
    test('无 active session 返回 null（不弹卡）', () {
      final recap = OfflineRecapService.buildRecap(
        session: null,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime(2026, 5, 11, 12),
      );
      expect(recap, isNull);
    });

    test('离开不足阈值（0.5h < 1h）不弹卡', () {
      final started = DateTime(2026, 5, 11, 10);
      final recap = OfflineRecapService.buildRecap(
        session: mkSession(startedAt: started),
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: started.add(const Duration(minutes: 30)),
      );
      expect(recap, isNull);
    });

    test('闭关已满（挂 5h ≥ 计划 4h）→ isComplete + progress 1.0 + 预估 > 0', () {
      final started = DateTime(2026, 5, 11, 10);
      final recap = OfflineRecapService.buildRecap(
        session: mkSession(durationHours: 4, startedAt: started),
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: started.add(const Duration(hours: 5)),
      );
      expect(recap, isNotNull);
      expect(recap!.isComplete, isTrue);
      expect(recap.progressPct, 1.0);
      expect(recap.estimatedMojianshi, greaterThan(0));
      expect(recap.estimatedExperience, greaterThan(0));
    });

    test('进行中（挂 2h < 计划 4h）→ 未满 + progress ≈ 0.5', () {
      final started = DateTime(2026, 5, 11, 10);
      final recap = OfflineRecapService.buildRecap(
        session: mkSession(durationHours: 4, startedAt: started),
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: started.add(const Duration(hours: 2)),
      );
      expect(recap, isNotNull);
      expect(recap!.isComplete, isFalse);
      expect(recap.progressPct, closeTo(0.5, 0.01));
    });

    test('地图名正确映射（shanLin → 山林）', () {
      final started = DateTime(2026, 5, 11, 10);
      final recap = OfflineRecapService.buildRecap(
        session: mkSession(mapType: RetreatMapType.shanLin, startedAt: started),
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: started.add(const Duration(hours: 5)),
      );
      expect(recap!.mapName, '山林');
    });

    test('预估产出（磨剑石/经验）与 computeOutputs 直接调用一致', () {
      final started = DateTime(2026, 5, 11, 10);
      final now = started.add(const Duration(hours: 5));
      final session = mkSession(durationHours: 4, startedAt: started);
      final direct = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      final recap = OfflineRecapService.buildRecap(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(recap!.estimatedMojianshi, direct.mojianshi);
      expect(recap.estimatedExperience, direct.experiencePoints);
    });
  });
}
