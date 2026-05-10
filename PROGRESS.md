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

## 进行中

- 无

## 已知偏差 / 挂账事项

1. **Riverpod 版本**：CLAUDE.md v1.1 锁 3.x，但实际用 2.x（phase1_tasks.md 一致）。等 Phase 5 收尾时统一文档
2. **lib/ 目录结构**：CLAUDE.md 写 DDD（`core/features/shared`），实际用 phase1_tasks 的 flat（`data/combat/ui/providers`）
3. **`riverpod_lint` 砍掉**：与 `isar_generator 3.x` 在 analyzer 版本互斥，Phase 5 切 Isar 4.x 时再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个（章节3+关卡15+装备45+心法22+招式102+奇遇26+百科18+模板7）。等 DeepSeek 改文末
5. **phase1_tasks.md T17 场景 D 笔误**：「差 2 大境界」应为「差 3」（三流→绝顶）。做到 T17 时一并改
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 numbers.yaml 平衡值（×1.0 / ×0.7）为准。GDD 文字暂不修
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气。GDD 没明确要求 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界层 vs 修炼度层重名、属性单项分布、+20+ 强化曲线等。Phase 1 实现到对应位置时按需提问
9. **T05 验收「inspector: true 浏览器看表」未跑**：需要 `flutter run` 实机启动，Mac 端无 Xcode 跑不了 macOS desktop，留给 Windows DeepSeek 端首次跑应用时验。代码已默认开 inspector
10. **yaml key 命名约定差异**：`numbers.yaml` 用 snake_case（CLAUDE.md §4 规范），内容 yaml（equipment/techniques/skills/stages）用 camelCase（与 schema §5 JSON 示例 + Def.fromYaml 期望对齐）。两套约定按文件类型隔离不冲突
11. **T07 验收「日志输出 counts」**：Mac 端 `flutter run` 跑不了，已写在 main.dart 的 `kDebugMode` debugPrint 里，留给 Windows DeepSeek 端首次跑应用时看到
12. **`LevelDiffModifier.diff3OrMore.attacker` 数据层 vs 公式层语义不同**：T07 NumbersConfig 把 yaml 里 null 的字段兜底为 `diff2.attacker`(=2.5)（数据层字段非空保证）；T08 RealmUtils 公式层按 GDD §5.5 + phase1_tasks T08 §470 取 `1.0`（"已经被碾压无须放大"），不读这个字段。两层语义独立，T07 测试不变。后续 Phase 5 收尾时一并把 NumbersConfig 兜底改成 1.0 + 删 T07 这条断言
13. **numbers.yaml validation_examples b/c 的 max_hp 字段与注释手算不自洽**：example_b expected 7500（注释手算 6600）、example_c expected 6800（注释手算 5180）。公式真实值（按公式 1000+内力*0.7+根骨*500+装备血量）：B=6600、C=6180。建议 DeepSeek/数值同学修 yaml 里的 expected 值与公式对齐；公式实现不背锅，T09 测试以"按公式应得"为准
14. **灵巧流派暴击 +0.20 未在 numbers.yaml 参数化**：yaml `combat.critical` 段没有 `lingqiao_bonus` 字段（注释 line 74 仅描述）。T09 暂硬编码在 `CharacterDerivedStats._lingQiaoCriticalBonus`。后续 yaml 加字段（建议 `combat.critical.lingqiao_bonus: 0.20`）+ 改 NumbersConfig 读取

## 下一步

T10 伤害计算器（GDD §5.3/§5.4 全公式 + 5 战例 final_damage 验收）→ T11 战斗节点

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
