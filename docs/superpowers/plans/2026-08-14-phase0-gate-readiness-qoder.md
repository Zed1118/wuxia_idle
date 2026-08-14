# Phase 0 外部门禁工程就绪（Qoder）

## 目标

独立审计并补齐 Phase 0A 真人试玩与最低档 Windows 实机 Gate 的工程准备，使外部参与者拿到包后能够按冻结协议运行、回传、校验和裁决；不生成或伪造外部结果。

## 分支

`feat/phase0b-qoder-gate-readiness`，基线 `06ab4162`。

## 验收标准

- 只改 `tools/phase0minus_probe/`、`docs/phase0/`、相关 spec 和本计划文件；不得接根应用或改变正式游戏规则。
- 逐项核对 Windows 构建/硬件 manifest/两视口×3 runner/结果 validator/SHA-256，以及 6 人类型配额、匿名 session、原始 JSON、聚合裁决链。
- 外部审查发现必须先复现或给出代码证据；只修真实阻塞，禁止照单全收和范围扩张。
- 增加必要的契约测试或失败夹具，证明远程桌面、独显代签、混 commit、样本不足、重复测试者和缺失证据均 fail-closed。
- 形成一份操作者可执行的 readiness 报告：已就绪、仍需人类/设备、回传目录、验证命令、失败处置。
- 不运行真实 Windows Gate，不把作者/Agent 当真人测试者，不填写主观评分。
- 跑 `flutter analyze --no-pub` 及直接相关 targeted tests，并记录精确通过数。
- 说明红线影响与残留风险；不得新增生产中文文案或生产数值。
- 工作区全部提交且干净；最终 tip 使用 `[READY]`，若发现协议需项目主人拍板则用 `[BLOCKED]`。

## 任务切片

1. 对照规格审计 Windows 与真人 Gate 全链。
2. 用测试/夹具复现真实缺口，完成最小修复并小切片提交。
3. 编写 readiness 报告和操作顺序。
4. 跑 targeted + analyze，复核未触碰正式路径。
5. 冻结分支并写 `[READY]` 或 `[BLOCKED]` tip。

## 当前恢复点

- 状态：已建隔离 worktree，等待 Qoder 执行。
- 最后完成：`flutter pub get`；Windows/isolation/viewport targeted 13/13 通过。
- 下一步：按冻结规格审计外部门禁全链并做破坏性证伪。
- 已跑验证：`test/gate`、`test/isolation_contract_test.dart`、`test/viewport_calibration_contract_test.dart` 共 13/13。
- 阻塞项：真实 Windows 物理机和 6 名真人不在本任务内；只能准备和验证工具链。

