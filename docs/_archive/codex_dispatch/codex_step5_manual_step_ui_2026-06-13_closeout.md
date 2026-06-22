# 挂机武侠「半手动战斗 P0 步骤5 manualStep 单步 UI」视觉验收 closeout

验收日期: 2026-06-13  
验收员: Codex  
验收轮次: R2 直达包重验  
验收包: `/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app`  
窗口: 1280 x 720, 位置 `{80,80}`  
路由: 开屏直达 `battle_manual_step`, 未进入 hub, 未点击列表  
场景: `scenarioChargeBreak`, seed=3

## 截图回收

截图目录: `docs/codex_step5_manual_step_ui_2026-06-13_screenshots/`

- `r2_01_initial.png`: R2 开屏初始态, 右下「下一步」
- `r2_02_after_next_1.png`: 点击下一步 1 次
- `r2_03_after_next_2.png`: 点击下一步 2 次
- `r2_04_after_next_4.png`: 点击下一步 4 次
- `r2_05_picker_attempt_strong.png`: 点击主控单体技后 picker 弹窗
- `r2_06_after_pick_target.png`: picker 内选择青衫剑客后, 技能待发
- `r2_07_after_pick_next_fast.png`: 待发后点击下一步
- `r2_08_after_pick_next_settled.png`: 待发后点击下一步 settled
- `r2_09_after_more_next_fast.png`: 行动顺序条出现, 技能打到青衫剑客
- `r2_10_after_more_next_settled.png`: 同步 settled 截图
- `r2_11_step_actor_fast.png`: 单点一步后队列缩短
- `r2_12_step_actor_settled.png`: 单点一步 settled
- `r2_13_queue_last_actor.png`: 最后一名 actor 结算后队列清空
- `r2_14_queue_empty_settled.png`: 队列清空 settled
- `r2_15_new_boundary.png`: 队列空后再点进入新回合边界

## 先决路由确认

**PASS**。R2 开屏即为战斗屏，底部指令台最右侧是实心绛金「下一步」，不是描边「快进」。本轮未进入 hub，也未点击任何列表入口。

## 逐项结论

1. 初始态: **PASS**
   - 右下按钮为实心绛金「下一步」，点击区视觉尺寸约 96 x 52 以上。
   - 开屏无人出手，画面冻结在 seed 态。
   - 顶部敌蓄力危险条存在，符合已知非 bug。

2. 行动顺序条: **PASS，带时序观察**
   - 行动顺序条最终出现，文案为「本回合行动顺序: ...」，角色名可读。
   - 队首角色有绛金描边高亮，后续角色为较暗描边。
   - 危险条与行动顺序条同屏时上下分区清楚，没有重叠或互相遮挡。
   - 观察: 从冷启动直接点 1-2 次时未出现顺序条，只看到回合数递增；本轮实际在后续推进到回合 6 后出现。视觉形态通过，但时序可再由实现侧确认是否符合预期。

3. 强制停顿逐步: **PASS**
   - 有队列状态下，单点「下一步」只结算一个 actor。
   - `r2_09_after_more_next_fast.png` 中队列为「弟子乙 > 青衫剑客」。
   - 再单点后，`r2_11_step_actor_fast.png` 队列缩短为「青衫剑客」，同时只出现一次伤害飘字。
   - 再单点后，`r2_13_queue_last_actor.png` 队列清空；队列空后再点，`r2_15_new_boundary.png` 进入新回合边界并生成下一轮队列。

4. 目标 picker（立即弹）: **PASS**
   - 选中主控后点击单体技「强力 崩山式」，立即弹出居中的「选择目标」弹窗。
   - 弹窗列出存活敌人: 青衫剑客、巷口杀手、巷尾杀手。
   - 每个敌人项带血量，未见死亡敌人。
   - 弹窗水墨暗面板与战场背景对比足够，1280 x 720 下居中且不溢出。

5. 选目标下发: **PASS**
   - picker 内点击青衫剑客后弹窗关闭。
   - 「强力 崩山式」技能卡盖「待发」印。
   - 后续推进到该 actor 行动时，伤害落在青衫剑客身上；青衫剑客血量从 9500 降至 6078，随后继续降至 4924，飘字位置也在该敌人区域。

## 视觉质量关注点

- 「下一步」与「快进」区别: **PASS**。R2 显示实心绛金「下一步」，与上一轮误路由的描边「快进」区别明显。
- 点击区: **PASS**。右下按钮尺寸充足，文案清楚。
- 行动顺序条 vs 危险条: **PASS**。危险条在上，顺序条在其下方独立横条，不重叠。
- picker 弹窗: **PASS**。居中、不溢出、暗色 panel 对比足够，标题和敌人血量可读。

## 鼠标合成复核

- 点击「下一步」能推动回合数、生成顺序队列并触发 actor 结算。
- 点击主控技能能立即弹出 picker。
- 点击 picker 敌人项能关闭弹窗并设置技能待发。
- 本轮未发现鼠标合成导致的误判。

## 真玩拍板

不计入视觉 FAIL 的手感结论: 单步节奏在出现行动顺序条后是顺的，队首高亮、每步一个 actor、队列缩短都比较清楚。picker 的打断感成立，技能点下去会立即让玩家选择目标；选择后「待发」印清楚。唯一需要实现侧确认的是冷启动前几次「下一步」只有回合数递增、没有顺序条的时序是否为设计预期。

## 总结

R2 直达包 `battle_manual_step` 视觉验收 **通过**。上一轮 FAIL 确认为误点相邻路由导致；本轮直达包下「下一步」、行动顺序条、逐 actor 单步、picker、目标下发均已覆盖并通过。
