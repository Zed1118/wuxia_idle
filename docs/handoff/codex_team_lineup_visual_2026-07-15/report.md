# 出战编成屏 `team_lineup` 目检报告

- 验收日期：2026-07-15
- 仓库基线：`main@383e145c`
- 路由：`flutter run -d macos --dart-define=VISUAL_ROUTE=team_lineup`
- 就绪信号：`VISUAL_ROUTE_READY: team_lineup`
- 视口：1280×720，1440×900（由 `VISUAL_WINDOW_W/H` 锁定逻辑窗口）

## 总结论

**A–H 全部通过。** 未见 overflow、截断、遮挡或编成屏业务 exception。有1 处非阻断文案瑕疵，见报告末尾。

| 项 | 结论 | 截图 | 现象 |
|---|---|---|---|
| A. 出战三席 | PASS | [1280 基线](01_baseline_1280x720.png) / [1440 基线](10_baseline_1440x900.png) | 祖师第一席显示「前排」；二流/三流/学徒梯度、刚猛/灵巧/阴柔三流派、「破绽集火」/「控场·压制蓄力」均完整显示，无 overflow。 |
| B. 替补三态 | PASS | [1280 基线](01_baseline_1280x720.png) | 记名弟子无拦截标；降将显示「境界偏低」+「未修主修」；闭关行者显示「境界偏低」+「未修主修」+「闭关中」。 |
| C. 点选交换 | PASS | [满席换防 Dialog](02_swap_dialog_1280x720.png) / [换上后刷新](03_swapped_and_confirmed_1280x720.png) / [入空席 Dialog](09_insert_into_empty_dialog_1280x720.png) | 点记名弟子立即弹 PaperDialog；可选三席换下，有空席时显示「第三席 · 入空席」；确认后列表刷新并出现「编成已定」。 |
| D. 出战卡调度 | PASS | [弟子调度](04_disciple_dispatch_1280x720.png) / [祖师调度](05_founder_dispatch_1280x720.png) | 弟子卡有「下场歇息」及与他席互换；祖师卡只有互换，无「下场歇息」操作。 |
| E. 拦截提示 | PASS | [未修主修 Snackbar](06_block_no_main_snackbar_1280x720.png) / [闭关中 Snackbar](07_block_retreat_snackbar_1280x720.png) | 降将提示「未修主修心法，研习立为主修后方可上场」；闭关行者提示「闭关中门人不可调整」；两者均不弹换防 Dialog。 |
| F. 空席态 | PASS | [空席](08_empty_seat_1280x720.png) | 弟子下场后出战席顺序收拢，末席显示「空席 / 点替补门人入席」。 |
| G. 双视口 smoke | PASS | [1280×720](01_baseline_1280x720.png) / [1440×900](10_baseline_1440x900.png) | 两视口均完整呈现三席+替补池，无 overflow/exception/遮挡。 |
| H. 深底配色 | PASS | [替补标签](01_baseline_1280x720.png) / [替补悬停](13_hover_bench_card_1280x720.png) | 墨黑底上低境界红、未修主修灰、闭关蓝均可辨；边框、正文与状态色层级稳定，未见浅底色板混用造成的糊字。 |

## 真机手感

- 悬停：出战卡和替补卡都出现局部墨晕/柔光跟随，不引起内容位移；克制且能确认点击区。证据：[出战卡悬停](12_hover_active_card_1280x720.png)、[替补卡悬停](13_hover_bench_card_1280x720.png)。
- 点按：卡面整体为点击区，反馈无明显延迟；可用项进入 PaperDialog，被拦截项原位给 Snackbar，交互结果区分清晰。
- Dialog：宣纸浅底与深色棋盘对比充足，选项按钮高度、间距与可点性均稳定。

## 非阻断观察

1. **祖师调度说明行与实际操作不一致**：已正确隐藏「下场歇息」按钮，但 Dialog 说明仍写「下场歇息或与他席互换」。建议祖师分支改为「与他席互换」。
2. **换下原在场大弟子后不能立即换回**：其进入替补池后显示「未修主修」，点击后按「加入者须已修主修」硬前置拦截。这与现行校验一致；若 seed 的预期是让原阵容可无条件复原，需另行确认 seed/旧角色口径。
3. 首次 1440×900 启动捕获过一次 macOS 输入状态遗留引起的 Flutter `KeyDownEvent` 断言（物理 E 键被记为已按下）。清除输入状态后热重启，READY 后持续观察无再现；判定为验收环境瞬态，未归因于编成屏。
