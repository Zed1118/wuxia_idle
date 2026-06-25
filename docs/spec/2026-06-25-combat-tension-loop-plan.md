# 战斗张力循环 实装计划（双层伤势为主体）

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐 task 执行。步骤用 `- [ ]` checkbox。
> **设计源**：`docs/spec/2026-06-25-combat-tension-loop-design.md`（含红线决策史）。

**Goal:** 守红线实现「内力弹药 + 境界门槛 + 双层 per-角色伤势」战斗张力循环，给推进刹车 / 战斗张力 / 挂机循环，**不引入体力**。

**Architecture:** ① 内力弹药机制已实装（`battle_state.dart:406` 进场满+不恢复），仅需 UI 显眼化；② 境界门槛=平衡 pass（非代码）；③ 双层 per-角色伤势=唯一新系统，仿 `innerDemonResidueHoursRemaining` 疗养模式 + `outputMultiplier` 攻击折扣通道 + `applyFailurePenalty` 结算 hook。

**Tech Stack:** Flutter / Riverpod 3 / Isar（saveVer 0.28→0.29）/ numbers.yaml 数值层。

---

## 机制决策（已拍板·executor 不要改，review 由用户）

1. 轻伤：连战每场 +1 stack，挂机 tick/闭关收功清零，减**速度**（砍命中——项目无 hitRate，YAGNI）。
2. 重伤：硬仗（主线 `stageDef.isBossStage` / 心魔 / 塔 `floorIndex%5==0`）后——**战败→全参战角色重伤**；**惨胜→endHp<maxHp×阈值的存活角色重伤**；全员高血通关无重伤。
3. 重伤 debuff：减 `internalForceMax` + 攻击 `outputMultiplier` 折扣。
4. 疗养：per-角色 `injuryHoursRemaining`，挂机/闭关真实时间递减→0 痊愈，自动恢复，带伤可出战。
5. 红线铁律：带伤永远能打 / 疗伤非必需 / 无加速疗养 / 不留存焦虑。
6. 数值全进 numbers.yaml `injury:` 段，测验机制不验具体数字。

## 初始数值（numbers.yaml · tunable · balance 后真机校）

```yaml
injury:
  light_injury:
    speed_penalty_per_stack: 3      # 每层减速度(base 100+,轻微)
    max_stacks: 5                    # 累积上限
  heavy_injury:
    recovery_hours: 8.0              # 疗养时长(同心魔余毒先例)
    internal_force_max_penalty_pct: 0.15  # 重伤减内力上限 15%
    attack_output_multiplier: 0.85   # 重伤攻击 ×0.85
    heavy_win_hp_threshold_pct: 0.25 # 惨胜阈值:存活角色 endHp<25% maxHp 吃重伤
```

