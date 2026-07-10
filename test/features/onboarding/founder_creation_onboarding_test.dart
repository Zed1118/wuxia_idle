import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import "../../support/isar_test_support.dart";
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_founder_creation_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('generateFounderFateChoices 一次抽 3 份且不重复', () {
    final config = GameRepository.instance.founderCreation;
    final choices = generateFounderFateChoices(
      config: config,
      rng: DefaultRng(seed: 7),
    );

    expect(choices, hasLength(3));
    expect(choices.map((e) => e.id).toSet(), hasLength(3));
  });

  test('createFoundingMaster 写入命盘属性 / 起手主修 / 出身资源 / 履历 id', () async {
    final config = GameRepository.instance.founderCreation;
    final school = config.schools.firstWhere(
      (e) => e.school == TechniqueSchool.yinRou,
    );
    final origin = config.origins.firstWhere((e) => e.id == 'herb_hut_keeper');
    final fate = config.fatePool.firstWhere((e) => e.id == 'clear_mind');

    final didSeed = await OnboardingService(isar: IsarSetup.instance)
        .createFoundingMaster(
          selection: FounderCreationSelection(
            school: school,
            origin: origin,
            fate: fate,
          ),
        );

    expect(didSeed, true);
    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final founder = await isar.characters.get(save.founderCharacterId!);
    expect(founder, isNotNull);
    expect(save.activeCharacterIds, [founder!.id]);
    expect(founder.founderCreationSchoolId, school.id);
    expect(founder.founderCreationOriginId, origin.id);
    expect(founder.founderCreationFateId, fate.id);
    expect(founder.attributes.constitution, fate.attributeProfile.constitution);
    expect(
      founder.attributes.enlightenment,
      fate.attributeProfile.enlightenment,
    );
    expect(founder.attributes.agility, fate.attributeProfile.agility);
    expect(founder.attributes.fortune, fate.attributeProfile.fortune);

    final main = await isar.techniques.get(founder.mainTechniqueId!);
    expect(main!.defId, school.startingTechniqueIds.single);
    expect(founder.school, TechniqueSchool.yinRou);

    final weapon = await isar.equipments.get(founder.equippedWeaponId!);
    final armor = await isar.equipments.get(founder.equippedArmorId!);
    final accessory = await isar.equipments.get(founder.equippedAccessoryId!);
    expect([
      weapon!.defId,
      armor!.defId,
      accessory!.defId,
    ], school.startingEquipmentIds);
    expect(weapon.slot, EquipmentSlot.weapon);
    expect(armor.slot, EquipmentSlot.armor);
    expect(accessory.slot, EquipmentSlot.accessory);

    final mojianshi = await isar.inventoryItems
        .filter()
        .itemTypeEqualTo(ItemType.moJianShi)
        .findFirst();
    final jieJing = await isar.inventoryItems
        .filter()
        .itemTypeEqualTo(ItemType.xinXueJieJing)
        .findFirst();
    expect(mojianshi!.quantity, 50 + origin.mojianshiBonus);
    expect(jieJing!.quantity, origin.jieJingBonus);
  });

  test('ensureFoundingMasters 保持默认模板且不写创建选择 id', () async {
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final founder = await IsarSetup.instance.characters.get(
      save.founderCharacterId!,
    );
    expect(founder!.founderCreationSchoolId, isNull);
    expect(founder.founderCreationOriginId, isNull);
    expect(founder.founderCreationFateId, isNull);
  });

  test('自定义名 → founder.name / save.sectName', () async {
    final config = GameRepository.instance.founderCreation;
    final sel = FounderCreationSelection(
      school: config.schools.first,
      origin: config.origins.first,
      fate: config.fatePool.first,
      founderName: '慕容无咎',
      sectName: '青城派',
    );
    await OnboardingService(
      isar: IsarSetup.instance,
    ).createFoundingMaster(selection: sel);

    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final founder = await isar.characters.get(save.founderCharacterId!);
    expect(founder!.name, '慕容无咎');
    expect(save.sectName, '青城派');
  });

  test('留空 founderName/sectName 回退默认「祖师」「我的门派」', () async {
    final config = GameRepository.instance.founderCreation;
    final sel = FounderCreationSelection(
      school: config.schools.first,
      origin: config.origins.first,
      fate: config.fatePool.first,
    );
    await OnboardingService(
      isar: IsarSetup.instance,
    ).createFoundingMaster(selection: sel);

    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final founder = await isar.characters.get(save.founderCharacterId!);
    expect(founder!.name, '祖师');
    expect(save.sectName, '我的门派');
  });
}
