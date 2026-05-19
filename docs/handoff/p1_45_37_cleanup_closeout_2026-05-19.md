# P1 #45 全销账 + #37 部分销账 cleanup closeout · 2026-05-19

> Mac + Opus 4.7 主对话续推进(2026-05-19 下午,~45min 实际执行),起自 nightshift 2026-05-19 全程 closeout (HEAD `2a093c0`) 之后,3 commit 连续销账 P1 挂账。终态 HEAD `3a1315e`。

## §1 起手会话状态

- HEAD `2a093c0`(nightshift 2026-05-19 全程 closeout 后)
- 测试 1111 pass + 1 skip + analyze 0 issues
- PROGRESS.md 79 行(< 80 目标)
- 剩余 P1 挂账:#37 / #43 / #44 / #45(4 项)
- 用户拍板路径:候选 ① unlockedCodexCount 接 chip → ② T07/T08 死代码删除 → ③ T03 yu_zhong_qiao_men 挂回(连贯 3 项续推进同子系统 P1 收口)

## §2 3 commit 一览

| commit | 任务 | 文件改动 | +/- lines |
|---|---|---|---|
| `102d639` | T08 unlockedCodexCount 接 BaikeScreen chip 销账 | 3 | +30/-8 |
| `f8dfd19` | T07/T08 4 项死代码销账(1 字段 + 3 provider) | 6 | +6/-63 |
| `3a1315e` | #37 yu_zhong_qiao_men 挂回(rain×inn fortuneEvent) | 4 (含 rename) | +31/-7 |

3 commit 已 push origin/main,工作树干净。

## §3 commit 细节

### §3.1 `102d639` chip 接 provider(~10min sonnet)

**改动**:
- `lib/features/codex/presentation/codex_tab.dart`:`_CodexListView` 从 `StatelessWidget` → `ConsumerWidget`,chip 数据源走 `unlockedCodexCountProvider.value ?? step.clamp(0, 8)` fallback(原 inline `step.clamp(0, 8)` 移到 provider 层)
- `test/features/codex/presentation/codex_tab_test.dart`:+1 case 验证 provider 单独 override 驱动 chip,mechanic gating 仍走 step
- `PROGRESS.md`:#45 4→3 死 provider,候选列表递补

**踩坑**:Riverpod 3.x `AsyncValue.valueOrNull` 已删,改用 `.value`(T? 类型 getter)。

**测试**:codex_tab_test 19/19 pass,全量 1112 pass + 1 skip + 0 issues。

### §3.2 `f8dfd19` T07/T08 死代码全销账(~20min sonnet)

**reality check 修正(关键决策)**:audit 报告推删 7 项,Phase 0 跨 yaml/test/Phase 5 三维 grep 实测只 4 项真死,**3 项保留率 ~43% 差异**:
- `dropEquipmentDefIds / dropItemDefIds` → stages.yaml 主线全 stage 在用占位(Phase 5 DropService 接)
- `dropSourceTags / acquireSourceTags` → techniques.yaml / equipment.yaml 大量占位
- `quantityOf` → test 4 处在用(audit 漏 grep test/)
- `inheritFrom / enabledInDemo` → audit 已自标 Phase 5 保留

**真删 4 项**:
- T07:`StageDef.narrativeId` @Deprecated(字段定义 + 构造 + fromYaml + stages.yaml 注释 + defs_test 4 处引用 + T33 deprecated test 整段)
- T08:`leftTeamProvider` + `rightTeamProvider`(battle_providers.dart `@riverpod`,helper 0 caller,功能由 battleProvider 覆盖)
- T08:`gameEventServiceProvider`(@riverpod function + rm orphan .g.dart,5 处生产 caller + 16 处 test caller 均直接 `new GameEventService(isar)` 体例稳定,class doc 措辞对齐直接实例化)

**memory 沉淀**:[`feedback_audit_report_phase0_verify`](../../.claude/projects/-Users-a10506/memory/feedback_audit_report_phase0_verify.md) — audit "0 引用候选"必跑 yaml/test/Phase 5 三维 grep。

**测试**:1111 pass + 1 skip + 0 issues(原 1112 减 T33 deleted test)。

### §3.3 `3a1315e` #37 yu_zhong_qiao_men 挂回(~15min sonnet)

**起手 decree**:`p1_37_orphan_decree_2026-05-19.md` 已决议 yu_zhong_qiao_men 强推荐挂回(rain×inn 槽位空缺 / hear_stories→fortune+1 / learn_legend→enlightenment+1)。

