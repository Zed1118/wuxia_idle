# Phase D 敌人图 第四批 MJ prompts(2026-06-03 · jueDing 绝顶)

> 派单方:Mac Opus · 执行方:用户起 MJ Discord 出图/选片/压缩/归位
> 上游:批1/2/3 体例 + memory `feedback_mj_wuxia_prompt_pitfalls`
> 权威缺图清单:`test/fixtures/known_missing_assets.txt`
> 本批 = 绝顶(jueDing)14 张(宝物阶,Ch5 中州/西凉论剑线)
> jueDing 共 27 缺图,本批前 14;余 13 jueDing + 宗师 13 + 武圣 1 后续续批

## 配方(敌人胸像 icon)

- `chinese ink painting style portrait` + 非暴力文化身份 + biome 风物 backdrop
- 流派色调:gangMeng 深褐 earthy / lingQiao 灰青 slate gray / yinRou 暗紫 deep purple
- **阶梯度(顶阶前夜 · 比第三批再升)**:jueDing = peerless/transcendent presence/grandmaster aura,气象逼近宗师。衣着可 **refined elegant**(顶阶解禁,但仍水墨克制不奢华艳俗)。
- chest-up front-facing / monochrome ink wash / 去 sref / stylize 150 / 去武器名
- **autojourney 防撞车**:每条开头 ~40 字带唯一身份词(中州论剑 4 人尤其错开:先锋/副手/助阵/顶)
- **触发规避**:刀客/剑客/水寇/守将/舵主 改中性:刀客→martial master / 剑客→sword-art master / 水寇→river-guild man / 守将→garrison commander / 舵主→river-guild helm master

## 归位映射(文件 ↔ prompt 顺序一致)

| # | iconPath | 身份 | 流派 | 阶 | boss | biome |
|---|---|---|---|---|---|---|
| 1 | assets/enemies/xiliangbazhu.png | 西凉霸主 | yinRou | jueDing | ✓ | frontier |
| 2 | assets/enemies/weishui_chuangong.png | 渭水船工头 | lingQiao | jueDing | | mountainForest |
| 3 | assets/enemies/tongguan_shoujiang.png | 潼关守将 | gangMeng | jueDing | | mountainForest |
| 4 | assets/enemies/changan_daoke.png | 长安刀客 | yinRou | jueDing | | mountainForest |
| 5 | assets/enemies/zhongzhou_wuxue.png | 中州武学传人 | gangMeng | jueDing | | temple |
| 6 | assets/enemies/songshan_daozong_dizi.png | 嵩山道宗弟子 | lingQiao | jueDing | | temple |
| 7 | assets/enemies/daojia_jianke.png | 道家剑客 | yinRou | jueDing | | temple |
| 8 | assets/enemies/yidu_jianke.png | 义渡剑客 | yinRou | jueDing | | dock |
| 9 | assets/enemies/caobang_duozhu.png | 漕帮舵主 | gangMeng | jueDing | | dock |
| 10 | assets/enemies/huanghe_shuikou.png | 黄河水寇 | lingQiao | jueDing | | dock |
| 11 | assets/enemies/zhongzhou_lunjian_xianfeng.png | 中州论剑先锋 | gangMeng | jueDing | ✓ | drillGround |
| 12 | assets/enemies/zhongzhou_fushou.png | 中州论剑副手 | lingQiao | jueDing | | drillGround |
| 13 | assets/enemies/zhongzhou_zhuzhen.png | 中州论剑助阵 | yinRou | jueDing | | drillGround |
| 14 | assets/enemies/zhongzhou_lunjian.png | 中州论剑顶尖 | gangMeng | jueDing | | cityWall |

## prompts(顺序同上)

1 xiliangbazhu
chinese ink painting style portrait, formidable xiliang frontier overlord with peerless commanding presence, on an arid frontier pass with sand dunes and a distant fortress, deep purple shadow palette, imposing broad frame, piercing cold eyes, refined elegant chieftain robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

2 weishui_chuangong
chinese ink painting style portrait, masterful weishui river boatmen-chief with deft peerless bearing, in a deep misty mountain forest by a river bend, slate gray palette, lean sinewy build, sharp penetrating eyes, refined practical garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

3 tongguan_shoujiang
chinese ink painting style portrait, mighty tongguan garrison commander with towering resolute presence, in a deep misty mountain forest before a mountain fortress, dark brown earthy palette, broad powerful shoulders, hardened majestic face, refined officer armor robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

4 changan_daoke
chinese ink painting style portrait, enigmatic changan martial master with cool peerless air, in a deep misty mountain forest at twilight, deep purple shadow palette, narrowed profound eyes, supremely calm composure, refined dark elegant robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

5 zhongzhou_wuxue
chinese ink painting style portrait, distinguished central-plains martial heir with stately peerless bearing, inside an old mountain temple hall with incense haze, dark brown earthy palette, broad upright shoulders, noble composed face, refined scholarly martial robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

6 songshan_daozong_dizi
chinese ink painting style portrait, refined songshan daoist-sect disciple with serene agile bearing, inside an old mountain temple hall with incense haze, slate gray palette, lithe graceful build, clear penetrating eyes, refined daoist robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

7 daojia_jianke
chinese ink painting style portrait, transcendent daoist sword-art master with ethereal quiet air, inside an old mountain temple hall with incense haze, deep purple shadow palette, half-closed profound eyes, supremely calm composure, refined flowing daoist robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

8 yidu_jianke
chinese ink painting style portrait, poised ferry-crossing sword-art master with cool refined air, on a misty yellow-river dock with moored ferries, deep purple shadow palette, narrowed keen eyes, supremely calm composure, refined elegant robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

9 caobang_duozhu
chinese ink painting style portrait, commanding canal-guild helm master with sturdy peerless presence, on a misty yellow-river dock with moored barges, dark brown earthy palette, broad mighty shoulders, weathered authoritative face, refined guild-master garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

10 huanghe_shuikou
chinese ink painting style portrait, agile yellow-river guild man with swift peerless bearing, on a misty yellow-river dock with rushing currents, slate gray palette, lean nimble build, sharp darting eyes, refined practical garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

11 zhongzhou_lunjian_xianfeng
chinese ink painting style portrait, vanguard champion of the central-plains sword discourse with bold peerless presence, on a grand martial arena platform with a vast blurred crowd, dark brown earthy palette, broad commanding shoulders, fierce resolute face, refined contender robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

12 zhongzhou_fushou
chinese ink painting style portrait, deputy second of the central-plains sword discourse with agile keen bearing, on a grand martial arena platform with a vast blurred crowd, slate gray palette, lean quick build, sharp bright eyes, refined contender robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

13 zhongzhou_zhuzhen
chinese ink painting style portrait, supporting second of the central-plains sword discourse with reserved cool air, beside a grand martial arena platform with a vast blurred crowd, deep purple shadow palette, narrowed quiet eyes, supremely calm composure, refined dark robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

14 zhongzhou_lunjian
chinese ink painting style portrait, supreme grandmaster of the central-plains sword discourse with absolute commanding presence, before a grey stone city wall under vast sky, dark brown earthy palette, broad towering frame, piercing majestic eyes, refined master's robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

## 归位

出图选片后压缩(pngquant/oxipng,~250-450KB)→ cp 到上表 iconPath。
归位后:重跑 asset_audit → cp asset_audit_missing.txt known_missing_assets.txt 刷 allowlist。
本批 14 张归位后预计 enemy 缺图:63→49(余 13 jueDing + 13 zongShi + 1 wuSheng + 其他)。
