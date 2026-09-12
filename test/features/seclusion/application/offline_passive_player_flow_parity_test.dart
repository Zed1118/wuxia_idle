import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

typedef _Snapshot = ({
  int material,
  int experience,
  int inventory,
  int experienceBalance,
  RealmTier tier,
  RealmLayer layer,
  double expFraction,
  double materialFraction,
});

void main() {
  final start = DateTime(2026, 9, 9, 10);

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  Future<_Snapshot> run(String mode, {bool crossesTier = false}) async {
    final directory = await Directory.systemTemp.createTemp('passive_parity_');
    var now = start;
    ProviderContainer? container;
    OnlinePresenceController? controller;

    void mount() {
      container = ProviderContainer(
        overrides: [
          onlinePresenceControllerProvider.overrideWith((ref) {
            final instance = OnlinePresenceController(
              ref,
              clock: () => now,
              heartbeatInterval: const Duration(milliseconds: 20),
            );
            ref.onDispose(instance.dispose);
            return instance;
          }),
        ],
      );
      controller = container!.read(onlinePresenceControllerProvider);
    }

    Future<void> waitForBaseline() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while ((await IsarSetup.currentSaveData())!.lastOnlineAt != now &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect((await IsarSetup.currentSaveData())!.lastOnlineAt, now);
    }

    Future<void> reopen() async {
      container?.dispose();
      container = null;
      await IsarSetup.close();
      await IsarSetup.init(directory: directory, inspector: false);
      mount();
    }

    try {
      await IsarSetup.init(directory: directory, inspector: false);
      final character = Character.create(
        name: 'passive parity fixture',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: start.subtract(const Duration(days: 1)),
        internalForce: 500,
      )..id = 1;
      if (crossesTier) {
        character.realmLayer = RealmLayer.dengFeng;
        character.experience =
            GameRepository.instance
                .getRealm(RealmTier.xueTu, RealmLayer.dengFeng)
                .experienceToNext -
            1;
      }
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.characters.put(character);
        final save = (await IsarSetup.currentSaveData())!;
        save.activeCharacterIds = [character.id];
        save.founderCharacterId = character.id;
        save.isOnboardingCompleted = true;
        save.createdAt = start.subtract(const Duration(days: 1));
        save.lastOnlineAt = start;
        save.passiveLastSettledAt = start;
        await IsarSetup.instance.saveDatas.put(save);
        if (crossesTier) {
          final cleared = GameRepository
              .instance
              .numbers
              .innerDemon
              .requiredRealmLayer
              .keys
              .toList();
          await IsarSetup.instance.mainlineProgress.put(
            MainlineProgress()
              ..saveDataId = save.slotId
              ..clearedStageIds = cleared
              ..clearedAt = cleared.map((_) => start).toList(),
          );
        }
      });
      await IsarSetup.touchOnlineNow(now: start);
      mount();

      switch (mode) {
        case 'closed':
          await reopen();
          now = start.add(const Duration(hours: 8));
          await controller!.settlePassiveWindow();
        case 'foreground':
          controller!.markStartupSettleDone();
          for (var hour = 1; hour <= 8; hour++) {
            now = start.add(Duration(hours: hour));
            await waitForBaseline();
          }
        case 'background':
          controller!.markStartupSettleDone();
          controller!.onAppBlurred();
          await Future<void>.delayed(const Duration(milliseconds: 30));
          now = start.add(const Duration(hours: 8));
          controller!.onAppFocused();
          await waitForBaseline();
        case 'repeated_blur':
          controller!.markStartupSettleDone();
          controller!.onAppBlurred();
          await Future<void>.delayed(const Duration(milliseconds: 30));
          now = start.add(const Duration(hours: 4));
          controller!.onAppBlurred();
          await Future<void>.delayed(Duration.zero);
          await IsarSetup.instance.writeTxn(() async {});
          now = start.add(const Duration(hours: 8));
          controller!.onAppFocused();
          await waitForBaseline();
        case 'hourly_restart':
          for (var hour = 1; hour <= 8; hour++) {
            now = start.add(Duration(hours: hour));
            await controller!.settlePassiveWindow();
            await reopen();
          }
        case 'minute_returns':
          for (var minute = 1; minute <= 480; minute++) {
            now = start.add(Duration(minutes: minute));
            await controller!.settlePassiveWindow();
          }
      }

      final save = (await IsarSetup.currentSaveData())!;
      final item = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_mojianshi',
      );
      final savedCharacter = (await IsarSetup.instance.characters.get(1))!;
      final snapshot = (
        material: save.totalPassiveMojianshi,
        experience: save.totalPassiveExperience,
        inventory: item?.quantity ?? 0,
        experienceBalance: savedCharacter.experience,
        tier: savedCharacter.realmTier,
        layer: savedCharacter.realmLayer,
        expFraction: savedCharacter.passiveExperienceRemainder,
        materialFraction: save.passiveMojianshiRemainder,
      );
      return snapshot;
    } finally {
      container?.dispose();
      await IsarSetup.close();
      await directory.delete(recursive: true);
    }
  }

  for (final crossesTier in [false, true]) {
    for (final mode in [
      'background',
      'foreground',
      'repeated_blur',
      'hourly_restart',
      'minute_returns',
    ]) {
      test(
        '8h $mode equals one closed interval (crosses tier: $crossesTier)',
        () async {
          final closed = await run('closed', crossesTier: crossesTier);
          expect(closed.tier, crossesTier ? RealmTier.sanLiu : RealmTier.xueTu);
          expect(closed.experience, crossesTier ? 37 : 24);
          expect(closed.material, crossesTier ? 3 : 2);
          final observed = await run(mode, crossesTier: crossesTier);
          expect(observed.experience, closed.experience);
          expect(observed.material, closed.material);
          expect(observed.inventory, closed.inventory);
          expect(observed.experienceBalance, closed.experienceBalance);
          expect(observed.tier, closed.tier);
          expect(observed.layer, closed.layer);
          expect(observed.expFraction, closeTo(closed.expFraction, 1e-7));
          expect(
            observed.materialFraction,
            closeTo(closed.materialFraction, 1e-7),
          );
        },
      );
    }
  }
}
