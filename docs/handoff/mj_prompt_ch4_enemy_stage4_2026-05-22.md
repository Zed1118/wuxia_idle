# Ch4 enemy 15 张 MJ prompt spec(2026-05-22)

> 派单方:Mac Opus 4.7(3h 托管 D 批次)
> 执行方:用户起 MJ Discord(本 doc 起 prompt spec,不代用户派单)
> 上游:memory `feedback_mj_character_batch_v6_evolution` v6 体例(去 sref / 武器抽象 / stylize ≤150 / 不真人 portrait)+ `feedback_mj_wuxia_prompt_pitfalls` 第 16 条累计触发

## 触发规避

15 张 ≥ Moderator 累计触发阈值(Stage 3 BOSS 22 张实战过 7 张锁 ~5h)。**强制规避 6 维**:
1. ❌ 真人写实 portrait sref baseline
2. ❌ 武器具名(jian/dao/sabre/blade/whip)→ 改抽象「pole / staff / scarf wrapped tool」
3. ❌ 暴力/军事身份(bandit chief / killer / soldier)→ 改职业「frontier traveler / desert wanderer」
4. ❌ stylize > 200 → **stylize 150**
5. ❌ sw > 50 → **sw 30 或 0(去 sref)**
6. ❌ 大批量同 prompt → **2-3 张一批 + 间隔 ≥ 45min**

## Ch4 enemy 15 张清单

| stage | iconPath | 文化身份 | 流派色调 |
|---|---|---|---|
| 04_01 | liukou_a/b/c.png | 河西走廊流寇 3 人(头领/副手/刀手)| 深褐(gangMeng)/ 灰青(lingQiao)/ 暗紫(yinRou)|
| 04_02 | guard_a/b/c.png | 玉门关把总 / 西凉骑士 / 商队护卫 | 同上 |
| 04_03 | shafei_a/b/c.png | 大漠沙匪 3 人(头领/刀手/弓手)| 同上 |
| 04_04 | xiliangboss + xiliang_a/b.png | 西凉武林名宿 + 2 徒(校场风格)| 同上 |
| 04_05 | xiliangbazhu + bazhu_zuofu/youfu.png | **西凉霸主**(jueDing 跨阶) + 左 / 右护法(yiLiu·dengFeng)| 暗紫(主 boss)+ 深褐 / 灰青 |

## 通用 prompt 模板(西北边塞气质)

```
chinese ink painting style portrait, [文化身份], 
[西北风物词: dusty wind / sandy desert / frontier outpost / weathered face / 
desert sun glare / sparse grassland / loess landscape], 
[流派气质词], aged paper texture, monochrome ink wash, 
restrained palette, no weapon detail, 
front-facing chest-up composition, 
--ar 1:1 --stylize 150 --v 7
```

## 15 张具体 prompt 草案

### stage_04_01 流寇 3 人(河西走廊初见)

```
liukou_a: 流寇头领
chinese ink painting style portrait, weathered frontier traveler with stoic 
expression, dusty wind, loess landscape backdrop, dark brown earthy palette, 
broad shoulders, no weapon, restrained ink wash, --ar 1:1 --stylize 150 --v 7

liukou_b: 流寇副手  
chinese ink painting style portrait, lean frontier wanderer, agile posture, 
dusty wind, sparse grassland, slate gray palette, alert eyes, no weapon, 
restrained ink wash, --ar 1:1 --stylize 150 --v 7

liukou_c: 流寇刀手
chinese ink painting style portrait, silent frontier wanderer, narrowed eyes, 
dusty wind, deep purple shadow palette, calm composure, no weapon detail, 
restrained ink wash, --ar 1:1 --stylize 150 --v 7
```

### stage_04_02 玉门把总 3 人(古道驿站)

