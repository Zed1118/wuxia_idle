# 二阶段 G0 推荐方案关闭审计（2026-08-24）

## 授权与边界

- 用户授权：当前 Codex 会话明确回复“按推荐方案执行 G0”。
- 基线：Batch8 READY `9ea75869312d69ebe56cc1eb8af28945e95a4854`。
- 本批性质：决策登记和长期文档同步；不等于 M2/M5/M6 生产实现完成。
- 旧证据包：`phase2_g0_decision_packet_2026-08-23.md` 保留 G0 前事实与选项，当前状态转由 decision registry 权威记录。

## 决议摘要

- 本批所称 11 项产品语义 = replay 1 项、`MAINLINE-RUN-01` 的锁人/换装/伤势 3 个维度、听剑占用/成长对象 2 项、心魔惩罚/AI 2 项、解锁/生态/断魂庄 bot 3 项；registry 以 9 个 ID 表达，其中 run 父项合并承载 3 个维度。
- 主线 replay 选 C；连续 run 为锁人 A、换装 B、伤势中断 B。
- 听剑占用选 A，与闭关、远征、断魂庄、疗伤均互斥；成长对象选 B（主修招式熟练度），比例与 cap 仍调优。
- 心魔失败惩罚选 B；七心魔 AI 选 C，先补四列矩阵再逐名冻结。
- 渐进解锁选 C；生态选 B；断魂庄前台 bot 选 B。
- 五项旧否继续不重开；失败原因诊断只部分放开事实性展示。
- 二十项调优只授权生成候选，生产值仍需完整证据 Gate。

## 实现漂移与后续任务

- 当前心魔生产路径仍扣主修修炼度 10%；M5 必须独立迁移并跑失败惩罚、突破、重试和报告回归。
- 七心魔继续使用现有 AI，直到矩阵逐名冻结。
- 未签的模式解锁 gate 和剩余逐关生态保持现状。
- 其余产品合同按依赖拆入 M2/M5/M6，必须在独立 worktree 实现和验证。

## 验证记录

- 已验证内容 tip：`34308c7c81e79ce11ffa7d09e171890070fcfade`；后续 READY 为空提交封签，不改变已验证树。

- `ruby -ryaml` 解析两份 registry：通过；decision ID 49 个且无重复，活动 `proposed` / `proposed_reopen` 为 0。
- `TUNE-*` prefix 计数：20；统一授权锚点 `applies_to_count: 20`、`candidate_generation_authorized: true`、`production_change_authorized: false`，完整覆盖。
- 11 项产品语义按上述组成逐项核对；6 个 reopen 为 5 个 `not_reopened` + 1 个 `partially_reopened`；rejected registry 对应 7 条历史记录均保留并追加处置。
- 长期文档搜索无活动 `blocked_pending_user`、`二阶段待决索引` 或“不得在 G0 前”陈述；心魔生产漂移在 GDD、PROGRESS 与本审计中显式登记。
- `flutter test --no-pub --no-test-assets test/data/truth_source_guard_test.dart`：9/9 通过。首次运行前新 worktree 缺 `.dart_tool` 与被忽略的 Isar 生成物，先按 lockfile 执行 `flutter pub get --enforce-lockfile` 和 `dart run build_runner build`，未改变 tracked 源码。
- `git diff --check`：通过；变更文件不含 `lib/`、`data/`、`test/` 或 UI。
- Codex 独立审查在补齐 deferred 用户签字边界后为 P0/P1/P2 = 0/0/0；Pi + DeepSeek V4 Flash 复核为 P0/P1 = 0/0，提出的可消除 P2（11 项组成与调优覆盖证据）已在本审计补齐。
- Qoder + Qwen3.8-Max 首轮复核为 P0/P1/P2 = 0/1/3：唯一 P1 是把 `REOPEN-LOADOUT-PLAN-01=A` 与 `MAINLINE-RUN-01/B` 的活动快照混写，已拆成“一套持久装配”与“独立 run 快照决议”；两项文案 P2（历史句、断魂庄措辞）已修。增量复核为 P0/P1 = 0/0；其余非阻断 P2 中，GDD 历史原句已与基线逐字核对并恢复原设计源链接，交叉引用键已对齐既有 `related_decision` 体例，PROGRESS 当前 119 行与 G0 前基线相同且本批不再净增行数。
