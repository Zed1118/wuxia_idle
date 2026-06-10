# 藏经阁 + 技能装配系统 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 P1a 已实装的解锁态/熟练度/残页后端接到玩家可见可操作——新建藏经阁 screen，给每角色 6 槽技能装配（自动配+可调），熟练度/残页进度可见，已装技能注入战斗。

**Architecture:** Character 加 5 个独立装配字段（沿 equippedWeaponId 体例）+ 奇遇槽复用现有。纯域 `SkillLoadout.autoFill` 算自动填充，`SkillLoadoutService` 持久化。战斗注入点 `BattleState.fromCharacter` 从「主修心法全招」改为「读 6 个装配槽」。UI 新建 `CangJingGeScreen` 聚合，沿现有 picker/MeridianBar/WuxiaInkButton 体例。

**Tech Stack:** Flutter Desktop · Riverpod · Isar(isar_community) · 纯 Dart 域 + TDD · 数值走 numbers.yaml / 文案走 UiStrings。

**关键风险（执行前必读）：** Task 7 改 `BattleState.fromCharacter` 的 `availableSkills` 构造——现状是主修心法**全部** skillIds 进池，改后只有装配的招进池。这是 §2.6 装配限制的核心语义，但会改变现有战斗行为，**现有 battle/balance 测试可能需同步更新**（不是 bug，是预期行为变更）。该 task 必须全量跑 battle + balance 测族，把受影响的断言改成「装配后行为」。

**几个 plan 级决策（spec 的实现细化，偏离处已标）：**
- **自动填充 = 只填空槽，永不覆盖非空槽**（简化 spec 的「manual 标记」：非空槽即视为玩家保留，无需额外 schema 字段）。
- **主修2 取序 = 按 powerMultiplier 降序**取非大招的前 2（确定性、无需 proficiency 依赖；spec 提的「熟练度高→低」作为后续 refinement，本波不做）。
- **大招识别 = 主修心法招中 powerMultiplier ≥ 5000**（沿 GDD §6 大招倍率参考）。阈值进 numbers.yaml 不硬编码。

---

## 文件结构

| 文件 | 责任 | 增/改 |
|---|---|---|
| `lib/core/domain/character.dart` | 加 5 装配字段 + 工厂参数 | 改 |
| `lib/data/isar_setup.dart` | saveVersion 0.16.0→0.17.0 | 改 |
| `lib/data/numbers.yaml` | `skill_loadout.ultimate_power_threshold: 5000` | 改 |
| `lib/data/numbers_config.dart` | 读上面字段 | 改 |
| `lib/features/cultivation/domain/skill_loadout.dart` | 纯域：6 槽值对象 + autoFill | 建 |
| `lib/features/cultivation/application/skill_loadout_service.dart` | Isar 持久化 + 装配 gate 校验 | 建 |
| `lib/features/battle/domain/battle_state.dart` | fromCharacter availableSkills 改读装配槽 | 改 |
| `lib/shared/strings.dart` | 藏经阁 UiStrings | 改 |
| `lib/features/cangjingge/presentation/cangjingge_screen.dart` | 藏经阁主屏 | 建 |
| `lib/features/cangjingge/presentation/skill_slot_picker.dart` | 换招 bottom sheet | 建 |
| `lib/features/cangjingge/presentation/skill_proficiency_row.dart` | 熟练度行 | 建 |
| `lib/features/cangjingge/presentation/fragment_progress_row.dart` | 残页行 | 建 |
| `lib/features/main_menu/presentation/main_menu.dart` | 加藏经阁入口 + 门控 | 改 |
| `test/features/cultivation/skill_loadout_test.dart` | autoFill 纯域测 | 建 |
| `test/features/cultivation/skill_loadout_service_test.dart` | service + gate 测 | 建 |
| `test/features/battle/battle_loadout_injection_test.dart` | 注入测 | 建 |

---

## Phase 1 — Schema：Character 装配槽字段

### Task 1: Character 加 5 装配字段 + saveVersion 升

**Files:**
- Modify: `lib/core/domain/character.dart`（字段在 line 50 后、工厂在 104-173）
- Modify: `lib/data/isar_setup.dart:86`
- Test: `test/data/isar_setup_test.dart:48`

- [ ] **Step 1: 改 saveVersion 测试期待值（先红）**

`test/data/isar_setup_test.dart:48` 改：
```dart
expect(save.saveVersion, '0.17.0',
```

