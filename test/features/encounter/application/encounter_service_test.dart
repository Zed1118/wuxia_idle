import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

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

    // ── W16 GDD §12.4 节日活动 · festival 维度 ─────────────────────

    test('festivalRequired=chunJie + festivalToday=null → 不触发', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = const EncounterDef(
        id: 'enc_festival_chun_jie',
        type: EncounterType.fortuneEvent,
        trigger: EncounterTrigger(festivalRequired: Festival.chunJie),
        baseProbability: 1.0,
        outcomeMapping: {
          'gain': OutcomeDef(
            type: OutcomeType.attributeBonus,
            attributeKey: AttributeKey.fortune,
          ),
        },
      );
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 9),
        encounters: [def],
        rng: _FixedRng(0.0),
        // festivalToday 不传 → null,非节日
      );
      expect(result, isNull, reason: 'festivalRequired 非 null 但今日非节日');
    });

    test('festivalRequired=chunJie + festivalToday=yuanXiao → 不触发(不同节日)',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = const EncounterDef(
        id: 'enc_festival_chun_jie_2',
        type: EncounterType.fortuneEvent,
        trigger: EncounterTrigger(festivalRequired: Festival.chunJie),
        baseProbability: 1.0,
        outcomeMapping: {
          'gain': OutcomeDef(
            type: OutcomeType.attributeBonus,
            attributeKey: AttributeKey.fortune,
          ),
        },
      );
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 9),
        encounters: [def],
        rng: _FixedRng(0.0),
        festivalToday: Festival.yuanXiao,
      );
      expect(result, isNull, reason: 'festivalRequired=chunJie 但今日是元宵');
    });

    test('festivalRequired=chunJie + festivalToday=chunJie + rng < p → 触发',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = const EncounterDef(
        id: 'enc_festival_chun_jie_3',
        type: EncounterType.fortuneEvent,
        trigger: EncounterTrigger(festivalRequired: Festival.chunJie),
        baseProbability: 1.0,
        outcomeMapping: {
          'gain': OutcomeDef(
            type: OutcomeType.attributeBonus,
            attributeKey: AttributeKey.fortune,
          ),
        },
      );
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 5),
        encounters: [def],
        rng: _FixedRng(0.5), // p = 1.0 * 1.25 = 1.25,0.5 < 1.25 → 触发
        festivalToday: Festival.chunJie,
      );
      expect(result?.id, def.id);
    });

    test('festivalRequired=null + festivalToday=chunJie → 触发(节日维度免审)',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkFortune();
      final result = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(fortune: 9),
        encounters: [def],
        rng: _FixedRng(0.0),
        festivalToday: Festival.chunJie,
      );
      expect(result?.id, def.id,
          reason: 'festivalRequired=null → 任何节日/非节日都通过该维度');
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
      // 波A A4 来源统一:解锁写 SaveData.skillUnlockProgress(单一真相源),
      // 旧池 EncounterProgress.unlockedSkillIds 退役只读不再写。
      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.skillUnlockProgress.isUnlocked('skill_encounter_ting_yu_jian'),
          isTrue);
      expect(
          save.skillUnlockProgress
              .where((e) => e.skillId == 'skill_encounter_ting_yu_jian')
              .length,
          1,
          reason: '重复 apply 去重,不增条目');
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.unlockedSkillIds, isEmpty, reason: '旧池退役,不再写入');
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

    test('attributeBonus + founderCharacterId → 真正加到角色属性（审计②修复）',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 建 fortune=5 的主角存 Isar，取 autoIncrement id。
      final ch = Character.create(
        name: '主角',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: _mkAttrs(fortune: 5),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
      );
      late int charId;
      await IsarSetup.instance.writeTxn(() async {
        charId = await IsarSetup.instance.characters.put(ch);
      });

      final r = await svc.applyOutcome(
        saveDataId: 1,
        encounter: _mkFortune(),
        outcomeId: 'gain_wisdom',
        founderCharacterId: charId,
      );
      expect(r, isA<AttributeBonusApplied>());

      final updated = await IsarSetup.instance.characters.get(charId);
      expect(updated!.attributes.fortune, 6,
          reason:
              '奇遇属性奖励应真正写到角色 attributes（旧 bug:只记 EncounterProgress 不改角色）');
      expect(updated.attributeBonusFromAdventure, 1,
          reason: '生涯累计计数写活（此前 never-written 死字段）');
      // EncounterProgress 仍同步记录（cap 追踪不变）。
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.attributeGainsFortune, 1);
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

    test('P1.y · founderCharacterId 传入 → tutorialStep 推到 7', () async {
      // seed SaveData tutorialStep=6(已达收徒)
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.saveDatas.put(SaveData()
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.12.0'
          ..createdAt = DateTime.now()
          ..lastSavedAt = DateTime.now()
          ..lastOnlineAt = DateTime.now()
          ..tutorialStep = 6);
      });
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkInsight();

      await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'insight_success',
        founderCharacterId: 42, // 非 null → 走 tutorialSvc.advanceForFirstAdventure
        encounterTitle: 'test',
      );

      final tutorialSvc = TutorialService(IsarSetup.instance);
      expect(await tutorialSvc.getCurrentStep(), 7,
          reason: '首次奇遇触发 founderCharacterId != null → 推 step 7');
    });

    test('P1.y · founderCharacterId=null → tutorialStep 不推进', () async {
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.saveDatas.put(SaveData()
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.12.0'
          ..createdAt = DateTime.now()
          ..lastSavedAt = DateTime.now()
          ..lastOnlineAt = DateTime.now()
          ..tutorialStep = 6);
      });
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final def = _mkInsight();

      await svc.applyOutcome(
        saveDataId: 1,
        encounter: def,
        outcomeId: 'insight_success',
        // founderCharacterId: null(test fixture 路径)
      );

      final tutorialSvc = TutorialService(IsarSetup.instance);
      expect(await tutorialSvc.getCurrentStep(), 6,
          reason: 'founderCharacterId=null 不入 GameEvent / tutorial 路径');
    });
  });

  // ========================================================================
  // C-W14-2:biome / weather 维度
  // ========================================================================

  group('recordIdleMinutes + biome/weather 累加', () {
    test('biome+weather 同 call → 两个 list 各 +N',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);

      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.swordTomb,
        weather: EncounterWeather.mist,
        minutes: 60,
      );
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.swordTomb,
        weather: EncounterWeather.mist,
        minutes: 30,
      );

      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.biomeMinutes.minutesOf(EncounterBiome.swordTomb), 90);
      expect(p.weatherMinutes.minutesOf(EncounterWeather.mist), 90);
    });

    test('仅 biome / 仅 weather / 都 null 行为',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);

      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.temple,
        weather: null,
        minutes: 45,
      );
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: null,
        weather: EncounterWeather.rain,
        minutes: 30,
      );
      // 都 null 应 noop
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: null,
        weather: null,
        minutes: 999,
      );
      // minutes 0 应 noop
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.temple,
        weather: EncounterWeather.rain,
        minutes: 0,
      );

      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.biomeMinutes.minutesOf(EncounterBiome.temple), 45);
      expect(p.weatherMinutes.minutesOf(EncounterWeather.rain), 30);
      // 未喂的维度仍 0
      expect(p.biomeMinutes.minutesOf(EncounterBiome.swordTomb), 0);
    });

    test(
        'recordIdleMinutes 多次累加 fixed-length list 不抛(W13 教训回归)',
        () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 第一次 record 后,findFirst 重新拉的 list 是 fixed-length;
      // 第二次 record 进 `addMinutes`(新 enum 走 add 分支)若不 List.of 会抛。
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.mountainForest,
        weather: null,
        minutes: 30,
      );
      // 新 biome 走 add 分支
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.bambooForest,
        weather: EncounterWeather.snow,
        minutes: 60,
      );
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(1)
          .findFirst();
      expect(p!.biomeMinutes.minutesOf(EncounterBiome.mountainForest), 30);
      expect(p.biomeMinutes.minutesOf(EncounterBiome.bambooForest), 60);
      expect(p.weatherMinutes.minutesOf(EncounterWeather.snow), 60);
    });
  });

  group('evaluateTriggers 多维度 AND 语义', () {
    EncounterDef mkMultiDim({
      Map<TechniqueSchool, int> school = const {},
      Map<EncounterBiome, int> biome = const {},
      Map<EncounterWeather, int> weather = const {},
      int? fortune,
    }) {
      return EncounterDef(
        id: 'enc_multi',
        type: EncounterType.techniqueInsight,
        trigger: EncounterTrigger(
          schoolKillThreshold: school,
          biomeMinutes: biome,
          weatherMinutes: weather,
          fortuneRequired: fortune,
        ),
        baseProbability: 1.0,
        outcomeMapping: const {
          'ok': OutcomeDef(type: OutcomeType.none),
        },
      );
    }

    test('biomeMinutes 未达 → 不触发', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.swordTomb,
        weather: null,
        minutes: 30,
      );
      final def = mkMultiDim(biome: {EncounterBiome.swordTomb: 60});
      final hit = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(),
        encounters: [def],
        rng: _FixedRng(0.0),
      );
      expect(hit, isNull);
    });

    test('weatherMinutes 未达 → 不触发', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: null,
        weather: EncounterWeather.rain,
        minutes: 30,
      );
      final def = mkMultiDim(weather: {EncounterWeather.rain: 60});
      final hit = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(),
        encounters: [def],
        rng: _FixedRng(0.0),
      );
      expect(hit, isNull);
    });

    test('biome + weather 全达 → 触发', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.cliffWaterfall,
        weather: EncounterWeather.rain,
        minutes: 60,
      );
      final def = mkMultiDim(
        biome: {EncounterBiome.cliffWaterfall: 60},
        weather: {EncounterWeather.rain: 60},
      );
      final hit = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(),
        encounters: [def],
        rng: _FixedRng(0.0),
      );
      expect(hit, isNotNull);
      expect(hit!.id, 'enc_multi');
    });

    test('school + biome + weather 三维度都满足才触发', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 喂全套
      await svc.recordKill(
        saveDataId: 1,
        defeatedSchools: const [
          TechniqueSchool.gangMeng,
          TechniqueSchool.gangMeng,
          TechniqueSchool.gangMeng,
          TechniqueSchool.gangMeng,
          TechniqueSchool.gangMeng,
        ],
      );
      await svc.recordIdleMinutes(
        saveDataId: 1,
        biome: EncounterBiome.drillGround,
        weather: null,
        minutes: 30,
      );
      final def = mkMultiDim(
        school: {TechniqueSchool.gangMeng: 5},
        biome: {EncounterBiome.drillGround: 30},
        fortune: 3,
      );
      final hit = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(),
        encounters: [def],
        rng: _FixedRng(0.0),
      );
      expect(hit, isNotNull);

      // 缺一维:school 不够,应失败
      final defStricter = mkMultiDim(
        school: {TechniqueSchool.gangMeng: 99},
        biome: {EncounterBiome.drillGround: 30},
        fortune: 3,
      );
      final missHit = await svc.evaluateTriggers(
        saveDataId: 1,
        attributes: _mkAttrs(),
        encounters: [defStricter],
        rng: _FixedRng(0.0),
      );
      expect(missHit, isNull);
    });
  });

  group('equipEncounterSkill / unequipEncounterSkill (C-W14-3-A)', () {
    // 测试用 character 在 Isar 内的最小构造,境界可注入。realm 7 值
    // index 0-6,tier 1-7 等于 index+1。
    Future<int> seedCharacter({
      required RealmTier tier,
      String? equippedEncounterSkillId,
    }) async {
      final isar = IsarSetup.instance;
      final c = Character.create(
        name: '测试侠',
        realmTier: tier,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime.now(),
        equippedEncounterSkillId: equippedEncounterSkillId,
      );
      return isar.writeTxn(() => isar.characters.put(c));
    }

    // 真实 yaml 加载后,encounter_skills.yaml 应在场。从中拿
    // skill_encounter_ting_yu_jian(tier 3,W14-1 ★)做测试目标。
    SkillDef tier3Skill() =>
        GameRepository.instance.skillDefs['skill_encounter_ting_yu_jian']!;

    test('成功路径:境界达标 + 已 unlock → EquipSucceeded', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      // erLiu (index 2) >= tier 3 - 1 = 2 ✅
      final cid = await seedCharacter(tier: RealmTier.erLiu);
      // 波A A4:解锁态 seed 写新池 SaveData.skillUnlockProgress。
      await IsarSetup.instance.writeTxn(() async {
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.skillUnlockProgress = List.of(save.skillUnlockProgress)
          ..markUnlocked('skill_encounter_ting_yu_jian');
        await IsarSetup.instance.saveDatas.put(save);
      });

      final skill = tier3Skill();
      final r = await svc.equipEncounterSkill(
        characterId: cid,
        skillDef: skill,
        saveDataId: 1,
      );
      expect(r, isA<EquipSucceeded>());
      final after = await IsarSetup.instance.characters.get(cid);
      expect(after!.equippedEncounterSkillId, skill.id);
    });

    test('未 unlock → EquipNotUnlocked,不写 character', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      final cid = await seedCharacter(tier: RealmTier.zongShi); // 高境界
      await svc.getOrCreate(saveDataId: 1);
      // unlockedSkillIds 留空

      final skill = tier3Skill();
      final r = await svc.equipEncounterSkill(
        characterId: cid,
        skillDef: skill,
        saveDataId: 1,
      );
      expect(r, isA<EquipNotUnlocked>());
      expect((r as EquipNotUnlocked).skillId, skill.id);
      final after = await IsarSetup.instance.characters.get(cid);
      expect(after!.equippedEncounterSkillId, isNull);
    });

    test('境界不足 → EquipTierLocked,不写 character', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      // xueTu (index 0) < tier 3 - 1 = 2 ❌
      final cid = await seedCharacter(tier: RealmTier.xueTu);
      // 波A A4:解锁态 seed 写新池 SaveData.skillUnlockProgress。
      await IsarSetup.instance.writeTxn(() async {
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.skillUnlockProgress = List.of(save.skillUnlockProgress)
          ..markUnlocked('skill_encounter_ting_yu_jian');
        await IsarSetup.instance.saveDatas.put(save);
      });

      final skill = tier3Skill();
      final r = await svc.equipEncounterSkill(
        characterId: cid,
        skillDef: skill,
        saveDataId: 1,
      );
      expect(r, isA<EquipTierLocked>());
      final tl = r as EquipTierLocked;
      expect(tl.requiredTier, 3);
      expect(tl.currentTier, RealmTier.xueTu);
      final after = await IsarSetup.instance.characters.get(cid);
      expect(after!.equippedEncounterSkillId, isNull);
    });

    test('character 不存在 → EquipNotFound', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final r = await svc.equipEncounterSkill(
        characterId: 9999,
        skillDef: tier3Skill(),
        saveDataId: 1,
      );
      expect(r, isA<EquipNotFound>());
    });

    test('非奇遇 skill 注入 → EquipNotFound(防误调)', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      // 普通心法招式,parentTechniqueDefId 非空 → isEncounterSkill=false
      final fake = const SkillDef(
        id: 'skill_gangmeng_jichu_basic',
        name: 'fake',
        description: '',
        type: SkillType.normalAttack,
        powerMultiplier: 500,
        internalForceCost: 0,
        cooldownTurns: 0,
        requiresManualTrigger: false,
        parentTechniqueDefId: 'tech_gangmeng_jichu',
        visualEffect: 'punch',
      );
      final r = await svc.equipEncounterSkill(
        characterId: 1,
        skillDef: fake,
        saveDataId: 1,
      );
      expect(r, isA<EquipNotFound>());
    });

    test('canEquipEncounterSkillByTier 静态函数', () {
      // 三流 (index 1) tier 2 ✅
      expect(
        EncounterService.canEquipEncounterSkillByTier(
          realmTier: RealmTier.sanLiu,
          skillTier: 2,
        ),
        isTrue,
      );
      // 三流 (index 1) tier 3 ❌(需 index >= 2)
      expect(
        EncounterService.canEquipEncounterSkillByTier(
          realmTier: RealmTier.sanLiu,
          skillTier: 3,
        ),
        isFalse,
      );
      // 武圣 (index 6) tier 7 ✅
      expect(
        EncounterService.canEquipEncounterSkillByTier(
          realmTier: RealmTier.wuSheng,
          skillTier: 7,
        ),
        isTrue,
      );
    });

    test('unequipEncounterSkill 返回 hadEquipped,清字段', () async {
      final svc = EncounterService(isar: IsarSetup.instance);
      final cid = await seedCharacter(
        tier: RealmTier.erLiu,
        equippedEncounterSkillId: 'skill_encounter_ting_yu_jian',
      );

      final had = await svc.unequipEncounterSkill(characterId: cid);
      expect(had, isTrue);
      final after = await IsarSetup.instance.characters.get(cid);
      expect(after!.equippedEncounterSkillId, isNull);

      // 再次卸下 → hadEquipped=false
      final hadAgain = await svc.unequipEncounterSkill(characterId: cid);
      expect(hadAgain, isFalse);
    });
  });
}
