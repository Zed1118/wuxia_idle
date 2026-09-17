import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/lore_loader.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/event/application/game_event_service.dart';
import 'package:wuxia_idle/features/equipment/application/milestone_grant_hook.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// 每次读取前进一步，守住原有的取时次数与批量写入共用时刻。
class _SteppingClock extends SystemClock {
  _SteppingClock(this.start);

  final DateTime start;
  int calls = 0;

  @override
  DateTime now() => start.add(Duration(seconds: calls++));
}

class _MaximumRng implements Rng {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return max - 1;
  }

  @override
  double nextDouble() => throw StateError('装备属性只应使用整数随机源');

  @override
  T pick<T>(List<T> list) => list[nextInt(list.length)];
}

Equipment _equipment(String id, DateTime at) => Equipment.create(
  defId: id,
  tier: EquipmentTier.xunChang,
  slot: EquipmentSlot.weapon,
  obtainedAt: at,
  obtainedFrom: '测试结算',
);

Character _character(DateTime at) => Character.create(
  name: '试客',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  attributes: Attributes(),
  rarity: RarityTier.biaoZhun,
  lineageRole: LineageRole.founder,
  createdAt: at,
);

void main() {
  late Directory directory;
  final at = DateTime(2026, 9, 16, 20);

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('settlement_clock_');
    await IsarSetup.init(directory: directory, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  test('五类结算事件与装备轶事使用注入时钟并保持原取时顺序', () async {
    final isar = IsarSetup.instance;
    final clock = _SteppingClock(at);
    final service = GameEventService(
      isar,
      clock: clock,
      random: Random(1),
      loreLoader: (id) async => LoreContent.placeholder(id),
    );
    final first = _equipment('clock_first', at);
    final second = _equipment('clock_second', at);
    await isar.writeTxn(() async {
      await isar.equipments.putAll([first, second]);
      await service.recordRetreatCompleted(
        characterId: 1,
        characterName: '试客',
        actualHours: 1,
        mapName: '山林',
      );
      await service.recordEquipmentObtained(
        characterId: 1,
        equipmentId: first.id,
        equipmentDefId: first.defId,
        equipmentName: '试剑',
        source: '山林',
        equipment: first,
      );
      await service.recordRealmBreakthrough(
        character: _character(at),
        result: const AdvancementResult(
          layersGained: 1,
          tierBefore: RealmTier.xueTu,
          layerBefore: RealmLayer.qiMeng,
          tierAfter: RealmTier.xueTu,
          layerAfter: RealmLayer.ruMen,
          internalForceMaxBefore: 100,
          internalForceMaxAfter: 200,
        ),
      );
      await service.recordResonanceUpgraded(
        characterId: 1,
        equipmentId: first.id,
        equipmentName: '试剑',
        newStage: 2,
      );
      await service.recordBossDefeated(
        characterId: 1,
        stageId: 'stage_01_05',
        stageName: '山林',
        bossName: '山匪',
        warbornEquipment: [first, second],
      );
    });

    final events = await isar.gameEvents.where().findAll();
    expect(events.map((event) => event.eventType), [
      GameEventType.retreatCompleted,
      GameEventType.equipmentObtained,
      GameEventType.realmBreakthrough,
      GameEventType.resonanceUpgraded,
      GameEventType.bossDefeated,
    ]);
    expect(events.map((event) => event.occurredAt), [
      for (final second in [0, 1, 3, 4, 5]) at.add(Duration(seconds: second)),
    ]);
    expect(first.lores.map((lore) => lore.addedAt), [
      at.add(const Duration(seconds: 2)),
      at.add(const Duration(seconds: 6)),
    ]);
    expect(second.lores.single.addedAt, at.add(const Duration(seconds: 6)));
    expect(
      (await isar.equipments.get(first.id))!.lores.map((lore) => lore.addedAt),
      first.lores.map((lore) => lore.addedAt),
    );
    expect(clock.calls, 7);
  });

  test('没有突破时不读取注入时钟也不写事件', () async {
    final isar = IsarSetup.instance;
    final clock = _SteppingClock(at);
    await isar.writeTxn(
      () => GameEventService(isar, clock: clock).recordRealmBreakthrough(
        character: _character(at),
        result: const AdvancementResult(
          layersGained: 0,
          tierBefore: RealmTier.xueTu,
          layerBefore: RealmLayer.qiMeng,
          tierAfter: RealmTier.xueTu,
          layerAfter: RealmLayer.qiMeng,
          internalForceMaxBefore: 100,
          internalForceMaxAfter: 100,
        ),
      ),
    );
    expect(clock.calls, 0);
    expect(await isar.gameEvents.count(), 0);
  });

  test('塔新建与懒补发各读取一次时钟，复用进度不取时', () async {
    final isar = IsarSetup.instance;
    final clock = _SteppingClock(at);
    final service = TowerProgressService(isar: isar);
    final progress = await service.getOrCreate(saveDataId: 1, clock: clock);
    expect(progress.createdAt, at);
    expect(clock.calls, 1);

    final reused = await service.getOrCreate(saveDataId: 1, clock: clock);
    expect(reused.id, progress.id);
    expect(clock.calls, 1);

    await isar.writeTxn(() async {
      progress.highestClearedFloor =
          TowerProgressService.ticketMilestoneFloors.first;
      await isar.towerProgress.put(progress);
    });
    await service.getOrCreate(saveDataId: 1, clock: clock);
    final ticket = await isar.inventoryItems.getByDefId('item_duanhuntie');
    expect(ticket, isNotNull);
    expect(ticket!.quantity, 1);
    expect(ticket.firstObtainedAt, at.add(const Duration(seconds: 1)));
    expect(ticket.lastObtainedAt, ticket.firstObtainedAt);
    expect(clock.calls, 2);

    await service.getOrCreate(saveDataId: 1, clock: clock);
    expect(clock.calls, 2);
    expect(
      (await isar.inventoryItems.getByDefId('item_duanhuntie'))!.quantity,
      1,
    );
  });

  test('里程碑事务入口透传独立时钟与随机源，重复授予不再消费', () async {
    final isar = IsarSetup.instance;
    final clock = _SteppingClock(at);
    final rng = _MaximumRng();
    final granted = await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      return grantMilestoneForClearedStageInTxn(
        isar: isar,
        save: save,
        clearedStageId: 'stage_mass_battle_05',
        clock: clock,
        rng: rng,
      );
    });
    expect(granted, ['armor_special_bai_zhan_jia']);
    final equipment = (await isar.equipments.where().findAll()).single;
    final definition = GameRepository.instance.getEquipment(equipment.defId);
    expect(equipment.obtainedAt, at);
    expect(equipment.baseAttack, definition.baseAttackMax);
    expect(equipment.baseHealth, definition.baseHealthMax);
    expect(equipment.baseSpeed, definition.baseSpeedMax);
    expect(rng.calls, greaterThan(0));
    expect(clock.calls, 1);
    final previousCalls = rng.calls;

    final repeated = await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      return grantMilestoneForClearedStageInTxn(
        isar: isar,
        save: save,
        clearedStageId: 'stage_mass_battle_05',
        clock: clock,
        rng: rng,
      );
    });
    expect(repeated, isEmpty);
    expect(await isar.equipments.count(), 1);
    expect(clock.calls, 1);
    expect(rng.calls, previousCalls);
  });

  test('里程碑事务入口未注入时保留系统时钟与原随机范围', () async {
    final isar = IsarSetup.instance;
    final before = DateTime.now();
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      await grantMilestoneForClearedStageInTxn(
        isar: isar,
        save: save,
        clearedStageId: 'stage_mass_battle_05',
      );
    });
    final after = DateTime.now();
    final equipment = (await isar.equipments.where().findAll()).single;
    final definition = GameRepository.instance.getEquipment(equipment.defId);
    expect(equipment.obtainedAt.isBefore(before), isFalse);
    expect(equipment.obtainedAt.isAfter(after), isFalse);
    expect(
      equipment.baseAttack,
      inInclusiveRange(definition.baseAttackMin, definition.baseAttackMax),
    );
    expect(
      equipment.baseHealth,
      inInclusiveRange(definition.baseHealthMin, definition.baseHealthMax),
    );
    expect(
      equipment.baseSpeed,
      inInclusiveRange(definition.baseSpeedMin, definition.baseSpeedMax),
    );
  });

  test('奇遇进度仅首次创建读取时钟', () async {
    final clock = _SteppingClock(at);
    final service = EncounterService(isar: IsarSetup.instance);
    final first = await service.getOrCreate(saveDataId: 1, clock: clock);
    final second = await service.getOrCreate(saveDataId: 1, clock: clock);
    expect(first.createdAt, at);
    expect(second.createdAt, at);
    expect(second.id, first.id);
    expect(clock.calls, 1);
  });
}
