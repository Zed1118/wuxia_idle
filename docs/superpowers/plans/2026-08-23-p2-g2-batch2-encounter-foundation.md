# P2 G2 第二批：遭遇基础合同

## 目标

从 READY `6da121cf` 出发，并行完成 `SpawnDirector`、`AttackTokenDirector` 与显式 `ActivityParticipationRequest` 三条纯领域合同，为下一批 `Phase0aEncounterFlow` 和黑风岭 35–45 总量 / 8–16 活跃 / 2–4 攻击令牌生产纵切提供单一语义基础。

## 并行切片

1. D01（Pi + DeepSeek V4 Flash）：总量/活跃/后备分离，显式入口、补兵阈值、预警和攻击宽限快照，稳定顺序，不硬编数值。
2. D02（Qoder + Qwen3.8-Max）：近战/远程/冲锋/支援显式预算，屏外高威胁、出生宽限和不可阻挡范围上限，确定性分配。
3. E01（Codex Luna）：实现方案原文中的显式参与请求类型，只校验请求，不选角色、不写默认 policy。

## 红线

- 不修改 reducer、伤害、奖励、伤势、存档、UI 或生产关卡数据。
- 20%–30%、8–16、2–4 是后续数据/试玩参数；合同只接受调用方配置，不在 Dart 定默认值。
- 主线重打/扫荡参与者、`MainlineRun` 锁定/换装/伤势中断仍为 `PROPOSED`；E01 不得替用户选择。
- 本批的 READY 是基础合同 READY，不冒充黑风岭生产纵切已完成。

## 验证

- 每路先红测，targeted test、限定 analyze、`git diff --check`。
- 主窗口必须逐字段审查实际 diff，要求不可变输入/输出、重复 ID fail closed、输入顺序无关。
- 集成后联合重跑三路新测试、现有 reducer/headless/live 核心回归及全仓 analyze。
