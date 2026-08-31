# Phase 2 U13 主线跨章实现与验收证据

日期：2026-08-31 至 2026-09-01
冻结语义：章内连续；章末返回当前章卷尾；非终章从卷轴进入下一章时新建 run；`stage_21_05` 终章无下一章。

## 结论

U13 非视觉生产门已从 `0/1` 推进到候选 `1/1`。本单只补齐主线跨章编排与持久恢复，不改奖励、经济、解锁、玩家数值、技能或战斗规则；真人观感继续挂账，不用自动测试冒充试玩。

| 检查项 | 候选结论 | 生产证据 |
|---|---|---|
| 章内连续 | PASS | `MainlineRunCoordinator` 与 `_nextStageInSameChapter` 保持原同章连续 run；整个 `test/features/mainline` 回归 `453/453`。 |
| 普通章末卷尾 | PASS | `runStageFlow` 消费 `chapterCompleted`，持久记录 `showChapterScroll` 后打开 managed `ChapterTransitionScreen`。 |
| 下一章新 run | PASS | 卷轴 typed action 调用 `beginNextChapter`；旧游标关闭与下一章 `prepared` journal 在同一 Isar 事务，run id 不同且 loadout version 从 1 开始。 |
| 终章无下一章 | PASS | production repository 解析 `stage_21_05` 为 final boundary；卷轴只返回章节，不创建 active next run。 |
| 崩溃恢复 | PASS | `coreApplied + none` 的章末崩溃点会补记卷轴游标；`showChapterScroll` 可重显；事务中断回滚为旧游标 active 且零部分新 run。 |
| 真人卷轴观感 | DEFERRED | 按用户指示挂账；不计入本单 `1/1` 非视觉生产门。 |

## 实测证据

- 初始真红：4 个测试文件因 boundary resolver、卷轴游标、跨章事务 API 与 typed UI action 均不存在而加载失败。
- 定向合同：章末解析、journal domain/service、卷轴 UI 共 `26/26`；含 coordinator/recovery 的扩展定向组 `40/40`。
- 生产接线：真实 `runStageFlow` 从章末空动作崩溃点恢复卷轴，进入 `stage_02_01` 独立 version-1 run；终章关闭后 active journal 为零。
- 主线域回归：`453/453`。
- 双向破坏证红：删除“创建新 run”半边，服务合同与生产接线各红 1 项，共 2 项；删除“关闭旧游标”半边，同样共红 2 项并报 multiple active journals；均用精确反向补丁还原。
- 静态验证：`flutter analyze --no-pub lib test` 为 `No issues found! (ran in 14.4s)`；整仓 format 为 `Formatted 1685 files (0 changed) in 2.98 seconds.`。
- 首次持锁全量：`06:01 +5801: All tests passed!`，`[E]=0`，退出码 0。
- 相对基线没有 `lib/shared/strings.dart` 最终差异，没有测试删除，因此无需测试契约迁移登记。

本证据只支持 U13 候选与最终 Gate/集成判定，不宣称 M6 或整个 Phase 2 完成，不启动 M3/M7。
