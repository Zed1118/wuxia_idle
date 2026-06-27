# 战斗命中演出分级 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把命中演出理成一致阶梯，并新增「命中特写镜头」让大招暴击/击杀的峰值一击被强调。纯表现层。

**Architecture:** 基础档（ImpactTier）已存在。本计划只补两块**真正缺的新工作**：① 题字分级（字号/辉光）② 命中特写镜头（缩放脉冲，复用现有关键帧 400ms 顿帧窗口）。新增一个纯函数 `hitClimaxFor(action,state)` 作单一真相源，零 schema 改动、不碰结算。

**Tech Stack:** Flutter + Riverpod；战斗表现层在 `lib/features/battle/presentation/`；配置走 `data/numbers.yaml` + `lib/data/numbers_config.dart`。

> **spec 纠偏（实测）**：spec §4 表写「峰值顿帧 200ms 新增」**有误**——`BattleLog.isKeyAction`（暴击/大招/破招/击杀）已走 `key_moment_hold_ms=400`，峰值早有 400ms 顿帧。特写**复用该 400ms 窗口**，不新增顿帧参数。spec §7「presentation.hit_tier」配置归位到现有 `animation:` 段下 `animation.hit_tier`（沿用 AnimationNumbers 既有配置家，避免新起顶层 section）。

---

## File Structure

- `data/numbers.yaml` — 新增 `animation.hit_tier`（题字峰值字号/辉光模糊/特写缩放/脉冲时长）。
- `lib/data/numbers_config.dart` — 新增 `HitTierConfig` 类 + `AnimationNumbers.hitTier` 字段 + 解析。
- `lib/features/battle/domain/battle_state.dart` — 加公开 `characterById(int)`（DRY，供击杀查找）。
- `lib/features/battle/presentation/impact_profile.dart` — 加 `enum HitClimax` + 纯函数 `hitClimaxFor(action, state)`。
- `lib/features/battle/presentation/ultimate_caption_overlay.dart` — `show()` / `UltimateCaptionContent` 接受 `fontSize` + `glow` 参数（默认值=现状，不破坏现有调用）。
- `lib/features/battle/presentation/battle_screen.dart` — 题字触发处传峰值字号+辉光；命中特写缩放脉冲（门控 `!_isFastForward && _rushToActorId == null`）。
- 测试：`test/features/battle/hit_climax_test.dart`（派生纯函数）+ `test/data/hit_tier_config_test.dart`（配置解析）。

---

## Task 1: 配置层 — animation.hit_tier + HitTierConfig

**Files:**
- Modify: `data/numbers.yaml`（`animation:` 段，约 1422 行起）
- Modify: `lib/data/numbers_config.dart`（`AnimationNumbers` 约 1586-1670）
- Test: `test/data/hit_tier_config_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/data/hit_tier_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('HitTierConfig 解析 yaml', () {
    final c = HitTierConfig.fromYaml(const {
      'caption_peak_size': 68,
      'caption_glow_blur': 12.0,
      'closeup_scale': 1.10,
      'closeup_pulse_ms': 220,
    });
    expect(c.captionPeakSize, 68);
    expect(c.captionGlowBlur, 12.0);
    expect(c.closeupScale, 1.10);
    expect(c.closeupPulseMs, 220);
  });

  test('缺段回落默认（防御 fallback）', () {
    final c = HitTierConfig.fromYaml(const {});
    expect(c.captionPeakSize, 68);
    expect(c.closeupScale, 1.10);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/hit_tier_config_test.dart`
Expected: FAIL（`HitTierConfig` 未定义）

- [ ] **Step 3: 加 HitTierConfig 类 + AnimationNumbers 字段**

在 `numbers_config.dart` `AnimationNumbers` 类下方加：

