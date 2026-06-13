# Codex UI Polish Sweep Closeout v0

日期: 2026-06-12  
分支: `fix/ui-polish-sweep`  
本地验收 SHA: `5cdd696e`  
阶段: Day 1 诊断 sweep + Day 2 低风险表现层微调

## 开局确认

- 已读 `PROGRESS.md` 顶段: 当前为 1.0 长线打磨期, 质量优先, 不设上线压力。
- 已读 `CLAUDE.md` §5 / §9: 本轮不碰数值、文案、GDD、CLAUDE、numbers、schema、IDS, 不引入新状态管理或游戏引擎, 避免 Material 饱和色。
- 已切本地分支 `fix/ui-polish-sweep`, 未 push, 未 merge main。
- 已执行 `./tool/build_acceptance.sh`, 产物:
  - `build/macos/Build/Products/Debug/wuxia_idle.app`

## 截图证据

- 主 sweep: `docs/handoff/visual_capture_5cdd696e_20260612_234753/`
  - 27/27 routes READY
  - 全部为 1280x720 视口, Retina 输出 2560x1440
  - 全部为干净窗口截图, 无全屏兜底
- 1080p 对照 1: `docs/handoff/visual_capture_5cdd696e_20260613_004017/`
  - `enemy_gallery`, `main_menu`, `battle_charge_break`
- 1080p 对照 2: `docs/handoff/visual_capture_5cdd696e_20260613_004658/`
  - `seclusion_setup`
- Day 2 after: `docs/handoff/visual_capture_5cdd696e_20260613_011907/`
  - `seclusion_setup`, `battle_charge_break`, `enemy_gallery`
  - before/after 拼图: `docs/handoff/visual_capture_5cdd696e_20260613_011907/_before_after_ui_polish_3_routes_1280x720.png`
- 分组 contact sheet:
  - `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_sheet_27_routes_1280x720.png`
  - `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_battle_1280x720.png`
  - `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_systems_1280x720.png`
  - `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_seclusion_equipment_1280x720.png`
  - `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_narrative_dialog_gallery_1280x720.png`

## 严重度概览

| 严重度 | 数量 | 概览 |
|---|---:|---|
| P0 | 1 | `seclusion_setup` 720p 主操作按钮被视口裁掉, 文本不可读 |
| P1 | 2 | `battle_charge_break` 高饱和红/黄按钮与水墨体系不统一; `enemy_gallery` 第二排卡片信息被裁 |
| P2 | 8 | 长页/列表 720p 密度、空状态、展览页暗底可读性等细节 |
| PASS | 16 | 未见破版、溢出、缺图或明显配色跑偏 |

Day 2 微调后: P0 0 / P1 0 / 剩余 P2 8。原 P0/P1 三项均已用 1280x720 after 截图闭环。

## 逐路由诊断表

维度编号: 1 对齐与栅格; 2 字号层级; 3 留白与密度; 4 水墨克制色; 5 溢出截断; 6 图像兜底; 7 状态可读性; 8 触控目标。

| 路由 | 问题 | 维度 | 严重度 | Day 2 处置建议 |
|---|---|---:|---|---|
| `battle_scene` | 基础战斗界面稳定; 底部战报字号略小但未影响布局 | 2 | P2 | 观察, 不优先改 |
| `battle_ultimate_caption` | 大招题字构图稳定, 无溢出 | - | PASS | 不改 |
| `battle_boss_frame` | Boss 边框/单位状态可读, 无溢出 | - | PASS | 不改 |
| `battle_charge_break` | 指令按钮使用高饱和红/黄, 与其他战斗路由的克制墨色按钮不统一; 1080p 仍存在 | 4,7 | P1 | 可做低风险纯样式微调, before/after 必留 |
| `battle_interrupt_caption` | 破招题字稳定, 无溢出 | - | PASS | 不改 |
| `battle_defeat` | 败北 overlay 稳定, 主按钮可读可点 | - | PASS | 不改 |
| `character_panel` | 下方装备区只露出标题, 但主档案信息完整; 属长页密度问题 | 3,5 | P2 | 观察, 不优先改 |
| `character_panel_growth` | 修炼进度与派生数值可读; 下方仍是长页裁切 | 3 | P2 | 观察 |
| `technique_panel_tier_all` | 主修卡与三系图稳定; 底部下一段仅露边, 未破主内容 | 3 | P2 | 观察 |
| `technique_panel_hero` | 和 tier_all 结构一致, 无新增风险 | 3 | P2 | 观察 |
| `main_menu` | 720p 下底部入口被截, 1080p 正常; 首屏信息量偏满但可滚动语义明显 | 3,5 | P2 | 可微调密度, 非优先 |
| `chapter_list` | 章节横卡与章节列表稳定, 状态徽章清晰 | - | PASS | 不改 |
| `sect_screen_npc` | 空状态文案位置偏低且对比偏弱, 但不破布局 | 3,7 | P2 | 可小调空状态可读性 |
| `stage_list` | 主线列表稳定, Boss/通关态清晰 | - | PASS | 不改 |
| `tower_floor_list` | 时间线可读; 顶部/底部露出相邻卡片属滚动定位痕迹 | 3 | P2 | 观察 |
| `seclusion_map_list` | 地图卡图像兜底正常; 底部下一卡片露边属长列表 | 3 | P2 | 观察 |
| `seclusion_setup` | 1280x720 下主按钮仅露顶部红边, 按钮文本不可见; 1920x1080 正常 | 5,8 | P0 | Day 2 优先低风险压缩布局或固定底部安全区 |
| `seclusion_active` | 进行中面板主按钮可见, 信息层级清楚 | - | PASS | 不改 |
| `seclusion_result` | 返回按钮完整可见; 结果列表和突破提示稳定 | - | PASS | 不改 |
| `inventory` | 装备/物料 tabs、筛选、格子均稳定; 锁态清晰 | - | PASS | 不改 |
| `equipment_detail_screen` | 强化/开锋首屏可见; 典故区域从下方露出属长页内容 | - | PASS | 不改 |
| `equipment_detail_gallery` | 图片均加载; 暗底展览页文件名偏小, 底部下一行露边 | 2,3 | P2 | 观察或展览页统一缩略说明 |
| `narrative_scene` | 背景、正文浮层、继续按钮稳定; 无缺图 | - | PASS | 不改 |
| `technique_refine_insight_dialog` | 弹窗可读, 双按钮目标足够 | - | PASS | 不改 |
| `encounter_outcome_skill_banner` | 横幅位置和留白稳定, 无溢出 | - | PASS | 不改 |
| `battle_victory_first_clear` | 首通胜利奖励 overlay 可读; 按钮可见 | - | PASS | 不改 |
| `enemy_gallery` | 第二排头像进入视口但名称/血条被底部裁掉; 1080p 仍有同类裁切 | 1,3,5 | P1 | 需要调整 gallery 栅格行距/首屏布局; 纯表现层但改前留 before/after |

