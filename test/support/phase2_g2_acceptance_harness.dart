// G2 acceptance matrix for the stage_01_03 production vertical slice.
//
// This file is test-side only. It records evidence states and never changes
// production hosts, runtime wiring, or production data.

enum G2GateId {
  continuousMovementAndAttack,
  continuousClear35To45,
  activeThreat8To16,
  defensiveOptions,
  learnableBoss,
  victoryToNextStage,
  rulesParity,
  dualViewportPerformanceAndInk,
}

extension G2GateIdLabels on G2GateId {
  String get id => switch (this) {
    G2GateId.continuousMovementAndAttack => 'g2-01-continuous-movement-attack',
    G2GateId.continuousClear35To45 => 'g2-02-continuous-clear-35-45',
    G2GateId.activeThreat8To16 => 'g2-03-active-threat-8-16',
    G2GateId.defensiveOptions => 'g2-04-defense-options',
    G2GateId.learnableBoss => 'g2-05-learnable-boss',
    G2GateId.victoryToNextStage => 'g2-06-victory-next-stage',
    G2GateId.rulesParity => 'g2-07-manual-auto-headless-parity',
    G2GateId.dualViewportPerformanceAndInk => 'g2-08-dual-viewport-performance-ink',
  };

  String get title => switch (this) {
    G2GateId.continuousMovementAndAttack => '连续移动/普攻无掉帧',
    G2GateId.continuousClear35To45 => '35–45 总敌人连续清怪',
    G2GateId.activeThreat8To16 => '8–16 active 且威胁可读',
    G2GateId.defensiveOptions => '盾反/招架/闪避各自有用',
    G2GateId.learnableBoss => 'Boss 可学习且破绽可利用',
    G2GateId.victoryToNextStage => '胜利到下一关无阻塞',
    G2GateId.rulesParity => 'manual/auto/headless 同规则',
    G2GateId.dualViewportPerformanceAndInk => '双 viewport 性能与水墨视觉通过',
  };
}

enum G2EvidenceKind {
  candidateContract,
  headlessIntegration,
  runtimeIntegration,
  manualIntegration,
  performanceProfile,
  visualCapture,
}

extension G2EvidenceKindLabels on G2EvidenceKind {
  String get label => switch (this) {
    G2EvidenceKind.candidateContract => 'candidate contract',
    G2EvidenceKind.headlessIntegration => 'headless integration',
    G2EvidenceKind.runtimeIntegration => 'runtime integration',
    G2EvidenceKind.manualIntegration => 'manual integration',
    G2EvidenceKind.performanceProfile => 'performance profile',
    G2EvidenceKind.visualCapture => 'visual capture',
  };
}

enum G2EvidenceStatus { pass, fail, blocked, tuningCandidate }

extension G2EvidenceStatusLabels on G2EvidenceStatus {
  String get label => switch (this) {
    G2EvidenceStatus.pass => 'PASS',
    G2EvidenceStatus.fail => 'FAIL',
    G2EvidenceStatus.blocked => 'BLOCKED/待集成复验',
    G2EvidenceStatus.tuningCandidate => 'TUNING/candidate',
  };
}

final class G2AcceptanceGate {
  const G2AcceptanceGate({
    required this.id,
    required this.requiredEvidence,
    required this.acceptance,
    this.candidateNote,
  });

  final G2GateId id;
  final List<G2EvidenceKind> requiredEvidence;
  final String acceptance;
  final String? candidateNote;

  String get title => id.title;
}

final class G2AcceptanceEvidence {
  const G2AcceptanceEvidence({
    required this.kind,
    required this.status,
    required this.source,
    required this.summary,
  });

  final G2EvidenceKind kind;
  final G2EvidenceStatus status;
  final String source;
  final String summary;
}

final class G2AcceptanceGateResult {
  G2AcceptanceGateResult({
    required this.gate,
    required this.status,
    required List<G2AcceptanceEvidence> evidence,
  }) : evidence = List.unmodifiable(evidence);

  final G2AcceptanceGate gate;
  final G2EvidenceStatus status;
  final List<G2AcceptanceEvidence> evidence;
}

final class G2AcceptanceReport {
  G2AcceptanceReport({required List<G2AcceptanceGateResult> results})
    : results = List.unmodifiable(results);

  final List<G2AcceptanceGateResult> results;

  G2EvidenceStatus get overallStatus {
    if (results.any((result) => result.status == G2EvidenceStatus.fail)) {
      return G2EvidenceStatus.fail;
    }
    if (results.any((result) => result.status != G2EvidenceStatus.pass)) {
      return G2EvidenceStatus.blocked;
    }
    return G2EvidenceStatus.pass;
  }

  G2AcceptanceGateResult resultFor(G2GateId id) => results.firstWhere(
    (result) => result.gate.id == id,
  );

  String toMarkdown({String generatedAt = '<fill after evidence capture>'}) {
    final out = StringBuffer()
      ..writeln('# G2 stage_01_03 验收记录')
      ..writeln()
      ..writeln('- generated_at: `$generatedAt`')
      ..writeln('- stage: `stage_01_03` / 黑风岭')
      ..writeln('- overall: `${overallStatus.label}`')
      ..writeln('- scope: production vertical slice only')
      ..writeln()
      ..writeln(
        '本表是可执行验收 harness 的证据记录，不把候选数值或未集成证据写成生产 PASS。',
      )
      ..writeln()
      ..writeln('| gate | hard acceptance | status | required evidence | evidence |')
      ..writeln('|---|---|---|---|---|');

    for (final result in results) {
      final evidence = result.evidence.isEmpty
          ? '待填'
          : result.evidence
                .map(
                  (entry) =>
                      '${entry.kind.label}: ${entry.status.label} (${entry.source})',
                )
                .join('<br>');
      final candidate = result.gate.candidateNote == null
          ? ''
          : '<br>${result.gate.candidateNote}';
      out.writeln(
        '| `${result.gate.id.id}` | ${result.gate.acceptance}$candidate | '
        '${result.status.label} | ${result.gate.requiredEvidence.map((e) => e.label).join('<br>')} | $evidence |',
      );
    }
    return out.toString();
  }
}

