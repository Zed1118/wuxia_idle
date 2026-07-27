# Ch18「阳关故人」章级设计 spec(宗师段收官章 · **已拍板冻结**)

**日期**:2026-07-27 · **载体**:main 直落(bg 会话·纯文档) · **上游**:`docs/spec/2026-07-24-zongshi-arc-ch16-18-design.md` §8 前瞻
**状态**:**已拍板冻结**(2026-07-27 用户六项全按推荐 = **1A/2A/3A/4A/5A/6B**·实装依据)。段级六项已于 2026-07-24 冻结,本 spec 只细化 Ch18,不改段级拍板。
**注**:文件名沿用起草时的段级定位名「西凉腹地」,**章名已拍定为「阳关故人」**,按 Ch17 先例拍板后不改文件名。

---

## 1. Phase 0 实测基线(2026-07-27 主 checkout 现跑 · 禁转抄 · 实装前重核防 drift)

| 项 | 实测值 | 出处 |
|---|---|---|
| 主线规模 | **17 章 85 关** | `data/stages.yaml` |
| cap | **40**(宗师·圆熟 yuanShu) | `data/numbers.yaml:206` |
| skill 池 | genericIds **216** / merged **256** / skillDefs **256** | `skill_count_contract_test.dart:28,38` · `skill_qi_redline_test.dart:57` |
| boss 敌 / catalog | **36** / **49**(主线 isBossStage 43 + 塔 6) | `stages_boss_enemy_test.dart:35` · `boss_memory_providers_test.dart:50` |
| 首通 / 全内容 | **Lv102**(cumExp **3633**) / **Lv118** | `progression_release_budget_test.dart:22,47,49,53` |
| idle_horizon | 缺口 **4879** EXP · 终态 abs12 · 层内余量 **1221** | `progression_idle_horizon_simulation_test.dart:59-75` |
| Ch17 曲线 | HP 56800→58000(+300/关) / 攻 1925→1950 / 速 352→360(+2) / diffMult 18.0→18.8(+0.2) / exp 70·72·74·94·114(计 **424**) | `stages.yaml:3908-4113` |
| `mount_deferred` | **全仓仅剩 1 处** = yang_guan | `data/skills.yaml:2995` |
| yang_guan 现值 | mult **4000** · **yinRou** · tier6 · CD5 · powerSkill/single · mainline_drop · **proficiency 块完整**(0.08 档) | `data/skills.yaml:2981-3000` |
| `standaloneBossManualIds` | **11 条**(Ch8-17) | `wave_b_content_redline_test.dart:166-180` |
| 残页配平 | fragment **3/3/3 已平** | 现跑分组统计 |
| fang 变体 | yinRou 已用(17_03) · lingQiao 已用(17_04) · **gangMeng 仍全仓零使用** | `stages.yaml:4005,4048` |
| 霸主既有定义 | `enemy_wuSheng_xiliang_bazhu`「西凉霸主」· realmTier **sanLiu**·shuLian · school **yinRou** · HP 12000 / 攻 450 · chargeSkill `skill_xie_yu_chuan_lian` | `stages.yaml:1500+`(stage_06_05) |
| 章名候选避撞 | 阳关故人 / 天地之远 / 故人来 / 东来故人 / 王庭 **均 0 命中** | 全仓 grep |

**上游 spec 需订正三处(本 spec 以实测为准 · 段级与 Ch17 spec 本身均未回改)**:

1. **`RealmTier.values[(cap-1)~/7]` 在 `lib/` 里不存在**——那是 `data/numbers.yaml:206` 注释的简化描述。真实判据是 `getRealmByAbsoluteLevel(cap).tier`(`lib/data/game_repository.dart:865-867` → `lib/data/validation/skill_red_lines_validator.dart:109` 的 `releaseSkillTierCap = releaseRealm.tier.index + 1`)。**改从层表实证**:`data/numbers.yaml:429+` zongShi 覆盖 abs **36-42**,故 cap 40→42 **within-tier**(releaseTier 不变),cross-tier 全套不触发,只 cap-value 断言需改。**但 42 = zongShi 末层**,武圣段抬 cap 必是 cross-tier,本章是最后一次「便宜」的抬 cap。
2. **「天地之远」不是既定章名**。全仓 **0 命中**;段级 §4 那句是**风格词爬升位**描述(Ch16 入西之静→Ch18 天地之远),§8 给的是定位名「西凉腹地·段收官」。**且 Ch17 章尾未写死下一章名**——Ch16 结在「下一程,沙海纵深」(硬锚),Ch17 结在「他转身…看那缕烟」(`chapter_17.yaml:44`,无章名)。故 Ch18 章名是**自由选项**,进 §10 #1 拍板。
3. **`progression_idle_horizon_simulation_test.dart` 两处 stale 字串**:`:59` 测试名写「余量692」但 `:68` 实断言 **1221**;`:67` reason 写「Lv115」但 `:63` 断言 **118**。不影响断言执行(Ch17 批漏更),本章顺修。

