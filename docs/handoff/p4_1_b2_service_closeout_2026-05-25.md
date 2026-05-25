# 会话 closeout · 2026-05-25 P4.1 §12.2 帮派门派 B2 service + trigger

> 体量 ≤80 行 · Mac+Opus xhigh ~1h · 接续 B1 schema(commit `ac6b523`)
> 范围:2 new + 3 modified = 5 file · `feat/p4_1_sect_management_b2_service` branch
> 2 commit pushed(`6ecc754` B2 + `053aa46` PROGRESS)· 0 analyze · 1458 测全过 / 0 regression

## TL;DR

P4.1 4-batch 拆分第 2 批 service+trigger 全闭环:`SectMemberService`(recruit/promoteRank/dismiss · caller 持锁)+ `TerritoryService`(claim/release/availableForClaim/ownerOf)+ sect_providers 扩 7 项(2 Service Provider + 3 Query + 2 Mutation Notifier)+ Q7 B mission hook 占位 + AscendService sect.founderId rewire hook + spec 多处修正(命名 + 范围 OUT)+ reality 收敛 Q6 ABC 全退 1.1 + founder_buff_service 0 改。speed 锚点 ×0.25(spec 估 4-5h · 实测 ~1h xhigh)。**B3 UI / B4 R5+closeout 留下波**。

## 1. 改动一览

| 文件 | 改动 | 行数 |
|---|---|---|
| `lib/features/sect/application/sect_member_service.dart` | 新 SectMemberService(recruit/promoteRank/dismiss/listMembers/memberCapFor)+ 3 result enum | 168 |
| `lib/features/sect/application/territory_service.dart` | 新 TerritoryService(allDefs/defOf/ownerOf/claim/release/availableForClaim/territoryCapFor)+ 2 result enum + SectMemberRecruitApplier typedef | 140 |
| `lib/features/sect/application/sect_providers.dart` | 扩 7 provider/notifier(sectMember/territoryService Provider · sectMembers/sectMemberCount/availableTerritories Query · SectMemberMutation/TerritoryMutation AsyncNotifier · ResolveSectEventNotifier 加 Q7 B mission hook + _maybeRecruitMissionCandidate helper)+ 5 import | +210 |
| `lib/features/ascension/application/ascend_service.dart` | performAscend step 7 后加 sect.founderId rewire hook(founderIdEqualTo + caller writeTxn 内 put)+ 1 import | +13 |
| `docs/spec/p4_1_sect_management_spec_2026-05-25.md` | §1+§3+§5+§8+§9 五段修正(命名 / 范围 OUT / Trigger Hook / B2 表 / 不变量)· 149 行 ≤150 | ±20 |

## 2. 关键设计决议(对 B1 spec 草案修正)

- **Q6 A encounter recruit 退 1.1**:reality 扩 EncounterDef `affectsSectMembership` schema + candidate pool 生成路径 + UI 弹窗超 B2 范围
- **Q6 B stage_boss 招降退 1.1**:stages.yaml 无 recruitable / StageDef 无 isStageBoss / BattleResolutionService 无 hook
- **Q7 B 落 B2 作 1.1 预埋**:ResolveSectEventNotifier outcome=win + event.type=mission → 50% rng `missionRecruitProb` → SaveData.recruitedDiscipleIds 池首未入派弟子招入。Demo 无 mission trigger(SectEventService.checkAndTrigger 单 tournament 分支),1.1 加 mission event 触发后 0 改本端
- **founder_buff_service 0 改**:reality P1.1 红线测族基于 isFounder 不基于 isInSect。Demo player+disciples 默认 isInSect=false,加 `!c.isInSect` early return 会破 P1.1 R5 现有红线。作用域真扩留 1.1(配 Demo 初始化改 player+disciples 自动入派 + P1.2 跨派系 playerSectId 真比较)
- **provider 体例修正**:spec §3 原写「沿 founder_buff_service.dart provider 体例」实为 @riverpod codegen,本批沿 sect_providers.dart manual `Provider((ref) =>) + AsyncNotifierProvider` 体例(SectEventService 同模式)
- **命名修正**:spec §3 `BattleResultService` → `BattleResolutionService`(reality 类名)· §5 `SectEventService.resolveMission` → `ResolveSectEventNotifier.resolve` 内 mission 分支注入(reality SectEventService 单 resolve 方法不分 type)
- **AscendService rewire 设计**:promotedDiscipleId != null 分支内 founderIdEqualTo 查询 sect → put 新 founderId(caller writeTxn 内 · 沿 step 7 体例)。member 关系不动(旧 member.sectId 自然挂新 founder)。单 sect Demo 假设

