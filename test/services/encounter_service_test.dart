import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/defs/encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/encounter_progress.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/services/encounter_service.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// Phase 4 W14-1 · EncounterService 真 Isar 落地测试。
///
/// 体例对齐 tower_progress_service_test:setUp 用临时目录 + IsarSetup.init。
/// 不依赖 GameRepository fixture(encounters.yaml 单独 yaml parse test 走)。
class _FixedRng implements Rng {
  _FixedRng(this._value);
  final double _value;
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => _value;
  @override
  T pick<T>(List<T> list) => list.first;
}

EncounterDef _mkInsight({
  String id = 'enc_insight',
  Map<TechniqueSchool, int> threshold = const {TechniqueSchool.lingQiao: 5},
  int? fortuneRequired = 3,
  double baseProbability = 1.0,
  String skillId = 'skill_encounter_ting_yu_jian',
}) {
  return EncounterDef(
    id: id,
    type: EncounterType.techniqueInsight,
    trigger: EncounterTrigger(
      schoolKillThreshold: threshold,
      fortuneRequired: fortuneRequired,
    ),
    baseProbability: baseProbability,
    outcomeMapping: {
      'insight_success': OutcomeDef(
        type: OutcomeType.unlockSkill,
        skillId: skillId,
      ),
      'practice_partial': const OutcomeDef(
        type: OutcomeType.attributeBonus,
        attributeKey: AttributeKey.agility,
      ),
    },
  );
}

EncounterDef _mkFortune({
  String id = 'enc_fortune',
  AttributeKey key = AttributeKey.fortune,
  int? fortuneRequired = 1,
  double baseProbability = 1.0,
}) {
  return EncounterDef(
    id: id,
    type: EncounterType.fortuneEvent,
    trigger: EncounterTrigger(
      schoolKillThreshold: const {},
      fortuneRequired: fortuneRequired,
    ),
    baseProbability: baseProbability,
    outcomeMapping: {
      'gain_wisdom': OutcomeDef(
        type: OutcomeType.attributeBonus,
        attributeKey: key,
      ),
    },
  );
}

Attributes _mkAttrs({int fortune = 5}) {
  return Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = fortune;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      // 不依赖 encounters fixture,但 GameRepository 需 numbers/equipment 等
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_encounter_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('getOrCreate + recordKill', () {
    test('首次 getOrCreate → 默认空进度 + recordKill 累加 lingQiao=3', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.saveDataId, 1);
      expect(p.triggeredEncounterIds, isEmpty);
      expect(p.schoolKillCounts, isEmpty);
      expect(p.attributeGainsTotal, 0);
      expect(p.unlockedSkillIds, isEmpty);

      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: const [
          TechniqueSchool.lingQiao,
          TechniqueSchool.lingQiao,
          TechniqueSchool.lingQiao,
        ],
      );
      final after = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(after, isNotNull);
      expect(after!.schoolKillCounts.countOf(TechniqueSchool.lingQiao), 3);
      expect(after.schoolKillCounts.countOf(TechniqueSchool.gangMeng), 0);
    });

    test('recordKill 多次反序列化 fixed-length list 后仍可累加(W13 教训回归)',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 第一波:gangMeng
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: const [TechniqueSchool.gangMeng],
      );
      // 第二波:同 saveDataId,触发 findFirst 反序列化(fixed-length)+ 加新 school
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: const [
          TechniqueSchool.yinRou,
          TechniqueSchool.yinRou,
        ],
      );
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.schoolKillCounts.countOf(TechniqueSchool.gangMeng), 1);
      expect(p.schoolKillCounts.countOf(TechniqueSchool.yinRou), 2);
    });
  });

  group('evaluateTriggers', () {
    test('school threshold 未达 → 返回 null', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: List.filled(4, TechniqueSchool.lingQiao),
      );
      final def = _mkInsight();
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 9),
        encounters: [def],
        rng: _FixedRng(0.0), // rng.nextDouble = 0 → 永远过
      );
      expect(result, isNull,
          reason: 'lingQiao=4 < threshold 5,trigger 不满足');
    });

    test('fortune < required → 返回 null', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: List.filled(10, TechniqueSchool.lingQiao),
      );
      final def = _mkInsight(fortuneRequired: 8);
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 5),
        encounters: [def],
        rng: _FixedRng(0.0),
      );
      expect(result, isNull, reason: 'fortune=5 < required 8');
    });

    test(
        'trigger 满足 + rng < p → 返回 def(fortune 软概率公式 base * (1+f/20))',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: List.filled(5, TechniqueSchool.lingQiao),
      );
      // fortune=10, base=0.5 → p = 0.5 * (1 + 10/20) = 0.75
      final def = _mkInsight(baseProbability: 0.5);
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 10),
        encounters: [def],
        rng: _FixedRng(0.7), // 0.7 < 0.75 → 触发
      );
      expect(result?.id, def.id);
    });

    test('trigger 满足但 rng >= p → 返回 null', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: List.filled(5, TechniqueSchool.lingQiao),
      );
      // fortune=5, base=0.3 → p = 0.3 * 1.25 = 0.375
      final def = _mkInsight(baseProbability: 0.3);
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 5),
        encounters: [def],
        rng: _FixedRng(0.4), // 0.4 > 0.375 → 不触发
      );
      expect(result, isNull);
    });

    test('已 markTriggered 的 encounter 不再候选', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkFortune();
      await svc.markTriggered(saveDataId: 1, encounterId: def.id);

      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 9),
        encounters: [def],
        rng: _FixedRng(0.0),
      );
      expect(result, isNull, reason: '已在 triggeredEncounterIds 中应被跳过');
    });
  });

  group('applyOutcome', () {
    test('unlockSkill → 写 unlockedSkillIds 去重', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkInsight();
      final result = await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'insight_success',
      );
      expect(result, isA<UnlockSkillApplied>());
      expect((result as UnlockSkillApplied).skillId,
          'skill_encounter_ting_yu_jian');

      // 重复 apply 不再增列表
      await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'insight_success',
      );
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.unlockedSkillIds, ['skill_encounter_ting_yu_jian']);
    });

    test('attributeBonus → 写对应字段 + lifetime cap enforce', () async {
      final svc =
          EncounterService(isar: IsarSetup.instance, attributeGainCap: 3);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkFortune();
      // 第 1 次:fortune+1 → total=1
      var r = await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'gain_wisdom',
      );
      expect(r, isA<AttributeBonusApplied>());
      expect((r as AttributeBonusApplied).delta, 1);
      // 第 2 次:total=2
      await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'gain_wisdom',
      );
      // 第 3 次:total=3 达 cap
      await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'gain_wisdom',
      );
      // 第 4 次:已达 cap,返回 AttributeCapReached
      r = await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'gain_wisdom',
      );
      expect(r, isA<AttributeCapReached>());
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.attributeGainsFortune, 3);
      expect(p.attributeGainsTotal, 3);
    });

    test('skip(未配 outcomeMapping)→ NoneOutcome,不写 Isar', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkInsight();
      final result = await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'skip',
      );
      expect(result, isA<NoneOutcome>());
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.attributeGainsTotal, 0);
      expect(p.unlockedSkillIds, isEmpty);
    });
  });
}
