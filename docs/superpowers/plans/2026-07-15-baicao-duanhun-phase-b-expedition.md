# 百草岭远征 Phase B 实施计划（B1 规则/随机/节点/战斗 + B2 持久化/离线/UI）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 实装百草岭远征 `expedition` feature：整队派遣、稳定随机节点生成、headless 自动战斗、无限深入（瘴蚀终止压力）、离线分批幂等结算、随时召回/战败返程、总览与返程行记 UI——守在线=离线与第 30 节点收益封顶。

**Architecture:** 两段任务组。**B1（纯规则/领域，无 Isar/无 UI）**：稳定 seed 派生 + 节点序列生成 + 方针权重 + 节点奖励计算 + 瘴蚀衰减 + headless 战斗 wiring（复用 `BattleResolutionService.resolve`）。**B2（持久化/应用/UI）**：`ExpeditionRun`（A1 已冻结）读写、离线分批结算（settlement cursor 幂等 + 单批上限 + 分帧）、召回/战败单事务、总览/行记屏。B 只依赖 Phase A，不依赖 Phase C。

**Tech Stack:** Flutter Desktop · Isar · Riverpod 3.x · Dart · `DefaultRng(seed:)` 确定性随机 · `data/expeditions.yaml`（A2 骨架）。

**依赖：** **Phase A1/A2 完成**（`ExpeditionRun`/`ActivityMemberSnapshot`/`SaveData` 字段/`CharacterOccupancyService`/`ExpeditionConfig`+`expeditions.yaml` 骨架/断魂帖 item 均已冻结）。**下游：** 无（C 独立）；批3 联合经济探针读本 feature 产出速率。

**源规格：** baicao design §4（百草岭全节）/§9.1（数据流）/§10（异常恢复）/§12.1（领域测试）/§12.4（visual_route）＋ companion §4.3（稳定随机）/§4.4（长离线性能幂等）。

---

## 前置

```bash
flutter pub get && dart run build_runner build --delete-conflicting-outputs
git grep -n "class ExpeditionRun" lib/     # 确认 A1 已在分支
git grep -n "normal_node_minutes" data/expeditions.yaml   # 确认 A2 骨架在
```

数值填表：`data/expeditions.yaml` 的节点权重/奖励公式系数在批3 联合经济探针出快/中/慢三档后填；B 实装期用 A2 骨架 + 本计划占位初值（`# TODO(batch3-probe)` 标注，非红线，探针定案后回填）。

---

## 文件结构

| 文件 | 责任 | 组 |
|---|---|---|
| `lib/features/expedition/domain/expedition_seed.dart` | 稳定 seed 派生（§4.3/§4.7） | B1 |
| `lib/features/expedition/domain/expedition_node.dart` | 节点类型枚举 + 单节点模型 | B1 |
| `lib/features/expedition/domain/expedition_rules.dart` | 节点序列生成 + 方针权重 + 瘴蚀 + 奖励计算（纯函数） | B1 |
| `lib/features/expedition/application/expedition_battle_runner.dart` | headless 战斗（snapshot→finalState→resolve） | B1 |
| `lib/features/expedition/application/expedition_service.dart` | 派遣/召回/战败/离线分批结算（事务 + cursor） | B2 |
| `lib/features/expedition/application/expedition_providers.dart` | Riverpod provider | B2 |
| `lib/features/expedition/presentation/expedition_overview_screen.dart` | 江湖远行总览（§7.1 百草岭卡） | B2 |
| `lib/features/expedition/presentation/expedition_recap_screen.dart` | 返程行记（§4.7） | B2 |
| `data/expeditions.yaml` | 补节点权重/深度曲线/奖励表 | B1/B2 |

> 冻结命名：`ExpeditionNodeType { caiYao, feiYi, zaoYu, yiJi, xianGuan }`（采药/废驿/遭遇/遗迹/险关，§4.4）；`ExpeditionRules`（纯静态函数）；`ExpeditionService`（应用层）。

---

# ── B1：规则 / 稳定随机 / 节点 / headless 战斗 ──

## Task B1.1: 稳定 seed 派生（§4.3）

