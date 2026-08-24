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
