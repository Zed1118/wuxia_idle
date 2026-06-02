# Phase D 敌人图 第三批 MJ prompts(2026-06-03 · yiLiu 一流)

> 派单方:Mac Opus · 执行方:用户起 MJ Discord 出图/选片/压缩/归位
> 上游:第一批 batch1 / 第二批 batch2 体例 + memory `feedback_mj_wuxia_prompt_pitfalls`
> 权威缺图清单:`test/fixtures/known_missing_assets.txt`
> 本批 = 一流(yiLiu)14 张(利器阶,Ch4-5 轻功对决关:边境/渡口/城墙/竹林)
> 剩余缺图 enemy:63(绝顶 27 / 宗师 13 / 武圣 1),后续第四批起按梯度续

## 配方(敌人胸像 icon)

- `chinese ink painting style portrait` + 非暴力文化身份 + biome 风物 backdrop
- 流派色调:gangMeng 深褐 earthy / lingQiao 灰青 slate gray / yinRou 暗紫 deep purple
- **阶梯度(比第二批再升一档)**:yiLiu = accomplished/masterful/first-rate/commanding,身姿利落有宗师气象前兆,**仍未到 jueDing+ 的 transcendent/peerless 顶阶**。衣着 fine practiced(比 erLiu 的 neat 更讲究但不奢)。
- chest-up front-facing / monochrome ink wash / 去 sref / stylize 150 / 去武器名
- **autojourney 防撞车**:每条开头 ~40 字带唯一身份词(14 身份已错开开头形容词)
- **触发规避(本批重点)**:水寇/刺客/刀客/剑客 已改中性职业词,避 bandit/assassin/killer/blade/sword:
  水寇→river-stronghold man / 刀客→martial drifter / 刺客→rooftop prowler / 剑客→martial wanderer

## 归位映射(文件 ↔ prompt 顺序一致)

| # | iconPath | 身份 | 流派 | 阶 | boss | biome |
|---|---|---|---|---|---|---|
| 1 | assets/enemies/bazhu_youfu.png | 西凉右护法 | lingQiao | yiLiu | | 边境 |
| 2 | assets/enemies/bazhu_zuofu.png | 西凉左护法 | gangMeng | yiLiu | | 边境 |
| 3 | assets/enemies/guard_a.png | 玉门关把总 | gangMeng | yiLiu | | 边境 |
| 4 | assets/enemies/guard_b.png | 西凉骑士 | lingQiao | yiLiu | | 边境 |
| 5 | assets/enemies/guard_c.png | 商队护卫 | yinRou | yiLiu | | 边境 |
| 6 | assets/enemies/lightfoot_shuikou_a.png | 渡口水寇 | gangMeng | yiLiu | | 渡口 |
| 7 | assets/enemies/lightfoot_shuikou_b.png | 渡口船工 | lingQiao | yiLiu | | 渡口 |
| 8 | assets/enemies/lightfoot_shuikou_c.png | 渡口刀客 | yinRou | yiLiu | | 渡口 |
| 9 | assets/enemies/lightfoot_yexun_a.png | 城防夜巡 | gangMeng | yiLiu | | 城墙 |
| 10 | assets/enemies/lightfoot_yexun_b.png | 飞檐捕快 | lingQiao | yiLiu | | 城墙 |
| 11 | assets/enemies/lightfoot_yexun_c.png | 瓦上刺客 | yinRou | yiLiu | | 城墙 |
| 12 | assets/enemies/lightfoot_zhuke_a.png | 江南剑客 | lingQiao | yiLiu | | 竹林 |
| 13 | assets/enemies/lightfoot_zhuke_b.png | 密竹刀客 | yinRou | yiLiu | | 竹林 |
| 14 | assets/enemies/lightfoot_zhuke_c.png | 竹林游侠 | gangMeng | yiLiu | | 竹林 |

## prompts(顺序同上)

1 bazhu_youfu
chinese ink painting style portrait, agile xiliang right-guardian deputy with masterful poised bearing, on an arid frontier pass with sand dunes and a border watchtower, slate gray palette, lithe powerful build, sharp piercing eyes, fine practiced robe, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

2 bazhu_zuofu
chinese ink painting style portrait, powerful xiliang left-guardian deputy with commanding stern presence, on an arid frontier pass with sand dunes and a border watchtower, dark brown earthy palette, broad mighty shoulders, resolute weathered face, fine practiced robe, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

3 guard_a
chinese ink painting style portrait, seasoned yumen pass garrison captain with authoritative bearing, before the great yumen frontier gate and rampart, dark brown earthy palette, broad solid shoulders, hardened commanding face, fine officer's attire, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

4 guard_b
chinese ink painting style portrait, lithe xiliang frontier rider with swift confident bearing, on an arid frontier road with sand and distant cavalry, slate gray palette, lean agile build, keen alert eyes, fine riding garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

5 guard_c
chinese ink painting style portrait, watchful caravan escort guard with reserved steady air, beside a desert merchant caravan and camels, deep purple shadow palette, narrowed vigilant eyes, calm controlled composure, fine travel garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

6 lightfoot_shuikou_a
chinese ink painting style portrait, brawny river-stronghold man with tough commanding presence, on a misty river dock with moored boats, dark brown earthy palette, broad powerful shoulders, weathered bold face, fine rugged garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

7 lightfoot_shuikou_b
chinese ink painting style portrait, nimble river-dock boatman with quick deft bearing, on a misty river dock with moored boats, slate gray palette, lean wiry build, sharp clear eyes, fine practiced work garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

8 lightfoot_shuikou_c
chinese ink painting style portrait, shadowy river-dock martial drifter with cool detached air, on a misty river dock at dusk with moored boats, deep purple shadow palette, narrowed cold eyes, calm controlled composure, fine dark garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

9 lightfoot_yexun_a
chinese ink painting style portrait, sturdy city-wall night patrolman with vigilant firm bearing, atop a grey stone city wall under a night sky, dark brown earthy palette, broad solid shoulders, alert stern face, fine patrol uniform, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

10 lightfoot_yexun_b
chinese ink painting style portrait, eaves-leaping constable with swift agile bearing, on grey rooftops above a night city wall, slate gray palette, lean nimble build, sharp quick eyes, fine constable garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

11 lightfoot_yexun_c
chinese ink painting style portrait, rooftop prowler in dark garb with silent cold air, crouched on grey night rooftops above a city wall, deep purple shadow palette, narrowed cold eyes, calm controlled composure, fine dark fitted garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

12 lightfoot_zhuke_a
chinese ink painting style portrait, lithe jiangnan martial wanderer with elegant assured bearing, in a misty green bamboo grove, slate gray palette, slender agile build, sharp clear eyes, fine scholarly martial robe, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

13 lightfoot_zhuke_b
chinese ink painting style portrait, secretive bamboo-grove martial drifter with cool quiet air, deep within a dense misty bamboo grove, deep purple shadow palette, narrowed calm eyes, controlled composure, fine dark garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

14 lightfoot_zhuke_c
chinese ink painting style portrait, rugged bamboo-grove ranger with sturdy free-spirited bearing, at the edge of a misty bamboo grove, dark brown earthy palette, broad steady shoulders, weathered open face, fine rugged garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

## 归位

出图选片后压缩(pngquant/oxipng,~250-450KB)→ cp 到上表 iconPath。
归位后:重跑 asset_audit → cp asset_audit_missing.txt known_missing_assets.txt 刷 allowlist。
本批 14 张归位后预计 enemy 缺图:77(批2 后)→63。
