# Phase D 敌人图 第一批 MJ prompts(2026-06-02)

> 派单方:Mac Opus · 执行方:用户起 MJ Discord 出图/选片/压缩/归位
> 上游:memory `feedback_mj_wuxia_prompt_pitfalls` + `feedback_mj_character_batch_v6_evolution`
>      + 既有体例 `mj_prompt_ch4_enemy_stage4_2026-05-22.md`
> 权威缺图清单:`test/fixtures/known_missing_assets.txt`(enemy 107)
> 本批 = 最低两阶 xueTu(3) + sanLiu(13) = 16 张(寻常货/像样货,中原 Ch1-2)

## 配方(敌人胸像 icon · 战斗界面圆形头像 80px)

- `chinese ink painting style portrait` + 非暴力文化身份 + biome 风物 backdrop
- 流派色调:gangMeng 深褐 earthy / lingQiao 灰青 slate gray / yinRou 暗紫 deep purple
- 阶梯度:xueTu/sanLiu = humble/coarse/unrefined(前 3 阶禁 refined/exquisite)
- chest-up front-facing / monochrome ink wash / 去 sref / stylize 150 / 去武器名
- 触发规避:已去 killer/soldier/bandit 暴力词改职业;若 Moderator 拒,2-3 张/批间隔

## 归位映射(文件 ↔ prompt 顺序与 chat 输出一致)

| # | iconPath | 身份 | 流派 | 阶 | boss | biome |
|---|---|---|---|---|---|---|
| 1 | assets/enemies/gateguard_b.png | 城兵乙 | yinRou | xueTu | ✓ | cityWall |
| 2 | assets/enemies/dock_a.png | 渡口刀客 | gangMeng | xueTu | ✓ | dock |
| 3 | assets/enemies/dock_b.png | 渡口剑客 | lingQiao | xueTu | ✓ | dock |
| 4 | assets/enemies/black_killer.png | 黑衣杀手 | lingQiao | sanLiu | | escortRoad |
| 5 | assets/enemies/jianghu_a.png | 江湖客甲 | gangMeng | sanLiu | | escortRoad |
| 6 | assets/enemies/jianghu_b.png | 江湖客乙 | yinRou | sanLiu | | escortRoad |
| 7 | assets/enemies/elder_grey.png | 花白胡子老者 | gangMeng | sanLiu | | teaHouse |
| 8 | assets/enemies/kibitzer_a.png | 旁观武人甲 | lingQiao | sanLiu | | teaHouse |
| 9 | assets/enemies/kibitzer_b.png | 旁观武人乙 | yinRou | sanLiu | | teaHouse |
| 10 | assets/enemies/shaonian.png | 春水堂少年 | lingQiao | sanLiu | | smithy |
| 11 | assets/enemies/swordtester_a.png | 试剑客 | gangMeng | sanLiu | | smithy |
| 12 | assets/enemies/swordtester_b.png | 散修客 | yinRou | sanLiu | | smithy |
| 13 | assets/enemies/langren_a.png | 校场浪人 | lingQiao | sanLiu | ✓ | drillGround |
| 14 | assets/enemies/langren_b.png | 校场刀客 | yinRou | sanLiu | ✓ | drillGround |
| 15 | assets/enemies/killer_a.png | 巷口杀手 | yinRou | sanLiu | ✓ | alley |
| 16 | assets/enemies/killer_b.png | 巷尾杀手 | gangMeng | sanLiu | ✓ | alley |

## prompts(顺序同上)

1 gateguard_b
chinese ink painting style portrait, stern town gate watchman with commanding bearing, standing before a grey stone city wall and watchtower, deep purple shadow palette, narrowed cold eyes, calm composure, coarse worn uniform, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

2 dock_a
chinese ink painting style portrait, weathered river-dock ferryman with imposing presence, misty water and wooden pier behind, dark brown earthy palette, broad sturdy shoulders, stoic weathered face, coarse rough clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

3 dock_b
chinese ink painting style portrait, lean river-dock wanderer with alert bearing, misty water and wooden pier behind, slate gray palette, sharp alert eyes, agile poise, plain coarse garb, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

4 black_killer
chinese ink painting style portrait, dark-clad shadowy jianghu figure, on a dusty central-plains escort road with sparse roadside trees, slate gray palette, lean build, sharp alert eyes, plain coarse dark clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

5 jianghu_a
chinese ink painting style portrait, wandering jianghu traveler with steady bearing, on a dusty central-plains escort road with sparse roadside trees, dark brown earthy palette, broad sturdy shoulders, stoic weathered face, coarse worn clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

6 jianghu_b
chinese ink painting style portrait, quiet jianghu wanderer with reserved air, on a dusty central-plains escort road with sparse roadside trees, deep purple shadow palette, narrowed cold eyes, calm composure, plain coarse garb, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

7 elder_grey
chinese ink painting style portrait, grey-bearded old martial elder with calm dignity, inside an old tea house with wooden rafters, dark brown earthy palette, broad steady shoulders, weathered kindly face, plain coarse robe, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

8 kibitzer_a
chinese ink painting style portrait, tea-house onlooker with martial bearing, inside an old tea house with wooden rafters, slate gray palette, lean build, sharp alert eyes, plain coarse garb, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

9 kibitzer_b
chinese ink painting style portrait, reserved tea-house onlooker with quiet air, inside an old tea house with wooden rafters, deep purple shadow palette, narrowed cool eyes, calm composure, plain coarse garb, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

10 shaonian
chinese ink painting style portrait, young martial-hall apprentice with eager bearing, in a blacksmith forge yard with smoke haze, slate gray palette, lean youthful build, bright alert eyes, plain coarse tunic, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

11 swordtester_a
chinese ink painting style portrait, lone sword-testing wanderer with focused bearing, in a blacksmith forge yard with smoke haze, dark brown earthy palette, broad sturdy shoulders, stoic intent face, coarse worn clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

12 swordtester_b
chinese ink painting style portrait, itinerant lone cultivator with detached air, in a blacksmith forge yard with smoke haze, deep purple shadow palette, narrowed quiet eyes, calm composure, plain coarse traveling garb, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

13 langren_a
chinese ink painting style portrait, drill-ground drifter with confident commanding bearing, at a martial training field with a wooden fence, slate gray palette, lean wiry build, sharp alert eyes, plain coarse garb, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

14 langren_b
chinese ink painting style portrait, drill-ground drifter with cold imposing presence, at a martial training field with a wooden fence, deep purple shadow palette, narrowed cold eyes, calm composure, coarse worn clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

15 killer_a
chinese ink painting style portrait, dark-clad alley figure with cold menacing presence, in a narrow shadowed town alley at dusk, deep purple shadow palette, narrowed cold eyes, calm composure, plain coarse dark clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

16 killer_b
chinese ink painting style portrait, dark-clad alley figure with brooding imposing bearing, in a narrow shadowed town alley at dusk, dark brown earthy palette, broad sturdy shoulders, stoic grim face, coarse worn dark clothing, humble unrefined, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

## 归位

出图选片后压缩(pngquant/oxipng,沿 narrative_scene 体例 ~250-450KB)→ cp 到上表 iconPath。
全 16 张归位后:重跑 asset_audit → cp asset_audit_missing.txt known_missing_assets.txt 刷 allowlist(剩 91 enemy + 45 equipment)。
