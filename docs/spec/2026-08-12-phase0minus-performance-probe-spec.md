# 挂机武侠 · Phase 0− 怪海性能探针技术规格

> **日期**：2026-08-12
> **状态**：已审阅；实现中
> **遵循**：`GDD.md` v1.24、`CLAUDE.md` v1.42
> **上位方向**：`/Users/a10506/Desktop/挂机武侠_v2_最终方案_20260812.md`
> **执行计划**：`docs/superpowers/plans/2026-08-12-phase0minus-performance-probe.md`
> **本文件授权范围**：只定义可撤销的性能探针；不授权根项目引入 Flame，不授权生产接线，不授权读取正式存档。

## 0. 一句话裁决问题

> 在写实水墨横版场景尚未制作、玩法尚未设计前，先证明或证伪：目标最低档 Windows 与当前开发 Mac 能否在常规桌面视口，以稳定的 Profile 帧时间、受控内存和可复用对象池，承载 `20 个普通敌人 + 1 个精英 + 一次清场特效峰值`。

Phase 0− 只回答“技术负载能否承受”。它不能回答：

- 怪海是否符合武侠定位；
- 聚怪与清场是否好玩；
- Flame 是否进入正式产品；
- 旧 122 关、259 招、265 张敌人立绘、147 张背景如何迁移；
- 现有 3v3 是否保留；
- 手操与挂机经济如何并轨。

这些分别属于上位方向、Phase 0A、0C、Phase 1 前存量 ADR 与后续系统 spec。

## 1. 基线事实

### 1.1 现有项目没有同屏怪海先例

- `MassBattleStrategy.enemyTeamsPerWave` 以 wave 替换敌队，单波仍走 `DefaultGroundStrategy` 的回合结算；“累计 5–7 人、2–4 wave”不等于同屏实时 20–30 个实体。
- 现有战斗表现是 Flutter Widget + `AnimationController`；根依赖没有 Flame。
- `GDD.md` §11.3 的正式选型仍是纯 Flutter Widget + `AnimationController`；明确的第三方引擎禁令在 `CLAUDE.md` §9。v2 用户决策只给 Phase 0−/0A 一个隔离验证例外，0C 才能申请生产栈变更。

因此不得用现有群战“已经能跑”推导怪海可行，也不得在 0− 通过后直接批量改造生产内容。

### 1.2 可复用的本地先例

- `lib/features/debug/application/battle_frame_profile.dart` 已使用 `SchedulerBinding.instance.addTimingsCallback` 采集 `FrameTiming`，证明项目具备 Profile 帧采集先例。
- 现有采集只记录 build/raster 最大值与连续超预算；0− 必须扩展为原始时序、`totalSpan`、p50/p95/p99、严重超限、场景 checksum、内存、GC、对象池与跨平台报告。
- `visualRouteIsarDirectory` 与对应守卫测试记录了真实风险：视觉路由曾裸调 `IsarSetup.init()`，可能打开/迁移玩家真实档；seed 服务 `_clearAll()` 会清空业务 collection。PR #120 已修复该路径。0− 必须比视觉路由更彻底——**完全不链接 Isar**，而不只是换一个目录。

### 1.3 当前开发机基线（仅记录，不是执行结果）

2026-08-12 现查：

| 项目 | 当前值 |
|---|---|
| Flutter | 3.41.5 stable |
| Dart | 3.11.3 |
| macOS | 26.4 |
| SoC | Apple M5，10 核 GPU |
| 内存 | 32GB |
| 可用 60Hz 外接屏 | 2560×1440 |
| 高刷外接屏 | 5120×2880，UI 2560×1440，144Hz |

正式报告必须在 run 当天重新采集版本、硬件、显示器和 driver；本表不能代替结果 manifest。

## 2. 隔离架构

### 2.1 推荐形态

后续实现使用独立 Flutter/Flame 探针包，例如：

