# Codex Phase5 主线一战斗 UI 信息表达视觉验收 · 2026-06-17

## 环境

- 仓库: `/Users/a10506/Desktop/Projects/挂机武侠`
- 分支: `feat/phase5-battle-experience`
- HEAD: `661977d8`(包含派单要求的 `0c879f09`,属于更新提交)
- 备注: 入场时本地分支 `git pull --ff-only` 提示无 upstream; 后续 `git fetch origin` 后当前分支位于 `origin/feat/phase5-battle-experience` 同名 HEAD。未切回 main,未改 `lib/`,未 commit。
- 启动: 先按派单跑 `VISUAL_ROUTE=battle_scene`,但该路由进入时很快落到胜利结算;随后改用已有交互入口 `VISUAL_ROUTE=battle_drag_live` 复验,该入口也在数秒内自动结算,导致部分交互只能给出证据不足结论。
- 截图目录: `docs/handoff/codex_phase5_mainline1_visual_2026-06-17/`

## 逐项结论

| 项 | 结论 | 截图 | 现象 |
|---|---|---|---|
| A. 点击技能方块弹简介浮层 | 通过,但有遮挡 | `10_skill_click_calibrated.png` | 校准 Retina 坐标后,单击 `裂石指` 弹出宣纸水墨技能简介浮层,可见技能名、类型、目标、倍率、耗内等字段;但战斗同时进入胜利结算,胜利弹窗遮挡了下半部,未能完整看清冷却/特性/「知道了」。 |
| B. 点击不下发 | 通过 | `10_skill_click_calibrated.png` | 单击后出现简介浮层,画面未见「待发」印或手动下发轨迹;后台自动战斗仍继续推进并结算,但不是单击技能直接出手。 |
| C. 长按拖招下发 | 不通过/无法确认 | `11_drag_during_attempt.png`, `12_drag_release_result.png` | 使用 CGEvent 长按技能并拖到敌人头像区域,未捕捉到拖拽引导线、敌头像高亮或拖拽命中因果;路由在操作窗口内已进入胜利结算层。 |
| D. aoe 必须拖 | 不通过/无法确认 | `05_aoe_click_attempt.png`, `10_skill_click_calibrated.png` | `battle_drag_live` 顶部提示仍写「点大招群体直发」,与本次“aoe 也必须长按拖”目标相冲突;本轮未取得群体技单击只弹简介的清晰截图。 |
| E. 按钮文案三态 | 不通过/部分可见 | `03_drag_live_default.png`, `00_default_window.png` | 可用技能可见 `耗内250 · CD3/CD5`;冷却态可见 `冷却3`;未在本局观察到 `内力不足` 文案。 |
| F. buff/debuff 标签 | 未触发完整验收 | `00_default_window.png` | `battle_scene` 中可见敌方头像下方 `内伤` 标签贴附;本局未稳定触发/截到 `踉跄`、`剑鸣`,也未能在结算前完成 hover 释义截图。 |
| G. 内力条标签 | 通过 | `03_drag_live_default.png`, `10_skill_click_calibrated.png` | 角色头像下内力条显示 `内 1500/1500`、敌方显示 `内 300/300`,真机观感清楚。 |
| H. 整体默认/小窗口 | 通过,但小窗受结算遮挡 | `03_drag_live_default.png`, `13_small_window.png` | 默认窗口下底栏技能区、头像、内力条不溢出,水墨基调克制;小窗口约 620x520 时控件仍在布局内,但胜利弹窗遮挡底栏,无法作为完整交互态小窗通过证据。 |

## 总结

主线一「单击弹简介、不再裸单击下发」方向在真机上有可见证据,但本次验收入口自动战斗过快且 `battle_drag_live` 顶部提示仍保留“点大招群体直发”,导致长按拖招、aoe 必须拖、内力不足、hover 释义无法完整验收。建议 Claude 修/补一个冻结或手动步进的交互验收路由,并同步移除群体技点触直发逻辑/提示后再复验。
