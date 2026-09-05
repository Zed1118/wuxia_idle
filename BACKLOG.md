# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。
> 2026-08-23 最新收口事实：主线、塔、扫荡、远征、断魂庄五个生产消费面已永久切至 Phase 0A 单角色 ARPG，live/headless 共用 reducer；历史多人会话安全兑现、释放或保留奖励选择态，不再启动旧 runner。旧 3v3 已在 Gate commit `597a243b` 原子删除并合入 `main`，同 commit 的 Mac/Windows 本地物理机矩阵均 6/6 PASS；六人真人 Gate 已取消。Windows 结果不定义产品最低配置，详 `docs/audit/route_c_gate_closeout_2026-08-23.md`。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 4 | 丹房强度 2B | 数值复核 | 2026-08-23 已补 3 功能×3 等级×多时窗/资源瓶颈共 66 场景证据，一次结算与四段结算差值 ≤1e-9；当前只证明在线/离线计算一致，不证明体感强度，维持「不动」并待真人试玩。 |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 2026-08-23 已按 production 概率/阈值跑 10 万固定 seed：五门映射 Boss 每轮各清一次口径 p50=36、p90=50、p95=54；总 Boss 击杀数口径 p50=124、p90=154、p95=164。18 本主线秘籍首通必得另列；只刷新证据，实玩后再拍是否调值。 |
| 6 | 高熟练度难度微调候选 | 数值微调 | 2026-08-23 已覆盖 105 主线+49 塔×3 流派×熟练度 0/30/100/300/800，共 2310 局，0 timeout、最大单击 3535；起手档画像不代表持续成长/装备态，禁止据此自动调敌，待真玩拍板。 |

## 二 · 已解锁可派

（空——Phase 0A 护法近身标签错列打磨已于 2026-08-22 销账；git 历史可溯）

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |
| 4 | 主线首次 CI 宿主缺失与超时根因未闭合 | 首次 run `33950577057` attempt 1 的断言/超时保留；实时时限加固已用受控延迟验证，但反例在宿主内加载阶段，不能当作原故障复现。再开条件：取得可定位首次失败的异步加载/清理证据或同类复现；优先取证，不靠重跑变绿销账，也不据文档 diff 排除生产时序缺陷。详 `docs/superpowers/plans/2026-09-05-mainline-ci-wait-investigation.md`。 |
| 3 | Flutter SDK 3.41.5→≥3.44 升级(解锁 audioplayers 6.8.x / 松 windows-2022 钉) | 2026-08-05 拍板暂缓(无需求驱动+isar fork 兼容风险与上行 #2 统一处理);再开条件=windows-2022 退役公告 / audioplayers 出本项目需要的修复 / #2 解锁开依赖维护批时**合并做**。要点存档(2026-08-01 实测):真闸门=audioplayers ≥6.8.0 要 Flutter ≥3.44(非 pubspec 约束);动作序列=升 SDK→pub upgrade→CMake 3.14→3.15 三处(`windows/CMakeLists.txt:2,11`+`windows/runner/CMakeLists.txt:1`)→CI 三处 flutter-version 钉(`ci.yml:36,78`/`windows-release.yml:35`)→`windows-release.yml:26` 放回 windows-latest→Windows release CI 实跑(唯一真证明);isar_community 对新 Dart 兼容须复核 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

（空——Route C 已于 2026-08-23 完成双平台 Gate 并原子合入 `main`。）
