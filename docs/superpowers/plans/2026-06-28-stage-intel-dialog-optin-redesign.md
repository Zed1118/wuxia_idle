# 战前情报弹窗 opt-in 重做 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把睡觉模式被排除的「战前情报」重做成 opt-in 纯查看弹窗，复用关卡行现有 info 图标，去掉与行内整备条冗余的整备/难度内容。

**Architecture:** 新建精简版 `stage_intel_dialog.dart`（`StageIntelContent` 可测 widget + `showStageIntelDialog` 纯查看包装，返回 `Future<void>` 单关闭按钮）。仅改 `stage_list_screen.dart` 那一个 info 图标的 `onPressed` 指向新弹窗；`loot_rumor_dialog.dart` 不动（爬塔/preview card 仍用）。新弹窗内部复用 `LootRumorContent` 渲染「可能收获」。

**Tech Stack:** Flutter + Riverpod 3.x，纯表现层，无 schema/saveVer/numbers.yaml/data 改动。

**前置事实（已核对 main `0e610bc0`）：**
- 当前 `strings.dart` **无任何 `prebattle*` 常量**（随被排除的 11 提交一起未进 main）→ 本计划是**新增保留子集**，非删除。
- `UiStrings.close = '关闭'`（`strings.dart:117`）已存在，弹窗关闭按钮直接复用。
- 现 `stage_list_screen_test.dart` 对 info 图标**只断言存在、不点击**（`:146`）→ 改 `onPressed` 目标不破现测，需新增点击断言。
- `_StageRow.build` 作用域内 `def`（StageDef）、`rumor`（DropRumorTable，`:375`）、`currentRealm`（field）均已就绪，wiring 无需新增数据流。
- 文案措辞沿用原 11，不改写（含「敌阵偏X，可备克制路数」这类既有措辞，本切片不动）。

---

### Task 1: 新增保留子集 prebattle 文案

**Files:**
- Modify: `lib/shared/strings.dart`

新增的常量（保留子集；**不**加 `prebattleIntelPreparationSection` / `prebattleIntelStart` / `prebattleIntelCancel` / `prebattleRecommendedRealm` / `prebattleDifficulty` / `prebattlePrepRealmReady` / `prebattlePrepRealmLow` / `prebattlePrepRealmUnknown` / `prebattleRiskRealmLow`——这些是被去掉的冗余）。

- [ ] **Step 1: 在 `UiStrings` 类内（紧接 `difficultyDeadly` 常量之后，约 `:1015`）插入**

```dart
  static const String prebattleIntelTitle = '战前情报';
  static const String prebattleIntelEnemySection = '敌阵';
  static const String prebattleIntelResponseSection = '应对';
  static const String prebattleIntelRiskSection = '风险';
  static const String prebattleIntelLootSection = '可能收获';
  static const String prebattleIntelNoEnemy = '未见敌踪';
  static const String prebattleIntelBossTag = '首领';
  static const String prebattleIntelChargeTag = '蓄力';
  static String prebattleIntelDialogTitle(String stageName) =>
      '$prebattleIntelTitle · $stageName';
  static String prebattleEnemyLine(
    String name,
    String realm,
    String school,
    String tags,
  ) => tags.isEmpty
      ? '$name · $realm · $school'
      : '$name · $realm · $school · $tags';
  static String prebattlePrepCounterSchool(String school) =>
      '敌阵偏$school，可备克制路数。';
  static const String prebattlePrepBoss = '首领关宜留足内力，先处理随从再攻坚。';
  static const String prebattlePrepGroup = '敌众时备一门群体招，先清场再压主目标。';
  static const String prebattlePrepCharge = '敌方有蓄力招，保留破招或爆发内力。';
  static const String prebattleRiskBoss = '首领战败会触发额外折损，勿空内力硬拼。';
  static const String prebattleRiskCharge = '蓄力招若未打断，可能瞬间扭转战局。';
  static const String prebattleRiskOutnumbered = '敌方人数较多，拖久容易被围攻。';
  static const String prebattleRiskNone = '未见明显险兆，按常规节奏推进。';
```

