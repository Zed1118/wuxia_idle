# DeepSeek 端产出清单

> 本文档供 Mac/Opus 端查阅。列出了 DeepSeek 端所有产出的 id 及其对应文件，方便在数值 yaml 中定义同名 id 进行联结。
>
> **产出日期**：2026-05-10
> **总文件数**：143 个内容文件
> **协作约定**：Mac 端在数值 yaml 中定义这些 id 后，游戏加载层即可通过 id 匹配文案。id 不一致会抛错。

## 仓库信息

| 项目 | 内容 |
|---|---|
| 仓库地址 | https://github.com/Zed1118/wuxia_idle |
| SSH | `git@github.com:Zed1118/wuxia_idle.git` |
| 主分支 | `main` |
| 平台 | Windows + Mac 双端 |
| 引擎 | Flutter Desktop (Windows) |
| Mac 端职责 | `lib/`、`data/*.yaml`（根目录数值文件）、`test/`、`GDD.md` |
| Windows/DeepSeek 端职责 | `data/narratives/`、`data/lore/`、`data/events/` |
| 冲突原则 | 文案冲突以 DeepSeek 端为准，代码/数值冲突以 Opus 端为准 |
| 克隆命令 | `git clone git@github.com:Zed1118/wuxia_idle.git` |

---

## 1. 章节卷首/卷尾（3 章）

| id | 标题 | 文件 |
|---|---|---|
| chapter_01 | 学武出山 | `data/narratives/chapters/chapter_01.yaml` |
| chapter_02 | 武林初识 | `data/narratives/chapters/chapter_02.yaml` |
| chapter_03 | 名扬江湖 | `data/narratives/chapters/chapter_03.yaml` |

每章包含 `prologue`（卷首，200-300 字）和 `epilogue`（卷尾，100-200 字）。

## 2. 主线关卡短文（15 关）

### 第一章：学武出山
| id | 标题 | 文件 |
|---|---|---|
| stage_01_01 | 山门之外 | `data/narratives/stages/stage_01_01.yaml` |
| stage_01_02 | 荒山野店 | `data/narratives/stages/stage_01_02.yaml` |
| stage_01_03 | 黑风岭 | `data/narratives/stages/stage_01_03.yaml` |
| stage_01_04 | 洛阳城外 | `data/narratives/stages/stage_01_04.yaml` |
| stage_01_05 | 风雨渡口 | `data/narratives/stages/stage_01_05.yaml` |

### 第二章：武林初识
| id | 标题 | 文件 |
|---|---|---|
| stage_02_01 | 城南客栈 | `data/narratives/stages/stage_02_01.yaml` |
| stage_02_02 | 茶馆论剑 | `data/narratives/stages/stage_02_02.yaml` |
| stage_02_03 | 春水堂 | `data/narratives/stages/stage_02_03.yaml` |
| stage_02_04 | 城外校场 | `data/narratives/stages/stage_02_04.yaml` |
| stage_02_05 | 巷中夜雨 | `data/narratives/stages/stage_02_05.yaml` |

### 第三章：名扬江湖
| id | 标题 | 文件 |
|---|---|---|
| stage_03_01 | 古道西风 | `data/narratives/stages/stage_03_01.yaml` |
| stage_03_02 | 许昌擂台 | `data/narratives/stages/stage_03_02.yaml` |
| stage_03_03 | 山寺夜话 | `data/narratives/stages/stage_03_03.yaml` |
| stage_03_04 | 雁门旧事 | `data/narratives/stages/stage_03_04.yaml` |
| stage_03_05 | 一剑封名 | `data/narratives/stages/stage_03_05.yaml` |

每关包含 `opening`（30-80 字）、`post_victory`（20-50 字）、部分含 `post_defeat`（10-30 字，可选）。

## 3. 装备典故（45 件，7 品阶全覆盖）

### 寻常货（6 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| sheng_xiu_jian | 生锈剑 | 剑 | 1 | `data/lore/sheng_xiu_jian.yaml` |
| cu_tie_jian | 粗铁剑 | 剑 | 1 | `data/lore/cu_tie_jian.yaml` |
| zhu_gan_qiang | 竹竿枪 | 枪 | 1 | `data/lore/zhu_gan_qiang.yaml` |
| shu_pi_dun | 树皮盾 | 盾 | 1 | `data/lore/shu_pi_dun.yaml` |
| chen_tie_mian_ju | 沉铁面具 | 面具 | 1 | `data/lore/chen_tie_mian_ju.yaml` |
| han_jiu_dai | 寒酒袋 | 辅助 | 1 | `data/lore/han_jiu_dai.yaml` |

