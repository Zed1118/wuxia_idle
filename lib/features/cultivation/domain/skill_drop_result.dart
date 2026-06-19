/// 第七阶段批二 ④：一场战斗后技能书掉落的结果(供战后珍稀展示分层)。
class SkillDropResult {
  /// 真解首通本次新授的招 id；null=未授(非首通/重复)。
  final String? manualGranted;

  /// 本次掉的残页招 id；null=本次未掉残页。
  final String? fragmentSkillId;

  /// 残页本次掉后的累计页数(仅 fragmentSkillId!=null 时有意义)。
  final int fragmentCount;

  /// 残页集齐阈值。
  final int fragmentThreshold;

  /// 本次掉残页恰好触发集齐解锁。
  final bool fragmentJustUnlocked;

  const SkillDropResult({
    this.manualGranted,
    this.fragmentSkillId,
    this.fragmentCount = 0,
    this.fragmentThreshold = 0,
    this.fragmentJustUnlocked = false,
  });

  static const none = SkillDropResult();

  /// 重仪式(真解首通 或 残页集齐解锁)。
  bool get isMajor => manualGranted != null || fragmentJustUnlocked;

  /// 轻提示(掉残页但未集齐)。
  bool get isMinorFragment => fragmentSkillId != null && !fragmentJustUnlocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillDropResult &&
          runtimeType == other.runtimeType &&
          manualGranted == other.manualGranted &&
          fragmentSkillId == other.fragmentSkillId &&
          fragmentCount == other.fragmentCount &&
          fragmentThreshold == other.fragmentThreshold &&
          fragmentJustUnlocked == other.fragmentJustUnlocked;

  @override
  int get hashCode => Object.hash(
        manualGranted,
        fragmentSkillId,
        fragmentCount,
        fragmentThreshold,
        fragmentJustUnlocked,
      );

  @override
  String toString() => 'SkillDropResult('
      'manualGranted: $manualGranted, '
      'fragmentSkillId: $fragmentSkillId, '
      'fragmentCount: $fragmentCount, '
      'fragmentThreshold: $fragmentThreshold, '
      'fragmentJustUnlocked: $fragmentJustUnlocked)';
}
