# 百草岭／断魂庄 Phase A2 实施计划 — 发布上限、断魂帖、副本内效果与配置校验

> 📋 计划态存档 · 本文是实施前的计划,文中路径与文件名为**当时的规划意图**,以实际落地为准;`lib/` 路径的新旧对照见 `docs/PATH_MIGRATION_MAP.md`。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Phase A1 冻结的持久化基础上，把发布上限从绝对层 10（Lv100）提到 17（Lv170）、写存量溢出连跳探针、加断魂帖凭证道具与两份补给的副本内效果字段、并建立 `data/expeditions.yaml`／`data/boss_gauntlets.yaml` 的加载与 fail-fast 校验骨架——供 Phase B/C 填充数值与内容。

**Architecture:** 配置 + 校验为主，**无玩法屏、无战斗逻辑**。发布上限只改 yaml 一个数 + 同步测试断言；溢出探针是诊断测（沿 `test/support/progression_battle_probe.dart` 体例）；配置类为纯 Dart（非 Isar，可后续自由扩展），A2 只落**校验不变式 + 加载接线 + 最小合法骨架**，B/C 各自填真实节点/敌人/奖励表。

**Tech Stack:** Flutter Desktop · Isar · Dart · YAML（`data/*.yaml` + `_loadOptionalAsset` + `_validate*` fail-fast 体例）。

**依赖：** **Phase A1 完成**（`ExpeditionRun`/`BossGauntletRun`/`SaveData` 字段/0.37 已冻结）。**下游：** Phase B 填 `expeditions.yaml` 节点/奖励表、Phase C 填 `boss_gauntlets.yaml` 敌人/机制表；批3 联合经济探针扩展本阶段溢出探针。

**源规格：** baicao design §3.1（存量溢出）／§5.1（补给副本内效果）／§6.4（断魂帖）／§8.2（配置与校验）＋ companion §4.1 A2。

---

