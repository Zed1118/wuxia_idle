# Phase 0B 本机工程收口（Kimi）

## 目标

在隔离探针内完成当前不依赖真人、Windows 实机或人工美术的 Phase 0B 工程收口，重点补齐固定镜头 `phase0b_art_load` 的 1.0× 两视口×3 正式观察矩阵，并形成可复核证据。

## 分支

`feat/phase0b-kimi-closeout`，基线 `06ab4162`。

## 验收标准

- 只改 `tools/phase0minus_probe/`、Phase 0B 文档和本计划文件；不得接入根应用、存档、奖励或正式战斗。
- 完成 1280×720、1440×900 各 3 次，协议为 12s 预热 + 60s 采样 + 30s 冷却；不得缩短、伪造或把 smoke 冒充正式矩阵。
- 产物绑定同一干净 commit、设备/显示器/DPR、素材 SHA-256，并显式保持 `gate_eligible=false`。
- 若脚本、报告或校验存在阻塞性缺陷，先以测试复现再做最小修复；不扩展玩法、美术规格或正式资产。
- 更新 `docs/spec/2026-08-13-phase0b-art-sample-spec.md`，区分已完成、已验证、未完成和不能由 Agent 替代的 Gate。
- 跑 `flutter analyze --no-pub` 与 `flutter test --no-pub test/phase0b`，记录命令和通过数。
- 说明四类红线均未触及：数值硬红线、三系锁死、在线=离线、反主流不做项；不得在 Dart 散写中文或生产数值。
- 工作区全部提交且干净；最终 tip 使用 `[READY]`，若需要人类拍板或外部条件则用 `[BLOCKED]`。

## 任务切片

1. 核对 runner、采集字段和既有 0.05× smoke 的缺口。
2. 必要时先补测试/校验，再提交一个小切片。
3. 执行完整 1.0× 矩阵并验证 manifest/summary/hash。
4. 更新规格与恢复点，跑 targeted + analyze。
5. 冻结分支并写 `[READY]` 或 `[BLOCKED]` tip。

## 当前恢复点

- 状态：**已完成**。固定镜头 `phase0b_art_load` 1.0× 矩阵已执行并固化证据，分支 tip 已打 `[READY]`。
- 最后完成：补齐 art-load app/runner 的 `build_commit` 与 `asset_sha256` 字段；执行 1280×720 与 1440×900 各 3 次正式观察；`flutter test --no-pub test/phase0b` 2/2 通过；`flutter analyze --no-pub` 0 issue；工作区干净；tip 前缀 `[READY]`。
- 下一步：无。等待合并审核。
- 已跑验证：
  - 矩阵脚本 6 次观察均通过 runner 校验并生成 `phase0b-art-load-matrix-20260814T124851Z.json`；
  - `test/phase0b/phase0b_art_load_evidence_test.dart` 2/2 pass；
  - `flutter analyze --no-pub` 0 issue；
  - `tools/phase0minus_probe` targeted 测试 24/24 pass。
- 阻塞项：真人 Gate、Windows 实机、人工补画不在本任务内；不得伪造替代。

