# Phase 0A 横版怪海玩法灰盒 · 可恢复执行计划

> **日期**：2026-08-13  
> **建议分支**：`codex/phase0a-gameplay-greybox`（从 Phase 0− 冻结 tip 建新分支/独立 worktree；不直接在已交付的 0− 分支继续堆叠）  
> **当前文档 worktree**：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/phase0minus-performance-probe`  
> **技术规格**：`docs/spec/2026-08-13-phase0a-gameplay-greybox-spec.md`  
> **上位输入**：`/Users/a10506/Desktop/挂机武侠_v2_最终方案_20260812.md` §11 Phase 0A  
> **性能基线**：`docs/phase0/2026-08-13-phase0minus-macos-baseline.md`  
> **性质**：可撤销的玩法验证；不是生产接线、不是美术样片、不是 Windows 发布签字。

## 1. 目标

在 10 个工作日硬时间盒内，沿用 Phase 0− 的独立 Flame 包和性能采集器，实现一个能被真人盲测的最小战斗循环：

```text
WASD 浅纵深移动 + 鼠标瞄准
        ↓
移动普攻积真气 / 身法脱困
        ↓
聚怪整理站位
        ↓
识别精英蓄力并破招
        ↓
范围清场成片击溃
        ↓
换气 → 下一批 / 再打一轮
```

本阶段必须证明：

1. 无正式美术时，聚怪后成片清场仍有明确释放感；
2. 身法、聚怪、破招不是装饰按键，各有不可替代的作用；
3. `20 普通怪 + 1 精英` 中主角、预警、聚怪落点和精英蓄力仍可读；
4. 6 名独立测试者中多数愿意主动再打，并认为优于现有点招战斗；
5. 玩法增量在 Mac 上仍满足 0− 帧时、GC、对象池和隔离约束；
6. 没有 Windows 最低档实机报告时，结论最多只到 `LOCAL_PASS_WINDOWS_PENDING`。

## 2. 范围

### 2.1 必须实现

- 单个无身份白盒门人，无 AI 队友、无换人；
- 横向卷轴、浅纵深地带、WASD + 鼠标世界瞄准；
- 按住左键移动普攻；
- `Space` 身法、`Q` 聚怪、`R` 清场；
- 真气、CD、一个指令缓冲、每 `castId` 触发去重；
- 普通近战杂兵、3 攻击名额、包围/分离/击退/死亡；
- 一种精英：`1.2s` 蓄力预警、2 点破势值、成功踉跄/失败重击；
- 10 → 20 → 20+1 三批固定流程、换气、死亡/重开/再打一轮；
- 命中停顿、击退、错帧死亡、有界镜震、墨迹/残影代理和分层 HUD；
- 人工试玩模式 + 确定性性能回放模式；
- 测试包、键位卡、问卷/观察表、Mac 报告与 Windows 复跑说明。

### 2.2 明确不做

- 跳跃、空中连段、手柄正式映射、改键；
- AI 队友、战中换人、援护、第四个主动技能；
- 三流派、正式门人数据、境界/装备/心法/真意；
- 正式数值公式、掉落、背包、结算、自动攻克、离线挂机；
- 正式骨骼/网格美术、正式声音资产、剧情；
- 生产路由、Riverpod、Isar、saveVersion、奖励或根项目 Flame 依赖；
- 改造 122 关、259 招、265 张敌人立绘或 147 张背景；
- 开始 Phase 0B/0C 或以“既然灰盒好玩”为由接生产。

## 3. 执行前置

### 3.1 必须冻结的输入

- [ ] Phase 0− 当前 tip commit、`probe_scenarios.yaml` checksum、Mac 基线报告已记录；
- [ ] 从冻结 tip 创建 0A 独立分支/worktree，不把 0− 已交付分支变回 WIP；
- [ ] `tools/phase0minus_probe/` 当前 nested tests/analyze 和根 `flutter analyze` 为绿；
- [ ] 0A 独立 app identifier、结果目录和源码隔离守卫方案已确认；
- [ ] 6 名正式测试者 + 2 名候补的类型、排期、输入设备和测试方式已登记；
- [ ] 问卷、观察表、当前生产对照段和 3/3 反顺序已冻结；
- [ ] 一名人类裁决责任人已确认。

测试者名单未就绪不阻止 Slice 1–6 实现，但阻止冻结正式测试包和主观 Gate 签字。

### 3.2 实现起点

保留现有：

- `tools/phase0minus_probe/lib/main.dart` 作为 0− 入口；
- `assets/probe_scenarios.yaml` 与既有三档负载语义；
- `metrics/`、`report/`、`run/` 采集链；
- 对象池、空间索引、Windows/Mac 脚本和隔离契约的可复用部分。

在同一隔离包新增 gameplay 领域；配置使用独立域，不改 0− 三档负载语义：

```text
assets/probe_scenarios.yaml           # 新增 gameplay 域
lib/main.dart                         # 显式选择 0− / 0A 模式
lib/gameplay/config/
lib/gameplay/input/
lib/gameplay/combat/
lib/gameplay/encounter/
lib/gameplay/presentation/
lib/gameplay/telemetry/
test/gameplay/
```

## 4. `CLAUDE.md` §8.2 四证据验收清单

Phase 0A 是有意隔离的可玩原型，四证据按下列口径交付：

### 4.1 真实入口与负向生产接线证据

- 交付可真实启动、接收键鼠输入、完成三批并写报告的 Mac Profile 应用；不能只停在 unit fixture；
- 根 `pubspec.yaml` / `pubspec.lock`、生产 `lib/`、`data/`、路由、Isar、奖励与存档零接线；
- `git diff` + 依赖图 + 隔离契约测试证明 Flame 仍只在 nested package；
- 0− 入口仍可独立复跑，旧 Mac 基线不被无声改写。

### 4.2 Targeted tests 与实机结果

- 输入、资源/CD、`castId`、位移/边界、攻击名额、精英破招、三批流程、反馈聚合、对象池、报告与隔离测试全绿；
- nested `flutter analyze`、nested `flutter test`、根 `flutter analyze`通过；
- Mac 两视口各 3 个有效 Profile run，p99/连续严重帧/GC/RSS/对象池证据齐全；
- 6 人原始问卷、观察记录、“再打一轮”真实点击与对照评分齐全；
- 没有 Windows 实机时明确写 `WINDOWS_PENDING`，不伪造跨平台通过数。

### 4.3 红线影响说明

- 无体力、日课、抽卡、VIP、在线 buff、掉落或经济；
- 不读境界/装备/心法，不改三系锁死和 GDD 伤害公式；
- 灰盒参数进独立 YAML，不向生产 Dart 写中文文案/数值；
- 反馈强但噪音受限，主角与危险层始终高于特效；
- 无 AI 队友；不动 `activeCharacterIds` / `LineupService`；
- 不做随机装备海、具名兵器迁移或真意 schema。

### 4.4 残留风险

交付必须列清：

- Windows 最低档未验证及 Flutter renderer/driver 差异；
- 白盒代理动画/声音不等于正式美术 ROI；
- 6 人小样本只能淘汰明显错误，不代表市场证明；
- 键鼠先行，手柄/改键/可达性未覆盖；
- 只有一类杂兵/一类精英，不能证明长期内容变化；
- 无正式伤害/真气/境界适配，不能外推生产平衡；
- 无网络分发和长时间稳定性。

### 4.5 UI/UX 加码

- 人工试玩与确定性回放均必须验 `1280×720` / `1440×900`；
- 验鼠标瞄准、键盘持续态、窗口失焦/重获焦、Esc 暂停、点击重玩和鼠标 cursor；
- 不用超高视口、自动演示或单帧截图代替真人键鼠试玩；
- 改任一可见交互后，必须复跑 focus/鼠标/键盘 smoke，不能只验战斗逻辑。

## 5. 任务切片

### Slice 0：冻结规格与建分支

**操作**

- 读真相源、已否清单、v2、0− spec/plan/report；
- 完成本 spec 和可恢复计划；
- 记录 0− tip/checksum，建立 `codex/phase0a-gameplay-greybox` 隔离 worktree；
- 将 10 日时间盒起点写入恢复点。

**Gate**：新 worktree 干净；0− 入口可复跑；文档无待实现者自行猜测的核心参数。

**建议提交**：`[READY] 冻结 Phase 0A 灰盒规格`

### Slice 1：隔离入口与配置领域

**新增/修改预计**

- `assets/probe_scenarios.yaml` 的独立 gameplay 域；
- `lib/main.dart` 的显式 0A 模式选择；
- `lib/gameplay/config/phase0a_config.dart`；
- `lib/gameplay/combat/combat_types.dart`；
- `test/gameplay/config/phase0a_config_test.dart`；
- `test/isolation_contract_test.dart`。

**实现**

- 固定三批、键位、移动、技能、敌人、反馈、Gate 与固定 seed；
- 独立 0A 入口、app identifier/结果目录；
- 隔离契约扩到新源码和依赖图；
- 保留 0− `main.dart` 路径和 `probe_scenarios.yaml` 原三档负载的原有行为。

**Gate**：配置 parse/checksum 测试通过；三批、键位和 Gate 与 spec 一致；根项目无依赖变更。

**建议提交**：`建立 Phase 0A 隔离入口`

### Slice 2：键鼠输入、主角与相机

**新增/修改预计**

- `lib/gameplay/input/gameplay_input_controller.dart`；
- `lib/gameplay/combat/player_controller.dart`；
- `lib/gameplay/presentation/gameplay_camera.dart`；
- `test/gameplay/input/`；
- `test/gameplay/combat/player_controller_test.dart`。

**实现**

- WASD 对角线归一化、浅纵深边界滑动；
- 鼠标屏幕→世界落点，面向与移动解耦；
- 按住左键移动普攻、一个指令缓冲、失焦/死亡/暂停释放持续键；
- 有界镜头跟随/look-ahead，震屏不改逻辑瞄准；
- 主角轮廓、普攻扇形/清场圆形调试开关与最小 HUD。

**Gate**：用键鼠玩 60 秒无卡键/瞄准偏移；移动普攻可用；两视口的主角尺寸与边界正常。

**建议提交**：`实现移动瞄准与普攻`

### Slice 3：身法、聚怪、清场与真气

**新增/修改预计**

- `lib/gameplay/combat/skill_runtime.dart`；
- `lib/gameplay/combat/hit_group.dart`；
- `lib/gameplay/presentation/skill_telegraphs.dart`；
- `test/gameplay/combat/skill_runtime_test.dart`；
- `test/gameplay/combat/hit_group_test.dart`。

**实现**

- Space 身法：`200px/180ms`、CD `3.2s`、无敌 `30–150ms`、结束锁定 `80ms`，穿杂兵但不穿精英/边界；
- Q 聚怪：鼠标落点预览、半径、牵引，精英 35% 位移；
- R 清场：角色中心半径 `340px`、裸伤 65/失衡伤 110.5、成片清杂兵、60 气、无独立 CD 只受动作锁定、精英固定受 120；
- 真气产耗、CD、不足负反馈、每 `castId` 触发/命中去重；
- 同一技能实例一次主 hit-stop/镜震计数。

**Gate**：普攻节奏为 `300ms`、伤害 `34`；一次技能实例同时命中多怪只产 5 气；开场气 40；Q 零耗气/CD 6.5s；R 耗气 60、无独立 CD 但受动作锁定；聚怪→普攻→清场循环能完成。

**建议提交**：`实现聚怪清场技能循环`

### Slice 4：杂兵、攻击名额与精英破招

**新增/修改预计**

- `lib/gameplay/combat/enemy_agent.dart`；
- `lib/gameplay/combat/attack_slot_director.dart`；
- `lib/gameplay/combat/elite_break_runtime.dart`；
- `test/gameplay/combat/attack_slot_director_test.dart`；
- `test/gameplay/combat/elite_break_runtime_test.dart`。

**实现**

- 普通近战的追击、纵深取位、分离、进攻前摇/恢复、受击/击退/错帧死亡；
- 3 个杂兵近战名额，无名额者仍围势/威吓；
- 精英独立 1 名额、`1.2s` 蓄力和高优先级扇形预警；
- 2 点破势值、`castId` 去重、成功踉跄/承伤窗、失败重击与身法躲避；
- 精英在清场中可读且不被一击清除。

**Gate**：名额不超 3+1；精英可被普攻或技能真实破招；没有破招时可靠身法躲开；破势不被多碰撞重复结算。

**建议提交**：`实现怪群攻防与精英破招`

### Slice 5：三批流程、胜负和可读性

**新增/修改预计**

- `lib/gameplay/encounter/wave_director.dart`；
- `lib/gameplay/encounter/session_controller.dart`；
- `lib/gameplay/presentation/gameplay_hud.dart`；
- `lib/gameplay/presentation/combat_feedback.dart`；
- `test/gameplay/encounter/`；
- `test/gameplay/presentation/feedback_budget_test.dart`。

**实现**

- A 10→B 20→C 20+1、波间 `3.0s` 换气（气保留并恢复 25，HP 不回满）、死亡/暂停/重开/三批完成；
- “再打一轮”真实点击和会话记录；
- HP/真气/CD/批次/敌数/落点/破招 HUD；
- 命中闪白、聚怪轨迹、一次主 hit-stop/镜震、错帧死亡、破招踉跄反馈；
- 主角/精英/普通危险/技能/特效的固定可读性层级。

**Gate**：两视口连续完成三批；主角与精英预警不被清场特效覆盖；单一清场不触发 N 次主停顿/镜震。

**建议提交**：`打通三批灰盒战斗流程`

### Slice 6：确定性回放、报告与 Mac 性能

**新增/修改预计**

- `lib/gameplay/telemetry/gameplay_session_metrics.dart`；
- `lib/gameplay/telemetry/deterministic_gameplay_replay.dart`；
- `scripts/run_phase0a_macos_profile.sh`；
- `scripts/run_phase0a_windows_profile.ps1`；
- `test/gameplay/telemetry/`；
- `docs/phase0/<date>-phase0a-macos-regression.md`。

**实现**

- 人工与确定性模式分开；固定输入/seed/三批 checksum；
- 每批耗时、受击、技能使用/空放、聚怪/清场命中、破招、重玩点击；
- 沿用 `FrameTiming`/RSS/GC/对象池/碰撞/报告/checksum 链；
- Mac 两视口各 3 个 12s+60s+30s 有效 run；
- 相对 0− 同视口 target 档输出 before/after。

**Gate**：所有 run p99 `<16.6ms`、严重连帧 0、GC 可得、对象池无泄漏；报告不混入人工操作样本。

玩法确定性 Gate 同时跑固定 10 seeds：无移动、持续 LMB、Q/R 亮就放的脚本至少 `8/10` 死于 W3 或超时；会用身法、Q→R 与破招的基准脚本至少 `8/10` 通过。同步记录峰值活跃数、攻击名额、Q→R 击溃、裸 R 清场率、破招率、单波受击和波次耗时，并按 spec §10 判定。

**建议提交**：`补齐灰盒回放与性能报告`

### Slice 7：内部走查与唯一调整轮

**操作**

- 由不计入正式样本的内部人员做 1280×720 / 1440×900 smoke；
- 使用固定问题找明显卡点：主角/预警、聚怪—清场节奏、身法价值、精英破招；
- 一次只改一类变量，记录 before/after；
- 冻结 build commit、scenario checksum、键位卡、已知问题、问卷和对照段；
- 冻结后不再中途替换测试包。

**Gate**：正式 6 人拿到同 checksum 包；若修复崩溃等硬问题必须换包，已有样本全部作废重测，不混版。

**建议提交**：`冻结 Phase 0A 独立测试包`

### Slice 8：6 人 Gate 与本地裁决

**交付模板**

```text
docs/phase0/<date>-phase0a-playtest-protocol.md
docs/phase0/<date>-phase0a-playtest-results.md
docs/phase0/<date>-phase0a-decision.md
```

**操作**

- 2 挂机 + 2 ARPG + 2 混合，3/3 对照顺序；
- 只给键位卡，不先教最优循环；
- 保留原始分数、原话、观察和失败样本；
- 按 spec §10 计算中位数、4/6、5/6 与否决项；
- 结合 Mac 性能、隔离、工时和残留风险裁决。

**Gate**：输出 `LOCAL_PASS_WINDOWS_PENDING` / `LOCAL_FAIL` / `INCONCLUSIVE`；不用平均分掩盖任一否决项。

**建议提交**：`[READY] 完成 Phase 0A 本地玩法裁决`  
若缺 6 人或 Windows 且只完成可玩包：`[BLOCKED] 等待 Phase 0A 外部 Gate`

### Slice 9：Windows 同版本复跑（外部依赖）

- 使用冻结 commit/checksum 在 i5-8250U / UHD 620 / 8GB 级实机人工复跑；
- 1280×720 / 1440×900 各 3 个有效确定性 run；
- 回传 hardware/driver/renderer/GC/RSS/对象池/帧时 manifest；
- 通过后才能把 `LOCAL_PASS_WINDOWS_PENDING` 升为 `PASS` 并向人类申请 0B；
- 失败则在降密度/提最低配置/停线中重新拍板，不用 Mac 成绩覆盖。

## 6. 验证命令清单

实现期须以当时真实路径为准；以下是最低口径：

```bash
cd tools/phase0minus_probe
flutter pub get
flutter analyze
flutter test

