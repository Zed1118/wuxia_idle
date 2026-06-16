# M6 心魔失败惩罚 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 GDD §12.1 设计、配置已就绪但零 wire 的心魔关战败惩罚（内力 ×0.85 / 主修 ×0.9 + 余毒 debuff）接入战斗结算与存档。

**Architecture:** 惩罚纯逻辑落 `InnerDemonService.applyFailurePenalty`（in-place 改 Character/Technique，沿 `DispelService.applyDefeatPenalty` 体例但**不回退层**）；在 `BattleResolutionService.resolve` 战败+心魔关分支调用（与 Boss 散功天然互斥）；余毒持久到 `Character.innerDemonResidueHoursRemaining`，战斗输出 ×0.95 走新增 `BattleCharacter.outputMultiplier` 末端乘，闭关内力产出 ×0.80 + 满 8h 清走 `SeclusionService`。

**Tech Stack:** Dart / Flutter / Riverpod 3 / Isar（@collection 加字段需 `dart run build_runner build`）。

**已读实接入点（worktree HEAD 基线，行号供定位、以实际为准）：**
- 配置类 `lib/features/inner_demon/domain/inner_demon_def.dart`（`InnerDemonFailurePenalty` L152-189 / `InnerDemonResidueDebuff` L191-212 / `InnerDemonDef.empty` L48-68 / `fromYaml` L70-115）
- numbers.yaml `inner_demon.failure_penalty` / `residue_debuff`（约 L564-599）
- 结算 `lib/features/battle/application/battle_resolution.dart`（`resolve` L95，Boss 散功分支 L168-188，`BattleResolutionResult` L20-66）
- 散功模型参照 `lib/features/dispel/application/dispel_service.dart`（`applyDefeatPenalty` L198，`DefeatPenaltyResult`）
- `lib/core/domain/character.dart`（字段区 L24-25 / `Character.create` L118-197）
- `lib/core/domain/technique.dart`（`cultivationProgress`/`cultivationLayer`/`cultivationProgressToNext` L30-33）
- 快照 `lib/features/battle/domain/battle_state.dart`（`BattleCharacter` 字段+`attackPowerMultiplier` L146/L193，ctor L166-200，`fromCharacter` L213，`copyWith` L359-427）
- 伤害末端 `lib/features/battle/domain/damage_calculator.dart`（`calculateResolved` L99，末端乘式 L193-200）
- 玩家队构造 `lib/features/battle/application/stage_battle_setup.dart`（`fromCharacter` 调用 L227-235）
- 闭关 `lib/features/seclusion/application/seclusion_service.dart`（`computeOutputs` L175，`internalForcePoints` L228-238，`completeRetreat` L265，writeTxn 内 `ch` 改 L336-343）
- 战败持久化+损失摘要 `lib/features/mainline/presentation/stage_entry_flow.dart`（defeat resolve L835-847，writeTxn putAll L850-858，`DefeatLossEntry` 构造 L860-889）

> **环境前置（fresh worktree，[[feedback_wuxia_pen_build_runner]] / [[feedback_fresh_worktree_libisar_dylib]]）：**
> 首次跑测前：`dart run build_runner build --delete-conflicting-outputs`；若 `libisar.dylib` 截断致 dlopen 失败，从主仓 `/Users/a10506/Desktop/Projects/挂机武侠/` 拷完整 dylib。

---

### Task 1: numbers.yaml 内力地板系数 + 配置字段

**Files:**
- Modify: `data/numbers.yaml`（`inner_demon.failure_penalty` 段）
- Modify: `lib/features/inner_demon/domain/inner_demon_def.dart`（`InnerDemonFailurePenalty`）
- Test: `test/features/inner_demon/domain/inner_demon_def_test.dart`（若无则新建）

- [ ] **Step 1: 写失败测试**

在测试文件加：

```dart
test('InnerDemonFailurePenalty.fromYaml 解析 internal_force_floor_pct', () {
  final p = InnerDemonFailurePenalty.fromYaml({
    'internal_force_multiplier': 0.85,
    'internal_force_floor_pct': 0.50,
  });
  expect(p.internalForceFloorPct, 0.50);
});

test('InnerDemonFailurePenalty.fromYaml 缺字段默认 0.50', () {
  final p = InnerDemonFailurePenalty.fromYaml({});
  expect(p.internalForceFloorPct, 0.50);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inner_demon/domain/inner_demon_def_test.dart`
