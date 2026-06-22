# 爆品展示动画 + reward 音效重做 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 高阶装备(重器+)掉落时先播一段水墨印章盖落全屏动画(墨团背景+震屏+tier 色梯度),再照常进结算弹窗;reward 音效门槛化(只高阶爆品才响)并重做素材。

**Architecture:** 纯函数 `pickTreasureHighlight` 筛出 ≥门槛最高 tier 的爆品 → `TreasureDropOverlay`(showGeneralDialog 调起的自管动画 widget) → 公共 `playTreasureDropIfAny` 在主线/塔结算弹窗前 await 播放。门槛进 numbers.yaml,删除两处旧 reward 触发(移到动画层)。

**Tech Stack:** Flutter(AnimationController + showGeneralDialog), Isar/Riverpod(既有), YAML numbers config。

参考 spec: `docs/superpowers/specs/2026-06-11-treasure-drop-animation-design.md`

---

### Task 1: numbers.yaml 门槛配置 + TreasureDropConfig 解析

**Files:**
- Modify: `data/numbers.yaml`(skill_unlock 块后加 treasure_drop)
- Modify: `lib/data/numbers_config.dart`(加 TreasureDropConfig + 顶层 wire)
- Test: `test/data/numbers_config_test.dart`(若无则新建)

- [ ] **Step 1: numbers.yaml 加配置块**(在 `skill_unlock:` 块 line ~1665 后):

```yaml
# 爆品展示动画门槛(2026-06-11 真玩验收):装备 tier ≥ 此阶才播印章盖落动画 + reward 音。
treasure_drop:
  min_tier: zhongQi   # 寻常货/像样货/好家伙/利器/重器/宝物/神物 — 默认重器(5阶)及以上
```

- [ ] **Step 2: 写失败测试**(`test/data/numbers_config_test.dart` 加 group;若文件不存在则建,import `package:wuxia_idle/data/numbers_config.dart` + enums):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  group('TreasureDropConfig', () {
    test('解析 min_tier', () {
      final c = TreasureDropConfig.fromYaml({'min_tier': 'zhongQi'});
      expect(c.minTier, EquipmentTier.zhongQi);
    });
    test('空/缺字段兜底重器', () {
      expect(TreasureDropConfig.fromYaml(null).minTier, EquipmentTier.zhongQi);
      expect(TreasureDropConfig.fromYaml({}).minTier, EquipmentTier.zhongQi);
    });
  });
}
```

- [ ] **Step 3: 跑测试确认失败**：`flutter test test/data/numbers_config_test.dart` → FAIL(TreasureDropConfig 未定义)。

- [ ] **Step 4: 加 TreasureDropConfig**(numbers_config.dart 末尾,沿 SkillUnlockConfig:2273 体例):

```dart
/// 爆品展示动画门槛(2026-06-11)。顶层 `treasure_drop` 段。
class TreasureDropConfig {
  final EquipmentTier minTier;
  const TreasureDropConfig({required this.minTier});

  static const empty = TreasureDropConfig(minTier: EquipmentTier.zhongQi);

  factory TreasureDropConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    final name = y['min_tier'] as String?;
    if (name == null) return empty;
    return TreasureDropConfig(minTier: EquipmentTier.values.byName(name));
  }
}
```

- [ ] **Step 5: 顶层 wire**(numbers_config.dart):① Numbers 类加字段 `final TreasureDropConfig treasureDrop;` ② 构造器 required 参数 `required this.treasureDrop,` ③ fromYaml 中(skillUnlock:259 解析旁)加 `treasureDrop: TreasureDropConfig.fromYaml((y['treasure_drop'] as Map?)?.cast<String, dynamic>()),`。grep `skillUnlock:` 确认三处都补上(字段声明/构造器/fromYaml)。

- [ ] **Step 6: 跑测试确认通过 + analyze**：`flutter test test/data/numbers_config_test.dart && flutter analyze lib/data/numbers_config.dart` → PASS / No issues。

- [ ] **Step 7: Commit**：

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/numbers_config_test.dart
git commit -m "[schema] 爆品动画门槛 treasure_drop.min_tier(默认重器)"
```