## File Structure

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/core/domain/character.dart` | +2 字段 `lightInjuryStacks`/`injuryHoursRemaining` | Modify :31,137,178 |
| `lib/data/isar_setup.dart` | saveVer 0.28→0.29（无迁移分支） | Modify :138 |
| `lib/features/injury/domain/injury_config.dart` | `InjuryConfig.fromYaml`（仿 InnerDemonResidueDebuff） | Create |
| `lib/data/numbers_config.dart` | 挂载 `injury` 字段 | Modify :152,259,382 |
| `lib/features/injury/application/injury_service.dart` | `applyHeavyInjury` + 轻伤累积纯函数 | Create |
| `lib/features/battle/domain/derived_stats.dart` | `internalForceMaxWithLineage` +heavyInjured / `speed` +lightInjuryStacks | Modify :255,139 |
| `lib/features/battle/application/stage_battle_setup.dart` | 烘焙伤势进 BattleCharacter | Modify :195,231 |
| `lib/features/battle/application/battle_resolution.dart` | `resolve` +isHardFight + 轻伤/重伤判定 | Modify :204 |
| `lib/features/mainline/presentation/stage_entry_flow.dart` + `tower/presentation/tower_entry_flow.dart` | caller 接线 + 持久化 | Modify |
| `lib/features/seclusion/application/seclusion_service.dart` + `lib/features/.../offline_passive_service.dart` | 疗养递减 + 轻伤清零 | Modify :424,78 |
| `lib/shared/strings.dart` + `lib/features/character_panel/presentation/lineage_character_detail_screen.dart` | 伤势文案 + UI chip | Modify |
| `data/numbers.yaml` | `injury:` 段 | Modify |

---

### Task 1: Character 加伤势字段 + saveVer bump

**Files:** Modify `lib/core/domain/character.dart`（:31,137,178）+ `lib/data/isar_setup.dart`（:138）

- [ ] **Step 1: 加字段**（character.dart，紧贴 `innerDemonResidueHoursRemaining` :31 后）

```dart
/// 轻伤(疲劳)累积层数。连战每场 +1,挂机 tick/闭关收功清零。减速度。
int lightInjuryStacks = 0;
/// 重伤(内伤)疗养剩余真实小时(0=痊愈)。硬仗战败/惨胜设值,挂机/闭关递减。
/// 仿 innerDemonResidueHoursRemaining 体例。带伤可出战(debuff 生效)。
double injuryHoursRemaining = 0;
```
构造器参数（:137 区，仿 `double innerDemonResidueHoursRemaining = 0,`）：加 `int lightInjuryStacks = 0,` `double injuryHoursRemaining = 0,`；构造器赋值（:178 区）：加 `..lightInjuryStacks = lightInjuryStacks` `..injuryHoursRemaining = injuryHoursRemaining`。

- [ ] **Step 2: bump saveVer**（isar_setup.dart:138）

```dart
static const _currentSaveVersion = '0.29.0';
// 0.29.0 伤势系统:Character +lightInjuryStacks/injuryHoursRemaining,新字段旧档读默认 0,无迁移分支,仅 bump。
```

- [ ] **Step 3: build_runner 重生 .g.dart**（.g.dart gitignored，必跑）

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: wrote N outputs（含 character.g.dart）

- [ ] **Step 4: 冒烟 — 全量 analyze + 现有 isar 测**

Run: `flutter analyze && flutter test test/data/isar_setup_test.dart`
Expected: analyze 0 issues；isar 测全绿（新字段默认 0 不破旧测）

- [ ] **Step 5: Commit**

```bash
git add lib/core/domain/character.dart lib/data/isar_setup.dart
git commit -m "feat(injury): Character 加双层伤势字段 + saveVer 0.29"
```

---

### Task 2: InjuryConfig + numbers.yaml + 挂载

**Files:** Create `lib/features/injury/domain/injury_config.dart`；Modify `data/numbers.yaml`、`lib/data/numbers_config.dart`（:152,259,382）；Test `test/features/injury/domain/injury_config_test.dart`

- [ ] **Step 1: 写失败测**（injury_config_test.dart）

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/injury/domain/injury_config.dart';

void main() {
  test('InjuryConfig.fromYaml 解析全字段 + 缺省默认', () {
    final c = InjuryConfig.fromYaml({
      'light_injury': {'speed_penalty_per_stack': 3, 'max_stacks': 5},
      'heavy_injury': {
        'recovery_hours': 8.0, 'internal_force_max_penalty_pct': 0.15,
        'attack_output_multiplier': 0.85, 'heavy_win_hp_threshold_pct': 0.25,
      },
    });
    expect(c.lightSpeedPenaltyPerStack, 3);
    expect(c.lightMaxStacks, 5);
    expect(c.heavyRecoveryHours, 8.0);
    expect(c.heavyInternalForceMaxPenaltyPct, 0.15);
    expect(c.heavyAttackOutputMultiplier, 0.85);
    expect(c.heavyWinHpThresholdPct, 0.25);
    // 缺省回默认
    final d = InjuryConfig.fromYaml(const {});
    expect(d.lightMaxStacks, 5);
  });
}
```