final class G2AcceptanceHarness {
  G2AcceptanceHarness._();

  static const stageId = 'stage_01_03';

  static const List<G2AcceptanceGate> stage0103Matrix = [
    G2AcceptanceGate(
      id: G2GateId.continuousMovementAndAttack,
      requiredEvidence: [
        G2EvidenceKind.runtimeIntegration,
        G2EvidenceKind.performanceProfile,
      ],
      acceptance: '连续移动与普攻场景无掉帧证据',
    ),
    G2AcceptanceGate(
      id: G2GateId.continuousClear35To45,
      requiredEvidence: [
        G2EvidenceKind.candidateContract,
        G2EvidenceKind.headlessIntegration,
      ],
      acceptance: '连续清除 35–45 个敌人且无软锁',
      candidateNote: 'TUNING/candidate: 35–45 总敌人与对应 encounter 仅作候选边界。',
    ),
    G2AcceptanceGate(
      id: G2GateId.activeThreat8To16,
      requiredEvidence: [
        G2EvidenceKind.candidateContract,
        G2EvidenceKind.visualCapture,
      ],
      acceptance: 'active 数量处于 8–16 候选边界且威胁可读',
      candidateNote: 'TUNING/candidate: active 上限与布局仍需生产集成复验。',
    ),
    G2AcceptanceGate(
      id: G2GateId.defensiveOptions,
      requiredEvidence: [
        G2EvidenceKind.runtimeIntegration,
        G2EvidenceKind.manualIntegration,
        G2EvidenceKind.visualCapture,
      ],
      acceptance: '盾反、招架、闪避均能改变可观测战斗结果',
    ),
    G2AcceptanceGate(
      id: G2GateId.learnableBoss,
      requiredEvidence: [
        G2EvidenceKind.runtimeIntegration,
        G2EvidenceKind.manualIntegration,
        G2EvidenceKind.visualCapture,
      ],
      acceptance: 'Boss 规律可学习，破绽可被玩家利用',
    ),
    G2AcceptanceGate(
      id: G2GateId.victoryToNextStage,
      requiredEvidence: [
        G2EvidenceKind.runtimeIntegration,
        G2EvidenceKind.manualIntegration,
      ],
      acceptance: '胜利结算后可无阻塞进入下一关',
    ),
    G2AcceptanceGate(
      id: G2GateId.rulesParity,
      requiredEvidence: [
        G2EvidenceKind.headlessIntegration,
        G2EvidenceKind.runtimeIntegration,
        G2EvidenceKind.manualIntegration,
      ],
      acceptance: 'manual、auto、headless 使用同一规则与事件语义',
    ),
    G2AcceptanceGate(
      id: G2GateId.dualViewportPerformanceAndInk,
      requiredEvidence: [
        G2EvidenceKind.performanceProfile,
        G2EvidenceKind.visualCapture,
      ],
      acceptance: '1280x720 与 1440x900 均有性能原始证据且水墨视觉通过',
    ),
  ];

  static G2AcceptanceReport evaluate({
    Map<G2GateId, List<G2AcceptanceEvidence>> evidenceByGate = const {},
  }) {
    final results = <G2AcceptanceGateResult>[];
    for (final gate in stage0103Matrix) {
      final evidence = evidenceByGate[gate.id] ?? const [];
      final status = _evaluateGate(gate, evidence);
      results.add(
        G2AcceptanceGateResult(
          gate: gate,
          status: status,
          evidence: evidence,
        ),
      );
    }
    return G2AcceptanceReport(results: results);
  }

  static G2AcceptanceReport candidateStage0103() => evaluate(
    evidenceByGate: {
      G2GateId.continuousClear35To45: const [
        G2AcceptanceEvidence(
          kind: G2EvidenceKind.candidateContract,
          status: G2EvidenceStatus.tuningCandidate,
          source: 'test/fixtures/phase2/combat/ch1_candidate',
          summary: 'candidate encounter shape only; production integration pending',
        ),
      ],
      G2GateId.activeThreat8To16: const [
        G2AcceptanceEvidence(
          kind: G2EvidenceKind.candidateContract,
          status: G2EvidenceStatus.tuningCandidate,
          source: 'test/fixtures/phase2/combat/ch1_candidate',
          summary: 'candidate active bound only; visual integration pending',
        ),
      ],
    },
  );

  static G2EvidenceStatus _evaluateGate(
    G2AcceptanceGate gate,
    List<G2AcceptanceEvidence> evidence,
  ) {
    if (evidence.any((entry) => entry.status == G2EvidenceStatus.fail)) {
      return G2EvidenceStatus.fail;
    }
    for (final required in gate.requiredEvidence) {
      final matching = evidence.where((entry) => entry.kind == required);
      if (!matching.any((entry) => entry.status == G2EvidenceStatus.pass)) {
        return G2EvidenceStatus.blocked;
      }
    }
    return G2EvidenceStatus.pass;
  }
}
