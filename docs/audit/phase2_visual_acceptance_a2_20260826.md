# Phase 2 A2：T2+T3 双视口视觉验收（2026-08-26）

口径：内容区 1280×720 / 1440×900；Retina 截图分别为 2560×1440 / 2880×1800。正式证据采集期间唯一 macOS App、唯一 GUI 写入者、串行切路由；未修改玩家可见 UI。
结果（2026-08-26 协调者改判后）：46 个可达行中 14 行全项 PASS、32 行至少命中一项 FAIL；`stage_victory_dialog` 两视口经真实导航仍被生产结算异常阻断，按契约记 SKIP。互斥态不外推：未引用 widget test 扩大覆盖，只登记实际抵达状态。
`phase0a_battle_screen` / `phase0a_visual_roster` 的四张图均改走 `phase0a_black_ridge_profile`：生产 catalog → runtime binding → encounter host → screen，不使用 debug battle YAML 轻负载。
过程注：重拍准备时 CUA 按显示名读取误拉起另一 worktree 的同 bundle-id 旧 App；发现后在抓图前退出两者，改按本 worktree 绝对 App 路径重启，替换图均于实例计数 1 时采集。

## 证据表（正好 48 行）

| 目标 | 视口 | 溢出 | 返回 | 键盘 | semantics | 鼠标 | 截图文件名 |
|---|---|---|---|---|---|---|---|
| stage_entry_flow | 1280×720 | PASS | FAIL | PASS | PASS | N/A | stage_entry_flow_1280x720.png |
| stage_entry_flow | 1440×900 | PASS | FAIL | PASS | PASS | N/A | stage_entry_flow_1440x900.png |
| stage_list_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | stage_list_screen_1280x720.png |
| stage_list_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | stage_list_screen_1440x900.png |
| stage_victory_dialog | 1280×720 | SKIP | SKIP | SKIP | SKIP | SKIP | — |
| stage_victory_dialog | 1440×900 | SKIP | SKIP | SKIP | SKIP | SKIP | — |
| tower_entry_flow | 1280×720 | PASS | FAIL | PASS | PASS | N/A | tower_entry_flow_1280x720.png |
| tower_entry_flow | 1440×900 | PASS | FAIL | PASS | PASS | N/A | tower_entry_flow_1440x900.png |
| sweep_screen | 1280×720 | PASS | PASS | FAIL | PASS | N/A | sweep_screen_1280x720.png |
| sweep_screen | 1440×900 | PASS | PASS | FAIL | PASS | N/A | sweep_screen_1440x900.png |
| phase0a_mainline_battle_host | 1280×720 | PASS | FAIL | PASS | PASS | N/A | phase0a_mainline_battle_host_1280x720.png |
| phase0a_mainline_battle_host | 1440×900 | PASS | FAIL | PASS | PASS | N/A | phase0a_mainline_battle_host_1440x900.png |
| phase0a_battle_screen | 1280×720 | PASS | FAIL | PASS | PASS | N/A | phase0a_battle_screen_1280x720.png |
| phase0a_battle_screen | 1440×900 | PASS | FAIL | PASS | PASS | N/A | phase0a_battle_screen_1440x900.png |
| inner_demon_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | inner_demon_screen_1280x720.png |
| inner_demon_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | inner_demon_screen_1440x900.png |
| tower_floor_list_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | tower_floor_list_screen_1280x720.png |
| tower_floor_list_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | tower_floor_list_screen_1440x900.png |
| mass_battle_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | mass_battle_screen_1280x720.png |
| mass_battle_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | mass_battle_screen_1440x900.png |
| light_foot_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | light_foot_screen_1280x720.png |
| light_foot_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | light_foot_screen_1440x900.png |
| main_menu_status_summary | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | main_menu_status_summary_1280x720.png |
| main_menu_status_summary | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | main_menu_status_summary_1440x900.png |
| phase0a_visual_roster | 1280×720 | PASS | FAIL | PASS | PASS | N/A | phase0a_visual_roster_1280x720.png |
| phase0a_visual_roster | 1440×900 | PASS | FAIL | PASS | PASS | N/A | phase0a_visual_roster_1440x900.png |
| mainline_location_archive_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | mainline_location_archive_screen_1280x720.png |
| mainline_location_archive_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | mainline_location_archive_screen_1440x900.png |
| pending_jianghu_affairs_screen | 1280×720 | PASS | PASS | PASS | PASS | N/A | pending_jianghu_affairs_screen_1280x720.png |
| pending_jianghu_affairs_screen | 1440×900 | PASS | PASS | PASS | PASS | N/A | pending_jianghu_affairs_screen_1440x900.png |
| light_foot_participant_picker | 1280×720 | PASS | PASS | PASS | PASS | N/A | light_foot_participant_picker_1280x720.png |
| light_foot_participant_picker | 1440×900 | PASS | PASS | PASS | PASS | N/A | light_foot_participant_picker_1440x900.png |
| disciple_scheduling_screen | 1280×720 | PASS | PASS | PASS | PASS | N/A | disciple_scheduling_screen_1280x720.png |
| disciple_scheduling_screen | 1440×900 | PASS | PASS | PASS | PASS | N/A | disciple_scheduling_screen_1440x900.png |
| mass_battle_participant_picker | 1280×720 | PASS | PASS | PASS | PASS | N/A | mass_battle_participant_picker_1280x720.png |
| mass_battle_participant_picker | 1440×900 | PASS | PASS | PASS | PASS | N/A | mass_battle_participant_picker_1440x900.png |
| sect_itinerary_panel | 1280×720 | PASS | PASS | PASS | PASS | N/A | sect_itinerary_panel_1280x720.png |
| sect_itinerary_panel | 1440×900 | PASS | PASS | PASS | PASS | N/A | sect_itinerary_panel_1440x900.png |
| technique_panel_screen | 1280×720 | PASS | PASS | PASS | PASS | N/A | technique_panel_screen_1280x720.png |
| technique_panel_screen | 1440×900 | PASS | PASS | PASS | PASS | N/A | technique_panel_screen_1440x900.png |
| expedition_recap_screen | 1280×720 | PASS | PASS | PASS | PASS | N/A | expedition_recap_screen_1280x720.png |
| expedition_recap_screen | 1440×900 | PASS | PASS | PASS | PASS | N/A | expedition_recap_screen_1440x900.png |
| expedition_overview_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | expedition_overview_screen_1280x720.png |
| expedition_overview_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | expedition_overview_screen_1440x900.png |
| gauntlet_reward_screen | 1280×720 | PASS | FAIL | FAIL | FAIL | N/A | gauntlet_reward_screen_1280x720.png |
| gauntlet_reward_screen | 1440×900 | PASS | FAIL | FAIL | FAIL | N/A | gauntlet_reward_screen_1440x900.png |
| lineage_panel_screen | 1280×720 | PASS | PASS | FAIL | FAIL | N/A | lineage_panel_screen_1280x720.png |
| lineage_panel_screen | 1440×900 | PASS | PASS | FAIL | FAIL | N/A | lineage_panel_screen_1440x900.png |

