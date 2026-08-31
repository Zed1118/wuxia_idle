# Phase 2 U13 主线跨章语义差距审计

日期：2026-08-31  
冻结语义：章内连续；章末返回章节卷轴；下一章新建 run；终章无下一章。

## 当前事实

| 检查项 | 当前结论 | 生产证据 |
|---|---|---|
| 章内连续 | 已存在 | `MainlineRunCoordinator` 只在完整结算后装配同一参与者的下一关快照；生产 resolver `_nextStageInSameChapter` 限制同章后继。 |
| 章末返回章节卷轴 | 缺口 | coordinator 在同章无后继时只返回 `chapterCompleted`；`runStageEntryFlow` 未消费该结果做导航。`ChapterTransitionScreen` 目前只能从章节卡“卷”入口进入。 |
| 下一章新建 run | 数据入口可形成，但无跨章流程守卫 | 各章首关 `prevStageId == null`，从 StageList 重新进入会 bootstrap 新 run；当前没有“章末卷轴 → 下一章首关”的生产编排，也没有断言新 run id 的跨章用例。 |
| 终章无下一章 | 数据上成立，但无专门终章分支 | `stage_21_05` 无 successor；现有同章 resolver 同样返回 null。当前代码不能区分普通章末与终章，因此也没有只对非终章展示下一章入口的契约。 |
| 崩溃恢复 | 仅覆盖关内/章内继续 | durable journal 支持已结算后继续下一关，但没有“章末已结算、卷轴未展示”和“卷轴已展示、下一章 run 未创建”的恢复游标。 |

## 建议下一门

把 U13 定为独立 `0/1 → 1/1` 非视觉生产门，不复用上一章 run：

1. 为 chapter completion 返回 typed disposition，明确 `nextChapterIndex?`，终章为 null；
2. `runStageEntryFlow` 在普通章末结算完成后导航到当前章卷尾，并只为非终章提供进入下一章入口；
3. 下一章入口调用现有 bootstrap 新建 run，断言 run id、loadout version 与上一章不同；
4. 在现有 settlement journal/outbox 上记录章末过场恢复事实，避免崩溃后跳过或重复创建 run；
5. 破坏证红覆盖跨章沿用旧 run、普通章末不进卷轴、终章错误出现下一章入口三类退化。

该审计未修改 U13 生产行为，也未启动 M3/M7；视觉与真人流程验收继续挂账。