## 2. 章定位

宗师段**收官章** · **within-tier**(cap 40→42 = 宗师·登峰 dengFeng·段封顶)· requiredRealm `zongShi` · 敌层 yuanShu→dengFeng 递进 · 三系锁死不变(宗师↔宝物↔失传神功)。

**章名「阳关故人」(拍定 1A)**:王维「西出阳关无故人」去一「无」字,即本章题眼;与真解 `skill_yang_guan_wu_gu_ren`「阳关无故人」一字之差,与 Ch4 章名「西出阳关」首尾回旋。
**主题**:承 Ch17 末 Boss 教的「硬打,打不过——等势」,本章把它交到人身上:霸主等了几十年,也是**等势**。整个西凉弧的三重收束——**铜镜**(Ch4 李寒不取 → Ch16 新掌门不取 → Ch18 亲手相赠)、**「故人」**(Ch16「等的年头足够长,来的人就是故人」→ Ch17「『故』不在见没见过,在走没走过同一条路」→ Ch18 兑现)、**「无物可赠」的反面**(Ch6 霸主对李寒说「无物可赠。你已经不需要了」→ 本章对新掌门是「有物可赠」,而赠的物「不是一件东西,是一句话」·`chapter_16.yaml:18` 原文)。

## 3. 五关草案(数值待探针校准 · biome 全复用 · 敌招零新增)

| 关 | id | biome | 侧面 | 流派/层 | Boss | HP / 攻 / 速 |
|---|---|---|---|---|---|---|
| 1 | stage_18_01 | desert 碗口下沉 | 从丘脊下到碗底·真正踏进腹地 | gangMeng·yuanShu | — | 58300 / 1960 / 362 |
| 2 | stage_18_02 | desert 沿烟而行 | 那缕烟是唯一路标·途中遇拦 | lingQiao·yuanShu | — | 58600 / 1970 / 364 |
| 3 | stage_18_03 | cityWall 西凉城下 | 看见城·城不像中原的城 | yinRou·huaJing | — | 58900 / 1980 / 366 |
| 4 | stage_18_04 | drillGround 演武场 | 章中 Boss·西凉三弟子·**0.20 窗口 + 两相位** | gangMeng·huaJing | 章中 Boss | 59200 / 1990 / 368 |
| 5 | stage_18_05 | frontier 火堆前 | 末 Boss 霸主·**0.12 两相位全机制**·真解收编 | **yinRou**·dengFeng | 末 Boss | **59500** / **2000** / 370 |

