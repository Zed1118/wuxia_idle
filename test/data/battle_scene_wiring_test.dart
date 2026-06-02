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
  EncounterBiome.desert: 'battle_desert',
  EncounterBiome.temple: 'battle_temple',
  EncounterBiome.teaHouse: 'battle_teahouse',
  EncounterBiome.inn: 'battle_inn',
  EncounterBiome.alley: 'battle_alley',
  EncounterBiome.smithy: 'battle_smithy',
  EncounterBiome.escortRoad: 'battle_escortroad',
  EncounterBiome.cliffWaterfall: 'battle_cliffwaterfall',
  EncounterBiome.bambooForest: 'battle_bambooforest',
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

  test('所有 stage 背景路径 ∈ biome 映射图集(单一真相源 _map)', () {
    // 白名单 = _map.values + tower 用 innerrealm, 不写死数字, 避免长尾扩图后 drift
    final valid = {..._map.values, 'battle_innerrealm'};
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
