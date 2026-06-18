# 打击感表现层（批次 2.4）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给重击（暴击普攻/强力技/大招/人剑合一/破招）加分级递进的打击感表现层（hit-stop + 单字题字「斩·震·断」+ 镜头轻震 + 全屏闪白），普攻保持现有轻反馈，纯表现层零数值/逻辑改动。

**Architecture:** 中央纯函数 `impactProfileFor(action, cfg)` 派生 `ImpactProfile`（tier + glyph + 三参数），`battle_screen._playAction` 单点调度到 4 个命令式效果通道。glyph/tier 全派生现有 `SkillDef`/`BattleAction` 字段（零 schema），三参数走 `numbers.yaml`，单字走 `UiStrings`。

**Tech Stack:** Flutter（AnimationController/Timer 命令式表现层）+ Riverpod（numbersConfigProvider）+ Isar 无关 + flutter_test。

**上游 spec:** `docs/spec/2026-06-18-phase5-mainline2-batch24-impact-feel-design.md`

**红线（每 task 守）:** §5.4 不写 BattleState / 伤害公式零调用 · §5.5 hit-stop 只动屏上播放节拍 · §5.6 数值进 yaml、文案进 UiStrings · 2.3 不变量：快进/拖招态跳过 hit-stop+震。

---

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/data/numbers_config.dart` | `ImpactFeedbackConfig` + `ImpactTierParams` 强类型 + 接入 `CombatNumbers` | Modify |
| `data/numbers.yaml` | `combat.impact_feedback` 三档参数 | Modify |
| `lib/shared/strings.dart` | `UiStrings` 加单字「斩/震/断」 | Modify |
| `lib/features/battle/presentation/impact_profile.dart` | `ImpactTier` enum + `ImpactProfile` + `impactProfileFor` 纯函数 | Create |
| `lib/features/battle/presentation/impact_glyph_overlay.dart` | `ImpactGlyphOverlay`（单字水墨题字，短停留） | Create |
| `lib/features/battle/presentation/screen_flash.dart` | `ScreenFlashOverlay`（全屏轻闪） | Create |
| `lib/features/battle/presentation/camera_shake.dart` | `CameraShake`（Transform 包场景层） | Create |
| `lib/features/battle/presentation/battle_screen.dart` | `_playAction` 调度 + hit-stop Timer 延后 + 各 overlay 接入 | Modify |
| `test/features/battle/presentation/impact_profile_test.dart` | 纯函数单测 | Create |
| `test/features/battle/presentation/impact_feedback_widget_test.dart` | overlay/防重叠/不溢出 widget 测 | Create |

---

## Task 1: 数值配置层 `ImpactFeedbackConfig`（先行，无 UI 依赖）

**Files:**
- Modify: `lib/data/numbers_config.dart`（`CombatNumbers` 类附近 ~1082-1132 + 新增配置类）
- Modify: `data/numbers.yaml`（`combat:` 段，`boss_charge:` 后 ~line 125）

- [ ] **Step 1: 在 `numbers_config.dart` 末尾（或 `BossChargeConfig` 后）新增配置类**

```dart
/// 批次 2.4 打击感表现层三档参数（numbers.yaml `combat.impact_feedback`）。
/// 纯表现层（hit-stop 时长 / 镜头震幅 / 全屏闪白 alpha），不影响伤害/逻辑。
/// fixture 不带该段时回落默认值（沿 BossChargeConfig 防御 fallback 体例）。
class ImpactFeedbackConfig {
  final ImpactTierParams light;
  final ImpactTierParams medium;
  final ImpactTierParams heavy;

  const ImpactFeedbackConfig({
    required this.light,
    required this.medium,
    required this.heavy,
  });

