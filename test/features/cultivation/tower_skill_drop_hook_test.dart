import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/stage_skill_drop_hook.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

TowerFloorDef _bossFloor({String? fragment}) => TowerFloorDef(
      floorIndex: 10,
      requiredRealm: RealmTier.sanLiu,
      enemyTeam: const [],
      bossKind: TowerBossKind.major,
      dropSkillFragmentId: fragment,
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_drop_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('爬塔残页:prob=1.0 每次 Boss 胜利掉,集齐 5 次自动解锁(非首通限定)', () async {
    final svc = SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
    final floor = _bossFloor(fragment: 'skill_tower_frag');
    for (var i = 0; i < 5; i++) {
      await runTowerSkillDropHookAfterVictory(
        floor: floor,
        svc: svc,
        towerFragmentDropProb: 1.0,
        rng: Random(i),
      );
    }
    expect(await svc.isUnlocked('skill_tower_frag'), true);
  });

  test('爬塔残页:prob=0.0 不掉', () async {
    final svc = SkillUnlockService(IsarSetup.instance);
    final floor = _bossFloor(fragment: 'skill_tower_frag2');
    await runTowerSkillDropHookAfterVictory(
      floor: floor,
      svc: svc,
      towerFragmentDropProb: 0.0,
      rng: Random(0),
    );
    final (cur, _) = await svc.fragmentProgress('skill_tower_frag2');
    expect(cur, 0);
  });

  test('floor 无 dropSkillFragmentId → no-op', () async {
    final svc = SkillUnlockService(IsarSetup.instance);
    final floor = _bossFloor(fragment: null);
    await runTowerSkillDropHookAfterVictory(
      floor: floor,
      svc: svc,
      towerFragmentDropProb: 1.0,
      rng: Random(0),
    );
    // 不抛即可(无 fragment 不写)。
    expect(true, true);
  });
}