```text
tools/phase0minus_probe/
├── pubspec.yaml                 # Flame 只在此处；根 pubspec 不动
├── .gitignore                   # 忽略 nested package 的 build/.dart_tool/结果原始文件
├── assets/probe_scenarios.yaml  # 所有负载与 Gate 数值
├── lib/
│   ├── main.dart
│   ├── probe_game.dart
│   ├── workload/
│   ├── metrics/
│   └── report/
├── test/
└── build/results/               # raw 产物，不提交
```

目录名只是推荐，实际实现可调整，但必须满足：

1. 根 `pubspec.yaml` / `pubspec.lock` 不出现 Flame；
2. 探针不得 import `package:wuxia_idle/...` 的 Isar、repository、seed、reward 或 production navigation；
3. 探针不成为正式应用 route，不从主菜单、debug menu 或 visual route 进入；
4. 独立构建 Mac/Windows Profile 可执行文件；
5. 0C 若决定不保留 Flame，删除探针不会影响正式游戏加载和测试。

### 2.2 数据与文案约束

- 敌人数、速度、半径、攻击名额、粒子数、时间盒、阈值等全部来自 `probe_scenarios.yaml`；不得散写在 Dart。
- 固定随机种子和脚本版本写入 scenario 文件，报告记录文件 SHA-256。
- 原型不展示玩家叙事文案；必要标签使用探针内部集中 strings，不把中文散写到组件。
- 不读取正式 `data/*.yaml`，避免把性能探针误变成生产数值接线。

### 2.3 明确禁止

- `IsarSetup.init()`、`Isar.open()`、`GameRepository.loadAllDefs()`；
- import `phase2_seed_service.dart` 或调用任何 `_clearAll()` 同类业务清库逻辑；
- `getApplicationDocumentsDirectory()`、SharedPreferences、正式存档槽目录；
- 发放角色经验、装备、真意、货币、关卡胜利或任何长期进度；
- 访问网络、遥测上传或公开分发；
- 在 Debug 模式用 FPS overlay 截图宣称通过；
- 为跑过 Gate 临时减少场景负载但不更新 scenario checksum。

实现时增加静态契约测试：扫描探针源文件与依赖图，出现上述 production import/API 即失败。

## 3. 固定场景与代表性负载

### 3.1 坐标与视口

- 世界坐标：横向 `2400 logical px`，浅纵深 `480 logical px`。
- 相机：脚本化横向往返滚动，总位移 `1600 logical px`；不能固定不动，以覆盖 transform/culling。
- 玩家：沿固定折线路径移动并自动朝鼠标代理方向攻击；使用固定 seed，三次 run 的路径、技能时点和清场时点一致。
- 常规桌面视口：`1280×720`、`1440×900`。
- Windows：OS 缩放固定 100%，目标 DPR 1.0，显示器 60Hz。
- Mac：优先在 60Hz、DPR 1.0 的 2560×1440 外接屏执行；若实际 DPR/刷新率不同，必须记录并把结果标为不同环境，不得隐去。

报告同时记录：逻辑视口、物理 framebuffer、DPR、刷新率、全屏/窗口态。`1280×720` 指逻辑窗口，不得只改截图裁切尺寸。

### 3.2 玩家代理

固定 1 个玩家代理：

- 8 方向移动/朝向状态；
- 待机、移动、普攻、清场、受击 5 个动画状态；
- 1 个 hurt circle、1 个移动碰撞 circle、普攻与清场各 1 组 hitbox；
- 1 条 HP、1 条真气、2 个技能冷却 HUD；
- 每轮脚本执行移动、普攻、受击、清场和短暂恢复，不允许站桩只渲染静态精灵。

动画使用低成本代理序列或 atlas，但必须每帧推进；单色矩形静止不算“带简单动画的代理”。代理资产规格与帧数写入 manifest。

### 3.3 普通敌人代理

每个普通敌人必须同时具备：

- 待机、移动、攻击、受击、死亡 5 个状态；
- 简单追击 + 近身分离/绕行；
- 空间索引查询邻居，而非全量 O(n²) 两两遍历作为最终方案；
- 1 个移动碰撞 circle、1 个 hurt circle、1 个短时 attack hitbox；
- 受击击退、死亡退池；
- 非攻击者在外围包围/威吓，不能所有实体同帧攻击。

