import '../defs/encounter_def.dart';
import '../defs/sect_candidate_def.dart';
import '../defs/skill_def.dart';
import '../numbers_config.dart';

/// 奇遇域加载期红线(2026-07-18 审查批C 自 GameRepository 抽出)。
///
/// 体例:顶层自由函数 + 显式参数,参数名与 GameRepository 字段名一致,
/// 方法体自抽出起逐字未改;越界抛 [StateError] 启动失败(fail-fast)。

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
///
/// 注:本函数同时是 GDD §5.4「招式倍率全局 ≤8000 单线」的 schema 唯一真 sink
/// (对全部 skillDefs 含 skills.yaml 校验,原 GameRepository._enforceEncounterSkillRedLines)。
void enforceEncounterSkillRedLines({
  required Map<String, SkillDef> skillDefs,
  required Set<String> encounterSkillIds,
  required Map<String, EncounterDef> encounterDefs,
  required NumbersConfig numbers,
}) {
  final skillPowerMax = numbers.combat.redLines.skillPowerMultiplierMax;
  final qiDeltaAbsCap = numbers.combat.qi.deltaAbsCap;
  // GDD §5.4 红线:全游戏招式 powerMultiplier ≤ 配置上限。覆盖 skills.yaml +
  // encounter_skills.yaml 全部 skillDefs——此前该上限只在下方 encounterSkillIds
  // 循环内校验,普通心法招(skills.yaml)越界会静默 load(审计 C-F4 缺口)。
  for (final s in skillDefs.values) {
    if (s.powerMultiplier > skillPowerMax) {
      throw StateError(
        'skill ${s.id} powerMultiplier=${s.powerMultiplier} > '
        '$skillPowerMax (GDD §5.4)',
      );
    }
    if (s.qiDelta.abs() > qiDeltaAbsCap) {
      throw StateError(
        'skill ${s.id} qiDelta=${s.qiDelta} abs > '
        '$qiDeltaAbsCap (numbers.combat.qi.deltaAbsCap)',
      );
    }
  }
  const tierCaps = [1500, 2000, 2500, 3000, 4000, 5500, 8000];
  for (final id in encounterSkillIds) {
    final s = skillDefs[id]!;
    final tier = s.tier;
    if (tier == null || tier < 1 || tier > 7) {
      throw StateError('encounter skill $id tier=$tier,应 ∈ [1, 7]');
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
    // 全局 ≤ 8000 上限已在方法开头对全部 skillDefs 统一校验,此处只保留
    // encounter 专属的 per-tier 更严 cap。
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
void enforceEncounterRedLines({
  required Map<String, EncounterDef> encounterDefs,
  required Map<String, SectCandidateDef> sectCandidates,
}) {
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
      throw StateError('encounter ${def.id} fortuneRequired=$fr 应 ∈ [1, 10]');
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
      if (fallback != null && !def.outcomeMapping.containsKey(fallback)) {
        throw StateError(
          'encounter ${def.id} affectsSectMembership.fallbackOutcomeId='
          '$fallback 未在 outcomeMapping 中(spec §3 cap 满/拒绝 fallback)',
        );
      }
    }
  }
}
