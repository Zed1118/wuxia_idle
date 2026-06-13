# P1 周目进化 实装 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 已通关关卡/全塔可挑战「下一周目」——敌人 +6%/周目 scale + 反制词条进化,新周目须重新手动单步通关再解锁自动刷。

**Architecture:** cycleIndex 入进度模型(主线 per-关-周目 key / 爬塔全塔周目);battleKey + resolveAutoPlayMode 接 cycle;敌人进化全在 `_enemyToBattle()` 注入(scale + 5 词条复用现有战斗 hook,御体/真气/识破纯注入零改结算,凝甲/反震加最小结算逻辑);周目选择 UI 复用 G3 选关屏 tile 体例。

**Tech Stack:** Flutter / Riverpod / Isar(saveVersion 0.20.0→0.21.0)/ numbers.yaml / TDD。

**参照 spec:** `docs/superpowers/specs/2026-06-14-cycle-evolution-p1-design.md`

**全局约束(每个 commit 前):** `flutter analyze` 0;改 schema 后 `dart run build_runner build --delete-conflicting-outputs`;§5.4 红线不破。

---

## 文件结构

- `lib/features/mainline/domain/mainline_progress.dart` — 加 `clearedStageCycleKeys`
- `lib/features/mainline/application/mainline_progress_service.dart` — recordVictory 接 cycle + cycle query helper
- `lib/features/tower/domain/tower_progress.dart` — 加 `currentCycleIndex`/`maxClearedCycle`
- `lib/features/tower/application/tower_progress_service.dart` — recordClear 接 cycle + 推进周目
- `lib/data/isar_setup.dart` — saveVersion 0.21.0 + 迁移段
- `data/numbers.yaml` + `lib/data/numbers_config.dart`(或现有 config 类)— 新增 `cycle_evolution` 段解析
- `lib/features/battle/application/stage_battle_setup.dart` — `_enemyToBattle` 加 cycleIndex + 词条注入;buildEnemyTeam/buildTeams 透传
- `lib/features/battle/domain/damage_calculator.dart` — 加 `defenderCritDamageTakenMult` param(凝甲)
- `lib/features/battle/domain/default_ground_strategy.dart`(或 _resolveAction 所在)— 反震 on-hit 逻辑
- `lib/features/battle/domain/auto_play_mode.dart` 消费侧 — isCleared per-cycle
- `lib/features/mainline/presentation/stage_list_screen.dart` 等选关屏 — 周目选择 UI
- `lib/shared/strings.dart` — 江湖记招 + 周目 UiStrings

---

## Phase A · Schema + 迁移(🔴 0.21.0 单点收口)

### Task A1: MainlineProgress 加 clearedStageCycleKeys

**Files:** Modify `lib/features/mainline/domain/mainline_progress.dart`; Test `test/features/mainline/mainline_cycle_progress_test.dart`

- [ ] **Step 1: 失败测** — 写 `test/features/mainline/mainline_cycle_progress_test.dart`,用真 Isar(沿 `test/features/battle/battle_replay_record_service_test.dart` 的 setUpAll `Isar.initializeIsarCore` + tempDir 体例):
```dart
test('recordVictory(cycle:2) 写 stageId#2 cycleKey + highestClearedCycle 派生', () async {
  final svc = MainlineProgressService(isar: IsarSetup.instance);
  await svc.getOrCreate(saveDataId: 1);
  await svc.recordVictory('stage_01_01'); // 默认 cycle 1
  await svc.recordVictory('stage_01_01', cycle: 2);
  final p = await svc.getOrCreate(saveDataId: 1);
  expect(p.clearedStageCycleKeys, containsAll(['stage_01_01#1', 'stage_01_01#2']));
  expect(MainlineProgressService.highestClearedCycle(p, 'stage_01_01'), 2);
  expect(MainlineProgressService.highestClearedCycle(p, 'stage_01_02'), 0);
});
```
- [ ] **Step 2: 跑测确认 fail**（`clearedStageCycleKeys`/`highestClearedCycle` 未定义)
Run: `flutter test test/features/mainline/mainline_cycle_progress_test.dart`
- [ ] **Step 3: 加字段** — `mainline_progress.dart` 在 `clearedAt` 后加:
```dart
  /// 每关每周目已手动通关键集合,每条 `"stageId#cycle"`(append-only 无序集合)。
  /// cycle1 解锁链仍用 [clearedStageIds];本字段管周目维度(P1 周目进化)。
  List<String> clearedStageCycleKeys = [];
```
- [ ] **Step 4: build_runner** Run: `dart run build_runner build --delete-conflicting-outputs`
- [ ] **Step 5: service 改** — `mainline_progress_service.dart` `recordVictory` 加 `{int cycle = 1}` 参数,首通 append `'$stageId#$cycle'` 到 `clearedStageCycleKeys`(幂等 contains 判定),cycle==1 时仍维护 `clearedStageIds`(原逻辑不动);加 static:
```dart
  static int highestClearedCycle(MainlineProgress p, String stageId) {
    var hi = 0;
    for (final k in p.clearedStageCycleKeys) {
      final parts = k.split('#');
      if (parts.length == 2 && parts[0] == stageId) {
        final c = int.tryParse(parts[1]) ?? 0;
        if (c > hi) hi = c;
      }
    }
    return hi;
  }
  static int currentChallengeCycle(MainlineProgress p, String stageId, {required int maxCycle}) {
    final next = highestClearedCycle(p, stageId) + 1;
    return next > maxCycle ? maxCycle : next;
  }
```
- [ ] **Step 6: 跑测绿** Run: `flutter test test/features/mainline/mainline_cycle_progress_test.dart`
- [ ] **Step 7: Commit** `git add -A && git commit -m "feat: MainlineProgress 加 clearedStageCycleKeys + 周目派生(P1 周目进化)"`

