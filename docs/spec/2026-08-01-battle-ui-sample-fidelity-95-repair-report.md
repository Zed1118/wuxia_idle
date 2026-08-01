# 战斗界面样板还原度 95+ 修复报告

> 日期：2026-08-01<br>
> 文档类型：视觉修复规格 / 实施前审查报告<br>
> 当前代码态：`main@acc31ee8`<br>
> 状态：**已复核待实施**<br>
> 唯一视觉母版：`docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png`<br>
> 母版规格：1672 × 941 逻辑像素<br>
> 母版 SHA-256：`fe5c8e8d1696c8136db140ae31ccb7e096b34e385bb21b442340e90b582f5957`<br>
> 当前复核基线：黄金帧 **81/100**、生产泛化 **72/100**；旧综合口径为 **77/100**，本报告改用取低值口径，发布基线为 **72/100**<br>
> 最终目标：黄金帧与生产泛化 **分别 ≥95/100**，最终分取两者较低值
> 附录 A 处理状态：已按 `CLAUDE.md §8.2` 完成独立 triage；正文仅合并证据成立的部分

---

## 0. 执行摘要

当前战斗界面已经完成三段式结构、人物舞台、七技能签、角色名帖和战备行囊的
主体迁移，方向正确，功能与桌面交互稳定。但 2026-07-31 记录的“R2 98/100”不能继续
作为生产视觉质量口径：它主要证明固定黄金 fixture 的几何、色阶和组件状态已经被
定点校准，没有充分证明画面材质、人物轮廓和量产关卡都贴近样板。

2026-08-01 在当前 `main` 重新编译 macOS debug app，并以原生窗口 ID 抓取
1280×720、1440×900、1672×941 三档黄金路由，以及主线、塔、群战六张生产路由后，
重新得到以下基线：

| 评分对象 | 当前分 | 目标 | 差距 |
|---|---:|---:|---:|
| 黄金样板固定帧 | 81 | ≥95 | 14 |
| 常规生产战斗泛化 | 72 | ≥95 | 23 |
| 最终发布口径 | 72（取低值） | ≥95 | 23 |

差距主要集中在五处：

1. 验收工具没有真正比较 reference/current，历史高分缺少足够硬证据；
2. 黄金路由固定注入专用人物、七招、蓄势和行囊物件，视觉丰富度高于生产常态；
3. 蓄势横幅、Boss 数字环、人物血条仍有明显通用游戏 HUD 感；
4. 1280×720 由 `height >= 190` 触发整套紧凑换皮，与 1440/1672 不是同一视觉语言；
5. 不同场景和量产立绘的明度、锐度、接地与水墨融合波动较大。

本轮要达到 95+，不能继续只做坐标微调。推荐按“验收工具可信化 → 公共 HUD 去现代化 →
案台响应式统一 → 人物/场景泛化 → 动态状态与全模式终验”的顺序串行推进。预计需要
4～6 个专注实施切片；实现开始前必须另建 `CLAUDE.md §8.0` 要求的可恢复 plan 和独立
worktree。本报告只定义修复规格，不自动修改战斗代码、数据或资产。

---

## 1. 目标定义与评分纪律

### 1.1 “95+”的正式含义

95+ 不是“某一张截图看起来很像”，而是同时满足：

- **黄金帧还原分 G ≥95**：同一 1672×941 母版场景、固定阵容、固定状态的直接对照；
- **生产泛化分 P ≥95**：真实主线、塔、群战、特殊状态和双常规桌面视口都保持同一风格；
- **最终分 F = min(G, P)**，且 F ≥95；
- A～E 核心分项自身得分率均 ≥90%；
- 一票否决项全部通过。

不能使用加权平均让黄金 fixture 的高分抵消量产场景低分。例如 G=98、P=88 时，最终分
只能记 88，不能记 93 或 95。

### 1.2 黄金帧评分表 G

沿用样板复刻批的五维量表，避免换表抬分：

| 分项 | 权重 | 当前 | 95 分最低目标 | 主要证据 |
|---|---:|---:|---:|---|
| G1 结构与比例 | 25 | 23 | 24 | 三段边界、人物/案台锚点、控制区 |
| G2 色彩基调 | 20 | 15 | 19 | 分区 RGB、明度、饱和度、语义色面积 |
| G3 人物构图 | 20 | 15 | 19 | 六人动作轮廓、大小、站位、接地、Boss 层级 |
| G4 案台内容 | 20 | 17 | 19 | 名帖、七签、顺序、朱印、耗气、行囊 |
| G5 材质与字形 | 15 | 11 | 14 | 纸纹、笔触、血条、蓄势、字体和时代感 |
| **合计** | **100** | **81** | **95** | — |

满分不要求抗锯齿逐像素一致，但必须满足结构、视觉层级、材质语言和人物轮廓高度一致。

### 1.3 生产泛化评分表 P

| 分项 | 权重 | 当前 | 95 分最低目标 | 核心判断 |
|---|---:|---:|---:|---|
| P1 结构与响应式 | 20 | 17 | 19 | 1280/1440/1672 同一视觉语言，1v1～3v3 不漂移 |
| P2 场景与人物融合 | 25 | 16 | 24 | 暖/冷/浅/深背景中立绘都不浮贴、不糊黑 |
| P3 案台与信息密度 | 20 | 14 | 19 | 一招六空签、七招、自动轮转都像完成品 |
| P4 HUD 与材质统一 | 15 | 9 | 14 | 血条、真气、蓄势、状态牌均水墨化且可读 |
| P5 动态状态一致性 | 10 | 7 | 9 | 冷却、气不足、待发、破招、暂停、快进、结算 |
| P6 桌面交互与稳定性 | 10 | 9 | 10 | semantics、键盘、focus、cursor、无 overflow/异常 |
| **合计** | **100** | **72** | **95** | — |

### 1.4 计分规则

每个子项按以下三级记分：

- 全部满足：100% 分值；
- 部分满足：50% 分值，必须列出差距与证据；
- 不满足：0 分；
- 不允许用“已有测试”“代码看起来正确”替代原生窗口截图和母版对照；
- 不允许由实现者一人完成最终人工评分。实现者可自评，Codex 复核，最终两张主对照图由
  用户终拍；有争议时不取平均，取较低分或继续修复。

### 1.5 一票否决项

以下任一项失败，最终分最高记 94：

1. reference 缺失或 SHA-256 不一致；
2. 只对 `battle_tap_live` 黄金 fixture 达标，生产矩阵未达标；
3. 1280×720 或 1440×900 出现 overflow、遮挡、裁切或视觉换皮断层；
4. 人物脸、主武器、血条或 Boss 关键轮廓被 HUD 遮挡；
5. 为截图伪造生产存档、战斗数值、技能装配、蓄势或行囊状态；
6. 修改伤害、真气、冷却、AI、tick、胜负、掉落、存档 schema/saveVersion；
7. 核心按钮丢失 semantics、键盘激活、focus、tooltip 或 mouse cursor；
8. 新增 Material 默认饱和色、教程弹窗或散落中文/数值硬编码；
9. 只通过 widget 渲染器截图，没有至少一轮原生 macOS 窗口抓图；
10. Windows 字体/缩放没有在发布前补一次实机验收。

---

## 2. 当前基线证据

### 2.1 本轮截图

截图位于 Git 忽略目录，仅作为本机修复基线，不提交仓库：

- 黄金三视口：`build/visual_acceptance/review_20260801/battle_tap_live/`
- 主线：`battle_audit_stage_01_03/`
- 塔：`battle_audit_tower_14/`
- 群战：`battle_audit_stage_mass_battle_01/`
- 左右并排：`build/visual_acceptance/review_20260801/sample_vs_current_1672.png`

当前 1672×941 黄金帧 SHA-256：
`0ed5d1ea2d6c5cc19057943dffeeffa678827453c3c7b0bc0cfcb24bd751bdb7`。

三档黄金截图和六张生产截图全部包含 `VISUAL_ROUTE_READY` 与原生 `window_id`，日志未发现
`VISUAL_ROUTE_ERROR`、`Exception`、`RenderFlex` 或 overflow。

### 2.2 当前图像量测

Retina 2× 截图先用 Lanczos 缩回 1672×941，再按母版边界 y=60 / y=700 分区：