- [ ] **Step 2: 跑测试确认红**

Run: `flutter test test/data/isar_setup_test.dart`
Expected: FAIL（实际仍 0.16.0）

- [ ] **Step 3: 加 Character 字段 + 工厂参数**

`lib/core/domain/character.dart` line 50（`learnedSkillIds` 后）插入：
```dart
  /// 技能装配槽（P1b 藏经阁 · 沿 equippedEncounterSkillId 体例，每角色独立）。
  /// 主修×2 / 辅修×1 / 共鸣×1 / 大招×1；奇遇槽复用 equippedEncounterSkillId。
  /// null=空槽（autoFill 会补）。装配 gate 见 SkillLoadoutService。
  String? mainSkillId1;
  String? mainSkillId2;
  String? assistSkillId;
  String? resonanceSkillId;
  String? ultimateSkillId;
```

工厂 `Character.create` 参数列表（line 104-132 区）在 `String? equippedEncounterSkillId,` 后加：
```dart
    String? mainSkillId1,
    String? mainSkillId2,
    String? assistSkillId,
    String? resonanceSkillId,
    String? ultimateSkillId,
```

工厂 body（line 133-173 区）在 `..equippedEncounterSkillId = equippedEncounterSkillId` 后加：
```dart
      ..mainSkillId1 = mainSkillId1
      ..mainSkillId2 = mainSkillId2
      ..assistSkillId = assistSkillId
      ..resonanceSkillId = resonanceSkillId
      ..ultimateSkillId = ultimateSkillId
```

- [ ] **Step 4: 升 saveVersion**

`lib/data/isar_setup.dart:86` 改：
```dart
// P1b 藏经阁:Character 加 5 装配槽字段(mainSkillId1/2/assist/resonance/ultimate)→ 0.17.0。
static const _currentSaveVersion = '0.17.0';
```

- [ ] **Step 5: 重跑 build_runner（Character schema 改了）**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 成功，character.g.dart 含新字段

- [ ] **Step 6: 跑测试确认绿**

Run: `flutter test test/data/isar_setup_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/core/domain/character.dart lib/data/isar_setup.dart test/data/isar_setup_test.dart lib/core/domain/character.g.dart
git commit -m "feat(schema): Character 加 5 技能装配槽 + saveVersion 0.17.0"
```

---

## Phase 2 — 自动填充纯域

### Task 2: SkillLoadout 值对象 + autoFill

**Files:**
- Create: `lib/features/cultivation/domain/skill_loadout.dart`
- Create: `test/features/cultivation/skill_loadout_test.dart`
- Modify: `lib/data/numbers.yaml`（加阈值）+ `lib/data/numbers_config.dart`（读阈值）

- [ ] **Step 1: numbers.yaml 加大招阈值**

`data/numbers.yaml` 找 `skill_proficiency:` 段附近加：
```yaml
skill_loadout:
  ultimate_power_threshold: 5000   # 主修心法招 powerMultiplier ≥ 此值 → 大招槽(GDD §6)
```

`lib/data/numbers_config.dart` 加对应读取（沿现有 config 体例，找 `skillProficiency` 解析处旁加）：
```dart
final int loadoutUltimatePowerThreshold;
// 构造里：loadoutUltimatePowerThreshold = yaml['skill_loadout']?['ultimate_power_threshold'] as int? ?? 5000,
```

- [ ] **Step 2: 写 autoFill 失败测试**

