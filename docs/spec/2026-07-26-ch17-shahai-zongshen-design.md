# Ch17「沙海纵深」章级设计 spec(宗师段第 2 章 · 待拍板)

**日期**:2026-07-26 · **载体**:main 直落(bg 会话·纯文档) · **上游**:`docs/spec/2026-07-24-zongshi-arc-ch16-18-design.md` §8 前瞻
**状态**:**待用户拍板**(§10 六项)。段级六项已于 2026-07-24 冻结,本 spec 只细化 Ch17,不改段级拍板。

---

## 1. Phase 0 实测基线(2026-07-26 主 checkout 现跑 · 禁转抄 · 实装前重核防 drift)

| 项 | 实测值 | 出处 |
|---|---|---|
| 主线规模 | **16 章 80 关** | `data/stages.yaml` mainline 计数 |
| cap | **38**(zongShi·shuLian 熟练) | `numbers.yaml:206` |
| skill 总池 | **255**(215 + encounter 40) | `skill_count_contract_test.dart:12` |
| boss 敌数 | **34** | `stages_boss_enemy_test.dart:39` |
| 图鉴 catalog | **47**(主线 41 + 塔 6) | `boss_memory_providers_test.dart:50` |
| 首通 / 全内容 | **Lv97**(cumExp 3209) / **Lv115** | `progression_release_budget_test.dart:22,49,53` |
| idle_horizon | s1 **45.6 天**,下沿 **45.0** 三档同线 | `progression_idle_horizon_simulation_test.dart:209-212` |
| Ch16 曲线 | HP 53000→56500 / 攻 1850→1920 / 速 340→350 / diffMult 17.0→17.8 / exp 64·66·68·88·108(计 394) | `stages.yaml:3665-3882` |
| mount_deferred 招 | **3**:feng_juan(mainline_drop·lingQiao·t4·3200)/ yang_guan(mainline_drop·yinRou·t6·4000)/ ye_yu(fragment·yinRou·t6·3900) | `skills.yaml` |
| 残页池配平 | **3/3/3 已平**(含 deferred 的 ye_yu——`残页` 配平不排除 mountDeferred) | `wave_b_content_redline_test.dart:162` |
| 「平沙落雁」避撞 | **0 命中**(仅段级 spec 自身提及) | 全仓 grep |

**段级 spec 需订正两处**(本 spec 以实测为准):
1. §6 写「skill 计数 254→256」——实测现值 **255**,Ch17 加 1 门真解后为 **256**。
2. §3 写「fang 变体(敦煌佛窟意象)…Ch17/18 按叙事追加」——实测 `*_shichuan_fang_*` 9 招**早已存在**(`skills.yaml:2231-2340`),`fang`=**佛门防御变体**(`tech_*_shichuan_fang`)非敦煌意象;其中 gangMeng/lingQiao 两组在 stages/towers **零使用**,Ch17 可直接接线,**敌招零新增**。另 §8「同章三灵巧向收获」有误——ye_yu 是 **yinRou**,实为 2 灵巧 + 1 阴柔。

**cap 38→40 = within-tier**:`_releaseCapTier` = `RealmTier.values[(cap-1)~/7]`,38 与 40 同得 index 5 = zongShi。故 **releaseTier 不变**,memory `feedback_wuxia_release_cap_raise_reconcile` 的 cross-tier 全套(三系锁死连动/新阶招暴露)**本章不触发**,只 cap-value 断言需改。cap 40 = 宗师·**圆熟 yuanShu**。

## 2. 章定位

宗师段第 2 章 · **within-tier**(cap 38→40 = 宗师·圆熟)· requiredRealm `zongShi` · 敌层 shuLian→yuanShu 递进 · 三系锁死不变(宗师↔宝物↔失传神功)。
**主题**:承 Ch4 李寒「再往上的那一段,不在剑上,是在另一处」——沙海里剑术不管用,**天地才管用**。这正是宗师段风格词(澄澈/无为/玄妙/化境:人 vs 天地)的落点,也让末 Boss 的**机制窗口**在叙事上成立:不能硬打,要等那个时机 = 顺势而非逞强(守 §5.7 先感受问题再给答案)。

## 3. 五关草案(数值待探针校准 · biome 全复用)

