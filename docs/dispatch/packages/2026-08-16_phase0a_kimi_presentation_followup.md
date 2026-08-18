# Phase 0A 表现层审计收窄返修（Kimi）

`f5b6a12e` 的现状盘点基本可复核，但“后续小切片”仍把 probe 当作实装目标，与项目主人已拍板的“进入根应用生产接线”冲突。请只修订原两份文档，新增返修 commit，不 amend/rebase。

## 硬口径

- probe 从此只是手感/图像/性能参考和验收证据，不再扩展其美术、HUD、音频依赖或实现。
- 不在 probe 引入音频依赖；复用根应用现有 `lib/shared/audio` 链路，缺的 battleDeath/battleUlt/Q/R 等专用资产在根 `assets/audio/` 补齐。
- 后续表现层实装域是根应用纯 Flutter 战斗表现层 + 根 `assets/`；实际文件名待 Qoder 生产接线路线冻结后再定，不在审计中虚构。

## 必改

1. 总览保留事实盘点，但将“表现层缺口集中在 probe”改为“probe 提供新方向参考，根应用仍是旧战斗形态，缺口需随生产接线在根应用补齐”。
2. 重写“后续小切片”：
   - P0 只允许资产规格/资产制作与根应用接线前置，不改 probe renderer；
   - 纯 Flutter 动作/特效/HUD 实装必须排在 Qoder 的 deterministic simulation core 与 input adapter 边界确立之后；
   - 音效走根应用现有后端，删除 probe 引入依赖选项；
   - 验收继续使用 probe 已有双视口/可读性基线作对照，但正式验收对象必须是根应用真实入口。
3. 计划恢复点同步改为上述口径，阻塞项为无。
4. 只改原两文档，`git diff --check`，tip 以 `[READY]` 开头，worktree 干净；其余禁区沿用原派单。
