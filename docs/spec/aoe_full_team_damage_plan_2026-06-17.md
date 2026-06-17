# aoe 群体技全体伤害 实装计划

> **For agentic workers:** 用 superpowers:subagent-driven-development 逐 task 实装。steps 用 `- [ ]`。

**Goal:** 让 aoe 群体技结算时对全体存活敌人各造成完整伤害(各目标=单体值,无衰减),消除「拖下发 aoe 只打单体」缺陷。

**Architecture:** `BattleAI.decide()` 返回 `(SkillDef, List<int> targetIds)`(single=[单一]、aoe=全体 slotIndex 升序);`_resolveAction()` 抽 per-target helper 后 loop targetIds,攻方扣费一次、逐目标独立结算、胜负 loop 后判。single 走同一 loop 行为等价(回归保障)。

**Tech Stack:** Dart / Flutter · 战斗结算 `lib/features/battle/domain/`。

---

## 边界决策(实装必守,plan 内已定不再请示)

1. **攻方扣内力/CD/AP 一次**:技能放一次,不论命中几个目标(loop 外)。
2. **aoe 一次性命中当前全体存活敌人**:同 tick 同时命中,中途打死不影响其余目标(全算完再判胜负,无中途中断)。
3. **fanzhen 反伤覆盖语义**:loop 中最后命中的带 `cycle_fanzhen` 敌人写攻方内伤(与现单体覆盖语义一致,不叠层)。
4. **每个 target 一条 BattleAction**:保持 `BattleAction.targetId` 单一字段;aoe → 多条 action。
5. **rng 消费顺序锚 slotIndex 升序**:targetIds 排序固定,保 seed 复现确定。
6. **破招/内伤/stagger 逐目标独立**:canInterrupt 的 aoe 可同时打断多个蓄力敌。
7. **single 走同一 loop**(targetIds 单元素),行为与现状逐字节等价。

---

## Task 1: decide 返回 List<int> targetIds

**Files:** Modify `lib/features/battle/domain/battle_ai.dart:23-57`;Modify `lib/features/battle/domain/strategy/default_ground_strategy.dart:352,354,380`(三处 `.$2`)

- [ ] **Step 1: 改测先行** —— 在 `test/features/battle/domain/battle_ai_test.dart` 加测:single 技 decide 返回 `[单一 targetId]`(长度 1);aoe 技 decide 返回全体存活敌人 charId 按 slotIndex 升序(造 3 活敌场景,断言 list == 升序全体)。
- [ ] **Step 2: 跑测验证 FAIL**(decide 仍返回 int)。Run: `flutter test test/features/battle/domain/battle_ai_test.dart`
- [ ] **Step 3: 改 decide 签名** —— 返回类型 `(SkillDef skill, List<int> targetIds)`。single 路径(pending 指定 / 破招锁定 / `_pickTargetId`)各包成单元素 list;新增 aoe 分支:`if (skill.targetType == TargetType.aoe)` → `enemyTeam.where(isAlive).sortedBy(slotIndex).map(characterId).toList()`。`_pickTargetId` 保持返回 int 不动。
- [ ] **Step 4: 适配 caller** —— `default_ground_strategy.dart` 三处 `BattleAI.decide(...).$2`:forcedSkill 路径(352)取 `.$2`(现 int)改为新返回的 targetIds;decided 路径(354/380)同。本 task 先让 single 取 `targetIds`(后续 task 真 loop),此处可临时 `final targetIds = decided.$2;` 并在下方暂仍 `targetIds.first` 保持单体行为(Task 3 改真 loop)。
- [ ] **Step 5: 全量回归** —— Run: `flutter test`。Expected: 既有全绿(single 行为不变)+ 新 battle_ai 测过。
- [ ] **Step 6: Commit** —— `git commit -m "重构 BattleAI.decide 返回 targetIds 列表(single 单元素·aoe 全体)"`

## Task 2: 抽 per-target helper(重构·行为不变)

**Files:** Modify `default_ground_strategy.dart:382-503`(_resolveAction 单 target 段)

- [ ] **Step 1:** 把单 target 处理(`_findById` 后伤害/内伤/破招/stagger → targetAfter + 本目标的 fanzhen 贡献 + BattleAction)抽成 helper:`({BattleCharacter targetAfter, InternalInjurySlot? actorFanzhenInjury, BattleAction action}) _resolveOneTarget(BattleState preState, BattleCharacter preActor, BattleCharacter target, SkillDef skill, NumbersConfig n, Random rng)`。把现有 393-503 逻辑搬入,**不改任何计算**,只是参数化 target。
- [ ] **Step 2:** `_resolveAction` 改为:取 `targetIds.first` 的 target → 调 `_resolveOneTarget` → 用返回的 targetAfter/fanzhen/action 走原写回+消费+胜负。**行为与重构前逐字节等价**。
- [ ] **Step 3: 全量回归** —— Run: `flutter test`。Expected: 全绿(纯重构,零行为变化)。
- [ ] **Step 4: Commit** —— `git commit -m "抽 _resolveOneTarget helper(重构·行为不变)"`

