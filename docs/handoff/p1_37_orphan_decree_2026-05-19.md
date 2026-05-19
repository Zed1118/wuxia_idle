# P1 #37 6 orphan event 决议归档 · 2026-05-19

> Nightshift T03 audit 产出。**只决议,不动 encounters.yaml / events/_archive/**。

## §1 6 orphan 主题表

| id | 标题 | 主题归类 | biome 推断 | weather 推断 | 调子 |
|---|---|---|---|---|---|
| duan_qiao_can_yue | 断桥残月 | 心境 | bridge(无对应key) | night(残月) | 悲悯人情,无武学钩子 |
| gu_chuan_deng_ying | 孤船灯影 | 江湖故事 | dock | night | 孤寂漂泊,hermit 哲学,无武学钩子 |
| huang_cun_yao_ren | 荒村咬人 | 邪门调子 | abandonedVillage(无key) | clear | 恐怖超自然,写实武侠基调异质 |
| lao_jing_hui_xiang | 老井回响 | 心境 | well(无key,可拟合inn) | clear | 神秘内省;discover_secret 摸到断剑——有武侠钩子 |
| qing_lou_can_meng | 青楼残梦 | 音律 | inn-adjacent | night | 琵琶断弦,音律系Demo不做,无武学输出 |
| yu_zhong_qiao_men | 雨中敲门 | 江湖故事 | inn | rain | 老妇记名册,江湖味浓;outcomes映射清晰 |

## §2 encounters.yaml slot 缺口扫描

| type | 当前数(grep实测) | GDD §8.4 下限 | 缺口 |
|---|---|---|---|
| techniqueInsight | 20 | 20 | 刚到下限(无缺口,但无余量) |
| fortuneEvent 基础(非节日) | 16 | 15 | 满(+1余量) |
| festivalRequired | 8 | 6 | 满(中位,6-10范围内) |

**biome×weather 空缺(可用于挂回参考)**:
- rain × inn → 空缺(现有 feng_xue_gu_dian 是 snow×inn;rain×inn 无条目)
- well / bridge / abandonedVillage → 无对应 biome key(挂回须拟合或新增 biome,下波再议)

## §3 每条决议表

| id | 决议 | 理由 | 若挂回:type + biome + weather + outcome |
|---|---|---|---|
| duan_qiao_can_yue | **永封档** | biome=废桥(无key),3 outcomes 全为民事行为(修桥/听故事/留银),零武学钩子 | — |
| gu_chuan_deng_ying | **永封档** | dock×night 槽已饱和(#18 ye_du_gu_chuan + #40 jiang_xin_ye_hua),hermit诗意但无武学输出 | — |
| huang_cun_yao_ren | **永封档** | 邪门/恐怖调子与写实武侠基调异质;biome=荒村(无key);uncover_truth/confront_horror无法映射至 attributeBonus/unlockSkill | — |
| lao_jing_hui_xiang | **永封档**(2026-05-19 拍板) | ① fortuneEvent 池 16/15 不饥渴;② biome=inn 拟合"枯井"语义膨胀;③ inn 槽 yu_zhong_qiao_men rain×inn 已饱和;④ "神秘幽寒"调子异质于 fortuneEvent 主流"江湖奇缘";⑤ _archive/ 留档,Phase 5+ 若开 biome=well 直接启用 | — |
| qing_lou_can_meng | **永封档** | 音律系统 Demo 不做(GDD §8.4);outcomes(connect_string/meditate_silence)无武学输出;青楼调子与项目基调不完全契合 | — |
| yu_zhong_qiao_men | **推荐挂回** | rain×inn 槽位空缺;hear_stories→fortune+1 / learn_legend→enlightenment+1 映射清晰;江湖名册设定风格吻合 | type=fortuneEvent / biome=inn / weather=rain / hear_stories→fortune+1 / learn_legend→enlightenment+1 |

## §4 closeout

本批 audit 终态决议:6 条 orphan 中 **5 条永封档**(废桥 / 邪门 / 音律 / dock饱和 / **lao_jing_hui_xiang 2026-05-19 拍板永封档**),**1 条挂回**(yu_zhong_qiao_men 2026-05-19 已实装 rain×inn)。

**yu_zhong_qiao_men 已实装**(2026-05-19,HEAD `3a1315e`):encounters.yaml +1 条(rain×inn,type=fortuneEvent)+ events/ 落对应 yaml → fortuneEvent基础数 16→17,仍在 GDD §8.4 范围内(15-25)。

**lao_jing_hui_xiang 永封档拍板理由**(2026-05-19 用户拍板):
- ① fortuneEvent 池 16/15 不饥渴,无挂回压力
- ② biome=inn 拟合"枯井"语义膨胀,需 encounter comment 注释属"打补丁"
- ③ inn 槽 yu_zhong_qiao_men rain×inn 刚饱和,再添挤
- ④ "神秘幽寒"调子异质于 fortuneEvent 主流"江湖奇缘"
- ⑤ _archive/ 留档,Phase 5+ 若开 biome=well/abandoned_well 直接启用

**#37 挂账状态**:**全销账**(6 条 = 5 永封档 + 1 挂回实装)。

**优先级判定**: fortuneEvent 基础(17)≥ 15 → 不强求新增;techniqueInsight(20)= 下限 → 下波 P1 #43 高阶占位补 18 条 skill 时连带补 techniqueInsight 类 encounter(本批 6 条无此类型可转)。
