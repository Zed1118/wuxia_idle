import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/application/cultivation_service.dart';
import 'package:wuxia_idle/features/cultivation/application/technique_learn_flow_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_service.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/derived_stats.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';

import 'phase0a_ch1_founder_profile.dart';

/// 满 build 极值画像夹具（派单包 B 目标 1）。
///
/// 与 [seedPhase0aCh1FounderProfile] 相同的生产创建路径起档（Isar 临时库 +
/// [OnboardingService]），再沿**生产服务**把角色推到终局满 build：
///   - 境界：[CharacterAdvancementService.applyExperience] 推到武圣·登峰
///     （禁止直接写 `realmTier`）；
///   - 主修：本流派传说神功（`chuanShuoShenGong`）中招式倍率最高者，经
///     [TechniqueLearnFlowService] 学习、[CultivationService] 推满极境（`jiJing`）；
///   - 辅修：本流派其余心法按 tier 降序，循环学习到生产拒绝（`assistSlotsFull`）
///     为止——**上限由生产逻辑派生，不硬编码槽数**；
///   - 装备：神物（`shenWu`）三槽，武器按流派内基础攻击最高者程序化选取
///     （`where + sort`，无硬编码 id 清单），强化到 [RealmUtils.maxEnhanceLevelOf]、
///     共鸣到最高段、开锋三槽满，经 [EquipmentService.equip] 上身；
///   - 快照：恒由 [PlayerCombatantSnapshotAssembler] 重新装配，不手拼。
///
/// 任一装备/心法步骤被三系锁死（或占用）拒绝即 `throw`，不静默降级——满 build
/// 必须是生产路径真实可达的构筑，否则探针结论无意义。
///
/// 与既有 calculator 探针 `test/balance/full_build_damage_redline_test.dart` 的
/// 体例对齐（+49 强化 / 心剑通灵共鸣 / 双攻击开锋），使本夹具成为其「真实
/// reducer 路径」的对照件。以下偏离生产经济/约束处已在审计报告登记「建议上提」：
///   1. 直接 [Equipment.create] 设定强化/共鸣/开锋，绕过 EnhancementService /
///      ForgingService 的材料经济路径；
///   2. 开锋一、二同取 `attack`（与红线 oracle 同体例）违反生产「开锋二不得与
///      开锋一同类型」约束；
///   3. 辅修槽上限在生产 `technique_learning.dart` 写死为 3、未进 numbers.yaml。
final class Phase0aFullBuildProfile {
  const Phase0aFullBuildProfile({
    required this.profileId,
    required this.school,
    required this.snapshot,
    required this.weaponDefId,
    required this.armorDefId,
    required this.accessoryDefId,
    required this.mainTechniqueDefId,
    required this.assistTechniqueDefIds,
    required this.enhanceLevel,
    required this.maxEnhanceLevel,
    required this.resonanceBattleCount,
    required this.absoluteRealmLevel,
  });

  final String profileId;
  final TechniqueSchool school;
  final CombatantSnapshot snapshot;
  final String weaponDefId;
  final String armorDefId;
  final String accessoryDefId;
  final String mainTechniqueDefId;
  final List<String> assistTechniqueDefIds;
  final int enhanceLevel;
  final int maxEnhanceLevel;
  final int resonanceBattleCount;
  final int absoluteRealmLevel;
}

