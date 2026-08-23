# P2-M2-V01：验证 Ch1 五关候选运行时构造

## 目标与边界

仅新增一份 candidate-only 测试，将现有 Ch1 五关 fixture 逐关经过
catalog loader → typed migrated route selector → R11 migrated runtime plan builder →
Batch14 `assembleMigratedEncounterPlan` 显式 seam，证明候选数据能完成结构构造。

- 分支：`codex/phase2-m2-v01-ch1-candidate-runtime-construction-matrix-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-v01-ch1-candidate-runtime-construction-matrix`
- 精确基线：`7bc31c5f5463aac26e127912576350487ac0a8d3`
- owned files 仅为本计划与
  `test/data/phase2/ch1_candidate_runtime_construction_matrix_test.dart`。
- 禁止：fixture、production data、host、tuning、registry、audit、main 及其他任何文件。

## 冻结语义

- 五关必须从现有三份 candidate fixture 经真实 `loadCombatCatalogManifest`
  加载，不手造 encounter 或 route。
- `stage_01_01..05` 逐关经 `selectCombatStageEncounterRoute`，必须得到持有
  exact manifest encounter identity 的 `MigratedCombatStageEncounterRoute`；legacy 不允许回退。
- 每关经 `buildPhase0aMigratedEncounterPlan` 构造 fresh runtime contracts、same-director
  roster 与 mapping，然后交给 Batch14 assembler seam。
- runtime actor ID 由 caller 按 content order 提供独立命名空间；不把 actor ID、
  entry ID、role、defeat kind 或字符串规则推断为 objective identity。
- R13 `defeatProjectionsByActorId` 的 key set 必须 exact 覆盖 roster actor ID，
  且每个 actor 的 value 都是显式空 projection list；不生成 target / commander
  payload，`externalProjectors` 也为空。
- 测试不调用 `advance` / `eventsFor`，只断言 tick/spawn tick/outcome 保持初始态且
  assembler 构造不消费 caller RNG。
- 本切片不宣称 objective executable、production vertical slice、平衡、性能、
  host 接线或任何 candidate/tuning 冻结。

## 验收 checklist（CLAUDE §8.2）

- [x] TDD 先因目标测试的结构期望失败，再补齐五关矩阵并转绿；
  五关分别作为含 stage ID 的独立命名 test case。
- [x] 真实 loader 加载 5 assignments / 5 encounters，五关均选出 exact typed
  migrated route。
- [x] 每关 plan 保持 route/encounter identity 与 bundle/mapping/roster director identity。
- [x] 每关 assembler seam 构造成功，state tick/spawn tick 仍为 0、outcome 仍为
  ongoing、RNG 首值未被消费。
- [x] R13 source 精确覆盖 roster actor ID，每 actor 显式空 projection；
  missing/extra coverage 继续 fail closed。
- [x] 源码守卫禁止 `advance` / `eventsFor` 与 objective identity 字符串推断；
  文件头与计划明确不宣称 production vertical slice / balance / performance。
- [x] 运行新测试及 Ch1 catalog / route selector / R11 / R13 / Batch14 composition
  去重 targeted，并完成 scoped analyze、format、diff/path/status 守卫；不跑 full。
- [x] Qoder CLI 1.1.x 精确 `Qwen3.8-Max` / reasoning `high` 完成编码前
  设计审查和最终 diff 只读审查，如实记录结论。
- [x] 红线：0 production/candidate tuning 数值/公式变更，0 production
  data/玩家文案/三系/在线离线/反主流/reward/save/UI/host 接线变更。
- [x] 所有非空提交使用中文动宾，tip 追加精确 READY 空提交。

## 任务切片

1. 读取项目红线、已否清单、候选 fixture/catalog 与 route/R11/R13/Batch14 合同。
2. 调用 Qoder/Qwen3.8-Max/high 完成编码前只读设计审查，提交本计划恢复点。
3. 新增五关构造矩阵测试，先跑有效红灯，再最小补齐。
4. 运行去重 targeted 与静态/范围守卫，调用 Qoder 审查最终 diff。
5. 更新恢复点与验证证据，提交后追加指定 READY 空提交。

