# M4 typed 生存目标生产消费计划

## 结果合同

- 单一目标：让 catalog 中已有的 `survive_duration` 从 typed 定义真实进入动态 encounter 每帧事件、胜负判定和现有生存 HUD/结算文案，形成固定 `1/1` 子 Gate。
- 基线：`038a4a9c90731b2c64e09633c5045b0b5572e6ea`，承接六生态包各至少一场生产关的 clean 候选。
- 不扩张项：不迁移具体主线关、不自行冻结生存时长、不改 `numbers.yaml`、schema/saveVersion、奖励、敌人数或技能数值；不启动 M3，不 merge/push。
- 人工边界：HUD 位置、可读性和真实战斗观感挂账；widget 结构测试不冒充真人目检。

## 固定验收门

1. 只有显式声明 `CombatSurviveDurationRef` 的 migrated encounter 才按每帧真实 `deltaSeconds` 产生 `TimeElapsed`，event id 逐 tick 稳定去重。
2. 玩家存活且时间到时即胜，敌人仍存活不阻塞；同拍玩家死亡仍由既有 flow 规则优先判负。
3. `Phase0aBattleController` 只从独立、只读的生存目标表现快照读取 required/elapsed；既有 runtime observation 窄接口与 legacy flow 行为不变。
4. 现有 `_SurviveConditionBanner` 显示 typed 剩余拍数，typed 生存胜利显示“守住了”，不新增或硬编码中文。
5. 破坏证红：移除时间投影时领域/生产用例必须红；断开 typed HUD 消费时 widget 用例必须红。
6. targeted、邻接、analyze、整仓 format、macOS Debug build、持锁全量与独立 Gate 全绿，最终 worktree clean。

## 后置挂账

- `stage_02_02` 的具体 `required_ticks`、压力曲线和残局退场需要产品调优后再迁移。
- 真人确认 HUD 是否遮挡、倒计时是否易读、存活胜利的收尾感是否自然。
- 守阵和追击仍是后续独立 M4 子门；本批不伪称七模板完成。

## 实施证据

- 真红：生产事件测试在未接线时得到空事件；移除 `TimeElapsed` 投影后同一用例 `1/1` 红。
- 真红：typed HUD 消费退化为 `null` 后 widget 用例 `1/1` 红；两处均已精确还原并复绿。
- 邻接回归：动态 encounter 终局/死亡优先、runtime observation 窄接口、legacy 生存 HUD、第一章目标和八类 primitive mapper 共 `63/63` 通过。
- 静态与构建：`flutter analyze --no-pub lib test` 为 `No issues found`；整仓 format 零改动；macOS Debug 构建成功。
- 持锁全量：`04:39 +5737: All tests passed!`，`[E]` 错误块为 `0`。
- 真人挂账：HUD 可读性、遮挡、真实压力下倒计时与终局收尾感均未判 PASS。
