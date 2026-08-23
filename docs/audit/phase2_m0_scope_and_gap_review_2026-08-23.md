# 二阶段 M0 范围与差距复核

## 结论

二阶段方案是 M0–M9 的大型产品改造，不能把“快”理解为绕过 G0/G1 后直接批量改 105 关。当前最快可恢复路径是：

1. 冻结当前绿基线与决策底账；
2. 并行完成真实实现证据、测试/性能基线和不依赖未决项的纯领域候选；
3. 由主调度独立审 diff 与 targeted 证据；
4. 用户返回后只拍板会改变产品语义的 G0 条目；
5. G1 真实 API 冻结后才开黑风岭纵切和内容扩面。

## 基线与约束

- 冻结 commit：`e292d3a069fbc0e129dd74fafc1ebb3746f53557`。
- `main == origin/main`，主 worktree clean。
- 实测 `flutter analyze --no-pub`：0 issue（2026-08-23 本批）。
- 现有用户 worktree 全部保留不碰；二阶段使用新分支/worktree。
- 不自动部署、发布、push 或合入 `main`。
- 同时最多一个全量 Flutter 测试、一个 build runner、一个真窗口视觉任务。

## 已证实实现差距

| 条目 | 当前生产行为 | 证据 | 安全处置 |
|---|---|---|---|
| 主线掌门指针 | `founderCharacterId` 为空或无效时，live/sweep 均会静默取首角色 | `phase0a_mainline_battle_host.dart` `_buildPlayerSnapshot`；`phase0a_sweep_headless_runner.dart` | 建独立掌门解析器，空值/悬空 ID/角色缺失 fail closed；不顺便决定重打参与者 |
| 主线成长/伤势归属 | 结算已按 `participantCharacterIds` 过滤实际参与者，但主线进度为存档级，无个人主线记录 | `stage_entry_flow.dart`；`boss_memory_hook.dart` 仍读全 `activeCharacterIds` | 参与者、个人记录、奖励归属和 automation policy 分任务冻结 |
| MainlineRun | 不存在连续 run 领域/持久化合同；每关独立进入/结算 | `CharacterOccupancyService` 仅聚合闭关/远征/断魂庄 | 未拍板锁人/换装/伤势中断前不实装 |
| 随行听剑 | 无代码、数据或测试；现有 `swordSong` 是剑鸣共鸣特效，非门人随行 | `strings.dart`；`combatant_snapshot.dart` | core 合同可建候选，占用与比例仍分别 PROPOSED/TUNING |
| 心魔失败 | 不扣永久内力；施加内息紊乱；当前扣 10% 主修修炼度 | `InnerDemonService.applyFailurePenalty`；`inner_demon_failure_penalty_test.dart` | 保留现行直到 G0 拍板；不提前改惩罚 |
| 心魔旧字段 | `internal_force_multiplier/floor/debuff_id` 和 Dart 注释仍宣称扣内力，与实现不符 | `data/numbers.yaml`；`inner_demon_def.dart` | 先证明生产读方为零，再单独清理与补接线测试 |
| 七心魔 AI | 已有七名与 05/06/07 部分镜像参数，无完整“七名→七考验→AI”绑定 | `stages.yaml`；`numbers.yaml`；mapper/AI 测试 | 保留 canon，候选映射不作冻结事实 |
| 换波冷却 | `preserve_cooldowns: false`，生产仍重置 | `data/numbers.yaml`；`phase0a_stage_content_mapper.dart` | 本批只证据化；后续由 C15 独立修正与精确 tick 断言 |

## 必须等待用户的 G0 产品决策

1. 主线重打、前台 bot、headless、扫荡是否固定掌门，个人记录如何归属。
2. 连续 MainlineRun 是否锁定参与者/装配，关间是否允许换装，伤势何时中断。
3. 随行听剑占用单关还是整段 run，释放时点和互斥。
4. 心魔失败是否保留当前 10% 主修修炼度扣减。
5. 贪/嗔/痴/慢/疑/空/真与七类 AI 考验的具体映射。

## 方案与已否注册表的重开冲突

当前请求授权“推进二阶段方案”，但没有逐项说明重开以下旧否决；为防误解，先登记为 `proposed_reopen`：

| 方案新说法 | 已否条目 | 当前安全默认 |
|---|---|---|
| 每角色亲战/差遣两套装配 | Build 方案保存 | 不启用产品存储/UI |
| 章节卷轴、江湖纪事 | 章节回顾入口；江湖见闻录收藏百科 | 不建新一级导航 |
| 威胁图标/Boss 预警 | Boss 技能预兆图标 | 保留现有非图标预警 |
| 统一归来报告 | 闭关归来事件小结 | 保留现有离线摘要 |
| 轻功模式专属收益定位 | 轻功关卡收益差异化 | 不改现有奖励 |
| 失败/返程原因和伤势展示 | 失败原因诊断 | 保留领域 reason，不新增建议型诊断 UI |

## 当前安全并行切片

- C02 六几何纯领域候选；
- C04 攻击 flags 与防御解析顺序候选；
- C05 单一累计姿态状态机候选；
- C06 状态固定 tick、刷新与叠加候选；
- C03 动作时间线固定拍状态机候选；
- C07 真气预留、提交、取消与击杀窗口上限候选；
- M0 实现差距证据包与性能/测试基线地图。

以上均不改生产路径、数值、存档、公共 reducer/model 或长寿设计文档。它们是 G1 审查候选，不是已完成产品接线。
