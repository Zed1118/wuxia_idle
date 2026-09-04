enum CombatContentKind { mainline, tower }

/// Internal content identity used by shared combat host factories.
final class CombatContentRef {
  const CombatContentRef.mainline(this.contentId)
    : kind = CombatContentKind.mainline,
      assert(contentId != '');

  const CombatContentRef.tower(this.contentId)
    : kind = CombatContentKind.tower,
      assert(contentId != '');

  final CombatContentKind kind;
  final String contentId;

  @override
  bool operator ==(Object other) =>
      other is CombatContentRef &&
      other.kind == kind &&
      other.contentId == contentId;

  @override
  int get hashCode => Object.hash(kind, contentId);
}
