# 二阶段 M2 Batch13 装配、目标与路由接缝审计（2026-08-24）

## 基线与范围

- 基线：Batch12 READY `81d47f16880b2b9d7a860379cf308cca3f6110e2`。
- R08、R09、R10 文件所有权互不重叠；assembler 汇合点只归 R08，encounter flow/tracker 只归 R09，route selector 为 R10 新文件。
- 本批只交付显式可选的 application/data-validation 合同，不启用 production stage route。

## 预注册风险与控制

- assembler 偷带默认调优：R08 仅透传 exact optional gate，source guard 禁止预算/角色推断与 host 改动。
- objective 双真相源：R09 在配置 objective runtime 时屏蔽旧 survive/director 自动胜利；null 时保持旧语义，玩家死亡始终优先。
- objective 半提交：R09 用 prepared transition 在 flow 其余可失败投影完成后单次 commit；source/lazy iterable/controller 异常不提交 objective progress。
- RNG 过度承诺：当前 resolver/RNG 无 rewind 接口；审计只要求本任务不新增随机消费且保留既有行为，不宣称异常可回退 RNG。
- route fallback：R10 必须让现有 migration resolver 复核 assignment/allowlist/encounterCount/legacyContent shape；migrated 异常不得走 legacy。
- production promotion：生产 YAML、host、mainline mapper、candidate fixtures 全部不在 owned files。

## 验证记录

待 R08 / R09 / R10 READY 后补充来源 commit、外部模型证据、联合/full test 与独立审查结论。
