import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/jianghu/application/reputation_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

/// T24 · P1.2 §3 EncounterIntegration 真 wire 闭环测族。
///
/// 验证三件事:
/// 1. caller 传 [ReputationDeltaApplier] → service 端 resolve outcome 后
///    真触发 applier(args = encounter.affectsReputation 拆出来的 playerId
///    / factionId / deltaMin / deltaMax)
/// 2. caller 不传 applier(老路径)→ service 端 null guard,不 throw
/// 3. [ReputationService.deltaApplierFromRng] 闭包 5 次抽样,delta ∈
///    `[deltaMin, deltaMax]` 闭区间(防 Random / Rng 出界)
///
/// 设计纪律:
/// - 用真 [ReputationService]:Isar 落地 + clamp [-100, +100] 也一起验
/// - applier collector 用 record list 收 call 参数,断言 args 透传
/// - encounter fixture 用 [AffectsReputation] 段(deltaMin/deltaMax 不等
///   验抽样;相等单点验 fast-path)

EncounterDef _mkEnc({
  String id = 'enc_reputation_wire',
  AffectsReputation? affects,
}) {
  return EncounterDef(
    id: id,
    type: EncounterType.fortuneEvent,
    trigger: const EncounterTrigger(),
    baseProbability: 1.0,
    outcomeMapping: const {
      'help': OutcomeDef(type: OutcomeType.none),
    },
    affectsReputation: affects,
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('wuxia_t24_encounter_rep_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('T24 · EncounterIntegration applier wire', () {
    test('caller 传 applier + affectsReputation → 真触发 applyDelta 且 args 透传',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);

      final calls = <
          ({
            int playerId,
            String factionId,
            int deltaMin,
            int deltaMax,
          })>[];
      Future<void> collector({
        required int playerId,
        required String factionId,
        required int deltaMin,
        required int deltaMax,
      }) async {
        calls.add((
          playerId: playerId,
          factionId: factionId,
          deltaMin: deltaMin,
          deltaMax: deltaMax,
        ));
      }

      final enc = _mkEnc(
        affects: const AffectsReputation(
          factionId: 'shaolin',
          deltaMin: 3,
          deltaMax: 8,
        ),
      );
      await svc.applyOutcome(
        saveDataId: 1,
        encounter: enc,
        outcomeId: 'help',
        reputationApplier: collector,
        reputationPlayerId: 1,
      );

      expect(calls, hasLength(1), reason: 'applier 必触发一次');
      expect(calls.single.playerId, 1);
      expect(calls.single.factionId, 'shaolin');
      expect(calls.single.deltaMin, 3);
      expect(calls.single.deltaMax, 8);
    });

    test('caller 不传 applier → service null guard,不 throw 且 reputation 不动',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final repSvc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);

      final enc = _mkEnc(
        affects: const AffectsReputation(
          factionId: 'wudang',
          deltaMin: 5,
          deltaMax: 5,
        ),
      );
      // 关键:reputationApplier / reputationPlayerId 都不传 → 老路径
      await svc.applyOutcome(
        saveDataId: 1,
        encounter: enc,
        outcomeId: 'help',
      );

      expect(await repSvc.valueFor(1, 'wudang'), 0,
          reason: '无 applier → 不写 reputation,sane fallback 0');
    });

    test('affectsReputation == null → 即使传 applier 也不触发(向后兼容)',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);

      var called = false;
      Future<void> applier({
        required int playerId,
        required String factionId,
        required int deltaMin,
        required int deltaMax,
      }) async {
        called = true;
      }

      final enc = _mkEnc(); // affectsReputation == null
      await svc.applyOutcome(
        saveDataId: 1,
        encounter: enc,
        outcomeId: 'help',
        reputationApplier: applier,
        reputationPlayerId: 1,
      );

      expect(called, isFalse,
          reason: 'encounter 不影响声望时,即使 applier 在场也不调');
    });

    test('deltaApplierFromRng 闭包真落 Isar + delta ∈ [min, max]',
        () async {
      final repSvc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      // seed 42 取一致 Rng 序列,验抽样到 reputations 表
      final applier = repSvc.deltaApplierFromRng(DefaultRng(seed: 42));

      // 5 次抽样,delta ∈ [4, 7] inclusive(span=3 → nextInt(4))
      for (var i = 0; i < 5; i++) {
        await applier(
          playerId: 1,
          factionId: 'rep_range_test',
          deltaMin: 4,
          deltaMax: 7,
        );
      }

      // 累积 5 次,每次 ∈ [4,7] → 总和 ∈ [20, 35]
      final total = await repSvc.valueFor(1, 'rep_range_test');
      expect(total, inInclusiveRange(20, 35),
          reason: '5 次抽样累积 ∈ [5*4=20, 5*7=35]');
    });

    test('deltaApplierFromRng · deltaMin == deltaMax 走 fast-path 不抛错',
        () async {
      final repSvc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      // span=0 时不能 nextInt(0)(会抛 RangeError);helper 应跳分支
      final applier = repSvc.deltaApplierFromRng(DefaultRng(seed: 1));

      await applier(
        playerId: 1,
        factionId: 'fast_path',
        deltaMin: 5,
        deltaMax: 5,
      );
      expect(await repSvc.valueFor(1, 'fast_path'), 5,
          reason: 'span=0 → delta=deltaMin,无随机分支');
    });

    test('deltaApplierFromRng 写穿 ReputationService.applyDelta clamp [-100,+100]',
        () async {
      final repSvc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      final applier = repSvc.deltaApplierFromRng(DefaultRng(seed: 7));

      // 单次 +50,连 3 次 → 150 但 clamp 到 100
      for (var i = 0; i < 3; i++) {
        await applier(
          playerId: 1,
          factionId: 'clamp_test',
          deltaMin: 50,
          deltaMax: 50,
        );
      }
      expect(await repSvc.valueFor(1, 'clamp_test'), 100,
          reason: '§5.4 红线防越,clamp 由 applyDelta 端落');
    });
  });
}