| 区域 | 当前减母版平均 RGB | MAE | 边缘 IoU | 判断 |
|---|---|---:|---:|---|
| 顶栏 | (+0.60, +0.43, -0.07) | 10.13 | 0.194 | 色阶近，按钮/文字轮廓仍不同 |
| 战场 | (+7.25, +8.51, +10.27) | 28.44 | 0.107 | 明显偏亮、偏冷、轮廓差距最大 |
| 案台 | (-0.85, +0.06, -0.36) | 15.51 | 0.140 | 均色近，但纸签/字形/器物边缘不同 |
| 全屏 | (+4.75, +5.83, +6.89) | 23.96 | 0.113 | 不支持“整体约 ±4”结论 |

这些指标只用于定位和防回退，不直接换算人工得分。平均 RGB 接近不能证明材质和人物轮廓接近；
边缘 IoU 也不能单独惩罚纸纹抗锯齿差异。

### 2.3 已验证工程基线

- `flutter analyze --no-pub`：0 issue；
- 战斗案台、布局、舞台、人物、背景、行囊和路由定向测试：151/151 通过；
- 当前 HEAD 全量实测：4792 pass / 0 fail；
- 当前 battle visual acceptance suite：79 条 route（73 动态战斗 + 6 确定性素材/状态）；
- `5a649ea3..acc31ee8` 的 `lib/` 改动仅新增于 `lib/features/debug/`；当前 HEAD 重抓的
  1672×941 黄金 PNG 与旧基线 SHA-256、逐字节 `cmp` 均一致，因此 81/72 视觉基线无需重算；
- 主工作树审查时存在此前报告的未跟踪副本，截图和本轮 triage 证据只写入忽略的 `build/`。

工程稳定性不是本轮主要问题；本轮应把精力集中到视觉一致性与验收可信度。

---

## 3. 根因分析

### R1 · 还原度工具没有 reference/current 比较闭环

`tools/visual_capture/analyze_battle_v2_fidelity.py` 当前擅长记录 viewport、DPR、seed、tick、
区域和诊断层，但不会读取唯一母版并输出 reference/current 的结构或感知差异。历史评分因而主要依赖：

- 硬编码几何断言；
- 分区平均 RGB；
- 实现者人工目检；
- READY、无溢出和 widget 测试。

这些证据能证明“组件稳定”，不能证明“视觉已经 95% 相似”。

### R2 · 黄金 fixture 过度代表生产质量

`battle_tap_live` 固定使用：

- 样板专用凌风、隐世老者、山贼刀客、山贼弓手立绘；
- 七张样板招式签；
- 固定蓄势 2 拍；
- 两件预览行囊物件和固定数量；
- 专用人物横纵比、脚底 fraction 和光学校准。

真实早期主线、塔和群战常见的是一张技能签、六张暗空签与三格空行囊。黄金路由适合做
母版像素级复刻，但不能替代生产矩阵。

### R3 · 战场 HUD 仍使用通用矩形语法

- `DangerBar` 以四段 `LinearGradient` 形成平滑红条，缺少母版的朱砂干笔、破边和纸面渗色；
- `BeatCountdownRing` 在 Boss 头顶形成醒目红色数字圆环，母版没有同等权重元素；
- `HpBar` 是圆角 2px 的平直实心色条，文字使用较粗 UI 字重；
- 状态签虽加墨染，但资源条本身仍把人物切成“立绘 + 现代 HUD”两层。

### R4 · 1280×720 使用二元换皮而非连续响应式

`SkillCommandButton`、`BattleSkillSlipSurface`、`BattlePouchRail` 等组件通过
`height >= 190` 决定 `expandedSampleStyle`。跨过阈值后同时改变：

- 朱印实填 / 浅描边；
- 纸签标题与朱印布局；
- 字号和耗气旋纹；
- 页脚高度和边距；
- 行囊标题、槽位、底牌尺寸。

这使 1280×720 虽不溢出，却像另一套低配皮肤。

### R5 · 人物与场景融合对素材分布过敏

生产立绘来源、明度、锐度和透明画布留白不一。当前已有背景明度自适应和逐资产脚底/光学 profile，
但仍存在：

- 暖山道中人物较照片化、平滑；
- 冷塔背景中部分人物像贴在浅灰画布上；
- 深色背景中个别立绘易糊黑；
- 1v1、2v2、3v3 的人物视觉面积不够稳定；
- 样板专用资产得到精细校准，量产资产只得到通用档。

### R6 · 案台均色接近，但局部材质与信息权重仍偏现代

当前案台平均 RGB 已接近母版，但仍有：

- 技能纸张偏亮、偏干净，纤维和旧污层次不足；
- 耗气旋纹与数字偏大、偏粗、偏青蓝；
- 人物名帖文字比母版更粗更亮；
- 行囊格仍有 inventory slot 的方框感；
- 一招六空签时，案台大面积像灰暗占位列表而非未题字卷案。

---

## 4. 修复范围与红线

### 4.1 允许修改

- `lib/features/battle/presentation/` 下纯表现层 Widget、Painter、布局 token；
- `lib/shared/theme/` 中战斗专用颜色、材质、字体 token；
- `lib/features/debug/` 下 visual route、诊断层和固定验收 fixture；
- `tools/visual_capture/` 下只读图像分析和报告生成工具；
- 相关 widget、布局、视觉路由、语义和资产守卫测试；
- 必要时新增少量可复用的笔刷 mask、纸纹或墨边资产，但需先做一张样板再批量接线。

### 4.2 禁止修改

- 战斗伤害、永久内力、真气循环、技能倍率、冷却规则、AI、tick、胜负、掉落；
- `data/numbers.yaml`、`data/skills.yaml` 和角色/敌人数值；
- Isar schema、saveVersion、迁移和存档内容；
- 在线=离线、三系锁死和任何 GDD 红线；
- 为追样板新增 Boss 技能预兆图标；该方向在已否任务清单中明确排除；
- 药品行囊自动补位；该方向同样已否；
- 不得为了统一观感给 `battle_audit_gauntlet_*` 注入生产入口没有的场景背景；若未来要给断魂庄
  增加场景美术，必须先作为内容层决策修改真实 `gauntlet_entry_flow`，不属于本轮视觉修复；
- 教程弹窗、高饱和 Material 色或新的网游式稀有度光效；
- 全量重做 79+ 立绘；只允许对明确不达标的代表资产做局部返修或校准。

### 4.3 样板专用资产纪律

样板专用资产可以继续用于黄金帧 G 分，但必须遵守：

- 不计入生产泛化 P 分；
- 不得把专用资产的 profile 当作量产人物已改善的证据；
- production path 默认不得注入预览行囊或伪造七招；
- 最终报告要单列样板专用资产体积与发布包影响；
- 若决定把某张样板资产升级为正式资产，必须改为生产数据真正消费并补全跨场景验收。

---

## 5. 分区修复方案

### 5.1 P0 · 建立可信的 95 分验收工具

#### 修改目标

扩展 `analyze_battle_v2_fidelity.py`，或新增同目录专用模块，使其显式读取：

- 唯一 reference 路径与 SHA-256；
- 当前 1672×941 黄金截图；
- 顶栏 / 战场 / 案台区域；
- 可选诊断层：人物、HUD、技能签、语义色、文字；
- 当前 commit、DPR、route、seed、tick 和原生窗口 ID。

#### 必须输出

1. `fidelity_manifest.json`：输入文件、哈希、视口、route、seed、tick；
2. `fidelity_metrics.json`：分区 RGB、LAB、MAE、边缘 IoU、结构锚点；
3. `fidelity_report.md`：机器指标和人工评分表，不自动把指标合成神秘总分；
4. `diff_full.png`：全屏绝对差异热图；
5. `diff_header.png`、`diff_field.png`、`diff_desk.png`；
6. reference/current 左右并排图；
7. 所有 mask 和阈值配置，保证结果可复核。

#### 建议机器门槛

机器门槛只做防回退，不能单独宣称 95：

