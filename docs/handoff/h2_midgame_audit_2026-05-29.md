# H2 中期(Ch2-3 · 2-3h)玩法深度 audit + 候选清单

> 起草:2026-05-29 · H 段 Batch H2 · 4 并行子 agent(装备/心法/师徒+共鸣/闭关+章节+升阶)Phase 0 grep
> **本 doc 0 代码改** · 6 条 load-bearing 断言已 grep 实测核验 · 用户拍套餐后再实装(沿 H1 体例)
> 范围:H2.1 装备/心法 build 深度 · H2.2 师徒/闭关/共鸣度首次解锁 · H2.3 章节切换/升阶/难度曲线

## 0. 两大根因(贯穿 4 系统)

- **A · 挂机循环与中期成长脱节**:idle/闭关 **0 喂共鸣度**(`seclusion/` 无 battleCount)+ 闭关 EXP 性价比远低于战斗(挂满 72h ≈ 打 2 关 Ch3 Boss)+ 闭关特色产出 `insightPoints`/`techniqueLearnPoints` **无任何消费 sink**。"挂机"游戏的离线收益对中期成长贡献微乎其微 → 与品类定位冲突。
- **B · backend 做完但前端没接线 / 死字段**:章节翻篇叙事不 load · 学新心法 UI 0 caller · insightPoints 死钱包 · cultivation_progress_pct 死字段 · 升阶大境界数据齐备但 UI 不区分 · 换装 effective 数值 UI 不展示。**多为低成本接线即可兑现的已产内容**。

## 1. 装备系统(H2.1a)

| # | 维度 | 现状(grep 实测)| 严重度 | 文件:行 |
|---|------|------|--------|---------|
| E1 | 同阶武器零差异 | haoJiaHuo 5 把武器数值完全相同,仅 schoolBias 区别;base 属性仅 attack/health/speed 三维,无防御/暴击维度承载取舍 → 武器选择被境界+流派锁死无决策 | 🔴 设计深度 | `equipment.yaml:186-267` · `enums.dart:90-95` |
| E2 | 无换装对比 | detail 页只显裸 base 绝对值,不显 vs 已装备 delta;强化/共鸣/开锋乘法 effective 值 UI 完全不展示 → 中期捡一堆同阶掉落无法判优 | 🔴 接线 | `equipment_detail_screen.dart:355-411` · `derived_stats.dart:189-214` |
| E3 | 强化曲线 / 掉落弧线 | 成熟健康:+10 安全区→+11 概率区→心血结晶保底;Ch2-3 掉落"打完升一阶"弧线成立 | 🟢 无 gap | `numbers.yaml:462-519` · `stages.yaml:558-573` |
| E4 | 开锋 build | 唯一真横向 build 入口(吸血/破甲/攻/速四选二+第2槽排斥),中期 +10/+15 及时接入;但词条仅 4 种,因 base 属性单薄被迫承载全部深度 | 🟡 P1 | `numbers.yaml:550-573` · `forging_service.dart:54-104` |

## 2. 心法系统(H2.1b)

| # | 维度 | 现状(grep 实测)| 严重度 | 文件:行 |
|---|------|------|--------|---------|
| T1 | 学新心法 UI 未接线 | `.learn(` 全 lib/ **0 caller**(只 test/seed);技能面板只有散功无学习;奇遇 0 产出 technique;领悟点攒了无处花 → 中期玩家**无法主动学任何新心法**,心法获取环节缺位(代码注释自承 §7.2 Phase 5+)| 🔴 总阀门 | `game_event_service.dart:22` · `technique_learning.dart:48` |
| T2 | 3 辅修槽只第1个参与相生 | `SynergyService.detectActive` 只读 `assistTechniqueIds.first` + 辅修永不升层(`battle_resolution.dart:271`)→ build 维度砍 2/3,12 个相生组合 build 价值腰斩 | 🔴 设计深度 | `synergy_service.dart:37` |
| T3 | 同阶变体数值同质 | 49 本矩阵齐全(7阶×3流派+攻/防/内变体),但同阶变体 speedBonus/internalForceGrowthBonus 完全一致,差异只在 skillIds → 心法层"选哪本"无意义 | 🟡 P1 | `techniques.yaml:64-101` |
| T4 | 闭关喂修炼度近零 | 三流藏经阁挂满 72h 仅 +91 progress(够升 1 层);修炼度全靠在线刷战斗 | 🔴(根因A)| `numbers.yaml:959-967` |
| T5 | 散功代价 | 机制+UI 警示完整,但因 T1 无学习入口 → 散功是"只减不换"死操作,无使用场景 | 🟡 P1 | `dispel_dialog.dart:34-64` |

