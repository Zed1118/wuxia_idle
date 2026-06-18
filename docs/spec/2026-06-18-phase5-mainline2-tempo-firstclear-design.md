# 第五阶段 · 主线二 · 即放时序(2.3)+ 首通门控(2.5) 设计

> 2026-06-18 · brainstorm 拍板 · opus xhigh
> 源:`docs/spec/phase5_battle_experience_loot_spec_2026-06-17.md` §3 主线二。
> 本设计**修正源 spec 两处 stale 前提**(见 §0),据实测重定方向。
> 范围:批次 **2.3 即放时序** + **2.5 首通门控** 一并做。2.2(普攻不动)无改动;2.4(打击感表现层)留后续批。

## 0. 修正源 spec 的两处 stale 前提(Phase 0 实测)

1. **2.3 前置「读 BattleReplayRecord(saveVer0.19)保 seed 重放」已不成立**:`BattleReplayRecord` collection 在「战斗交互重做 Phase 3 / saveVer0.23」随录制回放链整体删除,不在 `_allSchemas`(`lib/data/isar_setup.dart:69-85`,删除注释 `:114`)。当前确定性**只靠**单一 `_rng` 实例 + advance 严格递进(`lib/core/application/battle_providers.dart:81`)。**不复活任何 replay 落盘。**
2. **2.5「自动推进只到已首通的最远关」是 loose wording**:实测无跨关自动链。选关始终手动(`stage_list_screen.dart:26` locked 关靠"通关前一关解锁");"挂机"= 离线收益 + 战斗内自动连播。`AutoPlayMode.auto`=自动连播无拖招层 / `interactive`=自动连播挂拖招层(`auto_play_mode.dart:8`)。故 2.5 落地为「首通强制 interactive 模式」(§3)。

## 1. 现状锚点(file:line)

- 战斗 time-based 行动制:每 tick 全员 `actionPoint += speed`,AP≥1000 出手并归零(`lib/features/battle/domain/strategy/default_ground_strategy.dart:19-33`)。节拍间隔 `numbers.yaml animation.action_interval_ms: 800`。
- 当前拖招:松手 → `requestUltimate()` 写 `BattleState.pendingUltimates[charId]` → 该角色**下一自然轮**才消费,不插队(`default_ground_strategy.dart:148-181`)。Phase 4 C5 用 `_rushToActorId` 快进模拟即时感。
- 拖招 UI 入口:`lib/features/battle/presentation/battle_screen.dart:660` `_onSkillDragEnd` → `requestUltimate`。
- 干预门控:`allowPlayerIntervention`(`battle_screen.dart:482`);只 interactive 非群战启用(`stage_entry_flow.dart:456`)。
- auto/interactive 决策:`resolveAutoPlayMode(override, globalDefault)`(`auto_play_mode.dart:21`),在 `_StageBattleHostState.initState`(`stage_entry_flow.dart:404-412`)算。
- isFirstClear 判定:已存在(`stage_entry_flow.dart:734`,读 `clearedStageIds`);周目 key `clearedStageCycleKeys`(`mainline_progress.dart:37`)。
- 确定性红线测:`test/features/battle/battle_seed_determinism_test.dart`(auto 无干预路径,同 seed 两跑全等)。

## 2. 批次 2.3 · 即放时序(引擎级真插队 · 预支语义)

### 2.1 机制核心
玩家在 interactive 战斗中拖技能方块到目标松手:
- 该角色**立即插入当前 tick `actorQueue` 队首**,在当前原子结算完成后**下一个**结算,不等 AP 自然满。
- 出手用拖的招、对拖中的目标。
- 出手后该角色 **AP 归零**(与正常出手同语义)→ 预支这一拍,随后等满一周期才再动。**净出手频率近不变**——非数值杠杆,守 §5.4 / 爽感走表现层不走数值膨胀。
- 本 tick 其它该动角色,在被拖角色出手后照常继续(被拖角色只是"插队首 + 预支")。
- 替换现状 pending+C5 路径:玩家拖招从"标记下次"变"现在就打"。C5 `_rushToActorId` 此路径不再触发(留 auto 观战提速,不动)。

