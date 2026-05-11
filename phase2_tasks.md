# phase2_tasks.md · 第二阶段（第 4-6 周）装备 + 心法系统任务清单

> **文档地位**：本文档是给 Mac 端 Claude Code + Opus 4.7 的执行清单，每个任务自带验收标准，逐个交付即可。
>
> **遵循文档**：GDD.md v1.1、data_schema.md v1.1、numbers.yaml v0.1.0、phase1_summary.md
>
> **阶段目标**：装备能从 0 强化到 +12+、共鸣度能从生疏走到默契、心法修炼度能升层、散功能扣代价。整体是 Phase 1 战斗系统的"上下游接通"。
>
> **总工作量预估**：约 14-15 个工作日（3 周）

---

## 0. 总体说明（必读）

### 0.1 与 Phase 1 的关系

Phase 1 已交付：
- 数据模型层：`Equipment` / `Technique` / `Character` 三个 @collection 全字段就绪
- 派生属性层：`CharacterDerivedStats` 已读 `enhanceLevel` / `battleCount` 等字段做计算
- 战斗引擎：纯快照战斗（`BattleCharacter` immutable），战斗中**不会**回写到 Isar

Phase 2 干的事：
- **服务层**：把"能改 Equipment / Technique / Character 状态"的所有业务逻辑封装为 service 类
- **战斗结算 hooks**：战斗结束时回写 `battleCount++` / `skillUsageCount[i]++` / 掉落物品入背包
- **最小 UI**：仓库 / 强化 / 开锋 / 心法面板 4 块，**仍走调试菜单入口**，不做正式主菜单（留 Phase 3）

### 0.2 关键约束（不要踩雷）

1. **延续 Phase 1 红线**
   - 数值常量全部走 `numbers.yaml`（Phase 1 已有 `equipment.enhancement` / `equipment.forging` / `techniques.cultivation` / `techniques.dispersion` 等段，**不要再硬编码**）
   - 中文文案不进 Dart 代码（UI 标签走 `lib/ui/strings.dart`，战斗调试走 `enum_localizations.dart`，剧情/典故走 DeepSeek）

2. **战斗依然纯快照**
   - `BattleCharacter` 仍是 immutable，战斗引擎**不直接改 Isar**
   - 改 Isar 的写操作集中在 **战斗结算阶段**（一个新增的 `BattleResolutionService`），由 `BattleNotifier` 在 result 翻转时调用一次
   - 这样保留 Phase 1 的"纯函数引擎易测"优势

3. **Phase 2 不做的事（明确边界）**
   - 角色生成（属性 roll、6 档稀有度） → Phase 3（与师徒传承一并做）
   - 心法相生组合（GDD §4.5）→ Phase 3（需要 SynergyDef yaml + 文案，与 DeepSeek 联动）
   - 武学领悟、师承传承、闭关、商店、奇遇 → Phase 3+
   - 多存档 → Phase 5

4. **Riverpod 仍锁 2.x**
   - `riverpod_annotation` 代码生成式 provider，与 Phase 1 一致

### 0.3 已拍板的决策（2026-05-11 Pen 确认）

| 决策项 | 关联任务 | 决议 |
|---|---|---|
| §12 #3 强化 +20~+49 成功率 | T20 | yaml 公式 `max(0.30, 0.50 - 0.02*(level-19))`，超 +19 段失败惩罚一律 `full` |
| 心法学习领悟点消耗 | T23 | 辅修 100 点 / 主修 500 点（写入 `numbers.yaml` 新段 `techniques.learning_cost`） |
| stages.yaml dropTable 覆盖范围 | T27 | Phase 2 仅给 2 个测试用关卡上 dropTable，正式关卡留 Phase 3 |
| §12 #6 武学领悟机缘值 | — | Phase 3，本阶段不实现 |
| §12 #10 师承遗物细节 | — | Phase 3，本阶段 `isLineageHeritage` 仅作 +5% 内力上限 buff，不实现传位流程 |

### 0.4 任务依赖图

```
                    Phase 1 完成线（v0.1.0-phase1）
                          │
            ┌─────────────┼─────────────┐
            ▼             ▼             ▼
       T19 EquipFactory  T23 学习服务  T27 掉落服务
            │             │             │
            ▼             ▼             │
       T20 强化服务      T24 修炼度累积  │
            │             │             │
            ▼             ▼             │
       T21 开锋服务      T25 散功服务    │
            │             │             │
            └──────┬──────┘             │
                   ▼                    │
              T22 战斗加成整合           │
                   │                    │
                   ▼                    │
              T26 战斗结算 hooks ◄──────┘
                   │
            ─── Week 2 完成线 ───
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
       T28 角色面板  T29 装备仓库+强化  T31 心法面板
                   │          │
                   ▼          │
              T30 开锋 UI  ◄──┘
                   │
                   ▼
              T32 4 测试场景 + 验收 + tag v0.2.0-phase2
```

