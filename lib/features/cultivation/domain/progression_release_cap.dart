final class ProgressionReleaseCap {
  const ProgressionReleaseCap({required this.maxAbsoluteRealmLevel});

  static const int maxRealmLayers = 49;

  final int maxAbsoluteRealmLevel;

  factory ProgressionReleaseCap.fromYaml(Map<String, dynamic>? yaml) {
    final releaseCap = yaml?['release_cap'] as Map?;
    final level =
        (releaseCap?['max_absolute_realm_level'] as num?)?.toInt() ??
        maxRealmLayers;
    if (level < 1 || level > maxRealmLayers) {
      throw StateError(
        'progression.release_cap.max_absolute_realm_level must be between '
        '1 and $maxRealmLayers, got $level',
      );
    }
    return ProgressionReleaseCap(maxAbsoluteRealmLevel: level);
  }
}