**Files:**
- Create: `lib/features/expedition/domain/expedition_seed.dart`
- Test: `test/features/expedition/expedition_seed_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/expedition/expedition_seed_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';

void main() {
  test('相同(存档,远征,节点)得相同 seed；不同输入得不同 seed', () {
    expect(ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
        ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7));
    expect(ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
        isNot(ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 8)));
    expect(ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
        isNot(ExpeditionSeed.forNode(saveId: 2, runSerial: 3, node: 7)));
  });
  test('seed 为非负 32-bit，重启稳定（显式混种，不用对象 hashCode）', () {
    final s = ExpeditionSeed.forNode(saveId: 12, runSerial: 5, node: 21);
    expect(s, greaterThanOrEqualTo(0));
    expect(s, lessThan(1 << 32));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/expedition/expedition_seed_test.dart` → 编译失败。

- [ ] **Step 3: 实现（显式整数混合，禁 Object.hashCode 作协议，§4.3）**

```dart
// lib/features/expedition/domain/expedition_seed.dart

/// 稳定随机 seed 派生（§4.3/§4.7）。**显式整数混合**，跨重启/跨平台稳定；
/// 不使用可能受运行时影响的 `Object.hashCode` 作为跨重启协议。
class ExpeditionSeed {
  const ExpeditionSeed._();

  static const int _prime1 = 0x9E3779B1; // 黄金比例散列常数
  static const int _prime2 = 0x85EBCA77;
  static const int _prime3 = 0xC2B2AE3D;
  static const int _mask32 = 0xFFFFFFFF;

  /// 节点级稳定 seed = mix(存档标识, 远征序号, 节点编号)。
  static int forNode({
    required int saveId,
    required int runSerial,
    required int node,
  }) {
    var h = 0x811C9DC5; // FNV offset basis
    h = ((h ^ (saveId & _mask32)) * _prime1) & _mask32;
    h = ((h ^ (runSerial & _mask32)) * _prime2) & _mask32;
    h = ((h ^ (node & _mask32)) * _prime3) & _mask32;
    // 末尾雪崩混合
    h ^= h >> 15;
    h = (h * _prime2) & _mask32;
    h ^= h >> 13;
    return h & _mask32;
  }
}
```

- [ ] **Step 4: 测试** → PASS。`flutter test --no-pub test/features/expedition/expedition_seed_test.dart`

- [ ] **Step 5: 提交** `git commit -m "feat: 加百草岭稳定随机seed派生"`

---

## Task B1.2: 节点模型 + 序列生成 + 方针权重（§4.2/§4.3/§4.4）

**Files:**
- Create: `lib/features/expedition/domain/expedition_node.dart`
- Create: `lib/features/expedition/domain/expedition_rules.dart`
- Test: `test/features/expedition/expedition_rules_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/expedition/expedition_rules_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';

void main() {
  test('每 5 的倍数节点为险关（精英战）', () {
    for (final n in [5, 10, 15, 20, 25, 30]) {
      expect(ExpeditionRules.isEliteNode(n), isTrue, reason: 'node $n');
    }
    for (final n in [1, 4, 7, 11, 29]) {
      expect(ExpeditionRules.isEliteNode(n), isFalse, reason: 'node $n');
    }
  });

  test('相同 saveId/runSerial/node 生成相同节点类型（稳定）', () {
    ExpeditionNode gen(int n) => ExpeditionRules.generateNode(
          saveId: 1, runSerial: 2, node: n, policy: ExpeditionPolicy.yanJingCaiYao);
    expect(gen(7).type, gen(7).type);
    // 险关恒为遭遇型险关
    expect(gen(10).type, ExpeditionNodeType.xianGuan);
  });

  test('沿径采药方针偏采药节点（权重生效，统计意义）', () {
    var caiYao = 0;
    for (var n = 1; n <= 200; n++) {
      if (n % 5 == 0) continue; // 排除险关
      if (ExpeditionRules.generateNode(
            saveId: 1, runSerial: 1, node: n,
            policy: ExpeditionPolicy.yanJingCaiYao).type ==
          ExpeditionNodeType.caiYao) caiYao++;
    }
    // 采药方针下采药占比应显著高于均分（4 类普通节点均分 25%）
    expect(caiYao / 160.0, greaterThan(0.35));
  });
}
```

- [ ] **Step 2: 跑测试确认失败** → 编译失败。

- [ ] **Step 3a: 节点模型**

