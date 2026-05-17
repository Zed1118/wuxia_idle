import 'package:isar_community/isar.dart';

import '../../../data/defs/master_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../encounter/domain/encounter_progress.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/game_event.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../shared/utils/rng.dart';
import '../../encounter/application/encounter_service.dart';
import '../../equipment/application/equipment_factory.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../tower/domain/tower_progress.dart';

/// Phase 2 调试场景种子工厂（phase2_tasks.md T32 §492-509 子提交 3）。
///
/// 4 个静态方法 [seedP1] / [seedP2] / [seedP3] / [seedP4] 各对应一个调试场景：
/// 一次 writeTxn 清空业务表（SaveData 不动）+ 写入场景所需的 Character /
/// Equipment / Technique / InventoryItem。
///
/// **物料行 fail-fast 兼容**：每个场景都必创 `InventoryItem(moJianShi)` 与
/// `InventoryItem(xinXueJieJing)` 两行，匹配
/// [EnhancementService.persistResult] 的 fail-fast 约定（行不存在直接抛
/// [StateError]）。即便场景不强化，留两行 0 quantity 也合规。
///
/// **固定 id**：种子角色固定 `id=1`，便于 [CharacterPanelScreen] 与
/// [TechniquePanelScreen] 直接传 `characterId=1`。装备 / 心法 id 由
/// `Isar.autoIncrement` 决定（clear 后从 1 起）。
class Phase2SeedService {
  const Phase2SeedService({required this.isar});

  final Isar isar;