### 0.5 目录结构（在 Phase 1 基础上扩）

```
lib/
├── services/                       # Phase 2 新建
│   ├── equipment_factory.dart      # T19
│   ├── enhancement_service.dart    # T20
│   ├── forging_service.dart        # T21
│   ├── technique_learning.dart     # T23
│   ├── cultivation_service.dart    # T24
│   ├── dispel_service.dart         # T25
│   ├── battle_resolution.dart      # T26
│   └── drop_service.dart           # T27
├── combat/
│   └── derived_stats.dart          # T22 扩展（已有，加 enhance/forging buff）
├── ui/
│   ├── character_panel/            # T28
│   ├── inventory/                  # T29
│   ├── enhancement/                # T30
│   ├── technique_panel/            # T31
│   └── debug/
│       └── phase2_test_menu.dart   # T32
└── providers/
    ├── inventory_providers.dart    # T28-T29
    └── battle_providers.dart       # T26 扩展（注入 BattleResolutionService）

data/
└── numbers.yaml                    # 已有相关段，本阶段不改（如需扩 Pen 拍板）
```

---

## Week 1：装备数值层（T19-T22）

### T19 · EquipmentFactory + RNG 抽象

- **预估时长**：1 天
- **依赖任务**：Phase 1 完成
- **涉及文件**：`lib/services/equipment_factory.dart`、`lib/utils/rng.dart`

**任务内容**：
1. `lib/utils/rng.dart`：定义 `Rng` 抽象（`int nextInt(int max)` / `double nextDouble()` / `T pick<T>(List<T>)`），默认实现走 `dart:math.Random`，**测试时可注入种子或确定性 mock**
2. `EquipmentFactory.fromDef(EquipmentDef def, {required Rng rng, ...optionals})`：
   - 在 `[def.baseAttackMin, def.baseAttackMax]` 范围内 roll → `Equipment.baseAttack`
   - 同理 roll `baseHealth` / `baseSpeed`
   - `enhanceLevel = 0` / `battleCount = 0` / `forgingSlots` 自动填 3 个空槽
   - `obtainedAt` / `obtainedFrom` 调用方传
3. 边界守卫：def 的 min > max 时 fail-fast（数据错误）

**验收标准**：
- [ ] 单测 ≥ 8 用例：固定种子 → 确定性输出 / 各 tier roll 范围内 / 三个 slot（weapon/armor/accessory）字段差异（武器无 hp / 护甲无 attack）/ forgingSlots 长度恒 3
- [ ] `flutter analyze` 0 issues
- [ ] **不读 NumbersConfig**（数值范围已在 EquipmentDef 内），保持 factory 纯 def-driven

**可能的坑**：
- Equipment 的 `late DateTime obtainedAt` 必须传，工厂方法里默认值不生效（schema 约定）
- 测试时如果直接用 `Random()` 写不出确定性测试 → 必须先做 Rng 抽象再实现 factory

---

### T20 · 强化服务（成功率 / 心血结晶 / 磨剑石）

- **预估时长**：1.5 天
- **依赖任务**：T19
- **涉及文件**：`lib/services/enhancement_service.dart`、`lib/data/numbers_config.dart`（扩段）、单测

**任务内容**：
1. `NumbersConfig` 扩 `EnhancementConfig` 类：解析 yaml `equipment.enhancement.success_curve` + `mojianshi_cost` + `xinxue_jiejing.guaranteed_success_costs`（注意 +20-49 段成功率公式 `max(0.30, 0.50 - 0.02*(level-19))` 走代码而非 yaml 字段）
2. `EnhancementService`：
   - `EnhanceAttempt tryEnhance({required Equipment eq, required int characterAbsoluteLevel, required Rng rng, required int currentMojianshi, required int currentCrystals})`：
     - 校验 `enhanceLevel < min(49, characterAbsoluteLevel)`（GDD §6.2 上限 = 持有者境界总层数）
     - 查 `success_curve` 取成功率 + `mojianshi_cost` 取消耗
     - 材料不够 → 返回 `EnhanceResult.insufficientMaterial`
     - rng → 命中 / 失败：成功 → enhanceLevel++ / 扣全额材料；失败 → `material_penalty` 扣半 or 全 + 心血结晶 +1
   - `EnhanceAttempt useCrystalToGuarantee({required Equipment eq, required int currentCrystals})`：
     - 校验 enhanceLevel ∈ [14-19] 或 [20-49]，查 `guaranteed_success_costs`
     - 晶石够 → 强制成功 + enhanceLevel++ + 扣晶石
