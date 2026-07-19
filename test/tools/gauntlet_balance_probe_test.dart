// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_battle_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _seeds = 50;
const _schools = TechniqueSchool.values;

const _profiles = [
  _ProbeProfile(
    name: 'entry_lv100',
    tier: RealmTier.sanLiu,
    layer: RealmLayer.shuLian,
    build: ProgressionBuildProfile.undergeared,
  ),
  _ProbeProfile(
    name: 'recommended_lv150',
    tier: RealmTier.erLiu,
    layer: RealmLayer.qiMeng,
    build: ProgressionBuildProfile.standard,
  ),
  _ProbeProfile(
    name: 'full_lv170',
    tier: RealmTier.erLiu,
    layer: RealmLayer.shuLian,
    build: ProgressionBuildProfile.nearMax,
  ),
];

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test('三档玩家与断魂庄敌队守数值红线', () {
    final redLines = repository.numbers.combat.redLines;
    for (final profile in _profiles) {
      for (var slot = 0; slot < _schools.length; slot++) {
        final build = buildProgressionPlayerBuild(
          repository: repository,
          tier: profile.tier,
          layer: profile.layer,
          school: _schools[slot],
          slot: slot,
          isFounder: slot == 0,
          profile: profile.build,
        );
        expect(
          build.battleCharacter.maxHp,
          lessThanOrEqualTo(redLines.playerHpMax),
        );
        expect(
          build.battleCharacter.internalForce,
          lessThanOrEqualTo(redLines.internalForceMax),
        );
        for (final equipment in build.equipped) {
          expect(
            equipment.baseAttack,
            lessThanOrEqualTo(redLines.equipmentBaseAttackMax),
          );
        }
      }
    }

    final enemies = repository.bossGauntletConfig!.enemyTeams.values.expand(
      (team) => team,
    );
    for (final enemy in enemies) {
      expect(enemy.baseHp, lessThan(redLines.damageReadabilityMax));
      expect(enemy.baseHp, lessThanOrEqualTo(redLines.bossHpMax));
      for (final skillId in enemy.skillIds) {
        expect(
          repository.skillDefs[skillId]!.powerMultiplier,
          lessThanOrEqualTo(redLines.skillPowerMultiplierMax),
        );
      }
    }
  });

  test(
    '断魂庄三档连战胜率落入设计 bracket 且满配经历 Boss 全阶段',
    () {
      final results = {
        for (final profile in _profiles)
          profile.name: _probe(repository, profile),
      };
      for (final result in results.values) {
        print(result.summary);
      }

      final entry = results['entry_lv100']!;
      final recommended = results['recommended_lv150']!;
      final full = results['full_lv170']!;

      expect(entry.clearRate, lessThanOrEqualTo(0.35), reason: '入门档不应无脑通关');
      expect(
        recommended.clearRate,
        inInclusiveRange(0.40, 0.90),
        reason: '推荐档应有稳定空间但不应无脑必胜',
      );
      expect(full.clearRate, greaterThanOrEqualTo(0.80), reason: '当前满配应稳定通关');
      expect(
        full.finalPhaseRate,
        greaterThanOrEqualTo(0.80),
        reason: '满配胜局仍须把闻九针推进到最终阶段，不能跳过机制窗口',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

class _ProbeProfile {
  const _ProbeProfile({
    required this.name,
    required this.tier,
    required this.layer,
    required this.build,
  });

  final String name;
  final RealmTier tier;
  final RealmLayer layer;
  final ProgressionBuildProfile build;
}

class _ProbeResult {
  const _ProbeResult({
    required this.name,
    required this.stageWins,
    required this.clears,
    required this.finalPhaseRuns,
    required this.totalTicks,
  });

  final String name;
  final List<int> stageWins;
  final int clears;
  final int finalPhaseRuns;
  final int totalTicks;

  double get clearRate => clears / _seeds;
  double get finalPhaseRate => finalPhaseRuns / _seeds;

  String get summary {
    String pct(int value) => '${(value / _seeds * 100).toStringAsFixed(1)}%';
    return '$name | stage=${stageWins.map(pct).join('/')} '
        '| clear=${pct(clears)} | finalPhase=${pct(finalPhaseRuns)} '
        '| avgTicks=${(totalTicks / _seeds).toStringAsFixed(1)}';
  }
}

_ProbeResult _probe(GameRepository repository, _ProbeProfile profile) {
  final config = repository.bossGauntletConfig!;
  final stageWins = List<int>.filled(config.stages.length, 0);
  var clears = 0;
  var finalPhaseRuns = 0;
  var totalTicks = 0;

  for (var seed = 0; seed < _seeds; seed++) {
    final baseTeam = [
      for (var slot = 0; slot < _schools.length; slot++)
        buildProgressionPlayer(
          repository: repository,
          tier: profile.tier,
          layer: profile.layer,
          school: _schools[slot],
          slot: slot,
          isFounder: slot == 0,
          profile: profile.build,
        ),
    ];
    var members = [
      for (final player in baseTeam)
        ActivityMemberSnapshot()..characterId = player.characterId,
    ];

    for (var stageIndex = 0; stageIndex < config.stages.length; stageIndex++) {
      final players = GauntletController.stagePlayerTeam(
        baseTeam: baseTeam,
        members: members,
      );
      if (players.isEmpty) break;
      final stage = config.stages[stageIndex];
      final result = GauntletBattleRunner.runStage(
        playerTeam: players,
        enemyDefs: config.enemiesForTeam(stage.enemyTeamId),
        numbers: repository.numbers,
        seed: seed * config.stages.length + stageIndex,
      );
      totalTicks += result.finalState.tick;
      members = GauntletController.snapshotAfterStage(
        before: members,
        finalState: result.finalState,
      );
      if (!result.leftWin) break;

      stageWins[stageIndex]++;
      if (stageIndex == config.stages.length - 1) {
        clears++;
        final boss = result.finalState.rightTeam.single;
        if (boss.bossPhaseIndex == boss.bossPhases!.length - 1) {
          finalPhaseRuns++;
        }
      }
    }
  }

  return _ProbeResult(
    name: profile.name,
    stageWins: stageWins,
    clears: clears,
    finalPhaseRuns: finalPhaseRuns,
    totalTicks: totalTicks,
  );
}