## 3. 不变量沿用

- §5.4 红线不动 · §5.3 三系锁死(sectRank 三阶 ≠ 修炼七阶) · §5.5 在线=离线 · §5.1 反留存
- BattleStrategy / DamageCalculator / founder_buff_service / derived_stats 0 改 · §6 公式不动
- doc 体量:本 closeout 80 行内 / spec 149≤150 / PROGRESS 89≤100(B1 段并入 B2 净增长 0 行)
- 不动 GDD.md / CLAUDE.md / numbers.yaml(B1 已落)/ data_schema.md / IDS_REGISTRY.md / yaml 数据层

## 4. 挂账事项(全留 1.1 · spec §1 范围 OUT 已对齐)

- **Q6 A encounter recruit**:扩 EncounterDef + candidate pool + UI 弹窗
- **Q6 B stage_boss 招降**:扩 stages.yaml recruitable + StageDef + BattleResolutionService hook
- **Q4 真 stage_boss territory 占领 trigger**:battle hook + ownership 切换
- **Q5 sectRank 自动升迁规则**:Demo 手动升,自动规则细化
- **多代 sect 传递**:本 task 加 founderId rewire hook · 但 member 跨代不验证
- **founder_buff_service 作用域真扩**:配 Demo 初始化改 + P1.2 跨派系 playerSectId 真比较
- **member 招收 narrative ~30 条**:B3 UI 落地后写 1.1
- **P1.2 跨派系 wire**:留 P1.2 完整落地后

## 5. memory 影响

- 无新增 memory(本批沿 spec 直推 · 决策证据已在 spec / closeout doc)
- 沿用:`feedback_phase0_grep_two_axes`(B2 Phase 0 6 维 grep 发现 Q6 B/Q6 A 不一致 + provider 体例错引 + 命名错 → 退 1.1 + spec 修正,避免实装时撞墙)/ `feedback_opus_xhigh_interactive_duration`(B2 实测 ×0.25 锚点 · service+trigger 类 task 在 spec 已 reality verify 前提下加速到 B1 schema-only 同档)/ `feedback_phase05_diagnose_before_solve`(reality 探针先 grep schema 状态,3 个 trigger 真因证伪不一一直上实装)

## 6. 下波(用户选)

| # | 候选 | 模型 | 时长 |
|---|---|---|---|
| 1 | PR squash → main 后起 B3 UI | — / xhigh | ~5min + 1.5-2.5h |
| 2 | 直接接 B3 UI 不 merge(branch overlay)| xhigh | 1.5-2.5h |
| 3 | nightshift Tier 2/3 改进 | high/xhigh | 1-2h / 3-4h |
| 4 | 清 10 老 feature/fix 残留 branch | high | ~10min |

**建议**:PR squash merge → main 后起新会话 B3 UI(沿 B1 体例 · 三段式 + 12-15 UiStrings + main_menu 第 18 入口 · 新会话上下文清)。

---

**P4.1 B2 service + trigger 闭环 ✅** · 2 new + 3 modified file · 2 commit pushed origin · spec 估 4-5h · 实测 ~1h xhigh(×0.25 锚)
