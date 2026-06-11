import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

void main() {
  tearDown(GameRepository.resetForTest);

  test('TowerFloorDef.fromYaml 解析 dropSkillFragmentId(无 → null)', () {
    final f = TowerFloorDef.fromYaml({
      'floorIndex': 1,
      'requiredRealm': 'xueTu',
      'enemyTeam': const [],
      'baseExpReward': 80,
    });
    expect(f.dropSkillFragmentId, isNull);

    final f2 = TowerFloorDef.fromYaml({
      'floorIndex': 10,
      'requiredRealm': 'sanLiu',
      'enemyTeam': const [],
      'bossKind': 'major',
      'dropSkillFragmentId': 'skill_frag_x',
    });
    expect(f2.dropSkillFragmentId, 'skill_frag_x');
  });

  Future<String> Function(String) towerLoader(
      String Function(String) transform) {
    Future<String> loader(String path) async {
      final original = await File(path).readAsString();
      if (path == 'data/towers.yaml') return transform(original);
      return original;
    }
    return loader;
  }

  test('正例:production towers 加载不抛', () async {
    await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    expect(GameRepository.isLoaded, true);
  });

  test('① 非 Boss 层配 dropSkillFragmentId → 抛 StateError', () async {
    // floor 1 是普通层(bossKind null);注入 dropSkillFragmentId。
    String inject(String s) => s.replaceFirst(
          '  - floorIndex: 1\n',
          '  - floorIndex: 1\n    dropSkillFragmentId: skill_gangmeng_mingjia_ult\n',
        );
    expect(
      GameRepository.loadAllDefs(loader: towerLoader(inject)),
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', contains('非 Boss'))),
    );
  });

  test('② Boss 层配不存在的 dropSkillFragmentId → 抛 StateError', () async {
    // floor 10 现配 dropSkillFragmentId: skill_yan_zi_san_chao(波B);替为幽灵 id。
    String inject(String s) => s.replaceFirst(
          'dropSkillFragmentId: skill_yan_zi_san_chao',
          'dropSkillFragmentId: ghost_frag_not_loaded',
        );
    expect(
      GameRepository.loadAllDefs(loader: towerLoader(inject)),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('ghost_frag_not_loaded'))),
    );
  });
}