## 前置

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # A1 新 collection 的 .g.dart
```

确认 A1 已合入本分支：`git grep -n "_currentSaveVersion = '0.37.0'" lib/data/isar_setup.dart` 有命中；`lib/features/expedition/domain/expedition_run.dart` 存在。

---

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `data/numbers.yaml:206` | 发布上限值 10→17 | Modify |
| `test/data/numbers_config_progression_release_cap_test.dart` | 上限断言 10→17 | Modify |
| `test/tools/overflow_layer_jump_probe_test.dart` | 存量溢出连跳分布诊断 | Create |
| `lib/core/domain/enums.dart:337` | `ItemType` 加 `ticket` + `fromDefId` case | Modify |
| `data/items.yaml` | 断魂帖 def + 两补给副本内效果字段 | Modify |
| `lib/data/defs/item_def.dart` | 副本内效果字段解析 | Modify |
| `lib/data/defs/expedition_config.dart` | 远征配置 def + fromYaml | Create |
| `lib/data/defs/boss_gauntlet_config.dart` | 断魂庄配置 def + fromYaml | Create |
| `data/expeditions.yaml` / `data/boss_gauntlets.yaml` | 最小合法骨架（B/C 填真数据） | Create |
| `lib/data/game_repository.dart` | 加载接线 + 两 `_validate*` | Modify（`:172` loadAllDefs / `:415` _loadOptionalAsset 体例 / `:449` 校验区 / `:512` _validate 体例） |

---

## Task 1: 发布上限 10→17

**Files:**
- Modify: `data/numbers.yaml:206`
- Modify: `test/data/numbers_config_progression_release_cap_test.dart`（`'current release ends at absolute realm layer 10'` 用例）

- [ ] **Step 1: 改测试断言（先红）**

`test/data/numbers_config_progression_release_cap_test.dart` 中断言当前发布上限的用例，标题与期望值 10→17：

```dart
    test('current release ends at absolute realm layer 17', () {
      expect(
        GameRepository
            .instance
            .numbers
            .progressionReleaseCap
            .maxAbsoluteRealmLevel,
        17,
      );
```

（上方 `defaults to all 49...` 与 `rejects values outside...` 两个用例**不动**——17 仍在 [1,49] 合法区间。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/data/numbers_config_progression_release_cap_test.dart`
Expected: 失败——生产值仍 10，断言期望 17。

- [ ] **Step 3: 改 numbers.yaml**

`data/numbers.yaml:206`：

```yaml
    max_absolute_realm_level: 17
```

- [ ] **Step 4: 跑测试 + 上界红线测（放宽·非破坏）**

Run:
```bash
flutter test --no-pub \
  test/data/numbers_config_progression_release_cap_test.dart \
  test/data/mainline_stage_curve_redline_test.dart \
  test/balance/inner_demon_r5_redline_test.dart
```
Expected: 全 PASS（后两者断言敌人绝对层 `≤ cap`，cap 由 10 放宽到 17，现有敌人 ≤Lv100 仍满足）。

- [ ] **Step 5: 提交**

```bash
git add data/numbers.yaml test/data/numbers_config_progression_release_cap_test.dart
git commit -m "[balance] 发布上限提至绝对层17对应Lv170"
```

---

## Task 2: 存量溢出连跳探针（§3.1）

> 目的：实测「封顶期继续累加的存量经验」在上限 10→17 时的连跳层数分布，为「一次性兑现（默认）vs 分段抬升（10→13→17）」提供数据。诊断测，非玩法代码；沿 `test/support/progression_battle_probe.dart` 体例，用 `loadTestGameRepository`。

**Files:**
- Create: `test/tools/overflow_layer_jump_probe_test.dart`

- [ ] **Step 1: 写探针**

```dart
// test/tools/overflow_layer_jump_probe_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';

import '../support/test_data.dart';

/// 给定绝对层 cap，返回「越过 cap 的层视为锁定」的判定（沿 progression_gate 体例）。
bool Function(RealmTier, RealmLayer) _lockAtCap(int cap, GameRepository repo) {
  return (t, l) => repo.getRealm(t, l).absoluteLevel > cap;
}

void main() {
  setUpAll(loadTestGameRepository);

  test('存量溢出连跳分布（cap 10→17）', () {
    final repo = GameRepository.instance;
    realmLookup(RealmTier t, RealmLayer l) => repo.getRealm(t, l);

    // 典型封顶档：停在 Lv100（绝对层 10 顶层），持有 N 倍「层均经验」的溢出存量。
    // 层均经验取当前层 experienceToNext 作单位，扫 1×~12× 覆盖短挂机到长挂机。
    final buffer = StringBuffer('overflow× | 连跳层数(cap17)\n');
    var worstJump = 0;
    for (final mult in const [1, 2, 4, 6, 8, 12]) {
      final ch = buildCappedFounderAtLv100(); // test_data helper：绝对层10顶
      final unit = realmLookup(ch.realmTier, ch.realmLayer).experienceToNext;
      final res = CharacterAdvancementService.applyExperience(
        ch,
        unit * mult,
        realmLookup: realmLookup,
        isLayerLocked: _lockAtCap(17, repo),
      );
      buffer.writeln('${mult}x | ${res.layersGained}');
      if (res.layersGained > worstJump) worstJump = res.layersGained;
    }
    // 输出分布供人工拍板（一次性 vs 分段）。
    // ignore: avoid_print
    print(buffer.toString());

    // Ratchet：典型档一次性兑现连跳应可接受（§3.1 约 ≤4 层量级）。若此断言未来
    // 因经济改动被顶破，说明溢出直逼 Lv170，需按 §3.1 降级为分段抬升 10→13→17。
    expect(worstJump, lessThanOrEqualTo(7),
        reason: '存量溢出连跳过大→改分段抬升，勿直接放宽此阈值');
  });
}
```

> `buildCappedFounderAtLv100()` 若 `test/support/test_data.dart` 无现成 helper，在其中新增（沿现有 `buildFounder`/`buildTestCharacter` 体例，把 `realmTier/realmLayer` 设到绝对层 10 顶层、`experience` 清零）；不在测试文件内散写属性数值。

- [ ] **Step 2: 跑探针**

Run: `flutter test --no-pub test/tools/overflow_layer_jump_probe_test.dart -r expanded`
Expected: PASS，控制台打印连跳分布表。

- [ ] **Step 3: 记录结论**

把探针输出的连跳分布贴入 baicao design §3.1 下方（或批3 审查报告），标注「默认一次性兑现」或「触发分段抬升」的判定。**本任务只产数据 + ratchet，不实装分段抬升逻辑**（若需分段，另开切片）。

- [ ] **Step 4: 提交**

```bash
git add test/tools/overflow_layer_jump_probe_test.dart test/support/test_data.dart
git commit -m "test: 加存量溢出连跳分布探针"
```

---

## Task 3: 断魂帖凭证道具

**Files:**
- Modify: `lib/core/domain/enums.dart:337`（`ItemType` + `fromDefId`）
- Modify: `data/items.yaml`
- Test: `test/core/domain/item_type_ticket_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/domain/item_type_ticket_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('断魂帖 defId 映射到 ItemType.ticket（不落 miscMaterial）', () {
    expect(ItemType.fromDefId('item_duanhuntie'), ItemType.ticket);
  });
  test('既有映射不回归', () {
    expect(ItemType.fromDefId('item_silver'), ItemType.silver);
    expect(ItemType.fromDefId('item_mojianshi'), ItemType.moJianShi);
    expect(ItemType.fromDefId('item_unknown_xyz'), ItemType.miscMaterial);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/core/domain/item_type_ticket_test.dart`
Expected: 失败——`ItemType.ticket` 未定义。

- [ ] **Step 3: 加枚举值 + fromDefId case**

`lib/core/domain/enums.dart` `ItemType` 值列表加 `ticket`（放 `silver` 前，保 `silver` 仍是最后一个带 `;` 的成员）：

```dart
enum ItemType {
  moJianShi, // 磨剑石（强化材料）
  xinXueJieJing, // 心血结晶（强化保底，GDD §6.3）
  jingYanDan, // 经验丹
  techniqueScroll, // 心法秘籍
  ticket, // 副本凭证（断魂帖等）
  miscMaterial, // 杂项材料
  silver; // 银两（货币）
```

`fromDefId` 的 `switch` 加 case（`default` 之前）：

```dart
      case 'item_duanhuntie':
        return ItemType.ticket;
```

- [ ] **Step 4: 同步 ItemType 穷尽 switch（default 静默吞风险）**

```bash
git grep -n "switch.*itemType\|switch (type)\|ItemType\." lib/ | grep -iE "switch|case ItemType"
git grep -ln "ItemType" lib/features lib/shared
```
逐一检查命中处的 `switch (ItemType)` 是否穷尽——**新增 `ticket` 后凡带 `default:` 兜底或未列全 case 的 switch 会静默把断魂帖归错类**（memory `feedback_enum_fromdefid_default_swallow`）。资源总览/图鉴/背包分类等展示 switch 补 `ticket` 分支（展示文案走 `UiStrings`/`EnumL10n`，不散写）。若某处确应与杂项同显，显式 `case ItemType.ticket:` 落到该分支，不靠 `default`。

- [ ] **Step 5: 加 items.yaml 条目**

`data/items.yaml` 道具列表加（沿 `:31` inline map 体例）：

```yaml
  - { defId: item_duanhuntie, type: miscMaterial, name: 断魂帖 }
```

> 注：`items.yaml` 的 `type` 字段是 `ItemDef` 自己的分类枚举（见 `item_def.dart`），与 `ItemType.fromDefId`（入库/展示归类）是两套；断魂帖在 `items.yaml` 用既有合法 `type` 值即可，运行期归类由 `fromDefId` 给 `ticket`。若 `ItemDef.fromYaml` 对 `type` 有白名单校验且需要独立值，另加 def 层枚举值并同步其 fromYaml（跑 Step 6 若解析报错再处理）。

- [ ] **Step 6: 测试 + analyze**

Run:
```bash
flutter test --no-pub test/core/domain/item_type_ticket_test.dart
flutter analyze --no-pub lib/
```
Expected: PASS + 0 issue（analyze 会逮出遗漏的非穷尽 switch 警告）。

- [ ] **Step 7: 提交**

```bash
git add lib/core/domain/enums.dart data/items.yaml test/core/domain/item_type_ticket_test.dart
git commit -m "feat: 加断魂帖凭证道具与ticket类型"
```

---

## Task 4: 两补给的副本内效果字段（§5.1）

**Files:**
- Modify: `lib/data/defs/item_def.dart`（`:20` 构造 / `:39` fromYaml / `:58` return）
- Modify: `data/items.yaml:31,34`
- Test: `test/data/item_def_gauntlet_effect_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/data/item_def_gauntlet_effect_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';

void main() {
  test('疗伤丹解析断魂庄内回血比例，行囊补给解析回气比例', () {
    final dan = ItemDef.fromYaml({
      'defId': 'item_liaoshangdan',
      'type': 'miscMaterial',
      'name': '疗伤丹',
      'gauntlet_hp_heal_pct': 0.30,
    });
    expect(dan.gauntletHpHealPct, 0.30);
    expect(dan.gauntletQiRestorePct, 0.0);

    final buji = ItemDef.fromYaml({
      'defId': 'item_xingnang_buji',
      'type': 'miscMaterial',
      'name': '行囊补给',
      'gauntlet_qi_restore_pct': 0.20,
    });
    expect(buji.gauntletQiRestorePct, 0.20);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/data/item_def_gauntlet_effect_test.dart`
Expected: 失败——`gauntletHpHealPct` 未定义。

- [ ] **Step 3: 加字段（沿 `injury_heal_hours` 三处体例）**

`item_def.dart` 类字段区加（沿 `:45-48` 既有字段）：

```dart
  /// 断魂庄内：恢复一名存活角色最大生命比例（§5.1；副本外无此效果）。
  final double gauntletHpHealPct;

  /// 断魂庄内：恢复全体存活角色最大真气比例（§5.1）。
  final double gauntletQiRestorePct;
```

`const ItemDef({...})`（`:20`）加：

```dart
    this.gauntletHpHealPct = 0.0,
    this.gauntletQiRestorePct = 0.0,
```

`fromYaml`（`:45-48` 之后）解析：

```dart
    final gauntletHpHealPct =
        (y['gauntlet_hp_heal_pct'] as num?)?.toDouble() ?? 0.0;
    final gauntletQiRestorePct =
        (y['gauntlet_qi_restore_pct'] as num?)?.toDouble() ?? 0.0;
```

`return ItemDef(...)`（`:58`）传入：

```dart
      gauntletHpHealPct: gauntletHpHealPct,
      gauntletQiRestorePct: gauntletQiRestorePct,
```

- [ ] **Step 4: 填 items.yaml 两道具**

`data/items.yaml:31`（疗伤丹）末尾加 `gauntlet_hp_heal_pct: 0.30`；`:34`（行囊补给）加 `gauntlet_qi_restore_pct: 0.20`：

```yaml
  - { defId: item_liaoshangdan,  type: miscMaterial,  name: 疗伤丹, injury_heal_hours: 4.0, residue_heal_hours: 2.0, clear_light_injury: true, gauntlet_hp_heal_pct: 0.30 }
  - { defId: item_xingnang_buji, type: miscMaterial,  name: 行囊补给, clear_light_injury: true, gauntlet_qi_restore_pct: 0.20 }
```

- [ ] **Step 5: 测试**

Run: `flutter test --no-pub test/data/item_def_gauntlet_effect_test.dart`
Expected: PASS。

- [ ] **Step 6: 提交**

```bash
git add lib/data/defs/item_def.dart data/items.yaml test/data/item_def_gauntlet_effect_test.dart
git commit -m "feat: 疗伤丹行囊补给加副本内效果字段"
```

---

## Task 5: 远征/断魂庄配置加载与 fail-fast 校验（§8.2）

> A2 只落**加载接线 + 校验不变式 + 最小合法骨架**；配置类为纯 Dart（非 Isar），Phase B 填 `expeditions.yaml` 真节点/奖励表、Phase C 填 `boss_gauntlets.yaml` 真敌人/机制表时**自由扩展这两个类**（无 schema 迁移成本）。

**Files:**
- Create: `lib/data/defs/expedition_config.dart`
- Create: `lib/data/defs/boss_gauntlet_config.dart`
- Create: `data/expeditions.yaml` / `data/boss_gauntlets.yaml`（最小合法骨架）
- Modify: `lib/data/game_repository.dart`（`:141` 字段 / `:165` 构造 / `:415` 加载 / `:449` 校验区 / `:512` `_validate*` 体例）
- Test: `test/features/expedition/expedition_config_validation_test.dart`

- [ ] **Step 1: 写失败测试（合法 + 各非法路径 fail-fast）**

```dart
// test/features/expedition/expedition_config_validation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_config.dart';

void main() {
  group('ExpeditionConfig.fromYaml', () {
    test('合法配置解析节点时长与恢复比例', () {
      final c = ExpeditionConfig.fromYaml(const {
        'normal_node_minutes': 90,
        'elite_node_minutes': 180,
        'hp_recover_pct_per_node': 0.10,
        'qi_recover_pct_per_node': 0.25,
        'zhangshi_pct_per_layer': 0.05,
      });
      expect(c.normalNodeMinutes, 90);
      expect(c.qiRecoverPctPerNode, 0.25);
    });
    test('节点时长非正 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(const {'normal_node_minutes': 0}),
        throwsStateError,
      );
    });
    test('恢复比例越界 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(const {
          'normal_node_minutes': 90,
          'elite_node_minutes': 180,
          'hp_recover_pct_per_node': 1.5,
        }),
        throwsStateError,
      );
    });
  });

  group('BossGauntletConfig.fromYaml', () {
    Map<String, dynamic> base() => {
          'supply_cap': 3,
          'stages': [
            {'role': 'elite', 'enemy_team_id': 'gauntlet_su_wujiu'},
            {'role': 'elite', 'enemy_team_id': 'gauntlet_shi_zhenyue'},
            {'role': 'boss', 'enemy_team_id': 'gauntlet_wen_jiuzhen'},
          ],
        };
    test('恰好两精英+一 Boss 且补给上限 3 合法', () {
      final c = BossGauntletConfig.fromYaml(base());
      expect(c.stages.length, 3);
      expect(c.supplyCap, 3);
    });
    test('关次角色非 2精英+1Boss → StateError', () {
      final bad = base()..['stages'] = [
        {'role': 'elite', 'enemy_team_id': 'a'},
        {'role': 'boss', 'enemy_team_id': 'b'},
      ];
      expect(() => BossGauntletConfig.fromYaml(bad), throwsStateError);
    });
    test('补给上限 ≠ 3 → StateError', () {
      final bad = base()..['supply_cap'] = 5;
      expect(() => BossGauntletConfig.fromYaml(bad), throwsStateError);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/expedition/expedition_config_validation_test.dart`
Expected: 编译失败（找不到 `ExpeditionConfig`/`BossGauntletConfig`）。

- [ ] **Step 3a: ExpeditionConfig**

```dart
// lib/features/expedition/domain/expedition_config.dart

/// 百草岭配置（§8.2）。A2 只落校验不变式与顶层字段；Phase B 扩展节点权重/深度
/// 曲线/奖励表（纯 Dart，无 schema 迁移）。
class ExpeditionConfig {
  const ExpeditionConfig({
    required this.normalNodeMinutes,
    required this.eliteNodeMinutes,
    required this.hpRecoverPctPerNode,
    required this.qiRecoverPctPerNode,
    required this.zhangshiPctPerLayer,
  });

  final int normalNodeMinutes;
  final int eliteNodeMinutes;
  final double hpRecoverPctPerNode;
  final double qiRecoverPctPerNode;

  /// 瘴蚀每层递减比例（§4.5，第31节点起每5节点+1层，封顶100%）。
  final double zhangshiPctPerLayer;

  factory ExpeditionConfig.fromYaml(Map<String, dynamic> y) {
    final normal = (y['normal_node_minutes'] as num?)?.toInt() ?? 0;
    final elite = (y['elite_node_minutes'] as num?)?.toInt() ?? 0;
    final hp = (y['hp_recover_pct_per_node'] as num?)?.toDouble() ?? 0.0;
    final qi = (y['qi_recover_pct_per_node'] as num?)?.toDouble() ?? 0.0;
    final zhangshi = (y['zhangshi_pct_per_layer'] as num?)?.toDouble() ?? 0.0;

    if (normal <= 0 || elite <= 0) {
      throw StateError('expeditions: 节点时长必须为正 (normal=$normal elite=$elite)');
    }
    for (final e in {'hp': hp, 'qi': qi, 'zhangshi': zhangshi}.entries) {
      if (e.value < 0 || e.value > 1) {
        throw StateError('expeditions: ${e.key} 比例须 ∈ [0,1]，got ${e.value}');
      }
    }
    return ExpeditionConfig(
      normalNodeMinutes: normal,
      eliteNodeMinutes: elite,
      hpRecoverPctPerNode: hp,
      qiRecoverPctPerNode: qi,
      zhangshiPctPerLayer: zhangshi,
    );
  }
}
```

- [ ] **Step 3b: BossGauntletConfig**

```dart
// lib/features/boss_gauntlet/domain/boss_gauntlet_config.dart

class GauntletStageConfig {
  const GauntletStageConfig({required this.role, required this.enemyTeamId});
  final String role; // 'elite' | 'boss'
  final String enemyTeamId;
}

/// 断魂庄配置（§8.2）。A2 落关次角色/补给上限校验；Phase C 扩展敌队机制/奖励。
class BossGauntletConfig {
  const BossGauntletConfig({required this.stages, required this.supplyCap});

  final List<GauntletStageConfig> stages;
  final int supplyCap;

  factory BossGauntletConfig.fromYaml(Map<String, dynamic> y) {
    final supplyCap = (y['supply_cap'] as num?)?.toInt() ?? 0;
    final rawStages = (y['stages'] as List?) ?? const [];
    final stages = [
      for (final s in rawStages)
        GauntletStageConfig(
          role: (s as Map)['role'] as String? ?? '',
          enemyTeamId: s['enemy_team_id'] as String? ?? '',
        ),
    ];

    if (supplyCap != 3) {
      throw StateError('boss_gauntlets: 补给上限固定为 3，got $supplyCap');
    }
    final eliteCount = stages.where((s) => s.role == 'elite').length;
    final bossCount = stages.where((s) => s.role == 'boss').length;
    if (stages.length != 3 || eliteCount != 2 || bossCount != 1) {
      throw StateError(
        'boss_gauntlets: 三关须恰为两精英+一Boss，got '
        '${stages.length}关 elite=$eliteCount boss=$bossCount',
      );
    }
    for (final s in stages) {
      if (s.enemyTeamId.isEmpty) {
        throw StateError('boss_gauntlets: 关次 enemy_team_id 不得为空');
      }
    }
    return BossGauntletConfig(stages: stages, supplyCap: supplyCap);
  }
}
```

- [ ] **Step 3c: 最小合法骨架 yaml**

`data/expeditions.yaml`：

```yaml
# 百草岭远征配置（§8.2）。A2 最小合法骨架；Phase B 填节点权重/深度曲线/奖励表。
normal_node_minutes: 90
elite_node_minutes: 180
hp_recover_pct_per_node: 0.10
qi_recover_pct_per_node: 0.25
zhangshi_pct_per_layer: 0.05
```

`data/boss_gauntlets.yaml`（enemy_team_id 先占位，Phase C 建真敌队并对齐校验）：

```yaml
# 断魂庄三关配置（§8.2）。A2 最小合法骨架；Phase C 填敌队机制/奖励。
supply_cap: 3
stages:
  - { role: elite, enemy_team_id: gauntlet_su_wujiu }
  - { role: elite, enemy_team_id: gauntlet_shi_zhenyue }
  - { role: boss,  enemy_team_id: gauntlet_wen_jiuzhen }
```

- [ ] **Step 3d: 接线 loadAllDefs + 加校验**

`game_repository.dart` 加字段（沿 `:141 itemDefs` 体例）：`final ExpeditionConfig? expeditionConfig;` `final BossGauntletConfig? bossGauntletConfig;`，构造函数（`:165`）加 `this.expeditionConfig`、`this.bossGauntletConfig`。

`loadAllDefs`（沿 `:415 _loadOptionalAsset` items.yaml 体例）加载（graceful，fixture 无 yaml 时为 null）：

```dart
    final expeditionConfig = await _loadOptionalAsset(
      load, 'data/expeditions.yaml',
      (raw) => ExpeditionConfig.fromYaml(_asMap(raw)),
    );
    final bossGauntletConfig = await _loadOptionalAsset(
      load, 'data/boss_gauntlets.yaml',
      (raw) => BossGauntletConfig.fromYaml(_asMap(raw)),
    );
```

> `_asMap` 若无现成 helper，用现有 yaml 顶层 map 解析体例（参照 `numbers.yaml` 加载）；`fromYaml` 内部已 fail-fast，无需再在 `_validate*` 重复关次/上限校验。跨表引用（`enemy_team_id` 悬空）留 Phase C 建真敌队后，在 `game_repository.dart:449` 校验区加 `_validateBossGauntletReferences` 沿 `_validateEncounterEventReferences`（`:549`）体例——**A2 不校验悬空**（骨架敌队尚未建，A2 校验只到结构层）。

把 `expeditionConfig`/`bossGauntletConfig` 传入 `GameRepository(...)` 构造。

- [ ] **Step 4: 测试 + analyze + 加载冒烟**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub \
  test/features/expedition/expedition_config_validation_test.dart \
  test/data/    # 确认 loadAllDefs 冒烟不因新 yaml 崩
flutter analyze --no-pub lib/
```
Expected: PASS + 0 issue。

- [ ] **Step 5: 提交**

```bash
git add lib/features/expedition/domain/expedition_config.dart lib/features/boss_gauntlet/domain/boss_gauntlet_config.dart data/expeditions.yaml data/boss_gauntlets.yaml lib/data/game_repository.dart test/features/expedition/expedition_config_validation_test.dart
git commit -m "feat: 加远征断魂庄配置加载与校验骨架"
```

---

## Task 6: 批末验证（Phase A2 收口）

- [ ] **Step 1: analyze**

Run: `flutter analyze --no-pub lib/ test/` → 0 issue（重点看 ItemType 非穷尽 switch 是否清零）。

- [ ] **Step 2: A2 targeted 全绿**

Run:
```bash
flutter test --no-pub \
  test/data/numbers_config_progression_release_cap_test.dart \
  test/tools/overflow_layer_jump_probe_test.dart \
  test/core/domain/item_type_ticket_test.dart \
  test/data/item_def_gauntlet_effect_test.dart \
  test/features/expedition/expedition_config_validation_test.dart
```

- [ ] **Step 3: 跨切面全量（改了 numbers/枚举/配置，按 §8.0 必跑）**

Run: `flutter test --no-pub`
Expected: 0 fail。重点核 ItemType 新值未破坏既有背包/掉落/资源总览用例；发布上限放宽未破坏关卡曲线红线。

- [ ] **Step 4: 更新恢复点 + 探针结论回填**

本文件恢复点记 A2 完成；探针连跳分布结论回填 baicao §3.1（一次性/分段判定）。

---

## 当前恢复点（2026-07-15 A2 实装批·分支 `feat/baicao-duanhun-phase-a2`·未 push）

- **状态：** **Task 2/3/4/5 已完成并 commit**（cap 无关基建全落）；**Task 1（发布上限 10→17）阻塞待用户拍板**。commit 区间 `c14f4b15`(T3)→`3830a80b`(T2)，基于本地 main HEAD `e2e4385c`（含 A1）。
- **已跑验证：** `flutter analyze --no-pub`（lib+test）**0**；全量 `flutter test --no-pub` **4046 pass / 0 fail**（基线 4034 +12 新测）。
- **Task 1 阻塞根因（计划盲点·实装期发现）：** 发布上限 10→17 使 `releaseSkillTierCap` 从三流(2)→二流(3)，触发 `game_repository.dart:_enforceSkillSourceRedLines`（波B 红线⑦）要求所有二流 mainlineDrop/fragment 招挂载到掉落点——**2 招孤儿**致 `loadAllDefs` 抛错、生产不加载：① `skill_qian_jun_zhui_yue`（千钧坠岳·mainline_drop）② `skill_zhu_ying_yao_hong`（烛影摇红·fragment）。wave-B 设计（`2026-06-11-wave-b-24-skills-content-design.md`）原挂 stage_03_05（Ch3 灰衣人 Boss）/ tower f15，但 **Codex Lv100 批已把二者敌人 re-tier 到 xueTu（学徒）**，把二流招挂到学徒内容属跨阶错配，须内容级重排（属 Phase B/C「填真敌人/奖励表」）。
- **下一步（待用户拍板）：** Task 1 phasing——**推荐 defer 到 B/C**（cap→17 与二流内容/正确挂载同批落）；A2 已交付全部 cap 无关基建。溢出探针（T2）已实测一次性兑现安全，cap 抬升时机不影响该结论。
- **未 push 原因：** 分支基于本地 main（含用户 24 未 push commit·「push 是用户的活」），push 分支会连带上传用户未 push work，留用户处置。

## 交给 Phase B/C 的接口

| 产物 | 下游 |
|---|---|
| `max_absolute_realm_level: 17` | 全成长/结算路径（已生效） |
| 溢出探针 + ratchet | 批3 联合经济探针扩展；§3.1 一次性/分段判定 |
| `item_duanhuntie` + `ItemType.ticket` | C（入场扣帖）、§4.6 资源总览 |
| `ItemDef.gauntletHpHealPct/gauntletQiRestorePct` | C2（整备页用药） |
| `ExpeditionConfig` / `BossGauntletConfig` + 两 yaml 骨架 | B 填节点/奖励表、C 填敌队/机制表 + 加悬空引用校验 |

## 自检（写完 vs 源规格）

- **Spec 覆盖：** companion §4.1 A2 五项全覆盖——发布上限（T1）/存量溢出探针（T2）/断魂帖（T3）/补给托管副本内效果字段（T4，托管**事务**属 C2）/配置加载与校验（T5）。§3.1 溢出 = T2。§8.2 校验不变式（时长正/比例区间/2精英1Boss/上限3）= T5。
- **Placeholder 扫描：** 每 code step 完整代码 + 精确路径/命令；`enemy_team_id` 骨架占位已显式标注「Phase C 建真敌队 + 加悬空校验」，非隐藏 TODO。
- **类型一致：** `ItemType.ticket`（枚举）贯穿 fromDefId/switch 同步；`gauntletHpHealPct`/`gauntletQiRestorePct`（double）三处（字段/构造/fromYaml）一致；配置校验错误统一 `StateError`（沿项目 fail-fast 体例）。
- **版本 bump 同步：** T1 已含测试断言同步（10→17），未留漏改的红线上界。
