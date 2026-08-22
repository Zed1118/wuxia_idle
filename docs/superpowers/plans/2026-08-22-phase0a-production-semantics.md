# Phase 0A 生产语义补齐批

日期：2026-08-22
分支：`codex/phase0a-production-semantics-0822`

## 目标

补齐 Phase 0A 对塔 42/49 护法结界、`surviveTicks` 胜负条件和
`cycleVulnerability` 高周目覆盖的生产消费，使 Ch2–Ch21 主线 100 关与
塔 49 层预检从 146/149 推进到 149/149 eligible。可玩与 headless 必须
复用同一 reducer/结算语义。

## 边界

- 不拆旧 3v3，不切主线正式入口，不迁远征/断魂庄，不 merge/push/deploy。
- 不新增或调整战斗数值，不改 YAML 机制值，不触三系锁死或伤害公式。
- 护法机制必须动态读取护法存活态；不得把 ward 冻结为静态快照乘子。
- `surviveTicks` 在 reducer 拍边界判定，不能在 `runToEnd` 后补判。
- `cycleVulnerability` 显式消费 cycle 上下文，cycle 1 保持基础值。

## 验收标准

1. 生产接线：真实塔 42/49、真实 `surviveTicks` 关卡与周目配置经
   mapper → flow → reducer/damage resolver → headless 消费。
2. guardian：护法存活时 Boss 目标保护与动态减伤成立；破招转移遵守既有
   最低血护法语义；护法全灭后减伤/拦截解除。
3. survive：提前全歼、撑满拍数、提前阵亡及 N-1/N 边界结果正确；HUD 与
   结算语言可区分普通全歼。
4. cycle：cycle 1 取 base，cycle 2+ 取生产 override；承伤乘子仍守 schema
   下限与伤害不进百万红线。
5. manifest 精确为 149 eligible / 0 skipped，所有 canonical case 重放确定。
6. `flutter analyze --no-pub lib test` 0 issue；targeted 与全量测试通过；
   `git diff --check` 通过。
7. UI 走 1280×720 / 1440×900 widget smoke 与 macOS 实机 guardian/survive
   Gate，检查键鼠、溢出、提示遮挡和卡死。
8. 无中文文案/数值散写进 Dart，无高频 debug 日志、临时输出、截图或生成物
   误提交；恢复点和提交信息符合 CLAUDE.md §8.0/§8.2/§8.3。

## 切片

1. 冻结塔 42/49 guardian 行为矩阵和 Phase 0A 状态边界。
2. 接入 guardian reducer、目标/破招规则、damage resolver 与表现。
3. 接入 surviveTicks reducer、flow、HUD 与结算表现。
4. 参数化 cycleVulnerability 生产装配。
5. 刷新 manifest/diagnostic，完成自动验证与实机 Gate。
6. 主 agent 审查、提交并更新恢复点。

## 当前恢复点

- 状态：进行中。
- 最后完成：从 `3fbeb448` 建立独立 worktree/分支；DeepSeek 只读审计冻结
  guardian 矩阵：塔 42 = ward + 顶层蓄力 + 破招转移 + 每相位一次双护法
  合击；塔 49 = ward + vulnerability + 阶段蓄力，无破招转移/合击。
- 下一步：实现 guardian 运行态字段、动态 ward、目标保护、塔 42 破招转移与
  合击；保持零配置 RNG/状态逐字节回归。
- 已跑验证：上一批基线 analyze 0、全量 5344/5344、实机 Boss 三态通过。
- 阻塞项：无；六人主观 Gate 与 Windows Gate 不属于本批。