### 3.4 精英代理

目标档额外 1 个精英：

- 体型/碰撞半径大于普通敌人；
- 每 `2.5s` 产生一次可见蓄力预警；
- 占用 1 个独立进攻名额；
- 有持续 aura 或轮廓效果；
- 清场事件中走受击、击退、死亡/幸存分支，不能只作为普通敌人换色。

### 3.5 攻击名额与 AI

- 近战进攻名额固定 4；精英另有 1 个独立名额。
- 无名额的敌人仍进行追击、分离、包围和动画更新。
- 每 `2.5s` 重新调度精英蓄力；普通敌人攻击节奏由固定 seed 产生。
- 同一脚本在各档位只改变实体规模，不改变玩家路线、清场时点或相机时点。

这不是正式 AI 设计，只是让 CPU、碰撞、动画与调度负载接近 0A，而不是测 30 张静态图片。

### 3.6 碰撞与空间索引

- 空间索引建议 uniform grid / spatial hash；cell size 由 YAML 配置，首值 `96 logical px`。
- 每帧更新移动实体所在 cell。
- 覆盖：玩家—敌人、敌人—敌人分离、attack hitbox—hurtbox、击退后的边界约束。
- 报告记录每帧 broad-phase candidate 数、narrow-phase check 数的 p50/p99/max。
- 若实现阶段选择别的索引，须保持同一负载与报告字段，并说明复杂度和原因。

### 3.7 清场峰值

每 `10s` 触发一次固定清场事件；预热期至少完整触发一次，采样期至少触发 6 次。

峰值组件预算：

| 组件 | 基线 10 | 目标 20+1 | 压力 30 |
|---|---:|---:|---:|
| 敌人死亡墨片（每敌 6） | 60 | 126 | 180 |
| 中心墨爆粒子 | 64 | 64 | 64 |
| 残影/轨迹 | 32 | 32 | 32 |
| 同屏伤害数字上限 | 10 | 12 | 12 |
| 峰值效果实体预算 | 166 | 234 | 288 |

约束：

- 所有粒子/残影/伤害数字必须真实创建、更新、衰减与退池；不能只在报告里计数。
- 同一技能实例只触发一次主 hit-stop/震屏代理，不能按命中数叠加。
- 伤害数字有显示上限，但报告另记实际命中数与被合并数。
- 敌人死亡允许在 `120ms` 窗口内确定性错帧，以模拟正式方案的错峰退场；错峰参数固定，不得为某平台私改。

### 3.8 Flutter HUD 覆盖层

HUD 通过 Flutter overlay 覆盖 Flame 画面，至少包含：

- 玩家 HP、真气；
- 2 个技能冷却；
- 当前敌人数、档位名；
- 暂停/恢复状态。

HUD 以代表性频率更新；HP/真气/冷却可按帧或固定 tick 更新，但频率写入 YAML/manifest。测量阶段禁止显示滚动帧图、逐帧日志或 DevTools overlay，以免监控工具污染被测对象。性能摘要在 run 结束后输出。

## 4. 三档场景

| 档位 ID | 实体 | 精英 | 清场峰值 | 用途 | Gate |
|---|---:|---:|---:|---|---|
| `baseline_10` | 10 普通 | 0 | 166 效果实体 | 建立最低成本与缩放基线 | 必须记录；失败直接 FAIL |
| `target_20_plus_1` | 20 普通 | 1 | 234 效果实体 | 首轮正式体验目标 | **硬 Gate** |
| `stress_30` | 30 普通 | 0 | 288 效果实体 | 观察退化曲线和余量 | 首轮只记录，不自动成为正式密度 |

说明：

- `30` 档不因为性能通过就授权正式内容同屏 30 人。怪群密度首先服从写实武侠定位。
- `40–60` 是单战斗区或整关累计叙事规模，不进入 0− 同屏硬 Gate。
- 0A 若增加新的玩法状态，仍须保留这三档作为性能回归对照。