| 关 | id | biome | 侧面 | 流派/层 | Boss | HP / 攻 / 速 |
|---|---|---|---|---|---|---|
| 1 | stage_17_01 | desert 砂丘初程 | 入沙海第一浪·中原步法失效 | lingQiao·shuLian | — | 56800 / 1925 / 352 |
| 2 | stage_17_02 | desert 黑风口 | 沙暴迷路·天地压人 | gangMeng·shuLian | — | 57100 / 1932 / 354 |
| 3 | stage_17_03 | temple 沙埋古城 | 整座城被沙吞掉(非佛窟·避撞 Ch15_03)·守城人不走 | yinRou·jingTong | — | 57400 / 1938 / 356 |
| 4 | stage_17_04 | desert 沙海深处 | 章中 Boss·**破招前置教学** | gangMeng·jingTong | 章中 Boss | 57700 / 1944 / 358 |
| 5 | stage_17_05 | frontier 西凉腹地门前 | 末 Boss·**0.20 单窗口机制教学**·真解 | lingQiao·yuanShu | 末 Boss | **58000** / **1950** / 360 |

- Boss 位 **{4,5}**(沿全段体例)· 17_01 **不配 prevStageId**(跨章引用加载期 StateError)· diffMult **18.0→18.8**(+0.2/关,承 Ch16 末 17.8)· baseExpReward **70/72/74/94/114**(章计 **424**·沿 +6/关轨迹) → 累计 exp 3209 **→ 3633**。
- HP 头寸 56500→**58000**(段级 §2 三章分配中位)、敌攻 1920→**1950**(≤2000 参照内留 Ch18 用尽空间)。
- **敌招零新增**:01/02/05 用既有 `skill_{lingqiao,gangmeng}_shichuan_{basic,skill,ult}`;**03 沙埋古城用 `skill_yinrou_shichuan_fang_*`**(防御变体·「守着一座空城不走」的静),**04 用 `skill_gangmeng_shichuan_fang_*`**(全仓零使用·首次接线)。9 招基础包 + fang 变体足够三章,不写新敌招。

## 4. 末 Boss 机制层(段级拍板 6 · 单窗口 0.20 教学)

- `vulnerability.outOfWindowDamageMult: **0.20**`,比照塔 floor30(`towers.yaml:1300` 同为 0.20)的**宽松位**;`bossPhases` 单相位 `onEnterMechanic: chargeCounter` 开窗,窗口外承伤 20%。
- **单窗口**=只在蓄招期开窗,不做 floor25 的两相位复合(0.12×ward);玩家第一次遇到主线机制型 Boss,给最宽的容错。cycleVulnerability(周目收窄)**本章不配**,留 Ch18 或周目批。
- `chargeSkillId` = 真解(双用 canon:破他的招、学他的招),与 `dropSkillManualId` 同招——`wave_b_content_redline_test:31` 硬断言。
- **17_04 章中 Boss 的定位取决于 §6 拍板**:若走 A 案则配 chargeCounter 作破招前置教学(先学「打断蓄招」,末关再学「只有窗口能打」,两级递进);若走 C 案则同 Ch16_04 走纯 stat 门槛、**不配 bossPhases**(memory:有 bossPhases ⟹ 必须有 charge,否则 readable_tempo 挂)。

## 5. 真解「平沙落雁」`skill_ping_sha_luo_yan`(新写 · 避撞 0)

沿 Ch16「铁马冰河」模板:`lingQiao` · `tier: 6` · `powerMultiplier: **6400**`(≤8000 硬线·敌招 cap 5500 上浮档,同 tie_ma/yang_guan 对齐先例)· `qiDelta -30` · `cooldownTurns **4**`(灵巧向 CD 倾斜,区别于刚猛真解 CD5·照 feng_juan 三层模板)· `powerSkill/single` · `source: mainline_drop` · `visualEffect: geese_over_sand`。
proficiency 灵巧向高半档:`shuLian {damage_pct 0.05}` / `jingTong {damage_pct 0.05, cooldown_delta -1}` / `huaJing {cooldown_delta -2}`。
**取名依据**:古琴曲名,雁阵起落写「顺风势而非抗风势」,与 §2 主题同拍;沙海意象不撞 Ch8「瀚海孤烟」/ Ch14「十荡十决」/ Ch16「铁马冰河」。

## 6. ★ feng_juan 收编 fork(本 spec 最需拍板项)

段级 §5 拍「feng_juan 宗师段沙海关**普通掉落收编**(非真解·收集向·删 mount_deferred)」。**Phase 0 实测:该拍板与现行红线测不相容**——
`wave_b_content_redline_test:40-53` 用**集合相等**断言:凡 `mainline_drop && !mountDeferred && 在发布阶内` 的招,**必须**是某个 `isBossStage && dropSkillManualId != null` 主线关的掉落;同测 `:36` 又断言**每章至多 1 本真解**。feng_juan(tier4·在阶内)一旦删 deferred,就只能挂章末 Boss,而 Ch17 的章末位已给平沙落雁。**没有「普通关普通掉落」这条通路**。

