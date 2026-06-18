# 第五阶段 · 主线二 批次 2.4 · 打击感表现层 — Spec

> 日期：2026-06-18 · 状态：用户已拍板，开工
> 上游：`phase5_battle_experience_loot_spec_2026-06-17.md` §3 批次 2.4
> 设计支柱：GDD §5.7「战斗体验原则（爽感主旋律）」——爽感走表现层，不数值膨胀、不抽卡稀有炫耀
> 命名约定：第五阶段 / 主线二 / 批次 2.4（不嵌套「阶段」，见 memory feedback_wuxia_phase_naming）

## 0. 已锁定决策（用户拍板）

- **触发范围 = 分层**：普攻保留现有轻反馈（受击闪 `HitFlash` + 飞泥 `projectile_trail`），不加打击感；重击（暴击普攻 / 强力技 / 大招 / 人剑合一 / 破招）才上 hit-stop + 题字 + 镜头震。
- **题字 = 双轨分工**：大招 / 人剑合一沿用现有「招式全名」题字（炫技仪式）；强力技 / 暴击普攻显单字效果字「破·斩·震·断」；破招继续显「破!」。
- **强度 = 分级递进**：暴击普攻（light）< 强力技（medium）< 大招 / 人剑合一（heavy），三参数（hit-stop 时长 / 镜头震幅 / 闪白强度）按档递增。
- **架构 = 中央 ImpactProfile 派生 + 单点调度**（4 效果各自独立挂边沿、BattleState 字段驱动两案否决，后者违红线）。

## 1. Phase 0 已核实现状（2026-06-18 本仓实测，带 file:line）

- 边沿中央处理器：`battle_screen.dart:414` `_playAction(action, state)`，由 actionLog 增长驱动（`:952` `ref.listen` 第 3 分支 sublist 逐 action 调）。已驱动：出手动画 / 伤害飘字 `_spawnPopup` / 残影 `_spawnTrail`（`projectile_trail.dart`）/ 流派特效精灵 `_spawnBattleEffects` / 受击闪 `_triggerHitFlash`（`hit_flash.dart`）/ 大招题字 + 破! 题字（`ultimate_caption_overlay.dart`，`_playAction:431-443`）/ 音效。
- 播放节拍：`_playTimer = Timer.periodic(interval → advance())`（`battle_screen.dart:355-367`）；`interval` 取 `animConfig.actionIntervalMs`（常速）/ `fastForwardIntervalMs`（快进/拖招 rush）；`_startTimer` 内 `_isPaused` gate 兜所有重启路径（`:357`）。
- 快进/拖招态标志：`_isFastForward`（`:369`）/ `_rushToActorId`（`:284`，2.3 拖招即放 C5 快进到出手）。
- 现有题字 overlay：`UltimateCaptionOverlay`（`ultimate_caption_overlay.dart:78`，GlobalKey `_ultimateCaptionKey:270` 命令式 `show(name, isEnemy)`，250ms 淡入 + 1200ms 停留 + 350ms 淡出）；展示内容 `UltimateCaptionContent`（水墨墨团 `caption_ink_blob.png` + 双层描边大字，玩家暖金 `resultHighlight` / 敌方绛红 `gangMeng`）。
- 派生字段齐（零新 schema）：`SkillDef.type`（normalAttack/powerSkill/ultimate/jointSkill）/ `SkillDef.style`（`TechniqueSchool?` gangMeng/lingQiao/yinRou，`enums.dart:104-106`）/ `SkillDef.canInterrupt`；`BattleAction.interrupted`（破招事件）+ `attackResult.isCritical` / `isDodged`。
- 数值层：`numbers.yaml combat.*`（系数全 yaml，§5.6）。
- 后台挂机：battle_screen 未挂载时 `_playTimer` 不存在 → 屏上表现层全部不触发（守 §5.5）。

## 2. 派生层（纯函数 · 可单测）

新建 `lib/features/battle/presentation/impact_profile.dart`：

```
enum ImpactTier { light, medium, heavy }

class ImpactProfile {
  final ImpactTier tier;
  final String? glyph;        // 「破/斩/震/断」单字；大招/人剑合一为 null（走全名题字双轨）
  final int hitStopMs;
  final double shakeMagnitude;
  final double flashStrength;  // 全屏闪白 alpha 上界
}

ImpactProfile? impactProfileFor(BattleAction action, NumbersConfig cfg);
```

判定规则（**全派生现有字段，零 schema、零迁移**）：