### 像样货（7 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| yan_ling_dao | 雁翎刀 | 刀 | 1 | `data/lore/yan_ling_dao.yaml` |
| liu_ye_dao | 柳叶刀 | 刀 | 1 | `data/lore/liu_ye_dao.yaml` |
| han_ya_suo | 寒鸦索 | 索 | 1 | `data/lore/han_ya_suo.yaml` |
| shi_mian_jian | 石棉肩 | 肩甲 | 1 | `data/lore/shi_mian_jian.yaml` |
| niu_jin_gong | 牛筋弓 | 弓 | 1 | `data/lore/niu_jin_gong.yaml` |
| she_gu_chang_bian | 蛇骨长鞭 | 鞭 | 1 | `data/lore/she_gu_chang_bian.yaml` |
| ma_an_xue | 马鞍靴 | 靴 | 1 | `data/lore/ma_an_xue.yaml` |

### 好家伙（6 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| qing_feng_jian | 青锋剑 | 剑 | 2 | `data/lore/qing_feng_jian.yaml` |
| mo_dao | 陌刀 | 刀 | 2 | `data/lore/mo_dao.yaml` |
| yue_ya_chan | 月牙铲 | 铲 | 2 | `data/lore/yue_ya_chan.yaml` |
| wu_gou | 吴钩 | 钩 | 2 | `data/lore/wu_gou.yaml` |
| jing_hong_gong | 惊鸿弓 | 弓 | 2 | `data/lore/jing_hong_gong.yaml` |
| qing_guang_ling | 清光铃 | 铃 | 2 | `data/lore/qing_guang_ling.yaml` |

### 利器（5 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| duan_shui | 断水 | 剑 | 2 | `data/lore/duan_shui.yaml` |
| pan_long_zhang | 盘龙杖 | 杖 | 2 | `data/lore/pan_long_zhang.yaml` |
| xue_po_bi_shou | 血珀匕首 | 匕首 | 2 | `data/lore/xue_po_bi_shou.yaml` |
| zhui_feng_yue | 追风钺 | 钺 | 2 | `data/lore/zhui_feng_yue.yaml` |
| hu_po_jian | 琥珀剑 | 剑 | 2 | `data/lore/hu_po_jian.yaml` |

### 重器（5 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| han_shuang_jian | 寒霜剑 | 剑 | 3 | `data/lore/han_shuang_jian.yaml` |
| jin_si_jia | 金丝甲 | 甲 | 3 | `data/lore/jin_si_jia.yaml` |
| nu_ma_qiang | 怒马枪 | 枪 | 3 | `data/lore/nu_ma_qiang.yaml` |
| jingang_zhuo | 金刚镯 | 镯 | 3 | `data/lore/jingang_zhuo.yaml` |
| jin_chan_jia | 金蝉甲 | 甲 | 3 | `data/lore/jin_chan_jia.yaml` |

### 宝物（5 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| cang_ming_gu_jian | 苍冥古剑 | 剑 | 3 | `data/lore/cang_ming_gu_jian.yaml` |
| tian_chan_shou_tao | 天蚕手套 | 手套 | 3 | `data/lore/tian_chan_shou_tao.yaml` |
| xue_lian_hua | 血莲花 | 暗器 | 3 | `data/lore/xue_lian_hua.yaml` |
| chi_huo_lian | 赤火链 | 锁链 | 3 | `data/lore/chi_huo_lian.yaml` |
| xing_chen_jian | 星辰剑 | 剑 | 3 | `data/lore/xing_chen_jian.yaml` |

### 神物（3 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| ri_yue_shuang_ren | 日月双刃 | 双刃 | 3 | `data/lore/ri_yue_shuang_ren.yaml` |
| xuan_tie_zhong_jian | 玄铁重剑 | 剑 | 3 | `data/lore/xuan_tie_zhong_jian.yaml` |
| yun_ji_guang | 云极光 | 剑 | 3 | `data/lore/yun_ji_guang.yaml` |

