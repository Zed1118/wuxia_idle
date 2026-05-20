# M4 PoC #46 · Stage 1 PoC 5 件装备 Spec(2026-05-20)

> Stage 0 收官后 Stage 1 PoC:5 件 yaml 真实武器 × 2 套 prompt(icon 白底 + 详情大图带 sref)= 10 张装备图,验证 MJ 出图能否进 Demo 量产。

## §0 决策溯源

接 Stage 0 收官(详 `art_poc_stage0_ref_exploration_2026-05-20.md`):
- ✅ 3 套候选 prompt(A 极致水墨 / B 暗黑沉郁 / C 山水意境)各跑 4-8 张,合计 ~28 张候选
- ✅ Stage 0 验收主观 8/10(套 A 上排右 1 Upscale 后 9/10 厚涂感)+ 客观 4/4 全 pass
- ✅ 锁 4 张 sref(主角色 + 备用角色 + 主环境 + 备用环境),已上传 MJ CDN 拿到稳定 URL
- ✅ 教训沉淀:`--no oil painting, red, vibrant, cinematic` 是水墨防护必带

## §1 4 张 sref baseline(已锁,Stage 1 用)

| 用途 | URL | 内容描述 | 本地备份 |
|---|---|---|---|
| **主角色 sref ⭐** | `https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png` | 套 A:厚涂斗笠剑客侧立 + 米黄宣纸底 + 灰墨厚涂 + 右上角红印章签名 | `~/Desktop/MJ_Stage0_Ref/A_main_char_sref.png` |
| **备用角色 sref** | `https://cdn.midjourney.com/17373e56-b316-4694-bca9-a6d04eb87282/0_3.png` | 修复 B:斗笠剑客全身 + 草丛 + 暖橙灯笼点缀 + 雾感蓝灰 | `~/Desktop/MJ_Stage0_Ref/B_backup_char_sref.png` |
| **主环境 sref ⭐** | `https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png` | 套 C:雪景古松 + 远山 + 极小人物 + 极致水墨意境(与 ChatGPT baseline 04_xuezhong_tingge.png 神还原) | `~/Desktop/MJ_Stage0_Ref/C_env_sref.png` |
| **备用环境 sref** | `https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_2.png` | 套 C:远山栈道 + 双人 + 古松悬崖 | `~/Desktop/MJ_Stage0_Ref/C_env_backup_sref.png` |

**装备图 Stage 1 推荐使用**:**主环境 sref**(`C_env_sref.png` URL)。
**理由**:环境 sref 是无人物纯水墨风,污染最小;装备图也是"无人物物品图",同源一致性最强。如果用角色 sref,可能装备图上长出剑客或灯笼元素。

## §2 5 件装备 PoC 清单(GDD 7 阶跳采,纯 weapon)

跳采样保 7 阶视觉梯度(寻常货 → 神物 一眼可读),全 weapon 类(视觉冲击力强,易出图),全部使用 `data/equipment.yaml` 真实 yaml id + name。

| # | 阶 | yaml id | yaml name | 英文描述(prompt 用) |
|---|---|---|---|---|
| 1 | 寻常货 (1/7) | `weapon_xunchang_tie_jian` | 铁剑 | basic plain iron sword, simple wooden grip, novice weapon, no decoration, rough forging marks |
| 2 | 好家伙 (3/7) | `weapon_haojiahuo_qing_feng_jian` | 青锋剑 | green-tempered steel jian, refined craftsmanship, silk tassel on pommel, jianghu standard sword |
| 3 | 利器 (4/7) | `weapon_liqi_long_quan` | 龙泉剑 | longquan dragon-spring tempered sword, ancient Chinese masterwork, subtle dragon engraving on blade, ornate guard |
| 4 | 宝物 (6/7) | `weapon_baowu_chang_hong_jian` | 长虹剑 | rainbow arc sword, refined steel with iridescent tempering pattern, jianghu treasured weapon, ornate jade pommel, silk wrap |
| 5 | 神物 (7/7) | `weapon_shenwu_tian_wen_jian` | 天问剑 | tian wen mythical sword, divine craftsmanship, brutal weight with battle nicks, otherworldly aura, ancient relic of forgotten era, massive blade |

**视觉梯度设计意图**:
- 寻常货:朴素铁器,锻造痕迹粗糙 → 一眼"廉价"
- 好家伙:钢制 + 丝穗 → "正常江湖货"
- 利器:精铸 + 龙纹 → "好兵器"
- 宝物:镶玉 + 彩芒 + 包丝 → "传家宝"
- 神物:厚重 + 战痕 + 异常气场 → "传说神物"(但 prompt 不写 legendary)

