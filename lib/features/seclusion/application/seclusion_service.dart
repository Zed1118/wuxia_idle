import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/reward_entry.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/utils/rng.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../../core/domain/technique.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/application/synergy_service.dart';
import '../../encounter/application/encounter_service.dart';
import '../../event/application/game_event_service.dart';
import '../../tutorial/application/tutorial_service.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';

/// 闭关产出汇总（Phase 3 T48 / W15 #30 扩 2 维度）。
///
/// 由 [SeclusionService.computeOutputs] 返回，[completeRetreat] 写入 Isar。
typedef RetreatOutputs = ({
  double actualHours,
  int mojianshi,
  List<Equipment> equipmentDrops,
  int experiencePoints,
  int techniqueLearnPoints,
  int internalForcePoints,
});

/// 闭关收功完整结果(W15 #30 第 3 期扩 advancement)。
///
/// 包含 [RetreatOutputs] 所有字段 + 可选 [AdvancementResult]。advancement 非
/// null 表示本次收功触发了升层(`outputs.experiencePoints > 0` 后调用
/// [CharacterAdvancementService.applyExperience] 的结果);为 null 表示无
/// EXP 累加或 EXP 累加但未跨阈值。
typedef RetreatResult = ({
  double actualHours,
  int mojianshi,
  List<Equipment> equipmentDrops,
  int experiencePoints,
  int techniqueLearnPoints,
  int internalForcePoints,
  AdvancementResult? advancement,
});

/// 闭关系统服务（Phase 3 T48 / W15 #30 扩 3 维度）。
///
/// 全静态方法，依赖注入 [RetreatConfig] + [Rng]（测试可 mock）。
/// 与 [TowerProgressService] / [MainlineProgressService] 完全独立：
/// 不互相 import，saveDataId 隔离。
///
/// 关键不变量：
///   - 同一 saveDataId 至多一条 active session；[startRetreat] 开始前
///     先调 [_abandonActive]（内部方法）
///   - [computeOutputs] 纯函数（不写 Isar），由 [completeRetreat] 调用
///   - actualHours = min(elapsed, durationHours, capHours)
///   - 加成均按 `session.startedAt` 时刻判定（不跨日切换 — GDD §7.3）：
///     * solarBonus = 1.30 if startedAt 是节气日 else 1.00（按月日比对，忽略年）
///     * ziShi = 23:00-01:00 → internalForce 维度 ×1.20，其他维度不受影响
///   - mojianshi      = floor(def.mojianshiPerHour      × actualHours × realmScale × solarBonus)
///   - experiencePts  = floor(def.experiencePerHour     × actualHours × realmScale × solarBonus)
///   - techniqueLearn = floor(config.baseTechniqueLearnPerHour × def.techniqueLearnRate
///                            × actualHours × realmScale × solarBonus)
///   - internalForce  = floor(config.baseInternalForcePerHour  × def.internalForceGrowth
///                            × actualHours × realmScale × solarBonus × ziShiBonus)
///   - 装备抽检：per session 单次，概率 = equipmentDropRate × baseEquipDropProbability
///   - 正午阳刚 +20% 未消费 — 依赖 §12 #7 流派 extra_effect 决议，留挂账
class SeclusionService {
  const SeclusionService({required this.isar, this.encounterService});

  final Isar isar;

  /// 奇遇服务(C-W14-2)。null = 不喂 biome/weather 累计(测试 fixture 默认)。
  /// 生产路径 provider 注入,完成闭关后按 `actualHours × 60` 喂分钟。
  final EncounterService? encounterService;

  // ─────────────────────────────────────────────────────────────────────────
  // 公开 API
  // ─────────────────────────────────────────────────────────────────────────

  /// 当前存档是否可以进入指定地图（境界锁）。
  ///
  /// [charRealmTier] 为角色当前大阶。
  ///
  /// 纯函数：不用 Isar,保持 static。
  static bool canEnterMap({
    required RetreatMapType mapType,
    required RealmTier charRealmTier,
    required List<SeclusionMapDef> maps,
  }) {
    final def = _getDef(mapType, maps);
    return charRealmTier.index >= def.requiredRealm.index;
  }