### Task A2: TowerProgress 加 currentCycleIndex/maxClearedCycle

**Files:** Modify `lib/features/tower/domain/tower_progress.dart` + `tower_progress_service.dart`; Test `test/features/tower/tower_cycle_progress_test.dart`

- [ ] **Step 1: 失败测**:
```dart
test('通关 30 层 → maxClearedCycle=1;开 cycle2 后 currentCycleIndex=2', () async {
  final svc = TowerProgressService(isar: IsarSetup.instance);
  await svc.getOrCreate(saveDataId: 1);
  final now = DateTime(2026, 6, 14);
  for (var f = 1; f <= 30; f++) {
    await svc.recordClear(floorIndex: f, now: now, elapsedMs: 1000);
  }
  var p = await svc.getOrCreate(saveDataId: 1);
  expect(p.maxClearedCycle, 1);
  await svc.advanceCycle(saveDataId: 1); // 玩家选挑战下一周目
  p = await svc.getOrCreate(saveDataId: 1);
  expect(p.currentCycleIndex, 2);
  expect(p.highestClearedFloor, 0); // 新周目从头爬
});
```
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 加字段** `tower_progress.dart`:
```dart
  /// 玩家当前在爬的周目(问鼎轮回,全塔规则)。default 1。
  int currentCycleIndex = 1;
  /// 已 30 层全通关到的最高周目(0=未通关整塔,N=cycle 1..N 均通关)。
  int maxClearedCycle = 0;
```
- [ ] **Step 4: build_runner**
- [ ] **Step 5: service 改** — `recordClear`:首通 floor==30 时 `maxClearedCycle = currentCycleIndex`;加 `advanceCycle`(maxClearedCycle>=currentCycleIndex 才可推进:`currentCycleIndex++` + `highestClearedFloor=0` + 清当前周目派生)。`canChallenge` 不变(当前周目内层判定)。
- [ ] **Step 6: 跑测绿**
- [ ] **Step 7: Commit** `git commit -m "feat: TowerProgress 加 currentCycleIndex/maxClearedCycle + advanceCycle(问鼎轮回)"`

### Task A3: saveVersion 0.21.0 + 迁移

**Files:** Modify `lib/data/isar_setup.dart`; Test `test/data/save_migration_021_test.dart`

- [ ] **Step 1: 失败测** — 造一行 saveVersion='0.20.0' 的旧档 + MainlineProgress(clearedStageIds=['stage_01_01']) + TowerProgress(highestClearedFloor=30),跑 init 迁移,断言:`clearedStageCycleKeys` 含 `'stage_01_01#1'`;tower `currentCycleIndex==1` + `maxClearedCycle==1`;saveVersion=='0.21.0'。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 改** — `isar_setup.dart`:`_currentSaveVersion = '0.21.0'`;`_migrateSaveData` 加段(沿现有体例 writeTxn):遍历 mainlineProgress 把每个 `clearedStageIds[i]` 补 `'$id#1'` 入 clearedStageCycleKeys(去重);遍历 towerProgress 设 `currentCycleIndex=1` + `maxClearedCycle = highestClearedFloor>=30 ? 1 : 0`。
- [ ] **Step 4: build_runner + 跑测绿**
- [ ] **Step 5: 全仓改 0.20.0 断言** Run: `git grep -n "'0.20.0'" test/` → 把出现的版本断言改 0.21.0(saveVersion 断言处)。`flutter test test/data/`
- [ ] **Step 6: Commit** `git commit -m "feat: saveVersion 0.21.0 + 周目字段迁移(旧档 cycle1/塔周目1)"`