- [ ] **Step 2: 验证编译**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/shared/strings.dart`
Expected: No issues found（未引用也不报错，const 静态字段）。

- [ ] **Step 3: 提交**

```bash
git add lib/shared/strings.dart
git commit -m "feat: 新增战前情报弹窗保留子集文案"
```

---

### Task 2: 新建 stage_intel_dialog（TDD）

**Files:**
- Create: `lib/features/loot_preview/presentation/stage_intel_dialog.dart`
- Test: `test/features/loot_preview/stage_intel_dialog_test.dart`

- [ ] **Step 1: 写失败测试** `test/features/loot_preview/stage_intel_dialog_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/stage_intel_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  StageDef stage({bool boss = false, List<EnemyDef>? enemies}) {
    return StageDef(
      id: 'stage_test',
      name: '试剑坡',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.sanLiu,
      enemyTeam:
          enemies ??
          [
            const EnemyDef(
              id: 'bandit_a',
              name: '山道悍匪',
              realmTier: RealmTier.sanLiu,
              realmLayer: RealmLayer.ruMen,
              school: TechniqueSchool.gangMeng,
              baseHp: 1200,
              baseAttack: 180,
              baseSpeed: 110,
              skillIds: ['skill_normal'],
              iconPath: '',
            ),
          ],
      isBossStage: boss,
      dropTable: const [
        EquipmentDrop(equipmentDefId: 'weapon_test', dropChance: 0.3),
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 2,
          dropChance: 1.0,
        ),
      ],
      baseExpReward: 100,
      difficultyMultiplier: 1,
    );
  }

  Future<void> pumpIntel(
    WidgetTester tester,
    StageDef stage, {
    RealmTier currentRealm = RealmTier.xueTu,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageIntelContent(
            stage: stage,
            currentRealm: currentRealm,
            rumorTable: DropRumorTable.fromDropTable(
              stage.dropTable,
              gating: FirstClearGating.scrollOnly,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('战前情报显敌阵/应对/风险/掉落，去整备难度冗余', (tester) async {
    await pumpIntel(tester, stage());

    expect(find.text(UiStrings.prebattleIntelEnemySection), findsOneWidget);
    expect(find.textContaining('山道悍匪'), findsOneWidget);
    // 单刚猛敌 → 应对段给克制建议
    expect(find.text(UiStrings.prebattleIntelResponseSection), findsOneWidget);
    expect(find.textContaining('可备克制路数'), findsOneWidget);
    // 无 boss/蓄力/人多 → 风险兜底
    expect(find.text(UiStrings.prebattleRiskNone), findsOneWidget);
    // 掉落复用 LootRumorContent
    expect(find.text(UiStrings.prebattleIntelLootSection), findsOneWidget);
    expect(find.text(UiStrings.lootBucketChangKeDe), findsOneWidget);
    // 去冗余：无推荐境界/难度判语/境界低行
    expect(find.textContaining('推荐：'), findsNothing);
    expect(find.textContaining('境界低于推荐'), findsNothing);
  });

  testWidgets('首领蓄力三人阵给应对与风险提示', (tester) async {
    await pumpIntel(
      tester,
      stage(
        boss: true,
        enemies: const [
          EnemyDef(
            id: 'm1',
            name: '黑风喽啰',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.lingQiao,
            baseHp: 1000,
            baseAttack: 120,
            baseSpeed: 130,
            skillIds: ['skill_normal'],
            iconPath: '',
          ),
          EnemyDef(
            id: 'm2',
            name: '黑风刀客',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.ruMen,
            school: TechniqueSchool.lingQiao,
            baseHp: 1100,
            baseAttack: 140,
            baseSpeed: 130,
            skillIds: ['skill_normal'],
            iconPath: '',
          ),
          EnemyDef(
            id: 'boss',
            name: '黑风寨主',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.shuLian,
            school: TechniqueSchool.lingQiao,
            baseHp: 2200,
            baseAttack: 220,
            baseSpeed: 130,
            skillIds: ['skill_normal', 'skill_charge'],
            iconPath: '',
            isBoss: true,
            chargeSkillId: 'skill_charge',
          ),
        ],
      ),
    );

    expect(find.textContaining('黑风寨主'), findsOneWidget);
    expect(
      find.textContaining(
        '${UiStrings.prebattleIntelBossTag} / ${UiStrings.prebattleIntelChargeTag}',
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.prebattlePrepGroup), findsOneWidget);
    expect(find.text(UiStrings.prebattlePrepCharge), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskBoss), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskCharge), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskOutnumbered), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test --no-pub test/features/loot_preview/stage_intel_dialog_test.dart`
Expected: 编译失败 `stage_intel_dialog.dart` 不存在 / `StageIntelContent` 未定义。

- [ ] **Step 3: 写实现** `lib/features/loot_preview/presentation/stage_intel_dialog.dart`

```dart
import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../battle/domain/enum_localizations.dart';
import '../domain/drop_rumor.dart';
import 'loot_rumor_dialog.dart';

/// 战前情报弹窗（opt-in 纯查看）：关卡行 info 图标触发。
///
/// 只补行内（整备条/掉落摘要）没有的「敌阵详列 + 应对要点」，并复用
/// [LootRumorContent] 显「可能收获」。不挂关卡 onTap、不返回战斗决定，
/// 守「即拖即放立即出手」——点关卡行仍直接进战斗。
Future<void> showStageIntelDialog(
  BuildContext context, {
  required StageDef stage,
  required DropRumorTable rumorTable,
  RealmTier? currentRealm,
}) {
  return PaperDialog.show<void>(
    context,
    title: UiStrings.prebattleIntelDialogTitle(stage.name),
    body: SingleChildScrollView(
      child: StageIntelContent(
        stage: stage,
        rumorTable: rumorTable,
        currentRealm: currentRealm,
      ),
    ),
    actions: [
      PlaqueButton(
        label: UiStrings.close,
        primary: true,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

class StageIntelContent extends StatelessWidget {
  const StageIntelContent({
    super.key,
    required this.stage,
    required this.rumorTable,
    this.currentRealm,
  });

  final StageDef stage;
  final DropRumorTable rumorTable;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    final responseLines = _teamPreparationLines(
      stage.enemyTeam,
      isBossStage: stage.isBossStage,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntelSection(
          title: UiStrings.prebattleIntelEnemySection,
          child: _EnemyIntelList(enemies: stage.enemyTeam),
        ),
        if (responseLines.isNotEmpty)
          _IntelSection(
            title: UiStrings.prebattleIntelResponseSection,
            child: _IntelLines(lines: responseLines),
          ),
        _IntelSection(
          title: UiStrings.prebattleIntelRiskSection,
          child: _RiskIntel(stage: stage),
        ),
        _IntelSection(
          title: UiStrings.prebattleIntelLootSection,
          child: LootRumorContent(
            table: rumorTable,
            currentRealm: currentRealm,
          ),
        ),
      ],
    );
  }
}

class _IntelSection extends StatelessWidget {
  const _IntelSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: WuxiaUi.jiang,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _IntelLines extends StatelessWidget {
  const _IntelLines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final line in lines) _IntelLine(line)],
    );
  }
}

class _EnemyIntelList extends StatelessWidget {
  const _EnemyIntelList({required this.enemies});

  final List<EnemyDef> enemies;

  @override
  Widget build(BuildContext context) {
    if (enemies.isEmpty) {
      return const _IntelLine(UiStrings.prebattleIntelNoEnemy);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final enemy in enemies) _IntelLine(_enemyLine(enemy))],
    );
  }

  String _enemyLine(EnemyDef enemy) {
    final tags = <String>[
      if (enemy.isBoss) UiStrings.prebattleIntelBossTag,
      if (enemy.chargeSkillId != null) UiStrings.prebattleIntelChargeTag,
    ].join(' / ');
    return UiStrings.prebattleEnemyLine(
      enemy.name,
      EnumL10n.realm(enemy.realmTier, enemy.realmLayer),
      EnumL10n.school(enemy.school),
      tags,
    );
  }
}

class _RiskIntel extends StatelessWidget {
  const _RiskIntel({required this.stage});

  final StageDef stage;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (stage.isBossStage) UiStrings.prebattleRiskBoss,
      if (stage.enemyTeam.any((e) => e.chargeSkillId != null))
        UiStrings.prebattleRiskCharge,
      if (stage.enemyTeam.length >= 3) UiStrings.prebattleRiskOutnumbered,
    ];
    if (lines.isEmpty) lines.add(UiStrings.prebattleRiskNone);
    return _IntelLines(lines: lines);
  }
}

