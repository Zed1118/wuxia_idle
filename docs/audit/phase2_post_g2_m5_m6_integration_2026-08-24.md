# 二阶段 G2 后真实状态与 M5/M6 最小整合审计（2026-08-24）

## 1. 裁决摘要

- G2 黑风岭已正式关闭；关闭范围严格限定为 `stage_01_03` 生产纵切。
- G2 READY `e7932cc35be42a5228a14f9707135f96656e20b1` 是后续二阶段唯一整合基线。
- G2 不等于 M2 完成，更不等于整个二阶段完成。
- 两项注册为 `in_progress` 的任务其实都已由原 owner 会话完成并交付 READY；原 worktree 已移除，不存在活跃写入者。
- 本整合只纳入两个文件互斥的小批并治理状态漂移，不修改玩法数值、调优、解锁、奖励、schema、`main` 或 `origin/main`。
- registry 现有条目只能证明已登记任务的状态；M3/M4/M7/M8/M9 大量工作尚未登记，禁止用条目数计算二阶段完成率。

## 2. 基线、所有权与分支事实

| 对象 | branch / HEAD | 工作区状态 | owner 状态 |
|---|---|---|---|
| primary checkout | `main` / `e292d3a069fbc0e129dd74fafc1ebb3746f53557` | clean；未修改 | 无二阶段施工 |
| G2 READY | `codex/phase2-ch1-black-ridge-integration-20260824` / `e7932cc35be42a5228a14f9707135f96656e20b1` | clean | 已完成 |
| M5 source | `codex/phase2-m5-expedition-entry-availability-guard-20260824` / `ee527d90f775e1ba1a6abe622a886cfa21ac6d0e` | 原 worktree 已移除 | task `01a031c2-fb61-7930-99d9-4033b53cb064` 已完成 |
| M6 source | `codex/phase2-m6-a12-dispel-activity-lock-enforcement-20260824` / `5e1edac2a939d09c0f36cea9c6b295e70996befb` | 原 worktree 已移除 | task `01a031c2-fb5f-7dc0-8145-08abc325d5d8` 已完成 |
| 本整合 | `codex/phase2-post-g2-m5-m6-integration-20260824` / G2 READY 起步 | 独立 worktree | `codex_root` |

另有一个活跃 Codex task 只写
`/Users/a10506/.codex/visualizations/2026/08/24/01a033e9-e39d-7be2-90ca-a67c4073d8dc/ink-vfx-web`，
不占用 Flutter 仓库、上述分支或测试资源，不构成本批冲突。

三条 source/基线分支共同祖先为
`8296db0c033b64faa1eb09b24f2f22269f281363`。该提交是三条分支祖先；
M5、M6、G2 互不包含。`base..tip` 文件集合三组交集均为空，故没有盲目
cherry-pick：先核对 ancestry、tree diff、文件交集和实际语义，再按 source 历史逐提交纳入。

## 3. M0-M9 真实状态矩阵

