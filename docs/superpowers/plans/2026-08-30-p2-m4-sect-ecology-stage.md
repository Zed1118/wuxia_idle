# P2 M4 门派生态生产纵切计划

## 结果合同

- 单一结果：将 `stage_02_02` 从 legacy 扩波迁移为真实生产 encounter，让门派生态的外门弟子、暗器弟子、轻功弟子和教习四职能经真实入口、typed catalog、runtime binding、同核 reducer 与真实表现路径运行。
- 明确非目标：不恢复三段剑链、守势或化解；不开 M3 五武器调优；不改存档 schema/saveVersion、`numbers.yaml`、奖励、掉落、关卡基础数值或现有技能数值；不迁移 Ch2 其余四关；不新增美术。
- 用户 2026-08-30 明确授权：M2 屏外提示、聚合伤害、五关与机缘真人目检统一挂到阶段末，不再阻塞下一批工程。这是延后目检，不是把历史 `UNVERIFIABLE` 改写为 `PASS`。

## 固定验收门（6 项）

1. `CombatArchetypeVariant` 的显示名由 YAML 显式声明并严格校验，生产 snapshot/敌人 HUD 消费该名称，不回退内部 ID 或同一 base enemy 名。
2. 门派生态精确四个 canonical role：`sect_outer` / `sect_hidden_weapon` / `sect_lightfoot` / `sect_instructor`；每个 role 有 attack set、tag、posture ref、drop ref、sfx ref 和两个现有美术变体。
3. `stage_02_02` 精确路由到 migrated encounter，25 总量、10 active，分布为 14/6/4/1，四种令牌预算不超过现有 2/1/1/1 上限。
4. 生产 runtime binding 与真实 `StageDef.enemyTeam.single` 闭包；入口、位置、AI、技能和视觉引用 exact 覆盖，任一缺失 fail closed。
5. 真实 production host 可构造 25 名敌人，每个 active window 无重复位置，四职能 AI 与 token policy 可辨；击败 25 个目标后 objective 完成且不依赖 legacy fallback。
6. 实现去掉任一条生产接线后相应守卫必须变红；targeted + adjacent + analyze + format + 持锁全量 + macOS Debug build 全绿，worktree clean 并留一个可恢复候选。

## 基线与进度口径

- 基线：`ab09f692137a737db90abb044d7fceec45f23afb`，已包含用户刚确认正常的暗黑式鼠标战斗和定点聚怪。
- 分支：`codex/p2-m4-sect-ecology-stage-20260830`。
- worktree：`/Users/a10506/.codex/worktrees/p2-m4-sect-ecology-stage-20260830`。
- 当前分母：M4-A 工程实现与本地验证已完成，独立 Gate 通过并冻结 clean 候选后由 `0/1` 变为 `1/1`。M4 父 Gate 仍为 `0/1`，不用一个生态纵切冒充六生态完成。
- 预期增量：第二套生态包从 0 个生产关提升到 1 个生产关；本批不更改顶层 M0–M9 `1/10` 口径。
- 成本边界：无可靠 token/用量读数，以墙钟观察；若约 90 分钟仍未形成真实 production host 闭包，停止扩展数据面并重评。
- 集成证据：生产入口消费、破坏证红、风险匹配回归、意图 diff、clean status、候选 commit。本批不自行 merge/push main。

## 当前恢复点

- 状态：工程实现与风险匹配验证已完成，等待在本 commit 冻结 `[READY]` 候选并执行独立 Gate；Gate 前 M4-A 仍记 `0/1`。
- 最后完成：`stage_02_02` 已接入 25 人/10 active 的四角色门派生态；typed catalog、stage-local verified refs、runtime bundle、production host、角色显示名与 25 目标完成链均已转绿。首次全量发现一条 Ch1 旧契约仍硬编码基础模板名，已升级为“普通职能使用 archetype display name、真实头目保留 stage base identity”，并登记测试契约迁移。
- 破坏证红：把 adapter 的职能显示名恢复为 base enemy 名，生产测试精确 `1` 例失败；删除 `stage_02_02` assignment，真实路由测试精确 `1` 例失败。两处均已精确反向还原，Ch2 定向 `3/3` 转绿。
- 已跑验证：display-name schema `100/100`；Ch1 相邻生产链 + Ch2 `19/19`；`test/data/phase2` `52/52`；catalog loader/validator `66/66`；第二次持锁全量 `5728/5728`；`flutter analyze --no-pub lib test` 零问题；整仓 format `1649` 文件且最终无未格式化文件；macOS Debug build 成功。fresh worktree 已完成 `pub get --offline` 与 build_runner 128 outputs。
- 下一步：提交测试契约修正与迁移登记，生成绑定最终 SHA 的外置 receipt，运行测试契约迁移 Gate 与独立 Gate；不得在 Gate 后改写候选。
- 阻塞项：无新产品决策阻塞；真人目检按用户授权统一延后，且不因工程 Gate 通过自动改写为 G2 PASS。