```dart
/// 命中演出分级表现层参数（numbers.yaml `animation.hit_tier`）。
/// 纯表现层（题字字号/辉光、特写缩放/脉冲时长），不影响伤害/逻辑。
/// fixture 不带该段时回落默认值（沿 ImpactFeedbackConfig 防御体例）。
class HitTierConfig {
  final int captionPeakSize;   // 大招暴击 特大题字字号（基准 56）
  final double captionGlowBlur; // 暴击题字辉光模糊半径（0=无辉光）
  final double closeupScale;    // 特写缩放峰值
  final int closeupPulseMs;     // 特写缩放脉冲总时长（在关键帧 400ms 顿帧内）
  const HitTierConfig({
    required this.captionPeakSize,
    required this.captionGlowBlur,
    required this.closeupScale,
    required this.closeupPulseMs,
  });
  factory HitTierConfig.fromYaml(Map y) => HitTierConfig(
    captionPeakSize: (y['caption_peak_size'] as num?)?.toInt() ?? 68,
    captionGlowBlur: (y['caption_glow_blur'] as num?)?.toDouble() ?? 12.0,
    closeupScale: (y['closeup_scale'] as num?)?.toDouble() ?? 1.10,
    closeupPulseMs: (y['closeup_pulse_ms'] as num?)?.toInt() ?? 220,
  );
  static const HitTierConfig defaults = HitTierConfig(
    captionPeakSize: 68,
    captionGlowBlur: 12.0,
    closeupScale: 1.10,
    closeupPulseMs: 220,
  );
}
```

在 `AnimationNumbers` 加字段 `final HitTierConfig hitTier;`、构造默认 `this.hitTier = HitTierConfig.defaults`、`defaults` 静态值带 `hitTier: HitTierConfig.defaults`、`fromYaml` 加 `hitTier: HitTierConfig.fromYaml(y['hit_tier'] as Map? ?? const {})`。

- [ ] **Step 4: numbers.yaml 加 hit_tier 段**

在 `data/numbers.yaml` `animation:` 段内（`key_moment_hold_ms` 附近）加：

```yaml
  hit_tier:                    # 命中演出分级（纯表现层）
    caption_peak_size: 68      # 大招暴击 特大题字（基准 56）
    caption_glow_blur: 12.0    # 暴击题字辉光模糊半径
    closeup_scale: 1.10        # 命中特写缩放峰值
    closeup_pulse_ms: 220      # 特写脉冲时长（在关键帧 400ms 顿帧内）
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/data/hit_tier_config_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/hit_tier_config_test.dart
git commit -m "feat: 命中演出分级配置层 animation.hit_tier"
```

---

## Task 2: 派生真相源 — HitClimax + hitClimaxFor（纯函数）

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`（加公开 `characterById`）
- Modify: `lib/features/battle/presentation/impact_profile.dart`
- Test: `test/features/battle/hit_climax_test.dart`

- [ ] **Step 1: BattleState 加公开 characterById**

在 `battle_state.dart` `BattleState` 类内加（供击杀查找，DRY）：

```dart
/// 按角色 id 在 left/right 两队查找；找不到返 null。
BattleCharacter? characterById(int id) {
  for (final c in leftTeam) {
    if (c.id == id) return c;
  }
  for (final c in rightTeam) {
    if (c.id == id) return c;
  }
  return null;
}
```

- [ ] **Step 2: 写失败测试**

```dart
// test/features/battle/hit_climax_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_profile.dart';
// 用现有 battle fixtures/builder 造 BattleAction + BattleState。
// 复用 test/ 下既有战斗测试的角色/动作构造 helper（参照 impact_profile 或 battle_log 测试）。

void main() {
  // 大招+暴击 → ultimateCrit
  // normalAttack 命中使目标 isAlive=false → kill
  // 大招暴击且击杀 → ultimateCrit（优先，题字更大）
  // 普通命中非暴击非击杀 → none
  // 大招非暴击 → none（仅暴击大招才特写）
  // 闪避 → none
  // 占位，按既有 fixture 风格补全
}
```

> **实现者注**：先 `grep -rn "ImpactProfile\|impactProfileFor" test/` 找现有 impact_profile 测试的 BattleAction/BattleState 构造方式，照搬造样本，避免重造 fixture。

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/battle/hit_climax_test.dart`
Expected: FAIL（`HitClimax` / `hitClimaxFor` 未定义）

