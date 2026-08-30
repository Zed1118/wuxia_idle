import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_sfx.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/audio/audio_backend.dart';
import 'package:wuxia_idle/shared/audio/sound_manager.dart';

Phase0aHitLanded _hit(
  int seq, {
  String actor = 'player',
  bool critical = false,
  bool ultimate = false,
}) => Phase0aHitLanded(
  seq: seq,
  tick: 1,
  actor: actor,
  target: actor == 'player' ? 'enemy' : 'player',
  moveKind: Phase0aMoveKind.light,
  isCritical: critical,
  isUltimate: ultimate,
  resolvedDamage: 1,
  remainingHealth: 99,
);

final class _BurstFlow implements Phase0aBattleFlow {
  bool _emitted = false;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => const [];

  @override
  Phase0aArenaState get state => const Phase0aArenaState(
    tick: 0,
    nextSeq: 21,
    player: Phase0aActor(
      id: 'player',
      side: Phase0aSide.player,
      position: ArenaVector.zero,
      facing: ArenaVector(1, 0),
      maxHealth: 100,
      currentHealth: 100,
      moveSpeed: 1,
      qiCurrent: 0,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    ),
    enemies: [
      Phase0aActor(
        id: 'enemy',
        side: Phase0aSide.enemy,
        position: ArenaVector(40, 0),
        facing: ArenaVector(-1, 0),
        maxHealth: 100,
        currentHealth: 100,
        moveSpeed: 1,
        qiCurrent: 0,
        qiMax: 100,
        attackCooldownRemaining: 0,
        defeatKind: Phase0aDefeatKind.normal,
      ),
    ],
    skillSlots: [
      Phase0aSkillSlot(
        slot: 'gather',
        cooldownRemaining: 0,
        qiCost: 0,
        availability: Phase0aSkillAvailability.ready,
      ),
      Phase0aSkillSlot(
        slot: 'clear',
        cooldownRemaining: 0,
        qiCost: 0,
        availability: Phase0aSkillAvailability.ready,
      ),
    ],
  );

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    if (_emitted) return const [];
    _emitted = true;
    return [for (var seq = 1; seq <= 20; seq += 1) _hit(seq)];
  }
}

final class _RecordingAudioBackend implements AudioBackend {
  final List<String> sfxPaths = [];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playBgm(String assetPath, double volume) async {}

  @override
  Future<void> playSfx(String assetPath, double volume) async {
    sfxPaths.add(assetPath);
  }

  @override
  void setBgmVolume(double volume) {}

  @override
  Future<void> stopBgm() async {}
}

void main() {
  test('same-side hit burst emits one highest-semantic sound', () {
    final events = <Phase0aEvent>[
      for (var seq = 1; seq <= 20; seq += 1) _hit(seq),
      _hit(21, critical: true),
      _hit(22, ultimate: true),
    ];

    expect(phase0aSfxAssetsForFrame(events, playerId: 'player'), [
      'audio/sfx/battleUlt.mp3',
    ]);
  });

  test('player and enemy hit groups each retain one representative', () {
    expect(
      phase0aSfxAssetsForFrame([
        _hit(1),
        _hit(2),
        _hit(3, actor: 'enemy'),
      ], playerId: 'player'),
      ['audio/sfx/battleHit_0_0.mp3', 'audio/sfx/battleHit_1_0.mp3'],
    );
  });

  test(
    'boss charge warning is present first and duplicate assets collapse',
    () {
      expect(
        phase0aSfxAssetsForFrame([
          _hit(1),
          const Phase0aGatherStarted(seq: 2, tick: 1, actor: 'player'),
          const Phase0aBossChargeStarted(
            seq: 3,
            tick: 1,
            actor: 'boss',
            skillId: 'charge',
            chargeTicks: 3,
          ),
          const Phase0aGatherStarted(seq: 4, tick: 1, actor: 'player'),
        ], playerId: 'player'),
        ['audio/sfx/battleChargeStart.mp3', 'audio/sfx/battleHit_0_0.mp3'],
      );
    },
  );

  testWidgets('production screen consumes one frame sound plan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final backend = _RecordingAudioBackend();
    final previous = SoundManager.instance;
    SoundManager.instance = SoundManager(backend);
    addTearDown(() => SoundManager.instance = previous);
    final controller = Phase0aBattleController(
      flow: _BurstFlow(),
      roster: Phase0aVisualRoster(
        visuals: const {
          'player': Phase0aActorVisual(
            name: 'player',
            assetPath: 'assets/characters/battle_founder_v2.png',
            isElite: false,
          ),
          'enemy': Phase0aActorVisual(
            name: 'enemy',
            assetPath: 'assets/characters/battle_founder_v2.png',
            isElite: false,
          ),
        },
      ),
      fixedDeltaSeconds: 0.1,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );

    controller.step();
    await tester.pump();

    expect(backend.sfxPaths, ['audio/sfx/battleHit_0_0.mp3']);
  });
}