Expected: FAIL — `internalForceFloorPct` getter 未定义。

- [ ] **Step 3: 加字段**

`InnerDemonFailurePenalty` 类加 final 字段 + ctor required + `empty()`(L55-61) 补 `internalForceFloorPct: 0.50,` + `fromYaml` 解析：

```dart
  /// 内力扣减地板（new 内力不低于 internalForceMax × 此值；防无限重试归零）。
  final double internalForceFloorPct;
```
ctor 加 `required this.internalForceFloorPct,`；fromYaml 加：
```dart
        internalForceFloorPct:
            (y['internal_force_floor_pct'] as num?)?.toDouble() ?? 0.50,
```

`data/numbers.yaml` `inner_demon.failure_penalty` 段加（在 `internal_force_multiplier` 行后）：
```yaml
    internal_force_floor_pct: 0.50   # 内力扣减地板=internalForceMax×0.50(M6 防无限重试归零)
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inner_demon/domain/inner_demon_def_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add data/numbers.yaml lib/features/inner_demon/domain/inner_demon_def.dart test/features/inner_demon/domain/inner_demon_def_test.dart
git commit -m "feat(M6): 心魔失败惩罚内力地板系数 internal_force_floor_pct"
```

---

### Task 2: Character 余毒持久字段 + build_runner

**Files:**
- Modify: `lib/core/domain/character.dart`（字段 + `Character.create`）
- Regenerate: `lib/core/domain/character.g.dart`（build_runner）
- Test: `test/core/domain/character_test.dart`（若无则新建）

- [ ] **Step 1: 写失败测试**

```dart
test('Character 默认 innerDemonResidueHoursRemaining = 0', () {
  final c = Character.create(
    name: '测试', realmTier: RealmTier.xueTu, realmLayer: RealmLayer.qiMeng,
    attributes: Attributes.balanced(), rarity: RarityTier.common,
    lineageRole: LineageRole.founder, createdAt: DateTime(2026),
  );
  expect(c.innerDemonResidueHoursRemaining, 0);
});
```
（`Attributes.balanced()` / enum 值按实际 fixture 调整；目的只是构造一个 Character。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/domain/character_test.dart`
Expected: FAIL — getter 未定义。

- [ ] **Step 3: 加字段 + create 参数**

`character.dart` 字段区（`int internalForceMax = 500;` 附近）加：
```dart
  /// 心魔余毒剩余清除所需闭关时长(小时;0=无余毒)。M6 心魔关战败时设为
  /// failure_penalty.debuff_clear_via_retreat_hours(=8);闭关收功累减 actualHours,
  /// 归 0 即清。在身时:战斗输出 ×residue_debuff.battle_output_multiplier +
  /// 闭关内力产出 ×internal_force_recovery_multiplier。
  double innerDemonResidueHoursRemaining = 0;
```
`Character.create` 加可选参 `double innerDemonResidueHoursRemaining = 0,` + 级联 `..innerDemonResidueHoursRemaining = innerDemonResidueHoursRemaining`。

- [ ] **Step 4: 重生成 + 跑测试**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/core/domain/character_test.dart`
Expected: PASS（旧档加载新字段默认 0 由 Isar 保证，无迁移）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/domain/character.dart lib/core/domain/character.g.dart test/core/domain/character_test.dart
git commit -m "feat(M6): Character 加心魔余毒持久字段 innerDemonResidueHoursRemaining"
```

---

### Task 3: 惩罚纯逻辑 InnerDemonService.applyFailurePenalty

**Files:**
- Modify: `lib/features/inner_demon/application/inner_demon_service.dart`（加结果类 + 静态方法）
- Test: `test/features/inner_demon/application/inner_demon_failure_penalty_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

