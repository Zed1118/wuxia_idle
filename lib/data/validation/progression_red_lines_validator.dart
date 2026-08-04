import '../../core/domain/enums.dart';
import '../defs/seclusion_map_def.dart';
import '../defs/skill_def.dart';
import '../defs/stage_def.dart';
import '../defs/progression_release_cap.dart';
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
  // 1:1 锚死（spec 2026-08-01 §7）：floor N ↔ 境界绝对层 N，故塔层数不得
  // 超过境界总层数。层数本身由 towers.yaml 定义，代码不写死具体值——
  // 上界是约束语义，具体层数是数据事实（memory feedback_red_line_test_semantics）。
  if (towerFloors.length > ProgressionReleaseCap.maxRealmLayers) {
    throw StateError(
      '爬塔层数 ${towerFloors.length} 超过境界总层数 '
      '${ProgressionReleaseCap.maxRealmLayers}（1:1 锚死上界）',
    );
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

/// Phase 3 T47:闭关地图 5 张校验。
void enforceSeclusionRedLines({
  required List<SeclusionMapDef> seclusionMaps,
  required NumbersConfig numbers,
}) {
  if (seclusionMaps.length != 5) {
    throw StateError('闭关地图应为 5 张，实际 ${seclusionMaps.length}');
  }
  final seen = <RetreatMapType>{};
  for (final m in seclusionMaps) {
    if (!seen.add(m.mapType)) {
      throw StateError('闭关地图类型重复：${m.mapType.name}');
    }
    if (!RetreatMapType.values.contains(m.mapType)) {
      throw StateError('未知闭关地图类型：${m.mapType.name}');
    }
    if (m.mojianshiPerHour <= 0) {
      throw StateError('闭关地图 ${m.mapType.name} mojianshiPerHour 必须 > 0');
    }
  }
  final config = numbers.retreat;
  if (config.capHours < 1 || config.capHours > 168) {
    throw StateError('闭关 capHours=${config.capHours}，应 ∈ [1, 168]');
  }
}

/// Phase 3 Week 5 T59 主线红线(2026-05-21 P2 Ch4 spec 漏检放开:动态 chapter 数)。
///
/// 校验项:
///   - mainline stages 总数 == 5 * chapterCount(每章 5 关固定)
///   - chapterIndex 必须从 1 起连续递增({1..N},不跳号)
///   - 每个 chapter 必须正好 5 关
///   - narrativeDefeatId != null 时 isBossStage 必须 true(避免章内
///     普通关误配 defeat 文案)
///
/// 章内具体哪几关是 Boss 由 yaml 决定(当前约定 4/5 为 Boss),但本红线
/// 不硬绑位置,只要求 defeat 文案与 Boss 标记一致。
void enforceMainlineRedLines({required Map<String, StageDef> stageDefs}) {
  final mainlines = stageDefs.values
      .where((s) => s.stageType == StageType.mainline)
      .toList();
  if (mainlines.isEmpty) return; // 允许测试 fixture 不带主线
  final byChapter = <int, List<StageDef>>{};
  for (final s in mainlines) {
    final ch = s.chapterIndex;
    if (ch == null) {
      throw StateError('主线 stage ${s.id} 缺 chapterIndex');
    }
    byChapter.putIfAbsent(ch, () => []).add(s);
  }
  final chapters = byChapter.keys.toList()..sort();
  final maxCh = chapters.last;
  // 必须从 1 起连续递增(不跳号)
  for (var i = 0; i < chapters.length; i++) {
    if (chapters[i] != i + 1) {
      throw StateError('主线 chapterIndex 必须从 1 起连续递增,实际 $chapters');
    }
  }
  // 每章必须正好 5 关
  for (final ch in chapters) {
    final inCh = byChapter[ch]!;
    if (inCh.length != 5) {
      throw StateError('主线 ch=$ch 应有 5 关,实际 ${inCh.length}');
    }
  }
  // 总数 == 5 * chapterCount
  if (mainlines.length != 5 * maxCh) {
    throw StateError(
      '主线关卡应为 ${5 * maxCh} 关($maxCh 章 × 5 关),实际 ${mainlines.length}',
    );
  }
  for (final s in mainlines) {
    if (s.narrativeDefeatId != null && !s.isBossStage) {
      throw StateError(
        '主线 stage ${s.id} 配 narrativeDefeatId 但 isBossStage=false,'
        '战败剧情只应在 Boss 关触发',
      );
    }
  }
}