---

### Task 2: TreasureHighlight 值对象 + pickTreasureHighlight 纯函数

**Files:**
- Create: `lib/features/equipment/domain/treasure_highlight.dart`
- Test: `test/features/equipment/domain/treasure_highlight_test.dart`

- [ ] **Step 1: 写失败测试**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';

TreasureHighlight _c(String id, EquipmentTier tier) => TreasureHighlight(
      defId: id, name: id, tier: tier,
      slot: EquipmentSlot.weapon, iconPath: 'x.png');

void main() {
  group('pickTreasureHighlight', () {
    const min = EquipmentTier.zhongQi;
    test('空候选 → null', () {
      expect(pickTreasureHighlight(const [], min), isNull);
    });
    test('全低阶(利器) → null', () {
      expect(pickTreasureHighlight([_c('a', EquipmentTier.liQi)], min), isNull);
    });
    test('重器边界 → 触发', () {
      expect(pickTreasureHighlight([_c('a', EquipmentTier.zhongQi)], min)?.defId, 'a');
    });
    test('多件取最高 tier', () {
      final r = pickTreasureHighlight(
        [_c('a', EquipmentTier.zhongQi), _c('b', EquipmentTier.baoWu), _c('c', EquipmentTier.liQi)],
        min);
      expect(r?.defId, 'b');
    });
    test('并列最高取首件', () {
      final r = pickTreasureHighlight(
        [_c('a', EquipmentTier.shenWu), _c('b', EquipmentTier.shenWu)], min);
      expect(r?.defId, 'a');
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**：`flutter test test/features/equipment/domain/treasure_highlight_test.dart` → FAIL。

- [ ] **Step 3: 实现**(`lib/features/equipment/domain/treasure_highlight.dart`):

```dart
import '../../../core/domain/enums.dart';

/// 爆品动画展示用的单件高亮装备快照(从 EquipmentDef 投影,纯数据便于测试)。
class TreasureHighlight {
  final String defId;
  final String name;
  final EquipmentTier tier;
  final EquipmentSlot slot;
  final String iconPath;
  const TreasureHighlight({
    required this.defId,
    required this.name,
    required this.tier,
    required this.slot,
    required this.iconPath,
  });
}

/// 从候选中筛 tier ≥ [minTier] 的最高 tier 那件(并列取首);无则 null。
/// EquipmentTier 声明序即由低到高,用 .index 比较。
TreasureHighlight? pickTreasureHighlight(
    List<TreasureHighlight> candidates, EquipmentTier minTier) {
  TreasureHighlight? best;
  for (final c in candidates) {
    if (c.tier.index < minTier.index) continue;
    if (best == null || c.tier.index > best.tier.index) best = c;
  }
  return best;
}
```

- [ ] **Step 4: 跑测试确认通过**：`flutter test test/features/equipment/domain/treasure_highlight_test.dart` → PASS(5 tests)。

- [ ] **Step 5: Commit**：

```bash
git add lib/features/equipment/domain/treasure_highlight.dart test/features/equipment/domain/treasure_highlight_test.dart
git commit -m "feat: TreasureHighlight + pickTreasureHighlight 纯函数(取最高 tier 爆品)"
```

---

### Task 3: 爆品 tier 梯度色 + 印章绛红 token

**Files:**
- Modify: `lib/shared/theme/colors.dart`(加 sealCrimson)
- Modify: `lib/shared/theme/tier_colors.dart`(加 treasureGlowColor/treasureSeedColor)
- Test: `test/shared/theme/tier_colors_test.dart`(若无则建)

> 注:通用 `tierColorForEquipment` 里 zhongQi=gangMeng(红 #C23A2A),会与印章绛红撞色。爆品动画用独立梯度色(青铜/紫/金),不复用通用 tier 色。

- [ ] **Step 1: 写失败测试**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/theme/tier_colors.dart';

void main() {
  test('爆品梯度色三档互异', () {
    final z = treasureSeedColor(EquipmentTier.zhongQi);
    final b = treasureSeedColor(EquipmentTier.baoWu);
    final s = treasureSeedColor(EquipmentTier.shenWu);
    expect({z, b, s}.length, 3);
  });
  test('glow 与 seed 各 tier 非空', () {
    for (final t in [EquipmentTier.zhongQi, EquipmentTier.baoWu, EquipmentTier.shenWu]) {
      expect(treasureGlowColor(t), isNotNull);
      expect(treasureSeedColor(t), isNotNull);
    }
  });
}
```

- [ ] **Step 2: 跑测试确认失败**：FAIL(函数未定义)。

- [ ] **Step 3: colors.dart 加印章绛红**(WuxiaColors 类内,gangMeng 附近):

```dart
  /// 爆品印章专用深绛红(区别 gangMeng 刚猛红,落款庄重)。
  static const Color sealCrimson = Color(0xFF9E2B25);
```

- [ ] **Step 4: tier_colors.dart 加爆品梯度色**(文件末尾):

```dart
/// 爆品动画墨团光晕色(半透明,radial gradient 中心)。重器青铜→宝物紫→神物金。
Color treasureGlowColor(EquipmentTier tier) => switch (tier) {
      EquipmentTier.shenWu => const Color(0x77F0D878),
      EquipmentTier.baoWu => const Color(0x559A63C8),
      _ => const Color(0x55C89B3C), // 重器及兜底:青铜赭金
    };

/// 爆品动画墨点/图标光色(不透明实色)。
Color treasureSeedColor(EquipmentTier tier) => switch (tier) {
      EquipmentTier.shenWu => const Color(0xFFF0D878),
      EquipmentTier.baoWu => const Color(0xFFB886E6),
      _ => const Color(0xFFC89B3C),
    };
```

- [ ] **Step 5: 跑测试确认通过 + analyze**：PASS / No issues。

- [ ] **Step 6: Commit**：

```bash
git add lib/shared/theme/colors.dart lib/shared/theme/tier_colors.dart test/shared/theme/tier_colors_test.dart
git commit -m "feat: 爆品 tier 梯度色(青铜/紫/金)+印章绛红 sealCrimson"
```

---

### Task 4: TreasureDropContent 静态展示 widget

**Files:**
- Create: `lib/features/equipment/presentation/treasure_drop_overlay.dart`(本 task 只加 Content,Task 5 加 Overlay+触发函数)
- Test: `test/features/equipment/presentation/treasure_drop_content_test.dart`

> 复用:墨团 asset `assets/ui/mj/caption_ink_blob.png`(ultimate_caption_overlay.dart:8)+ ColorFiltered 染色;图标走 `Image.asset(iconPath)` errorBuilder→`EquipGlyph`(equipment_glyph.dart);印章题字走 `EnumL10n.equipmentTier`。

- [ ] **Step 1: 写失败测试**(三档 tier 渲染不崩 + 缺图 errorBuilder 不破):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';

TreasureHighlight _h(EquipmentTier tier) => TreasureHighlight(
      defId: 'd', name: '玄铁重剑', tier: tier,
      slot: EquipmentSlot.weapon, iconPath: 'assets/missing.png');

void main() {
  for (final tier in [EquipmentTier.zhongQi, EquipmentTier.baoWu, EquipmentTier.shenWu]) {
    testWidgets('TreasureDropContent 渲染 $tier 不崩 + 缺图兜底', (t) async {
      // t=1.0:印章已落定、墨团定格;缺图 iconPath 触发 errorBuilder→EquipGlyph 不破。
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: TreasureDropContent(highlight: _h(tier), t: 1.0)),
      ));
      expect(find.text('玄铁重剑'), findsOneWidget);
      expect(find.text(EnumL10n.equipmentTier(tier)), findsOneWidget);
    });
  }
}
```

- [ ] **Step 2: 跑测试确认失败**：FAIL(TreasureDropContent 未定义)。

- [ ] **Step 3: 实现 TreasureDropContent**(`treasure_drop_overlay.dart`):

```dart
import 'package:flutter/material.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/equipment_glyph.dart';
import '../../battle/domain/enum_localizations.dart';
import '../domain/treasure_highlight.dart';

const String _kInkBlobAsset = 'assets/ui/mj/caption_ink_blob.png';

/// 爆品展示静态内容(无动画;动画值 [t] 0→1 由 [TreasureDropOverlay] 驱动)。
/// t 时间轴:0-0.16 墨团炸开 / 0.16-0.30 印章盖落 / 0.30 震屏峰 / 0.30+ 保持。
/// 拆出便于 widget test + 视觉验收路由。
class TreasureDropContent extends StatelessWidget {
  final TreasureHighlight highlight;
  final double t;
  const TreasureDropContent({super.key, required this.highlight, this.t = 1.0});

  @override
  Widget build(BuildContext context) {
    final glow = treasureGlowColor(highlight.tier);
    final seed = treasureSeedColor(highlight.tier);
    // 墨团 scale: 0.2→1.15→1(炸开回弹)
    final blobScale = t < 0.16 ? (0.2 + (t / 0.16) * 0.95) : (1.15 - ((t - 0.16).clamp(0, 0.14) / 0.14) * 0.15);
    // 印章: t<0.16 隐藏在上方,0.16→0.30 落下,之后定住
    final sealT = ((t - 0.16) / 0.14).clamp(0.0, 1.0);
    final sealDy = (1 - sealT) * -90.0;
    final sealRot = (1 - sealT) * -0.4;
    // 震屏: 0.30 附近左右抖
    final shake = (t > 0.28 && t < 0.36) ? ((t * 120).floor().isEven ? -5.0 : 5.0) : 0.0;
    return Align(
      alignment: const Alignment(0, -0.2),
      child: Transform.translate(
        offset: Offset(shake, 0),
        child: SizedBox(
          width: 320, height: 240,
          child: Stack(alignment: Alignment.center, children: [
            // 墨团背景(染 tier glow)
            Transform.scale(
              scale: blobScale.clamp(0.0, 1.2),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(glow, BlendMode.srcIn),
                child: Image.asset(_kInkBlobAsset, width: 260, height: 190,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                        width: 240, height: 170,
                        decoration: BoxDecoration(
                            color: glow, borderRadius: BorderRadius.circular(120)))),
              ),
            ),
            // 装备图标 + 名
            Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 56, height: 56,
                child: Image.asset(highlight.iconPath, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        EquipGlyph(tierColor: seed, slot: highlight.slot))),
              const SizedBox(height: 4),
              Text(highlight.name,
                  style: TextStyle(
                      color: WuxiaColors.textPrimary, fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
            ]),
            // 印章盖落(绛红 + tier 题字)
            Transform.translate(
              offset: Offset(0, sealDy),
              child: Transform.rotate(
                angle: sealRot,
                child: Opacity(
                  opacity: sealT,
                  child: Container(
                    width: 64, height: 64, alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: WuxiaColors.sealCrimson,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0xFF7A1F1A), width: 2)),
                    child: Text(EnumL10n.equipmentTier(highlight.tier),
                        style: const TextStyle(
                            color: Color(0xFFF3E6D0), fontSize: 20,
                            fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过 + analyze**：`flutter test test/features/equipment/presentation/treasure_drop_content_test.dart && flutter analyze lib/features/equipment/presentation/treasure_drop_overlay.dart` → PASS(3) / No issues。

- [ ] **Step 5: Commit**：

```bash
git add lib/features/equipment/presentation/treasure_drop_overlay.dart test/features/equipment/presentation/treasure_drop_content_test.dart
git commit -m "feat: TreasureDropContent 印章盖落+墨团背景静态层(tier 梯度)"
```

---

### Task 5: TreasureDropOverlay 动画 + playTreasureDropIfAny

**Files:**
- Modify: `lib/features/equipment/presentation/treasure_drop_overlay.dart`(加 Overlay + 触发函数)
- Modify: `lib/shared/audio/audio_assets.dart` 无需改(复用 SfxId.reward)
- Test: `test/features/equipment/presentation/treasure_drop_overlay_test.dart`

- [ ] **Step 1: 写失败测试**(动画 widget pump 跑完不崩 + gate=false 不弹):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';

void main() {
  testWidgets('TreasureDropOverlay 动画跑完自动结束回调', (t) async {
    var done = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: TreasureDropOverlay(
      highlight: TreasureHighlight(defId: 'd', name: '倚天神剑',
          tier: EquipmentTier.shenWu, slot: EquipmentSlot.weapon, iconPath: 'm.png'),
      onDone: () => done = true,
    ))));
    expect(find.text('倚天神剑'), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(done, isTrue);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**：FAIL(TreasureDropOverlay 未定义)。

- [ ] **Step 3: 加 TreasureDropOverlay + playTreasureDropIfAny**(treasure_drop_overlay.dart 追加;import 加 `dart:async` 不需要,加 game_repository/sound_manager/drop_service):

```dart
// 文件顶部 import 追加:
import '../../../data/game_repository.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../application/drop_service.dart';

/// 爆品动画 overlay(showGeneralDialog 调起,自管 AnimationController)。
/// 动画跑完或点击跳过 → onDone。总时长 1.3s。
class TreasureDropOverlay extends StatefulWidget {
  final TreasureHighlight highlight;
  final VoidCallback onDone;
  const TreasureDropOverlay({super.key, required this.highlight, required this.onDone});

  @override
  State<TreasureDropOverlay> createState() => _TreasureDropOverlayState();
}

class _TreasureDropOverlayState extends State<TreasureDropOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish, // 点击跳过
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xB3000000), // 半透明暗幕
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => TreasureDropContent(highlight: widget.highlight, t: _ctrl.value),
        ),
      ),
    );
  }
}

