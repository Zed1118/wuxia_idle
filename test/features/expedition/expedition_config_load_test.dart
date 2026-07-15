import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../../support/test_data.dart';

/// 江湖远行 A2 配置的加载接线 canary：证明生产 `data/expeditions.yaml` /
/// `data/boss_gauntlets.yaml` 经 `loadAllDefs` 真被解析进仓储（非 graceful null），
/// 且守结构不变式。只断言语义不变式（非 Phase B/C 会调的瞬时数值），故内容填充后不脆断。
void main() {
  setUpAll(loadTestGameRepository);

  test('生产远征/断魂庄配置经 loadAllDefs 接线非空', () {
    final repo = GameRepository.instance;
    expect(repo.expeditionConfig, isNotNull, reason: 'data/expeditions.yaml 应被加载');
    expect(repo.bossGauntletConfig, isNotNull,
        reason: 'data/boss_gauntlets.yaml 应被加载');
  });

  test('远征节点时长为正、断魂庄守两精英一Boss+补给上限3不变式', () {
    final repo = GameRepository.instance;
    final exp = repo.expeditionConfig!;
    expect(exp.normalNodeMinutes, greaterThan(0));
    expect(exp.eliteNodeMinutes, greaterThan(0));

    final gauntlet = repo.bossGauntletConfig!;
    expect(gauntlet.supplyCap, 3);
    expect(gauntlet.stages.length, 3);
    expect(gauntlet.stages.where((s) => s.role == 'elite').length, 2);
    expect(gauntlet.stages.where((s) => s.role == 'boss').length, 1);
  });
}