---

## Phase B · 敌人 cycle scale

### Task B1: numbers.yaml cycle_evolution 段 + config 解析

**Files:** Modify `data/numbers.yaml` + config 类(grep `class .*Config` 找 numbers 解析处,沿 `mass_battle`/`enemy_defaults` 段体例新增 `CycleEvolutionConfig`); Test `test/data/cycle_evolution_config_test.dart`

- [ ] **Step 1: 失败测** — 断言 `GameRepository.instance.numbers.cycleEvolution.scalePerCycle == 0.06` + `maxCycleMainline==3` + `maxCycleTower==2` + traits 参数(yuti c2/c3 pct、fanzhen damage、ningjia critTakenMult、zhenqi ifPct、shipo skillId)可读 + `traitsFor(cycle, isBoss, isTower)` 返回正确集合。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: yaml + config** — `data/numbers.yaml` 末加:
```yaml
cycle_evolution:
  scale_per_cycle: 0.06
  max_cycle_mainline: 3
  max_cycle_tower: 2
  defense_rate_cap: 0.6        # 御体叠加后 clamp,防伤害归零
  traits:
    yuti: { defense_rate_bonus_c2: 0.08, defense_rate_bonus_c3: 0.12 }
    fanzhen: { damage_per_tick: 200, ticks: 3 }
    ningjia: { crit_damage_taken_mult: 0.5 }
    zhenqi: { internal_force_pct: 0.20 }
    shipo: { charge_skill_id: skill_qing_feng_jue }  # 复用既有蓄力破招技
  assignment:
    mainline: { 2: [yuti], 3: [yuti, fanzhen, shipo] }
    tower_normal: { 2: [yuti, zhenqi] }
    tower_boss: { 2: [yuti, fanzhen, shipo, ningjia] }
```
解析进 `CycleEvolutionConfig`,含 `Set<String> traitsFor({required int cycle, required bool isBoss, required bool isTower})`(cycle<=1 返回空)。
- [ ] **Step 4: 跑测绿 + Commit** `git commit -m "feat: numbers.yaml cycle_evolution 段(scale+5词条+分配)"`

### Task B2: _enemyToBattle 接 cycleIndex(scale + 注入纯注入型词条)

**Files:** Modify `stage_battle_setup.dart`; Test `test/features/battle/enemy_cycle_scale_test.dart`

- [ ] **Step 1: 失败测**:
```dart
test('cycle 3 敌人 hp/attack ×1.12 + 御体注入(defenseRate↑clamp) + activeBuffs 标签', () {
  final enemy = EnemyDef(/* baseHp 1000, baseAttack 500, school..., isBoss false */);
  final c1 = StageBattleSetup.debugEnemyToBattle(enemy: enemy, slotIndex: 0, cycleIndex: 1);
  final c3 = StageBattleSetup.debugEnemyToBattle(enemy: enemy, slotIndex: 0, cycleIndex: 3, isTower: false);
  expect(c3.maxHp, (1000 * 1.12).toInt());
  expect(c3.totalEquipmentAttack, (500 * 1.12).toInt());
  expect(c3.defenseRate, greaterThan(c1.defenseRate)); // 御体
  expect(c3.activeBuffs, containsAll(['cycle_yuti', 'cycle_fanzhen', 'cycle_shipo']));
  expect(c1.activeBuffs, isEmpty);
});
```
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 改** — `_enemyToBattle` 加 `int cycleIndex = 1, bool isTower = false`;读 `cycleEvolution`:`scale = 1 + scalePerCycle*(cycleIndex-1)`,hp/attack/maxInternalForce ×scale(int);`traits = traitsFor(cycle, isBoss, isTower)`;按 trait 改注入值:`yuti`→defenseRate += pct(c2/c3) clamp ≤ defense_rate_cap;`zhenqi`→IF ×(1+pct);`shipo`→chargeSkillId = traits.shipo.skillId(若敌无自带);`activeBuffs = traits.map((t)=>'cycle_$t').toList()`(凝甲/反震仅靠标签,结算侧消费)。`debugEnemyToBattle` + `buildEnemyTeam` + `buildTeams` 链路加 cycleIndex/isTower 透传。
- [ ] **Step 4: 跑测绿 + Commit** `git commit -m "feat: _enemyToBattle 接 cycleIndex(scale + 御体/真气/识破注入 + 词条标签)"`

