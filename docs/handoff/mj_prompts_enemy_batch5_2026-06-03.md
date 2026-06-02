# Phase D 敌人图 第五批 MJ prompts(2026-06-03 · jueDing 余 + zongShi)

> 派单方:Mac Opus · 执行方:用户起 MJ Discord 出图/选片/压缩/归位
> 上游:批1-4 体例 + memory `feedback_mj_wuxia_prompt_pitfalls`
> 本批 = 绝顶(jueDing)13 + 宗师(zongShi)1 = 14 张(Ch4-5 轻功对决终段 + 群战 + 西凉边塞)
> 本批后剩 13 缺图(12 zongShi + 1 wuSheng)= 第六批清零

## 配方(敌人胸像 icon)

- `chinese ink painting style portrait` + 非暴力文化身份 + biome 风物 backdrop
- 流派色调:gangMeng 深褐 earthy / lingQiao 灰青 slate gray / yinRou 暗紫 deep purple
- **阶梯度**:jueDing = peerless/transcendent/grandmaster aura(同批4);zongShi(#14 黄河急流人)= **legendary world-shaking grand-grandmaster, supreme mastery**(更高一阶,水墨克制不奢)。衣着 refined elegant。
- chest-up front-facing / monochrome ink wash / 去 sref / stylize 150 / 去武器名
- **autojourney 防撞车**:每条开头 ~40 字唯一身份词(changfeng/pubu/massbattle 同 biome 组尤其错开)
- **触发规避**:守将→garrison commander / 剑客→sword-art master / 刀客→martial master / 残将→battered frontier commander / 狂骑→wild frontier rider / 刺客→shadow prowler / 胡骑→nomad horseman / 铁卫→iron guardian

## 归位映射(文件 ↔ prompt 顺序一致)

| # | iconPath | 身份 | 流派 | 阶 | boss | biome |
|---|---|---|---|---|---|---|
| 1 | assets/enemies/lightfoot_changfeng_a.png | 关楼守将 | gangMeng | jueDing | ✓ | frontier |
| 2 | assets/enemies/lightfoot_changfeng_b.png | 长风剑客 | lingQiao | jueDing | ✓ | frontier |
| 3 | assets/enemies/lightfoot_changfeng_c.png | 万里刀客 | yinRou | jueDing | ✓ | frontier |
| 4 | assets/enemies/lightfoot_pubu_a.png | 山涧剑客 | lingQiao | jueDing | | cliffWaterfall |
| 5 | assets/enemies/lightfoot_pubu_b.png | 瀑布刀客 | yinRou | jueDing | | cliffWaterfall |
| 6 | assets/enemies/lightfoot_pubu_c.png | 险崖游侠 | gangMeng | jueDing | | cliffWaterfall |
| 7 | assets/enemies/massbattle_canbu_a.png | 西凉残将 | gangMeng | jueDing | ✓ | frontier |
| 8 | assets/enemies/massbattle_canbu_b.png | 西凉狂骑 | lingQiao | jueDing | ✓ | frontier |
| 9 | assets/enemies/massbattle_canbu_c.png | 西凉刺客 | yinRou | jueDing | ✓ | frontier |
| 10 | assets/enemies/massbattle_guanqi_a.png | 胡骑万夫 | lingQiao | jueDing | | frontier |
| 11 | assets/enemies/massbattle_guanqi_b.png | 胡骑游骑 | yinRou | jueDing | | frontier |
| 12 | assets/enemies/massbattle_guanqi_c.png | 胡骑铁卫 | gangMeng | jueDing | | frontier |
| 13 | assets/enemies/songshan_daozong.png | 嵩山道宗 | lingQiao | jueDing | ✓ | cityWall |
| 14 | assets/enemies/huanghe_jichuang.png | 黄河急流人 | yinRou | zongShi | | dock |

## prompts(顺序同上)

1 lightfoot_changfeng_a
chinese ink painting style portrait, mighty frontier gate-tower garrison commander with towering peerless presence, atop a windswept frontier gate-tower at a mountain pass, dark brown earthy palette, broad commanding shoulders, hardened majestic face, refined officer robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

2 lightfoot_changfeng_b
chinese ink painting style portrait, swift long-wind sword-art master with agile peerless bearing, on a windswept frontier pass with drifting clouds, slate gray palette, lithe graceful build, sharp piercing eyes, refined flowing robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

3 lightfoot_changfeng_c
chinese ink painting style portrait, far-roaming martial master with cool peerless air, on a vast windswept frontier plain at dusk, deep purple shadow palette, narrowed profound eyes, supremely calm composure, refined dark robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

4 lightfoot_pubu_a
chinese ink painting style portrait, poised mountain-stream sword-art master with serene agile bearing, beside a roaring cliff waterfall and pines, slate gray palette, lithe graceful build, clear penetrating eyes, refined robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

5 lightfoot_pubu_b
chinese ink painting style portrait, shadowy waterfall martial master with cool quiet air, beside a roaring cliff waterfall in mist, deep purple shadow palette, narrowed calm eyes, supremely controlled composure, refined dark robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

6 lightfoot_pubu_c
chinese ink painting style portrait, rugged cliff-edge ranger with sturdy free peerless bearing, on a perilous cliff ledge by a waterfall, dark brown earthy palette, broad steady shoulders, weathered open face, refined rugged garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

7 massbattle_canbu_a
chinese ink painting style portrait, battered xiliang frontier commander with grim resolute presence, on a war-torn frontier battlefield with banners, dark brown earthy palette, broad weathered shoulders, scarred stern face, refined battle-worn armor robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

8 massbattle_canbu_b
chinese ink painting style portrait, wild xiliang frontier rider with fierce agile presence, on a war-torn frontier battlefield with dust haze, slate gray palette, lean powerful build, blazing sharp eyes, refined riding armor, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

9 massbattle_canbu_c
chinese ink painting style portrait, silent xiliang shadow prowler with cold lethal air, on a war-torn frontier battlefield at dusk, deep purple shadow palette, narrowed icy eyes, supremely calm composure, refined dark fitted garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

10 massbattle_guanqi_a
chinese ink painting style portrait, swift nomad horseman leader with keen commanding bearing, on a windswept frontier steppe with distant horses, slate gray palette, lean wiry build, sharp alert eyes, refined nomad garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

11 massbattle_guanqi_b
chinese ink painting style portrait, roving nomad outrider with cool reserved air, on a windswept frontier steppe at twilight, deep purple shadow palette, narrowed watchful eyes, supremely calm composure, refined nomad garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

12 massbattle_guanqi_c
chinese ink painting style portrait, armored nomad iron-guardian with sturdy imposing presence, on a windswept frontier steppe with banners, dark brown earthy palette, broad mighty shoulders, stoic hardened face, refined heavy garb, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

13 songshan_daozong
chinese ink painting style portrait, eminent songshan daoist-sect grandmaster with serene towering presence, before a grey stone city wall under a vast sky, slate gray palette, upright composed frame, clear penetrating eyes, refined daoist master robe, transcendent grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

14 huanghe_jichuang
chinese ink painting style portrait, legendary yellow-river rapids elder with world-shaking supreme mastery and profound stillness, on a misty yellow-river dock amid rushing currents, deep purple shadow palette, deep-set fathomless eyes, utterly serene composure, refined elder's robe, peerless legendary grandmaster aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

## 归位

出图选片后压缩(pngquant/oxipng,~250-450KB)→ cp 到上表 iconPath。
归位后:重跑 asset_audit → cp asset_audit_missing.txt known_missing_assets.txt 刷 allowlist。
本批 14 张归位后预计 enemy 缺图:49→35 余 13(批6 zongShi 12 + wuSheng 1 清零)。
