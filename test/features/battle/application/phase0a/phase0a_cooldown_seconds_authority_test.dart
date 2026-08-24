import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../../../../support/test_data.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async => repo = await loadTestGameRepository());

  test('261 条生产技能显式物化玩家与敌方 Phase0A 冷却秒', () {
    expect(repo.skillDefs, hasLength(261));
    for (final skill in repo.skillDefs.values) {
      final playerSeconds = skill.cooldownSeconds;
      final enemySeconds = skill.phase0aEnemyCooldownSeconds;
      expect(playerSeconds, isNotNull, reason: skill.id);
      expect(enemySeconds, isNotNull, reason: skill.id);
      expect(playerSeconds!.isFinite, isTrue, reason: skill.id);
      expect(enemySeconds!.isFinite, isTrue, reason: skill.id);
      expect(playerSeconds, greaterThanOrEqualTo(0), reason: skill.id);
      expect(enemySeconds, greaterThanOrEqualTo(0), reason: skill.id);

      if (skill.id == 'skill_phase0a_gather') {
        expect(playerSeconds, 5, reason: skill.id);
      } else if (skill.id == 'skill_phase0a_clear') {
        expect(playerSeconds, 8, reason: skill.id);
      } else {
        expect(
          playerSeconds,
          closeTo(skill.cooldownTurns * 0.55, 1e-12),
          reason: skill.id,
        );
      }
      expect(
        enemySeconds,
        closeTo(skill.cooldownTurns * 1.0, 1e-12),
        reason: skill.id,
      );
    }
  });

  test('Phase0A production mapper 对 cooldownTurns 零读取', () {
    final source = File(
      'lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('cooldownTurns')));
  });
}
