# 第七阶段 批一 · 战后体验 实施计划(英雄镜头 + 珍稀掉落触发细化)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Boss 首胜后弹「英雄镜头」(本场最高输出角色立绘切入),并把珍稀掉落展示从 binary gate 细化到「利器+首次获得 / 重器+每次」。

**Architecture:** 纯表现层。新增纯函数 `TopDamageContributor.from(BattleState)`(读 actionLog 派生最高输出角色)+ 纯展示 `HeroCameraOverlay`;在两条交互结算 flow(mainline `_applyVictoryResolution` / tower 结算)各派生 `HeroCameraData?` 并在 `presentVictoryCeremony` 之前、`isBossStage && isFirstClear` 时弹镜头。珍稀掉落给 `pickTreasureHighlight` 加 `extraDisplayTiers` 集合,flow 层用库存计数判「利器首次」。不写 `BattleState`、不调伤害公式、不改掉落经济(GDD §5.4)。

**Tech Stack:** Flutter Desktop · Riverpod 3 · Isar · `flutter test` / `flutter analyze`。数值进 `data/numbers.yaml` + `lib/data/numbers_config.dart`;中文进 `lib/shared/strings.dart`(`UiStrings`)/ `EnumL10n`。

> **关键事实(已核实)**:玩家方 `teamSide==0`;`BattleAction.actorId == BattleCharacter.characterId == Character.id`(strategy 5 处 + `battle_state.dart:341`);final 战斗态经 `ref.read(battleProvider)` 取(胜利时 BattleScreen 仍在栈);`presentVictoryCeremony` 全仓仅 `stage_entry_flow:218` + `tower_entry_flow` `_showVictoryDialog` 两处(离线走 `offline_recap_service` 不经此 → §5.5 天然守);立绘素材 `assets/characters/{founder,first_disciple,second_disciple}.png` 现成,`Character.portraitPath` 字段已有。

---

## Task 1: `TopDamageContributor` 纯函数派生

**Files:**
- Create: `lib/features/battle/domain/top_damage_contributor.dart`
- Test: `test/features/battle/top_damage_contributor_test.dart`