### 其他/奇门（8 件）
| id | 名称 | 类型 | 段数 | 文件 |
|---|---|---|---|---|
| po_feng_quan_tao | 破风拳套 | 拳套 | 1 | `data/lore/po_feng_quan_tao.yaml` |
| gui_tou_dao | 鬼头刀 | 刀 | 1 | `data/lore/gui_tou_dao.yaml` |
| tian_que | 天阙 | 剑 | 2 | `data/lore/tian_que.yaml` |
| sha_ying | 煞影 | 匕首 | 2 | `data/lore/sha_ying.yaml` |
| tie_gu_shan | 铁骨扇 | 扇 | 2 | `data/lore/tie_gu_shan.yaml` |
| xue_chi_jian | 血齿剑 | 剑 | 2 | `data/lore/xue_chi_jian.yaml` |
| pi_li_wan | 霹雳丸 | 暗器 | 1 | `data/lore/pi_li_wan.yaml` |
| jin_que_shan | 金雀扇 | 扇 | 1 | `data/lore/jin_que_shan.yaml` |

## 4. 奇遇事件（26 个）

每个事件均在 `data/events/<id>.yaml`，含 `opening` + 2-4 个 `choices`（每个 choice 含 `outcome_id` 和 `body`），至少有一个无伤而退选项。

| id | 标题 | 分支数 |
|---|---|---|
| bamboo_listen_rain | 听雨悟剑 | 3 |
| huang_miao_jiu_seng | 荒庙旧僧 | 3 |
| ye_du_gu_chuan | 夜渡孤船 | 3 |
| lao_jing_hui_xiang | 老井回响 | 3 |
| xue_ye_gu_qin | 雪夜古琴 | 3 |
| du_ke_wen_dao | 渡客问道 | 3 |
| shan_ya_can_bei | 山崖残碑 | 3 |
| huang_yuan_yi_zhong | 荒原遗冢 | 3 |
| cha_ting_dui_ju | 茶亭对局 | 3 |
| yu_zhong_qiao_men | 雨中敲门 | 3 |
| jiu_lou_jue_yin | 酒楼绝饮 | 3 |
| qiu_ye_wei_qi | 秋夜围棋 | 3 |
| duan_qiao_can_yue | 断桥残月 | 3 |
| feng_xue_gu_dian | 风雪古店 | 3 |
| luo_hua_jian_yuan | 落花剑缘 | 3 |
| xiang_ye_shen_ji | 乡野神祭 | 3 |
| jiang_xin_ye_hua | 江心夜话 | 3 |
| huang_sha_ke_zhan | 黄沙客栈 | 3 |
| gu_chuan_deng_ying | 孤船灯影 | 3 |
| shi_dao_shou_hu | 石岛守护 | 3 |
| jue_ding_feng_qi | 绝顶风起 | 3 |
| huang_cun_yao_ren | 荒村咬人 | 3 |
| mu_chan_dui_yin | 暮蝉对饮 | 3 |
| xing_chen_wu_dao | 星辰悟道 | 3 |
| han_mei_ying_xue | 寒梅映雪 | 3 |
| qing_lou_can_meng | 青楼残梦 | 3 |

## 5. 心法描述（22 本，70+ 招式）

全部在 `data/narratives/techniques/<id>.yaml`，每本含 `origin`（100-200 字）、可选 `mantra`、及 3-4 个 `moves`（每个 40-80 字）。

### 刚猛流（7 本）
| id | 名称 | 品阶 | 招数 | 招式 id |
|---|---|---|---|---|
| fu_hu_zhang | 伏虎掌 | 入门功 | 4 | fu_hu_jiang_long / fu_hu_hu_yue / fu_hu_lie_yang / fu_hu_hui_tou |
| tie_sha_zhang | 铁砂掌 | 入门功 | 3 | tie_sha_kai_bei / tie_sha_tui_men / tie_sha_huo_yan |
| pan_long_gun_fa | 盘龙棍法 | 常练功 | 3 | pan_long_sao_tang / pan_long_tiao_deng / pan_long_shen_long |
| jin_zhong_zhao | 金钟罩 | 名家功 | 3 | jin_zhong_ning_shen / jin_zhong_weng_ming / jin_zhong_po_ji |
| po_jun_quan | 破军拳 | 门派绝学 | 3 | po_jun_chong_zhen / po_jun_she_qiang / po_jun_duan_hou |
| wu_ying_shi_dao | 无影十刀 | 江湖秘传 | 3 | wu_ying_po_kong / wu_ying_can_xiang / wu_ying_gui_yi |
| da_jin_gang_lun_quan | 大金刚轮拳 | 失传神功 | 3 | jin_gang_jiang_mo / jin_gang_suo_long / jin_gang_lun_hui |