## FAIL / SKIP 记录（只登记，不给修复方案）

- 返回 FAIL：战斗态 `stage_entry_flow` / `tower_entry_flow` / `phase0a_mainline_battle_host` / `phase0a_battle_screen` / `phase0a_visual_roster` 无返回控件；`gauntlet_reward_screen` 只有选奖流程。复现：进入对应路由或真实战斗，检查顶栏并点 Esc。涉及：`lib/features/mainline/presentation/phase0a_mainline_battle_host.dart`、`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart`、`lib/features/boss_gauntlet/presentation/gauntlet_reward_screen.dart`。
- 键盘 FAIL：Tab 跳过主交互卡或只有灰底、无可辨焦点环，覆盖 stage/tower/light-foot/mass-battle 列表、心魔、主菜单状态卡、远征总览、门派谱、扫荡结果、断魂庄奖励。复现：进入页面后连续 Tab 至循环。涉及各目标 screen 文件，代表：`stage_list_screen.dart`、`tower_floor_list_screen.dart`、`inner_demon_screen.dart`、`main_menu_status_summary.dart`、`expedition_overview_screen.dart`、`lineage_panel_screen.dart`、`sweep_screen.dart`。
- semantics FAIL：可点击卡在 AX 树中为 `text` / `image` / `container`，或返回按钮 label 为空，覆盖 stage/tower/light-foot/mass-battle 列表、心魔、状态摘要、地点、远征、断魂庄奖励、门派谱。复现：Accessibility Inspector 绑定 App 后检查主要卡片 role/label。涉及同名 presentation screen 文件。
- 鼠标 **N/A（无法验证 · 2026-08-26 协调者改判，原记 46 行 FAIL）**：macOS `screencapture` 默认不含光标，本次证据全部来自截图，执行端不具备观测 cursor 形状的能力，「均为默认箭头 cursor」不是可成立的观测结论。代码事实反证：共用交互组件 `WuxiaInkButton` 在 `lib/shared/widgets/wuxia_ink_button.dart:72-77` 显式设置 `FocusableActionDetector(mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic)`，该组件在 `lib/` 有 49 处调用点，覆盖本表绝大多数目标；`stage_list_screen` / `inner_demon_screen` 等用 `InkWell`，同样自带 click cursor。故 46 行改记 N/A（量测能力边界），不作为产品缺陷登记。若要真判 cursor，须用能录入光标的录屏或 `SystemMouseCursors` 断言型 widget test，属独立任务。
- SKIP（两视口）：`stage_list` → `stage_01_05` 真战胜出后在胜利弹窗前抛 `Bad state: Combat settlement participant does not match the selected character`（`stage_entry_flow.dart:1799`）；另走 `stage_list_cycle`，强攻战败、寻隙超时，且 headless 结算抛身份不匹配（`sweep_settlement.dart:97`），故无可诚实截图。
- 溢出：46 个可达行均未见 RenderFlex 黄黑条、文字裁切或无滚动的出界；720p 长页均验证可滚动。空待办/单地点等真实空态按轻负载计，不作极限声明。

