# P2 G1 唯一关键路径清账

## 目标

只清理 G2 前真实阻塞，不扩张 mapper/observer/证据型微任务。恢复基线为 M6 Batch1 READY `6941bca57299df6d7c5c97476610f1d18eb0bea4`；本分支不修改 `main` / `origin/main`。

## 四项事实结论

| G1 非终态项 | 事实 | 本批动作 |
|---|---|---|
| `P2-G1-BATCH1-INTEGRATION` | READY tip `29f04073` 已进入当前祖先链，审计/测试/外审完整 | 仅把 registry `ready_candidate` 订正为 `ready_reviewed` |
| `P2-G1-BATCH2-INTEGRATION` | READY tip `56450ba3` 已进入当前祖先链，审计/测试/外审完整 | 仅把 registry `ready_candidate` 订正为 `ready_reviewed` |
| `P2-G1-C11-COOLDOWN-SECONDS` | 三处 production mapper 仍读 `cooldownTurns` 并乘不同攻击间隔 | 需用户冻结 seconds 权威，再实现归零 |
| `P2-G1-C12-BOT-TACTICS` | 三战术 typed policy 已有，但所有 production adapter 构造仍走默认兼容 policy | 接入真实 selector/consumer，并用 live/headless 同核证据关闭 |

## C11 推荐冻结

当前玩家数字键按 `cooldownTurns × 0.55s`，敌方阶段技和蓄力技按 `cooldownTurns × 1.0s`。同一 `SkillDef` 可跨玩家/敌方复用，因此一个通用秒字段无法无损表达两种旧语义。

推荐：玩家数字键将当前 `turns × 0.55s` 一次性物化到 `SkillDef.cooldownSeconds`；敌方阶段技/蓄力技在敌人/阶段内容绑定中增加显式 seconds override，并按当前 `turns × 1.0s` 物化。mapper 三处只读 seconds，随后静态守卫 Phase 0A production 对 `cooldownTurns` 零读取。该方案保持当前手感并切断未来攻击间隔调优对技能冷却的隐式连动。

未取得用户明确批准前，不写 seconds、不机械复制 YAML、不启用伪红守卫。

## G2 前最小关键路径

| 顺序 | 产物 | 退出条件 |
|---:|---|---|
| 1 | G1 状态清账 + C11/C12 真缺口关闭 | G1 21 项全部 `ready_reviewed`，production cooldownTurns 读方为 0，三战术有真实消费者 |
| 2 | Ch1 production catalog | candidate 数据进入 `data/combat/**`，production loader/validator/host 可达；仍标 candidate/tuning，不冒充定值冻结 |
| 3 | `stage_01_03` 黑风岭生产纵切 | 生产入口可玩；35–45 总敌量、8–16 活跃、令牌 2–4；手动/bot/headless/结算/下一关同核 |
| 4 | G2 八项验收 | 八项逐一 `PASS / REWORK / BLOCKED`；仅全 PASS 或用户明确豁免才关闭 |

G2 前不进入五武器、其余生态、21 章、49 塔或 M3/M4 扩面。

## 恢复点

- 当前状态：G1 两项 registry 漂移已订正；C11 等待用户冻结；C12 真实生产缺口已定位。
- 下一步：收到 C11 批准后，建立精确代码白名单并按 TDD 完成 C11/C12；未批准时本分支以 `[BLOCKED]` tip 冻结。
