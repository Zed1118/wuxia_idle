# P2 M7 第七章剩余内容迁移计划

## 结果合同

- 单一结果：复用已存在的 `ch7_army` 生态和 `stage_07_01/04` 生产模板，把真实缺口 `stage_07_02/03/05` 接入 typed catalog、runtime binding 与 production encounter factory，使第七章 `2/5 → 5/5`。
- 固定分母：全主线 typed production catalog `33/105 → 36/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 仍 `1/10`。
- 实时基线：分支从治理纠偏 commit `5aac9f5c5d2a6215e37f9030e87beb83d4bc5c96` 建立；`main == origin/main == c75a57c7`，当前候选已含第六章 `33/105`。
- 关键阻塞：第七章五关的 StageDef、叙事和既有军阵生态完整，但 `07_02/03/05` 各缺 assignment、encounter、runtime binding，生产 factory 会落回 legacy mapper。
- 成本边界：只处理三条真实缺口；约 90 分钟无 `33→36` 可验证增量则停线重评。

## 非目标与保护边界

- 不改 `stages.yaml`、`numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、叙事、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不启动 M8/M9，不扩展新的战斗原语或生态。
- 真人桌面、普通存档平衡、视觉、音频、手感和 Windows 继续 `DEFERRED`；自动化不得代签。

## CLAUDE.md §8.2 验收清单

1. `07_02/03/05` 各有唯一 migrated assignment、encounter 与 runtime binding，基敌严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第七章总计 `5/5`。
3. 初始 RED；新增三关动态 headless 覆盖敌人生成、目标、Boss 身份、终局和超时。
4. 至少两向 mutation 精确证红并反向还原。
5. targeted、相邻回归、analyze、format、持锁全量及 Gate 如实记录；测试契约删除仅由专用迁移门覆盖。
6. 更新 PROGRESS、task registry、计划与审计，最终 tip `[READY]`、worktree clean；不 merge、不 push。

## 执行结果

- 完成 `stage_07_02/03/05` 唯一 assignment、encounter 和 runtime binding，第七章 `2/5 → 5/5`，叠加候选主线 `33/105 → 36/105`；已集成 main/origin 仍为 `28/105`。
- 初始有效 RED `0/6`；首次实现 `5/6` 暴露 `stage_07_05` 三个 Boss 基模衍生 actor 并发必败，不改数值/技能/奖励，改为 `active_limit: 1` 依次入场后定向 `6/6`。
- 两向变异均精确证红：删 `stage_07_03` assignment 和错绑 `stage_07_05.base_enemy_id`；反向补丁后两文件 SHA-256 与变异前一致。
- 验证：第六+第七章 `12/12`，Phase 2 data `102/102`，mainline application `183/183`，analyze 零问题，format `1721` 文件零变更，持锁全量 `5911/5911`、`[E] 0`、锁已释放。
- 测试契约迁移门：删除旧精确计数断言 1 条，新增断言 28 条、用例 6 条，登记 1 条，原生 `PASS: test_contract_migration`。
- 实现 commit：`1d5b9f8ab6997940e332d563e9fdb1bfcd0bdf42`。标准 Gate 在最终 READY 治理提交后对 exact tip 执行，原始结果不在本文预判。
- 集成前语义复核否决了 `07_02/07_05` 的扩写敌组：两关分别按正文/spec 收回单骑与单 Boss，删除未获 canon 支持的四名衍生角色；exact actor-id、Boss 名称/原图/技能/蓄力/阶段断言及两向语义变异通过后再进入集成评审，主线分母仍为 `36/105`。
