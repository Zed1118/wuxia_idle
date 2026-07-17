import '../../core/domain/enums.dart';
import '../defs/skill_def.dart';
import '../defs/tower_floor_def.dart';
import '../numbers_config.dart';

/// 进度内容域(爬塔/主线/闭关/Boss 蓄力)加载期红线
/// (2026-07-18 审查批C 自 GameRepository 抽出)。
///
/// 体例:顶层自由函数 + 显式参数,参数名与 GameRepository 字段名一致,
/// 方法体自抽出起逐字未改;越界抛 [StateError] 启动失败(fail-fast)。

void enforceTowerRedLines({
  required List<TowerFloorDef> towerFloors,
  required Map<String, SkillDef> skillDefs,
  required NumbersConfig numbers,
}) {
  if (towerFloors.isEmpty) return; // 允许测试 fixture 不带 towers
  if (towerFloors.length != 30) {
    throw StateError('爬塔层数应为 30，实际 ${towerFloors.length}');
  }
  const minorBossFloors = {5, 15, 25};
  const majorBossFloors = {10, 20, 30};
  final seen = <int>{};
  for (var i = 0; i < towerFloors.length; i++) {
    final f = towerFloors[i];
    if (f.floorIndex != i + 1) {
      throw StateError('爬塔层不连续：期望 floorIndex=${i + 1}，实际 ${f.floorIndex}');
    }
    if (!seen.add(f.floorIndex)) {
      throw StateError('爬塔 floorIndex 重复：${f.floorIndex}');
    }
    // Boss 分布严格校验
    final expectedKind = minorBossFloors.contains(f.floorIndex)
        ? TowerBossKind.minor
        : majorBossFloors.contains(f.floorIndex)
        ? TowerBossKind.major
        : null;
    if (f.bossKind != expectedKind) {
      throw StateError(
        '爬塔 floor=${f.floorIndex} bossKind=${f.bossKind?.name ?? "null"}，'
        '期望 ${expectedKind?.name ?? "null"}',
      );
    }
    // 普通层不得带 narrative
    if (f.bossKind == null &&
        (f.narrativeOpeningId != null || f.narrativeVictoryId != null)) {
      throw StateError('爬塔 floor=${f.floorIndex} 普通层不应配 narrative');
    }
    // 每层 1-3 个敌人
    if (f.enemyTeam.isEmpty || f.enemyTeam.length > 3) {
      throw StateError(
        '爬塔 floor=${f.floorIndex} 敌人数 ${f.enemyTeam.length}，'
        '应 ∈ [1, 3]',
      );
    }
    // Boss 层至少有一个主 Boss；20/25/30 可带护法形成多目标压力。
    if (f.bossKind != null && !f.enemyTeam.any((e) => e.isBoss)) {
      throw StateError('爬塔 Boss floor=${f.floorIndex} 至少应有 1 个 isBoss 主敌');
    }
    // §5.4 红线：Boss baseHp ≤ bossHpMax（config-driven，2026-06-14 调至 60000）
    final bossHpMax = numbers.combat.redLines.bossHpMax;
    for (final e in f.enemyTeam) {
      if (e.baseHp > bossHpMax) {
        throw StateError(
          '红线越界：爬塔 floor=${f.floorIndex} enemy=${e.id} '
          'baseHp=${e.baseHp} > $bossHpMax',
        );
      }
    }
    // 可玩性 P1a：残页只能配在 Boss 层 + id 须在 skills.yaml。
    final frag = f.dropSkillFragmentId;
    if (frag != null) {
      if (f.bossKind == null) {
        throw StateError(
          '爬塔 floor=${f.floorIndex} 配 dropSkillFragmentId 但非 Boss 层(P1a §二红线)',
        );
      }
      if (skillDefs[frag] == null) {
        throw StateError(
          '爬塔 floor=${f.floorIndex} dropSkillFragmentId=$frag 未在 skills.yaml(P1a §二红线)',
        );
      }
    }
  }
}
