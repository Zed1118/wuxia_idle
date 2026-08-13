import 'dart:io';

const phase0aParticipantEnvironmentKey = 'PHASE0A_PARTICIPANT_ID';
const phase0aSessionEnvironmentKey = 'PHASE0A_SESSION_ID';
const phase0aOrderEnvironmentKey = 'PHASE0A_ORDER';
const phase0aSlotEnvironmentKey = 'PHASE0A_SLOT';

final class PlaytestIdentity {
  const PlaytestIdentity({
    required this.participantId,
    required this.sessionId,
    required this.order,
    required this.slot,
  });

  factory PlaytestIdentity.fromEnvironment([Map<String, String>? values]) {
    final environment = values ?? Platform.environment;
    final participantId = environment[phase0aParticipantEnvironmentKey] ?? '';
    final sessionId = environment[phase0aSessionEnvironmentKey] ?? '';
    final order = environment[phase0aOrderEnvironmentKey] ?? '';
    final slotText = environment[phase0aSlotEnvironmentKey] ?? '';
    final slot = int.tryParse(slotText);
    final identity = PlaytestIdentity(
      participantId: participantId,
      sessionId: sessionId,
      order: order,
      slot: slot ?? -1,
    );
    final errors = identity.validate();
    if (errors.isNotEmpty) {
      throw FormatException(
        'Invalid Phase 0A anonymous session environment: ${errors.join('; ')}',
      );
    }
    return identity;
  }

  static final RegExp _participantPattern = RegExp(r'^P0[1-6]$');
  static final RegExp _sessionPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{2,31}$');

  final String participantId;
  final String sessionId;
  final String order;
  final int slot;

  List<String> validate() {
    final errors = <String>[];
    if (!_participantPattern.hasMatch(participantId)) {
      errors.add('participant_id must be P01..P06');
    }
    if (!_sessionPattern.hasMatch(sessionId)) {
      errors.add('session_id must be a 3..32 character anonymous slug');
    }
    if (order != 'AB' && order != 'BA') {
      errors.add('order must be AB or BA');
    }
    if (slot < 1 || slot > 6) errors.add('slot must be 1..6');
    return errors;
  }

  Map<String, Object?> toJson() => {
    'participant_id': participantId,
    'session_id': sessionId,
    'order': order,
    'slot': slot,
  };
}