`test/features/cultivation/skill_loadout_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_loadout.dart';

SkillDef _skill(String id, {int power = 500, int? tier}) => SkillDef(
  id: id, name: id, description: '', type: SkillType.active,
  powerMultiplier: power, internalForceCost: 0, cooldownTurns: 0,
  requiresManualTrigger: false, parentTechniqueDefId: tier == null ? 'tech_a' : null,
  visualEffect: '', tier: tier, narrativeInsightId: null, imagePath: null,
  canInterrupt: false, aiUsePolicy: AiUsePolicy.normal, proficiency: null,
);

void main() {
  group('SkillLoadout.autoFill', () {
    test('空槽：主修招按 power 降序填 main1/main2，大招进 ultimate', () {
      final main = [_skill('a', power: 800), _skill('ult', power: 6000), _skill('b', power: 1200)];
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: main, assistTechniqueSkills: const [],
        jointSkill: null, realmTier: RealmTier.yiLiu, existing: const SkillLoadout(),
        ultimatePowerThreshold: 5000,
      );
      expect(r.ultimateSkillId, 'ult');
      expect(r.mainSkillId1, 'b');   // power 1200 先
      expect(r.mainSkillId2, 'a');   // power 800 次
    });

    test('境界 gate：高 tier 奇遇招不填（这里辅修招带 tier 模拟锁）', () {
      final assist = [_skill('hi', tier: 7)];  // tier7 需 wuSheng
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: const [], assistTechniqueSkills: assist,
        jointSkill: null, realmTier: RealmTier.xueTu, existing: const SkillLoadout(),
        ultimatePowerThreshold: 5000,
      );
      expect(r.assistSkillId, isNull);
    });

    test('非空槽不被覆盖', () {
      final main = [_skill('a', power: 800)];
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: main, assistTechniqueSkills: const [],
        jointSkill: null, realmTier: RealmTier.yiLiu,
        existing: const SkillLoadout(mainSkillId1: 'keep'),
        ultimatePowerThreshold: 5000,
      );
      expect(r.mainSkillId1, 'keep');
      expect(r.mainSkillId2, 'a');
    });

    test('joint null → resonance 空', () {
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: const [], assistTechniqueSkills: const [],
        jointSkill: null, realmTier: RealmTier.yiLiu, existing: const SkillLoadout(),
        ultimatePowerThreshold: 5000,
      );
      expect(r.resonanceSkillId, isNull);
    });
  });
}
```

- [ ] **Step 3: 跑确认红**

Run: `flutter test test/features/cultivation/skill_loadout_test.dart`
Expected: FAIL（skill_loadout.dart 不存在）

- [ ] **Step 4: 实现 SkillLoadout**

`lib/features/cultivation/domain/skill_loadout.dart`：
```dart
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

/// 技能装配 6 槽值对象（奇遇槽独立在 Character.equippedEncounterSkillId，不在此）。
/// autoFill 只填空槽，永不覆盖非空槽（非空=玩家保留）。
class SkillLoadout {
  final String? mainSkillId1;
  final String? mainSkillId2;
  final String? assistSkillId;
  final String? resonanceSkillId;
  final String? ultimateSkillId;

  const SkillLoadout({
    this.mainSkillId1,
    this.mainSkillId2,
    this.assistSkillId,
    this.resonanceSkillId,
    this.ultimateSkillId,
  });

  factory SkillLoadout.fromCharacter(Character c) => SkillLoadout(
        mainSkillId1: c.mainSkillId1,
        mainSkillId2: c.mainSkillId2,
        assistSkillId: c.assistSkillId,
        resonanceSkillId: c.resonanceSkillId,
        ultimateSkillId: c.ultimateSkillId,
      );

  /// 非空槽 id（去重去 null），= 该角色战斗可用心法/共鸣/大招招（不含奇遇/破招）。
  List<String> get equippedIds =>
      [mainSkillId1, mainSkillId2, assistSkillId, resonanceSkillId, ultimateSkillId]
          .whereType<String>()
          .toList();

  static SkillLoadout autoFill({
    required List<SkillDef> mainTechniqueSkills,
    required List<SkillDef> assistTechniqueSkills,
    required SkillDef? jointSkill,
    required RealmTier realmTier,
    required SkillLoadout existing,
    required int ultimatePowerThreshold,
  }) {
    bool gate(SkillDef s) => s.canEquipAtRealm(realmTier);

    // 大招槽：主修招中 power ≥ 阈值，取第 1。
    final ults = mainTechniqueSkills
        .where((s) => gate(s) && s.powerMultiplier >= ultimatePowerThreshold)
        .toList();
    final ultimate = existing.ultimateSkillId ?? (ults.isNotEmpty ? ults.first.id : null);

    // 主修 2 槽：主修招中 power < 阈值，按 power 降序。
    final mains = mainTechniqueSkills
        .where((s) => gate(s) && s.powerMultiplier < ultimatePowerThreshold)
        .toList()
      ..sort((a, b) => b.powerMultiplier.compareTo(a.powerMultiplier));
    final mainIds = mains.map((s) => s.id).toList();
    final used = <String?>{existing.mainSkillId1, existing.mainSkillId2};
    final pool = mainIds.where((id) => !used.contains(id)).toList();
    final m1 = existing.mainSkillId1 ?? (pool.isNotEmpty ? pool.removeAt(0) : null);
    final m2 = existing.mainSkillId2 ?? (pool.isNotEmpty ? pool.removeAt(0) : null);

    // 辅修槽：辅修招取第 1（gate）。
    final assists = assistTechniqueSkills.where(gate).toList();
    final assist = existing.assistSkillId ?? (assists.isNotEmpty ? assists.first.id : null);

    // 共鸣槽：joint_skill（已解锁才传非 null）+ gate。
    final resonance = existing.resonanceSkillId ??
        ((jointSkill != null && gate(jointSkill)) ? jointSkill.id : null);

    return SkillLoadout(
      mainSkillId1: m1,
      mainSkillId2: m2,
      assistSkillId: assist,
      resonanceSkillId: resonance,
      ultimateSkillId: ultimate,
    );
  }
}
```