class _IntelLine extends StatelessWidget {
  const _IntelLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
  }
}

List<String> _teamPreparationLines(
  List<EnemyDef> enemies, {
  required bool isBossStage,
}) {
  final lines = <String>[];
  if (isBossStage) lines.add(UiStrings.prebattlePrepBoss);
  if (enemies.length >= 3) lines.add(UiStrings.prebattlePrepGroup);
  if (enemies.any((e) => e.chargeSkillId != null)) {
    lines.add(UiStrings.prebattlePrepCharge);
  }
  final schools = enemies.map((e) => e.school).toSet();
  if (schools.length == 1 && schools.isNotEmpty) {
    lines.add(
      UiStrings.prebattlePrepCounterSchool(
        EnumL10n.school(_counterSchoolFor(schools.single)),
      ),
    );
  }
  return lines;
}

TechniqueSchool _counterSchoolFor(TechniqueSchool enemySchool) {
  return switch (enemySchool) {
    TechniqueSchool.gangMeng => TechniqueSchool.lingQiao,
    TechniqueSchool.lingQiao => TechniqueSchool.yinRou,
    TechniqueSchool.yinRou => TechniqueSchool.gangMeng,
  };
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test --no-pub test/features/loot_preview/stage_intel_dialog_test.dart`
Expected: All tests passed!（2 passed）

如 `EnumL10n.school(lingQiao)` 显示名非「灵巧」导致克制行断言失败：测试用的是 `find.textContaining('可备克制路数')`（不绑具体门派名），不受影响；若失败优先核 `_IntelLines`/section 渲染。

- [ ] **Step 5: 提交**

```bash
git add lib/features/loot_preview/presentation/stage_intel_dialog.dart test/features/loot_preview/stage_intel_dialog_test.dart
git commit -m "feat: 战前情报 opt-in 弹窗（敌阵+应对+风险+掉落，去冗余整备）"
```

---

### Task 3: 关卡行 info 图标改指向战前情报

**Files:**
- Modify: `lib/features/mainline/presentation/stage_list_screen.dart`（import + `:499-510` IconButton）

- [ ] **Step 1: 加 import**（与现有 loot_preview import 邻接，约 `:14` 之后）

```dart
import '../../loot_preview/presentation/stage_intel_dialog.dart';
```

- [ ] **Step 2: 改 info IconButton（`:499-510`）**

把原块：

```dart
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: UiStrings.lootRumorDialogTitle,
                color: WuxiaColors.textMuted,
                onPressed: () => showLootRumorDialog(
                  context,
                  table: rumor,
                  currentRealm: currentRealm,
                ),
              ),
