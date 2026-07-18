import 'package:flutter/services.dart' show rootBundle;

import 'defs/codex_entry.dart';
import 'defs/codex_index.dart';
import 'defs/encounter_def.dart';
import 'encounter_event_loader.dart';
import 'defs/territory_def.dart';
import 'codex_loader.dart';
import 'defs/equipment_def.dart';
import 'defs/boss_phase_def.dart';
import 'defs/faction_def.dart';
import 'defs/founder_creation_def.dart';
import 'defs/founder_names_def.dart';
import 'defs/master_def.dart';
import 'defs/recruit_candidate_def.dart';
import 'defs/realm_def.dart';
import 'defs/sect_candidate_def.dart';
import 'defs/item_def.dart';
import 'defs/shop_item_def.dart';
import 'defs/seclusion_map_def.dart';
import 'defs/skill_def.dart';
import 'defs/stage_def.dart';
import 'defs/synergy_def.dart';
import 'defs/technique_def.dart';
import 'defs/tower_floor_def.dart';
import 'defs/expedition_config.dart';
import 'defs/boss_gauntlet_config.dart';
import 'lore_loader.dart';
import '../core/domain/enums.dart';
import 'numbers_config.dart';
import 'validation/drop_table_reference_validator.dart';
import 'validation/economy_codex_red_lines_validator.dart';
import 'validation/encounter_red_lines_validator.dart';
import 'validation/lineage_recruit_red_lines_validator.dart';
import 'validation/progression_red_lines_validator.dart';
import 'validation/skill_red_lines_validator.dart';
import 'validation/technique_equipment_red_lines_validator.dart';
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

  /// 已加载时返回实例，否则返回 null（轻量 Widget/test 防御式读取用，不抛错）。
  static GameRepository? get instanceOrNull => _instance;

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

  /// 新档祖师塑形配置(`data/founder_creation.yaml`)。
  final FounderCreationConfig founderCreation;

  /// 祖师/门派随机取名素材(`data/founder_names.yaml`)。
  final FounderNamesConfig founderNames;

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
  /// 内容补齐前缺失时跳过该条(其余 7 条仍加载),不阻塞主流程。
  final Map<String, CodexEntry> codexEntries;

  /// P4.1 §12.2 山头领地静态 def(`data/territories.yaml`,Q4=A)。
  ///
  /// **graceful**:test fixture 不带 yaml 时空 map。Demo 6 territory · 1.1+
  /// 真 stage_boss 占领 trigger 落地时数量可扩(spec §9 R3)。
  /// 动态 ownership 由 `Sect.territoryIds` + B2 `TerritoryService` 持有,
  /// 本字段仅静态 def 索引。
  final Map<String, TerritoryDef> territoryDefs;

  /// 门派完整静态定义(`data/factions.yaml`)。
  /// 显示名与 NPC 归属统一从此读取；fixture 不带 yaml 时为空 map。
  final Map<String, FactionDef> factionDefs;

  /// P1.2 factionId → alignment 映射(`data/factions.yaml`)。
  /// stage boss kill 声望 wire 查 rival faction 用。fixture 不带 yaml 时空 map。
  final Map<String, String> factionAlignments;

  /// 材料经济 P1 商店商品 def（`data/shop.yaml`）。
  /// P1 阶段只卖磨剑石/心血结晶 2 种材料；标价上限 100000。
  /// **graceful**：test fixture 不带 yaml 时空 map。
  final Map<String, ShopItemDef> shopItemDefs;

  /// 道具效果 def（`data/items.yaml`，材料经济 P2）。
  /// 经验丹经验值 / 秘籍 unlockSkillId / 道具名。fixture 不带 yaml 时空 map。
  final Map<String, ItemDef> itemDefs;

  /// 江湖远行配置（§8.2，纯 Dart 非 Isar）。fixture 不带 yaml 时为 null；
  /// yaml 存在但结构非法 → 加载期 FormatException fail-fast。
  final ExpeditionConfig? expeditionConfig;
  final BossGauntletConfig? bossGauntletConfig;

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
    required this.founderCreation,
    required this.founderNames,
    required this.recruitCandidates,
    required this.sectCandidates,
    required this.encounterDefs,
    required this.encounterSkillIds,
    required this.synergies,
    required this.codexEntries,
    required this.territoryDefs,
    required this.factionDefs,
    required this.factionAlignments,
    required this.shopItemDefs,
    required this.itemDefs,
    this.expeditionConfig,
    this.bossGauntletConfig,
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
      final encounterSkillsRaw = parseYamlMap(
        await load('data/encounter_skills.yaml'),
      );
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
      // 仍引用 unlockSkill skillId,enforceEncounterSkillRedLines(validation/) 会在空池上 fail-fast
      // (不再被 isNotEmpty 闸门跳过),故生产损坏/缺失不会静默失效。
    }
    final stageDefs = _parseDefMap(
      stagesRaw['stages'] as List,
      StageDef.fromYaml,
      idOf: (d) => d.id,
    );
    final towerFloors =
        ((towersRaw['floors'] as List?) ?? const [])
            .map(
              (e) =>
                  TowerFloorDef.fromYaml(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false)
          ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));

    final mastersRaw = parseYamlMap(await load('data/masters.yaml'));
    final masters =
        ((mastersRaw['masters'] as List?) ?? const [])
            .map((e) => MasterDef.fromYaml(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false)
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    final founderCreation = await _loadOptionalAsset<FounderCreationConfig>(
      load,
      'data/founder_creation.yaml',
      (raw) => FounderCreationConfig.fromYaml(parseYamlMap(raw)),
      fallback: FounderCreationConfig.empty,
    );

    final founderNames = await _loadOptionalAsset<FounderNamesConfig>(
      load,
      'data/founder_names.yaml',
      (raw) => FounderNamesConfig.fromYaml(parseYamlMap(raw)),
      fallback: FounderNamesConfig.empty,
    );

    // P1.1 A1 E.1:收徒候选 yaml(允许 test fixture 不带 → 空 map)。
    // 生产路径红线校验在 enforceRecruitCandidateRedLines(validation/) 拦三系锁死违例。
    // **fixture 兜底**:某些 fixture loader 走 File fallback 读生产 yaml,但
    // 自己的 techniques/equipment 是 stub → starting* 引用 def 不存在。这种
    // 情形预先校验 starting refs,不全则视 fixture 模式空 map(不挂到 repo);
    // 生产 yaml 引用全部对齐,自然 pass 进入严格红线校验。
    Map<String, RecruitCandidateDef> recruitCandidates = const {};
    try {
      final recruitRaw = parseYamlMap(
        await load('data/recruit_candidates.yaml'),
      );
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
    // 生产路径红线校验在 enforceSectCandidateRedLines(validation/) 拦三系锁死违例。
    Map<String, SectCandidateDef> sectCandidates = const {};
    try {
      final sectCandidatesRaw = parseYamlMap(
        await load('data/sect_candidates.yaml'),
      );
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
      // 红线校验阶段(enforceEncounterRedLines(validation/) 检查非空与字段合法)。
    }

    // W18-A1:心法相生 yaml(允许 test fixture 不带,空 list)。生产路径
    // 红线校验在 enforceSynergyRedLines(validation/) 强制 ≥ 5 + multiplier 范围。
    final synergies = await _loadOptionalAsset(load, 'data/synergies.yaml', (
      raw,
    ) {
      final synergiesRaw = parseYamlMap(raw);
      return ((synergiesRaw['synergies'] as List?) ?? const [])
          .map((e) => SynergyDef.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    }, fallback: const <SynergyDef>[]);

    // P1.z 机制百科 md(graceful;档 8 缺失或 fixture 不带均允许空 map)。
    final codexList = await CodexLoader.loadAll(loader: load);
    final codexEntries = <String, CodexEntry>{
      for (final e in codexList) e.id: e,
    };

    // P4.1 §12.2 territories.yaml(graceful;fixture 不带 yaml 时空 map)。
    final territoryDefs = await _loadOptionalAsset(
      load,
      'data/territories.yaml',
      (raw) {
        final territoriesRaw = parseYamlList(raw);
        final defs = territoriesRaw
            .map(
              (r) => TerritoryDef.fromYaml(Map<String, dynamic>.from(r as Map)),
            )
            .toList(growable: false);
        return {for (final d in defs) d.id: d};
      },
      fallback: const <String, TerritoryDef>{},
    );

    // P1.2 factions.yaml 完整定义(graceful;fixture 不带时空 map)。
    final factionDefs = await _loadOptionalAsset(load, 'data/factions.yaml', (
      raw,
    ) {
      final factionsRaw = parseYamlMap(raw);
      return _parseDefMap(
        (factionsRaw['factions'] as List?) ?? const [],
        FactionDef.fromYaml,
        idOf: (def) => def.id,
      );
    }, fallback: const <String, FactionDef>{});
    final factionAlignments = <String, String>{
      for (final def in factionDefs.values) def.id: def.alignment,
    };

    // 材料经济 P1 shop.yaml(graceful;fixture 不带 yaml 时空 map)。
    // 生产路径红线校验在 enforceShopRedLines(validation/) 拦标价越界。
    final shopItemDefs = await _loadOptionalAsset(load, 'data/shop.yaml', (
      raw,
    ) {
      final shopRaw = parseYamlMap(raw);
      return _parseDefMap(
        shopRaw['shop'] as List,
        ShopItemDef.fromYaml,
        idOf: (d) => d.id,
      );
    }, fallback: const <String, ShopItemDef>{});

    // 材料经济 P2 items.yaml(graceful;fixture 不带 yaml 时空 map)。
    final itemDefs = await _loadOptionalAsset(load, 'data/items.yaml', (raw) {
      final itemsRaw = parseYamlMap(raw);
      return _parseDefMap(
        itemsRaw['items'] as List,
        ItemDef.fromYaml,
        idOf: (d) => d.defId,
      );
    }, fallback: const <String, ItemDef>{});

    // 江湖远行 A2 配置骨架(graceful;fixture 无 yaml 时 null,损坏/非法 fail-fast)。
    final expeditionConfig = await _loadOptionalAsset<ExpeditionConfig?>(
      load,
      'data/expeditions.yaml',
      (raw) => ExpeditionConfig.fromYaml(parseYamlMap(raw)),
      fallback: null,
    );
    final bossGauntletConfig = await _loadOptionalAsset<BossGauntletConfig?>(
      load,
      'data/boss_gauntlets.yaml',
      (raw) => BossGauntletConfig.fromYaml(parseYamlMap(raw)),
      fallback: null,
    );

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
      founderCreation: founderCreation,
      founderNames: founderNames,
      recruitCandidates: recruitCandidates,
      sectCandidates: sectCandidates,
      encounterDefs: encounterDefs,
      encounterSkillIds: encounterSkillIds,
      synergies: synergies,
      codexEntries: codexEntries,
      territoryDefs: territoryDefs,
      factionDefs: factionDefs,
      factionAlignments: factionAlignments,
      shopItemDefs: shopItemDefs,
      itemDefs: itemDefs,
      expeditionConfig: expeditionConfig,
      bossGauntletConfig: bossGauntletConfig,
    );
    repo._enforceRedLines();
    await _validatePresetLoreReferences(equipmentDefs, load);
    await _validateEncounterEventReferences(encounterDefs, load);
    _validateFactionTerritoryReferences(
      stageDefs,
      encounterDefs,
      factionAlignments,
      territoryDefs,
    );
    _instance = repo;
    return repo;
  }

  /// 加载可选 yaml asset(P0-1 2026-06-29 审查修复)。区分两类异常:
  /// - `load(assetPath)` 抛 → 文件不存在/不可读(test fixture 不带某 yaml 的
  ///   合法情况,或生产 asset 缺失)→ 返回 [fallback],静默。
  /// - `load` 成功但 [parse] 抛 → yaml 存在但损坏/字段类型错 → 抛
  ///   [FormatException] 附文件名 rethrow,**不再静默降级**(此前 `catch (_) {}`
  ///   会把损坏 yaml 吞成空,致商店空架/道具失效/阵营 wire 断链而玩家无感知,
  ///   启动也不 fail-fast)。缺失走红线层 `isEmpty return` 跳过,损坏在此拦下。
  static Future<T> _loadOptionalAsset<T>(
    Future<String> Function(String) load,
    String assetPath,
    T Function(String raw) parse, {
    required T fallback,
  }) async {
    final String raw;
    try {
      raw = await load(assetPath);
    } catch (missingOptionalAsset) {
      // 可选 asset 缺失是旧测试 fixture/未启用模块的合法路径,此处故意不打日志。
      // yaml 一旦存在,解析错误会在下方 fail-fast。
      return fallback;
    }
    try {
      return parse(raw);
    } catch (e) {
      throw FormatException('解析 $assetPath 失败(yaml 损坏或字段类型错误): $e');
    }
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
          throw StateError('装备 ${def.id} presetLore $loreId default_lore 段为空');
        }
      }
    }
  }

  /// C2 [审计 2026-06-24]:奇遇 `events/<id>.yaml` 引用一致性校验(仿
  /// [_validatePresetLoreReferences] 体例,兑现 GDD §8.1「任一端缺失直接抛错」)。
  ///
  /// 对每条 [EncounterDef] await [EncounterEventLoader.load]:
  /// - placeholder 兜底(缺文件 / 解析失败)→ StateError(此前静默显示「[文案待补]」)
  /// - content.id != encounter id → StateError(yaml 内 id 不自洽)
  /// - events choices 中除 `skip` 外的 outcome_id 不在 [EncounterDef.outcomeMapping]
  ///   → StateError(此前 [EncounterDef.resolveOutcome] 静默 fallback
  ///   [OutcomeType.none],玩家选择后奖励无声丢失)
  ///
  /// 兼容 test fixture:encounterDefs 为空时整个跳过(不触 yaml)。
  /// 串行 await(57 文件量级,启动开销 < 50ms,不并发避免压垮 rootBundle)。
  static Future<void> _validateEncounterEventReferences(
    Map<String, EncounterDef> encounterDefs,
    Future<String> Function(String) load,
  ) async {
    for (final def in encounterDefs.values) {
      final content = await EncounterEventLoader.load(def.id, loader: load);
      if (content.isPlaceholder) {
        throw StateError(
          'encounter ${def.id} 缺 data/events/${def.id}.yaml 或解析失败 (GDD §8.1)',
        );
      }
      if (content.id != def.id) {
        throw StateError(
          'encounter ${def.id} events yaml 内 id=${content.id} 不自洽 (GDD §8.1)',
        );
      }
      for (final choice in content.choices) {
        if (choice.outcomeId == 'skip') continue;
        if (!def.outcomeMapping.containsKey(choice.outcomeId)) {
          throw StateError(
            'encounter ${def.id} events choice outcome_id="${choice.outcomeId}" '
            '不在 outcomeMapping,resolveOutcome 会静默丢失奖励 (GDD §8.1)',
          );
        }
      }
    }
  }

  /// P1.2/P4.1 门派声望 + 山头领地引用/自洽的启动期强校验(仿 lore/encounter
  /// `_validate*References`,补 factions/territories 缺 fail-fast 的历史空白)。
  /// 纯函数 of 已加载的 4 个 map,`loadAllDefs` 末尾调。三类断言:
  ///  ① faction alignment 仅 orthodox/neutral/evil(factions.yaml 头注不变量);
  ///  ② stages/encounters 引的 factionId 必须存在于 factions.yaml,否则
  ///     ReputationService 会静默兜底(factions.yaml 头注 → 'yiLiu'),声望 wire 失灵;
  ///  ③ territory baseDefenseLevel ∈ [1,7](§5.3 七阶映射)。
  /// **graceful**:test fixture 不带 factions.yaml 时 [factionAlignments] 空 →
  /// 跳过 ② 引用校验(否则带 stage 不带 faction 的 fixture 会误抛);① ③ 对空 map
  /// 天然 no-op。
  static void _validateFactionTerritoryReferences(
    Map<String, StageDef> stageDefs,
    Map<String, EncounterDef> encounterDefs,
    Map<String, String> factionAlignments,
    Map<String, TerritoryDef> territoryDefs,
  ) {
    const validAlignments = {'orthodox', 'neutral', 'evil'};
    for (final entry in factionAlignments.entries) {
      if (!validAlignments.contains(entry.value)) {
        throw StateError(
          'faction ${entry.key} alignment="${entry.value}" 非法'
          '(仅 orthodox/neutral/evil · P1.2 §6)',
        );
      }
    }

    if (factionAlignments.isNotEmpty) {
      for (final s in stageDefs.values) {
        final fid = s.factionId;
        if (fid != null && !factionAlignments.containsKey(fid)) {
          throw StateError(
            'stage ${s.id} factionId="$fid" 不在 factions.yaml,'
            '声望 wire 会静默兜底 (P1.2 §6)',
          );
        }
      }
      for (final e in encounterDefs.values) {
        final fid = e.affectsReputation?.factionId;
        if (fid != null && !factionAlignments.containsKey(fid)) {
          throw StateError(
            'encounter ${e.id} affectsReputation.factionId="$fid" '
            '不在 factions.yaml,声望 wire 会静默兜底 (P1.2 §6)',
          );
        }
      }
    }

    for (final t in territoryDefs.values) {
      if (t.baseDefenseLevel < 1 || t.baseDefenseLevel > 7) {
        throw StateError(
          'territory ${t.id} baseDefenseLevel=${t.baseDefenseLevel} '
          '越界 [1,7] (§5.3 七阶)',
        );
      }
    }
  }

  /// 把 numbers.yaml 嵌套的 `realms.tiers[].layers[]` 展平为 49 行 [RealmDef]。
  static List<RealmDef> _parseRealms(Map<String, dynamic> realmsSection) {
    final tiers = realmsSection['tiers'] as List;
    final out = <RealmDef>[];
    for (final t in tiers) {
      final tier = RealmTier.values.byName(t['tier'] as String);
      final eqCap = EquipmentTier.values.byName(
        t['equipment_tier_cap'] as String,
      );
      final techCap = TechniqueTier.values.byName(
        t['technique_tier_cap'] as String,
      );
      for (final l in (t['layers'] as List)) {
        out.add(
          RealmDef(
            tier: tier,
            layer: RealmLayer.values.byName(l['layer'] as String),
            absoluteLevel: (l['absolute_level'] as num).toInt(),
            internalForceMax: (l['internal_force_max'] as num).toInt(),
            experienceToNext: (l['experience_to_next'] as num).toInt(),
            equipmentTierCap: eqCap,
            techniqueTierCap: techCap,
          ),
        );
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
    enforceEquipmentRedLines(equipmentDefs: equipmentDefs, numbers: numbers);

    // Phase 3 Week 8 T64：心法 fixture 扩 21 本,7 阶 × 3 流派覆盖度
    //   + 每本 3 招 type 精确 normalAttack/powerSkill/ultimate
    enforceTechniqueRedLines(
      techniqueDefs: techniqueDefs,
      skillDefs: skillDefs,
    );
    // Phase 3 T33：stage 链路校验。prevStageId 必须能找到，
    // 且与本关同 chapterIndex（防跨章引用 / 错字 id）。
    for (final s in stageDefs.values) {
      final prev = s.prevStageId;
      if (prev == null) continue;
      final prevDef = stageDefs[prev];
      if (prevDef == null) {
        throw StateError('stage ${s.id} prevStageId=$prev 引用不存在的关卡');
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
    enforceMainlineRedLines(stageDefs: stageDefs);

    // Phase 3 T40：爬塔 30 层校验
    //   - floorIndex 1-30 连续唯一
    //   - bossKind 严格在 5/10/15/20/25/30
    //   - 普通层 narrativeOpeningId / narrativeVictoryId 必须为 null
    //   - Boss HP ≤ bossHpMax（§5.4 红线，config-driven，2026-06-14 调至 60000）
    enforceTowerRedLines(
      towerFloors: towerFloors,
      skillDefs: skillDefs,
      numbers: numbers,
    );

    // Phase 3 T47：闭关地图 5 张校验
    enforceSeclusionRedLines(seclusionMaps: seclusionMaps, numbers: numbers);

    // Phase 3 Week 4 T53：师徒 3 角色校验
    enforceMasterRedLines(
      masters: masters,
      techniqueDefs: techniqueDefs,
      equipmentDefs: equipmentDefs,
    );
    enforceFounderCreationRedLines(
      founderCreation: founderCreation,
      techniqueDefs: techniqueDefs,
      equipmentDefs: equipmentDefs,
    );
    enforceRecruitCandidateRedLines(
      recruitCandidates: recruitCandidates,
      techniqueDefs: techniqueDefs,
      equipmentDefs: equipmentDefs,
    );

    // 第七阶段批三 P2：命名弟子拜入配置红线（stage 存在唯一 / slot 合法 /
    // slot role 与 join role 一致 / role∈{senior,junior} / narrative 非空）。
    // 防 numbers.yaml↔masters.yaml 漂移静默生成错角色 / stage 拼错永不触发。
    enforceLineageOnboardingRedLines(
      joins: numbers.lineageOnboarding.discipleJoins,
      existingStageIds: stageDefs.keys.toSet(),
      masters: masters,
    );

    // P4.1 1.1 Q6A:sect_candidates.yaml 校验(空 map → 跳过)
    enforceSectCandidateRedLines(
      sectCandidates: sectCandidates,
      techniqueDefs: techniqueDefs,
      equipmentDefs: equipmentDefs,
    );

    // P4.1 1.1 Q6B:Boss 招降 bossRecruit 校验(三重校:isBossStage 守 + candidateRef
    // 在 sectCandidates + baseProbability ∈ [0,1])· sectCandidates 空时仅校第一/三条
    enforceBossRecruitRedLines(
      stageDefs: stageDefs,
      sectCandidates: sectCandidates,
    );
    enforceSkillDropRedLines(stageDefs: stageDefs, skillDefs: skillDefs);

    // F7（2026-06-23 掉落优化 配置卫生）：dropTable 引用完整性（stage + tower 全覆盖）。
    enforceDropTableReferences(
      stageDefs: stageDefs,
      towerFloors: towerFloors,
      equipmentIds: equipmentDefs.keys.toSet(),
    );

    // P0 破招:Boss 招牌蓄力技校验(chargeSkillId 必在敌人 skillIds 内 +
    // boss_charge tick 数值范围)
    enforceBossChargeRedLines(stageDefs: stageDefs, numbers: numbers);

    // 批二①：Boss 阶段 unlockSkillIds 引用必须在 skills.yaml 中存在（含 tower floors）
    enforceBossPhaseSkillIds(
      stageDefs,
      skillDefs.keys.toSet(),
      towerFloors: towerFloors,
    );
    // 批二②:弱点/抗性乘子值域红线（守 §5.4 弱点 ≤2.0；含 tower floors）。
    enforceWeaknessRedLines(
      stageDefs,
      numbers.combat.weakness.minMult,
      numbers.combat.weakness.maxMult,
      towerFloors: towerFloors,
    );
    // floor30 护法结界:guardianWard 引用完整性 + 值域 + 自引用（stage + tower 全覆盖）。
    for (final s in stageDefs.values) {
      enforceGuardianWardReferences(s.enemyTeam, location: 'stage ${s.id} ');
    }
    for (final f in towerFloors) {
      enforceGuardianWardReferences(
        f.enemyTeam,
        location: 'tower floor ${f.floorIndex} ',
      );
    }

    // C1.3.2 断魂庄:敌队随 BossGauntletConfig 独立解析(非 stageDefs/towerFloors),
    // 单独跑同口径引用完整性红线(design §8.2 引用不得悬空)。
    _enforceGauntletEnemyRedLines();

    // 波A build gate:破招技(canInterrupt=true)必须有 style 流派归属
    enforceInterruptSkillRedLines(skillDefs: skillDefs, numbers: numbers);

    // 波A A4:全招必有合法 source 来源 tag + 池/字段一致性
    enforceSkillSourceRedLines(
      skillDefs: skillDefs,
      stageDefs: stageDefs,
      towerFloors: towerFloors,
      encounterSkillIds: encounterSkillIds,
      releaseRealm: getRealmByAbsoluteLevel(
        numbers.progressionReleaseCap.maxAbsoluteRealmLevel,
      ),
    );

    // 2026-06-14 拖招:targetType 语义红线(普攻/合击不可群体 + 群体技集合非空)
    enforceSkillTargetTypeRedLines(skillDefs: skillDefs);

    // Phase 4 W14-1 C-1:encounter fixture 校验(若加载到)
    enforceEncounterRedLines(
      encounterDefs: encounterDefs,
      sectCandidates: sectCandidates,
    );

    // Phase 4 W14-3-A:encounter_skills.yaml 校验 + unlock 引用一致性
    enforceEncounterSkillRedLines(
      skillDefs: skillDefs,
      encounterSkillIds: encounterSkillIds,
      encounterDefs: encounterDefs,
      numbers: numbers,
    );

    // W18-A1:心法相生 yaml 校验(空 list 兼容 test fixture)
    enforceSynergyRedLines(synergies: synergies, techniqueDefs: techniqueDefs);

    // P1.z 机制百科 md 校验(空 map 兼容 test fixture;graceful 缺档 8)
    enforceCodexRedLines(codexEntries: codexEntries);

    // 材料经济 P1：商店标价上限校验（空 map 兼容 test fixture）。
    enforceShopRedLines(shopItemDefs: shopItemDefs, itemDefs: itemDefs);

    // 材料经济 P2：道具经验值红线（空 map 兼容 test fixture）。
    enforceItemRedLines(itemDefs: itemDefs, numbers: numbers);

    // 桃花岛一期：建筑配置红线（itemDefs 为空时跳过，test fixture 兼容）。
    enforceTaohuaIslandRedLines(itemDefs: itemDefs, numbers: numbers);
  }

  /// 批二①：Boss 阶段 unlockSkillIds 红线校验。
  ///
  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配置了
  /// [EnemyDef.bossPhases] 的敌人，校验各阶段 [BossPhaseDef.unlockSkillIds]
  /// 中的每个 id 须在 [skillIdSet] 内存在。
  /// 静态方法便于单元测试独立调用（不依赖 loadAllDefs 完整流程）。
  static void enforceBossPhaseSkillIds(
    Map<String, StageDef> stages,
    Set<String> skillIdSet, {
    Iterable<TowerFloorDef> towerFloors = const [],
  }) {
    void checkPhases({
      required Iterable<BossPhaseDef> phases,
      required String label,
    }) {
      for (final phase in phases) {
        for (final sid in phase.unlockSkillIds) {
          if (!skillIdSet.contains(sid)) {
            throw StateError(
              '$label bossPhase hpThresholdPct='
              '${phase.hpThresholdPct} unlockSkillIds 引用 $sid '
              '未在 skills.yaml 中存在（批二①红线）',
            );
          }
        }
      }
    }

    void checkEnemy({required EnemyDef enemy, required String label}) {
      final phases = enemy.bossPhases;
      if (phases != null) {
        checkPhases(phases: phases, label: label);
      }
      for (final entry in enemy.cycleBossPhases.entries) {
        checkPhases(phases: entry.value, label: '$label cycle ${entry.key}');
      }
    }

    // Stage enemies: label includes stage id for locatability.
    for (final s in stages.values) {
      for (final e in s.enemyTeam) {
        checkEnemy(enemy: e, label: 'stage ${s.id} 敌人 ${e.id}');
      }
    }
    // Tower-floor enemies: label includes floorIndex for locatability.
    for (final f in towerFloors) {
      for (final e in f.enemyTeam) {
        checkEnemy(enemy: e, label: 'tower floor ${f.floorIndex} 敌人 ${e.id}');
      }
    }
  }

  /// 批二②：弱点/抗性乘子值域红线校验。
  ///
  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配了
  /// [EnemyDef.schoolDamageTakenMult] 的敌人，校验各流派
  /// 乘子 ∈ [[minMult], [maxMult]]，越界 throw 含敌人 id + 流派 + 值。
  /// 静态方法便于单元测试独立调用（沿 [enforceBossPhaseSkillIds] 体例）。
  static void enforceWeaknessRedLines(
    Map<String, StageDef> stages,
    double minMult,
    double maxMult, {
    Iterable<TowerFloorDef> towerFloors = const [],
  }) {
    // Stage enemies: label includes stage id for locatability.
    for (final s in stages.values) {
      for (final e in s.enemyTeam) {
        final mults = e.schoolDamageTakenMult;
        if (mults == null) continue;
        for (final entry in mults.entries) {
          final v = entry.value;
          if (v < minMult || v > maxMult) {
            throw StateError(
              'stage ${s.id} 敌人 ${e.id} schoolDamageTakenMult '
              '${entry.key.name}=$v 越界，应 ∈ [$minMult, $maxMult]（批二②红线）',
            );
          }
        }
      }
    }
    // Tower-floor enemies: label includes floorIndex for locatability.
    for (final f in towerFloors) {
      for (final e in f.enemyTeam) {
        final mults = e.schoolDamageTakenMult;
        if (mults == null) continue;
        for (final entry in mults.entries) {
          final v = entry.value;
          if (v < minMult || v > maxMult) {
            throw StateError(
              'tower floor ${f.floorIndex} 敌人 ${e.id} schoolDamageTakenMult '
              '${entry.key.name}=$v 越界，应 ∈ [$minMult, $maxMult]（批二②红线）',
            );
          }
        }
      }
    }
  }

  /// F7（2026-06-23 掉落优化 配置卫生 guardrail）：dropTable 引用完整性校验。
  ///
  /// 遍历所有主线 stage + 爬塔 floor 的 dropTable，启动期 fail-fast：
  ///   - [EquipmentDrop.equipmentDefId] 必须在 [equipmentIds]
  ///     （否则 runtime 取装备会崩 → 战斗中崩，防 Ch5/Ch6 写错悬空）
  ///   - [ItemDrop.inventoryItemDefId] 必须能被 [ItemType.fromDefId] 解析为非
  ///     [ItemType.miscMaterial]（miscMaterial 是兜底吞值桶，悬空/拼错 defId 会
  ///     静默落入并入背包显示成杂项材料；fail-fast 拦下）。
  ///
  /// 保留本入口兼容既有测试/调用；实现委托给独立校验器，
  /// [_enforceRedLines] 启动期统一调用。
  static void enforceDropTableReferences({
    required Map<String, StageDef> stageDefs,
    required List<TowerFloorDef> towerFloors,
    required Set<String> equipmentIds,
  }) => DropTableReferenceValidator.validate(
    stageDefs: stageDefs,
    towerFloors: towerFloors,
    equipmentIds: equipmentIds,
  );

  /// 护法结界引用校验:主 Boss guardianIds 须在同队 enemyTeam 存在,
  /// damageTakenMult ∈ (0,1], guardianIds 非空、不含自身 id。缺失/越界
  /// fail-fast(spec §5)。静态方法便于单元测试独立调用(沿
  /// [enforceWeaknessRedLines] 体例);[location] 非空时前缀进 StateError 便于定位
  /// (如 `'stage foo '` / `'tower floor 30 '`),启动期 [_enforceRedLines] 传入。
  static void enforceGuardianWardReferences(
    List<EnemyDef> enemyTeam, {
    String location = '',
  }) {
    final ids = enemyTeam.map((e) => e.id).toSet();
    for (final e in enemyTeam) {
      final w = e.guardianWard;
      if (w == null) continue;
      if (w.guardianIds.isEmpty) {
        throw StateError('$location敌人 ${e.id} guardianWard.guardianIds 为空');
      }
      if (w.damageTakenMult <= 0 || w.damageTakenMult > 1) {
        throw StateError(
          '$location敌人 ${e.id} guardianWard.damageTakenMult='
          '${w.damageTakenMult} 越界(须 ∈ (0,1])',
        );
      }
      for (final gid in w.guardianIds) {
        if (gid == e.id) {
          throw StateError(
            '$location敌人 ${e.id} guardianWard 引用自身 $gid'
            '(Boss 不能作自己的护法,否则结界永不破)',
          );
        }
        if (!ids.contains(gid)) {
          throw StateError(
            '$location敌人 ${e.id} guardianWard 引用 $gid 不在本队 enemyTeam',
          );
        }
      }
    }
  }

  /// C1.3.2 断魂庄敌队引用完整性红线（design §8.2「敌人/招式引用不得悬空」）。
  ///
  /// 断魂庄敌队随 [BossGauntletConfig.enemyTeams] 独立解析（非 stageDefs/
  /// towerFloors），故在此单独跑与主线/爬塔同口径的校验：
  ///   ① 每关 enemy_team_id 有对应敌队定义（关次引用不悬空）；
  ///   ② 敌人 skillIds 全在 skillDefs（招式引用不悬空）；
  ///   ③ chargeSkillId（若配）在该敌人 skillIds 内（破招红线①同口径）；
  ///   ④ bossPhases/cycleBossPhases 的 unlockSkillIds 全在 skillDefs（批二①同口径）；
  ///   ⑤ guardianWard 引用完整性/值域/自引用（复用 [enforceGuardianWardReferences]）。
  /// vulnerability 开窗途径与 bossPhases 阈值降序已由 `EnemyDef.fromYaml` 兜底。
  void _enforceGauntletEnemyRedLines() {
    final config = bossGauntletConfig;
    if (config == null) return;
    final skillIdSet = skillDefs.keys.toSet();

    // ① 关次 → 敌队引用不悬空。
    for (final stage in config.stages) {
      if (!config.enemyTeams.containsKey(stage.enemyTeamId)) {
        throw StateError(
          'boss_gauntlets: 关次 enemy_team_id=${stage.enemyTeamId} '
          '无对应敌队定义（§8.2 引用悬空）',
        );
      }
    }

    for (final teamEntry in config.enemyTeams.entries) {
      final teamId = teamEntry.key;
      final team = teamEntry.value;
      final loc = 'boss_gauntlets 敌队 $teamId ';
      for (final e in team) {
        // ② skillIds 引用不悬空。
        for (final sid in e.skillIds) {
          if (!skillIdSet.contains(sid)) {
            throw StateError('$loc敌人 ${e.id} skillId=$sid 未在 skills.yaml 存在');
          }
        }
        // ③ chargeSkillId 在自身 skillIds（破招红线①同口径）。
        final cs = e.chargeSkillId;
        if (cs != null && !e.skillIds.contains(cs)) {
          throw StateError(
            '$loc敌人 ${e.id} chargeSkillId=$cs 不在其 skillIds（破招红线①）',
          );
        }
        // ④ bossPhases/cycleBossPhases unlockSkillIds 引用不悬空（批二①同口径）。
        for (final phase in <BossPhaseDef>[
          ...?e.bossPhases,
          for (final ps in e.cycleBossPhases.values) ...ps,
        ]) {
          for (final sid in phase.unlockSkillIds) {
            if (!skillIdSet.contains(sid)) {
              throw StateError(
                '$loc敌人 ${e.id} bossPhase unlockSkillIds 引用 $sid '
                '未在 skills.yaml 存在（批二①红线）',
              );
            }
          }
        }
      }
      // ⑤ 护法结界引用完整性/值域/自引用。
      enforceGuardianWardReferences(team, location: loc);
    }

    // ⑥ 通关奖励引用不悬空（C2.4·§6.2/§8.2）：首通秘籍在 skills.yaml、
    //    三选一命名装备候选在 equipment.yaml。
    if (!skillIdSet.contains(config.firstClearRewardSkillId)) {
      throw StateError(
        'boss_gauntlets: first_clear_reward_skill_id='
        '${config.firstClearRewardSkillId} 未在 skills.yaml 存在（§8.2 引用悬空）',
      );
    }
    for (final eqId in config.rewardCandidateEquipmentIds) {
      if (!equipmentDefs.containsKey(eqId)) {
        throw StateError(
          'boss_gauntlets: reward_candidate_equipment_id=$eqId '
          '未在 equipment.yaml 存在（§8.2 引用悬空）',
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
      orElse: () => throw StateError('境界 ${tier.name}/${layer.name} 未配置'),
    );
  }

  RealmDef getRealmByAbsoluteLevel(int level) {
    if (level < 1 || level > 49) {
      throw RangeError('absoluteLevel 必须 ∈ [1, 49]，实际 $level');
    }
    return realms[level - 1];
  }

  EquipmentDef getEquipment(String defId) =>
      equipmentDefs[defId] ?? (throw StateError('EquipmentDef 未配置: $defId'));

  TechniqueDef getTechnique(String defId) =>
      techniqueDefs[defId] ?? (throw StateError('TechniqueDef 未配置: $defId'));

  SkillDef getSkill(String defId) =>
      skillDefs[defId] ?? (throw StateError('SkillDef 未配置: $defId'));

  StageDef getStage(String defId) =>
      stageDefs[defId] ?? (throw StateError('StageDef 未配置: $defId'));

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
        orElse: () => throw StateError('SeclusionMapDef 未配置: ${mapType.name}'),
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
}