  factory ImpactFeedbackConfig.fromYaml(Map y) => ImpactFeedbackConfig(
        light: ImpactTierParams.fromYaml(
          y['light'] as Map? ?? const {},
          defaultHitStopMs: 60,
          defaultShake: 3.0,
          defaultFlash: 0.12,
        ),
        medium: ImpactTierParams.fromYaml(
          y['medium'] as Map? ?? const {},
          defaultHitStopMs: 90,
          defaultShake: 6.0,
          defaultFlash: 0.20,
        ),
        heavy: ImpactTierParams.fromYaml(
          y['heavy'] as Map? ?? const {},
          defaultHitStopMs: 120,
          defaultShake: 10.0,
          defaultFlash: 0.30,
        ),
      );
}

class ImpactTierParams {
  final int hitStopMs;
  final double shakeMagnitude;
  final double flashStrength;

  const ImpactTierParams({
    required this.hitStopMs,
    required this.shakeMagnitude,
    required this.flashStrength,
  });

  factory ImpactTierParams.fromYaml(
    Map y, {
    required int defaultHitStopMs,
    required double defaultShake,
    required double defaultFlash,
  }) =>
      ImpactTierParams(
        hitStopMs: (y['hit_stop_ms'] as num?)?.toInt() ?? defaultHitStopMs,
        shakeMagnitude:
            (y['shake_magnitude'] as num?)?.toDouble() ?? defaultShake,
        flashStrength:
            (y['flash_strength'] as num?)?.toDouble() ?? defaultFlash,
      );
}
```

- [ ] **Step 2: 接入 `CombatNumbers`**

在 `class CombatNumbers` 加字段（`bossCharge` 后）：
```dart
  final BossChargeConfig bossCharge;
  final ImpactFeedbackConfig impactFeedback;
```
构造函数 `required this.impactFeedback,`（在 `required this.bossCharge,` 后）。
`fromYaml` 末尾 `bossCharge:` 之后加：
```dart
      impactFeedback: ImpactFeedbackConfig.fromYaml(
        y['impact_feedback'] as Map? ?? const {},
      ),
```

- [ ] **Step 3: 在 `data/numbers.yaml` 的 `combat:` 段加配置**

在 `boss_charge:` 块之后（与 `boss_charge` 同缩进，2 空格）插入：
```yaml
  # 批次 2.4 打击感表现层三档（纯表现层，真机调手感后定稿；§5.5 只动屏上播放节拍不改逻辑）。
  impact_feedback:
    light:  { hit_stop_ms: 60,  shake_magnitude: 3.0,  flash_strength: 0.12 }
    medium: { hit_stop_ms: 90,  shake_magnitude: 6.0,  flash_strength: 0.20 }
    heavy:  { hit_stop_ms: 120, shake_magnitude: 10.0, flash_strength: 0.30 }
```

- [ ] **Step 4: 跑 analyze 确认编译**

Run: `flutter analyze lib/data/numbers_config.dart`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/data/numbers_config.dart data/numbers.yaml
git commit -m "feat(2.4): ImpactFeedbackConfig 三档参数 + numbers.yaml"
```

---

## Task 2: `UiStrings` 单字「斩/震/断」

**Files:**
- Modify: `lib/shared/strings.dart`（`interruptCaption` 附近 ~line 81）

- [ ] **Step 1: 加三个单字常量**

在 `static const String interruptCaption = '破！';` 后加：
```dart
  // 批次 2.4 打击感单字效果字（重击非破招非大招）。破由现有 interruptCaption 承载。
  static const String impactGlyphZhan = '斩'; // 灵巧 / 无流派 默认
  static const String impactGlyphZhen = '震'; // 刚猛
  static const String impactGlyphDuan = '断'; // 阴柔
```

- [ ] **Step 2: 跑 analyze**

Run: `flutter analyze lib/shared/strings.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/strings.dart
git commit -m "feat(2.4): UiStrings 加打击感单字 斩/震/断"
```

---

## Task 3: 纯函数 `impactProfileFor`（TDD）

**Files:**
- Create: `lib/features/battle/presentation/impact_profile.dart`
- Test: `test/features/battle/presentation/impact_profile_test.dart`

- [ ] **Step 1: 写失败测试**

