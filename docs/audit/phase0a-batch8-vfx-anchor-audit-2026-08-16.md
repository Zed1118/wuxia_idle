# Phase 0A Batch 8A VFX 锚点审计

**审计日期**: 2026-08-16  
**基线**: `[READY] 3aa7e8a3` (Phase 0A 第七批)  
**审计范围**: 表现层 VFX 特效位置绑定现状  
**参考**: `codex/phase0a-combat-feel-slice` (只读, Flame probe 路线)

## 1. 核心发现

### 1.1 所有 CustomPaint VFX 固定在屏幕中心

| 特效 | 文件:行 | 当前 anchor | 问题 |
|------|---------|------------|------|
| 掌风轨迹 | `phase0a_battle_screen.dart:412` | `const Center(...)` | 不绑定出手者/目标位置 |
| Q 涡旋 | `phase0a_battle_screen.dart:422` | `const Center(...)` | 不绑定玩家位置 |
| R 墨爆 | `phase0a_battle_screen.dart:433` | `const Center(...)` | 不绑定玩家位置 |
| 死亡墨散 | `phase0a_battle_screen.dart:442` | `const Center(...)` | 不绑定被击败敌人位置 |

**唯一的例外**: 伤害数字 (`_damagePopup`:465-493) 已正确使用 `stage.worldToScreen(actor.position)` 绑定。

### 1.2 死亡墨散存在尸体丢失风险

`Phase0aVfxController.consume()` 在消费 `Phase0aEnemyDefeated` 事件时，只记录 `targetId` 字符串。渲染时 `_FeedbackLayer._actor()` 从 `controller.state.enemies` 查询位置——但敌人死亡后可能已从 state 移除，导致 `_actor()` 返回 null，fallback 到 `safeRect.center`。

**修复方向**: VFX entry 中应保存事件发生时的 `ArenaVector` 快照，而非运行时查询 id。

### 1.3 掌风 VFX 缺少位置信息

`Phase0aVfxEntry` 的 `palmTrail` 类型仅记录 `actorId` 和 `targetId`，渲染时未使用。`_FeedbackLayer` 直接渲染 `const Center(...)`，完全忽略 entry 携带的 id 信息。

## 2. 只读参考: combat-feel-slice 结论

`codex/phase0a-combat-feel-slice` (Flame probe) 的可用结论:

- **命中反馈**: 闪白 0.08s + 血条强调 1.4s 效果可接受
- **伤害标签池**: 48 个标签、共享缓存、无 `saveLayer`/标签，峰值 22/48
- **聚怪控制**: 拉拢后 1.35s 停顿窗口，失衡 3.2s
- **掌风升级**: 从白线改为墨绿掌风片，有效距离 420→540
- **性能**: 反馈池 136/160，双视口 p99 < 9.1ms，零超预算帧

**注意**: 这些实现基于 Flame 世界坐标系统，不能直接复用到 Flutter widget 架构。

## 3. 审计结论

当前 VFX 特效与战斗动作完全脱节，是 Demo 感的主要来源。修复方向明确：将 VFX entry 扩展为携带位置快照，渲染层使用 `Phase0aStage.worldToScreen()` 将快照映射到屏幕坐标。