| 案 | 做法 | 代价 | 收益 |
|---|---|---|---|
| **A(推荐)** | 挂 **17_04 章中 Boss** 作其 `dropSkillManualId` + `chargeSkillId`;红线测 `:36` 语义收紧为「每章至多 1 本**末Boss**真解」 | 改 1 处测语义;17_04 须配 chargeCounter 相位;feng_juan mult 3200 在宗师段偏弱,建议 [balance] **3200→4800**(同十荡十决 3600→4800 先例) | 兑现段级拍板;两级破招教学(章中学打断→末关学窗口)正好是本章机制主题;测语义本意就是「每章一门末Boss真解」,现写法把章中 Boss 也算进来是口径过宽,**收紧是订正不是放水** |
| B | feng_juan 顶替平沙落雁作末 Boss 真解,不新写 | 违段级 §4「Ch16/17 新写 tier6 真解 ×2」冻结项;须 tier 4→6 + mult 3200→6400 双改 | skill 计数不变 255,改动最小 |
| C | 续 deferred 到 Ch18 | 段级 §5「归 Ch17」drift;Ch18 要同时收 yang_guan + feng_juan **两个** mainline_drop,撞同一条断言,问题只是推迟且更挤 | Ch17 零测试语义改动 |
| D | 改 `source: mainline_drop → fragment` | **破残页 3/3/3 配平**(lingQiao 变 4),须再补 2 招 | 字面最贴「非真解收集向」 |

## 7. 夜雨十年灯残页(段级 §3 · 无 fork)

`skill_ye_yu_shi_nian_deng` 删 `mount_deferred`,挂 **17_05 `dropSkillFragmentId`**(照 Ch16_05 挂月落无声先例)。
**配平零影响**——`残页` 配平(`:162`)不排除 mountDeferred,该招本就计在 3/3/3 内;删标只让它进 `releaseFragments` 挂载完备集合,必须被挂上。若 §6 走 A 案,17_04 已占 `dropSkillManualId`,残页仍挂 17_05,两关各一份收获不重叠。

## 8. 叙事纲(13 篇 · ~6300 字 · 沿 Ch16 体例)

- **已写死的锚**:Ch16 章尾末句「往西,沙海铺向纵深…**下一程,沙海纵深**」——**章名有硬叙事锚,不是自由选项**。同章尾已埋三线:① 铜镜「剩下的一半,在西凉深处」② 接关人「霸主在西凉深处等,等东边再来一个故人」③「入了冬的风从身后推着他」(季节续冬)。
- **章首**:入沙海第一夜,砂丘一浪叠一浪;中原的步法在流沙上不管用——**问题先出现**(§5.7)。
- **章尾**:望见西凉腹地的轮廓,不进;回味末 Boss 教的那件事(硬打不过,等势);hook Ch18 重会霸主。
- 10 段 stage(每关 opening/victory)+ 2 defeat(**17_04 / 17_05** 两 Boss 关)+ chapter_17 卷首尾。
- **motif 承接**:李寒「剑到了一处地方,就要听那处地方的风」(chapter_04 epilogue 原文)在本章正面兑现;「故人」二字继续搓热但不点破,留 Ch18 反转。风格词按段级 §4 爬升位:Ch16 入西之静 → **Ch17 天地之大** → Ch18 天地之远。
- 黑名单词 + 现代词 grep 必 **0**;实装批先读 chapter_04/05/06 全文对齐李寒与霸主人物细节。

## 9. reconcile 面(实装前 Phase-0 重新 grep 复定 · 本节只列站点不锚行号)

