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
- **状态：** C1 组进行中。**C1.1** qi_drain 效果 ✅ commit `2000fd55`；**C1.2** 关次边界白名单快照 ✅ commit `17d14e5e`（`ActivityMemberSnapshot` 加冷却平行列 `skillCooldownKeys/Turns`，可加性无 saveVer 迁移、远征留空）；**C1.3.1** qi_drain 引擎接线 ✅ commit `2116db97`。C1.3.2/C1.3.3 未开工。
- **C1.3.1 落点（已实装）：** `SkillDef.qiDrainPct`（camelCase·默认 0·fromYaml 解析）；`default_ground_strategy._resolveAction` 在 targetAfters 写回后、`next` 组装前——`forcedSkill != null && skill.qiDrainPct > 0` → 对 `oppSide` 存活成员施 `QiDrainEffect`（复用 C1.1）改写 `left`/`right` + 每被夺成员一条 `EnumL10n.qiDrained` 日志（`drainActions` 并入 actionLog）；`game_repository._enforceEncounterSkillRedLines` 加 `qiDrainPct ∈ [0,0.5]` 启动 fail-fast。**测走 strategy 直驱确定性 harness**（`p0_charge_break_test` 体例·`strategy.tick(state, n, rng: Random(seed))` 手搭 mid-charge 态；memory `feedback_battle_determinism_test_via_notifier` 的 notifier.advance 适用于**种子分歧**测，本 wiring 测非此类，故未用）。
- **下一步：** C1.3 余下两子切片（TDD·建议序）：
  1. **敌队内容 3 队 `EnemyDef`**：苏无咎+2 青衣护院（灵巧·锁脉针 charge+`qiDrainPct` 0.30·破招 vulnerability 窗外 0.65）/石镇岳+2 执杖庄客（刚猛·guardianWard 0.25·全倒「铁衣破」）/闻九针（阴柔·bossPhases 三阶段 100-70 集中/70-35 逆行封脉 vuln 0.35/<35 断魂九针）。机制全走 `EnemyDef` 既有字段（bossPhases/guardianWard/vulnerability）；数值占位 `TODO(batch3-probe)`。合成参照 `expedition_combat_runner._synthesizeEnemies` → `StageBattleSetup.buildEnemyTeam`；`boss_gauntlets.yaml` enemy_team_id 已配。**⚠️ 加 skills.yaml 锁脉针招（qiDrainPct 0.30）会撞 `test/data/skill_qi_redline_test.dart:57` `hasLength(246)` 硬计数 → 同步 bump。**
  2. **`gauntlet_battle_runner` + `GauntletController.advance()`**：runner 沿 `ExpeditionBattleRunner.runNodeBattle`（`default_ground_strategy.runToEnd` + `Random(seed)`）；advance 跑当前关 → `snapshotAfterStage`（C1.2 已备）→ currentStage++/进 interlude 不自动连打；seed = `stableSeed(saveId, gauntletRunId, stage)`。
- **已跑验证（2026-07-16 本会话 worktree 实测）：** analyze `lib test` 0；qi_drain_wiring 3/3；skill_qi_redline 6/6（+guard 1）；battle+boss_gauntlet 回归 636/0；**全量 `flutter test --no-pub` 4129 pass / 0 fail**（基线 4125+4=wiring3+guard1）。
- **阻塞项：** 无（Phase A 冻结完备）。**C2.4 奖励发放前需用户拍板**：2 孤儿招（千钧坠岳/烛影摇红·`mount_deferred:true`）挂载去向——本 Phase C 计划未含（首通奖励是新招「锁脉针法」），推荐并入远征遗迹掉落做独立小批。
- **计划修订记录：** ① C1.1 测原 plan 有矛盾期望值（`applyTo(100,140)` 同时写 70 与 58），已按 design §5.2「30% 最大真气」订正为 **58**；② C1.2 `snapshotAfterStage` 签名加 `before` 入参以保留 reserved 占用冻结（plan 原单参签名会丢 reserved）。

## 自检（写完 vs 源规格）
- **Spec 覆盖：** §5.1 入场托管（C2.1）·§5.2 真气扣减（C1.1）·§5.2-5.4 三关机制（C1.3）·§4.2/5.5 跨关白名单（C1.2）·§5.6/§10 恢复（C2.3）·§6.2 命名装备+保护（C2.4）·§6.3 失败（C2.5）·§9.2 事务幂等（C2.1/2.2/2.4）·§7 UI（C2.5）·§12.2 战斗测试（C1.3）·§12.4 visual_route（C2.5）。
- **Placeholder 扫描：** C1.1 完整代码（qi_drain 是引擎新维度，全码 + schema 界）；C1.2/1.3/C2.* 给不变式 + 精确接口 + 事务边界（复用既有战斗/事务/屏体例，避免铺全码膨胀）。敌人数值占位 `TODO(batch3-probe)`。
- **类型一致：** `GauntletPhase`（A1）/托管三列表（A1）/`gauntletHpHealPct`（A2）/`RewardEntry.rewardKey` 全程一致；seed 走与 Phase B 同款显式混种。
- **红线守卫：** qi_drain ∈ (0,0.5] 硬界（C1.1 测）；承伤乘子 [0.05,1.0]（C1.3）；均减伤/资源剥夺方向不膨胀伤害（守 §5.4）。
