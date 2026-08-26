import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

const _grid1Skip = '本断言实测 FAIL,证据见报告第 1 格：生产端不存在高/低特效密度设置入口';
const _grid2Skip = '本断言实测 FAIL,证据见报告第 2 格：无法构造唯一差异为特效密度的生产 run';
const _grid3Skip = '本断言实测 FAIL,证据见报告第 3 格：无高/低特效生产 run 可生成逐 tick 摘要';
const _grid4Skip = '本断言实测 FAIL,证据见报告第 4 格：生产配置缺少塔 14/群战 18/24 active 密度目标';

List<File> _dartFiles(Iterable<String> roots) {
  final files = <File>[];
  for (final root in roots) {
    files.addAll(
      Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    );
  }
  return files..sort((a, b) => a.path.compareTo(b.path));
}

String _sources(Iterable<File> files) =>
    files.map((file) => file.readAsStringSync()).join('\n');

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('阻塞事实：现有闪烁偏好未接入战斗，且无特效密度入口', () {
    final settingsDomain = File(
      'lib/features/settings/domain/gameplay_settings.dart',
    ).readAsStringSync();
    final settingsSources = _sources(
      _dartFiles(const ['lib/features/settings']),
    );
    final battleSources = _sources(
      _dartFiles(const [
        'lib/features/battle',
        'lib/features/mainline',
        'lib/features/mass_battle',
        'lib/features/tower',
      ]),
    );
    final allProductionSources = _sources(_dartFiles(const ['lib']));

    expect(settingsDomain, contains('final bool reduceFlashing;'));
    expect(settingsSources, contains('gameplaySettingsProvider'));
    expect(battleSources, isNot(contains('reduceFlashing')));
    for (final absentSymbol in const [
      'EffectDensity',
      'effectDensity',
      'VfxDensity',
      'vfxDensity',
      'lowEffects',
      'lowEffectDensity',
    ]) {
      expect(
        allProductionSources,
        isNot(contains(absentSymbol)),
        reason: '出现 $absentSymbol 后应重写本 BLOCKED 证据并解除对应 skip',
      );
    }

    // ignore: avoid_print
    print(
      '[N15][ENTRY] reduceFlashing=settings-only; '
      'reduceFlashing-battle-consumers=0; effect-density-symbols=0',
    );
  });

  test('阻塞事实：现有塔14与群战映射量不是 14/18/24 active 密度配置', () {
    final numbers = repo.numbers;
    final player = testCombatantSnapshot(includeProductionBasicAttack: true);
    final floor = repo.getTowerFloor(14);
    final towerMapping = Phase0aStageContentMapper.mapTower(
      floor: floor,
      playerSnapshot: player,
      numbers: numbers,
    );
    final massStages =
        repo.stageDefs.values
            .where((stage) => stage.massBattleEnemyCounts?.isNotEmpty ?? false)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final configuredMassWaves = <String, List<int>>{};
    final mappedMassWaves = <String, List<int>>{};
    for (final stage in massStages) {
      final mapping = Phase0aStageContentMapper.mapMassBattle(
        stage: stage,
        playerSnapshot: player,
        numbers: numbers,
      );
      configuredMassWaves[stage.id] = stage.massBattleEnemyCounts!;
      mappedMassWaves[stage.id] = [
        for (final wave in mapping.waves) wave.enemies.length,
      ];
    }

    expect(
      towerMapping.waves.single.enemies,
      hasLength(floor.enemyTeam.length),
    );
    expect(mappedMassWaves, configuredMassWaves);
    final activeCounts = mappedMassWaves.values
        .expand((waves) => waves)
        .toSet();
    expect(activeCounts, isNotEmpty);

    final totals = <String, int>{
      for (final entry in configuredMassWaves.entries)
        entry.key: entry.value.fold(0, (sum, count) => sum + count),
    };
    // ignore: avoid_print
    print(
      '[N15][DENSITY] tower-floor-14 configured=${floor.enemyTeam.length} '
      'mapped=${towerMapping.waves.single.enemies.length}; '
      'mass-waves=$configuredMassWaves; mass-totals=$totals; '
      'active-counts=$activeCounts',
    );
  });

  test('第 1 格：高/低特效 run 真实敌人计数完全相等', () {
    fail('解除 skip 前须接入真实高/低特效设置并执行双 run');
  }, skip: _grid1Skip);

  test('第 2 格：高/低特效 run 攻击令牌分配序列摘要完全相等', () {
    fail('解除 skip 前须从同一生产令牌观察面收集两条序列');
  }, skip: _grid2Skip);

  test('第 3 格：高/低特效 run 逐 tick 领域状态稳定摘要完全相等', () {
    fail('解除 skip 前须以稳定摘要运行同 seed/关卡/角色双 run');
  }, skip: _grid3Skip);

  test('第 4 格：塔 14 与群战 18/24 实测单位数符合独立生产配置', () {
    fail('解除 skip 前须先有可从生产配置读取的 14/18/24 active 目标');
  }, skip: _grid4Skip);
}
