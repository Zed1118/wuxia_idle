# 挂账 #37 余 8 events orphan 主题复审(2026-05-17)

> 目的:挂账 #37 PROGRESS 写「剩余 8 条主题不适配」,本批复审验证 — **2 条可挂回**,6 条留 orphan。
> 操作:本预研不动 yaml/_archive,实装留 W17 candidate B 全链闭环后做。
> 触发:本会话 Mac 端 DeepSeek/Codex Pen 期间并行可做的 C 任务。

---

## 1. 8 文件主题速览

| # | 文件 | 主题 | 武学呼应度 |
|---|---|---|---|
| 1 | `duan_qiao_can_yue.yaml` 断桥残月 | 替老妪修桥 / 听镖局往事 | 弱(心境,无招式呼应) |
| 2 | `gu_chuan_deng_ying.yaml` 孤船灯影 | 江上隐士读诗 / 黑猫 | 弱(诗意非武意) |
| 3 | `huang_cun_yao_ren.yaml` 荒村咬人 | 疯病村 + 后山未死之人 | 零(邪门调子) |
| 4 | `huang_yuan_yi_zhong.yaml` 荒原遗冢 | **齐眉棍插坟前 + 40 年腕力磨痕** | **强**(棍道传承) |
| 5 | `jiang_xin_ye_hua.yaml` 江心夜话 | **江上老少传承江湖故事** | **中**(传承 + 江湖意) |
| 6 | `lao_jing_hui_xiang.yaml` 老井回响 | 井底断剑 + 风声夹人声 | 中(怀古 + 剑,但池无断剑专属招) |
| 7 | `qing_lou_can_meng.yaml` 青楼残梦 | 琵琶断弦知音 | 弱(心境,音律非武学) |
| 8 | `yu_zhong_qiao_men.yaml` 雨中敲门 | 老妇 30 年记 800 江湖人 | 弱(江湖记忆,无武学动作) |

---

## 2. 35 招池未引用 17 个 vs 候选事件匹配

`encounter_skills.yaml` 35 招池,encounters.yaml 当前已引用 18 个,**未引用 17 个**:

| skill id | name | powerMul | 描述节选 | 匹配候选 |
|---|---|---|---|---|
| qiu_quan | 求拳 | 1400 | **不追求招式华美,只求一拳一拳地追问——怎样的出拳才算对** | ⭐⭐ **huang_yuan_yi_zhong**(40 年磨棍追问腕力) |
| wu_xia_yi | 武侠意 | 2400 | **心中自有一片江湖。剑未出鞘,侠意已至——这不是招式,是武人的风骨** | ⭐⭐ **jiang_xin_ye_hua**(老少传承江湖意) |
| jin_gang | 金刚不坏 | 3800 | 内劲画弧如墙横在江面,铁索拦江万夫莫开 | × 防御主题,与遗冢不匹 |
| an_qi | 暗器初探 | 1700 | 袖中藏刃,腕底翻花 | × 8 文件无暗器主题 |
| huo_du | 活渡 | 1500 | 身形向前一闪,留虚影 | × 无身法主题 |
| pu_xi_tu | 朴息图 | 900 | 最简单的一呼一吸,朴拙之中藏吐纳本源 | △ 远匹老井(井下静) |
| tun_tu | 吞吐 | 1100 | 一吞一吐丹田鼓荡 | × 吐纳非心境 |
| qing_feng_jian | 青锋剑 | 2700 | (略) | × 与 lao_jing 断剑不匹(青锋是新剑) |
| huo_quan | 火拳 | 1900 | (略) | × 8 文件无火主题 |
| jian_bu | 渐步 | 750 | 脚步渐次而进,叠在前一步余韵 | × 无步法主题 |
| lie_huo / lei_dian / shan_he / fei_xian / xuan_bing / lie_yan / qian_kun | (略) | 2900-5500 | 各种元素/大招类 | × 8 文件无此类元素主题 |

---

## 3. 推荐挂回 2 条

### 3.1 huang_yuan_yi_zhong → qiu_quan(求拳,tier 1 powerMul 1400)

**主题契合**:
- 事件:荒原遗冢前一根齐眉棍,40 年练棍腕力磨出两道深沟,「拔棍试力」「掘土探丘」二选一,主题 = 「敬意 / 传承 / 棍道追问」
- 招式:**求拳** = 「不追求招式华美,只求一拳一拳地追问——怎样的出拳才算对」,与 40 年磨棍「追问」高度同源

