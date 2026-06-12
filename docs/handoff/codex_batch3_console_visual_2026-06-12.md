# 批三 + T8/T10/T11 指令台视觉验收 · 2026-06-12

结论：FAIL。5 个路由中 `battle_charge_break` 基础危险条/破招高亮可见，但 `battle_scene`、`equipment_detail_screen`、`character_panel`、`inventory` 均未满足本轮 PASS 条件；不可合 main。

## 环境

| 项 | 记录 |
|---|---|
| Worktree | `/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/battle-ux-equip-chain` |
| HEAD | `b040f0f6` |
| App | `build/macos/Build/Products/Debug/wuxia_idle.app` |
| 构建 | 复用预编 debug 包；未 build |
| 写入范围 | 仅 `docs/handoff/codex_batch3_console_visual_2026-06-12.md` 与 `docs/handoff/codex_batch3_console_visual_2026-06-12/` 截图 |
| 窗口 | app 默认打开为约 800×632 pt（Retina 截图 1600×1264 px）；未手动放大到规避溢出 |

备注：hub 鼠标点击在本机合成事件下不稳定，实际用 hub 键盘 Home/Down/Enter 进入路由；未 rebuild、未改代码。

## 逐路由判读

| 路由 | 结果 | 现象 | 截图 |
|---|---|---|---|
| `battle_charge_break` | 存疑 / 局部 PASS | 顶部绛红危险条存在，文案完整：「青衫剑客 正在蓄势：青锋绝（还有 2 回合发动）」；底部焦点在主控，`破招 / 破势 / 耗120` 按钮为金色并有白边。但当前默认窗口下右侧只露出一个技能分组按钮，未见强力/破招/共鸣/大招四组同排。 | `docs/handoff/codex_batch3_console_visual_2026-06-12/t1_charge_break.png` |
| `battle_scene` | FAIL | 最近战报条出现且为 3 行，右侧有 `›`；胜利 overlay 正常弹出。但指令台技能按钮区只显示一个「强力 / 重击 / 冷却3」按钮，未呈现强力→破招→共鸣→大招四组排布。 | `t3_report_strip.png`, `t3_victory_overlay.png` |
| `equipment_detail_screen` | FAIL | 首屏显示天问剑大图与信息卡上半部，可见属性、默契、属性加成与已解锁招式；未直接看到【强化 +N】/【开锋 X/3】入口，入口在当前首屏下方被裁出。 | `t8_equip_detail.png` |
| `character_panel` | FAIL | 装备区 3 个已穿槽可见；点击武器已穿槽 2 次内未弹出快捷面板，未见更换/强化/开锋/查看典故/卸下。切弟子页点击也未响应，空槽 sheet 未能验到。 | `t10_character_equip_section.png`, `t10_worn_slot_actions.png`, `t10_worn_slot_actions2.png` |
| `inventory` | FAIL | 装备 Tab 顶部筛选条存在（全部/可装备/已穿戴/可开锋/境界未达），但锁定装备覆盖文案为「未达境界」，不是具体境界原因（如「需一流境界」）；点击「境界未达」未切换到该筛选态。 | `t11_inventory.png`, `t11_inventory_filter_locked.png` |

## 修复点

1. `battle_scene` / `battle_charge_break`：按验收窗口确保指令台技能组完整呈现，至少能同时看到强力、破招、共鸣、大招四组，且不挤压、不溢出。
2. `equipment_detail_screen`：把强化与开锋入口继续上移，保证首屏直接可见。
3. `character_panel`：修复已穿装备槽点击命中，2 次内必须弹出快捷操作面板；同时确认空槽点击能打开装备选择 sheet。
4. `inventory`：锁定装备文案改为具体境界原因；筛选条点击后列表需实时过滤。

## 截图目录

`docs/handoff/codex_batch3_console_visual_2026-06-12/`

主要截图：

- `t1_charge_break.png`
- `t3_report_strip.png`
- `t3_victory_overlay.png`
- `t8_equip_detail.png`
- `t10_character_equip_section.png`
- `t10_worn_slot_actions.png`
- `t10_worn_slot_actions2.png`
- `t11_inventory.png`
- `t11_inventory_filter_locked.png`