## 5. 执行矩阵

### 5.1 每个平台的固定矩阵

| 维度 | 值 |
|---|---|
| 模式 | Flutter Profile |
| 视口 | 1280×720、1440×900 |
| 档位 | 10、20+1、30 |
| 冷启动 | 每平台至少 1 次，不计稳定 p99 Gate |
| 稳态重复 | 每个“视口×档位”3 个有效 run |
| 单 run 预热 | 12 秒；必须完整包含第 10 秒的第一次真实清场，避免冷启动着色/渲染路径与采样边界竞争 |
| 单 run 采样 | 60 秒 |
| 单 run 冷却观察 | 30 秒 |
| 随机性 | 固定 seed；seed 与脚本 checksum 进 manifest |

每个平台合计至少 `2×3×3 = 18` 个稳态 run，另有冷启动 run。不得把三次连跑拼成一个 180 秒样本后只算一个 p99。

### 5.2 运行环境控制

- 接通电源，关闭低电量模式；Windows 使用“最佳性能/高性能”。
- 关闭浏览器视频、IDE 索引、同步盘等明显后台负载；报告列出仍运行的已知高负载进程。
- 窗口置前、可见、未遮挡；最小化、失焦暂停、屏保、远程桌面降帧期间的 run 一律无效。
- 固定 60Hz；若平台无法设置，记录真实刷新率并重跑，不与 60Hz Gate 混签。
- Windows 缩放 100%；GPU 驱动版本、独显/核显选择写入报告。
- Profile 可执行必须来自同一 git commit 与相同 scenario checksum。

## 6. 帧时间采集与统计

### 6.1 数据源

使用 `SchedulerBinding.instance.addTimingsCallback` 采集每帧 `FrameTiming`，至少写出：

- `frameNumber` / 单调序号；
- `timestampUs`；
- `buildDurationUs`；
- `rasterDurationUs`；
- `totalSpanUs`；
- 当前档位、视口、清场事件序号；
- 当前 active/pool 计数；
- 当前 RSS。

硬 Gate 使用 `totalSpan`；build/raster 用于归因。不能用 `1000 / 平均 FPS` 反推 p99。

### 6.2 预热与有效样本

- 启动后 10 秒不进入稳定统计；预热必须覆盖至少一次相机全程、攻击调度和清场峰值。
- 采样 60 秒，60Hz 环境有效帧数应 ≥3000；少于 3000 标记 `INVALID_INSUFFICIENT_FRAMES`。
- callback 返回批量 timings 时按 `frameNumber`/回调顺序还原时序；连续超限不能按排序后的时长计算。
- 若 run 中窗口最小化、设备睡眠、断点或 debugger pause，整次 run 无效，不手工删掉个别坏帧。

### 6.3 百分位算法

统一采用 nearest-rank，不插值：

```text
sorted = durationsUs ascending
rank = ceil(percentile * N)
value = sorted[clamp(rank - 1, 0, N - 1)]
```

报告 p50、p95、p99、max，单位保留到 `0.001ms`；原始值保留整数微秒。统计函数须有固定序列 unit test，防语言库默认算法漂移。

### 6.4 超限定义

| 指标 | 定义 |
|---|---|
| 正常帧预算 | `totalSpan < 16.6ms` |
| 超预算帧 | `totalSpan >= 16.6ms` |
| 严重超限帧 | `totalSpan > 33.3ms` |
| 连续严重超限 | 原始时间序列中连续 2 帧 `>33.3ms` |
| 冷启动尖峰 | 预热前第一次资源/特效使用产生的 max，单独报告 |

临界值语义按上表固定；目标 Gate 是 `p99 <16.6ms`（严格小于）且连续严重超限为 0。

### 6.5 多 run 聚合

- 每个 run 先独立判定，不把 3 个 run 混池后计算一个“好看的总 p99”。
- 硬 Gate 要求目标档 3/3 run 均通过；报告同时给出三次 p99 的中位数与最差值。
- 任一 run 无效必须重跑；任一有效 run 失败即该“平台×视口×档位”失败，除非证明是外部系统事件并完整重跑 3 次。

