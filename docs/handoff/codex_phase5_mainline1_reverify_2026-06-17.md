# Codex 复验报告：主线一战斗 UI 交互复验（单步路由）

时间：2026-06-17  
项目：`/Users/a10506/Desktop/Projects/挂机武侠`  
分支：`feat/phase5-battle-experience`  
HEAD：`96dbd5ac`  
路由：`flutter run -d macos --dart-define=VISUAL_ROUTE=battle_drag_live`（未加 `DEVELOPER_DIR`）

## 开局确认

- 已读 `docs/handoff/codex_dispatch_phase5_mainline1_reverify_2026-06-17.md`、`PROGRESS.md` 顶段续20/续21、`CLAUDE.md` §5 红线。
- 启动后终端打印 `VISUAL_ROUTE_READY: battle_drag_live`。
- 初始画面为暂停态，顶栏可见继续/单步按钮；单步按钮点击后回合从 0 推进到 1。
- 顺手复确认：内力条显示 `内 1500 / 1500`；底部技能区、头像区、日志区无明显溢出。

截图：`00_initial_fullscreen.png`、`18_single_step_button_round1.png`

## 逐项判定

| 项 | 判定 | 现象 | 截图 |
|---|---|---|---|
| D：aoe 单击弹简介 | 通过 | 单击 `万钧裂空` 弹宣纸水墨简介浮层，字段可见 `目标 群体`、倍率 5000、耗内 250、冷却 5 回合；未直接出手。 | `01_D_aoe_click_info.png` |
| D：single 单击弹简介 | 通过 | 单击 `裂石指` 弹宣纸水墨简介浮层，字段可见 `目标 单体`、倍率 3000、耗内 250、冷却 3 回合；未直接出手。 | `02_D_single_click_info.png` |
| C：single 长按拖招 | 通过（有暂停态说明） | 长按 `裂石指` 拖到 `铁布衫客` 头像，出现红色引导线与目标黄色高亮。松手后暂停态先显示 `待发`，继续推进后日志出现 `主控「裂石指」10118 伤（暴击）`，目标血量从 40000 降到 24496。 | `03_C_single_drag_guideline.png`、`07_C_single_after_continue.png` |
| C：aoe 长按拖招 | 不通过 | fresh 路由单独复验：长按 `万钧裂空` 拖到场地中央有引导线，继续推进后只顶部敌人扣血（40000 → 16416），`巷口杀手`/`巷尾杀手` 仍为 40000/40000；未按“群体技松手即对全体触发”表现。前序战斗中也复现同样现象。 | `12_C_aoe_fresh_guideline.png`、`14_C_aoe_fresh_after_continue.png` |
| E：内力不足文案 | 通过 | 反复拖放大招并推进后，主控内力降到 `0 / 1500`，`裂石指` 与 `万钧裂空` 按钮状态行均显示 `内力不足`。 | `17_E_mana_insufficient.png` |
| F：debuff + hover 释义 | 无法确认 | 路由推进到回合 46，未出现 `内伤` 标签。代码核对显示 `scenarioDragLive()` 三名我方均为 `TechniqueSchool.gangMeng`，敌方为 `yinRou`；规则层 `内伤` 只在 `yinRou` 打 `lingQiao` 时施加，因此本路由数据不满足触发条件，无法进一步 hover 释义。`踉跄`/`剑鸣` 本场景也未触发。 | `19_F_after_enemy_attacks.png`、`20_F_after_more_enemy_attacks.png` |
| 单步按钮 | 通过 | 起手暂停态可见 `skip_next` 单步按钮；点击后回合数字从 0 变 1，后续可逐步推进回合。 | `18_single_step_button_round1.png` |
| G/H 复确认 | 通过 | 内力条显示 `内 X/Y`；当前 1470x845 窗口下布局无按钮文字溢出、头像/血条/技能按钮未互相遮挡。 | `00_initial_fullscreen.png`、`17_E_mana_insufficient.png` |

## 总结

本轮复验结果：

- 通过：D、E、单步按钮、G/H 复确认。
- C 部分通过：single 拖招目标高亮与命中成立；aoe 拖招未按群体触发，不通过。
- F 无法确认：验收路由数据与 `内伤` 触发规则不匹配，未能产生可 hover 的 debuff 标签。

## 给 Claude 的待修项

1. 修 `万钧裂空` 拖放后的目标解析/执行路径：`TargetType.aoe` 当前视觉实测只命中一个敌人，应命中全部存活敌人。
2. 修 F 的验收路由数据或新增专用验收态：让 `内伤` 可稳定出现。建议将至少一名我方受击目标改为 `TechniqueSchool.lingQiao`，或在验收路由预置一个带 `internalInjury` 的角色，便于验证头像标签与 hover 释义。
3. 可选：明确暂停态下“松手即命中”的验收语义。当前 single 松手后先显示 `待发`，需要继续推进后才出现伤害；如果这是预期，派单口径建议写成“松手下发，推进后命中”。

## 附件

截图目录：`docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/`
