# Phase 0A 反馈事件契约返修（Kimi）

`5f4f2b9c` 的资产盘点可复核，但事件 payload 把“不携平衡常量”误扩大成“不携运行时结算数值”，会使用户已明确要求的伤害飘字、CD 剩余、气值门槛无法实装。请只修原三份文档，新增返修 commit，不 amend/rebase。

## 必修

1. 契约总纲明确区分：
   - 禁止进事件：伤害倍率、CD 配置时长、技能半径等调优/平衡常量；
   - 必须进事件：模拟核已结算的运行时结果，例如 `resolved_damage`、`remaining_health`、`cooldown_remaining`、`qi_current`、`qi_required`。这些是反馈数据，不是硬编码平衡值。
2. `hit_landed` 最小 payload 补 `resolved_damage`（与飘字直接对应）及表现必要的结果字段；明确由 simulation/settlement 产生，表现层禁止重算伤害。
3. `gather_applied` / `clear_applied` 不能只带 `affected` id；改为有序的 target outcome 列表，至少能表达 target、resolved_damage（如有）、defeated、status_applied，让群体飘字/死亡/失衡只消费结果不重算。
4. `skill_availability_changed` 补足 UI 所需运行态：状态为 cooldown 时携 `cooldown_remaining`；为 qi/ready 时可携 `qi_current`/`qi_required`；不把这些写死成配置常量。
5. 删除 `attack_started` 的“相邻两次之间必有 hit_landed”：未命中合法，不得用假 hit 封口。改为仅按 seq/actor 去重，动作收束由模拟拍/表现时序管理。
6. `enemy_defeated` 的音频缺失回退锁为静音；禁默认借 `battleStagger`冒充死亡。manifest 同步删除该候选。
7. 计划恢复点由“完成待冻结”改为“返修完成已冻结”；核心命令中的资产数量改为每个目录可独立复现的 `find <dir> -type f | wc -l`，不用一条 `ls ... | wc -l` 伪装三个计数。

## 冻结

- 只改原三文档，行数仍各 <=150，`git diff --check`，tip 以 `[READY]` 开头，worktree 干净。
- 其余禁区沿用原派单，不生成资产、不改 Dart/YAML/pubspec。