```dart
// lib/features/expedition/domain/expedition_node.dart

/// 节点类型（§4.4）。险关是遭遇型的精英变体。
enum ExpeditionNodeType { caiYao, feiYi, zaoYu, yiJi, xianGuan }

/// 单个已生成节点（纯值对象；奖励在结算时按类型算，不预存）。
class ExpeditionNode {
  const ExpeditionNode({
    required this.index,
    required this.type,
    required this.durationMinutes,
  });

  final int index;
  final ExpeditionNodeType type;
  final int durationMinutes;

  bool get isBattle =>
      type == ExpeditionNodeType.zaoYu || type == ExpeditionNodeType.xianGuan;
}
```

- [ ] **Step 3b: 规则纯函数**

```dart
// lib/features/expedition/domain/expedition_rules.dart
import '../../../shared/utils/rng.dart';
import 'expedition_node.dart';
import 'expedition_run.dart' show ExpeditionPolicy;
import 'expedition_seed.dart';

/// 百草岭节点/瘴蚀/权重纯规则（§4.2-§4.5）。无 Isar、无副作用。
class ExpeditionRules {
  const ExpeditionRules._();

  /// 每 5 的倍数节点为险关（§4.2）。
  static bool isEliteNode(int node) => node > 0 && node % 5 == 0;

  /// 普通节点四类权重（方针偏移，§4.3）。险关不走此表。
  /// 权重和为正；数值填表见 expeditions.yaml（此处为规则骨架默认）。
  static Map<ExpeditionNodeType, int> _normalWeights(ExpeditionPolicy policy) {
    // 基础均衡（各 10），方针把对应类型抬到 25。
    final w = {
      ExpeditionNodeType.caiYao: 10,
      ExpeditionNodeType.feiYi: 10,
      ExpeditionNodeType.zaoYu: 10,
      ExpeditionNodeType.yiJi: 10,
    };
    switch (policy) {
      case ExpeditionPolicy.yanJingCaiYao:
        w[ExpeditionNodeType.caiYao] = 25;
      case ExpeditionPolicy.xunJiFangYou:
        w[ExpeditionNodeType.yiJi] = 25;
      case ExpeditionPolicy.yiZhanLiXing:
        w[ExpeditionNodeType.zaoYu] = 25;
    }
    return w;
  }

  /// 生成指定节点（稳定：同 saveId/runSerial/node 结果一致）。
  static ExpeditionNode generateNode({
    required int saveId,
    required int runSerial,
    required int node,
    required ExpeditionPolicy policy,
    int normalMinutes = 90,
    int eliteMinutes = 180,
  }) {
    if (isEliteNode(node)) {
      return ExpeditionNode(
          index: node,
          type: ExpeditionNodeType.xianGuan,
          durationMinutes: eliteMinutes);
    }
    final rng = DefaultRng(
        seed: ExpeditionSeed.forNode(
            saveId: saveId, runSerial: runSerial, node: node));
    final weights = _normalWeights(policy);
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = rng.nextInt(total);
    for (final e in weights.entries) {
      if (roll < e.value) {
        return ExpeditionNode(
            index: node, type: e.key, durationMinutes: normalMinutes);
      }
      roll -= e.value;
    }
    return ExpeditionNode(
        index: node,
        type: ExpeditionNodeType.caiYao,
        durationMinutes: normalMinutes);
  }

  /// 瘴蚀层数（§4.5）：第 31 节点起每 5 节点 +1 层，恢复减益 5%/层封顶 100%。
  static int zhangshiLayers(int deepestCompletedNode) {
    if (deepestCompletedNode <= 30) return 0;
    return ((deepestCompletedNode - 30) / 5).floor();
  }

  /// 瘴蚀后的恢复乘子（1.0 → 0.0，§4.5）。
  static double recoveryMultiplier(int zhangshiLayers, {double perLayer = 0.05}) {
    final reduction = (zhangshiLayers * perLayer).clamp(0.0, 1.0);
    return 1.0 - reduction;
  }
}
```

- [ ] **Step 4: 测试** → PASS。

- [ ] **Step 5: 提交** `git commit -m "feat: 加百草岭节点生成与方针权重规则"`

---

## Task B1.3: 节点奖励计算（§4.4/§6.1，纯函数）

