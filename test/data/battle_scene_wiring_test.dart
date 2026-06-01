import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

// biome → 背景文件名(与 design 映射表一致)
const _map = {
  EncounterBiome.mountainForest: 'battle_mountainforest',
  EncounterBiome.cityWall: 'battle_citywall',
  EncounterBiome.frontier: 'battle_frontier',
  EncounterBiome.drillGround: 'battle_drillground',
  EncounterBiome.dock: 'battle_dock',
  EncounterBiome.mountainPath: 'battle_mountainpath',
  EncounterBiome.innerRealm: 'battle_innerrealm',
  EncounterBiome.desert: 'battle_frontier',
  EncounterBiome.temple: 'battle_mountainforest',
  EncounterBiome.teaHouse: 'battle_citywall',
  EncounterBiome.inn: 'battle_citywall',
  EncounterBiome.alley: 'battle_citywall',
  EncounterBiome.smithy: 'battle_drillground',
  EncounterBiome.escortRoad: 'battle_mountainpath',
  EncounterBiome.cliffWaterfall: 'battle_mountainpath',
  EncounterBiome.bambooForest: 'battle_mountainforest',
};

void main() {
  late GameRepository repo;

  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDownAll(GameRepository.resetForTest);

  test('每个主线 stage 都有 sceneBackgroundPath 且按 biome 映射正确', () {
    for (final s in repo.stageDefs.values) {
      expect(s.sceneBackgroundPath, isNotNull, reason: '${s.id} 缺背景');
      if (s.biome != null) {
        final expected = 'assets/scenes/${_map[s.biome]}.png';
        expect(s.sceneBackgroundPath, expected, reason: '${s.id} 映射错');
      }
    }
  });

  test('所有 stage 背景路径 ∈ 7 张 battle_*.png', () {
    const valid = {
      'battle_mountainforest',
      'battle_citywall',
      'battle_frontier',
      'battle_drillground',
      'battle_dock',
      'battle_mountainpath',
      'battle_innerrealm',
    };
    for (final s in repo.stageDefs.values) {
      final name =
          s.sceneBackgroundPath!.split('/').last.replaceAll('.png', '');
      expect(valid.contains(name), isTrue, reason: '${s.id}: $name 非法');
    }
  });

  test('所有 tower floor 背景路径 == battle_innerrealm.png', () {
    expect(repo.towerFloors, hasLength(30));
    for (final f in repo.towerFloors) {
      expect(
        f.sceneBackgroundPath,
        'assets/scenes/battle_innerrealm.png',
        reason: 'floor ${f.floorIndex} 缺背景或映射错',
      );
    }
  });
}
