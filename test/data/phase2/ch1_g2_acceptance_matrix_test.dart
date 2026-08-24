import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/ch1_candidate_defeat_projection_declarations.dart';
import '../../support/phase2_g2_acceptance_harness.dart';

void main() {
  test('stage_01_03 matrix contains exactly the eight G2 hard gates', () {
    expect(
      G2AcceptanceHarness.stage0103Matrix.map((gate) => gate.id),
      <G2GateId>[
        G2GateId.continuousMovementAndAttack,
        G2GateId.continuousClear35To45,
        G2GateId.activeThreat8To16,
        G2GateId.defensiveOptions,
        G2GateId.learnableBoss,
        G2GateId.victoryToNextStage,
        G2GateId.rulesParity,
        G2GateId.dualViewportPerformanceAndInk,
      ],
    );
    for (final gate in G2AcceptanceHarness.stage0103Matrix) {
      expect(gate.requiredEvidence, isNotEmpty, reason: gate.id.id);
      expect(gate.acceptance, isNotEmpty, reason: gate.id.id);
    }
  });

  test('candidate stage shape is evidence input, never a production PASS', () {
    final candidateEntries =
        ch1CandidateDefeatProjectionEntriesByStageId['stage_01_03']!;
    expect(candidateEntries, hasLength(40));
    expect(
      candidateEntries.every((entry) => entry.key.startsWith('candidate_ch1_s03_')),
      isTrue,
    );

    final report = G2AcceptanceHarness.candidateStage0103();
    expect(report.overallStatus, G2EvidenceStatus.blocked);
    expect(
      report.results.every(
        (result) => result.status != G2EvidenceStatus.pass,
      ),
      isTrue,
    );
    expect(report.resultFor(G2GateId.continuousClear35To45).status,
        G2EvidenceStatus.blocked);
    expect(report.resultFor(G2GateId.activeThreat8To16).status,
        G2EvidenceStatus.blocked);
  });

  test('all required evidence must pass before a gate can pass', () {
    final gate = G2AcceptanceHarness.stage0103Matrix.first;
    final onlyProfile = G2AcceptanceHarness.evaluate(
      evidenceByGate: {
        gate.id: const [
          G2AcceptanceEvidence(
            kind: G2EvidenceKind.performanceProfile,
            status: G2EvidenceStatus.pass,
            source: 'captured evidence',
            summary: 'profile supplied',
          ),
        ],
      },
    );
    expect(onlyProfile.resultFor(gate.id).status, G2EvidenceStatus.blocked);

    final complete = G2AcceptanceHarness.evaluate(
      evidenceByGate: {
        gate.id: const [
          G2AcceptanceEvidence(
            kind: G2EvidenceKind.runtimeIntegration,
            status: G2EvidenceStatus.pass,
            source: 'integrated stage run',
            summary: 'runtime supplied',
          ),
          G2AcceptanceEvidence(
            kind: G2EvidenceKind.performanceProfile,
            status: G2EvidenceStatus.pass,
            source: 'captured evidence',
            summary: 'profile supplied',
          ),
        ],
      },
    );
    expect(complete.resultFor(gate.id).status, G2EvidenceStatus.pass);
  });

  test('record renderer keeps blocked and candidate states explicit', () {
    final markdown = G2AcceptanceHarness.candidateStage0103().toMarkdown();

    for (final gate in G2AcceptanceHarness.stage0103Matrix) {
      expect(markdown, contains(gate.id.id));
    }
    expect(markdown, contains('BLOCKED/待集成复验'));
    expect(markdown, contains('TUNING/candidate'));
    expect(markdown, isNot(contains('FROZEN')));
  });

  test('production integration hooks are present without asserting stage PASS', () {
    final headless = File(
      'lib/features/battle/application/phase0a/phase0a_headless_runner.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/debug/application/battle_frame_profile.dart',
    ).readAsStringSync();
    final visualRoutes = File(
      'lib/features/debug/application/visual_route.dart',
    ).readAsStringSync();

    expect(headless, contains('runToEnd'));
    expect(profile, contains('BattleFrameProfileAccumulator'));
    expect(profile, contains('p99'));
    expect(visualRoutes, contains('phase0aBattleProfile'));
    expect(visualRoutes, contains('phase0aBattleBossMechanics'));
    expect(
      G2AcceptanceHarness.candidateStage0103().overallStatus,
      isNot(G2EvidenceStatus.pass),
    );
  });
}