**Files:**
- Modify: `lib/features/expedition/domain/expedition_rules.dart`（加 `rewardsForNode`）
- Test: `test/features/expedition/expedition_reward_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/expedition/expedition_reward_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';

void main() {
  test('第 10/20/30 节点固定含一张断魂帖（§4.4 里程碑）', () {
    final r = ExpeditionRules.rewardsForNode(
      node: const ExpeditionNode(
          index: 10, type: ExpeditionNodeType.xianGuan, durationMinutes: 180),
      saveId: 1, runSerial: 1,
    );
    expect(r.quantityOf('item_duanhuntie'), 1);
  });
  test('采药节点产药草/灵泉水（rewardKey 走 defId，非中文散写）', () {
    final r = ExpeditionRules.rewardsForNode(
      node: const ExpeditionNode(
          index: 1, type: ExpeditionNodeType.caiYao, durationMinutes: 90),
      saveId: 1, runSerial: 1,
    );
    expect(r.any((e) => e.rewardKey.startsWith('item_')), isTrue);
    expect(r.quantityOf('item_duanhuntie'), 0);
  });
  test('第 30 节点后单位时间奖励不再增长（§4.5 封顶）', () {
    int expAt(int node) => ExpeditionRules.rewardsForNode(
          node: ExpeditionNode(
              index: node, type: ExpeditionNodeType.zaoYu, durationMinutes: 90),
          saveId: 1, runSerial: 1,
        ).quantityOf('exp');
    expect(expAt(35), lessThanOrEqualTo(expAt(30)));
  });
}
```

- [ ] **Step 2: 跑测试确认失败** → 编译失败（无 `rewardsForNode`）。

- [ ] **Step 3: 实现 `rewardsForNode`（`expedition_rules.dart` 追加）**

```dart
  /// 固定里程碑：第 10/20/30… 节点各一张断魂帖（§4.4）。
  static bool isTicketMilestone(int node) => node > 0 && node % 10 == 0;

  /// 单节点奖励（§4.4/§6.1）。exp/材料 defId 与数量走 rewardKey；
  /// 第 30 节点后 exp 系数封顶（§4.5），deepestNode>30 不再随深度增长。
  static List<RewardEntry> rewardsForNode({
    required ExpeditionNode node,
    required int saveId,
    required int runSerial,
    int baseExpPerBattle = 200, // TODO(batch3-probe): 探针定案后回填 expeditions.yaml
    int baseExpCapNode = 30,
  }) {
    final rewards = <RewardEntry>[];
    final capNode = node.index > baseExpCapNode ? baseExpCapNode : node.index;

    switch (node.type) {
      case ExpeditionNodeType.caiYao:
        rewards.add(RewardEntry()..rewardKey = 'item_yaocao'..quantity = 1);
        rewards.add(RewardEntry()..rewardKey = 'item_lingquanshui'..quantity = 1);
      case ExpeditionNodeType.feiYi:
        rewards.add(RewardEntry()..rewardKey = 'item_silver'..quantity = 50);
      case ExpeditionNodeType.zaoYu:
      case ExpeditionNodeType.xianGuan:
        final mult = node.type == ExpeditionNodeType.xianGuan ? 3 : 1;
        rewards.add(RewardEntry()
          ..rewardKey = 'exp'
          ..quantity = baseExpPerBattle * mult * (capNode ~/ 5 + 1) ~/ 7);
      case ExpeditionNodeType.yiJi:
        rewards.add(RewardEntry()..rewardKey = 'item_silver'..quantity = 30);
    }
    if (isTicketMilestone(node.index)) {
      rewards.add(RewardEntry()..rewardKey = 'item_duanhuntie'..quantity = 1);
    }
    return rewards;
  }
```

> `item_yaocao`/`item_lingquanshui` 若 `items.yaml` 未定义，B1 顺带补 def（沿 A2 断魂帖体例，`ItemType.miscMaterial`）；奖励公式系数最终由批3 探针回填 `expeditions.yaml`，此处占位标注 `TODO(batch3-probe)`。

- [ ] **Step 4: 测试** → PASS。

- [ ] **Step 5: 提交** `git commit -m "feat: 加百草岭节点奖励计算含里程碑断魂帖"`

---