/// 公共触发:有 ≥门槛爆品且 [gate] 时,播动画(+reward 音)并 await 至结束。
/// 主线传 gate=true;塔传 gate=isFirstClear(沿现有 reward gate)。
Future<void> playTreasureDropIfAny(
    BuildContext context, DropResult drops, {required bool gate}) async {
  if (!gate || !GameRepository.isLoaded) return;
  final minTier = GameRepository.instance.numbers.treasureDrop.minTier;
  final candidates = drops.equipments.map((e) {
    final def = GameRepository.instance.getEquipment(e.defId);
    return TreasureHighlight(
        defId: e.defId, name: def.name, tier: def.tier,
        slot: def.slot, iconPath: def.iconPath);
  }).toList();
  final hl = pickTreasureHighlight(candidates, minTier);
  if (hl == null || !context.mounted) return;
  SoundManager.instance.playSfx(SfxId.reward);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => TreasureDropOverlay(
        highlight: hl, onDone: () => Navigator.of(ctx).pop()),
  );
}
```

- [ ] **Step 4: 跑测试确认通过 + analyze**：`flutter test test/features/equipment/presentation/treasure_drop_overlay_test.dart && flutter analyze lib/features/equipment/presentation/treasure_drop_overlay.dart` → PASS / No issues。

- [ ] **Step 5: Commit**：

```bash
git add lib/features/equipment/presentation/treasure_drop_overlay.dart test/features/equipment/presentation/treasure_drop_overlay_test.dart
git commit -m "feat: TreasureDropOverlay 动画 + playTreasureDropIfAny 公共触发"
```

---

### Task 6: Wiring 主线 + 塔 + 删两处旧 reward

**Files:**
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart:184`(showStageVictoryDialog 前插触发)
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart:35-36`(删旧 reward)
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart`(插触发 + 删旧 reward:550-551)

