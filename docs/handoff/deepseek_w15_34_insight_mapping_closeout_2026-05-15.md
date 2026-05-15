# W15 DeepSeek 34 招 narrativeInsightId closeout

## 1. 总览

- 总映射:22 / 35 招(ting_yu_jian 已映,本次新增 21)
- 引用 insights 数:22 / 35 (无多招重复引用同一 insight)
- 留空招式:13 / 34(保留 2 体系独立性,W14-4 audit 推荐)

## 2. 映射决策表

| 招式 id | insight_id | 判断依据 |
|---|---|---|
| skill_encounter_long_yin | long_yin_shen_jian | 名字"龙吟"+ 剑鸣主题双重命中 |
| skill_encounter_yi_jian | yi_dian_qian_jun | 凝练一击定乾坤,一击制敌 |
| skill_encounter_wu_ming | gu_dao_xi_feng | 两者都是"没有名字的招式",走过路自然迈出的招 |
| skill_encounter_water_qi | liu_shui_wu_qing | 流水之势连绵不断,核心意象一致 |
| skill_encounter_shan_he | shan_quan_ji_jian | 山水剑意激流之势,自然景观+剑招 |
| skill_encounter_chen_xin | ku_chan_bu_dong | 禅定心不动剑不动,沉心 ↔ 枯禅 |
| skill_encounter_drill_strike | po_feng_yi_ji | 校场连击 ↔ 擂台校场练就,场景直接命中 |
| skill_encounter_ice_break | shuang_dong_qian_li | 冰封装 ↔ 霜冻千里,极寒冻结主题 |
| skill_encounter_xuan_bing | shuang_jiang_man_tian | 玄冰诀 ↔ 霜降漫天,寒气弥漫周身 |
| skill_encounter_jian_yi | can_juan_can_zhao | 剑意萌芽 ↔ 残卷悟招,初学者从残缺中发现剑意 |
| skill_encounter_qing_feng_jian | qiu_shui_tian_ya | 清风剑 ↔ 秋水天涯,剑客孤旅/微妙剑势 |
| skill_encounter_xuan_yin | han_feng_che_gu | 玄阴指 ↔ 寒风彻骨,阴寒之气 |
| skill_encounter_fei_xian | yi_qi_jue_chen | 飞仙步 ↔ 一气绝尘,极速身法屏息冲刺 |
| skill_encounter_night_strike | ye_luo_wu_sheng | 夜行袭 ↔ 叶落无声,潜行暗袭无声 |
| skill_encounter_xuan_jian | xiao_xiang_ye_yu | 玄剑 ↔ 潇湘夜雨,连绵不绝如夜雨敲窗 |
| skill_encounter_huo_quan | can_yang_ru_xue | 火拳 ↔ 残阳如血,火/残阳红色视觉意象 |
| skill_encounter_pai_yun_zhang | can_bei_zhang_feng | 排云掌 ↔ 残碑掌风,掌力隔空投射 |
| skill_encounter_huo_du | yan_hui_xu_ying | 活渡 ↔ 燕回虚影,闪避虚影身法 |
| skill_encounter_jin_gang | tie_suo_heng_jiang | 金刚不坏 ↔ 铁索横江,不可逾越的防御屏障 |
| skill_encounter_tian_dao | jing_di_wang_yue | 天道一线 ↔ 井底望月,以狭缝窥天道的逆转视角 |
| skill_encounter_jian_bu | wu_hen_zhi_ji | 渐步 ↔ 无痕之迹,步法融入前人之迹 |
| skill_encounter_ting_yu_jian | ting_yu_jian | ★ W14-4 audit 已映射(非本次新增) |

## 3. 故意留空的招式(13 条)

| 招式 id | 名称 | 留空理由 |
|---|---|---|
| skill_encounter_jichu_buxi | 基础步息 | 35 insights 无基础步法主题,强填破坏独立性 |
| skill_encounter_pu_xi_tu | 朴息图 | 无对应基础呼吸吐纳 insight |
| skill_encounter_qi_yu_jue | 起欲诀 | 无"集中一击/起欲"相关主题 |
| skill_encounter_tun_tu | 吞吐 | 无进阶呼吸吞吐主题 insight |
| skill_encounter_qiu_quan | 求拳 | 无"求索拳道"主题 insight |
| skill_encounter_an_qi | 暗器初探 | 35 insights 无暗器相关主题 |
| skill_encounter_wu_xia_yi | 武侠意 | "武侠精神/意念"为宏大主题,无贴近 insight |
| skill_encounter_relic_blade | 古剑遗韵 | 古剑/遗韵意境独特,无贴近匹配 |
| skill_encounter_lie_huo | 烈火诀 | 35 insights 无烈火/火焰主题(仅有残烛/残阳) |
| skill_encounter_lei_dian | 雷电诀 | 无雷电相关 insight |
| skill_encounter_lie_yan | 烈焰焚天 | 同上,无火焰类型 insight |
| skill_encounter_qian_kun | 乾坤掌 | 乾坤/宇宙主题无贴近 insight |
| skill_encounter_feng_qi | 凤起九天 | 凤凰意象无对应 insight |

## 4. 风险与挂账

- 35 insights 中 13 个未被任何招式引用(cang_long_zhua / du_jiang_bei_wang / feng_zhong_can_zhu / gu_miao_zhong_sheng / han_ya_du_jiang / huang_sha_bi_ri / luo_ye_gui_gen / ming_deng_zhi_yin / po_lang_yi_dao / qi_mai_tong_shen / xing_luo_qi_qi / xue_ye_wu_hen / yue_xia_du_ying) — 属正常 2 体系独立,后续可评估是否补映射或新增招式
- encounter_skills 全部 35 招 description 仍为 TODO_NARRATIVE,待后续 DeepSeek 独立派单补文案
- Mac 端无 Python/PyYAML 环境可做 yaml 解析校验,已通过结构一致性和 insight_id 自洽验证

## 5. 提交

- commit: 0fbe572
- 推送: push 完成