/// 造一个 [school] 流派的满 build 画像。调用前须已 `initializeTestIsarCore()` +
/// 在临时目录 `IsarSetup.init` + `GameRepository.loadAllDefs`，且传入的 [isar]
/// 为空库（无 founder）。
Future<Phase0aFullBuildProfile> seedPhase0aFullBuildProfile({
  required Isar isar,
  required TechniqueSchool school,
  String originId = 'mountain_wanderer',
  String fateId = 'balanced_seed',
  int rngSeed = 20260820,
}) async {
  if (!GameRepository.isLoaded) {
    throw StateError('GameRepository 必须在造满 build 画像前加载');
  }
  final repo = GameRepository.instance;
  final numbers = repo.numbers;
  const characterId = 1;

  // 1. 流派 → founder_creation 选项 id（与诊断口径同源：mountain_wanderer/balanced_seed）。
  final schoolOption = repo.founderCreation.schools.firstWhere(
    (option) => option.school == school,
    orElse: () => throw StateError('founder_creation 缺流派 ${school.name}'),
  );

  // 2. 生产创建路径起档（character id 1）。
  await seedPhase0aCh1FounderProfile(
    isar: isar,
    schoolId: schoolOption.id,
    originId: originId,
    fateId: fateId,
    rngSeed: rngSeed,
  );

  final character = await isar.characters.get(characterId);
  if (character == null) {
    throw StateError('起档后找不到 characterId=$characterId');
  }

  // 3. 境界：走生产推进服务到武圣·登峰（不直接写 realmTier）。
  final totalExp = _experienceToReachTopRealm(character, repo);
  CharacterAdvancementService.applyExperience(
    character,
    totalExp,
    realmLookup: repo.getRealm,
    isLayerLocked: null,
  );
  if (character.realmTier != RealmTier.wuSheng ||
      character.realmLayer != RealmLayer.dengFeng) {
    throw StateError(
      '满 build 夹具无法推进到武圣·登峰，停在 '
      '${character.realmTier.name}·${character.realmLayer.name}',
    );
  }
  final maxEnhance = RealmUtils.maxEnhanceLevelOf(character);
  final absoluteRealmLevel = RealmUtils.absoluteLevelOf(
    character.realmTier,
    character.realmLayer,
  );

  // 内力补满、清内息紊乱/伤势，避免非满 build 干扰极值。
  character.internalForce = character.internalForceMax;
  character.innerBreathDisorderHoursRemaining = 0;
  character.lightInjuryStacks = 0;
  character.injuryHoursRemaining = 0;

  // 4. 重置起手 loadout：删起手心法、清主辅修指针、充领悟点钱包。
  //    辅修候选先算好，钱包按「主修 + 全部辅修候选」足额，学习循环到生产拒绝为止。
  final mainDef = _selectMainTechnique(repo, school);
  final assistCandidates = _selectAssistCandidates(repo, school, mainDef.id);
  final wallet =
      numbers.learningCost.costFor(TechniqueRole.main) +
      assistCandidates.length *
          numbers.learningCost.costFor(TechniqueRole.assist);
  final starterTechniqueIds = await isar.techniques
      .filter()
      .ownerCharacterIdEqualTo(characterId)
      .idProperty()
      .findAll();
  character.mainTechniqueId = null;
  character.assistTechniqueIds = [];
  character.insightPoints = wallet;
  await isar.writeTxn(() async {
    await isar.techniques.deleteAll(starterTechniqueIds);
    await isar.characters.put(character);
  });

  // 5. 主修：学习传说神功并推满极境。
  final learnFlow = TechniqueLearnFlowService(isar);
  final mainLearn = await learnFlow.learn(
    characterId: characterId,
    techniqueDefId: mainDef.id,
    role: TechniqueRole.main,
  );
  if (!mainLearn.isSuccess || mainLearn.learnedTechniqueId == null) {
    throw StateError('主修 ${mainDef.id} 学习被拒：${mainLearn.status.name}');
  }
  final mainTechniqueId = mainLearn.learnedTechniqueId!;
  final cultivationDelta =
      numbers.cultivationProgressToNext.values.fold<int>(0, (a, b) => a + b) +
      1000;
  await isar.writeTxn(() async {
    final tech = await isar.techniques.get(mainTechniqueId);
    if (tech == null) {
      throw StateError('主修心法实例 $mainTechniqueId 落库后丢失');
    }
    CultivationService.applyProgressDelta(
      tech: tech,
      delta: cultivationDelta,
      progressToNextMap: numbers.cultivationProgressToNext,
    );
    await isar.techniques.put(tech);
  });
  final mainTechnique = await isar.techniques.get(mainTechniqueId);
  if (mainTechnique?.cultivationLayer != CultivationLayer.jiJing) {
    throw StateError(
      '主修修炼度未达极境：${mainTechnique?.cultivationLayer.name}',
    );
  }

  // 6. 辅修：按 tier 降序循环学习，直到生产返回 assistSlotsFull（派生槽上限）。
  final assistDefIds = <String>[];
  for (final candidate in assistCandidates) {
    final result = await learnFlow.learn(
      characterId: characterId,
      techniqueDefId: candidate.id,
      role: TechniqueRole.assist,
    );
    if (result.status == TechniqueLearnFlowStatus.assistSlotsFull) break;
    if (!result.isSuccess) {
      throw StateError('辅修 ${candidate.id} 学习被拒：${result.status.name}');
    }
    assistDefIds.add(candidate.id);
  }
  if (assistDefIds.isEmpty) {
    throw StateError('流派 ${school.name} 未能配出任何辅修');
  }

  // 7. 装备：神物三槽程序化选取 + 满强化/满共鸣/满开锋，经生产 equip 上身。
  final weaponDef = _selectEquipment(repo, EquipmentSlot.weapon, school);
  final armorDef = _selectEquipment(repo, EquipmentSlot.armor, null);
  final accessoryDef = _selectEquipment(repo, EquipmentSlot.accessory, null);
  final resonanceBattleCount = numbers.resonanceStages.last.minBattleCount;
  final equipService = EquipmentService(isar: isar);
  for (final def in [weaponDef, armorDef, accessoryDef]) {
    final equipment = _buildMaxEquipment(
      def: def,
      numbers: numbers,
      enhanceLevel: maxEnhance,
      resonanceBattleCount: resonanceBattleCount,
      ownerCharacterId: characterId,
    );
    final equipmentId = await isar.writeTxn(() => isar.equipments.put(equipment));
    final outcome = await equipService.equip(
      characterId: characterId,
      equipmentId: equipmentId,
    );
    if (outcome != EquipOutcome.success) {
      throw StateError('神物 ${def.id} 装备被拒：${outcome.name}（三系锁死/占用）');
    }
  }

  // 8. 快照：恒由生产装配器重新装配。
  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster(const [characterId]);
  if (snapshots.length != 1) {
    throw StateError('满 build 快照应恰有 1 个，实得 ${snapshots.length}');
  }

  return Phase0aFullBuildProfile(
    profileId: 'full_build/${school.name}',
    school: school,
    snapshot: snapshots.single,
    weaponDefId: weaponDef.id,
    armorDefId: armorDef.id,
    accessoryDefId: accessoryDef.id,
    mainTechniqueDefId: mainDef.id,
    assistTechniqueDefIds: assistDefIds,
    enhanceLevel: maxEnhance,
    maxEnhanceLevel: maxEnhance,
    resonanceBattleCount: resonanceBattleCount,
    absoluteRealmLevel: absoluteRealmLevel,
  );
}

