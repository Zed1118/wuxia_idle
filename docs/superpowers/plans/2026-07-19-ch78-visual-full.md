# Ch7/Ch8 美术 22 图全 route 双视口真机抽验

## 目标

- 纯验收 Ch7（`stage_07_01..05`）与 Ch8（`stage_08_01..05`）的 10 个真实战斗 route、10 个剧情 opening 背景呈现，以及章节列表 Ch7/Ch8 封面态。
- 每个呈现点在 `1280×720` 与 `1440×900` 各留 1 张截图，共 `21×2=42` 张；逐张登记路径、统一判定与异常点。
- 只记录与初判，不修改生产代码、资产、YAML 或设计文档；美术风格终判保留给用户。

## 分支

- 基点：`main@43df2d10`
- 分支：`codex/ch78-visual-full`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/ch78-visual-full`
- 截图目录（Git 忽略）：`build/visual_acceptance/ch78_full_sweep/`

## 验收标准

- [ ] 21 个呈现点 × 2 个视口全部有截图与判定，无遗漏。
- [ ] 判定只使用 `PASS` / `FAIL（附异常）` / `存疑待拍（附一句话疑点）`。
- [ ] 战斗逐图检查立绘落位、脚底锚点、透明边缘、HUD/背景对比度与文字可读性。
- [ ] 剧情逐图检查背景题材呈现、scrim/正文浮层对比度与文字可读性。
- [ ] 章节列表检查 Ch7 冷灰到 Ch8 暖沙的封面梯度连续性。
- [ ] 灰衣人递进检查：`stage_07_04` 北京遮脸 → `stage_08_03` 塞北遮脸 → `stage_08_05` 露真容。
- [ ] 逐 route 日志无 overflow / exception / error；若有则保留日志、截图并判 FAIL。
- [ ] 生产接线证据：battle 使用动态真实 `stage` route；narrative 使用生产 `NarrativeReaderScreen`、真实 opening YAML 与 `stageNarrativePath`；章节列表使用生产 `ChapterListScreen`。
- [ ] targeted test / 基线：按纯验收单仅执行用户指定 `build_runner` + `flutter analyze --no-pub`；不重复全量 4417 基线。
- [ ] 红线影响：零触及数值硬红线、三系锁死、在线=离线、反主流清单与文案/数值硬编码。
- [ ] 残留风险：未能驱动到的态、日志噪声、截图驱动限制与风格待拍项列清。
- [ ] Git 最终除本 plan 外零变化；截图不入库；plan 提交后 tip 为 `[READY]` 且树干净。

## 任务切片

1. 读取真相源、拒绝任务登记表、视觉验收与 worktree 规范；建立隔离 worktree。
2. 获取依赖、运行代码生成与 analyze 基线；定位动态 battle route、narrative 呈现路径和 chapter list。
3. 建立本恢复点与 21×2 联络表骨架。
4. 完成 `1280×720` 的 10 battle + 10 narrative + 1 chapter list 截图、读图与日志检查。
5. 完成 `1440×900` 的 10 battle + 10 narrative + 1 chapter list 截图、读图与日志检查。
6. 对账 42 张证据，汇总异常、灰衣人递进、封面梯度、红线声明与残留风险。
7. 复核 Git 只含 plan，提交中文动宾消息并追加 `[READY]` tip，确认树干净。

## route 与路径口径

- battle：`battle_audit_stage_07_01..battle_audit_stage_07_05`、`battle_audit_stage_08_01..battle_audit_stage_08_05`。动态解析器 `battleAuditStageId` 消费真实 `stages.yaml`；固定 battle suite 当前仍只枚举 Ch1–6，本单显式逐 route 运行。
- narrative：编译期 `VISUAL_ROUTE=narrative_scene` + `VISUAL_STAGE=stage_07_01..stage_08_05`，呈现真实 `${stageId}_opening` 与 `stageNarrativePath(stageId)`；截图索引使用 `narrative_stage_XX_XX` 作为呈现点名。
- chapter list：`chapter_list` 生产屏，滚动到 Ch7/Ch8 章卡同时可见的末部状态后截图。

## 联络表

> 路径均相对本 worktree。PASS 表示本单指定的落位、边缘、对比度、文字、overflow/exception/error 检查未见异常；不代表对美术风格作终判。

| 呈现点 | 1280×720 截图 | 判定 | 异常点 | 1440×900 截图 | 判定 | 异常点 |
|---|---|---|---|---|---|---|
| `battle_audit_stage_07_01` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_07_01.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_07_01.png` | PASS | 无 |
| `battle_audit_stage_07_02` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_07_02.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_07_02.png` | PASS | 无 |
| `battle_audit_stage_07_03` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_07_03.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_07_03.png` | PASS | 无 |
| `battle_audit_stage_07_04` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_07_04.png` | PASS | 灰衣人北京态遮脸，递进符合预期 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_07_04.png` | PASS | 灰衣人北京态遮脸，递进符合预期 |
| `battle_audit_stage_07_05` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_07_05.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_07_05.png` | PASS | 无 |
| `battle_audit_stage_08_01` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_08_01.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_08_01.png` | PASS | 无 |
| `battle_audit_stage_08_02` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_08_02.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_08_02.png` | PASS | 无 |
| `battle_audit_stage_08_03` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_08_03.png` | PASS | 灰衣人塞北态仍遮脸，衣纹递进可辨 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_08_03.png` | PASS | 灰衣人塞北态仍遮脸，衣纹递进可辨 |
| `battle_audit_stage_08_04` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_08_04.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_08_04.png` | PASS | 无 |
| `battle_audit_stage_08_05` | `build/visual_acceptance/ch78_full_sweep/battle/1280x720/battle_audit_stage_08_05.png` | PASS | 灰衣人最终态露真容，脚底与披风边缘正常 | `build/visual_acceptance/ch78_full_sweep/battle/1440x900/battle_audit_stage_08_05.png` | PASS | 灰衣人最终态露真容，脚底与披风边缘正常 |
| `narrative_stage_07_01` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_07_01.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_07_01.png` | PASS | 无 |
| `narrative_stage_07_02` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_07_02.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_07_02.png` | PASS | 无 |
| `narrative_stage_07_03` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_07_03.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_07_03.png` | PASS | 无 |
| `narrative_stage_07_04` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_07_04.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_07_04.png` | PASS | 无 |
| `narrative_stage_07_05` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_07_05.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_07_05.png` | PASS | 无 |
| `narrative_stage_08_01` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_08_01.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_08_01.png` | PASS | 无 |
| `narrative_stage_08_02` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_08_02.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_08_02.png` | PASS | 无 |
| `narrative_stage_08_03` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_08_03.png` | PASS | 夜景最暗，但正文浮层与按钮仍清楚 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_08_03.png` | PASS | 夜景最暗，但正文浮层与按钮仍清楚 |
| `narrative_stage_08_04` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_08_04.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_08_04.png` | PASS | 无 |
| `narrative_stage_08_05` | `build/visual_acceptance/ch78_full_sweep/narrative/1280x720/narrative_stage_08_05.png` | PASS | 无 | `build/visual_acceptance/ch78_full_sweep/narrative/1440x900/narrative_stage_08_05.png` | PASS | 无 |
| `chapter_list_ch07_ch08_covers` | `build/visual_acceptance/ch78_full_sweep/chapter_list/chapter_list_ch07_ch08_covers_scrolled_1280x720.png` | PASS | Ch7 冷灰雪岭→Ch8 暖沙夕阳梯度连续 | `build/visual_acceptance/ch78_full_sweep/chapter_list/chapter_list_ch07_ch08_covers_scrolled_1440x900.png` | PASS | Ch7 冷灰雪岭→Ch8 暖沙夕阳梯度连续 |