3. 关键约束：**永不破防降级**（GDD §6.2 红线，yaml 已锁 `never_degrade: true`）

**验收标准**：
- [ ] 单测 ≥ 12 用例：4 段成功率（+1-10 必成 / +11-13 90% / +14-16 75% / +17-19 50%）/ +20-49 公式 / 失败惩罚 half/full 两路 / 晶石保底两段 / 材料不足 / 上限封顶（角色绝顶启蒙最多 +22）
- [ ] 蒙特卡洛测试：固定种子跑 1000 次 +12 强化，成功率落 ±5% 内
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- 失败也算"消耗一次尝试"，**enhanceLevel 不变但材料按 penalty 扣**
- 晶石保底 +14-16 段消耗 3 颗，必须先确认晶石数量再判定可用
- yaml `success_rate: null` 表示 +20-49 段，代码必须**显式分支**走公式，不能直接 read

---

### T21 · 开锋服务（3 槽、解锁条件、词条互斥）

- **预估时长**：1 天
- **依赖任务**：T20
- **涉及文件**：`lib/services/forging_service.dart`、单测

**任务内容**：
1. `NumbersConfig` 扩 `ForgingConfig`：解析 yaml `equipment.forging.slots`（每槽 unlock 等级 + available_types + bonus_value 表）
2. `ForgingService`：
   - `List<ForgingSlotType> availableTypesForSlot({required Equipment eq, required int slotIndex})`：
     - slotIndex 1/2/3 对应 yaml 三槽
     - 校验 `eq.enhanceLevel >= unlock_at_enhance_level`，否则返回空 list
     - slot 2 排除 slot 1 已选类型（yaml `constraint`）
     - slot 3 仅 specialSkill（必须由 EquipmentDef 提供候选 skill id 列表，本阶段假设 def 已含 `specialSkillCandidates`，未配则空）
   - `void forge({required Equipment eq, required int slotIndex, required ForgingSlotType type, String? specialSkillId})`：
     - 校验类型可用 → 写入 `eq.forgingSlots[slotIndex - 1]`（unlocked=true / type / bonusValue 走 yaml）
     - 已开锋槽**不允许覆盖**（Phase 2 简化）

**验收标准**：
- [ ] 单测 ≥ 8 用例：解锁条件 4 个边界（+9/+10/+14/+15/+18/+19）/ slot 2 互斥 / 重复开锋拒绝 / slot 3 specialSkill 校验 / bonusValue 与 yaml 一致
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- `EquipmentDef` 当前**没有** `specialSkillCandidates` 字段，T21 需新增（schema 扩字段，DeepSeek yaml 也要补，本阶段先用空数组兜底，特殊技能槽允许"未配置"状态）
- slot index 1/2/3 vs 数组 0/1/2，注意 off-by-one

---

### T22 · 装备战斗加成整合到 CharacterDerivedStats

- **预估时长**：1 天
- **依赖任务**：T19、T20、T21
- **涉及文件**：`lib/combat/derived_stats.dart`（扩展）、单测

**任务内容**：
扩 `CharacterDerivedStats`，把强化 / 共鸣 / 开锋 / 师承 buff 全部纳入 `effectiveEquipmentAttack` / `effectiveEquipmentHp` / `effectiveEquipmentSpeed`：

```
final eq_atk_with_enhance = baseAttack × (1 + enhanceLevel × 0.05)
final eq_atk_with_resonance = eq_atk_with_enhance × resonanceBonus
final eq_atk_with_forging = eq_atk_with_resonance × (1 + forging_attack_bonus_pct)
// 师承遗物：仅 internalForceMax × 1.05，不影响 eq_atk
final effective_eq_atk = eq_atk_with_forging
```

新增 `derived_internal_force_max_with_lineage(...)`：师承遗物逐件叠加 +5%（GDD §6.1 注：是否累代叠加属 §12 #10 待决项，**Phase 2 默认每件独立叠加**，Pen 拍板前不变）