- Boss 位 **{4,5}**(沿全段体例)· 18_01 **不配 prevStageId**(跨章引用加载期 StateError)· diffMult **19.0→19.8**(+0.2/关,承 Ch17 末 18.8)· baseExpReward **76/78/80/100/120**(章计 **454**·沿 +6/关轨迹) → cumExp 3633 **→ 4087**(预估,实装批逐值实测)。
- HP 58000→**59500**(段级 §2 钉线·<60000 硬线)、敌攻 1950→**2000**(段级 §2「≤2000 用尽」·见 §10 #5)、速 +2/关、敌层 **yuanShu→dengFeng**(承 Ch16 qiMeng→shuLian / Ch17 shuLian→yuanShu 的三段递进,末 Boss dengFeng = cap 42 同层)。
- **敌招零新增**:01/02/03/05 用既有 `skill_{gangmeng,lingqiao,yinrou}_shichuan_{basic,skill,ult}`;**04 用 `skill_gangmeng_shichuan_fang_*`**(fang=佛门防御变体·tier6 同档·**唯一仍全仓零使用的一组**,本章首次接线,「护主守成」语义贴三弟子)。三章共用池到此**恰好用尽**,零新写。
- **18_04 流派/敌名须与 Ch5 既有 `enemy_zongShi_xiliang_sandizi`(`stages.yaml:1246`)对齐**——实装批先读该定义再定,本表 gangMeng 为草案值。

## 4. 机制层(段级拍板 6 · 章中 + 末 Boss 全机制)

- **18_04 章中 Boss**:`vulnerability.outOfWindowDamageMult: **0.20**`(承 Ch17 末关同档,玩家已学过)+ 两相位 `chargeCounter`。比 Ch17 章中(只 chargeCounter 无 vulnerability)进一档。
- **18_05 末 Boss 霸主**:`outOfWindowDamageMult: **0.12**`,**比照塔 floor25**(`towers.yaml:983` 同为 0.12)的两相位复合位——`bossPhases` 三段 `1.0 / 0.80 / 0.5`,后两段各配 `unlockSkillIds` + `onEnterMechanic: chargeCounter`(照 floor25 `towers.yaml:990-1005` 模板)。这是主线迄今最紧的机制门槛,也是段级拍板 6「渐进」的终点。
- `chargeSkillId` = `skill_yang_guan_wu_gu_ren` = `dropSkillManualId`(双用 canon:破他的招、学他的招;`wave_b_content_redline_test` 双用硬断言(注释锚 `:26`;**不锚具体行号**——Ch17 spec 转抄的 `:31` 现测已 drift))。**霸主 school 既定 yinRou、yang_guan 亦 yinRou,流派天然自洽**,无需改任一侧。
- `cycleVulnerability`(周目收窄)见 §10 #6;`schoolDamageTakenMult` 本章不配(floor25 有,主线未用过,不在收官章首引新维度)。

## 5. 真解收编 `skill_yang_guan_wu_gu_ren`(段级拍板 4 · 无 fork)

- 删 `mount_deferred: true`(`skills.yaml:2995`)→ **全仓 mount_deferred 归零**,兑现段级 §3「宗师段收官后全清零」。
- `[balance] powerMultiplier **4000→6400**`(段级拍板 4 冻结值·对齐 Ch16 铁马冰河 / Ch17 平沙落雁同档·≤8000 硬线)。
- `tier: 6` / `style: yinRou` / `CD 5` / `qiDelta -30` **均不动**;**proficiency 块已完整**(0.08/0.08+CD-1/CD-1),不像 Ch16 铁马冰河那样需补(该批曾因写入截断漏 `huaJing`),**实装批仍须逐字核一遍**。
- **`standaloneBossManualIds` 必须登记 `skill_yang_guan_wu_gu_ren`**——删 deferred 后它进 mainlineDrop 配平池,不登记则破 2/2/2(Ch17 feng_juan 同型先例,注释已明写)。
- **skill 计数四站点预期全不破**(收编 = 删标记 + 改数值,**不增 skills.yaml 条数**):genericIds 216 / merged 256 / skillDefs 256 均不变。**这是 Ch16/Ch17 都没有过的情况**,reconcile 面显著小于前两章——但**实装批必须实跑取证,不当既定事实**。
- **章末残页不设**(段级 §3:Ch18 章末 = yang_guan 真解,不另设 fragment)。fragment 3/3/3 现已平,不动即不破。
- **真解位约束的实测口径(2026-07-27 现跑·与 Ch17 spec §6 措辞不同)**:`wave_b_content_redline_test` 被 Ch17 批收紧成「**末Boss / 章中各至多 1 本**」(不是 Ch17 spec 写的「每章至多 1 本末Boss真解」),且「本章最末关」**从单链结构派生、不锚 `_05` 字面 id**。Ch18 末 Boss 掉 yang_guan、章中三弟子不掉真解,两侧均在约束内,**本章无需再动该测语义**。

## 6. 叙事纲(13 篇 · ~6300 字 · 沿 Ch16/17 体例)

**Ch17 章尾已写死的硬锚(`chapter_17.yaml:19-44` 原文,须逐条承接)**:碗底一线黑 + 一缕**极淡、笔直、久久不散**的烟(「有人在那里烧火。烧了不知多少年」)/「**硬打,打不过**」= 等势不逞强 /「今日不进…等它凉透,再走那最后一段」/ 铜镜另一半在西凉深处、**两人都没取** /「故」的自问已预设答案方向(「在走没走过同一条路、在同一个地方陷过同一次砂」)/ 季节续冬(「跟出阳关那夜是同一股风」)/ 霸主基调「**烧火的人不急。等了几十年的人,不会急在这一天**」。

- **章首**:凉透了才下去。碗口下沉的第一步,与 Ch17 章尾那一坐直接接续。
- **章尾**:铜镜收束 + 「故人」兑现 + hook 武圣段。**「无物可赠」的对照是本章题眼**——Ch6 霸主对李寒说「无物可赠。你已经不需要了」(`stage_06_05_victory.yaml:5` 原文),对新掌门则有物可赠;而 Ch16 已写死「镜子不是一件东西,是一句话」,故**赠镜 = 赠那句话**,物与话在此合一。
- **真解名的反转**:招名「阳关无故人」,而本章恰恰完成「有故人」。招是霸主几十年前起的名,名里的「无」是他自己的判词;新掌门走完这条路,把那个「无」字取消掉。**招名不改**(改则破 Ch4 原生锚),反转全走叙事。
- 10 段 stage(每关 opening/victory)+ 2 defeat(**18_04 / 18_05** 两 Boss 关)+ chapter_18 卷首尾。
- **实装批先读全文对齐人物细节**:`chapter_04`(铜镜原文 `:34-35`「他没去取」)/ `chapter_05` / `chapter_06` + `stage_06_05_victory`(霸主唯一一次开口)/ `chapter_16` / `chapter_17`。黑名单词 + 现代词 grep 必 **0**。
- 风格词按段级 §4 爬升终点位(澄澈/无为/玄妙/化境);李寒线在本章收——他没走完的那一段,新掌门走完了。

## 7. reconcile 面(实装前 Phase-0 重新 grep 复定 · 本节只列站点不锚行号)

- **count 85→90**:`progression_playtest_diagnostic`(CSV **byte-lock** 须 `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生)/ `game_repository_test`(≥3 处:mainlineCount / 主线 N 关红线 / R3 prevStageId 单链)/ `mainline_narrative_completeness`(count + 章循环 1→18)/ `balance_simulator` / **`readable_first_clear_tempo_diagnostic_test.dart:113` 终章门槛 `stage_17_05`→`stage_18_05`**(drift 高发点·行号已现测)。
- **boss 敌 36→38** `stages_boss_enemy_test` / **catalog 49→51**(主线 43→45)`boss_memory_providers_test`——两站点独立,易只改一个。
- **skill 计数四处/三文件:预期全不破**(§5),但仍**逐个跑取证**,不默认。
- **白名单** `standaloneBossManualIds` 登记 `skill_yang_guan_wu_gu_ren`。
- **cap 40→42**:within-tier(§1 订正 1 已实证),只 `numbers_config_progression_release_cap` cap-value 断言 + `data/numbers.yaml:206` 注释重写;**确认不破(非猜)**:`wave_b`/`skill_source_redline` 挂载完备、`inner_demon_r5` R5.3、`mainline_stage_curve` ≤cap 类——逐个跑取证。
- **mount_deferred 归零的连带**:挂载完备测(红线⑦)此后**无豁免项**,任何新增 drop 招必须当批挂载。实装批确认该测在零 deferred 下仍绿。
- **progression 逐值实测禁猜**:`progression_release_budget` 首通(cumExp 4087 预估 / Lv?)与全内容(Lv118 guard 必破须放宽)· **`idle_horizon` 缺口 4879 必破须重校** + **顺修 §1 订正 3 两处 stale 字串** · `enhancement_material_supply` 结晶上界沿放宽复核。
- **生产可见性(漏则死内容)**:`chapter_list_screen.dart:31` `_chapters` 加 18 + widget 测章卡计数(viewport 扩容)/ `strings.dart` `chapter18Title`·`chapter18Hint` + 两处 switch(`:1526` Title / `:1550` Hint)/ **`strings.dart:1405` `mainMenuMainlineHint`「17 章 85 关」→「18 章 90 关」** / main_menu·status_summary 章循环 ≤18 / `boss_memory_key` chNum=18(**持久化字段不重排旧值**)。
- **GDD 头部当前状态块必更**(cap 42 / 18 章 90 关 / 实测锚两值),`truth_source_guard_test` 自动拦;§8.1 章表 + 招式池同步。
- **敌 id 命名空间**:章名拍定后前缀落为 **`enemy_zongShi_yangguan_<敌名>`**(实装批先全仓 grep 复验避撞);**注意 `enemy_zongShi_xiliang_sandizi` 与 `enemy_wuSheng_xiliang_bazhu` 已占 `xiliang` 中缀**,新敌须全量 grep 防重名(段级 §3 已提醒)。霸主本章新建 def,不复用 Ch6 那个(数值/层级完全不同量级)。
- **美术**:`known_missing_assets`(`test/fixtures/known_missing_assets.txt`·现 0 条)登记 11 图(5 敌立绘 + `chapter_18_cover` + 5 叙事背景),合并后走 codex image_gen 专批(沿 Ch14-17 惯例)。

## 8. 红线守卫

- 末 Boss HP **59500 < 60000** · 敌攻 **2000** = 参照上限用尽(见 §10 #5)· yang_guan **6400 ≤ 8000** · 敌招 ult 5500 = tier6 cap · vulnerability 0.12 / 0.20 ∈ schema [0.05, 1.0]。
- 三系锁死:敌招全 tier6 失传神功档(fang 变体同 tier6)· 真解 tier6 · 不降档充数。
- `chargeSkillId` 必与 `onEnterMechanic: chargeCounter` 成对;18_01 缺 `prevStageId`;配了 `bossPhases` 就必须有 charge 机制(否则 `readable_tempo` missingBossMechanic 挂)。
- 在线=离线 / §5.1 反主流不碰 / 难度增量走机制层不抬 `bossHpMax` 硬线(段级拍板 1)。

## 9. 章末 Boss 难度(memory `feedback_wuxia_boss_balance_crosstier` 适用性辨明)

该 memory 结论是「想让玩家真打不过须跨 1-2 阶」。**本章不适用其原始处方**——cap 42 = 段封顶,末 Boss dengFeng 与玩家同 tier,**无阶可跨**。段级拍板 1 正是为此:数值轴到顶后,难度**只走机制层**(0.12 两相位 = 有效伤害压到 12%,等价于制造「差 2 阶」的破防感,但不膨胀数字)。
另据 `feedback_boss_phase_needs_hp_not_just_threshold`:首击秒杀时 `hpThresholdPct` 相位不触发。Ch17 用 `0.9` 阈值 + 注释「受击进相位立即推蓄力,保 nearMax 首发即开窗」解决;**本章两相位 0.80/0.5 须探针实证窗口真的可见**(floor25 是塔环境,主线玩家侧强度不同),50 seeds 剖面校准,不照抄塔阈值。

## 10. 拍板汇总(六项 · **2026-07-27 全按推荐拍定**)

| # | 决策项 | 选项 | **拍定** |
|---|---|---|---|
| 1 | **章名** | A「阳关故人」/ B「天地之远」/ C 另拟 | **A** ✅ — 与真解「阳关无故人」一字之差完成整弧题眼反转;与 Ch16「凉州词」同为唐诗化用体例;与 Ch4「西出阳关」首尾回旋。三候选避撞均 0,B 的「远」与 Ch17「纵深」语义重复 |
| 2 | **末 Boss 机制档** | A 0.12 + 两相位(比照 floor25 完整复合)/ B 0.12 + 单相位 | **A** ✅ — 段级拍板 6 明写「全机制」;收官章是机制线终点,单相位与 Ch17 无区分度 |
| 3 | **章中 Boss 身份** | A 西凉三弟子(Ch5/Ch6 既有人物复出)/ B 新敌 | **A** ✅ — 三弟子在 Ch6 是「分立两侧」的护法位,演武场拦路合人物;零新人物成本,且加厚旧弧回旋 |
| 4 | **铜镜收束** | A 霸主亲手相赠 / B 仍不取,只把话说了 | **A** ✅ — 段级 §4 冻结项(「Ch16 见镜不取→Ch18 霸主亲手相赠」);且与 Ch6「无物可赠」形成本章题眼对照 |
| 5 | **敌攻是否用尽 2000** | A 用尽(1960→2000)/ B 止于 1990 留余量 | **A** ✅ — 段级 §2 明写「≤2000 用尽」;宗师段收官后武圣段难度全走机制层,攻轴留余量无消费方 |
| 6 | **`cycleVulnerability`** | A 配(周目收窄 0.12→~0.07,照 floor25)/ B 不配,留周目批 | **B** ✅ — 主线迄今零使用;收官章一次引入「两相位 + 周目收窄」两个新维度,校准面翻倍且周目剖面本章无法验;留独立周目批 |

## 11. 实装建议

- coupled **xhigh** 批整章一次做完(同 Ch10-17);开工先全 Phase-0 grep **重核本 spec 全部行号与计数**(本节数字为 2026-07-27 实测,会 drift)。
- 必读 memory:`feedback_wuxia_add_mainline_chapter_reconcile` / `feedback_wuxia_release_cap_raise_reconcile` / `feedback_stages_yaml_edit_direction`(从 `- id:` 正向定位) / `feedback_flutter_test_batch_silent_skip`(批传显式路径静默漏跑,验收须逐文件对账) / `feedback_chinese_path_shell_pitfalls` #5(zsh 不分词,多文件 test 用数组)。
- 合并前 `build_runner` → `analyze` 0 → 批末**全量**(schema/数值跨切面必跑);`dart format` 在 Edit dart 之后必跑。
- **破坏证红在 commit 之后做**(yang_guan mult 改 9000>8000 → RED → 还原绿);还原后必重跑绿。
- 本章是宗师段收官:合并后 `mount_deferred` 全仓归零、cap 触 zongShi 末层 42,**下一次抬 cap(武圣段)是 cross-tier**,reconcile 面会重新变大——收官 closeout 须写明这一点。
