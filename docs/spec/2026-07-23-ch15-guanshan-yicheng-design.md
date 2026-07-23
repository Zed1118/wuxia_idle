# Ch15「关山一程」设计 spec(已拍板 · 实装依据)

**日期**:2026-07-23 · **载体**:main 直落(bg 会话·纯文档)
**境界阶**:绝顶(jueDing·绝对层 29-35)· 主线第 15 章 · **绝顶段收官**(within-tier 封顶抬层,照 Ch12 一流收官 26→28 体例)
**状态**:**已拍板冻结**(2026-07-23 用户八项全按推荐:章名「关山一程」/cap 33→35 dengFeng 封顶/真解新写「孤城闭」yinRou mult4800/末 Boss 阳关守关老将「借关一战」/佛门 fang 系 15_03 上主线/美术 known_missing 后批/Lv guard 预估 ≤112 实装实测终拍/宗师段 HP 头寸倾向机制层·正式拍留宗师段 spec)

---

## 定位
- **绝顶段第三章=收官章**(承 Ch13 首章/Ch14 第二章·cap 33=绝顶·圆熟 yuanShu,`numbers.yaml:206` 实测)。
- `requiredRealm: jueDing` 不变·章内敌层 **yuanShu→dengFeng** 递进封顶(照 Ch12 收官章模板)。
- 三系锁死不变:绝顶 ↔ 重器 zhongQi ↔ 江湖秘传 jiangHuMiChuan。
- **releaseTier 无变化**(段内抬层封顶)——红线⑦挂载完备不新触发(mount_deferred 仅剩 feng_juan tier4 `skills.yaml:2933`/yang_guan tier6 `:2977`,均拍定归宗师段,cap 35 仍豁免)。

## 承接 hook(chapter_14.yaml epilogue 原文实读)
- 「这一回,不是远客来叩山了——是他要下山,去赴那个更远的约」+「万里关山的头一程,从他脚下开始」——**Ch15 = 西行头一程**,五关对称 Ch14(客上山五程 ↔ 主下山五程)。
- 「阳关外头,还有一位比我老得多的人,看了中原几十年」——宗师段 yang_guan 伏笔已埋,**本章不兑现**(西凉地界留 Ch16+ 宗师段)。
- 「留符人不是守山人——符留在这里,路却要往前走」+ 临别「回来。山在这里,符在这里,走多远,都得回来」。
- **Ch4「西出阳关」回旋结构**(stage_04_01..05 实测:阳关初渡/古道行商·玉门关把总/沙海迷踪/西凉论剑·biome frontier/desert 已有):当年循符出关的少年,如今以留符人身份重走旧路——「旧路新走」全章叙事母题,西行 biome/场景资产全复用。

## 主线剧情(西行头一程 · 5 关=下山赴约五程)
| 关 | id | biome(全复用) | 侧面 | 流派/层 | Boss | HP/Atk 锚 |
|---|---|---|---|---|---|---|
| 1 | stage_15_01 | mountainPath 山门官道 | 送行拳(中原同道沿路讨教·辞山) | gangMeng·yuanShu | — | 52000/1450 |
| 2 | stage_15_02 | dock 黄河渡 | 渡河辞中原(渡口夜客讨教) | yinRou·yuanShu | — | 54000/1520 |
| 3 | stage_15_03 | frontier 戈壁古窟 | 行脚僧论武(佛门 fang 系首上主线) | lingQiao·huaJing | 非 boss | 56000/1600 |
| 4 | stage_15_04 | desert 沙海 | 沙海马贼总瓢把子(章中 Boss·stat 门槛无相位·配 defeat) | gangMeng·huaJing | 章中 Boss | 58000/1720 |
| 5 | stage_15_05 | frontier 阳关城下 | 守关老将「借关一战」(末 Boss·真解·配 defeat) | yinRou·dengFeng | 末 Boss | **59500/1850** |

- Boss 位 **{4,5}**·15_01 不跨章 prevStageId·15_02..05 章内单链。
- 速度 322→336(承 Ch14 300→320)·diffMult 16.2→17.0(承 16.0)·baseExpReward 58/60/62/82/102(沿 +6/关轨迹·章计 +364)。

