# P2-M2-R13：显式目标事件源

## 目标与边界

在 Batch13 READY `77c5520e` 的 R09 不可变 objective frame / source 接缝上，
新增一个纯 application 层显式事件源：每个 roster runtime actor 必须由
caller 完整声明 defeat projection，其他六类 objective event 只能由 caller
projector 提供。本任务不切换 production host，不构造 objective tracker/controller，
不推断 ID、entry、role、defeat kind 或任何候选数据语义。

- 分支：`codex/phase2-m2-r13-explicit-objective-event-source-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r13-explicit-objective-event-source`
- 基线：Batch13 READY `77c5520e04355e041a5db6b40dde05b169874117`
- 只允许：
  - `lib/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart`
  - `test/features/battle/application/phase0a/phase0a_explicit_objective_event_source_test.dart`
  - 本计划
- 禁止：main、registry、audit、现有 R09 flow/frame/tracker、assembler、host、
  repository/YAML/UI/save/reward/injury/tuning/candidate 数据。

## 冻结合同

- API 仅新增 sealed defeat projection、Target/Commander 两个显式值类、
  external projector typedef 与
  `Phase0aExplicitObjectiveEventSource implements Phase0aEncounterObjectiveEventSource`。
- constructor 显式接收 exact `Phase0aEncounterRoster`、
  `Map<String, Iterable<projection>>` 与 external projector iterable；立即防御性
  冻结 map、每 actor projection list 与 projector list。
- projection map key set 必须与 `roster.bindings.actorId` 精确相等；missing / extra
  fail closed，显式空 list 是合法 no-op。
- `eventsFor` 只对 `Phase0aEnemyDefeated.target` 做 exact actor lookup；unknown
  defeated actor fail closed，不读 entryId / roleId / archetype / defeatKind / position，
  不做字符串规则推断。
- defeat event ID 固定为
  `phase0a:defeat:<tick>:<seq>:<projectionIndex>`，重放稳定，同一 defeat 的
  多个同类 projection 不碰撞。
- 全局顺序固定为 combat event 顺序 → 每 actor projection 声明顺序 →
  external projector 声明顺序 → 每 projector yield 顺序。
- external projector 返回的 lazy iterable 全部物化后才返回事件批；只允许
  `AnchorDestroyed` / `EntityDefended` / `TimeElapsed` /
  `CheckpointReached` / `MarkerTouched` / `TargetPursued`，拒绝
  `TargetDefeated` / `CommanderDefeated` 绕过 roster coverage。
- 诚实边界：R09 frame 已深冻 arena actor 及其公开容器，但通用 event
  payload 不是所有类型深拷贝；R13 defeat 路径只读 scalar。

## 验收 checklist（CLAUDE §8.2）

- [x] TDD 红测由目标文件/API 缺失触发，实现后转绿。
- [x] 覆盖 exact / missing / extra actor coverage 与显式空 projection。
- [x] 覆盖 target + commander、多 defeat 顺序、稳定唯一 ID、unknown actor 与
  non-defeat no-op。
- [x] 证明误导性 actor/entry/role/defeatKind 不改变显式投影，无隐式语义。
- [x] external 六类允许，Target/Commander 拒绝；projector/yield 顺序稳定。
- [x] lazy projector 完整物化；中途 throw 时不暴露 partial result。
- [x] caller map/list 在构造后突变不污染 source。
- [x] 经 R09 真实 runtime flow 证明 source throw 不提交 session/director/outcome/
  records/objective progress。
- [x] source guard 证明无 entryId/role/archetype/candidate/host/IO/default 推断。
- [x] 生产接线证据：实现现有 R09 interface 的真实 runtime source，但不切 host，
  不冒充生产 route 已启用。
- [x] 红线：0 数值/YAML/玩家文案，0 三系/在线离线/反主流/reward/save/UI
  触点。
- [ ] Pi CLI 0.84.x / `deepseek/deepseek-v4-flash` / thinking high 完成设计
  和最终 diff 两轮只读审查，如实记录结果。
- [ ] targeted + R09 受影响回归、scoped analyze、format、`git diff --check`
  与 owned-files 审计全绿；不跑 full。
- [ ] 小切片中文动宾 commit，最终追加精确 READY 空提交。

## 任务切片

1. 读取项目红线、已否清单、R09 frame/source/flow、objective event 与 roster。
2. 提交本计划初始恢复点；调用 Pi 做编码前设计审查。
3. 先写新测试并跑出 API 缺失红灯，提交测试切片。
4. 实现最小 source，运行 targeted 与 R09 回归，修正问题并提交实现。
5. 调用 Pi 审查最终 diff；主 agent 证伪 findings，完成静态与路径验收。
6. 更新恢复点与验收证据，提交后追加 READY 空提交。

## 当前恢复点

- 状态：计划、Pi 设计审查、TDD 红绿与实现已完成，待提交实现后执行
  Pi 最终 diff 审查与收口验证。
- 最后完成：新增 sealed defeat projection（显式 target/commander payload）与
  exact-roster source；构造期冻结输入并验 coverage，运行期按冻结顺序投影、生成
  tick/seq/index ID，全物化 external 六类并拒绝 defeat 绕过。
- 下一步：提交 source + 本恢复点，用同一 Pi exact model/thinking 做最终
  diff 只读审查，证伪 findings 后完成 format/analyze/path 验收与 READY。
- 已跑验证：确认 `HEAD=77c5520e04355e041a5db6b40dde05b169874117`，
  worktree 初始干净；`pi --version` = `0.84.1`。新测试先因目标文件/API
  缺失编译失败，实现后 15/15 PASS；R09 flow 15、tracker 15、production
  objective integration 2、roster 9、objective primitive 9，连同新测试共
  65/65 PASS；scoped `flutter analyze --no-pub` 4 items 0 issue；format 通过。
- Pi 设计审查：`pi` 0.84.1，model `deepseek/deepseek-v4-flash`，thinking
  `high`，`--no-session --tools read,grep,find,ls --print` 只读命令；结论「有条件
  PASS，无 P0」。其 P1 要求冻结类型/constructor 已采纳；marker-only projection
  建议会隐式把 runtime actor ID 当 objective ID，由主 agent 证伪后改为显式
  targetId/commanderId payload。其 actor 空白 ID 顾虑已由 roster 上游的 exact
  director ID 校验覆盖；missing/extra 诊断、external 不变异 frame 边界已落实。
- 阻塞项：无。
- 生产接线：本切片只交付 R09 runtime 可直接消费的 source 实现，不切换 host。
- 红线影响：无数值、YAML、玩家文案、reward/save/UI 及三系或在线离线变更。
- 残留风险：当前仅计划阶段；通用 event payload 非 R09 全类型深拷贝，
  本任务将仅依赖 defeat 标量并如实保留该边界。