**验收标准**：
- [ ] 5 战例（A-E）现有验收数值不破（Phase 1 numbers.yaml validation_examples）
- [ ] 新增 5 战例：+0/+12/+19/+49 强化 / 满共鸣 / 开锋攻击 / 满师承 buff（4 件遗物 +20% 内力上限）
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- Phase 1 的 `effectiveEquipmentAttack` 已经是 baseAttack × (1 + enhanceLevel × 0.05)，T22 是**追加共鸣 + 开锋**，不要重复计算
- 共鸣 bonus 当前在 `Equipment.resonanceBonus(NumbersConfig)`，T22 调用时传 NumbersConfig
- 开锋 attack/speed bonus 是百分比（yaml 写的 15 = +15%），lifesteal/pierce 是新机制（lifesteal = 命中回血百分比，pierce = 无视防御百分比），T22 仅整合 attack/speed，**lifesteal/pierce 留 T26 战斗结算时处理**

---

## Week 2：心法数值层 + 战斗联动（T23-T27）

### T23 · 心法学习服务

- **预估时长**：0.5 天
- **依赖任务**：T22
- **涉及文件**：`lib/services/technique_learning.dart`、单测

**任务内容**：
1. `TechniqueLearningService.learn({required Character ch, required TechniqueDef def, required TechniqueRole role, required int currentInsightPoints})`：
   - 校验 tier 不超过角色境界对应阶（GDD §5.3 三系锁死，已有 `RealmUtils` 工具）
   - 校验角色 `assistTechniqueIds.length < 3`（GDD §4.2 辅修最多 3）
   - 主修学习：若已有主修 → 拒绝（必须先散功，调用方处理）
   - 消耗领悟点（**Demo 阶段统一消耗 100 点学习辅修，500 点学习主修**，写进 `numbers.yaml` 新段 `techniques.learning_cost`，见 Pen 拍板项）
   - 创建 `Technique.create(...)`，写入 Isar，返回 id
2. 错误类型：`InsufficientInsightPoints` / `TechniqueTierTooHigh` / `AssistSlotsFull` / `MainTechniqueAlreadyExists`

**验收标准**：
- [ ] 单测 ≥ 6 用例：4 个错误分支 + 主修学习成功 + 辅修学习成功
- [ ] yaml 加 `techniques.learning_cost` 段，T23 提交时同步更新 `numbers_config.dart` 和 fixture

**可能的坑**：
- 学习领悟点的"领悟点"在 Phase 2 还没有获取来源（GDD §7.2 武学领悟系统未实现），**Phase 2 仅校验扣减，初始领悟点由测试场景手动塞 1000 给玩家**
- `TechniqueRole` 是个 enum（main / assist），方法签名要明示

---

### T24 · 修炼度累积（招式使用 → 升层）

- **预估时长**：1 天
- **依赖任务**：T23
- **涉及文件**：`lib/services/cultivation_service.dart`、单测

**任务内容**：
1. `CultivationService.recordSkillUsage({required Technique tech, required String skillId, int delta = 1})`：
   - `tech.skillUsageCount` 调 `MapLikeOnSkillUsage.increment`（Phase 1 已有 extension）
   - `tech.cultivationProgress += delta`
   - 检查是否升层：while `cultivationProgress >= cultivationProgressToNext` 且 `cultivationLayer != jiJing`：
     - `cultivationProgress -= cultivationProgressToNext`
     - `cultivationLayer = next layer`（按 yaml `techniques.cultivation.layers` 顺序）
     - `cultivationProgressToNext = next progress_required`（按 yaml `progress_to_next`）
   - 已到 jiJing → progress 封顶在 `cultivationProgressToNext`
2. 返回 `CultivationProgressResult`：是否升层 / 旧层 / 新层 / 当前 progress

**验收标准**：
- [ ] 单测 ≥ 8 用例：单次累积 / 跨层累积 / 多层连升（一次塞 5000 progress）/ 极境封顶 / 9 层全部升过 / yaml 数值与代码计算一致
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- `cultivationProgressToNext` 是当前层升下一层所需，**不是累积总值**
- 多层连升时要 while 循环消耗，不是一次跳到位
- jiJing（极境）后 progress 不再涨

---

### T25 · 散功服务（双重惩罚 + cultivationLayer 重算）

- **预估时长**：0.5 天
- **依赖任务**：T24
- **涉及文件**：`lib/services/dispel_service.dart`、单测

