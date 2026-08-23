# 二阶段 M2 Batch12 运行时执行接缝审计（2026-08-24）

## 基线与授权

- 基线：Batch11 READY `57f04b397d1412128535ba8f74a7e61ecdfb4577`。
- 用户已授权持续自动推进，并明确要求充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent。
- 本批不需要新的产品语义决策；候选数值晋升、真人试玩与 production host 切换继续保持 Gate。

## 范围

- R05：攻击 token director 的批次 intent 执行接缝。
- R06：objective controller 的原子运行时跟踪接缝。
- R07：combat encounter content + spawn director 到精确 enemy roster 的显式映射接缝。
- 集成态验证三项可组合，但不接 production data/host/UI/save/reward/injury。

## 预注册风险与控制

- intent 注入或重排：R05 输出只能是输入 identity 的稳定子序列；失败发生在 observer/reducer 前。
- 目标身份误推断：R06 仅消费显式 event 或调用方显式 defeat classifier；不按字符串或角色类型猜测 commander。
- content/runtime roster 漂移：R07 在 actor factory 调用前比较 entry-id 集合，并保持 runtime enemy id 的显式权威来源。
- candidate 值误晋升：生产路径、YAML 与 host 不在 owned files；最终审计再次检查 production path isolation。
- 工作树污染：实现和集成均在独立 branch/worktree，main/origin main 只读核对。

## 验证记录

### 来源

- R05：实现 `ddce919f`，READY `a674c420`。Pi CLI 0.84.1 实际使用 `deepseek/deepseek-v4-flash`、thinking high 完成设计审查与最终 diff 复核，最终 PASS；61/61、scoped analyze 0，Codex 独立复审 P0/P1/P2=0。
- R06：实现 `b4ebdb84`，READY `b69f5449`。目标进度批次先在局部快照完成再一次提交；28/28、scoped analyze 0，Codex 独立复审 P0/P1/P2=0。
- R07：实现 `99f90d99`，READY `79819c6b`。Qoder CLI 1.1.28 实际使用 `Qwen3.8-Max`、reasoning high 完成设计和最终 diff 审查，最终 PASS；78/78、scoped analyze 0，Codex 独立复审 P0/P1/P2=0。

### 主控集成验证

- 集成提交：R06 `197b8a95` / `50a0612c`，R07 `41045cf8` / `ee13d743`，R05 `725097f5` / `39fb21b0` / `92e2310d`。
- 12 个合同与应用测试文件联合 targeted：167/167 通过。
- 9 个变更 Dart 项 scoped analyze：0 issue；format 0 changed。
- fresh integration worktree 执行 `flutter pub get`、build_runner 生成 126 个 gitignored outputs，并复制与主 checkout shasum 一致的 `libisar.dylib`；批末 full Flutter test：4877/4877 通过，exit 0。
- task/decision registry YAML parse、全部 prerequisite 闭合、`git diff --check`、production path isolation、63 个 gitignored generated files 与动态库一致性检查全部通过。
- 预分析发现 R05 prerequisite 使用不存在的旧任务名；已在 `0f7f306c` 修正为真实 `P2-G2-D04-TOKEN-OBSERVE-SEAM`，全 registry 无其他悬空 prerequisite。
- `main` 与 `origin/main` 均保持 `e292d3a0`，未被修改。

## 待终审与残留 Gate

- 当前实现、来源工具审查、三项来源独立复审、联合 targeted、analyze、full test 与仓库审计均已通过；待集成态独立终审后冻结 READY。
- production candidate budgets、Ch1 production catalog/actor assembly、host route、Mac/Windows Profile 与真人试玩仍受 promotion/G2 Gate 锁定；Batch12 不宣称这些产品验收完成。
