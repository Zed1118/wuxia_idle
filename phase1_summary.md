# Phase 1 交付总结

**里程碑**：v0.1.0-phase1（2026-05-11）  
**范围**：T01-T17，战斗核心系统 + 调试验收菜单

---

## 一、交付功能清单

| 任务 | 交付物 |
|---|---|
| T01 | Flutter Desktop 脚手架（Riverpod 2.5 / Isar 3.1 / yaml / intl） |
| T02 | 18 个枚举，91 值（境界/修炼度/流派/装备阶/心法阶…） |
| T03 | 5 个 @embedded 嵌入对象 + List-as-Map extension |
| T04 | Character / Equipment / Technique @collection + 共鸣/散功 |
| T05 | SaveData + IsarSetup（单 slot，多 slot 留 Phase 5） |
| T06 | 5 个纯 Dart Def 类（equipment/technique/skill/stage/realm） |
| T07 | yaml_loader + GameRepository 单例 + 红线校验 + 占位 fixture |
| T08 | RealmUtils 6 个境界派生纯函数（走 numbers.yaml，零硬编码） |
| T09 | CharacterDerivedStats（maxHp/speed/criticalRate/evasionRate/effectiveEqAtk） |
| T10 | DamageCalculator 7 阶流水（闪→基础→修炼→克制→暴击→防御→境界差） |
| T11 前清账 | 5 处硬编码接 NumbersConfig（共鸣阈值/倍率/散功/灵巧暴击…） |
| T11 | BattleCharacter(immutable) / BattleState(initial+copyWith) / BattleResult |
| T12 | BattleEngine(tick/runToEnd) + BattleAI(优先级决策) |
| T13 | EnumL10n 全枚举中文化 + BattleLog 5 分支格式化 |
| T14 | 战斗 UI 3v3 半横版静态布局（WuxiaColors / CharacterAvatar / HpBar） |
| T15 | 攻击动画（三段式 yaml-driven）+ 伤害飘字 + 屏震 |
| T16 | Riverpod 串接（BattleNotifier）+ 大招按钮置灰/解除 + 结算 overlay |
| T17 | 4 套调试场景菜单（A同境/B克制/C装备/D碾压）+ hint 横幅 + 数值验收测试 |

**测试覆盖**：160 个测试（unit 143 + widget 13 + scenario 4），全部通过。

---

## 二、数值验收（5 个 validation_examples 实测对照）

公式：`final = (IF×0.4 + eqAtk×1.0 + PM) × cult × counter × crit × (1-def) × realmMod`

| 战例 | 场景 | 预期 | 实测 | 误差 |
|---|---|---|---|---|
| A | 学徒新手关（同境，普攻，无暴击） | 826 | 826 | 0% |
| B | 二流圆熟同境对决（强力技能） | 4,889 | 4,880 | ≤ 0.2% |
| C | 三流打二流（差 1 境，守方×0.7） | 1,972 | 1,993 | ≤ 1.1% |
| D | 一流大招暴击 + 刚克阴（×1.25, ×2.0） | 28,525 | 28,350 | ≤ 0.7% |
| E | 武圣极境顶配（压力测试，血量 ≤20000 红线） | 约 19500 HP，无崩盘 | 血量公式满足，上限验证通过 | — |

> T17 场景 A 实测范围 **2000-8000**（critRate=0 排除暴击）、场景 B 克制比值 **1.667**、场景 C 装备比值 **1.92**（≥60%）、场景 D 三流每击 ≤300 + 绝顶首击 >6000，均符合 GDD §5.2 红线。

---

## 三、已知问题 / Phase 2 待办

| # | 问题 | 优先级 | 备注 |
|---|---|---|---|
| #2 | lib/ 目录结构为 flat，CLAUDE.md 描述 DDD | 低 | Phase 5 整理 |
| #3 | riverpod_lint 砍掉（与 isar_generator 3.x 互斥） | 低 | Phase 5 切 Isar 4.x 时补 |
| #6 | GDD §5.3 公式 ×8 vs yaml ×1.0 | 低 | yaml 为准，GDD 口误已知 |
| #12 | LevelDiffModifier.diff3OrMore yaml 兜底为 diff2 而非 1.0 | 低 | Phase 5 一并修 |
| #17 | phase1_tasks T12 §709 笔误（差2守方 0.05 → 实为差3+） | 记录 | 已在 T17 注释中修正 |
| #18 | flutter build web 被 Isar dart:ffi 阻塞 | 中 | Phase 5 切 Isar 4.x |
| #20 | T15/T16 视觉验收（攻击动画/飘字/大招）待 Windows 端跑通 | 中 | 环境就绪后补验 |
| — | 真实角色生成（属性 roll）、装备掉落、心法修炼均未做 | 正常 | Phase 2 装备+心法系统专题 |

---

## 四、性能基准

| 指标 | 实测（Mac M 芯片，debug 模式） |
|---|---|
| 全量测试套件（160 用例）运行时长 | ~5.5 秒 |
| 纯战斗测试（105 用例）运行时长 | ~4.1 秒 |
| `flutter analyze` | 0 issues（1.9 秒） |
| BattleEngine.runToEnd（maxTicks=1000）| <1 ms（纯计算，无 UI） |
| 战斗 UI 动画 FPS | 待 Windows 端首跑验收（挂账 #20） |

---

## 五、后续阶段一句话概览

- **Phase 2**：装备系统（掉落 / 强化 / 开锋 / 共鸣度递增）+ 心法系统（学习 / 修炼度 / 散功）
- **Phase 3**：主线关卡 / 爬塔 / 闭关地图 / 奇遇事件
- **Phase 4**：接 DeepSeek 文案 + 剧情 + 新手引导
- **Phase 5**：迁 Isar 4.x / Riverpod 3.x / 美术 AI 出图 / MSIX 打包
