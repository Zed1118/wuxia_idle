# P2 M5 断魂庄快速推演生产接线结果合同

## 唯一目标

- task：`P2-M5-GAUNTLET-HEADLESS-PRODUCTION-WIRING`。
- 基线：`fe2a287f29285ab9988b0c3387765fc6f04a5b3f`。
- 纠正 M5 审计假阳性：断魂庄已有自动策略、准入和 headless driver，但原生产整备页只进入 live flow，没有任何 `lib/` 消费者调用 driver。将已首通后的快速推演接入玩家可达生产入口，使断魂庄“自动解锁”一格从严格基线 `BLOCKED` 恢复为可证的 `PASS`。

## 生产合同

1. 首次完整通关仍只能亲战；只有真实 `clearedGauntletIds` 包含 exact gauntlet 时才能自动准入。
2. 已通关整备页显示“快速推演”，提交玩家实际选定的单名参与者和固定 `direct + playerBot + headless + replay` tuple。
3. 自动策略校验、扣帖与建会话共用 [GauntletService.enter] 的同一事务边界；界面状态陈旧时不得先扣资源再拒绝。
4. 进入成功后只调用既有 `driveHeadlessReplayToRewardChoice`；败局仍由既有伤势/失败 owner 结算，胜局硬停在现有三选一页，不代替玩家选奖。
5. 现有 direct headless replay 不得冒充 durable dispatch；断魂庄差遣一格继续 `BLOCKED`。

## 验证与停止线

- 生产页首通前不显示快速推演，首通后未选人仍 fail closed。
- 生产页的入场准入与 driver 必须复用同一 exact request，且实际参与者与 loadout plan 一一绑定。
- 破坏证红至少两向：强制首通前显示时可见性用例必须红；移除或退化 exact production request/driver 消费时路由用例必须红。
- targeted、analyze、整仓 format、锁保护全量、项目 Gate、合并 push 与精确 SHA CI 全部通过后才关闭本切片。
- 本切片只修复被过早计入的断魂庄自动化格，不新增权重；有效 M5 矩阵维持 `37/42`，顶层 M5 仍 `0/1 BLOCKED`。

## 禁止范围

- 不改 schema/saveVersion、玩家数值、技能、奖励金额或概率、经济、解锁阈值、YAML TUNING 或战斗规则。
- 不新建 runner、reducer、settlement 或 durable owner；不启动 M3/M7。
- 真人桌面交互、视觉与 Windows 实机继续挂账，不冒充正式 M5/Phase 2 验收。
