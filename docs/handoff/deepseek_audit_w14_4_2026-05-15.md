# DeepSeek W14-4 audit report (2026-05-15)

## 1. 结论
任务 A/B/C/D 全部完成。lore 45 orphan 归档、events 23 orphan 归档、insights vs encounter_skills 对齐 audit 完成（匹配率 1/35）、IDS_REGISTRY.md 修正 143→326 并补 W14-2/W14-3 新 ID。

## 2. 数据快照
- HEAD: 8019e1e (audit 前)
- equipment.yaml: 35 件 (weapon_*/armor_*/accessory_* 命名体系)
- encounters.yaml: 15 条
- encounter_skills.yaml: 35 招 (skill_encounter_* 前缀)
- lore/: 45 → 0 主目录 + 45 archive
- events/: 38 → 15 主目录 + 23 archive
- insights/: 35

## 3. 任务 A 完成情况 · lore vs equipment 对齐

### 结果
- 匹配 lore: **0 个**
- orphan 归档: **45 个** (全部移入 `data/lore/_archive/`)
- equipment 缺 lore: **35 个** (全部)

### 分析
`data/lore/` 的 45 个 yaml 文件名（如 `sheng_xiu_jian.yaml`、`qing_feng_jian.yaml`）对应的是 IDS_REGISTRY.md 中旧版 `eq_tier*` 装备体系，与 `data/equipment.yaml` 的 35 件装备（`weapon_xunchang_tie_jian` 等）命名完全不同，**0 个严格匹配**。

`equipment.yaml` 中 35 件装备的 `presetLoreIds` 字段全为空 `[]`，说明装备→lore 关联尚未建立。

### 45 orphan lore 归档清单
`cang_ming_gu_jian`, `chen_tie_mian_ju`, `chi_huo_lian`, `cu_tie_jian`, `duan_shui`, `gui_tou_dao`, `han_jiu_dai`, `han_shuang_jian`, `han_ya_suo`, `hu_po_jian`, `jin_chan_jia`, `jin_que_shan`, `jin_si_jia`, `jing_hong_gong`, `jingang_zhuo`, `liu_ye_dao`, `ma_an_xue`, `mo_dao`, `niu_jin_gong`, `nu_ma_qiang`, `pan_long_zhang`, `pi_li_wan`, `po_feng_quan_tao`, `qing_feng_jian`, `qing_guang_ling`, `ri_yue_shuang_ren`, `sha_ying`, `she_gu_chang_bian`, `sheng_xiu_jian`, `shi_mian_jian`, `shu_pi_dun`, `tian_chan_shou_tao`, `tian_que`, `tie_gu_shan`, `wu_gou`, `xing_chen_jian`, `xuan_tie_zhong_jian`, `xue_chi_jian`, `xue_lian_hua`, `xue_po_bi_shou`, `yan_ling_dao`, `yue_ya_chan`, `yun_ji_guang`, `zhu_gan_qiang`, `zhui_feng_yue`

### 35 件 equipment 缺 lore（留下次补）
`weapon_xunchang_tie_jian`, `weapon_xunchang_zhe_dao`, `weapon_xunchang_ruan_bian`, `armor_xunchang_bu_yi`, `accessory_xunchang_yu_pei`, `weapon_xiangyang_gang_dao`, `weapon_xiangyang_chang_jian`, `weapon_xiangyang_jiu_jie_bian`, `armor_xiangyang_pi_jia`, `accessory_xiangyang_yin_jie`, `weapon_haojiahuo_qing_feng_jian`, `weapon_haojiahuo_xuan_hua_fu`, `weapon_haojiahuo_chan_si_suo`, `armor_haojiahuo_jin_pao`, `accessory_haojiahuo_yu_pei_lao`, `weapon_liqi_long_quan`, `weapon_liqi_pan_long_dao`, `weapon_liqi_lian_zi_bian`, `armor_liqi_xuan_tie_jia`, `accessory_liqi_fei_yu_pei`, `weapon_zhongqi_po_zhen_chui`, `weapon_zhongqi_qing_xu_jian`, `weapon_zhongqi_du_long_suo`, `armor_zhongqi_yin_lin_jia`, `accessory_zhongqi_qing_yu_huan`, `weapon_baowu_xuan_tian_fu`, `weapon_baowu_chang_hong_jian`, `weapon_baowu_xue_lian_bian`, `armor_baowu_jin_si_jia`, `accessory_baowu_yu_long_pei`, `weapon_shenwu_po_jun_dao`, `weapon_shenwu_tian_wen_jian`, `weapon_shenwu_huan_meng_bian`, `armor_shenwu_xuan_huang_pao`, `accessory_shenwu_kun_lun_pei`