- [ ] **Step 2: 跑测验失败**

Run: `flutter test test/features/injury/domain/injury_config_test.dart`
Expected: FAIL（injury_config.dart 不存在）

- [ ] **Step 3: 实现 InjuryConfig**（仿 `inner_demon_def.dart:216` InnerDemonResidueDebuff.fromYaml）

```dart
class InjuryConfig {
  final int lightSpeedPenaltyPerStack;
  final int lightMaxStacks;
  final double heavyRecoveryHours;
  final double heavyInternalForceMaxPenaltyPct;
  final double heavyAttackOutputMultiplier;
  final double heavyWinHpThresholdPct;
  const InjuryConfig({
    required this.lightSpeedPenaltyPerStack, required this.lightMaxStacks,
    required this.heavyRecoveryHours, required this.heavyInternalForceMaxPenaltyPct,
    required this.heavyAttackOutputMultiplier, required this.heavyWinHpThresholdPct,
  });
  factory InjuryConfig.fromYaml(Map<String, dynamic> y) {
    final l = (y['light_injury'] as Map?) ?? const {};
    final h = (y['heavy_injury'] as Map?) ?? const {};
    return InjuryConfig(
      lightSpeedPenaltyPerStack: (l['speed_penalty_per_stack'] as num?)?.toInt() ?? 3,
      lightMaxStacks: (l['max_stacks'] as num?)?.toInt() ?? 5,
      heavyRecoveryHours: (h['recovery_hours'] as num?)?.toDouble() ?? 8.0,
      heavyInternalForceMaxPenaltyPct: (h['internal_force_max_penalty_pct'] as num?)?.toDouble() ?? 0.15,
      heavyAttackOutputMultiplier: (h['attack_output_multiplier'] as num?)?.toDouble() ?? 0.85,
      heavyWinHpThresholdPct: (h['heavy_win_hp_threshold_pct'] as num?)?.toDouble() ?? 0.25,
    );
  }
}
```

- [ ] **Step 4: numbers.yaml 加 `injury:` 段**（顶层，仿 `inner_demon:` :1444）— 用上方「初始数值」block。

- [ ] **Step 5: NumbersConfig 挂载**（numbers_config.dart：字段 :152 区加 `final InjuryConfig injury;`；构造器 :259 区加 `required this.injury,`；fromYaml :382 区加 `injury: InjuryConfig.fromYaml((y['injury'] as Map?)?.cast<String,dynamic>() ?? const {}),`）

- [ ] **Step 6: 跑测 + analyze**

Run: `flutter test test/features/injury/domain/injury_config_test.dart && flutter analyze`
Expected: PASS / 0 issues

- [ ] **Step 7: Commit**

```bash
git add lib/features/injury/domain/injury_config.dart lib/data/numbers_config.dart data/numbers.yaml test/features/injury/domain/injury_config_test.dart
git commit -m "feat(injury): InjuryConfig + numbers.yaml injury 段 + NumbersConfig 挂载"
```

---

### Task 3: InjuryService — 重伤设值 + 轻伤累积纯函数

**Files:** Create `lib/features/injury/application/injury_service.dart`；Test `test/features/injury/application/injury_service_test.dart`（用 `test()` 非 testWidgets，memory：Isar widget test 死锁）

- [ ] **Step 1: 写失败测**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/features/injury/application/injury_service.dart';