## fixture 参数出处

| 参数 | 值 | 来源 file:line |
|---|---|---|
| 心法面板阶位 | 7 阶各 1 本 | `lib/features/debug/application/phase2_seed_service.dart:1132-1149` |
| 黑风岭生产 roster | 40 敌；同时在场上限 12 | `data/combat/encounters/black_wind_ridge.yaml:5-6,15-255` |
| 黑风岭路由数据链 | stage_01_03 + repository catalog/runtime binding + 生产 combatants | `lib/features/debug/presentation/visual_route_host.dart:521-568` |
| 黑风岭玩家技能定义 | 3 条（直拳/重击/怒涛拳）；图中实际装备 1 条 + 5 空槽，不作满载声明 | `data/techniques.yaml:24-35; data/skills.yaml:78-124` |
| 主线选关状态 | Ch1 01-04 已通，01-05 可挑战 | `lib/features/debug/application/phase2_seed_service.dart:424-451` |
| 通天塔列表 | 49 层 | `data/towers.yaml:2-10` |
| 轻功路线 | 5 路 | `data/stages.yaml:4-5,5382-5622` |
| 守城路线密度 | 5 关；首关 2 波/10 敌，末关 4 波/26 敌 | `data/stages.yaml:4-5,5749-5750,5982-5983` |
| 参与者池/远征候选 | 祖师、大弟子、二弟子 3 人 | `lib/features/debug/application/phase2_seed_service.dart:1338-1362,1414-1417` |
| 远征返程 | 深度 14；5 项奖获；1 人负伤 | `lib/features/debug/presentation/visual_route_host.dart:1453-1473` |
| 断魂庄奖励 | awaitingRewardChoice；3 件候选 | `lib/features/debug/application/phase2_seed_service.dart:1528-1568` |
| 门派谱 | 1 代；祖师 + 2 门人；1 件遗物 | `lib/features/debug/presentation/visual_route_host.dart:2384-2426` |

## 小结

48 行（改判后按溢出/返回/键盘/semantics 四项判）：PASS 14，FAIL 32，SKIP 2；截图 46/46 存在且尺寸匹配。剩余未做行：0。鼠标列 46 行统一记 N/A，理由见上。

## 改判溯源（2026-08-26 协调者）

- 单列 0 PASS / 46 FAIL 是量测失效的典型签名，先证伪再采信：已用代码事实证伪，见上「鼠标」条。
- 改判仅动鼠标列。返回 12 FAIL、键盘 22 FAIL、semantics 20 FAIL **保持原判**，未做同类证伪，属后续独立 triage 项，不在本次改判范围。
- `stage_victory_dialog` 两行 SKIP 的根因（`Combat settlement participant does not match the selected character`，`stage_entry_flow.dart` / `sweep_settlement.dart`）已由结算参与者身份修复单关闭，这 2 行现已具备重拍条件，但本次未重拍，仍记 SKIP。
