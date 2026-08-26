# BACKLOG 补给扫描提案（2026-08-26）

## 口径

- 只扫描 `PROGRESS.md`、`docs/audit/`、`docs/spec/` 与 tracked code marker；正向总账以 `BACKLOG.md:9-31` 为准。
- 反向储备 `docs/spec/rejected_task_registry.md:1-120` 已完整读取且可解析；下列提案均未命中其未重开条目。
- 三态只表示 BACKLOG 准入建议，不代表实现、验收、入账或 M0-M9 晋升；红级实现仍须另行授权。
- 同一根因只列一次；旧报告中已被后续生产代码关闭、仅属“可下沉/可优化”或测试守卫文本的命中不入候选。

## 一 · 待拍板

| ID | 一句话提案 | 证据 | 准入判定 |
|---|---|---|---|
| P01 | 决定 M0-M9 权重，建立可回答整体进度的正式口径。 | `PROGRESS.md:15` | **待拍板**：权重属于人类治理决策。 |
| P02 | 决定 POSTURE 接线采用“蓄力仍即时破招、另开姿态窗”还是“统一累计至 14”。 | `docs/spec/phase2_parked_contract_wiring_delta_20260826.md:48-49` | **待拍板**：会改变玩家可见破招规则。 |
| P03 | 决定 TIMELINE 只作用玩家普攻还是覆盖技能，并冻结五类武器归属来源。 | `docs/spec/phase2_parked_contract_wiring_delta_20260826.md:94-95` | **待拍板**：动作时序与装备分类均未冻结。 |
| P04 | 决定 QI profile 是覆盖 `skills.yaml` 收支还是作为基础值叠加，并锁定现有心法/塔/Boss 修正规则。 | `docs/spec/phase2_parked_contract_wiring_delta_20260826.md:139-142` | **待拍板**：否则形成双真相源并改成长/战斗数值。 |
| P05 | 拍定 3-5 人试玩的数据采集口径、范围与招募方式，再派只读导出和汇总工具。 | `docs/spec/2026-08-07-playtest-data-collection-draft.md:1-18,21-39` | **待拍板**：上游已同意试玩，但采集三项仍未定。 |
| P06 | 拍定跨平台中文字体/fallback 与七级语义字阶，再启动全产品字体治理。 | `docs/audit/global_content_visual_audit_2026-07-25.md:270-290` | **待拍板**：涉及玩家可见 UI、字体许可与包体取舍。 |
| P07 | 完成断魂庄 `batch3-probe`，定案三选一命名装备及首通/精英经验、领悟奖励。 | `lib/data/defs/boss_gauntlet_config.dart:38-48` | **待拍板**：当前生产 TODO 明示数值/命名仍为占位。 |

## 二 · 已解锁未做

| ID | 一句话提案 | 证据 | 准入判定 |
|---|---|---|---|
| U01 | 对齐候选目录令牌总和 `[2,4]` 与冻结生产值总和 6 的守卫口径。 | `PROGRESS.md:16` | **已解锁未做**：偏差已定位，冻结值已有来源，不需发明新值。 |
| U02 | 对 A2 的返回、键盘焦点与 semantics 三列失败做独立 triage，并按真实缺陷拆修。 | `docs/audit/phase2_visual_acceptance_a2_20260826.md:61-65,91-94` | **已解锁未做**：原报告明确保留为后续独立 triage。 |
| U03 | 在结算参与者修复后的真实路径重拍 `stage_victory_dialog` 双视口证据。 | `docs/audit/phase2_visual_acceptance_a2_20260826.md:95` | **已解锁未做**：原阻塞已关闭，现具备重拍条件。 |
| U04 | 按生产路径与 patch-id 逐个分类 86 个历史分叉，确认真实孤立集成债。 | `docs/audit/phase2_candidate_branch_worktree_classification_2026-08-26.md:16,27-30` | **已解锁未做**：只读分类方法与停止边界已明确。 |
| U05 | 跑 7/14/30 天跨系统资源经济集成模拟，并核对扫荡手动 N 次经济一致性。 | `docs/audit/long_balance_audit_v2_2026-06-30.md:43-46,54-61` | **已解锁未做**：先做诊断，不自动调值。 |
| U06 | 开 M4 生态/模板/表现生产批：其余五生态、三模板、可读性/LOD/音频聚合与性能工具。 | `docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md:39` | **已解锁未做**：G2 前置已满足；逐批生态审核作为批内 Gate。 |

## 三 · 依赖锁死（附再开条件）

