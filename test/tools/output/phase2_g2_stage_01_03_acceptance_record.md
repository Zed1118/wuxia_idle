# G2 `stage_01_03` 黑风岭验收记录

- stage: `stage_01_03` / 黑风岭
- overall: `8/8 PASS`
- candidate commit: `811256300fa1b9af72bda6cbbc2e9df9257d9c5f`
- candidate source: `test/fixtures/phase2/combat/ch1_candidate`
- generated_at: `2026-08-24T20:45:36+0800`
- boundary: 怪潮参数继续保持 `TUNING/candidate`，本记录不把候选值升级为冻结值；第 5 项复用既有生产 `stage_01_05`，未迁 catalog、未扩大章节范围。

## Gate 结论

| gate | status | 可定位证据 | 结论 |
|---|---|---|---|
| `g2-01-continuous-movement-attack` | `PASS` | `test/features/mainline/application/phase0a_mainline_g2_production_acceptance_test.dart:68`；最终 G2 套件 `94/94 PASS` | 真实 production host 以固定 tick 连续提交移动+普攻，断言命令与落地事件均非零并在 tick 上限前获胜。当前 Profile 六轮有效矩阵均有 ≥8622 sampled frames。 |
| `g2-02-continuous-clear-35-45` | `PASS` | 同上 `:68-115`；`phase0a_mainline_production_encounter_factory_test.dart:140` | `stage_01_03` 连续清除 40 个唯一敌人，峰值 active=12，符合总量 35–45。 |
| `g2-03-active-threat-8-16` | `PASS` | `visual-captures-81125630/1280x720/high-density.jpeg`（SHA256 `5dbb2390…5323`，12 敌）；`1440x900/high-density.jpeg`（`57c5c970…0da6`，8 敌）；`phase0a_battle_screen_test.dart` 27/27 | 双视口均落在 8–16 active；普通敌人姓名/满血条去重，人物轮廓、落地墨印和伤害数字可读。护法威胁标签回归由 `phase0a_mechanics_presentation_test.dart` 3/3 固化。 |
| `g2-04-defense-options` | `PASS` | manual run `g2-manual-production-entry-81125630-20260824T123000Z` 的 `defense-e-shield.jpeg`（`1366f198…869a`）、`defense-f-parry.jpeg`（`18667a31…e08`）、`defense-z-dodge.jpeg`（`a10c4812…f9d1`）；防御纵切联合 23/23 | 真实入口 E 显示吸收 1800，F 进入冷却，Z 显示闪避/位移残影；自动直证盾吸收、招架免伤并结算有界反击、闪避位移和无敌分支。F 截图只证明输入被接受及冷却，反击语义以生产自动测试为直接证据。 |
| `g2-05-learnable-boss` | `PASS` | 同一 manual run 的 `stage-01-05-boss-charge-high-health.jpeg`（`fe800beb…4e31`）、`stage-01-05-boss-after-r.jpeg`（`fe83ce59…a842`）、`stage-01-05-victory-settlement.jpeg`（`a4c5db55…627e`）；`phase0a_charge_production_wiring_test.dart:125,396` 6/6；`wave_b_drop_skill_wiring_test.dart:234` | 真实入口可见“蓄力可破”，R 后出现击破并完成胜利结算；生产 e2e 直证 `skill_xie_yu_chuan_lian` 蓄力、破招事件、charging 清除、踉跄>0、CD 写入。首通钩子直证掉落同招真解、解锁、可装配并进入 availableSkills。视觉 seed 输出过高导致 R 直接击杀，截图未单独驻留踉跄帧，状态证据由 production e2e 补足。 |
| `g2-06-victory-next-stage` | `PASS` | `phase0a_mainline_g2_production_acceptance_test.dart:108-115`；`mainline_progress_service_test.dart:105`；manual run 的胜利结算与 `stage-01-05-post-victory-stage-list.jpeg`（`cee74d32…9730`） | `stage_01_03` production settlement 精确返回 `stage_01_04`，进度服务断言只解锁该关；真实入口验证胜利结算及返回选关无阻塞。人工 visual seed 预先通关 01_01–01_04，故不把该截图冒充“首次解锁”直证。 |
| `g2-07-manual-auto-headless-parity` | `PASS` | `phase0a_mainline_g2_production_acceptance_test.dart:117-160`，seed=`20260824`；最终 G2 套件日志 | 逻辑 run ID：`g2-parity-manual-20260824`、`g2-parity-auto-20260824`、`g2-parity-headless-20260824`。三路使用同一 production mapping、fixed delta、steady-guard policy；ticks、事件序列、outcome、final state 逐值相等。允许差异仅为输入/调度入口及前台渲染、音画和墙钟采样，不允许 reducer、事件语义、结算或奖励差异。真实 UI 补充 run ID 为 `g2-manual-production-entry-81125630-20260824T123000Z`。 |
| `g2-08-dual-viewport-performance-ink` | `PASS` | 1280 正式根 `exclusive-81125630-1280x720-20260824T121137Z`；1440 完整复测根 `exclusive-recheck-81125630-1440x900-20260824T122231Z`；上述双视口截图 | 1280 三轮：frames 8640/8622/8637，p99 2.612/3.921/3.239ms，severe 0/1/1。1440 完整复测三轮：8641/8640/8640，p99 2.612/2.959/3.029ms，severe 0/0/0。六轮均 DPR=2、GC telemetry collected、RSS 有首/峰/尾值，warmup/sample/cooldown=12/60/30s，满足 frames≥3000、p99<16.6ms、severe≤1。 |

