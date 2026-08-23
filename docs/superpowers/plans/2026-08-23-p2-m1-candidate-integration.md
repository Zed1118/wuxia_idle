# P2-M1 C02–C10 候选整合计划

## 元数据

- taskId：`P2-M1-CANDIDATE-INTEGRATION`
- branch：`codex/phase2-m1-candidate-integration-20260823`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-integration`
- base：`e292d3a069fbc0e129dd74fafc1ebb3746f53557`
- 性质：隔离候选整合；不接生产入口，不合并或 push `main`

## 范围

整合并主审 C02–C10：六几何、动作时间线、防御解析、姿态、固定拍状态、真气账本、五武器普攻链结构、三特性 modifier、事件顺序/表现 feed；同时纳入 Pi + DeepSeek Flash 的 M0 实现差距证据包。

## 验收

- 九模块联合 targeted：77/77 通过。
- 九模块实现与测试共 18 个文件：`flutter analyze --no-pub <18 files>`，0 issue。
- 新 worktree 补齐根包 build runner 产物和归档 probe 子包依赖后：`flutter analyze --no-pub`，0 issue。
- `git diff --check` 通过，工作树 clean，最终 tip 使用 `[READY][CODEX][P2-M1]`。

## 当前恢复点

- 状态：候选代码和 Pi 证据已整合、已验证；等待 Qoder 性能/测试基线和 M0 协调文档并入后终验。
- 已知边界：九个模块均未接 `phase0a_combat_model.dart`、reducer、数据、存档或 UI，不代表生产玩法已完成。
- 未决：`PROPOSED` 产品决策与已否方向重开项继续 blocked；不得由候选 API 反推已拍板。

