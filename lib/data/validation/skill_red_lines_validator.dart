import '../../core/domain/enums.dart';
import '../defs/realm_def.dart';
import '../defs/skill_def.dart';
import '../defs/stage_def.dart';
import '../defs/tower_floor_def.dart';
import '../numbers_config.dart';

/// 招式域加载期红线(2026-07-18 审查批C 自 GameRepository 抽出)。
///
/// 体例:顶层自由函数 + 显式参数,参数名与 GameRepository 字段名一致,
/// 方法体自抽出起逐字未改(唯一例外:enforceSkillSourceRedLines 的
/// releaseRealm 由调用方传入,原为实例方法 getRealmByAbsoluteLevel 内查);
/// 越界抛 [StateError] 启动失败(fail-fast)。

/// P0 破招红线(沿 [enforceBossRecruitRedLines] 体例):
/// - 任何配了 chargeSkillId 的敌人:该 id 必须在其 skillIds 内,否则 throw。
/// - numbers.bossCharge:defaultChargeTicks ∈ [1,8] / defaultStaggerTicks ∈ [0,5]。
/// 技能书掉落红线(可玩性 P1a · spec §二)。仅 Boss 关可配 dropSkill,且 id 必须在 skillDefs。
void enforceSkillDropRedLines({
  required Map<String, StageDef> stageDefs,
  required Map<String, SkillDef> skillDefs,
}) {
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
/// 波A interrupt_power_pct 红线:任何阶的有效减防
/// staggerDefenseDown × (1 + pct) 不得超过 interruptPowerCap(cap ∈ (0, 0.5])。
void enforceInterruptSkillRedLines({
  required Map<String, SkillDef> skillDefs,
  required NumbersConfig numbers,
}) {
  final bc = numbers.combat.bossCharge;
  if (bc.interruptPowerCap <= 0 || bc.interruptPowerCap > 0.5) {
    throw StateError(
      'boss_charge.interruptPowerCap=${bc.interruptPowerCap},'
      '应 ∈ (0, 0.5](波A 减防红线)',
    );
  }
  for (final s in skillDefs.values) {
    if (!s.canInterrupt) continue;
    if (s.style == null) {
      throw StateError(
        'skill ${s.id} canInterrupt=true 但缺 style 流派归属(波A build gate 红线)',
      );
    }
    final prof = s.proficiency;
    if (prof == null) continue;
    for (final stage in numbers.skillProficiency.stages) {
      final eff =
          bc.staggerDefenseDown * (1 + prof.interruptPowerPctAt(stage.id));
      if (eff > bc.interruptPowerCap) {
        throw StateError(
          'skill ${s.id} 阶 ${stage.id} 有效减防 '
          '${eff.toStringAsFixed(3)} > cap ${bc.interruptPowerCap}'
          '(波A interrupt_power_pct 红线)',
        );
      }
    }
  }
}

/// 波A A4 来源模型红线(波B 扩 ⑤-⑦):
/// ① 全招 source 非空(yaml 漏配 fail-fast);
/// ② encounter_skills 池全 = encounter;
/// ③ canInterrupt 破招技 = special;
/// ④ stages dropSkillManualId 指向的招 = mainlineDrop;
/// ⑤ 任何 dropSkillFragmentId(塔层/章末重打)指向的招 = fragment(波B 泛化);
/// ⑤+ boss_gauntlets first_clear_reward_skill_id 指向的招 = gauntlet
///    (Phase C 断魂庄首通奖励·2026-07-19 转正,新增识别分支);
/// ⑥ drop 招(mainlineDrop|fragment|gauntlet)必有 style + tier(缺 style 永不可装配,
///    缺 tier canEquipAtRealm 恒 true 破 §5.3,均属配置错误);
/// ⑦ 当前发布阶 drop 招挂载完备:每招恰 1 个挂载点。高于发布
/// 上限的招式定义允许暂无挂载，留给后续副本与玩法;发布阶内但标记
/// mountDeferred 的招同样豁免挂载完备性(正式挂载点尚未做,留 batch3
/// 远征掉落等,挂载时删标记 = 发布)。
///
/// [releaseRealm] 为当前发布上限对应境界(调用方经
/// GameRepository.getRealmByAbsoluteLevel(numbers.progressionReleaseCap
/// .maxAbsoluteRealmLevel) 解出后传入)。
/// [gauntletRewardSkillIds] 为断魂庄首通奖励挂载点(调用方自
/// BossGauntletConfig.firstClearRewardSkillId 收集,空 = 未加载 gauntlet 配置)。
void enforceSkillSourceRedLines({
  required Map<String, SkillDef> skillDefs,
  required Map<String, StageDef> stageDefs,
  required List<TowerFloorDef> towerFloors,
  required Set<String> encounterSkillIds,
  required RealmDef releaseRealm,
  List<String> gauntletRewardSkillIds = const [],
}) {
  final releaseSkillTierCap = releaseRealm.tier.index + 1;
  bool isCurrentReleaseSkill(String id) =>
      (skillDefs[id]?.tier ?? releaseSkillTierCap + 1) <= releaseSkillTierCap;

  for (final s in skillDefs.values) {
    if (s.source == null) {
      throw StateError('skill ${s.id} 缺 source 来源 tag(波A A4 红线 ①)');
    }
    if (encounterSkillIds.contains(s.id) && s.source != SkillSource.encounter) {
      throw StateError(
        'skill ${s.id} 在奇遇池但 source=${s.source!.name}(波A A4 红线 ②)',
      );
    }
    if (s.canInterrupt && s.source != SkillSource.special) {
      throw StateError(
        'skill ${s.id} canInterrupt 但 source=${s.source!.name}(波A A4 红线 ③)',
      );
    }
    if ((s.source == SkillSource.mainlineDrop ||
            s.source == SkillSource.fragment ||
            s.source == SkillSource.gauntlet) &&
        (s.style == null || s.tier == null)) {
      throw StateError(
        'skill ${s.id} source=${s.source!.name} 缺 style/tier(波B 红线 ⑥)',
      );
    }
  }
  final manualMounts = <String>[];
  final fragmentMounts = <String>[];
  final gauntletMounts = <String>[];
  for (final st in stageDefs.values) {
    final m = st.dropSkillManualId;
    if (m != null) {
      if (skillDefs[m]?.source != SkillSource.mainlineDrop) {
        throw StateError(
          'stage ${st.id} dropSkillManualId=$m source 应为 mainline_drop(波A A4 红线 ④)',
        );
      }
      if (isCurrentReleaseSkill(m)) manualMounts.add(m);
    }
    final sf = st.dropSkillFragmentId;
    if (sf != null) {
      if (skillDefs[sf]?.source != SkillSource.fragment) {
        throw StateError(
          'stage ${st.id} dropSkillFragmentId=$sf source 应为 fragment(波B 红线 ⑤)',
        );
      }
      if (isCurrentReleaseSkill(sf)) fragmentMounts.add(sf);
    }
  }
  for (final f in towerFloors) {
    final fr = f.dropSkillFragmentId;
    if (fr != null) {
      if (skillDefs[fr]?.source != SkillSource.fragment) {
        throw StateError(
          'tower floor ${f.floorIndex} dropSkillFragmentId=$fr '
          'source 应为 fragment(波B 红线 ⑤)',
        );
      }
      if (isCurrentReleaseSkill(fr)) fragmentMounts.add(fr);
    }
  }
  for (final g in gauntletRewardSkillIds) {
    if (skillDefs[g]?.source != SkillSource.gauntlet) {
      throw StateError(
        'boss_gauntlets first_clear_reward_skill_id=$g '
        'source 应为 gauntlet(Phase C 断魂庄红线 ⑤+)',
      );
    }
    if (isCurrentReleaseSkill(g)) gauntletMounts.add(g);
  }
  // ⑦ 挂载完备性(test fixture 无 stage/tower defs 时跳过:挂载列表空 +
  // production 加载两者必在,fixture 只载 skills 不应误杀)。
  if (stageDefs.isNotEmpty || towerFloors.isNotEmpty) {
    final manualSkills = skillDefs.values
        .where(
          (s) =>
              s.source == SkillSource.mainlineDrop &&
              !s.mountDeferred &&
              (s.tier ?? releaseSkillTierCap + 1) <= releaseSkillTierCap,
        )
        .map((s) => s.id)
        .toSet();
    final fragmentSkills = skillDefs.values
        .where(
          (s) =>
              s.source == SkillSource.fragment &&
              !s.mountDeferred &&
              (s.tier ?? releaseSkillTierCap + 1) <= releaseSkillTierCap,
        )
        .map((s) => s.id)
        .toSet();
    final gauntletSkills = skillDefs.values
        .where(
          (s) =>
              s.source == SkillSource.gauntlet &&
              !s.mountDeferred &&
              (s.tier ?? releaseSkillTierCap + 1) <= releaseSkillTierCap,
        )
        .map((s) => s.id)
        .toSet();
    void check(String kind, List<String> mounts, Set<String> skills) {
      if (mounts.length != mounts.toSet().length) {
        throw StateError('$kind 招存在重复挂载(波B 红线 ⑦):$mounts');
      }
      final orphan = skills.difference(mounts.toSet());
      final dangling = mounts.toSet().difference(skills);
      if (orphan.isNotEmpty || dangling.isNotEmpty) {
        throw StateError('$kind 招挂载不完备(波B 红线 ⑦):孤儿=$orphan 错挂=$dangling');
      }
    }

    check('mainlineDrop', manualMounts, manualSkills);
    check('fragment', fragmentMounts, fragmentSkills);
    // gauntlet 挂载点未加载(空)且无 gauntlet 来源招时跳过(fixture 兼容);
    // 任一非空即校验——挂载引用缺失(招在、挂载空)即孤儿,错挂/重复同逮。
    if (gauntletMounts.isNotEmpty || gauntletSkills.isNotEmpty) {
      check('gauntlet', gauntletMounts, gauntletSkills);
    }
  }
}

/// 2026-06-14 拖招交互:targetType 语义红线(写约束语义,不锚瞬时数字)。
/// ① normalAttack/jointSkill 必 single(普攻/合击不可群体);
/// ② aoe 群体技集合非空(production 至少有群体技,防回填整体丢失)。
/// 注:fromYaml 默认 single(默认安全),不校验"yaml 必填",只守真正语义约束。
void enforceSkillTargetTypeRedLines({
  required Map<String, SkillDef> skillDefs,
}) {
  var aoeCount = 0;
  for (final s in skillDefs.values) {
    if ((s.type == SkillType.normalAttack || s.type == SkillType.jointSkill) &&
        s.targetType != TargetType.single) {
      throw StateError(
        'skill ${s.id} type=${s.type.name} 不可为群体技 '
        '(普攻/合击必 single · 拖招红线 ①)',
      );
    }
    if (s.targetType == TargetType.aoe) aoeCount++;
  }
  if (aoeCount == 0) {
    throw StateError('production 无任何 aoe 群体技(拖招红线 ②:回填整体丢失?)');
  }
}

/// P0 破招:Boss 招牌蓄力技校验(chargeSkillId 必在敌人 skillIds 内 +
/// boss_charge tick 数值范围)。
void enforceBossChargeRedLines({
  required Map<String, StageDef> stageDefs,
  required NumbersConfig numbers,
}) {
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
