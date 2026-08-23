# P2-M2-D01-CH1：Ch1 candidate-only / non-production combat catalog

## 目标与边界

仅在 `test/fixtures/phase2/combat/ch1_candidate/**` 交付第 1 章山匪目录候选，以 C01 catalog schema 与 R03 objective controller 作为冻结合同。全部数值均为 candidate-only / non-production、未冻结、不可被 production path 消费。

- 分支：`codex/phase2-m2-d01-ch1-candidate-data-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-d01-ch1-candidate-data`
- 基线：`02ab6df5f42ff21f8ae27c752c97d58969dda62c`
- 允许：`test/fixtures/phase2/combat/ch1_candidate/**`、`test/data/phase2/ch1_candidate_combat_catalog_test.dart`、本计划。
- 禁止：task/decision registry、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、`lib/**`、production `data/**`、host/UI/save/reward/injury/formula。
- 前置合同集成：按主控指示 cherry-pick 上游 `e4762e71` 为本分支 `53a0e87c`；其 `lib` 与 C01 测试/审计改动是上游原子提交，不属于 D01 实现 diff。D01 自身仍只改三类允许路径。

## 冻结语义与候选约束

- 山匪四个 canonical role ID 仅为 `bandit_blade`、`bandit_crossbow`、`bandit_rope_raider`、`bandit_gong_leader`。
- 五关映射仅为 `stage_01_01..05`，依次表达破路 / 据点 / 伏击 / 斩将 / 斩将。
- `stage_01_03` 候选总量 40、active 12，均处 35–45 / 8–16 边界内；攻击令牌总预算按每关 2–4 的保守候选表达，各类预算显式且不宣称平衡冻结。
- objective 只使用 C01/R03 的扁平 `all | any` 与八原语；不定义 failure、timeout、phase、residual-enemy、reward 或 production flow。
- entrance / position / behavior / attackSet / attack tag / posture / drop / sfx / visual，加 objective target / anchor / entity / checkpoint / marker，共十四类 namespace 由测试提供完整显式 reference index，loader 与 manifest 共同 fail closed。
- 候选 fixture 通过路径、文件头 marker、ID 前缀与 production `data/**` 反向扫描防止误接生产。

## Pi + DeepSeek V4 Flash 只读使用记录

- `pi 0.84.1` 可用，model catalog 包含 `deepseek/deepseek-v4-flash`。
- 只读 auth probe：`status=ready`、`authType=api_key`；未使用 credential 输出参数，未打印密钥。
- 无工具、无会话连接探测返回 `DEEPSEEK_V4_FLASH_READY`。
- 无工具、无会话内容审查返回 `REVISE`：认可 40/12、五关顺序和扁平目标；建议补齐 warning/grace tick、逐 role 分布、entity ID 与引用闭合。基线 C01 当时尚无 objective namespace，因此先完成既有九类；随后 Batch10 终审把该缺口升级为 P1，并由上游 `e4762e71` 正式补齐五类合同。
- 实际 3 份 YAML + test 首轮无工具终审返回 `PASS`：确认 canonical IDs、五关顺序、40/12、token 总预算 4/4/4/3/2、既有九类引用闭合与 production 隔离，并准确指出待上游闭合的 objective ID 风险。
- cherry-pick 上游后第二次无工具终审再次返回 `PASS`：确认 70 个 objective target、2 个 anchor、1 个 checkpoint 及空 entity/marker 集合精确闭合，且未新增 failure/phase/residual/reward 语义。

## 验收 checklist（CLAUDE §8.2）

- [x] TDD 红：先提交测试，因 candidate fixture 缺失失败，并记录命令/错误。
- [x] 4 archetype roles、5 encounters、5 stage assignments 均由真实 C01 loader/manifest 加载。
- [x] 五关模板顺序、canonical IDs、`stage_01_03` 数量/active 与 token 候选守卫通过。
- [x] 十四类外部引用显式 reference index 精确闭合，无未知或多余 ID。
- [x] 每个 objective composition 经 R03 mapper 构造 controller；不新增目标语义。
- [x] production 隔离负向守卫、数量越界与 canonical ID 漂移守卫通过。
- [x] targeted test、C01/R03 关键回归、scoped analyze、format、`git diff --check` 通过。
- [x] 红线：D01 0 production data、0 `lib`、0 中文玩家文案、0 三系/伤势/奖励/save/UI/formula 触点；前置 C01 原子 commit 单列。
- [x] 常规实现 commit 后追加 `[READY][PI][P2-M2-D01] Ch1 候选目录与目标 fixture 完成` 空提交，树干净。

## 任务切片

1. 读取项目红线、已否清单、C01/R03 计划、二阶段方案 §13/§14/§15/M2。
2. 只读探测 Pi + DeepSeek V4 Flash，并审查候选结构。
3. 先写 candidate-only tests，执行缺 fixture 红测并记录证据。
4. 最小实现 archetype / encounter / assignment fixtures。
5. 运行 targeted、scoped analyze、format、diff/path 边界审计。
6. 更新恢复点，提交实现与 READY 空提交。

## 当前恢复点

- 状态：实现与前置合同适配完成，最终验证已绿；本计划随普通实现 commit 冻结，随后立即追加指定 READY 空提交。
- 最后完成：cherry-pick `e4762e71` 为 `53a0e87c`；扩展十四类显式 reference index；第二次 DeepSeek 实际文件终审 `PASS`；候选 targeted 9/9，C01 loader/manifest/schema + R03 mapper 联合关键回归（含候选）63/63，scoped analyze 8 项 0 issue。
- 下一步：主控独立检查实际 diff、测试证据与候选风险，决定后续集成；本任务不接 production。
- 已跑验证：`flutter pub get --offline` 成功；TDD 红测 2 pass / 7 fail（预期缺 fixture）；实现后候选 targeted 9/9；联合关键回归 63/63；`flutter analyze --no-pub` scoped 8 项 0 issue；`dart format` 当前 0 changed；`git diff --check` 通过。
- 阻塞项：无。
- 残留风险：候选 token 与 role multiplier 未经自动模拟、双平台 Profile 或真人试玩，不得冻结或接生产。