  /// 取当前 active session；无活跃 session 返回 null。
  Future<RetreatSession?> getActiveSession(int saveDataId) async {
    return isar.retreatSessions
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .statusEqualTo(RetreatStatus.active)
        .findFirst();
  }

  /// 开始闭关：
  ///   1. 境界校验（不满足抛 [StateError]）
  ///   2. abandon 旧 active session（若有）
  ///   3. 写新 [RetreatSession] + 更新 [Character.currentRetreatSessionId]
  Future<RetreatSession> startRetreat({
    required RetreatMapType mapType,
    required int durationHours,
    required int saveDataId,
    required int characterId,
    required RealmTier charRealmTier,
    required List<SeclusionMapDef> maps,
    required DateTime now,
  }) async {
    if (!canEnterMap(
      mapType: mapType,
      charRealmTier: charRealmTier,
      maps: maps,
    )) {
      throw StateError(
        '境界不足：${charRealmTier.name} 无法进入 ${mapType.name}（'
        '要求 ${_getDef(mapType, maps).requiredRealm.name}）',
      );
    }

    late RetreatSession created;

    await isar.writeTxn(() async {
      // 1. abandon 旧 active（若有）
      final old = await isar.retreatSessions
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .statusEqualTo(RetreatStatus.active)
          .findFirst();
      if (old != null) {
        old.status = RetreatStatus.abandoned;
        old.completedAt = now;
        await isar.retreatSessions.put(old);
      }

      // 2. 建新 session
      final session = RetreatSession()
        ..saveDataId = saveDataId
        ..mapType = mapType
        ..durationHours = durationHours
        ..startedAt = now
        ..completedAt = null
        ..status = RetreatStatus.active
        ..actualRewards = [];
      final sid = await isar.retreatSessions.put(session);
      session.id = sid;
      created = session;

      // 3. 更新 character.currentRetreatSessionId
      final ch = await isar.characters.get(characterId);
      if (ch != null) {
        ch.currentRetreatSessionId = sid;
        await isar.characters.put(ch);
      }
    });

    return created;
  }