### 灵巧流（7 本）
| id | 名称 | 品阶 | 招数 | 招式 id |
|---|---|---|---|---|
| yan_hui_shen_fa | 燕回身法 | 常练功 | 3 | yan_hui_qing_dian / yan_hui_dao_zhuan / yan_hui_chuan_lin |
| fei_hua_jian | 飞花剑 | 常练功 | 3 | fei_hua_luo_ying / fei_hua_nian_hua / fei_hua_san_ban |
| bi_hu_gong | 壁虎功 | 名家功 | 3 | bi_hu_tie_qiang / bi_hu_you_yan / bi_hu_chuan_liang |
| chun_shui_jian_fa | 春水剑法 | 门派绝学 | 3 | chun_shui_bo_guang / chun_shui_chun_han / chun_shui_liu_shen |
| jing_hong_shen_fa | 惊鸿身法 | 门派绝学 | 3 | jing_hong_pian_ying / jing_hong_rao_yun / jing_hong_jing_hong |
| yi_yang_zhi | 一阳指 | 失传神功 | 3 | yi_yang_dian_xue / yi_yang_po_zhao / yi_yang_guan_tong |
| qing_gang_xin_fa | 青冈心法 | 入门功 | 3 | qing_gang_gu_ben / qing_gang_an_jin / qing_gang_zhang_ya |

### 阴柔流（6 本）
| id | 名称 | 品阶 | 招数 | 招式 id |
|---|---|---|---|---|
| hui_chun_jue | 回春诀 | 常练功 | 3 | hui_chun_ning_xi / hui_chun_jie_du / hui_chun_jiu_ji |
| han_bing_mian_zhang | 寒冰绵掌 | 名家功 | 3 | han_bing_tou_gu / han_bing_san_cun / han_bing_han_mei |
| chan_si_jin | 缠丝劲 | 名家功 | 3 | chan_si_rao_zhi / chan_si_bu_wang / chan_si_chou_si |
| she_hun_da_fa | 摄魂大法 | 江湖秘传 | 3 | she_hun_ning_mu / she_hun_duo_she / she_hun_an_du |
| xuan_yin_du_gong | 玄阴毒功 | 江湖秘传 | 3 | xuan_yin_yin_du / xuan_yin_du_zhang / xuan_yin_bi_guan |
| ming_yu_shen_gong | 冥玉神功 | 失传神功 | 3 | ming_yu_ning_zhi / ming_yu_cui_gu / ming_yu_huan_sheng |

### 三系兼修/特殊（2 本）
| id | 名称 | 品阶 | 招数 | 招式 id |
|---|---|---|---|---|
| tai_xu_wu_xiang_gong | 太虚无相功 | 传说神功 | 3 | tai_xu_ru_jing / tai_xu_qian_ying / tai_xu_wu_wo |
| hun_yuan_gui_yuan_gong | 混元归元功 | 传说神功 | 3 | hun_yuan_gui_yuan / hun_yuan_wan_xiang / hun_yuan_wu_ji |

## 6. 武学领悟独立招式（35 招）

全部在 `data/narratives/techniques/insights/<id>.yaml`，每招含 `name`、`description`（40-80 字）、`prerequisite_hint`（氛围提示，不写数值条件）。