## 7. 内存、GC 与对象池

### 7.1 进程内存

每秒记录：

- `ProcessInfo.currentRss`；
- `ProcessInfo.maxRss`；
- 采样前基线、预热后基线、清场峰值、60 秒采样末、30 秒冷却末；
- 如平台可得，补充 private working set / resident private bytes。

首轮硬判：

1. 冷却末 RSS 不得高于预热后基线 `max(10%, 64MiB)`；
2. 连续 6 次清场后的每轮冷却谷值不得形成明显单调增长；
3. 三次 run 的末端 RSS 不得逐次无界抬升。

若 RSS 受平台 allocator 保留策略影响而超过阈值，不能直接删 Gate；须结合 heap/池计数证明“保留但可复用”，由报告列为 NEEDS_REVIEW。

### 7.2 GC 采集

Profile run 打开固定 VM service 端口，由配套 collector 订阅 VM/GC 事件或导出 DevTools Memory timeline；探针应用内不得为采样主动触发 GC。每次记录：

- new-space / old-space GC 次数；
- 每次 GC 开始/结束时间与 pause；
- GC 前后 heap used；
- 与 `>16.6ms`、`>33.3ms` 帧的时间关联；
- 单次最长 pause、采样期累计 pause。

GC 字段若因平台/Flutter 版本不可得，run 可完成但标记 `GC_TELEMETRY_MISSING`，整个 Phase 0− 不得判 PASS，必须先修采集或由人类明确降级证据要求。

首轮判红：

- 同一种清场峰值可稳定复现 GC + 连续严重超限；
- old-space 在 6 次清场后只升不降且对象池 active 已归零；
- 单次 GC pause `>33.3ms` 并在 3 个 run 中重复出现。

### 7.3 对象池

至少为以下类型独立记录：

- enemy；
- particle；
- afterimage/trail；
- damage label；
- hitbox/temporary effect（如实现使用）。

每类写出：

- `createdTotal`；
- `acquiredTotal` / `releasedTotal`；
- `reusedTotal`；
- `activeCurrent` / `activePeak`；
- `freeCurrent`；
- `allocationAfterWarmup`。

硬不变量：

1. `createdTotal = activeCurrent + freeCurrent`（不含明确销毁的类型；若允许销毁须另列）；
2. 每次场景复位后 active 回到固定基线；
3. 预热覆盖最大峰值后，采样期新增分配不超过该类池峰值的 5%；
4. 清场后粒子、残影、伤害数字在生命周期结束时全部 release；
5. 任何计数负数、重复 release、active 逐轮增加均直接 FAIL。

### 7.4 日志噪声

- 采样期不得每帧 `debugPrint`；原始数据缓冲后批量写文件。
- 控制台只输出 run 开始、无效原因、结束 summary 与结果文件路径。
- 报告采集本身的 CPU/IO 开销须通过“启用/禁用 raw writer”对照一次；退化超过 5% 时改为环形 buffer 或后台批量写。

## 8. Mac 与 Windows 报告格式

### 8.1 产物结构

建议产物：

```text
build/phase0minus_results/<commit>/<platform>/<timestamp>/
├── manifest.json
├── frames.jsonl
├── memory_gc.jsonl
├── pool.jsonl
├── summary.json
├── summary.csv
└── run.log
```

原始文件不提交仓库；生成 SHA-256 manifest。仓库只提交一份短的裁决报告，例如：

`docs/phase0/2026-08-13-phase0minus-macos-baseline.md`(实际落点,原示例 docs/performance/ 目录从未建立)

### 8.2 manifest 必填字段

- git commit、branch、dirty 状态；dirty run 不用于最终 Gate；
- 根项目 commit 与探针包 commit（若不同）；
- scenario 文件路径、版本、SHA-256、seed；
- Flutter、Dart、Flame 版本；
- build mode 与完整命令；
- OS 版本、CPU、核心/线程、RAM；
- GPU、driver、渲染后端；
- 显示器、刷新率、OS 缩放、DPR、逻辑/物理视口；
- 电源模式、是否远程桌面；
- warmup/sample/cooldown 时长；
- collector 版本和结果文件 SHA-256。