`test/features/battle/presentation/impact_profile_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_profile.dart';
import 'package:wuxia_idle/shared/strings.dart';

// 最小 SkillDef 构造 helper（只填打击感判定相关字段）。
SkillDef _skill({
  required SkillType type,
  TechniqueSchool? style,
}) =>
    SkillDef(
      id: 't',
      name: 't',
      description: '',
      type: type,
      powerMultiplier: 100,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: '',
      style: style,
    );

AttackResult _result({bool crit = false, bool dodge = false}) => AttackResult(
      damage: dodge ? 0 : 100,
      isCritical: crit,
      isDodged: dodge,
    );

BattleAction _action({
  required SkillDef? skill,
  AttackResult? result,
  bool interrupted = false,
}) =>
    BattleAction(
      actorId: 1,
      targetId: 2,
      skill: skill,
      attackResult: result,
      interrupted: interrupted,
    );

const _cfg = ImpactFeedbackConfig(
  light: ImpactTierParams(hitStopMs: 60, shakeMagnitude: 3, flashStrength: 0.12),
  medium:
      ImpactTierParams(hitStopMs: 90, shakeMagnitude: 6, flashStrength: 0.20),
  heavy:
      ImpactTierParams(hitStopMs: 120, shakeMagnitude: 10, flashStrength: 0.30),
);

void main() {
  group('impactProfileFor tier', () {
    test('普攻非暴击 → null', () {
      final p = impactProfileFor(
        _action(skill: _skill(type: SkillType.normalAttack), result: _result()),
        _cfg,
      );
      expect(p, isNull);
    });

    test('暴击普攻 → light', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.normalAttack),
          result: _result(crit: true),
        ),
        _cfg,
      );
      expect(p!.tier, ImpactTier.light);
      expect(p.hitStopMs, 60);
    });

    test('强力技 → medium', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
          result: _result(),
        ),
        _cfg,
      );
      expect(p!.tier, ImpactTier.medium);
      expect(p.hitStopMs, 90);
    });

    test('大招 → heavy, glyph null', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.ultimate),
          result: _result(crit: true),
        ),
        _cfg,
      );
      expect(p!.tier, ImpactTier.heavy);
      expect(p.glyph, isNull);
      expect(p.hitStopMs, 120);
    });

    test('闪避 → null', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.ultimate),
          result: _result(dodge: true),
        ),
        _cfg,
      );
      expect(p, isNull);
    });

    test('attackResult 空 → null', () {
      final p = impactProfileFor(
        _action(skill: _skill(type: SkillType.ultimate)),
        _cfg,
      );
      expect(p, isNull);
    });
  });

  group('impactProfileFor glyph', () {
    test('刚猛强力技 → 震', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
          result: _result(),
        ),
        _cfg,
      );
      expect(p!.glyph, UiStrings.impactGlyphZhen);
    });

    test('阴柔强力技 → 断', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.yinRou),
          result: _result(),
        ),
        _cfg,
      );
      expect(p!.glyph, UiStrings.impactGlyphDuan);
    });

    test('灵巧/无流派 → 斩', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.lingQiao),
          result: _result(),
        ),
        _cfg,
      );
      expect(p!.glyph, UiStrings.impactGlyphZhan);
    });

    test('破招（interrupted）强力技 → tier 在但 glyph null', () {
      final p = impactProfileFor(
        _action(
          skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
          result: _result(),
          interrupted: true,
        ),
        _cfg,
      );
      expect(p!.tier, ImpactTier.medium);
      expect(p.glyph, isNull); // 破由现有「破！」承载
    });
  });
}
```

> **注**：`AttackResult` / `BattleAction` 的构造参数名以 `battle_state.dart` 实际为准——实现前先 `grep -n "class AttackResult" lib/features/battle/domain/battle_state.dart` 核对字段名（`damage`/`isCritical`/`isDodged` 等），如有出入同步改 helper。`SkillDef` 必填参数以 `skill_def.dart:76-94` 为准。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/presentation/impact_profile_test.dart`
Expected: FAIL（`impact_profile.dart` 不存在 / `impactProfileFor` 未定义）。

- [ ] **Step 3: 写实现**

`lib/features/battle/presentation/impact_profile.dart`：
```dart
import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../domain/battle_state.dart';
import 'ultimate_caption_overlay.dart' show isUltimateCaptionSkill;

