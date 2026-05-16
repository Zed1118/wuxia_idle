import 'package:flutter/foundation.dart' show debugPrint;
import 'package:isar_community/isar.dart';

import '../../../data/defs/skill_def.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/utils/rng.dart';
import '../domain/encounter_def.dart';
import '../domain/encounter_progress.dart';

/// 单条 trigger 候选(internal,evaluateTriggers 返回)。
typedef TriggerableEncounter = ({EncounterDef def, double probability});

/// applyOutcome 返回值,UI 端展示用。
sealed class OutcomeApplied {
  const OutcomeApplied();
}

class UnlockSkillApplied extends OutcomeApplied {
  final String skillId;
  const UnlockSkillApplied(this.skillId);
}

class AttributeBonusApplied extends OutcomeApplied {
  final AttributeKey key;
  final int delta;
  const AttributeBonusApplied(this.key, this.delta);
}

class AttributeCapReached extends OutcomeApplied {
  /// 已达 [cap] 上限,outcome 被静默吞(不抛错,GDD §4.1 line 183 设计)。
  final int cap;
  const AttributeCapReached(this.cap);
}

class NoneOutcome extends OutcomeApplied {
  const NoneOutcome();
}

/// 装备奇遇 skill 结果(C-W14-3-A,sealed 便于 UI exhaustive switch)。
sealed class EquipEncounterSkillResult {
  const EquipEncounterSkillResult();
}

class EquipSucceeded extends EquipEncounterSkillResult {
  final String skillId;
  const EquipSucceeded(this.skillId);
}

/// 该 skillId 不在 [EncounterProgress.unlockedSkillIds] 内(玩家未通过奇遇 unlock)。
class EquipNotUnlocked extends EquipEncounterSkillResult {
  final String skillId;
  const EquipNotUnlocked(this.skillId);
}

/// 角色境界未达 skill.tier(GDD §5.3 三系锁死)。
class EquipTierLocked extends EquipEncounterSkillResult {
  final int requiredTier;
  final RealmTier currentTier;
  const EquipTierLocked({
    required this.requiredTier,
    required this.currentTier,
  });
}

/// 角色 / skill 不存在(配置错或并发删除)。
class EquipNotFound extends EquipEncounterSkillResult {
  final String reason;
  const EquipNotFound(this.reason);
}

/// 奇遇 / 武学领悟服务(C-W14-1)。
///
/// 三个核心 API:
///   - [recordKill]:战斗 victory hook 调,累积按流派击杀数
///   - [evaluateTriggers]:战斗 victory 之后调,返回首个可触发的 encounter
///   - [applyOutcome]:玩家选择 outcome_id 后调,执行 unlock skill / +1 attribute
///
/// 设计原则:
///   - **service 不依赖 GameRepository**:caller 端注入 encounters 列表,
///     便于测试与 fixture 隔离(沿用 TowerProgressService 体例)
///   - **fortune 软概率**:p = base * (1 + fortune / 20)(C-W14-1 决策点 Q3)
///   - **lifetime cap**:4 属性总和 ≤ [attributeGainCap](默认 5,
///     GDD §4.1 line 183)。达 cap 后 applyOutcome 返回 [AttributeCapReached],
///     不写 Isar、不抛错
///   - **Isar fixed-length list 教训**(W13):写 schoolKillCounts 前必须
///     `List.of(...)` 转 growable
class EncounterService {
  const EncounterService({
    required this.isar,
    this.attributeGainCap = 5,
  });

  final Isar isar;
  final int attributeGainCap;

  /// 获取或创建进度行。
  Future<EncounterProgress> getOrCreate({required int saveDataId}) async {
    final existing = await isar.encounterProgress
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .findFirst();
    if (existing != null) return existing;

    final fresh = EncounterProgress()
      ..saveDataId = saveDataId
      ..triggeredEncounterIds = []
      ..schoolKillCounts = []
      ..unlockedSkillIds = []
      ..createdAt = DateTime.now();
    await isar.writeTxn(() => isar.encounterProgress.put(fresh));
    return fresh;
  }