**任务内容**：
1. `DispelService.dispel({required Character ch, required Technique mainTech, required Technique newMainTech, required NumbersConfig n})`：
   - 校验 `mainTech.role == main` 且 `newMainTech.ownerCharacterId == ch.id` 且 `newMainTech.role == assist`
   - 内力扣减：`ch.internalForce = (ch.internalForce * (1 - n.dispersionInternalForcePenalty)).toInt()`（=×0.5）
   - 原主修：调 `mainTech.disperse(n)`（已有 extension），完事后 progress -50%，role 切 assist
   - **新增：cultivationLayer 重算**：根据新的 progress 反查 yaml `progress_to_next`，从当前 layer 往前回退（progress 不够升下层 → 当前 layer 即可；不够维持当前 layer → 回退到上一层并把 progress 加上 prev `progress_required`）
   - 新主修：`newMainTech.role = main`
   - Character 字段更新：`mainTechniqueId = newMainTech.id`，`assistTechniqueIds` 加旧主修 id（如未满 3）/ 满则旧主修被剔除回到背包
   - 触发 `GameEvent`：`eventType: techniqueDispelled`

**验收标准**：
- [ ] 单测 ≥ 6 用例：基本散功 / cultivationLayer 回退一层 / 不回退（progress 还够）/ 新主修不属于该角色拒绝 / 旧主修非 main 拒绝 / 内力 -50% 精度（floor）
- [ ] 单测：散功后再用 `recordSkillUsage` 累积，能从回退后的 layer 重新升回去

**可能的坑**：
- cultivationLayer 回退算法易写错：进先级是 progress = 旧 progress × 0.5，可能跨层（如圆满 1500 progress * 0.5 = 750，需要回退到 daCheng 层并把 750 - daCheng 的 progressToNext 加上前层差额）。建议写成 `_recalcLayerFromProgress(progress, n)` 纯函数，逻辑清晰
- 新主修必须从角色已学辅修里挑，不是凭空出现
- 旧主修扔回辅修槽时校验槽位是否满 3，满则提示 Pen「旧主修要废弃」

---

### T26 · 战斗结算 hooks（回写 battleCount / skillUsageCount / 掉落 / 心血结晶）

- **预估时长**：1.5 天
- **依赖任务**：T22、T24、T27（T27 早于本任务做掉落）
- **涉及文件**：`lib/services/battle_resolution.dart`、`lib/providers/battle_providers.dart`（扩展）、单测、widget 测试

**任务内容**：
1. `BattleResolutionService.resolve({required BattleState finalState, required List<Character> participatingCharacters, required StageDef stageDef, required Rng rng})`：
   - 对每个参战角色：
     - 装备 `battleCount++`（武器 / 护甲 / 饰品三件，**未参战角色不算**）
     - 该角色主修 + 辅修心法的 `skillUsageCount[skillId].count += 该招式实际使用次数`（从 `finalState.actionLog` 统计）
     - 主修心法触发 `CultivationService.recordSkillUsage`（升层）
   - 调 `DropService.rollDrops(stageDef, rng)` → 装备入背包（=`Equipment.create` + `ownerCharacterId = null`，进 `defaultCharacter` 仓库）/ InventoryItem 数量更新
   - 注意：lifesteal / pierce 是战斗内 buff，T26 仅写战后副作用，**lifesteal 实际生效在 BattleEngine 中，T22 + T26 共用 forging slot 数据但不重复计算**
   - **战败也结算**：参战装备的 battleCount 也涨（GDD §6.4 没说必须胜利才涨），主修 progress 也涨

2. `BattleNotifier` 扩展：result 翻转时调 `BattleResolutionService.resolve(...)`，并在 BattleResult 中追加 `dropEvents` / `cultivationEvents`，UI（T28）展示
3. 接 Riverpod 注入：`battleResolutionServiceProvider`

**验收标准**：
- [ ] 单测 ≥ 10 用例：胜利 / 战败 / 掉落 0 件 / 掉落 1 件 / 升层 / 多角色独立累积 / 未参战角色不动 / 心血结晶不在结算流程（只在 EnhancementService 内）
- [ ] widget 测试：跑完一场调试场景，battleCount 在 Isar 中确实更新（用 fakeIsar 或 in-memory）
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- "实际使用招式次数"要从 `actionLog` 反推，注意 `skill?.id` 可能 null（普通行动）
- 写 Isar 用 transaction（`isar.writeTxn(() async { ... })`），单条 `await` 顺序保证
- battleCount 的 buff 升级（如从 99 → 100 突破到趁手）当场战斗**不生效**（BattleCharacter 是开战时快照），下场战斗才用新值
- **战斗结算可能跨多个 Isar Collection**，写失败要 rollback（Isar txn 自动管）

---

### T27 · 装备掉落服务（StageDef 扩 dropTable）

- **预估时长**：1 天
- **依赖任务**：T19
- **涉及文件**：`lib/services/drop_service.dart`、`lib/data/defs/stage_def.dart`（扩字段）、`data/stages.yaml`（扩字段）、单测

