/// Stable negative target ids for NPC-backed combat snapshots.
///
/// This helper is intentionally independent of the legacy battle engine so
/// shared snapshot assembly can use it without importing [BattleState].
abstract final class EnmityTargetId {
  const EnmityTargetId._();

  /// Returns a stable id in a namespace separate from player and slot ids.
  static int targetIdForNpcId(String npcId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in npcId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return -1000000 - hash;
  }
}
