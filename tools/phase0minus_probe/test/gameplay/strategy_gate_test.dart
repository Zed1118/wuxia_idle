import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/gameplay_game.dart';
import 'package:phase0minus_probe/gameplay/strategy/gameplay_strategy.dart';

void main() {
  const seeds = <int>[
    20260813,
    20260814,
    20260815,
    20260816,
    20260817,
    20260818,
    20260819,
    20260820,
    20260821,
    20260822,
  ];
  final source = File('assets/probe_scenarios.yaml').readAsStringSync();

  ProbeConfig configForSeed(int seed) => ProbeConfig.parse(
    source.replaceFirst(
      RegExp(r'^fixed_seed:\s*\d+\s*$', multiLine: true),
      'fixed_seed: $seed',
    ),
  );

  Future<StrategyRunResult> run(
    WidgetTester tester,
    int seed,
    GameplayStrategy strategy,
  ) async {
    final game = GameplayGame(config: configForSeed(seed));
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameplayGame>(game: game)),
    );
    await tester.pump();
    final result = runGameplayStrategy(
      game: game,
      strategy: strategy,
      seed: seed,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    return result;
  }

  testWidgets('fixed 10-seed strategy gate records the current verdict', (
    tester,
  ) async {
    final weakResults = <StrategyRunResult>[];
    final baselineResults = <StrategyRunResult>[];
    for (final seed in seeds) {
      weakResults.add(await run(tester, seed, WeakHoldStrategy()));
      baselineResults.add(await run(tester, seed, BaselineComboStrategy()));
    }

    final weakFailures = weakResults
        .where((result) => result.failedInWaveThreeOrTimedOut)
        .length;
    final baselinePasses = baselineResults
        .where((result) => result.passed)
        .length;
    final report = {
      'strategy_gate': weakFailures >= 8 && baselinePasses >= 8
          ? 'PASS'
          : 'FAIL',
      'weak_failures_in_wave_3_or_timeout': weakFailures,
      'baseline_victories': baselinePasses,
      'weak': weakResults.map((result) => result.toJson()).toList(),
      'baseline': baselineResults.map((result) => result.toJson()).toList(),
    };
    // ignore: avoid_print
    print(const JsonEncoder.withIndent('  ').convert(report));

    expect(
      weakFailures,
      greaterThanOrEqualTo(8),
      reason:
          'Weak strategy must fail in W3 or time out in at least 8/10 seeds.',
    );
    expect(baselinePasses, greaterThan(0));
    expect(
      report['strategy_gate'],
      'FAIL',
      reason: 'Known recovery point: baseline is still below 8/10.',
    );
  });
}
