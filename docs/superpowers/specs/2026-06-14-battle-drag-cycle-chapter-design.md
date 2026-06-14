# 战斗交互重做 + 周目按章 设计 spec（2026-06-14）

> 来源:真玩验收 4 反馈。用户拍板:① 战斗=自动播放+随时拖招干预(废逐步单步)② 周目按章、通关整章 Boss 才解锁下一周目 ③ 群体技 targetType 我推导一版用户审。
> 上游现状:两轮 Phase 0(周目 per-stage / 半手动系统全波及面),证据见会话记录。
> 工作原则:战斗内核 tick/resolve/rng 确定性层**封冻**(balance_simulator 数千局依赖,非为重放);只改驱动方式与指令入口。

---

## A · 周目按章(per-stage → per-chapter)

- **A1 schema**:`MainlineProgress.clearedStageCycleKeys` 键 `"stageId#cycle"` → `"chapterIndex#cycle"`。迁移:旧键抽 stageId 的 chapterIndex(stages.yaml 已有 `chapterIndex`,6 章×5 关)重组;同 chapter 多关旧记录取**最大 cycle**。saveVersion 0.21.0 → **0.22.0**。
- **A2 解锁语义**:通关该章**第 5 关(章末 Boss `stage_0X_05`)**第 N 周目 → 解锁该章第 N+1 周目。`highestClearedCycle(progress, chapterIndex)` 按章查。
- **A3 难度应用**:玩家在章入口选当前挑战周目 → 该章**所有 5 关**敌人都用该周目 scale(`_enemyToBattle` cycleIndex 由章入口传入,关粒度入口逻辑不变)。
- **A4 UI**:`CycleSelectControl` 参数 `stageId` → `chapterIndex`,挂载位置从「每个 stage tile」上移到「**章标题/章入口一处**」。4 选关屏(主线/心魔/轻功/群战)改:章展开时显一处周目控件,关 tile 不再各带。心魔/轻功/群战无 chapterIndex → 视为单章(沿用其现有 cycle 字段或按副本整体一周目)。
- **A5 service**:`recordVictory(stageId, cycle)` 内部由 stageId 解析 chapterIndex 写章键;`currentChallengeCycle` 改 per-chapter。
- **A6 红线**:迁移幂等测;章 Boss 通关才升周目测;章内非 Boss 关通关不解锁下一周目测。

## B · 战斗自动流转(废半手动单步)

- **B1 废弃**(Phase 0 清单):`manualStep` 参数及全部分支 / `_NextStepButton` / `_ActorOrderBar` / `_TargetPickerDialog` / `_onNextStep` / `_pickTarget`。
- **B2 新循环**:所有战斗默认自动连续播放(Timer→`advance()`),动画流畅不停顿——这直接解决「太慢」。`stepOne`/`BattleStrategy.stepOne` 接口**保留**(拖招立即触发要用,见 C5)。
- **B3 确定性**:`_rng`/`_resolveAction`/actionPoint 制/state immutability **零改**。确定性为 balance sim + 测试服务,保留。
- **B4 录制回放废弃**(待用户拍,见开放点①):`BattleNotifier.replay()`/`_startReplayTimer`/`recordedOps`/`recordManualClearIfNeeded`/`BattleReplay*` 重放链(~800 行)。重打已通关关本就自动播放,重放冗余。`resolveAutoPlayMode` 4 态 → 简化(见 B5)。
- **B5 模式简化**:新范式下「自动 vs 手动」不再二分——战斗永远自动流转,拖招是随时可叠加的干预层。`AutoPlayMode` 简化为 `auto`(纯挂机不干预) / `interactive`(允许拖招)二元;G3 per-stage `AutoPlayToggle`/`StageAutoPlayControl` 语义改为「挂机自动 / 允许我拖招」,保留 5 屏接线。`autoPlayOverride` 字段保留(语义重定义)。

## C · 拖招交互(替点选列表)

- **C1 手势**:技能栏 item 用 `GestureDetector` onPanStart/Update/End(**不用 Draggable**——要实时画引导线,Draggable 的 feedback widget 不便画线到任意 drop 点)。长按/拖起 → 进入拖招态。
- **C2 引导线**:复用 `ProjectileTrail` 的 `CustomPaint`/`_TrailPainter`。Overlay 层从技能 item 锚点 → 当前指针位置实时绘流派色引导线。
- **C3 drop 命中**:敌人 `CharacterAvatar` 挂 `GlobalKey`,onPanEnd 用 `findRenderObject`+`localToGlobal` 做 hitTest 命中敌人头像;命中时头像高亮(借现有 `_slotFrac`/特效层)。
- **C4 单体/群体**:拖招者技能 `targetType==single` → 必须拖到某敌头像,命中=指定该 targetId;`targetType==aoe` → 技能栏**点一下直接触发**(不需拖,目标=全体/AI 选最佳),拖动可选但忽略落点。
- **C5 立即触发语义**(待用户拍,见开放点②):拖招命中 → `requestUltimate(charId, skill, targetId)`(签名不变,确定性安全)→ 立即「快进到该拖招者结算」:连续 `step()` 直到该角色出手(中间 actor 快速播放/跳过动画)。手感=拖完很快看到我的角色打出这招。**不做真插队**(破 rng 顺序/确定性,balance sim 会崩)。UI 反馈:拖招后该角色头像「蓄势」高亮直到出手。

## D · 群体技 targetType 字段

- **D1 schema**:`SkillDef` 加 `targetType: TargetType?`(enum `single`/`aoe`,null 默认 single)。skills.yaml(184)+ encounter_skills.yaml(40)= **224 招**回填。
- **D2 推导一版**(交用户审):规则草案——massBattle/群战范围技=aoe;描述含「全体/群敌/周围/横扫/席卷」=aoe;`canInterrupt`(破招)=single;其余默认 single。脚本生成 `docs/` 候选清单,用户只改判错的。
- **D3 红线**:`SkillType.ultimate`/`power` 的 targetType 非空;aoe 招在拖招 UI 走点触分支测。

## E · 实装阶段(TDD,各阶段 analyze 0 + 全量绿后进下一阶)

1. **Phase 1 — D 群体技字段**:SkillDef.targetType + yaml 回填(我推导版→用户审)+ 红线。最独立,先做。
2. **Phase 2 — A 周目按章**:schema 迁移 + service + 4 选关屏 UI + 红线。
3. **Phase 3 — B 自动流转**:废半手动单步 + 录制回放(待①)+ 模式简化 + saveVersion。
4. **Phase 4 — C 拖招交互**:手势 + 引导线 + drop 命中 + 立即触发(②)。依赖 D(targetType)与 B(自动流转)。
5. **收尾**:Codex 视觉验收(拖招引导线/章周目控件/无下一步按钮)+ 真玩复验 + closeout。

## F · 开放点(2026-06-14 已拍板)

- **① 录制回放 → 完全废弃**。删 ~800 行重放链 + 简化 schema/决策树。重打走自动播放+随时拖招。
- **② 拖招立即触发 → 快进到拖招者结算**(确定性安全,体感「很快」非「瞬时」)。不做真插队。
- **③ 群战拖招 → 先纯自动,拖招挂 backlog**。massBattle 维持 runToEnd 纯自动;拖招仅主线/塔/心魔/轻功。群战 per-actor 拆分挂二期。