## §3 双轨 Prompt 模板(混合双轨)

### §3.1 列表 icon 模板(白底清晰,128×128 可读)

**不带 sref**(避免污染,要清晰白底独立物品),纯文字描述风格:

```
<英文描述>, isolated centered weapon, clean off-white rice paper background, sharp clear lines, medium ink wash details on blade, suitable for game inventory icon, single weapon only, no character, no scene, no background elements, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors
```

**关键参数**:
- `--ar 1:1`:正方形,适合 icon
- `--stylize 100`:低风格化,清晰可读优先
- `--no character, scene, background elements`:严格独立物品
- `--no oil painting, red, vibrant`:水墨防护

### §3.2 详情大图模板(厚涂氛围,带主环境 sref)

```
<英文描述>, dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon held aloft or suspended in mist, thick paint texture, jianghu poetic mood, ancient relic showcase --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person
```

**关键参数**:
- `--ar 1:1`:正方形,适合详情页
- `--stylize 200`:中等风格化,氛围 + 物品清晰平衡
- `--sref <主环境 sref URL>`:锁水墨厚涂风
- `--no character, person`:防止画出剑客
- `--no oil painting, red, vibrant`:水墨防护

## §4 5 件装备的具体 Prompt(直接复制可用)

### 1. 铁剑(寻常货)

**Icon**:
```
basic plain iron sword, simple wooden grip, novice weapon, no decoration, rough forging marks, isolated centered weapon, clean off-white rice paper background, sharp clear lines, medium ink wash details on blade, suitable for game inventory icon, single weapon only, no character, no scene, no background elements, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors
```

**详情大图**:
```
basic plain iron sword, simple wooden grip, novice weapon, no decoration, rough forging marks, dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon held aloft or suspended in mist, thick paint texture, jianghu poetic mood --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person
```

### 2. 青锋剑(好家伙)

**Icon**:
```
green-tempered steel jian, refined craftsmanship, silk tassel on pommel, jianghu standard sword, isolated centered weapon, clean off-white rice paper background, sharp clear lines, medium ink wash details on blade, suitable for game inventory icon, single weapon only, no character, no scene, no background elements, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors
```

**详情大图**:
```
green-tempered steel jian, refined craftsmanship, silk tassel on pommel, jianghu standard sword, dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon held aloft or suspended in mist, thick paint texture, jianghu poetic mood --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person
```

### 3. 龙泉剑(利器)

**Icon**:
```
longquan dragon-spring tempered sword, ancient Chinese masterwork, subtle dragon engraving on blade, ornate guard, isolated centered weapon, clean off-white rice paper background, sharp clear lines, medium ink wash details on blade, suitable for game inventory icon, single weapon only, no character, no scene, no background elements, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors
```

**详情大图**:
```
longquan dragon-spring tempered sword, ancient Chinese masterwork, subtle dragon engraving on blade, ornate guard, dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon held aloft or suspended in mist, thick paint texture, jianghu poetic mood, ancient relic showcase --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person
```

### 4. 长虹剑(宝物)

**Icon**:
```
rainbow arc sword, refined steel with iridescent tempering pattern, jianghu treasured weapon, ornate jade pommel, silk wrap on grip, isolated centered weapon, clean off-white rice paper background, sharp clear lines, medium ink wash details on blade, suitable for game inventory icon, single weapon only, no character, no scene, no background elements, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors
```

**详情大图**:
```
rainbow arc sword, refined steel with iridescent tempering pattern, jianghu treasured weapon, ornate jade pommel, silk wrap on grip, dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon held aloft or suspended in mist, thick paint texture, jianghu poetic mood, ancient relic showcase --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person
```

### 5. 天问剑(神物)

**Icon**:
```
tian wen mythical sword, divine craftsmanship, brutal weight with battle nicks, otherworldly aura, ancient relic of forgotten era, massive blade, isolated centered weapon, clean off-white rice paper background, sharp clear lines, medium ink wash details on blade, suitable for game inventory icon, single weapon only, no character, no scene, no background elements, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors
```

**详情大图**:
```
tian wen mythical sword, divine craftsmanship, brutal weight with battle nicks, otherworldly aura, ancient relic of forgotten era, massive blade, dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon held aloft or suspended in mist, thick paint texture, jianghu poetic mood, ancient relic showcase --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person
```