- [ ] **Step 4: 实现 hitClimaxFor**

在 `impact_profile.dart` 末尾加：

```dart
/// 命中峰值类型（特写触发源）。none=不特写。
enum HitClimax { none, ultimateCrit, kill }

/// 由 [action] + [state] 派生峰值类型。纯函数。
/// ultimateCrit = 大招/人剑合一 且暴击；kill = 本击使目标死亡。
/// 二者皆中时 ultimateCrit 优先（题字更大）。
HitClimax hitClimaxFor(BattleAction action, BattleState state) {
  final r = action.attackResult;
  if (r == null || r.isDodged) return HitClimax.none;
  if (isUltimateCaptionSkill(action.skill) && r.isCritical) {
    return HitClimax.ultimateCrit;
  }
  final targetId = action.targetId;
  if (targetId != null) {
    final target = state.characterById(targetId);
    if (target != null && !target.isAlive) return HitClimax.kill;
  }
  return HitClimax.none;
}
```

需在文件顶部确保已 import `battle_state.dart`（已有）。

- [ ] **Step 5: 补全测试用例并跑通**

按 Step 2 注释的 6 个用例补全（用 Step 2 找到的 fixture 风格）。
Run: `flutter test test/features/battle/hit_climax_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle/domain/battle_state.dart lib/features/battle/presentation/impact_profile.dart test/features/battle/hit_climax_test.dart
git commit -m "feat: 命中峰值派生 hitClimaxFor + BattleState.characterById"
```

---

## Task 3: 题字分级 — 峰值字号 + 暴击辉光

**Files:**
- Modify: `lib/features/battle/presentation/ultimate_caption_overlay.dart`
- Modify: `lib/features/battle/presentation/battle_screen.dart`（约 506-514 题字触发处）

- [ ] **Step 1: UltimateCaptionContent / show() 加可选参数**

`ultimate_caption_overlay.dart`：`UltimateCaptionContent` 加 `final double fontSize;`（默认 56）+ `final double glowBlur;`（默认 0）。`fontSize: 56`（约 63 行）改用该字段。`glowBlur>0` 时给 `Text.style.shadows` 加一层暖金辉光（`Shadow(color: WuxiaColors.resultHighlight, blurRadius: glowBlur)`，敌方用 gangMeng）。`UltimateCaptionOverlayState.show()` 签名加 `{double fontSize = 56, double glowBlur = 0}` 透传给 content。**默认值=现状**，现有调用零改动。

- [ ] **Step 2: battle_screen 题字触发处传分级参数**

`battle_screen.dart` 约 506-514（`isUltimateCaptionSkill` 分支 `_ultimateCaptionKey.currentState?.show(...)`）：先求 `final climax = hitClimaxFor(action, s);` 和 `final isCrit = action.attackResult?.isCritical ?? false;`。调 `show` 时传：
- `fontSize: climax == HitClimax.ultimateCrit ? widget.animConfig.hitTier.captionPeakSize.toDouble() : 56`
- `glowBlur: isCrit ? widget.animConfig.hitTier.captionGlowBlur : 0`

（`s` = 当前 BattleState，本方法已有；`widget.animConfig` 已是 AnimationNumbers，见 Task 1。）

- [ ] **Step 3: 编译 + 全量 analyze**

Run: `flutter analyze`
Expected: 0 issue（默认参数保证现有调用不破）

- [ ] **Step 4: widget 冒烟（不崩）**

复用现有 battle 题字 widget 测（`grep -rn "UltimateCaption" test/`）若有则加一例：大字号+辉光参数下 `UltimateCaptionContent` 能 build 不抛。无现成测试文件则跳过，留真机目检。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/presentation/ultimate_caption_overlay.dart lib/features/battle/presentation/battle_screen.dart
git commit -m "feat: 大招题字分级 — 暴击峰值特大字号 + 辉光"
```

---

## Task 4: 命中特写镜头 — 缩放脉冲

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`

