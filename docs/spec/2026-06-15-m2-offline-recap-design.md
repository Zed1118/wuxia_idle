# M2 离线收益汇总「归来」卡 — 设计 + 实装 spec

> 2026-06-15 · 范围 A **已实装并合 main**（commit `7efb82c8`，13 测）。范围 B 仍待拍板，单独立项。
> Phase 0 诊断见 §1。

## §1 Phase 0 诊断结论（关键事实）

1. **离线产出机制不存在**：`SaveData.lastOnlineAt` 死字段（全仓无读写点）。GDD §5.5「关游戏 8h 回来=挂 8h」当前未实装被动挂机。
2. **唯一时间→产出路径 = 闭关**：`SeclusionService.completeRetreat` 按真实时长结算（`actualHours = min(elapsed, planned, cap)`）。
3. **无金币概念**：资源 = 磨剑石 / 心血结晶 / 经验。审查表「记金币」实为磨剑石/经验。
4. 启动直接进 HomeFeed，无离线汇总 UI。

## §2 范围 A（已实装 ✅）

**「重开时若闭关有进展/已满，弹『归来』卡 + 引导收功」**

- 用现有 active RetreatSession，重开算 elapsed → 显示「离去约 Xh · 『地图』闭关[已圆满/进行中 P%] · 预计可收 N 磨剑石 · M 经验」+「前去收功」。
- 不新增挂机机制、不改 §5.5 语义、0 改 schema：仅把**已发生的**闭关产出可见化。无红线风险。

### 实装落点（commit `7efb82c8`）

| 层 | 文件 | 测 |
|---|---|---|
| 计算 | `seclusion/application/offline_recap_service.dart`（纯函数，复用 computeOutputs） | 6 |
| UI | `seclusion/presentation/offline_recap_card.dart`（PaperPanel+PlaqueButton 水墨卡） | 4 |
| 挂钩 | `seclusion/presentation/offline_recap_gate.dart`（`maybeShowOfflineRecap`） | 3 |
| 接入 | `home_feed/presentation/home_feed_screen.dart`（ConsumerStatefulWidget postframe 调一次） | — |
| 文案 | `shared/strings.dart` `offlineRecap*` 段 | — |

- 阈值：离开 ≥ 1h 才弹；无 active / 无 Isar 时静默 no-op。
- 预估产出与实际收功口径一致（同走 `computeOutputs`）。
- 「前去收功」push `ActiveRetreatScreen`；「稍后再说」关闭。

## §3 范围 B（仍待拍板 · 红线相邻 · 单独立项）

**「真·通用被动离线挂机 + 累计总额」** = 实装 GDD §5.5 通用被动挂机，当前完全不存在，是新机制。触红线 §5.5（在线=离线）+ §5.1（反留存）。4 个待拍板：

1. 离线产出真发放到背包，还是仅预览？
2. 未闭关时关游戏算不算挂机产出？（全新被动经济，冲击现有产出曲线）
3. 用哪个地图/角色算产出？
4. 累计字段（总磨剑石/总经验）用途？（仅汇总卡展示，还是 M15 统计看板铺垫）

若做：SaveData 扩字段 + saveVer 0.23→0.24 迁移 + 新 OfflineCalculatorService + 启动路由改造 + **数值平衡复评**。应单独立项，不混在 UX polish 项里。

## §4 后续可选增强

- `lastOnlineAt` 真写入点（app lifecycle detached / 存档时）做精确「离开时长」；当前用 `session.startedAt` 推算已够。
