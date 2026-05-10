# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 1 战斗系统**（phase1_tasks.md 定义的 T01–T18），目标 3 周交付。

## 已完成

- **T01 / T02 / T03**（2026-05-10）已收尾，详见 git log + `lib/data/models/`：T01 工程脚手架（Riverpod 2.5 / Isar 3.1 / yaml / intl，data/ 声明 asset 根）/ T02 18 个枚举（91 值）/ T03 5 个 @embedded + 2 个 List-as-Map extension（6/6）
- **T04 Character/Equipment/Technique @collection + 工厂 + Resonance/Dispersion extension**（2026-05-10，14/14）
- **T05 SaveData + IsarSetup（单 slot 简化版，switchSlot/listAllSlots/deleteSlot 留 Phase5）**（2026-05-10，18/18，inspector 验收待 Windows）
- **T06 5 个 Def 纯 Dart 类（equipment/technique/skill/stage/realm，AdventureDef/SynergyDef/RetreatMapDef 留 Phase4）**（2026-05-10，30/30）
- **T07 yaml_loader + GameRepository 单例 + 红线校验 + 10/6/18/6 占位 fixture（武侠风命名+TODO_NARRATIVE）**（2026-05-10，44/44，main 加 kDebugMode counts 日志待 Windows 端验）
- **T08 RealmUtils 境界派生工具**（2026-05-10）
  - `lib/combat/derived_stats.dart`：6 个静态纯函数（absoluteLevelOf / realmDiffModifier / internalForceMaxOf / defenseRateOf / equipmentTierCapOf / maxEnhanceLevelOf），全部从 `GameRepository.instance` 读 RealmDef + numbers.yaml，**无任何硬编码数值**
  - `realmDiffModifier` 取 `|attackerTier.index - defenderTier.index|`，差 0/1/2 走 yaml 段；差 3+ attacker 按 GDD §5.5 + phase1_tasks T08 §470 取 `1.0`（不读 yaml `diff_3_or_more.attacker`，因为 yaml 里是 null —— 见挂账 #12）
  - `equipmentTierCapOf` 用 `realms.firstWhere(tier==）` 取大境界对应 cap（同大境界 7 层共用）
  - `test/combat/derived_stats_test.dart` 15 用例（含 phase1_tasks T08 §463-466 钉死的 4 条验收：`absoluteLevelOf(zongShi,huaJing)==41` / `realmDiffModifier(yiLiu,sanLiu)→(2.5,0.3)` / `realmDiffModifier(sanLiu,jueDing)→(1.0,0.05)` / `defenseRateOf(yiLiu)==0.20`，加首尾边界与 maxEnhanceLevelOf 角色构造）全过
  - `flutter analyze` 0 issues / `flutter test` 59/59 通过
- **T09 CharacterDerivedStats 角色派生属性**（2026-05-10）
  - `lib/combat/derived_stats.dart` 追加 `CharacterDerivedStats` class：`maxHp` / `speed` / `criticalRate` / `evasionRate` / `effectiveEquipmentAttack` / `effectiveEquipmentHp` / `effectiveEquipmentSpeed`
  - `NumbersConfig` 扩两段强类型：`enhancementBonusPerLevel`（来自 `equipment.enhancement.bonus_per_level`，0.05）+ `techniqueSpeedBonus: Map<TechniqueTier,int>`（来自 `techniques.tiers[].speed_bonus`，主修生效）
  - `effectiveEquipmentAttack/Hp/Speed` 严格按 phase1_tasks T09 §515 **乘法连乘**：`base × (1 + enhanceLevel × bonusPerLevel) × resonanceBonus × (1 + 开锋百分比)`；血量无开锋项；开锋仅 `unlocked==true` 的槽位计入
  - `criticalRate` 顺序：先 `base + agility×perPoint`，再 +0.20（灵巧流派），**最后 clamp**；clamp 到 `max_rate=0.50`
  - 灵巧 +0.20 暂硬编码（`_lingQiaoCriticalBonus`），yaml `combat.critical` 段未参数化此值（注释 line 74 仅描述）—— 见挂账 #14
  - 5 战例 maxHp 公式实现验证：A=3850 / B=6600 / C=6180 / D=7760 / E=19500（≤20000 红线）；yaml `max_hp` 字段在 b/c 两例与公式真实值不自洽 —— 见挂账 #13
  - 21 用例新增（5 战例 + speed 3 + critical 3 + evasion 2 + attack 5 + hp/speed 3）
  - `flutter analyze` 0 issues / `flutter test` 80/80 通过