**任务内容**：
1. 扩 `StageDef`：新增 `dropTable: List<DropEntry>` 字段
   ```yaml
   # data/stages.yaml 示例
   dropTable:
     - equipmentDefId: weapon_xunchang_tie_jian
       dropChance: 0.3      # 30% 掉
     - inventoryItemDefId: item_mojianshi
       quantity: [1, 3]     # 1-3 颗磨剑石
       dropChance: 1.0      # 必掉
   ```
2. `DropService.rollDrops(StageDef stage, Rng rng) → DropResult`：
   - 遍历 dropTable，对每条 `rng.nextDouble() < dropChance` → 命中
   - 装备类：调 `EquipmentFactory.fromDef(...)` 生成实例
   - 物品类：返回 `InventoryItem` defId + quantity（如是 range，再 roll）
3. fixture 扩展：现有 `data/stages.yaml` 6 个关卡每个加 dropTable（**Pen 决定**：是否本阶段就给所有关卡上掉落表，还是仅测试用 2 个关卡上）

**验收标准**：
- [ ] 单测 ≥ 6 用例：dropChance=0 不掉 / dropChance=1 必掉 / quantity range / 蒙特卡洛 1000 次 dropChance=0.3 落 ±5%
- [ ] yaml 加 dropTable 后 `GameRepository.loadAllDefs` 不崩
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- yaml `dropTable` 是 list of "either equipment or item"，dart 端用 `sealed class DropEntry { EquipmentDrop / ItemDrop }` 模式更清晰
- DropService 不做 Isar 写入，只返回 DropResult；写入由 T26 的 BattleResolutionService 统一做（保持纯函数 + 易测）

---

## Week 3：UI + 测试场景 + 验收（T28-T32）

### T28 · 角色面板 UI（属性 / 装备槽 / 心法槽 / 派生数值汇总）

- **预估时长**：1.5 天
- **依赖任务**：T22、T26
- **涉及文件**：`lib/ui/character_panel/character_panel_screen.dart`、`lib/providers/character_providers.dart`

**任务内容**：
1. `characterByIdProvider` family / `equipmentByIdProvider` family / `techniqueByIdProvider` family（Riverpod）
2. UI 布局（参考 ui_structure.md 如有，否则自定）：
   - 顶部：姓名 / 境界 / 流派色
   - 中部：四项属性 + 派生数值（HP / 内力 / 速度 / 暴击率 / 闪避）
   - 装备区：3 个槽（武器/护甲/饰品），每槽显示装备图标 + tier 颜色 + +N 强化等级 + 共鸣阶段
   - 心法区：主修高亮 + 3 个辅修槽 + 当前修炼度层 + 进度条
3. 卡牌色调延续 Phase 1 `WuxiaColors`，无空状态时显示"未装备"灰色占位

**验收标准**：
- [ ] widget 测试 ≥ 4 用例：3 槽显示 / 未装备占位 / 共鸣阶段图标 / 修炼度进度条
- [ ] 视觉验收（Windows 端跑）：能看到 3 个角色面板（祖师 + 大弟子 + 二弟子），切换流畅

**可能的坑**：
- Equipment / Technique 在 Isar 是单独表，从 Character 拿 id 后要去 Isar 查，注意 Riverpod 异步 provider
- forgingSlots 在角色面板**不显示**（开锋详情在 T30 单独页），仅显示装备 +N 即可

---

### T29 · 装备仓库 UI + 强化入口

- **预估时长**：1.5 天
- **依赖任务**：T20、T28
- **涉及文件**：`lib/ui/inventory/inventory_screen.dart`、`lib/ui/enhancement/enhance_dialog.dart`

**任务内容**：
1. 仓库页：所有 `Equipment.where().findAll()` 列表展示，按 tier 分段折叠
2. 列表项：tier 颜色边框 + 名字 + slot 图标 + +N + 共鸣阶段，**点击 → 弹强化对话框**
3. 强化对话框：
   - 当前 +N → +N+1 预览
   - 显示成功率（查 success_curve）/ 磨剑石需求 / 心血结晶余量
   - 按钮：「强化」（走 EnhancementService.tryEnhance）/「保底成功」（晶石够时显示）
   - 结果显示：成功 → 闪金光 + 显示新 +N；失败 → 屏震 + 显示「+1 心血结晶」
4. 装备 / 卸下入口（拖到角色面板 / 点角色名菜单），延后到 T28 完整化

**验收标准**：
- [ ] widget 测试 ≥ 5 用例：仓库列表渲染 / 强化对话框打开 / 成功显示 / 失败显示 / 材料不足按钮 disabled
- [ ] 视觉验收（Windows）：连续强化 +0 → +12，成功率符合直觉（前 10 必成）