**proposed entry**(encounters.yaml 末尾追加):

```yaml
  - id: huang_yuan_yi_zhong
    type: techniqueInsight
    trigger:
      biome: wilderness           # 或 plains,看现有 enum
      fortuneRequired: 3
    baseProbability: 0.35
    outcomeMapping:
      sense_echo:
        type: unlockSkill
        skillId: skill_encounter_qiu_quan
      find_relic:
        type: attributeBonus
        attributeKey: enlightenment
        attributeDelta: 1
```

(events 文件已有,只 `git mv data/events/_archive/huang_yuan_yi_zhong.yaml data/events/`)

### 3.2 jiang_xin_ye_hua → wu_xia_yi(武侠意,tier 4 powerMul 2400)

**主题契合**:
- 事件:江上一老一少,船家因无月停船,老人讲少年渡江找人 40 年的故事,少年「眼里的光是少年才有的那种」,「碰壶一饮而尽」「最后一滴倒进江水」
- 招式:**武侠意** = 「心中自有一片江湖。剑未出鞘,侠意已至——这不是招式,是武人的风骨」,完美匹配老少江湖意传承的内核

**proposed entry**:

```yaml
  - id: jiang_xin_ye_hua
    type: fortuneEvent
    trigger:
      biome: river               # 或类似
      fortuneRequired: 5
    baseProbability: 0.4
    outcomeMapping:
      learn_legend:
        type: unlockSkill
        skillId: skill_encounter_wu_xia_yi
      bond_with_young:
        type: attributeBonus
        attributeKey: fortune
        attributeDelta: 1
      # skip 第 3 choice 不 map
```

**注意**:jiang_xin_ye_hua 有 3 个 choices(2 outcome + skip),与多数 events 体例一致;wu_xia_yi 是 tier 4 招(2400),fortuneRequired=5 合理。

---

## 4. 留 orphan 的 6 条说明

| 文件 | 留 orphan 理由 |
|---|---|
| duan_qiao_can_yue | 修桥 + 听镖局往事,心境主题,无武学动作,无适配招 |
| gu_chuan_deng_ying | 江上隐士读诗 + 黑猫,诗意非武意 |
| huang_cun_yao_ren | 疯病村 + 邪门,与项目水墨克制武侠基调不符,主题不适配 |
| lao_jing_hui_xiang | 井底断剑主题需要"古剑/断剑/怀古剑"专属招,35 池无强匹配 |
| qing_lou_can_meng | 琵琶断弦知音,音律心境,非武学 |
| yu_zhong_qiao_men | 老妇 30 年记 800 江湖人,叙事手法非武学呼应 |

**结论**:6 条主题确实「江湖故事 / 心境感悟 / 邪门调子」,与 35 招池主流武学路径不符,**长期留 _archive/**(PROGRESS 挂账 #37 描述准确)。

---

## 5. 实装时机推荐

**不在本会话实装**,理由:
1. W17 DeepSeek 文案 chu_xi_ci_sui / qing_ming_yu_si 在飞,encounters.yaml 即将 36→38。我若现在挂 2 条 → 同期撞 commit
2. encounter_yaml_test 期望数会从 36 同时撞 +2(DeepSeek 文案)和 +2(本批)= 40

**推荐时机**:
- DeepSeek 文案 + Codex 验收闭环 → encounter_yaml_test 36→38 同步 → Mac 端 PROGRESS 销账 W17 candidate B 全链闭环
- **然后**作为 W17 polish 收尾任务:2 entry yaml + 2 events git mv + test 38→40(预计 sonnet 15-30 min)

挂回后挂账 #37 余 8 → 余 6(降挂账数 2 条,所有 W14 起 orphan 总数 23 → 累计挂回 17 → orphan 6)。

---

## 6. 已生效产出

- 本预研文档:复审 8 文件 + 17 未引用招匹配分析 + 2 条挂回方案 yaml entry 草稿 + 6 条留 orphan 理由
- **0 yaml 改 / 0 events mv / 0 test 改**,纯文档证据

实装时直接看本文档 §3.1/§3.2 yaml entry 草稿即可,无需重读 8 文件 + 35 招池。

---

**预研文档结束。本预研不影响 W17 主战场,实装由用户在 W17 candidate B 闭环后拍板。**
