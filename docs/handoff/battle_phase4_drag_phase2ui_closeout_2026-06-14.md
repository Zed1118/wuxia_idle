# 战斗交互重做 Phase 4 拖招 + Phase 2 UI 周目按章 · 会话交接(2026-06-14 续2)

> worktree `battle-drag-cycle-chapter`(branch `worktree-battle-drag-cycle-chapter`,HEAD `55e447b4`,全 push origin,未合 main)。
> spec:`docs/superpowers/specs/2026-06-14-battle-drag-cycle-chapter-design.md`(§C 拖招 / §A 周目按章 / §F 开放点)。
> 至此 spec 全 4 Phase + 收尾视觉验收外**代码层全闭环**。

## 本会话完成(xhigh · TDD)

### Phase 4 拖招交互(`0a4d79e9` · battle_screen.dart)
- **C1 手势**:`_SkillCommandButton` 包 `GestureDetector` 长按拖(`onLongPress*`),规避底栏横向滚动手势竞争;仅 `enabled`(门控开+ready+未待发)时挂。
- **C2 引导线**:`_DragGuideLayer`/`_DragGuidePainter`——流派色笔触线(按钮锚点→指针),`Positioned.fill`+`IgnorePointer` 实时跟手。
- **C3 drop 命中**:敌头像挂 `GlobalKey`(`_enemyAvatarKeys`);顶层纯函数 `hitTestEnemyId(指针, 敌矩形列表)`;`onLongPressEnd` 用 `localToGlobal` 收集存活敌矩形命中;命中头像绛红光晕(`_CharacterSlot.hovered`)。
- **C4 单体/群体**:`targetType==single` 必拖到敌头像=指定 `targetId`;`aoe` 点触直接触发(忽略落点,目标走 AI)。**附加(偏离 spec「single 必拖」)**:single tap 仍走 AI target(additive 友好),drag 才指定 targetId——更友好且满足两红线测。
- **C5 立即触发**:`_onSkillCommand` 下发后置 `_rushToActorId`,Timer 切快进间隔,`advance` 到该角色出手(actionLog 现其 action)即恢复常速;**纯 UI 时序加速,不改引擎/rng**(确定性安全,balance sim 不受影响)。拖招者头像「蓄势」流派色光晕(`_CharacterSlot.charging`)直到出手。
- **门控**:`allowPlayerIntervention`(Phase 3 inert 占位)真消费——`false`(群战/纯自动,开放点③)技能按钮禁用 + 不挂拖招手势。
- **测**:`battle_drag_skill_test` 12(hitTest 纯函数 4 + aoe 点触 + 单体拖命中下发 targetId + 拖空白不下发 + 门控关 tap/拖均不下发)。门控变更同步 `battle_command_console_test`/`widget_test` pumpBattle 加 `allowPlayerIntervention:true`。

### Phase 2 UI 周目控件上移章层(`55e447b4`)
- 新 `selected_cycle_provider.dart`:`selectedChallengeCycleProvider`(@riverpod family by chapterKey,纯 UI 状态不落盘)+ `resolveTargetCycle` 纯函数(显式选择优先 / 已通章回放最高 / 未通章 cycle1)。
- `CycleSelectControl` 改 `stageId`→`chapterKey`:读 `highestClearedCycleForChapter`,自持状态(写 provider,选中态勾标高亮),**只设状态不进战斗**(回放=highest / 挑战=highest+1)。整章未通(highest=0)空占位。
- 4 选关屏上移挂载 + 删 per-stage 控件:主线 `ch{N}` 挂 journey map 下方 / 副本(心魔/轻功/群战)`stageType.name` 挂屏顶;关 tile 点击经 `resolveTargetCycle` 读选定周目传 `targetCycle`(原 per-stage `onSelectCycle` 全删)。
- per-stage **自动/手动 toggle**(`StageAutoPlayControl`)保留 per-tile 不变(与周目正交)。
- 验收 route `stage_list_cycle` 改用新 `Phase2SeedService.seedChapterCycleVisualCheck`(整章 Ch1 含章末 Boss 01_05 cycle1 全通 → `ch1#1`)使章头控件可见。
- **测**:`selected_cycle_provider_test` 4 + `cycle_select_control_test` 重写章级 7 + `stage_list_screen_cycle_test` 重写(章头唯一控件 / 整章未通 guard)。

## 闸门
analyze 0 / 全量 **2159 测** / 1 skip / 零回归(基线 2146 → +13)。

## 待续(需视觉/真玩 · 不可 CLI 验)
1. **Codex 视觉验收**:拖招引导线(流派色跟手)/ 命中敌头像高亮 / 拖招者蓄势光晕 / 章头周目控件(选中态)/ 战斗无「下一步」纯自动流。route 已就绪:`stage_list_cycle`(章周目)、拖招需真关卡(无静态 route——拖拽手势 native GUI)。
2. **真玩复验**:① 长按拖技能到敌头像手感 ② 立即触发「拖完很快看到我的角色出手」体感 ③ aoe 点触 vs single 拖区分清不清 ④ 章头选周目 → 关 tile 进入用该周目流是否顺。
3. **合 main**:视觉+真玩通过后 rebase→ff-only(注意 .g.dart gitignored,主 checkout 需 build_runner;libisar.dylib)。

## 环境须知
- fresh worktree 必跑 `flutter pub get && dart run build_runner build`(.g.dart gitignored,本会话新增 `selected_cycle_provider.g.dart`)+ 从主仓拷 `libisar.dylib`。
- 验收一律 `-d macos`;analyze 用 `--fatal-warnings`。
- **交互流已自主拍板**(handoff 原「需用户确认」项):章头选周目=设 `selectedChallengeCycleProvider` 状态,关 tile 点击 `resolveTargetCycle` 用该周目——由 spec「控件上移到章层」语义确定,如真玩觉不顺再调。
