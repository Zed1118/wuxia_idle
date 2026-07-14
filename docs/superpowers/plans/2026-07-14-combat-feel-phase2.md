# 战斗爽感二期(玩法评估 §十三 #2)· 切片 plan(已拍板:2026-07-14 用户「按推荐」4 项全过)

> 实装执行:拍板后按切片走 superpowers:subagent-driven-development 或 executing-plans,切片内再展开 TDD 逐步;本文件是拍板用切片案,不含逐步代码。

- **目标**:首通战斗「看得见的爽感」三件套——首通脚本化展示帧 + 技能伤害占比调参 + battleUlt/battleChargeStart 专属 SFX;顺带收口 backlog §七「转用素材听感复核」、§九「节奏真机校值」两个既有开放项。
- **归属**:玩法评估 §十三 #2(`docs/spec/playability_phase2_backlog.md:198`);方向源 `docs/audit/self_review_2026-07-09.md`;延续第五阶段(战斗体验)轴。
- **分支**:`feat/combat-feel-phase2`(基 main `e727322d`)
- **基线(2026-07-14 本会话核对)**:analyze 0(现跑 4.6s);全量 3949 pass(上会话主 checkout 实测,快照);技能伤害占比 38.4% / 普攻 61.6%(07-09 tempo 诊断);SFX 借用态核实 `lib/shared/audio/dedicated_audio_assets.dart:29-42`(battleUlt←realmAdvance 目标 800-1600ms / battleChargeStart←defeat 目标 500-1200ms),`assets/audio/sfx/battleUlt.mp3`、`battleChargeStart.mp3` 文件已在(内容为借用)。
- **验收标准**:analyze 0;format 0 changed;targeted+全量绿;tempo 诊断新旧对比报告落 `test/tools/output/`;战斗表现改动过 1280×720/1440×900 视觉 smoke + 真机 `-d macos` 手感;§8.2 四证据齐。

## 硬约束(实装期逐条守)

- 爽感只走表现层,不改伤害公式/不数值膨胀(GDD §5.1/§5.4);T2 是「占比重分配」不是「总伤抬升」,软红线不进百万。
- T2 属 balance 轴:先 Phase 0.5 诊断再改数,commit 前缀 `[balance]`,招式倍率全局 ≤8000;警惕单维度调参分布不变坑(memory `feedback_balance_buff_singledim_no_effect`)。
- 展示帧只动播放/表现层(BattlePlaybackController + overlay),不碰 strategy/Notifier 结算:Phase 0 必过「Strategy immutable vs UI tick」wiring 维度 grep;不破 seed 重放确定性(不涉 BattleReplayRecord 结构)。
- SFX 按 enum.name 命名放 `assets/audio/sfx/`,同步 `dedicated_audio_assets.dart` 状态表;skills.yaml 若新增字段用 camelCase(CLAUDE §4 例外)。

## 待拍板项(4 个,均附推荐)

| # | 决策 | 推荐 | 理由 |
|---|---|---|---|
| 1 | 技能占比目标区间 | **45%-50%**(现 38.4%) | 技能成为可感的主导时刻、普攻仍是节奏底;>55% 恐反转成「普攻无意义」 |
| 2 | 展示帧触发范围 | **仅首通 + 不阻塞出手**(hold 只加开局亮相/首技慢镜/Boss 起手三拍) | 挂机重复战斗不能每场慢镜;守「即拖即放立即出手」主旋律 |
| 3 | SFX 素材产线时点 | **T0 后立刻发 Suno prompt**,用户生成+听选与 T1/T2 并行 | 素材有用户环节(生成+听选),前置发单不阻塞代码切片 |
| 4 | 实施顺序 | **T0→T1→T2→T4 同批推进,T3 素材到位后插入** | T4 真机校值与 T1 真机手感同一 session 一次看完 |

## T2 Phase 0.5 探针证据(2026-07-14 实测,20 seed × 30 关 × 2 profile)

| 探针 | 改动 | 技能占比 | 结论 |
|---|---|---|---|
| 基线 | — | 39.9%(动作行 5.6) | 本会话现跑,与 07-09 记录一致 |
| 1 单发伤害 | auto_skill_power 0.75→1.0 | 40.7%(+0.8pp) | 证伪:占比由出手次数主导非单发 |
| 2 首发时机 | opening_cd 1→0 | 撞 ratchet 红(stage_01_05 动作行 6.4→5.2 <6) | 证伪:提前首发=技能提前收尾 |
| 3 气经济 | opening_qi 40→80 | 39.9%(不动) | 证伪:气不是绑定约束 |
| cap A/B | 战中 CD 上限 2 vs 0(试加新 key) | 双跑全等 47.1% | 死配置,整片撤除(代码+key+测) |
| 4 战斗时长 | enemy_hp 2.4→3.2 / boss 1.35→1.6 | **49.7%**(动作行 6.6) | 唯一强杠杆 confirmed |
| 校准终值 | **2.4→3.0 / 1.35→1.5** | **47.1%**(动作行 6.3 / 16.2s) | 落带中部,普攻 52.9% 仍是节奏底 |

