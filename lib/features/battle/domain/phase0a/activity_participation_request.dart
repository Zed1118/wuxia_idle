/// Explicit activity entry contract for Phase 0A.
///
/// This is deliberately only a value object. Availability, occupancy,
/// first-clear rules, and mode-specific policy belong to the caller's
/// `CharacterAvailabilityService`/policy layer; this type never infers them.
library;

/// Content families that may own an activity entry.
enum ActivityContentKind {
  mainline,
  tower,
  lightFoot,
  massBattle,
  innerDemon,
  gauntlet,
  expedition,
}

/// How the selected character participates in the activity.
enum ActivityParticipationMode { direct, dispatch }

/// Who controls a direct or dispatched run.
enum ActivityController { human, playerBot }

/// Whether the run uses the visible realtime clock or deterministic headless
/// progression.
enum ActivityClock { realtime, headless }

/// Why the activity is being entered.
enum ActivityEntryKind { firstClear, replay, sweep, offlineResume }

/// Immutable, explicit activity participation request.
///
/// Every field is required intentionally. This contract does not choose the
/// current leader, provide a fallback loadout, or encode semantic
/// compatibility between the enum fields; those decisions belong to the
/// availability/policy layer.
final class ActivityParticipationRequest {
  ActivityParticipationRequest({
    required String contentId,
    required this.contentKind,
    required this.characterId,
    required String loadoutPlanId,
    required this.participation,
    required this.controller,
    required this.clock,
    required this.entryKind,
  }) : _contentId = contentId.trim(),
       _loadoutPlanId = loadoutPlanId.trim() {
    if (_contentId.isEmpty) {
      throw ArgumentError.value(contentId, 'contentId', 'must not be empty');
    }
    if (_loadoutPlanId.isEmpty) {
      throw ArgumentError.value(
        loadoutPlanId,
        'loadoutPlanId',
        'must not be empty',
      );
    }
    // Character.id is an Isar integer primary key; persisted IDs are positive.
    if (characterId <= 0) {
      throw ArgumentError.value(
        characterId,
        'characterId',
        'must be a positive character ID',
      );
    }
  }

  final String _contentId;
  final ActivityContentKind contentKind;
  final int characterId;
  final String _loadoutPlanId;
  final ActivityParticipationMode participation;
  final ActivityController controller;
  final ActivityClock clock;
  final ActivityEntryKind entryKind;

  String get contentId => _contentId;
  String get loadoutPlanId => _loadoutPlanId;

  @override
  bool operator ==(Object other) =>
      other is ActivityParticipationRequest &&
      other.contentId == contentId &&
      other.contentKind == contentKind &&
      other.characterId == characterId &&
      other.loadoutPlanId == loadoutPlanId &&
      other.participation == participation &&
      other.controller == controller &&
      other.clock == clock &&
      other.entryKind == entryKind;

  @override
  int get hashCode => Object.hash(
    contentId,
    contentKind,
    characterId,
    loadoutPlanId,
    participation,
    controller,
    clock,
    entryKind,
  );

  @override
  String toString() =>
      'ActivityParticipationRequest('
      'contentId: $contentId, contentKind: $contentKind, '
      'characterId: $characterId, loadoutPlanId: $loadoutPlanId, '
      'participation: $participation, controller: $controller, '
      'clock: $clock, entryKind: $entryKind)';
}