```dart
// 构造一个 Character(internalForce, internalForceMax) + 主修 Technique
// (cultivationLayer, cultivationProgress)。配置用 InnerDemonDef.empty().failurePenalty +
// residueDebuff(0.85/0.90/floor 0.50/8h)。
test('内力 ×0.85 但不低于 internalForceMax×0.50 地板', () {
  final ch = _char(internalForce: 1000, internalForceMax: 1000);
  final tech = _mainTech(layer: CultivationLayer.daCheng, progress: 200);
  final r = InnerDemonService.applyFailurePenalty(
    ch: ch, mainTech: tech, penalty: _penalty, residueHours: 8);
  expect(ch.internalForce, 850);            // 1000×0.85=850 > floor 500
  expect(r.internalForceAfter, 850);
});

test('内力低于地板时 clamp 到 internalForceMax×0.50', () {
  final ch = _char(internalForce: 520, internalForceMax: 1000);
  final tech = _mainTech(layer: CultivationLayer.daCheng, progress: 200);
  InnerDemonService.applyFailurePenalty(
    ch: ch, mainTech: tech, penalty: _penalty, residueHours: 8);
  expect(ch.internalForce, 500);            // 520×0.85=442 < floor 500 → 500
});

test('主修 progress ×0.90 且 layer 不回退', () {
  final ch = _char(internalForce: 1000, internalForceMax: 1000);
  final tech = _mainTech(layer: CultivationLayer.daCheng, progress: 200);
  InnerDemonService.applyFailurePenalty(
    ch: ch, mainTech: tech, penalty: _penalty, residueHours: 8);
  expect(tech.cultivationProgress, 180);    // 200×0.9
  expect(tech.cultivationLayer, CultivationLayer.daCheng);  // 不掉层
});

test('余毒 hours 设到 residueHours', () {
  final ch = _char(internalForce: 1000, internalForceMax: 1000);
  InnerDemonService.applyFailurePenalty(
    ch: ch, mainTech: _mainTech(layer: CultivationLayer.daCheng, progress: 200),
    penalty: _penalty, residueHours: 8);
  expect(ch.innerDemonResidueHoursRemaining, 8.0);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inner_demon/application/inner_demon_failure_penalty_test.dart`
Expected: FAIL — `applyFailurePenalty` / `InnerDemonPenaltyResult` 未定义。

- [ ] **Step 3: 实现**

`inner_demon_service.dart` import `Character` + `Technique`（`../../../core/domain/character.dart` / `technique.dart`），加：

```dart
/// 心魔关战败惩罚结果（in-place 改 ch.internalForce + mainTech.cultivationProgress
/// 已发生，此处汇总供 UI 展示 / 测试断言）。与 DispelService.DefeatPenaltyResult
/// 区别：心魔惩罚 layer 不回退（spec「不跌破当前层起点」自动满足）。
class InnerDemonPenaltyResult {
  final int internalForceBefore;
  final int internalForceAfter;
  final int progressBefore;
  final int progressAfter;
  final double residueHoursApplied;
  const InnerDemonPenaltyResult({
    required this.internalForceBefore,
    required this.internalForceAfter,
    required this.progressBefore,
    required this.progressAfter,
    required this.residueHoursApplied,
  });
}
```

`InnerDemonService` 加静态方法：

```dart
  /// 心魔关战败惩罚（M6）。对单个**有主修**的参战角色调用一次。
  ///
  /// in-place 改：
  ///   - ch.internalForce = max(floor(old × internalForceMultiplier),
  ///                            floor(internalForceMax × internalForceFloorPct))
  ///   - mainTech.cultivationProgress = floor(old × mainCultivationMultiplier)
  ///     （cultivationLayer / cultivationProgressToNext 不动 → 不跌破当前层起点）
  ///   - ch.innerDemonResidueHoursRemaining = residueHours（再败刷新，不叠加）
  ///   - 辅修不动（subCultivationMultiplier=1.00，不触碰辅修字段）
  ///
  /// Isar 持久化由 caller 负责（沿 DispelService.applyDefeatPenalty 体例）。
  static InnerDemonPenaltyResult applyFailurePenalty({
    required Character ch,
    required Technique mainTech,
    required InnerDemonFailurePenalty penalty,
    required double residueHours,
  }) {
    final ifBefore = ch.internalForce;
    final progressBefore = mainTech.cultivationProgress;

    final floor = (ch.internalForceMax * penalty.internalForceFloorPct).floor();
    final scaled = (ch.internalForce * penalty.internalForceMultiplier).floor();
    ch.internalForce = scaled < floor ? floor : scaled;

    mainTech.cultivationProgress =
        (mainTech.cultivationProgress * penalty.mainCultivationMultiplier).floor();

    ch.innerDemonResidueHoursRemaining = residueHours;

    return InnerDemonPenaltyResult(
      internalForceBefore: ifBefore,
      internalForceAfter: ch.internalForce,
      progressBefore: progressBefore,
      progressAfter: mainTech.cultivationProgress,
      residueHoursApplied: residueHours,
    );
  }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inner_demon/application/inner_demon_failure_penalty_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/inner_demon/application/inner_demon_service.dart test/features/inner_demon/application/inner_demon_failure_penalty_test.dart
git commit -m "feat(M6): 心魔失败惩罚纯逻辑 applyFailurePenalty(内力地板+主修floor不掉层+余毒)"
```