| 指标 | 当前 | 目标上/下限 |
|---|---:|---:|
| 顶栏三通道平均差绝对值 | 最大 0.60 | ≤3.0 |
| 战场三通道平均差绝对值 | 最大 10.27 | ≤4.0 |
| 案台三通道平均差绝对值 | 最大 0.85 | ≤3.0 |
| 顶栏 MAE | 10.13 | ≤12 |
| 战场 MAE | 28.44 | ≤22 |
| 案台 MAE | 15.51 | ≤14 |
| 顶栏边缘 IoU | 0.194 | ≥0.22 |
| 战场边缘 IoU | 0.107 | ≥0.12 |
| 案台边缘 IoU | 0.140 | ≥0.18 |
| 顶栏底线 / 案台顶线误差 | ≤1px | ≤1px |

阈值必须先对 reference 自校验：reference 对自身应得到 RGB/MAE 0、IoU 1.0；对一次 PNG
无损复制也必须相同。对 Retina 2× 缩回 1× 的自校验允许记录抗锯齿误差，但不得修改阈值掩盖错误。

#### 验收

- 破坏 reference 哈希后工具必须失败；
- 交换错误 route 后必须失败；
- 修改 y=700 边界后结构门禁必须报错；
- 不提供诊断层时明确写 approximate/unavailable，不伪报精确值；
- 工具单元测试覆盖输入发现、DPR、哈希、区域、阈值和报告生成。

### 5.2 P0 · 蓄势横幅与 Boss 倒数去现代化

#### 当前问题

母版是暗绛朱砂干笔短签；当前是柔和透明渐变横条，并叠加独立红色数字圆环。

#### 修复要求

- `DangerBar` 保持现有 Semantics 和选取最临近蓄势敌人的逻辑，只替换视觉层；
- 使用确定性 `CustomPainter` 或小型笔刷 mask 画出：左右破边、中央重墨、上下渗色、少量刮痕；
- 蓄势文字与拍数保持一行，整体宽度和锚点贴母版；
- Boss 头顶 34px 红色数字环不得继续成为第二警示中心；顶部横幅继续只显示最临近发动的一名敌人，
  每名蓄势角色旁则保留不抢脸部的暗绛小印/角标，逐人显示剩余拍数；
- 不新增“Boss 技能预兆图标”，不改变蓄势规则；
- 1280/1440/1672 同一材质，只允许等比缩放。

#### 目标文件

- `lib/features/battle/presentation/widgets/battle_banners.dart`
- `lib/features/battle/presentation/character_avatar.dart`
- `lib/shared/theme/wuxia_tokens.dart`
- `test/features/battle/presentation/battle_command_console_test.dart`
- `test/features/battle/presentation/character_avatar_test.dart`

#### 视觉 Gate

- 与 Boss 发髻、脸部和气韵线零相交；
- 红色面积不高于母版同区域的 1.15 倍；
- 50% 灰阶缩略时，Boss 人物仍先于横幅被看到；
- 三视口的横幅轮廓只缩放、不换皮。
- 双敌乃至三敌同时蓄势时，每名敌人的蓄势身份与剩余拍数均可辨；顶部横幅仍保持单主警示，
  不复制成多条横幅。

### 5.3 P0 · 人物状态条水墨化

#### 当前问题

墨染背景已经透明化，但内部 `HpBar` 仍是平直实心矩形，绛红和青灰色块饱和度高，数字粗重。

#### 修复要求

- 直接修改 `HpBar` 本体的战斗视觉；全仓 `lib/` 仅有 4 个真实构造点，均位于
  `character_avatar.dart`，无需再增加无调用者的战场专用分支；
- 血量轨道改为墨拓断边，填充仍须清楚表达比例；
- 气/真气条使用低饱和青灰，避免 Material 蓝；
- 数字字重从“压住色条”改为“落在墨牌上”，但 1280×720 仍可读；
- 姓名、Boss「势」印、血条、气条形成一个有机窄条，不是四层独立 Widget；
- 保留五位数/六位数的可读和压缩策略，不改真实数值；
- 死亡、重伤、护法结界等状态仍能区分。

#### 目标文件

- `lib/features/battle/presentation/character_avatar.dart`
- `lib/features/battle/presentation/hp_bar.dart`
- `lib/features/battle/presentation/battle_layout_tokens.dart`
- `lib/shared/theme/wuxia_tokens.dart`

#### 视觉 Gate

- 母版 1672 对照中状态条宽、高、纵向位置误差 ≤2px；
- 1280 下四位、五位、六位数均不裁切；
- 状态条不得成为人物之后的第二视觉主体；
- 小字对直接底色对比度 ≥4.5:1。

### 5.4 P1 · 统一三视口的技能签视觉语言

#### 当前问题

`expandedSampleStyle = height >= 190` 造成实填朱印/描边朱印、固定布局/紧凑布局之间的突然切换。

#### 修复要求

- 用连续 `styleProgress` 取代二元换皮，例如由实际签高在目标区间内归一化到 0～1；
- 纸色、朱印填色、墨边、纸纹和字体家族在三视口保持不变；
- 只连续缩放字号、间距、旋纹、页脚和朱印尺寸；
- 1280 下仍使用暗绛实印，不回退成浅红描边印；
- 朱印、冷却墨洗、待发印和耗气脚线保持互不相交；
- 冷却、真气不足、待发、破招和自动执招不得改变签体宽高；
- 纸签亮度比当前略压暗，增加低频旧污、纤维和边缘缺口，避免新打印卡片感；
- 耗气旋纹和数字降低视觉权重，字号/字重更贴母版。

#### 目标文件

- `lib/features/battle/presentation/widgets/battle_bottom_bar.dart`
- `lib/features/battle/presentation/widgets/battle_skill_slip.dart`
- `lib/features/battle/presentation/battle_layout_tokens.dart`
- `lib/shared/theme/wuxia_tokens.dart`

#### 视觉 Gate

- 三视口并排时可判断为同一组件的等比响应，不是三套皮肤；
- 1280/1440/1672 的朱印填色和墨边语义一致；
- 七签齐底、无 overflow、无标题/朱印/脚线相交；
- 空签和真签共享纸张家族，但空签退后且不伪装按钮。

### 5.5 P1 · 一招六空签与空行囊成为完成态

#### 当前问题

黄金路由七签、两件行囊很丰富；生产早期关卡却常出现一招六空签和三格空行囊，底部约四分之三
区域长期缺少有效内容，读感更像开发占位。

#### 修复要求

- 保持稳定七槽，不改变技能装配规则；
- 空签继续不可点击、不可伪装技能，但应像“未题字的旧签”而非灰色 disabled 卡；
- 空签可使用低权重纸纹、淡墨空印和细微高低错落，禁止大字说明或教程；
- 有且仅有一张真实技能时，它应成为明确主签，其他空签整体后退；
- 空行囊保持真实状态，不注入假道具；木匣、锦格和空印本身要有器物完成度；
- 自动观战轮转继续使用同一案台骨架，不回退到普通工具栏。

#### 生产 Gate

- `battle_audit_stage_01_03` 的一招六空签画面达到 P3 ≥19/20；
- 5 秒内能指出唯一可用招式，同时不会误认为其他六签可点；
- 三个空行囊格读作真实空态，而不是资源加载失败；
- 不实现药品自动补位，不引入伪状态。

### 5.6 P1 · 人物与场景融合泛化

#### 修复要求

- 以生产资产而非样板专用资产建立代表集；
- 至少覆盖暖亮、暖暗、冷亮、冷暗四类背景；
- 逐类量测人物 mask 的暗部 P05、平均饱和度、边缘锐度和接地误差；
- 背景明度自适应继续只做表现层，不改角色数据；
- 通用 profile 先解决 80% 资产，只有明确异常资产才登记局部 profile；
- 避免继续为 debug sample path 增加生产组件分支；
- Boss 气韵、接触影和人物本体不得在浅背景形成矩形光晕；
- 人物不能因暗场景全部糊成黑块，也不能因亮场景像贴纸。

#### 代表场景

| 类型 | 路由 | 核心检查 |
|---|---|---|
| 暖亮标准 | `battle_tap_live` | 母版构图与色阶 |
| 暖亮生产 | `battle_audit_stage_01_03` | 一招六空签、3v1 |
| 冷亮生产 | `battle_audit_tower_14` | 立绘浮贴、浅灰背景 |
| 群战生产 | `battle_audit_stage_mass_battle_01` | 3v3 密度和远近层级 |
| 心魔暗场 | `battle_inner_demon_stage` | 暗部不糊、反相气韵 |
| 轻功错层 | `battle_light_foot_stage` | 上下错层和状态牌 |
| 护法结界 | `battle_guardian_ward` | Boss 气韵、多个状态 tag |
| 纯程序化背景 | `battle_audit_gauntlet_02` | 无场景美术下的接地、景深、暗部融合、护法结界 tag 与 3v3 密度 |

