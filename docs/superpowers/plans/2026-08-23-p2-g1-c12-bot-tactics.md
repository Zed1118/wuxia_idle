# P2 G1 C12 玩家 Bot 三战术候选

## 范围

- 为 `Phase0aPlayerBotAdapter` 注入 typed tactic policy。
- 只组合既有 `Phase0aPlayerCommand` 能力，不读取表现层/隐藏信息，不新增战斗规则或数值。
- 默认 `production` policy 保持旧行为：ready 的 gather、clear、numeric skill 同拍请求。

## 行为画像

| Policy | 已有 command 选择 |
| --- | --- |
| `seekGap` | 仅在目标存在可见蓄力/踉跄窗口时按优先级择一 ready numeric skill；窗口外保留资源 |
| `assault` | gather、clear、numeric skill 同拍请求 |
| `steadyGuard` | 窗口外保守不放 tactical；窗口内优先 clear 打断，否则择一 numeric skill |

寻隙/稳守会优先选择最近的可见窗口目标（`chargingCast != null` 或
`staggerTicksRemaining > 0`），等距按 id 决胜；没有窗口时沿用最近目标进行走位和普攻。
所有目标选择、移动、朝向、普攻和 readiness 判定仍由现有 adapter/state/reducer
路径完成。护盾和危险区脱离不在当前 command 面，故本批是 C12A 行为画像骨架，
不是完整表现层战术实现。

## 验收

- 同一状态/同一 policy 每次生成相同 command。
- 默认 policy 与变更前 command 逐字段一致。
- 三个显式 policy 在相同 ready 状态下产生可观察差异。
- targeted `flutter analyze` 与 Bot/headless tests 通过。
