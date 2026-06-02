# Phase D 敌人图 第二批 MJ prompts(2026-06-03 · erLiu 二流)

> 派单方:Mac Opus · 执行方:用户起 MJ Discord 出图/选片/压缩/归位
> 上游:memory `feedback_mj_wuxia_prompt_pitfalls` + 第一批 `mj_prompts_enemy_batch1_2026-06-02.md`
> 权威缺图清单:`test/fixtures/known_missing_assets.txt`
> 本批 = 二流(erLiu)13 + 一流(yiLiu)补 1 = 14 张(好家伙阶,中原 Ch2-3)

## 配方(敌人胸像 icon · 战斗界面圆形头像)

- `chinese ink painting style portrait` + 非暴力文化身份 + biome 风物 backdrop
- 流派色调:gangMeng 深褐 earthy / lingQiao 灰青 slate gray / yinRou 暗紫 deep purple
- **阶梯度(关键 · 比第一批升一档)**:erLiu = seasoned/practiced/composed/capable(中阶有功底,但**未到 refined/exquisite/ornate** 顶阶)。第一批是 humble/coarse/unrefined,本批换 neat practiced/competent bearing。
- chest-up front-facing / monochrome ink wash / 去 sref / stylize 150 / 去武器名
- **autojourney 防撞车**:每条开头 ~40 字带唯一身份词(本批 14 个身份各不同,已错开开头形容词)
- 触发规避:已去 killer/soldier/bandit 暴力词改职业;流寇→"mountain stronghold headman" 中性化

## 归位映射(文件 ↔ prompt 顺序一致)

| # | iconPath | 身份 | 流派 | 阶 | boss | biome |
|---|---|---|---|---|---|---|
| 1 | assets/enemies/mingmen_a.png | 名门弟子 | lingQiao | erLiu | | cityWall |
| 2 | assets/enemies/jianghu_qianbei.png | 江湖前辈 | gangMeng | erLiu | | cityWall |
| 3 | assets/enemies/anye.png | 暗夜使者 | yinRou | erLiu | | cityWall |
| 4 | assets/enemies/guntou_zhu.png | 擂主光头汉 | gangMeng | erLiu | | drillGround |
| 5 | assets/enemies/taixia_a.png | 台下挑战者 | lingQiao | erLiu | | drillGround |
| 6 | assets/enemies/taixia_b.png | 旁观高手 | yinRou | erLiu | | drillGround |
| 7 | assets/enemies/seng_huiyi.png | 灰袍僧人 | yinRou | erLiu | | temple |
| 8 | assets/enemies/seng_a.png | 寺中沙弥 | gangMeng | erLiu | | temple |
| 9 | assets/enemies/seng_b.png | 寺中行者 | lingQiao | erLiu | | temple |
| 10 | assets/enemies/tongmen_a.png | 雁门同伙甲 | lingQiao | erLiu | ✓ | mountainPath |
| 11 | assets/enemies/tongmen_b.png | 雁门同伙乙 | yinRou | erLiu | ✓ | mountainPath |
| 12 | assets/enemies/shidi_a.png | 灰衣师弟 | gangMeng | erLiu | ✓ | drillGround |
| 13 | assets/enemies/shidi_b.png | 灰衣师妹 | lingQiao | erLiu | ✓ | drillGround |
| 14 | assets/enemies/liukou_a.png | 流寇头领 | gangMeng | yiLiu | | mountainForest |

## prompts(顺序同上)

1 mingmen_a
chinese ink painting style portrait, poised noble-school disciple with refined martial bearing, before a grey stone city wall and watchtower, slate gray palette, sharp clear eyes, upright composed poise, neat practiced attire, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

2 jianghu_qianbei
chinese ink painting style portrait, veteran jianghu senior with steady authoritative presence, before a grey stone city wall and watchtower, dark brown earthy palette, broad solid shoulders, weathered confident face, neat sturdy robe, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

3 anye
chinese ink painting style portrait, hooded night-shade messenger with quiet cold air, before a grey stone city wall at dusk, deep purple shadow palette, narrowed cool eyes, calm controlled composure, neat dark garb, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

4 guntou_zhu
chinese ink painting style portrait, bald muscular arena champion with imposing confidence, on a raised martial arena platform with a blurred watching crowd, dark brown earthy palette, broad powerful shoulders, stoic bold face, neat sturdy vest, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

5 taixia_a
chinese ink painting style portrait, eager arena challenger with agile keen bearing, on a raised martial arena platform with a blurred watching crowd, slate gray palette, lean quick build, sharp bright eyes, neat practiced attire, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

6 taixia_b
chinese ink painting style portrait, watchful hidden expert with reserved cool air, beside a raised martial arena platform with a blurred crowd, deep purple shadow palette, narrowed quiet eyes, calm controlled composure, neat dark garb, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

7 seng_huiyi
chinese ink painting style portrait, grey-robed temple monk with serene profound air, inside an old mountain temple hall with incense haze, deep purple shadow palette, half-closed tranquil eyes, calm controlled composure, neat grey kasaya robe, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

8 seng_a
chinese ink painting style portrait, sturdy young temple novice with earnest steady bearing, inside an old mountain temple hall with incense haze, dark brown earthy palette, broad solid shoulders, calm earnest face, neat plain monk tunic, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

9 seng_b
chinese ink painting style portrait, lean temple wandering practitioner with alert calm bearing, inside an old mountain temple hall with incense haze, slate gray palette, lean agile build, sharp clear eyes, neat plain monk tunic, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

10 tongmen_a
chinese ink painting style portrait, agile yanmen pass accomplice with quick wary bearing, on a misty mountain pass with pine and cliffs, slate gray palette, lean nimble build, sharp darting eyes, neat travel-worn garb, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

11 tongmen_b
chinese ink painting style portrait, shadowy yanmen pass accomplice with cold reserved air, on a misty mountain pass with pine and cliffs, deep purple shadow palette, narrowed cold eyes, calm controlled composure, neat dark travel garb, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

12 shidi_a
chinese ink painting style portrait, grey-clad junior martial brother with sturdy resolute bearing, on a raised martial arena platform with a blurred watching crowd, dark brown earthy palette, broad solid shoulders, stoic resolute face, neat grey uniform, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

13 shidi_b
chinese ink painting style portrait, grey-clad junior martial sister with nimble composed bearing, on a raised martial arena platform with a blurred watching crowd, slate gray palette, lean graceful build, sharp clear eyes, neat grey uniform, seasoned capable rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

14 liukou_a
chinese ink painting style portrait, rugged mountain stronghold headman with commanding tough presence, in a deep misty mountain forest with tall pines, dark brown earthy palette, broad powerful shoulders, weathered hardened face, neat rugged garb, accomplished first-rate rank, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

## 归位

出图选片后压缩(pngquant/oxipng,沿 batch1 体例 ~250-450KB)→ cp 到上表 iconPath。
归位后:重跑 asset_audit → cp asset_audit_missing.txt known_missing_assets.txt 刷 allowlist。
本批 14 张归位后预计 enemy 缺图 91→77。
