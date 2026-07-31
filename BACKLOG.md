# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 3 | P2③ Boss 协同窗口 | 设计讨论 | 「敌方协同」新概念,先定范围再动(master spec §四) |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |
| 7 | CLAUDE §12.2 #5 归档行闭关单倍率表述 | no-touch 文档订正 | 1A 经验倍率拆分批后 stale,待版本订正窗口 |
| ~~8~~ | ~~生产 DefaultRng 无种子统一走 rngProvider(#57 遗留)~~ **已销账 2026-07-26** | 生产接线 | 2026-07-22 拍板留议(非阻塞·stage_entry_flow.dart:826/:1040 两处直 new,全生产约 10 位点:tower×2/gauntlet_reward/recruitment/disciple_join/milestone_equipment/onboarding×2 等·2026-07-24 外审 triage 补记)。**2026-07-25 实证代价升级(不再是纯洁癖项)**::826 的裸 rng 一路传到稀有彩头 roll(`battle_resolution` → `drop_service.rollRareBonus`),彩头命中(cycle=1 时 5%+1.5%)即在固定掉落外追加 1 件装备,打翻 `sweep_settlement_test` 的 `equipmentDrops==1` 精确断言 → **CI 约 5-6.5% 跑次无故变红**(PR #55/#64/#72 三次「随机 fail」真身·PR #72 同 commit 重跑绿实证);因是生产 inline `new` 而非 provider,**测试 override 不到**。修法二选一:根因修(改读 rngProvider)/测试侧修(override numbersConfig 关 rare_bonus_drop 或断言改 ≥1)。详 memory `feedback_wuxia_sweep_rare_bonus_flaky_drop_count`。**2026-07-25 CI 红部分销账(取根因修)**:`stage_entry_flow.dart` 两处(胜利/战败结算)已改 `ref.read(rngProvider)`,新增 wiring 测钉契约(注入必中 rng → 掉落 2 件),破坏证红闭环 + 15 跑全绿;**CI 随机红根因已除**。**余下仍开**:约 8 处生产 DefaultRng(tower×2/gauntlet_reward/recruitment/disciple_join/milestone_equipment/onboarding/founder_creation),另 `stage_entry_flow.dart:233` 的 `rng: Random()` 是 `dart:math` 签名(换 provider 需另立 Random 类型注入点,见 memory `feedback_wuxia_rngprovider_vs_dartmath_random`)。**2026-07-26 余下 8 处全部收口 → 本条销账**:Phase 0 实测确认恰好 8 处(`phase2_seed_service` 的 5 处在 `lib/features/debug/` 不算生产)。按调用点能否拿到 `ref` 分两层修——**UI/flow 层 4 处**(`gauntlet_reward_screen:118`/`tower_entry_flow:227,487`/`founder_creation_screen:71`)直接 `ref.read(rngProvider)`;**service 层 4 处**(`recruitment`/`disciple_join`/`milestone_equipment_grant`/`onboarding`)改构造注入 `Rng`(沿 `MilestoneEquipmentGrantService` 既有 `DateTime Function()? now` 注入体例),有 ref 的 4 个构造点(`recruitment_providers`/`recruitment_dialog`/`disciple_join_hook`/`save_select_screen`)传 `ref.read(rngProvider)`,无 ref 的构造点(`ascend_service`/`milestone_grant_hook`/`defaultFounderCreationSeeder`)落构造默认值兜底但**已可注入**(可注入才是本项真目的)。`OnboardingService` 因 `rng ?? DefaultRng()` 非常量表达式去掉 `const`(现查全仓无 `const OnboardingService(...)` 调用点,零破坏面)。新增 `test/shared/utils/rng_provider_wiring_contract_test.dart` 三层契约棘轮防复发。**仍不在本条范围**:`dart:math Random()` 签名的约 15 处(含 `stage_entry_flow.dart:233`)是另一类问题,换 provider 需另立 Random 类型注入点,本次未动 |
| 11 | 既有场景素材的书法题字/印章是否触伪文字红线 | 设计拍板 | 2026-07-25 Ch16 美术批合成验证时发现:`assets/scenes/battle_frontier.png` 右上带书法题字+红印章,`battle_desert.png` 有小红印记(早期 MJ 素材遗留);CLAUDE §8.2/视觉验收规范禁「带伪文字 MJ 素材」。拍板点=是否判定为违红线 → 违则开清查小批(全 assets/scenes 扫一轮 + 重出或去字)。**2026-07-26 全库已扫 · 用户看过真机图后暂不改动 · 条目保持开启**。① **规则真出处**:`docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:47` G5.1「任何 MJ 图里 AI 生成的**假汉字/假英文**必须被遮盖或避开」——针对的是「冒充可读文本」,非一切字形痕迹。② **与既有美术约定冲突**:印章是主动要的母题(`docs/PUBLISHING_ART_PASS_1_0.md:215`「5-8% 暗红印章」、MJ 提示词 `.nightshift/prompts/T03.md:77`「印章作落款」),故拍板需区分**多字题字**与**朱红印章**两类。③ **实测计数**:`battle_*` 19 张中 **5 张带题字**(frontier/dock/escortroad/teahouse/temple)+ 2 张仅印章(drillground/desert);`chapter_*_cover` 16 张中 **3 张带题字**(02/04/06)+ 1 张仅印章(03);`narrative_stage_*` 属同批的 30 张约 8-12 张(**目检估数,未逐张确认**)。④ **时间模式(最关键)**:受影响文件**全部**是 `7月2日 21:17` 那批早期 MJ 产物,**7月18日之后出的 52 张零问题**——问题封闭不会增量。⑤ **可见性实测**:`BoxFit.cover` + 16% scrim 下题字在 1280×720 完全落在可见带内(chrome 只盖 y<92 与 y>540);`frontier` 用在 16 关且右上大字最扎眼,`escortroad` 密排小字最淡。⑥ **证据留档**:`build/visual_acceptance/zh_inscription_ruling_2026-07-25/` 6 张(真机合成图 ×2 / 题字放大 ×2 / 全库 contact sheet ×2,gitignored 随 checkout 存续)。**下次拍板可直接用上述数据,无需重扫** |

## 二 · 已解锁可派

| # | 项 | 域 | 预估 | 依据 |
|---|---|---|---|---|
| ~~4~~ | ~~`damage_popup` 反解析 UiStrings 输出的耦合隐患~~ **已销账 2026-07-25** | battle 表现层 | — | 上游改传纯伤害数字串,分段排版由 `PopupType.critical` 语义驱动;`_parseCriticalDamage`/`_CriticalDamageParts`/整句模板 `UiStrings.criticalDamagePopup` 全删,allowlist 3→2。**建表时的「且无测试拦」定性经实验证伪**:改模板措辞实测 3 条既有测试即红(`damage_popup_test` 2 + `widget_test` 1),真问题是往返本身无谓 + 失配退化成整串套数字样式且红在别处误导诊断。改后新增回归测 + 门禁棘轮双证红留档 |
| 5 | 断魂庄 / 百草岭远征补 audit 路由 | debug 视觉路由 + 视觉验收 | ~1h | 2026-07-31 现查:audit 路由实测只有 `battle_audit_stage`(主线)/`_light_foot_`/`_mass_battle_`/`battle_audit_tower` 四类,断魂庄与远征均不在内 → 其敌立绘**从未进过任何一轮目检**;补路由即补齐 153 关覆盖外最后一块 |
| 6 | 战斗样板复刻批余下 2 分 | battle 表现层验收 | ~40min | R2 98/100 未拿两项:顶栏 Tab/tooltip 键盘走查无直证 + 「渲染器帧 vs 原生窗口截图」方法学局限未前置到交付摘要(PR #107 已合 `cdb370e4`) |
| 7 | B3 立绘融合观感真人拍方向 | battle 表现层数值 | ~20min | 需先看真机实拍图;要调只动 `battleStandeeFusionOpacityAtFull`/明度下沿/上沿三常量,门禁测守边界。附带:登记值精度 ±9、`cliffwaterfall` 仅 boss 用法其取样带可能被立绘右缘侵入(该资产落下沿之下走基线档,当前不影响行为) |
| 8 | 送关旧部立绘白布动势 | 美术返修 | 随批 | 07-30 目检半中项:语义达成(「今早特意换的新布」)但派单要求的「被风吹得笔直/画面里唯一在动的东西」动势缺失 |
| 9 | F2「wait=80 冻结 vs wait=85 濒死」机制未解释 | 视觉验收工具链 | 低优 | 07-30 批只做了证据与可判读判据,底层为何在该窗口跳变未查明;不影响判据可用 |

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- **爬塔二流段 spec**——塔内容扩展另一轴
