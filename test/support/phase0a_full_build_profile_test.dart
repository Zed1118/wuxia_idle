// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import 'isar_test_support.dart';
import 'phase0a_full_build_profile.dart';

/// 满 build 画像夹具自检（派单包 B 目标 1）。
///
/// 钉死夹具确实产出「武圣·登峰 + 神物满强化满共鸣满开锋 + 传说神功极境主修 +
/// 辅修配满」的终局构筑，且三流派程序化选取的武器/主修 id 互不相同、装备派生
/// 攻击越过基础表值红线 2000（派生值放行，配置基础表值仍受 §5.4 硬守）。
void main() {
  late GameRepository repo;
  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('满 build 画像夹具：三流派均达终局构筑且选取互不相同', () async {
    final weaponIds = <String>{};
    final mainTechniqueIds = <String>{};

    for (final school in TechniqueSchool.values) {
      final directory = await Directory.systemTemp.createTemp(
        'phase0a_fb_selfcheck_',
      );
      try {
        await IsarSetup.init(directory: directory, inspector: false);
        final profile = await seedPhase0aFullBuildProfile(
          isar: IsarSetup.instance,
          school: school,
        );
        final snapshot = profile.snapshot;

        // 境界 = 武圣·登峰，强化 = 上限，绝对等级 49。
        expect(snapshot.realmTier, RealmTier.wuSheng);
        expect(snapshot.realmLayer, RealmLayer.dengFeng);
        expect(profile.enhanceLevel, profile.maxEnhanceLevel);
        expect(profile.enhanceLevel, 49);
        expect(profile.absoluteRealmLevel, 49);

        // 主修 = 传说神功 + 极境；本流派。
        final mainDef = repo.techniqueDefs[profile.mainTechniqueDefId]!;
        expect(mainDef.tier, TechniqueTier.chuanShuoShenGong);
        expect(mainDef.school, school);
        expect(snapshot.mainCultivationLayer, CultivationLayer.jiJing);

        // 辅修配满生产上限（3）且全本流派、不含主修。
        expect(profile.assistTechniqueDefIds, hasLength(3));
        for (final assistId in profile.assistTechniqueDefIds) {
          final assistDef = repo.techniqueDefs[assistId]!;
          expect(assistDef.school, school);
          expect(assistId, isNot(profile.mainTechniqueDefId));
        }

        // 三槽神物：def 阶 = shenWu；武器属本流派。
        final weaponDef = repo.equipmentDefs[profile.weaponDefId]!;
        final armorDef = repo.equipmentDefs[profile.armorDefId]!;
        final accessoryDef = repo.equipmentDefs[profile.accessoryDefId]!;
        expect(weaponDef.tier, EquipmentTier.shenWu);
        expect(armorDef.tier, EquipmentTier.shenWu);
        expect(accessoryDef.tier, EquipmentTier.shenWu);
        expect(weaponDef.schoolBias, school);

        // 落库装备实例：神物阶 + 满强化 + 心剑通灵共鸣（最高段）。
        final character = await IsarSetup.instance.characters.get(1);
        final equippedWeapon = await IsarSetup.instance.equipments.get(
          character!.equippedWeaponId!,
        );
        expect(equippedWeapon!.tier, EquipmentTier.shenWu);
        expect(equippedWeapon.enhanceLevel, profile.maxEnhanceLevel);
        expect(
          equippedWeapon.resonanceStage(repo.numbers),
          ResonanceStage.xinJianTongLing,
        );
        // 快照层佐证最高共鸣：心剑通灵附带剑鸣特效。
        expect(snapshot.swordSongResonanceActive, isTrue);

        // 装备派生攻击越过基础表值红线 2000（派生值放行，非配置基础值）。
        expect(
          snapshot.totalEquipmentAttack,
          greaterThan(2000),
          reason: '满 build 派生装备攻击应远超基础表值红线 2000',
        );

        weaponIds.add(profile.weaponDefId);
        mainTechniqueIds.add(profile.mainTechniqueDefId);

        print(
          '[满build自检] ${school.name}: weapon=${profile.weaponDefId} '
          'armor=${profile.armorDefId} accessory=${profile.accessoryDefId} '
          'main=${profile.mainTechniqueDefId} '
          'assists=${profile.assistTechniqueDefIds.join("|")} '
          'enhance=+${profile.enhanceLevel} '
          'eqAtk=${snapshot.totalEquipmentAttack} '
          'hp=${snapshot.maxHp} speed=${snapshot.speed}',
        );
      } finally {
        await IsarSetup.close();
        await directory.delete(recursive: true);
      }
    }

    // 三流派程序化选取的武器 / 主修 id 互不相同。
    expect(weaponIds, hasLength(3));
    expect(mainTechniqueIds, hasLength(3));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