/// 打击感强度档（暴击普攻 light < 强力技 medium < 大招/人剑合一 heavy）。
enum ImpactTier { light, medium, heavy }

/// 单次重击的打击感画像（纯派生现有字段，零 schema）。
class ImpactProfile {
  final ImpactTier tier;
  final String? glyph; // 「斩/震/断」；heavy/破招/大招为 null
  final int hitStopMs;
  final double shakeMagnitude;
  final double flashStrength;

  const ImpactProfile({
    required this.tier,
    required this.glyph,
    required this.hitStopMs,
    required this.shakeMagnitude,
    required this.flashStrength,
  });
}

/// 由 [action] 派生打击感画像；非重击（普攻非暴击/闪避/无结算）返 null。
/// 纯函数，无副作用，便于单测。三参数从 [cfg] 按档取。
ImpactProfile? impactProfileFor(BattleAction action, ImpactFeedbackConfig cfg) {
  final result = action.attackResult;
  if (result == null || result.isDodged) return null;

  final skill = action.skill;
  final ImpactTier tier;
  if (isUltimateCaptionSkill(skill)) {
    tier = ImpactTier.heavy;
  } else if (skill?.type == SkillType.powerSkill) {
    tier = ImpactTier.medium;
  } else if (skill?.type == SkillType.normalAttack && result.isCritical) {
    tier = ImpactTier.light;
  } else {
    return null; // 普攻非暴击 / 无 skill → 无打击感
  }

  final params = switch (tier) {
    ImpactTier.light => cfg.light,
    ImpactTier.medium => cfg.medium,
    ImpactTier.heavy => cfg.heavy,
  };

  // glyph 仅 light/medium 非破招（破招走现有「破！」，不重复）。
  String? glyph;
  if (tier != ImpactTier.heavy && !action.interrupted) {
    glyph = switch (skill?.style) {
      TechniqueSchool.gangMeng => UiStrings.impactGlyphZhen,
      TechniqueSchool.yinRou => UiStrings.impactGlyphDuan,
      _ => UiStrings.impactGlyphZhan, // lingQiao 或 null
    };
  }

  return ImpactProfile(
    tier: tier,
    glyph: glyph,
    hitStopMs: params.hitStopMs,
    shakeMagnitude: params.shakeMagnitude,
    flashStrength: params.flashStrength,
  );
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/presentation/impact_profile_test.dart`
Expected: PASS（全部 group 绿）。

- [ ] **Step 5: 跑全项目 analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle/presentation/impact_profile.dart test/features/battle/presentation/impact_profile_test.dart
git commit -m "feat(2.4): impactProfileFor 纯函数 + 单测（tier/glyph 派生）"
```

---

## Task 4: 单字题字 `ImpactGlyphOverlay`

**Files:**
- Create: `lib/features/battle/presentation/impact_glyph_overlay.dart`
- 参照样式：`lib/features/battle/presentation/ultimate_caption_overlay.dart`

- [ ] **Step 1: 写 overlay（短停留版，复用墨团样式）**

```dart
import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';

const String _kInkBlobAsset = 'assets/ui/mj/caption_ink_blob.png';

/// 批次 2.4 单字打击题字（「斩/震/断」）。与 [UltimateCaptionOverlay] 并列、
/// 独立 GlobalKey；短停留（870ms 总），区别于全名题字 1800ms。
/// 命令式 show(glyph, isEnemy)，latest-wins。纯表现层，不写 BattleState。
class ImpactGlyphOverlay extends StatefulWidget {
  const ImpactGlyphOverlay({super.key});

  @override
  State<ImpactGlyphOverlay> createState() => ImpactGlyphOverlayState();
}

class ImpactGlyphOverlayState extends State<ImpactGlyphOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _glyph;
  bool _isEnemy = false;

  static const _fadeInMs = 120;
  static const _holdMs = 500;
  static const _fadeOutMs = 250;
  static const _totalMs = _fadeInMs + _holdMs + _fadeOutMs;
  static const _fadeInEnd = _fadeInMs / _totalMs;
  static const _fadeOutStart = (_fadeInMs + _holdMs) / _totalMs;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _glyph = null);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void show(String glyph, {required bool isEnemy}) {
    setState(() {
      _glyph = glyph;
      _isEnemy = isEnemy;
    });
    _ctrl.forward(from: 0.0);
  }

  double get _opacity {
    final t = _ctrl.value;
    if (t < _fadeInEnd) return t / _fadeInEnd;
    if (t > _fadeOutStart) return (1.0 - t) / (1.0 - _fadeOutStart);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_glyph == null) return const SizedBox.shrink();
    final accent =
        _isEnemy ? WuxiaColors.gangMeng : WuxiaColors.resultHighlight;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: SizedBox(
              width: 200,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ColorFiltered(
                      colorFilter:
                          ColorFilter.mode(accent, BlendMode.srcIn),
                      child: Image.asset(
                        _kInkBlobAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(_glyph!, style: _glyphStyle(stroke: true)),
                  Text(_glyph!, style: _glyphStyle(stroke: false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _glyphStyle({required bool stroke}) => TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: stroke ? null : WuxiaUi.paper,
        foreground: stroke
            ? (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = const Color(0xCC0A0A0A))
            : null,
      );
}
```

- [ ] **Step 2: analyze**

Run: `flutter analyze lib/features/battle/presentation/impact_glyph_overlay.dart`
Expected: No issues found（若 `WuxiaColors.resultHighlight`/`WuxiaUi.paper` 名有出入，照 `ultimate_caption_overlay.dart:29,66` 实际名改）。

- [ ] **Step 3: Commit**

```bash
git add lib/features/battle/presentation/impact_glyph_overlay.dart
git commit -m "feat(2.4): ImpactGlyphOverlay 单字水墨题字（短停留）"
```

---

## Task 5: 全屏闪白 `ScreenFlashOverlay` + 镜头震 `CameraShake`

**Files:**
- Create: `lib/features/battle/presentation/screen_flash.dart`
- Create: `lib/features/battle/presentation/camera_shake.dart`

- [ ] **Step 1: 写 `ScreenFlashOverlay`（命令式全屏轻闪）**

```dart
import 'package:flutter/material.dart';

/// 批次 2.4 全屏轻闪。命令式 flash(strength, color)，~120ms 淡出。
/// 放在场景层之上、题字 overlay 之下。纯表现层。
class ScreenFlashOverlay extends StatefulWidget {
  const ScreenFlashOverlay({super.key});

  @override
  State<ScreenFlashOverlay> createState() => ScreenFlashOverlayState();
}

class ScreenFlashOverlayState extends State<ScreenFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _strength = 0.0;
  Color _color = Colors.white;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _strength = 0.0);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void flash(double strength, {Color color = Colors.white}) {
    setState(() {
      _strength = strength;
      _color = color;
    });
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_strength <= 0.0) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final a = (1.0 - _ctrl.value) * _strength;
          return ColoredBox(color: _color.withValues(alpha: a));
        },
      ),
    );
  }
}
```

- [ ] **Step 2: 写 `CameraShake`（Transform 包场景层）**

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 批次 2.4 镜头轻震。命令式 shake(magnitude)，~250ms 高频衰减抖动。
/// 包战斗场景层（不含 HUD/指令台/题字）。纯表现层。
class CameraShake extends StatefulWidget {
  final Widget child;
  const CameraShake({super.key, required this.child});

  @override
  State<CameraShake> createState() => CameraShakeState();
}

class CameraShakeState extends State<CameraShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _magnitude = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake(double magnitude) {
    _magnitude = magnitude;
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        if (_ctrl.value >= 1.0 || _magnitude <= 0.0) return child!;
        final decay = (1.0 - _ctrl.value);
        // 高频正弦抖动 × 衰减，x/y 相位错开。
        final dx = math.sin(_ctrl.value * math.pi * 12) * _magnitude * decay;
        final dy = math.cos(_ctrl.value * math.pi * 10) * _magnitude * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}
```

- [ ] **Step 3: analyze**

Run: `flutter analyze lib/features/battle/presentation/screen_flash.dart lib/features/battle/presentation/camera_shake.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/battle/presentation/screen_flash.dart lib/features/battle/presentation/camera_shake.dart
git commit -m "feat(2.4): ScreenFlashOverlay 全屏闪白 + CameraShake 镜头震"
```

---

## Task 6: 接入 `battle_screen._playAction` + hit-stop + widget 测

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`
- Test: `test/features/battle/presentation/impact_feedback_widget_test.dart`

- [ ] **Step 1: 加 GlobalKey + Timer 字段 + dispose**

在 `_ultimateCaptionKey`（:270）附近加：
```dart
  final GlobalKey<ImpactGlyphOverlayState> _impactGlyphKey =
      GlobalKey<ImpactGlyphOverlayState>();
  final GlobalKey<ScreenFlashOverlayState> _screenFlashKey =
      GlobalKey<ScreenFlashOverlayState>();
  final GlobalKey<CameraShakeState> _cameraShakeKey =
      GlobalKey<CameraShakeState>();
  Timer? _hitStopTimer;
```
在 `dispose()`（~:336 `_playTimer?.cancel()` 附近）加：`_hitStopTimer?.cancel();`
顶部 import 三个新文件 + `impact_profile.dart`。

- [ ] **Step 2: `_playAction` 末端调度打击感（在 sfx 块后）**

在 `_playAction` 方法 sfx 播放块之后、方法结束前插入：
```dart
    // ── 批次 2.4 打击感表现层（重击分级）。纯表现层，不写 state。 ──
    final cfg = _impactConfigOrNull();
    if (cfg != null) {
      final profile = impactProfileFor(action, cfg);
      if (profile != null) {
        final isEnemy = actor?.teamSide == 1;
        if (profile.glyph != null) {
          _impactGlyphKey.currentState?.show(profile.glyph!, isEnemy: isEnemy);
        }
        _screenFlashKey.currentState?.flash(
          profile.flashStrength,
          color: action.attackResult!.isCritical
              ? WuxiaColors.gangMeng
              : Colors.white,
        );
        // hit-stop + 镜头震：快进/拖招态跳过（守 2.3 时序 + 保快进顺滑）。
        if (!_isFastForward && _rushToActorId == null) {
          _cameraShakeKey.currentState?.shake(profile.shakeMagnitude);
          _applyHitStop(profile.hitStopMs);
        }
      }
    }
```

- [ ] **Step 3: 加 `_impactConfigOrNull` + `_applyHitStop` helper**

在 `_playAction` 附近加：
```dart
  /// 读打击感配置；GameRepository 未初始化（轻量 widget 测）时返 null 跳过。
  ImpactFeedbackConfig? _impactConfigOrNull() {
    try {
      return ref.read(numbersConfigProvider).combat.impactFeedback;
    } catch (_) {
      return null;
    }
  }

  /// hit-stop：命中瞬间停播放 Timer，延后 [ms] 后复播。
  /// 只动屏上播放节拍（advance 结算确定不变，守 §5.5）；_startTimer 内
  /// _isPaused/finished gate 兜住，暂停态不会被复活。
  void _applyHitStop(int ms) {
    if (_isPaused) return;
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
    _hitStopTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted && !ref.read(battleProvider).isFinished) _startTimer();
    });
  }
```

- [ ] **Step 4: 接 overlay 到 widget 树**

在 build 的 Stack 里，`UltimateCaptionOverlay`（:1134）**之前**加全屏闪白（场景之上、题字之下），并把场景层包进 `CameraShake`：
```dart
            // 场景层外包镜头震（只抖场景，不抖 HUD/题字）。
            // → 用 CameraShake(key: _cameraShakeKey, child: <战斗场景子树>)
            //   包住角色/特效那层（即现有放角色 avatar + trail + effect 的 Stack 子树），
            //   不要包 HUD/指令台/题字 overlay。
            ScreenFlashOverlay(key: _screenFlashKey),
            UltimateCaptionOverlay(key: _ultimateCaptionKey),
            ImpactGlyphOverlay(key: _impactGlyphKey),
```
> **实现注**：`CameraShake` 的包裹点要落在「角色+残影+特效」场景子树上，HUD（HP 条/内力/指令台）和三个题字/闪白 overlay 留在 shake 之外。先读 :1040-1140 区段确认场景子树边界再包，避免抖到 UI。

- [ ] **Step 5: 写 widget 测**

`test/features/battle/presentation/impact_feedback_widget_test.dart`：覆盖 ① 强力技重击触发 `ImpactGlyphOverlay` 渲染单字；② 破招不弹单字（防重叠）；③ 普攻非暴击无 overlay；④ 720p 不溢出。
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_glyph_overlay.dart';

void main() {
  testWidgets('ImpactGlyphOverlay idle 渲染 SizedBox.shrink', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImpactGlyphOverlay()));
    expect(find.text('斩'), findsNothing);
  });

  testWidgets('show 后渲染单字且不溢出 720p', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey<ImpactGlyphOverlayState>();
    await tester.pumpWidget(MaterialApp(home: ImpactGlyphOverlay(key: key)));
    key.currentState!.show('震', isEnemy: false);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('震'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
```
> **注**：`battle_screen` 级「破招不弹单字」的端到端断言成本高（需起整战斗）。本批用 Task 3 纯函数测 `interrupted → glyph null` 锁防重叠语义（已覆盖），widget 层只验 overlay 自身渲染。若执行时 battle_screen 已有轻量 harness 可复用，再补端到端 1 条。

- [ ] **Step 6: 跑新 widget 测 + 受影响的 battle widget 测**

Run: `flutter test test/features/battle/presentation/`
Expected: PASS（含既有 battle presentation 测零回归）。

- [ ] **Step 7: 跑全项目 analyze + 全量测**

Run: `flutter analyze && flutter test`
Expected: analyze 0；全量测零回归（基线 2368 +1 skip，本批净增 = 新增测数）。

- [ ] **Step 8: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/impact_feedback_widget_test.dart
git commit -m "feat(2.4): 打击感接入 _playAction（题字/闪白/镜头震/hit-stop）+ widget 测"
```

---

## Task 7: 视觉验收 + 收尾

- [ ] **Step 1: 真机自截重击打击感**

`VISUAL_ROUTE=battle_drag_live flutter run -d macos`（禁加 `DEVELOPER_DIR=`），触发强力技/大招观察单字题字 + 闪白 + 镜头震；hit-stop 为时序手感（单帧不可截），由纯函数测 + 真机目检确认。
> hit-stop/震屏是动态运动效果，单帧截图只能验题字/闪白渲染；时序手感真机目检。

- [ ] **Step 2: 更新 PROGRESS.md 续24 段**（顶段加一条，体例同续23）

- [ ] **Step 3: 并 main**

```bash
# 主 checkout 验测后并入（worktree → main，遵循 feedback_bg_worktree_baseref_fresh_diverge）
```

---

## Self-Review（已核对）

- **Spec 覆盖**：§2 派生层→Task 3 · §3 hit-stop→Task 6 · §4 镜头震→Task 5/6 · §5 单字题字→Task 4/6 · §6 闪白→Task 5/6 · §7 防重叠→Task 3（interrupted→glyph null）· §8 numbers.yaml→Task 1 · §9 测试→Task 3/6 · §10 红线→每 task 守。全覆盖。
- **类型一致**：`ImpactFeedbackConfig`/`ImpactTierParams`（Task 1）↔ `impactProfileFor(action, cfg)`（Task 3）↔ `_impactConfigOrNull()`（Task 6）签名一致；`ImpactGlyphOverlayState.show`/`ScreenFlashOverlayState.flash`/`CameraShakeState.shake` 在 Task 4/5 定义、Task 6 调用名一致。
- **占位扫描**：数值为占位但明标真机调（非 TBD）；helper 字段名注明「实现前 grep 核对」是必要的防漂移，非偷懒占位。
