# Codex 派单：全项目 UI 视觉打磨 sweep

**日期：** 2026-06-12
**项目：** 挂机武侠 · `/Users/a10506/Desktop/Projects/挂机武侠`
**分支：** main · HEAD 6b8eb9fc（已与 origin 同步）
**体量：** 周末两天 · 跨 27 个验收路由
**角色：** Codex 是 Mac 本地视觉验收 + 微调角色。这是一次全项目 UI 视觉统一性体检 + 低风险微调闭环。

---

## 背景

项目处于 1.0 长线打磨期（质量优先，不设上线压力）。战斗结束时序重排子系统刚落地，借此对全项目 UI 做一次横向视觉统一性 sweep：把散落各屏的对齐 / 字号 / 留白 / 配色 / 溢出问题一次扫出来，低风险的当场微调闭环，拿不准的记录待拍板。**不赶工、不偷懒，能一次扫全面就扫全面。**

## 开局动作（先报告，别直接改代码）

1. 读 `PROGRESS.md` 顶段 + `CLAUDE.md` §5 红线 / §9 不要做的事清单
2. `./tool/build_acceptance.sh` 编验收包（debug + `VISUAL_ROUTE=hub`），产物 `build/macos/Build/Products/Debug/wuxia_idle.app`
3. 用 `tools/visual_capture/visual_capture.sh <route...>` 批量截图（脚本默认双分辨率，sweep 主跑 1280×720），或 `open` 验收包用 hub 入口运行时切路由手动截
4. 全 27 路由扫一遍，**先出诊断表（Day 1 不改代码）**，报告诊断概览，再进 Day 2 微调

## 验收路由全清单（27 条，逐条过）

| 组 | 路由 |
|---|---|
| 战斗（6） | battle_scene / battle_ultimate_caption / battle_boss_frame / battle_charge_break / battle_interrupt_caption / battle_defeat |
| 角色修养（4） | character_panel / character_panel_growth / technique_panel_tier_all / technique_panel_hero |
| 主菜单导航（3） | main_menu / chapter_list / sect_screen_npc |
| 主线内容（2） | stage_list / tower_floor_list |
| 闭关（4） | seclusion_map_list / seclusion_setup / seclusion_active / seclusion_result |
| 装备物品（3） | inventory / equipment_detail_screen / equipment_detail_gallery |
| 叙事（1） | narrative_scene |
| 弹窗对话（3） | technique_refine_insight_dialog / encounter_outcome_skill_banner / battle_victory_first_clear |
| 展览（1） | enemy_gallery |

## 打磨诊断维度（每路由按这 8 维过一遍）

1. **对齐与栅格**：元素左 / 右 / 居中对齐是否一致，卡片内边距是否统一
2. **字号层级**：标题 / 正文 / 注释字号梯度是否清晰一致（卡内标题锚 14 w600）
3. **留白与密度**：是否拥挤或空旷，呼吸感
4. **水墨克制色**：有无 Material 默认饱和色（亮蓝 / 紫 / 荧光绿）漏网；是否守住青 / 墨 / 宣纸黄 / 绛红点缀（CLAUDE §9）
5. **溢出截断**：1280×720 下文字溢出、按钮挤出、竖排多单位累加溢出、异常横向滚动（720p 是最低分辨率，重点查）
6. **图像兜底**：`Image.asset` `errorBuilder` 是否生效，缺图不破布局
7. **状态可读性**：锁态 / 灰显 / 进度条 / 徽章 / tier 边框是否清晰
8. **触控目标**：按钮点击区是否够大（桌面鼠标）

**严重度分级：**
- **P0** = 破布局 / 溢出 / 缺图破版 / 饱和色明显违和
- **P1** = 明显不统一（同类屏字号·对齐·配色不一致）
- **P2** = 微调优化（留白·克制度·细节打磨）

## 硬规矩（5 条，不可破）

1. **不合 main**：所有改动只在专用分支或 worktree，合 main 闸门（`flutter analyze` 0 / 全量测 / 红线审）交回 Claude，你不 push main、不 merge。
2. **纯表现层 only**：只改 `lib/**/presentation` 下的颜色 / 间距 / 字号 / 留白 / 对齐参数。**禁动**：`numbers.yaml`、schema、任何数值常量、`data/*.yaml`、文案、战斗数学、Isar saveVersion。Dart 里不新增中文硬编码文案、不新增硬编码数值（CLAUDE §5.6）。
3. **改前判严重度**：P0 / P1 中纯样式参数的低风险项可自主改 + 截图闭环；凡涉及布局重构、需产品方向拍板、或拿不准方向的，**只记录不改**，留给用户 / Claude。
4. **每个改动必带 before/after**：同路由 1280×720 改前改后各一张截图对照。
5. **出 closeout**：诊断表 + 改动文件清单 + 截图目录，处置分三类标注：已改（带 before/after）/ 待 Claude 闸门 / 待用户拍板。

## 不可碰红线（CLAUDE §5）

数值红线（普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000）；三系锁死；不硬编码数值文案；不动 `GDD.md` / `CLAUDE.md` / `numbers.yaml` / `data_schema.md` / `IDS_REGISTRY.md`。水墨克制配色是要守的方向，不是要打破的。

## 两天节奏

### Day 1 — 诊断 sweep（不改代码）
- 编验收包 → 扫全 27 路由 1280×720（疑似溢出 / 布局问题的路由补 1920×1080 对照）
- 逐路由按 8 维填诊断表，列：路由 | 问题 | 维度 | 严重度 | 建议处置 | 截图
- 产全量诊断 closeout v0，报告 P0 / P1 / P2 分布概览

### Day 2 — 微调闭环
- 按诊断表挑 P0 / P1 低风险纯样式项执行微调
- 每项 before/after 1280×720 对照
- 更新 closeout，三类处置标注清楚

## 产物

- **截图目录**：`docs/handoff/visual_capture_<sha>_<时间戳>/`（脚本自动），文件名 `<route>_<分辨率>.png`
- **closeout**：`docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md`
- **改动分支名建议**：`fix/ui-polish-sweep`

---

## 基建速查

- **VisualRoute 枚举**：`lib/features/debug/application/visual_route.dart`
- **验收入口 / seed 工厂**：`lib/features/debug/presentation/visual_route_host.dart`（`buildVisualTarget()` route→seed+widget；hub 入口 `_AcceptanceHub`）
- **编验收包**：`tool/build_acceptance.sh`（单数 tool）
- **批量截图**：`tools/visual_capture/visual_capture.sh`（复数 tools）—— 等就绪信号 `VISUAL_ROUTE_READY: <id>` + settle 2s，截纯窗口
- **就绪信号**：首帧后 debugPrint `VISUAL_ROUTE_READY: <id>`
