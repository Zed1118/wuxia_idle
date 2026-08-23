# Phase 2 G2 Batch3 遭遇生产接缝审计

## 结论

G2 Batch3 的三条生产接缝已完成集成、主控修正和独立复审，可进入 READY。本批将 live/headless/retry 消费面统一到最小 flow 合同，建立了攻击令牌只读观察点和 legacy encounter compatibility wrapper，没有改变现有战斗结算、随机消耗或关卡节奏。

## 交付内容

- D03 `Phase0aBattleFlow`：仅暴露 state、outcome、ordered event records 和 `advance`。`Phase0aWaveBattleFlow` 实现该合同，controller/headless/retry 改为面向接口，production assembler 仍返回原有具体类型。
- D04 attack-token observe-only seam：`Phase0aCombatSession` 在 enemy intents 产生后、reducer 执行前可注入只读 observer。budget 和 request mapper 全由调用方显式提供，observer 无法返回、过滤、重排或改写 intents。
- E02 `Phase0aEncounterFlow.compatibility`：纯委托 legacy wave flow，用相同 seed 和 command 锁定 state/events/event records/outcome 的同步与异步 parity。

## 主控修正

- 将 observe-only 的对外诊断发布收紧为事务式：observer/director 异常时，session state、last observation 和 last allocation 均保持上一次成功提交的值。
- 将 default/observe parity 从 resolver 调用次数提升为逐调用完整输入转录比对，覆盖 attacker/target/kind/stagger/charge/ward。
- 补齐 encounter compatibility 的 victory/defeat/ongoing 明确期望值和异步 headless parity。

## 模型派单与复审

- Pi + DeepSeek `deepseek-v4-flash` 完成 D03，交付 READY `ca3c3307`。
- Qoder CLI + `Qwen3.8-Max` 完成 D04 代码和测试；Qoder 沙箱禁止执行 Flutter/Dart/Git 命令，主控在集成环境中完成实测、提交和 READY 验证 `b5eed546`。
- Codex 子 agent 完成 E02，交付 READY `ac69ee42`。
- D03/E02 与 D04 分别经独立 Codex 复审；主控修正后均为 0 P0 / 0 P1 / 0 P2 阻断。

## 验证

- 三条新接缝 targeted tests：19/19 通过。
- wave flow + headless kernel + production assembler：44/44 通过。
- retry + battle screen + mainline wiring：50/50 通过。
- 合计：113/113 通过。
- `flutter analyze --no-pub`：0 issues。
- `git diff --check`：通过。

## 边界与下一步

本 READY 不代表 SpawnDirector 已经动态生成敌人，不代表 AttackTokenDirector 已经 enforce，也不代表黑风岭数据、UI 预警、奖励或存档纵切已完成。下一批应建立只拥有一个 `Phase0aCombatSession` 的真实 encounter flow，消费 `SpawnDirector` 并产生 flow-level enemy-entry 事件；在数据和语义冻结前，token 仍保持 compatibility/observe-only。