## Qoder 只读审查证据

- CLI/version：`qoderclicn` 1.1.28；`--list-models` 实测包含精确
  `Qwen3.8-Max`。
- 设计审查：实际使用 `Qwen3.8-Max` + `--reasoning-effort high` +
  `--permission-mode dont_ask` + Read/Grep/Glob-only + `--no-session-persistence`，
  显式禁 Edit/Write/Bash。结论为 **PASS（附条件）**，确认五关的构造
  seam 存在，建议守住 namespaced runtime actor ID、exact coverage、零 tick/RNG
  消费和误宣称边界。Qoder 另建议字面量 actor↔objective 投影表，
  该建议与本任务“逐 actor 显式空 projection”冲突，经 Codex triage 后
  拒绝：V01 不生成任何 objective payload，因而也无 objective identity 推断。
- 最终 diff 审查：实际使用同一 `qoderclicn` 1.1.28 /
  `Qwen3.8-Max` / reasoning `high` / Read+Grep+Glob only /
  `--no-session-persistence` 配置，显式禁 Edit/Write/Bash。完整读取两个
  owned files 并对照 fixture/catalog/route/R11/R13/Batch14 合同后结论
  **PASS**，P0=0、P1=0。三条信息级 P2：误宣称边界并非全部机器守卫
  （已修正 checklist 文字）；五关单 test 循环的失败定位粒度较粗；
  exact key set 断言为无害的契约文档化重复。后续 Codex 独立复审已将
  五关拆为五个命名 case；exact key set 断言仍保留为合同证据。
- 不记录或输出 token/key。

## Codex 独立复审收口

- 独立复审确认 P0=0、P1=0，并提出两条非阻塞 P2：红线文字对测试
  scaffold 数字过宽，以及五关单 test loop 定位粒度较粗。
- 本收口将红线精确为「0 production/candidate tuning 数值/公式变更」；
  五关分别命名为 `stage_01_01..05` 的独立 test，复用同一 helper 与同一组
  构造/边界断言，不扩大行为面。
- Qoder 最终审查证据指向前一 READY `277bbabd`；本次仅按独立复审
  收口两条 P2，不冒充 Qoder 对收口 diff 做了第三轮审查。

## 当前恢复点

- 状态：前一 READY `277bbabd` 的独立复审 P2 已收口；计划边界表述
  已精确化，五关已拆为五个命名 test case，其余行为与断言不变。
- 最后完成：新测试 7/7 PASS；同一六文件去重 targeted 因新增四个
  命名 case，真实计数从 47 变为 51，实测 51/51 PASS；scoped analyze
  0 issue；format 0 changed。
- 下一步：提交本收口修正，追加与前一次同文本的 READY 空提交，
  交还主控。
- 已跑验证：只读确认初始 `HEAD=7bc31c5f5463aac26e127912576350487ac0a8d3`
  且工作树干净；`qoderclicn --version` = 1.1.28，model catalog 含精确
  `Qwen3.8-Max`；设计审查真实返回附条件 PASS。TDD 红灯为 0 pass /
  1 fail（矩阵尚未实现）；初次补齐后新测试 3/3、六文件去重 targeted
  47/47 PASS。独立复审收口后：新测试 7、Ch1 catalog 9、route selector
  10、R11 7、R13 15、Batch14 composition 3，合计 51/51 PASS；scoped
  `flutter analyze --no-pub` 新测试 0 issue；
  `dart format --output=none --set-exit-if-changed` 0 changed；
  `git diff --check 7bc31c5f..HEAD`、精确两 owned files 与 clean status 通过。
- 阻塞项：无。
- 残留 Gate：objective 事件生成与可执行性、production host/data 接线、
  candidate 数值冻结、平衡、性能、真人试玩与双平台 Profile 全部继续 Gate。
