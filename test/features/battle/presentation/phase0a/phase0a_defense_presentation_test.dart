import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/defense_resolution.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_sfx.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';

void main() {
  const started = Phase0aDefenseStarted(
    seq: 1,
    tick: 1,
    actor: 'player',
    action: Phase0aDefenseAction.dodge,
    fromPosition: ArenaVector.zero,
    toPosition: ArenaVector(110, 0),
    windowTicks: 2,
    shieldAbsorption: 0,
  );
  const resolved = Phase0aDefenseResolved(
    seq: 2,
    tick: 1,
    attackId: 'enemy:1:player',
    attacker: 'enemy',
    target: 'player',
    branch: DefenseBranch.dodge,
    incomingDamage: 0,
    counterDamage: 0,
    shieldRemaining: 0,
    nonRecursive: true,
    targetPosition: ArenaVector(110, 0),
  );

  test('defense events produce anchored VFX and existing audio feedback', () {
    final entries = Phase0aVfxController().consume([started, resolved]);

    expect(entries.map((entry) => entry.kind), [
      Phase0aVfxKind.defenseStarted,
      Phase0aVfxKind.defenseResolved,
    ]);
    expect(entries.first.anchor, const ArenaVector(110, 0));
    expect(entries.first.statusTicks, 2);
    expect(
      phase0aSfxAssetForEvent(started, playerId: 'player'),
      'audio/sfx/battleChargeStart.mp3',
    );
    expect(
      phase0aSfxAssetForEvent(resolved, playerId: 'player'),
      'audio/sfx/battleChargeStart.mp3',
    );
  });
}
