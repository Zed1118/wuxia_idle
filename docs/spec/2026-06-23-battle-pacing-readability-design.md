# 战斗节奏与可读性打磨（方案 A+C · 表现层）

> 状态：design（待用户 review → writing-plans）
> 阶段：1.0 长线打磨期 · 第五阶段（战斗体验与掉落优化）轴
> 范围：**纯表现层 / 播放循环**，不动引擎数值/rng/重放/GDD 战斗模型
> 模型：xhigh（战斗 UI 核心状态机改动，节奏/确定性/边界需一次想全）

## 1. 目标

留 ATB（3v3 time-based 行动制），常速战斗**看得清**。用户实测四症状全中：
①一帧蹦出多个行动 ②单个动作也太快 ③特效太乱叠一起 ④不知道刚发生什么。
四症一次性治。**快进档不动**（刷关照样秒过，burst 可接受）。

## 2. 根因（已 code-grounded）

- **① burst**：`BattleNotifier.advance()`（`battle_providers.dart:132`）循环 `strategy.tick()` 直到 actionLog 增长，而 `tick()` **排空整个 tick 的所有就绪 actor** → 同 tick 多人就绪时一次 advance 涨 N 个；`battle_screen.dart:1060-1064` 监听增量后**同步 for 循环逐个 `_playAction`** → N 个动画一帧堆叠。
- **②③**：`action_interval_ms=800` 与伤害飘字 `damage_popup_ms=800` 同量级 → 上一拍飘字未消下一拍已来；闪(150)/震(100)/弹道(260)/飘字 全叠。
- **④**：单次行动无停够时间读的「谁→谁·招·伤害·效果」聚焦提示（战报条 `recentKeyActions` 是滚动列表，非当拍焦点）。

## 3. 方案 A — 一拍一个行动

**A1 播放驱动改逐 actor 单步**：新增 `BattleNotifier.advanceOneAction({int maxConsecutiveTicks=100})`——循环 `stepOne` 直到 actionLog **恰好 +1** 或战斗结束（自动跳过无人出手的 tick 边界空步）。常速 Timer 改驱动它，取代 `advance()`。
- 确定性不变：`stepOne` 与 `advance` 共用同一 seeded rng、消费顺序一致（`battle_step_one_test` 红线已锁）；只是把同一序列摊到更多 Timer 拍，**最终战斗结果逐位不变**。
- 边界：`requestUltimate` pending（拖招）路径仍用现有 `_rushToActorId` 快进 step 逻辑，不回归。
- 快进档保持现有 `advance()`（整 tick 排空）@ `fast_forward_interval_ms`——刷关不受影响。

**A2 监听层自然单拍**：advanceOneAction 每拍 ≤1 新 action，`battle_screen:1060` 的 for 循环天然只播一个；保留 for 以兼容快进 drain 路径（仍可能多个，快进态不强求逐拍）。

**A3 拍子留白**：常速 `action_interval_ms` 调到覆盖「攻击动画(rush150+hold100+retreat150=400) + 飘字读完」；`damage_popup_ms` 收到 ≤ 间隔，杜绝跨拍重叠。普攻拍短、不拖（见 C 分级）。

## 4. 方案 C — 关键帧语义化强调

**C1 关键帧分类**：复用 `BattleLog.isKeyAction`（暴击 / 大招 ultimate / 人剑合一 jointSkill / 破招 canInterrupt / 击杀）。

**C2 分级节奏**：
- 平庸普攻：短拍（brisk），不打断观感。
- 关键帧：延长 hold（扩现有 `_applyHitStop(profile.hitStopMs)` 顿帧）+ 强调（复用既有大招/破招**题字** overlay + 受击放大），给玩家「这一下重要」的停顿读条。

**C3 特效错峰**：单拍内 闪→震→飘字 按序触发而非全叠（现 `_playAction` 集中触发点已在 `battle_screen:733/517`，改为带微延时的序列）。

## 5. 数值（numbers.yaml · 全 tunable，真机调）

`animation` 段新增/调整（默认值待真机手感校准）：
- `action_interval_ms`：常速基础拍（候选 ~900-1100，从 800 起步上调）。
- `key_moment_hold_ms`（新）：关键帧额外停顿（候选 ~300-500）。
- `damage_popup_ms`：收到 ≤ `action_interval_ms`（候选 ~600）。
- 普攻 vs 关键帧拍长差值（或复用 impact_feedback 分档驱动）。

**红线**：本批 0 改伤害/血量/速度/倍率等战斗规则数值，只动表现时序。

## 6. 确定性 / 重放 / 测试

- **不变**：引擎、rng、`BattleReplayRecord`、balance_simulator、全部红线测。
- **新增逻辑测**：`advanceOneAction` 单调性——每次调用 actionLog 恰好 +1（或 finished）；连续调用与单次 `advance()`(drain) **终态逐位相等**（同 seed）；空 tick 自动跳过不卡死。
- **关键帧分类测**：isKeyAction 复用已覆盖，补「分级节奏选哪条」纯函数测（若抽 helper）。
- **节奏/手感**：表现层 timing 不单测，走真机 `flutter run -d macos` 目检（贴 §爽感主旋律 memory）。

## 7. 范围外（明确不做）

- 改 ATB→回合制（已讨论否决）/ 任何引擎·数值·重放·GDD 战斗模型改动。
- 出战编成 UI（已搁置）。
- 战斗机制深度（破招/协同新内容）——本批只调「看清已发生的事」，不加新机制。

## 8. 验收

真机常速跑 3v3（含多人同 tick 就绪场景 + 关键帧场景）：①逐拍单动作不再 burst ②每拍看清谁→谁·招·伤害 ③特效不糊成一团 ④关键帧明显「顿一下+强调」。快进档行为不变。analyze 0 / 全量测零回归 + 新增 advanceOneAction 测族绿。
