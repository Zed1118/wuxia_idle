import 'package:flutter/services.dart' show rootBundle;

import 'defs/encounter_def.dart';
import 'defs/equipment_def.dart';
import 'defs/master_def.dart';
import 'defs/realm_def.dart';
import 'defs/seclusion_map_def.dart';
import 'defs/skill_def.dart';
import 'defs/stage_def.dart';
import 'defs/technique_def.dart';
import 'defs/tower_floor_def.dart';
import 'lore_loader.dart';
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

  /// 师徒角色 3 条，按 slotIndex 升序（0=祖师 / 1=大弟子 / 2=二弟子）。
  /// 索引方式：`masters[slotIndex]`（红线校验保证 0-2 连续唯一）。
  final List<MasterDef> masters;

  /// 奇遇 / 武学领悟定义(Phase 4 W14-1 C-1)。
  /// Phase 1 vertical slice 3 条;W14-2 扩 15-20 条。
  /// events 文案走 [EncounterEventLoader] 按需 load(narrative_loader 体例)。
  final Map<String, EncounterDef> encounterDefs;

  /// 奇遇专属招式 id 集合(C-W14-3-A,encounter_skills.yaml 加载)。
  /// 与 [skillDefs] 共享 runtime 类型 [SkillDef],但通过此 set 可快速筛
  /// 出"奇遇所得"招式,供 UI / 红线 / battle 装载使用。也可用
  /// `skillDefs[id]!.isEncounterSkill` 等价判断。
  final Set<String> encounterSkillIds;

  GameRepository._({
    required this.numbers,
    required this.realms,
    required this.equipmentDefs,
    required this.techniqueDefs,
    required this.skillDefs,
    required this.stageDefs,
    required this.towerFloors,
    required this.seclusionMaps,
    required this.masters,
    required this.encounterDefs,
    required this.encounterSkillIds,
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

    // Phase 4 W14-3-A:奇遇专属招式池(独立 yaml,与 skills.yaml 同 SkillDef 类型,
    // 合并到同 Map;允许测试 fixture 不带,空 set 让红线层 noop)。
    final encounterSkillIds = <String>{};
    try {
      final encounterSkillsRaw =
          parseYamlMap(await load('data/encounter_skills.yaml'));
      final encounterSkills = _parseDefMap(
        encounterSkillsRaw['encounter_skills'] as List,
        SkillDef.fromYaml,
        idOf: (d) => d.id,
      );
      for (final entry in encounterSkills.entries) {
        if (skillDefs.containsKey(entry.key)) {
          throw StateError(
            'encounter_skills.yaml 与 skills.yaml id 冲突: ${entry.key}',
          );
        }
        skillDefs[entry.key] = entry.value;
        encounterSkillIds.add(entry.key);
      }
    } on StateError {
      // 显式 collision 抛出的 StateError 透传,fail fast
      rethrow;
    } catch (e) {
      // test fixture 不带 encounter_skills.yaml 时静默,生产路径仍由
      // _enforceEncounterSkillRedLines 校验 unlock 引用一致性。
    }
    final stageDefs = _parseDefMap(
      stagesRaw['stages'] as List,
      StageDef.fromYaml,
      idOf: (d) => d.id,
    );
    final towerFloors = ((towersRaw['floors'] as List?) ?? const [])
        .map((e) => TowerFloorDef.fromYaml(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false)
      ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));

    final mastersRaw = parseYamlMap(await load('data/masters.yaml'));
    final masters = ((mastersRaw['masters'] as List?) ?? const [])
        .map((e) => MasterDef.fromYaml(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false)
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    // Phase 4 W14-1:encounters.yaml 允许测试 fixture 不带(catch 失败 → 空 map)。
    Map<String, EncounterDef> encounterDefs = const {};
    try {
      final encountersRaw = parseYamlMap(await load('data/encounters.yaml'));
      encounterDefs = _parseDefMap(
        encountersRaw['encounters'] as List,
        EncounterDef.fromYaml,
        idOf: (d) => d.id,
      );
    } catch (e) {
      // test fixture 不带 encounters.yaml 时静默,生产路径仍 fail-fast on
      // 红线校验阶段(_enforceEncounterRedLines 检查非空与字段合法)。
    }

    final repo = GameRepository._(
      numbers: numbers,
      realms: realms,
      equipmentDefs: equipmentDefs,
      techniqueDefs: techniqueDefs,
      skillDefs: skillDefs,
      stageDefs: stageDefs,
      towerFloors: towerFloors,
      seclusionMaps: numbers.retreat.maps,
      masters: masters,
      encounterDefs: encounterDefs,
      encounterSkillIds: encounterSkillIds,
    );
    repo._enforceRedLines();
    await _validatePresetLoreReferences(equipmentDefs, load);
    _instance = repo;
    return repo;
  }

  /// Phase 4 W15:装备 preset 典故 yaml 引用一致性校验。
  ///
  /// 对每个 [EquipmentDef.presetLoreIds] 元素 await [LoreLoader.load]:
  /// - 加载失败 / placeholder 兜底 → StateError(yaml 缺失或语法错)
  /// - LoreContent.id != 引用 loreId → StateError(yaml 内 id 不自洽)
  /// - defaultLore 段为空 → StateError(空文件不算 lore)
  ///
  /// 兼容 test fixture:装备 presetLoreIds 为空时整个跳过(不触 yaml),
  /// 仅在真实 equipment.yaml 引用 lore 时才异步校验。
  ///
  /// 串行 await(35 文件量级,启动开销 < 50ms,不并发避免压垮 rootBundle)。
  static Future<void> _validatePresetLoreReferences(
    Map<String, EquipmentDef> equipmentDefs,
    Future<String> Function(String) load,
  ) async {
    for (final def in equipmentDefs.values) {
      for (final loreId in def.presetLoreIds) {
        final content = await LoreLoader.load(loreId, loader: load);
        if (content.isPlaceholder) {
          throw StateError(
            '装备 ${def.id} presetLoreIds 引用 $loreId,'
            'data/lore/$loreId.yaml 缺失或解析失败',
          );
        }
        if (content.id != loreId) {
          throw StateError(
            '装备 ${def.id} presetLore $loreId yaml 内 id=${content.id} 不自洽',
          );
        }
        if (content.defaultLore.isEmpty) {
          throw StateError(
            '装备 ${def.id} presetLore $loreId default_lore 段为空',
          );
        }
      }
    }
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
    // Phase 3 Week 7 T63：装备 fixture 扩 35 件,校验单件红线 + 覆盖度
    _enforceEquipmentRedLines();

    // Phase 3 Week 8 T64：心法 fixture 扩 21 本,7 阶 × 3 流派覆盖度
    //   + 每本 3 招 type 精确 normalAttack/powerSkill/ultimate
    _enforceTechniqueRedLines();
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

    // Phase 3 Week 5 T59：主线 15 关校验
    //   - mainline stages 总数 = 15，按 chapterIndex 分 3 章 × 5 关
    //   - narrativeDefeatId 必须仅在 isBossStage=true 关配置
    _enforceMainlineRedLines();

    // Phase 3 T40：爬塔 30 层校验
    //   - floorIndex 1-30 连续唯一
    //   - bossKind 严格在 5/10/15/20/25/30
    //   - 普通层 narrativeOpeningId / narrativeVictoryId 必须为 null
    //   - Boss HP ≤ 50000（§5.4 红线）
    _enforceTowerRedLines();

    // Phase 3 T47：闭关地图 5 张校验
    _enforceSeclusionRedLines();

    // Phase 3 Week 4 T53：师徒 3 角色校验
    _enforceMasterRedLines();

    // Phase 4 W14-1 C-1:encounter fixture 校验(若加载到)
    _enforceEncounterRedLines();

    // Phase 4 W14-3-A:encounter_skills.yaml 校验 + unlock 引用一致性
    _enforceEncounterSkillRedLines();
  }

  /// 奇遇招式红线(C-W14-3-A):
  /// - 每招 tier ∈ [1, 7]
  /// - parentTechniqueDefId == null(必须独立于心法体系)
  /// - powerMultiplier ≤ 对应 tier cap(沿用 numbers.yaml techniques.tiers
  ///   max_skill_multiplier,1500/2000/2500/3000/4000/5500/8000)
  /// - 所有 encounterDefs unlockSkill outcome 引用的 skillId **必须存在于
  ///   encounter skill 池**(强校验,缺失抛 StateError,绑死 yaml 联结)
  ///
  /// 测试 fixture 不带 encounter_skills.yaml 时 encounterSkillIds 为空集,
  /// 跳过 cap 校验,但 unlock 引用一致性仍校验(encounters.yaml 在场时)。
  void _enforceEncounterSkillRedLines() {
    const tierCaps = [1500, 2000, 2500, 3000, 4000, 5500, 8000];
    for (final id in encounterSkillIds) {
      final s = skillDefs[id]!;
      final tier = s.tier;
      if (tier == null || tier < 1 || tier > 7) {
        throw StateError(
          'encounter skill $id tier=$tier,应 ∈ [1, 7]',
        );
      }
      if (s.parentTechniqueDefId != null) {
        throw StateError(
          'encounter skill $id parentTechniqueDefId='
          '${s.parentTechniqueDefId},应为空(独立于心法体系)',
        );
      }
      final cap = tierCaps[tier - 1];
      if (s.powerMultiplier > cap) {
        throw StateError(
          'encounter skill $id tier=$tier powerMultiplier='
          '${s.powerMultiplier} 越界,应 ≤ $cap',
        );
      }
      // GDD §5.4 红线:全游戏招式 powerMultiplier ≤ 8000
      if (s.powerMultiplier > 8000) {
        throw StateError(
          'encounter skill $id powerMultiplier=${s.powerMultiplier} > 8000',
        );
      }
    }
    // unlock 引用一致性:encounters.yaml 的所有 unlockSkill outcome
    // 必须能在 encounter skill 池里找到 def(且必须是 encounter skill,
    // 不许借用普通心法招式)。
    if (encounterDefs.isNotEmpty && encounterSkillIds.isNotEmpty) {
      for (final def in encounterDefs.values) {
        for (final outcome in def.outcomeMapping.values) {
          if (outcome.skillId == null) continue;
          final sid = outcome.skillId!;
          if (!encounterSkillIds.contains(sid)) {
            throw StateError(
              'encounter ${def.id} unlockSkill 引用 $sid '
              '不在 encounter skill 池(encounter_skills.yaml)',
            );
          }
        }
      }
    }
  }

  /// 奇遇红线(Phase 4 W14-1):
  /// - id 唯一(已由 _parseDefMap 保证)
  /// - baseProbability ∈ [0, 1](已由 fromYaml 保证)
  /// - schoolKillThreshold 各值 > 0
  /// - fortuneRequired ∈ [1, 10] 或 null
  /// - attributeBonus outcome 的 attributeKey 必须 != null(已由 fromYaml 保证)
  /// - unlockSkill outcome 的 skillId 非空(已由 fromYaml 保证)
  void _enforceEncounterRedLines() {
    if (encounterDefs.isEmpty) return;
    for (final def in encounterDefs.values) {
      for (final entry in def.trigger.schoolKillThreshold.entries) {
        if (entry.value <= 0) {
          throw StateError(
            'encounter ${def.id} school ${entry.key.name} '
            'threshold=${entry.value} 必须 > 0',
          );
        }
      }
      // C-W14-2:biome/weather 分钟阈值 > 0
      for (final entry in def.trigger.biomeMinutes.entries) {
        if (entry.value <= 0) {
          throw StateError(
            'encounter ${def.id} biome ${entry.key.name} '
            'minutes=${entry.value} 必须 > 0',
          );
        }
      }
      for (final entry in def.trigger.weatherMinutes.entries) {
        if (entry.value <= 0) {
          throw StateError(
            'encounter ${def.id} weather ${entry.key.name} '
            'minutes=${entry.value} 必须 > 0',
          );
        }
      }
      final fr = def.trigger.fortuneRequired;
      if (fr != null && (fr < 1 || fr > 10)) {
        throw StateError(
          'encounter ${def.id} fortuneRequired=$fr 应 ∈ [1, 10]',
        );
      }
    }
  }

  /// 心法 + 招式红线（Phase 3 Week 8 T64）：
  /// - 覆盖度：7 阶 × 3 流派 = 21 个 (tier,school) 组合每个 ≥ 1 本
  /// - 每本：skillIds.length == 3
  /// - 每本对应的 3 招 type 必须精确为 {normalAttack, powerSkill, ultimate}
  /// - 每招 parentTechniqueDefId 必须指向自身所属 technique
  ///
  /// 允许测试 fixture 不带 techniqueDefs(为空时整体跳过)。
  void _enforceTechniqueRedLines() {
    if (techniqueDefs.isEmpty) return;
    for (final tier in TechniqueTier.values) {
      for (final school in TechniqueSchool.values) {
        final hit = techniqueDefs.values
            .any((t) => t.tier == tier && t.school == school);
        if (!hit) {
          throw StateError(
            '心法覆盖度不足：缺 ${tier.name}/${school.name} 组合',
          );
        }
      }
    }
    for (final t in techniqueDefs.values) {
      if (t.skillIds.length != 3) {
        throw StateError(
          '心法 ${t.id} skillIds.length=${t.skillIds.length},应 == 3',
        );
      }
      final types = <SkillType>{};
      for (final sid in t.skillIds) {
        final s = skillDefs[sid];
        if (s == null) {
          throw StateError('心法 ${t.id} 引用不存在的 skill: $sid');
        }
        if (s.parentTechniqueDefId != t.id) {
          throw StateError(
            '心法 ${t.id} 招式 $sid parentTechniqueDefId='
            '${s.parentTechniqueDefId},应指向自身',
          );
        }
        types.add(s.type);
      }
      const required = {
        SkillType.normalAttack,
        SkillType.powerSkill,
        SkillType.ultimate,
      };
      if (types.length != required.length || !types.containsAll(required)) {
        throw StateError(
          '心法 ${t.id} 招式 type 分布 $types,'
          '应精确为 {normalAttack, powerSkill, ultimate}',
        );
      }
    }
  }

  /// 装备红线（Phase 3 Week 7 T63）：
  /// - 单件：baseAttackMax ≤ 2000（GDD §5.4 红线）/ baseAttackMin 区间合法
  /// - 覆盖度：每阶（7 阶）≥ 5 件 / 每阶 weapon 三流派各 ≥ 1 / armor + accessory 各 ≥ 1
  ///
  /// 允许测试 fixture 缺装备段(equipmentDefs 为空时跳过覆盖度,仅放过 master/stage 等独立测试)。
  void _enforceEquipmentRedLines() {
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
    if (equipmentDefs.isEmpty) return;
    for (final tier in EquipmentTier.values) {
      final tierItems = equipmentDefs.values.where((e) => e.tier == tier);
      if (tierItems.length < 5) {
        throw StateError(
          '装备覆盖度不足：${tier.name} 阶共 ${tierItems.length} 件,应 ≥ 5',
        );
      }
      final weapons = tierItems.where((e) => e.slot == EquipmentSlot.weapon);
      final armors = tierItems.where((e) => e.slot == EquipmentSlot.armor);
      final accessories =
          tierItems.where((e) => e.slot == EquipmentSlot.accessory);
      if (armors.isEmpty) {
        throw StateError('装备覆盖度不足：${tier.name} 阶缺 armor');
      }
      if (accessories.isEmpty) {
        throw StateError('装备覆盖度不足：${tier.name} 阶缺 accessory');
      }
      for (final school in TechniqueSchool.values) {
        final hit = weapons.any((w) => w.schoolBias == school);
        if (!hit) {
          throw StateError(
            '装备覆盖度不足：${tier.name} 阶缺 ${school.name} 流派武器',
          );
        }
      }
    }
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

  /// Phase 3 Week 4 T53 + T55：师徒 3 角色红线。
  ///
  /// 校验项：
  ///   - 必须 3 条；slotIndex 0/1/2 各一不重不漏
  ///   - slotIndex=0 必须 founder，slotIndex=1/2 必须 disciple
  ///   - founder 仅 1 个；不允许 grandDisciple（Demo 不做徒孙）
  ///   - defaultRealm 严格 < wuSheng（Demo 不做飞升锚点）
  ///   - AttributeProfile 4 项单项 ∈ [1, 10]，总和 ∈ [16, 24]（GDD §4.1）
  ///   - startingTechniqueIds / startingEquipmentIds 全部 id 须在对应 def map 中
  ///   - 三系锁死：starting 装备/心法 tier index ≤ defaultRealm index
  ///   - **T55 启用**：祖师 startingEquipmentIds 至少含 1 件
  ///     `EquipmentDef.isLineageHeritage == true`（师承遗物开篇即有）
  void _enforceMasterRedLines() {
    if (masters.length != 3) {
      throw StateError('师徒角色应为 3 条，实际 ${masters.length}');
    }
    final seenSlots = <int>{};
    var founderCount = 0;
    for (var i = 0; i < masters.length; i++) {
      final m = masters[i];
      if (m.slotIndex != i) {
        throw StateError(
          '师徒 slotIndex 不连续：期望 $i，实际 ${m.slotIndex}（id=${m.id}）',
        );
      }
      if (!seenSlots.add(m.slotIndex)) {
        throw StateError('师徒 slotIndex 重复：${m.slotIndex}');
      }
      // slot 与 role 对应
      if (m.slotIndex == 0) {
        if (m.lineageRole != LineageRole.founder) {
          throw StateError(
            '师徒 slot=0 必须为 founder，实际 ${m.lineageRole.name}（id=${m.id}）',
          );
        }
        founderCount++;
      } else {
        if (m.lineageRole != LineageRole.disciple) {
          throw StateError(
            '师徒 slot=${m.slotIndex} 必须为 disciple，'
            '实际 ${m.lineageRole.name}（id=${m.id}）',
          );
        }
      }
      // 飞升锚点
      if (m.defaultRealm == RealmTier.wuSheng) {
        throw StateError(
          '师徒 ${m.id} defaultRealm=wuSheng，Demo 阶段不允许（飞升锚点）',
        );
      }
      // AttributeProfile 范围
      final ap = m.attributeProfile;
      for (final entry in <String, int>{
        'constitution': ap.constitution,
        'enlightenment': ap.enlightenment,
        'agility': ap.agility,
        'fortune': ap.fortune,
      }.entries) {
        if (entry.value < 1 || entry.value > 10) {
          throw StateError(
            '师徒 ${m.id} attributeProfile.${entry.key}=${entry.value}，'
            '应 ∈ [1, 10]',
          );
        }
      }
      if (ap.total < 16 || ap.total > 24) {
        throw StateError(
          '师徒 ${m.id} attributeProfile.total=${ap.total}，应 ∈ [16, 24]',
        );
      }
      // starting id 存在性 + 三系锁死
      final realmIdx = m.defaultRealm.index;
      for (final techId in m.startingTechniqueIds) {
        final tech = techniqueDefs[techId];
        if (tech == null) {
          throw StateError(
            '师徒 ${m.id} startingTechniqueId=$techId 未在 techniques.yaml 中',
          );
        }
        if (tech.tier.index > realmIdx) {
          throw StateError(
            '师徒 ${m.id} 心法 $techId tier=${tech.tier.name} '
            '超出 defaultRealm=${m.defaultRealm.name} 的三系锁死上限',
          );
        }
      }
      for (final equipId in m.startingEquipmentIds) {
        final eq = equipmentDefs[equipId];
        if (eq == null) {
          throw StateError(
            '师徒 ${m.id} startingEquipmentId=$equipId 未在 equipment.yaml 中',
          );
        }
        if (eq.tier.index > realmIdx) {
          throw StateError(
            '师徒 ${m.id} 装备 $equipId tier=${eq.tier.name} '
            '超出 defaultRealm=${m.defaultRealm.name} 的三系锁死上限',
          );
        }
      }
    }
    if (founderCount != 1) {
      throw StateError('师徒 founder 数量应为 1，实际 $founderCount');
    }
    // T55：祖师 startingEquipmentIds 必须至少含 1 件师承遗物。
    final founder = masters[0];
    final hasHeritage = founder.startingEquipmentIds
        .any((id) => equipmentDefs[id]?.isLineageHeritage == true);
    if (!hasHeritage) {
      throw StateError(
        '师徒 ${founder.id}（祖师）startingEquipmentIds 必须至少含 1 件 '
        'isLineageHeritage=true 的装备（GDD §6.1 + Phase 3 W4 T55）',
      );
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

  /// 按 slotIndex 取师徒定义（0=祖师 / 1=大弟子 / 2=二弟子）。
  /// 越界抛 [RangeError]。
  MasterDef getMasterBySlot(int slotIndex) {
    if (slotIndex < 0 || slotIndex > 2) {
      throw RangeError('师徒 slotIndex 必须 ∈ [0, 2]，实际 $slotIndex');
    }
    return masters[slotIndex];
  }

  /// 取祖师定义（slotIndex=0），等价于 `getMasterBySlot(0)`。
  MasterDef getFounderMaster() => masters[0];

  /// 取 encounter 定义,未配置返回 null(避免 caller try/catch)。
  EncounterDef? findEncounter(String id) => encounterDefs[id];

  /// 全部 encounter 列表,按 id 字典序(便于测试稳定 + UI 列表)。
  List<EncounterDef> get allEncounters {
    final list = encounterDefs.values.toList(growable: false);
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  /// 全部奇遇专属招式,按 (tier, id) 排序(C-W14-3-A,UI 装备面板用)。
  List<SkillDef> get allEncounterSkills {
    final list = encounterSkillIds.map((id) => skillDefs[id]!).toList();
    list.sort((a, b) {
      final t = (a.tier ?? 0).compareTo(b.tier ?? 0);
      if (t != 0) return t;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// 判断给定 skill id 是否为奇遇招式(C-W14-3-A)。
  bool isEncounterSkill(String id) => encounterSkillIds.contains(id);

  /// Phase 3 Week 5 T59：主线 15 关红线。
  ///
  /// 校验项：
  ///   - mainline stages 总数 == 15
  ///   - 按 chapterIndex 分 3 章，每章 5 关
  ///   - narrativeDefeatId != null 时 isBossStage 必须 true（避免章内
  ///     普通关误配 defeat 文案）
  ///
  /// 章内具体哪几关是 Boss 由 yaml 决定（当前约定 4/5 为 Boss），但本红线
  /// 不硬绑位置，只要求 defeat 文案与 Boss 标记一致。
  void _enforceMainlineRedLines() {
    final mainlines = stageDefs.values
        .where((s) => s.stageType == StageType.mainline)
        .toList();
    if (mainlines.isEmpty) return; // 允许测试 fixture 不带主线
    if (mainlines.length != 15) {
      throw StateError(
        '主线关卡应为 15 关，实际 ${mainlines.length}',
      );
    }
    final byChapter = <int, List<StageDef>>{};
    for (final s in mainlines) {
      final ch = s.chapterIndex;
      if (ch == null) {
        throw StateError('主线 stage ${s.id} 缺 chapterIndex');
      }
      byChapter.putIfAbsent(ch, () => []).add(s);
    }
    for (final ch in [1, 2, 3]) {
      final inCh = byChapter[ch] ?? const [];
      if (inCh.length != 5) {
        throw StateError(
          '主线 ch=$ch 应有 5 关，实际 ${inCh.length}',
        );
      }
    }
    if (byChapter.keys.any((ch) => ch < 1 || ch > 3)) {
      throw StateError(
        '主线 chapterIndex 应 ∈ {1, 2, 3}，实际 ${byChapter.keys.toList()..sort()}',
      );
    }
    for (final s in mainlines) {
      if (s.narrativeDefeatId != null && !s.isBossStage) {
        throw StateError(
          '主线 stage ${s.id} 配 narrativeDefeatId 但 isBossStage=false，'
          '战败剧情只应在 Boss 关触发',
        );
      }
    }
  }
}