  /// 计算闭关产出（纯函数，不写 Isar）。
  ///
  /// [now] 为当前时刻，[config] 来自 GameRepository.numbers.retreat。
  static RetreatOutputs computeOutputs({
    required RetreatSession session,
    required RealmTier charRealmTier,
    required RetreatConfig config,
    required List<SeclusionMapDef> maps,
    required DateTime now,
    TechniqueSchool? charSchool,
    double synergyInternalForceGrowthPct = 0.0,
    double residueInternalForceMultiplier = 1.0,
    Rng? rng,
  }) {
    final def = _getDef(session.mapType, maps);
    final elapsed = now.difference(session.startedAt).inSeconds / 3600.0;
    final cap = config.capHours.toDouble();
    final planned = session.durationHours.toDouble();
    final actualHours = _clamp(elapsed, 0, _min(planned, cap));

    final scale = config.realmScaleFor(charRealmTier);
    final solarBonus = config.isSolarTermDay(session.startedAt)
        ? config.solarTermMultiplier
        : 1.0;
    final ziShiBonus = _isZiShi(session.startedAt)
        ? config.ziShiInternalForceMultiplier
        : 1.0;
    // CLAUDE.md §12.1 #7 v1.4:正午 + 角色主修 == applies_to_school(gangMeng)
    // 时,internalForcePoints 维度乘 zhengWuYangSchoolMultiplier(1.20)。
    // 非刚猛角色 / 非正午 → 系数 1.0 无加成。
    final zhengWuBonus =
        (_isZhengWu(session.startedAt) &&
            charSchool == config.zhengWuAppliesToSchool)
        ? config.zhengWuYangSchoolMultiplier
        : 1.0;

    final mojianshi = (def.mojianshiPerHour * actualHours * scale * solarBonus)
        .floor()
        .clamp(0, 999999);

    final experiencePoints =
        (def.experiencePerHour * actualHours * scale * solarBonus)
            .floor()
            .clamp(0, 999999);

    final techniqueLearnPoints =
        (config.baseTechniqueLearnPerHour *
                def.techniqueLearnRate *
                actualHours *
                scale *
                solarBonus)
            .floor()
            .clamp(0, 999999);

    // W18-A1.2 心法相生 internalForceGrowthPct 乘进 internalForcePoints
    // (闭关产出维度,与战斗 init internalForceMaxPct 分管;数值红线 ≤ 0.30 + 1.0
    // 基底 → 最大 1.30 倍 clamp 后仍 ≤ 999999)。
    // M6 Task 7: residueInternalForceMultiplier = 0.80（余毒在身）或 1.0（无余毒）
    //   从 GameRepository.numbers.innerDemon.residueDebuff.internalForceRecoveryMultiplier
    //   读取，不硬编码（§5.6 红线）。
    final internalForcePoints =
        (config.baseInternalForcePerHour *
                def.internalForceGrowth *
                actualHours *
                scale *
                solarBonus *
                ziShiBonus *
                zhengWuBonus *
                (1.0 + synergyInternalForceGrowthPct) *
                residueInternalForceMultiplier)
            .floor()
            .clamp(0, 999999);

    // 装备抽检：每 session 单次，概率 = equipmentDropRate × base
    final effectiveRng = rng ?? DefaultRng();
    final equipRoll = effectiveRng.nextDouble();
    final equipProb = def.equipmentDropRate * config.baseEquipDropProbability;
    final equipDrops = <Equipment>[];
    if (equipRoll < equipProb) {
      // Demo 阶段：无独立 seclusion dropTable，概率触发但无 table 时不崩溃
      // Phase 4 补全 dropTable 时替换此路径
    }

    return (
      actualHours: actualHours,
      mojianshi: mojianshi,
      equipmentDrops: equipDrops,
      experiencePoints: experiencePoints,
      techniqueLearnPoints: techniqueLearnPoints,
      internalForcePoints: internalForcePoints,
    );
  }

