// Run explicitly with flutter test and M4_PROFILE_SAVE_ROOT set to a new,
// isolated evidence directory. This tool never opens an application container.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../test/support/isar_test_support.dart';
import '../test/support/mainline_onboarding_harness.dart'
    show onboardingFounderSeed;
import '../test/support/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('prepare isolated legal and engineering profile saves', () async {
    final path = Platform.environment['M4_PROFILE_SAVE_ROOT'];
    if (path == null || !path.startsWith('/')) {
      throw StateError(
        'M4_PROFILE_SAVE_ROOT must be a new absolute directory.',
      );
    }
    final root = Directory(path);
    final parent = await root.parent.resolveSymbolicLinks();
    if (parent.contains('/Library/Containers/') ||
        parent.endsWith('/Library/Containers') ||
        await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      throw StateError(
        'Existing paths and application containers are forbidden.',
      );
    }
    await root.create();
    await initializeTestIsarCore();
    await loadTestGameRepository();
    final config = GameRepository.instance.founderCreation;
    final receipts = <Map<String, Object?>>[];
    for (final engineering in [false, true]) {
      final directory = Directory(
        '${root.path}/${engineering ? 'engineering' : 'legal'}',
      );
      await directory.create();
      try {
        await IsarSetup.init(directory: directory, inspector: false);
        expect(
          await OnboardingService(
            isar: IsarSetup.instance,
            rng: DefaultRng(seed: onboardingFounderSeed),
          ).createFoundingMaster(
            selection: FounderCreationSelection(
              school: config.schools.singleWhere((s) => s.id == 'gang_meng'),
              origin: config.origins.singleWhere(
                (s) => s.id == 'mountain_wanderer',
              ),
              fate: config.fatePool.singleWhere((s) => s.id == 'balanced_seed'),
            ),
          ),
          isTrue,
        );
        if (engineering) {
          await Phase2SeedService(
            isar: IsarSetup.instance,
          ).seedVisualCheckShenwuDrop();
        }
        final isar = IsarSetup.instance;
        final save = (await isar.saveDatas.where().findAll()).single;
        final characters = await isar.characters.where().findAll();
        final equipment = await isar.equipments.where().findAll();
        receipts.add({
          'directory': directory.path,
          'legal_character': !engineering,
          'purpose': engineering
              ? 'M4 performance only; never M2'
              : 'legal founding master',
          'source': engineering
              ? 'OnboardingService.createFoundingMaster + Phase2SeedService.seedVisualCheckShenwuDrop'
              : 'OnboardingService.createFoundingMaster',
          'founder_seed': onboardingFounderSeed,
          'founder_character_id': save.founderCharacterId,
          'active_character_ids': save.activeCharacterIds,
          'save_version': IsarSetup.currentSaveVersion,
          'characters': [
            for (final character in characters)
              {
                'id': character.id,
                'realm':
                    '${character.realmTier.name}/${character.realmLayer.name}',
                'internal_force': character.internalForce,
                'main_technique_id': character.mainTechniqueId,
                'equipped_ids': [
                  character.equippedWeaponId,
                  character.equippedArmorId,
                  character.equippedAccessoryId,
                ],
              },
          ],
          'equipment': [
            for (final item in equipment)
              {
                'id': item.id,
                'def_id': item.defId,
                'owner': item.ownerCharacterId,
              },
          ],
        });
      } finally {
        if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
      }
      expect(
        File('${directory.path}/wuxia_save_slot1.isar').existsSync(),
        isTrue,
      );
    }
    await File('${root.path}/manifest.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(receipts)}\n',
    );
  });
}