#### 视觉 Gate

- 同一人物跨四类背景的 mask 暗部漂移进入既有目标带；
- 接地误差 ≤人物视觉高度 2%；
- Boss 有压迫感但不靠大面积金光或矩形底板；
- 人物脸和主武器在所有代表场景可辨；
- 零场景美术背景下不得出现矩形光晕、明显贴纸边或失去接地；该路由是独立第五类覆盖，
  但不预设它一定比冷亮塔景更容易暴露浮贴，以实际并排图为准；
- 样板资产全删出评分后，生产 P2 仍 ≥24/25。

### 5.7 P2 · 顶栏、字体与按钮精修

顶栏目前是还原度最高的区域，只做收口：

- 保持标题、中央“战斗 3v3”和五个章钮的现有几何；
- 校准字距、笔画粗细、按钮内圈与母版边缘；
- 按钮 hover/focus 不使用明亮 Material 光晕；
- tooltip、Tab 顺序、Enter/Space 激活补原生窗口直证；
- 暂停/继续、日志、撤退/单步文案变化不得改变按钮直径和间距；
- 1280 下标题和控制区不争抢中央标题。

### 5.8 P2 · 动态状态统一

必须覆盖：

- 可用；
- 冷却；
- 真气不足；
- 待发与选目标；
- 破招高亮；
- 自动轮转第一/第二角色；
- 暂停/继续；
- 快进峰值；
- 伤害飘字与暴击；
- 结算前最后一击和结算层。

动态状态只改变状态墨层、数字和必要提示，不改变签宽、签高、人物站位或案台分区。

---

## 6. 文件级实施矩阵

| 文件/区域 | 计划改动 | 必测内容 | 风险 |
|---|---|---|---|
| `tools/visual_capture/analyze_battle_v2_fidelity.py` | 加 reference 比较、热图、指标报告 | 哈希、DPR、自校验、错误 route | 工具给出虚假精确分 |
| `battle_banners.dart` | 朱砂干笔蓄势短签 | 三视口、Semantics、Boss 不相交 | 警示变得不可读 |
| `character_avatar.dart` | 倒数降权、状态条、融合/接地收口 | 1v1/2v2/3v3、Boss、暗亮场景 | 热点文件、资产 profile 多 |
| `hp_bar.dart` | 直接水墨化轨道、填充与数字层 | 4 个生产调用点、四至六位数、HP/真气 | 可读性与压缩策略回归 |
| `battle_bottom_bar.dart` | 连续响应、名帖、空签、行囊 | 三视口、五技能态、语义 | 文件大、交互热点 |
| `battle_skill_slip.dart` | 纸张、墨洗、金线、连续尺寸 | 冷却/气不足/待发/破招 | painter 复杂度和性能 |
| `battle_layout_tokens.dart` / metrics | 三段与连续尺寸 token | 1280/1440/1672 几何 | 小窗回归 |
| `battle_scene_background.dart` | 场景色阶与纸纹收口 | 暖/冷/浅/深场景 | 全战斗场景波及 |
| `battle_standee_fusion.dart` | 代表集复校和边界保护 | 生产资产四象限 | 过拟合样板 |
| `wuxia_tokens.dart` | 战斗专用色/材质 token | 禁散写颜色、对比度 | token 波及范围 |
| `visual_route_host.dart` | 诊断层、生产矩阵 manifest | fixture/production 明确标注 | debug 状态误当生产 |
| `test/features/debug/visual_route_test.dart` | 守 audit 路由生产透传 | gauntlet 背景必须 null、BGM boss、三视口构造 | 误把生产 null 背景当缺陷 |
| `test/features/debug/visual_acceptance_gauntlet_coverage_test.dart` | 守断魂庄三关覆盖 | 3 条 route、敌队并集、阵列规模 | route 清单与生产配置漂移 |

热点文件必须串行修改，禁止多个分支同时改 `character_avatar.dart` 或
`battle_bottom_bar.dart`。

---

## 7. 实施阶段与恢复点

### 阶段 0 · 基线和工具可信化

交付：

- 锁 reference 哈希；
- 新黄金三视口截图；
- reference/current 报告、热图、并排图；
- 机器指标自校验与破坏证红；
- 报告中的当前分由工具证据重算。

Gate：工具不能比较 reference 时，不进入视觉修改。

### 阶段 1 · 战场公共 HUD

交付：

- 蓄势干笔短签；
- Boss 数字环降权或并入横幅；
- 人物姓名/血量/气条水墨化；
- 黄金三视口与 Boss/塔生产截图。

目标：G5 11→13+，P4 9→12+，总分至少提升 5 分。

### 阶段 2 · 案台与响应式

交付：

- 移除 `height >= 190` 视觉换皮；
- 三视口连续响应；
- 纸签、朱印、耗气脚线材质收口；
- 一招六空签和空行囊完成态。

目标：G4 17→19、G5 ≥14；P1 ≥19、P3 ≥19。

### 阶段 3 · 人物与场景泛化

交付：

- 暖/冷/浅/深四类场景代表集；
- 纯程序化断魂庄第五类场景；
- 生产人物融合指标和截图；
- 各代表路由保留修复前截图与 SHA-256，阶段末输出同路由 before/after；比较必须按人物/HUD/背景
  ROI 或允许变化 mask 分区，不能把本轮有意修改的公共 HUD 要求成全屏“变化像素 0”；
- 少量异常资产 profile 或局部返修；
- 样板专用人物从 P 分证据中剔除。

目标：G2 ≥19、G3 ≥19；P2 ≥24。

Gate：全战场 MAE 与边缘 IoU 只能防整体回退，不能单独证明 G3 从 15→19。人物 bbox、面积比、
脚底和 mask 指标可作为客观辅证；最终 G3 分仍须 Codex 独立人工评分，并由用户终拍主图。

### 阶段 4 · 动态状态和桌面语义

交付：

- 资源压力、待发、破招、自动轮转、暂停、快进、结算截图；
- Tab/tooltip/Enter/Space/focus/cursor 原生窗口直证；
- 不同状态不改布局几何的测试。

目标：P5 ≥9、P6=10。

### 阶段 5 · 95 分终验

交付：

- 黄金 G 评分包；
- 生产 P 评分包；
- 全部截图 manifest、日志、热图、量测 JSON；
- 实现者自评与 Codex 复核表；
- 用户终拍的黄金 3v3 和代表生产 Boss 两张主图；
- `flutter analyze`、targeted、全量测试结果；
- Windows 发布前实机残留风险。

只有 `min(G, P) ≥95` 才能标记完成。

---

## 8. 最终截图矩阵

### 8.1 黄金矩阵

| 路由 | 1280×720 | 1440×900 | 1672×941 | 用途 |
|---|---:|---:|---:|---|
| `battle_tap_live` | 必拍 | 必拍 | 必拍 | 母版主对照、七签、蓄势、行囊 |
| `battle_tap_preview` | 必拍 | 必拍 | 选拍 | 待发、选目标 |
| `battle_v2_resource_pressure` | 必拍 | 必拍 | 选拍 | 冷却、气不足 |
| `battle_v2_auto_rotation_first` | 选拍 | 必拍 | 选拍 | 自动第一角色 |
| `battle_v2_auto_rotation_second` | 选拍 | 必拍 | 选拍 | 自动第二角色 |

### 8.2 生产矩阵

| 路由 | 1280×720 | 1440×900 | 核心状态 |
|---|---:|---:|---|
| `battle_audit_stage_01_03` | 必拍 | 必拍 | 真实主线 3v1、一招六空签、空行囊 |
| `battle_audit_tower_14` | 必拍 | 必拍 | 真实塔 3v2、冷亮背景 |
| `battle_audit_stage_mass_battle_01` | 必拍 | 必拍 | 真实群战 3v3、人物密度 |
| `battle_audit_gauntlet_02` | 必拍 | 必拍 | 纯程序化背景、3v3、护法结界与接地 |
| `battle_inner_demon_stage` | 必拍 | 必拍 | 暗场景与反相人物 |
| `battle_light_foot_stage` | 必拍 | 必拍 | 轻功上下错层 |
| `battle_guardian_ward` | 必拍 | 必拍 | Boss 气韵与多状态 |
| `battle_v2_fast_forward_peak` | 选拍 | 必拍 | 快进动态峰值 |
| `battle_v2_pre_result` | 选拍 | 必拍 | 结算前最后一击 |