| 里程碑 | 最新裁决 | 已完成证据 | 未完成、依赖与阻塞 | 当前 owner / worktree |
|---|---|---|---|---|
| M0 基线与治理 | **部分完成** | G0 已拍板；G1/G2 有 READY 基线；registry/decision registry 可解析 | 20 项 `TUNE-*` 仍只授权候选生成；七心魔 AI 待四列矩阵；渐进解锁待 current→target 迁移表；其余生态按批审核 | 调优/延期项无施工 owner；本批只治理状态 |
| M1 规则合同 | **生产合同关闭** | G1 closeout 21 项合同关闭；波间冷却实现证据已补回 decision registry | 不代表上层产品流已消费全部合同 | 无在途 owner |
| M2 第一章产品流 | **部分完成** | G2 黑风岭 8/8；G1 的参与者/Run/输入等纯合同存在 | U01 生产“下一关”；连续五关；同一参与者；关间版本快照；不可战中断；伤势归属；结算幂等；退出/崩溃恢复；replay/manual/auto/headless/扫荡一致；U04/U05。依赖 G2/G0/G1/M6 Batch1 已满足，主要阻塞是生产协调器和事务接线尚未实现 | 未分配；建议下一批接管 |
| M3 武器与战斗深度 | **未启动生产批** | G2 已使 M3 可以按小批开启 | 五类普攻、三主修特性、防御/反击/反伤/Boss 响应、每武器三场画像及四类漏洞守卫均未关闭；依赖 G2，排在连续五关之后 | 未登记、无 owner/worktree |
| M4 生态/模板/表现 | **未启动生产批** | Ch1 山匪/黑风岭纵切与既有破路/据点/伏击/斩将可复用 | 其余五生态；守阵/生存/追击；七模板领域/UI；24 active 可读性、LOD、音频聚合、屏外威胁、性能工具。依赖 G2 与逐批生态审核 | 未登记、无 owner/worktree |
| M5 六类特殊玩法 | **部分完成** | 心魔失败语义、断魂庄自动准入、远征死亡入口守卫 READY | 塔→群战→轻功→断魂庄→远征→心魔仍须逐模式关闭 entry/首通/自动化/渐进解锁/奖励/伤势/记录/离线/production smoke；七心魔 AI 和渐进解锁仍显式延期 | 两个既有 owner 已完成；余项无 owner/worktree |
| M6 调度/导航/奖励 | **部分完成** | 主线叙事去阻塞、断魂庄准入、散功占用原子守卫 READY | 四入口导航、江湖地图、宗门行止、地点面板、门人选人、亲战/差遣、统一报告、三层奖励和个人归属、所有占用事务 fail closed、U01/U04/U05、连续五关 | 散功 owner 已完成；余项无 owner/worktree |
| M7 全内容生产 | **未启动** | 仅 Ch1 黑风岭纵切可作为模板证据 | 105/105 主线、49/49 塔、六生态、约 24/48 角色变体、引用完备、fallback allowlist 归零、三章/七层分批验收；依赖 M3/M4 模板和生态冻结 | 未登记、无 owner/worktree |
| M8 性能与兼容 | **未启动最终批** | G2 仅有当前 Mac 双视口纵切 Profile | 当前高密度内容 Mac+Windows、特效档/震屏闪光、无障碍、旧档迁移、72h/全内容经济、长离线/多活动/奖励重复、领域 hash 不变；依赖 M7 内容稳定 | 未登记、无 owner/worktree |
| M9 发布收口 | **未启动/被前置阻塞** | 无 | G0-G7 全关、全量 analyze/test、双平台构建、退役路径清零、文档统一、RC/tag/回滚/风险；依赖 M2-M8，合并/push 另需用户授权 | 未登记、无 owner/worktree |

## 4. 文档与注册表漂移

1. primary checkout 的 `CLAUDE.md`、`GDD.md`、`PROGRESS.md` 仍是 G2 前快照；primary/main 本批不改。
2. G2 READY 上 `PROGRESS.md` 已记录 G2，但 `CLAUDE.md v1.54` 与 `GDD.md v1.36` 头部仍写 G2 未关闭。本批分别以 v1.55/v1.37 标记旧快照已被取代。
3. `task_registry.yaml` 的 M5/M6 两项仍写 `in_progress` 和已消失 worktree；本批按原 task 最终提交、测试与审查证据改为 `ready_reviewed`，并保留历史路径及 `removed_after_ready` 状态。
4. registry 原来没有 G2 最终 `stage_01_03` 八项验收条目；本批补登记并显式限定 `completion_scope`。
5. `decision_registry.yaml` 的 `COMBAT-WAVE-CD-01` 仍是 `implementation_gap`，与 G1 closeout 和 owner task READY 冲突；本批按既有审计改为 `frozen_implemented`，没有改变设计值。
6. `BACKLOG.md` 是旧项目 backlog，不是二阶段剩余任务总表；未修改。
7. M5 source 计划末尾仍留一项未勾 checkbox，和 source 的 READY commit/最终测试证据不一致；为保持 source blob identity，本批不改该历史计划，只在本审计披露。

registry 本批同步后为 113 条：112 `ready_reviewed`、1 `completed`。这个数字只描述
已登记条目，**禁止**解释为二阶段 `112/113` 完成。

## 5. 本批整合内容与语义复核

### M5 远征入口

- 权威写事务重新读取 canonical character 后，死亡角色在创建 run、占用变更和 serial 递增前被拒绝。
- 失败后 `ExpeditionRun` 为零新增，`expeditionRunSerial` 不变。
- 存活、主修、祖师、占用、单 active 和路线人数既有规则不变。

### M6 散功入口

- UI 不再预改 detached/live 对象；只向 service 传稳定 ID 和二确前 tuple。
- service 在同一权威事务内检查闭关/远征/断魂庄占用，fresh-read character/旧主修/候选心法，并核对 stale tuple 后才进行三对象写入。
- occupied/stale/missing 均零写且不显示假成功；活动释放后允许成功。