  /// 战斗 victory hook 调:按敌人流派 +1(每个 enemy 一次)。
  ///
  /// W13 教训:Isar findAll list fixed-length,写前 `List.of`。
  Future<void> recordKill({
    required int saveDataId,
    required List<TechniqueSchool> defeatedSchools,
  }) async {
    if (defeatedSchools.isEmpty) return;
    await isar.writeTxn(() async {
      final progress = await isar.encounterProgress
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .findFirst();
      if (progress == null) {
        throw StateError(
          'EncounterProgress 未初始化:getOrCreate 未在 recordKill 前调用',
        );
      }
      // W13 fixed-length list 教训
      progress.schoolKillCounts = List.of(progress.schoolKillCounts);
      for (final s in defeatedSchools) {
        progress.schoolKillCounts.increment(s);
      }
      await isar.encounterProgress.put(progress);
    });
  }

  /// 挂机时长累积(C-W14-2)。
  ///
  /// 闭关 [SeclusionService.completeRetreat] 在写产出 txn 内调用,按
  /// `actualHours × 60` 喂分钟。biome/weather 任一为 null 跳过该维度
  /// (闭关地图未标 biome/weather 时 noop,不抛错)。
  ///
  /// W13 教训:写前 `List.of` 转 growable。
  Future<void> recordIdleMinutes({
    required int saveDataId,
    required EncounterBiome? biome,
    required EncounterWeather? weather,
    required int minutes,
  }) async {
    if (minutes <= 0) return;
    if (biome == null && weather == null) return;
    await isar.writeTxn(() async {
      final progress = await isar.encounterProgress
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .findFirst();
      if (progress == null) {
        throw StateError(
          'EncounterProgress 未初始化:getOrCreate 未在 recordIdleMinutes 前调用',
        );
      }
      // W13 fixed-length list 教训
      progress.biomeMinutes = List.of(progress.biomeMinutes);
      progress.weatherMinutes = List.of(progress.weatherMinutes);
      if (biome != null) progress.biomeMinutes.addMinutes(biome, minutes);
      if (weather != null) {
        progress.weatherMinutes.addMinutes(weather, minutes);
      }
      await isar.encounterProgress.put(progress);
    });
  }

  /// 评估所有可触发的 encounter。
  ///
  /// 流程:
  ///   1. 过滤已触发的 id
  ///   2. trigger 全部满足(schoolKillThreshold AND 全过 + fortune >= required)
  ///   3. 软概率公式 p = baseProbability * (1 + fortune/20),roll rng
  ///   4. 返回首个 roll 通过的 encounter(防止一次战斗连弹多个)
  ///
  /// caller(stage_entry_flow / tower_entry_flow)拿到非 null 后弹 UI。
  /// UI 关闭(玩家选/skip)后调 [applyOutcome] + [markTriggered]。
  Future<EncounterDef?> evaluateTriggers({
    required int saveDataId,
    required Attributes attributes,
    required List<EncounterDef> encounters,
    required Rng rng,
  }) async {
    final progress = await isar.encounterProgress
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .findFirst();
    if (progress == null) return null;

    final triggered = progress.triggeredEncounterIds.toSet();

    for (final def in encounters) {
      if (triggered.contains(def.id)) continue;
      if (!_checkTrigger(def, progress, attributes)) continue;

      final p = def.baseProbability * (1 + attributes.fortune / 20.0);
      if (rng.nextDouble() < p) {
        return def;
      }
    }
    return null;
  }

  /// 标记 encounter 已触发(从候选池剔除)。
  ///
  /// 通常在 UI dialog 出现的同一 frame 调用(或 applyOutcome 之前),
  /// 避免重复触发同一条。
  Future<void> markTriggered({
    required int saveDataId,
    required String encounterId,
  }) async {
    await isar.writeTxn(() async {
      final progress = await isar.encounterProgress
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .findFirst();
      if (progress == null) return;
      if (progress.triggeredEncounterIds.contains(encounterId)) return;
      progress.triggeredEncounterIds =
          List.of(progress.triggeredEncounterIds)..add(encounterId);
      await isar.encounterProgress.put(progress);
    });
  }

