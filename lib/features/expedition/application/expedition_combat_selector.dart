import 'package:isar_community/isar.dart';

import 'expedition_combat.dart';
import 'expedition_combat_runner.dart';
import 'phase0a_expedition_combat_runner.dart';
import 'phase0a_expedition_gate.dart';

ExpeditionCombat expeditionCombatFor(Isar isar, {required int memberCount}) =>
    Phase0aExpeditionGate.shouldUsePhase0a(memberCount: memberCount)
    ? Phase0aExpeditionCombatRunner(isar)
    : ExpeditionCombatRunner(isar);
