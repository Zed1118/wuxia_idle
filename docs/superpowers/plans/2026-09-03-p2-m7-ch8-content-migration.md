# P2 M7 第八章内容迁移计划

## 结果合同

- 单一结果：把已存在的 `stage_08_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第八章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `36/105 → 41/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 仍 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch8-content-migration-20260903` 建于已验证 `origin/main` `56cf00224c5d72360f629255338c2b8d4e0995c9`；exact-SHA CI run `33707737979` 为 `completed/success`。
- 关键阻塞：五关 `StageDef`、正文和已有西凉/门派/军阵生态可复用，但 assignment、encounter 与 runtime binding 均缺失，production factory 会落回 legacy mapper。
- 成本上限：只处理这 5 条真实缺口；约 90 分钟无 `36 → 41` 可验证增量则停线重评。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不处理 `stage_02_05` 历史风险，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## CLAUDE.md §8.2 验收清单

1. `08_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第八章 `5/5`，全主线候选 `41/105`。
3. 红线影响：只复用已有 typed 生态，不改基础数值/技能/文案；Boss 身份、蓄力技、阶段与图路必须保持 `StageDef` 原值。
4. 测试先红；每关锁定正文支持的 exact actor set、目标、factory 构建与 dynamic headless victory；章中/章末 Boss 锁定名称、原图、技能、蓄力技、阶段和 `createActor` 身份。
5. 至少两向 mutation 精确证红并反向还原；targeted、相邻回归、analyze、format、持锁全量及标准 Gate 如实记录。
6. 更新 PROGRESS、task registry、本计划与审计；最终 tip `[READY]`、worktree clean。本分支不自行 merge/push，候选不关闭正式 M7/Phase 2。

## 任务切片

1. 盘点五关 `StageDef`、全文、现有 catalog 与生产消费方，固定角色/目标边界。
2. 先加第八章生产合同测试并记录有效 RED。
3. 增加五条 assignment、一个 encounter source 与五组 runtime binding，仅复用现有西凉/门派/军阵生态。
4. 运行 targeted，修正 factory/objective/dynamic host 真实缺口；做两向 mutation 并精确还原。
5. 跑相邻回归、analyze/format、批末持锁全量、测试契约门与标准 Gate，刷新治理证据后冻结 READY。

## 当前恢复点

- 状态：`[READY]` 候选已冻结；第八章 `5/5`、全主线候选 `41/105`，但 main 集成水位仍为 `36/105`。
- 最后完成：五条 assignment、一个 encounter source、五组 runtime binding 与真实 factory/objective/reducer 动态闭环已建立；正文角色集合及两名灰衣 Boss 完整身份已锁定。
- 下一步：对分支 exact tip 做独立 diff/Gate 复核；通过后才可 `--ff-only` 受控集成并跑 exact-main CI。本计划不自行 merge/push。
- 已跑验证：targeted `6/6`；第七、八章各 `6/6`；Phase 2 data `108/108`；mainline application `183/183`；analyze 零问题；format `1722` 文件零变更；持锁全量 `5917/5917`、`[E] 0`、锁已释放；测试契约门 `PASS`。标准 Gate 的 full/analyze/format/commit/clean 通过，原始终行仅为 `FAIL: forbidden_files,test_deletions`。三向 mutation 均精确转红并按 SHA-256 恢复。
- 阻塞项：候选尚未进入 main/CI；真人桌面、视觉/音频/手感与 Windows 继续挂账，正式 M7/Phase 2 不关闭。
