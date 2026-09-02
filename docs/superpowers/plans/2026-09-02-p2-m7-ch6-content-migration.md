# P2 M7 第六章内容迁移计划

## 结果合同

- 单一结果：复用已集成的门派与西凉生态、普通关/小 Boss/章末 Boss 模板和既有目标原语，把 `stage_06_01..05` 接入真实 typed catalog、runtime binding 与 production encounter factory。
- 固定分母：第六章 `0/5 → 5/5`；全主线 typed production catalog `28/105 → 33/105`。塔保持 `0/49`，legacy runtime retirement 仍开放。
- 实时基线：当前分支从 `c75a57c76fde3752f9030b4fd8b44af49ba0ffc5` 建立；用户提供的事实为 `main == origin/main == c75a57c7`，第五章已合入且 exact-SHA CI run `33645109247` 成功；本 worktree 初始 clean。
- 关键阻塞：第六章 `StageDef`、章节解锁链和 opening/victory/defeat 叙事完整，但 `stage_06_01..05` 尚无 assignment、encounter、runtime binding，生产 factory 因此会返回 null 并落回 legacy mapper。
- 预期变化：只增加五条真实生产迁移路由；正式 M7 仍开放，Phase 2 仍为 `1/10`。
- 成本边界：单一第六章数据切片；约 90 分钟无生产门变化则停止扩面并重评。

## 非目标与保护边界

- 不重做 P0，不处理 `stage_02_05` 高基础随从风险，不启动 M8/M9。
- 不改 `stages.yaml`、`numbers.yaml`、敌人/玩家数值、Boss 招式、掉落、奖励、经济、叙事、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不增加玩法规则、TUNING 数值或第二套 runtime。
- 真人桌面、普通存档平衡、视觉、音频、手感和 Windows 全部继续 `DEFERRED`；自动化不得代签。

## CLAUDE.md §8.2 验收清单

1. 第六章五关各有唯一 migrated assignment、encounter 与 runtime binding，且基敌严格等于各自 `StageDef.enemyTeam.single`。
2. 真实 production repository、factory、runtime adapter、enemy AI、director、objective 与 reducer 完整消费。
3. 初始 RED；真实动态 headless 战斗覆盖敌人生成、目标、Boss 身份、终局和超时。
4. 至少两向有效 mutation 精确证红并用反向补丁还原。
5. targeted、相邻回归、`flutter analyze --no-pub lib test tool`、`dart format .`、持锁全量和标准 Gate 通过。
6. 更新 `PROGRESS.md`、task registry、本计划和审计；最终 `[READY]` 中文动宾提交且 worktree clean。

## 当前恢复点

- 分支：`codex/p2-m7-ch6-content-migration-20260902`。
- worktree：`/Users/a10506/.codex/worktrees/728d/挂机武侠`。
- 状态：第五章已在基线 `c75a57c7` 形成 `28/105` 集成水位；第六章五关尚未接入，候选分子目标为 `33/105`。
- 生产缺口证据：`stage_06_01..05` 在 `data/stages.yaml` 及叙事 manifest 有完整身份，但 assignment、encounter、runtime binding 均为 `0/5`。
- 实施策略：新增一份第六章 encounter catalog，复用 `ch2_sects` / `ch4_xiliang` 已冻结的 entrances、positions、behaviors、attack sets、visual variants 和 verified-only references；不新增玩法语义或数值。
- 交付边界：未经用户再次授权，不 merge、不 push；真人桌面、普通存档平衡/手感、视觉、音频与 Windows 继续挂账。

## 收口结果（2026-09-03）

- 初始有效 RED：`0/6`（环境缺依赖与生成文件的首次失败未计入产品 RED）；恢复后第六章专测 `6/6`。
- 生产接线：五个 assignment、encounter、runtime binding 均为 `5/5`；真实 factory 路由与动态 headless 胜利均为 `5/5`，第六章候选主线水位 `28/105 → 33/105`。
- 破坏证红：删除 `stage_06_03` assignment 与篡改 `stage_06_05.base_enemy_id` 各造成一次 fail-closed；反向补丁后 SHA-256 分别恢复为 `0150329fd6cfaae7ebd76a84efa0ce07890b7ba4633cb282037f5a3ab61d4aa3` 与 `681aee7c9bac89025e36d72c0c45f1548d08936466e6c45c927526b440c02e80`。
- 回归：Phase 2 数据 `96/96`、mainline application `183/183`、整仓持锁全量 `5905/5905`，reporter `[E]` `0` 且锁已释放；`flutter analyze --no-pub lib test tool` 无问题，`dart format .` `1720 files (0 changed)`。
- 状态边界：标准 Gate 已在 `c75a57c7..b7a2fdf5` 独立复跑；`forbidden_files`、full `5905/5905`、analyze、format 通过，零 `lib/` 改动故 `receipt_crosscheck` 跳过。最终分支 tip `[READY] b63a8155`、worktree clean；同树 READY 评估 tip `a49151c7` 的静态 Gate 全过，`test_deletions=1` 由测试契约迁移门覆盖，full 已由同树先前 Gate 通过。候选分支不进入 main/origin，不关闭正式 M7/Phase 2；真人桌面、视觉/音频/手感和 Windows 继续 `DEFERRED`。