  /// 场景 P1：强化曲线（玩家手动连点 +0 → +19 看成功率分布）。
  ///
  /// - 1 个二流·圆熟角色（absoluteLevel=19，cap +19 与 spec 对齐）
  /// - 1 件 +0 利器武器，已装备在角色身上
  /// - 1000 磨剑石 / 100 心血结晶（足够走完 +19 曲线）
  Future<void> seedP1() async {
    final isar = this.isar;

    await isar.writeTxn(() async {
      await _clearAll();

      final eq = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 0);
      await isar.equipments.put(eq);

      final ch = _buildCharacter(internalForce: 1500, internalForceMax: 2200)
        ..equippedWeaponId = eq.id;
      await isar.characters.put(ch);

      eq.ownerCharacterId = ch.id;
      await isar.equipments.put(eq);

      await _seedMaterials( mojianshi: 1000, jieJing: 100);
    });
  }

  /// 场景 P2：共鸣触发（一件 battleCount=99 装备，再战一回合 →100 触发"趁手"）。
  ///
  /// 子提交 3 不直接接战斗（character_to_battle 转换 helper 留 Phase 3），
  /// 种子写完后 UI 跳 InventoryScreen 让玩家观察 battleCount=99 的装备；
  /// 共鸣 99→100 的数值正确性走子提交 4 phase2_scenarios_test 纯单测覆盖。
  Future<void> seedP2() async {
    final isar = this.isar;

    await isar.writeTxn(() async {
      await _clearAll();

      final eq = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 99);
      await isar.equipments.put(eq);

      final ch = _buildCharacter(internalForce: 1500, internalForceMax: 2200)
        ..equippedWeaponId = eq.id;
      await isar.characters.put(ch);

      eq.ownerCharacterId = ch.id;
      await isar.equipments.put(eq);

      await _seedMaterials( mojianshi: 2000, jieJing: 200);
    });
  }

  /// 场景 P3：散功代价（主修 yuanMan/1500 progress + IF 10000 → daCheng/750 + IF 5000）。
  ///
  /// 算法对照 [DispelService._recalcLayerByRollback] 文档示例：
  ///   - disperse: progress 1500 × 0.5 = 750
  ///   - rollback: prevReq(daCheng→yuanMan)=900；750<900 → 回退 daCheng/750
  ///   - 停：prevReq(zhongCheng→daCheng)=500；750≥500
  /// 与 spec §502 完全一致。
  ///
  /// - 1 角色 internalForce=10000 / internalForceMax=10000
  /// - 主修：刚猛/名家功 cultivationLayer=yuanMan / progress=1500
  /// - 辅修：阴柔/名家功 cultivationLayer=daCheng（供玩家在面板上点"设为主修"）
  Future<void> seedP3() async {
    final isar = this.isar;
    final numbers = GameRepository.instance.numbers;

    await isar.writeTxn(() async {
      await _clearAll();

      final main = _buildTechnique(
        defId: 'tech_gangmeng_mingjia',
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        cultivationLayer: CultivationLayer.yuanMan,
        cultivationProgress: 1500,
        cultivationProgressToNext:
            numbers.cultivationProgressToNext[CultivationLayer.yuanMan]!,
      );
      final assist = _buildTechnique(
        defId: 'tech_yinrou_mingjia',
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.yinRou,
        role: TechniqueRole.assist,
        cultivationLayer: CultivationLayer.daCheng,
        cultivationProgress: 0,
        cultivationProgressToNext:
            numbers.cultivationProgressToNext[CultivationLayer.daCheng]!,
      );
      await isar.techniques.putAll([main, assist]);

      final ch = _buildCharacter(
        internalForce: 10000,
        internalForceMax: 10000,
        school: TechniqueSchool.gangMeng,
      );
      ch.mainTechniqueId = main.id;
      ch.assistTechniqueIds = [assist.id];
      await isar.characters.put(ch);

      main.ownerCharacterId = ch.id;
      assist.ownerCharacterId = ch.id;
      await isar.techniques.putAll([main, assist]);

      await _seedMaterials( mojianshi: 2000, jieJing: 200);
    });
  }

  /// 场景 P4：全栈对比（+0 利器待玩家强化到 +19 + battleCount=2000 默契满）。
  ///
  /// 玩家在 InventoryScreen 操作：选 +0 装备强化到 +19 + 开锋 1/2/3，对比同
  /// defId 的裸装。battleCount=2000 预置在主装备上，进战斗时（子提交 4
  /// 单测覆盖）默契阶段加成自动生效。
  ///
  /// - 1 角色二流·圆熟
  /// - 装备 A：+0 利器武器 battleCount=2000（已装备在角色身上）
  /// - 装备 B：+0 利器武器 battleCount=0（裸装对照，未装备）
  /// - 2000 磨剑石 / 200 心血结晶（强化到 +19 足够 + 余裕）
  Future<void> seedP4() async {
    final isar = this.isar;

    await isar.writeTxn(() async {
      await _clearAll();

      final eqMain = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 2000);
      final eqRef = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 0);
      await isar.equipments.putAll([eqMain, eqRef]);

      final ch = _buildCharacter(internalForce: 1500, internalForceMax: 2200)
        ..equippedWeaponId = eqMain.id;
      await isar.characters.put(ch);

      eqMain.ownerCharacterId = ch.id;
      // eqRef 留在背包（ownerCharacterId=null）
      await isar.equipments.put(eqMain);

      await _seedMaterials( mojianshi: 2000, jieJing: 200);
    });
  }

  /// 场景 P5：师徒系统种子（Phase 3 Week 4 T54）。
  ///
  /// Demo §7.1 师徒传承：3 角色（祖师 + 大弟子 + 二弟子）依 `data/masters.yaml`
  /// 定义初始化，全部入 [SaveData.activeCharacterIds] 默认入阵 → P5 后可直接
  /// 进主线/爬塔/闭关战斗（清挂账 #25：P1 缺主修不能直接打）。
  ///
  /// 决策依据：`docs/handoff/week4_d_minimal_spec_2026-05-13.md` 方案 A。
  /// 祖师=玩家本人由 `MasterDef.lineageRole=founder` + `Character.isFounder=true`
  /// 体现；不另建独立 founder NPC。
  ///
  /// 与 P1-P4 一致：每次 `_clearAll` 重新写入（不做幂等），可反复点 P5 reseed。
  /// SaveData 主体不动，仅写入 `activeCharacterIds` / `founderCharacterId`。
  Future<void> seedMasterDisciple() async {
    final isar = this.isar;
    final repo = GameRepository.instance;
    final masters = repo.masters;
    final rng = DefaultRng();
    final now = DateTime.now();

    await isar.writeTxn(() async {
      await _clearAll();

      // 1. 创建 3 角色，祖师固定 id=1（与既有 main_menu / character_panel 对齐）。
      //    大弟子 / 二弟子由 Isar autoIncrement → id=2 / id=3。
      final founder = _buildMasterCharacter(masters[0], now: now)..id = 1;
      await isar.characters.put(founder);
      final firstDisciple = _buildMasterCharacter(masters[1], now: now);
      await isar.characters.put(firstDisciple);
      final secondDisciple = _buildMasterCharacter(masters[2], now: now);
      await isar.characters.put(secondDisciple);

      // 2. 师徒关系（双向）。
      founder.discipleIds = [firstDisciple.id, secondDisciple.id];
      firstDisciple.masterId = founder.id;
      secondDisciple.masterId = founder.id;

      // 3. 按 slot 顺序装备 + 学心法。
      //    顺序：先装备/学心法（会写回 character 的 equippedXxxId / mainTechniqueId 字段），
      //    最后 putAll 一次性把 character 改动持久化。
      final pairs = [
        (masters[0], founder),
        (masters[1], firstDisciple),
        (masters[2], secondDisciple),
      ];
      for (final pair in pairs) {
        await _equipMasterStarting(
          isar,
          character: pair.$2,
          defIds: pair.$1.startingEquipmentIds,
          rng: rng,
          now: now,
        );
        await _learnMasterStarting(
          isar,
          character: pair.$2,
          techDefIds: pair.$1.startingTechniqueIds,
          now: now,
        );
      }
      await isar.characters.putAll([founder, firstDisciple, secondDisciple]);

      // 4. SaveData.activeCharacterIds 默认入阵 3 师徒（清挂账 #25 P1 缺主修）。
      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.activeCharacterIds = [
          founder.id,
          firstDisciple.id,
          secondDisciple.id,
        ];
        save.founderCharacterId = founder.id;
        save.sectName ??= '我的门派';
        await isar.saveDatas.put(save);
      }

      // 5. 基础物料（让玩家进 P5 后可立即试强化）。
      await _seedMaterials( mojianshi: 2000, jieJing: 200);
    });
  }

  /// W7-W11 视觉验收专用 seed（W12 fix:Codex 视觉验收前置预设）。
  ///
  /// 在 [seedMasterDisciple] 基础上额外 mark Ch1 01-04 通关:
  /// - **场景 D / E（W11）**:`stage_01_01` 可重打验 victory 副作用,
  ///   `stage_01_05` 可挑战验 drop 入背包
  /// - **场景 G（W10）**:`stage_01_05` 章末大 Boss 可直接挑战,
  ///   无需先真通 Ch1 01-04 节省 5-7 分钟
  /// - 不动装备/心法（沿用 [seedMasterDisciple]）
  ///
  /// stage_01_05 平衡 drift(W7-W8 后 P5 实力可边缘胜)挂账 #33,
  /// **派单时若仍胜出**改用「stage_01_05 不点大招」让玩家方负伤更多。
  Future<void> seedVisualCheckW7W11() async {
    // 1. 跑师徒种子（装备 / 心法 / activeCharacterIds 全套）
    await seedMasterDisciple();

    // 2. mark Ch1 01-04 cleared 让 stage_01_05 可挑战
    final svc = MainlineProgressService(isar: isar);
    await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    final now = DateTime.now();
    for (final stageId in const [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
    ]) {
      await svc.recordVictory(stageId: stageId, now: now);
    }
  }

  /// W14-3 视觉验收专用 seed(下批 Codex 完整 EncounterSkillSection 验收用)。
  ///
  /// 在 [seedVisualCheckW7W11] 基础上预 unlock 7 个 encounter skill(tier 1-7 各
  /// 1 个,取该 tier 在 [GameRepository.allEncounterSkills] 中首个 id),并把
  /// 大弟子(id=2,境界 erLiu / tier index 2)预装备一个 tier 3 skill。Codex
  /// 跑 EncounterSkillSection 时可观察:
  ///   - 大弟子 slot 填充态(已装备 + 卸下按钮)
  ///   - bottom sheet 中 tier 4-7 显示 lock icon disabled
  ///   - 切换师徒 3 人(yiLiu / erLiu / sanLiu)看不同 lock 行为
  ///
  /// 不修改师徒境界 — 沿用 `data/masters.yaml` defaultRealm 天然分层
  /// (祖师 yiLiu 可装 ≤4 / 大弟子 erLiu ≤3 / 二弟子 sanLiu ≤2)。
  ///
  /// EncounterProgress 走 [EncounterService.getOrCreate] 拿单行(沿 W14-1 体例,
  /// 与战斗 hook / idle tick / applyOutcome 共享同行)。其内含 writeTxn,与外层
  /// 修改字段 txn 分离(W14-2 嵌套 writeTxn 教训)。
  Future<void> seedVisualCheckW14_3() async {
    await seedVisualCheckW7W11();

    final repo = GameRepository.instance;
    final byTier = <int, List<String>>{};
    for (final s in repo.allEncounterSkills) {
      final t = s.tier;
      if (t == null) continue;
      byTier.putIfAbsent(t, () => []).add(s.id);
    }

    final unlocked = <String>[
      for (var t = 1; t <= 7; t++)
        if (byTier[t]?.isNotEmpty ?? false) byTier[t]!.first,
    ];
    final equippedSkillId =
        (byTier[3]?.isNotEmpty ?? false) ? byTier[3]!.first : null;

    final encounterService = EncounterService(isar: isar);
    final progress = await encounterService.getOrCreate(
      saveDataId: IsarSetup.currentSlotId,
    );

    await isar.writeTxn(() async {
      progress.unlockedSkillIds = unlocked;
      await isar.encounterProgress.put(progress);

      if (equippedSkillId != null) {
        // 大弟子 id=2(seedMasterDisciple: founder=1 / 大弟子 autoInc=2 / 二弟子=3)
        final disciple = await isar.characters.get(2);
        if (disciple != null) {
          disciple.equippedEncounterSkillId = equippedSkillId;
          await isar.characters.put(disciple);
        }
      }
    });
  }

  /// W15-r2 装备详情屏 round2 验收专用 seed。
  ///
  /// 在 [seedVisualCheckW7W11] 基础上额外入 6 件 tier 5-7 装备到背包(祖师
  /// `ownerCharacterId=1` 但不入 equippedXxxId 槽位 — 境界一流锁死)。
  /// Codex round2 可观察:
  ///   - 重器/宝物/神物 3 段 lore 完整排版(超 round1 已验的 1-2 段)
  ///   - 装备详情屏 → 实际强化 +1 动画(P5 已含 2000 墨剑石 / 200 心血结晶)
  ///   - 共鸣度阶段切换 / 师承遗物 chip(若 def 标 isLineageHeritage)
  ///
  /// 6 件覆盖 weapon/armor/accessory 三 slot × tier 5/6/7 各 2 件:
  ///   - 重器(tier 5):青虚剑 / 银鳞甲
  ///   - 宝物(tier 6):长虹剑 / 金丝甲
  ///   - 神物(tier 7):天问剑 / 昆仑佩
  ///
  /// 装备 ownerCharacterId=1(祖师持有)但**不入 equippedXxxId** — 境界锁死纪律
  /// (GDD §5.3 一流 ≤ tier 4)。InventoryScreen `allEquipments` 不按 owner
  /// 过滤,这 6 件会以背包态显示在 ExpansionTile tier 5-7 分组。
  Future<void> seedVisualCheckW15R2() async {
    await seedVisualCheckW7W11();

    final repo = GameRepository.instance;
    final rng = DefaultRng();
    final now = DateTime.now();

    const tier57DefIds = <String>[
      'weapon_zhongqi_qing_xu_jian',
      'armor_zhongqi_yin_lin_jia',
      'weapon_baowu_chang_hong_jian',
      'armor_baowu_jin_si_jia',
      'weapon_shenwu_tian_wen_jian',
      'accessory_shenwu_kun_lun_pei',
    ];

    await isar.writeTxn(() async {
      for (final id in tier57DefIds) {
        final def = repo.getEquipment(id);
        final eq = EquipmentFactory.fromDef(
          def,
          rng: rng,
          obtainedAt: now,
          obtainedFrom: 'visual_check_w15_r2',
          ownerCharacterId: 1,
        );
        await isar.equipments.put(eq);
      }
    });
  }

  /// W15 下波 共鸣度 / 多次强化 / 开锋槽 build 视觉验收 seed
  /// (round2 closeout §8 留挂账)。
  ///
  /// 在 [seedVisualCheckW7W11] 基础上额外入 6 件武器到背包,各件预设不同的
  /// `battleCount` / `enhanceLevel` / `forgingSlots` 配置,让 Codex 一次性
  /// 看完三个维度的"段位光谱"。装备 `ownerCharacterId=1`(祖师持有)但**不入
  /// equippedXxxId**(避免境界锁死与默认槽位冲突,W15-r2 体例延续)。
  ///
  /// 6 件覆盖矩阵(全部选与 P5 师徒 starting_equipment **不重复** 的 defId,
  /// 避免 Codex 视觉验收背包内同 def 重复展示):
  ///
  /// | # | defId                              | tier | battleCount | enhance | 开锋槽 | 共鸣段     | 师承遗物 |
  /// |---|------------------------------------|------|-------------|---------|--------|------------|----------|
  /// | 1 | weapon_xunchang_tie_jian           | 1    | 0           | 0       | 0      | 生疏       | 否       |
  /// | 2 | weapon_xiangyang_chang_jian        | 2    | 200         | 5       | 0      | 趁手 +10%  | 否       |
  /// | 3 | weapon_haojiahuo_xuan_hua_fu       | 3    | 800         | 10      | 1      | 默契 +20%  | 否       |
  /// | 4 | weapon_liqi_pan_long_dao           | 4    | 2500        | 15      | 2      | 心剑通灵    | **强制** |
  /// | 5 | weapon_zhongqi_qing_xu_jian        | 5    | 1500        | 19      | 3      | 默契       | 否       |
  /// | 6 | weapon_shenwu_tian_wen_jian        | 7    | 5000        | 0       | 0      | 心剑通灵    | 否       |
  ///
  /// 开锋配置(numbers.yaml `equipment.forging.slots` 锚定):
  ///   - slot1 unlocked at +10:`attack` +15(numbers.yaml `bonus_value.attack`)
  ///   - slot2 unlocked at +15:`speed` +20(`bonus_value.speed`,与 slot1 不同 type
  ///     符合 "不能与开锋一相同" 约束)
  ///   - slot3 unlocked at +19:`specialSkill` bonusValue=1(`specialSkillId` 不填,
  ///     UI 仅显槽位 unlocked + type chip)
  ///
  /// 师承遗物:`weapon_liqi_pan_long_dao` def **不**自带 `isLineageHeritage`
  /// (def 自带的两件 `weapon_liqi_long_quan` / `armor_haojiahuo_jin_pao` 已被
  /// P5 师徒装上),fixture 通过 `EquipmentFactory.fromDef(... isLineageHeritage:
  /// true)` 强制标(W4 T55 留的 override 通道)。Codex 应看到「师承遗物」chip。
  Future<void> seedVisualCheckW15Resonance() async {
    await seedVisualCheckW7W11();

    final repo = GameRepository.instance;
    final rng = DefaultRng();
    final now = DateTime.now();

    const specs = <_ResonanceSpec>[
      _ResonanceSpec('weapon_xunchang_tie_jian', 0, 0, 0),
      _ResonanceSpec('weapon_xiangyang_chang_jian', 200, 5, 0),
      _ResonanceSpec('weapon_haojiahuo_xuan_hua_fu', 800, 10, 1),
      _ResonanceSpec(
        'weapon_liqi_pan_long_dao',
        2500,
        15,
        2,
        forceLineageHeritage: true,
      ),
      _ResonanceSpec('weapon_zhongqi_qing_xu_jian', 1500, 19, 3),
      _ResonanceSpec('weapon_shenwu_tian_wen_jian', 5000, 0, 0),
    ];

    await isar.writeTxn(() async {
      for (final spec in specs) {
        final def = repo.getEquipment(spec.defId);
        final eq = EquipmentFactory.fromDef(
          def,
          rng: rng,
          obtainedAt: now,
          obtainedFrom: 'visual_check_w15_resonance',
          ownerCharacterId: 1,
          isLineageHeritage: spec.forceLineageHeritage,
        );
        eq.battleCount = spec.battleCount;
        eq.enhanceLevel = spec.enhanceLevel;
        for (var i = 0; i < spec.forgedSlots; i++) {
          final slot = eq.forgingSlots[i];
          slot.unlocked = true;
          switch (slot.slotIndex) {
            case 1:
              slot.type = ForgingSlotType.attack;
              slot.bonusValue = 15;
            case 2:
              slot.type = ForgingSlotType.speed;
              slot.bonusValue = 20;
            case 3:
              slot.type = ForgingSlotType.specialSkill;
              slot.bonusValue = 1;
          }
        }
        await isar.equipments.put(eq);
      }
    });
  }

  /// W15 P3 后续 F2 视觉验收专用 seed(Codex E 二轮派单的升层 banner 取景):
  /// 3 active 角色全员 [RealmTier.xueTu]·[RealmLayer.qiMeng] + experience=0,
  /// 主线 / 塔 / 奇遇进度全清。配合 stage_01_01 / 塔 floor1 通关后,
  /// `CharacterAdvancementService.applyExperience` 用 yaml 配置
  /// (xueTu.qiMeng experience_to_next=50)触发升层 banner。
  ///
  /// **3 角色各学 1 个 tier 0 入门功**(`tech_gangmeng_jichu` / `tech_lingqiao_jichu` /
  /// `tech_yinrou_jichu`),设 mainTechniqueId + character.school 满足
  /// `StageBattleSetup` / `BattleCharacter.fromCharacter` 主修非空硬约束。
  /// 不装备装备(GDD §5.3 三系锁死,学徒只能装备 tier 0 寻常货,本批 fixture
  /// 故意 0 装备避免漂移)。物料给 100 磨剑石 + 10 心血结晶,够 victory drop
  /// 累积观察。SaveData.activeCharacterIds / founderCharacterId 沿
  /// [seedMasterDisciple] 体例。
  ///
  /// 流派分布:祖师 gangMeng / 大弟子 lingQiao / 二弟子 yinRou — 顺手覆盖
  /// 正午阳刚(只祖师享受 +20%)+ 战斗中 1/3 概率触发刚猛震伤 / 阴柔内伤
  /// 等本批新落地 §12.1 #7 v1.4 数值的真实命中场景。
  Future<void> seedVisualCheckW15Fresh() async {
    final isar = this.isar;
    final now = DateTime.now();
    final realmDef = GameRepository.instance.getRealm(
      RealmTier.xueTu,
      RealmLayer.qiMeng,
    );

    await isar.writeTxn(() async {
      await _clearAll();
      await isar.mainlineProgress.clear();
      await isar.towerProgress.clear();
      await isar.encounterProgress.clear();

      Character buildFresh({required String name, required bool isFounder}) {
        return Character.create(
          name: name,
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes()
            ..constitution = 6
            ..enlightenment = 6
            ..agility = 6
            ..fortune = 6,
          rarity: RarityTier.biaoZhun,
          lineageRole:
              isFounder ? LineageRole.founder : LineageRole.disciple,
          createdAt: now,
          internalForce: realmDef.internalForceMax,
          internalForceMax: realmDef.internalForceMax,
          experience: 0,
          experienceToNextLayer: realmDef.experienceToNext,
          isActive: true,
          isFounder: isFounder,
        );
      }

      final founder = buildFresh(name: '祖师', isFounder: true)..id = 1;
      await isar.characters.put(founder);
      final firstDisciple = buildFresh(name: '大弟子', isFounder: false);
      await isar.characters.put(firstDisciple);
      final secondDisciple = buildFresh(name: '二弟子', isFounder: false);
      await isar.characters.put(secondDisciple);

      founder.discipleIds = [firstDisciple.id, secondDisciple.id];
      firstDisciple.masterId = founder.id;
      secondDisciple.masterId = founder.id;

      // 3 角色各学 1 tier 0 入门功(round2 修:StageBattleSetup 强制主修非空)。
      // 沿 _learnMasterStarting 体例:首项 main + 写 mainTechniqueId + school。
      await _learnMasterStarting(
        isar,
        character: founder,
        techDefIds: const ['tech_gangmeng_jichu'],
        now: now,
      );
      await _learnMasterStarting(
        isar,
        character: firstDisciple,
        techDefIds: const ['tech_lingqiao_jichu'],
        now: now,
      );
      await _learnMasterStarting(
        isar,
        character: secondDisciple,
        techDefIds: const ['tech_yinrou_jichu'],
        now: now,
      );

      await isar.characters.putAll([founder, firstDisciple, secondDisciple]);

      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.activeCharacterIds = [
          founder.id,
          firstDisciple.id,
          secondDisciple.id,
        ];
        save.founderCharacterId = founder.id;
        save.sectName ??= '我的门派';
        await isar.saveDatas.put(save);
      }

      await _seedMaterials(mojianshi: 100, jieJing: 10);
    });
  }

  /// W18-A1 心法相生视觉验收专用 seed(本批 Codex Pen 验收 5 组合各 1 命中)。
  ///
  /// 在 `_clearAll` + 三 progress clear 基础上写 5 角色,每角色 main + assist
  /// tech 配对触发恰好 1 个相生组合,5 角色合起来覆盖
  /// [GameRepository.synergies] 5 个 id 全集(red-line: 集合相等,见
  /// `phase2_seed_service_test.dart` W18-A1 段)。
  ///
  /// | # | 角色      | main tech              | assist tech            | 命中优先级               |
  /// |---|-----------|------------------------|------------------------|---------------------------|
  /// | 1 | A·阴阳    | tech_gangmeng_mingjia  | tech_yinrou_mingjia    | schoolPair(组合 1)       |
  /// | 2 | B·刚柔    | tech_gangmeng_mingjia  | tech_lingqiao_mingjia  | schoolPair(组合 2)       |
  /// | 3 | C·阴影    | tech_yinrou_mingjia    | tech_lingqiao_mingjia  | schoolPair(组合 3)       |
  /// | 4 | D·同流派  | tech_yinrou_mingjia    | tech_yinrou_changlian  | sameSchool(组合 4)       |
  /// | 5 | E·同辈    | tech_lingqiao_mingjia  | tech_yinrou_mingjia    | sameTier(组合 5)         |
  ///
  /// 5 角色全 yiLiu·qiMeng(equipment cap=liQi / technique cap=menPaiJueXue,
  /// mingJiaGong + changLianGong 全在三系锁死 GDD §5.3 安全区)+
  /// activeCharacterIds 全塞,CharacterPanelScreen TabBar 显 5 个角色供 Codex
  /// 切 5 Tab 拿 5 张 chip 截图(`lineageTabLabels` 扩 3→5 配套)。
  ///
  /// 战斗注入观测点([StageBattleSetup.applySynergy] 4 字段实装):
  ///   - A·阴阳 hpPct 0.20 → HpBar maxHp 数字 vs 基线 P5(同境界)
  ///   - B·刚柔 speedPct 0.25 → 出手节奏(speed 不显数字)
  ///   - C·阴影 attackPct 0.15 + speedPct 0.15 → DamagePopup 数值
  ///   - D·同流派 attackPct 0.20 → DamagePopup 数值
  ///   - E·同辈 internalForceMaxPct 0.25 → 内力条 max 数字
  ///
  /// 优先级避坑:E·同辈 main=lingQiao + assist=yinRou(顺序与组合 3 main=yinRou+
  /// assist=lingQiao 反),不撞 schoolPair → 走 sameTier;D·同流派 main + assist
  /// 同 school(yinRou)→ 走 sameSchool(优先级先于 sameTier,即便 tier 不等
  /// changLianGong vs mingJiaGong)。
  ///
  /// mark Ch1 01-04 cleared(沿 [seedVisualCheckW7W11]),Codex 可直挑
  /// stage_01_05 拿战斗注入截图。物料 100 磨剑石 + 10 心血结晶(沿
  /// [seedVisualCheckW15Fresh])。
  Future<void> seedVisualCheckW18A1() async {
    final isar = this.isar;
    final now = DateTime.now();
    final realmDef = GameRepository.instance.getRealm(
      RealmTier.yiLiu,
      RealmLayer.qiMeng,
    );

    await isar.writeTxn(() async {
      await _clearAll();
      await isar.mainlineProgress.clear();
      await isar.towerProgress.clear();
      await isar.encounterProgress.clear();

      Character buildA1({required String name, required bool isFounder}) {
        return Character.create(
          name: name,
          realmTier: RealmTier.yiLiu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes()
            ..constitution = 6
            ..enlightenment = 6
            ..agility = 6
            ..fortune = 6,
          rarity: RarityTier.biaoZhun,
          lineageRole:
              isFounder ? LineageRole.founder : LineageRole.disciple,
          createdAt: now,
          internalForce: realmDef.internalForceMax,
          internalForceMax: realmDef.internalForceMax,
          experience: 0,
          experienceToNextLayer: realmDef.experienceToNext,
          isActive: true,
          isFounder: isFounder,
        );
      }

      // 5 角色:祖师 = A·阴阳(占 id=1 与既有体例一致),其余 4 弟子。
      final chA = buildA1(name: 'A·阴阳', isFounder: true)..id = 1;
      await isar.characters.put(chA);
      final chB = buildA1(name: 'B·刚柔', isFounder: false);
      await isar.characters.put(chB);
      final chC = buildA1(name: 'C·阴影', isFounder: false);
      await isar.characters.put(chC);
      final chD = buildA1(name: 'D·同流派', isFounder: false);
      await isar.characters.put(chD);
      final chE = buildA1(name: 'E·同辈', isFounder: false);
      await isar.characters.put(chE);

      // 师徒关系:祖师 A 名下 4 弟子(沿 seedMasterDisciple 双向写法)。
      chA.discipleIds = [chB.id, chC.id, chD.id, chE.id];
      chB.masterId = chA.id;
      chC.masterId = chA.id;
      chD.masterId = chA.id;
      chE.masterId = chA.id;

      // 5 角色 main+assist tech 配对(W18-A1 心法相生 5 组合各 1 命中)。
      final pairs = <(Character, List<String>)>[
        (chA, const ['tech_gangmeng_mingjia', 'tech_yinrou_mingjia']),
        (chB, const ['tech_gangmeng_mingjia', 'tech_lingqiao_mingjia']),
        (chC, const ['tech_yinrou_mingjia', 'tech_lingqiao_mingjia']),
        (chD, const ['tech_yinrou_mingjia', 'tech_yinrou_changlian']),
        (chE, const ['tech_lingqiao_mingjia', 'tech_yinrou_mingjia']),
      ];
      for (final pair in pairs) {
        await _learnMasterStarting(
          isar,
          character: pair.$1,
          techDefIds: pair.$2,
          now: now,
        );
      }

      await isar.characters.putAll([chA, chB, chC, chD, chE]);

      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.activeCharacterIds = [
          chA.id,
          chB.id,
          chC.id,
          chD.id,
          chE.id,
        ];
        save.founderCharacterId = chA.id;
        save.sectName ??= '我的门派';
        await isar.saveDatas.put(save);
      }

      await _seedMaterials(mojianshi: 100, jieJing: 10);
    });

    // mark Ch1 01-04 cleared(沿 seedVisualCheckW7W11),让 Codex 直挑
    // stage_01_05 拿战斗注入截图。MainlineProgressService 自带 writeTxn,
    // 需在外层 writeTxn 之外调用。
    final svc = MainlineProgressService(isar: isar);
    await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    final cleared = DateTime.now();
    for (final stageId in const [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
    ]) {
      await svc.recordVictory(stageId: stageId, now: cleared);
    }
  }

  // ── private helpers ────────────────────────────────────────────────────────

  /// 清空业务 collection（保留 SaveData）。装备 / 心法 / 角色 / 物品 / 事件全清。
  Future<void> _clearAll() async {
    await isar.characters.clear();
    await isar.equipments.clear();
    await isar.techniques.clear();
    await isar.inventoryItems.clear();
    await isar.gameEvents.clear();
  }

  Future<void> _seedMaterials({
    required int mojianshi,
    required int jieJing,
  }) async {
    final now = DateTime.now();
    // defId 统一为 item_* 体系（与 towers.yaml / stages.yaml drop + tower_entry_flow
    // 映射对齐），避免同 ItemType 多 defId 行分裂。
    final moj = InventoryItem()
      ..defId = 'item_mojianshi'
      ..itemType = ItemType.moJianShi
      ..quantity = mojianshi
      ..firstObtainedAt = now
      ..lastObtainedAt = now;
    final jie = InventoryItem()
      ..defId = 'item_xinxuejiejing'
      ..itemType = ItemType.xinXueJieJing
      ..quantity = jieJing
      ..firstObtainedAt = now
      ..lastObtainedAt = now;
    await isar.inventoryItems.putAll([moj, jie]);
  }

  /// 二流·圆熟角色模板（absoluteLevel=19，强化 cap +19 与 spec 对齐）。
  /// 出生时间 / 师徒关系 / 稀有度均用占位值，仅供调试场景演示。
  static Character _buildCharacter({
    required int internalForce,
    required int internalForceMax,
    TechniqueSchool? school,
  }) {
    final now = DateTime.now();
    return Character.create(
      name: '测试角色',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.yuanShu,
      attributes: Attributes()
        ..constitution = 6
        ..enlightenment = 6
        ..agility = 6
        ..fortune = 6,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: now,
      internalForce: internalForce,
      internalForceMax: internalForceMax,
      school: school,
      isActive: true,
      isFounder: true,
    )..id = 1;
  }

  /// 利器·龙泉剑 +0 / +N 的快捷构造（spec §501 默认武器选 yaml `weapon_liqi_long_quan`）。
  static Equipment _buildLiQiWeapon({
    required int enhanceLevel,
    required int battleCount,
  }) {
    final now = DateTime.now();
    final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
    return Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: now,
      obtainedFrom: 'phase2_seed',
      baseAttack: def.baseAttackMin,
      baseHealth: def.baseHealthMin,
      baseSpeed: def.baseSpeedMin,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
    );
  }

  static Technique _buildTechnique({
    required String defId,
    required TechniqueTier tier,
    required TechniqueSchool school,
    required TechniqueRole role,
    required CultivationLayer cultivationLayer,
    required int cultivationProgress,
    required int cultivationProgressToNext,
  }) {
    final now = DateTime.now();
    return Technique.create(
      defId: defId,
      ownerCharacterId: 1,
      tier: tier,
      school: school,
      role: role,
      learnedAt: now,
      cultivationLayer: cultivationLayer,
      cultivationProgress: cultivationProgress,
      cultivationProgressToNext: cultivationProgressToNext,
    );
  }

  // ── seedMasterDisciple helpers (Phase 3 Week 4 T54) ────────────────────────

  /// 按 [MasterDef] 构造 Character（slotIndex 决定占位名，T56 接 DeepSeek 文案后替换）。
  ///
  /// `internalForce` 满血默认（境界对应 [RealmDef.internalForceMax]）。
  static Character _buildMasterCharacter(
    MasterDef def, {
    required DateTime now,
  }) {
    final realmDef = GameRepository.instance.getRealm(
      def.defaultRealm,
      def.defaultLayer,
    );
    return Character.create(
      name: _defaultMasterName(def),
      realmTier: def.defaultRealm,
      realmLayer: def.defaultLayer,
      attributes: Attributes()
        ..constitution = def.attributeProfile.constitution
        ..enlightenment = def.attributeProfile.enlightenment
        ..agility = def.attributeProfile.agility
        ..fortune = def.attributeProfile.fortune,
      rarity: RarityTier.biaoZhun,
      lineageRole: def.lineageRole,
      isFounder: def.lineageRole == LineageRole.founder,
      createdAt: now,
      internalForce: realmDef.internalForceMax,
      internalForceMax: realmDef.internalForceMax,
      experienceToNextLayer: realmDef.experienceToNext,
      isActive: true,
    );
  }

  static String _defaultMasterName(MasterDef def) {
    switch (def.slotIndex) {
      case 0:
        return '祖师';
      case 1:
        return '大弟子';
      case 2:
        return '二弟子';
      default:
        return '师徒_${def.id}';
    }
  }

  /// 按 [defIds] 顺序生成装备实例并装在 [character] 对应槽位上。
  ///
  /// 通过 [EquipmentFactory.fromDef] 走标准 roll 路径（与 DropService 一致），
  /// 自动设 `ownerCharacterId`。同 slot 多件覆盖（后写入的胜出）。
  static Future<void> _equipMasterStarting(
    Isar isar, {
    required Character character,
    required List<String> defIds,
    required Rng rng,
    required DateTime now,
  }) async {
    final repo = GameRepository.instance;
    for (final id in defIds) {
      final def = repo.getEquipment(id);
      final eq = EquipmentFactory.fromDef(
        def,
        rng: rng,
        obtainedAt: now,
        obtainedFrom: 'master_starting',
        ownerCharacterId: character.id,
      );
      await isar.equipments.put(eq);
      switch (def.slot) {
        case EquipmentSlot.weapon:
          character.equippedWeaponId = eq.id;
          break;
        case EquipmentSlot.armor:
          character.equippedArmorId = eq.id;
          break;
        case EquipmentSlot.accessory:
          character.equippedAccessoryId = eq.id;
          break;
      }
    }
  }

  /// 按 [techDefIds] 顺序学心法：首项 [TechniqueRole.main]，其余 [TechniqueRole.assist]。
  ///
  /// 不走 [TechniqueLearningService.learn]（种子场景跳过 fail-fast 校验 +
  /// 不消耗领悟点）。直接构造 [Technique] 实例并写 Isar，同步 character 的
  /// `mainTechniqueId` / `assistTechniqueIds` / `school`（主修流派透传）。
  static Future<void> _learnMasterStarting(
    Isar isar, {
    required Character character,
    required List<String> techDefIds,
    required DateTime now,
  }) async {
    final repo = GameRepository.instance;
    final numbers = repo.numbers;
    for (var i = 0; i < techDefIds.length; i++) {
      final def = repo.getTechnique(techDefIds[i]);
      final role = i == 0 ? TechniqueRole.main : TechniqueRole.assist;
      final tech = Technique.create(
        defId: def.id,
        ownerCharacterId: character.id,
        tier: def.tier,
        school: def.school,
        role: role,
        learnedAt: now,
        cultivationProgressToNext:
            numbers.cultivationProgressToNext[CultivationLayer.chuKui]!,
      );
      await isar.techniques.put(tech);
      if (role == TechniqueRole.main) {
        character.mainTechniqueId = tech.id;
        character.school = def.school;
      } else {
        character.assistTechniqueIds = [
          ...character.assistTechniqueIds,
          tech.id,
        ];
      }
    }
  }
}

class _ResonanceSpec {
  const _ResonanceSpec(
    this.defId,
    this.battleCount,
    this.enhanceLevel,
    this.forgedSlots, {
    this.forceLineageHeritage = false,
  });

  final String defId;
  final int battleCount;
  final int enhanceLevel;
  final int forgedSlots;
  final bool forceLineageHeritage;
}