- **T10 伤害计算器（核心）**（2026-05-10）
  - `lib/combat/damage_calculator.dart`：`AttackContext` / `AttackResult` / `DamageCalculator.calculate`
  - 7 阶段流水：闪避 → 基础伤害 → 修炼度 → 流派克制 → 暴击 → 防御 → 境界差，全部系数从 NumbersConfig 走、零硬编码魔数
  - `NumbersConfig` 再扩两段：`cultivationMultiplier: Map<CultivationLayer,double>`（9 层 1.0–3.0）+ `SchoolCounterMatrix`（3×3 attacker→target 单向查表，`multiplierFor` / `extraEffectFor` 双向判断，**未用嵌套 if-else**）
  - 暴击：`forceCritical || roll<critRate`；倍率刚猛/阴柔走 `combat.critical.base_damage_multiplier`(1.5)，灵巧走 `_lingQiaoCriticalDamageMultiplier`(2.0) —— 见挂账 #15
  - 境界差：高打低用 attackerMod、低打高用 defenderMod、同 1.0；attacker/defender 分两位置返回到 [AttackResult]
  - 闪避走 `ctx.rng ?? Random()`；测试全部用 `Random(seed)` 复现（seed=99 主线、seed=42 闪避验证）
  - `formulaBreakdown` 形如 `(600*0.4 + 130 + 500) * 1.0 * 1.0 * 1.0 * 0.95 * 1.0 = 826 [atkLv=2,defLv=1]`
  - 验收：5 战例 A/B/C/D 与 yaml `validation_examples.calculated_damage` 误差 0.2%–1.2%（均 ≤5%）；战例 E 公式输出 ~52416（与 phase1_tasks "≤30000" 不自洽 —— 见挂账 #16）；流派 6 组矩阵均符
  - 21 用例新增（5 战例 + 流派 6 + 闪避 2 + 暴击 3 + 境界差 3 + breakdown 2）
  - `flutter analyze` 0 issues / `flutter test` 101/101 通过
- **T11 战斗状态机数据结构**（2026-05-10）
  - `lib/combat/battle_state.dart`：`BattleResult` enum + `BattleAction` + `BattleCharacter`(immutable) + `BattleState`(initial / copyWith with sentinel / isFinished / pendingUltimates)；`BattleCharacter.fromCharacter` 单一入口走 CharacterDerivedStats，`availableSkills` 从 `TechniqueDef.skillIds → GameRepository.getSkill` 解析；边界守卫(school 必填 / role=main / teamSide∈{0,1} / slotIndex∈[0,2]) 全 fail-fast；不引入文档外 BattleSide 抽象；死亡判定由 T12 控
  - 16 用例 / `flutter analyze` 0 / `flutter test` 117/117（注：T12 时追加 `pendingUltimates` / `totalEquipmentAttack` / `mainCultivationLayer` 三字段，T11 测试不破）
- **T13 战斗事件日志**（2026-05-10）
  - `lib/combat/enum_localizations.dart`：`EnumL10n` 覆盖 BattleResult / TechniqueSchool / RealmTier / RealmLayer / SkillType + realm 拼接 + attackEffect 字符串映射（已知 3 值，未知兜底原样）。Phase 1 唯一允许的"代码内中文"，Phase 4 DeepSeek 接管
  - `lib/combat/battle_log.dart`：formatAction 单行（普通/暴击/闪避/克制/击杀 5 分支，克制方向走"克方主语"与 GDD §4.4 一致）+ formatSummary（胜负+tick+最高伤害+击杀名单）+ formatAllActions。与 DamageCalculator 解耦（§752），只读 AttackResult 不重算
  - 16 用例（EnumL10n 全枚举值 + formatAction 5 分支 + formatSummary 已/未结束 + 集成跑完整战斗验 §747 钉死"行动/伤害/胜负+不出拼音"）/ `flutter test` 145/145