- [ ] **Step 1: 主线插触发点**(stage_entry_flow.dart,`if (outcome != null && context.mounted)` 块内、`await showStageVictoryDialog(` 之前;import 加 `import '../../equipment/presentation/treasure_drop_overlay.dart';`):

```dart
  if (outcome != null && context.mounted) {
    await playTreasureDropIfAny(context, outcome.drops, gate: true);
    if (!context.mounted) return;
    await showStageVictoryDialog(
      context: context,
      stage: stage,
      drops: outcome.drops,
      advancements: outcome.advancements,
      resonanceUpgrades: outcome.resonanceUpgrades,
    );
  }
```

- [ ] **Step 2: 删主线弹窗内旧 reward**(stage_victory_dialog.dart:31-37,保留 realmAdvance):

```dart
  // 结算 jingle:跨 tier 大境界突破响 realmAdvance(爆装备音已移到 playTreasureDropIfAny
  // 动画层 + 门槛化,2026-06-11)。
  if (advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
```

- [ ] **Step 3: 塔插触发 + 删旧 reward**(tower_entry_flow.dart `_showVictoryDialog`,`showDialog` 之前插触发;import 加 treasure_drop_overlay)。改 reward 块(545-551)为:

```dart
  if (isFirstClear && advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
  await playTreasureDropIfAny(context, drops, gate: isFirstClear);
  if (!context.mounted) return;
  await showDialog<void>(
    // …既有 showDialog 不变…
```