### 8.3 单 run 汇总表

| 字段 | 说明 |
|---|---|
| run_id | 平台-视口-档位-重复序号 |
| validity | VALID / INVALID + 原因 |
| frames | 有效帧数 |
| p50/p95/p99/max total | 帧总耗时 |
| p99 build/raster | 归因 |
| over_16_6_count/pct | 超预算帧 |
| over_33_3_count | 严重超限帧 |
| max_consecutive_over_33_3 | 连续严重超限 |
| cold_first_clear_max | 冷启动清场尖峰 |
| rss_baseline/peak/end/cooldown | 内存 |
| gc_count/max_pause/total_pause | GC |
| pool_created/reused/peak/leaked | 对象池 |
| broad/narrow checks p99 | 碰撞负载 |
| gate | PASS / FAIL / INVALID / REVIEW |

### 8.4 平台总表

每个平台必须同时展示两个视口、三个档位、三次 run；禁止只报告最好一次：

| 视口 | 档位 | run1 p99 | run2 p99 | run3 p99 | 最差连续 33.3ms | RSS/GC | 结论 |
|---|---|---:|---:|---:|---:|---|---|

### 8.5 最终裁决块

报告首页必须有：

```text
Mac target gate: PASS / FAIL / BLOCKED
Windows minimum-spec gate: PASS / FAIL / BLOCKED
Overall: PASS / PASS_WITH_LOWER_DENSITY / FAIL / BLOCKED
Approved max Phase 0A target: __ active enemies
Unresolved risks: __
Decision owner/date: __
```

## 9. 目标 Windows 最低配置

### 9.1 首轮候选最低档

本规格提出以下 **验证用最低档候选**，待项目主人确认后成为 0− Gate 的目标机。它不是最终商店页承诺：

| 项目 | 最低档候选 |
|---|---|
| OS | Windows 10 22H2 或 Windows 11，64-bit |
| CPU | 4 核 8 线程，性能不高于/不优于 Intel Core i5-8250U 级别作为门槛样本 |
| GPU | DirectX 11 核显，性能以 Intel UHD 620 级别为目标下界 |
| 内存 | 8GB |
| 存储 | SSD，至少 2GB 可用空间（探针本身不代表最终包体） |
| 显示 | 60Hz，1280×720 与 1440×900，100% 缩放 |
| 电源 | 插电，最佳性能模式 |

选择这一档的目的，是给 2D 买断制桌面游戏一个保守下界。若项目主人认为过低，可在开跑前改一次；不能看完失败结果后无记录地抬配置。

### 9.2 实机有效性

- 最优证据是一台实际 i5-8250U/UHD 620/8GB 或更弱但仍属支持范围的机器。
- 更强机器通过不能证明最低档通过。
- 若只有离散显卡机器，必须确认进程实际使用目标 GPU；不能用 GTX/RTX 结果代签 UHD 620。
- 虚拟机、云桌面、远程桌面不作为 Gate 证据。
- 目标机不就绪时 Overall = BLOCKED；允许先完成 Mac 报告，但不得进入 Phase 0A。

### 9.3 Windows 渲染差异

Flutter Windows 与 macOS 的渲染后端、driver、DPR 与调度特征不同。报告必须写明实际 renderer，不得把“同 Flutter 版本”当成等价环境。Windows 若单独失败，应先判定：

1. GPU/driver/renderer；
2. OS 缩放与 framebuffer；
3. shader/首次资源；
4. HUD/raster；
5. AI/collision/build；
6. 对象池/GC。

不能只说“Flutter 桌面性能不好”。

## 10. Gate 与失败降级

### 10.1 PASS

以下全部成立才 PASS：

