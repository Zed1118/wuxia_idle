# P2 G2 Batch3：遭遇生产接缝

## 目标

从 READY `1150c56a` 出发，为 `Phase0aEncounterFlow` 建立不改现有战斗节奏的最薄生产接缝：统一 flow 接口、攻击令牌 observe-only intent policy、legacy wave compatibility wrapper。

## 切片

1. D03（Pi + DeepSeek `deepseek-v4-flash`）：抽取 `Phase0aBattleFlow`，让 controller/headless/retry 面向接口；旧 `Phase0aWaveBattleFlow` 行为和 assembler 返回类型不变。
2. D04（Qoder CLI + `Qwen3.8-Max`）：在 enemy AI intents 与 reducer 之间建立可注入 observe-only policy；调用方显式提供 budget/request mapper，无默认语义。
3. E02（Codex）：建立 `Phase0aEncounterFlow.compatibility`，包装旧 wave flow，用同 seed/同 command 锁定 state/events/eventRecords/outcome parity。

## 红线与验收 checklist

- [x] 不建第二 reducer/session/headless 内核；生产结算仍只走 `Phase0aCombatSession -> reducePhase0aTick`。
- [x] observe-only 不过滤、重排或改写 enemy intents，默认不注入 policy 时与基线完全一致。
- [x] 不猜 `offscreen/highImpact/telegraph/kind`，不在 Dart 写 20%–30% / 8–16 / 2–4 tuning。
- [x] compatibility wrapper 不接动态生成，不冒充黑风岭纵切已完成。
- [x] production seam 有真实 controller/headless/session 消费证据，不只停在 fixture。
- [x] targeted tests 覆盖 live/headless 非 wave 类型、default parity、observe parity 与终局幂等。
- [x] 红线影响：数值硬红线/三系锁死/在线=离线/反主流项均为 0 行为改动。
- [x] 残留风险明示：SpawnDirector 真动态生成、token enforce、黑风岭数据与 UI 预警仍属后续批次。
- [x] 主控逐 diff 复审，targeted tests + `flutter analyze --no-pub` + `git diff --check` 通过。

## 当前恢复点

- 状态：实现、集成、主控修正与两路独立复审均已完成，等待 Batch3 READY tip。
- 最后完成：主控确定性回归补强 `49bc45f4`。
- 下一步：封签 Batch3 READY；后续批次再建单 `Phase0aCombatSession` 驱动的真实遭遇流与 SpawnDirector 入场事件。
- 已跑验证：新接缝 19/19，核心回归 94/94，合计 113/113，analyze 0。
- 阻塞项：无；本批主动不触及未冻结调参与 enforce 语义。