## Task B1.4: headless 节点战斗 wiring（§4.5）

**Files:**
- Create: `lib/features/expedition/application/expedition_battle_runner.dart`
- Test: `test/features/expedition/expedition_battle_runner_test.dart`

- [ ] **Step 1: 写失败测试（确定性：同 seed 同结果）**

```dart
// test/features/expedition/expedition_battle_runner_test.dart
import 'package:flutter_test/flutter_test.dart';
// ...（沿 test/support/ 战斗 fixture 构建 snapshot 队伍与敌队）
import 'package:wuxia_idle/features/expedition/application/expedition_battle_runner.dart';

void main() {
  test('同 seed 同快照 → 同战斗结果（确定性）', () {
    final r1 = ExpeditionBattleRunner.runNodeBattle(/* 见 support fixture */);
    final r2 = ExpeditionBattleRunner.runNodeBattle(/* 相同入参 */);
    expect(r1.leftWin, r2.leftWin);
    expect(r1.survivorHp, r2.survivorHp);
  });
  test('全队倒下 → leftWin=false，用于离线结算即时停止', () {
    // 用极弱快照对强敌，断言 leftWin=false
  });
}
```

> 战斗队伍/敌队 fixture 沿现有 `test/support/` 与 `stage_battle_setup.BattleCharacter.fromCharacter` 体例构建；不在测试内散写属性数值。

- [ ] **Step 2: 跑测试确认失败** → 编译失败。

- [ ] **Step 3: 实现 runner（复用现有战斗系统）**

```dart
// lib/features/expedition/application/expedition_battle_runner.dart
// 复用 default_ground_strategy tick 循环跑到 finalState，再 BattleResolutionService.resolve。
// 见 lib/features/battle/application/battle_resolution.dart（resolve 契约）
// 与 lib/features/battle/domain/strategy/default_ground_strategy.dart（tick）。

/// headless 节点战斗结果（供离线结算用）。
class ExpeditionNodeBattleResult {
  const ExpeditionNodeBattleResult({
    required this.leftWin,
    required this.survivorHp,
    required this.survivorQi,
    required this.resolution,
  });
  final bool leftWin;
  final Map<int, int> survivorHp;  // characterId → 战后当前生命
  final Map<int, int> survivorQi;  // characterId → 战后当前真气
  final Object resolution;         // BattleResolutionResult（奖励/掉落副作用汇总）
}

class ExpeditionBattleRunner {
  const ExpeditionBattleRunner._();

  /// 用出发快照 + 当前远征生命/真气 + 敌队 + 稳定 seed 跑一场自动战斗。
  /// 1) 构建 BattleState（BattleCharacter.fromCharacter，注入 snapshot HP/qi）；
  /// 2) DefaultRng(seed: nodeSeed) 驱动 default_ground_strategy tick 到 result 确定；
  /// 3) BattleResolutionService.resolve(finalState, ...) 收集修炼/掉落/伤势副作用；
  /// 4) 回读 finalState 存活者 HP/qi 写回 survivorHp/survivorQi。
  static ExpeditionNodeBattleResult runNodeBattle({
    // required BattleCharacter 队伍快照 / 敌队 def / int nodeSeed /
    // required Rng rng / NumbersConfig / lookups ...（沿 resolve 参数）
  }) {
    throw UnimplementedError('B1.4 实装：拼装 finalState + resolve，见头注 4 步');
  }
}
```

> 本步是**wiring 任务**：`runNodeBattle` 的 4 步骨架已在头注写死，实装即按 `BattleResolutionService.resolve`（`battle_resolution.dart:105` 已核签名）与 `default_ground_strategy` tick 循环拼装。战败（`finalState.result != leftWin`）在离线结算中即时停止后续节点（§4.2）。**不复用会自动跑完所有波次的群战策略**（§8.1）。

- [ ] **Step 4: 测试** → PASS（确定性 + 战败判定）。

- [ ] **Step 5: 提交** `git commit -m "feat: 加百草岭headless节点战斗wiring"`

---

# ── B2：持久化 / 离线分批结算 / 召回战败 / UI ──

## Task B2.1: 派遣入场（占用校验 + 快照 + 事务，§4.1/§9.1）