```

改为：

```dart
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: UiStrings.prebattleIntelTitle,
                color: WuxiaColors.textMuted,
                onPressed: () => showStageIntelDialog(
                  context,
                  stage: def,
                  rumorTable: rumor,
                  currentRealm: currentRealm,
                ),
              ),
```

- [ ] **Step 3: 清理无用 import**

如 `showLootRumorDialog` 在 `stage_list_screen.dart` 已无其他引用，删 `import '../../loot_preview/presentation/loot_rumor_dialog.dart';`（`:14`）。先确认：

Run: `grep -n "showLootRumorDialog\|loot_rumor_dialog" lib/features/mainline/presentation/stage_list_screen.dart`
若仅剩 import 行 → 删该 import；否则保留。（analyze 的 unused_import 会兜底提示。）

- [ ] **Step 4: analyze**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/features/mainline/presentation/stage_list_screen.dart`
Expected: No issues found.

- [ ] **Step 5: 提交**

```bash
git add lib/features/mainline/presentation/stage_list_screen.dart
git commit -m "feat: 关卡行 info 图标改弹战前情报（替掉落传闻）"
```

---

### Task 4: 关卡列表测试断言点击弹战前情报

**Files:**
- Modify: `test/features/mainline/presentation/stage_list_screen_test.dart`

