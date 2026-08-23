# Phase 2 G2 Batch6 接入前合同审计

## 结论

Batch6 已完成 production host 切换前的三个纯合同：typed encounter mapping、全量动态 visual roster、显式 encounter migration resolver。主线、塔、远征与群英宿主仍走 legacy `assemble`；本批不宣称已经切换动态 encounter 生产路由。

## 交付内容

- D09：Pi + DeepSeek `deepseek-v4-flash` 新增不可变 `Phase0aEncounterMapping` 及 `assembleEncounterFromMapping` typed bridge；`NumbersConfig`、caller RNG 和可选 observer 继续显式传入并完全委托 Batch5 `assembleEncounter`。
- D10：Qoder + `Qwen3.8-Max` 产出 `fromCombatants` 候选；因验证阶段越界启动全仓 `build_runner`，主控立即取消。确认无越界 tracked 生成物后由 Codex 接管，保留核心逻辑并补齐 blank player/actor/asset fail-closed 与测试。
- E05：Codex 新增 caller 显式声明 `migrationState` 的纯 resolver；legacy/migrated 必须分别与 allowlist、encounter count、legacy-content 形态严格一致，不允许 resolver 推断状态。

## 主控审查

- mapping 集合为防御性不可修改副本；director/roster identity、player ID、duplicate actor 构造期 fail closed，完整 coverage/player adapter/move binding 继续由唯一 assembler 路径校验。
- visual roster 在 runtime 前遍历全量 combatants，reserve/warning/active 均有视觉；玩家沿用 founder fallback，敌人沿用 snapshot iconPath。
- migration resolver 不包含 loader、stage ID、host routing、tuning、objective 或 token 语义。
- 相对 `27c9777c` 未修改任何 production host、data、reward、save 或数值配置；未新增依赖。

## 集成基线回归闭环

批末全量测试没有把失败误判为并发噪声。主控以原始 `main` 与各 READY 恢复点二分，定位并修复了更早二阶段批次漏过的三类确定性回归：

- `19360f19` 将 Phase 0A 扇角接入 `ForwardFanScope` 后错误拒绝既有 `halfArcRadians > pi` 全向哨兵。兼容层现在先拒绝负数/非有限值，再只向共享 scope 传 `min(original, pi)`；共享 `ForwardFanScope` 合同未放宽，后置严格边界仍使用 caller 原值。
- G1 候选留下数值默认参数与源码契约误命中：换波间歇、spawn 内部计数改为 caller 显式输入；Qi/TimedStatus 初始化改为等价重定向构造，运行语义不变。
- C11 强制 tactical `cooldownSeconds` 后 debug fixture 漏迁。gather/clear 现分别显式读取 YAML 5/8 秒；binding 同步拒绝 NaN/Infinity，并新增直接边界测试。

两个修复任务均在独立 worktree 完成、主控 cherry-pick 复审并生成 READY tip：`e13c8049`、`38b38dd0`。

## 验证

- 新合同、dynamic encounter、assembler、observer、legacy wave、headless、spawn/roster、battle screen、retry、mainline 和 tower：266/266 通过。
- D09 分支专项 15/15，关联回归 95/95；D10 分支 visual/mapper 36/36；E05 主控 targeted 5/5。
- 回归闭环最终集成专项：143/143 通过；覆盖扇角/vulnerability、source contract、Qi/status/spawn/wave、debug fixture/mechanics 和 tactical cooldown。
- `flutter analyze --no-pub lib test`：0 issues。直接运行无路径范围的根命令会误纳入独立嵌套包 `tools/phase0minus_probe`，其独立依赖不属于主包 analyzer 边界，因此未作为主项目 Gate。
- 最终 `flutter test --no-pub`：4599/4599 通过，退出码 0。
- 原三路合同终审及三路回归定位/修复复审：最终均为 0 P0 / 0 P1 / 0 P2；发现的账本失真、audit 缺失与两个非阻断冷却 P2 均已闭环。
- `git diff --check`：通过。

## 冻结边界与后续

本 READY 不代表黑风岭 encounter 数据、伏击 objective、AttackToken enforce、入口预警 VFX 或 production host switch 已完成。下一批必须继续停在已冻结产品语义内；若内容 objective 与令牌 enforce 仍未拍板，只能推进 loader/schema/validator 等不猜语义的基础设施。

## 已知非阻断债务

- legacy/encounter assembler 仍各有一段 factory → adapter → session 组合重复，当前无行为分叉。
- encounter runtime 局部 rollback 不能回滚 caller `Random` 已消费序列。