## 3. 师徒 + 共鸣度首次解锁(H2.2)

| # | 维度 | 现状(grep 实测)| 严重度 | 文件:行 |
|---|------|------|--------|---------|
| S1 | 师徒中期零闭环 | 收徒进 inactive 池,全库无"出阵/培养/产出"API,弟子不参战不产出 → 收了就放着(飞升接任是远期 payoff)| 🔴(部分 Demo scoped)| `recruitment_service.dart:103` · `lineage_panel_screen.dart` |
| S2 | 收徒门槛与中期错配 | 触发门槛=一流(yiLiu),但 Ch3 敌人全 erLiu(二流),一流首现于 Ch4 → 中期(Ch2-3)摸不到收徒,"中期内容"实为 Ch4+ | 🟡 P1 | `tutorial_service.dart:92` · `stages.yaml:996` |
| R1 | 人剑合一中期触不到 | 默契(解锁人剑合一)=500 手动战,趁手=100 战;idle 0 喂 battleCount → 2-3h 中期勉强摸到趁手,核心卖点人剑合一"看得见够不着" | 🔴(根因A)| `numbers.yaml:522-543` · `battle_resolution.dart:130-143` |
| R2 | 共鸣度引导 | detail 页"距默契尚需 X 战"静态展示优秀,但无 tutorial 首引导 + 晋升时刻无 toast/banner(`resonanceUpgradedEquipmentIds` 数据有未消费)| 🟡 P1 接线 | `equipment_detail_screen.dart:288-330` |
| S3 | 祖师 buff 死字段 | `cultivation_progress_pct:0.03` 仅 lineage_panel 当 label 显,**无公式消费**(违 memory `feedback_yaml_config_unused_field`);buff +2~5% 静默 bake 进总值无角标,中期难感知 | 🟡 P1 | `numbers.yaml:1111` · `lineage_panel_screen.dart:313` |
| F1 | 武学领悟 encounter | 替代抽卡机制完整(57 条:25 insight+32 fortune),但入门奇遇需 100 单一流派击杀/闭关地形分钟,中期首次领悟偏晚;step7 触发后才解释 | 🟡 P1 | `encounters.yaml:26-44` |

## 4. 闭关 / 章节切换 / 升阶 / 难度曲线(H2.2+H2.3)