- [ ] **Step 5: 跑确认绿**

Run: `flutter test test/features/cultivation/skill_loadout_test.dart`
Expected: PASS（4 测）

- [ ] **Step 6: Commit**

```bash
git add lib/features/cultivation/domain/skill_loadout.dart test/features/cultivation/skill_loadout_test.dart data/numbers.yaml lib/data/numbers_config.dart
git commit -m "feat(cultivation): SkillLoadout 纯域 autoFill 6 槽自动填充"
```

---

## Phase 3 — 装配持久化 Service

### Task 3: SkillLoadoutService（装配 gate + autoFill 落库）

**Files:**
- Create: `lib/features/cultivation/application/skill_loadout_service.dart`
- Create: `test/features/cultivation/skill_loadout_service_test.dart`

定义槽 enum + service。装配 gate（canEquipAtRealm）在 equipSkill 校验。

- [ ] **Step 1: 写失败测试（gate + autoFill 落库）**

`test/features/cultivation/skill_loadout_service_test.dart`（沿现有 isar test 体例：`IsarSetup.initForTest` 或同款 setUp，参考 `skill_unlock_service_test.dart` 的 setUp/tearDown）：
```dart
// setUp: 建临时 isar + 一个 Character(realmTier=xueTu) put 入库
// 测 1: equipSkill 低境界装高 tier 招 → 返回 SlotEquipTierLocked，槽不变
// 测 2: equipSkill 境界达标 → 槽写入 skillId
// 测 3: applyAutoFill → 角色 6 槽按 autoFill 结果落库
// 测 4: unequipSlot → 槽置 null
```
（完整断言照 skill_unlock_service_test.dart 的 writeTxn 包裹 + isar.characters.get 读回模式写。）

- [ ] **Step 2: 跑确认红**

Run: `flutter test test/features/cultivation/skill_loadout_service_test.dart`
Expected: FAIL（service 不存在）

- [ ] **Step 3: 实现 SkillLoadoutService**