## §5 跑图操作清单

### §5.1 顺序建议

按梯度低 → 高顺序跑(让你逐渐感受 7 阶视觉差异):

1. **铁剑** Icon → 详情大图
2. **青锋剑** Icon → 详情大图
3. **龙泉剑** Icon → 详情大图
4. **长虹剑** Icon → 详情大图
5. **天问剑** Icon → 详情大图

每件**先 imagine 1 次 grid(4 张)**,挑最对感觉的 1 张 Upscale,然后下一件。

### §5.2 命名建议

```
~/Desktop/MJ_Stage1_PoC/
├── 01_tie_jian_icon_001.png       <- 铁剑 icon U1
├── 01_tie_jian_detail_001.png     <- 铁剑 详情大图 Upscale
├── 02_qing_feng_jian_icon_001.png
├── 02_qing_feng_jian_detail_001.png
├── 03_long_quan_icon_001.png
├── 03_long_quan_detail_001.png
├── 04_chang_hong_jian_icon_001.png
├── 04_chang_hong_jian_detail_001.png
├── 05_tian_wen_jian_icon_001.png
└── 05_tian_wen_jian_detail_001.png
```

### §5.3 Fast time 估算

10 张目标 × 平均 2-3 次 grid 重抽 = 20-30 次 imagine × ~1 分钟 = **30-45 min Fast time**。Standard 15h Fast 完全够。

### §5.4 出图后

把 10 张全部截图 / 单独发我(可以一张张发,我边看边给反馈调 prompt)。

## §6 验收标准

### §6.1 主观维度(1-10 评分)

- [ ] 5 件大图风格与主环境 sref 主观一致度 ≥ 80%
- [ ] 5 件 icon 在 128×128 缩放下可清晰辨认(给妻子/朋友看不告诉名字,能不能猜出兵器类型?)
- [ ] **7 阶视觉梯度可读**:铁剑 vs 天问剑 一眼看出"廉价 vs 贵重"(梯度感最关键)
- [ ] 装备图无人物 / 灯笼 / 雪松 / 印章 等 sref 主体元素污染
- [ ] 与 ChatGPT baseline `04_xuezhong_tingge.png` 主观风格一致度 ≥ 80%

### §6.2 客观维度(全 pass)

- [ ] 全 10 张无明显 AI 瑕疵(透视错乱 / 鬼画文字 / 多余构件 / 比例失真)
- [ ] icon 严格无背景 / 无场景元素(白底 + 单一物品)
- [ ] 详情大图保留水墨厚涂氛围,饱和度极低(无红 / 无油画)
- [ ] 高分辨率(MJ Upscale 后 2048×2048 起)

### §6.3 通过标准

- 至少 **8/10** 张满足"主观全维度 ≥ 7" + "客观全 pass" → Stage 1 通过 → 起 Stage 2 量产 spec
- **5-7/10** 张达标 → 局部调 prompt 重跑不达标的
- < 5/10 张达标 → 评估 Stage 1 重新设计 prompt / 换 sref / 转 fal.ai

## §7 Stage 1 → Stage 2 路径

### §7.1 验收通过(预期路径)

1. 我起草 `docs/handoff/art_poc_stage2_full_production_2026-05-20.md`,含:
   - 全 35 件装备清单(yaml 真实名,按 7 阶 × 5 件 / 阶分批)
   - 3 师徒角色立绘(祖师 + 大弟子 + 二弟子,用主角色 sref)
   - 5 闭关地图(用主环境 sref)
   - UI 资源(主菜单背景 + 章节封面 + 战斗场景背景)
   - 批次规划(每批 5-7 件,2-3 天跑完一批,避 Fast time 单日上限)
2. Stage 2 预算估算:Fast time ~8-15h(Standard 15h 单月够,可能需要 1 个月跑完或升 Pro $60 加 30h Fast)

### §7.2 验收失败(降级路径)

| 失败模式 | 应对 |
|---|---|
| 装备图厚涂氛围 OK 但梯度不明显(铁剑跟天问剑看着差不多)| 调英文描述差异化:寻常货加 `crude rough`,神物加 `magnificent massive imposing` |
| icon 白底但物品糊 / 不清晰 | 降 `--stylize` 到 50 + 删 sumi-e 等水墨修饰词 |
| 详情大图被 sref 污染(出现剑客/灯笼/印章)| 换 备用环境 sref 或不带 sref 用纯文字 prompt |
| 风格漂移大(每件风格不一致)| 提高 sref 权重 `--sref::1.5` 或转 fal.ai LoRA 训练锁死 |