| # | 维度 | 现状(grep 实测)| 严重度 | 文件:行 |
|---|------|------|--------|---------|
| C1 | 章节翻篇 dead content | chapter_01~03.yaml prologue/epilogue 文学质量高(衔接无缝),但 lib/ **0 引用**,运行时不 load;打完章末 Boss 进新章只有列表卡片变亮,无翻篇仪式 → 最高质量过场白白浪费,**接 loader ROI 极高** | 🔴 接线 | `narrative_loader.dart`(缺 chapter loader)· `chapter_*.yaml` |
| C2 | 升阶大境界仪式 | 7 次大境界突破(三流→二流带解锁/品阶提升)与 42 次小层升级**共用同一小 banner**;lib/ 无 `crossedTier/isTierUp` 概念;`AdvancementResult` 已含 tierBefore/After → 只需 UI 判 `tierAfter!=tierBefore` 走庆祝 | 🟡 P1 接线 | `advancement_service.dart:43-52` · `game_event_service.dart:177` |
| C3 | 闭关产出无意义 | insightPoints 写入+展示但全 lib/ **0 消费**(死钱包);闭关 EXP 性价比远低战斗 → 中期玩家无理由闭关 | 🔴(根因A)| `seclusion_service.dart:343` · `numbers.yaml:847` |
| C4 | 闭关首次引导 | 5 地图境界门布局合理(中期 4/5 可用),但首次进入 0 onboarding,setup 屏只一行"每小时预估" | 🟡 P1 | `seclusion_setup_screen.dart:124` |
| C5 | 难度曲线 | 章内递增健康;Ch1末(跨2阶 erLiu Boss)→Ch2首(sanLiu)断崖回落 65% 是 stage_01_05 跨阶设计已知代价(升阶碾压期);Ch2末→Ch3首平滑;红线全合规(最高敌 11000hp/900atk)| 🟢 无 gap | `stages.yaml:265-985` |
| N1 | 章节切换叙事文本 | 文本本身衔接流畅,质量是项目亮点(青衫人剑鞘等道具贯穿)| 🟢 无 gap(待 C1 接线兑现)| `chapter_*.yaml` |

## 5. 候选套餐(用户拍其一 · H2-Q1)

| 套餐 | 内容 | 估时 | ROI | 数值/schema 改 |
|---|------|------|-----|------|
| **小套餐 · 接线 polish**(强推荐)| C1 章节翻篇过场 + C2 升阶大境界仪式 + E2 换装对比/effective + R2 共鸣晋升 toast + S3 死字段清理 | ~3-4h | ⭐⭐⭐⭐⭐ | 0 数值改 · backend 全已做只差接线 |
| **中套餐 · + 挂机循环重平衡**(根因A)| 小套餐 + idle 喂共鸣度/修炼度 + 闭关 EXP 重平衡 + insightPoints/learnPoints 消费 sink(接 T1 学心法)| ~6-8h | ⭐⭐⭐⭐ | numbers.yaml 多段 + 需 balance 验证 |
| **大套餐 · + 深度加深(1.1 级)**| 中套餐 + T2 辅修相生全槽 + E1 武器差异化 + S1 师徒中期闭环 | ~12h+ | ⭐⭐⭐ | schema + 数值大改 · 部分 §12 scoped |

## 6. 起床决策点

| # | 问题 | 推荐 |
|---|------|------|
| **H2-Q1** | 套餐选哪个? | **小套餐**(全是已产 backend 接线,0 数值改 0 风险 + 体验高光时刻 ROI 最高;挂机循环重平衡留中套餐单独拍)|
| **H2-Q2** | 学新心法 UI 1.0 启动 vs 维持 §7.2 Phase 5+? | **维持 scoped**,但中套餐给 insightPoints/learnPoints 一个轻量消费 sink(否则闭关特色产出永远是死钱包)|
| **H2-Q3** | 收徒门槛一流→下调二流让中期可体验? | **下调到二流**(让 Ch2-3 玩家真摸到师徒系统;小改 `tutorial_service.dart:92` 门槛 + 验 S1 闭环是否同步)· 待中套餐拍 |
| **H2-Q4** | 根因A 挂机循环脱节 1.0 必修 vs 1.1? | **1.0 必修**("挂机武侠"离线收益无意义是品类级硬伤,但需数值决策 → 中套餐独立批 + balance_simulator 验)|

---

**核心提示**:中期玩法深度的"骨架"实装扎实(数据建模/红线/UI 透明展示都到位),断的是**首次体验节奏 + 离线循环兑现**。小套餐先把"已做但没接线"的高光时刻接上(章节翻篇/升阶仪式/换装对比),立即可见;根因A 挂机循环重平衡是品类级修复,值得单独一批 + balance 数据驱动。建议 H2→小套餐→中套餐(根因A)→H3 后期 audit。
