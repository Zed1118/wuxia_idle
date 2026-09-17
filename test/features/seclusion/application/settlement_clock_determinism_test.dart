import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service_providers.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

final _startedAt = DateTime(2026, 5, 11, 10);
final _completedAt = _startedAt.add(const Duration(hours: 72));

RetreatSession _session(int seedId) => RetreatSession()
  ..id = seedId
  ..saveDataId = 1
  ..mapType = RetreatMapType.shanLin
  ..durationHours = 0
  ..realmTierAtStart = RealmTier.xueTu
  ..startedAt = _startedAt
  ..status = RetreatStatus.active
  ..actualRewards = [];

Future<T> _withStore<T>(Future<T> Function() action) async {
  final directory = await Directory.systemTemp.createTemp('wuxia_clock_');
  await IsarSetup.init(directory: directory, inspector: false);
  try {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(
        Character.create(
          name: '时钟守卫',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.founder,
          createdAt: _startedAt,
          internalForce: 500,
        )..id = 1,
      );
      final save = (await IsarSetup.currentSaveData())!;
      save
        ..founderCharacterId = 1
        ..activeCharacterIds = [1]
        ..createdAt = _startedAt.subtract(const Duration(days: 1))
        ..lastSavedAt = _startedAt
        ..lastOnlineAt = _startedAt
        ..passiveLastSettledAt = _startedAt;
      await isar.saveDatas.put(save);
    });
    return await action();
  } finally {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  }
}

Future<Map<String, Object?>> _storedFields() async {
  final isar = IsarSetup.instance;
  return {
    'save': await isar.saveDatas.where().exportJson(),
    'characters': await isar.characters.where().exportJson(),
    'equipment': await isar.equipments.where().exportJson(),
    'techniques': await isar.techniques.where().exportJson(),
    'inventory': await isar.inventoryItems.where().exportJson(),
    'events': await isar.gameEvents.where().exportJson(),
    'sessions': await isar.retreatSessions.where().exportJson(),
    'encounters': await isar.encounterProgress.where().exportJson(),
  };
}

Map<String, Object?> _progressFields(RealmProgressDisplay value) => {
  'level': value.level,
  'experience': value.experience,
  'experienceToNext': value.experienceToNext,
  'progress': value.progress,
  'state': value.state.name,
};

Map<String, Object?> _resultFields(RetreatResult result) {
  final advancement = result.advancement;
  return {
    'elapsedHours': result.elapsedHours,
    'retreatHours': result.retreatHours,
    'passiveHours': result.passiveHours,
    'passive': result.passive,
    'actualHours': result.actualHours,
    'mojianshi': result.mojianshi,
    'silver': result.silver,
    'itemRewards': result.itemRewards,
    // 装备所有持久字段同时通过 _storedFields 的导出逐项比较。
    'equipmentDrops': [
      for (final equipment in result.equipmentDrops) equipment.id,
    ],
    'equipmentDropNodeHours': result.equipmentDropNodeHours,
    'realmTierAtStart': result.realmTierAtStart.name,
    'experiencePoints': result.experiencePoints,
    'techniqueLearnPoints': result.techniqueLearnPoints,
    'internalForcePoints': result.internalForcePoints,
    'routeSteps': result.routeSteps,
    'mapEvents': [
      for (final event in result.mapEvents)
        {
          'hourMark': event.hourMark,
          'kind': event.kind.name,
          'text': event.text,
        },
    ],
    'advancement': advancement == null
        ? null
        : {
            'layersGained': advancement.layersGained,
            'tierBefore': advancement.tierBefore.name,
            'layerBefore': advancement.layerBefore.name,
            'tierAfter': advancement.tierAfter.name,
            'layerAfter': advancement.layerAfter.name,
            'internalForceMaxBefore': advancement.internalForceMaxBefore,
            'internalForceMaxAfter': advancement.internalForceMaxAfter,
            'experienceGained': advancement.experienceGained,
            'progressBefore': _progressFields(
              advancement.progressChange.before,
            ),
            'progressAfter': _progressFields(advancement.progressChange.after),
          },
  };
}