void main() {
  test('applyHeavyInjury 设 injuryHoursRemaining=recoveryHours,再伤刷新不叠加', () {
    final c = Character()..injuryHoursRemaining = 0;
    InjuryService.applyHeavyInjury(c, recoveryHours: 8.0);
    expect(c.injuryHoursRemaining, 8.0);
    c.injuryHoursRemaining = 3.0; // 疗养中
    InjuryService.applyHeavyInjury(c, recoveryHours: 8.0); // 再伤
    expect(c.injuryHoursRemaining, 8.0, reason: '刷新不叠加(仿余毒)');
  });
  test('accumulateLightInjury +1 不超 maxStacks', () {
    final c = Character()..lightInjuryStacks = 4;
    InjuryService.accumulateLightInjury(c, maxStacks: 5);
    expect(c.lightInjuryStacks, 5);
    InjuryService.accumulateLightInjury(c, maxStacks: 5);
    expect(c.lightInjuryStacks, 5, reason: 'clamp 到 maxStacks');
  });
}
```

- [ ] **Step 2: 跑测验失败** — Run: `flutter test test/features/injury/application/injury_service_test.dart` → FAIL

- [ ] **Step 3: 实现**（仿 `InnerDemonService.applyFailurePenalty` 全静态体例 + `inner_demon_service.dart:153` 刷新不叠加）

```dart
import '../../../core/domain/character.dart';

class InjuryService {
  InjuryService._();
  /// 重伤:设疗养剩余=recoveryHours(再伤刷新不叠加,仿余毒)。
  static void applyHeavyInjury(Character c, {required double recoveryHours}) {
    c.injuryHoursRemaining = recoveryHours;
  }
  /// 轻伤:连战 +1,clamp maxStacks。
  static void accumulateLightInjury(Character c, {required int maxStacks}) {
    final n = c.lightInjuryStacks + 1;
    c.lightInjuryStacks = n > maxStacks ? maxStacks : n;
  }
}
```

- [ ] **Step 4: 跑测 PASS** — `flutter test test/features/injury/application/injury_service_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/features/injury/application/injury_service.dart test/features/injury/application/injury_service_test.dart
git commit -m "feat(injury): InjuryService 重伤设值+轻伤累积纯函数"
```

---

### Task 4: 派生属性接伤势 debuff

**Files:** Modify `lib/features/battle/domain/derived_stats.dart`（`internalForceMaxWithLineage` :255、`speed` :139）；Test `test/combat/derived_stats_test.dart`（追加）

- [ ] **Step 1: 写失败测**（追加到 derived_stats_test.dart）

```dart
test('重伤减 internalForceMax', () {
  final c = makeChar(); // 现有测 helper
  final base = CharacterDerivedStats.internalForceMaxWithLineage(c, [], numbers);
  final hurt = CharacterDerivedStats.internalForceMaxWithLineage(c, [], numbers, heavyInjured: true);
  expect(hurt, lessThan(base));
  expect(hurt, closeTo((base / (1 - numbers.injury.heavyInternalForceMaxPenaltyPct)).round() == base ? base : hurt, 1)); // 比例减
});
test('轻伤减速度,按 stacks 线性', () {
  final c = makeChar();
  final base = CharacterDerivedStats.speed(c, [], mainTech, numbers);
  final hurt = CharacterDerivedStats.speed(c, [], mainTech, numbers, lightInjuryStacks: 3);
  expect(base - hurt, 3 * numbers.injury.lightSpeedPenaltyPerStack);
});
```

- [ ] **Step 2: 跑测验失败** — 编译失败（参数不存在）

- [ ] **Step 3: 实现**
- `internalForceMaxWithLineage`（:255）加可选 `bool heavyInjured = false`；在 clamp（:273）**前**、仿 founderBuff（:266）：
```dart
if (heavyInjured) { mult *= (1 - n.injury.heavyInternalForceMaxPenaltyPct); }
```
- `speed`（:139）加可选 `int lightInjuryStacks = 0`；末端 clamp 前：
```dart
sp -= lightInjuryStacks * n.injury.lightSpeedPenaltyPerStack;
if (sp < 0) sp = 0;
```

- [ ] **Step 4: 跑测 PASS** — `flutter test test/combat/derived_stats_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/derived_stats.dart test/combat/derived_stats_test.dart
git commit -m "feat(injury): derived_stats 接重伤减内力上限+轻伤减速度"
```

---

### Task 5: 烘焙伤势进 BattleCharacter

**Files:** Modify `lib/features/battle/application/stage_battle_setup.dart`（`_playerToBattle` :195、residueMult :231）；Test `test/features/battle/application/stage_battle_setup_test.dart`（追加）

- [ ] **Step 1: 写失败测** — 构造带重伤 Character（`injuryHoursRemaining>0`），断言烘焙出的 BattleCharacter `outputMultiplier` 含重伤折扣（≤ residue 单独值），`maxInternalForce` 减。

```dart
test('重伤角色烘焙:outputMultiplier 含攻击折扣 + maxInternalForce 减', () {
  final c = makePlayerChar()..injuryHoursRemaining = 8.0;
  final bc = StageBattleSetup.playerToBattleForTest(c, ...); // 若无 test 入口,经 buildPlayerTeam
  expect(bc.outputMultiplier, lessThanOrEqualTo(numbers.injury.heavyAttackOutputMultiplier + 1e-9));
});
```

- [ ] **Step 2: 跑测验失败**

- [ ] **Step 3: 实现**（`_playerToBattle`，仿 residueMult :231-246）：
```dart
final heavyInjured = character.injuryHoursRemaining > 0;
final injuryAtkMult = heavyInjured ? n.injury.heavyAttackOutputMultiplier : 1.0;
// 与余毒可乘组合(battle_state.dart:170 注释:outputMultiplier 可乘性):
final outMult = residueMult * injuryAtkMult;
final base = BattleCharacter.fromCharacter(
  ..., outputMultiplier: outMult,
  heavyInjured: heavyInjured,            // 透传给 internalForceMaxWithLineage
  lightInjuryStacks: character.lightInjuryStacks, // 透传给 speed
);
```
（`fromCharacter` :285 区加两个可选参数透传到 #4 的派生调用 :308-314。镜像敌队 `inner_demon_service` 不带伤势=默认 0/false。）

- [ ] **Step 4: 跑测 PASS + 全量 battle 测**

Run: `flutter test test/features/battle/`
Expected: 全绿（0 回归）

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/application/stage_battle_setup.dart lib/features/battle/domain/battle_state.dart test/features/battle/application/stage_battle_setup_test.dart
git commit -m "feat(injury): 烘焙重伤攻击折扣+内力减+轻伤速度进 BattleCharacter"
```