**可能的坑**：
- 强化对话框关闭时 BattleNotifier-style 的 ref.listen 可能需要触发 inventory provider 失效
- 强化失败的屏震要复用 Phase 1 T15 的 ScreenShake controller，**不要新写一套**

---

### T30 · 开锋 UI（解锁条件 + 词条选择）

- **预估时长**：1 天
- **依赖任务**：T21、T29
- **涉及文件**：`lib/ui/enhancement/forging_panel.dart`

**任务内容**：
1. 在 T29 强化对话框底部加「开锋」tab
2. 3 个槽位卡片：
   - 槽 1（+10 解锁）/ 槽 2（+15 解锁）/ 槽 3（+19 解锁）
   - 未解锁：灰色 + "强化到 +N 解锁"
   - 已解锁未开锋：显示可选词条列表（attack / speed / lifesteal / pierce），点击 → forge
   - 已开锋：显示已选词条 + bonus 数值，灰色不可改
3. 槽 2 选项过滤掉槽 1 已选类型

**验收标准**：
- [ ] widget 测试 ≥ 4 用例：3 槽锁定状态 / 槽 2 互斥过滤 / 开锋后显示词条 / 槽 3 specialSkill 候选为空时显示"该装备无专属技能"
- [ ] 视觉验收（Windows）：从 +9 → +10 时槽 1 自动可用

**可能的坑**：
- 槽 3 specialSkill 的候选 skill id 列表来自 `EquipmentDef`，Phase 2 开始时 def 字段是空，UI 要兼容空状态
- 开锋一旦下手不能改（Phase 2 简化），UI 要明确"确认开锋"二次确认

---

### T31 · 心法面板 UI（已学列表 / 主修切换触发散功 dialog / 修炼度进度条）

- **预估时长**：1 天
- **依赖任务**：T25
- **涉及文件**：`lib/ui/technique_panel/technique_panel_screen.dart`

**任务内容**：
1. 已学心法列表（按 tier 分组），每条显示：名字 / tier / 流派 / 当前修炼度层 / 进度条
2. 主修标签高亮，辅修最多 3 个
3. 点击辅修 → 「设为主修」按钮 → 弹散功 dialog：
   - 显示双重代价："当前内力 X → X×0.5 = X/2 / 原主修修炼度 Y → Y/2 / 修炼度层可能回退"
   - 二次确认按钮 → 调 `DispelService.dispel`
   - 完成后弹"散功完成"消息 + 触发 GameEvent

**验收标准**：
- [ ] widget 测试 ≥ 4 用例：列表渲染 / 进度条 / 散功 dialog 打开 / 散功后主修切换
- [ ] 视觉验收（Windows）：散功后 UI 立即更新数值

**可能的坑**：
- 散功 dialog 必须二次确认（GDD §6 强制规则），不能 one-click 触发
- cultivationLayer 回退后要立即刷新 UI，注意 provider invalidate 时机

---

### T32 · 4 套测试场景 + Phase 2 验收 + tag v0.2.0-phase2

- **预估时长**：1.5 天
- **依赖任务**：T28-T31 全部完成
- **涉及文件**：`lib/ui/debug/phase2_test_menu.dart`（新建）、`test/services/phase2_scenarios_test.dart`（新建）、`phase2_summary.md`（新建）

**任务内容**：
1. 调试菜单第二屏（与 Phase 1 T17 menu 并列）：
   - **场景 P1 强化曲线**：给一件 +0 装备 + 1000 磨剑石 + 100 晶石，连续点强化到 +19，看实际成功率分布
   - **场景 P2 共鸣度战斗触发**：给一件 battleCount=99 装备，跑一场战斗，下次进战看 battleCount=100 触发"趁手" buff
   - **场景 P3 散功代价**：角色当前内力 10000 / 主修 yuanMan 1500 progress，散功换辅修，看：内力 → 5000 / 修炼度 → daCheng + 750 progress
   - **场景 P4 强化 + 开锋 + 共鸣全栈**：从 +0 强化到 +19 + 开锋 1/2/3 + battleCount=2000 默契满，对比裸装伤害
2. `phase2_scenarios_test.dart`：4 场景的数值验收单测（不依赖 UI）
3. **验收清单**：
   - [ ] flutter analyze 0 issues / flutter test 全绿（预期 ~200 用例）
   - [ ] 4 场景 UI 跑通（Windows 视觉验收）
   - [ ] 数值校验：5 个 Phase 1 战例 + 5 个 Phase 2 战例（强化 / 共鸣 / 开锋 / 散功 / 全栈）