### 8.3 截图规范

- 使用当前 commit 新编译的 macOS debug app；
- 用 `VISUAL_WINDOW_W/H` 锁逻辑窗口尺寸；
- 通过 CGWindowID 截游戏内容，不截桌面、阴影或鼠标；
- 日志必须有 READY、route、seed/tick（动态路由）、window ID；
- 同一路由连续两次状态摘要一致；
- Retina 图精确缩回 1× 后量测；
- 截图和日志放 `build/visual_acceptance/battle_sample_95/`，不提交 Git；
- 最终 report 可记录哈希和相对路径，但不得把唯一证据留在即将删除的 worktree。

---

## 9. 测试与验证命令

实施过程中按切片跑 targeted，批末再全量；不在每个小改后无脑跑全量。

### 9.1 Targeted

```bash
flutter test --no-pub \
  test/features/battle/presentation/battle_command_console_test.dart \
  test/features/battle/presentation/battle_layout_metrics_test.dart \
  test/features/battle/presentation/battle_stage_geometry_test.dart \
  test/features/battle/presentation/character_avatar_test.dart \
  test/features/battle/presentation/battle_scene_background_test.dart \
  test/features/battle/presentation/battle_pouch_rail_test.dart \
  test/features/debug/visual_route_test.dart \
  test/features/debug/visual_acceptance_gauntlet_coverage_test.dart
```

按实际修改补充：

- `battle_screen_pause_test.dart`
- `battle_tap_skill_test.dart`
- `battle_mode_pill_test.dart`
- `test/tools/desktop_semantics_audit_test.dart`
- 新增的 fidelity analyzer Python 单测。

### 9.2 静态与格式

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
git diff --check
```

### 9.3 批末全量

```bash
flutter test --no-pub
```

### 9.4 原生窗口视觉捕获

```bash
tools/visual_capture/visual_capture.sh \
  --route battle_tap_live \
  --resolutions 1280x720,1440x900,1672x941 \
  --output build/visual_acceptance/battle_sample_95 \
  --wait 2 \
  --ready-timeout 180