> v1 范围：**居中缩放脉冲**（放大到 closeup_scale 再弹回），复用现有关键帧 400ms 顿帧窗口。spec 的「朝命中点轻推」留 v2（需目标 widget 坐标，本期不做，避免坐标 plumbing）。

- [ ] **Step 1: 加缩放 AnimationController**

`battle_screen.dart` State 内加 `late final AnimationController _closeupCtrl;`，`initState` 里 `_closeupCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: widget.animConfig.hitTier.closeupPulseMs));`，`dispose` 里 `_closeupCtrl.dispose();`。（参照现有 `_shakeCtrl` 的生命周期写法。）

- [ ] **Step 2: 命中处触发特写（门控同屏震）**

在 Step（Task3 已求 `climax`）的打击感块内、`if (!_isFastForward && _rushToActorId == null)` 门控内，加：

```dart
if (climax != HitClimax.none) {
  _closeupCtrl.forward(from: 0.0).then((_) => _closeupCtrl.reverse());
}
```

（与屏震同门控 → 快进/扫荡/拖招自动抑制，守在线=离线。）

- [ ] **Step 3: 战斗区包 Transform.scale**

找到战斗主区（现有屏震 `Transform.translate` 包裹处，搜 `_shakeCtrl` / `_impactShakeAmplitude` 的 build 用法），在其外再包一层由 `_closeupCtrl` 驱动的 `AnimatedBuilder` + `Transform.scale`：

```dart
AnimatedBuilder(
  animation: _closeupCtrl,
  builder: (_, child) {
    final s = 1.0 + (widget.animConfig.hitTier.closeupScale - 1.0) * _closeupCtrl.value;
    return Transform.scale(scale: s, child: child);
  },
  child: /* 现有屏震 Transform 包裹的战斗区 */,
)
```

- [ ] **Step 4: 全量 analyze + test**

Run: `flutter analyze && flutter test`
Expected: analyze 0；test 全绿（无新逻辑回归；特写纯表现层）

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "feat: 命中特写镜头 — 大招暴击/击杀缩放脉冲(快进抑制)"
```

---

## Task 5: 收口 — 全量验证 + 真机目检挂钩

**Files:** 无代码改动（验证 + 文档）

- [ ] **Step 1: 全量 analyze + test**

Run: `flutter analyze && flutter test`
Expected: analyze 0 issue；test 全绿。贴输出。

- [ ] **Step 2: 结算零改动核验（红线）**

Run: `git diff main --stat`
Expected: diff **不含** `damage_calculator.dart` / battle 结算逻辑 / schema（saveVer 不变）。仅表现层 + 配置 + 测试。

- [ ] **Step 3: 真机目检（与 ① 节奏校值同一次 pass）**

`flutter run -d macos` 看：① 大招暴击/击杀触发特写缩放、② 普通大招不特写、③ 暴击题字辉光+大招暴击特大字号、④ 快进/扫荡无特写。绝对值（峰值字号/辉光/缩放/脉冲 ms）边玩边在 `numbers.yaml animation.hit_tier` 调到手感对。**此步是表现层真验收，纯代码测覆盖不到。**

- [ ] **Step 4: 更新 PROGRESS.md**

顶段加一条 2026-06-27 演出分级实装条目（含测数 delta）。

---

## Self-Review 记录

- **spec 覆盖**：§3 真相源→Task2；§4 题字分级→Task3、特写→Task4（顿帧"新增"已纠偏=复用现有400ms）；§5 修饰签名→暴击辉光(Task3)/会心·破招已有不动；§6 特写门控→Task4 Step2；§7 配置→Task1；§9 验收→Task5。**未覆盖项**：暴击屏闪绛红/会心glyph/破招「破!」均已实装无需动（spec §5 标"有"）。
- **类型一致**：`HitTierConfig`(Task1) / `HitClimax`+`hitClimaxFor`(Task2) / `characterById`(Task2) / `captionPeakSize·captionGlowBlur·closeupScale·closeupPulseMs`(Task1↔3↔4) 全程同名。
- **依赖姐妹项**：① 节奏校值 + 内力平衡 不在本计划（真机调参/平衡，非本表现层 design）。