(删除原 `else if (isFirstClear && drops.equipments.isNotEmpty) playSfx(reward)` 分支。)

- [ ] **Step 4: analyze + 全量 test**：

Run: `flutter analyze && flutter test`
Expected: No issues / All tests passed(基线 1932 + Task1-5 新增,对账增量)。

- [ ] **Step 5: Commit**：

```bash
git add lib/features/mainline/presentation/stage_entry_flow.dart lib/features/mainline/presentation/stage_victory_dialog.dart lib/features/tower/presentation/tower_entry_flow.dart
git commit -m "feat: 主线/塔爆品动画 wiring + 删两处旧 reward(移到动画层门槛化)"
```

---

### Task 7: reward 音效重做 Suno prompt doc(素材解耦)

**Files:**
- Create: `docs/_archive/suno/suno_reward_treasure_sfx_prompts_2026-06-11.md`

> 素材生成是用户在 Suno 的动作;本 task 只产 prompt。动画 wiring 已用现有 reward.mp3 占位落地(Task 6),新素材到位后替换(零接线改动)。

- [ ] **Step 1: 写 prompt doc**(沿 `docs/_archive/suno/suno_battlehit_blade_sfx_prompts_2026-06-11.md` 体例,目标:珍稀「获得宝物」质感,明确区别 victory 上扬。含 4 条 reward 候选 prompt,强调 wuxia 玉/磬/古琴泛音的「得宝」感而非「胜利」感,≤1.5s one-shot)。