**Files:**
- Create: `lib/features/expedition/application/expedition_service.dart`
- Test: `test/features/expedition/expedition_dispatch_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/expedition/expedition_dispatch_test.dart（Isar，沿 inner_force_qi_migration 体例）
// 断言：
//  - 祖师(isFounder) 入队 → 抛错（§4.1）
//  - 已被占用角色(CharacterOccupancyService) 入队 → 抛错
//  - 成功派遣：ExpeditionRun 落库、members 含装备/心法保留 id 快照、
//    SaveData.expeditionRunSerial +1、departedAt 写入
//  - 每存档最多一条 active ExpeditionRun（再派遣抛错）
```

- [ ] **Step 2-5:** 实现 `ExpeditionService.dispatch(...)`：单 `writeTxn` 内校验占用（`CharacterOccupancyService.snapshot()`）→ 拒绝 founder/已占用/>3人 → 建 `ExpeditionRun`（`ActivityMemberSnapshot` 冻结 `equippedWeaponId/ArmorId/AccessoryId` + `mainTechniqueId` 等到 `reservedEquipmentIds`/`reservedTechniqueIds`）→ `expeditionRunSerial++` → put。提交 `feat: 加百草岭派遣入场事务`。

## Task B2.2: 离线分批幂等结算（§4.4/§9.1 — 本 feature 最难点）

**Files:**
- Modify: `lib/features/expedition/application/expedition_service.dart`
- Test: `test/features/expedition/expedition_settlement_test.dart`

- [ ] **核心不变式（测试先行断言）：**
  - **在线分段 == 一次性离线**：把 elapsed 分 N 次结算与一次结算，节点/奖励/伤势完全一致（§12.1）。
  - **幂等**：同一节点只能「未完成→完成」一次；重复结算不重复发奖。
  - **单批上限**：一次 `writeTxn` 最多结算 `maxNodesPerBatch`（配置常量，禁数十节点一事务，§4.4）；未消费 elapsed 留在会话，下批继续。
  - **settlement cursor 守卫**：事务内先校验 `lastSettledAt` 未被并发改动再提交批结果（§4.4.3）。
  - **战败即停**：headless 战斗 `leftWin=false` → 停止生成后续节点（§4.2）。
  - **时间回拨**：`max(lastSettledAt, now)`，不产生负进度（§10）。

- [ ] **实现要点：** `settle({DateTime? now})` 纯计算下一批节点（`ExpeditionRules.generateNode` + `rewardsForNode`）→ 战斗节点走 `ExpeditionBattleRunner` → 每批 `writeTxn` 内校验 cursor + 更新 `currentNode`/`members` HP-qi(节点后恢复 `recoveryMultiplier(zhangshiLayers)`)/`stagedRewards`/`lastSettledAt` → 分帧让出（每批后 UI 可展示进度）。提交 `feat: 加百草岭离线分批幂等结算`。

## Task B2.3: 召回 / 战败返程单事务（§4.6/§9.1）

- [ ] **测试断言：** 召回保留完成节点奖励、当前节点作废、不附加伤势；战败保留此前奖励、失败节点无奖励；两者均在**同一事务**发奖 + 结算伤势 + 关闭会话 + 释放角色（`ExpeditionRun` 删除，占用自动解除）；全体派遣成员（含途中倒下者）获完成节点经验（§4.6）。提交 `feat: 加百草岭召回战败返程事务`。

## Task B2.4: provider + 总览/行记 UI（§7.1/§4.7/§12.4）

**Files:**
- Create: `expedition_providers.dart` / `expedition_overview_screen.dart` / `expedition_recap_screen.dart`
- visual_route: `expedition_overview` / `expedition_active` / `expedition_recap`（沿 team_lineup 确定性 seed 体例，§12.4）

- [ ] **要点：** 总览显示队伍选择/三方针/当前深度/完成节点/下一节点剩余时间/召回；返程行记显示最深节点/完成节点/重要战斗/主要奖励/断魂帖数/伤势；入口锁定用既有气泡/百科（不新增教程弹窗，§7.1）；1280×720 与 1440×900 一屏完成主决策。加三条 visual_route（`seedExpedition*` 全态）供 Codex 目检。提交 `feat: 加江湖远行总览与返程行记UI`。

> UI 细节按项目 SOP 在实装期真机截图验收（1280×720/1440×900），本计划只钉信息架构 + visual_route，不钉像素。

