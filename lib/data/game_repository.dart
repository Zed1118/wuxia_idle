import 'package:flutter/services.dart' show rootBundle;

import 'defs/equipment_def.dart';
import 'defs/realm_def.dart';
import 'defs/seclusion_map_def.dart';
import 'defs/skill_def.dart';
import 'defs/stage_def.dart';
import 'defs/technique_def.dart';
import 'defs/tower_floor_def.dart';
import 'models/enums.dart';
import 'numbers_config.dart';
import 'yaml_loader.dart';

/// 全局配置仓储（启动时一次性把 `data/*.yaml` 加载到内存）。
///
/// 加载顺序：本仓储先于 [IsarSetup.init]，见 `main.dart`。
///
/// 红线校验在 [loadAllDefs] 末尾执行；任何越界（装备攻击 > 2000、
/// 内力上限不在 [500, 15000]）直接抛 [StateError]，启动失败。
class GameRepository {
  static GameRepository? _instance;

  /// 已初始化的全局实例。未调用 [loadAllDefs] 直接访问会抛 [StateError]。
  static GameRepository get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('GameRepository 未初始化，请先调用 loadAllDefs()');
    }
    return i;
  }

  /// 是否已加载（test 多次 setUp 复用判断用）。
  static bool get isLoaded => _instance != null;

  final NumbersConfig numbers;
  final List<RealmDef> realms;
  final Map<String, EquipmentDef> equipmentDefs;
  final Map<String, TechniqueDef> techniqueDefs;
  final Map<String, SkillDef> skillDefs;
  final Map<String, StageDef> stageDefs;

  /// 爬塔 30 层，按 floorIndex 升序（1..30）。
  /// 索引方式：`towerFloors[floorIndex - 1]`（红线校验保证 1-30 连续唯一）。
  final List<TowerFloorDef> towerFloors;

  /// 闭关地图 5 张（numbers.yaml `retreat.maps`，Phase 3 T47）。
  final List<SeclusionMapDef> seclusionMaps;

  GameRepository._({
    required this.numbers,
    required this.realms,
    required this.equipmentDefs,
    required this.techniqueDefs,
    required this.skillDefs,
    required this.stageDefs,
    required this.towerFloors,
    required this.seclusionMaps,
  });

  /// 启动时一次性加载全部 yaml 配置。
  ///
  /// [loader] 可注入：生产用 [rootBundle.loadString]，测试可传内存字符串
  /// 加载器。任何 yaml 缺失 / 语法错 / 红线越界都直接抛异常（fail fast）。
  static Future<GameRepository> loadAllDefs({
    Future<String> Function(String path)? loader,
  }) async {
    final load = loader ?? rootBundle.loadString;

    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
    final equipmentDefs = _parseDefMap(
      equipmentRaw['equipment'] as List,
      EquipmentDef.fromYaml,
      idOf: (d) => d.id,
    );
    final techniqueDefs = _parseDefMap(
      techniquesRaw['techniques'] as List,
      TechniqueDef.fromYaml,
      idOf: (d) => d.id,
    );
    final skillDefs = _parseDefMap(
      skillsRaw['skills'] as List,
      SkillDef.fromYaml,
      idOf: (d) => d.id,
    );
    final stageDefs = _parseDefMap(
      stagesRaw['stages'] as List,
      StageDef.fromYaml,
      idOf: (d) => d.id,
    );
    final towerFloors = ((towersRaw['floors'] as List?) ?? const [])
        .map((e) => TowerFloorDef.fromYaml(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false)
      ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));

    final repo = GameRepository._(
      numbers: numbers,
      realms: realms,
      equipmentDefs: equipmentDefs,
      techniqueDefs: techniqueDefs,
      skillDefs: skillDefs,
      stageDefs: stageDefs,
      towerFloors: towerFloors,
      seclusionMaps: numbers.retreat.maps,
    );
    repo._enforceRedLines();
    _instance = repo;
    return repo;
  }

  /// 把 numbers.yaml 嵌套的 `realms.tiers[].layers[]` 展平为 49 行 [RealmDef]。
  static List<RealmDef> _parseRealms(Map<String, dynamic> realmsSection) {
    final tiers = realmsSection['tiers'] as List;
    final out = <RealmDef>[];
    for (final t in tiers) {
      final tier = RealmTier.values.byName(t['tier'] as String);
      final eqCap =
          EquipmentTier.values.byName(t['equipment_tier_cap'] as String);
      final techCap =
          TechniqueTier.values.byName(t['technique_tier_cap'] as String);
      for (final l in (t['layers'] as List)) {
        out.add(RealmDef(
          tier: tier,
          layer: RealmLayer.values.byName(l['layer'] as String),
          absoluteLevel: (l['absolute_level'] as num).toInt(),
          internalForceMax: (l['internal_force_max'] as num).toInt(),
          experienceToNext: (l['experience_to_next'] as num).toInt(),
          equipmentTierCap: eqCap,
          techniqueTierCap: techCap,
        ));
      }
    }
    return out;
  }

  static Map<String, T> _parseDefMap<T>(
    List items,
    T Function(Map<String, dynamic>) parser, {
    required String Function(T) idOf,
  }) {
    final m = <String, T>{};
    for (final raw in items) {
      final def = parser(Map<String, dynamic>.from(raw as Map));
      final id = idOf(def);
      if (m.containsKey(id)) {
        throw StateError('重复 def id: $id');
      }
      m[id] = def;
    }
    return m;
  }

  /// 启动期红线校验（GDD §5.2 + phase1_tasks T07 验收）。
  void _enforceRedLines() {
    if (realms.length != 49) {
      throw StateError('RealmDef 行数应为 49，实际 ${realms.length}');
    }
    for (final r in realms) {
      if (r.internalForceMax < 500 || r.internalForceMax > 15000) {
        throw StateError(
          '红线越界：${r.tier.name}/${r.layer.name} '
          'internalForceMax=${r.internalForceMax}，应 ∈ [500, 15000]',
        );
      }
    }
    for (final e in equipmentDefs.values) {
      if (e.baseAttackMax > 2000) {
        throw StateError(
          '红线越界：装备 ${e.id} baseAttackMax=${e.baseAttackMax} > 2000',
        );
      }
      if (e.baseAttackMin < 0 || e.baseAttackMin > e.baseAttackMax) {
        throw StateError(
          '装备 ${e.id} baseAttackMin/Max 不合法：'
          '${e.baseAttackMin}/${e.baseAttackMax}',
        );
      }
    }
    // Phase 3 T33：stage 链路校验。prevStageId 必须能找到，
    // 且与本关同 chapterIndex（防跨章引用 / 错字 id）。
    for (final s in stageDefs.values) {
      final prev = s.prevStageId;
      if (prev == null) continue;
      final prevDef = stageDefs[prev];
      if (prevDef == null) {
        throw StateError(
          'stage ${s.id} prevStageId=$prev 引用不存在的关卡',
        );
      }
      if (s.chapterIndex != null &&
          prevDef.chapterIndex != null &&
          s.chapterIndex != prevDef.chapterIndex) {
        throw StateError(
          'stage ${s.id} (ch=${s.chapterIndex}) 与 prevStageId=$prev '
          '(ch=${prevDef.chapterIndex}) 跨章引用',
        );
      }
    }

    // Phase 3 T40：爬塔 30 层校验
    //   - floorIndex 1-30 连续唯一
    //   - bossKind 严格在 5/10/15/20/25/30
    //   - 普通层 narrativeOpeningId / narrativeVictoryId 必须为 null
    //   - Boss HP ≤ 50000（§5.4 红线）
    _enforceTowerRedLines();

    // Phase 3 T47：闭关地图 5 张校验
    _enforceSeclusionRedLines();
  }

  void _enforceTowerRedLines() {
    if (towerFloors.isEmpty) return; // 允许测试 fixture 不带 towers
    if (towerFloors.length != 30) {
      throw StateError(
        '爬塔层数应为 30，实际 ${towerFloors.length}',
      );
    }
    const minorBossFloors = {5, 15, 25};
    const majorBossFloors = {10, 20, 30};
    final seen = <int>{};
    for (var i = 0; i < towerFloors.length; i++) {
      final f = towerFloors[i];
      if (f.floorIndex != i + 1) {
        throw StateError(
          '爬塔层不连续：期望 floorIndex=${i + 1}，实际 ${f.floorIndex}',
        );
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
        throw StateError(
          '爬塔 floor=${f.floorIndex} 普通层不应配 narrative',
        );
      }
      // 每层 1-3 个敌人
      if (f.enemyTeam.isEmpty || f.enemyTeam.length > 3) {
        throw StateError(
          '爬塔 floor=${f.floorIndex} 敌人数 ${f.enemyTeam.length}，'
          '应 ∈ [1, 3]',
        );
      }
      // Boss 层固定 1 个敌人
      if (f.bossKind != null && f.enemyTeam.length != 1) {
        throw StateError(
          '爬塔 Boss floor=${f.floorIndex} 应为 1 个敌人，'
          '实际 ${f.enemyTeam.length}',
        );
      }
      // §5.4 红线：Boss HP ≤ 50000
      for (final e in f.enemyTeam) {
        if (e.baseHp > 50000) {
          throw StateError(
            '红线越界：爬塔 floor=${f.floorIndex} enemy=${e.id} '
            'baseHp=${e.baseHp} > 50000',
          );
        }
      }
    }
  }

  void _enforceSeclusionRedLines() {
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
        throw StateError(
          '闭关地图 ${m.mapType.name} mojianshiPerHour 必须 > 0',
        );
      }
    }
    final config = numbers.retreat;
    if (config.capHours < 1 || config.capHours > 168) {
      throw StateError(
        '闭关 capHours=${config.capHours}，应 ∈ [1, 168]',
      );
    }
  }

  /// 测试用：清空全局实例。生产代码不要调用。
  static void resetForTest() {
    _instance = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 便捷查询
  // ─────────────────────────────────────────────────────────────────────────

  RealmDef getRealm(RealmTier tier, RealmLayer layer) {
    return realms.firstWhere(
      (r) => r.tier == tier && r.layer == layer,
      orElse: () =>
          throw StateError('境界 ${tier.name}/${layer.name} 未配置'),
    );
  }

  RealmDef getRealmByAbsoluteLevel(int level) {
    if (level < 1 || level > 49) {
      throw RangeError('absoluteLevel 必须 ∈ [1, 49]，实际 $level');
    }
    return realms[level - 1];
  }

  EquipmentDef getEquipment(String defId) =>
      equipmentDefs[defId] ??
      (throw StateError('EquipmentDef 未配置: $defId'));

  TechniqueDef getTechnique(String defId) =>
      techniqueDefs[defId] ??
      (throw StateError('TechniqueDef 未配置: $defId'));

  SkillDef getSkill(String defId) =>
      skillDefs[defId] ??
      (throw StateError('SkillDef 未配置: $defId'));

  StageDef getStage(String defId) =>
      stageDefs[defId] ??
      (throw StateError('StageDef 未配置: $defId'));

  /// 取第 N 层爬塔（1-30）。越界抛 [RangeError]。
  TowerFloorDef getTowerFloor(int floorIndex) {
    if (floorIndex < 1 || floorIndex > 30) {
      throw RangeError('爬塔 floorIndex 必须 ∈ [1, 30]，实际 $floorIndex');
    }
    return towerFloors[floorIndex - 1];
  }

  /// 按地图类型取闭关地图定义。未配置时抛 [StateError]。
  SeclusionMapDef getSeclusionMap(RetreatMapType mapType) =>
      seclusionMaps.firstWhere(
        (m) => m.mapType == mapType,
        orElse: () =>
            throw StateError('SeclusionMapDef 未配置: ${mapType.name}'),
      );
}