- Mac、最低档 Windows 均完成有效矩阵；
- 两视口的目标档 3/3 run `p99(totalSpan) <16.6ms`；
- 目标档连续 2 帧 `>33.3ms` 为 0；
- baseline 不失败；
- 内存、GC、对象池无硬失败；
- 报告、manifest、原始文件 checksum 齐全；
- 根应用、Isar、正式存档零接线。

### 10.2 优化顺序（只允许时间盒内）

1. 修重复分配、对象池泄漏和每帧日志；
2. 空间索引与候选碰撞数；
3. HUD rebuild 频率与 overlay 范围；
4. 粒子、残影、伤害数字的池化和上限；
5. 死亡错帧、AI tick 分频；
6. atlas/纹理尺寸与绘制批次；
7. 最后才讨论降低同屏密度。

每次优化必须保留 before/after 同场景对照。不得一次改多个变量后无法归因。

### 10.3 失败分支

| 结果 | 处置 |
|---|---|
| 10 档也失败 | 直接 FAIL；停止 Flame 怪海主路线或更换验证载体重做 0− |
| 10 通过、20+1 失败 | 先按 §10.2 优化；仍失败则只可降密度并回到上位定位拍板 |
| Mac 通过、Windows 失败 | 不进入 0A；在“提高最低配置 / 降密度 / 换载体”三选一 |
| 帧时间通过、内存/池失败 | FAIL；不能以平均 FPS 掩盖长期不稳定 |
| 30 压力档失败、20+1 通过 | 仍可 PASS；正式同屏目标不得默认为 30 |
| GC telemetry 缺失 | BLOCKED；补采集后重跑 |
| Isar/玩家目录被访问 | 立即停止、判安全 Gate FAIL，先修隔离并审计受影响文件 |

### 10.4 降低密度的规则

若最终只能稳定在 12–16 活跃敌人：

- 必须更新 v2 的目标档和 Phase 0A 场景；
- 通过分批入场、外围非实体威吓、击溃/逃散、镜头外队列维持“众敌围攻”意象；
- 不得把累计 40–60 人写成同屏性能已验证；
- Overall 标为 `PASS_WITH_LOWER_DENSITY`，由项目主人确认后才能进入 0A。

## 11. 时间盒

| 节点 | 上限 | 超时动作 |
|---|---:|---|
| 首个 30 代理 + 一条 FrameTiming 报告 | 0.5 工作日 | 暂停并复核载体/工具链，不继续美化 |
| 三档负载 + 采集器 + targeted tests | 1 工作日 | 缩到最小可裁决实现，不加玩法 |
| Mac 完整矩阵与一次定向优化 | 累计 2 工作日 | 输出 PASS/FAIL，不无限调参 |
| Windows 构建、矩阵和报告 | 目标机就绪后 1 工作日 | BLOCKED/FAIL，列明链路问题 |
| Phase 0− 总实现 | 3 工作日目标，5 工作日硬上限 | 停止继续投入，交人类裁决 |

等待目标 Windows 设备的日历时间不计实现工时，但恢复点必须每天可见地写明 BLOCKED 原因；不得在等待期间越界开始 0A。

## 12. 测试者与分发

Phase 0− **不适用**上位方案的“2 挂机 + 2 ARPG + 2 混合”6 人玩法样本：

- 本阶段无玩法主观结论，不招募体验测试者；
- 只需要 1 名 Mac 操作员和 1 名目标 Windows 操作员，按同一 runbook 执行；可以是同一人；
- Windows 产物只私下交给目标机操作员，不公开发包、不上 itch.io、不做 beta；
- 产物附 SHA-256、commit、运行命令、预期输出目录和无效 run 判定；
- 6 人招募、远程/当面方式、问卷和可执行分发从 Phase 0A 前置准备开始。

因此“没人试玩”不会阻塞 0−；“没有最低档 Windows 实机”会阻塞 0−。

## 13. 红线影响