---

### Task 4: 接入 BattleResolutionService.resolve

**Files:**
- Modify: `lib/features/battle/application/battle_resolution.dart`
- Test: `test/features/battle/application/battle_resolution_inner_demon_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

构造 finalState（玩家战败）+ 心魔关 `StageDef`（`stageType == StageType.innerDemon`，`isBossStage=false`）+ 参战角色（有主修）。断言：

```dart
test('心魔关战败施加心魔惩罚 + 余毒', () {
  final result = BattleResolutionService.resolve(
    finalState: lostState, participatingCharacters: [ch],
    equipmentsByCharacter: {ch.id: []}, techniquesByCharacter: {ch.id: [mainTech]},
    rng: SeededRng(1), progressToNextMap: progressMap,
    techniqueDefLookup: lookup, dropService: dropSvc,
    stageDef: innerDemonStage, isVictory: false, numbersConfig: numbers);
  expect(result.innerDemonPenaltyByCharacter[ch.id], isNotNull);
  expect(result.defeatPenaltyByCharacter, isEmpty);    // 非 Boss 关，散功不触发
  expect(ch.innerDemonResidueHoursRemaining, greaterThan(0));
});

test('心魔关胜利不施加惩罚', () {
  final result = BattleResolutionService.resolve(/* ...isVictory: true... */);
  expect(result.innerDemonPenaltyByCharacter, isEmpty);
});