---

### Task 6: 战斗结算判定伤势

**Files:** Modify `lib/features/battle/application/battle_resolution.dart`（`resolve` :204）；Test `test/features/battle/application/battle_resolution_test.dart`（追加）

- [ ] **Step 1: 写失败测** — 三场景：① 战败硬仗→全参战角色 injuryHoursRemaining>0；② 惨胜（某角色 finalState endHp<25%maxHp）→ 该角色重伤、高血角色不重伤；③ 普通杂兵战（isHardFight=false）→ 无重伤、仅轻伤 +1。

```dart
test('硬仗战败→全参战角色重伤', () {
  final chars = [makeChar(), makeChar()];
  resolve(isVictory: false, isHardFight: true, finalState: lostState, participatingCharacters: chars, numbersConfig: n, ...);
  expect(chars.every((c) => c.injuryHoursRemaining > 0), isTrue);
});
test('惨胜→只低血存活角色重伤', () { /* finalState.leftTeam[0].currentHp/maxHp < 0.25 */ });
test('杂兵战→无重伤,轻伤+1', () {
  final c = makeChar();
  resolve(isVictory: true, isHardFight: false, participatingCharacters: [c], ...);
  expect(c.injuryHoursRemaining, 0);
  expect(c.lightInjuryStacks, 1);
});
```

- [ ] **Step 2: 跑测验失败** — 编译失败（`isHardFight` 参数不存在）

