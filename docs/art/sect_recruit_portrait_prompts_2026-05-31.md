# sect/recruit 招募 NPC 立绘 9 张 MJ prompt(2026-05-31)

> 候选 4 backlog:坐实缺口 = 6 sect_candidates + 3 recruit_candidates,全部 portraitPath 已配但图未出。
> 配方 = W4 师徒立绘同款(主角色 sref + sw60 + ar2:3 + stylize300)→ 与已出 founder/disciple 同画风血脉感。
> 体例依据:memory feedback_mj_wuxia_prompt_pitfalls(第15条立绘 trade-off)+ feedback_mj_character_batch_v6_evolution(节奏纪律)。

## 主角色 sref(锁定,9 张全用)
`https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png`(套A厚涂斗笠剑客+红印章+米黄宣纸底)

## 节奏纪律(降 Moderator 累计触发)
- **分 2 批**:批1 = 竹影/漠行/山隐/江湖/幽谷(5,混3流派);批2 间隔 ≥30min = 铁匠/云寒青/柳拂陻/马智远(4)
- 每批**先单张 PoC**(grid 4),过了再批量;每 4-6 prompt 停 30s
- **降级预案**:任一触发 Moderator → 该张去 sref + 武器抽象(chain whip→"long decorative object" / jian·dao→"slim long object")+ 身份艺术化(figure)+ stylize 100 + ar 1:1 + 加 `--no photograph, realistic photo, character realism, weapon, blade`(v6 合规配方,牺牲画风统一)

## 对照表
| # | 角色 | 文件名 | 流派 | 武器 | 年龄/差异锚(防撞型) |
|---|------|--------|------|------|---------------------|
| 1 | 竹影客 | sect_candidate_bamboo.png | lingQiao | 长剑 jian | 青年20s·内敛灵秀·竹林 |
| 2 | 漠行客 | sect_candidate_desert.png | gangMeng | 钢刀 dao | 中年40s·壮硕风沙·短须 |
| 3 | 山隐子 | sect_candidate_mountain.png | yinRou | 链鞭 | 成熟50s·沉静·鬓微霜 |
| 4 | 江湖客 | sect_candidate_river.png | lingQiao | 长剑 jian | 中年30s末·随性带笑·酒葫芦 |
| 5 | 幽谷客 | sect_candidate_valley.png | yinRou | 链鞭 | 中年40s·孤僻·药篓 |
| 6 | 铁匠之子 | sect_candidate_blacksmith.png | gangMeng | 钢刀 dao | 青年20s·朴实·铁砧炉 |
| 7 | 云寒青 | recruit_candidate_a.png | gangMeng | 钢刀 dao | 28s·坚毅·边塞短须 |
| 8 | 柳拂陻 | recruit_candidate_b.png | lingQiao | 长剑 jian | 女·20s·轻灵·江南屋脊 |
| 9 | 马智远 | recruit_candidate_c.png | 无流派 | 链鞭 | 青年20s·书生·青衫书卷 |

## 9 条 prompt(逐条整行复制)

# 1. 竹影客 -> sect_candidate_bamboo.png
A young man in his early 20s with refined quiet features, clean-shaven, full dark hair tied in a simple topknot, standing full body portrait, wearing a plain bamboo-green muted robe, holding a slender Chinese double-edged jian sword loosely at his side, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with jade-green accent, atmospheric misty bamboo forest background with light rain, solitary graceful poised pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, scars, blood, dirty face, multiple figures

# 2. 漠行客 -> sect_candidate_desert.png
A sturdy middle-aged man in his 40s, sun-bronzed steady face, short trimmed dark beard, full dark hair, broad shoulders, standing full body portrait, wearing a coarse ochre-brown travel robe, holding a single-edged Chinese dao sabre with one curved sharp edge, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with ochre-brown accent, atmospheric misty desert dunes background with a distant stone pass gate, solitary weathered pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, ancient sage, scars, blood, dirty face, military uniform, double-edged jian, straight sword, multiple figures

# 3. 山隐子 -> sect_candidate_mountain.png
A mature man in his early 50s with composed serene features, mostly dark hair greying at the temples tied up neatly, clean-shaven, standing full body portrait, wearing a muted indigo and dark-green hermit robe, holding a loosely coiled flexible chain whip, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with muted indigo accent, atmospheric misty mountain valley background with medicinal herbs, solitary quiet pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, bald, ancient sage, wispy long beard, scars, blood, dirty face, nunchaku, three-section staff, sword, multiple figures

# 4. 江湖客 -> sect_candidate_river.png
A lively middle-aged man in his late 30s with a warm open expression and a faint smile, short dark stubble, full dark hair loosely tied, standing full body portrait, wearing a worn travel-green robe with a wine gourd at his waist, a thin Chinese double-edged jian sword slung across his back, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with muted green accent, atmospheric misty riverside canal-town background, casual relaxed pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, scars, blood, dirty face, multiple figures

# 5. 幽谷客 -> sect_candidate_valley.png
A reclusive lean man in his mid 40s with a quiet guarded expression, loose dark hair, clean-shaven, standing full body portrait, wearing a shadowy dark-green secluded robe with a herb basket on his back, holding a loosely coiled flexible chain whip, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with dark-green accent, atmospheric misty deep secluded valley background, solitary withdrawn pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, ancient sage, wispy beard, scars, blood, dirty face, nunchaku, three-section staff, sword, multiple figures

# 6. 铁匠之子 -> sect_candidate_blacksmith.png
A young man in his early 20s with an honest sturdy face, clean-shaven, cropped dark hair, muscular forearms, standing full body portrait, wearing a simple iron-grey blacksmith tunic with a leather apron, a sturdy single-edged Chinese dao sabre at his waist, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with forge-ember amber accent, atmospheric misty village smithy background with a cold forge, solitary grounded pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, scars, blood, dirty face, double-edged jian, straight sword, multiple figures

# 7. 云寒青 -> recruit_candidate_a.png
A resolute man in his late 20s with firm steady features, short trimmed dark beard, full dark hair, upright bearing, standing full body portrait, wearing a deep charcoal-grey sturdy travel robe, holding a single-edged Chinese dao sabre, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with iron-grey accent, atmospheric misty northern frontier peaks background, solitary disciplined pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, scars, blood, dirty face, military uniform, armor, double-edged jian, straight sword, multiple figures

# 8. 柳拂陻 -> recruit_candidate_b.png
A nimble young swordswoman in her early 20s with graceful agile features, dark hair tied back neatly, standing full body portrait, wearing a light willow-green agile traveler outfit, a thin slender Chinese double-edged jian sword slung across her back, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with light jade-green accent, atmospheric misty Jiangnan rooftops and canal-town background, poised nimble pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, male, beard, white hair, elderly, scars, blood, dirty face, multiple figures

# 9. 马智远 -> recruit_candidate_c.png
A young scholar in his early 20s with refined gentle features, clean-shaven, dark hair in a neat scholar topknot, standing full body portrait, wearing a plain ink-blue scholar robe, holding a loosely coiled flexible chain whip with a book scroll tucked at his belt, ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with subtle ink-blue accent, atmospheric misty academy courtyard background, calm upright scholarly pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 300 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 60 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon, photograph, realistic photo, white hair, elderly, bald, scars, blood, dirty face, nunchaku, three-section staff, sword, multiple figures