- [ ] **Step 2: Commit**：

```bash
git add docs/_archive/suno/suno_reward_treasure_sfx_prompts_2026-06-11.md
git commit -m "docs: reward 爆品音效重做 Suno prompt(区别 victory 得宝质感)"
```

---

### Task 8: 闸门 + 视觉验收交接

**Files:**
- (验证 only,无新建)

- [ ] **Step 1: 全量闸门**：

Run: `flutter analyze && flutter test`
Expected: No issues found / All tests passed(基线 1932 + 新增测,记录最终数)。

- [ ] **Step 2: 编 release 包供真玩/视觉验收**：

Run: `flutter build macos --release`
Expected: ✓ Built。(注:不加 DEVELOPER_DIR 前缀。)

- [ ] **Step 3: 合 main + push**(用户确认后):

```bash
cd /Users/a10506/Desktop/Projects/挂机武侠 && git merge --ff-only worktree-treasure-drop-anim && git push
```

- [ ] **Step 4: 交接说明**:真玩验收点 = 打主线/塔掉重器+装备 → 印章盖落动画(墨团/震屏/tier 色)→ 弹窗。新 reward 素材待用户 Suno 后替换 `assets/audio/sfx/reward.mp3`。

---

## 风险提示
- 动画时间轴常量(墨团/印章/震屏断点)按视觉验收微调,Content 里 `t` 断点集中可改。
- 塔 `_showVictoryDialog` 的 `context` 在 `await playTreasureDropIfAny` 后需 `context.mounted` 守卫(已在 Step 3 加)。
- reward 素材未替换前用旧 reward 占位,听感仍与 victory 近——属预期,待 Task 7 素材到位解决。