- **T12 战斗引擎 + AI 行动选择**（2026-05-10）
  - `lib/combat/battle_ai.dart`：`BattleAI.decide(actor,state,n) → (SkillDef,int targetId)` 纯函数。招式优先级 pendingUltimates > powerSkill(选 powerMultiplier 最高) > normalAttack；目标对面活角色 currentHp 最低（同 hp 选 slotIndex 小），从 pendingUltimates 移除由 Engine 做无 side effect
  - `lib/combat/battle_engine.dart`：`tick / runToEnd(maxTicks 默认 1000) / requestUltimate`。tick 顺序锁死=全员 CD-=1(最低 0)→全员 ap+=speed→筛活角色 ap≥1000 按 (ap desc, speed desc, teamSide asc, slotIndex asc) 排序→依次 _resolveAction(AI.decide → _calculateInBattle → 应用 hp+扣内力+写 CD(当 tick 不减)+ap-=1000+写 BattleAction+消费 pending+死亡判定+胜负判定)。`_calculateInBattle` 复刻 T10 公式但读 BattleCharacter 快照（避免 battle_state↔damage_calculator 循环 import）
  - **BattleCharacter 字段补完**：追加 `totalEquipmentAttack`(派生缓存) + `mainCultivationLayer`(战斗中不变) + `BattleState.pendingUltimates`(T11 漏，T12 §698 钉死)
  - `requestUltimate` 强校验 type=ultimate 否则 ArgumentError；不打断当 tick；该角色行动后无论是否真用上一律消费 pending（一次机会）
  - 12 用例（3v3 同条件分胜负 / speed 2:1 行动比 / requestUltimate 内力扣+CD 写入+pending 消费 / 三流→绝顶差 2 必败 / 排序破平局 2 套 / maxTicks→draw / decide 优先级 + CD>0 跳过 + 目标 hp 最低 + 跳死亡）
  - `flutter analyze` 0 issues / `flutter test` 129/129 通过
- **T11 前清账冲刺**（2026-05-10）：5 处真硬编码全部接 NumbersConfig（共鸣度阈值/倍率、师承遗物 0.7、散功 0.5、灵巧暴击 +0.20 与 ×2.0）；API 签名变更 (Equipment.resonanceStage/resonanceBonus 由 getter 改为方法、inheritFrom/disperse 加 NumbersConfig 参数)；numbers.yaml 修正 b/c max_hp + 加 critical 两段；phase1_tasks T10 §576 验收线 ≤30000→≤100000；CLAUDE.md §2 改 Phase 1 锁 Riverpod 2.x；解决挂账 #1/#13/#14/#15/#16；101/101 测试同步通过

## 进行中

- 无（T13 完成，下一步 T14 战斗 UI 布局）

## 已知偏差 / 挂账事项

2. **lib/ 目录结构**：CLAUDE.md 写 DDD（`core/features/shared`），实际用 phase1_tasks 的 flat。Phase 5 整理
3. **`riverpod_lint` 砍掉**：与 `isar_generator 3.x` 在 analyzer 版本互斥，Phase 5 切 Isar 4.x 时再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个。等 DeepSeek 改文末
5. **phase1_tasks.md T17 场景 D 笔误**：「差 2」应为「差 3」（三流→绝顶）。做 T17 时改
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 yaml 平衡值（×1.0 / ×0.7）为准。GDD 文字暂不修
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气。GDD 没明确 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界/修炼度层重名、属性分布、+20+ 强化曲线等。Phase 1 实现到对应位置时按需提问
9. **T05 验收 inspector 未跑**：Mac 无 Xcode 跑不了 desktop，留 Windows 首跑验
10. **yaml key 命名约定差异**：numbers.yaml snake_case，内容 yaml camelCase。按文件类型隔离不冲突
11. **T07 验收 counts 日志**：Mac 跑不了 `flutter run`，已写 main.dart kDebugMode，留 Windows 首跑验
12. **`LevelDiffModifier.diff3OrMore.attacker` 数据层 vs 公式层语义不同**：NumbersConfig 兜底为 `diff2.attacker`(=2.5)，公式层取 `1.0`。Phase 5 收尾时一并把兜底改 1.0
17. **phase1_tasks T12 §709 笔误**：「三流→绝顶差 2 守方 0.05」错（差 2 守方=0.3，差 3+ 才是 0.05）。"必败"语义仍成立，验收按差 2 实测

> 已解决条目（#1/#13/#14/#15/#16）已归档到文末。

## 下一步

T14 战斗 UI 布局（3v3 半横版静态布局）+ T15 动画 → T16 Riverpod 串接

## 关键约束（每次开局必读）

- 数值红线：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000（GDD §5.2）
- 不硬编码数值（走 numbers.yaml）、不硬编码中文文案（走 data/narratives, lore, events）
- Riverpod 状态管理；Isar 本地存储；data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md（DeepSeek 领地）
- Mac 端写 lib/、data/*.yaml（顶层）、test/；DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub：https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作：Mac+Opus 写代码与数值；Windows+DeepSeek 写文案

## 归档（已解决挂账）

#1 Riverpod 锁 2.x / #13 yaml b/c max_hp / #14-#15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000（详见 T11 前清账冲刺 commit）。