---

## Phase C · 凝甲 + 反震(战斗结算最小逻辑)

### Task C1: 凝甲(暴击伤害减半)— damage_calculator param

**Files:** Modify `damage_calculator.dart` + 调用处(strategy `_resolveAction`); Test `test/features/battle/cycle_trait_ningjia_test.dart`

- [ ] **Step 1: 失败测** — 同输入强制暴击,`defenderCritDamageTakenMult: 0.5` 的伤害 ≈ critMult 段减半(对比 1.0 基线)。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 改** — `damage_calculator` 计算 critMult 后:`final effectiveCritMult = isCritical ? (critMult - 1.0) * defenderCritDamageTakenMult + 1.0 : 1.0;`(只削暴击增量,非暴击不影响),用 effectiveCritMult 进 raw。函数签名加 `double defenderCritDamageTakenMult = 1.0`。
- [ ] **Step 4: 调用处** — `_resolveAction`(grep calculateAttack 调用)传 `defenderCritDamageTakenMult: defender.activeBuffs.contains('cycle_ningjia') ? n.cycleEvolution.traits.ningjia.critDamageTakenMult : 1.0`。
- [ ] **Step 5: 跑测绿 + Commit** `git commit -m "feat: 凝甲词条(暴击伤害减半,复用暴击系数路径)"`

### Task C2: 反震(玩家命中→反弹内伤到攻击者)

**Files:** Modify strategy(`default_ground_strategy.dart` _resolveAction 命中后);Test `test/features/battle/cycle_trait_fanzhen_test.dart`

- [ ] **Step 1: 失败测** — 玩家攻击带 `cycle_fanzhen` 的敌人,命中后攻击者获 `InternalInjurySlot(remainingTurns: 3, damagePerTick: 200)`;打死/未命中不触发。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 改** — `_resolveAction` 内,玩家主攻击命中(非闪避、teamSide 0 打 teamSide 1)且 `defender.activeBuffs.contains('cycle_fanzhen')` 时,给 attacker 写/刷新 `internalInjury = InternalInjurySlot(remainingTurns: ticks, damagePerTick: damage)`(读 numbers fanzhen 参数;沿现有阴柔内伤 slot 写法 battle_state.dart:126 + strategy 衰减体例,穿透防御不暴击)。
- [ ] **Step 4: 跑测绿 + Commit** `git commit -m "feat: 反震词条(玩家命中反弹固定内伤,复用 InternalInjurySlot)"`

---

## Phase D · battleKey / resolveAutoPlayMode 接周目

### Task D1: 入口流传 cycle + isCleared per-cycle

**Files:** Modify `stage_entry_flow.dart` / `tower_entry_flow.dart`;消费 `resolveAutoPlayMode` 处;Test `test/features/battle/auto_play_mode_cycle_test.dart`

- [ ] **Step 1: 失败测** — provider/纯函数层:给定 MainlineProgress 含 `stage_01_01#1` 不含 `#2`,`stage_01_01` cycle1 isCleared=true / cycle2 isCleared=false(per-cycle 判定);battleKey 用对应 cycle 串。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 改** — `_StageBattleHost`:`currentCycle = MainlineProgressService.currentChallengeCycle(progress, stage.id, maxCycle: ...)` 或玩家从周目选择 UI 选定的 cycle(D2 wire);battleKey=`stageBattleKey(id, cycle: currentCycle)`;`isCleared = progress.clearedStageCycleKeys.contains('${stage.id}#$currentCycle')`;onVictory `recordVictory(stage.id, cycle: currentCycle)` + record 用带 cycle battleKey。`_enemyToBattle` 链传 cycleIndex=currentCycle。tower 同理用 `currentCycleIndex` + `recordClear(cycle:)`。
- [ ] **Step 4: 跑测绿 + 全量回归** Run: `flutter test`
- [ ] **Step 5: Commit** `git commit -m "feat: 入口流接 cycle(battleKey/isCleared/录制/敌人scale per周目)"`

---

## Phase E · 周目选择 UI + 江湖记招叙事

### Task E1: UiStrings + 周目选择控件

**Files:** Modify `lib/shared/strings.dart` + 新 `lib/features/battle/presentation/cycle_select_control.dart`(沿 G3 `stage_auto_play_control.dart` 体例);Test `test/features/battle/presentation/cycle_select_control_test.dart`(provider override 喂态,避免 Isar writeTxn 死锁,见 memory feedback_isar_widget_test_deadlock)

