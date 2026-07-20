import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/application/progression_gate_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../../../support/test_data.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('45 主线首通从 Lv1 出发，累计 1053 经验结束于 Lv63(2026-07-20 Ch9 +210)', () {
    final character = _newCharacter(repo);
    final mainline =
        repo.stageDefs.values
            .where((stage) => stage.stageType == StageType.mainline)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    expect(mainline, hasLength(45));
    var cumulativeExperience = 0;
    var maximumJump = 0;
    for (final stage in mainline) {
      final before = _displayLevel(repo, character);
      cumulativeExperience += stage.baseExpReward;
      _applyExperience(repo, character, stage.baseExpReward);
      final after = _displayLevel(repo, character);
      final jump = after - before;
      if (jump > maximumJump) maximumJump = jump;
      expect(
        jump,
        stage.isBossStage ? inInclusiveRange(1, 3) : inInclusiveRange(0, 1),
        reason: '${stage.id}: Lv$before → Lv$after',
      );
    }

    expect(cumulativeExperience, 1053);
    expect(maximumJump, 3);
    expect(_displayLevel(repo, character), 63);
  });

  test('当前全内容 + 72h 闭关 + 24h 离线 + 三枚丹药结束于 Lv94(2026-07-20 Ch9 扩)', () {
    final character = _newCharacter(repo);
    final combatRewards = <int>[
      ..._stageRewards(repo, StageType.mainline),
      ...repo.towerFloors.map((floor) => floor.baseExpReward),
      ..._stageRewards(repo, StageType.lightFoot),
      ..._stageRewards(repo, StageType.massBattle),
      ..._stageRewards(repo, StageType.innerDemon),
    ];
    for (final reward in combatRewards) {
      _applyExperience(repo, character, reward);
    }
    expect(combatRewards.fold<int>(0, (sum, reward) => sum + reward), 1960);
    expect(_displayLevel(repo, character), 82);

    final retreatExperience = _retreatExperience(
      repo,
      character,
      RetreatMapType.cangJingGe,
      72,
    );
    _applyExperience(repo, character, retreatExperience);
    expect(retreatExperience, 356);
    expect(_displayLevel(repo, character), 87);

    final passive = OfflinePassiveService.compute(
      awayHours: 24,
      realmTier: character.realmTier,
      config: repo.numbers.passiveIdle,
    );
    _applyExperience(repo, character, passive.experience);
    expect(passive.experience, 115);
    expect(_displayLevel(repo, character), 89);

    for (final id in const [
      'item_jingyandan_small',
      'item_jingyandan_mid',
      'item_jingyandan_large',
    ]) {
      final fraction = repo.itemDefs[id]!.layerFraction!;
      final threshold = repo
          .getRealm(character.realmTier, character.realmLayer)
          .experienceToNext;
      _applyExperience(repo, character, (threshold * fraction).round());
    }

    final level = _displayLevel(repo, character);
    expect(level, 94);
  });

  test('三流可达地图 72h 闭关仅提升 3–6 个显示级', () {
    final character = _newCharacter(
      repo,
      tier: RealmTier.sanLiu,
      layer: RealmLayer.qiMeng,
    );
    final before = _displayLevel(repo, character);
    final experience = _retreatExperience(
      repo,
      character,
      RetreatMapType.guJianZhong,
      72,
    );

    _applyExperience(repo, character, experience);

    expect(_displayLevel(repo, character) - before, inInclusiveRange(3, 6));
  });

  test('三流 8h 离线不超过 1 级，三枚经验丹分别为当层 10%/20%/30%', () {
    final character = _newCharacter(
      repo,
      tier: RealmTier.sanLiu,
      layer: RealmLayer.qiMeng,
    );
    final before = _displayLevel(repo, character);
    final passive = OfflinePassiveService.compute(
      awayHours: 8,
      realmTier: character.realmTier,
      config: repo.numbers.passiveIdle,
    );

    _applyExperience(repo, character, passive.experience);

    expect(_displayLevel(repo, character) - before, lessThanOrEqualTo(1));
    expect(
      const [
        'item_jingyandan_small',
        'item_jingyandan_mid',
        'item_jingyandan_large',
      ].map((id) => repo.itemDefs[id]!.layerFraction),
      orderedEquals(const [0.1, 0.2, 0.3]),
    );
  });
}

const _allInnerDemonStages = {
  'stage_inner_demon_01',
  'stage_inner_demon_02',
  'stage_inner_demon_03',
  'stage_inner_demon_04',
  'stage_inner_demon_05',
  'stage_inner_demon_06',
  'stage_inner_demon_07',
};

Character _newCharacter(
  GameRepository repo, {
  RealmTier tier = RealmTier.xueTu,
  RealmLayer layer = RealmLayer.qiMeng,
}) {
  final realm = repo.getRealm(tier, layer);
  return Character.create(
    name: 'progression_budget_probe',
    realmTier: tier,
    realmLayer: layer,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 7, 14),
    internalForceMax: realm.internalForceMax,
    experienceToNextLayer: realm.experienceToNext,
  );
}

void _applyExperience(
  GameRepository repo,
  Character character,
  int experience,
) {
  CharacterAdvancementService.applyExperience(
    character,
    experience,
    realmLookup: repo.getRealm,
    isLayerLocked: (tier, layer) => ProgressionGateService.isLayerLocked(
      nextTier: tier,
      nextLayer: layer,
      releaseCap: repo.numbers.progressionReleaseCap,
      realmLookup: repo.getRealm,
      innerDemonDef: repo.numbers.innerDemon,
      clearedStageIds: _allInnerDemonStages,
    ),
  );
}

List<int> _stageRewards(GameRepository repo, StageType type) {
  final stages =
      repo.stageDefs.values.where((stage) => stage.stageType == type).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return stages.map((stage) => stage.baseExpReward).toList(growable: false);
}

int _retreatExperience(
  GameRepository repo,
  Character character,
  RetreatMapType mapType,
  int hours,
) {
  final startedAt = DateTime(2026, 7, 1, 10);
  final session = RetreatSession()
    ..saveDataId = 1
    ..mapType = mapType
    ..realmTierAtStart = character.realmTier
    ..startedAt = startedAt;
  return SeclusionService.computeOutputs(
    session: session,
    charRealmTier: character.realmTier,
    config: repo.numbers.retreat,
    maps: repo.seclusionMaps,
    now: startedAt.add(Duration(hours: hours)),
  ).experiencePoints;
}

int _displayLevel(GameRepository repo, Character character) {
  final realm = repo.getRealm(character.realmTier, character.realmLayer);
  return RealmProgressDisplay.fromSnapshot(
    absoluteRealmLevel: realm.absoluteLevel,
    experience: character.experience,
    experienceToNext: realm.experienceToNext,
    hasNextRealmLayer:
        CharacterAdvancementService.nextLayer(
          character.realmTier,
          character.realmLayer,
        ) !=
        null,
  ).level;
}
