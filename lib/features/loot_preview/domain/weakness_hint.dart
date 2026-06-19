// lib/features/loot_preview/domain/weakness_hint.dart
import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';
import '../../battle/domain/enum_localizations.dart';

/// 第七阶段批二②「弱点/抗性 事后可查」纯派生（drop_rumor 兄弟）。
///
/// 由关卡 Boss 敌人的 [EnemyDef.schoolDamageTakenMult] 派生水墨提示行：
///   - mult > 1.0（弱点）→「似惧 X 路数」
///   - mult < 1.0（抗性）→「X 路难伤」
///   - mult == 1.0 / 无条目 → 不出行（常见情况空）
///
/// **门控**（§5.7 先感受问题再给答案）：仅 [cleared]==true 才返回内容，否则空。
/// **Boss 取舍**：取 [enemyTeam] 中 `isBoss==true` 的敌人；无标记则回退到队首
/// （单敌关卡）。多敌只看 Boss，不汇总小兵。
///
/// 纯函数（无 BuildContext / 无 Isar），呈现层 [WeaknessHintLines] 薄壳渲染。
List<String> weaknessHintLines(
  List<EnemyDef> enemyTeam, {
  required bool cleared,
}) {
  if (!cleared || enemyTeam.isEmpty) return const [];
  final boss = _bossOf(enemyTeam);
  final mult = boss?.schoolDamageTakenMult;
  if (mult == null || mult.isEmpty) return const [];

  final lines = <String>[];
  // 流派枚举顺序稳定（gangMeng/lingQiao/yinRou），保证行序确定。
  for (final school in TechniqueSchool.values) {
    final v = mult[school];
    if (v == null) continue;
    final name = EnumL10n.school(school);
    if (v > 1.0) {
      lines.add(UiStrings.weaknessHintWeak(name));
    } else if (v < 1.0) {
      lines.add(UiStrings.weaknessHintResist(name));
    }
    // v == 1.0：中性，不出行。
  }
  return lines;
}

/// 取队伍中的 Boss（isBoss==true 优先；无标记回退队首，覆盖单敌关卡）。
EnemyDef? _bossOf(List<EnemyDef> enemyTeam) {
  for (final e in enemyTeam) {
    if (e.isBoss) return e;
  }
  return enemyTeam.isNotEmpty ? enemyTeam.first : null;
}