最终八个 source-owned 文件与 source READY tip 的 Git blob 逐文件一致。主控对实际 diff
独立语义复核未发现 P0/P1；两个 source 还各自保留 Pi/Qoder 的最终只读审查证据。

## 6. 验证

| 门禁 | 结果 |
|---|---|
| M5 dispatch focused | 14/14 PASS |
| M5 expedition feature | 108/108 PASS |
| M6 persist | 10/10 PASS |
| M6 pure service | 16/16 PASS |
| M6 production UI | 20/20 PASS |
| M6 dispel feature | 27/27 PASS |
| G2 回归保护网 | 94/94 PASS |
| GDD truth source guard | 9/9 PASS |
| changed Dart format | 6 files, 0 changed |
| application analyze | `flutter analyze --no-pub lib test tool`，0 issue |
| root analyze | fresh worktree 首次因嵌套 `tools/phase0minus_probe` 未安装自身 package metadata 失败；对该已跟踪独立 package 执行 `flutter pub get --offline` 后，同一根命令复跑 0 issue |
| registry parse | 两份 YAML PASS |
| diff/whitelist | PASS |

没有重跑 G2 已在同一基线候选完成的 5249 项最终全量；本批按计划只做 source 域全量、
G2 定向保护网和 analyze。下一个最终整合候选再运行一次全量。

## 7. 下一批推荐：U01 第一章连续 Run 生产闭环

任务建议：`P2-M2-M6-U01-CH1-CONTINUOUS-RUN`。这是当前最小、无调优依赖、
且能消费最多既有 G0/G1/G2/M6 合同的生产批；只关闭 U01 与第一章连续五关，不顺带
扩 U04/U05、奖励统一或特殊模式。

### 建议白名单

生产文件：

- `lib/features/mainline/presentation/stage_entry_flow.dart`
- `lib/features/mainline/presentation/stage_victory_dialog.dart`
- `lib/features/mainline/presentation/mainline_run_coordinator.dart`（仅当外层非递归循环确需新增）
- `lib/features/mainline/application/mainline_next_stage_runtime_admission.dart`
- `lib/features/mainline/application/mainline_stage_runtime_admission.dart`
- `lib/features/mainline/domain/mainline_run.dart`
- `lib/shared/strings.dart`

测试文件：

- `test/features/mainline/presentation/stage_entry_flow_test.dart`
- `test/features/mainline/presentation/stage_entry_flow_branches_test.dart`
- `test/features/mainline/presentation/stage_victory_dialog_test.dart`
- `test/features/mainline/presentation/phase0a_mainline_wiring_test.dart`
- `test/features/mainline/application/mainline_next_stage_runtime_admission_test.dart`
- `test/features/mainline/application/mainline_stage_runtime_admission_test.dart`
- `test/features/mainline/domain/mainline_run_test.dart`
- `test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart`（新建生产链验收）
- 对应计划、registry 与单份 audit。

明确禁止：`data/**`、`numbers.yaml`、奖励/解锁/schema、M3/M4、特殊模式、第二套
reducer/session/headless 内核和 main。

### 红测与验证清单

1. 真实红测：当前胜利弹层只有“确认”并固定 pop 回关卡列表，无法在结算成功后选择下一关。
2. `stage_01_01 → stage_01_05` 一次非递归外层 run；第 1-4 关显示“进入下一关”，第 5 关显示章末去向。
3. 整段 participantId 不变；每关允许换装但 snapshot version 单调递增、ID 不复用。
4. 只有成功 settlement/release 后可进入下一关；参与者不再可战时 fail closed 并返回明确 stop reason。
5. 每关 record/reward/injury 只结算一次；普通主线关间无强制 narrative。
6. 退出、认输、失败和 context unmount 不递归、不误进下一关；最少补一个写边界崩溃/重放幂等破坏证。
7. 既有 run/admission/stage flow/victory dialog 定向、第一章生产链测试、G2 94 项保护网、scoped/root analyze、format/diff/白名单通过。

### 完成定义

- 在生产入口而非纯合同测试中完成第一章连续五关。
- 结算提交先于下一关 admission，参与者锁定和版本化装配快照可观测。
- 失败/退出/不可战/重复回调均无重复奖励、伤势或进度。
- 不冻结听剑成长比例/cap，不触碰 U04/U05，不声称 M2/M6 完成。
- 独立语义复核 P0/P1=0、clean `[READY]`；用户授权前不 merge/push。
