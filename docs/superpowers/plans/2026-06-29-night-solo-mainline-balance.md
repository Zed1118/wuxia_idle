# 2026-06-29 · night-solo-mainline-balance

## 目标

完成 backlog「单人主线 01_05→06_05 平衡调参」：覆盖生产新档祖师单人走 Ch1-6 的真实体验，修正 01_05 之后仍可能单人 1v3 的卡点、过软点与奖励断点。

## 分支

- `codex/night-solo-mainline-balance`
- worktree: `/Users/a10506/.codex/worktrees/1994/挂机武侠`

## 验收标准

- 按 `CLAUDE.md` §8.0 执行：计划文件、恢复点、小切片 commit、targeted verification。
- 不静默 buff 玩家；优先调整 `data/stages.yaml` 的敌阵、Boss、掉落、经验等真实玩法配置，必要时补非弹窗 UI 提示。
- 不破数值红线：装备基础攻击 ≤2000，玩家血 ≤20000，内力 ≤15000，Boss 血不进 1M，招式倍率 ≤8000。
- 不破三系锁死：境界、装备阶、心法阶一一对应。
- 生产新档单人路径有定向测试/模拟覆盖，至少能解释 Ch1-6 哪些关卡是可过、卡点、过软点。
- 完成后提交，汇报分支、提交、验证、剩余风险。

## 任务切片

1. 读取 `AGENTS.md`、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/spec/playability_phase2_backlog.md`、`docs/audit/onboarding_30min_review_2026-06-28.md`。
2. 诊断现有 Ch1-6 单人主线测试/模拟覆盖，确认生产单人构建和奖励流。
3. 扩展或新增单人主线模拟，覆盖 `stage_01_05` 至 `stage_06_05` 的连续奖励、装备、强化、胜率和终态。
4. 按诊断结果小幅调整关卡敌阵、Boss、掉落或经验节奏，避免 buff 玩家本体。
5. 跑定向测试与 schema/红线相关检查。
6. 更新恢复点、提交切片；必要时补第二切片收口。

## 当前恢复点

- 状态：收口验证中。
- 最后完成：
  - 已读必读文档；已在 detached worktree 上创建 `codex/night-solo-mainline-balance` 分支。
  - 新增 `solo_mainline_ch1_ch6_balance_test.dart`，覆盖生产新档祖师单人、按关卡要求境界整备、掉落/经验/强化滚动推进的 Ch1-6 主线。
  - 已将 `stage_01_05` 至 `stage_06_05` 的单人主线路径从多人敌阵调为单敌/单 Boss 推进，并补齐 01→02、04→05、05→06、06→06_05 的关键装备掉落桥。
  - 已将跨阶 Boss 的关卡要求对齐敌方境界：`stage_05_05` 要求 `zongShi`，`stage_06_05` 要求 `wuSheng`。
- 下一步：做最终 targeted verification，审查 diff，提交本切片。
- 已跑验证：
  - `flutter test --no-pub test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart`
  - `flutter test --no-pub test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/data/drop_table_reference_redline_test.dart test/data/stages_boss_enemy_test.dart test/data/stage_skill_drop_redline_test.dart`
  - `flutter analyze --no-pub`
- 阻塞项：无。