### 2.2 边界与门控
- **CD/内力不足**:拖起(pickup)阶段即拦,复用主线一 1.2「内力不足」禁用态 + CD 灰显,不进插队路径。不会出现"插队却放不出"。
- **作用域**:仅 `allowPlayerIntervention==true`(interactive,非群战)生效。auto/挂机无玩家输入 → 插队永不触发 → **auto 确定性测天然不受影响**。
- **连续插队**:可连拖 A→B→C 各自插队(各自 AP 归零);同角色 AP 归零后短期不能再拖(无刷招)。**无额外次数拦截**(用户拍板)。

### 2.3 确定性与测试
- 不恢复 replay 落盘。确定性只守 auto 路径红线测——本改动不碰它(无输入路径行为不变)。
- 新增**插队确定性测**:同 seed + 同串拖招输入(固定 tick 时点+目标)两跑 → actionLog+胜负全等。
- 扩 `test/features/battle/presentation/battle_drag_skill_test.dart`:验立即出手 + AP 归零 + CD/内力 pickup 拦截 + 连续插队。

### 2.4 改动面(plan 阶段精确)
- `default_ground_strategy.dart`:新立即插队入口(如 `interveneNow(state, charId, skill, targetIds)`):actorQueue 插队首 + 被拖角色 AP 归零 + 走既有 `_resolveOneTarget` 结算(逐目标独立,沿 aoe 体例)。
- `battle_providers.dart` `BattleNotifier`:暴露立即插队方法,内部调 strategy + 复用同 `_rng`。
- `battle_screen.dart:660` `_onSkillDragEnd`:改调立即插队,退掉 pending 写入 + C5 rush(玩家路径)。
- 保留 `requestUltimate`/pending 结构供非玩家路径或回退(plan 阶段确认是否全删)。

## 3. 批次 2.5 · 首通门控(首通强制 interactive)

### 3.1 机制
某关(某周目)**首通前 → 强制 `AutoPlayMode.interactive`**(挂拖招层),无视全局/per-stage 的 auto 设置;**首通后 → 恢复 `resolveAutoPlayMode` 按设置**(可纯 auto 复刷)。
- 效果:每个新关首通时拖招层一定在场(技能展示/参与空间);已通关卡纯 auto 复刷不拖慢。
- 战斗仍自动连播,门控只决定"拖招层在不在",**非速度 buff**,守 §5.5 在线=离线。
- 范围:**仅主线**(`clearedStageCycleKeys` 数据源)。爬塔首通门控不在本批(用户拍板,避免跨两 flow 体量膨胀)。

### 3.2 门控点
`_StageBattleHostState.initState`(`stage_entry_flow.dart:404-412`):算出 `_mode` 前,先判本场 `(stageId, targetCycle)` 是否首通(读 `MainlineProgress` 的 `clearedStageCycleKeys`,cycleKey=`'$stageId#$cycle'`,复用 `MainlineProgressService.highestClearedCycle` 或等价判定)。首通 → `_mode = interactive`,跳过 `resolveAutoPlayMode`;否则走原决策。
- 纯函数化首通判定便于单测(如 `isFirstClearForMode(progress, stageId, cycle)`)。
- 群战例外延续:massBattle 即便 interactive 也不挂拖招(`_allowIntervention` 已排 massBattle),首通门控对群战= interactive 但无拖招,无害。

### 3.3 测试
- 纯函数首通判定单测(首通 true / 已通 false / 多周目各自独立)。
- widget/逻辑测:首通关 `_mode` 强制 interactive(即便 global auto=true);已通关按 override/global。

## 4. 验收(对齐源 spec §3 验收)
- 普攻非主要击杀来源(2.1 已证伪过强,本批不动数值)。
- 首通有技能展示空间(2.5 强制 interactive)。
- 复刷不显著拖慢(首通后恢复 auto)。
- 全红线守(2.3 AP 归零非频率杠杆 / 2.5 模式解锁非速度 buff)。
- 重放/插队确定性测绿 + auto 路径确定性测不破。

## 5. 风险与档位
- 档位 **xhigh**(动引擎 actorQueue + 战斗推进时序)。
- 主风险:插队改变 actor 结算顺序 → 须确保 auto 无干预路径 rng 消费序列不变(测兜底);插队路径自身确定(新测兜底)。
- 2.5 低风险(纯模式决策分支),可与 2.3 并做。