- [ ] **Step 1: 失败测** — 已通关 cycle1、可挑战 cycle2 的关:控件显「第一周目(自动)/ 挑战第二周目(手动)」两态;选挑战 → 回调带 targetCycle=2。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 实装** — UiStrings 加 `cycleCurrentLabel`/`cycleChallengeNext`/`jianghuRememberHint='此敌已识得你的路数,见招拆招。'` 等;`CycleSelectControl` ConsumerWidget(读 progress 派生 highestClearedCycle/currentChallengeCycle,渲染当前周目 + 挑战下一周目切换,onChanged 回 targetCycle)。
- [ ] **Step 4: 跑测绿 + Commit** `git commit -m "feat: 周目选择控件 + 江湖记招 UiStrings"`

### Task E2: 选关屏接线 + 江湖记招战前提示

**Files:** Modify `stage_list_screen.dart`(+心魔/轻功/群战/tower 屏,沿 G3 接线点);battle 进场提示;Test 扩选关屏 widget 测

- [ ] **Step 1: 失败测** — cleared tile 在 cycle 可推进时显 CycleSelectControl;cycle≥2 进战斗 BattleScreen 显 jianghuRememberHint。
- [ ] **Step 2: 跑测 fail**
- [ ] **Step 3: 实装** — 选关屏 cleared tile 区(G3 AutoPlayToggle 同位)加 CycleSelectControl;选挑战 cycle N+1 → 进 `_StageBattleHost(targetCycle:)`;BattleScreen 加可选 cycleHint 文案条(cycle≥2 显)。tower 顶部加 currentCycleIndex 切换 + 通关 30 层后「挑战下一轮回」入口(调 advanceCycle)。
- [ ] **Step 4: 跑测绿 + 全量回归 + Commit** `git commit -m "feat: 选关屏接周目选择 + 江湖记招战前提示(主线/塔/心魔/轻功/群战)"`

### Task E3: 验收 route + Codex 派单

**Files:** Modify `visual_route.dart` + `visual_route_host.dart`;新 `docs/codex_dispatch_cycle_evolution_*.md`

- [ ] **Step 1:** 加 route `stage_list_cycle`(seed:01_01 cycle1 已通关 → 显挑战 cycle2)+ `tower_cycle`(seed:通关 30 层 → 显挑战 cycle2)。analyze 0。
- [ ] **Step 2:** 写 Codex 派单(沿 `codex_dispatch_g3_autoplay_toggle_*` 体例:验周目选择控件 / 挑战 N+1 进战斗 / 江湖记招提示 / cycle≥2 敌人进化可感)。
- [ ] **Step 3: Commit** `git commit -m "feat: 周目进化验收 route + Codex 派单"`

---

## Phase F · 压测守红线 + 收口

### Task F1: 跨阶+周目压测 + 全量回归

**Files:** Test `test/balance/cycle_evolution_redline_test.dart`

- [ ] **Step 1:** 写压测:主线 cycle 3 + 神物关 + 爬塔 cycle 2 Boss 层,多 seed 跑 battle,断言敌人 maxHp ≤ redLines(boss ≤50000)、单次伤害 ≤8000、玩家血/内力红线不破。
- [ ] **Step 2:** 跑 `flutter test`(全量)确认不退;`flutter analyze` 0。
- [ ] **Step 3: Commit** `git commit -m "test: 周目进化跨阶压测守红线 + 全量回归"`

### Task F2: PROGRESS + closeout

- [ ] 更新 PROGRESS.md 顶部 P1 周目进化条;写 `docs/handoff/p1_cycle_evolution_closeout_2026-06-14.md`(≤80 行)。Commit。

---

## Self-Review 覆盖检查

- spec §三 schema → A1/A2/A3 ✓;§五 scale → B1/B2 ✓;§六 5 词条 → 御体/真气/识破(B2)+ 凝甲(C1)+ 反震(C2)✓;§四 battleKey/自动判定 → D1 ✓;§七 周目选择 UI → E1/E2 ✓;§八 叙事 hook → E1/E2 ✓;§九 红线/TDD → F1 + 各 task TDD ✓。
- 类型一致:`traitsFor({cycle,isBoss,isTower})`、`activeBuffs` 标签 `'cycle_<trait>'`、`highestClearedCycle/currentChallengeCycle`、`advanceCycle`、`defenderCritDamageTakenMult` 全 plan 内一致。
- 无占位:各 code step 给出实际字段/签名/yaml;机械接线处引 G3/现有体例 file 锚点。