cd ../..
flutter analyze
```

0− 回归：

```bash
cd tools/phase0minus_probe
PROBE_GATE_DPR=2 scripts/run_macos_matrix.sh 1 0.1
```

0A Profile 矩阵由 Slice 6 的专用脚本执行，不为获得好看数字临时变更负载、视口、DPR 或采样时长。正式交付前使用 `superpowers:verification-before-completion` 执行一次全新验证，不引用过期日志宣称通过。

## 7. 时间盒、停止条件与工时记录

### 7.1 10 日硬上限

| 切片 | 累计建议上限 |
|---|---:|
| Slice 0–2 | Day 2 |
| Slice 3–4 | Day 5 |
| Slice 5–6 | Day 7 |
| Slice 7 | Day 8 |
| Slice 8 | Day 10 |
| Slice 9 | Windows 设备就绪后 1 日，不计本地实现时间 |

工时记录至少分：输入/战斗、敌人/AI、反馈/HUD、性能/报告、测试/修复、试玩准备与执行。

### 7.2 提前停止

任一成立即更新恢复点并停止扩展：

- 发现原型读写正式存档/应用目录或接生产奖励；
- 核心循环必须加 AI 队友、换人、跳跃或新主动技能才能成立；
- `20+1` 可读性在两轮有记录调整后仍失败；
- 最优策略仍是站桩单键，两轮节奏调整不能消除；
- Mac 目标档在时间盒内不能满足帧时/内存/对象池 Gate；
- 预计投入将超 10 工作日或范围超出 20%；
- 有效测试者不足时不定义为“默认通过”，转 `INCONCLUSIVE/BLOCKED`。

## 8. 恢复点更新模板

每个切片提交后更新本节，不在多个交接文档重复维护：

```text
状态：WIP / BLOCKED / LOCAL_PASS_WINDOWS_PENDING / LOCAL_FAIL / READY
当前分支与 commit：
已用工作日 / 10：
最后完成切片：
已实现：
下一步：
已跑验证（命令 + 通过数）：
已知风险：
外部阻塞：
不得重做/跨界：
```

## 9. 当前恢复点

- **状态**：WIP；Slice 1–5 首轮可玩闭环已实现，本机 Profile 可玩窗口已成功启动。
- **当前分支/commit**：`codex/phase0a-gameplay-greybox` / `c591e954`。
- **已用工作日 / 10**：实现已启动；精确工时由主线工作记录按实际投入回填，不以文档更新时间代替。
- **最后完成**：单门人键鼠移动普攻、Space 身法、Q 聚怪、R 清场、三波 `10→20→20+1`、普通攻击名额与精英破招首轮闭环；本机视觉检查完成。
- **下一步**：执行 Slice 6 确定性回放与 Mac 性能回归，并完善 hit-stop、镜震、伤害数字预算和可读性反馈；随后冻结内部走查包。
- **已跑验证**：29 tests 通过，`flutter analyze` 通过；macOS Profile 启动与首轮视觉检查完成。上述为当前实现恢复点，最终 Gate 仍须按 spec 复跑并落报告。
- **已知风险**：当前 Mac 只有 M5/32GB/DPR2 基线；6+2 测试者、对照关卡和人类裁决人尚未在文档中填入实名/排期。
- **外部阻塞**：目标最低档 Windows 实机缺失，跨平台 Gate 仍阻塞；项目主人已授权 Mac 先行，但不授权 0B/0C。
- **不得重做/跨界**：不重写 0− 基线；不改根应用/存档/奖励；不加 AI 队友/换人/跳跃/正式美术/成长系统；不在 Windows 未签前进入 0B。