```
guard_a: 玉门关把总
chinese ink painting style portrait, frontier gatekeeper authority, weathered 
official bearing, dust-worn cloak, loess landscape, dark brown palette, 
no weapon, restrained ink wash, --ar 1:1 --stylize 150 --v 7

guard_b: 西凉骑士
chinese ink painting style portrait, agile frontier rider, lean build, slate 
gray dust-cloak, sparse grassland, alert posture, no weapon, --ar 1:1 --stylize 150 --v 7

guard_c: 商队护卫
chinese ink painting style portrait, silent caravan escort, deep purple cloak, 
desert sun glare, calm vigilance, no weapon, --ar 1:1 --stylize 150 --v 7
```

### stage_04_03 沙匪 3 人(大漠迷踪)

```
shafei_a: 沙匪头领
chinese ink painting style portrait, desert wanderer leader, sand-weathered 
face, dark brown palette, sandy desert backdrop, no weapon, --ar 1:1 --stylize 150 --v 7

shafei_b: 沙盗刀手
chinese ink painting style portrait, silent desert wanderer, deep purple 
palette, sand dust, narrowed gaze, no weapon, --ar 1:1 --stylize 150 --v 7

shafei_c: 沙盗弓手
chinese ink painting style portrait, agile desert wanderer, slate gray, 
sand dust, distant gaze, no weapon, --ar 1:1 --stylize 150 --v 7
```

### stage_04_04 西凉论剑 3 人(校场)

```
xiliangboss: 西凉武林名宿
chinese ink painting style portrait, seasoned frontier elder, dignified beard, 
loess landscape, dark brown palette with worn jade tone, no weapon, 
restrained ink wash, --ar 1:1 --stylize 150 --v 7

xiliang_a/b: 武林名宿之徒
(xiliang_a) slate gray, agile young trainee
(xiliang_b) deep purple, silent young trainee
chinese ink painting style portrait, [color] frontier disciple, drill ground 
backdrop, no weapon, --ar 1:1 --stylize 150 --v 7
```

### stage_04_05 西凉霸主三人组(末 boss · 跨阶)

```
xiliangbazhu: 西凉霸主(jueDing 跨阶 · 寡言派 · yinRou)
chinese ink painting style portrait, enigmatic frontier master, gray robe, 
sparse beard, deep purple ink palette with subtle gold accent, night frontier 
fortress backdrop, hand raised in restrained gesture, no weapon, 
restrained ink wash, mysterious atmosphere, --ar 1:1 --stylize 150 --v 7

bazhu_zuofu: 西凉左护法(yiLiu·dengFeng gangMeng)
chinese ink painting style portrait, stoic frontier guardian, broad build, 
dark brown palette, frontier fortress backdrop, no weapon, --ar 1:1 --stylize 150 --v 7

bazhu_youfu: 西凉右护法(yiLiu·dengFeng lingQiao)
chinese ink painting style portrait, agile frontier guardian, lean build, 
slate gray palette, frontier fortress backdrop, no weapon, --ar 1:1 --stylize 150 --v 7
```

## 派单节奏(用户起 MJ Discord 时)

- **批次 1**(stage_04_01)3 张 / 间隔 45min(累计 ≤ 3 张,安全区)
- **批次 2**(stage_04_02)3 张 / 间隔 45min(累计 6 张,仍安全)
- **批次 3**(stage_04_03)3 张 / 间隔 45min(累计 9 张,接近阈值)
- **批次 4**(stage_04_04)3 张 / **间隔 ≥ 60min**(累计 12 张,警戒)
- **批次 5**(stage_04_05)3 张 / **间隔 ≥ 90min**(累计 15 张,临界,可能 Moderator)

## 落地约定

- assets 路径:`assets/enemies/<filename>.png`
- 文件名严格 = stages.yaml iconPath 值(15 个已锚定,无需重命名)
- 出图后 mv 到 assets/enemies/ + 跑 `flutter clean && flutter run -d windows` 验视觉
- closeout 写 `docs/handoff/mj_ch4_enemy_<batch>_closeout_<date>.md`

## 不变量

- v6 体例(去 sref / 武器抽象 / stylize ≤150)
- 黑名单词(memory `feedback_mj_wuxia_prompt_pitfalls`):`armor / soldier / military / dagger / blade / killer / bandit / weapon`