`lib/features/cultivation/application/skill_loadout_service.dart`：
```dart
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_loadout.dart';

enum SkillSlot { main1, main2, assist, resonance, ultimate }

sealed class EquipSlotResult {
  const EquipSlotResult();
}
class SlotEquipSucceeded extends EquipSlotResult { const SlotEquipSucceeded(); }
class SlotEquipTierLocked extends EquipSlotResult { const SlotEquipTierLocked(); }
class SlotEquipNotFound extends EquipSlotResult { const SlotEquipNotFound(); }

/// 技能装配持久化（P1b）。装配 gate = SkillDef.canEquipAtRealm（§5.3 三系锁死）。
class SkillLoadoutService {
  final Isar _isar;
  SkillLoadoutService(this._isar);

  Future<EquipSlotResult> equipSkill({
    required int characterId,
    required SkillSlot slot,
    required String skillId,
  }) async {
    final repo = GameRepository.instance;
    final def = repo.skillDefs[skillId];
    if (def == null) return const SlotEquipNotFound();
    EquipSlotResult result = const SlotEquipSucceeded();
    await _isar.writeTxn(() async {
      final c = await _isar.characters.get(characterId);
      if (c == null) { result = const SlotEquipNotFound(); return; }
      if (!def.canEquipAtRealm(c.realmTier)) { result = const SlotEquipTierLocked(); return; }
      _writeSlot(c, slot, skillId);
      await _isar.characters.put(c);
    });
    return result;
  }

  Future<void> unequipSlot({required int characterId, required SkillSlot slot}) async {
    await _isar.writeTxn(() async {
      final c = await _isar.characters.get(characterId);
      if (c == null) return;
      _writeSlot(c, slot, null);
      await _isar.characters.put(c);
    });
  }

  /// 读角色主/辅修心法招 + joint 解锁态，autoFill 补空槽并落库。
  Future<void> applyAutoFill({
    required int characterId,
    required List<SkillDef> mainTechniqueSkills,
    required List<SkillDef> assistTechniqueSkills,
    required SkillDef? jointSkill,
    required int ultimatePowerThreshold,
  }) async {
    await _isar.writeTxn(() async {
      final c = await _isar.characters.get(characterId);
      if (c == null) return;
      final filled = SkillLoadout.autoFill(
        mainTechniqueSkills: mainTechniqueSkills,
        assistTechniqueSkills: assistTechniqueSkills,
        jointSkill: jointSkill,
        realmTier: c.realmTier,
        existing: SkillLoadout.fromCharacter(c),
        ultimatePowerThreshold: ultimatePowerThreshold,
      );
      c.mainSkillId1 = filled.mainSkillId1;
      c.mainSkillId2 = filled.mainSkillId2;
      c.assistSkillId = filled.assistSkillId;
      c.resonanceSkillId = filled.resonanceSkillId;
      c.ultimateSkillId = filled.ultimateSkillId;
      await _isar.characters.put(c);
    });
  }

  void _writeSlot(Character c, SkillSlot slot, String? id) {
    switch (slot) {
      case SkillSlot.main1: c.mainSkillId1 = id;
      case SkillSlot.main2: c.mainSkillId2 = id;
      case SkillSlot.assist: c.assistSkillId = id;
      case SkillSlot.resonance: c.resonanceSkillId = id;
      case SkillSlot.ultimate: c.ultimateSkillId = id;
    }
  }
}
```

- [ ] **Step 4: 跑确认绿**

Run: `flutter test test/features/cultivation/skill_loadout_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/cultivation/application/skill_loadout_service.dart test/features/cultivation/skill_loadout_service_test.dart
git commit -m "feat(cultivation): SkillLoadoutService 装配 gate + autoFill 落库"
```

---

## Phase 4 — 解锁注入战斗（核心风险 task）

