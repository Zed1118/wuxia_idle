# Phase 2 G1 第二批核心合同候选审计

## 结论

第二批五路候选已合入 `codex/phase2-g1-batch2-integration-20260823` 并通过 Codex 主审。`main` / `origin/main` 未修改；未拍板 MainlineRun、伤势权重、奖励数额、奖励模式表或其他 `PROPOSED` / tuning 项。

本批有意区分“候选合同已冻结”和“生产全链已完成”：C13、C14、C16 为纯领域候选；C11、C12 因映射证据或 command 面不足分别冻结为 C11A、C12A。

## 五路结果

| task | 执行方 | READY tip | 主审结论 |
|---|---|---|---|
| C11A cooldown seconds | Codex Terra | `022321df` | `SkillDef.cooldownSeconds` 与 Q/R 真实 5s/8s 无损迁移；数字键和敌方技能仍依赖运行时攻击间隔，禁止猜成静态秒值 |
| C12A bot tactics | Codex Luna | `b3143d1a` | 默认 Bot 逐字段兼容；寻隙/稳守使用可见蓄力/踉跄窗口，强攻保留并发技能请求；护盾/危险区脱离待 command 面补齐 |
| C13 FailurePolicy | Pi + DeepSeek V4 Flash | `1754d763` | 注入规则、缺失 fail closed、session+participant+content 幂等、claim ledger 回滚；不含 injury 权重/MainlineRun/persistence |
| C14 RewardPolicy | Qoder + Qwen3.8-Max | `b8f737a0` | 三奖励层、个人/宗门 scope、两类版本化 claim key、重复拒绝与 claim ledger 批原子；生产事务/Outbox 仍待接线 |
| C16 defense hardening | Codex Luna | `58b700af` | 确定性顺序、redirect/counter 分离、nonrecursive、默认禁暴击/吸血/附带反伤、不可变 typed allowlist 与 caller-supplied remaining budget |

## 主审修正

- C12 初版仅做技能开关且测试在无窗口状态期待稳守释放 clear；退回后补可见窗口目标/资源保留，并用真实 numeric binding fixture 验证窗口内 hotkey。
- C13 初版 claim key 的枚举插值产出错误 canonical，且未拒绝分隔符碰撞、生命比例未拒绝 NaN/Infinity；主审修正并补测试。
- C14 初版 `parse` 对空组件抛 `ArgumentError`，与 fail-closed `FormatException` 合同冲突；主审统一异常并明确纯守卫只保证 claim ledger，不伪称能回滚外部副作用。
- C16 初版 allowlist 保存 mutable Set、每秒上限名称暗示 resolver 自带时间窗口；主审改为 const bool typed allowlist，并把输入改为调用方已计算的本秒剩余预算。
- 集成复核继续将 C12 自定义 policy 的集合复制为不可变值；Qoder 交叉审查指出 C16 typed allowlist 缺 value equality/hash，已补齐并加回归测试。
- C11 审计确认历史 `cooldownTurns` 有三种不等价生产语义；只迁移可证明无损的 Q/R，未机械复制 262 条旧值。

## 验证证据

- 五路集成联合 targeted：`100/100`。
- C11 mapper 真实数据/headless 链在生成 `.g.dart` 后通过，C11 定向集合 `33/33`。
- 根包运行 `dart run build_runner build`，生成 126 个 gitignored outputs；未提交生成物。
- 补齐 `tools/phase0minus_probe` 子包依赖后，根仓 `flutter analyze --no-pub`：`No issues found`。
- `decision_registry.yaml`、`task_registry.yaml` 解析通过；`git diff --check` 通过。
- Qoder + Qwen3.8-Max 交叉复核：无 P0/P1；其 allowlist value equality P2 已修复。`DefenseBranch.hit` 未使用与 shield-only counter 属既有纯候选语义，未在本批擅自改写，留生产接线前确认。
- Pi + DeepSeek V4 Flash 交叉复核：C12/C14 无 P0/P1/P2；确认 7 处生产 Bot 调用仍走默认兼容 policy，奖励 key/claim 合同与主审修正一致。其 P3 为 `tactic` 暂无消费者、chargingCast/多窗口 tie-break 测试可扩充及 `v01` 宽松解析，均留后续接线批处理。

## 明确保留的后续

- C11B：分别决定 numeric player skill、enemy phase skill、charge skill 的 seconds 来源，完成 mapper 生产读方迁移和 `cooldownTurns` 归零守卫。
- C12B：先扩展玩家 command/intent 的护盾、防御与危险区脱离能力，再实现稳守完整画像；不从表现层读取预警。
- C13/C14：接入 production session、SettlementPipeline、持久化 claim ledger 与同一事务/Outbox；奖励数额/模式表仍需数据与拍板。
- C16：接入统一命中事件与 reducer，caller 负责跨命中每秒预算；不得在 adapter 重复结算。

## 恢复点

- 分支：`codex/phase2-g1-batch2-integration-20260823`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-g1-batch2-integration`
- 预期 READY：`[READY][CODEX][P2-G1-BATCH2] 完成第二批核心合同候选`
- 后续继续从 READY tip 建独立 worktree，不直接修改 `main`。
