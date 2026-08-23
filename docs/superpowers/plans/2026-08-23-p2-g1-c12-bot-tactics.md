# P2 G1 C12 玩家 Bot 三战术候选

## 范围

- 为 `Phase0aPlayerBotAdapter` 注入 typed tactic policy。
- 只组合既有 `Phase0aPlayerCommand` 能力，不读取表现层/隐藏信息，不新增战斗规则或数值。
- 默认 `production` policy 保持旧行为：ready 的 gather、clear、numeric skill 同拍请求。

## 行为画像

| Policy | 已有 command 选择 |
| --- | --- |
| `seekGap` | 按优先级择一 ready numeric skill，保留 gather/clear |
| `assault` | gather、clear、numeric skill 同拍请求 |
| `steadyGuard` | 优先 clear，否则择一 numeric skill |

所有目标选择、移动、朝向、普攻和 readiness 判定仍由现有 adapter/state/reducer 路径完成。

## 验收

- 同一状态/同一 policy 每次生成相同 command。
- 默认 policy 与变更前 command 逐字段一致。
- 三个显式 policy 在相同 ready 状态下产生可观察差异。
- targeted `flutter analyze` 与 Bot/headless tests 通过。