### Task 4: BattleState.fromCharacter 改读装配槽

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart:258-301`
- Create: `test/features/battle/battle_loadout_injection_test.dart`

**改动语义：** `availableSkills` 从「主修心法全部 skillIds + joint 特殊逻辑 + encounter」改为「6 装配槽非空技能 + 破招技广发」。joint 不再特殊（已在 resonance 槽）；奇遇仍读 equippedEncounterSkillId（=第 6 槽）。**破招广发(po_shi)、swordSongActive buff 保留不动。**

- [ ] **Step 1: 写注入测试（先红）**

`test/features/battle/battle_loadout_injection_test.dart`：
```dart
// 构造一个 Character，手动设 mainSkillId1='a', ultimateSkillId='ult',
// equippedEncounterSkillId='enc'，其余槽 null。
// 走 BattleState.fromCharacter（player team）。
// 断言：availableSkills 的 id 集 == {'a','ult','enc', 破招技 id}（不含主修心法其他未装招）。
// 断言：空槽不进池（如 mainSkillId2 null 不报错、不注入）。
```
（参考现有 battle_state 测试的 fromCharacter 调用样板。）

- [ ] **Step 2: 跑确认红**

Run: `flutter test test/features/battle/battle_loadout_injection_test.dart`
Expected: FAIL（现状注入主修全招，集合不符）

- [ ] **Step 3: 改 battle_state.dart fromCharacter**

`lib/features/battle/domain/battle_state.dart` 把 line 258-274 区的 `final skills = <SkillDef>[...techDef.skillIds...]` + encounter + joint 三段，替换为读装配槽：
```dart
// P1b 藏经阁:availableSkills = 6 装配槽非空技能（替代旧「主修心法全招」）。
// 奇遇=equippedEncounterSkillId(第6槽);joint 已在 resonanceSkillId 槽,不再特殊注入。
final repo = GameRepository.instance;
final loadoutIds = <String?>[
  character.mainSkillId1,
  character.mainSkillId2,
  character.assistSkillId,
  character.resonanceSkillId,
  character.ultimateSkillId,
  character.equippedEncounterSkillId,
];
final skills = <SkillDef>[
  for (final id in loadoutIds)
    if (id != null && repo.skillDefs.containsKey(id)) repo.getSkill(id),
];
```
保留其后的 `swordSongActive` 判定块（resonance buff，仍按 weapon resonanceStage 算）与破招广发块（`if (teamSide == _playerTeamSide) ... po_shi`）**不动**。删除原 `hasJointSkillUnlocked → add joint_skill` 注入块（joint 现在走 resonance 槽）。

- [ ] **Step 4: 跑注入测试 + 全量 battle/balance 测族**

Run: `flutter test test/features/battle/battle_loadout_injection_test.dart`
Expected: PASS

Run: `flutter test test/features/battle/ test/tools/`
Expected: 部分现有测试可能 FAIL —— 因为它们假设「主修全招可用」。**逐个判断：若 fixture 角色没设装配槽 → 现在 availableSkills 只剩破招技。修复方式 = 测试 fixture 里给角色设装配槽（mainSkillId1 等），或在 setUp 调 SkillLoadoutService.applyAutoFill。** 把每个受影响测试改成「装配后行为」，不要改生产逻辑迁就旧断言。

- [ ] **Step 5: analyze + Commit**

Run: `flutter analyze`
Expected: 0
```bash
git add lib/features/battle/domain/battle_state.dart test/features/battle/
git commit -m "feat(battle): availableSkills 改读 6 装配槽(替代主修全招) + 测试适配"
```

---

## Phase 5 — autoFill 触发 wire + UI

### Task 5: 进战斗前 autoFill wire（保证旧存档不空池）

**Files:**
- Modify: `lib/features/battle/application/stage_battle_setup.dart`（battle 启动前）
- Test: 现有 stage_battle_setup 测族补一例

**为什么：** Task 4 让 fromCharacter 读装配槽。旧存档/新角色槽全 null → 战斗只剩破招技。**进战斗前必须 applyAutoFill 补满**。这是 autoFill 的主触发点（学技能/换心法靠「下次进战斗/进藏经阁」兜底，不逐 mutation wire · YAGNI）。

- [ ] **Step 1: 写测试**：一个槽全空的角色，经 stage_battle_setup 进战斗后，availableSkills 含其主修招（被 autoFill 补入），不只破招技。

- [ ] **Step 2: 跑确认红**

Run: `flutter test test/features/battle/stage_battle_setup_test.dart`（或对应测文件）
Expected: FAIL

- [ ] **Step 3: wire**

在 `stage_battle_setup.dart` 构造玩家 BattleCharacter 之前，对每个出战角色调 `SkillLoadoutService.applyAutoFill`。解析主/辅修心法招 + joint：
```dart
final loadoutSvc = SkillLoadoutService(isar);
for (final c in playerParty) {
  final mainTech = c.mainTechniqueId == null ? null : repo.techniqueDefs[...];  // 解析主修 techDef
  final mainSkills = mainTech == null ? <SkillDef>[]
      : mainTech.skillIds.map(repo.getSkill).toList();
  final assistSkills = c.assistTechniqueIds.expand((tid) =>
      repo.techniqueDefById(tid)?.skillIds.map(repo.getSkill) ?? const <SkillDef>[]).toList();
  final joint = /* 同 fromCharacter 的 hasJointSkillUnlocked 判定 */
      repo.skillDefs['skill_joint_skill'];  // 仅解锁时传非 null（沿 resonanceStage 判定）
  await loadoutSvc.applyAutoFill(
    characterId: c.id, mainTechniqueSkills: mainSkills,
    assistTechniqueSkills: assistSkills, jointSkill: joint,
    ultimatePowerThreshold: numbers.loadoutUltimatePowerThreshold,
  );
}
```
（joint 解锁判定复用 battle_state 原 `hasJointSkillUnlocked` 逻辑——抽成 helper `bool isJointUnlocked(equipped, numbers)` 供两处共用，避免 DRY 违反。）

- [ ] **Step 4: 跑确认绿 + Step 5: Commit**
```bash
git commit -am "feat(battle): 进战斗前 applyAutoFill 补满装配槽"
```

### Task 6: UiStrings 加藏经阁文案

**Files:** Modify `lib/shared/strings.dart`

- [ ] **Step 1-2: 加串（无测试，直接加）**，沿现有 `mainMenuXxx` 体例：
```dart
// ─── 藏经阁（P1b）──────────────────
static const String mainMenuSkillLibrary = '藏经阁';
static const String mainMenuSkillLibraryHint = '查看武学 / 装配出战招式 / 熟练度 / 残页';
static const String mainMenuSkillLibraryLockedHint = '修习武学后开启';
static const String cangjingLoadoutTitle = '出战配置';
static const String cangjingLoadoutHint = '自动配好 · 点槽位可换';
static const String cangjingLibraryTitle = '武学';
static const String cangjingFragmentTitle = '残页';
static String cangjingSlotMain(int n) => '主修$n';
static const String cangjingSlotAssist = '辅修';
static const String cangjingSlotResonance = '共鸣';
static const String cangjingSlotUltimate = '大招';
static const String cangjingSlotEncounter = '奇遇';
static const String cangjingSlotEmpty = '空';
static String cangjingProficiencyNeed(int n) => '再用 $n 次→下一阶';
static String cangjingFragmentProgress(int has, int total) => '$has / $total 页';
static const String cangjingTierLocked = '境界不足';
```

- [ ] **Step 3: Commit** `git commit -am "feat(strings): 藏经阁 UiStrings"`

### Task 7: 熟练度行 + 残页行组件

**Files:**
- Create: `lib/features/cangjingge/presentation/skill_proficiency_row.dart`
- Create: `lib/features/cangjingge/presentation/fragment_progress_row.dart`
- Test: `test/features/cangjingge/cangjingge_widgets_test.dart`

**SkillProficiencyRow:** 显「招名 + 阶段名 + MeridianBar(进度) + 当前加成% + 还需次数 + 装配态点」。入参：`SkillDef skill, int uses, SkillProficiencyConfig cfg, bool equipped`。阶段/倍率经 `SkillProficiency.stageFor/damageMultFor`，进度=当前 uses 距下一阶 minUses 的比值。复用 `MeridianBar(ratio:..., height:8)`。文案走 UiStrings。

**FragmentProgressRow:** 显「秘籍名 + ▣▣▣▢▢ + N/M 页」。入参：`String name, int has, int total`。满格用实心方块、空用空心。

- [ ] **Step 1: widget 测试**（沿 memory `feedback_listview_widget_test_viewport`：`tester.binding.window` 或 `setSurfaceSize(Size(800,2000))`）：泵 SkillProficiencyRow，`expect(find.text('精通'), findsOneWidget)` + 进度条存在；泵 FragmentProgressRow，`expect(find.textContaining('3 / 5'), findsOneWidget)`。Image.asset 类记得 errorBuilder（memory `feedback_image_asset_error_builder`）。
- [ ] **Step 2: 红 → Step 3: 实现两 widget（StatelessWidget，沿 WuxiaUi 宣纸 token，文案 UiStrings）→ Step 4: 绿 → Step 5: Commit**
```bash
git commit -m "feat(cangjingge): 熟练度行 + 残页进度行组件"
```

### Task 8: 换招 bottom sheet picker

**Files:** Create `lib/features/cangjingge/presentation/skill_slot_picker.dart`

沿 `encounter_skill_section.dart` 的 `_openPicker` + `_PickerSheet` 体例：
- `showModalBottomSheet<SkillDef>`，`backgroundColor: WuxiaColors.panel`
- 入参：候选 `List<SkillDef>`（按槽类型过滤：main/ultimate 取主修心法招、assist 取辅修招、resonance 取 joint）、`currentRealmTier`、当前槽 `equippedId`
- 每项显招名 + tier，境界不达（`!canEquipAtRealm`）灰显不可点（显 `UiStrings.cangjingTierLocked`）
- 选中回调 → `SkillLoadoutService.equipSkill(characterId, slot, skillId)`，结果 `SlotEquipTierLocked` 弹 SnackBar

- [ ] **Step 1: 测试**（picker 候选过滤 + gate 灰显）→ **2 红 → 3 实现 → 4 绿 → 5 Commit**
```bash
git commit -m "feat(cangjingge): 换招 bottom sheet picker + 装配 gate"
```

### Task 9: CangJingGeScreen 主屏

**Files:**
- Create: `lib/features/cangjingge/presentation/cangjingge_screen.dart`
- Test: `test/features/cangjingge/cangjingge_screen_test.dart`

竖向结构（照 brainstorm mockup `layout-A-full`）：
1. **AppBar**（必须有，memory `feedback_flutter_subscreen_appbar_audit`）+ 角色切换 tab
2. **出战配置栏**：6 槽（main1/2/assist/resonance/ultimate/encounter），点槽位开 SkillSlotPicker。槽显招名或 `cangjingSlotEmpty`
3. **武学库**：按主修/辅修心法分组，每招一 SkillProficiencyRow
4. **残页收集区**：账号级 `SkillUnlockService.fragmentProgress` 列 FragmentProgressRow

**进入时 autoFill：** `initState`/首帧 `ref.read(...)` 调 `SkillLoadoutService.applyAutoFill`（同 Task 5 解析逻辑，抽 helper 共用），保证打开即填好。

Provider：watch 当前角色（`characterProvider`）、`numbersProvider`、`skillUnlockProgress`。文案全 UiStrings。

- [ ] **Step 1: widget 测试**（pump screen，扩 viewport `setSurfaceSize(Size(900,2400))`；验 AppBar 标题 + 6 槽渲染 + 至少一 SkillProficiencyRow + 残页区）→ **2 红 → 3 实现 → 4 绿 → 5 Commit**
```bash
git commit -m "feat(cangjingge): 藏经阁主屏(6槽装配+武学库+残页+进入autoFill)"
```

### Task 10: 主菜单藏经阁入口 + 门控

**Files:** Modify `lib/features/main_menu/presentation/main_menu.dart`

沿 coreItems 的 WuxiaInkButton 体例（subagent 摘录第 10 节），在 coreItems 加：
```dart
WuxiaInkButton(
  label: UiStrings.mainMenuSkillLibrary,
  hint: skillLibLocked ? UiStrings.mainMenuSkillLibraryLockedHint : UiStrings.mainMenuSkillLibraryHint,
  icon: Icons.menu_book_outlined,
  thumbnailPath: WuxiaUi.entryTechnique,   // 复用心法入口图（或新增 asset）
  disabled: skillLibLocked,
  locked: skillLibLocked,
  onTap: () => _push(context, const CangJingGeScreen(characterId: _defaultCharacterId)),
),
```
门控 `final skillLibLocked = step < _techniquesUnlockStep;`（§5.7：修了心法才有技能可装，复用心法解锁门控）。

- [ ] **Step 1: 测试**（main_menu pump，门控锁态下入口 disabled）→ **2 红 → 3 实现 → 4 绿 → 5 Commit**
```bash
git commit -m "feat(main-menu): 藏经阁入口 + §5.7 门控"
```

---

## Phase 6 — 收尾

### Task 11: 全量回归 + analyze + PROGRESS

- [ ] **Step 1: 全量测试**

Run: `flutter test`
Expected: 全绿（baseline 1857 + 本批新增，1 skip）。受 Task 4 影响的 battle/balance 测应已在 Task 4 修复。

- [ ] **Step 2: analyze**

Run: `flutter analyze`
Expected: 0（含 info）

- [ ] **Step 3: 更新 PROGRESS.md 顶段**（走 python string-replace，bg 写守卫拦 Edit）：加 P1b 藏经阁全闭环条目，控行数 ≤100。

- [ ] **Step 4: 合 main + push**
```bash
git push origin main
```

---

## 自审备注（writing-plans self-review）

- **Spec 覆盖：** §3 schema→Task1 · §4 autoFill→Task2 · §3 gate/service→Task3 · §5 注入→Task4+5 · §6 入口→Task10 · §6 picker→Task8 · §7 组件→Task7+9 · §8 测试→各 task TDD · §9 范围(破招gate/24招/source tag 留 backlog)未建 task ✓ 符合预期。
- **类型一致：** `SkillLoadout`/`SkillSlot` enum/`EquipSlotResult` sealed 三处签名跨 Task2/3/8 一致；`applyAutoFill` 参数 Task3 定义、Task5/9 调用一致。
- **已知偏离（spec→plan）：** manual 标记简化为「只填空槽」· 主修2 取序按 power 降序（非 proficiency）· autoFill 触发简化为进战斗/进藏经阁两点。三处均在「plan 级决策」段标注。
- **最大风险：** Task 4 改 availableSkills 来源，现有 battle/balance 测需适配（Task4 Step4 已含修复指引：改 fixture 设装配槽，不迁就旧断言改生产逻辑）。
