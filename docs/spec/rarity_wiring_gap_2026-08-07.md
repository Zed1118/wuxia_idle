# 角色稀有度标签未派生 · 现状与选项(待拍板)

> 2026-08-07 N1 处置时发现。**2026-08-07 二稿:一稿结论有重大错误已作废重写**——一稿称「属性系统不存在、接线属 ±25% 平衡改动」,实测证伪:四项属性完整实装且已被战斗/奇遇/修炼消费,稀有度只是其总点数的派生标签,接线**零平衡影响**。错因:一稿只 grep 了 `character.dart` 找拼音字段名,而属性在独立文件 `lib/core/domain/attributes.dart` 且用英文名。

## 一、结论

**属性系统是完整的,缺的只是稀有度这个"标签"没有从属性派生出来。** 三处创建点把 `rarity` 写死成 `RarityTier.biaoZhun`(标准),导致**全仓 18 个角色定义里 16 个带着错标签**。

## 二、实测证据(2026-08-07 本会话)

### 2.1 属性系统:完整实装

| 环节 | 实况 |
|---|---|
| 数据 | `lib/core/domain/attributes.dart:11-14` — `constitution`/`enlightenment`/`agility`/`fortune`,`@embedded`,另有 `int get total`(:17) |
| 差异化 | 三处创建点全部从 yaml def 的 `attributeProfile` 读:`recruitment_service.dart:94-98` / `sect_recruit_handler.dart:105-109` / `master_builder.dart:48-52`。**每个角色的资质是逐个手写在 yaml 里的**,非 roll |
| 战斗消费 | `derived_stats.dart:101` HP 含 `根骨*conFactor` · `:139` 出手速度含 `身法*agFactor` · `:196` 闪避率 = `身法*perPointRate` |
| 奇遇消费 | `encounter_service.dart:100,210` 武学领悟读悟性、其他奇遇读机缘 |
| 奇遇补偿 | `encounter_service.dart:353-360` 真往属性上 `+=`;生涯上限 `numbers.yaml:983 lifetime_cap_per_character: 5`,经 `EncounterProgress.attributeGainsTotal` 兜底,**已实装** |
| UI | `lineage_character_detail_screen.dart:275` 角色面板已有「资质段:四项属性」;四项中文名 `enum_localizations.dart:240-243` |

### 2.2 稀有度:标签写死,16/18 与实际不符

`Attributes.total` getter 已存在;`numbers.yaml:942 rarity_distribution` 的 `total_points_range` 正是 total→档位映射表。但三处创建点写死 `RarityTier.biaoZhun`。逐角色实测:

| 来源 | 角色 | 四项 | 总点 | 应为 | 实际 |
|---|---|---|---:|---|---|
| recruit_candidates | candidate_a 云寒青 | 6/5/4/3 | 18 | 寻常 | 标准 ✗ |
| recruit_candidates | candidate_b 柳拂陻 | 3/5/7/4 | 19 | 寻常 | 标准 ✗ |
| recruit_candidates | candidate_c 马智远 | 5/5/5/5 | 20 | 标准 | 标准 ✓ |
| sect_candidates | bamboo_swordsman | 5/7/7/5 | 24 | **绝世** | 标准 ✗ |
| sect_candidates | mountain_hermit | 6/8/4/6 | 24 | **绝世** | 标准 ✗ |
| sect_candidates | river_drifter | 5/5/7/6 | 23 | **天才** | 标准 ✗ |
| sect_candidates | valley_hermit | 5/7/5/6 | 23 | **天才** | 标准 ✗ |
| sect_candidates | desert_wanderer | 8/4/5/4 | 21 | 资优 | 标准 ✗ |
| sect_candidates | blacksmith_son | 7/4/4/5 | 20 | 标准 | 标准 ✓ |
| masters | founder 祖师 | 5/7/5/5 | 22 | 资优 | 标准 ✗ |
| masters | first_disciple 大弟子 | 5/4/6/4 | 19 | 寻常 | 标准 ✗ |
| masters | second_disciple 二弟子 | 4/4/4/5 | 17 | **庸才** | 标准 ✗ |
| founder_creation | 6 个开局出身 | — | 21-22 | 资优 | 标准 ✗ |

### 2.3 UI 侧:稀有度零展示

- `rarity` 在全部 presentation 层**零引用**(只有 `sect_recruit_handler.dart:110` 那处赋值)
- 六档档名(庸才/寻常/标准/资优/天才/绝世)**只存在于 `enums.dart:151-156` 的行末注释**,`strings.dart` 无对应文案条目