4. 合并 main：`feat/phase2-equipment` / `feat/phase2-techniques` / `feat/phase2-ui` 三分支 no-ff 合并（与 Phase 1 同策略）
5. tag `v0.2.0-phase2` + 写 `phase2_summary.md`（功能清单 / 数值对照 / 已知问题 / 性能基准）

**验收标准**：见上方任务内容

**可能的坑**：
- 场景 P1 蒙特卡洛要塞固定种子 Rng，否则结果飘
- 场景 P3 散功后 cultivationLayer 回退算法验收，必须打对（建议先在 T25 单测里写死 expected 数值，T32 复用）
- 视觉验收一律推到 Windows 端（Mac 端 Isar dart:ffi web 不支持，挂账 #18）

---

## Phase 2 验收清单（精简版）

### A. 数据流通（无 UI 也应跑通）

- [ ] **A1** 给角色一件装备，跑战斗，battleCount += 1
- [ ] **A2** 战斗中招式使用 → 主修心法 cultivationProgress 累积
- [ ] **A3** 累积满 100 → cultivationLayer chuKui → xiaoCheng
- [ ] **A4** 散功调用后内力 -50% / 原主修 progress -50% / cultivationLayer 重算正确

### B. 装备系统

- [ ] **B1** EquipmentFactory roll 出的 baseAttack 在 yaml tier 范围内
- [ ] **B2** 强化 +1 → +10 100% 成功
- [ ] **B3** 强化 +14 → +15 大约 75% 成功（蒙特卡洛 100 次落 70-80）
- [ ] **B4** 强化失败必得 +1 心血结晶
- [ ] **B5** 心血结晶 ≥ 3 时 +14-16 段「保底成功」按钮可用
- [ ] **B6** 装备到 +10 解锁开锋一，可选 attack/speed/lifesteal/pierce
- [ ] **B7** 开锋二选项排除开锋一已选类型

### C. 共鸣度

- [ ] **C1** battleCount 99 → 100 时阶段切换 shengShu → chenShou，下场战斗装备数值 +10%
- [ ] **C2** battleCount 500/2000 阈值切换正确
- [ ] **C3** isLineageHeritage=true 时角色 internalForceMax × 1.05

### D. 心法

- [ ] **D1** 学习辅修消耗 100 领悟点，达到 3 个辅修后再学拒绝
- [ ] **D2** 学习超过角色境界对应 tier 的心法被拒绝（GDD §5.3 三系锁死）
- [ ] **D3** 主修存在时再学主修被拒绝（必须先散功）
- [ ] **D4** 散功完成后旧主修 role=assist，新主修 role=main，Character.mainTechniqueId 更新

### E. UI

- [ ] **E1** 角色面板能看到 3 槽装备 + 主修 + 3 辅修
- [ ] **E2** 强化对话框能连续点 +0 → +19，看到成功 / 失败 / 屏震 / 心血结晶涨
- [ ] **E3** 开锋词条选择能下手并显示 bonus
- [ ] **E4** 散功 dialog 二次确认后 UI 立即更新

### F. 性能

- [ ] **F1** 仓库 100 件装备列表流畅（debug 30+ FPS）
- [ ] **F2** 强化 100 次连点不卡（每次 Isar txn < 16ms）
- [ ] **F3** 战斗结算（含掉落 + 修炼度回写）单帧完成

---

## 已知不在 Phase 2 范围内的内容（避免误解）

下面这些 Phase 2 **故意不做**，留到后续阶段：

- 角色生成（属性 roll、6 档稀有度）→ Phase 3 与师徒传承一并做
- 心法相生组合（GDD §4.5）→ Phase 3，需 SynergyDef yaml + 文案
- 武学领悟系统（机缘值、灵光一现）→ Phase 3，与奇遇一并
- 师徒传承（飞升传位、师承遗物自动传）→ Phase 3
- 闭关产出 / 时辰加成 / 节气日 → Phase 3
- 江湖商店刷新机制 → Phase 3
- 主线关卡 / 爬塔 / 奇遇 → Phase 3
- 真正的"昨晚发生的事"摘要 UI → Phase 4
- 美术资源 → Phase 5
- 文案接 DeepSeek（typique description / lore）→ Phase 4

---

**文档结束。**

> 交给 Claude Code 执行：复制本文档贴进 Claude Code，告诉它「按 T19 → T32 顺序执行，每完成一个任务停下来等我 review，跑通 acceptance 后再开下一个」。Pen 拍板项见 §0.3，开工前一次性问完。
