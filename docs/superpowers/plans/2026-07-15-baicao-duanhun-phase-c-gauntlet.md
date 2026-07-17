# 断魂庄三关 Phase C 实施计划（C1 控制器/真气扣减/快照 + C2 整备/托管/恢复/奖励/UI）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax。

**Goal:** 实装断魂庄 `boss_gauntlet` feature：持帖入场、苏无咎／石镇岳／闻九针三连战控制器、敌方真气扣减通用效果、关次边界检查点、庄内整备页（会话托管补给）、崩溃恢复、Boss 胜利三选一（`awaitingRewardChoice`）、首通／失败结算——状态与最多三份补给跨战生效，凭证/补给守恒。

**Architecture:** **C1（控制器/战斗/领域）**：`BossGauntletController` 按关启动三场既有地面战斗（不复用自动跑完波次的群战策略，§8.1）、关次边界快照（跨战白名单 §4.2）、敌方 `qi_drain` 通用效果（引擎新维度 §5.2）。**C2（整备/托管/恢复/奖励/UI）**：入场扣帖 + 补给移入托管（单事务 Q2）、整备页用药扣托管、崩溃恢复到关次开打前整备态（§5.6）、`awaitingRewardChoice` 三选一原子结算（Q4/§9.2）、首通/失败结算、庄内整备屏。C 只依赖 Phase A，不依赖 Phase B。

**Tech Stack:** Flutter Desktop · Isar · Riverpod 3.x · `DefaultRng(seed:)` · `data/boss_gauntlets.yaml`（A2 骨架）。

**依赖：** **Phase A1/A2 完成**（`BossGauntletRun`＋`GauntletPhase`＋托管三列表＋`rewardCandidateDefIds`＋`isFirstClearPending`／`SaveData.clearedGauntletIds`＋`duanhunFirstClearedAt`／`ItemDef.gauntletHpHealPct/QiRestorePct`／断魂帖 item／`BossGauntletConfig`＋`boss_gauntlets.yaml` 骨架／`CharacterOccupancyService` 均已冻结）。**下游：** 批3 联合经济探针读三档胜率与命名装备产出；断魂庄首破纳战绩册列后续独立小批（§13）。

**源规格：** baicao design §5（断魂庄全节）/§6.2-6.4（奖励/断魂帖）/§9.2（事务）/§10（恢复）/§12.2（领域战斗测试）/§12.4（visual_route）＋ companion §3.2/§3.4/§3.6/§4.2。

---

## 前置

```bash
flutter pub get && dart run build_runner build --delete-conflicting-outputs
git grep -n "class BossGauntletRun\|GauntletPhase.awaitingRewardChoice" lib/   # A1 冻结在
git grep -n "gauntletHpHealPct\|item_duanhuntie\|class BossGauntletConfig" lib/ data/  # A2 在
```

敌人/机制数值（苏无咎/石镇岳/闻九针 HP/攻击/机制参数、命名装备三件、锁脉针法秘籍、典故）由本 feature 建（§4.8 内容资产），系数经批3 探针三档（入门/推荐/满配）校准；实装期用本计划占位初值 `TODO(batch3-probe)`。

---

## 文件结构

| 文件 | 责任 | 组 |
|---|---|---|
| `lib/features/boss_gauntlet/domain/qi_drain_effect.dart` | 敌方真气扣减通用效果（schema 界 (0,0.5]） | C1 |
| `lib/features/boss_gauntlet/application/gauntlet_controller.dart` | 三关编排 + 关次边界快照 + 跨战白名单 | C1 |
| `lib/features/boss_gauntlet/application/gauntlet_battle_runner.dart` | 单关 headless 战斗（含 qi_drain 生效） | C1 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart` | 入场扣帖/托管/整备用药/恢复/奖励结算（事务） | C2 |
| `lib/features/boss_gauntlet/application/gauntlet_reward_service.dart` | 首通/重复/失败奖励（§6.2/6.3） | C2 |
| `lib/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart` | 补给装载（§7.1） | C2 |
| `lib/features/boss_gauntlet/presentation/gauntlet_interlude_screen.dart` | 庄内整备（§7.2） | C2 |
| `data/boss_gauntlets.yaml` / `data/items.yaml` / 敌人·招式·装备·叙事表 | 内容资产 | C1/C2 |

> 冻结命名：`QiDrainEffect`；`GauntletController`；`GauntletService`；关角色 role 用 A2 `boss_gauntlets.yaml` 的 `elite`/`boss`。

---

# ── C1：控制器 / 真气扣减 / 关次快照 ──

## Task C1.1: 敌方真气扣减通用效果（§5.2，引擎新维度） ✅ 完成 `2000fd55`

**Files:**
- Create: `lib/features/boss_gauntlet/domain/qi_drain_effect.dart`
- Test: `test/features/boss_gauntlet/qi_drain_effect_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/boss_gauntlet/qi_drain_effect_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/qi_drain_effect.dart';

