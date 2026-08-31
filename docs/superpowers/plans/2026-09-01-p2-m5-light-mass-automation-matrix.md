# P2 M5 轻功/守城自动化矩阵收口计划

## 结果合同

- task：`P2-M5-LIGHT-MASS-AUTOMATION-MATRIX`。
- base：`44a5d241d3c96d58e9ef67254bfc5af2292b8cb1`。
- 唯一目标：把 M5 固定 `6 × 7 = 42` 分母中轻功、守城的自动化矩阵两格从 BLOCKED 关闭为 PASS，使工程证据从 `34/42` 推进到 `36/42`。
- 两格均须同时拥有已首通门槛、typed request、exact participant、真实生产入口、既有前台 bot/Phase 0A headless runner、共享胜败 settlement 与事实报告；孤立 policy、图标或 fixture 不计入。

## 生产合同

1. 首通仍必须人控；只有已通关轻功路线/守城关才能进入自动化。
2. 已通关可见重打消费全局 `autoPlayDefault`：关闭时继续人控，开启时以同一 exact participant 进入既有 `Phase0aMainlineBattleHost` 的 `playerBot + realtime + replay`。
3. 已通关新增明确快速推演入口，提交 `direct + playerBot + headless + replay`，复用现有 durable receipt、mapper、headless runner 和共享胜败 settlement；超时保持可恢复。
4. 原差遣继续是独立 `dispatch + playerBot + headless + offlineResume` 通道；快速推演不得伪装成差遣。
5. 守城 headless 必须持久化玩家本次选择的阵型；轻功拒绝阵型。

## 破坏证红

- 移除 direct replay allowlist 后，前台 bot/快速推演生产合同测试必须失败。
- 忽略 direct participant controller、把可见重打强制回 human 后，真实 Host controller 测试必须失败。
- 去掉首通门槛或把快速推演请求退回 dispatch/offlineResume 后，入口/服务测试必须失败。

## 验证与停止线

1. targeted：activity policy/service/coordinator、stage flow、轻功、守城、共享 runner/settlement。
2. `flutter analyze --no-pub lib test tool`。
3. `dart format .` 后确认 0 文件变化。
4. 持有 `/Users/a10506/.claude/locks/wuxia_full_test.lock` 运行一次全量。
5. Gate、合并 push、精确 SHA CI 全绿后，才把两格记为工程 PASS。
6. 若需要 schema/saveVersion、YAML/TUNING、奖励数值、解锁阈值或新 reducer/headless/settlement owner，停止并保留 BLOCKED。

## 非目标

- 不关闭 M5 顶层 `0/1`，不启动 M3/M7。
- 不改玩家数值、技能、奖励金额/概率、经济、战斗规则或现有差遣语义。
- 真人桌面手感/视觉与 Windows 实机继续挂账，不冒充正式 M5/Phase 2 验收。