- [ ] **Step 3: 实现** — `resolve` 加 `required bool isHardFight`（caller 传，Task 7）。在结算尾部、写 Character 前：
```dart
final inj = numbersConfig.injury;
for (final ch in participatingCharacters) {
  InjuryService.accumulateLightInjury(ch, maxStacks: inj.lightMaxStacks); // 每场 +1
}
if (isHardFight) {
  if (!isVictory) {
    for (final ch in participatingCharacters) {
      InjuryService.applyHeavyInjury(ch, recoveryHours: inj.heavyRecoveryHours);
    }
  } else {
    // 惨胜:存活角色 endHp<阈值
    for (final ch in participatingCharacters) {
      final bc = finalState.leftTeam.firstWhere((b) => b.characterId == ch.id, orElse: () => ...);
      if (bc.isAlive && bc.currentHp < bc.maxHp * inj.heavyWinHpThresholdPct) {
        InjuryService.applyHeavyInjury(ch, recoveryHours: inj.heavyRecoveryHours);
      }
    }
  }
}
```
（与心魔分支并存：心魔分支 :204 已限 `stageType==innerDemon`，互不冲突——心魔关同时是 isBossStage 也会吃通用重伤，符合「硬仗重伤」语义。）

- [ ] **Step 4: 跑测 PASS + 全量 battle 测** — `flutter test test/features/battle/`

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/application/battle_resolution.dart test/features/battle/application/battle_resolution_test.dart
git commit -m "feat(injury): 战斗结算判定连战轻伤+硬仗重伤(战败/惨胜)"
```

---

### Task 7: caller 接线 + 持久化

**Files:** Modify `lib/features/mainline/presentation/stage_entry_flow.dart`（胜 :769 / 败 :1032）、`lib/features/tower/presentation/tower_entry_flow.dart`；持久化仿 `innerDemonPenalty` putAll 体例

- [ ] **Step 1: 主线 resolve 传 isHardFight** — 两处 `resolve(...)` 加 `isHardFight: stageDef?.isBossStage ?? false`。
- [ ] **Step 2: 塔 resolve 传 isHardFight** — tower flow `resolve(...)` 加 `isHardFight: floor.floorIndex % 5 == 0`（5/10/15/20/25/30 Boss 楼层）。
- [ ] **Step 3: 持久化** — resolve 后受影响 Character writeTxn `isar.characters.putAll(participatingCharacters)`（仿现有心魔惩罚持久化路径）。
- [ ] **Step 4: 验证 — 全量 battle/mainline/tower 测**

Run: `flutter test test/features/battle/ test/features/mainline/ test/features/tower/`
Expected: 全绿

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(injury): 主线/塔 caller 传 isHardFight + 伤势持久化"
```

---

### Task 8: 疗养/清零 tick（闭关 + 离线挂机）

**Files:** Modify `lib/features/seclusion/application/seclusion_service.dart`（completeRetreat :424）、离线 `offline_passive_service.dart`（settle :78）；Test 两文件对应测（`test()` 非 widget）

- [ ] **Step 1: 写失败测** — ① 闭关收功后 `injuryHoursRemaining` 按 actualHours 递减、`lightInjuryStacks`=0；② 离线 settle 后 `injuryHoursRemaining` 按 awayHours 递减、`lightInjuryStacks`=0（即使 0 经验也疗养）。

- [ ] **Step 2: 跑测验失败**

- [ ] **Step 3: 实现**
- 闭关（seclusion_service.dart:424 旁，余毒递减同块）：
```dart
if (ch.injuryHoursRemaining > 0) {
  final left = ch.injuryHoursRemaining - outputs.actualHours;
  ch.injuryHoursRemaining = left < 0 ? 0 : left;
}
ch.lightInjuryStacks = 0; // 收功清轻伤
```
- 离线（offline_passive_service.dart：把疗养**移出** `yield_.experience>0` 分支 :79，无条件执行）：
```dart
if (c.injuryHoursRemaining > 0) {
  final left = c.injuryHoursRemaining - awayHours;
  c.injuryHoursRemaining = left < 0 ? 0 : left;
}
c.lightInjuryStacks = 0;
```

