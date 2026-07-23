# Ch14「山外来客」设计 spec(已拍板 · 实装依据)

**日期**:2026-07-23 · **载体**:main 直落(bg 会话·纯文档)
**境界阶**:绝顶(jueDing·绝对层 29-35)· 主线第 14 章 · **within-tier 抬层**(同 Ch11/12 体例,非 cross-tier)
**状态**:**已拍板冻结**(2026-07-23 用户七项全按推荐:章名「山外来客」/cap 31→33/shi_dang 收编+mult 4800/feng_juan 留 deferred 归宗师段/yang_guan 伏笔埋/美术 known_missing 后批/Lv guard 预估 ≤109 实测终拍)

---

## 定位
- **绝顶段第二章**(承 Ch13「山外青山」首章·cap 31=绝顶·熟练 shuLian,`numbers.yaml:206` 实测)。
- `requiredRealm: jueDing` 不变·章内敌层 **shuLian→yuanShu** 递进(照 Ch11 一流第二章模板)。
- 三系锁死不变:绝顶 ↔ 重器 zhongQi ↔ 江湖秘传 jiangHuMiChuan。
- **releaseTier 无变化**(jueDing 段内抬层)——红线⑦/挂载完备**不新触发**,影响面显著小于 Ch13 cross-tier。

## 承接 hook(chapter_13.yaml epilogue 原文实读)
- 「他把那枚凉铜符压在峰顶的石下,符面向着来路」——主角从**接符人变留符人**,传承弧完成态。
- 「绝顶之上没有更高的山了,可有**比山更远的东西**」——Ch14 题眼:不是更高,是**更远**。主角还没来得及走出去,「远」先找上门:**西凉马战宗师循名叩山**。
- 「成为江湖的人,脚下的路才刚起了个头」——成为江湖的第一课:名声引来的不是接符的后来者,是来试斤两的远客。

## 主线剧情(西凉叩山 · 5 关=马队上山五程)
| 关 | id | biome(全复用现有枚举) | 侧面 | 流派/层 | Boss | HP/Atk 锚 |
|---|---|---|---|---|---|---|
| 1 | stage_14_01 | mountainPath 山道 | 马蹄先声(开道信使·「马队在山道上敲了三天」) | gangMeng·shuLian | — | 48000/1350 |
| 2 | stage_14_02 | inn 山脚驿馆 | 西凉人不空手拜山(先锋讨教) | lingQiao·shuLian | — | 50000/1400 |
| 3 | stage_14_03 | mountainForest 山林 | 马队里的西域剑客(阴柔位·非 boss) | yinRou·yuanShu | 非 boss | 53000/1480 |
| 4 | stage_14_04 | drillGround 演武旧坪 | 副将「前五荡」(章中 Boss·stat 门槛无相位·配 defeat) | gangMeng·yuanShu | 章中 Boss | 55000/1580 |
| 5 | stage_14_05 | 沿 13_05 绝顶平台同 biome | 马战宗师借绝顶一战(末 Boss·真解·配 defeat) | gangMeng·yuanShu | 末 Boss | **58000/1700** |

- Boss 位 **{4,5}**·14_01 不跨章 prevStageId·14_02..05 章内单链·数值详 §5。

