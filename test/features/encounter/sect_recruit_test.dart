import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_rank.dart';

/// P4.1 1.1 Q6A · sect_recruit encounter B3 R5 测族(spec §7)。
///
/// 覆盖维度:
/// - **R5.production yaml** 5 NPC + 3 sect_recruit encounters 加载 + 字段
/// - **R5.1 招收 e2e**(R5.1 + R5.6 + R5.8 合并:isInSect/sectId/sectRank=initiate/isFounder=false)
/// - **R5.2 cap 满 fallback**
/// - **R5.4 schema 红线**:candidateRef invalid / 缺 accept_recruit / fallback invalid
/// - **R5.3 decline 路径 schema**:sect_recruit_bamboo decline_meet 是 attributeBonus
///
/// **fixture 策略**(沿 sect_member_service_test):真 Isar + tempDir + 真 yaml load
/// + minimal seed founder/sect。schema 红线测沿 game_repository_test brokenLoader 体例。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_sect_recruit_test_');
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
        createdAt: DateTime(2026, 5, 25),
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
        ..createdAt = DateTime(2026, 5, 25);
      sectId = await isar.sects.put(sect);
    });
    return (sectId: sectId, founderId: founderId);
  }

  group('R5.production · 加载层验 production yaml', () {
    test('sect_candidates.yaml 6 NPC 加载 + 字段完整', () {
      final candidates = GameRepository.instance.sectCandidates;
      expect(candidates.length, 6,
          reason: '5 PoC + 1 新增(valley_hermit · 1.1 池扩)');
      expect(candidates.keys, containsAll({
        'bamboo_swordsman',
        'desert_wanderer',
        'mountain_hermit',
        'river_drifter',
        'blacksmith_son',
        'valley_hermit',
      }));
      // 抽样验 bamboo_swordsman 字段
      final bamboo = candidates['bamboo_swordsman']!;
      expect(bamboo.name, '竹影客');
      expect(bamboo.defaultRealm, RealmTier.sanLiu);
      expect(bamboo.defaultLayer, RealmLayer.ruMen);
      expect(bamboo.school, TechniqueSchool.lingQiao);
      expect(bamboo.attributeProfile.total, 24); // 5+7+7+5
      expect(bamboo.startingTechniqueIds, ['tech_lingqiao_changlian']);
      expect(bamboo.startingEquipmentIds.length, 2);
    });

    test('3 sect_recruit encounters 加载 + affectsSectMembership 字段', () {
      final repo = GameRepository.instance;
      final ids = ['sect_recruit_bamboo', 'sect_recruit_desert',
        'sect_recruit_mountain'];
      for (final id in ids) {
        final def = repo.encounterDefs[id];
        expect(def, isNotNull, reason: '$id 应在 encounters.yaml 中');
        expect(def!.type, EncounterType.fortuneEvent);
        expect(def.affectsSectMembership, isNotNull);
        expect(def.affectsSectMembership!.fallbackOutcomeId, 'decline_meet');
        expect(def.outcomeMapping.keys, containsAll({'accept_recruit',
          'decline_meet'}));
      }
      // candidateRef 与 sectCandidates 1:1 映射(spec §0 Q9 Demo 单一)
      expect(repo.encounterDefs['sect_recruit_bamboo']!.affectsSectMembership!
          .candidateRef, 'bamboo_swordsman');
      expect(repo.encounterDefs['sect_recruit_desert']!.affectsSectMembership!
          .candidateRef, 'desert_wanderer');
      expect(repo.encounterDefs['sect_recruit_mountain']!.affectsSectMembership!
          .candidateRef, 'mountain_hermit');
    });

    test('R5.3 decline_meet outcome 是 attributeBonus +1', () {
      final repo = GameRepository.instance;
      final bamboo = repo.encounterDefs['sect_recruit_bamboo']!;
      final decline = bamboo.outcomeMapping['decline_meet']!;
      expect(decline.type, OutcomeType.attributeBonus);
      expect(decline.attributeDelta, 1);
      // accept_recruit 是 type:none(真效果走 sect wire)
      final accept = bamboo.outcomeMapping['accept_recruit']!;
      expect(accept.type, OutcomeType.none);
    });
  });

  group('R5.1 招收 e2e + R5.6 sectRank initiate + R5.8 isFounder=false', () {
    test('encounter accept_recruit → Character.create + recruit success'
        ' + isInSect/sectId/sectRank=initiate/isFounder=false + memberCount++',
        () async {
      final f = await seedFounder();
      final isar = IsarSetup.instance;
      final candidate =
          GameRepository.instance.sectCandidates['bamboo_swordsman']!;
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
      // R5.1 双向 fk
      expect(newChar!.isInSect, true);
      expect(newChar.sectId, f.sectId);
      // R5.6 sectRank initiate
      expect(newChar.sectRank, SectRank.initiate);
      // R5.8 isFounder=false(NPC 不误激活 founder buff)
      expect(newChar.isFounder, false);
      expect(newChar.isActive, false); // 不入 active 池
      // memberCount++
      final sect = await isar.sects.get(f.sectId);
      expect(sect!.memberCount, 1);
    });
  });

  group('R5.2 cap 满 fallback', () {
    test('sect.memberCount = cap(3) → recruit 返 fullCap + memberCount 不变',
        () async {
      final f = await seedFounder(initialMemberCount: 3); // sectLevel=1 cap=3
      final isar = IsarSetup.instance;
      final candidate =
          GameRepository.instance.sectCandidates['desert_wanderer']!;
      final repo = GameRepository.instance;
      final realmDef = repo.getRealm(
          candidate.defaultRealm, candidate.defaultLayer);
      late RecruitResult result;
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

        final memberSvc = SectMemberService(isar);
        result = await memberSvc.recruit(
          targetCharacterId: newChar.id,
          sectId: f.sectId,
          numbers: repo.numbers,
        );
      });
      expect(result, RecruitResult.fullCap);
      // memberCount 不变(沿 SectMemberService.recruit 体例 · cap 检查在写之前)
      final sect = await isar.sects.get(f.sectId);
      expect(sect!.memberCount, 3);
    });
  });

  group('R5.4 schema 红线(broken loader inject)', () {
    Future<String> Function(String) makeLoader({
      String? brokenEncountersYaml,
      String? brokenSectCandidatesYaml,
    }) {
      Future<String> loader(String path) async {
        if (path == 'data/encounters.yaml' && brokenEncountersYaml != null) {
          return brokenEncountersYaml;
        }
        if (path == 'data/sect_candidates.yaml' &&
            brokenSectCandidatesYaml != null) {
          return brokenSectCandidatesYaml;
        }
        return File(path).readAsString();
      }
      return loader;
    }

    // broken loader test 内部 throw 不污染 GameRepository._instance
    // (`loadAllDefs` :340 _enforceRedLines throws 在 :342 _instance 赋值之前)
    // 故 production data 保持 setUpAll 加载状态,无需 reset。

    test('affectsSectMembership.candidateRef 不在 sectCandidates → 抛 StateError',
        () async {
      // 用 brokenLoader inject encounters.yaml 末尾加 1 条引用不存在 candidateRef
      final brokenEncounters = '''
encounters:
  - id: bad_sect_recruit
    type: fortuneEvent
    trigger:
      fortuneRequired: 5
    baseProbability: 0.1
    outcomeMapping:
      accept_recruit:
        type: none
      decline_meet:
        type: attributeBonus
        attributeKey: enlightenment
        attributeDelta: 1
    affectsSectMembership:
      candidateRef: ghost_npc_not_loaded
      fallbackOutcomeId: decline_meet
''';
      expect(
        GameRepository.loadAllDefs(
            loader: makeLoader(brokenEncountersYaml: brokenEncounters)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ghost_npc_not_loaded'),
        )),
      );
    });

    test('affectsSectMembership 缺 accept_recruit outcome → 抛 StateError',
        () async {
      final brokenEncounters = '''
encounters:
  - id: bad_sect_recruit
    type: fortuneEvent
    trigger:
      fortuneRequired: 5
    baseProbability: 0.1
    outcomeMapping:
      decline_meet:
        type: attributeBonus
        attributeKey: enlightenment
        attributeDelta: 1
    affectsSectMembership:
      candidateRef: bamboo_swordsman
      fallbackOutcomeId: decline_meet
''';
      expect(
        GameRepository.loadAllDefs(
            loader: makeLoader(brokenEncountersYaml: brokenEncounters)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('accept_recruit'),
        )),
      );
    });

    test('affectsSectMembership.fallbackOutcomeId 不在 outcomeMapping → 抛',
        () async {
      final brokenEncounters = '''
encounters:
  - id: bad_sect_recruit
    type: fortuneEvent
    trigger:
      fortuneRequired: 5
    baseProbability: 0.1
    outcomeMapping:
      accept_recruit:
        type: none
    affectsSectMembership:
      candidateRef: bamboo_swordsman
      fallbackOutcomeId: nonexistent_outcome
''';
      expect(
        GameRepository.loadAllDefs(
            loader: makeLoader(brokenEncountersYaml: brokenEncounters)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('nonexistent_outcome'),
        )),
      );
    });
  });
}
