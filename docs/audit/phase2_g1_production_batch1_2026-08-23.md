# Phase 2 G1 第一批生产差距修复审计

## 结论

基于 `f93c29e6c5130ba1a95f56fe93c3c5ef343f680b` 的 G1 第一批候选已完成四个受控切片并通过集成验证。所有改动位于 `codex/phase2-g1-production-batch1-20260823`，未修改 `main` / `origin/main`，未拍板任何 `PROPOSED` 或 `PROPOSED_REOPEN` 项。

## 已完成切片

| task | READY tip | 生产结果 |
|---|---|---|
| P2-G1-C15-WAVE-COOLDOWN | `3b5e926b` | 主线/群战同关换波保留技能 CD；配置化间歇只递减剩余 CD；显式新关/特殊 policy 重置路径保留 |
| P2-G1-C17A-INNER-DEMON-INJURY | `673557ed` | 仅心魔战败免除物理轻伤/重伤；普通 Boss 伤势、内息紊乱和现有主修 ×0.90 行为保持 |
| P2-G1-A01-CURRENT-LEADER | `cc5a84b4` | 主线、塔、扫荡统一解析当前掌门；空、悬空或缺角色指针可诊断 fail closed，不再静默取首角色 |
| P2-G1-C17B-INNER-DEMON-LEGACY-CLEANUP | `8b13f6cc` | 清除五个零生产读方旧字段；typed penalty 只保留主修倍率；退役 key 复活时 fail-fast |

## 集成主审与修正

- C15 生产 `intermission_seconds` 保持 `0.0`，没有猜测未签的正数 tuning；测试用注入值证明精确递减能力。
- C17A 豁免严格为 `!resolvedVictory && stageType == innerDemon`，没有把心魔胜利或普通 Boss 扩成免伤势。
- A01 只改变无效指针行为；合法指针下参与者不变，没有新增 replay、bot、headless、扫荡参与者选择或 MainlineRun policy。
- C17B 初版要求 `main_cultivation_multiplier` 必填，联合测试发现会破坏只配置脆弱窗口的兼容 fixture；主审恢复缺省 `0.90`，并保留五个退役 key 的 fail-fast。
- Qoder + Qwen3.8-Max 独立审查发现扫荡装配未转发 `mapping.waveTransitionPolicy`；已补接并用 source contract 锁住，避免手动与 headless 的波间真气/AP/CD 语义分叉。
- 旧档复核确认正式 onboarding、debug seed、传位与恢复校验均建立有效指针；未完成 onboarding 的空档在战斗入口 fail closed 属合同预期。

## 验证证据

- 执行分支：C15 `97/97`；C17A `2/2`；A01 resolver/扫荡 `6` 项及主线/塔 wiring；C17B `27/27`。
- 集成态第一轮：受影响联合测试 `137/137`。
- C17B 合入后：心魔全目录 `50/50`；最终受影响联合测试 `173/173`。
- Qoder follow-up 修复后：扫荡真实主线/塔终局与同核 contract `3/3`。
- 新 worktree 补齐根包生成物与 `tools/phase0minus_probe` 子包依赖后，`flutter analyze --no-pub`：`No issues found`。
- YAML 解析、`git diff --check`、文件白名单与工作区状态在 READY 前复核。
- Pi + DeepSeek `deepseek-v4-flash` 独立只读审查：无阻断、无 `PROPOSED` 越界；其 loader 校验疑问经代码复核确认外层 `MainlineWaveDef.validate()` 已调用波间校验。
- Qoder + Qwen3.8-Max 独立只读审查：指出 sweep/headless 波间 policy 漏传；本批已修复。Qoder 环境权限未允许实际运行 Flutter，动态验证由 Codex 集成态完成。

## 明确保留的未决项

- `INNER-DEMON-CULTIVATION-01` 仍为 `PROPOSED`，当前主修修炼度 ×0.90 只是保留现状。
- `MAINLINE-REPLAY-PARTICIPANT-01`、MainlineRun、听剑占用/比例、七心魔 AI 映射等继续阻塞。
- 正数换波间歇时长仍属 tuning；当前只完成 typed 注入与精确递减机制。
- attack cooldown 仍由既有 `reset_action_point` 合同控制；本批冻结项仅涉及技能冷却。

## 恢复点

- 集成分支：`codex/phase2-g1-production-batch1-20260823`
- 工作区：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-g1-integration`
- 预期 READY marker：`[READY][CODEX][P2-G1] 完成首批生产差距修复`
- 后续批次只能从 READY tip 新建独立分支/worktree，不直接写 `main`。
