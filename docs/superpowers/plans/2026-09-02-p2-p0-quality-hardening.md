# P2 昨夜交付 P0 质量收口计划

## 结果合同

- 单一结果：在不扩大 M7 内容范围的前提下，关闭昨夜 M3 与第二章 M7 交付的三个 P0 质量缺口，使权威台账、自动矩阵的证据强度和第二章有效战斗参数事实保持一致。
- 实时基线：`main == origin/main == 1c0eaa3ae8c2b77730cd4ab0844e54fd15939991`，主 checkout clean；M3 集成提交 `f3076cef045145cc17cc2d4098f5fba0161998e1`，M7 第二章集成提交 `1c0eaa3ae8c2b77730cd4ab0844e54fd15939991`。
- 固定分母：P0 子门 `3/3`——权威台账刷新、M3 真实战斗矩阵加固、第二章 5 关有效参数与动态战斗审计。
- 当前关键阻塞：M3 的 45 格测试只证明合约接线，不覆盖敌方 AI、玩家受击/生存和时间边界；第二章测试不检查生态倍率后的有效角色参数与真实终局。
- 预期变化：不改变正式 M0–M9 的 `1/10`；只把昨夜交付从“集成但有证据缺口”推进为 `3/3` P0 质量门候选。
- 成本边界：约 90 分钟无任一 P0 子门变化时停止扩面并重评；不以测试数量、代码量或文档量冒充正式里程碑进度。

## 授权与非目标

- 已授权：更新 `PROGRESS.md`、Phase 2 task registry、相关计划/审计；补强 M3 与第二章生产路径测试；为确定性审计增加只读测试辅助结构。
- 不改：`numbers.yaml`、`stages.yaml`、玩家/敌人/技能/奖励/经济/解锁数值与规则、Isar、`schemaVersion`、`saveVersion`、checkpoint、结算 owner。
- 不推进：第三章、塔、M8、M9。
- 真人桌面手感、视觉、音频和 Windows 验收继续挂账；自动测试不得代签。

## §8.2 验收清单

1. **生产接线证据**：M3 矩阵从真实 repository、stage/encounter runtime、AI、director、objective 与 reducer 消费生产数据；第二章审计从真实 factory/runtime binding 读取有效 combatant。
2. **targeted tests**：三项 P0 的直接测试与相邻回归全部通过，并记录命令和通过数。
3. **红线影响**：不改生产数值与规则；对关键守卫执行破坏证红并精确还原。
4. **残留风险**：真人视觉/手感、Windows、非确定性长时性能仍独立挂账。
5. **集成纪律**：`flutter analyze`、整仓 `dart format .`、持锁全量、Gate、最终 diff 与 clean 状态完成后才冻结 `[READY]`；未经用户另行授权不合并、不 push。

## 实施顺序

1. 刷新 `PROGRESS.md` 与 task registry 的 M3/M7 集成事实、CI、Gate、正式挂账和当前内容分母。
2. 将 M3 45 格矩阵升级为真实关卡/encounter 敌人、AI、攻击、玩家生存、时间和终局约束；保留五武器 × 三流派 × 普通/精英/Boss 固定分母。
3. 为第二章 5 关建立有效角色参数快照和确定性动态战斗审计，重点暴露 `stage_02_05` Boss 基敌经生态倍率复用后的随从/掌门事实。
4. 执行破坏证红、targeted、相邻回归、analyze、format、持锁全量和 Gate，更新恢复点并提交 `[READY]`。

## 当前恢复点

- 分支：`codex/p2-p0-quality-hardening-20260902`
- worktree：`/Users/a10506/.codex/worktrees/p2-p0-quality-hardening-20260902`
- 状态：`3/3` P0 质量子门候选已收口，等待独立评审；正式 Phase 2 仍为 `1/10`，本分支未合并、未 push。
- 下一步：冻结 `[READY]` tip，由独立评审决定是否合入 main；通过后才继续 M7，M8/M9 不提前启动。
- 已跑验证：直接定向 `8/8`、相邻回归 `88/88`、三向 mutation 各精确 `1` 条失败并精确还原、analyze 0 issue、整仓 format 1716 files/0 changed、持锁全量 `5881/5881`、`[E]` 块 0、标准 Gate PASS。
- 阻塞项：自动化不能批准普通存档平衡、真人武器手感、二章实际节奏、视觉/音频或 Windows；`stage_02_05` 随从继承章末高基敌参数的产品合理性仍待后续决定，本批只披露不改值。
