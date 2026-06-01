import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  test('每个有敌人的 isBossStage 关卡 enemyTeam 恰有 ≥1 个 isBoss 敌人', () {
    final stages = GameRepository.instance.stageDefs.values;
    final bossStages =
        stages.where((s) => s.isBossStage && s.enemyTeam.isNotEmpty).toList();
    expect(bossStages, isNotEmpty, reason: 'production 应有带敌人的 boss stage');
    for (final s in bossStages) {
      expect(s.enemyTeam.where((e) => e.isBoss).length, greaterThanOrEqualTo(1),
          reason: '${s.id} 是 boss stage(有敌人),但 enemyTeam 无 isBoss 敌人');
    }
  });

  test('非 boss stage 不应有 isBoss 敌人', () {
    final stages = GameRepository.instance.stageDefs.values;
    for (final s in stages.where((s) => !s.isBossStage)) {
      expect(s.enemyTeam.any((e) => e.isBoss), false,
          reason: '${s.id} 非 boss stage 却标了 isBoss 敌人');
    }
  });

  test('恰好标注 14 个 boss 敌人(production 红线)', () {
    final stages = GameRepository.instance.stageDefs.values;
    final total =
        stages.fold<int>(0, (n, s) => n + s.enemyTeam.where((e) => e.isBoss).length);
    expect(total, 14);
  });
}
