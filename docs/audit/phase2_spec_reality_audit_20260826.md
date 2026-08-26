# 二阶段方案 ↔ 生产实况一致性审计（2026-08-26）

## 审计快照与口径

- 审计基线：`0378df73b88f011d4a686e4ec63f1b92f6771330`（短 SHA `0378df73`，本单给定为 `main`）。下表生产证据全部以 `git show/git grep 0378df73` 现取，不以并发工作区替代基线。
- 方案：`/Users/a10506/Desktop/二阶段优化方案.md`；mtime `2026-08-23 16:38:49 +0800`（epoch `1787474329`）；`1568` 行；`107923` bytes。
- 计数单位“断言组”：同一表格数据行、同一规范 bullet/段落内不可独立落地的约束算 1 组；一句中可独立证伪的并列合同拆组；后文对前文的同义复述去重到首次规范行，互相矛盾的复述不去重。
- 纳入：数值/数量、行为必须/不得、字段/schema/config/key、明确生产现状。排除：纯目标感受、理由、工期/owner/并行组织/派单话术。§18–20、§22–24 的过程条目因此不计；其中重复的产品完成条件已归并到 §0–17/§21/附录 A–B。
- 覆盖率：识别 `441` 组可验证硬断言，已对账 `441/441（100%）`；没有漏审的合格章节。结果：`一致 205`、`偏差 52`、`未实装 163`、`无法判定 21`。
- 严重度：`S1`=基线已进 main 且玩家可见；`S2`=基线已进 main 但当前不可见/仅合同或基础设施；`S3`=仅分支；`S4`=文档/注释/方案现状陈述互相矛盾。`无法判定` 不臆测定级，记 `—`。本基线无 S3。

## 偏差、未实装与无法判定清单

“组数”是该行压缩承载的断言组数；原文只做保真节选，完整语义以所列方案行号为准。查无生产闭环者只判 `未实装`/`无法判定`，不计入“一致”。

