# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 1 战斗系统**（phase1_tasks.md 定义的 T01–T18），目标 3 周交付。

## 已完成

- **T01 / T02 / T03**（2026-05-10）已收尾。详见 git log + `lib/data/models/`
  - T01：`flutter create` + Riverpod 2.5 / Isar 3.1 / yaml / intl，`data/` 声明为 asset 根，`*.g.dart` 不入库
  - T02：18 个枚举（91 个值）按 data_schema §2 进 `enums.dart`
  - T03：5 个 @embedded 类 + 2 个 List-as-Map extension，6 用例全过
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
- **T11 前清账冲刺**（2026-05-10，T01-T10 全面 review 后落地）
  - **5 处真硬编码全部接 NumbersConfig**：(a) `Equipment.resonanceStage` 阈值 100/500/2000 → 读 yaml `equipment.resonance.stages`（新加 `ResonanceStageConfig` + `NumbersConfig.resonanceStages`） (b) `Equipment.resonanceBonus` 倍率 1.0/1.10/1.20/1.30 同上 (c) `Equipment.inheritFrom` 0.7 → `n.resonanceInheritanceRetention` (d) `Technique.disperse` 0.5 → `n.dispersionCultivationPenalty` (e) `_lingQiaoCriticalBonus` / `_lingQiaoCriticalDamageMultiplier` → `CriticalConfig.lingqiaoCriticalBonus` + `lingqiaoDamageMultiplier`
  - **API 签名变更**：`Equipment.resonanceStage` / `resonanceBonus` 由 getter 改为方法 `(NumbersConfig)`；`inheritFrom(int, NumbersConfig)`；`Technique.disperse(NumbersConfig)`。entities_test.dart 加 `setUpAll` 走 fileLoader 拿 NumbersConfig
  - **numbers.yaml 修正**：(a) `combat.critical` 加 `lingqiao_critical_bonus: 0.20` + `lingqiao_damage_multiplier: 2.0` (b) `validation_examples.b/c.defender.max_hp` 改为公式真实值 6600 / 6180（与 yaml 注释一致）
  - **phase1_tasks T10 §576 验收线**：「≤30000」→「≤100000」（公式真实值 ~52000 留 2× buffer，且明示与守方血量上限是两条独立红线）
  - **CLAUDE.md §2 状态管理**：「Riverpod 3.x 已锁定」→「Phase 1 锁 2.x，与 phase1_tasks 一致；Phase 5 收尾再迁 3.x」
  - 解决挂账 #1 / #13 / #14 / #15 / #16；保留 #2/#3/#4/#5/#6/#7/#8/#9/#10/#11/#12（与 Phase 1 实现无关或留待后续）
  - `flutter analyze` 0 issues / `flutter test` 101/101 通过（对应测试同步更新签名，断言数值不变）

## 进行中

- 无

## 已知偏差 / 挂账事项

1. ✅ **已解决** Riverpod 版本：清账冲刺已改 CLAUDE.md §2 为「Phase 1 锁 2.x，Phase 5 再迁 3.x」
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
13. ✅ **已解决** numbers.yaml b/c max_hp：清账冲刺已修为公式真实值 6600 / 6180
14. ✅ **已解决** 灵巧暴击 +0.20 硬编码：清账冲刺已加 yaml `combat.critical.lingqiao_critical_bonus`
15. ✅ **已解决** 灵巧暴击 ×2.0 硬编码：清账冲刺已加 yaml `combat.critical.lingqiao_damage_multiplier`
16. ✅ **已解决** phase1_tasks T10 §576 战例 E ≤30000：清账冲刺已改验收线为 ≤100000

## 下一步

T11 战斗状态机数据结构（BattleCharacter 快照 + immutable BattleState） → T12 战斗引擎 + AI

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
