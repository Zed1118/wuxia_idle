# G2 stage_01_03 验收记录模板

- stage: `stage_01_03` / 黑风岭
- overall: `BLOCKED/待集成复验`
- candidate source: `test/fixtures/phase2/combat/ch1_candidate`
- generated_at: `<fill after evidence capture>`

本模板只记录证据状态，不提前宣告生产链路 PASS。候选边界必须保持 `TUNING/candidate`，不得升级为冻结值。

范围说明：`stage_01_03` 承担非 Boss 怪潮纵切；第 5 项使用既有生产 `stage_01_05` 章末 Boss 作为专项证据锚点，不把其迁入新 catalog，也不扩大本次内容施工范围。

| gate | hard acceptance | status | required evidence | record |
|---|---|---|---|---|
| `g2-01-continuous-movement-attack` | 连续移动/普攻无漏拍 | `BLOCKED/待集成复验` | runtime integration; performance profile | 待填：固定 tick 输入记录、普攻事件、原始帧证据 |
| `g2-02-continuous-clear-35-45` | 35–45 总敌人连续清怪 | `BLOCKED/待集成复验` | candidate contract; headless integration | `TUNING/candidate`；待生产 encounter 集成复验 |
| `g2-03-active-threat-8-16` | 8–16 active 且威胁可读 | `BLOCKED/待集成复验` | candidate contract; visual capture | `TUNING/candidate`；待双 viewport 视觉复验 |
| `g2-04-defense-options` | 盾反/招架/闪避各自有用 | `BLOCKED/待集成复验` | runtime integration; manual integration; visual capture | 待填：三类防御的可观测结果 |
| `g2-05-learnable-boss` | Boss 可学习且破绽可利用 | `BLOCKED/待集成复验` | `stage_01_05` runtime integration; manual integration; visual capture | 待填：正式入口蓄力预警、破招/破绽利用、同招掉落记录 |
| `g2-06-victory-next-stage` | 胜利到下一关无阻塞 | `BLOCKED/待集成复验` | runtime integration; manual integration | 待填：结算、路由、下一关入口 |
| `g2-07-manual-auto-headless-parity` | manual/auto/headless 同规则 | `BLOCKED/待集成复验` | headless integration; runtime integration; manual integration | 待填：同 seed、同事件语义、差异说明 |
| `g2-08-dual-viewport-performance-ink` | 双 viewport 性能与水墨视觉通过 | `BLOCKED/待集成复验` | performance profile; visual capture | 待填：`1280x720`、`1440x900` 原始证据 |

## Evidence checklist

- commit / binary checksum / fixture checksum: `<fill>`
- headless seed and output: `<fill>`
- manual and auto run ids: `<fill>`
- performance raw telemetry for both viewports: `<fill>`
- visual capture paths for both viewports: `<fill>`
- unresolved risk or blocker: `<fill>`