Future<Map<String, Object?>> _settlePassive(DateTime at) => _withStore(
  () async {
    final container = ProviderContainer(
      overrides: [systemClockProvider.overrideWithValue(SystemClock.fixed(at))],
    );
    try {
      // 读取真实生产 provider，不覆盖控制器，也不直接传入 now。
      final yielded = await container
          .read(onlinePresenceControllerProvider)
          .settlePassiveWindow();
      expect((await IsarSetup.currentSaveData())!.lastOnlineAt, at);
      return {'yield': yielded, 'stored': await _storedFields()};
    } finally {
      container.dispose();
    }
  },
);

Future<Map<String, Object?>> _settleRetreat(
  int seedId,
  DateTime at,
) => _withStore(() async {
  final session = _session(seedId);
  final isar = IsarSetup.instance;
  await isar.writeTxn(() async {
    await isar.retreatSessions.put(session);
    final character = (await isar.characters.get(1))!;
    character.currentRetreatSessionId = session.id;
    await isar.characters.put(character);
  });
  final container = ProviderContainer(
    overrides: [systemClockProvider.overrideWithValue(SystemClock.fixed(at))],
  );
  try {
    final result = await container
        .read(seclusionServiceProvider)!
        .completeRetreat(
          session: session,
          characterId: 1,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: container.read(systemClockProvider).now(),
        );
    final events = await isar.gameEvents.where().findAll();
    expect(events, isNotEmpty);
    expect(events.every((event) => event.occurredAt == at), isTrue);
    final encounters = await isar.encounterProgress.where().findAll();
    expect(encounters, isNotEmpty);
    expect(encounters.every((entry) => entry.createdAt == at), isTrue);
    return {'result': _resultFields(result), 'stored': await _storedFields()};
  } finally {
    container.dispose();
  }
});

void main() {
  late int hitSeedId;
  late int missSeedId;
  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
    final repository = GameRepository.instance;
    final dropService = DropService(
      equipmentDefLookup: repository.getEquipment,
      now: () => _completedAt,
    );
    bool hasDrop(int id) => SeclusionService.computeOutputs(
      session: _session(id),
      charRealmTier: RealmTier.xueTu,
      config: repository.numbers.retreat,
      maps: repository.seclusionMaps,
      now: _completedAt,
      dropService: dropService,
    ).equipmentDrops.isNotEmpty;
    // 闭关种子来自持久会话输入，保留现有 session/node seed 算法。
    final candidates = List.generate(1000, (index) => index + 1);
    hitSeedId = candidates.firstWhere(hasDrop);
    missSeedId = candidates.firstWhere((id) => !hasDrop(id));
  });

  test('真实被动积分 provider 消费固定时钟，重放全部持久字段一致', () async {
    final at = _startedAt.add(const Duration(hours: 8));
    final first = await _settlePassive(at);
    expect(await _settlePassive(at), first);
    final changed = await _settlePassive(at.add(const Duration(hours: 8)));
    expect(changed['yield'], isNot(first['yield']));
  });

  test('固定时钟和会话种子完整闭关两次结果及持久字段相同', () async {
    final first = await _settleRetreat(hitSeedId, _completedAt);
    expect(await _settleRetreat(hitSeedId, _completedAt), first);
    expect((first['stored']! as Map)['equipment'], isNotEmpty);
  });

  test('改变闭关结算时钟会改变结果，事件时间仍为同一结算时刻', () async {
    final first = await _settleRetreat(hitSeedId, _completedAt);
    final changed = await _settleRetreat(
      hitSeedId,
      _completedAt.add(const Duration(hours: 8)),
    );
    expect(changed['result'], isNot(first['result']));
  });

  test('改变会话种子输入确实改变装备掉落，非只改变会话编号', () async {
    final hit = await _settleRetreat(hitSeedId, _completedAt);
    final miss = await _settleRetreat(missSeedId, _completedAt);
    expect((hit['stored']! as Map)['equipment'], isNotEmpty);
    expect((miss['stored']! as Map)['equipment'], isEmpty);
  });
}
