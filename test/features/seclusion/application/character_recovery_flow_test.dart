import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  final start = DateTime(2026, 9, 22, 8);
  late Directory directory;
  late Isar isar;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recovery_flow_');
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      for (final id in [1, 2, 3, 4]) {
        await isar.characters.put(
          Character.create(
            name: 'role_$id',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: id == 2 ? LineageRole.disciple : LineageRole.founder,
            createdAt: start,
            isFounder: id != 2,
            isAlive: id != 4,
            injuryHoursRemaining: 8,
            innerBreathDisorderHoursRemaining: 6,
            lightInjuryStacks: 3,
          )..id = id,
        );
      }
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = 1;
      save.activeCharacterIds = [1];
      save.createdAt = start.subtract(const Duration(days: 1));
      save.lastOnlineAt = start;
      save.passiveLastSettledAt = start;
      await isar.saveDatas.put(save);
    });
  });
  tearDown(() async {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  Future<void> settle(int minutes) => OfflinePassiveService.settleWindow(
    isar: isar,
    now: start.add(Duration(minutes: minutes)),
    updatePresence: true,
  );

  for (final mode in ['foreground', 'offline', 'restart']) {
    test('掌门、非出战门人和旧掌门按相同真实时间恢复：$mode', () async {
      if (mode == 'foreground') {
        for (var minute = 1; minute <= 120; minute++) {
          await settle(minute);
        }
      } else if (mode == 'restart') {
        await settle(60);
        await IsarSetup.close();
        await IsarSetup.init(directory: directory, inspector: false);
        isar = IsarSetup.instance;
        await settle(120);
      } else {
        await settle(120);
      }

      for (final id in [1, 2, 3]) {
        final character = (await isar.characters.get(id))!;
        expect(character.injuryHoursRemaining, closeTo(6, 1e-9));
        expect(character.innerBreathDisorderHoursRemaining, closeTo(4, 1e-9));
        expect(character.lightInjuryStacks, 3, reason: '自然疗养不能清掉连战轻伤');
        expect(character.experience, id == 1 ? 6 : 0, reason: '门人的疗养与掌门资源收益分开');
      }
      final dead = (await isar.characters.get(4))!;
      expect(dead.injuryHoursRemaining, 8);
      expect(dead.innerBreathDisorderHoursRemaining, 6);
      expect(dead.isAlive, isFalse);
      await settle(120);
      expect(
        (await isar.characters.get(2))!.injuryHoursRemaining,
        closeTo(6, 1e-9),
        reason: '同刻重试不重复扣时间',
      );
    });
  }

  for (final heartbeat in [false, true]) {
    test('闭关中其他门人持续疗养，收功不重复恢复（心跳=$heartbeat）', () async {
      final service = SeclusionService(isar: isar);
      final session = await service.startRetreat(
        mapType: RetreatMapType.shanLin,
        saveDataId: 1,
        characterId: 1,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: start,
      );
      if (heartbeat) {
        await settle(60);
        await settle(120);
        expect((await isar.characters.get(1))!.injuryHoursRemaining, 6);
        expect((await isar.characters.get(2))!.injuryHoursRemaining, 6);
      }
      await service.completeRetreat(
        session: session,
        characterId: 1,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 3)),
      );
      final owner = (await isar.characters.get(1))!;
      expect(owner.injuryHoursRemaining, 5);
      expect(owner.innerBreathDisorderHoursRemaining, 3);
      expect(owner.lightInjuryStacks, 0);
      final disciple = (await isar.characters.get(2))!;
      expect(disciple.injuryHoursRemaining, 5);
      expect(disciple.innerBreathDisorderHoursRemaining, 3);
      expect(disciple.lightInjuryStacks, 3);
      expect(disciple.experience, 0);
    });
  }
}
