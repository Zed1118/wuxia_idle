# P2-M2-R17：迁移遭遇结算适配

## 目标与边界

从 `a952274781a11283ff5d7675ad270034a94cfd69` 出发，为 R11 已冻结的
`Phase0aEncounterMapping` 增加终局结算入口，使迁移遭遇与旧
`Phase0aStageMapping` 复用同一个结算 core，不复制伤害、暴击、技能
释放或参战者聚合规则。

- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r17-migrated-encounter-settlement-adapter`
- 分支：`codex/phase2-m2-r17-migrated-encounter-settlement-adapter-20260824`
- owned files 严格仅：
  - `lib/features/battle/application/phase0a/phase0a_settlement_adapter.dart`
  - `test/features/battle/application/phase0a/phase0a_migrated_encounter_settlement_test.dart`
  - 本计划
- 禁止接入或推断 route / objective / reward / injury / host /
  persistence / data / candidate / tuning；不改 production caller。

## 冻结 API 与结算事实

```dart
static CombatSettlementSnapshot fromEncounterMapping({
  required Phase0aEncounterMapping mapping,
  required Phase0aBattleOutcome outcome,
  required Phase0aArenaState finalState,
  required List<Phase0aEvent> events,
})
```

- `fromMapping` 与新入口只解包各自 mapping 的
  `initialState.player.id` / `combatants` / `moveBindings`，随即委托
  同一个私有 settlement core。core 不接收整个 initial state，从
  类型上防止误读 encounter 初态的空 enemies。
- core 只消费现有显式事实：初始玩家 actor ID、combatant 与
  character ID、move binding、终局 arena、终局 outcome 与语义事件。
- `ongoing` 拒绝结算；终局玩家 ID/阵营必须精确匹配；已映射
  combatants 中玩家 actor 必须恰好一次，否则 fail closed。
- 参战者顺序继承 combatants；玩家 HP 来自终局 player，其他角色
  若不在终局 active actor 集合中（后备或已离场）则 HP=0，不从
  director/roster 推断生存状态。
- 两个公开入口在进入 core 时对 combatants / move bindings / events
  建立防御性快照；返回的 `CombatSettlementSnapshot` 继续由其既有
  constructor 冻结 participants / casts / damage map。
- basic / gather / clear / 数字技能释放、暴击与伤害归属全部
  沿用现有聚合规则；未映射 actor 伤害仍进 total/暴击，但不
  写入 character 归属 map。

## TDD 与验收

- [x] 新测试先因 `fromEncounterMapping` 缺失编译红，实现后转绿。
- [x] 等价 legacy / encounter fixture 对一批混合事件逐字段全等：
  result / ticks / hadActions / participants / skillCasts / totalDamage /
  criticalCount / damageByCharacterId。
- [x] 覆盖玩家 exact-once 成功、缺失与重复，终局玩家 mismatch，
  ongoing，全部 fail closed。
- [x] 覆盖 active / reserve / exited 参战者 HP，basic / gather / clear /
  数字技能 cast，暴击、未映射 actor 与已映射 actor 伤害归属。
- [x] 证明 caller 列表/map/events 的后续突变不污染 mapping 或已产出
  settlement，返回集合仍不可修改。
- [x] source guard 精确冻结 imports（含 encounter mapping 与共享 core
  所需 combatant input 类型），不出现
  route / objective / reward / injury / host / persistence / repository /
  candidate / tuning 及双套聚合 loop。
- [x] 复跑新测试与现有 numeric settlement / stage settlement /
  encounter mapping / migrated encounter plan 回归，scoped analyze 0 issue。
- [x] `dart format --output=none --set-exit-if-changed`、`git diff --check`、
  baseline path audit、status / main refs 收口通过。
- [x] Pi CLI 0.84.1 / exact `deepseek/deepseek-v4-flash` / thinking high
  完成编码前设计与最终 diff 两轮只读审查，如实记录。
- [x] 中文动宾小提交，本计划的直接后继将追加精确空提交
  `[READY][PI][P2-M2-R17] 建立迁移遭遇结算适配`。

## Pi 证据

### 编码前设计审查

- CLI：Pi `0.84.1`；model：`deepseek/deepseek-v4-flash`；thinking：
  `high`。
- 命令只启用 `read,grep,find,ls`，并使用 `--no-session
  --no-skills --no-prompt-templates --print`；无 bash / edit / write，未执行
  测试。
- 结论：`PASS`，P0=0；指出三个实施期 P1 陷阱：core 只收
  `playerActorId`，等价 fixture 必须共享同一组解包输入，source
  guard 不得以裸 `data` 子串误伤既有 `data/defs/skill_def.dart`
  import；全部采纳。
- P2 实施提醒：保留既有三类错误文本；在共享 core 入口防御
  性复制 combatants / bindings / events；mutation 行为证据放在本身已
  冻结输入的 encounter 路径；不顺手改动 gather 空 skillId、
  guardian 或终局事件的旧口径。

### 最终 diff 审查

- CLI：Pi `0.84.1`；model：`deepseek/deepseek-v4-flash`；thinking：
  `high`；命令同样只启用 `read,grep,find,ls`，无 bash / edit /
  write，未执行测试。
- 结论：代码与测试 `PASS`，P0=0、P1=0；确认两入口只解包后
  委托单一 `_settle`，一个事件 loop / 一个 settlement constructor，无
  禁止推断或 production 调用点。
- Pi 指出的唯一 P2 为计划 checklist / 恢复点尚未收口，已在本次
  更新关闭。另记录信息级取舍：精确 import 顺序和构造点计数的
  source guard 对未来合法结构改动较敏感，但本切片作为严格边界证据
  保留；行为等价测试同时覆盖真实口径。

## 当前恢复点

- 状态：三份 owned files 完成；新 API 与旧 API 共用单一私有
  settlement core，两轮指定 Pi 只读审查均 `PASS`，代码级
  P0=0、P1=0、P2=0。
- 环境：`flutter pub get --enforce-lockfile` 通过；`build_runner`
  写入 126 outputs，仓库现有 63 个 `.g.dart`；`libisar.dylib`
  SHA-256 = `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- TDD：新测试先精确因缺少 `fromEncounterMapping` 编译失败；实现后
  新测试 6/6。九个文件联合 targeted（新测试、numeric/stage/charge/
  real-skill settlement 直接回归、mainline 结算两文件、encounter
  mapping 与 migrated plan）精确 94/94。
- 静态验证：scoped `flutter analyze --no-pub` 2 items，0 issue；
  `dart format --output=none --set-exit-if-changed` 2 files，0 changed；
  `git diff --check`、baseline path audit、status / main refs 均通过。
- 提交：`439c57e8` 计划恢复点、`f9538bc1` API / Pi 设计证据、
  `ff434ec7` 红测、`394b442c` 最小实现。
- 下一步：提交本收口恢复点，复跑最终证据，追加精确 READY
  空提交后交还主控。
- 阻塞项：无。
- 生产接线：未接；本切片只新增显式 adapter 入口。
