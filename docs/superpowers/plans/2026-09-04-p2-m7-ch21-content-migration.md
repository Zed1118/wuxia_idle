# P2 M7 第二十一章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_21_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第二十一章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `96/105 → 101/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch21-content-migration-20260904` 建于 `main == origin/main == 8674d01eedf64ff63d154b46d0ab3ac6c9d9ed8e`；该 SHA 的 CI run `33853360403` 为 `completed/success`。
- 关键阻塞：五关 StageDef、13 份章节/关卡正文与 5 个敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；无可靠用量表，约 90 分钟无工程门变化即重评，不扩到第十三章、塔或 M8/M9。

## 审计选择依据

- 当前 `StageDef` 是权威输入：21-01/04 为 `gangMeng`，21-02 为 `yinRou`，21-03/05 为 `lingQiao`；五关均为既有单敌合同。
- 21-04 必须保留 charge、三段 phase 与 vulnerability `0.16`；21-05 必须保留首周目 `0.10`、二周目 `0.05`，且 `skill_shan_wai_wu_shan` 同时作为 `dropSkillManualId` 与 Boss `chargeSkillId`。
- 21-05 的 `surviveTicks: 10` HUD、结算文案与 widget 覆盖已在生产代码存在；typed encounter 必须以 `any(defeat_commander, survive_duration=10)` 保留“击败或守满均胜”的既有语义。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十三章剩余关卡或塔，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `21_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第二十一章 `5/5`，全主线候选 `101/105`。
3. 五关保持冻结单敌；21-01/02/03 使用 defeat-target，21-04 使用 defeat-commander，21-05 使用 any(defeat-commander, survive-duration=10)。
4. 21-04/05 保留 Boss snapshot、蓄力技、三段 phase 与 `createActor` Boss 身份；vulnerability 精确为 `0.16` 与 `0.10 / 0.05`，21-05 chargeSkill 与掉落真解均为 `skill_shan_wai_wu_shan`。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity、守满替代胜利与五关 dynamic headless victory；至少三向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：已完成实时只读审计并建立独立工作树，尚未接入 Ch21 生产目录。
- 下一步：先落 Ch21 合同测试并取得缺路由 RED，再接 assignment、encounter、runtime binding 与 manifest。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
