# E1 视觉验收 54 项 FAIL triage（2026-08-28）

基线：`1ba913a633beb0fd8f9b47764161f47c54260707`。独立复算 `phase2_visual_acceptance_a2_20260826.md:12-59` 的 48 行：溢出 PASS/FAIL/SKIP=`46/0/2`，返回=`34/12/2`，键盘=`24/22/2`，semantics=`26/20/2`；四列 FAIL=`0+12+22+20=54`，与派单一致。

## 取证口径

- 临时 widget 探针在真实屏内逐屏发送 Tab：11/11 键盘 FAIL 屏均取得非空 primary focus；主交互 InkWell 节点有 `focus/tap` action。探针取证后已删除，`test/` 零最终 diff。
- 同一探针读取 SemanticsNode：下列 S1-S9 主卡均 `isButton=false`；A1 地点档案返回与 `sweep_screen` 的 PlaqueButton 均 `isButton=true`。这一区分不依赖焦点环截图。
- B1（战斗返回候选全排除）：`phase0a_battle_screen.dart:603-619` 终局 Enter 只重试、进行中 Esc 只暂停；`:668-677` Scaffold 无 appBar；`:798-811` 仅终局重试且主线 host 未传 builder（`phase0a_mainline_battle_host.dart:291-297`）。主线/塔 wrapper 只在外部 pop 后兜底 surrendered，不提供控件（`stage_entry_flow.dart:1474-1533`；`tower_entry_flow.dart:447-484`）。
- S1（主线关卡卡）：主 CTA 为裸 `InkWell`（`stage_list_screen.dart:1048-1049`）；时间线 `Semantics` 只有总标签（`:571-578`），情报按钮（`:1193-1196`）和叙事 TextButton（`:1326-1342`）只执行各自子动作，不能赋予主 CTA button role。
- S2（心魔卡）：唯一关卡 CTA 为裸 `InkWell`（`inner_demon_screen.dart:278-279`）；AppBar（`:71-74`）只负责页面返回。
- S3（塔层卡）：主 CTA 为裸 `InkWell`（`tower_floor_card.dart:182-188`）；掉落传闻控件（`:337-367`）只开传闻，标题栏返回/榜单（`tower_floor_list_screen.dart:111-123`）也不赋予塔层卡 button role。
- S4（守城卡）：唯一关卡 CTA 为裸 `InkWell`（`mass_battle_screen.dart:243-244`）；AppBar（`:70-73`）只负责页面返回。
- S5（轻功卡）：唯一路线 CTA 为裸 `InkWell`（`light_foot_screen.dart:230-231`）；AppBar（`:67-70`）只负责页面返回。
- S6（当前要事卡）：唯一摘要 CTA 为裸 `InkWell`（`main_menu_status_summary.dart:153-166`），无另一路由控件可为该卡补 button role。
- S7（远征卡）：候选卡与方针卡均为裸 `InkWell`（`expedition_overview_screen.dart:261-273,345-355`）；派遣 PlaqueButton（`:243-246`）是选卡后的下游动作，不能替代两类卡的 role。
- S8（奖励卡）：三张候选均为裸 `InkWell`（`gauntlet_reward_screen.dart:183-188,239-242`）；确认 PlaqueButton（`:94-103`）只在先激活候选后出现。
- S9（门派谱角色卡）：角色卡为裸 `InkWell`（`lineage_panel_screen.dart:315-375`）；顶部门人调度 TextButton（`:50-56`）与条件式飞升按钮（`:283-291`）执行别的动作。
- A1（地点档案实路）：`mainline_location_archive_screen.dart:71-73` 提供返回；落到 `WuxiaTitleBar` 的 `WuxiaIconButton`（`wuxia_title_bar.dart:66-70`），其显式 label/button/focus/activate 在 `wuxia_icon_button.dart:52-71`。

## 54 条逐条分类

