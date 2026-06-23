import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/sect/domain/sect_rank.dart' show SectRank;
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';

/// P4.1 1.1 Q6B · stage_boss recruit B3 R5 测族(spec §7)。
///
/// 覆盖维度:
/// - **R5.stages production yaml** 3 章末大 Boss bossRecruit 加载 + candidateRef 映射
/// - **R5.numbers** numbers.yaml stage_boss_recruit_prob = 0.40 + BossRecruitConfig 默认
/// - **R5.persistence** SaveData.triggeredBossRecruitStageIds 持久化(写→close→reopen 读)
/// - **R5.serviceTie e2e** Boss recruit candidate(mountain_hermit)走 SectMemberService.recruit success
/// - **R5.schema 红线** 三重校(非 isBossStage 配 + candidateRef invalid + probability 越界)
/// - **R5.compat** 1.0 ship Boss 全 bossRecruit=null 不破 load
///
/// **fixture 策略**(沿 sect_recruit_test):真 Isar + tempDir + 真 yaml load + minimal
/// seed founder/sect。schema 红线测沿 game_repository_test brokenLoader 体例。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_stage_boss_recruit_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// seed founder + sect(sectLevel=1 cap=3),不入候选 NPC(测族端 inject)。
  Future<({int sectId, int founderId})> seedFounder({
    int sectLevel = 1,
    int initialMemberCount = 0,
  }) async {
    final isar = IsarSetup.instance;
    late int sectId;
    var founderId = 0;
    await isar.writeTxn(() async {
      final founder = Character.create(
        name: '祖师',
        realmTier: RealmTier.wuSheng,
        realmLayer: RealmLayer.dengFeng,
        attributes: Attributes()
          ..constitution = 7
          ..enlightenment = 7
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.jueShi,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 5, 26),
        isFounder: true,
      );
      founderId = await isar.characters.put(founder);

      final sect = Sect()
        ..name = '无名宗'
        ..founderId = founderId
        ..sectLevel = sectLevel
        ..sectReputation = 50
        ..totalWins = 0
        ..memberCount = initialMemberCount
        ..territoryIds = []
        ..createdAt = DateTime(2026, 5, 26);
      sectId = await isar.sects.put(sect);
    });
    return (sectId: sectId, founderId: founderId);
  }

  group('R5.stages · production stages.yaml 6 Boss bossRecruit', () {
    test('Ch1-6 章末 Boss bossRecruit 加载 + candidateRef 对应 + 默认 probability',
        () {
      final repo = GameRepository.instance;
      final expectedMap = {
        'stage_01_05': 'bamboo_swordsman',
        'stage_02_05': 'desert_wanderer',
        'stage_03_05': 'mountain_hermit',
        'stage_04_05': 'river_drifter',
        'stage_05_05': 'blacksmith_son',
        'stage_06_05': 'valley_hermit',
      };
      for (final entry in expectedMap.entries) {
        final stage = repo.stageDefs[entry.key];
        expect(stage, isNotNull, reason: '${entry.key} 应在 stages.yaml 中');
        expect(stage!.isBossStage, true, reason: '${entry.key} 必 isBossStage=true');
        expect(stage.bossRecruit, isNotNull,
            reason: '${entry.key} 应配 bossRecruit(P4.1 1.1 Q6B PoC 3)');
        expect(stage.bossRecruit!.candidateRef, entry.value);
        // baseProbability 省略 → 默认 0.40
        expect(stage.bossRecruit!.baseProbability, 0.40);
        // candidateRef 必在 sectCandidates(_enforceBossRecruitRedLines 已校)
        expect(repo.sectCandidates[entry.value], isNotNull);
      }
    });
  });

  group('R5.numbers · numbers.yaml stage_boss_recruit_prob', () {
    test('stage_boss_recruit_prob = 0.40 + BossRecruitConfig 默认', () {
      final repo = GameRepository.instance;
      expect(repo.numbers.sectManagement.recruit.stageBossRecruitProb, 0.40,
          reason: 'Q6B 战胜 Boss 招降概率');
      // 既存 stageBossFailRecoverProb 保留 0.30(P4.1 v1.10 战败收降留 P5+/1.1)
      expect(
          repo.numbers.sectManagement.recruit.stageBossFailRecoverProb, 0.30);
      // BossRecruitConfig 默认 baseProbability 0.40 跟 numbers.yaml 一致
      const cfg = BossRecruitConfig(candidateRef: 'test');
      expect(cfg.baseProbability, 0.40);
    });
  });

  group('R5.persistence · SaveData.triggeredBossRecruitStageIds 持久化', () {
    test('写 stage_01_05 → close → reopen 读出一致', () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final save = await isar.saveDatas.get(0);
        expect(save, isNotNull);
        save!.triggeredBossRecruitStageIds = ['stage_01_05'];
        await isar.saveDatas.put(save);
      });
      // close → reopen
      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save, isNotNull);
      expect(save!.triggeredBossRecruitStageIds, ['stage_01_05']);
    });
  });

  group('R5.serviceTie · Boss candidate(mountain_hermit)走 service success', () {
    test('Character.create + SectMemberService.recruit → success + isInSect '
        '+ sectRank=initiate + isFounder=false + memberCount++', () async {
      final f = await seedFounder();
      final isar = IsarSetup.instance;
      final candidate =
          GameRepository.instance.sectCandidates['mountain_hermit']!;
      final repo = GameRepository.instance;
      final realmDef = repo.getRealm(
          candidate.defaultRealm, candidate.defaultLayer);
      late RecruitResult result;
      late int newCharId;
      await isar.writeTxn(() async {
        final newChar = Character.create(
          name: candidate.name,
          realmTier: candidate.defaultRealm,
          realmLayer: candidate.defaultLayer,
          attributes: Attributes()
            ..constitution = candidate.attributeProfile.constitution
            ..enlightenment = candidate.attributeProfile.enlightenment
            ..agility = candidate.attributeProfile.agility
            ..fortune = candidate.attributeProfile.fortune,
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.disciple,
          isFounder: false,
          isActive: false,
          createdAt: DateTime(2026, 5, 26),
          school: candidate.school,
          internalForce: realmDef.internalForceMax,
          internalForceMax: realmDef.internalForceMax,
          experienceToNextLayer: realmDef.experienceToNext,
        );
        await isar.characters.put(newChar);
        newCharId = newChar.id;

        final memberSvc = SectMemberService(isar);
        result = await memberSvc.recruit(
          targetCharacterId: newChar.id,
          sectId: f.sectId,
          numbers: repo.numbers,
        );
      });
      expect(result, RecruitResult.success);
      final newChar = await isar.characters.get(newCharId);
      expect(newChar, isNotNull);
      expect(newChar!.isInSect, true);
      expect(newChar.sectId, f.sectId);
      expect(newChar.sectRank, SectRank.initiate);
      expect(newChar.isFounder, false);
      expect(newChar.isActive, false);
      final sect = await isar.sects.get(f.sectId);
      expect(sect!.memberCount, 1);
    });
  });

  group('R5.schema 红线 · broken loader transform(沿 production yaml + replace)', () {
    /// transform 模式:读 production stages.yaml 后字符串改 1 处 inject 触发红线,
    /// 不破其他 production 红线(`_enforceMainlineRedLines` 15 关 / chapterIndex 连续)。
    Future<String> Function(String) makeStagesLoader(
        String Function(String original) transform) {
      Future<String> loader(String path) async {
        final original = await File(path).readAsString();
        if (path == 'data/stages.yaml') return transform(original);
        return original;
      }
      return loader;
    }

    test('① 非 isBossStage 配 bossRecruit → 抛 StateError', () async {
      // stage_01_01 是非 Boss 第一关 · '  - id: stage_01_01' 是 unique 锚
      // (F5/2026-06-23 删 dropEquipmentDefIds 占位字段后改锚 stage 声明行),注入 bossRecruit 段。
      String inject(String s) => s.replaceFirst(
            '  - id: stage_01_01\n',
            '  - id: stage_01_01\n    bossRecruit:\n'
                '      candidateRef: bamboo_swordsman\n',
          );
      expect(
        GameRepository.loadAllDefs(loader: makeStagesLoader(inject)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('isBossStage=false'),
        )),
      );
    });

    test('② bossRecruit.candidateRef 不在 sectCandidates → 抛 StateError',
        () async {
      // stage_01_05 已配 bossRecruit candidateRef=bamboo_swordsman(unique 锚 · 仅本 stage)
      String inject(String s) => s.replaceFirst(
            'candidateRef: bamboo_swordsman',
            'candidateRef: ghost_npc_not_loaded',
          );
      expect(
        GameRepository.loadAllDefs(loader: makeStagesLoader(inject)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ghost_npc_not_loaded'),
        )),
      );
    });

    test('③ baseProbability 越界(1.5)→ 抛 StateError', () async {
      // stage_01_05 已配 bossRecruit · 加 baseProbability: 1.5 触发红线
      String inject(String s) => s.replaceFirst(
            'candidateRef: bamboo_swordsman              # data/sect_candidates.yaml 已配(lingQiao 三系)',
            'candidateRef: bamboo_swordsman\n      baseProbability: 1.5',
          );
      expect(
        GameRepository.loadAllDefs(loader: makeStagesLoader(inject)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('1.5'),
        )),
      );
    });
  });

  group('R5.failRecover · 战败收降叙事 + dedup 共用', () {
    test('Ch1-6 boss_fail_recover 叙事文件存在', () async {
      final ids = [
        'stage_01_05_boss_fail_recover',
        'stage_02_05_boss_fail_recover',
        'stage_03_05_boss_fail_recover',
        'stage_04_05_boss_fail_recover',
        'stage_05_05_boss_fail_recover',
        'stage_06_05_boss_fail_recover',
      ];
      for (final id in ids) {
        final file = File('data/narratives/stages/$id.yaml');
        expect(file.existsSync(), true, reason: '$id.yaml 应存在');
      }
    });

    test('triggeredBossRecruitStageIds 由 victory/defeat 共用(先 mark → 另一方跳过)',
        () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final save = await isar.saveDatas.get(0);
        expect(save, isNotNull);
        save!.triggeredBossRecruitStageIds = ['stage_01_05'];
        await isar.saveDatas.put(save);
      });
      final save = await isar.saveDatas.get(0);
      expect(save!.triggeredBossRecruitStageIds, contains('stage_01_05'),
          reason: 'victory mark 后 defeat 应 skip(共用 set)');
    });

    test('stageBossFailRecoverProb 在 (0, 1] 且 < stageBossRecruitProb', () {
      final recruit = GameRepository.instance.numbers.sectManagement.recruit;
      expect(recruit.stageBossFailRecoverProb, greaterThan(0));
      expect(recruit.stageBossFailRecoverProb, lessThanOrEqualTo(1));
      expect(recruit.stageBossFailRecoverProb,
          lessThan(recruit.stageBossRecruitProb),
          reason: '战败收降概率应 < 战胜招降概率');
    });
  });

  group('R5.compat · 1.0 ship Boss 全 bossRecruit=null 兼容', () {
    test('stage_01_04 / stage_02_04 / stage_03_04 等小 Boss 关 bossRecruit=null 不破 load',
        () {
      final repo = GameRepository.instance;
      // 小 Boss 关本批未配 bossRecruit · 应为 null
      final smallBosses = ['stage_01_04', 'stage_02_04', 'stage_03_04'];
      for (final id in smallBosses) {
        final stage = repo.stageDefs[id];
        expect(stage, isNotNull);
        expect(stage!.isBossStage, true, reason: '$id 是 isBossStage=true 小 Boss');
        expect(stage.bossRecruit, isNull,
            reason: '$id 本批未配 bossRecruit · 兼容现有 load 不破');
      }
    });
  });
}