1. **返 null（无打击感，走现有轻反馈）**：`attackResult == null` / `isDodged` / 普攻且 `!isCritical`。
2. **tier 派生**：
   - `light` = 暴击普攻（`skill.type == normalAttack && isCritical`）
   - `medium` = 强力技（`skill.type == powerSkill`）
   - `heavy` = 大招 / 人剑合一（`isUltimateCaptionSkill(skill)`，复用 `ultimate_caption_overlay.dart:11`）
3. **glyph 派生**（仅 light/medium 非破招非大招；heavy / 破招 / 大招返 null）：
   - `action.interrupted` → null（破招走现有「破！」通道，不重复出单字，见下）
   - `skill.style == gangMeng` → 「震」
   - `skill.style == yinRou` → 「断」
   - `skill.style == lingQiao` 或 `style == null` → 「斩」（默认）
   - 单字常量进 `UiStrings`（`impactGlyphZhan/Zhen/Duan`，三字），不散写。
4. **三参数**：按 tier 从 `cfg.combat.impactFeedback.{light,medium,heavy}` 取。

> 「破·斩·震·断」中的「破」由现有破招「破！」（`UiStrings.interruptCaption`，`_playAction:438` 既有分支独占）承载——2.4 不动该分支，新 glyph 通道只产 斩/震/断。破招仍可经 `impactProfileFor` 拿到 tier（hit-stop/震/闪照常给打击感），仅 glyph 为 null 不弹单字，避免与「破！」双弹。详 §7 防重叠。

## 3. hit-stop（命中瞬停）

`_playAction` 末端，若 `profile != null` 且**非快进/拖招态**（`!_isFastForward && _rushToActorId == null`）：

```
_playTimer?.cancel();
_hitStopTimer?.cancel();
_hitStopTimer = Timer(Duration(milliseconds: profile.hitStopMs), () {
  if (mounted) _startTimer();   // _startTimer 内 _isPaused/finished gate 兜住
});
```

- **快进/拖招态跳过**：保快进顺滑 + 不碰 2.3 拖招即放时序不变量（`interveneNow` 在 tick 边界，hit-stop 只延后下一播放拍，不改 AP/出手）。
- 复用 `_isPaused` gate（暂停态 `_startTimer` 直接 return，不会被 hit-stop 复活）；`dispose` 释放 `_hitStopTimer`。
- 纯屏上播放节拍延后：`advance()` 结算结果确定不变，只是「何时播放下一拍」后移 80–120ms（守 §5.5 逻辑/速度不变、§5.4 伤害不变）。

## 4. 镜头轻震（复用既有 `_shakeCtrl` · 2026-06-18 修订）

> **Phase 0 补漏（开工后发现）**：battle_screen 已有屏震基建——`_shakeCtrl`（`battle_screen.dart:233/298`，`duration = animConfig.shakeDurationMs=100ms`）+ `screenShakeOffset`（`lib/shared/effects/screen_shake.dart`）包整个 SafeArea（含 HUD），**当前仅暴击触发、固定振幅 `animConfig.shakeOffsetPx=3.0`**（`_spawnPopup:623`）。故**复用此基建并分档**，不新建平行 `CameraShake`（两套屏震会在暴击重击双抖）。原 spec「只包场景层」属过度规定——既有 shipped 行为是整 SafeArea 抖，保留一致。

- 加字段 `double _impactShakeAmplitude`（默认 0）。`_playAction` 中 profile != null 且非快进/拖招态 → `_impactShakeAmplitude = profile.shakeMagnitude; _shakeCtrl.forward(from: 0)`。
- build 中 `screenShakeOffset(amplitude: ...)` 改读 `_impactShakeAmplitude`（替 `animConfig.shakeOffsetPx`）。
- **删 `_spawnPopup:623` 旧暴击触发**（`_playAction` 集中后避免双抖；`_spawnPopup` 由 `_playAction:423` 调，时序在 profile 块前）。
- 振幅分档：light 3.0（≈既有暴击振幅，行为不退化）/ medium 6.0 / heavy 10.0（profile 取自 numbers.yaml）。duration 沿用既有 100ms。
- 触发同 hit-stop（非快进/拖招）——既有暴击震在快进态也触发，本批改为快进/拖招跳过（去 juice 快放，可接受的小行为变更）。

## 5. 单字题字 overlay（ImpactGlyphOverlay）

新建 `ImpactGlyphOverlay`（与 `UltimateCaptionOverlay` 并列，独立 GlobalKey）：

