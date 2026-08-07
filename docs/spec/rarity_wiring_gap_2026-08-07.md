# 角色稀有度系统未实装 · 现状与选项(待拍板)

> 2026-08-07 N1 处置时发现并逐条实测。**本文只陈述现状与选项,不含实装**——接线涉平衡改动,需用户拍板。

## 一、结论

GDD §4.1 把「6 档角色稀有度分布」写为**强制规则**,`data/numbers.yaml:942` 也配了完整概率表,但**整套设计零实装**:配置在、枚举在、字段在、赋值写死、读取端为空。

## 二、实测证据(2026-08-07 本会话跑)

**配置侧**——`data/numbers.yaml` 6 档齐全:

| 档 | 概率 | total_points_range |
|---|---|---|
| 庸才 yongCai | 15% | 16-17 |
| 寻常 xunChang | 35% | 18-19 |
| 标准 biaoZhun | 25% | 20 |
| 资优 ziYou | 18% | 21-22 |
| 天才 tianCai | 5% | 23 |
| 绝世 jueShi | 2% | 24 |

**代码侧**——全 `lib/`(排除 `*.g.dart` 与 `lib/features/debug/`)**只有 7 处**引用 rarity:

| file:line | 性质 |
|---|---|
| `lib/core/domain/enums.dart:150-157` | 枚举定义(6 档齐全,中文名只在行末注释) |
| `lib/core/domain/character.dart:64` | 字段声明 `late RarityTier rarity` |
| `lib/core/domain/character.dart:158` | 构造参数 |
| `lib/core/domain/character.dart:207` | 赋值 `..rarity = rarity` |
| `lib/features/recruitment/application/recruitment_service.dart:99` | **硬编码 `RarityTier.biaoZhun`** |
| `lib/features/sect/presentation/sect_recruit_handler.dart:110` | **硬编码 `RarityTier.biaoZhun`** |
| `lib/features/onboarding/application/master_builder.dart:53` | **硬编码 `RarityTier.biaoZhun`** |

**关键:零读取点。** 没有任何代码读 `character.rarity` 做任何事——无 UI 展示、无属性派生、无战斗影响。`lib/shared/strings.dart` 里也没有六档档名文案(仅有「稀有彩头」等无关词条)。

**玩家侧可观察表现**:招募、宗门收徒、开局祖师——所有角色都是「标准」档,且界面上根本看不到稀有度这个概念。改 yaml 概率表不产生任何行为变化。

## 三、为什么之前两轮审计没逮到

- **PI1**(未消费字段扫描)按「lib 里 grep 字段名零命中」筛——`rarity` 在 lib 里满屏命中,不入候选。
- **Q1**(假阴复核)复核的是 PI1 的候选集,同样不覆盖。
- 这类「字段名有命中、真实取值是写死常量」的背离,需要专门的判据才扫得到。已据此新开 Q2 单(`docs/dispatch/2026-08-07_Q2.md`)全仓扫同类。

## 四、选项(需拍板,推荐 B)

| 选项 | 内容 | 代价 | 风险 |
|---|---|---|---|
| **A 全量接线** | roll 概率 + 按 total_points_range 派生属性 + UI 展示档位 + 红线测试 | 大 | **平衡风险实**:16→24 是 ±25% 属性摆幅。低档角色可能卡关、高档可能压平难度曲线;且现无属性→战力的直接通路(Character 无根骨/悟性等字段,只有 `attributeBonusFromAdventure` 一个奇遇加成计数器),派生路径本身要先设计 |
| **B 先接表现层,不动平衡**(推荐) | roll 概率决定档位 + UI 展示(角色面板/招募界面标档位)+ 六档文案入 strings;**total_points_range 暂不接**,属性维持现状 | 中 | 低。玩家立刻能看到「这徒弟是天才/庸才」的差异感,零平衡影响;后续要接属性再单独拍 |
| **C 砍配置** | 删 yaml 的 rarity_distribution + 删 Character.rarity 字段 | 小 | 与 GDD §4.1「强制规则」冲突,等于放弃该设计;且 Isar schema 改字段需升版迁移 |
| **D 维持现状 + 注释** | 已于 2026-08-07 执行(numbers.yaml:942 附近已加未接线警告) | 零 | 配置与行为继续脱节,但至少不再误导读者 |

**推荐 B 的理由**:稀有度的产品价值主要在「养成的期待感/差异感」——玩家收到一个「天才」弟子的情绪价值,不依赖属性真的更高。先把这份感受做出来,平衡风险为零;属性派生是独立的第二步,可等真人试玩数据再拍(与 BACKLOG 现有三条数值项同一处理节奏)。

**注意 B 也不是零成本**:要设计六档在 UI 上怎么呈现(色阶?题字?印章?),六档档名要进 strings,招募界面要有展示位。属于表现层任务,可派执行端。

## 五、关联

- 处置注释落点:`data/numbers.yaml` rarity_distribution 段头
- 同类背离全仓扫描:`docs/dispatch/2026-08-07_Q2.md`(qoderclicn 执行中)
- 同批发现的第二条:`inheritance.unlock_rules` 与活配置 `ascension.unlock_triggers.required_realm` 重复声明同一门槛(详见 numbers.yaml 该段注释)