  /// 应用 outcome,返回结构化结果(UI 用)。
  ///
  /// 三种 OutcomeType:
  ///   - unlockSkill:append to [EncounterProgress.unlockedSkillIds](去重)
  ///   - attributeBonus:检查 lifetime cap,加 +delta 到对应字段
  ///   - none:无 effect
  ///
  /// cap 达到时返回 [AttributeCapReached],不写 Isar(GDD §4.1 line 183
  /// "微弱后天弥补,生涯最多 +5")。
  Future<OutcomeApplied> applyOutcome({
    required int saveDataId,
    required EncounterDef encounter,
    required String outcomeId,
  }) async {
    final outcome = encounter.resolveOutcome(outcomeId);

    OutcomeApplied result = const NoneOutcome();
    await isar.writeTxn(() async {
      final progress = await isar.encounterProgress
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .findFirst();
      if (progress == null) {
        throw StateError(
          'EncounterProgress 未初始化:getOrCreate 未在 applyOutcome 前调用',
        );
      }

      switch (outcome.type) {
        case OutcomeType.unlockSkill:
          final sid = outcome.skillId!;
          if (!progress.unlockedSkillIds.contains(sid)) {
            progress.unlockedSkillIds =
                List.of(progress.unlockedSkillIds)..add(sid);
            await isar.encounterProgress.put(progress);
          }
          result = UnlockSkillApplied(sid);

        case OutcomeType.attributeBonus:
          if (progress.attributeGainsTotal >= attributeGainCap) {
            result = AttributeCapReached(attributeGainCap);
            return;
          }
          final key = outcome.attributeKey!;
          final delta = outcome.attributeDelta;
          // 部分超 cap 时按剩余空间裁剪(保证总和 ≤ cap)
          final remaining = attributeGainCap - progress.attributeGainsTotal;
          final applied = delta < remaining ? delta : remaining;
          switch (key) {
            case AttributeKey.constitution:
              progress.attributeGainsConstitution += applied;
            case AttributeKey.enlightenment:
              progress.attributeGainsEnlightenment += applied;
            case AttributeKey.agility:
              progress.attributeGainsAgility += applied;
            case AttributeKey.fortune:
              progress.attributeGainsFortune += applied;
          }
          await isar.encounterProgress.put(progress);
          result = AttributeBonusApplied(key, applied);

        case OutcomeType.none:
          result = const NoneOutcome();
      }
    });
    return result;
  }

  /// 装备奇遇 skill 到 character(C-W14-3-A)。
  ///
  /// 检查顺序(短路返回):
  ///   1. Character / EncounterProgress 存在
  ///   2. skillDef 必须是奇遇 skill(`isEncounterSkill == true`)
  ///   3. skillId 在 [EncounterProgress.unlockedSkillIds]
  ///   4. character.realmTier.index >= skillDef.tier - 1(境界 ≥ tier)
  ///
  /// 通过后 `character.equippedEncounterSkillId = skillId`,写 Isar。
  ///
  /// 返回 [EquipEncounterSkillResult] sealed,UI 端 exhaustive switch 渲染。
  Future<EquipEncounterSkillResult> equipEncounterSkill({
    required int characterId,
    required SkillDef skillDef,
    required int saveDataId,
  }) async {
    if (!skillDef.isEncounterSkill) {
      return EquipNotFound('skill ${skillDef.id} 不是奇遇招式');
    }
    final tier = skillDef.tier!;
    EquipEncounterSkillResult result = const EquipNotFound('未初始化');
    try {
      await isar.writeTxn(() async {
        final character = await isar.characters.get(characterId);
        if (character == null) {
          result = EquipNotFound('character #$characterId 不存在');
          return;
        }
        final progress = await isar.encounterProgress
            .filter()
            .saveDataIdEqualTo(saveDataId)
            .findFirst();
        if (progress == null) {
          result = EquipNotFound('EncounterProgress slot=$saveDataId 未初始化');
          return;
        }
        if (!progress.unlockedSkillIds.contains(skillDef.id)) {
          result = EquipNotUnlocked(skillDef.id);
          return;
        }
        // RealmTier 7 值:xueTu(0)/sanLiu(1)/erLiu(2)/yiLiu(3)/jueDing(4)/
        // zongShi(5)/wuSheng(6)。tier 1-7 ↔ index 0-6。
        if (character.realmTier.index < tier - 1) {
          result = EquipTierLocked(
            requiredTier: tier,
            currentTier: character.realmTier,
          );
          return;
        }
        character.equippedEncounterSkillId = skillDef.id;
        await isar.characters.put(character);
        result = EquipSucceeded(skillDef.id);
      });
    } catch (e, st) {
      debugPrint('equipEncounterSkill failed: $e\n$st');
      rethrow;
    }
    return result;
  }

