# Phase 0B 可玩初稿切片(Qoder 执行)

> 日期:2026-08-14 · 分支:`feat/phase0b-qoder-playable-draft`(worktree 隔离)
> 状态:进行中。目标是「可运行初稿,后期精修」,不是 Gate、不是 Phase 0C、不是正式生产。

## 1. 目标与边界

在 `tools/phase0minus_probe/` 内新增独立交互模式 `phase0b_playable_draft`,把现有占位姿态图集接进一个可手操的初稿循环:基础敌人 AI 初稿 + 单 Boss 初稿 + 第二流派初稿。

**隔离红线(与任务指令一致)**:

- 只改 `tools/phase0minus_probe/` 与本计划文件;不触碰根应用 `lib/`、`data/`、根 `pubspec.yaml`、存档、奖励、正式战斗。
- 不写 Gate 报告、不重跑正式 60 秒观察矩阵、不接入 ResultWriter/Gate writer。
- 模式字段固定 `gate_eligible=false`,HUD 明示 `NOT FINAL`。
- 不实现 `docs/spec/rejected_task_registry.md` 中的「敌方连环窗口链」(多单位接力蓄招)与「敌方集火对称化」(显式集火踉跄/低血者)。敌人 AI 只做:视口外出生、接近/包围、有限攻击预兆、退让。
- 不扩正式数值配置:不调根 `data/*.yaml`,也不改 probe 的 `assets/probe_scenarios.yaml`(其 checksum 已被既有证据链引用);初稿数值全部以 probe 本地 Dart 常量承载,显式标注 `NOT FINAL DRAFT TUNING`(probe 为一次性基建,phase0b 各模式已有同类先例)。
- 不做正式美术、音频、UI、掉落反馈(表现骨架属另一 Kimi 切片)。

## 2. 设计要点

### 2.1 新文件(domain 层,纯 Dart、可单测、确定性)

- `lib/phase0b/playable/draft_tuning.dart` — 初稿调参常量集合(口袋半径、环围半径、预兆/退让时长、Boss 血量/阶段阈值、流派 profile)。
- `lib/phase0b/playable/enemy_brain.dart` — 基础敌人 AI 状态机:
  - 状态:`waiting → entering → ringing → telegraphing → striking → retreating → (cooldown) → ringing`;`defeated` 终态。
  - 视口外出生:出生点 x 固定在当前视口 `[cameraLeft, cameraLeft+viewWidth]` 外 ±margin,分批延迟。
  - 包围:按 id 分配确定性环围槽位角,围绕主角保持 `ringRadius`;每 tick 硬投影保证与主角距离 ≥ `pocketRadius`(可读性口袋,沿用 0B 冻结的 ~112px 量级)。
  - 有限预兆:并发预兆令牌上限 2,按 id 顺序确定性授予;令牌授予只取决于「令牌空闲 + 自身冷却就绪」,不与任何敌人的预兆结束事件串联(即不构成员环窗口链)。
  - 退让:出招后强制向外退让一段再回环围;目标恒为主角当前位置,不做任何基于目标状态的目标选择(即不构成集火对称化)。
- `lib/phase0b/playable/boss_brain.dart` — 单 Boss 初稿:
  - 最多两阶段:HP ≤ 50% 一次性切入阶段二(不回升、不重复触发)。
  - 两种危险形状:震击(圆形判定区)与横扫(前向扇形),均有固定时长预兆窗;预兆期暴露判定区,落点只在区内造成伤害 → 危险窗口可读。
  - 出招后有短暂力竭(承伤加深)作为可读反击窗口;阶段二只缩短节奏、不膨胀数值(血量/伤害上限不突破)。
- `lib/phase0b/playable/style_profiles.dart` — 流派初稿:
  - 流派 A = 现有灰盒节奏(快频短弧普攻 + 聚怪 Q + 环形清场 R),流派 B = 阴柔向初稿(慢频长距窄弧普攻 + 内伤持续伤害、缓速雾 Q、直线穿刺 R)。
  - 沿用既有输入映射(WASD 移动 / LMB 普攻 / Space 身法 / Q / R),不新增操作键;两流派只改节奏与形状参数。
  - 解析器为纯函数,可用同一输入脚本对比两流派输出/节奏。