## 末 Boss(14_05)+ 真解 = shi_dang 收编(零新招)
- **西凉马战宗师**:中原绝顶换了新人的消息传到西凉,他万里叩山,只为「借绝顶一战」——主角站上被看的位置后来的第一个人,却不循他留的符,自带西凉的路数。胜后他把十荡十决留下,临行一句指向西凉更老的人物(**宗师段 `skill_yang_guan_wu_gu_ren`(阳关无故人·tier6·西凉霸主·`skills.yaml:2989` 注释「留宗师段阳关/西凉回访章收编」)伏笔**,三段西凉弧 feng_juan/shi_dang/yang_guan 串线)。
- **真解 = `skill_shi_dang_shi_jue`(十荡十决·tier5·gangMeng·mainline_drop·`skills.yaml:2954`)**:2026-07-22 注释已拍定「留 Ch14/15 绝顶压场章真解收编」——本章兑现。收编动作:删 `mount_deferred: true`(`:2968`)+ 挂 14_05 `chargeSkillId`(chargeCounter 两相位 + dropSkillManual 双用·照候峰翁模板)+ `standaloneBossManualIds` 白名单 +1。
- **[balance] mult 3600→4800**(拍板 §10#3):现值 3600 是 tier4 档旧锚,低于 Ch13 真解一览众山 4800——玩家后章真解弱于前章=爽感倒挂;抬至绝顶真解档 4800(守 ≤8000),CD 5(vs 一览众山 CD 4)保留为刚猛向差异化。proficiency 已配(刚猛向沿青锋绝锚)零改。
- school 轮换自洽:Ch10 yinRou/Ch11 gangMeng/Ch12 yinRou/Ch13 lingQiao→**Ch14 gangMeng**。

## 复用策略(池盘点 2026-07-23 实测·零新写)
- **敌招**:Ch13 刻意未用的 jianghu **ult ×3**(`skill_*_jianghu_ult`·mult 4000)本章上(难度递进的天然下一档)+ fang 变体余量(仅 stage_04_05 用过 3 处)——**零新写,连真解都是收编**,全章 skill 计数 **253→253 零变**。
- **装备**:zhongQi 11 件池足,五关 dropTable 复用搭配(weapon 1.0 + armor/accessory 0.3-0.5 沿体例)。
- **美术 11 图**(5 敌+cover+5 背景):照惯例 `known_missing_assets` 登记 + errorBuilder 兜底,合并后 codex image_gen 专批(拍板 §10#6)。

## §5 数值曲线(**HP 压缩区**·本章设计核心约束)
- Ch13 末 Boss 56000,Boss 血 **<60000 硬红线只剩 4000 头寸**且绝顶段还剩 Ch15 收官——曲线必须压扁:Ch14 末 Boss **58000**,给 Ch15 留 ~59500 封顶头寸;HP 增幅从 Ch12→13 的 +40% 压到 +3.6%。
- **难度杠杆转移**(HP 让位):① 敌招升 ult 档(4000 vs Ch13 skill 3200);② 敌层 shuLian→yuanShu(高于玩家进章 cap 31=shuLian,末 Boss +2 层);③ 攻击续曲线 1350→1700(参照线 ≤2000);④ difficultyMultiplier 15.0→15.2-16.0;⑤ 末 Boss 两相位 chargeCounter。
- 战败风险照 `boss_balance_crosstier` 口径 balance 探针校准;defense_rate 0.25(绝顶档)不变。

## 叙事纲(13 篇·同 Ch10-13 体例·~6300 字)
- `chapter_14`:章首(半山安顿·山下马蹄声起·「比山更远的东西,先骑着马来了」)+ 章尾(收十荡十决·远客下山·望向万里关山外→Ch15 hook:绝顶段收官/更远的江湖)。
- 10 段 stage(5 关 × opening/victory)+ 2 defeat(14_04/14_05)。
- 母题:「成为江湖」的第一课——被看的位置站稳之前,先接住循名而来的拳头。黑名单/现代词/网文腔 grep 0 命中·水墨克制。

## reconcile 面(within-tier·同 Ch11/12 体例·**实装前 Phase-0 grep 复定行号**)
- **count 65→70**:playtest CSV byte-lock 重生 / game_repo mainlineCount / narrative completeness + 章循环 [1..14] / balance_simulator / **readable_tempo 终章门槛 stage_13_05→stage_14_05**(Ch10/11 曾漏更此站·Ch13 spec 实证教训,必改)。
- **boss 敌 28→30** / **catalog 41→43** / 白名单 standaloneBossManualIds +shi_dang。
- **skill 计数零变**(253·收编不加招)——但 mult 抬档为 [balance] 项。
- **progression 级联(逐值实测禁猜)**:release_budget cumExp 位移 / idle_horizon 锚(现 Lv106/abs11/余量715/缺口6635·`progression_idle_horizon_simulation_test:59` 实测)全重校;**Lv guard ≤106→预估 ≤109**(沿每章 +3 轨迹·实测定·拍板 §10#7)。
- **生产可见性**:chapter_list `[1..14]` / strings chapter14Title·Hint + 两 switch / mainMenuHint「14 章 70 关」/ main_menu·status_summary `<=14` / boss_memory_key chNum=14。
- material 结晶软线沿放宽口径复核 / mainline_stage_curve +Ch14→jueDing 映射(cap-agnostic)/ GDD §8.1 章表+招式池挂载态同步 / `numbers.yaml:206` cap 31→33 + cap-value 断言测。

## 红线守卫
- 末 Boss **58000 < 60000** 硬红线·真解 mult 4800 ≤ 8000·敌攻 ≤1700(参照 ≤2000)。
- 三系锁死:敌招全 jiangHuMiChuan 档(ult/fang)·真解 tier5·不降档充数。
- 14_01 缺 prevStageId·末 Boss chargeSkillId 配 `onEnterMechanic: chargeCounter` 成对·章中 Boss stat 门槛无 bossPhases。
- 在线=离线·反主流清单不碰·爽感走表现层(真解抬档是修倒挂非膨胀)。

## 10. 待拍板汇总
1. **章名**:A「山外来客」(对仗承「山外青山」·双关:主角眼里的山外来人/来客眼里主角是山)/ B「关山来客」/ C「借峰一战」。**推荐 A**。
2. **cap**:A 31→33(yuanShu·对称 Ch11 第二章体例·预留 Ch15→35 封顶)/ B 31→32 小步。**推荐 A**。
3. **shi_dang 收编 + [balance] mult**:A 收编为末 Boss 真解·mult 3600→4800 对齐绝顶档(CD 5 保留差异化)/ B 收编保 3600(爽感倒挂)/ C 另新写 1 招(违 07-22 注释拍定)。**推荐 A**。
4. **feng_juan(tier4·大漠·灵巧·`:2947`)**:A 继续 deferred·注释更新指向宗师段西凉弧一并处置(Ch14 引入西凉线后它有了自然归宿预期)/ B Ch14 顺手收编(绝顶山巅与大漠流沙意象仍不搭)/ C 否决删除。**推荐 A**。
5. **末 Boss 人设**:A 西凉马战宗师+临行一句埋 yang_guan 宗师段伏笔 / B 不埋伏笔(西凉线 Ch14 即止)。**推荐 A**——三段西凉弧(tier4/5/6)一线贯穿,宗师段回访章素材已备。
6. **美术**:A known_missing 登记+合并后 codex 专批(惯例)/ B 实装批内联出图。**推荐 A**。
7. **Lv guard**:A 预估 ≤109 实装期实测终拍(沿 103→106 轨迹)/ B 压回(需砍经验·连锁大)。**推荐 A**。

## 实装建议
- coupled xhigh 批整章一次做完(同 Ch10-13)·先全 Phase-0 grep 复定站点(本 spec 行号 2026-07-23 实测·实装时重核防 drift)。
- 合并前主 checkout build_runner → analyze 0 → 批末全量;破坏证红(真解 mult 9000>8000 RED→还原绿)在 **commit 后**做(守 `feedback_break_red_after_commit`)。
- 派单建议:kimi 主执行 + Claude Gate(沿本批三单模式);memory 必读 `feedback_wuxia_add_mainline_chapter_reconcile`。