| id | 名称 | id | 名称 |
|---|---|---|---|
| ting_yu_jian | 听雨 | po_feng_yi_ji | 破风一击 |
| han_ya_du_jiang | 寒鸦渡江 | xue_ye_wu_hen | 雪夜无痕 |
| can_bei_zhang_feng | 残碑掌风 | qi_mai_tong_shen | 七脉通神 |
| shuang_jiang_man_tian | 霜降漫天 | du_jiang_bei_wang | 渡江北望 |
| gu_miao_zhong_sheng | 古庙钟声 | yi_qi_jue_chen | 一气绝尘 |
| ye_luo_wu_sheng | 叶落无声 | huang_sha_bi_ri | 黄沙蔽日 |
| qiu_shui_tian_ya | 秋水天涯 | xiao_xiang_ye_yu | 潇湘夜雨 |
| tie_suo_heng_jiang | 铁索横江 | ming_deng_zhi_yin | 明灯指引 |
| can_juan_can_zhao | 残卷残招 | liu_shui_wu_qing | 流水无情 |
| xing_luo_qi_qi | 星落七棋 | han_feng_che_gu | 寒风彻骨 |
| jing_di_wang_yue | 井底望月 | luo_ye_gui_gen | 落叶归根 |
| shan_quan_ji_jian | 山泉激涧 | yan_hui_xu_ying | 燕回虚影 |
| shuang_dong_qian_li | 霜冻千里 | can_yang_ru_xue | 残阳如血 |
| po_lang_yi_dao | 破浪一刀 | wu_hen_zhi_ji | 无痕之迹 |
| long_yin_shen_jian | 龙吟深涧 | yue_xia_du_ying | 月下独影 |
| ku_chan_bu_dong | 枯蝉不动 | yi_dian_qian_jun | 一点千钧 |
| cang_long_zhua | 苍龙爪 | feng_zhong_can_zhu | 风中残烛 |
| gu_dao_xi_feng | 古道西风 | | |

## 7. 延续典故模板（7 个）

全部在 `data/lore/_templates/<template_id>.yaml`，含 `placeholders` 占位符，由引擎运行时填充。

| template_id | 触发事件 | 占位符 |
|---|---|---|
| defeat_named_boss | 击败具名 Boss | boss_name / location / season |
| rescue_npc | 救助 NPC | npc_name / location / weather |
| train_at_location | 在某地苦练 | location / move_name / count |
| master_legacy | 师徒传承 | master_name / disciple_name / season |
| breakthrough_realm | 突破境界 | realm_name / location |
| strengthen_milestone | 强化里程碑 | level / smith_name |
| resonance_tier_up | 共鸣度跨阶 | resonance_tier |

## 8. 江湖见闻录百科（18 条）

全部在 `data/narratives/codex/<id>.md`，markdown 格式，200-500 字/条。

| id | 标题 |
|---|---|
| realm | 境界 |
| techniques_and_styles | 心法与流派 |
| equipment_tiers | 装备与品阶 |
| master_disciple | 师徒传承 |
| resonance | 共鸣度·人剑合一 |
| strengthening | 强化与磨剑石 |
| retreat | 闭关与时辰 |
| major_sects | 三大派概况 |
| jianghu_rules | 江湖通用规矩 |
| hidden_weapons | 暗器与毒 |
| encounter_system | 奇遇与机缘 |
| weapon_forging | 兵器铸造流派 |
| jianghu_medicine | 江湖医药 |
| three_styles_detail | 三流派详解 |
| battle_taboos | 武斗禁忌 |
| jianghu_ranks | 江湖九流 |
| famous_battles | 名战录 |
| lost_techniques | 失传绝学考 |

---

## 协作对齐要点

1. **id 是唯一联结键**。Mac 端在 `data/encounters.yaml`、`data/equipment.yaml`、`data/techniques.yaml`、`data/stages.yaml` 中定义同名 id 即可完成联结。

2. **id 命名规则**：全小写拼音 + 下划线，不带音标（如 `qing_feng_jian`，不是 `qīng fēng jiàn`）。

3. **DeepSeek 端不写数值**。所有文案文件不含 `damage`、`hp`、`reward` 等数值字段，也不含 `trigger` 条件——这些由 Mac 端在对应数值 yaml 中定义。

4. **工作流**：Mac 端先在数值 yaml 中定义 id → DeepSeek 端按 id 写对应文案。当前这批是反过来（文案先行），所以 Mac 端建数值 yaml 时需参考本清单的 id。

5. **校验**：`dart run tool/validate_content.dart` 会检查 id 是否齐全、字段是否缺、字数是否超限。