  /// 收功：
  ///   1. 计算产出
  ///   2. 写 mojianshi 进 InventoryItem
  ///   3. 更新 session：completedAt / status / actualRewards
  ///   4. 清 Character.currentRetreatSessionId
  Future<RetreatResult> completeRetreat({
    required RetreatSession session,
    required int characterId,
    required RealmTier charRealmTier,
    required RetreatConfig config,
    required List<SeclusionMapDef> maps,
    required DateTime now,
    Rng? rng,
  }) async {
    // CLAUDE.md §12.1 #7 v1.4:正午阳刚 +20% 需要角色主修流派 — writeTxn 外
    // 提前读 character.school(后续 writeTxn 内 read 写回 ch 沿原 W15 #30 第 3 期体例),
    // seclusion 完工低频,2 次 read 开销可忽略。
    final preCharForBonus = await isar.characters.get(characterId);

    // W18-A1.2:闭关收功时查 character 的心法相生(主修 + 全部辅修),
    // 命中 internalForceGrowthPct 注入 computeOutputs 内力维度。读 tech 在
    // writeTxn 外(seclusion 完工低频,2-3 次 isar.get 开销可忽略),拿不到
    // character / tech → growthPct 默认 0.0(无相生),整链 fallthrough。
    final synergyGrowthPct = await _detectSynergyGrowthPct(preCharForBonus);

    // M6 Task 7: 余毒乘数（§5.6: 从 config 读，不硬编码）。
    // 口径=按本次闭关「开始时」的余毒开关态：开始有余毒则整次产出 ×0.80，
    // 即便本次闭关时长超过剩余清除小时数（余毒在结束时才累减清除，见下方 ch 改区）。
    // 简化为「开关态」而非逐小时折算，符合 spec D 段拍板，非 off-by-one bug。
    final residueMult =
        (preCharForBonus?.innerDemonResidueHoursRemaining ?? 0) > 0
        ? GameRepository
              .instance
              .numbers
              .innerDemon
              .residueDebuff
              .internalForceRecoveryMultiplier
        : 1.0;

    final outputs = computeOutputs(
      session: session,
      charRealmTier: charRealmTier,
      config: config,
      maps: maps,
      now: now,
      charSchool: preCharForBonus?.school,
      synergyInternalForceGrowthPct: synergyGrowthPct,
      residueInternalForceMultiplier: residueMult,
      rng: rng,
    );

    // W15 #30 第 3 期:applyExperience 返回值,在 writeTxn 内闭包 assign,
    // 跨 writeTxn 暴露给 caller 用于 UI 升层 banner。
    AdvancementResult? advancement;

    await isar.writeTxn(() async {
      // 1. 写 mojianshi → InventoryItem
      // defId 统一为 'item_mojianshi'，与 towers.yaml / stages.yaml drop 体系
      // 及 tower_entry_flow._itemTypeOf 映射对齐，避免同 ItemType 多 defId 分裂。
      if (outputs.mojianshi > 0) {
        await _addInventoryItem(
          isar,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: outputs.mojianshi,
          now: now,
        );
      }

      // 2. 更新 session
      final rewards = <RewardEntry>[];
      if (outputs.mojianshi > 0) {
        rewards.add(
          RewardEntry()
            ..rewardKey = 'item_mojianshi'
            ..quantity = outputs.mojianshi,
        );
      }
      session
        ..completedAt = now
        ..status = RetreatStatus.completed
        ..actualRewards = rewards;
      await isar.retreatSessions.put(session);

      // 3. 写 Character:internalForce(clamp old max) + insightPoints 累加 +
      //    experience 写回 + 升层(W15 #30 第 2 期 + 第 3 期消费层接入),
      //    清 currentRetreatSessionId。
      //
      // applyExperience 后置于 internalForce clamp:升层拉新 internalForceMax 时
      // 不立即填新 cap,玩家走下次闭关自然填(GDD §5.1 反留存焦虑,升层奖励
      // 不"回血")。
      final ch = await isar.characters.get(characterId);
      if (ch != null) {
        if (outputs.internalForcePoints > 0) {
          final next = ch.internalForce + outputs.internalForcePoints;
          ch.internalForce = next > ch.internalForceMax
              ? ch.internalForceMax
              : next;
        }
        if (outputs.techniqueLearnPoints > 0) {
          ch.insightPoints += outputs.techniqueLearnPoints;
        }
        // 根因A(2026-05-29):闭关挂机折算 battleCount 喂出战装备共鸣度
        // (人剑合一离线可推进)。rate × actualHours,加到 3 件出战装备。
        final bcGain =
            (GameRepository
                        .instance
                        .numbers
                        .resonanceSeclusionBattleCountPerHour *
                    outputs.actualHours)
                .floor();
        if (bcGain > 0) {
          for (final eqId in [
            ch.equippedWeaponId,
            ch.equippedArmorId,
            ch.equippedAccessoryId,
          ]) {
            if (eqId == null) continue;
            final eq = await isar.equipments.get(eqId);
            if (eq == null) continue;
            eq.battleCount += bcGain;
            await isar.equipments.put(eq);
          }
        }
        // M6 Task 7: 余毒累减（§5.5 按 actualHours 闭关时长，不依赖真实时间戳）
        if (ch.innerDemonResidueHoursRemaining > 0) {
          final left =
              ch.innerDemonResidueHoursRemaining - outputs.actualHours;
          ch.innerDemonResidueHoursRemaining = left < 0 ? 0 : left;
        }
        if (outputs.experiencePoints > 0) {
          // P2.2 §12.1 心魔关 unlock 拦截 hook(Batch 2.2.B):wuSheng 各 layer
          // 升前查 inner_demon stage cleared 集,未通则 EXP 留账不消费(玩家
          // 挂机攒着,过关后下次闭关一次性消费多 layer)。非 wuSheng tier
          // (Demo + Ch4-6 路径)hook 短路 false,行为同 1.0 前。
          final progress = await isar.mainlineProgress
              .filter()
              .saveDataIdEqualTo(session.saveDataId)
              .findFirst();
          final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
          final innerDemonDef = GameRepository.instance.numbers.innerDemon;
          advancement = CharacterAdvancementService.applyExperience(
            ch,
            outputs.experiencePoints,
            realmLookup: GameRepository.instance.getRealm,
            isLayerLocked: (tier, layer) => InnerDemonService.isLayerLocked(
              nextTier: tier,
              nextLayer: layer,
              innerDemonDef: innerDemonDef,
              clearedStageIds: clearedSet,
            ),
          );
        }
        ch.currentRetreatSessionId = null;
        await isar.characters.put(ch);

        // P1 #42 Phase 2:GameEvent 写入 — 闭关完成 + (升层时)境界突破。
        // 同 writeTxn 内原子,不开嵌套 writeTxn(GameEventService 内部 put 不开)。
        final events = GameEventService(isar);
        final mapDef = _getDef(session.mapType, maps);
        await events.recordRetreatCompleted(
          characterId: characterId,
          characterName: ch.name,
          actualHours: outputs.actualHours.round(),
          mapName: mapDef.mapName,
        );
        if (advancement != null && advancement!.didAdvance) {
          await events.recordRealmBreakthrough(
            character: ch,
            result: advancement!,
          );
          // P1 #42 Phase 2 §10 P1.y:仅主角(founder)达一流 → 推 step 6
          // (GDD §7.1 收徒门槛是开派祖师的事,disciple 升层不算)。
          if (ch.lineageRole == LineageRole.founder) {
            final tutorialSvc = TutorialService(isar);
            await tutorialSvc.advanceForRealmBreakthrough(
              advancement!.tierAfter,
            );
          }
        }
      }
    });

    // C-W14-2 idle tick:writeTxn 外单独喂奇遇 biome/weather 累计。
    // 嵌套 writeTxn 会抛 IsarError,故分开两个 txn。原子性损失可接受:
    // mojianshi 已落地,idle tick 失败仅缺少奇遇累计,不破坏闭关数据。
    await _feedEncounterIdleMinutes(
      session: session,
      saveDataId: session.saveDataId,
      maps: maps,
      actualHours: outputs.actualHours,
    );

    return (
      actualHours: outputs.actualHours,
      mojianshi: outputs.mojianshi,
      equipmentDrops: outputs.equipmentDrops,
      experiencePoints: outputs.experiencePoints,
      techniqueLearnPoints: outputs.techniqueLearnPoints,
      internalForcePoints: outputs.internalForcePoints,
      advancement: advancement,
    );
  }

