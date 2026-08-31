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

- 状态：生产实现、双向破坏证红与风险匹配验证均已完成，等待冻结 `[READY]` tip 并执行独立 Gate；Gate 前 M4-B 仍记 `0/1`。
- 生产闭包：`ch7_army` 四角色与 8 个现有立绘变体已进入 typed catalog；`stage_07_01` 精确路由 `ch7_encounter_01_northern_outpost`，25 总量/10 active/12-6-5-2 分布/2-1-1-1 token；production host、AI、目标投影全部闭合。
- 破坏证红：删除 `stage_07_01` assignment 后 catalog fail closed，精确 `1` 个测试单元失败；把盾兵 `guardedPosition` 退化为 `directAdvance` 后角色策略守卫精确 `1` 例失败。两处均以精确反向补丁还原，新增守卫 `3/3` 转绿。
- 已跑验证：门派+官军纵切 `6/6`；loader/validator/migration/route `83/83`；`test/data/phase2` `55/55`；`flutter analyze --no-pub lib test` 零问题；整仓 format `1650` 文件、0 changed；持锁全量 `5731/5731`，末行 `08:22 +5731: All tests passed!`；macOS Debug build 成功。
- 下一步：提交本恢复点，运行无测试删行的独立 Gate；Gate 后不得再改写候选。
- 目检挂账：角色实战辨识度、阵型可读性、远程错峰、冲阵公平性、掌旗军官视觉优先级与 1600×900/1280×720 高密度表现，均待用户阶段性集中验收。