### 2.2 新文件(表现层,薄壳)

- `lib/phase0b/playable/phase0b_playable_draft_app.dart`:
  - Flame 游戏:3600×720 连续长卷(复用既有 `scroll_panorama` 底板)、dead-zone 跟随镜头、战斗带 y∈[365,640]。
  - 遭遇:两段怪群(6 / 10)+ 末段单 Boss 场地;敌人视口外出生。
  - 渲染:复用现有占位姿态图集(founder/bandit/elite pose atlas),按状态映射离散姿态;Boss 预兆画朱砂判定区(遵守冻结视觉语言:朱砂只出现在判定方向和窗口)。
  - HUD 固定文案:`PHASE 0B PLAYABLE DRAFT · NOT FINAL · gate_eligible=false` + 输入说明;运行时可用 1/2 切换流派(仅为评审便利,不改各流派输入映射)。
  - 元数据 `Phase0bPlayableDraftMetadata.gateEligible == false`;不写任何结果文件。

### 2.3 接线

- `lib/main.dart`:mode 白名单新增 `phase0b_playable_draft`,窗口标题与 widget 分支接线。
- `README.md`:新增该模式一段说明(review-only、非 Gate)。

### 2.4 测试

- `test/phase0b/playable/draft_enemy_ai_test.dart`:
  - 出生点全部在视口外;
  - 长时间模拟(主角移动 + 20 敌人)口袋不穿入(每 tick 距离 ≥ pocketRadius);
  - 并发预兆 ≤ 令牌上限;出招后出现退让;
  - 同种子双跑轨迹一致(确定性)。
- `test/phase0b/playable/draft_boss_test.dart`:
  - HP 越阈值只切一次阶段且不回退;阶段二节奏更紧;
  - 预兆 → 落招序列确定;判定区外不受伤害;力竭窗存在。
- `test/phase0b/playable/draft_style_test.dart`:
  - 同一输入脚本下,两流派普攻节奏(命中间隔)与形状(弧 vs 直线/环 vs 线)可区分;B 有内伤持续伤害而 A 无;两流派总输出量级相近但节奏不同。
- `test/phase0b/playable/playable_draft_mode_test.dart`:
  - 元数据 `gateEligible == false`;
  - `main.dart` 白名单含该 mode;
  - app 文件不引用 ResultWriter/Gate writer(源文本检查)。

## 3. 验收清单

- [ ] `flutter format` 无 diff;`flutter analyze --no-pub` 0 issue(tools/phase0minus_probe)。
- [ ] 新增 4 个测试文件全绿;probe 全量 `flutter test --no-pub` 全绿。
- [ ] 模式声明 `gate_eligible=false` 且 HUD 明示 NOT FINAL;无任何 Gate/结果目录写入。
- [ ] 敌人 AI:视口外出生、包围保留可读性口袋(单测不穿入)、有限预兆 + 退让;无连环窗口链/集火对称化。
- [ ] Boss:单 Boss、≤2 阶段、危险窗口可读、无数值膨胀。
- [ ] 第二流派:沿用既有输入与模型,节奏/形状与现有流派可区分(单测对比),不扩正式数值配置。
- [ ] 隔离:根 `lib/`、`data/`、根 `pubspec.yaml` 零改动(`git status` 证明)。
- [ ] 工作区干净,tip commit `[READY]` 前缀。

## 4. 任务切片

| # | 切片 | 状态 |
|---|---|---|
| 1 | 计划文件 | 完成 |
| 2 | enemy_brain + draft_tuning + 测试 | 待做 |
| 3 | boss_brain + 测试 | 待做 |
| 4 | style_profiles + 测试 | 待做 |
| 5 | app 薄壳 + main.dart 接线 + mode 测试 + README | 待做 |
| 6 | format/analyze/全量测试 + 恢复点收口 + [READY] | 待做 |

## 5. 当前恢复点

- 状态:切片 1 完成,准备进入切片 2。
- 最后完成:文档与既有 probe 结构通读(AGENTS/CLAUDE/GDD/rejected registry/0B 规格/main.dart/gameplay 层/隔离契约)。
- 下一步:写 `draft_tuning.dart` 与 `enemy_brain.dart` 及其测试。
- 已跑验证:暂无(尚未改码)。
- 阻塞项:无。