说明:07-09「不建议硬抬 HP」针对的是「发生得太少」观感(已由 T1 展示帧承接);45-50% 目标经四轴探针证明只有时长轴可达,校准幅度克制(+25%);ratchet / solo Ch1-6 / 首30min 回归全绿,enemy HP clamp ≤ bossHpMax 红线在位,伤害公式零改动。

## 任务切片

- [x] **T0 Phase 0 grep(~20min)**:六维 + 战斗 wiring 第七维。重点:`lib/features/battle/presentation/battle_playback_controller.dart` tick/advance 播放路径;首通 flag 注入链(`lib/features/battle/domain/auto_play_mode.dart:25` isFirstClear 既有);`battle_screen_config.dart` BattleScreenPlaybackConfig 扩展点;可复用 overlay 清单(hero_camera_overlay / ultimate_caption_overlay / impact_glyph_overlay / countdown_ring / screen_flash / victory_ceremony);`git worktree list` + branch 查在途为空。
- [x] **T1 首通脚本化展示帧(纯表现层)**(commit `af66ea93`:director 12 测 + BattleScreen 集成 5 测 + 受影响范围 243 绿;视觉 smoke 与 T4 同批):四拍 = 开局亮相 / 首技慢镜 / Boss 蓄力提示强化 / 破招题字强化(后两拍基于既有 countdown_ring + battleInterrupt 题字做首通强化)。新建 `lib/features/battle/presentation/first_clear_showcase.dart`(编排配置+节拍状态机,复用既有 overlay),接线 battle_playback_controller;测试 `test/features/battle/presentation/first_clear_showcase_test.dart`(widget)+ 播放控制单测。验证:targeted 绿 + `tools/visual_capture` 双分辨率 + 真机手感。
- [x] **T2 技能伤害占比调参(balance 轴)**(终值 readable_first_clear 3.0/1.5 → 47.1%,探针证据见上表,[balance] commit):Phase 0.5 三轮(最廉探针→诊断 print(git diff 撤净)→三值校准),基准工具 `test/tools/readable_first_clear_tempo_diagnostic_test.dart` + `test/tools/balance_simulator_test.dart`;确认真实杠杆(倍率 vs CD vs 产耗气)后改 `data/skills.yaml` / `data/numbers.yaml`;重跑 tempo 诊断出对比报告;红线守卫测绿(≤8000/软红线)。commit 前缀 `[balance]`。
- [ ] **T3 SFX 专属化(收口 §七听感复核)**:Suno prompt 两条(battleUlt 800-1600ms 大招爆发 / battleChargeStart 500-1200ms 负向预警)→ 用户生成+听选 → 覆盖落位 `assets/audio/sfx/battleUlt.mp3`、`battleChargeStart.mp3` → `dedicated_audio_assets.dart` readiness 翻 `finalAsset` → 守卫测同步(`test/shared/audio/dedicated_audio_assets_test.dart` + `audio_assets_test.dart`)。
- [ ] **T4 节奏真机校值(收口 §九)**:真机常速战斗看手感,调定 `data/numbers.yaml` 三值——`action_interval_ms=1000`(:1587)/ `key_moment_hold_ms=400`(:1604)/ `damage_popup_ms=1000`(:1584;backlog §九 旧口径 700 已 drift,以现值为准)——纯配置 + `lib/data/numbers_config.dart:1823` AnimationNumbers.defaults 同步。
- [ ] **T5 门禁+收尾**:build_runner / analyze / format / targeted / 全量;PROGRESS 登记;backlog §十三 #2(+§七/§九 对应项)勾账;PR + §8.2 Gate 四证据。

## 当前恢复点

- **状态**:T0/T1/T2 完成(分支 `feat/combat-feel-phase2` 基 `e727322d`);T3 prompts 已交付,等用户 Suno 生成+听选;T4 视觉 smoke 本会话做,手感终调等用户真机;T5 批末。
- **最后完成**:T2 [balance] 校准(占比 47.1%)+ Phase 0.5 探针记录上表。
- **已跑验证**:analyze 0;tempo 诊断(含 ratchet)绿;solo Ch1-6 + 首30min 回归绿;T1 相关 243 测绿。
- **阻塞项**:T3 素材落位(用户环节);T4 手感终调(用户真机)。
