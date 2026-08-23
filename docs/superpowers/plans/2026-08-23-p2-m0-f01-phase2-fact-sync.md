# P2-M0-F01：二阶段长寿文档事实同步

## 范围

仅修改 GDD、CLAUDE、PROGRESS 与本计划文件；同步可验证事实及未决索引，不改代码、YAML、registry 或玩法决策。

## 已核实事实

- `data/stages.yaml` 的 `stageType: mainline` 共 105 条，覆盖 21 章。
- registry 中 P2-G1/P2-G2 已完成项以 `ready_reviewed` 为 READY 事实；P2-G2 Batch7 为 `in_progress`，O01/S01 为 `dispatched`。
- 方案明确要求 `PROPOSED`/`TUNING` 不得在 G0 前写成已批准合同。

## 未决索引

主线重打/前台 bot/headless/扫荡参与者、连续 `MainlineRun` 锁定与换装/伤势中断、随行听剑占用、七类心魔 AI 映射、心魔失败是否扣主修修炼度，以及听剑成长比例/每关上限仍待 G0 明确决策或调参。

## 验收

- [x] 只改四个允许文件。
- [x] 关卡与章节计数可复现。
- [x] `rg` 对账 READY/进行中/已派发与未决词。
- [x] `git diff --check` 通过；未运行 build_runner。