## 三、关键设计判断:rarity 必须是 computed 不能是 stored

现在 `Character.rarity` 是 Isar **存储字段**。但:

1. 它是 `attributes.total` 的纯函数
2. 奇遇会真的往属性上加点(生涯 cap +5)

→ 存储字段**必然漂移**:二弟子出生 17 点(庸才),奇遇加满 5 点变 22 点(资优),存的标签却还是出生那刻的。

而 GDD §4.1 的设计理由原文是「用奇遇的微弱补偿留出努力空间,避免初始绝望感」——**「庸才逆袭成资优」是设计意图**,不是需要防止的漂移。所以正解是 computed getter,让标签始终反映当下。

代价:移除 Isar 存储字段需 schema 升版 + 老档迁移。

## 四、真正需要拍板的问题:实际分布严重偏离设计曲线

改成派生后,标签会说实话——但说出来的实话可能不好看。可获得角色池(12 个,不含开局六选一)实测分布 vs GDD §4.1 目标:

| 档 | GDD 目标 | 实际(12 人池) | 偏差 |
|---|---:|---:|---|
| 庸才 | 15% | 8%(1) | |
| 寻常 | 35% | 25%(3) | |
| 标准 | 25% | 17%(2) | |
| 资优 | 18% | 17%(2) | |
| 天才 | 5% | **17%(2)** | 3.4× |
| 绝世 | 2% | **17%(2)** | 8.5× |

**门派候选是重灾区**:`sect_candidates.yaml` 6 人里 2 绝世 + 2 天才 = 67% 在天才档以上。一旦档位可见,玩家会发现「门派随便招都是天才绝世」,稀有度的稀缺感当场归零。

这不是代码问题,是内容配置问题。**两条路需要你拍**:

| 选项 | 做法 | 影响 |
|---|---|---|
| **调资质贴合曲线** | 改 `sect_candidates.yaml` 等的 attributeProfile,让分布接近 15/35/25/18/5/2 | **真平衡改动**——这些角色的 HP/速度/闪避/奇遇率都会变,需重跑平衡验证 |
| **承认手工角色不适用概率分布** | 这 12 个是有名有姓的设计角色(每个都有 lore 文案),本就不该当随机抽卡看待;`probability` 列注释为「程序化生成时的分布指引」 | 零平衡影响,但要接受「已知角色偏强」这个设定 |

我的看法:后者更符合现状——这些角色都写了背景故事、指定了流派和初始装备,是**叙事角色**不是抽卡池。稀缺感应该靠「能不能招到他」(解锁条件)而不是「资质 roll 得好不好」。但这是你的产品判断。

## 五、完整范围(按依赖排序)

| # | 层 | 内容 | 平衡风险 |
|---|---|---|---|
| 1 | 派生 | rarity 改 computed getter,从 `attributes.total` 查 `rarity_distribution.total_points_range`;删三处硬编码;Isar schema 升版 + 老档迁移 | **零** |
| 2 | 文案 | 六档档名进 `strings.dart`(现仅存于代码注释) | 零 |
| 3 | 展示 | 角色面板资质段加档位标签;**招募/收徒界面加档位**(选人决策的核心信息) | 零 |
| 4 | 视觉 | 六档在水墨基调下怎么表达(色阶/印章/题字)——需视觉拍板 | 零 |
| 5 | 守卫 | 红线测试:rarity 恒等于 total 派生值(防再被写死);契约测试:新增 def 的 attributeProfile 总和必须 16-24、单项 1-10(GDD 强制规则) | 零 |
| 6 | 内容 | §四 的分布决策 | **视选项而定** |

第 1-5 层合计代码量很小(核心逻辑约 20 行 + 一个映射函数 + 测试),真正的工作量在第 4 层的视觉设计与第 6 层的产品决策。

## 六、关联

- 注释落点:`data/numbers.yaml` rarity_distribution 段头(2026-08-07 已加,一稿措辞含上述错误,待随本文二稿同步订正)
- 同类背离全仓扫描:`docs/dispatch/reports/2026-08-07_Q2_config_bypass.md`
- `Character.attributeBonusFromAdventure` 目前是**只写不读**字段(`encounter_service.dart:366` 写,零读取点;代码注释自陈「读端待接」)——若做第 3 层展示,「奇遇弥补 +N」正是它的读端