**改动**:
- `mv data/events/_archive/yu_zhong_qiao_men.yaml → data/events/`(rename 100% similarity,文案零改动,Mac 端做封档→激活 wire 不写文案)
- `data/encounters.yaml`:+1 条 fortuneEvent(biome inn 45min + weather rain 45min + fortuneRequired 3 + baseProbability 0.4),体例参考 `feng_xue_gu_dian` (snow×inn) 中期 fortuneEvent
- `test/features/encounter/domain/encounter_yaml_test.dart`:红线 44 → 45 + reason 加挂回备注

**GDD 合规**:fortuneEvent 基础 16→17 仍在 GDD §8.4 范围(15-25);红线 fortune+1 不超 §5.4 属性上限(point_per_attribute_max=10)。

**测试**:1111 pass + 1 skip + 0 issues。

## §4 PROGRESS.md 状态变化

| 项目 | 起手 | 终态 |
|---|---|---|
| HEAD | `2a093c0` | `3a1315e` |
| 测试 | 1111 pass + 1 skip | 1111 pass + 1 skip(中间峰值 1112,T33 删后回 1111)|
| analyze | 0 issues | 0 issues |
| 总行数 | 79 | 79(全程守 < 80 目标) |
| P1 剩余挂账 | 4 项(#37/#43/#44/#45)| **3 项**(#37 部分销账 + #43 + #44),#45 整条归档 |

## §5 整体进度推进

| 维度 | 起手 | 终态 |
|---|---|---|
| **Demo** | 100% ✅ | 100% ✅(无变化)|
| **1.0 路线图加权** | ~17%(P0 100% + P1 ~28%)| **~18%**(P0 100% + P1 ~32%)|
| **encounter 总数** | 44 | 45(fortuneEvent 16→17)|

## §6 下波候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| ① | #44 延续典故文案抽 yaml | sonnet + DeepSeek | 4-7h | UiStrings 违反 §5.6,LoreLoader 扩 + GameEventService 改读 yaml |
| ② | #43 高阶占位补齐 21-30 层 | **opus xhigh** + DeepSeek | 5-8h | **Demo 必交付**,18 条 skill + baoWu 掉表 |
| ③ | 美术 PoC + 水墨 LoRA 调研 | opus + 用户主导 | 6-10h | M4 硬门槛,技术选型先讨论 |
| ④ | lao_jing_hui_xiang 拍板 | — | 5-10min | inn 拟合略牵强 vs 继续封档(decree 提示 techniqueInsight 池补充优先级更高)|

## §7 硬约束沿用

- GDD §5.4 数值红线 / §5.6 不硬编码 / §10.2 江湖见闻录永久可查
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / WINDOWS_DEEPSEEK_GUIDE.md / data/narratives/ 文案(DeepSeek 领地)— 本批 yu_zhong_qiao_men.yaml mv 是封档→激活 wire,**文案零改动**算 Mac 决策范围
- 测试断言写约束语义(memory `feedback_red_line_test_semantics`)— 本批 encounter_yaml_test 红线 44→45 是既存写死数字升级,后续如再加 encounter 应考虑语义化重写
- ListView widget test ≥ 7-8 行扩 800x3000 viewport
- isar.writeTxn 测试用 test() 不 testWidgets()
- Riverpod 3.x 用 `.value` 不用 `.valueOrNull`(已删)
- Phase 0 reality check 必含分布矩阵 + audit 报告 0 引用候选三维 grep 验证(memory `feedback_audit_report_phase0_verify` 本会话新沉淀)
- closeout 数字必 grep 实测(memory `feedback_closeout_numbers_grep`)
- Mac git 走代理需 `HTTP_PROXY=""` 前缀(本会话 push 实战经验)

## §8 新沉淀 memory

- [`feedback_audit_report_phase0_verify`](../../.claude/projects/-Users-a10506/memory/feedback_audit_report_phase0_verify.md):audit "0 引用候选"必跑 yaml/test/Phase 5 三维 grep,差异率可达 40%+。配套 MEMORY.md index 已更新。

## §9 closeout

本会话定位:**P1 收口续推进**,清理 #45 + 部分 #37 + 1 新 memory 沉淀。3 commit 同子系统(P1 deadcode/orphan/provider 清理)连贯推进,无技术债遗留。下波 ① / ② 均是大块跨 Mac+DeepSeek 协作任务(4-8h),建议切新会话起 fresh context。