- 复用 `UltimateCaptionContent` 的水墨墨团 + 双层描边样式，但**单字**（字号可同或略大，停留更短：约 120ms 淡入 + 500ms 停留 + 250ms 淡出，短促有力，区别于全名题字 1800ms）。
- 命令式 `show(glyph, isEnemy)`，latest-wins 覆盖。
- 仅 `profile.glyph != null` 时触发（即 light/medium 非破招重击）。
- 大招 / 人剑合一仍走现有 `_ultimateCaptionKey.show(skill.name)`（双轨，互不干扰）。

## 6. 闪白（全屏轻闪）

重击在现有单体 `HitFlash`（贴目标头像）之外，叠一层**全屏轻闪** overlay：

- 命令式 controller，`ColoredBox` 全屏，alpha 上界 = `profile.flashStrength`（heavy 最亮），快速淡出（约 120ms）。
- 放在场景层之上、题字 overlay 之下（闪白不糊题字）。
- 暴击色沿用现有约定（暴击绛红 `gangMeng` / 否则白，参 `_triggerHitFlash:467`）。

## 7. 防重叠 / 双轨边界（关键）

- **破招**：`_playAction:438` 既有 `if (action.interrupted)` 分支独占弹「破！」（`UltimateCaptionOverlay`）。2.4 **不改该分支**；`impactProfileFor` 对 `interrupted` 仍派生 tier（hit-stop/震/闪照常给打击感），但 glyph 已在 §2 派生中返 null（不弹单字），故 `ImpactGlyphOverlay` 天然不触发，无需额外 gate。
- **大招 / 人剑合一**：heavy tier 给 hit-stop/震/闪 + 现有全名题字；glyph 为 null 不弹单字。
- 即：任一 action 至多一个题字通道（全名 XOR 单字 XOR 破!），打击感三件套（stop/震/闪）按 tier 叠加。

## 8. 数值（全进 numbers.yaml · §5.6）

新增 `numbers.yaml`：

```yaml
combat:
  impact_feedback:
    light:   { hit_stop_ms: 60,  shake_magnitude: 3.0, flash_strength: 0.12 }
    medium:  { hit_stop_ms: 90,  shake_magnitude: 6.0, flash_strength: 0.20 }
    heavy:   { hit_stop_ms: 120, shake_magnitude: 10.0, flash_strength: 0.30 }
```

- 初值占位，真机调手感后定稿（hit-stop 区间 60–120ms 落 spec §3 80–120ms 范围内，light 取 60ms 偏短保普攻暴击不顿）。
- schema 解析进 `NumbersConfig`（与现有 `combat.*` 同构），加载校验。

## 9. 测试

- **纯函数单测** `impact_profile_test.dart`：glyph 4 字映射（破招/刚猛/阴柔/灵巧/无 style）/ tier 3 档（暴击普攻/强力技/大招/人剑合一）/ 返 null（闪避 / 普攻非暴击 / attackResult 空）/ heavy glyph 为 null。
- **widget 测**：重击触发 `ImpactGlyphOverlay` 渲染单字 + 不溢出 720p；破招仍走「破!」不双弹单字（防重叠断言）；普攻非暴击无 overlay。
- **红线断言**：2.4 改动不写 BattleState（grep/结构断言）；不调用伤害公式（`damage_calculator` 零新引用）；hit-stop 仅操作 `_playTimer` 不碰 `advance` 结算。
- 全量回归：analyze 0 + 全量测零回归（主 checkout build_runner 后实测）。

## 10. 红线守护清单

- §5.4 表现层不写 BattleState、伤害公式零调用、不进百万（本批不产伤害）。
- §5.5 在线=离线：hit-stop 只动屏上播放节拍，逻辑/速度不变；后台挂机不触发。
- §5.6 不硬编码：三参数进 numbers.yaml，单字「破/斩/震/断」进 UiStrings。
- §5.7 爽感走表现层边界：分层 + 分级递进，不靠数值膨胀。
- 2.3 不变量：快进/拖招态跳过 hit-stop + 镜头震，不碰 `interveneNow` tick 边界时序。

## 11. 实现顺序（plan 拆 task 参考）

1. 派生层 `impact_profile.dart` + UiStrings 单字 + numbers.yaml schema + 纯函数单测（无 UI 依赖，先行）。
2. 单字题字 `ImpactGlyphOverlay` + `_playAction` 接入（双轨 + 防重叠）+ widget 测。
3. 全屏闪白 overlay + 接入。
4. 镜头震 `CameraShake` 包场景层 + 接入。
5. hit-stop 接入（`_playTimer` 延后 + 快进/拖招跳过 + dispose）+ 红线断言测。
6. 视觉验收（真机 / route 自截）+ 全量回归 + 并 main。
