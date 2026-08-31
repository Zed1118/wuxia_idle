# M4 24-active 性能收口计划

## 结果合同

- 单一目标：在 M2 + M4 A-G 受控集成候选上关闭 24-active macOS 帧门，不启动 M3，不把真人目检挂账改写为 PASS。
- 分支：`codex/p2-m4-24-active-performance-closeout-20260831`。
- 候选基线：`ce00d13ae850d84ab439d15a3c22e31d1fc632b3`（M4-D 前），组合评估范围覆盖 M4-D～G；M4-A～C 沿用各自已冻结候选，M4-H 不进入本候选。
- 证据基线：昨晚 1280×720 / 1440×900 各 3 轮均 FAIL，p99 total span 平均 `46.5945ms`；本次原始帧时间戳证明其中存在应用失焦后的约 10Hz macOS 节流，不能当成生产渲染结论。
- 分母：24-active 性能 Gate `0/1`；只有统一候选在两个视口各 3 轮全部通过复合帧门、回归与独立 Gate 后才记 `1/1`。
- 最高杠杆阻塞：必须让物理 Profile 窗口全程处于前台；后台样本虽帧内 build/raster 不超标，但 60 秒采样帧数会降到约 2565，现有 `sampled_frames >= 3000` 复合门会正确判红。
- 成本边界：无可靠 token/用量读数，按真实墙钟；约 90 分钟没有可测 Gate 改善时停止扩张并重评。

## 验收标准

1. 候选从 M4-G 建立，不包含 M4-H；移除与本 Gate 无关的 Isar 测试超时放宽，不改其业务断言。
2. 真实 `Phase0aBattleScreen`、controller、bot、生产 flow assembler 与 reducer 下保持玩家 + 24 active 敌人；不改实体、攻击令牌、难度、数值、存档或 checkpoint 语义。
3. 1280×720 与 1440×900 各 3 轮：每轮 sampled frames ≥3000、p99 total span <16.6ms、max consecutive severe frames ≤1、frame streak Gate PASS、GC 遥测完整、RSS 守门通过。
4. 24-active 生产接线与立绘解码预算必须在最终 commit 后各做一向破坏证红；性能是否过线只认前台物理 Profile，不以静态 widget 数量代替 Profile 结果。
5. targeted、相邻回归、`flutter analyze --no-pub lib test`、全仓 format、持锁全量、组合 receipt、独立 Gate 全部通过；worktree clean，tip 以 `[READY]` 或如实 `[BLOCKED]` 收口。
6. 主 checkout 保持 clean；不 merge、不 push、不修改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、schema/saveVersion。

## 任务切片

1. 建立受控候选并复核现有 Profile 原始证据。
2. 用帧时间戳区分真实 build/raster 热点与应用失焦节流；前提不成立时不改生产渲染。
3. 逐文件跑 24-active fixture、生产 route、帧采样器、解码预算、手感与战斗屏回归，冻结最终候选。
4. 最终 tip 上以未绑定的 `F15` 只做窗口激活，完成双视口 3×2 物理 Profile；任何 sampled frames 不足的轮次整轮作废并保留原始证据。
5. 过线后写组合 receipt，持锁跑全量与独立 Gate。

## 当前恢复点

- 状态：WIP，24-active 性能 Gate `0/1`；代码候选已可冻结，正式最终 tip 矩阵尚未开始。
- 最后完成：从 M4-G 建立独立 worktree，剥离 `game_event_feed_providers_test.dart` 的无关 2 分钟超时，确认该文件恢复默认超时后单跑 `3/3`；M4-H 未进入候选。
- 根因结论：相同生产代码在前台 Profile 下，1280×720 连续三轮 p99 total 为 `9.549/9.658/9.886ms`，1440×900 诊断轮为 `9.992ms`，严重连续帧均为 0。自动轮次的失败样本只有 `2565` 帧，原始间隔在约 12～55 秒持续出现 `115～121ms` 空洞，符合 macOS 后台节流而非战斗帧内耗时；因此不做无依据的生产优化。
- 已跑验证：24-active fixture `10/10`、生产 route `9/9`、帧采样器 `5/5`、解码预算 `1/1`、手感回归 `6/6`、战斗屏 `36/36`；`flutter analyze --no-pub lib test` 为 `No issues found!`；整仓 format `1656 files (0 changed)`。
- 现有证据：有效诊断位于 `build/g2_playtest/20260831/m4_performance_closeout/formal_matrix_frontmost_78101482/` 与 `diagnostic_frontmost_78101482/`；后台节流红样本保留在 `formal_matrix_78101482/`，不计入最终矩阵。
- 破坏证红：移除生产战斗立绘 `WuxiaImage` 受限解码接线后，解码预算测试 `1` 项失败；把 24-active 数量强制退化为 `1` 后，精确数量测试 `1` 项失败。后者同时揭示 widget 挂载用例原先只遍历现有敌人，数量退化时会假绿，已补独立 `hasLength(24)` 守卫，须在新 tip 上重做该向证红。
- 下一步：重新提交最终 `[READY]` tip；复验增强后的退化向破坏证红并精确还原；在该 tip 上重跑正式 3×2、全量、组合 receipt 与独立 Gate。
- 阻塞项：当前无工程阻塞；G2 真人可读性、手感、音频与 Windows 物理性能继续挂账，不在本单自签。
