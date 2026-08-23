# Phase 2 G2 首批生产接线审计

## 结论

本批只接入两条已证明不需要 tuning / `PROPOSED` 决策的生产路径：C02 前向扇形单目标判定，以及 C10 现有事件流的只读领域顺序投影。原始 reducer 事件、sequencer、VFX 和伤害/奖励结算均未改写。

`main` / `origin/main` 保持在 `e292d3a0`；本批工作仅存在 `codex/phase2-g2-production-integration-20260823` 专用 worktree。

## 生产接线

| task | 执行方 | 生产结果 | 边界 |
|---|---|---|---|
| C02 | Codex Terra | 真实 reducer 的单目标 strike 判定经 `ForwardFanScope` | 保留距离/actor-id 决胜、guardian 过滤、零朝向向右、严格闭扇角和单次命中；未开启多目标或其他 scope |
| C10 | Codex Luna | 共享 `Phase0aWaveBattleFlow` 每拍生成只读 `CombatEventRecord`，live controller 和同步/异步 headless 暴露同一投影 | 投影只消费事件快照；不回查 state、不重算伤害、不回馈 reducer/VFX |

## 主审返修

- C02 通用 scope 含 `1e-12` 几何容差，可能将极小角度的边界外目标改判命中；生产薄适配在通过 scope 校验后恢复旧 `acos <= halfArc` 严格边界，并补边界外回归。
- C10 初版是未消费 adapter，不足以称为生产接线；改为在 live/headless 共用 flow 中实际生成和缓存，并分别经 controller/result 暴露。
- C10 初版 canonical ID 漏掉坐标、guardian 字段和 outcomes 完整载荷，且 list `join(',')` 有分隔符碰撞；已按全部事件 equality payload 长度前缀编码，并规范化相等的 `0.0/-0.0` 坐标。
- C10 初版直接按 seq 返回 records，真实 reducer 同拍可先发 damage 后发 legality；已在 adapter 内经 `CombatEventOrder.order` 排序，原 `Phase0aEvent` seq 和 VFX 消费顺序不变。

## 验证

- 初次联合回归：`138/138`。
- C02 主审收紧后定向回归：`59/59`。
- C10 完整 payload / flow / headless 返修定向回归：`38/38`。
- 最终 G2 联合回归（reducer、几何、guardian、wave flow、Ch1 mapper/headless、mainline live、sweep、VFX）：`161/161`。
- DeepSeek 交叉审查：无 P0/P1；其 live getter 缺显式消费断言 P2 已修复，Ch1 五关现对比 live 逐拍 records 与 headless 全量 records，`17/17` 通过。其余建议为扩充 20 种事件的逐字段防回归矩阵，不影响本批正确性。
- Qoder + Qwen3.8-Max 交叉审查：无 P0/P1；确认 C02 严格边界、单目标/guardian 筛选与 C10 全 payload、同拍排序、live/headless 只读接线均成立。其两条 P2 为固定类型字段中理论上的 `null` 字面量及扩充逐类测试矩阵，均非本批功能缺陷。
- 根包已运行 `dart run build_runner build`，生成 126 个 gitignored outputs；`tools/phase0minus_probe` 依赖已补齐。
- 全仓 `flutter analyze --no-pub`：`No issues found`（最终返修后）。

## 本批明确阻塞

- C03：`firstEffect` 与现有同拍伤害可能双结算，tick/seconds 未冻结。
- C05/C06/C16：生产无统一 posture/status/defense 运行态；shield-only counter、`DefenseBranch.hit` 和 counter event 落点未决。
- C07：无 action identity/lifecycle，真气 reservation/commit 无法安全接入。
- C08：无 canonical weapon/effect registry 与连段运行态，直接接入会改 Ch1 普攻节奏。
- C09：modifier 字段消费归属与 recovery 方向未冻结。
- C13B：主线/塔/扫荡无 sessionId，规则表、持久 ledger、dangerTier 数据源未拍板；远征/断魂庄已有独立持久幂等。
- C14B：gauntlet 已在单事务内结算并删除 run，无 run 重入直接返回；内存 guard 既不持久也无旧 runId，拒绝冗余接线。

## 恢复点

- 分支：`codex/phase2-g2-production-integration-20260823`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-g2-production-integration`
- 预期 READY：`[READY][CODEX][P2-G2-BATCH1] 完成首批生产接线`
