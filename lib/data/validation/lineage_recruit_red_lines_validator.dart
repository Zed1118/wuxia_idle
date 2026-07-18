import '../../core/domain/enums.dart';
import '../defs/equipment_def.dart';
import '../defs/founder_creation_def.dart';
import '../defs/master_def.dart';
import '../defs/recruit_candidate_def.dart';
import '../defs/sect_candidate_def.dart';
import '../defs/stage_def.dart';
import '../defs/technique_def.dart';
import '../numbers_config.dart';

/// 师徒/招收域加载期红线(2026-07-18 审查批C 自 GameRepository 抽出;
/// enforceLineageOnboardingRedLines / enforceFounderSchoolUniqueness 两个
/// 原类外自由函数同域迁入)。
///
/// 体例:顶层自由函数 + 显式参数,参数名与 GameRepository 字段名一致,
/// 方法体自抽出起逐字未改;越界抛 [StateError] 启动失败(fail-fast)。

/// Phase 3 Week 4 T53 + T55：师徒 3 角色红线。
///
/// 校验项：
///   - 必须 3 条；slotIndex 0/1/2 各一不重不漏
///   - slotIndex=0 必须 founder，slotIndex=1/2 必须 disciple/senior/junior
///   - founder 仅 1 个；不允许 grandDisciple（Demo 不做徒孙）
///   - defaultRealm 严格 < wuSheng（Demo 不做飞升锚点）
///   - AttributeProfile 4 项单项 ∈ [1, 10]，总和 ∈ [16, 24]（GDD §4.1）
///   - startingTechniqueIds / startingEquipmentIds 全部 id 须在对应 def map 中
///   - 三系锁死：starting 装备/心法 tier index ≤ defaultRealm index
///   - ~~T55：祖师起手须含 1 件师承遗物~~ **2026-06-27 放宽移除**（祖师改学徒新手
///     空手起家；师承遗物改游戏中获得；飞升不依赖起手种子。详同名 spec）
void enforceMasterRedLines({
  required List<MasterDef> masters,
  required Map<String, TechniqueDef> techniqueDefs,
  required Map<String, EquipmentDef> equipmentDefs,
}) {
  if (masters.length != 3) {
    throw StateError('师徒角色应为 3 条，实际 ${masters.length}');
  }
  final seenSlots = <int>{};
  var founderCount = 0;
  for (var i = 0; i < masters.length; i++) {
    final m = masters[i];
    if (m.slotIndex != i) {
      throw StateError('师徒 slotIndex 不连续：期望 $i，实际 ${m.slotIndex}（id=${m.id}）');
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
      const validDisciple = {
        LineageRole.disciple,
        LineageRole.senior,
        LineageRole.junior,
      };
      if (!validDisciple.contains(m.lineageRole)) {
        throw StateError(
          '师徒 slot=${m.slotIndex} 必须为 disciple/senior/junior，'
          '实际 ${m.lineageRole.name}（id=${m.id}）',
        );
      }
    }
    // 飞升锚点
    if (m.defaultRealm == RealmTier.wuSheng) {
      throw StateError('师徒 ${m.id} defaultRealm=wuSheng，Demo 阶段不允许（飞升锚点）');
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
  // T55「祖师起手必带师承遗物」于 2026-06-27 放宽移除:祖师改学徒新手、空手起家,
  // 师承遗物改为游戏中获得（Ch3/tower 掉落）;飞升时任选已装备/库存传徒,不依赖
  // 起手种子（ascend_service 空选优雅兜底）。详 spec 2026-06-27-founder-start-realm-novice-design。
}

/// 新档祖师塑形红线:
/// - 三流派选项必须齐全且不重复；
/// - 每个流派至少 1 本起手心法,且心法存在、入门阶、流派一致；
/// - 每个流派必须给 3 件寻常货起手装备,覆盖武器/护甲/饰品各 1 件；
/// - 出身资源差异只能是低量非负数；
/// - 命盘池至少 3 份,每份属性单项 [1,10] / 总和 [16,24]。
void enforceFounderCreationRedLines({
  required FounderCreationConfig founderCreation,
  required Map<String, TechniqueDef> techniqueDefs,
  required Map<String, EquipmentDef> equipmentDefs,
}) {
  if (founderCreation.schools.isEmpty &&
      founderCreation.origins.isEmpty &&
      founderCreation.fatePool.isEmpty) {
    return;
  }
  enforceFounderSchoolUniqueness(founderCreation.schools);
  final schoolSet = <TechniqueSchool>{};
  for (final option in founderCreation.schools) {
    schoolSet.add(option.school);
    if (option.startingTechniqueIds.isEmpty) {
      throw StateError('founder_creation ${option.id} 未配置起手心法');
    }
    for (final techId in option.startingTechniqueIds) {
      final tech = techniqueDefs[techId];
      if (tech == null) {
        throw StateError('founder_creation $techId 未在 techniques.yaml 中');
      }
      if (tech.tier != TechniqueTier.ruMenGong) {
        throw StateError('founder_creation $techId 必须是入门功');
      }
      if (tech.school != option.school) {
        throw StateError('founder_creation $techId 流派与 ${option.id} 不一致');
      }
    }
    if (option.startingEquipmentIds.length != 3) {
      throw StateError('founder_creation ${option.id} 起手装备必须为 3 件');
    }
    final slots = <EquipmentSlot>{};
    for (final equipId in option.startingEquipmentIds) {
      final eq = equipmentDefs[equipId];
      if (eq == null) {
        throw StateError('founder_creation $equipId 未在 equipment.yaml 中');
      }
      if (eq.tier != EquipmentTier.xunChang) {
        throw StateError('founder_creation $equipId 必须是寻常货');
      }
      if (!slots.add(eq.slot)) {
        throw StateError(
          'founder_creation ${option.id} 起手装备槽位重复:${eq.slot.name}',
        );
      }
      if (eq.slot == EquipmentSlot.weapon && eq.schoolBias != option.school) {
        throw StateError('founder_creation $equipId 武器流派与 ${option.id} 不一致');
      }
    }
    if (slots.length != EquipmentSlot.values.length) {
      throw StateError('founder_creation ${option.id} 起手装备必须覆盖武器/护甲/饰品');
    }
  }
  if (schoolSet.length != TechniqueSchool.values.length) {
    throw StateError('founder_creation 必须覆盖刚猛/灵巧/阴柔三流派');
  }

  final originIds = <String>{};
  for (final origin in founderCreation.origins) {
    if (!originIds.add(origin.id)) {
      throw StateError('founder_creation origins id 重复:${origin.id}');
    }
    if (origin.mojianshiBonus < 0 || origin.jieJingBonus < 0) {
      throw StateError('founder_creation 出身资源 bonus 不可为负:${origin.id}');
    }
    if (origin.mojianshiBonus > 50 || origin.jieJingBonus > 3) {
      throw StateError('founder_creation 出身资源 bonus 过高:${origin.id}');
    }
  }
  if (founderCreation.origins.isEmpty) {
    throw StateError('founder_creation 至少需要 1 个出身');
  }

  final fateIds = <String>{};
  for (final fate in founderCreation.fatePool) {
    if (!fateIds.add(fate.id)) {
      throw StateError('founder_creation fatePool id 重复:${fate.id}');
    }
    final ap = fate.attributeProfile;
    for (final entry in <String, int>{
      'constitution': ap.constitution,
      'enlightenment': ap.enlightenment,
      'agility': ap.agility,
      'fortune': ap.fortune,
    }.entries) {
      if (entry.value < 1 || entry.value > 10) {
        throw StateError(
          'founder_creation ${fate.id} ${entry.key}=${entry.value},应 ∈ [1,10]',
        );
      }
    }
    if (ap.total < 16 || ap.total > 24) {
      throw StateError(
        'founder_creation ${fate.id} 总点 ${ap.total} 应 ∈ [16,24]',
      );
    }
  }
  if (founderCreation.fatePool.length < 3) {
    throw StateError('founder_creation fatePool 至少需要 3 份命盘');
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
void enforceRecruitCandidateRedLines({
  required Map<String, RecruitCandidateDef> recruitCandidates,
  required Map<String, TechniqueDef> techniqueDefs,
  required Map<String, EquipmentDef> equipmentDefs,
}) {
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
/// 校验(沿 [enforceRecruitCandidateRedLines] 体例,但 count 不锁 3 →
/// 5-8 弹性,Demo PoC 池余量沿用):
/// - 数量 ∈ [1, 20](防 yaml 误产生空段 / 数量越界)
/// - defaultRealm 不允许 wuSheng(NPC Demo 不为飞升锚点)
/// - attributeProfile 单项 [1,10] / total [16,24]
/// - startingTechniqueIds / startingEquipmentIds 引用合法 + 三系锁死
/// - id 唯一(_parseDefMap 已保证)
///
/// 允许 test fixture 不带 yaml → sectCandidates 空 map → 整个校验跳过。
void enforceSectCandidateRedLines({
  required Map<String, SectCandidateDef> sectCandidates,
  required Map<String, TechniqueDef> techniqueDefs,
  required Map<String, EquipmentDef> equipmentDefs,
}) {
  if (sectCandidates.isEmpty) return; // fixture 兜底
  if (sectCandidates.length > 20) {
    throw StateError('门派招收候选数量=${sectCandidates.length},应 ≤ 20(Demo PoC 5-8)');
  }
  for (final c in sectCandidates.values) {
    if (c.defaultRealm == RealmTier.wuSheng) {
      throw StateError('门派招收候选 ${c.id} defaultRealm=wuSheng,不允许飞升锚点');
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
/// - `bossRecruit.candidateRef` 必须在 sectCandidates 中(沿 Q6A
///   `enforceEncounterRedLines`(validation/) affectsSectMembership 体例 · 允许 fixture
///   sectCandidates 空 map 跳过 ref 校,但仍校第 1/3 条)
/// - `bossRecruit.baseProbability` ∈ [0.0, 1.0]
void enforceBossRecruitRedLines({
  required Map<String, StageDef> stageDefs,
  required Map<String, SectCandidateDef> sectCandidates,
}) {
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
    if (sectCandidates.isNotEmpty && sectCandidates[br.candidateRef] == null) {
      throw StateError(
        'stage ${s.id} bossRecruit.candidateRef=${br.candidateRef} '
        '未在 sect_candidates.yaml 中(spec §6 红线 ②)',
      );
    }
  }
}

/// 第七阶段批三 P2：命名弟子拜入配置红线（纯函数，便于单测各违例）。
///
/// 配置漂移 fail-fast，不静默生成错角色 / 永不触发：
/// - stage_id 必须存在于 stageDefs（同一关可挂多条 join,如终局 06_05 同关拜两弟子）；
/// - **role 在 disciple_joins 内唯一**（每个弟子 role 只拜入一次,防「两个 senior」误配；
///   spec A 后移后允许同 stage_id 多 role,故 dedup 改 role 而非 stage_id）；
/// - role 只允许 senior / junior（非 founder / disciple）；
/// - master_slot_index ∈ [0, masters.length)；
/// - **masters[slot].lineageRole 必须 == join.role**（防 numbers.yaml 与
///   masters.yaml 双源漂移：dedup 查 join.role 但创建用 masters role，
///   不一致会「配置说 senior 实际建 junior」）；
/// - narrative_id 非空。
void enforceLineageOnboardingRedLines({
  required List<DiscipleJoinDef> joins,
  required Set<String> existingStageIds,
  required List<MasterDef> masters,
}) {
  // 空 stages（测试精简 fixture，与覆盖度红线同约定）→ 跳过；生产 stages 必非空。
  if (existingStageIds.isEmpty) return;
  final seenRoles = <LineageRole>{};
  for (final j in joins) {
    if (!existingStageIds.contains(j.stageId)) {
      throw StateError(
        'lineage_onboarding.disciple_joins stage_id=${j.stageId} 引用不存在的关卡',
      );
    }
    if (!seenRoles.add(j.role)) {
      throw StateError(
        'lineage_onboarding.disciple_joins role=${j.role.name} 重复'
        '（每个弟子 role 只能拜入一次）',
      );
    }
    if (j.role != LineageRole.senior && j.role != LineageRole.junior) {
      throw StateError(
        'lineage_onboarding stage_id=${j.stageId} role=${j.role.name} '
        '非法，只允许 senior / junior',
      );
    }
    if (j.masterSlotIndex < 0 || j.masterSlotIndex >= masters.length) {
      throw StateError(
        'lineage_onboarding stage_id=${j.stageId} '
        'master_slot_index=${j.masterSlotIndex} 越界 [0, ${masters.length})',
      );
    }
    final slotRole = masters[j.masterSlotIndex].lineageRole;
    if (slotRole != j.role) {
      throw StateError(
        'lineage_onboarding stage_id=${j.stageId} role=${j.role.name} '
        '与 masters[${j.masterSlotIndex}].lineageRole=${slotRole.name} 不一致',
      );
    }
    if (j.narrativeId.isEmpty) {
      throw StateError(
        'lineage_onboarding stage_id=${j.stageId} narrative_id 为空',
      );
    }
  }
}

/// 祖师塑形 schools 唯一性红线（可独立测试）。
///
/// id 与 school（流派枚举）必须各自唯一。覆盖度红线（必须含三流派）只看
/// 去重后的集合大小，单独跑会把「同一流派配多条」静默吞掉（如 gangMeng×2 +
/// lingQiao + yinRou 仍凑满 3 种而漏过），导致创建页流派选项重复、选择漂移。
/// 本校验与 id 重复检查对称，在覆盖度校验前 fail-fast。
void enforceFounderSchoolUniqueness(List<FounderSchoolOption> schools) {
  final ids = <String>{};
  final usedSchools = <TechniqueSchool>{};
  for (final option in schools) {
    if (!ids.add(option.id)) {
      throw StateError('founder_creation schools id 重复:${option.id}');
    }
    if (!usedSchools.add(option.school)) {
      throw StateError(
        'founder_creation schools school 重复:${option.school.name}'
        '（每个流派只能配一条 schools 项）',
      );
    }
  }
}
