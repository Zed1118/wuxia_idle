import '../domain/mentor_insight_policy.dart';

/// Explicit lifecycle input reduced in caller declaration order.
sealed class MentorInsightStageOccupancyMutation {
  const MentorInsightStageOccupancyMutation();
}

/// Requests occupancy for the companion explicitly selected by the caller.
final class AcquireMentorInsightStageOccupancy
    extends MentorInsightStageOccupancyMutation {
  const AcquireMentorInsightStageOccupancy({
    required this.choice,
    required this.blockingStatus,
  });

  final MentorInsightChoice choice;
  final MentorInsightBlockingStatus blockingStatus;
}

/// Releases one exact stage and character occupancy pair.
final class ReleaseMentorInsightStageOccupancy
    extends MentorInsightStageOccupancyMutation {
  const ReleaseMentorInsightStageOccupancy({
    required this.companion,
    required this.reason,
  });

  final MentorInsightCompanion companion;
  final MentorInsightReleaseReason reason;
}

/// Immutable revisioned view of the optional single-stage companion.
final class MentorInsightStageOccupancySnapshot {
  const MentorInsightStageOccupancySnapshot._({
    required this.revision,
    required this.companion,
  });

  final int revision;
  final MentorInsightCompanion? companion;
}

/// A fully validated successor bound to one exact predecessor runtime.
final class MentorInsightStageOccupancyPreparedSuccessor {
  MentorInsightStageOccupancyPreparedSuccessor._({
    required Object ownerToken,
    required MentorInsightStageOccupancyRuntime predecessor,
    required this.base,
    required this.next,
    required List<MentorInsightStageOccupancyMutation> mutations,
  }) : _ownerToken = ownerToken,
       _predecessor = predecessor,
       mutations = List.unmodifiable(mutations);

  final Object _ownerToken;
  final MentorInsightStageOccupancyRuntime _predecessor;
  final MentorInsightStageOccupancySnapshot base;
  final MentorInsightStageOccupancySnapshot next;
  final List<MentorInsightStageOccupancyMutation> mutations;
  bool _committed = false;
}

/// Immutable owner lineage for explicit single-stage occupancy transitions.
final class MentorInsightStageOccupancyRuntime {
  MentorInsightStageOccupancyRuntime._({
    required Object ownerToken,
    required this.snapshot,
  }) : _ownerToken = ownerToken;

  factory MentorInsightStageOccupancyRuntime.empty() =>
      MentorInsightStageOccupancyRuntime._(
        ownerToken: Object(),
        snapshot: const MentorInsightStageOccupancySnapshot._(
          revision: 0,
          companion: null,
        ),
      );

  factory MentorInsightStageOccupancyRuntime.restore({
    required int revision,
    MentorInsightCompanion? companion,
  }) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }

    return MentorInsightStageOccupancyRuntime._(
      ownerToken: Object(),
      snapshot: MentorInsightStageOccupancySnapshot._(
        revision: revision,
        companion: companion,
      ),
    );
  }

  final Object _ownerToken;
  final MentorInsightStageOccupancySnapshot snapshot;

  /// Materializes and validates one ordered batch without changing this value.
  MentorInsightStageOccupancyPreparedSuccessor prepare(
    Iterable<MentorInsightStageOccupancyMutation> mutations,
  ) {
    final input = List<MentorInsightStageOccupancyMutation>.unmodifiable(
      mutations,
    );
    var companion = snapshot.companion;
    var changed = false;

    for (final mutation in input) {
      switch (mutation) {
        case AcquireMentorInsightStageOccupancy(
          :final choice,
          :final blockingStatus,
        ):
          final characterId = choice.menteeCharacterId;
          if (characterId == null) continue;
          if (!MentorInsightPolicy.canAccompany(blockingStatus)) {
            throw StateError('Mentor-insight companion is activity blocked');
          }

          final requested = MentorInsightCompanion(
            stageId: choice.stageId,
            characterId: characterId,
          );
          final active = companion;
          if (active != null) {
            if (active == requested) {
              throw StateError('Mentor-insight occupancy is already active');
            }
            if (active.stageId != requested.stageId) {
              throw StateError('Mentor-insight occupancy stage does not match');
            }
            throw StateError(
              'Mentor-insight occupancy character does not match',
            );
          }

          companion = requested;
          changed = true;
        case ReleaseMentorInsightStageOccupancy(
          companion: final requested,
          :final reason,
        ):
          if (!MentorInsightPolicy.releaseReasons.contains(reason)) {
            throw StateError('Mentor-insight release reason is unsupported');
          }

          final active = companion;
          if (active == null) {
            throw StateError('Mentor-insight release has no active occupancy');
          }
          if (active.stageId != requested.stageId) {
            throw StateError('Mentor-insight release stage does not match');
          }
          if (active.characterId != requested.characterId) {
            throw StateError('Mentor-insight release character does not match');
          }

          companion = null;
          changed = true;
      }
    }

    final next = changed
        ? MentorInsightStageOccupancySnapshot._(
            revision: snapshot.revision + 1,
            companion: companion,
          )
        : snapshot;
    return MentorInsightStageOccupancyPreparedSuccessor._(
      ownerToken: _ownerToken,
      predecessor: this,
      base: snapshot,
      next: next,
      mutations: input,
    );
  }

  /// Consumes one owner-bound prepared value and returns its new runtime.
  MentorInsightStageOccupancyRuntime commit(
    MentorInsightStageOccupancyPreparedSuccessor prepared,
  ) {
    if (!identical(prepared._ownerToken, _ownerToken)) {
      throw StateError('Prepared occupancy successor belongs to another owner');
    }
    if (!identical(prepared._predecessor, this)) {
      throw StateError('Prepared occupancy successor has another predecessor');
    }
    if (prepared._committed) {
      throw StateError('Prepared occupancy successor was already committed');
    }

    prepared._committed = true;
    return MentorInsightStageOccupancyRuntime._(
      ownerToken: _ownerToken,
      snapshot: prepared.next,
    );
  }
}