/// 从当前境界沿 [CharacterAdvancementService.nextLayer] 走到武圣·登峰所需的
/// 累计经验（逐层 `experienceToNext` 求和 + 余量，终局层经验保留不消费）。
int _experienceToReachTopRealm(Character character, GameRepository repo) {
  var total = 0;
  var tier = character.realmTier;
  var layer = character.realmLayer;
  var guard = 0;
  while (tier != RealmTier.wuSheng || layer != RealmLayer.dengFeng) {
    total += repo.getRealm(tier, layer).experienceToNext;
    final next = CharacterAdvancementService.nextLayer(tier, layer);
    if (next == null) break;
    tier = next.tier;
    layer = next.layer;
    if (++guard > 100) {
      throw StateError('境界推进循环异常（guard>100）');
    }
  }
  return total + 1000;
}

/// 本流派传说神功中「招式倍率最高」者；同倍率取 id 升序（稳定、偏基础变体）。
TechniqueDef _selectMainTechnique(GameRepository repo, TechniqueSchool school) {
  final candidates = repo.techniqueDefs.values
      .where(
        (tech) =>
            tech.tier == TechniqueTier.chuanShuoShenGong &&
            tech.school == school,
      )
      .toList();
  if (candidates.isEmpty) {
    throw StateError('流派 ${school.name} 无传说神功主修候选');
  }
  candidates.sort((a, b) {
    final byPower = _maxSkillPower(repo, b).compareTo(_maxSkillPower(repo, a));
    return byPower != 0 ? byPower : a.id.compareTo(b.id);
  });
  return candidates.first;
}

