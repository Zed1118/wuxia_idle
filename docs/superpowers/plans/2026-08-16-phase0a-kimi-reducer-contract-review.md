# Phase 0A reducer / 输入 / 事件闭环交叉复核计划（Kimi）

> 派单:`docs/dispatch/packages/2026-08-16_phase0a_kimi_reducer_contract_review.md`
> 复核对象:Qoder `feat/phase0a-qoder-reducer-input-event-loop`,tip `73f562c1` 前缀 `[READY]`,本 worktree 同 tip 树干净(freeze 满足 §8.3)。
> 本分支:`audit/phase0a-kimi-reducer-contract-review`(复核证据与最小修复落此,不动 Qoder 分支)。

## 目标

验证统一 reducer、玩家/AI 适配器、已结算事件兑现反馈契约与生产边界;证伪两项派单方加验项;确定缺陷最小修复。禁扩 UI/YAML/数值/旧 3v3。

## 复核证据(只读阶段已完成)

**契约逐事件核对**(`docs/spec/2026-08-16-phase0a-production-feedback-contract.md`):
- `hit_landed` 带 `resolvedDamage`/`remainingHealth`,仅 `resolved.isHit` 才发,无假 hit(reducer:156)。
- Q/R applied outcomes 按 id 升序稳定(`_opposingTargets` reducer:444),effectRadius 闭区间过滤(:222/:308)。
- `skill_availability_changed`:cooldown 态带 `cooldownRemaining`、ready/qi 带 `qiCurrent`/`qiRequired`;同拍全槽重算只发真实迁移(:518 `_emitCastAvailability`)。
- 死亡仅一次(移除出 `enemiesById`),死单位不再作 actor/target(:116)。
- 事件全 operator==,seq 单调,可确定性回放(既有 reducer 测 27 项覆盖)。
- 输入唯一入口:`Phase0aCombatSession.advance`(session:31)合并双适配器 intent → 同一 `reducePhase0aTick`;适配器层无复制命中/扣血/CD/真气规则。

**确定缺陷 A(证伪项 1 · 敌方技能静默污染玩家全局态)**:
`_tryCastSkill`(reducer:471)对任意 actor 生效且操作全局 `slots`(= 玩家 skillSlots)。敌方注入 gather/clear(slot id 撞玩家槽)时:① 玩家槽被置 CD、qiCost 被覆写(:483-487);② `_emitCastAvailability` 按敌方余气发 `Phase0aSkillAvailabilityChanged` → 污染玩家 HUD;③ 敌方 gather 会以敌为中心位移玩家(:267)。当前 enemy AI adapter 只发 move/attack,生产路径暂未触发,但 reducer 契约层未拒绝 = 静默污染面。

**确定缺陷 B(证伪项 2 · 负值/非有限值静默合法化)**:
- `deltaSeconds<0`:`_cooldownAfter`(:393)冷却反增、位移反向。
- `range<0`(rules:32)、`effectRadius<0`(reducer:559)、`ringRadius<0`(rules:50):平方后变正,等价取绝对值。
- `cooldownSeconds<0`:普攻 :194/技能 :484 赋负冷却 → 下拍立即 ready。
- `qiCost<0`:`qiCurrent<qiCost` 恒过,`qiCurrent-qiCost` 施放反回气(:490)。
- `resolved.damage<0`:`math.max(0,hp-(-x))` → 目标回血可超 maxHealth(:157/:245/:325),hit_landed 带负伤害。
- NaN/Infinity:比较恒 false,绕过一切 `< 0` 检查(如 `effectRadius=NaN` 时 `lengthSquared <= NaN` 恒 false 静默无目标;`deltaSeconds=NaN` 冷却直接 NaN 化)。

## 修复方案(最小边界 · 派单方已拍板口径)

仅改 `phase0a_combat_reducer.dart` + intent 文档注释:
1. `deltaSeconds` 非 finite 或 <0 → `ArgumentError`(入口显式拒绝)。
2. gather/clear 增加 `actor.side != player → continue`(player-only 契约,intent doc 注明;per-actor 语义留后续片)。
3. intent 全部外部 double(range/halfArcRadians/cooldownSeconds/effectRadius/ringRadius)非 finite 或 <0、qiCost<0 → 拒绝该 intent(continue,沿用既有 `ringRadius>effectRadius` 风格)。
4. `resolved.damage<0` → `StateError` fail-fast(不 clamp——不掩盖 resolver/公式错误);throw 发生在不可变状态装配前,目标/事件/状态天然零污染。

## 任务切片

1. 本计划档落盘。
2. 红测:`test/features/battle/domain/phase0a/phase0a_reducer_guard_test.dart`(敌方技能注入/负 deltaSeconds/负与 NaN intent 参数/负 resolved.damage)→ 确认红 → commit。
3. 最小修复 → 转绿 → 单独 commit。
4. 精确验证:targeted(原 64+新增)、首片 24、probe 对照 8 项、根 `flutter analyze --no-pub`、`dart format`、`git diff --check`;修复后破坏一行证红再复原。

## 当前恢复点

- 状态:复核完成,两处缺陷确认,红测待写。
- 最后完成:只读复核 + 缺陷定位(见上)。
- 下一步:写守卫红测。
- 已跑验证:无(仅静态阅读)。
- 阻塞项:无。

## 禁区

UI / YAML / GDD / PROGRESS / pubspec / probe / 旧 3v3 / schema / saveVersion / push / merge / rebase / revert / 碰 main。