  /// W18-A1.2 心法相生 internalForceGrowthPct 检测(闭关收功用)。
  ///
  /// 沿 [StageBattleSetup._playerToBattle] 体例,读 character 主修 + 全部辅修
  /// tech → [SynergyService.detectActive] → 提取
  /// `synergy.multipliers.internalForceGrowthPct`(0.0 - 0.30,红线 ≤ 0.30)。
  /// 任一条件缺失返 0.0(无相生):character / mainTechniqueId / mainTech /
  /// assistTech / synergies 全集任一缺。
  Future<double> _detectSynergyGrowthPct(Character? character) async {
    if (character == null) return 0.0;
    final mainId = character.mainTechniqueId;
    if (mainId == null) return 0.0;
    if (character.assistTechniqueIds.isEmpty) return 0.0;
    final mainTech = await isar.techniques.get(mainId);
    if (mainTech == null) return 0.0;
    final ownedTechniques = <Technique>[mainTech];
    for (final assistId in character.assistTechniqueIds) {
      final assistTech = await isar.techniques.get(assistId);
      if (assistTech != null) ownedTechniques.add(assistTech);
    }
    final synergy = SynergyService.detectActive(
      character: character,
      ownedTechniques: ownedTechniques,
      techDefLookup: (defId) => GameRepository.instance.techniqueDefs[defId],
      synergies: GameRepository.instance.synergies,
    );
    return synergy?.multipliers.internalForceGrowthPct ?? 0.0;
  }

