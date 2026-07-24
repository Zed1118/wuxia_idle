import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';

import '../support/test_data.dart';

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

void main() {
  late GameRepository repo;

  setUpAll(() async {
    GameRepository.resetForTest();
    repo = await loadTestGameRepository();
  });

  tearDownAll(GameRepository.resetForTest);

  test('Ch1–3 学徒 / Ch4–6 三流 / Ch7 二流，敌人不超过发布上限', () {
    // 章 → 境界阶(内容映射·2026-07-24 Ch16 宗师段首章扩):
    //   Ch1-3 学徒 / Ch4-6 三流 / Ch7-9 二流 / Ch10-12 一流 / Ch13-15 绝顶 / Ch16+ 宗师。
    RealmTier expectedTierOf(int chapterIndex) {
      if (chapterIndex <= 3) return RealmTier.xueTu;
      if (chapterIndex <= 6) return RealmTier.sanLiu;
      if (chapterIndex <= 9) return RealmTier.erLiu;
      if (chapterIndex <= 12) return RealmTier.yiLiu;
      if (chapterIndex <= 15) return RealmTier.jueDing;
      return RealmTier.zongShi;
    }

    final mainline = repo.stageDefs.values.where(
      (stage) => stage.stageType == StageType.mainline,
    );
    for (final stage in mainline) {
      final expectedTier = expectedTierOf(stage.chapterIndex!);
      expect(stage.requiredRealm, expectedTier, reason: stage.id);
      for (final enemy in stage.enemyTeam) {
        expect(
          enemy.realmTier,
          expectedTier,
          reason: '${stage.id}/${enemy.id}',
        );
        expect(
          repo.getRealm(enemy.realmTier, enemy.realmLayer).absoluteLevel,
          lessThanOrEqualTo(
            repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel,
          ),
          reason: '${stage.id}/${enemy.id} 不得越过当前发布上限',
        );
      }
    }
  });

  test('按章缩放敌人 HP/攻击并保留清晰坡度', () {
    const expected = {
      'stage_02_01': (2500, 100),
      'stage_02_02': (4100, 290),
      'stage_02_03': (2200, 170),
      'stage_02_04': (2300, 60),
      'stage_02_05': (8100, 770),
      'stage_03_01': (2100, 80),
      'stage_03_02': (2950, 230),
      'stage_03_03': (3250, 250),
      'stage_03_04': (2500, 80),
      'stage_03_05': (5850, 460),
      'stage_04_01': (3950, 400),
      'stage_04_02': (4150, 390),
      'stage_04_03': (3600, 330),
      'stage_04_04': (3400, 250),
      'stage_04_05': (9900, 470),
      'stage_05_01': (3500, 250),
      'stage_05_02': (3850, 280),
      'stage_05_03': (4200, 300),
      'stage_05_04': (4200, 300),
      'stage_05_05': (8400, 530),
      'stage_06_01': (3750, 280),
      'stage_06_02': (4250, 310),
      'stage_06_03': (4500, 330),
      'stage_06_04': (4200, 250),
      'stage_06_05': (12000, 450),
    };
    for (final entry in expected.entries) {
      final enemy = repo.getStage(entry.key).enemyTeam.single;
      expect((enemy.baseHp, enemy.baseAttack), entry.value, reason: entry.key);
    }
  });

  test('主线掉落装备/招式不超过当前发布上限对应阶', () {
    // 掉落上限 = 当前发布上限(maxAbsoluteRealmLevel → 境界阶)对应的装备/招式阶。
    //   掉落可高于本关境界(§5.3:高阶物可获得/携带/观摩,装备门槛只管"上身"不管"掉落"),
    //   但不得超过发布上限(否则掉落玩家本发布版永不可用的招/装)。
    //   装备阶 index 同序境界阶 index;招式阶 = 境界 index + 1(沿 releaseSkillTierCap 口径)。
    // cap-agnostic:Ch7 二流首章扩后发布上限=二流,自动允许好家伙/tier3,不需改本测数字。
    final releaseCapIndex = _releaseCapTier(repo).index;
    final equipTierCap = releaseCapIndex;
    final skillTierCap = releaseCapIndex + 1;
    final mainline = repo.stageDefs.values.where(
      (stage) => stage.stageType == StageType.mainline,
    );
    for (final stage in mainline) {
      for (final entry in stage.dropTable.whereType<EquipmentDrop>()) {
        expect(
          repo.getEquipment(entry.equipmentDefId).tier.index,
          lessThanOrEqualTo(equipTierCap),
          reason: '${stage.id}/${entry.equipmentDefId}',
        );
      }
      for (final entry in stage.dropTable.whereType<ItemDrop>()) {
        final unlockSkillId =
            repo.itemDefs[entry.inventoryItemDefId]?.unlockSkillId;
        if (unlockSkillId == null) continue;
        expect(
          repo.getSkill(unlockSkillId).tier,
          lessThanOrEqualTo(skillTierCap),
          reason: '${stage.id}/${entry.inventoryItemDefId}/$unlockSkillId',
        );
      }
      for (final skillId in [
        stage.dropSkillManualId,
        stage.dropSkillFragmentId,
      ].whereType<String>()) {
        expect(
          repo.getSkill(skillId).tier,
          lessThanOrEqualTo(skillTierCap),
          reason: '${stage.id}/$skillId',
        );
      }
    }
  });

  test('顺序结算主线时，普通关最多 +1 级，Boss 关最多 +3 级', () {
    final firstRealm = repo.getRealm(RealmTier.xueTu, RealmLayer.qiMeng);
    final character = Character.create(
      name: 'mainline_span_probe',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 7, 14),
      internalForceMax: firstRealm.internalForceMax,
      experienceToNextLayer: firstRealm.experienceToNext,
    );
    final mainline =
        repo.stageDefs.values
            .where((stage) => stage.stageType == StageType.mainline)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    for (final stage in mainline) {
      final before = _displayLevel(repo, character);
      CharacterAdvancementService.applyExperience(
        character,
        stage.baseExpReward,
        realmLookup: repo.getRealm,
      );
      final delta = _displayLevel(repo, character) - before;
      expect(
        delta,
        inInclusiveRange(0, stage.isBossStage ? 3 : 1),
        reason: '${stage.id}: $before → ${_displayLevel(repo, character)}',
      );
    }
  });

  test('Ch1_04 early boss stays in readable onboarding range', () {
    final enemy = repo.getStage('stage_01_04').enemyTeam.single;

    expect(
      enemy.baseHp,
      inInclusiveRange(2000, 2600),
      reason: 'Ch1_04 是第一章小 Boss，不应回退成过厚的新手墙',
    );
    expect(
      enemy.baseAttack,
      lessThanOrEqualTo(80),
      reason: 'Ch1_04 攻击只做新手压力，不应秒杀刚成型角色',
    );
  });

  test('Ch2_05 chapter boss attack does not regress to the old spike', () {
    final boss = repo
        .getStage('stage_02_05')
        .enemyTeam
        .singleWhere((enemy) => enemy.id == 'enemy_sanLiu_qingshan_main');

    expect(
      boss.baseHp,
      lessThanOrEqualTo(10000),
      reason: 'Ch2_05 章末 Boss 可厚，但不应越过当前三流章节曲线',
    );
    expect(
      boss.baseAttack,
      lessThanOrEqualTo(1000),
      reason: '外部审查中过高攻击已修正，后续不能回退到 1100+',
    );
  });

  test('Ch5 mainline base HP and attack form a clear chapter curve', () {
    final stageIds = [
      'stage_05_01',
      'stage_05_02',
      'stage_05_03',
      'stage_05_04',
      'stage_05_05',
    ];
    final enemies = stageIds.map(
      (stageId) => repo.getStage(stageId).enemyTeam.single,
    );
    final hpCurve = enemies.map((enemy) => enemy.baseHp).toList();
    final attackCurve = enemies.map((enemy) => enemy.baseAttack).toList();

    expect(hpCurve, [
      3500,
      3850,
      4200,
      4200,
      8400,
    ], reason: 'Ch5 应从普通关递进到小 Boss，再到章末 Boss');
    expect(attackCurve, [
      250,
      280,
      300,
      300,
      530,
    ], reason: 'Ch5 攻击压力应随关卡逐步抬升，不再首关倒挂');
    for (var i = 1; i < hpCurve.length; i += 1) {
      expect(hpCurve[i], greaterThanOrEqualTo(hpCurve[i - 1]));
      expect(attackCurve[i], greaterThanOrEqualTo(attackCurve[i - 1]));
    }
  });
}

/// 当前发布上限对应的境界阶(maxAbsoluteRealmLevel → RealmTier)。
RealmTier _releaseCapTier(GameRepository repo) {
  final absoluteLevel =
      repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel;
  return RealmTier.values[(absoluteLevel - 1) ~/ RealmLayer.values.length];
}