- **count 80→85**:`progression_playtest_diagnostic`(含 CSV **byte-lock** 须 `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生)/ `game_repository_test`(≥3 处:mainlineCount / 主线 N 关红线 / R3 prevStageId 单链)/ `mainline_narrative_completeness`(count + 章循环 1→17)/ `balance_simulator` / `readable_tempo`(**终章门槛 `stage_16_05`→`stage_17_05`**·drift 高发点)。
- **boss 敌 34→36** `stages_boss_enemy_test` / **catalog 47→49** `boss_memory_providers_test`(两站点独立,易只改一个)。
- **skill 计数 255→256 四处 / 三文件**(实测,非照抄 memory「三处」):`game_repository_test:61`(值 + 其长 reason 字串的逐项分解须加「+ 1 Ch17 平沙落雁」+ 上方注释块)/ `skill_count_contract_test:38`(mergedIds)与 `:45`(**GDD 字串「255 招（215 + 40）」交叉核对**)/ `skill_qi_redline_test:57`。
- **白名单**:`standaloneBossManualIds` 登记 `skill_ping_sha_luo_yan`(A 案再加 `skill_feng_juan_liu_sha`),否则破真解 2/2/2 配平。
- **cap 38→40**:within-tier,只 `numbers_config_progression_release_cap` cap-value 断言 + `numbers.yaml:206` 注释重写;**确认不破**(非猜):`wave_b`/`skill_source_redline` 挂载完备、`inner_demon_r5` R5.3、`mainline_stage_curve` ≤cap 类——实装批仍逐个跑取证。
- **progression 逐值实测禁猜**:`progression_release_budget` 首通(3633 / Lv?)与全内容(Lv115 guard 必破须放宽)· **`idle_horizon` s1 45.6/下沿 45.0 三档必破必重校**(测内注释已自承「Ch17 扩缺口必破须重校」)· `enhancement_material_supply` 结晶上界沿放宽复核。
- **生产可见性(漏则死内容)**:`chapter_list_screen._chapters` [1..17] + widget 测章卡计数(viewport 扩容)/ `UiStrings.chapter17Title`·`chapter17Hint` + 两处 switch / `mainMenuMainlineHint`「16 章 80 关」→「17 章 85 关」/ main_menu·status_summary 章循环 ≤17 / `boss_memory_key` chNum=17(**持久化字段不重排旧值**)。
- **GDD 头部当前状态块必更**(cap 40 / 17 章 85 关 / 实测锚两值),`truth_source_guard_test` 自动拦;§8.1 章表 + 招式池同步。
- **美术**:`known_missing_assets` 登记 11 图(5 敌立绘 + chapter_17_cover + 5 叙事背景),合并后走 codex image_gen 专批(沿 Ch14-16 惯例)。

## 10. ★ 拍板汇总(六项 · 每项附推荐)

| # | 决策项 | 选项 | 推荐 |
|---|---|---|---|
| 1 | **章名** | A「沙海纵深」/ B 另拟 | **A** — Ch16 章尾末句已写死「下一程,沙海纵深」,改名要回改已合并叙事 |
| 2 | **真解** | A 新写「平沙落雁」(lingQiao·6400·CD4·避撞 0)/ B 另拟 | **A** — 琴曲名写「顺势不抗势」,与本章机制主题同拍 |
| 3 | **feng_juan 收编**(详 §6) | A 挂 17_04 + 收紧测语义 + [balance] 3200→4800 / B 顶替末Boss真解 / C 续 deferred 到 Ch18 / D 改 fragment | **A** — 唯一同时兑现段级拍板、不破配平、且让机制教学成两级递进的走法 |
| 4 | **末 Boss 身份** | A 沙海领路人(霸主座下·灵巧·教「等势」)/ B 沙海马贼首领 / C 无名沙行者 | **A** — 承接 Ch16 接关人「霸主在西凉深处等」的引路链,Ch18 重会霸主前的最后一环 |
| 5 | **17_03 意象** | A 沙埋古城(temple·避撞 Ch15_03 佛窟)/ B 敦煌佛窟(段级 §8 原候选) | **A** — B 与 Ch15_03「戈壁古窟·行脚僧」重复;「整座城被沙吞掉」更贴宗师段天地母题 |
| 6 | **机制密度** | A 末 Boss 单窗口 0.20(段级拍板 6)+ 17_04 破招前置 / B 只末 Boss,17_04 纯 stat 门槛 | **A** — 与 §6 A 案绑定;若 §6 改选 C 则本项自动退 B |

## 11. 红线守卫

- 末 Boss HP **58000 < 60000** · 真解 **6400 ≤ 8000** · 敌招 ult 5500 = tier6 cap · 敌攻 **1950 ≤ 2000** 参照 · vulnerability 0.20 ∈ schema [0.05, 1.0]。
- 三系锁死:敌招全 tier6 失传神功档(fang 变体同 tier6)· 真解 tier6 · 不降档充数。
- `chargeSkillId` 必与 `onEnterMechanic: chargeCounter` 成对;17_01 缺 `prevStageId`;简单 stat 门槛 Boss **不配** `bossPhases`。
- 在线=离线 / §5.1 反主流不碰 / 难度增量走机制层不抬 `bossHpMax` 硬线(段级拍板 1)。

## 12. 实装建议

- coupled **xhigh** 批整章一次做完(同 Ch10-16);开工先全 Phase-0 grep **重核本 spec 全部行号与计数**(本节数字为 2026-07-26 实测,会 drift)。
- 必读 memory:`feedback_wuxia_add_mainline_chapter_reconcile` / `feedback_wuxia_release_cap_raise_reconcile` / `feedback_stages_yaml_edit_direction`(从 `- id:` 正向定位) / `feedback_flutter_test_batch_silent_skip`(批传显式路径会静默漏跑,验收须逐文件对账)。
- 合并前 `build_runner` → `analyze` 0 → 批末**全量**(schema/数值跨切面必跑);`dart format` 在 Edit dart 之后必跑。
- **破坏证红在 commit 之后做**(真解 mult 9000>8000 → RED → 还原绿);还原后必重跑绿。
