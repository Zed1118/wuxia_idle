import 'reward_claim_key.dart';

/// The three reward layers a content clear can produce.
///
/// The layer set is fixed; which scope each layer grants into is decided by
/// the caller-supplied [RewardPolicy], never hardcoded here.
enum RewardLayer { firstClear, repeat, personalGrowth }

/// Where a granted reward lands.
///
/// - [personal]: only the claiming character receives it.
/// - [sectShared]: the whole sect receives it (e.g. unique first-clear
///   rewards), so the claim guard for this scope must be shared across all
///   characters while [personal] guards stay per character.
enum RewardScope { personal, sectShared }

/// Pure declaration of which [RewardScope] each [RewardLayer] grants into.
///
/// The layer-to-scope table is supplied by the caller (production is expected
/// to read it from yaml), so no gameplay mode table is hardcoded in the
/// domain. All three layers must be covered; a partial table fails closed.
final class RewardPolicy {
  RewardPolicy({required Map<RewardLayer, RewardScope> scopeByLayer})
    : scopeByLayer = Map.unmodifiable(_requireFullCoverage(scopeByLayer));

  final Map<RewardLayer, RewardScope> scopeByLayer;

  RewardScope scopeOf(RewardLayer layer) {
    final scope = scopeByLayer[layer];
    if (scope == null) {
      throw StateError('RewardPolicy has no scope for layer ${layer.name}');
    }
    return scope;
  }

  static Map<RewardLayer, RewardScope> _requireFullCoverage(
    Map<RewardLayer, RewardScope> scopeByLayer,
  ) {
    final missing = [
      for (final layer in RewardLayer.values)
        if (!scopeByLayer.containsKey(layer)) layer.name,
    ];
    if (missing.isNotEmpty) {
      throw ArgumentError.value(
        scopeByLayer,
        'scopeByLayer',
        'RewardPolicy must cover every RewardLayer; missing: $missing',
      );
    }
    return scopeByLayer;
  }
}

/// Thrown when a claim key has already been claimed. The guarded apply
/// callback is never executed for the rejected claim.
final class RewardAlreadyClaimedException implements Exception {
  RewardAlreadyClaimedException(this.key);

  final RewardClaimKey key;

  @override
  String toString() => 'Reward already claimed: ${key.canonical}';
}

/// One entry of a batch claim: the key to claim and the callback that applies
/// the grant.
final class RewardGrantEntry<T> {
  const RewardGrantEntry({required this.key, required this.apply});

  final RewardClaimKey key;
  final T Function() apply;
}

/// Pure in-memory duplicate-claim guard.
///
/// Semantics:
/// - A duplicate key is rejected with [RewardAlreadyClaimedException] before
///   its apply callback runs.
/// - If the apply callback throws, the key is NOT marked claimed (rollback
///   semantics); the caller may retry with the same key.
/// - A key is marked claimed only after its apply callback returns.
/// - Batches are validated up front (against existing claims and against
///   duplicates inside the batch) and every callback runs before any claim
///   state is committed, so a failing batch never leaves partial claim-ledger
///   state. Applying rewards atomically still requires the caller to run the
///   callbacks inside one transaction/outbox boundary.
///
/// Scope isolation is the caller's responsibility: use one guard instance
/// shared across characters for [RewardScope.sectShared] and one instance per
/// character for [RewardScope.personal].
final class RewardGrantGuard {
  final Set<String> _claimedKeys = <String>{};

  bool isClaimed(RewardClaimKey key) => _claimedKeys.contains(key.canonical);

  /// Claims [key] and runs [apply]. Throws [RewardAlreadyClaimedException]
  /// for duplicate keys; rethrows [apply] errors without claiming.
  T claim<T>({required RewardClaimKey key, required T Function() apply}) {
    if (isClaimed(key)) {
      throw RewardAlreadyClaimedException(key);
    }
    final result = apply();
    _claimedKeys.add(key.canonical);
    return result;
  }

  /// Claims every entry atomically in this in-memory claim ledger: all keys
  /// are validated first, then all apply callbacks run, and only afterwards
  /// are the keys committed as claimed. Any duplicate key or throwing callback
  /// leaves every entry of the batch unclaimed. Callers remain responsible for
  /// making callback side effects transactional.
  List<T> claimBatch<T>(List<RewardGrantEntry<T>> entries) {
    if (entries.isEmpty) {
      return <T>[];
    }

    final seenInBatch = <String>{};
    for (final entry in entries) {
      final canonical = entry.key.canonical;
      if (_claimedKeys.contains(canonical) || !seenInBatch.add(canonical)) {
        throw RewardAlreadyClaimedException(entry.key);
      }
    }

    final results = <T>[for (final entry in entries) entry.apply()];

    for (final entry in entries) {
      _claimedKeys.add(entry.key.canonical);
    }
    return results;
  }
}
