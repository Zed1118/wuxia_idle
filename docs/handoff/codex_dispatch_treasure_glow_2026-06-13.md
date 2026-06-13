# Codex 派单：时序重排真玩视觉验收 + 神物金光强度回收

**日期：** 2026-06-13
**项目：** 挂机武侠 · `/Users/a10506/Desktop/Projects/挂机武侠`
**分支：** main · HEAD 89b4e31c（已与 origin 同步）
**角色：** Codex 是 Mac 本地视觉验收 + 微调角色。本轮聚焦战斗结束「时序重排」子系统真玩待办里 **Codex 能静态截图闭环的部分 = 神物金光强度 + tier-gate**。

---

## 背景

战斗结束时序重排 + 真玩迭代已落地（神物掉落爆品镜头带专属金光：边缘暖金辉光 + 盖章金闪 + 双环涟漪；重器/宝物不启用）。真玩待办之一：**金光强度是否太抢 / wash out，是否需要回收克制度**。

为让你能截图验金光（金光峰值是瞬时动画，运行时单帧截不到），已新加 3 个验收路由，把金光冻结在固定动画时间轴 `t`，并已合 main：

| route | 内容 | t |
|---|---|---|
| `battle_treasure_glow_peak` | 神物天问剑金光**峰值帧**（金闪迸发 + 双环涟漪 + 辉光升起叠加，金光最强时刻） | ≈0.32 |
| `battle_treasure_glow_rest` | 神物天问剑金光**末态**（辉光驻留，金闪/涟漪已褪） | 1.0 |
| `battle_treasure_zhongqi` | 重器青虚剑爆品（tier-gate 神物专属金光**不启用**，对比无金光） | 1.0 |

## 验收问题（核心，逐条截图判定）

1. **金光是否太抢**：`battle_treasure_glow_peak` 峰值帧的金光（辉光+金闪+涟漪叠加）是否盖住爆品内容 —— 印章落款 / 装备名 / 属性行（攻·血·速）/ 典故金句是否仍清晰可读。
2. **辉光是否 wash out**：`battle_treasure_glow_rest` 末态辉光驻留是否让背景/内容发灰、对比下降。
3. **tier-gate 正确性**：`battle_treasure_zhongqi` 是否确实无金光（与神物两图对比，确认稀有感拉开）。

## 金光强度回收（若判定太抢/wash out）

金光三层 opacity 系数在 `lib/features/equipment/presentation/treasure_drop_overlay.dart` 的 **`TreasureGlowLayer`** 类：

- ① 辉光：`opacity: (((t - 0.16) / 0.28).clamp(0.0, 1.0)) * 0.85`
- ② 金闪：`opacity: (1 - (t - 0.30).abs() / 0.16).clamp(0.0, 1.0) * 0.32`
- ③ 涟漪：`opacity: (1 - rp) * 0.85`

回收 = 调小这些尾部 opacity 系数（0.85 / 0.32 / 0.85）。

⚠️ **`TreasureGlowLayer` 被真实 `TreasureDropOverlay` 委托**，改它即改生产爆品镜头（这正是回收目的）。这属于**纯表现层 opacity 系数微调**（非 numbers.yaml 红线数值），是本轮的合法改动目标。改后必须：3 route before/after 1280×720 + 跑 `treasure_glow_layer_test.dart`（改 opacity 不影响 tier-gate 断言，应仍 3/3 绿）。

## 硬规矩（5 条，不可破）

1. **不合 main**：改动只在分支/worktree，合 main 闸门（`flutter analyze` 0 / 全量测 / 红线审）交回 Claude，你不 push main、不 merge。
2. **纯表现层 only**：本轮合法改动 = `TreasureGlowLayer` 的金光 opacity 系数 + 必要 presentation 间距/色。**禁动**：numbers.yaml、schema、数值常量、data/*.yaml、文案、战斗数学、Isar saveVersion、爆品门槛 `treasure_drop.min_tier`、TreasureDropContent 的内容布局逻辑。
3. **改前判 + 留拍板**：金光是否太抢由你截图判 + 给回收建议；回收幅度涉及「顶级稀有感」产品手感，**激进幅度（如砍半）只给方案不硬改，交用户拍板**；克制小幅（如 0.85→0.7）可自主试 + before/after。
4. **每改动 before/after**：3 route 各 1280×720 改前改后对照。
5. **出 closeout**：截图判定表（route × 太抢/wash out/OK）+ 回收方案/已改 + 三类处置（已改 / 待 Claude 闸门 / 待用户拍板）。

## Codex 验不了的待办（留用户真玩，本轮别碰）

- **SFX 时序**：victory + reward 双 jingle 是否吵 —— 音频听感，截图判不了。
- **简版勝 1.6s 时长**：是否合适 —— 动效时长手感，验收 route 是静态帧。
- **爆品镜头 vs 简版勝时序切换**：真玩流程，非单屏静态。

## 开局动作（先报告，别直接改代码）

1. 读 `PROGRESS.md` 顶段 + `CLAUDE.md` §5 红线
2. `./tool/build_acceptance.sh` 编验收包
3. `./tools/visual_capture/visual_capture.sh --res 1280x720 battle_treasure_glow_peak battle_treasure_glow_rest battle_treasure_zhongqi`（先截现状三图）
4. **报告金光强度判定**（太抢 / wash out / OK）+ 回收建议，再决定是否动手微调

## 产物

- **截图目录**：`docs/handoff/visual_capture_<sha>_<时间戳>/`，文件名 `<route>_1280x720.png`
- **closeout**：`docs/handoff/codex_treasure_glow_acceptance_2026-06-13_closeout.md`
- **改动分支名建议**：`fix/treasure-glow-tune`

---

## 基建速查

- 金光层 widget：`lib/features/equipment/presentation/treasure_drop_overlay.dart` → `TreasureGlowLayer`（tier-gate：仅 `EquipmentTier.shenWu` 启用）
- 验收路由 enum：`lib/features/debug/application/visual_route.dart`
- 验收 preview：`lib/features/debug/presentation/visual_route_host.dart` → `_TreasureGlowPreview`
- tier-gate 测：`test/features/equipment/presentation/treasure_glow_layer_test.dart`（3 case，改 opacity 后应仍绿）
- 编包：`tool/build_acceptance.sh` · 截图：`tools/visual_capture/visual_capture.sh`
