import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/inheritance/application/founder_buff_service.dart';
import 'package:wuxia_idle/features/lineup/application/lineup_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// 编成 → 战斗组队接线回归(spec §2/§5):LineupService.apply 落库后,
/// StageBattleSetup 按新列表序组队(战斗侧零改动即生效)+ founder buff 复算不掉。
void main() {
  late GameRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lineup_wiring_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  tearDownAll(GameRepository.resetForTest);

  Character makeChar({
    required int id,
    required String name,
    required int mainTechniqueId,
    bool isFounder = false,
    bool isActive = false,
    LineageRole lineageRole = LineageRole.disciple,
  }) {
    final realm = repository.getRealm(RealmTier.xueTu, RealmLayer.shuLian);
    return Character.create(
          name: name,
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.shuLian,
          attributes: Attributes()
            ..constitution = 5
            ..enlightenment = 5
            ..agility = 5
            ..fortune = 5,
          rarity: RarityTier.biaoZhun,
          lineageRole: lineageRole,
          createdAt: DateTime(2026, 7, 14),
          school: TechniqueSchool.gangMeng,
          internalForce: realm.internalForceMax,
          internalForceMax: realm.internalForceMax,
          experienceToNextLayer: realm.experienceToNext,
          isFounder: isFounder,
          isActive: isActive,
          mainTechniqueId: mainTechniqueId,
        )
        ..id = id;
  }

  /// 主修行用真 def(tech_gangmeng_jichu):battle setup 后续 loadout resolver
  /// 按 defId 取真招式,保证组队全链走通(战斗组队要求主修行在库)。
  Technique makeMainTech({required int id, required int ownerId}) {
    return Technique.create(
          defId: 'tech_gangmeng_jichu',
          ownerCharacterId: ownerId,
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 7, 14),
          cultivationProgress: 0,
          cultivationProgressToNext: 100,
          cultivationLayer: CultivationLayer.chuKui,
        )
        ..id = id;
  }

  Future<void> seed() async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        makeChar(
          id: 1,
          name: '祖师',
          isFounder: true,
          isActive: true,
          lineageRole: LineageRole.founder,
          mainTechniqueId: 901,
        ),
        makeChar(
          id: 2,
          name: '大弟子',
          isActive: true,
          lineageRole: LineageRole.senior,
          mainTechniqueId: 902,
        ),
        makeChar(id: 4, name: '替补甲', mainTechniqueId: 904),
      ]);
      await isar.techniques.putAll([
        makeMainTech(id: 901, ownerId: 1),
        makeMainTech(id: 902, ownerId: 2),
        makeMainTech(id: 904, ownerId: 4),
      ]);
      final save = SaveData()
        ..saveVersion = '0.36'
        ..createdAt = DateTime(2026, 7, 14)
        ..lastSavedAt = DateTime(2026, 7, 14)
        ..lastOnlineAt = DateTime(2026, 7, 14)
        ..founderCharacterId = 1
        ..activeCharacterIds = [1, 2];
      await isar.saveDatas.put(save);
    });
  }

  test('换人+重排后 battle setup 按新列表序组队(slot0=非祖师亦可)', () async {
    await seed();
    final isar = IsarSetup.instance;

    final applied = await LineupService(
      isar,
    ).apply(newActiveIds: [4, 1]);
    expect(applied.isSuccess, isTrue);

    final stage = GameRepository.instance.getStage('stage_01_01');
    final (left, _) = await StageBattleSetup(isar: isar).buildTeams(stage);

    expect(left.map((c) => c.characterId).toList(), [4, 1],
        reason: '列表序=站位序,slot0 前排为替补甲');
    expect(left[0].slotIndex, 0);
    expect(left[1].slotIndex, 1);
  });

  test('换人后 founder buff 仍激活(祖师必在保证)', () async {
    await seed();
    final isar = IsarSetup.instance;
    final numbers = GameRepository.instance.numbers;
    final svc = FounderBuffService(isar);

    expect(await svc.computeBuffActive(numbers), isTrue, reason: '基线激活');

    final applied = await LineupService(isar).apply(newActiveIds: [1, 4]);
    expect(applied.isSuccess, isTrue);

    expect(
      await svc.computeBuffActive(numbers),
      isTrue,
      reason: '换人不可能移出祖师(founderMissing 校验兜底),buff 恒在',
    );
  });

  test('NumbersConfig 冒烟:learningCost 主辅双档存在(择路流依赖)', () {
    final NumbersConfig n = GameRepository.instance.numbers;
    expect(n.learningCost.costFor(TechniqueRole.main), greaterThan(0));
    expect(n.learningCost.costFor(TechniqueRole.assist), greaterThan(0));
  });
}