- [ ] **Step 1: 在文件末尾 `}` 之前（`:176` 后）新增 testWidgets**

```dart
  testWidgets('点行尾 info 图标 → 弹战前情报（含敌阵段）而非纯掉落', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.prebattleIntelEnemySection),
      findsOneWidget,
      reason: 'info 图标升级为战前情报入口，含行内没有的敌阵详列',
    );
  });
```

- [ ] **Step 2: 跑该测试文件**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test --no-pub test/features/mainline/presentation/stage_list_screen_test.dart`
Expected: All tests passed!（含原有用例 + 新增 1）。
若 `pumpAndSettle` 超时（弹窗动画/sfx 未停）：改为 `await tester.pump(); await tester.pump(const Duration(milliseconds: 400));`。

- [ ] **Step 3: 提交**

```bash
git add test/features/mainline/presentation/stage_list_screen_test.dart
git commit -m "test: 关卡行 info 图标点击弹战前情报断言"
```

---

### Task 5: 全量验证

- [ ] **Step 1: 全仓 analyze**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze`
Expected: No issues found!

- [ ] **Step 2: 全量测试**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test --no-pub -j1`
Expected: 全绿，约 3282 passed/1 skip/0 fail（基线 3280 + 新增 dialog 2 测；stage_list 新增 1 测，按实际计数为准，不写死）。

- [ ] **Step 3: 真机目检（spec 验收 §6）**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter run -d macos`
人工核：① 点关卡行直接进战斗（无强制弹窗）② 点行尾 info → 弹「战前情报 · 关卡名」四段、无整备/推荐境界/难度冗余行、单「关闭」按钮 ③ 弹窗排版与信息密度可读。

---

## Self-Review

**Spec coverage：**
- 触发=复用 info 图标 onPressed → Task 3 ✓
- 纯查看 Future<void> + 单关闭按钮 → Task 2 Step 3 ✓
- 四段（敌阵/应对/风险/可能收获）→ Task 2 Step 3 `StageIntelContent` ✓
- 删整备段 + 推荐境界/难度/realmReady/Low/Unknown + riskRealmLow → Task 1 不新增这些常量 + Task 2 实现不含 → ✓
- 「整备」段标题改「应对」=`prebattleIntelResponseSection` → Task 1 ✓
- loot_rumor_dialog 不动、仅改 stage_list 一个 onPressed → Task 3 ✓
- 复用 LootRumorContent → Task 2 Step 3 ✓
- 文案/测试/wiring 改动文件清单 → Task 1-4 全覆盖 ✓
- 验收 1-6 → Task 5 ✓

**Placeholder scan：** 无 TBD/TODO，每步含完整代码或确切命令。✓

**Type consistency：** `StageIntelContent`/`showStageIntelDialog`/`_IntelLines`/`_RiskIntel({required stage})`/`prebattleIntelResponseSection` 在 Task 1-4 间命名一致；`PaperDialog.show<void>` + `PlaqueButton(primary, onTap)` 与现仓签名一致（已核 `paper_dialog.dart`）。✓