void main() {
  test('扣减比例 ∈ (0,0.5]，只降至零不为负', () {
    expect(QiDrainEffect(pct: 0.30).applyTo(currentQi: 100, maxQi: 140), 70);
    expect(QiDrainEffect(pct: 0.30).applyTo(currentQi: 10, maxQi: 140), 0);
  });
  test('越界比例构造抛错（schema 硬界）', () {
    expect(() => QiDrainEffect(pct: 0.0), throwsArgumentError);
    expect(() => QiDrainEffect(pct: 0.6), throwsArgumentError);
    expect(() => QiDrainEffect(pct: -0.1), throwsArgumentError);
  });
  test('比例基于最大真气（§5.2 锁脉针=30%最大真气）', () {
    // 100 当前、140 最大 → 扣 0.30*140=42 → 58
    expect(QiDrainEffect(pct: 0.30).applyTo(currentQi: 100, maxQi: 140), 58);
  });
}
```

- [ ] **Step 2: 跑测试确认失败** → 编译失败。

- [ ] **Step 3: 实现**

```dart
// lib/features/boss_gauntlet/domain/qi_drain_effect.dart

/// 敌方真气扣减通用效果（§5.2）。现行真气只有自产/自耗（v1.34），敌方剥夺是引擎
/// 新维度；schema 硬界比例 ∈ (0, 0.5]、只降至零不为负。锁脉针为首个实例，未来
/// Boss 可复用。属「资源剥夺」方向机制，不膨胀伤害数字。
class QiDrainEffect {
  QiDrainEffect({required this.pct}) {
    if (pct <= 0.0 || pct > 0.5) {
      throw ArgumentError('qi_drain pct 须 ∈ (0, 0.5]，got $pct');
    }
  }

  /// 扣减比例（作用于最大真气，§5.2）。
  final double pct;

