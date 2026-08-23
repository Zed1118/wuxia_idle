# P2-G1-C15：换波冷却生产修复

## 证据与修复

- M0 证据确认主线/群战 `preserve_cooldowns: false` 被 mapper 取反为清零；现已统一改为 `true`。
- 新增 `intermission_seconds` typed 配置，生产值保持已审口径 `0.0`，不猜未签的 tuning 时长。
- 换波保留路径按调用方注入的秒数推进 skill cooldown，保留剩余值并重算 availability；清零路径仍由既有显式入场/特殊 policy 控制。
- mapper 同时覆盖主线与群战，语义一致；新关入场合同未改动。

## 验收证据

- 同关不清零：mapper 断言 `resetSkillCooldowns == false`，flow 跨波保留测试覆盖。
- 间歇精确递减：注入 `intermissionSeconds: 0.5`，剩余 CD `2.0 → 1.5`。
- 新关重置：既有显式 `resetSkillCooldowns: true` 测试继续保留并断言清零。
- policy 拒绝负数/非有限秒数；schema/loader 也校验 typed intermission 秒数。

## 恢复点与风险

- 当前换波仍与 `wave_cleared` 同拍，生产配置 `0.0` 保持冻结事实；未来若 G1/G2 签定正数，仅需改 YAML，不改 reducer。
- 该切片不迁移旧 `cooldownTurns`，也不改 Phase0A reducer 的实时 tick 公式。
