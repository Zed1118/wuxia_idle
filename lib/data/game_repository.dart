import 'package:flutter/services.dart' show rootBundle;

import '../features/codex/domain/codex_category.dart';
import '../features/codex/domain/codex_entry.dart';
import '../features/codex/domain/codex_index.dart';
import '../features/encounter/domain/encounter_def.dart';
import '../features/sect/domain/territory_def.dart';
import 'codex_loader.dart';
import 'defs/equipment_def.dart';
import 'defs/master_def.dart';
import 'defs/recruit_candidate_def.dart';
import 'defs/realm_def.dart';
import 'defs/sect_candidate_def.dart';
import '../features/seclusion/domain/seclusion_map_def.dart';
import 'defs/skill_def.dart';
import 'defs/stage_def.dart';
import 'defs/synergy_def.dart';
import 'defs/technique_def.dart';
import '../features/tower/domain/tower_floor_def.dart';
import 'lore_loader.dart';
import '../core/domain/enums.dart';
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

  /// 收徒候选 NPC 列表(P1.1 A1 E.1,GDD §7.1)。
  /// 加载源:`data/recruit_candidates.yaml`,固定 3 候选(audit doc 方案 3 + D2.b)。
  /// **graceful**:test fixture 不带 yaml 时空 list,RecruitmentService 端兜底。
  final Map<String, RecruitCandidateDef> recruitCandidates;

  /// 门派招收候选 NPC 列表(P4.1 1.1 Q6A,GDD §12.2)。
  /// 加载源:`data/sect_candidates.yaml`,Demo 5-8 PoC(spec §1)。
  /// **graceful**:test fixture 不带 yaml / starting refs 不全时空 map(沿 P1.1
  /// recruitCandidates fixture-friendly 体例),encounter_hook 端 affectsSectMembership
  /// 路径在 map 空时 fallback 单 outcome。
  final Map<String, SectCandidateDef> sectCandidates;

  /// 奇遇 / 武学领悟定义(Phase 4 W14-1 C-1)。
  /// Phase 1 vertical slice 3 条;W14-2 扩 15-20 条。
  /// events 文案走 [EncounterEventLoader] 按需 load(narrative_loader 体例)。
  final Map<String, EncounterDef> encounterDefs;

  /// 奇遇专属招式 id 集合(C-W14-3-A,encounter_skills.yaml 加载)。
  /// 与 [skillDefs] 共享 runtime 类型 [SkillDef],但通过此 set 可快速筛
  /// 出"奇遇所得"招式,供 UI / 红线 / battle 装载使用。也可用
  /// `skillDefs[id]!.isEncounterSkill` 等价判断。
  final Set<String> encounterSkillIds;

  /// 心法相生 def(W18-A1,GDD §4.5)。
  /// data/synergies.yaml 加载。test fixture 不带 yaml 时为空 list。
  /// detectActive 遍历此 list,优先级 schoolPair > sameSchool > sameTier
  /// 由 SynergyService 实施。
  final List<SynergyDef> synergies;

  /// P1 #42 Phase 2 §10 P1.z 机制百科条目(GDD §10.2 第 3 方式)。
  ///
  /// 从 `data/narratives/codex/<id>.md` 加载,id 由 [CodexIndex.entries] 登记。
  /// **graceful**:test fixture 不带 md 时为空 map;档 8 `combat_advanced.md`
  /// DeepSeek 派单前缺失时跳过该条(其余 7 条仍加载),不阻塞主流程。
  final Map<String, CodexEntry> codexEntries;

  /// P4.1 §12.2 山头领地静态 def(`data/territories.yaml`,Q4=A)。
  ///
  /// **graceful**:test fixture 不带 yaml 时空 map。Demo 6 territory · 1.1+
  /// 真 stage_boss 占领 trigger 落地时数量可扩(spec §9 R3)。
  /// 动态 ownership 由 `Sect.territoryIds` + B2 `TerritoryService` 持有,
  /// 本字段仅静态 def 索引。
  final Map<String, TerritoryDef> territoryDefs;

  /// P1.2 factionId → alignment 映射(`data/factions.yaml`)。
  /// stage boss kill 声望 wire 查 rival faction 用。fixture 不带 yaml 时空 map。
  final Map<String, String> factionAlignments;

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
    required this.recruitCandidates,
    required this.sectCandidates,
    required this.encounterDefs,
    required this.encounterSkillIds,
    required this.synergies,
    required this.codexEntries,
    required this.territoryDefs,
    required this.factionAlignments,
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
      // test fixture 不带 encounter_skills.yaml 时静默(空池)。P2-a 后:若 encounters
      // 仍引用 unlockSkill skillId,_enforceEncounterSkillRedLines 会在空池上 fail-fast
      // (不再被 isNotEmpty 闸门跳过),故生产损坏/缺失不会静默失效。
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

    // P1.1 A1 E.1:收徒候选 yaml(允许 test fixture 不带 → 空 map)。
    // 生产路径红线校验在 _enforceRecruitCandidateRedLines 拦三系锁死违例。
    // **fixture 兜底**:某些 fixture loader 走 File fallback 读生产 yaml,但
    // 自己的 techniques/equipment 是 stub → starting* 引用 def 不存在。这种
    // 情形预先校验 starting refs,不全则视 fixture 模式空 map(不挂到 repo);
    // 生产 yaml 引用全部对齐,自然 pass 进入严格红线校验。
    Map<String, RecruitCandidateDef> recruitCandidates = const {};
    try {
      final recruitRaw =
          parseYamlMap(await load('data/recruit_candidates.yaml'));
      final loaded = _parseDefMap(
        recruitRaw['recruit_candidates'] as List,
        RecruitCandidateDef.fromYaml,
        idOf: (d) => d.id,
      );
      var allRefsValid = true;
      for (final c in loaded.values) {
        for (final tid in c.startingTechniqueIds) {
          if (techniqueDefs[tid] == null) {
            allRefsValid = false;
            break;
          }
        }
        if (!allRefsValid) break;
        for (final eid in c.startingEquipmentIds) {
          if (equipmentDefs[eid] == null) {
            allRefsValid = false;
            break;
          }
        }
        if (!allRefsValid) break;
      }
      if (allRefsValid) recruitCandidates = loaded;
    } catch (e) {
      // test fixture 不带 recruit_candidates.yaml 时静默
    }

    // P4.1 1.1 Q6A:sect_candidates.yaml 允许测试 fixture 不带 + starting refs
    // 不全 → 整个 map 空(fixture-friendly,沿 recruit_candidates 体例)。
    // 生产路径红线校验在 _enforceSectCandidateRedLines 拦三系锁死违例。
    Map<String, SectCandidateDef> sectCandidates = const {};
    try {
      final sectCandidatesRaw =
          parseYamlMap(await load('data/sect_candidates.yaml'));
      final loaded = _parseDefMap(
        sectCandidatesRaw['sect_candidates'] as List,
        SectCandidateDef.fromYaml,
        idOf: (d) => d.id,
      );
      var allRefsValid = true;
      for (final c in loaded.values) {
        for (final tid in c.startingTechniqueIds) {
          if (techniqueDefs[tid] == null) {
            allRefsValid = false;
            break;
          }
        }
        if (!allRefsValid) break;
        for (final eid in c.startingEquipmentIds) {
          if (equipmentDefs[eid] == null) {
            allRefsValid = false;
            break;
          }
        }
        if (!allRefsValid) break;
      }
      if (allRefsValid) sectCandidates = loaded;
    } catch (e) {
      // test fixture 不带 sect_candidates.yaml 时静默
    }

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

    // W18-A1:心法相生 yaml(允许 test fixture 不带,空 list)。生产路径
    // 红线校验在 _enforceSynergyRedLines 强制 ≥ 5 + multiplier 范围。
    List<SynergyDef> synergies = const [];
    try {
      final synergiesRaw = parseYamlMap(await load('data/synergies.yaml'));
      synergies = ((synergiesRaw['synergies'] as List?) ?? const [])
          .map((e) =>
              SynergyDef.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      // test fixture 不带 synergies.yaml 时静默
    }

    // P1.z 机制百科 md(graceful;档 8 缺失或 fixture 不带均允许空 map)。
    final codexList = await CodexLoader.loadAll(loader: load);
    final codexEntries = <String, CodexEntry>{
      for (final e in codexList) e.id: e,
    };

    // P4.1 §12.2 territories.yaml(graceful;fixture 不带 yaml 时空 map)。
    Map<String, TerritoryDef> territoryDefs = const {};
    try {
      final territoriesRaw = parseYamlList(await load('data/territories.yaml'));
      final defs = territoriesRaw
          .map((raw) => TerritoryDef.fromYaml(
                Map<String, dynamic>.from(raw as Map),
              ))
          .toList(growable: false);
      territoryDefs = {for (final d in defs) d.id: d};
    } catch (e) {
      // test fixture 不带 territories.yaml 时静默,生产路径由 B4 红线校验。
    }

    // P1.2 factions.yaml → factionId→alignment 映射(graceful;fixture 不带时空 map)。
    Map<String, String> factionAlignments = const {};
    try {
      final factionsRaw = parseYamlMap(await load('data/factions.yaml'));
      final list = (factionsRaw['factions'] as List?) ?? const [];
      factionAlignments = {
        for (final f in list)
          (f as Map)['id'] as String: (f)['alignment'] as String,
      };
    } catch (_) {}

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
      recruitCandidates: recruitCandidates,
      sectCandidates: sectCandidates,
      encounterDefs: encounterDefs,
      encounterSkillIds: encounterSkillIds,
      synergies: synergies,
      codexEntries: codexEntries,
      territoryDefs: territoryDefs,
      factionAlignments: factionAlignments,
    );
    repo._enforceRedLines();
    await _validatePresetLoreReferences(equipmentDefs, load);
    _instance = repo;
    return repo;
  }

  /// 查 [factionId] 的对立阵营所有 faction id。
  /// orthodox ↔ evil 互为 rival；neutral 无 rival。
  List<String> rivalFactionIds(String factionId) {
    final alignment = factionAlignments[factionId];
    if (alignment == null || alignment == 'neutral') return const [];
    final rival = alignment == 'orthodox' ? 'evil' : 'orthodox';
    return [
      for (final e in factionAlignments.entries)
        if (e.value == rival) e.key,
    ];
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
    // §5.4 内力红线上界走单一真相源 numbers.combat.red_lines(2026-05-29 消
    // hardcode);下界 500 是 realm def sanity floor,非 §5.4 红线,保留字面量。
    final ifMax = numbers.combat.redLines.internalForceMax;
    for (final r in realms) {
      if (r.internalForceMax < 500 || r.internalForceMax > ifMax) {
        throw StateError(
          '红线越界：${r.tier.name}/${r.layer.name} '
          'internalForceMax=${r.internalForceMax}，应 ∈ [500, $ifMax]',
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
    _enforceRecruitCandidateRedLines();

    // P4.1 1.1 Q6A:sect_candidates.yaml 校验(空 map → 跳过)
    _enforceSectCandidateRedLines();

    // P4.1 1.1 Q6B:Boss 招降 bossRecruit 校验(三重校:isBossStage 守 + candidateRef
    // 在 sectCandidates + baseProbability ∈ [0,1])· sectCandidates 空时仅校第一/三条
    _enforceBossRecruitRedLines();
    _enforceSkillDropRedLines();

    // P0 破招:Boss 招牌蓄力技校验(chargeSkillId 必在敌人 skillIds 内 +
    // boss_charge tick 数值范围)
    _enforceBossChargeRedLines();

    // 波A build gate:破招技(canInterrupt=true)必须有 style 流派归属
    _enforceInterruptSkillRedLines();

    // Phase 4 W14-1 C-1:encounter fixture 校验(若加载到)
    _enforceEncounterRedLines();

    // Phase 4 W14-3-A:encounter_skills.yaml 校验 + unlock 引用一致性
    _enforceEncounterSkillRedLines();

    // W18-A1:心法相生 yaml 校验(空 list 兼容 test fixture)
    _enforceSynergyRedLines();

    // P1.z 机制百科 md 校验(空 map 兼容 test fixture;graceful 缺档 8)
    _enforceCodexRedLines();
  }

  /// P1.z 机制百科红线(GDD §10.2 第 3 方式):
  /// - 加载到的 entry id 必须在 [CodexIndex.entries] 登记(graceful loader 已保证)
  /// - 机制条目(isMechanic):step ∈ [1, 8]
  /// - lore 条目(isLore):step == null
  /// - paragraphs 总字数 ∈ [200, 550](放宽 +50,three_styles_detail 543)
  /// - paragraphs 非空
  ///
  /// P2 扩段:A 组 4 篇补充阅读挂相同机制 category 与 P1.z 首批共存(同档可多条),
  /// 故 step 唯一性已废除;id 唯一性由 [CodexIndex.byId] + Map 加载层保证。
  void _enforceCodexRedLines() {
    if (codexEntries.isEmpty) return; // test fixture 兼容
    for (final e in codexEntries.values) {
      if (CodexIndex.byId(e.id) == null) {
        throw StateError('codex entry ${e.id} 不在 CodexIndex.entries 登记');
      }
      final step = e.step;
      if (e.category.isMechanic) {
        if (step == null || step < 1 || step > 8) {
          throw StateError(
            'codex entry ${e.id} 机制条目 step=$step 应 ∈ [1, 8]',
          );
        }
      } else if (e.category.isLore && step != null) {
        throw StateError(
          'codex entry ${e.id} lore 条目 step=$step 应为 null',
        );
      }
      if (e.paragraphs.isEmpty) {
        throw StateError('codex entry ${e.id} paragraphs 为空');
      }
      final chars = e.totalChars;
      if (chars < 200 || chars > 550) {
        throw StateError(
          'codex entry ${e.id} 字数=$chars,应 ∈ [200, 550](GDD §10.2)',
        );
      }
    }
  }

  /// W18-A1 心法相生红线(GDD §4.5 + numbers 红线对齐):
  /// - id 唯一(由 _parseDefMap 已保证,此处不重校)
  /// - multiplier 各项 ≥ 0 ≤ 0.30(防数值膨胀)
  /// - schoolPair 类型必须配 mainSchool + assistSchool 且两者不同
  /// - sameSchool / sameTier 类型不应配 mainSchool / assistSchool
  /// - synergies 非空时 ≥ 5(GDD §4.5 "5-8 个隐藏组合")— test fixture
  ///   不带 yaml 时 list 为空,跳过下限校验
  void _enforceSynergyRedLines() {
    if (synergies.isEmpty) return;
    if (synergies.length < 5) {
      throw StateError(
        'synergies.yaml 至少 5 组合(GDD §4.5),实际 ${synergies.length}',
      );
    }
    final seen = <String>{};
    for (final s in synergies) {
      if (!seen.add(s.id)) {
        throw StateError('synergy id 重复: ${s.id}');
      }
      if (!s.multipliers.isWithinRedLine) {
        throw StateError(
          'synergy ${s.id} multiplier 越界(应各项 ∈ [0, 0.30])',
        );
      }
      switch (s.requirementType) {
        case SynergyRequirementType.specificTechniques:
          if (s.requiredMainTechniqueId == null ||
              s.requiredAssistTechniqueId == null) {
            throw StateError(
              'synergy ${s.id} specificTechniques 必须配 '
              'mainTechniqueId + assistTechniqueId',
            );
          }
          if (s.mainSchool != null || s.assistSchool != null) {
            throw StateError(
              'synergy ${s.id} specificTechniques 不应配 mainSchool/assistSchool',
            );
          }
          if (techniqueDefs.isNotEmpty &&
              !techniqueDefs.containsKey(s.requiredMainTechniqueId)) {
            throw StateError(
              'synergy ${s.id} requiredMainTechniqueId='
              '${s.requiredMainTechniqueId} 不存在于 techniques.yaml',
            );
          }
          if (techniqueDefs.isNotEmpty &&
              !techniqueDefs.containsKey(s.requiredAssistTechniqueId)) {
            throw StateError(
              'synergy ${s.id} requiredAssistTechniqueId='
              '${s.requiredAssistTechniqueId} 不存在于 techniques.yaml',
            );
          }
          break;
        case SynergyRequirementType.schoolPair:
          if (s.mainSchool == null || s.assistSchool == null) {
            throw StateError(
              'synergy ${s.id} schoolPair 必须配 mainSchool + assistSchool',
            );
          }
          if (s.mainSchool == s.assistSchool) {
            throw StateError(
              'synergy ${s.id} schoolPair main/assist 不能相同(同流派走 sameSchool 类型)',
            );
          }
          if (s.requiredMainTechniqueId != null ||
              s.requiredAssistTechniqueId != null) {
            throw StateError(
              'synergy ${s.id} schoolPair 不应配 mainTechniqueId/assistTechniqueId',
            );
          }
          break;
        case SynergyRequirementType.sameSchool:
        case SynergyRequirementType.sameTier:
          if (s.mainSchool != null || s.assistSchool != null) {
            throw StateError(
              'synergy ${s.id} ${s.requirementType.name} 不应配 mainSchool/assistSchool',
            );
          }
          if (s.requiredMainTechniqueId != null ||
              s.requiredAssistTechniqueId != null) {
            throw StateError(
              'synergy ${s.id} ${s.requirementType.name} '
              '不应配 mainTechniqueId/assistTechniqueId',
            );
          }
          break;
      }
    }
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
  /// 跳过 per-skill cap 校验;但 unlock 引用一致性始终校验(encounters.yaml 在场时),
  /// P2-a 后空池 + 有 unlockSkill 引用 → fail-fast,不再静默跳过。
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
    //
    // P2-a(外部 review):此处不再以 `encounterSkillIds.isNotEmpty` 为前置闸门。
    // 否则 encounter_skills.yaml 在生产被 catch 静默吞掉(损坏/缺失)时招式池为空,
    // 一致性校验整段被跳过 → 奇遇招式静默失效。改为:只要 encounters 有 unlockSkill
    // 引用,招式池空也会在此 fail-fast(skillId 不在空池 → 抛 StateError)。无
    // unlockSkill outcome 的 fixture 自然不触发,保持兼容。
    if (encounterDefs.isNotEmpty) {
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
      // P4.1 1.1 Q6A:affectsSectMembership 引用 + accept_recruit 约定校
      final asm = def.affectsSectMembership;
      if (asm != null) {
        // candidateRef 必须在 sectCandidates 中(允许 fixture 空 map 跳过)
        if (sectCandidates.isNotEmpty &&
            sectCandidates[asm.candidateRef] == null) {
          throw StateError(
            'encounter ${def.id} affectsSectMembership.candidateRef='
            '${asm.candidateRef} 未在 sect_candidates.yaml 中',
          );
        }
        // outcomeMapping 必须含 accept_recruit(spec §3 强约定)
        if (!def.outcomeMapping.containsKey('accept_recruit')) {
          throw StateError(
            'encounter ${def.id} 含 affectsSectMembership 但 outcomeMapping '
            '缺 accept_recruit(spec §3 强约定 · 玩家招收意愿凭此 id 触发)',
          );
        }
        // fallbackOutcomeId 必须在 outcomeMapping 中(若指定)
        final fallback = asm.fallbackOutcomeId;
        if (fallback != null &&
            !def.outcomeMapping.containsKey(fallback)) {
          throw StateError(
            'encounter ${def.id} affectsSectMembership.fallbackOutcomeId='
            '$fallback 未在 outcomeMapping 中(spec §3 cap 满/拒绝 fallback)',
          );
        }
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

  /// P1.1 A1 E.1:收徒候选 NPC 红线(GDD §7.1 + audit 方案 3)。
  ///
  /// 校验:
  /// - 数量 == 3(D2.b 决议)
  /// - lineageRole 必须 disciple(祖师为玩家本人 = founder,候选只能是 disciple)
  /// - defaultRealm 不允许 wuSheng(飞升锚点)
  /// - attributeProfile 单项 [1,10] / total [16,24]
  /// - startingTechniqueIds / startingEquipmentIds 引用合法 + 三系锁死
  /// - id 唯一(_parseDefMap 已保证)
  ///
  /// 允许 test fixture 不带 yaml → recruitCandidates 空 map → 整个校验跳过。
  void _enforceRecruitCandidateRedLines() {
    if (recruitCandidates.isEmpty) return; // fixture 兜底
    if (recruitCandidates.length != 3) {
      throw StateError(
        '收徒候选应为 3 条（audit 方案 3 + D2.b），实际 ${recruitCandidates.length}',
      );
    }
    for (final c in recruitCandidates.values) {
      if (c.lineageRole != LineageRole.disciple) {
        throw StateError(
          '收徒候选 ${c.id} lineageRole=${c.lineageRole.name},必须为 disciple',
        );
      }
      if (c.defaultRealm == RealmTier.wuSheng) {
        throw StateError(
          '收徒候选 ${c.id} defaultRealm=wuSheng,Demo + 1.0 P1.1 不允许飞升锚点',
        );
      }
      // AttributeProfile 范围
      final ap = c.attributeProfile;
      for (final entry in <String, int>{
        'constitution': ap.constitution,
        'enlightenment': ap.enlightenment,
        'agility': ap.agility,
        'fortune': ap.fortune,
      }.entries) {
        if (entry.value < 1 || entry.value > 10) {
          throw StateError(
            '收徒候选 ${c.id} attributeProfile.${entry.key}=${entry.value},'
            '应 ∈ [1, 10]',
          );
        }
      }
      if (ap.total < 16 || ap.total > 24) {
        throw StateError(
          '收徒候选 ${c.id} attributeProfile.total=${ap.total},应 ∈ [16, 24]',
        );
      }
      // starting id 存在性 + 三系锁死
      final realmIdx = c.defaultRealm.index;
      for (final techId in c.startingTechniqueIds) {
        final tech = techniqueDefs[techId];
        if (tech == null) {
          throw StateError(
            '收徒候选 ${c.id} startingTechniqueId=$techId 未在 techniques.yaml 中',
          );
        }
        if (tech.tier.index > realmIdx) {
          throw StateError(
            '收徒候选 ${c.id} 心法 $techId tier=${tech.tier.name} '
            '超出 defaultRealm=${c.defaultRealm.name} 的三系锁死上限',
          );
        }
      }
      for (final equipId in c.startingEquipmentIds) {
        final eq = equipmentDefs[equipId];
        if (eq == null) {
          throw StateError(
            '收徒候选 ${c.id} startingEquipmentId=$equipId 未在 equipment.yaml 中',
          );
        }
        if (eq.tier.index > realmIdx) {
          throw StateError(
            '收徒候选 ${c.id} 装备 $equipId tier=${eq.tier.name} '
            '超出 defaultRealm=${c.defaultRealm.name} 的三系锁死上限',
          );
        }
      }
    }
  }

  /// P4.1 1.1 Q6A · 门派招收候选 NPC schema 校验。
  ///
  /// 校验(沿 [_enforceRecruitCandidateRedLines] 体例,但 count 不锁 3 →
  /// 5-8 弹性,Demo PoC 池余量沿用):
  /// - 数量 ∈ [1, 20](防 yaml 误产生空段 / 数量越界)
  /// - defaultRealm 不允许 wuSheng(NPC Demo 不为飞升锚点)
  /// - attributeProfile 单项 [1,10] / total [16,24]
  /// - startingTechniqueIds / startingEquipmentIds 引用合法 + 三系锁死
  /// - id 唯一(_parseDefMap 已保证)
  ///
  /// 允许 test fixture 不带 yaml → sectCandidates 空 map → 整个校验跳过。
  void _enforceSectCandidateRedLines() {
    if (sectCandidates.isEmpty) return; // fixture 兜底
    if (sectCandidates.length > 20) {
      throw StateError(
        '门派招收候选数量=${sectCandidates.length},应 ≤ 20(Demo PoC 5-8)',
      );
    }
    for (final c in sectCandidates.values) {
      if (c.defaultRealm == RealmTier.wuSheng) {
        throw StateError(
          '门派招收候选 ${c.id} defaultRealm=wuSheng,不允许飞升锚点',
        );
      }
      // AttributeProfile 范围
      final ap = c.attributeProfile;
      for (final entry in <String, int>{
        'constitution': ap.constitution,
        'enlightenment': ap.enlightenment,
        'agility': ap.agility,
        'fortune': ap.fortune,
      }.entries) {
        if (entry.value < 1 || entry.value > 10) {
          throw StateError(
            '门派招收候选 ${c.id} attributeProfile.${entry.key}=${entry.value},'
            '应 ∈ [1, 10]',
          );
        }
      }
      if (ap.total < 16 || ap.total > 24) {
        throw StateError(
          '门派招收候选 ${c.id} attributeProfile.total=${ap.total},应 ∈ [16, 24]',
        );
      }
      // starting id 存在性 + 三系锁死(CLAUDE.md §5.3)
      final realmIdx = c.defaultRealm.index;
      for (final techId in c.startingTechniqueIds) {
        final tech = techniqueDefs[techId];
        if (tech == null) {
          throw StateError(
            '门派招收候选 ${c.id} startingTechniqueId=$techId 未在 techniques.yaml 中',
          );
        }
        if (tech.tier.index > realmIdx) {
          throw StateError(
            '门派招收候选 ${c.id} 心法 $techId tier=${tech.tier.name} '
            '超出 defaultRealm=${c.defaultRealm.name} 的三系锁死上限',
          );
        }
      }
      for (final equipId in c.startingEquipmentIds) {
        final eq = equipmentDefs[equipId];
        if (eq == null) {
          throw StateError(
            '门派招收候选 ${c.id} startingEquipmentId=$equipId 未在 equipment.yaml 中',
          );
        }
        if (eq.tier.index > realmIdx) {
          throw StateError(
            '门派招收候选 ${c.id} 装备 $equipId tier=${eq.tier.name} '
            '超出 defaultRealm=${c.defaultRealm.name} 的三系锁死上限',
          );
        }
      }
    }
  }

  /// P4.1 1.1 Q6B · Boss 招降 bossRecruit 红线(spec §6 三重校):
  /// - 仅 `isBossStage: true` 关卡可配 bossRecruit(非 Boss 关配置直接抛)
  /// - `bossRecruit.candidateRef` 必须在 [sectCandidates] 中(沿 Q6A
  ///   `_enforceEncounterRedLines` affectsSectMembership 体例 · 允许 fixture
  ///   sectCandidates 空 map 跳过 ref 校,但仍校第 1/3 条)
  /// - `bossRecruit.baseProbability` ∈ [0.0, 1.0]
  void _enforceBossRecruitRedLines() {
    for (final s in stageDefs.values) {
      final br = s.bossRecruit;
      if (br == null) continue;
      if (!s.isBossStage) {
        throw StateError(
          'stage ${s.id} 配 bossRecruit 但 isBossStage=false,'
          '仅 Boss 关卡可配招降(spec §6 红线 ①)',
        );
      }
      if (br.baseProbability < 0.0 || br.baseProbability > 1.0) {
        throw StateError(
          'stage ${s.id} bossRecruit.baseProbability=${br.baseProbability},'
          '应 ∈ [0.0, 1.0](spec §6 红线 ③)',
        );
      }
      if (sectCandidates.isNotEmpty &&
          sectCandidates[br.candidateRef] == null) {
        throw StateError(
          'stage ${s.id} bossRecruit.candidateRef=${br.candidateRef} '
          '未在 sect_candidates.yaml 中(spec §6 红线 ②)',
        );
      }
    }
  }

  /// P0 破招红线(沿 [_enforceBossRecruitRedLines] 体例):
  /// - 任何配了 chargeSkillId 的敌人:该 id 必须在其 skillIds 内,否则 throw。
  /// - numbers.bossCharge:defaultChargeTicks ∈ [1,8] / defaultStaggerTicks ∈ [0,5]。
  /// 技能书掉落红线(可玩性 P1a · spec §二)。仅 Boss 关可配 dropSkill,且 id 必须在 skillDefs。
  void _enforceSkillDropRedLines() {
    for (final s in stageDefs.values) {
      final manual = s.dropSkillManualId;
      final frag = s.dropSkillFragmentId;
      if (manual == null && frag == null) continue;
      if (!s.isBossStage) {
        throw StateError(
          'stage ${s.id} 配 dropSkill 但 isBossStage=false,仅 Boss 关可配(P1a §二红线)',
        );
      }
      for (final id in [manual, frag]) {
        if (id != null && skillDefs[id] == null) {
          throw StateError(
            'stage ${s.id} dropSkill id=$id 未在 skills.yaml(P1a §二红线)',
          );
        }
      }
    }
  }

  /// 波A build gate 红线:canInterrupt=true 的破招技必须有 style 流派归属
  /// (装配 gate 按 style == character.school 过滤,无 style 的破招技永不可装配,
  /// 属配置错误 fail-fast)。
  void _enforceInterruptSkillRedLines() {
    for (final s in skillDefs.values) {
      if (s.canInterrupt && s.style == null) {
        throw StateError(
          'skill ${s.id} canInterrupt=true 但缺 style 流派归属(波A build gate 红线)',
        );
      }
    }
  }

  void _enforceBossChargeRedLines() {
    for (final s in stageDefs.values) {
      for (final e in s.enemyTeam) {
        final cs = e.chargeSkillId;
        if (cs == null) continue;
        if (!e.skillIds.contains(cs)) {
          throw StateError(
            'stage ${s.id} 敌人 ${e.id} chargeSkillId=$cs '
            '不在其 skillIds ${e.skillIds} 内(P0 破招红线 ①)',
          );
        }
      }
    }
    final bc = numbers.combat.bossCharge;
    if (bc.defaultChargeTicks < 1 || bc.defaultChargeTicks > 8) {
      throw StateError(
        'boss_charge.defaultChargeTicks=${bc.defaultChargeTicks},'
        '应 ∈ [1, 8](P0 破招红线 ②)',
      );
    }
    if (bc.defaultStaggerTicks < 0 || bc.defaultStaggerTicks > 5) {
      throw StateError(
        'boss_charge.defaultStaggerTicks=${bc.defaultStaggerTicks},'
        '应 ∈ [0, 5](P0 破招红线 ②)',
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
  void _enforceMainlineRedLines() {
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
        throw StateError(
          '主线 chapterIndex 必须从 1 起连续递增,实际 $chapters',
        );
      }
    }
    // 每章必须正好 5 关
    for (final ch in chapters) {
      final inCh = byChapter[ch]!;
      if (inCh.length != 5) {
        throw StateError(
          '主线 ch=$ch 应有 5 关,实际 ${inCh.length}',
        );
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
}