---

## Task B.V: 批末验证

- [ ] `flutter analyze --no-pub lib/ test/` → 0
- [ ] targeted：`flutter test --no-pub test/features/expedition/`
- [ ] 跨切面全量（新 collection 已在 A1，但 B 接线结算/掉落，按 §8.0 跑）：`flutter test --no-pub`
- [ ] visual_route 三条 @1280×720/1440×900 截图（Codex 目检派单）
- [ ] macOS debug build

## 当前恢复点（2026-07-16 · 分支 feat/baicao-duanhun-phase-b·worktree·未 push）
- **状态：** **B1 全 4 + B2.1 派遣 + B2.2 结算（a+b）+ `settleToNow` + B2.3 返程 + B2.4a provider + §4.7 返程行记屏 完成并 commit**；A2 基建已 FF 合入本地 main `a61df363`（未 push）。**B2.4 总览屏 / settle-on-open 接线 / 主导航入口 / B.V 未开工（交互+集成·morning 真机目检 gated）**。
- **已完成（严格 TDD·各独立 commit）：**
  - B1.1-1.4 + B2.1（commit `8926be46..5dab9768`）
  - **B2.2a `settle` 状态机**（`225c98d3`）：6 不变式全测（在线分段==一次性离线/幂等/单批上限 `defaultMaxNodesPerBatch=24`/cursor 守卫/战败即停/时间回拨）。节点完成时刻按 `departedAt+累计时长`绝对锚定→推进为 `(run,now)` 确定函数。敌队经 `ExpeditionCombat`（`expedition_combat.dart`）注入 seam 解耦。
  - **B2.2b 生产战斗接线**（`6ec6a1d5`）：`ExpeditionCombatRunner`（`expedition_combat_runner.dart`）派遣成员经 `StageBattleSetup.buildPlayerTeamForCharacters`（additive 公开法·零回归）装真队 + 占位敌（`_synthesizeEnemies`·学徒阶·`TODO(batch3-probe)`）+ `ExpeditionBattleRunner`。e2e 真角色→派遣→settle 推进节点 5 真打真赢。
  - **`settleToNow`**（`37419c6e`）：循环分批 settle 至追平/战败，供 B2.4 provider 消费。
  - **B2.3 `recall({defeated})`**（`9d4668be`）：单 writeTxn 发 `stagedRewards`（全员含倒下者经验·受发布上限层锁）+ 物品入库（`ItemType.fromDefId` + `inventoryItems.getByDefId` 增量）+ 战败伤势（倒下者 `applyHeavyInjury`/其余 `accumulateLightInjury`·召回不附伤）+ 删 `ExpeditionRun`（占用自动解除）。
  - **B2.4a provider**（`4ec4a0d0`）：`expeditionServiceProvider`（isar==null→null·nullable propagation 沿 lineup 体例）+ `activeExpeditionProvider`（watch 无远征→null·写路径后 caller `ref.invalidate`）+ `ExpeditionService.activeRun()` 公开访问器。战斗协作者 `ExpeditionCombatRunner` 有跨节点缓存、按结算次新建、**不入 provider**（避陈旧缓存）。
  - **§4.7 返程行记只读屏**（`21f893fd`）：`ExpeditionRecapScreen(result:)`（`expedition/presentation/`）展示 `ExpeditionReturnResult` 的最深/完成节点·主要奖获·断魂帖里程碑高亮·伤势三态（战败绛红/负伤/安然）。照 `retreat_result_screen` 水墨体例（`LightPaperPanel`/`SectionHeader`/`PlaqueButton`）；文案入 `UiStrings` 集中 sink（守 §5.6）。visual_route `expedition_recap` + 3 widget 测 @1280×720/1440×900 断言无溢出。**「重要战斗」明细当前 result 不载**（settle 应用恢复后丢弃逐节点战斗详情）→ 待 batch3 富化 result（附战斗摘要·涉 schema）后补。
  - **节点时长曲线纯函数**（`82c47659`·为 morning 总览屏预备）：`ExpeditionRules.nodeDurationMinutes` / `cumulativeMinutesToCompleteNode` / **`nextNodeRemaining({departedAt,completedNodes,now,normalMinutes,eliteMinutes})→Duration`**（§7.1「下一节点剩余时间」直接调此·越界归零·与 settle 完成节点判定同曲线绝对锚定）。settle `_completedNodesBy` 改用 `nodeDurationMinutes` DRY（behavior-preserving·8 settle 测回归绿）。7 新单测。**morning 总览屏「下一节点剩余」= 调 `nextNodeRemaining(run.departedAt, run.currentNode, now, config.normalNodeMinutes, config.eliteNodeMinutes)`，勿再手写。**
