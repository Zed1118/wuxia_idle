import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_resolver.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/stage_skill_drop_hook.dart';

/// 波B drop 招(真解/残页)装配 wiring 测族。
///
/// 覆盖(spec 2026-06-11-wave-b-24-skills-content-design §2):
/// 1. resolver.resolveUnlockedDropSkills:isUnlocked + style==school 过滤;
/// 2. equipSkill drop gate:未解锁 NotUnlocked / 流派不符 StyleLocked /
///    境界不足 TierLocked / 槽位限主修-大招 / 全过 Succeeded;
/// 3. standalone 招使用计数落账主修 skillUsageCount(熟练度进度,波A 残留修复);
/// 4. e2e:章末首通 hook → grantManual → 装配 → BattleState 战斗可用;
/// 5. 章末重打残页:每胜 rng 累计,集齐阈值解锁(stage_04_05 挂载)。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_wave_b_wiring_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<int> seedCharacter({
    RealmTier realmTier = RealmTier.xueTu,
    TechniqueSchool? school = TechniqueSchool.gangMeng,
  }) async {
    final isar = IsarSetup.instance;
    late int charId;
    await isar.writeTxn(() async {
      final c = Character.create(
        name: '测试弟子',
        realmTier: realmTier,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.xunChang,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 6, 11),
        school: school,
      );
      charId = await isar.characters.put(c);
    });
    return charId;
  }

  group('resolver.resolveUnlockedDropSkills', () {
    test('isUnlocked + style==school 双过滤,按 tier 排序', () async {
      final isar = IsarSetup.instance;
      final svc = SkillUnlockService(isar);
      // 解锁:刚猛真解(千钧坠岳 t3)+ 刚猛残页(开碑手 t1)+ 灵巧残页(燕子三抄)。
      await svc.grantManual('skill_qian_jun_zhui_yue');
      await svc.grantManual('skill_kai_bei_shou');
      await svc.grantManual('skill_yan_zi_san_chao');

      final charId = await seedCharacter(school: TechniqueSchool.gangMeng);
      final c = (await isar.characters.get(charId))!;
      final resolver = SkillLoadoutResolver(isar: isar);
      final drops = await resolver.resolveUnlockedDropSkills(
        c,
        GameRepository.instance,
      );
      expect(drops.map((s) => s.id).toList(),
          ['skill_kai_bei_shou', 'skill_qian_jun_zhui_yue'],
          reason: '只含本流派已解锁招,tier 升序;灵巧招不入刚猛池');
    });

    test('未解锁任何招 → 空;school null → 空', () async {
      final isar = IsarSetup.instance;
      final resolver = SkillLoadoutResolver(isar: isar);
      final repo = GameRepository.instance;

      final lockedId = await seedCharacter(school: TechniqueSchool.gangMeng);
      final locked = (await isar.characters.get(lockedId))!;
      expect(await resolver.resolveUnlockedDropSkills(locked, repo), isEmpty);

      final noSchoolId = await seedCharacter(school: null);
      final noSchool = (await isar.characters.get(noSchoolId))!;
      expect(
          await resolver.resolveUnlockedDropSkills(noSchool, repo), isEmpty);
    });
  });

  group('equipSkill drop gate', () {
    test('未解锁 → SlotEquipNotUnlocked', () async {
      final isar = IsarSetup.instance;
      final charId = await seedCharacter();
      final result = await SkillLoadoutService(isar).equipSkill(
        characterId: charId,
        slot: SkillSlot.main1,
        skillId: 'skill_kai_bei_shou',
      );
      expect(result, isA<SlotEquipNotUnlocked>());
    });

    test('已解锁但流派不符 → SlotEquipStyleLocked', () async {
      final isar = IsarSetup.instance;
      await SkillUnlockService(isar).grantManual('skill_kai_bei_shou');
      final charId = await seedCharacter(school: TechniqueSchool.lingQiao);
      final result = await SkillLoadoutService(isar).equipSkill(
        characterId: charId,
        slot: SkillSlot.main1,
        skillId: 'skill_kai_bei_shou', // 刚猛残页 tier1(tier gate 不触发,纯流派不符)
      );
      expect(result, isA<SlotEquipStyleLocked>());
    });

    test('已解锁但境界不足(高 tier 真解 × xueTu)→ SlotEquipTierLocked',
        () async {
      final isar = IsarSetup.instance;
      await SkillUnlockService(isar).grantManual('skill_shi_dang_shi_jue');
      final charId = await seedCharacter(
          realmTier: RealmTier.xueTu, school: TechniqueSchool.gangMeng);
      final result = await SkillLoadoutService(isar).equipSkill(
        characterId: charId,
        slot: SkillSlot.main1,
        skillId: 'skill_shi_dang_shi_jue', // tier 5
      );
      expect(result, isA<SlotEquipTierLocked>());
    });

    test('drop 招装辅修/共鸣槽 → SlotEquipStyleLocked(槽位限主修/大招)',
        () async {
      final isar = IsarSetup.instance;
      await SkillUnlockService(isar).grantManual('skill_kai_bei_shou');
      final charId = await seedCharacter(school: TechniqueSchool.gangMeng);
      for (final slot in [SkillSlot.assist, SkillSlot.resonance]) {
        final result = await SkillLoadoutService(isar).equipSkill(
          characterId: charId,
          slot: slot,
          skillId: 'skill_kai_bei_shou',
        );
        expect(result, isA<SlotEquipStyleLocked>(),
            reason: 'drop 招不可装 ${slot.name} 槽');
      }
    });

    test('已解锁 + 流派/境界全过 → Succeeded 且落库', () async {
      final isar = IsarSetup.instance;
      await SkillUnlockService(isar).grantManual('skill_kai_bei_shou');
      final charId = await seedCharacter(
          realmTier: RealmTier.xueTu, school: TechniqueSchool.gangMeng);
      final result = await SkillLoadoutService(isar).equipSkill(
        characterId: charId,
        slot: SkillSlot.main1,
        skillId: 'skill_kai_bei_shou', // tier 1 刚猛
      );
      expect(result, isA<SlotEquipSucceeded>());
      final c = (await isar.characters.get(charId))!;
      expect(c.mainSkillId1, 'skill_kai_bei_shou');
    });
  });

  // standalone 招使用计数落账测试见 battle_resolution_test.dart(波B group,
  // 复用该文件 fixture builders)。

  group('e2e:首通真解 → 装配 → 战斗可用 + 章末重打残页', () {
    test('stage_01_05 首通 → 斜雨穿帘解锁 → 阴柔角色可装 → 战斗 availableSkills 含',
        () async {
      final isar = IsarSetup.instance;
      final repo = GameRepository.instance;
      final svc = SkillUnlockService(isar);

      // 1. 首通 hook(clearedStageIds 不含本关 = 首通)。
      await runStageSkillDropHookAfterVictory(
        stage: repo.stageDefs['stage_01_05']!,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb:
            repo.numbers.skillUnlock.towerFragmentDropProb,
        rng: Random(1),
      );
      expect(await svc.isUnlocked('skill_xie_yu_chuan_lian'), isTrue,
          reason: '首通必给真解');

      // 2. 阴柔角色装配进主修槽。
      final charId = await seedCharacter(school: TechniqueSchool.yinRou);
      final equip = await SkillLoadoutService(isar).equipSkill(
        characterId: charId,
        slot: SkillSlot.main1,
        skillId: 'skill_xie_yu_chuan_lian',
      );
      expect(equip, isA<SlotEquipSucceeded>());

      // 3. BattleState.fromCharacter 读装配槽 → 战斗可用。
      final c = (await isar.characters.get(charId))!;
      final tech = Technique.create(
        defId: 'tech_yinrou_jichu',
        ownerCharacterId: charId,
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.yinRou,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 6, 11),
      );
      final bc = BattleCharacter.fromCharacter(
        character: c,
        equipped: const [],
        mainTechnique: tech,
        numbers: repo.numbers,
        teamSide: 0,
        slotIndex: 0,
      );
      expect(bc.availableSkills.map((s) => s.id),
          contains('skill_xie_yu_chuan_lian'),
          reason: '装配槽真解应进战斗 availableSkills');

      // 4. 重打不再重复给(幂等,真解只首通)。
      await runStageSkillDropHookAfterVictory(
        stage: repo.stageDefs['stage_01_05']!,
        svc: svc,
        clearedStageIds: const {'stage_01_05'},
        towerFragmentDropProb: 0.0,
        rng: Random(2),
      );
      expect(await svc.isUnlocked('skill_xie_yu_chuan_lian'), isTrue);
    });

    test('stage_04_05 重打:残页每胜概率累计,集齐阈值解锁关山拔戟', () async {
      final isar = IsarSetup.instance;
      final repo = GameRepository.instance;
      final threshold = repo.numbers.skillUnlock.fragmentThreshold;
      final svc = SkillUnlockService(isar, fragmentThreshold: threshold);
      final stage = repo.stageDefs['stage_04_05']!;
      expect(stage.dropSkillFragmentId, 'skill_guan_shan_ba_ji');

      // 重打 threshold 次,掉率 1.0 全命中 → 集齐解锁。
      for (var i = 0; i < threshold; i++) {
        await runStageSkillDropHookAfterVictory(
          stage: stage,
          svc: svc,
          clearedStageIds: const {'stage_04_05'}, // 非首通(真解不再给)
          towerFragmentDropProb: 1.0,
          rng: Random(i),
        );
      }
      expect(await svc.isUnlocked('skill_guan_shan_ba_ji'), isTrue,
          reason: '集齐 $threshold 片应自动解锁');
    });
  });
}