| 目标 | 视口 | 列 | 分类 | 证据 `file:line` |
|---|---|---|---|---|
| stage_entry_flow | 1280×720 | 返回 | 真缺陷 | B1；`stage_entry_flow.dart:1474-1533` |
| stage_entry_flow | 1440×900 | 返回 | 真缺陷 | B1；`stage_entry_flow.dart:1474-1533` |
| stage_list_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦主卡；`stage_list_screen.dart:1048-1049` |
| stage_list_screen | 1280×720 | semantics | 真缺陷 | S1；`stage_list_screen.dart:1048-1049,1193-1196,1326-1342` |
| stage_list_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦主卡；`stage_list_screen.dart:1048-1049` |
| stage_list_screen | 1440×900 | semantics | 真缺陷 | S1；`stage_list_screen.dart:1048-1049,1193-1196,1326-1342` |
| tower_entry_flow | 1280×720 | 返回 | 真缺陷 | B1；`tower_entry_flow.dart:447-484` |
| tower_entry_flow | 1440×900 | 返回 | 真缺陷 | B1；`tower_entry_flow.dart:447-484` |
| sweep_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦 PlaqueButton；`sweep_screen.dart:383-403` |
| sweep_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦 PlaqueButton；`sweep_screen.dart:383-403` |
| phase0a_mainline_battle_host | 1280×720 | 返回 | 真缺陷 | B1；`phase0a_mainline_battle_host.dart:291-297` |
| phase0a_mainline_battle_host | 1440×900 | 返回 | 真缺陷 | B1；`phase0a_mainline_battle_host.dart:291-297` |
| phase0a_battle_screen | 1280×720 | 返回 | 真缺陷 | B1；`phase0a_battle_screen.dart:603-619,668-677,798-811` |
| phase0a_battle_screen | 1440×900 | 返回 | 真缺陷 | B1；`phase0a_battle_screen.dart:603-619,668-677,798-811` |
| inner_demon_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦关卡卡；`inner_demon_screen.dart:278-279` |
| inner_demon_screen | 1280×720 | semantics | 真缺陷 | S2；`inner_demon_screen.dart:278-279` |
| inner_demon_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦关卡卡；`inner_demon_screen.dart:278-279` |
| inner_demon_screen | 1440×900 | semantics | 真缺陷 | S2；`inner_demon_screen.dart:278-279` |
| tower_floor_list_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦塔层卡；`tower_floor_card.dart:182-188` |
| tower_floor_list_screen | 1280×720 | semantics | 真缺陷 | S3；`tower_floor_card.dart:182-188,337-367` |
| tower_floor_list_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦塔层卡；`tower_floor_card.dart:182-188` |
| tower_floor_list_screen | 1440×900 | semantics | 真缺陷 | S3；`tower_floor_card.dart:182-188,337-367` |
| mass_battle_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦关卡卡；`mass_battle_screen.dart:243-244` |
| mass_battle_screen | 1280×720 | semantics | 真缺陷 | S4；`mass_battle_screen.dart:243-244` |
| mass_battle_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦关卡卡；`mass_battle_screen.dart:243-244` |
| mass_battle_screen | 1440×900 | semantics | 真缺陷 | S4；`mass_battle_screen.dart:243-244` |
| light_foot_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦路线卡；`light_foot_screen.dart:230-231` |
| light_foot_screen | 1280×720 | semantics | 真缺陷 | S5；`light_foot_screen.dart:230-231` |
| light_foot_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦路线卡；`light_foot_screen.dart:230-231` |
| light_foot_screen | 1440×900 | semantics | 真缺陷 | S5；`light_foot_screen.dart:230-231` |
| main_menu_status_summary | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦摘要卡；`main_menu_status_summary.dart:153-166` |
| main_menu_status_summary | 1280×720 | semantics | 真缺陷 | S6；`main_menu_status_summary.dart:153-166` |
| main_menu_status_summary | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦摘要卡；`main_menu_status_summary.dart:153-166` |
| main_menu_status_summary | 1440×900 | semantics | 真缺陷 | S6；`main_menu_status_summary.dart:153-166` |
| phase0a_visual_roster | 1280×720 | 返回 | 真缺陷 | 名册仅数据 `phase0a_visual_roster.dart:18-20`；实际表面同 B1 `phase0a_battle_screen.dart:603-619` |
| phase0a_visual_roster | 1440×900 | 返回 | 真缺陷 | 名册仅数据 `phase0a_visual_roster.dart:18-20`；实际表面同 B1 `phase0a_battle_screen.dart:603-619` |
| mainline_location_archive_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦“返回”；A1 `mainline_location_archive_screen.dart:71-73` |
| mainline_location_archive_screen | 1280×720 | semantics | 判据误用 | 实测 label=返回/isButton=true；`wuxia_icon_button.dart:52-71` |
| mainline_location_archive_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦“返回”；A1 `mainline_location_archive_screen.dart:71-73` |
| mainline_location_archive_screen | 1440×900 | semantics | 判据误用 | 实测 label=返回/isButton=true；`wuxia_icon_button.dart:52-71` |
| expedition_overview_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦候选卡；`expedition_overview_screen.dart:261-273` |
| expedition_overview_screen | 1280×720 | semantics | 真缺陷 | S7；`expedition_overview_screen.dart:261-273,345-355` |
| expedition_overview_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦候选卡；`expedition_overview_screen.dart:261-273` |
| expedition_overview_screen | 1440×900 | semantics | 真缺陷 | S7；`expedition_overview_screen.dart:261-273,345-355` |
| gauntlet_reward_screen | 1280×720 | 返回 | 判据误用 | 必选奖励后显式出栈；`gauntlet_reward_screen.dart:18-21,94-131,239-242` |
| gauntlet_reward_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦奖励卡；`gauntlet_reward_screen.dart:239-242` |
| gauntlet_reward_screen | 1280×720 | semantics | 真缺陷 | S8；`gauntlet_reward_screen.dart:94-103,239-242` |
| gauntlet_reward_screen | 1440×900 | 返回 | 判据误用 | 必选奖励后显式出栈；`gauntlet_reward_screen.dart:18-21,94-131,239-242` |
| gauntlet_reward_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦奖励卡；`gauntlet_reward_screen.dart:239-242` |
| gauntlet_reward_screen | 1440×900 | semantics | 真缺陷 | S8；`gauntlet_reward_screen.dart:94-103,239-242` |
| lineage_panel_screen | 1280×720 | 键盘 | 判据误用 | Tab 实测聚焦角色卡；`lineage_panel_screen.dart:315-375` |
| lineage_panel_screen | 1280×720 | semantics | 真缺陷 | S9；`lineage_panel_screen.dart:50-56,283-291,315-375` |
| lineage_panel_screen | 1440×900 | 键盘 | 判据误用 | Tab 实测聚焦角色卡；`lineage_panel_screen.dart:315-375` |
| lineage_panel_screen | 1440×900 | semantics | 真缺陷 | S9；`lineage_panel_screen.dart:50-56,283-291,315-375` |

## 汇总与修复建议（仅建议，未实装）

- 汇总：真缺陷 **28** 条（返回 10、semantics 18）；判据误用 **26** 条（返回 2、键盘 22、semantics 2）；无法判定 **0** 条。合计 54。
- 战斗返回（聚合 5 个目标/10 条）：在 `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart` 增加暂停态可见、可键盘激活的“退出战斗”；由 `phase0a_mainline_battle_host.dart`、`phase0a_tower_battle_host.dart` 把退出回调接到 `stage_entry_flow.dart`、`tower_entry_flow.dart` 的 surrendered 路径。不要改 `phase0a_visual_roster.dart`，它不是 UI。
- 主卡 semantics（聚合 9 屏/18 条）：在 `stage_list_screen.dart`、`inner_demon_screen.dart`、`tower_floor_card.dart`、`mass_battle_screen.dart`、`light_foot_screen.dart`、`main_menu_status_summary.dart`、`expedition_overview_screen.dart`、`gauntlet_reward_screen.dart`、`lineage_panel_screen.dart` 为可点主卡补 `Semantics(button:true, enabled:onTap!=null, label:...)`，并在相应 widget test 加 button/label/disabled 与真实 Tab+Enter 守卫。
