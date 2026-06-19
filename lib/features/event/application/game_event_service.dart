import 'dart:math';

import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/game_event.dart';
import '../../../core/domain/lore.dart';
import '../../../data/lore_loader.dart';
import '../../../features/battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../cultivation/application/character_advancement_service.dart';

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
/// **GameEvent 表打开方式**:caller 端在 writeTxn 内 `GameEventService(isar)` 直接实例化
/// (5 处 caller 体例:tower/seclusion/encounter/mainline 已稳定),调用对应 record method 即可。
class GameEventService {
  final Isar isar;

  /// P1 #44 · LoreLoader 注入(测试用 stub)。默认 null → 跑生产路径
  /// [LoreLoader.load](rootBundle 读 `data/lore/<id>.yaml`)。
  final Future<LoreContent> Function(String loreId)? loreLoader;

  /// P1 #44 · Random 注入(测试用 deterministic seed)。默认 null → new Random()。
  final Random? random;

  GameEventService(this.isar, {this.loreLoader, this.random});

  /// P1 #44 · 占位符替换(简单 String.replaceAll)。
  String _applyPlaceholders(String template, Map<String, String> vars) {
    var result = template;
    vars.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// P1 #44 · 延续典故池随机抽 + 占位符替换 + fallback。
  ///
  /// 流程:
  /// 1. LoreLoader.load(loreId)
  /// 2. placeholder / 对应池为空 → 返回 [fallback](UiStrings Dart 模板兜底)
  /// 3. 池非空 → Random 抽一条 + 占位符替换
  ///
  /// `{equip_name}` 不在 vars 内(yaml 按装备拆池,文案直接写具体兵器名,
  /// 不变量化);仅 `{source}` / `{boss_name}` / `{stage_name}` 走变量。
  Future<String> _resolveContinuedLore({
    required String loreId,
    required bool isBossDefeated,
    required Map<String, String> vars,
    required String fallback,
  }) async {
    final loader = loreLoader ?? LoreLoader.load;
    final lore = await loader(loreId);
    if (lore.isPlaceholder) return fallback;
    final pool = isBossDefeated
        ? lore.continuedLoreBossDefeatedPool
        : lore.continuedLoreObtainedPool;
    if (pool.isEmpty) return fallback;
    final rnd = random ?? Random();
    final pick = pool[rnd.nextInt(pool.length)];
    return _applyPlaceholders(pick.text, vars);
  }

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
  /// [equipment] 非空时同事务追加首段延续典故(P1 #42 Phase 5 / GDD §6.6)。
  /// P1 #44:延续典故走 LoreLoader 读 yaml 池 + 纯随机抽;池为空 / 文件缺失
  /// fallback 到 [UiStrings.continuedLoreObtained] Dart 模板。
  Future<void> recordEquipmentObtained({
    required int? characterId,
    required int equipmentId,
    required String equipmentDefId,
    required String equipmentName,
    required String source,
    Equipment? equipment,
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.equipmentObtained
      ..title = UiStrings.gameEventEquipmentTitle(equipmentName)
      ..summary = UiStrings.gameEventEquipmentSummary(equipmentName, source)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [equipmentDefId, equipmentId.toString()]
      ..occurredAt = DateTime.now()
      ..isRead = false);

    if (equipment != null) {
      final now = DateTime.now();
      final loreText = await _resolveContinuedLore(
        loreId: equipmentDefId,
        isBossDefeated: false,
        vars: {'source': source},
        fallback: UiStrings.continuedLoreObtained(equipmentName, source),
      );
      equipment.lores = [
        ...equipment.lores,
        Lore()
          ..text = loreText
          ..isPreset = false
          ..addedAt = now
          ..triggerEventDesc = 'equipmentObtained:$source',
      ];
      await isar.equipments.put(equipment);
    }
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
    final isDisciple = character.lineageRole.isDiscipleRole;
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
  /// [warbornEquipment] 非空时为每件主战装备同事务追加一段延续典故
  /// (P1 #42 Phase 5 / GDD §6.6)。P1 #44:每件装备各自走 LoreLoader 读
  /// yaml 池 + 纯随机抽;池为空 / 文件缺失 fallback 到
  /// [UiStrings.continuedLoreBossDefeated] Dart 模板。
  Future<void> recordBossDefeated({
    required int characterId,
    required String stageId,
    required String stageName,
    required String bossName,
    List<Equipment> warbornEquipment = const [],
  }) async {
    await isar.gameEvents.put(GameEvent()
      ..eventType = GameEventType.bossDefeated
      ..title = UiStrings.gameEventBossTitle(bossName)
      ..summary = UiStrings.gameEventBossSummary(bossName, stageName)
      ..relatedCharacterId = characterId
      ..relatedEntityIds = [stageId]
      ..occurredAt = DateTime.now()
      ..isRead = false);

    if (warbornEquipment.isNotEmpty) {
      final now = DateTime.now();
      for (final eq in warbornEquipment) {
        final loreText = await _resolveContinuedLore(
          loreId: eq.defId,
          isBossDefeated: true,
          vars: {'boss_name': bossName, 'stage_name': stageName},
          fallback: UiStrings.continuedLoreBossDefeated(bossName, stageName),
        );
        eq.lores = [
          ...eq.lores,
          Lore()
            ..text = loreText
            ..isPreset = false
            ..addedAt = now
            ..triggerEventDesc = 'bossDefeated:$stageId',
        ];
      }
      await isar.equipments.putAll(warbornEquipment);
    }
  }
}