## 末 Boss(15_05)+ 真解 = 新写「孤城闭」(skill 计数 253→254)
- **守关老将**:镇阳关数十年的中原老将,大隐于关,西陲最后一双眼睛。当年少年出关他抬手放行(Ch4 回旋),如今绝顶掌门再至,他拦路「借关一战」——**对称 Ch14「借山一战」**:中原送他出关前,要亲手称一称「留符人」的分量。胜后关门为开、老将放行一句收官,望关外收束绝顶段。**不占用 yang_guan**(关外西凉霸主·宗师段)。
- **真解 = `skill_gu_cheng_bi`(孤城闭·新写·tier5·yinRou·mainline_drop)**:「长烟落日孤城闭」西北边塞意象(季节接 Ch14 尾「秋风初起」),守关人以静制动、落闩锁关的本命杀法。mult **4800**(对齐绝顶真解档=一览众山/十荡十决)·qiDelta -30·CD 4·powerSkill·single·visualEffect gate_seal·proficiency 照既有阴柔真解三层模板。挂 15_05 `chargeSkillId=dropSkillManualId` 双用+两相位 chargeCounter(照 14_05 模板)+`standaloneBossManualIds` 白名单 +1(`wave_b_content_redline_test.dart:136`·第 8 门)。
- **命名避撞**:候选「关山月」与塔 15 残页 `skill_guan_shan_ba_ji` 关山拔戟(`skills.yaml:3126`)撞「关山」词根,弃。
- **school 轮换自洽**:Ch13 lingQiao/Ch14 gangMeng→**Ch15 yinRou**,绝顶三章三系各一。
- **为何新写非收编**:mount_deferred 仅剩 feng_juan(tier4)/yang_guan(tier6),**无 tier5 可收编招**——新写是唯一路径(同 Ch13 一览众山先例)。

## 复用策略(池盘点 2026-07-23 实测)
- **敌招**:tier5 jianghu 真身 ult×3 已被 Ch14 全部用掉(stages 用量 grep 实证)→本章**全员 ult 化**(五关皆带 ult 级=收官难度语义,vs Ch14 仅 3 关):15_01/04 复用 gangmeng ult;15_02 复用 yinrou ult;**15_03 lingqiao_jianghu_fang 三件套主线首用**(`skills.yaml:2145-2170` 主线零用·佛门系=明王拳体系配行脚僧人设);15_05 basic+skill+孤城闭。敌招零新写(新增仅真解 1 门)。
- **装备**:zhongQi 11 件池足,dropTable 主用 Ch14 未投放的 6 件(qing_xu_jian/du_long_suo/ri_yue_lun/yin_lin_jia/yu_lin_qing_jia/qing_yu_huan·equipment.yaml 实测)。
- **美术 11 图**(5 敌+cover+5 叙事背景):`known_missing_assets` 登记+errorBuilder 兜底,合并后 codex image_gen 专批;**战斗场景背景零新增**(battle_mountainpath/dock/frontier/desert 全已有)。

## §5 数值曲线(HP 封顶区收官·压缩区最后一章)
- Ch14 末 58000→Ch15 末 **59500**(<60000 硬线·头寸收官用尽);章内 52000→59500。
- 难度杠杆(HP 近顶后靠其余四轴):① 全员 ult 化;② 敌层 yuanShu→dengFeng 封顶(末 Boss 与玩家满 cap 同层=平起平坐一战);③ 攻 1450→1850(参照 ≤2000);④ diffMult 16.2→17.0;⑤ 末 Boss 两相位 chargeCounter。
- 战败风险照 boss_balance_crosstier 口径探针校准;defense_rate 绝顶档不变。
- **前瞻(留议·宗师段 spec 终拍)**:59500 后 Boss HP 硬线头寸归零,宗师段(Ch16+)难度须走机制层(§5.4 机制型 Boss 例外条款先例:脆弱窗口/结界)或届时拍板抬线——本章不决,仅登记。

## 叙事纲(13 篇·同 Ch10-14 体例·~6300 字)
- `chapter_15`:章首(钟三声辞山·官道向西·「万里关山,头一程」)+章尾(关门开·老将放行一句·立关下回望中原/望关外·绝顶段收束→宗师段 hook)。
- 10 段 stage(5 关×opening/victory)+2 defeat(15_04/15_05)。
- 母题:**「旧路新走」**——当年看这条路是远方,如今走这条路是分量;Ch4 意象(渡口/古道/沙海/关城)逐程回旋。黑名单/现代词/网文腔 grep 0·水墨克制。

