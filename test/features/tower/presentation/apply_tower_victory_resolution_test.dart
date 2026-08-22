import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_0a_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<int> insertCharacter(String name) {
    final character = Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 8, 22),
      internalForce: 3000,
    );
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(character),
    );
  }

  Future<void> writeSave(int founderId, int reserveId) {
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.0.1'
          ..createdAt = DateTime(2026, 8, 22)
          ..lastSavedAt = DateTime(2026, 8, 22)
          ..lastOnlineAt = DateTime(2026, 8, 22)
          ..activeCharacterIds = [founderId, reserveId]
          ..founderCharacterId = founderId,
      ),
    );
  }

  testWidgets('0A snapshot 只结算真实参战祖师，替补零污染', (tester) async {
    final ids = (await tester.runAsync(() async {
      final founderId = await insertCharacter('祖师');
      final reserveId = await insertCharacter('替补');
      await writeSave(founderId, reserveId);
      return (founderId, reserveId);
    }))!;
    final floor = GameRepository.instance.getTowerFloor(1);
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 37,
      hadActions: true,
      participants: [
        CombatParticipantSnapshot(
          characterId: ids.$1,
          currentHp: 7000,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 456,
      criticalCount: 3,
      damageByCharacterId: {ids.$1: 456},
    );

    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final result = await tester.runAsync(
      () => applyTowerVictoryResolution(
        ref: capturedRef!,
        floor: floor,
        isFirstClear: true,
        settlementSnapshot: settlement,
      ),
    );

    expect(result!.stats.totalDamage, 456);
    expect(result.stats.critCount, 3);
    expect(result.stats.totalTicks, 37);
    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(ids.$1);
      final reserve = await IsarSetup.instance.characters.get(ids.$2);
      expect(founder!.experience, floor.baseExpReward);
      expect(reserve!.experience, 0, reason: '未参战替补不得获得塔首通经验');
      expect(founder.lightInjuryStacks, 1);
      expect(reserve.lightInjuryStacks, 0, reason: '未参战替补不得累积连战伤势');
    });
  });
}