## Task 3: aoe loop 实装(行为变·aoe 打全体)

**Files:** Modify `default_ground_strategy.dart` _resolveAction;Test `test/features/battle/domain/aoe_full_team_test.dart`(新建)

- [ ] **Step 1: 行为测先行** —— 新建测:造主控 aoe 大招 + 3 活敌(slotIndex 0/1/2 各异 hp),advance 到主控行动,断言 3 敌**全部扣血**(各 currentHp < maxHp),且每个扣血量 = 同条件单体伤害(与 single 同技对单一敌的伤害相等,验"无衰减")。
- [ ] **Step 2: 跑测验证 FAIL**(当前只打 first)。Run: `flutter test test/features/battle/domain/aoe_full_team_test.dart`
- [ ] **Step 3: 实装 loop** —— _resolveAction 在拿到 targetIds 后:`final targets = targetIds.map((id)=>_findById(preState,id,oppSide)).whereType<BattleCharacter>().toList();` loop 逐个调 `_resolveOneTarget`,累积 `List<BattleCharacter> targetAfters` + `List<BattleAction> actions` + 末个非空 `actorFanzhenInjury`(覆盖)。攻方 actorAfter(扣内力/CD/AP/fanzhen)在 loop **外**算一次。写回:actorAfter + 逐个 targetAfters(`_replaceById`)。actionLog 追加 `actions` 全部。胜负 loop 后判一次。(边界决策 1-7)
- [ ] **Step 4: 跑测验证 PASS** + 全量回归 `flutter test`(single 仍全绿)。
- [ ] **Step 5: Commit** —— `git commit -m "实装 aoe 群体技全体伤害结算(各目标完整伤害·无衰减)"`

## Task 4: 确定性测 + 红线测补

**Files:** Test `test/features/battle/domain/aoe_full_team_test.dart`;`test/balance/full_build_damage_redline_test.dart`

- [ ] **Step 1:** 确定性测:同 seed(固定 Random(seed))跑两遍含 aoe 的完整战斗,断言每 tick state(扣血/log)逐一相等。
- [ ] **Step 2:** 红线补:在 full_build_damage_redline 加断言「满 build aoe 大招对单一目标伤害 == 同条件 single 同倍率伤害」(证 A 方案单次不抬高),并验全体场景峰值仍 < 1,000,000。
- [ ] **Step 3: 跑测 PASS** + 全量回归。
- [ ] **Step 4: Commit** —— `git commit -m "补 aoe 确定性测 + 红线断言(单次伤害不抬高)"`

## Task 5: F debuff 验收路由场景修(顺带)

**Files:** Modify `lib/features/debug/presentation/battle_test_menu.dart` scenarioDragLive

- [ ] **Step 1:** 内伤触发需「阴柔(攻)→灵巧(守)」。当前我方全 gangMeng、敌 yinRou 打我方 gangMeng 不触发。改:把一名我方角色流派设为 `lingQiao`(让敌方 yinRou 攻击触发内伤贴我方灵巧头像供 hover 复验),或加一阴柔我方 + 一灵巧敌人。保持敌高血久撑不变。
- [ ] **Step 2: 全量回归**(改 debug 场景不应破生产测)。
- [ ] **Step 3: Commit** —— `git commit -m "修 battle_drag_live 验收场景流派搭配(让内伤 debuff 可复验)"`

## Task 6: GDD 更新 + 终验

**Files:** Modify `GDD.md` §八#4;`PROGRESS.md`

- [ ] **Step 1:** GDD §八#4「群体技自动」从「前瞻」改「已实装」,补全体伤害规则一节(各目标完整伤害·无衰减·全体存活敌人·slotIndex 升序结算)。
- [ ] **Step 2: 终验** —— `flutter analyze`(0)+ `flutter test`(全量,记 baseline→after delta 零回归)。贴原始输出。
- [ ] **Step 3:** 更新 PROGRESS 续22 + commit + push。

---

## Self-Review 覆盖核对

design §2 伤害规则→Task3;§3.1 目标解析→Task1;§3.2 结算 loop→Task2+3;§3.3 AI 对称→Task1(decide 不分敌我,任一方 aoe 都展开对面);§4 测试→Task4;§4 F debuff→Task5;§5 GDD→Task6。无遗漏。
