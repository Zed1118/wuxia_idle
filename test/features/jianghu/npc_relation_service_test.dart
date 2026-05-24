import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu/application/npc_relation_service.dart';

/// P1.2 §3 NpcRelationService 红线契约。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('wuxia_npc_relation_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('upsert', () {
    test('新建 + 双向 (source, target) 隔离', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -60);
      final rels = await svc.allFor(1);
      expect(rels.length, 1);
      expect(rels.first.targetCharacterId, 10);
      expect(rels.first.type, 'foe');
      expect(rels.first.level, -60);
    });

    test('更新已有 (同 source+target) → 不新建', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -60);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -85);
      final rels = await svc.allFor(1);
      expect(rels.length, 1, reason: 'upsert 同 (source,target) 不应新建第二行');
      expect(rels.first.level, -85);
    });

    test('level clamp [-100, +100] 入仓', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 99,
          type: 'foe',
          level: -200);
      final rels = await svc.allFor(1);
      expect(rels.first.level, -100);
    });
  });

  group('enmityAgainst', () {
    test('过滤 type=foe + level ≤ threshold(-50)', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -60); // hit
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 11,
          type: 'foe',
          level: -49); // miss(level too high)
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 12,
          type: 'friend',
          level: -70); // miss(type)
      await svc.upsert(
          sourceCharacterId: 2,
          targetCharacterId: 13,
          type: 'foe',
          level: -100); // miss(source)
      final foes = await svc.enmityAgainst(1);
      expect(foes.length, 1);
      expect(foes.first.targetCharacterId, 10);
    });
  });

  group('attackPowerMultFor 三档(R5.2)', () {
    test('无关系 → 1.0', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      expect(await svc.attackPowerMultFor(1, 999), 1.0);
    });

    test('level=-49 → 1.0(刚高于阈值)', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -49);
      expect(await svc.attackPowerMultFor(1, 10), 1.0);
    });

    test('level=-50 → 1.15(临界 hit threshold)', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -50);
      expect(await svc.attackPowerMultFor(1, 10), 1.15);
    });

    test('level=-51 → 1.15', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -51);
      expect(await svc.attackPowerMultFor(1, 10), 1.15);
    });

    test('level=-80 → 1.25(临界 hit severe)', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -80);
      expect(await svc.attackPowerMultFor(1, 10), 1.25);
    });

    test('level=-100 → 1.25(severe clamp_max)', () async {
      final svc = NpcRelationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.upsert(
          sourceCharacterId: 1,
          targetCharacterId: 10,
          type: 'foe',
          level: -100);
      expect(await svc.attackPowerMultFor(1, 10), 1.25,
          reason: '§5.4 红线 clamp_max=1.25 防越');
    });
  });
}