- [ ] **Step 1: 写失败测试**(fixture 体例对齐 `battle_diagnosis_test.dart` 的 `_player/_enemy/_hit`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/top_damage_contributor.dart';

final _skill = SkillDef(id: 'atk', name: '普攻', type: SkillType.normal, powerMultiplier: 1.0);

BattleCharacter _p(int id, int slot) => BattleCharacter(
      characterId: id, name: '弟子$id', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.ruMen, school: TechniqueSchool.gangMeng,
      maxHp: 1000, currentHp: 1000, maxInternalForce: 500, currentInternalForce: 500,
      speed: 100, criticalRate: 0.05, evasionRate: 0.0, defenseRate: 0.1,
      totalEquipmentAttack: 100, mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const [], skillCooldowns: const {}, skillUses: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: true, teamSide: 0, slotIndex: slot);
BattleCharacter _e(int id) => BattleCharacter(
      characterId: id, name: '敌$id', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.ruMen, school: TechniqueSchool.gangMeng,
      maxHp: 1000, currentHp: 0, maxInternalForce: 0, currentInternalForce: 0,
      speed: 100, criticalRate: 0.05, evasionRate: 0.0, defenseRate: 0.1,
      totalEquipmentAttack: 100, mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const [], skillCooldowns: const {}, skillUses: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: false, teamSide: 1, slotIndex: 0);
BattleAction _act(int actorId, int dmg) => BattleAction(
      tick: 1, actorId: actorId, targetId: 1, skill: _skill,
      attackResult: const AttackResult(finalDamage: 0, isCritical: false)
          .copyWith(finalDamage: dmg),
      description: '');
BattleState _won(List<BattleCharacter> left, List<BattleAction> log) => BattleState(
      leftTeam: left, rightTeam: [_e(1)], tick: 50,
      result: BattleResult.leftWin, actionLog: log);

void main() {
  test('单玩家 → 取该玩家', () {
    final s = _won([_p(100, 0)], [_act(100, 300), _act(100, 200)]);
    final t = TopDamageContributor.from(s);
    expect(t!.actorId, 100);
    expect(t.totalDamage, 500);
  });
  test('多玩家 → 取最高输出', () {
    final s = _won([_p(100, 0), _p(101, 1)], [_act(100, 300), _act(101, 900)]);
    expect(TopDamageContributor.from(s)!.actorId, 101);
  });
  test('平局 → 取 slotIndex 小者', () {
    final s = _won([_p(100, 1), _p(101, 0)], [_act(100, 500), _act(101, 500)]);
    expect(TopDamageContributor.from(s)!.actorId, 101);
  });
  test('敌方伤害不计入', () {
    final s = _won([_p(100, 0)], [_act(100, 100), _act(1, 9999)]);
    final t = TopDamageContributor.from(s);
    expect(t!.actorId, 100);
    expect(t.totalDamage, 100);
  });
  test('无玩家伤害 → null', () {
    final s = _won([_p(100, 0)], [_act(1, 500)]);
    expect(TopDamageContributor.from(s), isNull);
  });
}
```

> 注:若 `AttackResult` 无 `copyWith`/默认构造不便,直接用其真实构造(实装时按 `damage_calculator.dart` 的 `AttackResult` 字段填,沿 `_hit` 体例)。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/top_damage_contributor_test.dart`
Expected: FAIL —— `top_damage_contributor.dart` 不存在 / `TopDamageContributor` 未定义。

- [ ] **Step 3: 写实现**

```dart
import 'battle_state.dart';

/// 本场最高输出玩家(从 [BattleState.actionLog] 派生,纯函数)。
/// 用于战后英雄镜头出镜角色。仅计玩家方(teamSide==0)。
class TopDamageContributor {
  final int actorId; // == Character.id
  final int totalDamage;
  const TopDamageContributor({required this.actorId, required this.totalDamage});

  static TopDamageContributor? from(BattleState state) {
    final playerSlot = <int, int>{};
    for (final c in [...state.leftTeam, ...state.rightTeam]) {
      if (c.teamSide == 0) playerSlot[c.characterId] = c.slotIndex;
    }
    if (playerSlot.isEmpty) return null;
    final byActor = <int, int>{};
    for (final a in state.actionLog) {
      final r = a.attackResult;
      if (r == null || !playerSlot.containsKey(a.actorId)) continue;
      byActor[a.actorId] = (byActor[a.actorId] ?? 0) + r.finalDamage;
    }
    if (byActor.isEmpty) return null;
    int? bestId;
    var bestDmg = -1;
    byActor.forEach((id, dmg) {
      if (bestId == null ||
          dmg > bestDmg ||
          (dmg == bestDmg && playerSlot[id]! < playerSlot[bestId]!)) {
        bestId = id;
        bestDmg = dmg;
      }
    });
    return TopDamageContributor(actorId: bestId!, totalDamage: bestDmg);
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/top_damage_contributor_test.dart`
Expected: PASS(5 测)。

- [ ] **Step 5: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/battle/domain/top_damage_contributor.dart test/features/battle/top_damage_contributor_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(第七阶段): TopDamageContributor 本场最高输出派生 + 测"
```

---

## Task 2: numbers.yaml `post_battle.hero_camera` + `HeroCameraConfig` + UiStrings

**Files:**
- Modify: `data/numbers.yaml`(新增顶层 `post_battle:` 段)
- Modify: `lib/data/numbers_config.dart`(新 `HeroCameraConfig` 类 + `NumbersConfig.heroCamera` 字段 + fromYaml 接线)
- Modify: `lib/shared/strings.dart`(`UiStrings` 词条)
- Test: `test/data/numbers_config_test.dart`(若存在则追加;否则新建最小测)

- [ ] **Step 1: 写失败测试**(numbers_config 解析)

```dart
// 追加到 numbers_config 解析测(沿现有体例 loadNumbersConfig / NumbersConfig.fromYaml)
test('post_battle.hero_camera 解析', () {
  final cfg = /* 现有测里加载真实 numbers.yaml 的方式 */;
  expect(cfg.heroCamera.holdSeconds, greaterThan(0));
  expect(cfg.heroCamera.holdSeconds, lessThanOrEqualTo(4));
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/numbers_config_test.dart`
Expected: FAIL —— `heroCamera` 未定义。

- [ ] **Step 3: 写实现**

`data/numbers.yaml` 顶层新增:

```yaml
# 战后体验(第七阶段 批一)。英雄镜头表现参数(纯表现层,不参与战斗结算)。
post_battle:
  hero_camera:
    hold_seconds: 3.0       # 自动消失时长(2-4s,点击可跳过)
    portrait_slide_px: 48   # 立绘侧滑入位移
    portrait_scale_from: 0.88  # 立绘起始缩放(放大到 1.0)
```

`lib/data/numbers_config.dart` —— 新 config 类(沿 `TreasureDropConfig` 体例):

```dart
/// 战后英雄镜头表现参数(第七阶段 批一)。顶层 `post_battle.hero_camera` 段。
class HeroCameraConfig {
  final double holdSeconds;
  final double portraitSlidePx;
  final double portraitScaleFrom;
  const HeroCameraConfig({
    required this.holdSeconds,
    required this.portraitSlidePx,
    required this.portraitScaleFrom,
  });
  static const empty = HeroCameraConfig(
      holdSeconds: 3.0, portraitSlidePx: 48, portraitScaleFrom: 0.88);
  factory HeroCameraConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return HeroCameraConfig(
      holdSeconds: (y['hold_seconds'] as num?)?.toDouble() ?? empty.holdSeconds,
      portraitSlidePx:
          (y['portrait_slide_px'] as num?)?.toDouble() ?? empty.portraitSlidePx,
      portraitScaleFrom: (y['portrait_scale_from'] as num?)?.toDouble() ??
          empty.portraitScaleFrom,
    );
  }
}
```

`NumbersConfig` 加字段 + 默认 + fromYaml 接线(分别在字段区、`empty`/默认构造、`fromYaml` 三处):

```dart
// 字段区(treasureDrop 之后):
final HeroCameraConfig heroCamera;

// fromYaml 内(treasureDrop 接线之后):
heroCamera: HeroCameraConfig.fromYaml(
  ((y['post_battle'] as Map?)?.cast<String, dynamic>()?['hero_camera'] as Map?)
      ?.cast<String, dynamic>(),
),
```
> 若 `NumbersConfig` 有 `empty`/const 默认实例,同步加 `heroCamera: HeroCameraConfig.empty`。构造函数 `required this.heroCamera`。

`lib/shared/strings.dart` —— `UiStrings` 加(集中 sink,§5.6):

```dart
static const heroCameraVanquished = '击破';   // 「击破 {bossName}」前缀
static String heroCameraDefeated(String bossName) => '击破 $bossName';
static const heroCameraTopOutput = '本场最强';  // 名号横幅副标
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/numbers_config_test.dart`
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add data/numbers.yaml lib/data/numbers_config.dart lib/shared/strings.dart test/data/numbers_config_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(第七阶段): post_battle.hero_camera 配置 + HeroCameraConfig + UiStrings"
```

---

## Task 3: `HeroCameraData` + `HeroCameraOverlay` + `presentHeroCamera`

**Files:**
- Create: `lib/features/battle/presentation/hero_camera_overlay.dart`
- Modify: `lib/features/battle/presentation/victory_ceremony.dart`(加 `presentHeroCamera`)
- Test: `test/features/battle/hero_camera_overlay_test.dart`

- [ ] **Step 1: 写失败 widget 测**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/hero_camera_overlay.dart';

void main() {
  const data = HeroCameraData(
      portraitPath: 'assets/characters/founder.png',
      heroName: '祖师', realmLabel: '三流', bossName: '黑袍人', topDamage: 1234);

  testWidgets('渲染名号 + 击破题字', (t) async {
    await t.pumpWidget(MaterialApp(
        home: HeroCameraOverlay(data: data, onDone: () {})));
    expect(find.text('祖师'), findsOneWidget);
    expect(find.textContaining('黑袍人'), findsOneWidget);
  });

  testWidgets('portraitPath==null 走退化不抛', (t) async {
    await t.pumpWidget(MaterialApp(
        home: HeroCameraOverlay(
            data: const HeroCameraData(
                portraitPath: null, heroName: '弟子', realmLabel: '三流',
                bossName: 'X', topDamage: 1),
            onDone: () {})));
    expect(find.text('弟子'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击触发 onDone', (t) async {
    var done = false;
    await t.pumpWidget(MaterialApp(
        home: HeroCameraOverlay(data: data, onDone: () => done = true)));
    await t.tap(find.byType(HeroCameraOverlay));
    expect(done, isTrue);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/hero_camera_overlay_test.dart`
Expected: FAIL —— `hero_camera_overlay.dart` 不存在。

- [ ] **Step 3: 写实现**(纯展示,体例对齐 `victory_overlay.dart` / `victory_ceremony.dart` 的 vignette + 印章 + Image.asset errorBuilder)

```dart
import 'package:flutter/material.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 英雄镜头数据(由战后结算 flow 派生)。
class HeroCameraData {
  final String? portraitPath;
  final String heroName;
  final String realmLabel;
  final String bossName;
  final int topDamage;
  const HeroCameraData({
    required this.portraitPath,
    required this.heroName,
    required this.realmLabel,
    required this.bossName,
    required this.topDamage,
  });
}

/// Boss 首胜英雄镜头 overlay(立绘切入)。纯展示;点击任意处 onDone。
class HeroCameraOverlay extends StatefulWidget {
  final HeroCameraData data;
  final VoidCallback onDone;
  const HeroCameraOverlay({super.key, required this.data, required this.onDone});
  @override
  State<HeroCameraOverlay> createState() => _HeroCameraOverlayState();
}

class _HeroCameraOverlayState extends State<HeroCameraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
        ..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTap: widget.onDone,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [Color(0x33000000), Color(0xCC000000)],
            stops: [0.45, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeOut.transform(_c.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                // 立绘侧滑入 + 放大(portraitPath==null/缺失 → 退化空)
                if (d.portraitPath != null)
                  Transform.translate(
                    offset: Offset((1 - t) * 48, 0),
                    child: Transform.scale(
                      scale: 0.88 + 0.12 * t,
                      child: Opacity(
                        opacity: t,
                        child: Image.asset(d.portraitPath!,
                            height: 280, fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d.heroName,
                        style: const TextStyle(
                            color: WuxiaColors.resultHighlight,
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    Text(d.realmLabel,
                        style: const TextStyle(
                            color: WuxiaColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(UiStrings.heroCameraDefeated(d.bossName),
                        style: const TextStyle(
                            color: WuxiaColors.resultHighlight, fontSize: 20)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```
> 颜色 token(`WuxiaColors.resultHighlight/textSecondary`)实装时按 `colors.dart` 真有的字段对齐(`victory_overlay.dart` 已用 `resultHighlight`)。

`victory_ceremony.dart` 加(`showVictorySealFlash` 旁,沿 showGeneralDialog 体例;时长读 numbers):

```dart
/// 弹英雄镜头并 await 至消失(numbers hold_seconds 或点击跳过)。
Future<void> presentHeroCamera(BuildContext context, HeroCameraData data) async {
  if (!context.mounted) return;
  final hold = GameRepository.isLoaded
      ? GameRepository.instance.numbers.heroCamera.holdSeconds
      : 3.0;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => HeroCameraOverlay(
        data: data, onDone: () => Navigator.of(ctx).maybePop()),
  );
}
```
> 自动消失:在 overlay 内用 `Future.delayed(holdSeconds)` 调 onDone,或 presenter 起 timer。实装时择一,守 mounted。需 `import 'hero_camera_overlay.dart';` + `import '../../../data/game_repository.dart';`(沿文件现有 import)。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/hero_camera_overlay_test.dart`
Expected: PASS(3 测)。

- [ ] **Step 5: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/battle/presentation/hero_camera_overlay.dart lib/features/battle/presentation/victory_ceremony.dart test/features/battle/hero_camera_overlay_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(第七阶段): HeroCameraOverlay 立绘切入 + presentHeroCamera"
```

---

## Task 4: 接线主线 flow(派生 HeroCameraData + Boss首胜 gate)

**Files:**
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`
  - `_applyVictoryResolution`(:635-)record 加 `HeroCameraData? heroCamera` + 派生逻辑(用 `finalState` + `characters` + `stage`)
  - 调用点(:217-218)在 `presentVictoryCeremony` 之前插 gate
- Create: gate 谓词 + 测 `test/features/battle/hero_camera_gate_test.dart`

- [ ] **Step 1: 写失败测试**(gate 谓词纯函数)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/hero_camera_overlay.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';

void main() {
  const data = HeroCameraData(
      portraitPath: null, heroName: 'x', realmLabel: 'y', bossName: 'z', topDamage: 1);
  test('Boss 首胜 + 有数据 → 弹', () {
    expect(shouldShowHeroCamera(isBoss: true, isFirstClear: true, data: data), isTrue);
  });
  test('非 Boss → 不弹', () {
    expect(shouldShowHeroCamera(isBoss: false, isFirstClear: true, data: data), isFalse);
  });
  test('非首胜 → 不弹', () {
    expect(shouldShowHeroCamera(isBoss: true, isFirstClear: false, data: data), isFalse);
  });
  test('无数据 → 不弹', () {
    expect(shouldShowHeroCamera(isBoss: true, isFirstClear: true, data: null), isFalse);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/hero_camera_gate_test.dart`
Expected: FAIL —— `shouldShowHeroCamera` 未定义。

- [ ] **Step 3: 写实现**

`victory_ceremony.dart` 加谓词:

```dart
/// 英雄镜头 gate:仅 Boss 首胜且有出镜数据时弹。
bool shouldShowHeroCamera({
  required bool isBoss,
  required bool isFirstClear,
  required HeroCameraData? data,
}) =>
    isBoss && isFirstClear && data != null;
```

`stage_entry_flow.dart` —— `_applyVictoryResolution` record 类型加字段 + 派生(在已取得 `characters` 之后、return 前):

```dart
// record 类型(:635-641)追加:
//   HeroCameraData? heroCamera,

// 派生(用 finalState/characters/stage;import top_damage_contributor.dart + hero_camera_overlay.dart):
HeroCameraData? heroCamera;
final top = TopDamageContributor.from(finalState);
if (top != null) {
  Character? hero;
  for (final c in characters) {
    if (c.id == top.actorId) { hero = c; break; }
  }
  if (hero != null) {
    final bossName = stage.enemyTeam.isNotEmpty
        ? stage.enemyTeam.last.name : stage.name;
    heroCamera = HeroCameraData(
      portraitPath: hero.portraitPath,
      heroName: hero.name,
      realmLabel: EnumL10n.realmTier(hero.realmTier),
      bossName: bossName,
      topDamage: top.totalDamage,
    );
  }
}
// return record 里加 heroCamera: heroCamera,
```

调用点(:217-218 块内,`presentVictoryCeremony` 之前):

```dart
if (outcome != null && context.mounted) {
  final firstClear = !clearedBeforeVictory.contains(stage.id);
  if (shouldShowHeroCamera(
      isBoss: stage.isBossStage,
      isFirstClear: firstClear,
      data: outcome.heroCamera)) {
    await presentHeroCamera(context, outcome.heroCamera!);
    if (!context.mounted) return;
  }
  await presentVictoryCeremony(context, outcome.drops, treasureGate: true);
  // ... 其余不变
```
> import:`top_damage_contributor.dart` / `hero_camera_overlay.dart` / 确认 `EnumL10n`(`enum_localizations.dart`)已 import,`Character` 已 import。

- [ ] **Step 4: 跑测试确认通过 + 全量 analyze**

Run: `flutter test test/features/battle/hero_camera_gate_test.dart && flutter analyze`
Expected: gate 测 PASS;analyze 0(确认 record 字段 + import 无误)。

- [ ] **Step 5: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/battle/presentation/victory_ceremony.dart lib/features/mainline/presentation/stage_entry_flow.dart test/features/battle/hero_camera_gate_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(第七阶段): 主线 Boss 首胜接英雄镜头 + gate 谓词"
```

---

## Task 5: 接线爬塔 flow(对称)

**Files:**
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart`
  - tower 结算函数(`~328-`,体例对齐主线 `_applyVictoryResolution`)record 加 `HeroCameraData? heroCamera` + 同 Task 4 派生(`floor.enemyTeam.last.name` 作 bossName)
  - `_showVictoryDialog`(`~575-`)加 `HeroCameraData? heroCamera` 参 + 在 `presentVictoryCeremony` 之前插 `shouldShowHeroCamera(isBoss: floor.isBoss, isFirstClear: isFirstClear, data: heroCamera)` gate
  - 调用 `_showVictoryDialog` 处把结算函数返回的 heroCamera 传入

- [ ] **Step 1: 写失败测试**(tower gate 复用 Task 4 的 `shouldShowHeroCamera`,无新谓词;此 Task 以 analyze + 既有 tower flow 测兜底回归)

无新单测谓词(gate 已测)。本 Task 验收 = `flutter analyze` 0 + 既有 tower flow 测不回归。

- [ ] **Step 2: 跑基线**

Run: `flutter test test/features/tower/ && flutter analyze`
Expected: 记录当前 PASS 数(baseline)。

- [ ] **Step 3: 写实现**

tower 结算函数派生 heroCamera(与 Task 4 同构,`stage.enemyTeam`→`floor.enemyTeam`、`EnumL10n.realmTier(hero.realmTier)`):

```dart
HeroCameraData? heroCamera;
final top = TopDamageContributor.from(finalState);
if (top != null) {
  Character? hero;
  for (final c in characters) { if (c.id == top.actorId) { hero = c; break; } }
  if (hero != null) {
    heroCamera = HeroCameraData(
      portraitPath: hero.portraitPath,
      heroName: hero.name,
      realmLabel: EnumL10n.realmTier(hero.realmTier),
      bossName: floor.enemyTeam.isNotEmpty ? floor.enemyTeam.last.name : '楼层 Boss',
      topDamage: top.totalDamage,
    );
  }
}
// 结算 record 加 heroCamera 字段并返回;调用方传入 _showVictoryDialog。
```

`_showVictoryDialog` 签名加 `HeroCameraData? heroCamera,`,体内 `presentVictoryCeremony` 之前:

```dart
if (shouldShowHeroCamera(
    isBoss: floor.isBoss, isFirstClear: isFirstClear, data: heroCamera)) {
  await presentHeroCamera(context, heroCamera!);
  if (!context.mounted) return;
}
await presentVictoryCeremony(context, drops, treasureGate: isFirstClear);
```
> import `top_damage_contributor.dart` / `hero_camera_overlay.dart` / `victory_ceremony.dart` / `enum_localizations.dart`(按 tower flow 现有 import 补)。「楼层 Boss」兜底中文若散写则改走 `UiStrings`(Task 2 可加 `heroCameraFloorBossFallback`)。

- [ ] **Step 4: 跑回归 + analyze**

Run: `flutter test test/features/tower/ && flutter analyze`
Expected: PASS 数 ≥ baseline;analyze 0。

- [ ] **Step 5: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/tower/presentation/tower_entry_flow.dart lib/shared/strings.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(第七阶段): 爬塔大Boss 首胜接英雄镜头(对称主线)"
```

---

## Task 6: 珍稀掉落触发细化(利器+首次)

**Files:**
- Modify: `lib/features/equipment/domain/treasure_highlight.dart`(`pickTreasureHighlight` 加 `extraDisplayTiers`)
- Modify: `lib/features/equipment/presentation/treasure_drop_overlay.dart`(`playTreasureDropIfAny` 加 `extraDisplayTiers` 参,透传)
- Modify: `stage_entry_flow.dart` + `tower_entry_flow.dart`(flow 层算「利器首次」集合并传入)
- Test: `test/features/equipment/treasure_highlight_test.dart`(追加/新建)

- [ ] **Step 1: 写失败测试**(`pickTreasureHighlight` 选取逻辑)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';

TreasureHighlight _hl(EquipmentTier t) => TreasureHighlight(
    defId: 'x', name: 'x', tier: t, slot: EquipmentSlot.weapon,
    iconPath: '', attack: 1, health: 1, speed: 1, tagline: '');

void main() {
  test('利器在 extraDisplayTiers → 被选(虽 < minTier=重器)', () {
    final hl = pickTreasureHighlight([_hl(EquipmentTier.liQi)],
        EquipmentTier.zhongQi, extraDisplayTiers: {EquipmentTier.liQi});
    expect(hl, isNotNull);
    expect(hl!.tier, EquipmentTier.liQi);
  });
  test('利器不在 extraDisplayTiers → 过滤(< minTier)', () {
    final hl = pickTreasureHighlight([_hl(EquipmentTier.liQi)],
        EquipmentTier.zhongQi, extraDisplayTiers: const {});
    expect(hl, isNull);
  });
  test('重器 ≥ minTier → 始终选(extra 空也选)', () {
    final hl = pickTreasureHighlight([_hl(EquipmentTier.zhongQi)],
        EquipmentTier.zhongQi, extraDisplayTiers: const {});
    expect(hl, isNotNull);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/equipment/treasure_highlight_test.dart`
Expected: FAIL —— `pickTreasureHighlight` 无 `extraDisplayTiers` 命名参。

- [ ] **Step 3: 写实现**

`treasure_highlight.dart` `pickTreasureHighlight`(:35)签名加可选参 + 选取条件:

```dart
TreasureHighlight? pickTreasureHighlight(
  List<TreasureHighlight> candidates,
  EquipmentTier minTier, {
  Set<EquipmentTier> extraDisplayTiers = const {},
}) {
  TreasureHighlight? best;
  for (final c in candidates) {
    final eligible =
        c.tier.index >= minTier.index || extraDisplayTiers.contains(c.tier);
    if (!eligible) continue;
    if (best == null || c.tier.index > best.tier.index) best = c;
  }
  return best;
}
```
> 若原函数已有「取最高 tier」逻辑,保留语义只加 `eligible` 的 extra 分支。

`treasure_drop_overlay.dart` `playTreasureDropIfAny`(:373)加参透传:

```dart
Future<bool> playTreasureDropIfAny(
    BuildContext context, DropResult drops,
    {required bool gate,
    Set<EquipmentTier> extraDisplayTiers = const {}}) async {
  // ...
  final hl = pickTreasureHighlight(candidates, minTier,
      extraDisplayTiers: extraDisplayTiers);
  // ...
}
```

`presentVictoryCeremony`(:151)同步加 `extraDisplayTiers` 参透传给 `playTreasureDropIfAny`。

flow 层算「利器首次」(主线 `_applyVictoryResolution` 内,drops putAll 入库之后;有 `isar` + `drops`):

```dart
// 利器首次:本次掉落含 liQi 且玩家先前无 liQi 装备
Future<Set<EquipmentTier>> _firstAcquisitionTiers(
    Isar isar, DropResult drops) async {
  final droppedLiQi = drops.equipments.where((e) =>
      GameRepository.instance.getEquipment(e.defId).tier == EquipmentTier.liQi);
  if (droppedLiQi.isEmpty) return const {};
  final all = await isar.equipments.where().findAll();
  var liQiCount = 0;
  for (final e in all) {
    if (GameRepository.instance.getEquipment(e.defId).tier == EquipmentTier.liQi) {
      liQiCount++;
    }
  }
  // 入库后总数 == 本次掉落件数 → 先前为 0 → 首次
  return liQiCount <= droppedLiQi.length ? {EquipmentTier.liQi} : const {};
}
```
把结果经 outcome record 带出(加 `Set<EquipmentTier> extraDisplayTiers`),调用点 `presentVictoryCeremony(context, outcome.drops, treasureGate: true, extraDisplayTiers: outcome.extraDisplayTiers)`。tower flow 同构(tower 结算函数算 + `_showVictoryDialog` 透传)。

- [ ] **Step 4: 跑测试确认通过 + analyze**

Run: `flutter test test/features/equipment/treasure_highlight_test.dart && flutter analyze`
Expected: PASS(3 测);analyze 0。

- [ ] **Step 5: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/equipment/domain/treasure_highlight.dart lib/features/equipment/presentation/treasure_drop_overlay.dart lib/features/mainline/presentation/stage_entry_flow.dart lib/features/tower/presentation/tower_entry_flow.dart test/features/equipment/treasure_highlight_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(第七阶段): 珍稀掉落细化 利器+首次(extraDisplayTiers)"
```

---

## Task 7: 全量回归 + PROGRESS + 收尾

**Files:**
- Modify: `PROGRESS.md`(顶段加续26 一条,≤同体例)

- [ ] **Step 1: 全量 analyze + test**

Run: `flutter analyze && flutter test`
Expected: analyze **0**;全量 PASS,测数 = baseline(2418)+ 本批新增(预计 +11~14:5 TopDamage + 3 overlay + 4 gate + 3 treasure,去重)。**实测后把真实测数写进 PROGRESS,禁转抄。**

> 若 fresh worktree 报 `.g.dart` 缺失 / `libisar.dylib` 截断:跑 `dart run build_runner build --delete-conflicting-outputs`;dylib 截断从主仓拷(memory `feedback_fresh_worktree_libisar_dylib`)。

- [ ] **Step 2: 红线核对**

确认:本批 0 处写 `BattleState`、0 处改 `damage_calculator`、0 处改掉落概率/经济;新数值全在 `numbers.yaml`;新中文全在 `UiStrings`/`EnumL10n`。
Run: `grep -rn "BattleState(" lib/features/battle/presentation/hero_camera_overlay.dart`(预期空)。

- [ ] **Step 3: 更新 PROGRESS.md**

顶段加续26(英雄镜头 Boss首胜立绘切入 + 珍稀掉落利器首次细化 · 测数实测 · 红线守 · 视觉验收待真机)。

- [ ] **Step 4: 提交**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add PROGRESS.md
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "docs(第七阶段): PROGRESS 续26 - 批一战后体验闭环"
```

---

## 自审(spec 覆盖 / 占位 / 类型一致)

- **spec 覆盖**:英雄镜头(§3/§4/§5 → Task 1/3/4/5)· 珍稀掉落细化(§6 → Task 6)· 红线/测试(§7/§8 → 各 Task + Task 7)· deferred 项不实装(技能书/队伍跳转/材料/zoom)。✅
- **类型一致**:`HeroCameraData` 字段(portraitPath/heroName/realmLabel/bossName/topDamage)Task 3 定义,Task 4/5 构造一致;`TopDamageContributor.{actorId,totalDamage}` Task 1 定义,Task 4/5 引用一致;`shouldShowHeroCamera({isBoss,isFirstClear,data})` Task 4 定义,Task 5 复用;`pickTreasureHighlight(..., {extraDisplayTiers})` Task 6 定义并被 `playTreasureDropIfAny`/`presentVictoryCeremony` 透传。✅
- **占位**:Task 2 numbers_config 测的「现有加载方式」为体例适配点(实装按 `numbers_config_test.dart` 真有的加载法),非逻辑占位。其余步骤均含真实代码。

## 视觉验收(非自动测覆盖)

英雄镜头 = 立绘滑入/缩放动效,单帧截不出全貌;用户真机 `flutter run -d macos` 打章末 Boss 首胜目检(立绘切入/名号/击破题字/金光晕/2-4s 时长/点击跳过)。珍稀掉落利器首次可静态截。
