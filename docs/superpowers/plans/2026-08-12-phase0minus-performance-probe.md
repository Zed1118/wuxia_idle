# Phase 0− 怪海性能探针 · 可恢复执行计划

> **日期**：2026-08-12
> **分支**：`codex/phase0minus-performance-probe`
> **worktree**：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/phase0minus-performance-probe`
> **上位输入**：`/Users/a10506/Desktop/挂机武侠_v2_最终方案_20260812.md` §9.3、§9.4、§11 `Phase 0−`
> **技术规格**：`docs/spec/2026-08-12-phase0minus-performance-probe-spec.md`
> **性质**：Phase 0− 可撤销技术验证；不是生产接入、不是 Flame 生产依赖授权、不是 Phase 0A 玩法验证。

## 1. 目标

在不接入正式存档、成长、战斗结算和生产导航的前提下，用隔离的 Flame 原型验证：

1. 当前开发 Mac 与目标最低档 Windows，能否在常规桌面视口稳定承载 `20 个普通敌人 + 1 个精英代理 + 清场特效峰值`；
2. 从 10 敌人到 20+1、30 敌人的帧时间、内存、GC 与对象池退化曲线是否可控；
3. 若目标档失败，问题是否能在严格时间盒内通过对象池、空间索引、特效上限与 HUD 更新频率解决；
4. 是否有足够证据批准 Phase 0A，或应降低密度、调整 Windows 最低配置、换验证载体、停止怪海主路线。

本任务不验证“好不好玩”，也不验证正式美术、259 招、122 关、旧 3v3 迁移或长期经济。

## 2. 现状事实与授权边界

- 现有 `MassBattleStrategy` 是多 wave 回合结算；每波替换一支敌队，并非实时同屏高密度实体。项目没有可直接外推到 20–30 实体的生产性能先例。
- 仓库已有 `BattleFrameProfileProbe`，通过 `SchedulerBinding.addTimingsCallback` 记录 build/raster；0− 可复用采集思想，但须补齐 `totalSpan`、p99、连续超限、原始样本和跨平台报告。
- 根 `pubspec.yaml` 当前没有 Flame；`GDD.md` §11.3 的正式选型仍是纯 Flutter Widget + `AnimationController`，明确的第三方引擎禁令在 `CLAUDE.md` §9。用户批准的 v2 只授权 **Phase 0−/0A 隔离验证载体**，不等于允许根应用生产依赖。
- 实现阶段应使用独立探针包/可执行入口；根应用的 `lib/`、`data/`、根 `pubspec.yaml`、生产路由和正式 Isar 均不接线。0C 才决定是否申请生产引入 Flame，并同步设计真相源。
- 本计划文件与技术规格本身不添加依赖、不实现代码、不提交。

## 3. 本批文档验收标准

- [x] 计划文件包含目标、分支/worktree、验收标准、任务切片、当前恢复点，满足 `CLAUDE.md` §8.0。
- [x] 技术规格定义三档固定负载、两种常规桌面视口、Profile 采集、p99 算法、帧超限、内存/GC/对象池、Mac/Windows 报告和 Gate。
- [x] 明确目标 Windows 最低配置候选、实机要求、无目标机时的阻塞语义。
- [x] 明确时间盒、失败降级、停止条件、Phase 0A 准入条件。
- [x] 明确不读取/写入 Isar，不调用 `IsarSetup`，不复用会 `_clearAll()` 的 seed 服务。
- [x] 明确 Phase 0− 不招募 6 人体验测试；只需两平台操作员执行同一脚本，试玩招募/分发从 0A 开始。
- [x] 本批只新增这两个 Markdown 文件；`git diff --name-only` 不出现代码、数据、根 `pubspec.yaml` 或 lockfile。

## 4. Phase 0− 运行 Gate

### 4.1 必须通过

- Mac 和目标最低档 Windows 均以 Profile 模式运行；Debug/Widget test 帧时间不得作为通过证据。
- `1280×720`、`1440×900` 两个常规桌面视口都跑三档固定场景；记录逻辑尺寸、物理尺寸、DPR、刷新率和 OS 缩放。
- 目标档 `20 普通敌人 + 1 精英 + 清场峰值`：每个有效 run 的 `p99(totalSpan) < 16.6ms`。
- 目标档不存在连续 2 帧 `totalSpan > 33.3ms`。
- 每场采样期 ≥60 秒、预热 ≥10 秒、有效帧数达到规格下限；每个“平台×视口×档位”至少 3 个有效 run。
- 对象池在预热后进入稳态；场景复位后 active 数回归基线，不出现逐轮增长。
- 进程 RSS 在冷却后不呈单调泄漏；GC/内存尖峰没有与连续严重超限共同构成稳定复现的卡顿。
- 任何正式 Isar 存档与应用文档目录均未被打开、迁移或写入。

### 4.2 只记录、不作为首轮硬门槛

- 压力档 `30 敌人 + 清场峰值` 的 p95/p99/最大帧、GC、RSS 与对象池退化曲线。
- 冷启动第一次全屏清场的 shader/资源首次使用尖峰。
- 当前开发 Mac 与 Windows 的绝对差异；两者硬件和 DPR 不同，不做伪精确横向等价。

### 4.3 裁决

- **PASS**：Mac 与目标最低档 Windows 的目标档全部硬 Gate 通过，批准起草/执行 Phase 0A。
- **PASS WITH LOWER DENSITY**：10 档稳定，20+1 稳定失败；只有在人类明确接受较低同屏密度并更新 v2 定位后，才可按新目标进入 0A。
- **BLOCKED**：没有符合最低配置定义的 Windows 实机、无法构建 Profile 包、指标采集链不可复现；不得用 Mac 结果代签 Windows。
- **FAIL**：时间盒内目标档仍失败、内存/对象池不稳、或隔离红线被破坏；停止怪海主路线或回到上位方案重新拍板。

## 5. `CLAUDE.md` §8.2 四证据验收清单

Phase 0− 是有意隔离的原型，四证据必须按以下口径交付，不能用“只是 PoC”跳过。

1. **生产接线证据（本任务为负向隔离证据）**
   - 根 `pubspec.yaml` 与 `pubspec.lock` 未引入 Flame；生产 `lib/`、路由、Isar、奖励结算零接线。
   - 提供独立探针入口、构建命令和真实桌面 Profile 可执行证据；不能只停在 unit fixture。
   - `git diff -- root pubspec/lib/data` 与依赖树证明生产面未被污染。
2. **targeted test 与实机结果**
   - p99、nearest-rank、连续帧、对象池回收、场景固定参数、禁止 Isar import 等 targeted tests 全绿。
   - Mac/Windows 两平台的真实 Profile 原始 JSONL、汇总 CSV/Markdown、命令、通过数和 SHA-256 齐全。
3. **红线影响说明**
   - 不改 §5.4 数值硬红线、三系锁死、在线=离线、反主流清单；无奖励、无经济、无日课。
   - 原型负载参数进探针 YAML，不在 Dart 散写玩法数值；原型 UI 不新增生产中文文案。
   - Flame 仅为独立验证例外；生产使用仍被 `CLAUDE.md` §9 的明确禁令拦截，且偏离 `GDD.md` §11.3 当前纯 Flutter 选型，须 0C 与人类拍板。
4. **残留风险**
   - 列清 Mac/Windows 渲染后端差异、DPR/刷新率差异、冷启动 shader 尖峰、最低配置样本只有一台、代理动画不等于正式骨骼资产、音频/正式场景未纳入等风险。

### UI/UX 加码

- 必跑 `1280×720` 与 `1440×900` 真桌面窗口，禁止只用超高/超长视口证明实体存在。
- HUD 须真实覆盖 Flame 画面；但测量时不显示每帧更新的调试曲线，避免探针测到自己的监控 UI。
- Phase 0− 没有正式交互验收；仍需确认窗口焦点、暂停/恢复、缩放或最小化不会让 run 被误记为有效样本。

## 6. 任务切片

### Slice 0：基线与决定冻结

- 读取 `CLAUDE.md`、`GDD.md`、rejected registry、桌面 v2、`MassBattleStrategy`、现有 frame profiler 与 Isar 隔离事故守卫。
- 冻结 Flutter/Dart、OS、硬件、显示器、视口、DPR、刷新率和根依赖基线。
- 输出本计划与技术规格；不改代码和依赖。

**Gate**：两份文档自包含，冲突与例外写清，工作树只含两份 Markdown。

### Slice 1：隔离探针骨架（后续实现任务）

- 建立独立探针包，Flame 只进入该包的依赖；根应用依赖不动。
- 建立确定性场景 YAML、固定 seed、独立入口与结果目录。
- 加静态守卫：禁止 import 根应用 Isar/seed/service，禁止访问 application documents。

**建议提交**：`隔离 Phase 0− 性能探针`

### Slice 2：三档代表负载

- 实装 1 玩家代理、10/20+1/30 敌人、动画、追击/分离、攻击名额、空间索引、碰撞、受击、击退、死亡。
- 实装固定峰值粒子、残影、限量伤害数字、相机滚动与 Flutter HUD。
- 对象池覆盖敌人、粒子、残影、伤害数字；所有计数进入报告。

**Gate**：相同 seed 重跑实体峰值与事件计数一致；三档不是只改屏幕上的数字标签。

**建议提交**：`实现性能探针固定负载`

### Slice 3：采集器与自动化

- 采集 `FrameTiming.totalSpan/buildDuration/rasterDuration` 原始序列。
- 实装 nearest-rank p50/p95/p99、16.6/33.3 超限、连续严重超限、RSS、GC、对象池和冷却内存。
- 输出 JSONL、CSV、summary、manifest 和 SHA-256；无效 run 自动标记，不进入 Gate 聚合。

**Gate**：统计函数 targeted tests 全绿；手工注入极端序列能稳定判红。

**建议提交**：`补齐探针性能采集与报告`

### Slice 4：Mac Profile 基线

- 当前开发 Mac 在 60Hz、DPR 1.0 外接显示器优先执行；若无法满足，记录真实参数并解释。
- 两视口 × 三档 × 3 run，另留冷启动 run。
- 生成 Mac 报告与优化前后对照；不得只贴平均 FPS。

**Gate**：目标档硬指标通过，或形成可复现的失败报告。

**建议提交**：`记录 Mac 怪海性能基线`

### Slice 5：目标最低档 Windows 实机

- 按 spec 的最低配置定义准备实机，100% 缩放、60Hz、插电高性能模式；记录 GPU/驱动/OS。
- 以同 commit、同 scenario checksum、同两视口、同三档执行 3 run。
- 若实机高于最低档，结果只算参考，不能签最低档 Gate。

**Gate**：目标档通过，或显式 BLOCKED/FAIL；Mac 不代签。

**建议提交**：`记录 Windows 最低档性能基线`

### Slice 6：裁决与恢复点

- 汇总 PASS / PASS WITH LOWER DENSITY / BLOCKED / FAIL。
- 列出实际工时、优化清单、未覆盖风险和 Phase 0A 可继承的边界。
- 若通过，0A 沿用同场景、采集器和目标档，不重写性能口径。

**建议提交**：`[READY] 完成 Phase 0− 性能裁决`

## 7. 时间盒

- **首个杀伤性探针**：0.5 个工作日内必须能启动 30 代理实体并输出一条真实 FrameTiming 报告；否则先停下复核工程风险。
- **Mac 完整 Gate**：累计不超过 2 个工作日。
- **Windows 构建、实机运行与总报告**：目标机已就绪时累计不超过 1 个工作日。
- **Phase 0− 总时间盒**：目标机已就绪时 3 个工作日；绝对上限 5 个工作日。达到上限仍不能裁决，不继续堆优化，转 BLOCKED/FAIL 由人类拍板。
- 等待 Windows 设备的日历时间不计实现工时，但必须在恢复点写明阻塞，不能先进入 0A。

## 8. 当前恢复点

- **状态**：Slice 0–4 已完成；Mac 最终 Profile 矩阵 18/18 个 run 通过完整单-run Gate。Windows 实机仍阻塞 Overall Gate。
- **最后完成**：
  - 核实现有群战为 wave 制，不是实时同屏先例；
  - 核实现有 `BattleFrameProfileProbe` 与视觉路由 Isar 隔离守卫；
  - 核实当前开发环境为 Flutter 3.41.5 / Dart 3.11.3 / macOS 26.4 / Apple M5 / 32GB；正式 run 仍须由报告重新采集并冻结；
  - 完成本计划与 `docs/spec/2026-08-12-phase0minus-performance-probe-spec.md`；
  - 在 `tools/phase0minus_probe/` 完成独立 Flame 1.38.0 桌面探针、三档固定负载、默认 Sweep 碰撞、对象池、Flutter HUD、FrameTiming/RSS/报告与两平台脚本；
  - 接通只读 VM service GC stream，不主动触发 GC；
  - 完成两视口 × 三档 × 3 run 的 Mac 最终矩阵：18/18 有效且单-run Gate 通过，最坏 p99 `2.440ms`、最坏单帧 `17.784ms`、连续严重帧 0、对象池预热后零分配；
  - 输出 `docs/phase0/2026-08-13-phase0minus-macos-baseline.md`。
- **下一步**：冻结并分发 Windows Profile 复跑包；目标最低档实机回传两视口 × 三档 × 3 run 与硬件/驱动 manifest 后，执行 Slice 5–6 总裁决。
- **已跑验证**：nested `flutter analyze` 通过；nested `flutter test` 17 项通过；根 `flutter analyze` 通过；Mac 18 个最终 Profile run 均产出 `frames.jsonl`、`memory_gc.jsonl`、`summary.json`、`manifest.json` 与 SHA-256。Mac Gate PASS；Phase 0− Overall 因 Windows 缺失保持 BLOCKED。
- **已拍板边界**：
  1. 首轮以“i5-8250U / Intel UHD 620 级核显 / 8GB”作为目标 Windows 最低档候选；若后续商业最低配置变化，须用新目标档复跑；
  2. Flame 只进入 `tools/phase0minus_probe/` 独立探针包，根应用依赖保持不变。
- **当前外部阻塞**：尚无满足目标档的 Windows 实机可用；允许先完成 Mac 基线和 Windows 复跑包，但 Overall Gate 必须保持 `BLOCKED`，不得进入 Phase 0A。