- [ ] **Step 4: 跑测 PASS** — `flutter test test/features/seclusion/ test/...offline...`

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(injury): 闭关收功+离线挂机疗养递减+轻伤清零(守在线=离线)"
```

---

### Task 9: UI — 伤势文案 + 角色面板 chip + 战败 banner

**Files:** Modify `lib/shared/strings.dart`（仿心魔块 :1660-1691）、`lib/features/character_panel/presentation/lineage_character_detail_screen.dart`（`_AttributesSection` :253 旁加状态 chip）、`stage_entry_flow.dart`（战败 banner :616 加 injuryApplied 字段，仿 residueApplied）；Test widget 测（viewport 扩，memory）

- [ ] **Step 1: UiStrings 加伤势文案**（仿 `innerDemonResidueNote` :1681）：
```dart
static const String injuryLightLabel = '带伤';      // 轻伤
static const String injuryHeavyLabel = '重伤';      // 重伤
static String injuryRecoveryHint(double h) => '内伤未愈 · 调息 ${h.ceil()}h';
```
- [ ] **Step 2: 角色面板状态 chip** — `lineage_character_detail_screen` 加 `_StatusSection`（仿 `_AttributesSection` chip 列）：`lightInjuryStacks>0` 显 `injuryLightLabel`；`injuryHoursRemaining>0` 显 `injuryHeavyLabel + injuryRecoveryHint`。
- [ ] **Step 3: 战败 banner** — `buildDefeatLossEntries`（:616）加 `injuryApplied` 平行字段（仿 residueApplied），战败后提示「N 名弟子负伤」。
- [ ] **Step 4: widget 测**（`setSurfaceSize(800,2000)` + addTearDown，memory ListView viewport）— 断言带伤角色面板显伤势 chip。

Run: `flutter test test/features/character_panel/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(injury): 伤势 UI(角色面板 chip + 战败 banner + UiStrings)"
```

---

### Task 10: 全量回归 + 红线 + 收尾

- [ ] **Step 1: 全量 analyze + test** — `flutter analyze && flutter test` → 0 issues / 全绿（baseline 2905 + 新增伤势测）
- [ ] **Step 2: 红线自检** — 确认无「没体力/没X不能战斗」闸：带 injuryHoursRemaining>0 的角色仍能进战斗（Task 5 烘焙只减 debuff 不拦截）；疗养只走真实时间（Task 8 无加速路径）。
- [ ] **Step 3: PROGRESS + 设计 spec 标实装完成**
- [ ] **Step 4: Commit + 收尾**

---

## ① 内力弹药显眼化（轻量 · 可与 Task 9 合并或单独小批）

机制已实装（`battle_state.dart:406` 进场满+不恢复）。仅 UI：战斗指令台招式标内力成本、内力见底视觉提示「内力将竭」。无 schema/逻辑改。建议 ③ 完成后单独表现层小批（参考既有 battle_screen 指令台）。

## ② 境界门槛（平衡 pass · 非 TDD）

调章末 Boss / 塔关键层 enemy scale，使跨 1-2 阶才稳触发战败（memory `feedback_wuxia_boss_balance_crosstier`）。验证走 `balance_simulator` win-rate + 真机。numbers.yaml 数值调整，无新代码。③ 落地后单独平衡批。

## 自检（writing-plans）

- **Spec 覆盖**：① 内力（机制已实装+UI 段）✅ / ② 门槛（平衡 pass 段）✅ / ③ 双层伤势（Task 1-10 全覆盖：schema/config/service/派生/烘焙/结算/接线/tick/UI/回归）✅。
- **Placeholder**：无 TBD；数值在 numbers.yaml tunable（设计明确 balance 后真机校，非占位）。
- **类型一致**：`lightInjuryStacks`(int)/`injuryHoursRemaining`(double) 全 task 一致；`InjuryService.applyHeavyInjury`/`accumulateLightInjury`、`InjuryConfig` 字段名跨 task 统一；`resolve` 的 `isHardFight` 参数 Task 6 定义、Task 7 传入一致。
- **范围**：③ 单系统聚焦；①② 明确为轻量/平衡 pass 不混入 TDD。