| 红线 | 影响 |
|---|---|
| §5.1 反主流清单 | 无体力、日课、抽卡、VIP、登录奖励；无经济系统 |
| §5.3 三系锁死 | 不读取角色/装备/心法，不产生境界或掉落，无影响 |
| §5.4 数值红线 | 代理 HP/攻击不代表玩法数值；不接 `DamageCalculator`，不改生产 YAML |
| §5.5 在线=离线 | 无挂机收益、在线 buff、快进或计时奖励，无影响 |
| §5.6 不硬编码 | 探针负载与阈值进独立 YAML；不向生产 Dart 写中文/数值 |
| 水墨克制 | 0− 使用代理资产，不做风格结论；清场粒子数量只为性能预算 |
| Flame 禁令 | 仅独立探针验证例外；根应用生产依赖仍禁止，0C 前不得接入 |
| 存档安全 | 不链接 Isar、不访问 app documents、不写任何正式进度 |

## 14. Targeted tests 与破坏证红

后续实现至少包含：

1. nearest-rank p50/p95/p99 固定序列；
2. `16.6ms` 边界和严格小于语义；
3. 连续 2 帧 `>33.3ms` 时间序列；
4. warmup 样本排除、帧数不足、最小化/暂停 invalid；
5. 三档实体、精英、粒子、伤害数字峰值与 YAML 一致；
6. 相同 seed 的事件计数/checksum 一致；
7. 对象池 acquire/release、不重复 release、复位回基线、预热后分配上限；
8. RSS 冷却阈值与 REVIEW 分支；
9. 报告必填字段、SHA-256、dirty run 拒绝；
10. 探针源与依赖不含 Isar、application documents、production seed/reward import；
11. root `pubspec.yaml` / `pubspec.lock` 无 Flame；
12. 两视口窗口参数进入 manifest。

至少做三次破坏证红：

- 把构造样本 p99 提到 `16.6ms`，确认严格门槛判失败；
- 故意漏 release 一个 pool 对象，确认复位不变量判失败；
- 在探针源 fixture 注入 `IsarSetup.init`，确认隔离契约测试判失败。

真实性能 Gate 本身不能由 unit test 替代。

## 15. Phase 0A 交接条件

只有 Overall = PASS，或项目主人明确接受 `PASS_WITH_LOWER_DENSITY`，才可进入 0A。交接必须包含：

- 通过的最大目标档与两个视口；
- 三档原始性能曲线；
- 固定 scenario checksum 和采集器版本；
- Phase 0A 不得删除的对象池、空间索引、HUD 和报告口径；
- 已知未覆盖：正式骨骼/网格动画、正式纹理尺寸、音效、正式场景多层、完整技能、正式掉落；
- 0A 每次改动后仍跑 `20+1 + 清场峰值`（或拍板后的降低档）性能回归。

Phase 0− 通过不授权：

- 把 30/60 同屏写入 GDD；
- 根项目加入 Flame；
- 改造正式存档或奖励；
- 批量迁移旧内容；
- 宣称已经达到暗黑/鬼谷手感。

## 16. 已拍板边界与剩余阻塞

1. **Windows 最低档（已授权首轮候选）**：i5-8250U / UHD 620 / 8GB 作为首轮验证下界；若后续商业最低配置变化，须在第一次对应实机 run 前换成明确型号/性能档并完整复跑。
2. **目标机可用性**：谁提供机器、何时可运行，是否能保证 100% 缩放与 60Hz。
3. **探针包位置（已授权）**：仓库内独立 `tools/phase0minus_probe`（含自身 `.gitignore`），便于复现、分发与版本锁定。
4. **隔离载体（已授权）**：Flame 只进入 `tools/phase0minus_probe/` 独立探针包；根 `pubspec.yaml`、根 lockfile、生产 `lib/` 与正式存档保持不变。
5. **GC collector**：实现时优先用 VM service 自动采集；若首版没有稳定自动采集，须标记 `GC_TELEMETRY_MISSING` 并保持 Gate 未通过，且不得在应用内主动触发 GC 或静默省略。

除上述边界与阻塞外，Phase 0− 不依赖出战门人、旧 3v3 去留、存量内容处置、真意 schema 或手操奖励拍板。