| # | 方案行号与原文摘录 | 组数 | 基线生产证据（`file:line`） | 判定 | 级别 |
|---:|---|---:|---|---|---|
| 1 | `:40`「当前仅 `radial + caster`」 | 1 | `lib/features/battle/domain/phase0a/combat_geometry.dart:13-20` 已有六种 `GeometryScopeKind` | 偏差（方案现状已过时） | S4 |
| 2 | `:41/:835`「`preserve_cooldowns: false`…重置技能冷却」 | 1 | `lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart:53-59` 默认 HP/气/CD 连续；`test/features/battle/application/phase0a/phase0a_wave_flow_test.dart:560-610` 精确断言 2.1→1.5 | 偏差（方案现状已过时） | S4 |
| 3 | `:43`「指针无效时仍有‘取首名角色’回退」 | 1 | `lib/shared/battle_shared/current_leader_resolver.dart:9-25` 空/悬空均抛错、无回退 | 偏差（方案现状已过时） | S4 |
| 4 | `:49/:360/:839`「当前仍扣主修修炼度」 | 1 | `test/features/inner_demon/application/inner_demon_failure_penalty_test.dart:8-13,128-190` 冻结并断言 progress/layer 不变 | 偏差（方案现状已过时） | S4 |
| 5 | `:114-121`「鼠标左键；`1–4`；`Q` 战术；`R` 绝技；`Space` 闪避；Q/R 完整 `SkillDef`」 | 12 | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:480-510,538-545` 仍为 J、E/F/Z、固定 Q/R、1–6（鼠标持续攻击已接）；`lib/shared/battle_shared/combatant_skill_loadout.dart:3-46` 仍七旧槽 | 偏差 | S1 |
| 6 | `:132-133/:935`「不再从 `cooldownTurns` 换算；YAML 和存档只表达秒」 | 4 | `lib/data/defs/skill_def.dart:45-57,167-209` 秒字段与 `cooldownTurns` 并存且 YAML 强读 turns；`test/features/battle/application/phase0a/phase0a_cooldown_seconds_authority_test.dart:13-50` 仍验证 turns→seconds 迁移关系 | 偏差 | S1 |
| 7 | `:135`「起手锁气、首效扣除；生效前打断/取消退气并进失败冷却」 | 2 | `lib/features/battle/domain/phase0a/action_timeline.dart:1-2` 明示 candidate 且不处理 resource/damage/reducer/presentation | 未实装 | S1 |
| 8 | `:162-207`「生产普攻由装备武器形态装配」及五武器链×三特性 | 18 | `lib/features/battle/domain/phase0a/basic_attack_chain.dart:1-5` 明示 candidate-only、不可执行；`lib/data/defs/equipment_def.dart:7-20,45-96` 无 `weaponForm` | 未实装 | S1 |
| 9 | `:294-320`「姿态统一」及 `timedStatus` 的持续/叠层/tick/换波合同 | 14 | `lib/features/battle/domain/phase0a/posture.dart:1-4` 明示无 production wiring；`lib/features/battle/domain/phase0a/status_effects.dart:1-8` 仅 engine-neutral caller-supplied 定义 | 未实装 | S1 |
| 10 | `:45/:77`「首通随行 0–1 门人…不重复获取」 | 8 | `lib/features/mainline/application/mentor_insight_claim_policy.dart:1-9` 仅纯合同、不拥有 ledger；`test/features/mainline/application/mentor_insight_claim_policy_test.dart:125-138` 证明 guard 非 durable storage | 未实装（无生产 exactly-once 发放闭环） | S1 |
| 11 | `:351-363`「通用/特殊模式失败、一次伤势、部分收益」 | 7 | `lib/shared/battle_shared/failure_policy.dart:1-4,12-42` 仅类型/解析合同，明示无持久化/schema；未见模式宿主统一接线 | 未实装 | S2 |
| 12 | `:371-374`「每角色保存 `1–4/Q/R`、自动战术、亲战/差遣双方案并锁快照」 | 5 | `lib/core/domain/character.dart:98-118` 仍持久化旧七槽；`lib/shared/battle_shared/combatant_skill_loadout.dart:14-46` 仍按旧槽装配 | 未实装 | S1 |
| 13 | `:381`「宗门只有一个‘当值历练’槽」 | 1 | `lib/features/battle/domain/phase0a/activity_participation_request.dart:3-5,32-37` 仅把 occupancy 交给各 caller；无全局当值槽生产合同 | 未实装 | S2 |
| 14 | `:387-393`「离线时间片统一处理…一份统一归来报告」及四个配置名/checkpoint | 8 | `lib/features/main_menu/presentation/main_menu_startup_gate.dart:28-35` 闭关离线与远征分别启动；`lib/features/seclusion/presentation/offline_recap_gate.dart:13-20,75-101` 与 `lib/features/expedition/presentation/expedition_recap_screen.dart:10-17` 为两套报告 | 未实装 | S1 |
| 15 | `:82/:401-404`「105 关胜利结果直接下一关；普通关不强制剧情」 | 3 | `test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart:20-85` 真实连续流只跑 `stage_01_01..05` 且明确不跨第二章；全 105 去剧情另有守卫但连续入口未全量闭环 | 偏差（部分实装） | S1 |
| 16 | `:1025-1026`「第 1 章其余关按…；五关依次为破路/据点/伏击/斩将/斩将」 | 6 | `data/combat/manifest/stage_assignments.yaml:1-14` 仅 `stage_01_03` migrated，其余四关 legacy；`test/data/phase2/ch1_production_catalog_test.dart:115-173` 锁定该单关纵切边界 | 未实装 | S1 |
| 17 | `:1025`「`stage_01_03`…攻击令牌 2–4」 | 1 | `data/combat/encounters/black_wind_ridge.yaml:13-17` 为 2+2+1+1=`6`；`test/data/phase2/ch1_production_catalog_test.dart:177-190` 反向钉死四项 | 偏差 | S1 |
| 18 | `:1025`「攻击令牌 2–4」；`:617/:1534`「近战…2–4」「2–4 近战攻击令牌与远程/冲锋令牌配比」 | 1 | `data/combat/encounters/black_wind_ridge.yaml:13-17` 近战=2、一致于后两处，但总预算=6、违反 `:1025` 的通常语义 | 偏差（方案内部口径歧义） | S4 |
| 19 | `:31/:34`「TUNING…真人试玩定标」「registry 记录原会话依据」 | 2 | `docs/spec/phase2_combat_core_tuning_candidates_20260826.md:5-7,106-111` 明写未替用户决定/仍需拍；`docs/dispatch/phase0a_overhaul/decision_registry.yaml:418-428` 却登记 frozen B；生产 YAML `:3-5`、两测试 `ch1_production_catalog_test.dart:186-190` 与 `ch1_candidate_combat_catalog_test.dart:216-228` 又声称用户拍板；`docs/dispatch/phase2_wiring/T1_token_budget_realign.md:30-45` 记载该说法查无实据 | 偏差（来源链互相矛盾） | S4 |
| 20 | `:413`「七层循环模板：清剿→组合战→伏击/据点→小头目→群涌→生存→Boss」 | 3 | `lib/data/defs/tower_floor_def.dart:11-17,34-35` 生产仍为每层 1–3 敌的旧队伍 schema；`test/features/tower/domain/tower_floor_def_test.dart:120-148` 只守 49 层/Boss 分布 | 偏差 | S1 |
| 21 | `:414/:416/:473`「首通后自动/headless/当值；任意空闲角色」 | 4 | `lib/features/tower/domain/tower_automation_policy.dart:46-50` 仅 direct+bot+headless+sweep；`lib/features/tower/application/tower_automation_admission.dart:68-76` 强制当前掌门 | 偏差 | S1 |
| 22 | `:425/:474-475`「轻功/群战首通后可自动、headless、差遣」 | 6 | `lib/features/light_foot/application/light_foot_participant_service.dart:12-30,61-89` 与 `lib/features/mass_battle/application/mass_battle_participant_service.dart:12-31,60-86` 仅逐次亲战候选/快照，无自动化 policy | 未实装 | S1 |
| 23 | `:461-462/:478`「里程碑首次手动；离线遇未解锁里程碑自动返程」 | 4 | `lib/features/expedition/application/expedition_service.dart:475-546` 节点循环直接 headless fight/结算，未见 milestone manual gate/自动返程分支 | 偏差 | S1 |
| 24 | `:482/:486` typed `AutomationPolicy` 五字段及各模式 unlock key | 5 | `lib/features/tower/domain/tower_automation_policy.dart:46-95`、`lib/features/boss_gauntlet/domain/gauntlet_automation_policy.dart:42-97` 只有两套单模式 allowlist，无统一五字段 policy | 未实装 | S2 |
| 25 | `:509-539` 三层奖励、同表、各模式固定/重复/个人落点 | 4 | `lib/shared/battle_shared/reward_policy.dart:3-24,74-90` 仅 caller-supplied 纯声明与内存 guard，明示 production YAML/事务由 caller 负责 | 未实装（无全模式统一闭环） | S2 |
| 26 | `:536`「首领残页集齐后…自动转换」 | 1 | `lib/features/cultivation/domain/skill_unlock_service.dart:9-11,59-85` 已解锁后直接短路 `none`，没有转换 | 偏差 | S1 |
| 27 | `:580`「未听闻完全隐藏；已听闻未开放显示传闻剪影；开放一次蜡封」 | 4 | `lib/features/jianghu_map/presentation/jianghu_map_screen.dart:52-75` 现为二态 `locked/status`，无 hidden/heard/open 状态 | 未实装 | S1 |
| 28 | `:603-612` 各模式总量/活跃区间及 20%–30% 配置化补兵 | 8 | `data/combat/manifest/stage_assignments.yaml:1-14` 只有 `stage_01_03` 新 encounter；`lib/data/defs/tower_floor_def.dart:11-17,34-35` 塔仍 1–3 敌旧结构 | 未实装 | S1 |
| 29 | `:638-649`「六套…24 个逻辑角色…约 48 个美术变体」及 canonical IDs | 8 | `data/combat/manifest.yaml:1-8` 生产 catalog 仅引用 `archetypes/bandits.yaml`；`data/combat/archetypes/bandits.yaml:2-60` 仅山匪四角色/八变体 | 未实装 | S1 |
| 30 | `:657-664` 六生态的章节/塔地域分配与固定可研究构成 | 7 | `data/combat/manifest/stage_assignments.yaml:1-14` 生产分配只覆盖 Ch1 单关；`data/combat/manifest.yaml:1-8` 无其余生态源 | 未实装 | S1 |
| 31 | `:670-715` 八目标原语组合成七模板及各模板终局行为 | 8 | `lib/features/battle/domain/phase0a/encounter_objective.dart:32-118` 只有原语合同；生产 `data/combat/encounters/black_wind_ridge.yaml:259-304` 仅 `defeat_targets` | 未实装 | S1 |
| 32 | `:721-745`「21 章首轮生产编排」矩阵 | 21 | `data/combat/manifest/stage_assignments.yaml:1-14` 只迁 Ch1 `stage_01_03`；验收记录 `test/tools/output/phase2_g2_stage_01_03_acceptance_record.md:1-8,51-55` 明示未扩大章节范围 | 未实装 | S1 |
| 33 | `:759-806/:1028` 敌头顶层级、Boss 顶条、聚合伤害 6–8 组、屏外≤3、HUD、战后统计 | 13 | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:934-942,1040-1094` 威胁单位仍显示名字+HP；`:1433-1440,1635-1667` 逐事件伤害 popup；未见屏外方向/战后指标闭环 | 偏差 | S1 |
| 34 | `:848-858/:891-927` 11 个领域边界、目录/schema、每战恰一 encounter、legacy 归零 | 13 | `data/combat/manifest.yaml:1-8` 仅单生态/单 encounter source；`data/combat/manifest/stage_assignments.yaml:1-14` 仍 4 个 Ch1 legacy；多模块仍明确 candidate-only（如 `posture.dart:1-4`） | 未实装 | S2 |
| 35 | `:885`「所有入口通过唯一 `CharacterAvailabilityService`」 | 1 | `lib/features/battle/domain/phase0a/activity_participation_request.dart:3-5` 明示由 caller 的 service/policy 负责；基线 `git grep 'class CharacterAvailabilityService' -- lib` 为 0 | 未实装 | S2 |
| 36 | `:931-935` `EquipmentDef.weaponForm`、新六槽字段、旧槽迁移、全消费方读秒 | 9 | `lib/data/defs/equipment_def.dart:7-20,45-96` 无 `weaponForm`；`lib/core/domain/character.dart:98-118` 仍旧槽；`lib/data/defs/skill_def.dart:45-57,167-209` 仍强读 `cooldownTurns` | 未实装 | S2 |
| 37 | `:1434-1440` p99/severe、8/12/16/14/18/24、50/150、双视口×3、headless/RSS/Windows | 7 | `test/tools/output/phase2_g2_stage_01_03_acceptance_record.md:1-8,14-21` 只证明 `stage_01_03` 双视口/12 active；`:51-55` 明示不扩大 M3/M4/其他章节 | 无法判定（其余档位/Windows 无基线证据） | — |
| 38 | `:800-802/:1420-1428` LOD、低特效不改实体/难度及多密度 UI 可读性 | 7 | `test/tools/output/phase2_g2_stage_01_03_acceptance_record.md:15-21` 只记录黑风岭双视口；未见塔14、群战18/24或低特效领域 hash 证据 | 无法判定（已查 `lib/`、`test/` 与 G2 记录） | — |
| 39 | `:338-343/:517`「手动/bot/headless 同 fixed tick、同 hash；同活动同重复掉落表」 | 7 | `test/tools/output/phase2_g2_stage_01_03_acceptance_record.md:20` 只证明该关 manual/auto/headless parity；`lib/features/main_menu/presentation/main_menu_startup_gate.dart:28-35` 仍分流离线系统 | 无法判定（不能外推全模式伤势/奖励） | — |

## 一致项汇总（不逐条展开）

- 一致 `205` 组，章节分布：§0 `2`；§1 `22`；§2 `12`；§3 `3`；§4 `15`；§5 `9`；§6 `8`；§7 `3`；§8 `6`；§9 `37`；§10 `14`；§11 `8`；§12 `11`；§13 `3`；§14 `12`；§15 `1`；§16 `7`；§17 `25`；§21 `7`。附录 A–B 的重复合同已归并到对应正文，不重复计数。
- 代表性已闭环事实只用于校验计数、不展开成清单：105/105 叙事去阻塞与 252-ID manifest、49 层数量、六几何类型、主线掌门 fail-closed、心魔不扣主修、远征全局单 active、断魂庄完整首通后 headless、三层奖励纯合同等。

## 收口

- 非一致 `236` 组 = `偏差 52`（其中 S4 文档矛盾 `7`）+ `未实装 163` + `无法判定 21`；严重度合计 S1 `168`、S2 `40`、S4 `7`、S3 `0`，另有未定级 `21`。
- 本单仅记录事实，没有修改生产代码、配置或测试，也没有为任何偏差自行选择实装方案。
