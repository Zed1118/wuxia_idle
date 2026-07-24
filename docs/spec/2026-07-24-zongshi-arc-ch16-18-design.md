# 宗师段(Ch16-18)设计 spec(段级已拍板 · Ch16 细化待拍板)

**日期**:2026-07-24 · **载体**:main 直落(bg 会话·纯文档)
**境界阶**:宗师(zongShi·绝对层 36-42)· 主线 Ch16-18 三章 · 承 Ch15「关山一程」出阳关西行
**状态**:**段级六项已拍板冻结**(2026-07-24 用户全按推荐);Ch16 章级细化【待拍板】(§9);Ch17/18 前瞻登记留各自章 spec 终拍

---

## 1. 段级六项拍板(2026-07-24 冻结 · BACKLOG §一#9 销账依据)

| # | 决策 | 拍定 |
|---|---|---|
| 1 | **难度机制层方向(=BACKLOG §一#9)** | **机制层扩难**:Boss HP 钉 ≤59500、敌攻钉 ≤2000 参照内,难度增量走 vulnerability 脆弱窗口+相位(§5.4 例外条款先例扩到主线);**不抬 bossHpMax 硬线**。依据:Ch15 头寸收官后玩家侧(装备攻 2000/血 20000/内力 15000)与敌侧全面进入红线收敛区,数值轴到顶,机制层是红线哲学终局形态(武圣段同适用) |
| 2 | 段构与 cap 轨迹 | Ch16-18 三章;cap 35→**38**(Ch16 cross-tier·releaseTier jueDing→zongShi)→**40**(Ch17)→**42**(Ch18 段封顶)。同绝顶段 31/33/35 体例 |
| 3 | 叙事弧 | **西凉故人弧「旧路更远处」**:出阳关入西凉,Ch4「西出阳关」深度回旋(黑石小铜镜=联结物),Ch18 重会西凉霸主本人 |
| 4 | 真解安排 | Ch16/17 新写 tier6 真解 ×2(skill 254→256),Ch18 收编 `skill_yang_guan_wu_gu_ren`(**[balance] mult 4000→6400** 对齐宗师真解档·同十荡十决 3600→4800 先例) |
| 5 | feng_juan 处置 | `skill_feng_juan_liu_sha`(tier4·lingQiao·大漠)宗师段沙海关**普通掉落收编**(非真解·收集向·删 mount_deferred),归 Ch17 沙海纵深章 |
| 6 | 机制型密度 | **渐进**:Ch16 常规(cross-tier 层差)→Ch17 末 Boss 单窗口教学(0.20 档宽松)→Ch18 章中+末 Boss 全机制(霸主 0.12 档)。守 §5.7 先感受问题再给答案 |

## 2. 机制层框架(#9 落地 · 零 schema 扩展)

- **schema 已就位**:`vulnerability.outOfWindowDamageMult` + `cycleVulnerability` 在 EnemyDef 上主线/塔共享(`stage_def.dart:273`),含「配 vulnerability 必须有开窗途径」加载期校验;开窗靠 `bossPhases` chargeCounter 相位(塔 floor25 0.12+相位 0.80/0.50、floor30 0.20+0.90/0.50 两先例实测定稿)。
- **渐进锚**:Ch17 末 Boss 0.20 档(比照 floor30 宽松位·单相位开窗教学);Ch18 章中 Boss ~0.20 / 末 Boss 霸主 0.12 档(比照 floor25·两相位)。首通挂机胜率按 `boss_balance_crosstier` 口径探针校准(自动战斗可过已被塔/心魔验证),cycleVulnerability 周目加压后议。
- **头寸分配(名义值钉线内)**:三章末 Boss HP 56500→58000→59500(<60000);敌攻三章 ~1880→~1950→**≤2000 用尽**(武圣段起攻轴亦须机制层,本 spec 不展开)。

## 3. 资源池盘点(2026-07-24 实测)

- **失传神功敌招系列不存在,须新写**(打破 Ch10-15 零新增惯例·段位必然):tier6 全池 6 门=3 开锋专属(special 口径外)+yang_guan(真解)+月落无声/夜雨十年灯(fragment),**敌招 0 门**;绝顶段复用的 tier5 jianghu 系列(21 招)Ch13-15 已用尽(Ch15 全员 ult 化)。新写 **9 招**(3 流派×basic/skill/ult),数值锚照 `skills.yaml:18` 注:**shiChuanShenGong cap=5500**,梯度 basic 500(强制)/skill 4400(80% cap)/ult 5500(cap·cd5·manualTrigger),一次写好三章共用。fang 变体(敦煌佛窟意象)不入基础包,Ch17/18 章 spec 按叙事需要追加。
- **fragment 双挂载(cross-tier 红线⑦硬站点)**:`skill_yue_luo_wu_sheng`/`skill_ye_yu_shi_nian_deng`(tier6·yinRou·fragment·全仓零挂载实测)releaseTier→zongShi 后不挂载则挂载完备测红。处置:**月落无声挂 Ch16 章末残页、夜雨十年灯挂 Ch17 章末残页**(照 jing_hong 挂 Ch13 章末先例),与各章真解(gangMeng/lingQiao)流派互补;Ch18 章末=yang_guan 真解不另设残页。连同 #5 feng_juan 收编,**宗师段收官后 mount_deferred 全清零**。
- **玩家侧就位,零新增**:失传神功心法池已写(`techniques.yaml:241-270` 三门+防御变体·tier: shiChuanShenGong「宗师境界开放」);宝物装备 12 件(11 常规+wu_ming_jian special·三章 dropTable 足);断崖绝壁闭关图已配(`numbers.yaml:1151` required_realm: zongShi·exp 500/h)cap 进宗师自动解锁零实装;defense_rate zongShi 0.30(`numbers.yaml:430`)。
- **敌 id 命名空间注意**:旧第二主线 Ch5/6 已占 `enemy_zongShi_*` 前缀(嵩山一决/西凉三弟子·数值已重排学徒/三流),宗师段新敌沿 Ch13-15 体例 `enemy_zongShi_<章名拼音>_<敌名>` 不重名即可,实装批 Phase-0 全量 grep 防撞。

## 4. 叙事弧:西凉故人(Ch4-6 旧弧回旋 · 三见史实证)

- **霸主三见史**(旧第二主线·叙事保留数值重排):Ch4 西出阳关初见留小铜镜(「关外黑石上,他没去取」epilogue 原文)/Ch5 三弟子复出/Ch6 霸主本人首次开口(`stages.yaml:1498`)。**Ch18 = 重会,不是初见**——当年低段位仰望,如今宗师身份平视。
- **「阳关无故人」反转收束**:王维原意「西出阳关无故人」;主角出关而来,霸主几十年看中原终于等到一个**故人**——招名叙事在 Ch18 完成「无故人→有故人」反转,与铜镜收束(Ch16 见镜不取→Ch18 霸主亲手相赠)同拍。
- **风格词**(zongShi·memory 文化弧):「澄澈/无为/玄妙/化境」(人 vs 天地),段内爬升:Ch16 入西之静→Ch18 天地之远。季节连贯:Ch14 秋风初起→Ch15 长烟落日→**Ch16 入冬**(西风/铁马冰河)。
- 师父遗言/止水印/凉铜符 motif 是否续带:实装批读旧 Ch4-6 叙事全文对齐人物细节后定(spec 登记动作,不预写)。

## 5. Ch16 章细化(草案 · 【待拍板】见 §9)

- **定位**:宗师段首章·cross-tier(cap 35→38=宗师·熟练)·敌层 qiMeng→shuLian 递进(01-02 启蒙/03-04 入门/05 熟练·照 Ch13 体例)·requiredRealm: zongShi·三系锁死:宗师↔宝物↔失传神功。
- **五关草案**(biome 全复用·HP 段首回落照 Ch13 体例):

| 关 | id | biome | 侧面 | 流派/层 | Boss | HP/Atk 锚(探针校准) |
|---|---|---|---|---|---|---|
| 1 | stage_16_01 | frontier 阳关外驿道 | 出关头程·中原侧最后相送 | gangMeng·qiMeng | — | 53000/1850 |
| 2 | stage_16_02 | desert 黑石戈壁 | 铜镜黑石(Ch4 回旋·见镜不取) | yinRou·qiMeng | — | 54000/1880 |
| 3 | stage_16_03 | inn 沙海孤驿 | 驿中西凉客·西凉侧第一面 | lingQiao·ruMen | 非 boss | 55000/1900 |
| 4 | stage_16_04 | desert 大漠游骑 | 西凉游骑将(章中 Boss·stat 门槛无相位·配 defeat) | lingQiao·ruMen | 章中 Boss | 56000/1910 |
| 5 | stage_16_05 | frontier 西凉门户关城 | 接关人(末 Boss·真解·配 defeat) | gangMeng·shuLian | 末 Boss | **56500/1920** |

- Boss 位 {4,5}·16_01 不跨章 prevStageId·速度 336→~350·diffMult 17.0→17.8·baseExpReward 64/66/68/88/108(沿 +6/关·章计 +394)。
- **末 Boss「接关人」**:西凉门户老守将,霸主座下留关数十年——对称 Ch15 中原守关老将(「中原有人送出关,西凉有人接进门」);无 vulnerability(拍板 6:Ch16 常规),两相位 chargeCounter 照 15_05 模板,chargeSkill=dropSkillManual 双用。
- **真解新写「铁马冰河」`skill_tie_ma_bing_he`**(gangMeng·tier6·mult **6400**·qiDelta -30·CD 5·powerSkill·single·visualEffect iron_cavalry·mainline_drop·proficiency 照刚猛真解三层模板):西凉军马意象承十荡十决、入冬季节对位;敌招 cap 5500 上浮档(4000→4800 先例同构)。避撞 grep 铁马/冰河 0 命中(「大漠孤烟」候选因撞 Ch8「瀚海孤烟」弃)。
- **章末残页位挂 `skill_yue_luo_wu_sheng`**(§3 fragment 处置·与真解流派互补)。
- 叙事纲 13 篇(~6300 字):章首(出关第一夜·关门在身后)+章尾(接关人放行入凉·黑石镜不取的回味·hook Ch17 沙海纵深);10 段 stage+2 defeat(16_04/16_05);黑名单/现代词 grep 0。

## 6. Ch16 reconcile 面(cross-tier 全套 · 实装前 Phase-0 grep 复定行号)

- **count 75→80**:playtest CSV byte-lock 重生/game_repo mainlineCount/narrative completeness+章循环 [1..16]/balance_simulator/readable_tempo 终章 stage_15_05→stage_16_05。
- **boss 敌 32→34**/**catalog 45→47**/**skill 计数 254→256 三处+GDD 字串**(铁马冰河+失传神功敌招 9 招=+10?——敌招入 genericIds 口径按 skill_count_contract 拆分桶实装核定,禁猜)/**wave_b 白名单** +铁马冰河(第 9 门)。
- **cap 35→38 四站点**(memory feedback_wuxia_release_cap_raise_reconcile)+**releaseTier jueDing→zongShi cross-tier 全套**(照 Ch13 §cap 段):挂载完备 !mountDeferred 复核(feng_juan/yang_guan 仍 deferred 至 Ch17/18)/月落·夜雨挂载(§3)/R5.3 cap-agnostic/stale 文案 grep/心法·装备侧完备性测 Phase-0 复定。
- **progression 逐值实测禁猜**:release_budget 首通/全内容(Lv112→预估 ~115 实测终拍)/**idle_horizon s3 50.7·下沿 50、s4 7.0·下沿 7.0 双贴线必破必重校**(2026-07-24 交接快照)/material 结晶上界沿放宽复核。
- **生产可见性**:chapter_list [1..16]/strings chapter16Title·Hint+两 switch/mainMenuHint「15 章 75 关→16 章 80 关」/main_menu·status_summary ≤16/boss_memory_key chNum=16。
- **GDD 头部当前状态块必更**(cap 38/16 章 80 关/实测锚,truth_source_guard 自动拦)+§8.1 章表+招式池;known_missing 11 图登记(5 敌+cover+5 叙事背景·合并后 codex image_gen 专批惯例)。

## 7. 红线守卫

- 末 Boss 56500<60000·真解 6400≤8000·敌招 ult 5500=tier6 cap·敌攻 ≤1920(参照 ≤2000)。
- 三系锁死:敌招全 tier6 失传神功档·真解 tier6·不降档充数;16_01 缺 prevStageId·16_05 chargeSkillId 配 onEnterMechanic: chargeCounter 成对·16_04 stat 门槛无 bossPhases。
- 在线=离线·反主流不碰·cross-tier 难度走层差+新敌招档,机制型按拍板 6 本章不上。

## 8. Ch17/18 前瞻登记(留各自章 spec 终拍)

- **Ch17 沙海纵深章**(cap 38→40):灵巧主题——末 Boss lingQiao 真解新写(候选「平沙落雁」·避撞 0 命中)+feng_juan 普通掉落收编+夜雨十年灯章末残页,同章三灵巧向收获;末 Boss 单窗口 0.20 档机制教学;敦煌佛窟意象/fang 变体敌招候选。
- **Ch18 西凉腹地·段收官**(cap 40→42 封顶):重会霸主·「阳关无故人」收编真解([balance] 4000→6400)·铜镜收束·章中+末 Boss 全机制(0.20/0.12 档)·末 Boss HP 59500 钉线复用·段末 hook 武圣段(最终段·攻/HP 双轴头寸全清,难度全面机制层)。

## 9. 待拍板汇总(Ch16 章级)

1. **章名**:A「凉州词」(乐府对位西凉·避撞 0)/B「大漠行」/C「黑石道」。**推荐 A**。
2. **真解**:A 新写「铁马冰河」(gangMeng·6400·CD5·避撞 0)/B「长河落日」或另拟。**推荐 A**。
3. **末 Boss**:A 西凉「接关人」门户老守将(对称 Ch15·霸主座下)/B 霸主门下大弟子。**推荐 A**(霸主一系纵深留 Ch17/18)。
4. **黑石铜镜**:A 16_02 见镜不取(hook Ch18 霸主亲手相赠)/B 取走携带。**推荐 A**(「他没去取」对称美学:当年没懂,如今懂了所以不取)。
5. **敌招新写规模**:A 基础 9 招(3 流派×basic/skill/ult·三章共用)/B 9+fang 变体 3(敦煌支线前置)。**推荐 A**(fang 留 Ch17/18 按叙事追加)。
6. **fragment 双挂载**:A 月落 Ch16 残页+夜雨 Ch17 残页(mount_deferred 段末全清)/B 双标 deferred 续挂。**推荐 A**。

## 10. 实装建议

- coupled xhigh 批整章一次做完(同 Ch10-15)·先全 Phase-0 grep 复定站点(本 spec 行号 2026-07-24 实测·实装时重核防 drift)·memory 必读 feedback_wuxia_add_mainline_chapter_reconcile(含 GDD 状态块站点)。
- 敌招 9 招新写与 Ch16 同批落(三章共用池一次到位);实装批读旧 Ch4-6 叙事全文对齐霸主/三弟子人物细节。
- 合并前 build_runner→analyze 0→批末全量;破坏证红(真解 mult 9000>8000 RED→还原绿)在 commit 后做;kimi 2026-07-26 10:10 前配额不可用→Claude 主执行或 codex+Claude Gate。