## 4. 任务 B 完成情况 · events vs encounters 对齐

### 结果
- 匹配 events: **15 个** (encounters.yaml 全引用保留在 `data/events/`)
- orphan 归档: **23 个** (移入 `data/events/_archive/`)

### 15 个保留 event（匹配 encounters.yaml）
`bamboo_listen_rain`, `cang_jing_ge_wu`, `cha_ting_dui_ju`, `du_ke_wen_dao`, `du_kou_chun_yu`, `duan_ya_chui_lian`, `gu_dao_xue_ji`, `gu_jian_zhong_yin`, `lu_pang_xian_xian`, `qun_xia_tu`, `shan_dao_wu_zhe`, `shan_lin_qi_yu`, `xiao_zhen_wen_yi`, `xuan_ya_pu_bu_li_lian`, `ye_xing_xun_dao`

### 23 orphan event 归档清单 + 题材摘要
| # | ID | 题材摘要 |
|---|---|---|
| 1 | duan_qiao_can_yue | 断桥残月，江湖相遇 |
| 2 | feng_xue_gu_dian | 风雪古店，避寒投宿 |
| 3 | gu_chuan_deng_ying | 孤船灯影，水上奇遇 |
| 4 | han_mei_ying_xue | 寒梅映雪，雪中悟道 |
| 5 | huang_cun_yao_ren | 荒村咬人，诡异事件 |
| 6 | huang_miao_jiu_seng | 荒庙旧僧，古庙奇遇 |
| 7 | huang_sha_ke_zhan | 黄沙客栈，沙漠奇遇 |
| 8 | huang_yuan_yi_zhong | 荒原遗冢，古墓探索 |
| 9 | jiang_xin_ye_hua | 江心夜话，渡船对话 |
| 10 | jiu_lou_jue_yin | 酒楼绝饮，江湖对饮 |
| 11 | jue_ding_feng_qi | 绝顶风起，山巅奇遇 |
| 12 | lao_jing_hui_xiang | 老井回响，古井奇事 |
| 13 | luo_hua_jian_yuan | 落花剑缘，花中剑意 |
| 14 | mu_chan_dui_yin | 暮蝉对饮，蝉鸣饮酒 |
| 15 | qing_lou_can_meng | 青楼残梦，风尘往事 |
| 16 | qiu_ye_wei_qi | 秋夜围棋，棋局对弈 |
| 17 | shan_ya_can_bei | 山崖残碑，崖壁古碑 |
| 18 | shi_dao_shou_hu | 石岛守护，孤岛守候 |
| 19 | xiang_ye_shen_ji | 乡野神祭，乡村祭祀 |
| 20 | xing_chen_wu_dao | 星辰悟道，夜观星象 |
| 21 | xue_ye_gu_qin | 雪夜古琴，雪中琴音 |
| 22 | ye_du_gu_chuan | 夜渡孤船，深夜渡河 |
| 23 | yu_zhong_qiao_men | 雨中敲门，雨夜访客 |

> 这 23 个 orphan events 是早期 W11-W13 留下的草稿，文案完整，后续扩 encounters 时可挂回。

## 5. 任务 C 完成情况 · insights vs encounter_skills 对齐

### 结果
- 去前缀匹配率: **1 / 35** (2.9%)
- 唯一匹配: `ting_yu_jian` ↔ `skill_encounter_ting_yu_jian`

