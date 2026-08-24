# P2 M6 Batch 1：叙事去阻塞与断魂庄自动化准入

## 并发设计

- 会话 A 独占 mainline presentation、manifest、对应 tests 与 `UiStrings`。
- 会话 B 独占 boss gauntlet domain/application 与对应 tests。
- 主控独占两个 registry、真相文档、审计和集成分支；两个源会话均不得直接修改 main。

## 合并门禁

1. 两个源任务均有 clean READY commit、精确外部模型设计/终审证据、targeted 与 scoped analyze。
2. 主控逐文件核验白名单与 `base..tip`，对外部报告独立证伪；缺陷回源修复，不在集成分支偷偷改源代码。
   - source patch 白名单以 `a6a373e1..source_tip` 核验；`693ed157` 仅为产品语义基线。
   - integration allowed scope 为两 source owned_files 与 batch owned_files 的并集，但主控自行 authored scope 仍只允许 batch 文档；源代码 blob/patch identity 必须与 source tip 一致。
3. 临时集成后运行联合 targeted、changed/root analyze、完整 `flutter test --no-pub`、registry/schema/叙事完整性检查和独立审查。
4. 只关闭本批真实 DoD；U01/U04/U05、完整五连关、G2、M3/M4、rulesVersion 和全模式自动化仍保持开放。
5. 生成审计、同步 `CLAUDE.md/GDD.md/PROGRESS.md`、冻结 `[READY]`，main 与 origin/main 均保持不变。

## 终态证据

- source READY：主线叙事 `802511dc987d1b2cffd96419be4b48c79e6cefc8`；断魂庄准入 `e6b733b606d9bb7463d6a33d2e6c19082f1f713b`。
- 集成验证冻结点：`1311399cda7a245d30a471b3af27603c761646b6`；23 个 source owned file 的 blob/mode 与两个 source tip 全部一致。
- 联合定向：151/151；断魂庄整目录：181/181；20 个变更 Dart format 0 change、analyze 0 issue；根 `flutter analyze --no-pub lib test tool` 0 issue；`git diff --check` 通过。
- 全量：`flutter test --no-pub -r compact` 5195/5195，`All tests passed!`，exit 0。此前中止产生的 `-1`/sink/finalization 噪声由本次完整成功覆盖。
- 外部 source 终审均 P0/P1=0；主控 source blob/mode、真实 diff 与联合集成审查 P0/P1/P2=0。
- 终态七文件 patch 经 Qoder `Qwen3.8-Max` / high / Read-only 独立复核，exit 0，P0/P1=0，结论 READY；仅报告 GDD 历史摘要与 PROGRESS 行数两项既有 P2，不扩大本批范围处理。
- 边界：U01/U04/U05、完整五连关、rulesVersion、全模式自动化、G2、M3/M4 仍开放；远征与驱散 source READY 留待独立小批，不计入本批。
- Git：验证后 worktree clean；`main`/`origin/main` 均保持 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。

## 恢复点

- 状态：代码、全量门禁、终态 registry/decision/三份真相源/audit/plan 与文档/Git 边界独立复核全部通过；等待追加唯一 READY tip。
- 本批 READY marker：`[READY][CODEX][P2-M6-BATCH1] 冻结叙事去阻塞与断魂庄自动准入`。
- 后续调度：不再扩张微任务；先精确清理 G1 非终态，再把 Ch1 candidate catalog 迁入 production loader/host，只以 `stage_01_03` 黑风岭完成 G2 八项。
