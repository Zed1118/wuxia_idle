import 'package:flutter/services.dart' show rootBundle;

import 'defs/equipment_def.dart';
import 'defs/realm_def.dart';
import 'defs/skill_def.dart';
import 'defs/stage_def.dart';
import 'defs/technique_def.dart';
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

  GameRepository._({
    required this.numbers,
    required this.realms,
    required this.equipmentDefs,
    required this.techniqueDefs,
    required this.skillDefs,
    required this.stageDefs,
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

    final repo = GameRepository._(
      numbers: numbers,
      realms: realms,
      equipmentDefs: equipmentDefs,
      techniqueDefs: techniqueDefs,
      skillDefs: skillDefs,
      stageDefs: stageDefs,
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
}