## reconcile 面(within-tier 封顶·同 Ch12/14 体例·实装前 Phase-0 grep 复定行号)
- **count 70→75**:playtest CSV byte-lock 重生/game_repo mainlineCount(`game_repository_test.dart:85`)/narrative completeness+章循环 [1..15]/balance_simulator/**readable_tempo 终章门槛 stage_14_05→stage_15_05**(`readable_first_clear_tempo_diagnostic_test.dart:113`·Ch10/11 漏更教训,必改)。
- **boss 敌 30→32**/**catalog 43→45**(主线 37→39+塔 6·`boss_memory_providers_test.dart:50`)。
- **skill 计数 253→254 三处**(`skill_count_contract_test.dart:38`/`skill_qi_redline_test.dart:57`/game_repo)+**GDD 字串**「253 招(213+40)」同步(`skill_count_contract_test.dart:45`·拆分桶实装核定)。
- **progression 级联(逐值实测禁猜)**:release_budget 全内容 Lv109(`progression_release_budget_test.dart:101`)→**预估 ≤112**(+364 exp 沿每章 +3 轨迹·实测终拍);idle_horizon 锚全重校+**test 名 stale 顺修**(`progression_idle_horizon_simulation_test.dart:60` 名写「Lv106/余量715/缺口6635」断言已 109/1079——Ch14 收账遗留,本批同步)。
- **cap 33→35 四站点**(memory feedback_wuxia_release_cap_raise_reconcile):`numbers.yaml:206` 值+注释/挂载完备 !mountDeferred 豁免复核/R5.3 cap-agnostic 复核/「绝顶·圆熟」stale 文案 grep。
- **生产可见性**:chapter_list `[1..15]`/strings chapter15Title·Hint+两 switch/mainMenuHint「14 章 70 关→15 章 75 关」(`strings.dart:1370`)/main_menu·status_summary `<=15`/boss_memory_key chNum=15。
- material 结晶沿放宽口径复核(15_04 [56,66]/15_05 [58,68] 沿轨迹)/mainline_stage_curve +Ch15 映射(cap-agnostic)/GDD §8.1 章表+招式池同步。

## 红线守卫
- 末 Boss **59500 < 60000** 硬红线·真解 mult 4800 ≤ 8000·敌攻 ≤1850(参照 ≤2000)。
- 三系锁死:敌招全 tier5 jianghu/fang 档·真解 tier5·不降档充数。
- 15_01 缺 prevStageId·末 Boss chargeSkillId 配 `onEnterMechanic: chargeCounter` 成对·章中 Boss stat 门槛无 bossPhases。
- 在线=离线·反主流清单不碰·收官难度走层差+ult 密度非数值膨胀。

## 10. 待拍板汇总
1. **章名**:A「关山一程」(取 epilogue「万里关山的头一程」·「山外青山→山外来客」山字弧收束转「关山」开新弧)/B「头一程」/C「西行辞山」。**推荐 A**。
2. **cap**:A 33→35(dengFeng 绝顶封顶·照 Ch12 一流收官 26→28 体例)/B 33→34 留半步(收官不封顶·违体例)。**推荐 A**。
3. **真解**:A 新写「孤城闭」(yinRou·mult 4800·CD 4·计数 253→254·绝顶三章三系各一)/B 新写但改刚猛或灵巧向(破三系各一)/C 本章无真解(破 Ch8-14 每章一门体例)。**推荐 A**(无 tier5 deferred 可收编,收编路线不存在)。
4. **末 Boss 人设**:A 阳关守关老将「借关一战」(对称 Ch14 借山一战·Ch4 回旋·不占 yang_guan 伏笔)/B 西凉先遣拦路(侵占宗师段西凉弧)。**推荐 A**。
5. **佛门 fang 系上主线**(15_03 行脚僧·lingqiao_fang 三件套主线首用):A 用(河西佛窟文化贴地+招池新鲜感)/B 全真身系(fang 继续只在 Ch4/塔)。**推荐 A**。
6. **美术**:A known_missing 登记+合并后 codex 专批(惯例)/B 实装批内联出图。**推荐 A**。
7. **Lv guard**:A 预估 ≤112 实装实测终拍(沿 106→109 轨迹)/B 压回(需砍经验·破曲线单调)。**推荐 A**。
8. **宗师段 HP 头寸(前瞻留议)**:A 倾向机制层扩难(§5.4 例外条款先例·HP 钉 59500)/B 届时抬硬线。**本章仅登记方向倾向,正式拍留宗师段 spec**。推荐 A 倾向。

## 实装建议
- coupled xhigh 批整章一次做完(同 Ch10-14)·先全 Phase-0 grep 复定站点(本 spec 行号 2026-07-23 实测·实装时重核防 drift)。
- 合并前主 checkout build_runner→analyze 0→批末全量;破坏证红(真解 mult 9000>8000 RED→还原绿)在 **commit 后**做(守 feedback_break_red_after_commit)。
- 派单:**kimi 2026-07-26 10:10 前配额不可用**→本章实装 Claude 主执行(coupled xhigh)或 codex+Claude Gate;memory 必读 `feedback_wuxia_add_mainline_chapter_reconcile`。
