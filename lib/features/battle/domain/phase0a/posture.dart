/// Pure posture domain candidate for the M1 contract.
///
/// This module has no production wiring, repositories, or gameplay defaults.
enum PostureRecoveryPolicy { reset, recover }

enum PostureHitKind { light, heavy, bossControl }

enum PostureEventType {
  postureDamageApplied,
  postureDamageOverflow,
  lightHitIgnoredByPoise,
  vulnerabilityEntered,
  postureDamageSuppressedDuringVulnerability,
  vulnerabilityEnded,
  postureReset,
  postureRecovered,
}

final class PostureConfig {
  PostureConfig({
    required this.capacity,
    required this.vulnerabilityTicks,
    required this.recoveryPolicy,
    required this.postVulnerabilityAccumulated,
  }) {
    _requireFiniteNonNegative(capacity, 'capacity');
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
    if (vulnerabilityTicks <= 0) {
      throw ArgumentError.value(
        vulnerabilityTicks,
        'vulnerabilityTicks',
        'must be positive',
      );
    }
    _requireFiniteNonNegative(
      postVulnerabilityAccumulated,
      'postVulnerabilityAccumulated',
    );
    if (postVulnerabilityAccumulated > capacity) {
      throw ArgumentError.value(
        postVulnerabilityAccumulated,
        'postVulnerabilityAccumulated',
        'must not exceed capacity',
      );
    }
    if (recoveryPolicy == PostureRecoveryPolicy.reset &&
        postVulnerabilityAccumulated != 0) {
      throw ArgumentError.value(
        postVulnerabilityAccumulated,
        'postVulnerabilityAccumulated',
        'reset policy requires zero accumulated posture',
      );
    }
  }

  final double capacity;
  final int vulnerabilityTicks;
  final PostureRecoveryPolicy recoveryPolicy;
  final double postVulnerabilityAccumulated;
}

final class PostureEvent {
  const PostureEvent(this.type, {this.amount = 0});

  final PostureEventType type;
  final double amount;

  @override
  bool operator ==(Object other) =>
      other is PostureEvent && other.type == type && other.amount == amount;

  @override
  int get hashCode => Object.hash(type, amount);
}

final class PostureTransition {
  const PostureTransition(this.state, this.events);

  final PostureState state;
  final List<PostureEvent> events;

  @override
  bool operator ==(Object other) =>
      other is PostureTransition &&
      other.state == state &&
      _eventsEqual(other.events, events);

  @override
  int get hashCode => Object.hash(state, Object.hashAll(events));
}

final class PostureState {
  const PostureState._({
    required this.config,
    required this.accumulated,
    required this.vulnerabilityTicksRemaining,
  });

  factory PostureState.initial(PostureConfig config) => PostureState._(
    config: config,
    accumulated: 0,
    vulnerabilityTicksRemaining: 0,
  );

  final PostureConfig config;
  final double accumulated;
  final int vulnerabilityTicksRemaining;

  bool get isVulnerable => vulnerabilityTicksRemaining > 0;

  PostureTransition apply(
    double damage, {
    PostureHitKind? hitKind,
    bool hasPoise = false,
  }) {
    _requireFiniteNonNegative(damage, 'damage');
    final events = <PostureEvent>[];
    if (hitKind == PostureHitKind.light && hasPoise) {
      events.add(const PostureEvent(PostureEventType.lightHitIgnoredByPoise));
    }
    if (isVulnerable) {
      if (damage > 0) {
        events.add(
          const PostureEvent(
            PostureEventType.postureDamageSuppressedDuringVulnerability,
          ),
        );
      }
      return PostureTransition(this, List.unmodifiable(events));
    }
    if (damage == 0) {
      return PostureTransition(this, List.unmodifiable(events));
    }

    final available = config.capacity - accumulated;
    final applied = damage < available ? damage : available;
    final overflow = damage - applied;
    var nextTicks = vulnerabilityTicksRemaining;
    var nextAccumulated = accumulated + applied;
    events.add(
      PostureEvent(PostureEventType.postureDamageApplied, amount: applied),
    );
    if (overflow > 0) {
      events.add(
        PostureEvent(PostureEventType.postureDamageOverflow, amount: overflow),
      );
    }
    if (nextAccumulated >= config.capacity) {
      nextAccumulated = config.capacity;
      nextTicks = config.vulnerabilityTicks;
      events.add(
        PostureEvent(
          PostureEventType.vulnerabilityEntered,
          amount: config.vulnerabilityTicks.toDouble(),
        ),
      );
    }
    return PostureTransition(
      PostureState._(
        config: config,
        accumulated: nextAccumulated,
        vulnerabilityTicksRemaining: nextTicks,
      ),
      List.unmodifiable(events),
    );
  }

  PostureTransition advance(int ticks) {
    if (ticks <= 0) {
      throw ArgumentError.value(ticks, 'ticks', 'must be positive');
    }
    if (!isVulnerable || ticks < vulnerabilityTicksRemaining) {
      return PostureTransition(
        PostureState._(
          config: config,
          accumulated: accumulated,
          vulnerabilityTicksRemaining: isVulnerable
              ? vulnerabilityTicksRemaining - ticks
              : vulnerabilityTicksRemaining,
        ),
        const [],
      );
    }
    final events = <PostureEvent>[
      const PostureEvent(PostureEventType.vulnerabilityEnded),
    ];
    final recovered = config.postVulnerabilityAccumulated;
    events.add(
      PostureEvent(
        config.recoveryPolicy == PostureRecoveryPolicy.reset
            ? PostureEventType.postureReset
            : PostureEventType.postureRecovered,
        amount: recovered,
      ),
    );
    return PostureTransition(
      PostureState._(
        config: config,
        accumulated: recovered,
        vulnerabilityTicksRemaining: 0,
      ),
      List.unmodifiable(events),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PostureState &&
      other.config == config &&
      other.accumulated == accumulated &&
      other.vulnerabilityTicksRemaining == vulnerabilityTicksRemaining;

  @override
  int get hashCode =>
      Object.hash(config, accumulated, vulnerabilityTicksRemaining);
}

double bossControlToPostureDamage(
  double controlStrength, {
  required double conversionFactor,
}) {
  _requireFiniteNonNegative(controlStrength, 'controlStrength');
  _requireFiniteNonNegative(conversionFactor, 'conversionFactor');
  return controlStrength * conversionFactor;
}

void _requireFiniteNonNegative(double value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'must be finite and non-negative');
  }
}

bool _eventsEqual(List<PostureEvent> a, List<PostureEvent> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