## 四证据汇总

### 覆盖清单（21×2 对账）

- 当前：`42/42`，其中 battle `20/20`、narrative `20/20`、chapter list `2/2`。
- 判定汇总：PASS `42` / FAIL `0` / 存疑待拍 `0`。

### 截图路径索引

- 单图路径已逐项填入上方联络表。
- 读图联络图（辅助，不计入 42 张）：
  - `build/visual_acceptance/ch78_full_sweep/battle/_contact_battle_1280x720.png`
  - `build/visual_acceptance/ch78_full_sweep/battle/_contact_battle_1440x900.png`
  - `build/visual_acceptance/ch78_full_sweep/narrative/_contact_narrative_1280x720.png`
  - `build/visual_acceptance/ch78_full_sweep/narrative/_contact_narrative_1440x900.png`

### 红线影响声明

- 本任务为纯验收；不修改 Dart、资产、YAML、数值、schema、saveVersion、GDD 或生产文档，零触及项目红线。

### 残留风险

- 本轮未发现错图、裂图、overflow、exception 或 error，未产生 FAIL。
- 本单只判呈现完整性与可读性；美术风格终判仍由用户拍板，PASS 不代表代替风格终审。
- battle 固定 suite 注册表仍只枚举 Ch1–6；Ch7/Ch8 本次依靠既有动态 parser 显式驱动，未改注册表。
- narrative 的 stage 参数是编译期 `VISUAL_STAGE`，因此逐 stage 重新构建；10 份 build log 与 20 份 route log均无 error/exception/overflow 命中。
- chapter list 初次键盘 End/PageDown 未滚动，保留两张未计数的顶端态；最终计数证据通过 CGEvent 滚轮到 Ch7/Ch8 大章卡同屏态。

## 当前恢复点

- 状态：Ch7/Ch8 原单验收完成，42/42 全部 PASS；待执行精确文件/日志/Git 对账并提交第一次 `[READY]`，随后按用户追加目标接续动态长战与特殊模式观察。
- 最后完成：10 个 battle、10 个 narrative 与 chapter list Ch7/Ch8 大封面态均完成双视口截图；灰衣人三段递进与章节封面冷灰→暖沙梯度均可辨；未见硬呈现缺陷。
- 下一步：运行第一次 completion verification（42 张精确存在、日志无异常、Git 只含 plan），提交中文动宾并追加 `[READY]`；之后把追加观察目标写入本 plan 并续跑。
- 已跑验证：`flutter analyze --no-pub`（0 issues，2026-07-19）；battle 20/20 与 narrative 20/20 文件计数；battle/narrative route log 关键词扫描 0 命中；narrative build log 关键词扫描 0 命中；四张联络图与两张 chapter list 最终图人工目检。
- 阻塞项：无。
