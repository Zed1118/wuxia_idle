# Phase D 敌人图 第六批 MJ prompts(2026-06-03 · zongShi + wuSheng · 清零)

> 派单方:Mac Opus · 执行方:用户起 MJ Discord 出图/选片/压缩/归位
> 上游:批1-5 体例 + memory `feedback_mj_wuxia_prompt_pitfalls`
> 本批 = 宗师(zongShi)12 + 武圣(wuSheng)1 = 13 张(顶阶 · Ch5-6 西凉/昆仑/嵩山终段)
> **本批 = 敌人 MJ prompt backlog 清零**(批2-6 共 69 张覆盖 known_missing 全部未认领项;归位后以 asset_audit 为准)

## 配方(敌人胸像 icon)

- `chinese ink painting style portrait` + 非暴力文化身份 + biome 风物 backdrop
- 流派色调:gangMeng 深褐 earthy / lingQiao 灰青 slate gray / yinRou 暗紫 deep purple
- **阶梯度(顶阶)**:zongShi = world-revered grand-grandmaster, supreme mastery, commanding gravitas;wuSheng(#9 西凉霸主终 Boss)= **martial saint, awe-inspiring godlike supremacy, legendary pinnacle, overwhelming aura**。衣着 refined majestic,**仍水墨克制不艳俗**。
- chest-up front-facing / monochrome ink wash / 去 sref / stylize 150 / 去武器名
- **autojourney 防撞车**:每条开头唯一身份词(西凉三弟子 3 人 + 昆仑 3 人 + 嵩山 2 人 + 黄河 2 人尤其错开)
- **触发规避**:剑客→sword-art master / 守关→pass guardian / 巡逻·巡山→patrol warden / 水兵→river marine / 遁客→reclusive master / 义勇→militia stalwart

## 归位映射(文件 ↔ prompt 顺序一致)

| # | iconPath | 身份 | 流派 | 阶 | boss | biome |
|---|---|---|---|---|---|---|
| 1 | assets/enemies/huanghe_shuibing.png | 黄河水兵 | lingQiao | zongShi | | dock |
| 2 | assets/enemies/huanghe_yuantou_yufu.png | 黄河源头渔人 | gangMeng | zongShi | | dock |
| 3 | assets/enemies/kunlun_dunke.png | 昆仑遁客 | yinRou | zongShi | | desert |
| 4 | assets/enemies/kunlun_waimen_shouguan.png | 昆仑外门守关 | lingQiao | zongShi | | desert |
| 5 | assets/enemies/kunlun_xiyuan_jianke.png | 昆仑西渐剑客 | gangMeng | zongShi | | desert |
| 6 | assets/enemies/lunjian_sanchang_xunluo.png | 论剑场散场巡逻 | yinRou | zongShi | | cityWall |
| 7 | assets/enemies/songshan_shouguan.png | 嵩山守关 | yinRou | zongShi | | mountainForest |
| 8 | assets/enemies/songshan_xunshanren.png | 嵩山巡山人 | lingQiao | zongShi | | mountainForest |
| 9 | assets/enemies/xiliang_bazhu.png | 西凉霸主(终) | yinRou | wuSheng | ✓ | mountainForest |
| 10 | assets/enemies/xiliang_disciple_gang.png | 西凉三弟子·刚猛 | gangMeng | zongShi | | mountainForest |
| 11 | assets/enemies/xiliang_disciple_ling.png | 西凉三弟子·灵巧 | lingQiao | zongShi | | mountainForest |
| 12 | assets/enemies/xiliang_sandizi.png | 西凉霸主三弟子 | yinRou | zongShi | | cityWall |
| 13 | assets/enemies/zhongzhou_yiyong.png | 中州义勇 | gangMeng | zongShi | | cityWall |

## prompts(顺序同上)

1 huanghe_shuibing
chinese ink painting style portrait, disciplined yellow-river marine veteran with steady commanding gravitas, on a misty yellow-river dock with war-barges, slate gray palette, lean sinewy build, sharp seasoned eyes, refined martial garb, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

2 huanghe_yuantou_yufu
chinese ink painting style portrait, weathered yellow-river headwater fisherman-sage with profound sturdy presence, by a misty river source among reeds, dark brown earthy palette, broad solid shoulders, deep-lined serene face, refined humble robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

3 kunlun_dunke
chinese ink painting style portrait, reclusive kunlun hermit master with cool fathomless air, amid vast kunlun desert dunes and distant snow peaks, deep purple shadow palette, half-closed profound eyes, supremely serene composure, refined flowing robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

4 kunlun_waimen_shouguan
chinese ink painting style portrait, vigilant kunlun outer-gate pass guardian with agile firm bearing, before a kunlun desert mountain gate, slate gray palette, lithe powerful build, keen penetrating eyes, refined guardian garb, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

5 kunlun_xiyuan_jianke
chinese ink painting style portrait, stalwart kunlun western-march sword-art master with mighty resolute presence, amid kunlun desert dunes under harsh sky, dark brown earthy palette, broad powerful shoulders, hardened intent face, refined martial robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

6 lunjian_sanchang_xunluo
chinese ink painting style portrait, watchful sword-arena closing patrol warden with cool reserved air, before a grey stone city wall at dusk, deep purple shadow palette, narrowed quiet eyes, supremely calm composure, refined dark garb, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

7 songshan_shouguan
chinese ink painting style portrait, solemn songshan mountain pass guardian with quiet imposing air, in a misty songshan pine forest, deep purple shadow palette, narrowed steady eyes, supremely controlled composure, refined dark robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

8 songshan_xunshanren
chinese ink painting style portrait, nimble songshan mountain-ranging patrol warden with keen alert bearing, in a misty songshan pine forest, slate gray palette, lean agile build, sharp clear eyes, refined practical garb, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

9 xiliang_bazhu
chinese ink painting style portrait, supreme xiliang martial-saint overlord with awe-inspiring godlike supremacy and overwhelming aura, on a windswept mountain ridge under a vast brooding sky, deep purple shadow palette, piercing fathomless eyes, utterly commanding stillness, refined majestic overlord robe, legendary martial-saint pinnacle aura, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

10 xiliang_disciple_gang
chinese ink painting style portrait, powerful first xiliang grand-disciple with mighty commanding presence, in a misty mountain forest, dark brown earthy palette, broad towering shoulders, fierce resolute face, refined disciple robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

11 xiliang_disciple_ling
chinese ink painting style portrait, swift second xiliang grand-disciple with agile peerless bearing, in a misty mountain forest, slate gray palette, lithe powerful build, sharp piercing eyes, refined disciple robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

12 xiliang_sandizi
chinese ink painting style portrait, enigmatic third xiliang grand-disciple with cool profound air, before a grey stone city wall, deep purple shadow palette, narrowed fathomless eyes, supremely calm composure, refined dark disciple robe, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

13 zhongzhou_yiyong
chinese ink painting style portrait, valiant central-plains militia stalwart with sturdy upright presence, before a grey stone city wall under banners, dark brown earthy palette, broad steady shoulders, earnest resolute face, refined sturdy garb, world-revered grand-master gravitas, front-facing chest-up composition, monochrome restrained ink wash on aged paper, --ar 1:1 --stylize 150 --no weapon, blade, sabre, dagger, sword, oil painting, vibrant colors, fantasy, anime, photograph --v 7

## 归位

出图选片后压缩(pngquant/oxipng,~250-450KB)→ cp 到上表 iconPath。
归位后:重跑 asset_audit → cp asset_audit_missing.txt known_missing_assets.txt 刷 allowlist。
**敌人 MJ prompt backlog 写完**(批2-6 = 69 张)。归位 + asset_audit 后剩余以实测为准(若仍有零星缺口属研究 tier 过滤遗漏,再补)。