## Day 2 已改

| 路由 | 文件 | 改动 | 结果 |
|---|---|---|---|
| `seclusion_setup` | `lib/features/seclusion/presentation/seclusion_setup_screen.dart` | 低高度视口启用紧凑布局: 降低 hero 高度、panel padding、卡片 minHeight 与垂直间距 | 1280x720 下「开始闭关」按钮完整可见 |
| `battle_charge_break` | `lib/features/battle/presentation/battle_screen.dart` | 技能指令按钮从纯流派色改为与 sidebar 混色, 保留破招金色高亮和流派边框 | 红/黄饱和度收敛, 可读性与状态区分保留 |
| `enemy_gallery` | `lib/features/debug/presentation/visual_route_host.dart` | gallery 栅格 childAspectRatio 0.62 -> 1.0, 缩小头像与血条宽度 | 1280x720 下前两排完整可见, 第三排露出作为滚动延续 |

## Day 2 候选队列

### 已当场微调

| 优先级 | 路由 | 微调方向 | 风险 |
|---:|---|---|---|
| 1 | `seclusion_setup` | 压缩 hero/产出卡/时长卡竖向间距, 让主按钮进入 720p 安全区 | 已改 |
| 2 | `battle_charge_break` | 将强力/共鸣/大招按钮颜色收敛到绛红/墨色 token, 保留破招强调但降低饱和度 | 已改 |
| 3 | `enemy_gallery` | 降低垂直间距并缩小头像/血条, 让第二排完整显示名称与血条 | 已改 |

### 待 Claude 闸门

- Day 2 若涉及 `lib/**/presentation` 以外文件, 停止并交回。
- Day 2 后需要跑 `flutter analyze` 与相关视觉复截图; 全量测试/合 main 闸门交 Claude。

### 待用户拍板 / 暂不改

- `main_menu` 720p 首屏信息量偏满: 是否追求 720p 全入口更完整, 还是保留当前大卡片质感。
- 展览页 (`equipment_detail_gallery`, `enemy_gallery`) 是否需要独立规范: 当前更像 debug gallery, 不完全像正式 UI。

## 当前未做事项

- 未修改 `data/`, `numbers.yaml`, `GDD.md`, `CLAUDE.md`, `data_schema.md`, `IDS_REGISTRY.md`。
- 未执行全量测试; 本轮为纯表现层微调, 已跑相关检查。
- 未提交 commit, 未 push。

## 验证

- `./tool/build_acceptance.sh` PASS
- `./tools/visual_capture/visual_capture.sh --res 1280x720 seclusion_setup battle_charge_break enemy_gallery` PASS, 3/3 READY
- `flutter analyze` PASS, 0 issues
- `flutter test test/features/seclusion/presentation/seclusion_map_list_screen_test.dart test/features/seclusion/presentation/seclusion_e2e_test.dart` PASS, 7/7
- `flutter test test/features/battle/presentation/battle_command_console_test.dart` PASS, 13/13

## 当前未改事项

- P2 项暂不动: `main_menu` 720p 密度、长列表露边、空状态可读性、展览页文件名偏小等, 均未破布局。