```

其他路由沿截图矩阵逐项执行。

---

## 10. CLAUDE.md §8.2 交付清单

### 10.1 生产接线证据

- [ ] 改动由真实 `BattleScreen`、`BattleField`、`CharacterAvatar`、`BottomBar` 消费；
- [ ] 不停在 gallery、fixture 或孤立 painter；
- [ ] 样板 route 与 production route 在评分包中明确区分；
- [ ] 真实一招六空签、真实空行囊、真实 3v1/3v2/3v3 均有截图。

### 10.2 Targeted test

- [ ] 直接相关测试命令与通过数记录；
- [ ] 新视觉工具有单测和破坏证红；
- [ ] 三视口几何、状态互不相交和响应式连续性有断言；
- [ ] Semantics、键盘、focus、cursor 不回退。

### 10.3 红线影响

- [ ] 伤害/血量/真气/AI/tick/掉落零改；
- [ ] 三系锁死零改；
- [ ] 在线=离线零改；
- [ ] schema/saveVersion 零改；
- [ ] 无散落中文、数值和颜色魔数；
- [ ] 无 Material 默认饱和色和教程弹窗。

### 10.4 残留风险

- [ ] Windows 字体栅格和缩放是否已验；
- [ ] 高频 painter 的重绘与 GPU 负载；
- [ ] 暗场景人物是否糊黑；
- [ ] 浅场景人物是否浮贴；
- [ ] 样板专用资产发布包体积；
- [ ] 动态峰值帧是否真实，而非 READY 前后冻结态。

### 10.5 清洁度

- [ ] 无截图、日志、热图、临时 mask 被提交；
- [ ] 无 `.g.dart` 或构建产物误提交；
- [ ] worktree 干净，全部改动已 commit；
- [ ] tip 以 `[READY]` 开头再交合并审核；
- [ ] commit message 使用中文动宾结构。

---

## 11. 风险与应对

| 风险 | 预警信号 | 应对 |
|---|---|---|
| 为追 95 继续过拟合黄金人物 | sample path 分支持续增加 | P 分剔除 sample 资产，生产矩阵独立计分 |
| 机器指标被当成最终分 | report 只输出一个数字 | 输出原始指标、mask、热图和人工表，不生成黑盒分 |
| 血条水墨化后不可读 | 1280 五/六位数糊成一块 | 保留对比度与 tabular figures，先可读再材质 |
| painter 过重 | 战斗中掉帧、repaint 扩散 | 尽量确定性静态 painter，检查 repaint boundary |
| `HpBar` 可读性回归 | 1280 下四至六位数裁切，或 HP/真气层级混淆 | 4 个生产调用点直改，配套数值长度与两种资源条测试 |
| 1280 再次变成另一套皮 | 新增更多 breakpoint bool | 只用连续插值，样式语义不切换 |
| 生产空态仍像占位 | 只验七招黄金路由 | 强制 `stage_01_03` 为 P3 Gate |
| 暗/亮场景调一头坏一头 | 单一 opacity 常量反复摆动 | 四象限代表集 + 自适应边界 + 少量异常登记 |
| 截图随 worktree 删除 | 证据只在分支 build 目录 | 终验前复制到主 checkout 忽略目录并记录哈希 |
| Windows 与 Mac 字体差异 | ship 前才发现换行/裁切 | 发布前补 Windows 100%/125%/150% 缩放抽验 |

---

## 12. 95 分退出条件

全部满足后才能把状态改为“已完成”：

- [ ] 黄金 G ≥95；
- [ ] 生产 P ≥95；
- [ ] 最终 F=min(G,P) ≥95；
- [ ] G1～G5、P1～P6 均达到各自最低目标；
- [ ] 一票否决项 10/10 通过；
- [ ] 黄金三视口 3/3 READY、原生窗口截图成功；
- [ ] 生产矩阵必拍项全部 READY；
- [ ] reference 哈希一致；
- [ ] 机器门槛全部通过；
- [ ] 实现者自评与 Codex 复核均附逐项证据；
- [ ] 用户终拍黄金 3v3 与代表生产 Boss；
- [ ] targeted、analyze、format、diff check、批末全量全部通过；
- [ ] 无数值、存档、交互语义和性能回归；
- [ ] 残留风险只允许 Windows 发布前实机项，且已明确负责人和再开条件。

若总分为 94 或任一核心分项低于目标，不得以“四舍五入”“整体观感不错”或“测试全绿”改写为
95；继续修复差距最大的分项。

---

## 13. 实施优先级结论

推荐顺序固定为：

1. **先修验收工具**，阻止再次虚高评分；
2. **再修蓄势、数字环和人物状态条**，这是黄金与生产共同最大 HUD 偏差；
3. **消除 1280 换皮断层**，统一技能签、朱印、耗气和行囊；
4. **修一招六空签完成度**，让生产常态不再明显低于黄金 fixture；
5. **按四类场景校准人物融合**，生产资产独立达到 95；
6. **补动态状态与桌面直证**；
7. **最后才做边缘像素、字距和纸纹微调**。

按当前差距，单纯继续调 RGB、坐标或样板专用人物无法稳定达到 95。必须同时修复验收方法、
公共 HUD、响应式与生产泛化四个层面。

---

## 14. 读者自检

本报告交给新的实现者时，应能直接回答：

1. 当前为何不是 98 分，而是黄金 81、生产 72？
2. 95 分由哪两套量表组成，最终分如何计算？
3. 哪些修改会触碰项目红线，明确禁止？
4. 第一批应该改什么文件，为什么不能先调人物坐标？
5. 如何证明生产常态不是靠黄金 fixture 代替？
6. 1280×720 为什么会出现不同朱印风格，修法是什么？
7. 机器指标如何使用，为什么不能直接输出黑盒总分？
8. 需要抓哪些路由、哪些视口、哪些动态状态？
9. 哪些测试和原生窗口证据是合并前必须项？
10. 什么条件下可以诚实地宣布“95+ 已完成”？

若实现者无法从本文直接回答任一问题，应先补文档或提出阻塞，不应开始大范围修改。


---

# 附录 A · Claude 复核修订意见（2026-08-01）

> 复核者：Claude（Opus 5）· 复核代码态 `main@acc31ee8`（报告基线为 `main@5a649ea3`，其后有 5 个 commit）
> 复核方式：全文通读 + 逐条现查代码/文件/哈希，**不采信报告自述**
> 结论：**主体可行，建议按下列 5 条修订后开工**。3 条为「必须」（其中 2 条推翻了原报告的设计前提），2 条为「建议」。

## A.0 先说结论：原报告哪些部分我复核后确认无误

以下均为本次现查实证，Codex 复核时可直接复用：

| 核对项 | 结果 |
|---|---|
| 母版 SHA-256 `fe5c8e8d…f5957` | ✅ 与 `docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png` 逐字符吻合 |
| 母版规格 1672×941 | ✅ PIL 实测 `(1672, 941)` |
| 当前黄金帧 SHA-256 `0ed5d1ea…1bdb7` | ✅ 与 `build/visual_acceptance/review_20260801/battle_tap_live/1672x941/` 实际产物吻合 |
| §2.1 基线证据目录 | ✅ 真实存在，9 张生产截图 + 并排图俱全，未随 worktree 蒸发 |
| R4 `height >= 190` 二元换皮 | ✅ 实在 `battle_bottom_bar.dart:642` `final expandedSampleStyle = (height ?? 0) >= 190;` |
| §6 文件级矩阵的 9 个目标文件 | ✅ 全部存在 |
| §8 截图矩阵的 10 个 route id | ✅ 全部在 `visual_route.dart` 真实存在，无臆造 |
| `--resolutions 1672x941` 可用性 | ✅ `visual_capture.sh:338` 是自由 CSV 解析，非枚举白名单 |
| 81 / 72 基线可信度 | ✅ 我独立看了 `sample_vs_current_1672.png`：当前版偏冷、丢前景层次、人物偏小偏散、蓄势横幅更亮且多一个红圈、血条更饱和；而顶栏/案台/技能签确已接近。**与报告的分项打分方向一致** |

报告的评分纪律（取低值不取平均、一票否决、机器指标不合成黑盒分）我认为是本项目迄今最严谨的一份验收框架，**建议保留不动**。

---

## A.1【必须 · 推翻前提】§5.3 的「战场专用样式」是不必要的间接层

**原文主张**（§5.3 修复要求第 1 条 + §11 风险表）：
> 「不全局改通用 `HpBar` 的所有页面；增加战场专用样式或战场专用 painter」
> 风险「全局 `HpBar` 回归 → 角色面板/详情页视觉变化 → 使用战场专用样式，不改默认值」

**现查证伪**：`HpBar` 在全仓的调用点情况是——

```
grep -rn 'HpBar(' lib/ --include='*.dart'
→ 共 5 处命中，其中 1 处是 hp_bar.dart:28 的构造函数声明本身
→ 真实调用点 4 处，全部在 lib/features/battle/presentation/character_avatar.dart
```

即 **`HpBar` 是战斗屏专用组件，角色面板/详情页根本没有使用它**。所谓「全局回归」风险为零。

**修订建议**：直接改 `HpBar` 本体，不要新建「战场专用样式」分支。理由：
- 新增第二套样式路径 = 长期要维护两条渲染分支，而其中一条永远没有调用者；
- 本项目已有先例反对这类抽象（memory 记「抽 interface/abstract 不是必须做的事——先 grep 现状 + 找真痛点」）；
- §11 风险表对应行应改为「无全局回归风险（已实测 HpBar 仅 4 个调用点且全在战场）」，否则会误导后续实施者继续加分支。

若 Codex 复核后发现我漏了动态构造（如通过 builder 间接实例化），请贴出反证，以反证为准。

### Codex triage：成立 · 已采纳

独立复核没有找到 builder、工厂、constructor tear-off 或导出层的隐藏构造。Dart 即便在 builder
中间接构造也必须出现 `HpBar` 符号；全仓符号搜索除 4 个生产调用外，只剩组件声明、测试、注释和 import。

```text
$ grep -rn 'HpBar(' lib/ --include='*.dart'
lib/features/battle/presentation/hp_bar.dart:28:  const HpBar({
lib/features/battle/presentation/character_avatar.dart:223:          child: HpBar(
lib/features/battle/presentation/character_avatar.dart:232:          child: HpBar(
lib/features/battle/presentation/character_avatar.dart:680:                  HpBar(
lib/features/battle/presentation/character_avatar.dart:690:                  HpBar(

$ rg -n --glob '*.dart' '\bHpBar\b|HpBar\.new|hp_bar\.dart' lib test
# lib/ 中除声明外仅上述 4 个调用；HpBar.new 为 0；其余为 3 个 hp_bar_test、1 个类型断言和注释/import。
```

正文 §5.3、§6 与 §11 已改为直接修改 `HpBar` 本体，不再规划第二条战场样式分支。

---

## A.2【必须 · 推翻前提】§5.2 移除人物层拍数环会在多敌同时蓄势时丢失信息

**原文主张**（§5.2）：
> 「Boss 头顶 34px 红色数字环不得继续成为第二警示中心；**推荐把拍数只留在顶部横幅**」

**现查风险**：`DangerBar` 的实现头注（`battle_banners.dart:108-110`）明写——
> 「纯读 `BattleState.rightTeam`：**取最临近发动（`chargeTicksRemaining` 最小）的存活蓄力敌人**」

代码 `:118-123` 的循环确认它只挑 `chargeTicksRemaining` 最小的**一个**敌人。同时全仓**查无**任何「同时只允许一个敌人蓄势」的限制（grep `anyCharging`/`alreadyCharging` 零命中）。

**结论**：多个敌人可以同时蓄势，而顶部横幅在设计上只显示其中一个。若按原文把拍数**只**留在横幅：
- 玩家无法知道第二个敌人也在蓄势；
- 3v3 时无法判断「即将发动的是哪一个」，而破招需要选目标。

这是**信息完整性**问题，不只是视觉权重问题。原报告只从「第二警示中心」的视觉角度论证，未考虑这一层。

**修订建议**：采用原文给的**后半个备选**而非前半个——
> 「或把倒数缩成不抢脸部的暗绛小印」

即 **保留每角色的拍数指示，但把它从「红圈数字」降权为「暗绛小印/角标」**，与顶部横幅形成主次而非二选一。同时把 §5.2 视觉 Gate 补一条：

- 新增 Gate：**双敌同时蓄势场景下，两个敌人的剩余拍数均可辨**（需要一条能造出双蓄势的验收路由或 fixture；现有 `battle_tap_live` 是固定单蓄势 2 拍，覆盖不到）。

### Codex triage：成立 · 已采纳

“没有单敌限制”只是弱证据；真正推翻单蓄势前提的是生产心魔 05–07：
`buildMirrorEnemyTeam` 会给最多三名镜像逐个注入同一个 `chargeSkillId`。常规主线、塔和断魂庄
每队最多只有一名可蓄势者，但心魔是明确的生产反例。

```text
$ ruby -ryaml <逐 enemyTeam 统计 chargeSkillId/chargeCounter>
data/stages.yaml: teams=122, multi_charge_capable=0
data/towers.yaml: teams=30, multi_charge_capable=0
data/boss_gauntlets.yaml: teams=3, multi_charge_capable=0
inner_demon_05..07: buildMirrorEnemyTeam injects chargeSkillId into every mirror (up to 3)

$ flutter test --no-pub build/triage/inner_demon_multi_charge_probe_test.dart --reporter expanded
stage_inner_demon_05 seeds=100 any=100 multi=100 multiSnapshots=905/3710 max=3
stage_inner_demon_06 seeds=100 any=100 multi=100 multiSnapshots=930/3965 max=3
stage_inner_demon_07 seeds=100 any=100 multi=100 multiSnapshots=935/4110 max=3
00:01 +1: All tests passed!
```

频率探针使用真实 `numbers.yaml`、真实心魔注入逻辑和 `DefaultGroundStrategy`，玩家侧取合法的
无破招普通招装配；它证明多蓄势不只是手造不可达状态。临时 probe 已在取证后删除。正文 §5.2
已明确“顶部单主警示 + 每角色暗绛小印”，并增加最多三敌同时蓄势 Gate。

---

## A.3【必须 · 覆盖缺口】生产矩阵漏了断魂庄，而它恰是 P2 最极端的象限

报告基线 `5a649ea3` 之后，PR #110（merge `afbf52f4`）新增了 `battle_audit_gauntlet_01..03` 三条 audit 路由，battle suite 由 76 → **79**。**Codex 写报告时这三条还不存在，属客观时间差，非疏漏。**

但这个缺口在本报告语境下很关键：

- **断魂庄是全项目唯一不叠场景美术的战斗**。`mainline`/`tower`/`sweep` 三个入口都向 `BattleScreen` 传 `sceneBackgroundPath`，只有 `gauntlet_entry_flow` 不传（`boss_gauntlet/` 目录下零背景引用）；
- `BattleSceneBackground` 在 `path == null` 时 `hasImage=false`，**只跳过 `WuxiaImage` 与 image scrim 两层**，程序化层（天空渐变 / `_DistantMountainPainter` 远山 / mist / ground 两 painter `intensity=1` / 晕影）反而**全开满强度**；
- 也就是说，这是一个「**背景 100% 程序化、零摄影级素材**」的战斗场景。

报告 §5.6 的代表场景四象限是「暖亮 / 暖暗 / 冷亮 / 冷暗」，**全部隐含「有背景图」这一前提**。而「无背景图」是第五种情况，且恰恰是**立绘最容易显出浮贴**的一种——因为没有照片级背景的噪点与景深可以借力融合。

**修订建议**：
1. §5.6「代表场景」表新增一行：

   | 纯程序化背景 | `battle_audit_gauntlet_02` | 无场景美术下的立绘融合、护法结界 tag、3v3 精英阵列 |

   （选 02 关次的理由：三人阵列 + 石镇岳带「护法结界」金色 pill + 「势」蓄势 tag，一屏同时覆盖融合、多状态 tag 与密度三项判据。）
2. §8.2 生产矩阵新增 `battle_audit_gauntlet_02`（1280×720 必拍 / 1440×900 必拍）。
3. §5.6 视觉 Gate 补一条：**在零场景美术背景下，立绘不得出现矩形光晕或明显贴纸边**。

参考图：本次已抓过三张 720p 实拍，在 `build/visual_acceptance/gauntlet_audit_20260801/`（gitignored，随 checkout 存续），Codex 可直接取用作 before 基线。

### Codex triage：部分成立 · 部分采纳

成立部分：断魂庄确实是当前生产入口中唯一不给 `BattleScreen` 传场景美术的战斗；`path==null`
时程序化层完整保留，且 route 02 同屏覆盖 3v3、护法结界与状态密度，值得作为独立第五类。

```text
$ ruby -ryaml <统计 stages/towers 的 sceneBackgroundPath>
data/stages.yaml: total=122 null_scene=0 null_scene_with_inline_enemy_team=0
data/towers.yaml: total=30 null_scene=0 null_scene_with_inline_enemy_team=0

$ sed -n '208,216p' lib/features/boss_gauntlet/presentation/gauntlet_entry_flow.dart
return BattleScreen(
  hint: ...,
  bgmTrack: BgmTrack.boss,
  ...
);  # 未传 sceneBackgroundPath

$ find build/visual_acceptance/gauntlet_audit_20260801 -type f
find: build/visual_acceptance/gauntlet_audit_20260801: No such file or directory

$ tools/visual_capture/visual_capture.sh --route battle_audit_gauntlet_02 \
    --resolutions 1280x720,1440x900 --output build/visual_acceptance/appendix_a_triage ...
# 两档 PNG/log 均成功生成并 READY。
```

不成立/证据不足部分：附录声称已有的旧截图目录当前不存在；重新实拍后，断魂庄的暗色低对比背景
并未比冷亮塔景更明显暴露“剪纸边”，反而更容易掩盖边缘。它更擅长暴露的是接地、景深不足、
暗部融死和程序化层的均匀感。因此正文已加入该路由，但删去“必然是最极端/最容易浮贴”的预设，
要求与冷亮塔景并排后按实图判断。

---

## A.4【必须 · 会绊倒实施者】新增测试触点未列入 §6 文件级实施矩阵

PR #110 在 `test/features/debug/visual_route_test.dart` 中新增了一条按路由分支的断言：

```dart
if (spec.route == VisualRoute.battleGauntletAudit) {
  expect(launcher.sceneBackgroundPath, isNull, reason: spec.id);   // ← 断魂庄必须为 null
  expect(launcher.bgmTrack, BgmTrack.boss, reason: spec.id);
} else {
  expect(launcher.sceneBackgroundPath, isNotNull, reason: spec.id);
}
```

**若实施者在做 §5.6 场景收口时顺手给断魂庄补一张背景，这条测试会红。** 这是有意为之的门禁（audit 路由必须忠实复现生产入口，补背景等于验玩家看不到的画面），不是待修的缺陷。

**修订建议**：§6 文件级实施矩阵新增一行：

| `test/features/debug/visual_route_test.dart` | 如改 audit 路由背景/BGM 透传需同步 | 三视口构造、gauntlet 分支断言 | 误把「断魂庄背景为 null」当缺陷去修 |

同时 §4.2「禁止修改」建议补一条：**不得为追求视觉一致性给断魂庄 audit 路由补场景背景**——要补应该改生产入口 `gauntlet_entry_flow`，那是内容层决策，不在本轮视觉修复范围。

### Codex triage：成立 · 已采纳

断言、注释和 production path 完全一致；这不是待修测试，而是防止 audit 伪造生产画面的门禁。

```text
$ rg -n -C 3 'battleGauntletAudit|sceneBackgroundPath, isNull' \
    test/features/debug/visual_route_test.dart
398: if (spec.route == VisualRoute.battleGauntletAudit) {
409:   expect(launcher.sceneBackgroundPath, isNull, reason: spec.id);
410:   expect(launcher.bgmTrack, BgmTrack.boss, reason: spec.id);
411: } else {
412:   expect(launcher.sceneBackgroundPath, isNotNull, reason: spec.id);

$ flutter test --no-pub test/features/debug/application/visual_acceptance_plan_test.dart \
    test/features/debug/visual_acceptance_gauntlet_coverage_test.dart \
    test/features/debug/visual_route_test.dart --reporter compact
00:07 +55: All tests passed!
```

正文 §4.2、§6 和 §9.1 已补禁改边界、两个测试触点与 targeted 命令。

---

## A.5【建议】补「同路由 before/after 逐像素对照」作为零回归直证

报告已要求 reference/current 对照（母版 vs 现状），这解决「像不像母版」。但**没有要求修复前后同一路由的逐像素 diff**，而这才是「有没有把别的场景改坏」的直证。

本项目有现成先例可循（2026-07-30 B3 立绘融合批）：
> 「desert 立绘明度 71.3→84.4（+13.2）、frontier +8.3、smithy +4.4、mountainforest +3.1 随强度单调，**alley 与 tower 变化像素 0 = 暗场景零回归的逐像素直证**（非靠『默认值没变』推断）」

§5.6 明确要求「人物不能因暗场景全部糊成黑块，也不能因亮场景像贴纸」——**证明这一点最强的证据是 before/after，而不是只看 after 一张**。只看修复后的图，永远无法区分「本来就好」与「改好了」，也无法发现「这张改好了但那张改坏了」。

**修订建议**：§7 阶段 3 交付项新增：

- 对四象限（+ A.3 新增的纯程序化象限）代表路由，各留一份**修复前**截图与哈希；
- 阶段末给出 before/after 的逐资产明度/饱和度 Δ 表与变化像素计数；
- **对本轮不打算改动的场景，须显式给出「变化像素 0」或说明为何允许非零**。

### Codex triage：部分成立 · 部分采纳

成立部分：reference/current 只能回答“离母版多远”，不能回答“这次改动让哪些生产场景退步”；
同路由 before/after 对生产泛化很有价值，而且现有基线截图已经覆盖大部分路由，新增成本可控。

```text
$ rg -n '变化像素 0|before/after' PROGRESS.md docs/spec/2026-07-30-battle-ui-b3-evaluation.md
PROGRESS.md:16: ... alley 与 tower 变化像素 0 = 暗场景零回归的逐像素直证 ...
docs/spec/2026-07-30-battle-ui-b3-evaluation.md:183:
  暗场景逐像素完全相同（变化像素 0）——零回归是直证 ...
```

不采纳部分：B3 是单一融合函数的受控修改，强度 `t=0` 的场景理应零像素变化；本轮会同时修改
公共 HUD、`HpBar`、横幅、案台和融合层，全屏要求“变化像素 0”会把有意改动误报为回归。
正文阶段 3 已改成：保留 before/hash，按人物、HUD、背景 ROI 或允许变化 mask 分区比较；只对明确
不在改动影响域内的 ROI 要求 0，其他区域记录变化量与理由。

---

## A.6【基线订正】报告中三处工程数字已随 main 前移

不影响方案，但实施者若拿这些数字当 ratchet 会对不上：

| 报告原值（§2.3） | 现值（`main@acc31ee8` 实测） |
|---|---|
| 全量 4786 pass / 0 fail | **4792 pass / 0 fail** |
| （未提）battle suite 76 条 | **79 条**（+3 断魂庄 audit） |
| 当前代码态 `main@5a649ea3` | `main@acc31ee8`（其后 5 commit，改动集中在 `lib/features/debug/` 与文档） |

`5a649ea3..acc31ee8` 的 lib 改动**全部在 `lib/features/debug/`**，未触碰任何 `lib/features/battle/presentation/` 文件，故报告的根因分析与文件级矩阵**不受影响**，无需重做基线截图。

### Codex triage：部分成立 · 部分采纳

三组核心订正均成立，`lib/` 影响范围也成立；“无需重做旧基线”另用当前 HEAD 新抓图逐字节验证。
但附录头部所写“其后有 5 个 commit”错误，实际为 8 个，所以本条不能判为完全成立。

```text
$ git rev-list --count 5a649ea3..acc31ee8
8

$ git diff --stat 5a649ea3..acc31ee8 -- lib/
 .../debug/application/visual_acceptance_plan.dart | 22 +++++++++++++++++++
 lib/features/debug/application/visual_route.dart  | 22 +++++++++++++++++++
 .../debug/presentation/battle_test_menu.dart       | 25 ++++++++++++++++++++++
 .../debug/presentation/visual_route_host.dart      | 15 +++++++++++++
 4 files changed, 84 insertions(+)

$ shasum -a 256 <旧 battle_tap_live 1672> <acc31ee8 新抓 1672>
0ed5d1ea2d6c5cc19057943dffeeffa678827453c3c7b0bc0cfcb24bd751bdb7  <旧图>
0ed5d1ea2d6c5cc19057943dffeeffa678827453c3c7b0bc0cfcb24bd751bdb7  <新图>
$ cmp -s <旧图> <新图>; echo $?
0

$ flutter test --no-pub --reporter compact
11:16 +4792: All tests passed!
```

79 route 不是 79 个 test case，而是 `visual_acceptance_plan_test.dart` 钉住的 battle suite 容量：
73 条动态战斗 route + 6 条确定性素材/状态 route。正文头部和 §2.3 已按 `acc31ee8` 订正。

---

## A.7 我不认为需要改、但想指出的一点

§5.1 的机器门槛（战场 MAE 28.44→≤22、边缘 IoU 0.107→≥0.12）在绝对值上仍然很宽松——IoU 0.12 意味着边缘重合度只有 12%。报告自己已经说清「机器门槛只做防回退，不能单独宣称 95」，所以这不是错误，逻辑是自洽的。

但请实施者注意其推论：**G3 人物构图要从 15 涨到 19，机器门槛完全检测不到这个跃迁**。也就是说这一项的达成与否，**只能靠人工评分与用户终拍**，机器指标全绿不构成任何证据。建议在 §7 阶段 3 的 Gate 里把这句写死，避免后期出现「机器指标都过了为什么还不算 95」的争执。

### Codex triage：部分成立 · 部分采纳

成立部分：全战场 MAE/边缘 IoU 是非语义全局指标，过线不能证明人物动作轮廓、Boss 层级或接地
已经达到 G3=19；最终人工评分和用户终拍不可替代。

绝对表述不成立：机器并非“完全检测不到”人物构图。现有 analyzer 已实现人物 alpha bbox、渲染面积、
Boss/玩家面积比和暗部 P05；只要诊断层存在，它们能对人物大小与层级提供客观 Gate。当前截图恰好
没有这些诊断层，所以本轮基线中相应值为 unavailable，而不是能力上只能靠人工。

```text
$ nl -ba tools/visual_capture/analyze_battle_v2_fidelity.py | sed -n '187,242p;267,322p'
187 def _character_metrics(...)
202     bbox = alpha_bbox(...)
223     "bbox_area": area,
224     "dark_p05": ...
231 def _boss_area_ratio(...)
316     "boss_area_ratio": _ratio_in_band(...)

$ python3 tools/visual_capture/analyze_battle_v2_fidelity.py --manifest <当前 manifest> ...
battle_tap_live_1672x941 ... boss ratio — ...
warnings: missing regions; missing character diagnostic layers; missing semantic UI diagnostic layer
```

正文阶段 3 已写成“全局 MAE/IoU 不得作为 G3 得分证据；人物诊断量测作辅证；Codex 人工复核和
用户终拍作最终判断”，避免把人工判断与机器守门错误地做成二选一。

---

## A.8 修订汇总（供 Codex 逐条复核）

Codex 独立 triage 总计：**成立 3 条、部分成立 4 条、证伪 0 条**。部分成立不是礼貌性折中：
每条均明确指出被反证或证据不足的子结论，正文只合并可证部分。

| # | 级别 | 内容 | Claude 给的证据 | Codex 判定与处置 |
|---|---|---|---|---|
| A.1 | 必须 | §5.3 去掉「战场专用样式」间接层，直接改 `HpBar` | `HpBar` 真实调用点 4 个且全在 `character_avatar.dart` | **成立 · 已采纳**：全符号搜索排除 builder/tear-off 隐藏调用；正文已改为直改本体 |
| A.2 | 必须 | §5.2 保留每角色拍数（降权为暗绛小印），不要只留顶部横幅 | `battle_banners.dart:108-123` 只取最临近一个敌人；无「单敌蓄势」限制 | **成立 · 已采纳**：心魔 05–07 最多三镜像真实可同时蓄势；100 seeds 均观察到 multi |
| A.3 | 必须 | §5.6/§8.2 补断魂庄（纯程序化背景象限） | `gauntlet_entry_flow` 不传背景；`BattleSceneBackground` null 分支只跳 2 层 | **部分成立 · 部分采纳**：第五类覆盖成立；旧截图目录不存在，且“最易浮贴”被实拍削弱，不预设最极端 |
| A.4 | 必须 | §6 补 `visual_route_test.dart` 触点；§4.2 补「不得给断魂庄 audit 补背景」 | PR #110 新增的 gauntlet 分支断言 | **成立 · 已采纳**：断言与生产入口一致；正文、矩阵、targeted 已补齐 |
| A.5 | 建议 | §7 阶段 3 补 before/after 逐像素零回归直证 | B3 批先例：「alley 与 tower 变化像素 0」 | **部分成立 · 部分采纳**：保留 before/hash 与分区 diff；拒绝对有意修改公共 HUD 的全屏 0 像素要求 |
| A.6 | 订正 | 基线数字 4786→4792、suite 76→79、代码态前移 | 现测 | **部分成立 · 部分采纳**：三数字、debug-only 和旧图不变均复核成立；“5 commits”实为 8 |
| A.7 | 提示 | 机器门槛检测不到 G3 人物构图跃迁，需在 Gate 写死 | 报告自身逻辑推论 | **部分成立 · 部分采纳**：全局 MAE/IoU 不足；但 bbox/面积比可作机器辅证，最终人工与用户终拍决定 |

**总评**：这份报告的方法论（取低值口径、一票否决、拒绝黑盒总分、样板资产不计入生产分）是对的，而且诚实地否定了自己上一轮的 98 分。**我支持按它开工**，前提是先过 A.1–A.4 这四条——其中 A.1 和 A.2 若不改，会分别造成「多维护一条无用渲染分支」和「多敌蓄势时丢信息」两个实际后果。