  /// 对一名角色施加：从 [currentQi] 扣 `pct * maxQi`，下限 0（不为负）。
  int applyTo({required int currentQi, required int maxQi}) {
    final drained = (currentQi - (pct * maxQi).round());
    return drained < 0 ? 0 : drained;
  }
}
```

> 战斗内接线：招式配置层加 `qi_drain_pct` 字段（`skills.yaml` 沿 `qiDelta` 体例），未破招时对存活玩家角色施加 `QiDrainEffect`（苏无咎锁脉针 §5.2）。CLAUDE §5.4 随实装批照 v1.31 体例追加机制型实例注记。

- [ ] **Step 4: 测试** → PASS。

- [ ] **Step 5: 提交** `git commit -m "feat: 加敌方真气扣减通用效果"`

---

## Task C1.2: 跨关状态白名单快照（§4.2/§5.5） ✅ 完成 `17d14e5e`

**Files:**
- Create: `lib/features/boss_gauntlet/application/gauntlet_controller.dart`（快照部分）
- Test: `test/features/boss_gauntlet/gauntlet_snapshot_test.dart`

- [ ] **不变式（测试先行）：** 三关之间**只继承**当前生命／当前真气／阵亡状态／技能冷却；行动条、临时 Buff/Debuff/控制/护盾/召唤物/临时目标/敌方状态**全部清除**（§4.2）。持久伤势属角色外部状态，不由关次快照重复写入。**逐类**「保留/清除」都要测覆盖，不依赖序列化整个 `BattleState`（§4.2）。

- [ ] **实现：** `GauntletController.snapshotAfterStage(finalState) → List<ActivityMemberSnapshot>`（写 `currentHp`/`currentQi`/`isDowned`；冷却单列存 A1 快照或关内重置——按 §4.2 冷却保留、行动条重置）。`restoreForNextStage(snapshot)` 只重置行动条。提交 `feat: 加断魂庄跨关状态白名单快照`。

## Task C1.3: 三关控制器 + 单关 headless 战斗（§5.2-5.5）

**Files:**
- Create: `lib/features/boss_gauntlet/application/gauntlet_battle_runner.dart`
- Modify: `gauntlet_controller.dart`
- Test: `test/features/boss_gauntlet/gauntlet_controller_test.dart`

- [ ] **测试断言：** 第一关苏无咎未破招扣真气（`QiDrainEffect` 生效）、破招开两拍完整承伤窗口（窗口外 0.65）；第二关石镇岳护卫存活时护阵 0.25、全倒解除触发「铁衣破」；第三关闻九针三阶段按血线切换（100-70 集中/70-35 逆行封脉窗口 0.35/低于35 断魂九针）。控制器**按关**启动三场既有地面战斗（`gauntlet_battle_runner` 用 `DefaultRng(seed:)` + `default_ground_strategy` tick → finalState），每场结束保存快照并停在整备（不自动连打）。

- [ ] **实现：** `gauntlet_battle_runner.runStage(stageConfig, teamSnapshot, seed) → finalState`（沿 Phase B `ExpeditionBattleRunner` 同 wiring，另注入 `QiDrainEffect` 与关机制承伤乘子）。`GauntletController.advance()`：跑当前关 → 快照 → `currentStage++` / 进 `interlude`。提交 `feat: 加断魂庄三关控制器与单关战斗`。

> 敌人机制（承伤窗口/护阵/三阶段）承伤乘子走 `boss_gauntlets.yaml` schema 有界 [0.05,1.0]（守 §5.4 机制型 Boss 例外，减伤方向不膨胀伤害）。种子 = `stableSeed(saveId, gauntletRunId, stage)`（沿 Phase B `ExpeditionSeed` 同款显式混种，§5.6 单关重打不重抽）。

---

# ── C2：整备 / 托管 / 恢复 / 待选奖励 / 结算 / UI ──

## Task C2.1: 入场扣帖 + 补给移入托管（单事务 Q2/§5.1/§9.2）

**Files:**
- Create: `lib/features/boss_gauntlet/application/gauntlet_service.dart`
- Test: `test/features/boss_gauntlet/gauntlet_entry_test.dart`

- [ ] **不变式：** `enter(team, supplies)` 单 `writeTxn` 内——校验占用（`CharacterOccupancyService`）+ 扣一张断魂帖（`item_duanhuntie`）+ 最多三份补给从普通库存**移入** `BossGauntletRun` 托管三列表（`escrowItemDefIds/LoadedQty/UsedQty`，`UsedQty=0`）+ 建会话（`GauntletPhase.inBattle`, `currentStage=1`, 队伍快照, seed）。扣帖与建会话必须同事务（§5.1）；失败/认输不退帖（§5.1）；补给移入后普通库存不再持有这三份（杜绝背包/战后治疗重复消费）。提交 `feat: 加断魂庄入场扣帖与补给托管事务`。

## Task C2.2: 整备页用药 + 关闭返还（守恒，§5.1/§9.2）

- [ ] **不变式：** 整备页 `useSupply(index)` 单事务只减托管 `UsedQty`（不碰普通库存），疗伤丹恢复一名存活角色 `gauntletHpHealPct`(30%)最大生命、行囊补给恢复全体存活 `gauntletQiRestorePct`(20%)最大真气（A2 字段），均不复活倒下者；战斗进行中不能用药（只整备页）。`close(reason)`（胜利/失败/认输/安全恢复）单事务把 `LoadedQty - UsedQty` 原子**返还**普通库存。**守恒测**：装入=已用+返还，任何路径不复制不丢失（§12.2）。提交 `feat: 加断魂庄整备用药与关闭返还`。

## Task C2.3: 崩溃恢复到关次开打前整备态（§5.6/§10）

- [ ] **不变式：** 检查点只在两类时刻（每场战斗结束进整备页；整备页每次用药后）；战斗中不存。关闭游戏重进 → 恢复到当前关**开打前整备态**、重打该关；断魂帖不重扣、已用补给不返不复制、已击败关次进度/队伍状态/暂存奖励保留；生命/真气/冷却/阵亡为该关开打前检查点原值不回满；单场重打同一稳定随机流不重抽（§5.6）。配置损坏：第一关前不可恢复 → 关会话退帖；已开战 → 认输关闭保已结算经验不复制补给（§10）。提交 `feat: 加断魂庄崩溃恢复关次边界`。

## Task C2.4: Boss 胜利 awaitingRewardChoice 三选一原子结算（Q4/§9.2）

**Files:**
- Create: `lib/features/boss_gauntlet/application/gauntlet_reward_service.dart`
- Modify: `gauntlet_service.dart`
- Test: `test/features/boss_gauntlet/gauntlet_reward_test.dart`

- [ ] **不变式（最关键幂等，§9.2）：**
  1. 最终 Boss 胜利 → 单事务原子固化「胜利＋`rewardCandidateDefIds`（三件命名装备）＋`isFirstClearPending`（首通判定快照）＋待结算」并进 `GauntletPhase.awaitingRewardChoice`。
  2. 胜利后、选择前关闭游戏 → 重进强制恢复奖励三选一页，**不再战斗、不重抽候选**。
  3. `chooseReward(defId)` 单事务一次性发装备＋经验（§6.2 首通 30%/重复 15%）＋领悟点＋秘籍（首通「锁脉针法」）＋典故（「断魂庄首破」加参战主装备），写 `SaveData.clearedGauntletIds`＋`duanhunFirstClearedAt`（首通），关会话。
  4. **重复点击/窗口重入只成功一次**（用 `clearedGauntletIds` 防重 + phase 迁到 `settled`）。
  5. 首通秘籍不重复掉落（`clearedGauntletIds` 判定）。

- [ ] **命名装备保护并入（Q6/§6.2）：** 重复通关未培养命名装备允许助炼/分解（装备批 `reservedEquipmentIds` 已接口）；带「断魂庄首破」典故/已培养(`battleCount>0`或已开锋)/装备中/占用/锁定的实例受保护；默认同 `defId` 至少留一件。**在奖励发放测试同时断言保护规则**。提交 `feat: 加断魂庄奖励三选一原子结算与命名装备保护`。

## Task C2.5: 失败结算（§6.3）+ 装载/整备 UI（§7/§12.4）

- [ ] **失败结算：** 已击败精英经验照常给全体参战（含途中倒下者）；装备/秘籍/领悟点/最终奖励全失；已用补给不返；按实际经历结算轻/重伤不扣永久内力；无保底/每日首胜/登录补偿/付费恢复（§6.3）。
- [ ] **UI：** `gauntlet_loadout`（断魂帖库存/三敌人/推荐境界/补给装载/持帖入庄）＋`gauntlet_interlude`（三角色生命-真气-阵亡-冷却/三份托管补给剩余/使用-继续闯关-认输离庄，1280×720 与 1440×900 一屏，§7.2）。两条 visual_route 沿 team_lineup 确定性 seed（§12.4）。提交 `feat: 加断魂庄失败结算与装载整备UI`。

> UI 像素细节实装期真机截图验收；本计划钉信息架构 + 两 visual_route。

---

## Task C.V: 批末验证

- [ ] `flutter analyze --no-pub lib/ test/` → 0
- [ ] targeted：`flutter test --no-pub test/features/boss_gauntlet/`
- [ ] 跨切面全量（qi_drain 触战斗引擎 + 结算路径，必跑）：`flutter test --no-pub`
- [ ] 红线：`flutter test --no-pub test/balance/` 相关（qi_drain/承伤乘子不破「伤害不进百万」硬线）
- [ ] visual_route 两条 @1280×720/1440×900（Codex 目检）
- [ ] macOS debug build

## 当前恢复点
- **状态：** C1 组进行中。**C1.1** qi_drain 效果 ✅ commit `2000fd55`；**C1.2** 关次边界白名单快照 ✅ commit `17d14e5e`（`ActivityMemberSnapshot` 加冷却平行列 `skillCooldownKeys/Turns`，可加性无 saveVer 迁移、远征留空）；**C1.3.1** qi_drain 引擎接线 ✅ commit `2116db97`；**C1.3.2** 敌队 3 队 EnemyDef（yaml 驱动）✅ commit `80c17947`；**C1.3.3** 单关战斗驱动 + 关次推进状态机 ✅ commit `2a894123`。**C1 组全完成**（断魂庄后端内核闭环）。**C2.1** 入场扣帖 + 补给会话托管 ✅ commit `b146e96a`（`GauntletService.enter` 单 writeTxn·严格 TDD 12 测）。**C2.2** 整备用药 + 关闭返还 ✅ commit `03a44548`+`613729f4`（`useSupply`/`close` + `ActivityMemberSnapshot` 加 maxHp/maxQi 列·严格 TDD 15 测）。**C2.3** 单场战斗驱动 + 崩溃恢复 ✅ commit `f8c2cc1d`+`cb0227f3`（`fightCurrentStage`/`continueToNextStage`/`GauntletController.stagePlayerTeam`/`recover`·严格 TDD 15 测=纯 6+驱动 4+恢复 5）。**C2.4** 通关奖励配置 + Boss 胜利三选一固化 + `chooseReward` 原子结算/幂等 ✅ commit `c98ee079`+`1e43428a`（+`bc704028` 测订正·[schema] reward 字段/加载红线·`stageBossReward`·`chooseReward` 发装备/经验/领悟点/秘籍/记通关/返还/关会话·严格 TDD 19 测）。**C2.5** 失败结算 + 装载/整备双 UI + 2 visual_route ✅ commit `43e98625`(settleDefeat §6.3·[schema] eliteRewardExp)+`27e6ac2f`(loadout 屏+5 provider §7.1)+`98eaf026`(interlude 屏+view provider §7.2)+`424b757e`(2 visual_route+seed §12.4)·严格 TDD 22 测·全量 4260/0·**C2 组全闭环(后端内核+前端信息架构)**。**下一步(后续切片)**：战斗驱动全链导航 wiring(loadout enter→逐关战斗[BattleScreen]→interlude→reward + 主菜单断魂庄入口)。**C2.4d 命名装备保护 + 断魂庄首破典故 延后**（典故需 Equipment schema 改·bg 夜跑不冒 saveVer 迁移风险·见下条）。
- **C1.3.1 落点（已实装）：** `SkillDef.qiDrainPct`（camelCase·默认 0·fromYaml 解析）；`default_ground_strategy._resolveAction` 在 targetAfters 写回后、`next` 组装前——`forcedSkill != null && skill.qiDrainPct > 0` → 对 `oppSide` 存活成员施 `QiDrainEffect`（复用 C1.1）改写 `left`/`right` + 每被夺成员一条 `EnumL10n.qiDrained` 日志（`drainActions` 并入 actionLog）；`game_repository._enforceEncounterSkillRedLines` 加 `qiDrainPct ∈ [0,0.5]` 启动 fail-fast。**测走 strategy 直驱确定性 harness**（`p0_charge_break_test` 体例·`strategy.tick(state, n, rng: Random(seed))` 手搭 mid-charge 态；memory `feedback_battle_determinism_test_via_notifier` 的 notifier.advance 适用于**种子分歧**测，本 wiring 测非此类，故未用）。
- **C1.3.2 落点（已实装·commit `80c17947`）：** 3 队 `EnemyDef` 走 **yaml 驱动**（用户 AskUserQuestion 拍板）：`boss_gauntlets.yaml` 新增 `enemy_teams:` map（gauntlet_su_wujiu / gauntlet_shi_zhenyue / gauntlet_wen_jiuzhen），`BossGauntletConfig` 加 `enemyTeams` 字段 + `enemiesForTeam(teamId)`，`fromYaml` 经 `EnemyDef.fromYaml` 解析。机制：苏无咎(灵巧·chargeSkillId=skill_suo_mai_zhen·vulnerability 0.65)/石镇岳(刚猛·guardianWard 0.25·guardianIds=2 执杖庄客 taunt)/闻九针(阴柔·bossPhases[1.0/0.70/0.35]·vulnerability 0.35·后二相 chargeCounter 解锁长练坊 skill/ult)。新招 `skill_suo_mai_zhen`(阴柔 tier2 mainline_drop·qiDrainPct 0.30·mount_deferred)，计数 246→247 已同步 GDD/skill_count_contract/skill_qi_redline。**加载期红线** `_enforceGauntletEnemyRedLines`（Slice C·§8.2 引用完整性）：stage.enemyTeamId∈enemyTeams / skillIds∈skillDefs / chargeSkillId∈skillIds / bossPhase unlockSkillIds∈skillDefs / guardianIds∈team，悬空 fail-fast。数值全 `TODO(batch3-probe)` 占位。
- **C1.3.3 落点（已实装·commit `2a894123`）：** 分两纯层。① `GauntletBattleRunner.runStage(playerTeam, enemyDefs, numbers, seed)`（新文件 `application/gauntlet_battle_runner.dart`）= `StageBattleSetup.buildEnemyTeam(enemyDefs)` + `ExpeditionBattleRunner.runNodeBattle` → `GauntletStageResult(leftWin, finalState)`。② `GauntletController.advance(run, finalState, isBossStage)`（纯状态机）：`snapshotAfterStage` 记战末快照 → 胜利非终关 `interlude`+`currentStage++`（不自动连打）/ 胜利终关 `awaitingRewardChoice` / 败平不推进停当前关（失败结算归 C2.5）。玩家 Isar 载入 + 组合(runStage→advance)归 C2.1 service。测 7（runner 3：确定性/三关机制字段进战斗/玩家高一阶破关1 leftWin + advance 4：胜非终/胜终/败/平）。
- **C2.1 落点（已实装·commit `b146e96a`）：** 新建 `boss_gauntlet/application/gauntlet_service.dart` `GauntletService.enter({List<int> characterIds, Map<String,int> supplies=defId→份数, required int supplyCap})`。**无 `now` 入参**——`BossGauntletRun` 无时间字段（stage-by-stage 交互，非离线时间结算，异于远征 dispatch）。单 writeTxn：pre-txn 纯校验(1-3人/去重/补给正数/总份≤supplyCap) → txn 内(save 存在/单 active `bossGauntletRuns.any(saveDataId==save.id)`/occupancy snapshot/逐角色 存在·非祖师·未占用·已修主修 建 `ActivityMemberSnapshot`) → 扣一张 `item_duanhuntie`(getByDefId·quantity<1 抛错) → 补给逐项移入 escrow 三列表(quantity 不足抛错·扣普通库存·usedQty=0) → 建 `BossGauntletRun`(saveDataId/seed/stage1/inBattle/members/escrow)。任一校验抛 StateError·单 writeTxn 回滚保原子（无帖/补给不足/回滚 3 测证）。TDD 12 测 `test/features/boss_gauntlet/gauntlet_enter_test.dart`(happy + 11 守卫)。**Phase 0 路径 drift 订正**：gauntlet 代码实际在 `lib/features/boss_gauntlet/`（非 plan 写的 `gauntlet/`）；occupancy 在 `activity/application/character_occupancy_service.dart`（非 `character/application/`）。**seed = `save.id`**（save.id 恒 0·无 serial·每关混 currentStage 归后续 combat drive 层，不在 enter 做）。**范围边界（自主判定·供复核）**：补给「类型合规」（仅疗伤丹/行囊补给可托管）**未在 kernel 强校验**——escrow 机制 item-agnostic，类型由 UI-offer 层约束（C2.5），非 corruption（close 照常返还）。
- **C2.2 落点（已实装·commit `03a44548`+`613729f4`）：** ① **快照 maxHp/maxQi 列**（`03a44548`）：`ActivityMemberSnapshot` 加 `maxHp`/`maxQi` 可加性列（无 saveVer·仿 C1.2 冷却列先例·远征留 0），`GauntletController.snapshotAfterStage` 两分支捕获 `combatant.maxHp/maxQi`（防御分支保留 prior）。**设计决策（Phase 0.5·plan 未名 maxHp 来源）**：用药按「% 最大值」恢复需 ceiling，快照原只存 currentHp/currentQi，选「存 max」（= 产出 currentHp 那场战斗的精确 max·frozen 队跨关不变）而非「useSupply 重建 BattleCharacter 取 max」（后者需 GameRepository/synergy/founderBuff/autoFill 重路径·测重且可能 drift）。② **`GauntletService.useSupply({index, targetCharacterId?})`**（`613729f4`）：单 writeTxn 只增 `escrowUsedQty[index]`（**不碰普通库存**）；疗伤丹（`gauntletHpHealPct>0`）恢目标 `round(maxHp×pct)` 钳 maxHp、行囊补给（`gauntletQiRestorePct>0`）恢全体存活 `round(maxQi×pct)` 钳 maxQi；不复活倒下者·仅 `interlude`·战斗中拒。③ **`close()`**：单 writeTxn 返还 `Loaded−Used` 到普通库存（getByDefId `+=`·行缺失据 ItemDef 重建）+ 删会话（占用解除）·无 active 幂等 no-op。`itemDefs` 构造注入（`enter` 不需·生产传 `GameRepository.instance.itemDefs`）。TDD 15 测（快照 +2·supply 13 含守恒「装入=已用+返还」）。**范围边界沿用 C2.1**：补给类型合规仍由 UI 约束（useSupply 按 ItemDef 效果字段分派·非类型白名单）。**data_schema.md 未同步**（新增 maxHp/maxQi 列·文档降级历史快照·留后续 housekeeping）。
- **C2.3 落点（已实装·commit `f8c2cc1d`+`cb0227f3`）：** ① 纯层 `GauntletController.stagePlayerTeam(baseTeam, members)`：满血基准队按会话快照装配本关出战队——首关 `member.maxHp==0`（enter 占位）→ 保满血；关次间 `maxHp>0` → `copyWith` 覆盖当前生命·真气·技能冷却；阵亡/血尽者剔除（残阵只带存活者·镜像 `ExpeditionCombatRunner`）。② `GauntletService.fightCurrentStage({config, numbers})`＝load run→`buildPlayerTeamForCharacters`→`stagePlayerTeam`→`runStage`（seed=`_stageSeed`=baseSeed×31+stage）→`advance`→**单事务原子持久化**；建队/战斗在事务外（纯计算），仅推进落原子事务——**战斗中崩溃（未落事务）→ 会话留当前关开打前态·重开重打**（§5.6 原子性即崩溃安全）。＋`continueToNextStage`（interlude→inBattle 翻相位）。③ `recover({config})`→`GauntletRecoveryOutcome`{none / resumed / refundedTicket / concedeRequired}：配置可用→resumed（不改会话·caller 按 phase 路由）；配置损坏（null/关次越界/敌队解析空）＋第一关前未开战（`hasFought`＝stage>1‖非 inBattle‖任一 maxHp>0 → false）→退帖+返还托管+删会话（`_returnEscrow` 抽出与 `close` 共用）；已开战→concedeRequired（信号交 C2.5 认输结算·不改会话不退帖）。**已跑验证（本会话 worktree 实测）**：`flutter analyze --no-pub lib/features/boss_gauntlet test/features/boss_gauntlet` 0；boss_gauntlet 全目录 **70/70**（55→+15=stagePlayerTeam 6 纯 + drive 4 e2e seedP3 生产链路 + recovery 5）。
- **C2.4 落点（已实装·commit `c98ee079`+`1e43428a`+`bc704028`）：** ① [schema] `BossGauntletConfig` 加 `firstClearRewardSkillId`/`rewardCandidateEquipmentIds`(恰3件)/`firstClearRewardExp`/`firstClearRewardInsight`；`boss_gauntlets.yaml` 补 `first_clear_reward_skill_id: skill_suo_mai_zhen` + 3 好家伙候选(占位·TODO batch3-probe) + exp300/insight20；`game_repository._enforceGauntletEnemyRedLines` 加 ⑥ 奖励引用红线(秘籍∈skills / 候选∈equipment fail-fast)。② `GauntletController.stageBossReward`(纯·进 awaitingRewardChoice 固化三选一候选 + `isFirstClearPending=!alreadyCleared`)，`fightCurrentStage` 事务内 advance 后调(`alreadyCleared`=`save.clearedGauntletIds.contains(gauntletId='duanhunzhuang')`)。③ `GauntletService.chooseReward({chosenEquipmentDefId,config,numbers,rng})` 单 writeTxn：校验(active/awaitingReward/∈候选)→发选中装备(`EquipmentFactory.fromDef` owner=null)→参战全员经验(层锁·同远征口径)+领悟点(首通全额/重复取半)→首通 inline `markUnlocked` 秘籍(避嵌套 txn)+`duanhunFirstClearedAt`→记 `clearedGauntletIds`→`_returnEscrow`+删会话；**幂等**=会话已删重入 no-op(§inv4/5)。**已跑验证**：boss_gauntlet 全目录 **86/86**(70→+16=config 4+ref红线 3+固化 pure 3+drive wiring 2+reward 4)；全仓 analyze 0；**全量 4238/0**(本条修 expedition_config_validation base() 补必填奖励字段)。**下一步 C2.5**（失败结算 §6.3 + 装载/整备 UI §7 + 2 visual_route §12.4·详本文件 Task C2.5 段）。
- **C2.4d 延后项（依赖未解除/需拍板·非偷懒）：** 命名装备保护(重复通关未培养命名装备可助炼/分解·带首破典故/battleCount>0/装备中/占用/锁定受保护/同 defId 至少留一件) + 「断魂庄首破」典故加参战主装备。**延后理由**：① 现奖励候选是好家伙占位(非专属命名装备)，保护价值待专属命名装备内容拍板后才实；② 首破典故=Equipment 实例级铭刻，现无该字段→需 Equipment schema 改 + saveVer bump + 迁移，bg 夜跑不冒无视觉验收的迁移风险。保护基于「现有信号」(equipped/reserved/isLocked/battleCount/至少留一件·无 schema)可先做，典故信号待 schema 决策。
- **已跑验证（2026-07-16 本会话 worktree 实测）：** C1.3.2 全量 `flutter test --no-pub` 4140 pass/0 fail；C1.3.3 新增 runner+advance 测 7/7 + boss_gauntlet 全目录 28/28 绿 + analyze 0 issue；`expedition_dispatch_test` 5/5 绿（证本 worktree Isar 事务测环境可用·libmdbx OK·C2.1 前置）。C1.3.3 自包含（新 runner/advance 复用现有战斗/快照，未改跨切面），未重跑全量（留 C.V 批末）。
- **已跑验证（2026-07-17 本会话 worktree 实测·C2.1）：** `gauntlet_enter_test` **12/12**；`flutter analyze --no-pub` 全仓 **0 issues**；boss_gauntlet 全目录 **40/40**（28→+12）；**全量 `flutter test --no-pub` 4192 pass / 0 fail**（phase-b 首次全量基线·含 battle-UI 合并后计数·exit 0·无 -N 失败标记）。C2.1 自包含（新增 service+test 两文件，零改跨切面），全量为回归 + 基线双用。
- **已跑验证（2026-07-17 本会话 worktree 实测·C2.2）：** `gauntlet_supply_test` **13/13** + `gauntlet_snapshot_test` **4/4**（+2）；`flutter analyze --no-pub` 全仓 **0**；boss_gauntlet 全目录 **55/55**（40→+15）；**全量 `flutter test --no-pub` 4207 pass / 0 fail**（4192+15·exit 0·无 -N）。改共享 `ActivityMemberSnapshot` schema（+maxHp/maxQi 可加性列·build_runner 重生 .g.dart·gitignored 不入 commit）故跑全量·expedition 等嵌入方零回归。
- **阻塞项：** 无（Phase A 冻结完备）。**C2.4 奖励发放前需用户拍板**：2 孤儿招（千钧坠岳/烛影摇红·`mount_deferred:true`）挂载去向——本 Phase C 计划未含（首通奖励是新招「锁脉针法」），推荐并入远征遗迹掉落做独立小批。
- **计划修订记录：** ① C1.1 测原 plan 有矛盾期望值（`applyTo(100,140)` 同时写 70 与 58），已按 design §5.2「30% 最大真气」订正为 **58**；② C1.2 `snapshotAfterStage` 签名加 `before` 入参以保留 reserved 占用冻结（plan 原单参签名会丢 reserved）；③ C1.3.2 敌队落点选 **yaml 驱动**（`enemy_teams` in boss_gauntlets.yaml + `BossGauntletConfig.enemyTeams`），用户 AskUserQuestion 拍板（plan 原留「合成参照 expedition」未定端）；④ C1.3.2 追加 **加载期引用红线**（`_enforceGauntletEnemyRedLines`·Slice C），plan step 1 未列，属 §8.2 完整性守卫补齐；⑤ **wave_b 真解配平红线排除副本奖励招** — design §6.2 单枚阴柔奖励（锁脉针法）与 wave_b 2/2/2 配平不变式冲突，判定「更新的 design spec 优先于更早的测不变式」，honor design 排除 gauntlet skillIds 出主线配平池（保留主线 6 真解 2/2/2）。**此为本会话唯一自主设计判断，供用户复核**（不认可可改为加填充招或放宽不变式）；⑥ C1.3.3：plan Task C1.3「runner 另注入 QiDrainEffect 与承伤乘子」假设过时——qi_drain 已在 C1.3.1 接进 strategy 层、承伤乘子 vuln/ward/bossPhases 已由 `buildEnemyTeam` 从 EnemyDef 灌入 `BattleCharacter`，runner 只需 `buildEnemyTeam + runNodeBattle` 无额外注入（Phase 0.5 证）。

## 自检（写完 vs 源规格）
- **Spec 覆盖：** §5.1 入场托管（C2.1）·§5.2 真气扣减（C1.1）·§5.2-5.4 三关机制（C1.3）·§4.2/5.5 跨关白名单（C1.2）·§5.6/§10 恢复（C2.3）·§6.2 命名装备+保护（C2.4）·§6.3 失败（C2.5）·§9.2 事务幂等（C2.1/2.2/2.4）·§7 UI（C2.5）·§12.2 战斗测试（C1.3）·§12.4 visual_route（C2.5）。
- **Placeholder 扫描：** C1.1 完整代码（qi_drain 是引擎新维度，全码 + schema 界）；C1.2/1.3/C2.* 给不变式 + 精确接口 + 事务边界（复用既有战斗/事务/屏体例，避免铺全码膨胀）。敌人数值占位 `TODO(batch3-probe)`。
- **类型一致：** `GauntletPhase`（A1）/托管三列表（A1）/`gauntletHpHealPct`（A2）/`RewardEntry.rewardKey` 全程一致；seed 走与 Phase B 同款显式混种。
- **红线守卫：** qi_drain ∈ (0,0.5] 硬界（C1.1 测）；承伤乘子 [0.05,1.0]（C1.3）；均减伤/资源剥夺方向不膨胀伤害（守 §5.4）。
