import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/game_event.dart';
import '../../../data/isar_provider.dart';
import '../../../features/battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../cultivation/application/character_advancement_service.dart';

part 'game_event_service.g.dart';

/// GameEvent 9 type 写入 helper(P1 #42 Phase 2)。
///
/// **设计纪律**:
/// - **不开 writeTxn**:caller 已持锁(同事务原子性 + 嵌套 writeTxn 抛 IsarError)
/// - 7 method 对应 7 实装 type:#1 / #2 / #3 / #5 / #6+#9 / #7 / #8
/// - **#9 disciplePromoted 借 [recordRealmBreakthrough] 内 `lineageRole` 路由**,
///   不开独立 method(Demo 阶段语义等同 #6,Phase 5+ 真独立路径再拆)
/// - **#4 techniqueLearned 不实装**:0 业务 caller(`TechniqueLearningService.learn`
///   只 test/seed 调,Phase 5+ §7.2 武学领悟 UI 实装才能挂)
///
/// **GameEvent 表打开方式**:caller 通过 [gameEventServiceProvider] 取 service
/// 实例,在 caller 的 writeTxn 内 await 调用对应 record method 即可。
class GameEventService {
  final Isar isar;

  GameEventService(this.isar);

  /// #1 闭关完成
  Future<void> recordRetreatCompleted({
    required int characterId,
    required String characterName,
    required int actualHours,
    required String mapName,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.retreatCompleted
      ..title = UiStrings.gameEventRetreatTitle
      ..summary = UiStrings.gameEventRetreatSummary(
          characterName, actualHours, mapName)
      ..relatedCharacterId = characterId
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }

  /// #2 奇遇触发
  Future<void> recordAdventureTriggered({
    required int characterId,
    required String encounterId,
    required String encounterTitle,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.adventureTriggered
      ..title = encounterTitle
      ..summary = UiStrings.gameEventAdventureSummary(encounterTitle)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [encounterId]
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }

  /// #3 获得装备
  ///
  /// [characterId] 可空(掉落进背包时 ownerCharacterId == null,事件归挂主角)。
  Future<void> recordEquipmentObtained({
    required int? characterId,
    required int equipmentId,
    required String equipmentDefId,
    required String equipmentName,
    required String source,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.equipmentObtained
      ..title = UiStrings.gameEventEquipmentTitle(equipmentName)
      ..summary = UiStrings.gameEventEquipmentSummary(equipmentName, source)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [equipmentDefId, equipmentId.toString()]
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }

  /// #5 武学领悟
  Future<void> recordSkillEnlightened({
    required int characterId,
    required String skillId,
    required String skillName,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.skillEnlightened
      ..title = UiStrings.gameEventSkillTitle(skillName)
      ..summary = UiStrings.gameEventSkillSummary(skillName)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [skillId]
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }

  /// #6 realmBreakthrough(主角) / #9 disciplePromoted(弟子)。
  ///
  /// 内部按 `character.lineageRole` 路由 eventType。Demo 阶段两路径数值等同,
  /// 真独立 #9 路径推 Phase 5+ 师徒系统升级。
  ///
  /// safety:`result.layersGained <= 0` 兜底 return(caller 一般已判 didAdvance)。
  Future<void> recordRealmBreakthrough({
    required Character character,
    required AdvancementResult result,
  }) async {
    if (result.layersGained <= 0) return;
    final isDisciple = character.lineageRole == LineageRole.disciple;
    final eventType = isDisciple
        ? GameEventType.disciplePromoted
        : GameEventType.realmBreakthrough;
    final title = isDisciple
        ? UiStrings.gameEventDiscipleTitle(character.name)
        : UiStrings.gameEventBreakthroughTitle;
    final realmName =
        EnumL10n.realm(result.tierAfter, result.layerAfter);
    await isar.gameEvents.put(GameEvent()
      ..eventType = eventType
      ..title = title
      ..summary =
          UiStrings.gameEventBreakthroughSummary(character.name, realmName)
      ..relatedCharacterId = character.id
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }

  /// #7 共鸣度晋升
  Future<void> recordResonanceUpgraded({
    required int characterId,
    required int equipmentId,
    required String equipmentName,
    required int newStage,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.resonanceUpgraded
      ..title = UiStrings.gameEventResonanceTitle(equipmentName)
      ..summary =
          UiStrings.gameEventResonanceSummary(equipmentName, newStage)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [equipmentId.toString()]
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }

  /// #8 击败 Boss
  ///
  /// caller 必先判 isFirstClear(主线读 `MainlineProgress.clearedStageIds`,
  /// 爬塔已有 `clearResult.isFirstClear`),防刷塔重复触发。
  Future<void> recordBossDefeated({
    required int characterId,
    required String stageId,
    required String stageName,
    required String bossName,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.bossDefeated
      ..title = UiStrings.gameEventBossTitle(bossName)
      ..summary = UiStrings.gameEventBossSummary(bossName, stageName)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [stageId]
      ..occurredAt = DateTime.now()
      ..isRead = false);
  }
}

/// nullable propagation(沿 [isarProvider] 体例):Isar 未 init 时返回 null,
/// caller 端 null-coalesce 跳过事件写入(test 路径自然 skip)。
@riverpod
GameEventService? gameEventService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return GameEventService(isar);
}