## §8 教训沉淀(Stage 0 → 1 已锁的 MJ prompt 写作 pitfalls)

| Pitfall | 应对 |
|---|---|
| "warm orange/amber accent" 会被 MJ 放大成全图红色 | 改 `subtle ... in distance` 或彻底删,只在 sref 里保留色温 |
| "cinematic" "deep shadows" 触发好莱坞油画风 | 替换为 `traditional Chinese painting` `sumi-e brushwork` |
| 缺水墨锚定词 → MJ 默认走 dark fantasy | **3 重锚定必带**:`ink wash painting style` + `sumi-e` + `traditional Chinese painting on rice paper` |
| 缺色彩反向锁 → 容易出彩色 | **必带 `monochrome, desaturated muted tones`** + `--no oil painting, red, orange, vibrant colors, cinematic` |
| MJ 把"Chinese painting"误读成加汉字落款 | 装备图 prompt 加 `--no chinese characters, calligraphy, text`(本 spec 未加,若装备图出鬼字再加)|
| `--stylize` 太高(400+)MJ 自由发挥过度 | icon 用 100,详情用 200,环境用 250,人物用 250-400 |

后续可能沉淀 memory `feedback_mj_wuxia_prompt_pitfalls`(Stage 1 收尾时统一沉淀)。

## §9 时间规划

| 时间 | 动作 | 负责 |
|---|---|---|
| 2026-05-20 当天 | Stage 1 spec 落地(本 commit) | 我 ✅ |
| 2026-05-20 / 21 | 用户跑 10 张装备图 | 用户 |
| Stage 1 跑完 | 我+用户验收 + 决策 Stage 2 路径 | 我 + 用户 |
| Stage 2 量产(若通过)| 35 装备 + 3 角色 + 5 场景 + UI ≈ 150 张 | 用户跑 + 我评 + 分批审 |

**预计 Stage 1 完工**:2026-05-21~05-22 之间。
**预计 Stage 2 完工**:2026-06-15 前(取决于批次节奏 + MJ Fast time 月用量)。

## §10 硬约束(沿 Stage 0)

- **GDD §1 水墨克制**(色调/饱和度上限不破)
- **不进 Flutter build**(MJ 出图存 `~/Desktop/MJ_Stage1_PoC/`,Stage 2 验收通过后才进 `assets/equipment/` 等 game asset 路径)
- **黑名单词**(prompt 中不可写):`legendary` / `epic` / `fantasy game art` / `RPG icon` / `anime` / `Genshin Impact style` / `Honkai` / `mobile game art`
- **`--no` 防护必带**:`oil painting, red, vibrant colors` 三件套
- **Cost cap**:Stage 1+2 在 MJ Standard $30 月费内,如果 Stage 2 量产 Fast 不够再考虑升 Pro $60
- **Riverpod / Isar / Flutter 代码层不动**(美术 PoC 与代码无关)

## §11 验证清单(本 spec 落地)

- [x] 本 spec doc 起草完(本 commit)
- [x] 4 张 sref 本地命名整理(`~/Desktop/MJ_Stage0_Ref/` 4 个 *_sref.png)
- [x] PROGRESS.md Stage 0 收官 + Stage 1 启动同步(本 commit)
- [ ] [等用户] Stage 1 跑 10 张装备图
- [ ] [等用户提交] 验收 + 决策 Stage 2 路径

## §12 下波候选(Stage 1 完工后)

| # | 任务 | 触发 |
|---|---|---|
| 1 | Stage 2 量产 spec 起草(全 35 装备 + 3 角色 + 5 场景 + UI 批次规划)| Stage 1 验收 ≥ 8/10 通过 |
| 2 | 调 prompt 重跑 Stage 1 部分装备 | Stage 1 5-7/10 局部不达标 |
| 3 | 转 fal.ai Flux + LoRA 训练 spec | Stage 1 < 5/10 反复不达标 |
| 4 | 同步起手 候选 3 心法相生 §4.5 重设计(sonnet 1-2h)| Stage 1 用户跑图期间 Mac 端空档 |

候选 4 备注:Stage 1 用户跑图 30-60min 期间我可能空档,可以同步起手非阻塞代码任务。等 Stage 1 启动后再拍板。