test('普通关战败不施加心魔惩罚', () {
  final result = BattleResolutionService.resolve(/* ...普通 stageType, isVictory: false... */);
  expect(result.innerDemonPenaltyByCharacter, isEmpty);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/application/battle_resolution_inner_demon_test.dart`
Expected: FAIL — `innerDemonPenaltyByCharacter` 未定义。

- [ ] **Step 3: 实现**

`battle_resolution.dart`：
1. import `../../inner_demon/application/inner_demon_service.dart`。
2. `BattleResolutionResult` 加字段 + ctor 默认空 map：
```dart
  /// M6:心魔关战败时每个有主修参战角色的惩罚结果。胜利/非心魔关恒空 map。
  final Map<int, InnerDemonPenaltyResult> innerDemonPenaltyByCharacter;
```
ctor 加 `this.innerDemonPenaltyByCharacter = const {},`。
3. `resolve` 内，Boss 散功分支（L168-188）**之后**加并列分支（心魔关 `isBossStage=false`，两路天然互斥）：
```dart
    // M6:心魔关战败 → 对每个有主修参战角色应用心魔失败惩罚 + 余毒。
    // 与 Boss 散功互斥(心魔关 isBossStage=false)。stageDef=null(tower) 不进。
    final innerDemonPenalty = <int, InnerDemonPenaltyResult>{};
    if (!isVictory &&
        stageDef != null &&
        stageDef.stageType == StageType.innerDemon &&
        numbersConfig != null) {
      final idDef = numbersConfig.innerDemon;
      for (final ch in participatingCharacters) {
        final mainTechId = ch.mainTechniqueId;
        if (mainTechId == null) continue;
        final techs = techniquesByCharacter[ch.id] ?? const <Technique>[];
        final mainTech = _findById(techs, mainTechId);
        if (mainTech == null) continue;
        innerDemonPenalty[ch.id] = InnerDemonService.applyFailurePenalty(
          ch: ch,
          mainTech: mainTech,
          penalty: idDef.failurePenalty,
          residueHours: idDef.failurePenalty.debuffClearViaRetreatHours.toDouble(),
        );
      }
    }
```
4. return 加 `innerDemonPenaltyByCharacter: innerDemonPenalty,`。
5. `toString()`（L60-65）可选追加 `innerDemon=${innerDemonPenaltyByCharacter.length}`。

> 注：`numbersConfig.innerDemon` 即 `InnerDemonDef`，确认 `NumbersConfig` 暴露 `innerDemon` getter（stage_battle_setup L57 已用 `GameRepository.instance.numbers.innerDemon`，存在）。`StageType` 已在 `battle_resolution.dart` 可见（经 stage_def import）；若未 import 则补 enums import。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/application/battle_resolution_inner_demon_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/application/battle_resolution.dart test/features/battle/application/battle_resolution_inner_demon_test.dart
git commit -m "feat(M6): resolve 战败心魔关分支调心魔惩罚(与Boss散功互斥)"
```

---

### Task 5: BattleCharacter.outputMultiplier + 伤害末端乘

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`（字段 + ctor + copyWith + fromCharacter）
- Modify: `lib/features/battle/domain/damage_calculator.dart`（calculateResolved 参数 + 末端乘）
- Test: `test/features/battle/domain/damage_calculator_output_multiplier_test.dart`（新建）

> **设计注**：不复用 `attackPowerMultiplier` —— 它是 SET 语义（恩怨/地形/群战互斥各自 `copyWith(set)`，battle_providers L217/L226、light_foot/mass strategy），余毒折进去会被覆盖。新增独立 `outputMultiplier`（默认 1.0、可乘性组合）。

- [ ] **Step 1: 写失败测试**

```dart
test('outputMultiplier 0.95 使最终伤害降 5%', () {
  final ctxFull = /* AttackContext, outputMultiplier 不传(默认1.0) */;
  final full = DamageCalculator.calculateResolved(/* ...outputMultiplier: 1.0... */, numbers);
  final reduced = DamageCalculator.calculateResolved(/* 同参 ...outputMultiplier: 0.95... */, numbers);
  expect(reduced.finalDamage, (full.mainDamage * 0.95).toInt() + full.quakeDamage);
});
```
（震伤是固定加值不被 outputMultiplier 乘 —— 沿 quakeDamage 不进 raw 乘式的体例。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/domain/damage_calculator_output_multiplier_test.dart`
Expected: FAIL — `outputMultiplier` 命名参数未定义。

- [ ] **Step 3: 实现**

`battle_state.dart`：
- 字段（仿 `attackPowerMultiplier` L146）：
```dart
  /// M6 心魔余毒:战斗输出乘数(默认 1.0=无)。余毒在身玩家角色 stage_battle_setup
  /// 设为 residue_debuff.battle_output_multiplier(0.95)。独立末端乘,可乘性组合
  /// (不与 attackPowerMultiplier 的 SET 语义冲突)。damage_calculator 末端乘 mainDamage。
  final double outputMultiplier;
```
- ctor 加 `this.outputMultiplier = 1.0,`（L193 附近）。
- `copyWith`：参数列表加 `double? outputMultiplier,`，构造体加 `outputMultiplier: outputMultiplier ?? this.outputMultiplier,`。
- `fromCharacter` 加可选参 `double outputMultiplier = 1.0,`，构造返回的 `BattleCharacter` 传 `outputMultiplier: outputMultiplier`（fromCharacter 末尾 return 处）。

`damage_calculator.dart` `calculateResolved`（L99）：
- 加命名参 `double outputMultiplier = 1.0,`。
- 末端乘式（L193-200）追加 `* outputMultiplier`：
```dart
    final raw = base * cultMult * schoolMult * effectiveCritMult * defMult *
        realmMult * attackPowerMultiplier * proficiencyDamageMult * outputMultiplier;
```
- `calculate`（L39，Character adapter）调 `calculateResolved` 处透传 `outputMultiplier: ctx.attacker.outputMultiplier`（若 AttackContext 持 BattleCharacter；否则在 default_ground_strategy L583-596 调用处传 `attacker.outputMultiplier`，与 `attackPowerMultiplier: attacker.attackPowerMultiplier` 同行加）。
- breakdown 字符串可选追加 `${outputMultiplier != 1.0 ? ' * ${_fmt(outputMultiplier)}(余毒)' : ''}`。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/domain/damage_calculator_output_multiplier_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/battle_state.dart lib/features/battle/domain/damage_calculator.dart test/features/battle/domain/damage_calculator_output_multiplier_test.dart
git commit -m "feat(M6): BattleCharacter.outputMultiplier + 伤害末端乘(余毒战斗输出0.95)"
```

---

### Task 6: stage_battle_setup 余毒注入战斗快照

**Files:**
- Modify: `lib/features/battle/application/stage_battle_setup.dart`（玩家队构造，fromCharacter L227-235）
- Test: `test/features/battle/application/stage_battle_setup_residue_test.dart`（新建，或并入既有 setup 测）

- [ ] **Step 1: 写失败测试**

构造余毒在身（`innerDemonResidueHoursRemaining > 0`）的 Character → 走玩家队构造 → 断言对应 `BattleCharacter.outputMultiplier == 0.95`；无余毒 → `1.0`。
（若 `_buildPlayerCharacter` 私有难直接测，则测公开入口 `buildTeams` 返回的 left 队 outputMultiplier。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/application/stage_battle_setup_residue_test.dart`
Expected: FAIL — outputMultiplier 仍 1.0。

- [ ] **Step 3: 实现**

玩家角色构造处（`fromCharacter` 调用 L227 前）加：
```dart
    final residueMult = character.innerDemonResidueHoursRemaining > 0
        ? GameRepository.instance.numbers.innerDemon.residueDebuff
            .battleOutputMultiplier
        : 1.0;
```
`fromCharacter(...)` 调用加参 `outputMultiplier: residueMult,`。
（`applySynergy` 的 `copyWith` 不传 outputMultiplier → 经 `?? this.outputMultiplier` 自动保留，无需改。）

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/application/stage_battle_setup_residue_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/application/stage_battle_setup.dart test/features/battle/application/stage_battle_setup_residue_test.dart
git commit -m "feat(M6): 余毒在身玩家角色战斗快照 outputMultiplier=0.95"
```

---

### Task 7: 闭关余毒——内力产出 ×0.80 + 满 8h 清

**Files:**
- Modify: `lib/features/seclusion/application/seclusion_service.dart`（`computeOutputs` + `completeRetreat`）
- Test: `test/features/seclusion/seclusion_residue_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

```dart
test('余毒在身闭关内力产出 ×0.80', () {
  final base = SeclusionService.computeOutputs(/* ...无余毒... */);
  final reduced = SeclusionService.computeOutputs(/* 同参 ...residueInternalForceMultiplier: 0.80... */);
  expect(reduced.internalForcePoints, (base.internalForcePoints * 0.80).floor());
});

// completeRetreat 集成测(走 Isar fixture)：
test('闭关收功累减余毒 hours，满 8h 清', () async {
  // ch.innerDemonResidueHoursRemaining = 5; 闭关 actualHours=3 → 剩 2
  // 再闭关 actualHours=3 → 剩 0(clamp，满 8h 累计)
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/seclusion/seclusion_residue_test.dart`
Expected: FAIL — `residueInternalForceMultiplier` 参数未定义。

- [ ] **Step 3: 实现**

`computeOutputs`（L175）加命名参 `double residueInternalForceMultiplier = 1.0,`；`internalForcePoints` 乘式（L228-238）追加 `* residueInternalForceMultiplier`（在 `.floor()` 前）。

`completeRetreat`（L265）：
- writeTxn 前已读 `preCharForBonus`（L277）。据其 `innerDemonResidueHoursRemaining > 0` 算 `residueMult`：
```dart
    final residueMult = (preCharForBonus?.innerDemonResidueHoursRemaining ?? 0) > 0
        ? GameRepository.instance.numbers.innerDemon.residueDebuff
            .internalForceRecoveryMultiplier
        : 1.0;
```
- `computeOutputs(...)` 调用（L285-294）加 `residueInternalForceMultiplier: residueMult,`。
- writeTxn 内 `ch` 改区（L336-343，与 internalForce 同块）加余毒累减：
```dart
        if (ch.innerDemonResidueHoursRemaining > 0) {
          final left = ch.innerDemonResidueHoursRemaining - outputs.actualHours;
          ch.innerDemonResidueHoursRemaining = left < 0 ? 0 : left;
        }
```
（`ch` 在该块后被 `isar.characters.put(ch)` 写回 —— 确认 put 在块尾；若该路径无 put 而靠外层 putAll，则同 stage_entry_flow 自动持久化。）

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/seclusion/seclusion_residue_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/seclusion/application/seclusion_service.dart test/features/seclusion/seclusion_residue_test.dart
git commit -m "feat(M6): 闭关余毒内力产出×0.80 + 累计满8h清"
```

---

### Task 8: 战败损失摘要展示心魔惩罚

**Files:**
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`（defeat 损失摘要 L860-889）
- Test: 既有 defeat 摘要测扩展 / 新建 `test/features/mainline/inner_demon_defeat_summary_test.dart`

> **持久化已免费**：心魔惩罚 in-place 改 `characters`/`techsByCh`，战败 writeTxn `putAll`（L850-858）自动写回。本任务只补 UI 摘要。

- [ ] **Step 1: 写失败测试**

断言：心魔关战败后，损失摘要 entries 含该角色的内力 before/after（且 `didRollback=false`，无层变化），并标记余毒。
（`DefeatLossEntry` 现有 `internalForceBefore/After` + layer 字段；为余毒加一个 `bool residueApplied` 可选字段，默认 false，不破现有 Boss 散功 entry。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/mainline/inner_demon_defeat_summary_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现**

`DefeatLossEntry` 加 `final bool residueApplied;`（ctor 默认 `false`）。损失摘要构造循环（L862-888）后追加心魔惩罚 entries：
```dart
  for (final ch in characters) {
    final ip = result.innerDemonPenaltyByCharacter[ch.id];
    if (ip == null) continue;
    final mainTech = /* 同 L865-871 取 mainTech */;
    String? techName = /* 同 L872-879 */;
    entries.add(DefeatLossEntry(
      characterName: ch.name,
      internalForceBefore: ip.internalForceBefore,
      internalForceAfter: ip.internalForceAfter,
      techniqueName: techName,
      oldLayerLabel: null,        // 心魔惩罚不掉层
      newLayerLabel: null,
      layersRolledBack: 0,
      residueApplied: true,
    ));
  }
```
若摘要 UI（VictoryOverlay/败北页 widget）需展示余毒文案，文案进 `UiStrings`（§5.6，禁散写中文），如 `UiStrings.innerDemonResidueNote`。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/mainline/inner_demon_defeat_summary_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/mainline/presentation/stage_entry_flow.dart lib/shared/strings.dart test/features/mainline/inner_demon_defeat_summary_test.dart
git commit -m "feat(M6): 战败损失摘要展示心魔惩罚+余毒"
```

---

### Task 9: 红线复评 + 全量验证

**Files:**
- Test: 全量

- [ ] **Step 1: 红线测**

Run: `flutter test test/balance/inner_demon_r5_redline_test.dart test/balance/full_build_damage_redline_test.dart`
Expected: PASS（outputMultiplier ≤ 1.0 只降不升，余毒不放大伤害；惩罚只降内力/主修）。

- [ ] **Step 2: check-redlines（16 红线测）**

Run: `flutter test test/data/p1a_redline_test.dart`（及 §5.4 相关红线测族）
Expected: PASS，无回归。

- [ ] **Step 3: 全量 analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: 全量测试**

Run: `flutter test`
Expected: 全过，净增长 = 新增测数（基线 2247 +1 skip）。

- [ ] **Step 5: 提交（若有收尾改动）**

```bash
git commit -am "test(M6): 红线复评 + 全量验证零回归" --allow-empty
```

---

## Self-Review

**Spec coverage：** A 触发点→Task4；B 数值惩罚→Task1(地板系数)+Task3(逻辑)+Task4(接入)；C 余毒：存档→Task2，战斗输出0.95→Task5+Task6，闭关内力0.80+清→Task7；D 测试→各 Task TDD + Task9 红线；UI 展示→Task8。**全覆盖。**

**类型一致：** `InnerDemonPenaltyResult`（Task3 定义 / Task4 用）；`applyFailurePenalty`（Task3 定义 / Task4 调）；`outputMultiplier`（Task5 定义 / Task6 设 / damage_calculator 用）；`residueInternalForceMultiplier`（Task7 computeOutputs 参）；`innerDemonResidueHoursRemaining`（Task2 字段 / Task3 设 / Task6 读 / Task7 减）；`internalForceFloorPct`（Task1 字段 / Task3 用）；`residueApplied`（Task8 字段）。**一致。**

**Placeholder 扫描：** 测试 fixture 构造（`_char`/`_mainTech`/enum 值）按实际 API 调整属正常 TDD 写测，非 placeholder；所有新代码块完整给出。

**待执行期校验（非阻塞，实现时确认）：**
- `NumbersConfig.innerDemon` getter 存在（stage_battle_setup L57 已用，确认）。
- `StageType` enum 在 battle_resolution 可见（经 stage_def import；不可见则补 enums import）。
- `damage_calculator.calculate` → `calculateResolved` 的 attacker 是否持 `outputMultiplier`：若 AttackContext 不持 BattleCharacter，则在 `default_ground_strategy` 调用点（L583-596）与 `attackPowerMultiplier` 同处传 `attacker.outputMultiplier`。
- completeRetreat 内 `ch` 写回 put 位置（确认在余毒累减块之后）。
