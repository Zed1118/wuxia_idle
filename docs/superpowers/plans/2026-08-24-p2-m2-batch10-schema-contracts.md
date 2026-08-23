# P2 M2 Batch10：Schema 与运行策略合同

## 目标

从 G0 READY `44e42497` 出发，关闭黑风岭生产纵切前最短的三条合同关键路径：combat catalog 表达能力、主线 replay/连续 run 参与策略、随行听剑占用与 claim 幂等。三路只提供可审查合同，不提前切生产数据或 UI。

## 并行来源

1. C01 / Codex：公共 schema、loader、validator、objective mapper；单一 public-schema owner。
2. R01 / Qoder Qwen3.8-Max：MainlineRun 与 replay/headless/sweep 参与者纯合同。
3. R02 / Pi DeepSeek V4 Flash：随行听剑单关占用、四类互斥、释放和首通 claim 纯合同。

当前状态：C01、R01 与 R02 已进入集成；Batch10 终审后续发现 C01 的 objective primitive ID 未进入权威 namespace 校验（P1），现由 `codex/phase2-m2-c01-objective-reference-fix-20260824` 返修，未重新打 READY。R01 的 transition 绕过 eligibility 问题已由 Qoder 修复；连续 run 现要求外部 battle-eligibility 事实，失败走 typed refusal 且不创建新状态或 snapshot。

G7 退役平衡诊断引用包已通过主控与独立复审并作为辅助证据并入；集成态 23 文件 265/265、变更 Dart analyze 0、额外两项 balance guard analyze 0，当前只等待最终集成态独立复审与 READY。

C01 P1 已由 `e4762e71` 修复并以 `d409779c` 集成；返修后联合 targeted 268/268、变更 Dart analyze 0、两项额外 guard analyze 0。第二次独立终审聚焦复跑 50/50，P0/P1/P2=0；Batch10 可在验收记录提交后追加空 READY。

## 硬边界

- 不写 `data/combat/**` 生产 YAML，不切主线 host，不改 save、UI、奖励或发布配置。
- 精确敌量、activeLimit、补兵阈值、token budget、武器/防御参数仍是 tuning；本批不得提供生产默认。
- 七心魔 AI、逐模式解锁和 Ch1 之外生态继续遵守 G0 的逐项用户签字要求。
- C01 不得发明未冻结的多目标完成语义；只能表达方案已有、内容中立且 fail-closed 的合同。
- 三个来源分支都必须有计划、targeted 测试、scoped analyze、干净工作树和 READY tip；主控仍需独立审查实际 diff。

## 集成顺序

R01 与 R02 文件独立，可在任意顺序整合；C01 修改公共 schema，先独立验证后再整合。三路合并后运行联合 targeted、相关 data/mainline scoped analyze、YAML/Markdown/diff 检查和独立 P0/P1/P2 复审。

## 下一唤醒

C01 READY 后才能启动 objective/token runtime 和 Ch1 候选数据包；R01/R02 READY 只解除合同层，不代表生产 host、成长发放或 UI 已完成。

- C01 已于 `b195571b` 集成，并已从该稳定基线唤醒 `P2-M2-R03-OBJECTIVE-CONTROLLER`。
- Batch10 终审 P1 返修只扩充 caller-required objective reference namespaces，并在 typed manifest 与 source-aware loader preflight 双层 fail closed；不改 production data/host/UI/save/reward/tuning，不把 target 推导或绑定为 spawn entry。
- Ch1 候选数据包仍只允许 candidate/fixture，不得在 tuning 证据 Gate 前提升为 production YAML。