int _maxSkillPower(GameRepository repo, TechniqueDef tech) => tech.skillIds
    .map((id) => repo.skillDefs[id]?.powerMultiplier ?? 0)
    .fold(0, (a, b) => a > b ? a : b);

/// 本流派其余心法（排除主修）按 tier 降序、id 升序，供辅修循环依序学习。
List<TechniqueDef> _selectAssistCandidates(
  GameRepository repo,
  TechniqueSchool school,
  String excludeDefId,
) {
  final candidates = repo.techniqueDefs.values
      .where((tech) => tech.school == school && tech.id != excludeDefId)
      .toList();
  candidates.sort((a, b) {
    final byTier = b.tier.index.compareTo(a.tier.index);
    return byTier != 0 ? byTier : a.id.compareTo(b.id);
  });
  return candidates;
}

/// 神物（`shenWu`）指定槽位中基础攻击最高者；[bias] 非空时再按流派过滤。
/// 同攻击取基础血量最高，再同取 id 升序（稳定）。
EquipmentDef _selectEquipment(
  GameRepository repo,
  EquipmentSlot slot,
  TechniqueSchool? bias,
) {
  final candidates = repo.equipmentDefs.values
      .where(
        (equip) =>
            equip.tier == EquipmentTier.shenWu &&
            equip.slot == slot &&
            (bias == null || equip.schoolBias == bias),
      )
      .toList();
  if (candidates.isEmpty) {
    throw StateError(
      '无神物 ${slot.name} 候选（bias=${bias?.name}）',
    );
  }
  candidates.sort((a, b) {
    final byAttack = b.baseAttackMax.compareTo(a.baseAttackMax);
    if (byAttack != 0) return byAttack;
    final byHealth = b.baseHealthMax.compareTo(a.baseHealthMax);
    if (byHealth != 0) return byHealth;
    return a.id.compareTo(b.id);
  });
  return candidates.first;
}

/// 满 build 装备实例：基础值取 def 上界、强化到上限、共鸣到最高段、开锋三槽满
/// （一/二取攻击加成，与红线 oracle 同体例；三取专属技能，无候选则留空 id）。
Equipment _buildMaxEquipment({
  required EquipmentDef def,
  required NumbersConfig numbers,
  required int enhanceLevel,
  required int resonanceBattleCount,
  required int ownerCharacterId,
}) {
  final forging = numbers.forging;
  final attackBonus1 =
      forging.slotByIndex(1).bonusValue[ForgingSlotType.attack] ?? 0;
  final attackBonus2 =
      forging.slotByIndex(2).bonusValue[ForgingSlotType.attack] ?? 0;
  final specialBonus3 =
      forging.slotByIndex(3).bonusValue[ForgingSlotType.specialSkill] ?? 0;
  final specialSkillId = def.specialSkillCandidates.isNotEmpty
      ? def.specialSkillCandidates.first
      : null;
  return Equipment.create(
    defId: def.id,
    tier: def.tier,
    slot: def.slot,
    school: def.schoolBias,
    obtainedAt: DateTime(2026, 9, 19),
    obtainedFrom: 'full_build_probe',
    baseAttack: def.baseAttackMax,
    baseHealth: def.baseHealthMax,
    baseSpeed: def.baseSpeedMax,
    enhanceLevel: enhanceLevel,
    ownerCharacterId: ownerCharacterId,
    battleCount: resonanceBattleCount,
    forgingSlots: [
      ForgingSlot()
        ..slotIndex = 1
        ..type = ForgingSlotType.attack
        ..unlocked = true
        ..bonusValue = attackBonus1,
      ForgingSlot()
        ..slotIndex = 2
        ..type = ForgingSlotType.attack
        ..unlocked = true
        ..bonusValue = attackBonus2,
      ForgingSlot()
        ..slotIndex = 3
        ..type = ForgingSlotType.specialSkill
        ..unlocked = true
        ..bonusValue = specialBonus3
        ..specialSkillId = specialSkillId,
    ],
  );
}