- **已跑验证（本会话 worktree 实测）：** `flutter analyze --no-pub lib test` 0；**全量 `flutter test --no-pub` 4075 pass/0 fail**（4071 基线 +provider1 +recap3）+ 后续 timing 7 测（`ExpeditionRules` 消费面 grep 证仅 expedition 内、blast radius 全含·expedition 全族复跑 45/0 已认证）→ 全项目现 **4082**；`stage_battle_setup_test` 35 回归绿；debug visual_route 32 测绿（新 `expedition_recap` id 往返通过）。macOS build **本环境不能跑**（仅 CommandLineTools·`xcodebuild` 缺）→ morning。
- **关键决策（B2.4 必读）：**
  - provider 需注入 `ExpeditionCombatRunner(isar)` + `GameRepository.instance.expeditionConfig!`；结算入口走 `settleToNow`，召回/战败走 `recall(defeated:)`（战败由 `settleToNow().defeated` 触发）。
  - 战败无持久 flag（可复现）；exp 全员各得；敌队/伤势深度曲线占位待 batch3 探针。
  - **异步 config race**（`feedback_flutter_async_config_race_controller_final`）：provider 装 config 别在构造期定死 null，didUpdateWidget/watch 透传。
- **下一步（morning·keystone=总览屏）：** ① **B2.4 总览屏 `ExpeditionOverviewScreen`**（§7.1·派遣态[队伍+方针选]+active 态[深度/完成/下一节点剩余/召回]两态·dispatch/recall 唯一玩家入口=此簇 keystone·**async-config-race**：读 config/combat 在动作时新建、别构造期定死 null）；② **离线追平 settle-on-open 接线**（**架构已探明**：镜像 `main_menu_startup_gate.dart` 的 `maybeRunSectMonthlyTick`，post-frame `unawaited(maybeSettleExpedition(ref))`；核心可抽 `settleActiveExpeditionOnOpen(service,isar,config)` 纯 dep 便单测；走 startup-gate **非** 屏 initState）；③ 主导航「江湖远行」入口；④ 2 visual_route（`expedition_overview/active`·seed 沿 team_lineup 体例）；⑤ B.V macOS build + Codex 真机 @1280×720/1440×900 目检两屏。**未先建 action controller**——总览屏未定形前抽 controller = speculative abstraction（`feedback_avoid_over_engineer_abstraction`），随屏共设。
- **阻塞项：** 无（backend/provider/recap 已全绿 unblocked；余总览屏交互+集成需 morning 真机验收，本环境缺全 Xcode）。

## 自检（写完 vs 源规格）
- **Spec 覆盖：** §4.1 派遣/占用（B2.1）·§4.2-4.4 节点/方针/里程碑（B1.2/1.3）·§4.5 瘴蚀/封顶/恢复（B1.2/1.3/2.2）·§4.6 召回战败（B2.3）·§4.7 稳定随机/行记（B1.1/B2.4）·§9.1 事务（B2.1/2.2/2.3）·§10 时间回拨（B2.2）·§12.1 在线=离线（B2.2）·§12.4 visual_route（B2.4）。
- **Placeholder 扫描：** B1.1/1.2/1.3 完整代码；B1.4 runner 头注写死 4 步骨架（wiring 任务，`UnimplementedError` 显式标注非隐藏 TODO）；B2.1-2.4 给不变式 + 实现要点 + 精确接口（较 B1 高一档，因纯持久化/UI wiring 复用既有事务/屏体例，避免与 C 重复铺全码）。数值占位统一 `TODO(batch3-probe)`。
- **类型一致：** `ExpeditionPolicy`（A1 冻结）/`ExpeditionNodeType`/`RewardEntry.rewardKey` 全程一致；seed 全走 `ExpeditionSeed.forNode`。