### 失配 insights（在 insights/ 但不在 encounter_skills.yaml）
`can_bei_zhang_feng`, `can_juan_can_zhao`, `can_yang_ru_xue`, `cang_long_zhua`, `du_jiang_bei_wang`, `feng_zhong_can_zhu`, `gu_dao_xi_feng`, `gu_miao_zhong_sheng`, `han_feng_che_gu`, `han_ya_du_jiang`, `huang_sha_bi_ri`, `jing_di_wang_yue`, `ku_chan_bu_dong`, `liu_shui_wu_qing`, `long_yin_shen_jian`, `luo_ye_gui_gen`, `ming_deng_zhi_yin`, `po_feng_yi_ji`, `po_lang_yi_dao`, `qi_mai_tong_shen`, `qiu_shui_tian_ya`, `shan_quan_ji_jian`, `shuang_dong_qian_li`, `shuang_jiang_man_tian`, `tie_suo_heng_jiang`, `wu_hen_zhi_ji`, `xiao_xiang_ye_yu`, `xing_luo_qi_qi`, `xue_ye_wu_hen`, `yan_hui_xu_ying`, `ye_luo_wu_sheng`, `yi_dian_qian_jun`, `yi_qi_jue_chen`, `yue_xia_du_ying`

### 失配 encounter_skills（在 encounter_skills.yaml 但不在 insights/）
`jichu_buxi`, `pu_xi_tu`, `jian_bu`, `qi_yu_jue`, `tun_tu`, `jian_yi`, `qiu_quan`, `an_qi`, `pai_yun_zhang`, `huo_du`, `drill_strike`, `wu_xia_yi`, `huo_quan`, `xuan_jian`, `relic_blade`, `qing_feng_jian`, `lie_huo`, `xuan_yin`, `fei_xian`, `water_qi`, `night_strike`, `lei_dian`, `jin_gang`, `shan_he`, `ice_break`, `xuan_bing`, `lie_yan`, `qian_kun`, `chen_xin`, `long_yin`, `feng_qi`, `yi_jian`, `wu_ming`, `tian_dao`

### 建议
35 ↔ 35 数量对上是巧合，不是设计对应。两套体系来源不同：
- `insights/` 35 篇对应 IDS_REGISTRY 中 `move_insight_*`（武学领悟招式文案），走中文诗意命名
- `encounter_skills.yaml` 35 招对应奇遇解锁技能池（`skill_encounter_*`），走拼音功能命名

**建议方向**：保持两套独立体系，不分并。`ting_yu_jian` 的重名是 W14-1 vertical slice 时遗留的历史巧合。后续若要建立 insight→encounter_skill 的文案关联，需 Mac 端在 encounter_skills.yaml 中新增 `narrativeInsightId` 字段做显式映射。

## 6. 任务 D 完成情况 · IDS_REGISTRY.md 修正

修正项:
- 自报数 143 → 改为 **326**（ch 3 + stage 36 + eq 45 + tech 22 + move 102 + adv 26 + codex 18 + tpl 7 + encounter_skill 35 + W14-2 encounter 12 + biome 15 + weather 5）
- 新增「奇遇事件（W14-2 扩充）」段：12 条 `enc_*` ID
- 新增「奇遇技能（W14-3-A）」段：35 条 `skill_encounter_*` ID（7 阶分级）
- 新增「区域枚举（biome）」段：15 值
- 新增「天气枚举（weather）」段：5 值
- 更新「ID 前缀速查」表：追加 `enc_` / `skill_encounter_` / `biome_` / `weather_`
- 变更记录追加 v1.2

## 7. 文件操作清单

```
data/events/_archive/  (+23 orphan events 移入)
data/events/           (保留 15 个匹配 encounters.yaml)
data/lore/_archive/    (+45 orphan lore 移入)
data/lore/             (清空，仅剩 _archive/ 和 _templates/)
IDS_REGISTRY.md        (修正 143→326 + 补 4 段新 ID 表)
docs/handoff/deepseek_audit_w14_4_2026-05-15.md (本报告新建)
```
