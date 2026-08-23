# P2-G0-EVIDENCE：二阶段 G0 只读决策包计划

## 元数据

- Task ID：`P2-G0-EVIDENCE`
- 里程碑：Phase 2 / G0
- 基线分支：`codex/phase2-g2-batch7-data-contracts-20260823`
- 事实快照基线：`fcc2730e6d9ccbad0a9dc371aecc4cf3c244eccb`（短哈希 `fcc2730e`）
- 工作分支：`codex/phase2-g0-decision-packet-20260823`
- 工作模式：只读取证；只新增决策包与本计划
- 禁止事项：不得修改或合并 `main` / `origin/main`，不得 push，不得修改代码、数据、测试、长寿文档或 registry，不得以推荐代替用户决定

## 目标

把二阶段方案、决策/否决 registry、M0 审计与当前生产代码/测试交叉核对成一份 G0 决策包。每个未决项都必须包含：当前生产事实及精确证据、旧否决冲突、互斥选项、未拍板时的安全默认、M2/M5/M6 受影响路径，以及一句可直接由用户回答的问题。

## 文件白名单

只允许新增：

1. `docs/audit/phase2_g0_decision_packet_2026-08-23.md`
2. `docs/superpowers/plans/2026-08-23-p2-g0-decision-packet.md`

## 非目标

- 不批准任何 `PROPOSED` / `proposed_reopen`。
- 不为 `TUNING` 写入生产数值。
- 不新建、更新或删除 decision / rejected registry 条目。
- 不实现 `MainlineRun`、随行听剑、七心魔定制 AI、双装配、江湖纪事、图标预警、统一归来报告、轻功差异化奖励或失败建议 UI。
- 不运行 `build_runner` 或 full test；文档任务不需要 Flutter 动态验收。

## 执行切片与恢复点

### Slice 1：固定基线与读取约束

- [x] 从指定基线建立独立 `codex/` 工作分支。
- [x] 完整读取 `CLAUDE.md`、`GDD.md`、桌面二阶段方案、decision registry、rejected registry、M0 audits。
- [x] 确认初始工作树 clean，且未触碰 `main` / `origin/main`。

恢复点：初次取证为 `e2c3da7690ed4f1ca4b8c7586e3049dd38b0483f`；指定 Batch7 后续先前移至 `6594dde268dfe2d484593ebbb08127dd4fdb8ac4`，再前移至已含 L01 loader/validator 与验收登记的 `fcc2730e6d9ccbad0a9dc371aecc4cf3c244eccb`。主控已明确要求在 `fcc2730e` 冻结事实快照；本包不再自动 fast-forward，只在后续整合时复核快照后增量是否影响结论。

Batch8 整合预检已复核 `fcc2730e`→`1a4e1dd352552929cb9d762f6de1f1d32e2391c7`：O02 目标引用纯映射、L02 迁移覆盖 Gate、对应测试/fixture 与 Batch7 验收文档均未增加生产数据、host routing、调参或用户产品语义，不改变 G0 结论。

### Slice 2：并行只读取证

- [x] 方案/长寿文档证据核对。
- [x] registry/M0 审计及历史否决核对。
- [x] 当前生产代码/测试证据核对。
- [x] 主会话交叉审查，区分“旧审计事实”“当前生产事实”“提案候选”。

恢复点：三路子 agent 均未写文件、未提交；代码/测试核对子 agent 在收到资源锁协调更新前已启动三组 `--no-test-assets` 纯合同/策略 targeted tests。协调更新后主会话与所有子 agent 均未再启动 Flutter/Dart/build_runner。

### Slice 3：编写决策包

- [x] 覆盖核心五项、听剑 TUNING、未登记 PROPOSED、断魂庄登记缺口、全部 `proposed_reopen`。
- [x] 每项写出六类必需信息及用户一句话问题。
- [x] `MAINLINE-RUN-01` 作为唯一父 ID，锁人/换装/伤势中断三维必须全答后才能汇总，不擅自新增 registry ID。
- [x] 把安全默认明确写成“未回答时的暂停态”，不写成批准。
- [x] 把全部广义 `TUNING` 拆成可逐项回答的原子数据/模拟队列，不混入 G0 产品决策。

恢复点：见 `docs/audit/phase2_g0_decision_packet_2026-08-23.md`。

### Slice 4：静态验收与收口

- [x] 运行精确 `rg` 覆盖检查、`git diff --check`、白名单路径检查与 `git status`。
- [x] 检查 Flutter/native-assets 串行锁；本任务为纯文档，不启动 Flutter/Dart/build_runner。
- [x] 提交两份新增文档。
- [x] 以 `[READY][CODEX][P2-G0-EVIDENCE]` 空提交收口。
- [x] 保持工作树 clean；不 merge，不 push。

## 验收清单

- [x] 正确性：所有“当前生产事实”可从固定基线代码、数据或测试复核；M0 旧基线缺口已显式纠偏。
- [x] 范围：只新增白名单内两个 Markdown 文件。
- [x] 决策纪律：未把候选映射、安全默认或推荐写成用户批准。
- [x] 否决纪律：六个 `proposed_reopen` 均保留旧否决冲突与显式重开问题。
- [x] 依赖：每项均标注 M2/M5/M6 影响或明确“无直接路径”。
- [x] 红线：不改产品代码、数值、data、registry、长寿文档；不触碰 `main` / `origin/main`。
- [x] 静态检查：`rg`、`git diff --check`、白名单路径检查通过。
- [x] 提交：实现提交与 READY 空提交完成。

## 动态测试说明

本批次只有文档新增，不需要也不再启动 `flutter test`、`flutter analyze`、`dart test`、`build_runner` 或 full test。资源锁协调更新到达前，代码/测试核对子 agent 已启动并完成三组 `flutter test --no-pub --no-test-assets` 纯合同/策略测试，共 23 个测试用例通过；依赖 Isar 生成文件的相关测试未执行，且没有运行 `build_runner` 或补写生成文件。协调更新到达后不再启动任何 Flutter/Dart 命令。该结果只辅助核对当前纯合同，不是对未实现方向的动态验收；后续实现批次如需 Flutter 验收，必须先执行指定 `ps` 锁检查并等外部放行。

## 剩余风险

- 外部桌面方案不是 Git 跟踪文件；本包引用的是 2026-08-23 读取到的行号快照。方案若改写，须重新核对行号与状态标签。
- decision registry 尚未给渐进解锁、生态分配和断魂庄前台 bot 独立 ID；本任务只能报告登记缺口，不能替用户补登记或批准。
- `TUNING` 仍需要 YAML、模拟与目标 Windows 实机证据；本包只给出保守暂停态。