  /// 卸下 character 的奇遇 skill slot(返回 true 表示原本有装备)。
  Future<bool> unequipEncounterSkill({required int characterId}) async {
    var hadEquipped = false;
    try {
      await isar.writeTxn(() async {
        final character = await isar.characters.get(characterId);
        if (character == null) return;
        hadEquipped = character.equippedEncounterSkillId != null;
        if (!hadEquipped) return;
        character.equippedEncounterSkillId = null;
        await isar.characters.put(character);
      });
    } catch (e, st) {
      debugPrint('unequipEncounterSkill failed: $e\n$st');
      rethrow;
    }
    return hadEquipped;
  }

  /// 静态 canEquip 校验(纯函数,UI 装备面板 disabled 判定用)。
  ///
  /// 不查 unlock 池(caller 已知 progress);仅校验 tier 锁死。
  static bool canEquipEncounterSkillByTier({
    required RealmTier realmTier,
    required int skillTier,
  }) =>
      realmTier.index >= skillTier - 1;

  /// trigger 全满足判定(纯函数,无 IO,便于测试)。
  ///
  /// 多维度 AND 语义:fortune + schoolKill + biomeMinutes + weatherMinutes
  /// 任一不满足直接返 false。任一维度配空 map = 该维度免审。
  static bool _checkTrigger(
    EncounterDef def,
    EncounterProgress progress,
    Attributes attributes,
  ) {
    // fortune 下限
    final required = def.trigger.fortuneRequired;
    if (required != null && attributes.fortune < required) return false;
    // 每流派击杀阈值
    for (final entry in def.trigger.schoolKillThreshold.entries) {
      if (progress.schoolKillCounts.countOf(entry.key) < entry.value) {
        return false;
      }
    }
    // 每 biome 挂机分钟阈值(C-W14-2)
    for (final entry in def.trigger.biomeMinutes.entries) {
      if (progress.biomeMinutes.minutesOf(entry.key) < entry.value) {
        return false;
      }
    }
    // 每 weather 挂机分钟阈值(C-W14-2)
    for (final entry in def.trigger.weatherMinutes.entries) {
      if (progress.weatherMinutes.minutesOf(entry.key) < entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// 测试 / 别名:走 [IsarSetup.currentSlotId] 包装,供 stage_entry_flow 等
/// caller 不显式传 saveDataId(沿用 TowerProgressService 体例)。
extension EncounterServiceCurrentSlot on EncounterService {
  Future<void> recordKillCurrentSlot({
    required List<TechniqueSchool> defeatedSchools,
  }) =>
      recordKill(
        saveDataId: IsarSetup.currentSlotId,
        defeatedSchools: defeatedSchools,
      );

  Future<EncounterDef?> evaluateTriggersCurrentSlot({
    required Attributes attributes,
    required List<EncounterDef> encounters,
    required Rng rng,
  }) =>
      evaluateTriggers(
        saveDataId: IsarSetup.currentSlotId,
        attributes: attributes,
        encounters: encounters,
        rng: rng,
      );
}