  /// 闭关 actualHours 累计喂给 EncounterService(C-W14-2)。
  ///
  /// 异常静默 + debugPrint(W13 教训:catch 加日志,不影响主流程)。
  Future<void> _feedEncounterIdleMinutes({
    required RetreatSession session,
    required int saveDataId,
    required List<SeclusionMapDef> maps,
    required double actualHours,
  }) async {
    final svc = encounterService;
    if (svc == null) return;
    if (actualHours <= 0) return;
    final def = _getDef(session.mapType, maps);
    if (def.biome == null && def.weather == null) return;
    final minutes = (actualHours * 60).floor();
    if (minutes <= 0) return;
    try {
      await svc.getOrCreate(saveDataId: saveDataId);
      await svc.recordIdleMinutes(
        saveDataId: saveDataId,
        biome: def.biome,
        weather: def.weather,
        minutes: minutes,
      );
    } catch (e, st) {
      debugPrint('SeclusionService.idle tick failed: $e\n$st');
    }
  }

  /// 放弃闭关（切换地图 / 主动放弃）：仅更新状态，不发奖。
  Future<void> abandonRetreat({
    required RetreatSession session,
    required int characterId,
    required DateTime now,
  }) async {
    await isar.writeTxn(() async {
      session
        ..completedAt = now
        ..status = RetreatStatus.abandoned;
      await isar.retreatSessions.put(session);

      final ch = await isar.characters.get(characterId);
      if (ch != null) {
        ch.currentRetreatSessionId = null;
        await isar.characters.put(ch);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 内部工具
  // ─────────────────────────────────────────────────────────────────────────

  static SeclusionMapDef _getDef(
    RetreatMapType mapType,
    List<SeclusionMapDef> maps,
  ) => maps.firstWhere(
    (m) => m.mapType == mapType,
    orElse: () => throw StateError('SeclusionMapDef 未找到: ${mapType.name}'),
  );

  /// 是否为子时（23:00-01:00 含）。
  /// W15 #30 修正：原 `_timeDayBonus` 把子时×1.2 当全产出加成是 bug，
  /// yaml 实际定义 `effect: internal_force_growth` 只乘内力维度。
  static bool _isZiShi(DateTime startedAt) {
    final h = startedAt.hour;
    return h == 23 || h == 0;
  }

  /// 是否为正午(11:00-13:00,左闭右开 = h ∈ {11, 12})。
  /// CLAUDE.md §12.1 #7 v1.4:仅刚猛流派角色在正午时段闭关 internalForcePoints 维度 +20%。
  static bool _isZhengWu(DateTime startedAt) {
    final h = startedAt.hour;
    return h == 11 || h == 12;
  }

  static double _min(double a, double b) => a < b ? a : b;

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static Future<void> _addInventoryItem(
    Isar isar, {
    required String defId,
    required ItemType itemType,
    required int quantity,
    required DateTime now,
  }) async {
    final existing = await isar.inventoryItems.getByDefId(defId);
    if (existing != null) {
      existing.quantity += quantity;
      existing.lastObtainedAt = now;
      await isar.inventoryItems.put(existing);
    } else {
      final item = InventoryItem()
        ..defId = defId
        ..itemType = itemType
        ..quantity = quantity
        ..firstObtainedAt = now
        ..lastObtainedAt = now;
      await isar.inventoryItems.put(item);
    }
  }
}