## 构建与校验和

- commit: `811256300fa1b9af72bda6cbbc2e9df9257d9c5f`
- Profile AOT payload: `build/macos/Build/Products/Profile/wuxia_idle.app/Contents/Frameworks/App.framework/App`，SHA256 `f3878ddda6e8f456fd2f4287e327f24d39df93cce57fe7a77fd493e0ec4ec314`
- Profile launcher: `build/macos/Build/Products/Profile/wuxia_idle.app/Contents/MacOS/wuxia_idle`，SHA256 `dbb2581e4ce05289ed54eba1db81c5d1e2819315558e21f36ff8a9535a8bdcda`
- fixture aggregate `data/combat`: SHA256 `ce0170945cd11b1475b274707a7d284344ac2099a3bdd6a7f0844a750450c093`

## 性能原始证据

- `1280x720` 三轮根：`/Users/a10506/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/tmp/g2_black_ridge_formal_current/exclusive-81125630-1280x720-20260824T121137Z`
- `1440x900` 首组三轮根：`/Users/a10506/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/tmp/g2_black_ridge_formal_current/exclusive-81125630-1440x900-20260824T121703Z`
- `1440x900` 完整复测三轮根：`/Users/a10506/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/tmp/g2_black_ridge_formal_current/exclusive-recheck-81125630-1440x900-20260824T122231Z`
- 每轮目录均含 `manifest.json`、`frames.jsonl`、`memory_gc.jsonl`、`run.log`、`summary.json`。
- RSS（首→尾，峰值）：1280 为 273727488→284868608（319619072）、295223296→286408704（337903616）、277823488→315539456（326565888）；1440 完整复测为 273563648→285229056（327057408）、273530880→300449792（333922304）、273465344→292487168（332840960）。

## 人工与视觉原始证据

- 高密度根：`/Users/a10506/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/tmp/g2_black_ridge_formal_current/visual-captures-81125630`
- 真实入口根：`/Users/a10506/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/tmp/g2_black_ridge_formal_current/manual-flow-81125630/g2-manual-production-entry-81125630-20260824T123000Z`
- 真实入口事件语义：E=`shield absorbed`，F=`parry accepted/cooldown`，Z=`dodge/invulnerable movement`；Boss=`BossChargeStarted → BossChargeInterrupted → stagger/cooldown`；结算=`victory → manual drop → progress routing`。瞬时反击、踉跄和首次解锁分别由上述 production 自动测试提供状态直证，不从单帧截图反推。

## 最终候选验证

- G2 定向套件：`94/94 PASS`。
- `flutter analyze --no-pub lib test tool`：`0 issues`。
- `flutter test --no-pub --file-reporter expanded:/tmp/phase2-g2-full-test-81125630-expanded.log`：`5249/5249 PASS`，日志 `/tmp/phase2-g2-full-test-81125630-expanded.log`。
- `git diff --check`：通过。

## 已披露残余风险

- `1440x900` 首组三轮为 2/3 PASS：r1 虽 p99=11.251ms，但 severe streak=2，原始失败证据保留在首组根目录；随后按同参数完整重跑三轮并 3/3 PASS。该偶发尖峰不隐去，后续性能回归继续观察。
- manual visual seed 在运行前已有 01_01–01_04 通关状态，无法提供“从未解锁到新解锁”的截图；该状态迁移由 production settlement + progress service 直接测试覆盖。
- 本轮不冻结怪潮候选数值，不扩大到 M3/M4、其他章节、武器或生态。