| ID | 一句话提案 | 证据 | 准入判定 / 再开条件 |
|---|---|---|---|
| D01 | 补齐轻功、守城地点详情的真实导航双视口证据。 | `docs/audit/phase2_visual_acceptance_a1_20260826.md:41-45` | **依赖锁死**；拿到主线第六章已通的真实存档后再开。 |
| D02 | 建立轻功 durable 差遣/session/occupancy/offline/report 全链并关闭 automation admission。 | `docs/audit/phase2_m5_light_foot_automation_admission_blocked_2026-08-25.md:5,21-29` | **依赖锁死**；用户授权持久活动/占用模型与 saveVersion，或明确把差遣移出固定门后再开。 |
| D03 | 建立守城 durable 差遣、阵型快照、occupancy/offline/report 全链。 | `docs/audit/phase2_m5_mass_battle_automation_admission_blocked_2026-08-25.md:5,20-25` | **依赖锁死**；用户授权 schema/saveVersion、共享占用与阵型持久快照后再开。 |
| D04 | 为七类内容统一三层奖励的 durable receipt/outbox，证明崩溃下零重零丢。 | `docs/audit/phase2_u09_reward_layers_blocked_2026-08-25.md:5,9-23` | **依赖锁死**；先授权 schema 与跨模式共享 durable owner。 |
| D05 | 增加每角色塔层个人最好成绩的持久模型。 | `docs/audit/phase2_m6_tower_participant_selection_2026-08-25.md:36-40` | **依赖锁死**；用户授权 schema/saveVersion 后再开，禁止以存档级最高层替代。 |
| D06 | 接通听剑成长 claim 的 durable observation、主修熟练度比例与每关 cap。 | `docs/audit/phase2_testonly_classification_20260826.md:18,23` | **依赖锁死**；`MENTOR-INSIGHT-CORE/RATE` 的成长比例、cap 与 durable 发放权威源获授权后再开。 |
| D07 | 关闭 M2 连续下一关与听剑占用的生产协调接缝，或由权威 Gate 明确退役被替代合同。 | `docs/audit/phase2_testonly_classification_20260826.md:16-17,23` | **依赖锁死**；M2 owner 冻结 run/stage/admission/session identity 与听剑占用事务边界后再开。 |
| D08 | 开 M3 五武器普攻、三主修特性、状态账本与防御/Boss 响应生产批。 | `docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md:38` | **依赖锁死**；M2 连续五关 Gate 关闭后再开。 |
| D09 | 把 M7 扩到 105 主线、49 塔、六生态与角色变体的全内容生产验收。 | `docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md:42` | **依赖锁死**；M3/M4 模板与生态冻结后再开。 |
| D10 | 执行 M8 高密度 Mac/Windows、无障碍、旧档、72h 经济与重复奖励兼容矩阵。 | `docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md:43`; `docs/audit/desktop_semantics_2026-07-30.md:115-118` | **依赖锁死**；M7 内容稳定且 Windows 目标机可用后再开。 |
| D11 | 执行 M9 双平台构建、退役路径、文档统一、RC/tag/回滚与发布风险收口。 | `docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md:44` | **依赖锁死**；M2-M8 全关，并另获 merge/push/tag 授权后再开。 |

## 四 · 已拍死，不重提

- 两套持久亲战/差遣 Build preset：来源冲突见 `docs/audit/phase2_g0_decision_packet_2026-08-23.md:136`；否决见 `docs/spec/rejected_task_registry.md:87`。
- 新章节回顾/收藏百科一级入口：来源冲突见 `docs/audit/phase2_g0_decision_packet_2026-08-23.md:494`；否决见 `docs/spec/rejected_task_registry.md:23,85`。
- Boss 技能预兆图标：来源冲突见 `docs/audit/phase2_g0_decision_packet_2026-08-23.md:526`；否决见 `docs/spec/rejected_task_registry.md:24`。
- 建议型失败原因诊断：来源冲突见 `docs/audit/phase2_g0_decision_packet_2026-08-23.md:622`；否决边界见 `docs/spec/rejected_task_registry.md:88`。
- 敌方连环窗口链、敌方集火对称化：spec 已主动排除于 `docs/spec/2026-08-05-phase8-boss-coop-guard-charge-design.md:11`；否决见 `docs/spec/rejected_task_registry.md:32-33`。
- 终局装备目标追踪/材料缺口聚合：spec 已主动排除于 `docs/spec/2026-07-05-material-source-lookup-ui-design.md:45`；否决见 `docs/spec/rejected_task_registry.md:37`。

## 五 · 命中但不入候选

- Phase 8 spec 头仍写“待实装”，但当前 manifest 已守 149 条零 skip，`tower_42/49` 与 `stage_21_05` 均 eligible：`test/support/phase0a_boss_phase_capability_matrix_test.dart:166-199`。
- F1 里程碑装备旧 spec 写“从未实装”，但当前 service 已声明 live 消费与幂等：`lib/features/equipment/application/milestone_equipment_grant_service.dart:10-13`。
- 多存档旧 spec 的 TODO 已被固定三槽生产实现取代：`lib/data/isar_setup.dart:56-57,619-744`。
- `defaultMaxNodesPerBatch` 只写“可下沉”而非必须任务，按准入规则排除：`lib/features/expedition/application/expedition_service.dart:370-372`。
- `.nightshift` 检查语句、测试中“不得含 TODO”的断言、`XXX` 文案占位均不是生产债，不提案。

## 结论

- 建议补给：待拍板 7 条、已解锁未做 6 条、依赖锁死 11 条；协调者应逐条复核最新基线后再入/销账。
- 本报告不改 `BACKLOG.md`、`PROGRESS.md`、`lib/`、`test/`、`data/`，不代拍任何红级决策。
