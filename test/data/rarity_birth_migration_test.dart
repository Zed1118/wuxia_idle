import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import '../support/isar_test_support.dart';
import '../support/test_data.dart';

/// BACKLOG 一#15：存档 0.38.0 → 0.39.0 资质档位回填迁移。
///
/// 2026-08-08「出生锁死」拍板后 `Character.rarity` 加载时不再重算，故 08-08 之前
/// 建的角色永久停留旧写死值 `biaoZhun`。本迁移按**出生点数**（而非当前总点数）
/// 一次性重算：`attributes.total − attributeBonusFromAdventure`。
///
/// **本套件的判别力**：用例①的角色吃满生涯 cap（total 27 / bonus 5），若迁移误按
/// **当前**总点数重算（BACKLOG 一#15 的选项 b），27 越出 `rarity_distribution`
/// 上界会被 `rarityForTotalPoints` 钳到 `jueShi`，与期望的 `ziYou` 不同 → 必红。
///
/// 走真实 `data/numbers.yaml`（`loadTestGameRepository` → `loadTestAsset` 读盘），
/// 不用合成 fixture，否则 `rarityTiers` 为空会退化成 `biaoZhun` 兜底给假绿。
void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    // 段 9 需要 numbers.rarityForTotalPoints → 必须先加载 defs。
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_rarity_birth_mig_');
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// 造一个「08-08 之前建的」角色：档位写死 [staleRarity]，与其出生点数不符。
  Character staleChar({
    required String name,
    required Attributes attributes,
    required int adventureBonus,
    RarityTier staleRarity = RarityTier.biaoZhun,
  }) => Character.create(
    name: name,
    realmTier: RealmTier.erLiu,
    realmLayer: RealmLayer.qiMeng,
    attributes: attributes,
    rarity: staleRarity,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 8, 1),
    internalForce: 700,
    internalForceMax: 3500,
    attributeBonusFromAdventure: adventureBonus,
  );

  Attributes attrs(int con, int enl, int agi, int fort) => Attributes()
    ..constitution = con
    ..enlightenment = enl
    ..agility = agi
    ..fortune = fort;

  Future<void> seedOldSave(List<Character> characters) async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.saveVersion = '0.38.0';
      await IsarSetup.instance.saveDatas.put(save);
      for (final c in characters) {
        await IsarSetup.instance.characters.put(c);
      }
    });
    await IsarSetup.close();
    // 重开 → _ensureSaveData 检出版本差 → 跑迁移。
    await IsarSetup.init(directory: tempDir, inspector: false);
  }

  test('0.38 旧档：吃满生涯加点的角色按出生点数重算，不按当前总点数', () async {
    // 出生 5/7/5/5 = 22（资优 21-22），吃满生涯 cap +5 记在根骨上 → 当前 27。
    final founder = staleChar(
      name: '林青崖',
      attributes: attrs(10, 7, 5, 5),
      adventureBonus: 5,
    )..id = 42;
    await seedOldSave([founder]);

    final migrated = (await IsarSetup.instance.characters.get(42))!;
    expect(
      migrated.attributes.total,
      27,
      reason: '前置条件：当前总点数确实越出 rarity_distribution 上界 24',
    );
    expect(
      migrated.rarity,
      RarityTier.ziYou,
      reason: '出生 27−5=22 落资优区间 [21,22]；若误用当前 27 会被钳到 jueShi',
    );
    expect(
      GameRepository.instance.numbers.rarityForTotalPoints(27),
      RarityTier.jueShi,
      reason: '反向锚：证明选项 (b) 与 (c) 在本用例上真的分叉，断言有判别力',
    );
  });

  test('0.38 旧档：未吃奇遇的角色按自身总点数重算', () async {
    // 3/5/7/4 = 19（寻常 18-19），bonus 0 → 出生点数 = 当前总点数。
    final disciple = staleChar(
      name: '叶清',
      attributes: attrs(3, 5, 7, 4),
      adventureBonus: 0,
    )..id = 43;
    await seedOldSave([disciple]);

    final migrated = (await IsarSetup.instance.characters.get(43))!;
    expect(migrated.rarity, RarityTier.xunChang);
  });

  test('迁移只改档位标签，不动任何数值字段', () async {
    final founder = staleChar(
      name: '林青崖',
      attributes: attrs(10, 7, 5, 5),
      adventureBonus: 5,
    )..id = 44;
    await seedOldSave([founder]);

    final migrated = (await IsarSetup.instance.characters.get(44))!;
    expect(migrated.attributes.constitution, 10);
    expect(migrated.attributes.enlightenment, 7);
    expect(migrated.attributes.agility, 5);
    expect(migrated.attributes.fortune, 5);
    expect(migrated.attributeBonusFromAdventure, 5);
    expect(migrated.internalForce, 700);
    expect(migrated.internalForceMax, 3500);
    expect(migrated.name, '林青崖');
  });

  test('版本升到当前版本且迁移幂等（重开不再改动）', () async {
    final founder = staleChar(
      name: '林青崖',
      attributes: attrs(10, 7, 5, 5),
      adventureBonus: 5,
    )..id = 45;
    await seedOldSave([founder]);

    expect(
      (await IsarSetup.currentSaveData())!.saveVersion,
      IsarSetup.currentSaveVersion,
    );

    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    final again = (await IsarSetup.instance.characters.get(45))!;
    expect(again.rarity, RarityTier.ziYou);
    expect(again.attributes.total, 27);
  });

  test('新档角色（档位本就正确）迁移后不被改坏', () async {
    // 出生即 23（天才），无奇遇加点，rarity 已正确。
    final prodigy = staleChar(
      name: '沈砚',
      attributes: attrs(6, 6, 6, 5),
      adventureBonus: 0,
      staleRarity: RarityTier.tianCai,
    )..id = 46;
    await seedOldSave([prodigy]);

    final migrated = (await IsarSetup.instance.characters.get(46))!;
    expect(migrated.attributes.total, 23);
    expect(migrated.rarity, RarityTier.tianCai);
  });
}
