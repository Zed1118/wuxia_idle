# P2 M4 官军生态生产纵切计划

## 结果合同

- 单一结果：让 `stage_07_01`「北地风寒」从 legacy 扩波迁移为真实 production encounter，官军/边军的盾兵、弓手、枪骑冲阵兵、掌旗军官四职能经真实入口、typed catalog、runtime binding、同核 reducer 与生产表现路径运行。
- 选择依据：二阶段方案已确认 Ch7 北地关隘属于官军/边军生态锚点；本关矩阵模板为既有“据点”，本批不发明守阵、生存或追击新语义。
- 明确非目标：不启动 M3；不恢复三段剑链、守势或化解；不迁移 Ch7 其余四关；不实现守阵/生存/追击；不改 schema/saveVersion、`numbers.yaml`、技能、奖励、掉落、关卡基础数值或存档；不新增美术；不 merge/push main。
- 用户 2026-08-30 23:10 授权：持续推进工程到 2026-08-31 08:00，所有桌面真人试玩与视觉目检统一挂账。这是延后目检，不是 G2 PASS 或 M4 父 Gate 完成。

## 固定验收门（6 项）

1. 新增 canonical archetype `ch7_army`，精确四角色：`army_shield` / `army_archer` / `army_spear_charger` / `army_standard_officer`；显示名分别为盾兵/弓手/枪骑冲阵兵/掌旗军官。
2. 每个角色都有 attack set、attack tag、posture ref、drop ref、sfx ref 和两个现有战斗立绘变体；不新建资产，不把内部 ID 当显示名。
3. `stage_07_01` 精确路由到 `ch7_encounter_01_northern_outpost`：25 总量、10 active，角色分布 12/6/5/2，令牌预算 2/1/1/1，目标精确覆盖 25 个 entry。
4. production runtime binding 与 `StageDef.enemyTeam.single == enemy_erLiu_beidi_shuzu` 精确闭包；入口、位置、AI、技能和视觉引用 exact 覆盖，任一缺失 fail closed。
5. production host 构造 25 名敌人；任意连续 10 人 active window 位置不重复；四角色分别落实 guarded/hold-distance/charge/support 行为与 melee/ranged/charge/support token；25 个 defeat projection 完成 objective。
6. 删除 stage assignment 与破坏四角色 runtime policy 任一项均使新增生产守卫变红；targeted + adjacent + analyze + format + 持锁全量 + macOS Debug build + Gate 通过，worktree clean 并冻结可恢复候选。

## 基线与进度口径

- 基线：`430e39cfc03b29d7d17e2d43204bfb0b6eb980c8`，包含 M4-A 门派生态 clean 候选。
- 分支：`codex/p2-m4-army-ecology-stage-20260830`。
- worktree：`/Users/a10506/.codex/worktrees/p2-m4-army-ecology-stage-20260830`。
- 当前分母：M4-B `0/1`；六项全部进入受控候选后才变为 `1/1`。M4 父 Gate 仍未完成，本批只让“其余五套生态至少一场生产关”由 `1/5` 推进到 `2/5`。
- 实际可观察增量：生产生态包从山匪+门派两套提升为山匪+门派+官军三套；生产 migrated stage 从 6 关提升为 7 关。
- 成本边界：到 08:00 停止扩张并冻结 clean 恢复点；若需新 AI 原语、技能、数值或模板语义，记录阻塞而不自行扩大范围。

## 当前恢复点

- 状态：只读合同已冻结，尚未开始生产写入。
- 下一步：先添加 `ch7_army`/`stage_07_01` 生产守卫并确认 RED，再补 archetype、encounter、manifest、assignment 与 runtime binding，最后跑完整批末工程门。
- 目检挂账：角色实战辨识度、阵型可读性、远程错峰、冲阵公平性、掌旗军官视觉优先级与 1600×900/1280×720 高密度表现，均待用户阶段性集中验收。
