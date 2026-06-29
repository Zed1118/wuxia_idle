# 胜利结算卷轴化

## 目标

在 `codex/visual-victory-scroll` 分支内，把战斗胜利结果改成统一的卷轴结算层。复用现有 `DropResult`、升层、战斗统计、伤势与疗伤入口数据，只改 UI 呈现，不改奖励、掉落概率、经验、熟练度、装备处理、疗伤、save/schema/numbers。

## 验收标准

- 生产接线证据：主线胜利仍从 `showStageVictoryDialog` 进入，消费方仍传入现有结算数据；按钮关闭行为不变。
- 分区清晰：经验/修为、掉落、装备、秘籍/残页、伤势/疗伤以卷轴报告区块呈现。
- 长内容可滚动：长掉落列表在常规桌面视口内不溢出。
- 红线：不碰 reward service、drop hook、概率、经验、装备处理、疗伤逻辑、save/schema/numbers；中文新增文案只进 `UiStrings`。
- 不做 rejected registry 中的来源聚合、掉落缺口标记、Boss 战利品展示升级。
- 验证：运行 build_runner、相关 victory/stage tests、`flutter analyze`、`git diff --check`。

## 任务切片

1. 读取 `AGENTS.md`、`CLAUDE.md`、`docs/spec/rejected_task_registry.md` 并确认边界。
2. 调整 `StageVictoryContent` 为卷轴报告层，保持现有数据和按钮路径。
3. 在 `UiStrings` 增加少量区块标题。
4. 补必要 widget 断言，覆盖分区与滚动。
5. 运行验证并提交。

## 当前恢复点

- 状态：已完成，待合并评审。
- 最后完成：`showStageVictoryDialog` 改为宣纸卷轴弹层，`StageVictoryContent` 改为可滚动分区报告；补充 UiStrings 与 widget 断言。
- 下一步：由主窗口按 `CLAUDE.md` §8.2/§8.3 评审并合并。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs`：通过，生成缺失 Isar/Riverpod 文件；该参数当前版本提示已移除并忽略。
  - `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart`：32/32 通过。
  - `flutter test test/features/battle/presentation/victory_overlay_test.dart test/features/battle/victory_overlay_diagnosis_test.dart test/features/battle/presentation/victory_seal_flash_test.dart test/features/battle/presentation/present_victory_ceremony_test.dart test/features/equipment/presentation/treasure_drop_overlay_test.dart`：13/13 通过。
  - `flutter analyze`：No issues found。
  - `git diff --check`：通过。
- 阻塞项：无。
