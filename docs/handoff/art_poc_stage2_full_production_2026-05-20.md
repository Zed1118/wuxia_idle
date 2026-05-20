# M4 PoC #46 · Stage 2 全量产 Spec(2026-05-20)

> Stage 1+1.5 PoC 全收官 → Stage 2 量产 ~88 张:28 件装备 + 3 师徒角色 + 5 闭关地图 + UI 资源 ~10 张。
> 预计 4-6 周完工(每周 1 批 ~30min Fast time)。

---

## §0 决策溯源 + Stage 1 教训

详 `art_poc_stage1_closeout_2026-05-20.md` + memory `feedback_mj_wuxia_prompt_pitfalls`。

**5 大装备类型全覆盖通过**(剑 jian / 刀 dao / 鞭索 / 防具 / 饰品)→ 进 Stage 2 量产。

---

## §1 全量产物清单(~88 张)

### §1.1 装备 28 件待跑(Stage 1+1.5 已跑 7 件)

7 阶 × 5 件 = 35 件;已跑 7 件(铁剑/青锋剑/龙泉剑/盘龙刀/缠丝索/锦袍/玉龙佩);**剩 28 件 × 2 = 56 张**。

#### 寻常货(1/7) — 剩 4 件
- weapon_xunchang_zhe_dao(折刀)— 刀类
- weapon_xunchang_ruan_bian(软鞭)— 鞭类
- armor_xunchang_bu_yi(粗布衣)— 防具
- accessory_xunchang_yu_pei(玉佩)— 饰品

#### 像样货(2/7) — 5 件
- weapon_xiangyang_gang_dao(钢刀)
- weapon_xiangyang_chang_jian(长剑)
- weapon_xiangyang_jiu_jie_bian(九节鞭)
- armor_xiangyang_pi_jia(皮甲)
- accessory_xiangyang_yin_jie(银戒)

#### 好家伙(3/7) — 剩 2 件
- weapon_haojiahuo_xuan_hua_fu(玄花斧)
- accessory_haojiahuo_yu_pei_lao(古玉佩)

#### 利器(4/7) — 剩 3 件
- weapon_liqi_lian_zi_bian(链子鞭)
- armor_liqi_xuan_tie_jia(玄铁甲)
- accessory_liqi_fei_yu_pei(翡玉佩)

#### 重器(5/7) — 5 件(yaml 待 grep 确认 zhongQi 阶完整名单)
- weapon_zhongqi_*(3 件)
- armor_zhongqi_*(1 件)
- accessory_zhongqi_*(1 件)

#### 宝物(6/7) — 剩 4 件
- weapon_baowu_xuan_tian_fu(玄天斧)
- weapon_baowu_chang_hong_jian(长虹剑)
- weapon_baowu_xue_lian_bian(血莲鞭)
- armor_baowu_jin_si_jia(金丝甲)

#### 神物(7/7) — 5 件
- weapon_shenwu_po_jun_dao(破军刀)
- weapon_shenwu_tian_wen_jian(天问剑)
- weapon_shenwu_huan_meng_bian(幻梦鞭)
- armor_shenwu_xuan_huang_pao(玄黄袍)
- accessory_shenwu_kun_lun_pei(昆仑佩)

### §1.2 师徒角色立绘 3 张

GDD §7.1 师徒系统:
- **祖师**:武僧形态(参 baseline `characters/04_wuseng_chanzhang.png`)
- **大弟子**:斗笠剑客形态(参 baseline `01_jianke_douli_baodao.png`)
- **二弟子**:女剑客形态(参 baseline `02_jianke_nuxia.png`)

带主角色 sref + `--sw 50`。

### §1.3 闭关地图 5 张

GDD §7.3 闭关系统 5 地图,参 ChatGPT baseline environments(5 张):
- 雪山亭(参 baseline `04_xuezhong_tingge.png`)
- 山岩栈道(参 baseline `05_shanyan_zhandao.png`)
- 山门寺庙(参 baseline `03_shanmen_simiao.png`)
- 水乡夜雨(参 baseline `02_shuixiang_yeyu.png`)
- 山村客栈(参 baseline `01_shancun_kezhan.png`)

带主环境 sref + `--sw 30`(允许更多变化)+ 16:9 横屏。

### §1.4 UI 资源 ~10 张

- 主菜单背景 1 张(参 baseline `ui/main_menu_jianghuxing.png` 结构)
- 章节封面 3 张(学武出山 / 武林初识 / 名扬江湖)
- 战斗场景背景 ~5 张

### §1.5 总计

| 类别 | 张数 | 已完成 | 待跑 |
|---|---|---|---|
| 装备 | 70(35 件 × 2 风格) | 14(7 件 × 2) | 56(28 件 × 2) |
| 角色立绘 | 3 | 0 | 3 |
| 闭关地图 | 5 | 0 | 5 |
| UI 资源 | ~10 | 0 | ~10 |
| **总** | **~88 张** | **14** | **~74 张** |

---

## §2 6 周批次规划

| 周 | 批次 | 内容 | 张数 | Fast 估算 |
|---|---|---|---|---|
| W1(本周-下周) | 第 1 批 | 寻常货剩 4 件 | 8 | ~20 min |
| W2 | 第 2 批 | 像样货 5 件 | 10 | ~25 min |
| W3 | 第 3 批 | 好家伙+利器剩 5 件 | 10 | ~25 min |
| W4 | 第 4 批 | 重器 5 件 + 3 师徒角色立绘 | 13 | ~40 min |
| W5 | 第 5 批 | 宝物+神物 9 件 | 18 | ~45 min |
| W6 | 第 6 批 | 5 闭关地图 + ~10 UI 资源 | ~15 | ~40 min |
| **总** | — | — | **~75 张** | **~200 min Fast(~3.3h)** |

**Standard 15h Fast 月配额绰绰有余**。

---

## §3 Prompt 模板库(5 类装备 + 角色 + 场景 + UI)

⚠️ **本 spec 仅作模板归档**。**Stage 2 每批次跑图时,我在对话里完整展开该批次所有 prompt**(参 memory `feedback_prompt_inline_ready_to_paste`),不让用户去 spec 找模板拼。

### §3.1 剑 jian 模板(Stage 1 验证)

**Icon**(不带 sref):
```
[精致度词梯度] [yaml name pinyin] jian sword, Chinese double-edged straight sword, symmetrical blade both sides sharp, [装备特征描述], isolated centered weapon, clean off-white background, sharp clear lines, single weapon only, no character, no scene, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors, fantasy, dao, sabre, curved blade, single edge
```

**详情大图**(带主环境 sref):
```
[精致度词梯度] [yaml name pinyin] jian sword, Chinese double-edged straight sword, symmetrical blade both sides sharp, [装备特征描述], dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon suspended in mist, thick paint texture, jianghu poetic mood --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --no oil painting, red, orange dominant, vibrant colors, character, person, fantasy, dao, sabre, curved blade, single edge
```

### §3.2 刀 dao 模板(Stage 1 验证,**必带 `--sw 50`**)

**Icon**:
```
[精致度词梯度] [yaml name pinyin] dao sabre, Chinese single-edged sabre with one sharp edge only, dao with curved spine, not jian sword, not double-edged, [装备特征描述], isolated centered weapon, clean off-white background, sharp clear lines, single weapon only, no character, no scene, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors, fantasy, double-edged, symmetrical blade, jian sword, straight sword
```

**详情大图**(带 sref + `--sw 50`):
```
[精致度词梯度] [yaml name pinyin] dao sabre, Chinese single-edged sabre with one sharp edge only, dao with curved spine, not jian sword, [装备特征描述], dramatic ceremonial display, dark ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background with subtle amber accent light, weapon suspended in mist, thick paint texture, jianghu poetic mood --ar 1:1 --stylize 200 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --sw 50 --no oil painting, red, orange dominant, vibrant colors, character, person, fantasy, double-edged, symmetrical blade, jian sword, straight sword
```

### §3.3 鞭/索/链 模板(Stage 1.5 验证,**必带 `--sw 50`**)

**Icon**:
```
[精致度词梯度] [yaml name pinyin] Chinese flexible weapon, flexible coiled rope/chain weapon with metal weighted tip, [装备特征描述], jianghu standard quality, sturdy braiding with iron weighted dart end, isolated centered weapon arranged in elegant coil showing flexibility, clean off-white background, sharp clear lines, single weapon only, no character, no scene, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors, fantasy, sword, blade, rigid weapon, jian, dao, sabre
```

**详情大图**(带 sref + `--sw 50`):同结构,加水墨修饰词 + sref + sw 50。

### §3.4 防具 模板(Stage 1.5 验证,**必带 `no figure inside` + `--sw 50`**)

**Icon**:
```
[精致度词梯度] [yaml name pinyin] Chinese traditional garment armor, [装备类型: silk robe / leather armor / iron armor], draped flowing with subtle embroidery patterns, hanging displayed empty garment, no figure inside, no body, no person wearing, [装备特征描述], isolated centered garment, clean off-white background, sharp clear lines, single item only, no character, no scene, museum display style --ar 1:1 --stylize 100 --v 7 --no character, person, figure inside, body, scene, background elements, oil painting, red, vibrant colors, fantasy, sword, weapon
```

**详情大图**(带 sref + `--sw 50`):同结构。

### §3.5 饰品 模板(Stage 1.5 验证,**必带 `--sw 50`**)

**Icon**:
```
[精致度词梯度] [yaml name pinyin] Chinese ornamental accessory, [装备类型: jade pendant / silver ring / jade ornament], with woven silk cord, ceremonial jade accessory, [装备特征描述], isolated centered ornament, clean off-white background, sharp clear lines, single item only, no character, no scene, museum display style --ar 1:1 --stylize 100 --v 7 --no character, scene, background elements, oil painting, red, vibrant colors, fantasy, sword, weapon, robe
```

**详情大图**(带 sref + `--sw 50`):同结构。

### §3.6 角色立绘 模板(用主角色 sref + `--sw 50`)

```
[角色描述: ancient Chinese wuxia martial artist / wandering wuseng monk / young swordswoman / ...], standing full body portrait, [角色特征 + 持具: holding ... / wearing ...], ink wash painting style, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette, atmospheric misty background, weathered tattered long robe, solitary contemplative pose, generous negative space, thick paint texture, jianghu poetic mood --ar 2:3 --stylize 250 --v 7 --sref https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png --sw 50 --no oil painting, red, orange dominant, vibrant colors, fantasy, anime, cartoon
```

### §3.7 闭关地图 模板(用主环境 sref + `--sw 30`)

```
[地图描述: misty mountain pavilion / cliff path with ancient pines / temple mountain gate / ...], misty mountain landscape, Chinese ink wash painting, sumi-e style, distant mountains in soft grey wash, pine trees in foreground, pale ink tonality, monochrome, ultimate color restraint, jianghu poetic mood, traditional rice paper texture, no figure or tiny figure as focal point --ar 16:9 --stylize 250 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --sw 30 --no oil painting, red, vibrant, cinematic, character, large person
```

### §3.8 UI 资源 模板(主菜单 / 章节封面)

```
[场景描述], wide cinematic landscape composition for game UI background, Chinese ink wash painting, sumi-e brushwork, traditional Chinese painting on rice paper, monochrome grey-black palette with subtle amber accent, atmospheric misty depth, generous negative space for UI overlay text, thick paint texture, jianghu poetic mood --ar 16:9 --stylize 300 --v 7 --sref https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png --sw 50 --no oil painting, red, vibrant, cinematic Hollywood, character close-up
```

---

## §4 7 阶精致度梯度词汇(再次明确)

详 memory `feedback_mj_wuxia_prompt_pitfalls` §6。

| 阶 | 关键词 |
|---|---|
| 寻常货 | `crude, ugly, rough, pitted, bent, beginner work, cheap, no decoration, no aesthetic appeal` |
| 像样货 | `plain, basic, sturdy, no-frills, common quality` |
| 好家伙 | `well-made, decent craftsmanship, sturdy reliable jianghu standard, modest tassel` |
| 利器 | `refined, beautifully forged, jianghu masterwork, elegant proportions, ornate guard` |
| 重器 | `notable craftsmanship, distinctive, recognizable` |
| 宝物 | `exquisite, ornate, masterful, treasured jianghu artifact, ceremonial silk wrap` |
| 神物 | `divine craftsmanship, awe-inspiring, ancient mythical relic, otherworldly aura, mythical weight, battle-scarred blade` |

---

## §5 验收标准

每批次完工后:
- [ ] 风格一致度 ≥ 80%(参 sref baseline)
- [ ] 类型识别度 ≥ 90%(剑/刀/鞭/防具/饰品 一眼可读)
- [ ] 7 阶视觉梯度可读
- [ ] 无明显 AI 瑕疵
- [ ] 无人物 / sref 内容污染(印章作国画落款除外)

不达标处理:
- 风格漂移 → 加强 sref 权重或调 stylize
- 类型错误 → 加强类型锁定咒语 + `--no` 防护
- AI 瑕疵 → 重抽

---

## §6 Fast Time 预算 + Cost Cap

### 总预估
- 28 件装备 × 2 张 × 平均 2 次重抽 = ~112 次 imagine
- 3 角色 × 平均 3 次重抽 = ~9 次
- 5 闭关地图 × 2 次 = ~10 次
- ~10 UI × 2 次 = ~20 次
- **总 ~151 次 imagine × ~1 min = ~2.5h Fast time**

### Standard 15h Fast 月配额够吗?
**够**。但**集中跑可能挤压** → 建议**分 6 周批次**(每周 ~30min Fast)。

### 升 Pro $60 时机
- 某周 Fast 用完 + Relax 太慢 → 升 Pro
- 需要 Stealth mode 保护设计不公开 → 升 Pro
- **暂不升**,Stage 2 当月观察 Fast time 用量

---

## §7 时间规划

**Stage 2 完工目标**:**2026-06-29(6 周)**。

| 周 | 完工日 | 张数 累计 |
|---|---|---|
| W1 | 2026-05-25 | 22 |
| W2 | 2026-06-01 | 32 |
| W3 | 2026-06-08 | 43 |
| W4 | 2026-06-15 | 56 |
| W5 | 2026-06-22 | 74 |
| W6 | 2026-06-29 | ~89 |

---

## §8 硬约束

- **GDD §1 水墨克制**(色调/饱和度上限不破)
- **不进 Flutter build**(MJ 出图存 `~/Desktop/MJ_Stage2_W*/`,Stage 2 完工后才进 `assets/equipment/` 等)
- **黑名单词永禁**(详 memory):legendary / epic / fantasy / anime / mobile game / Western medieval
- **`--no` 防护必带**(详 memory):oil painting, red, orange dominant, vibrant colors, cinematic, character, person, fantasy
- **`--sw 50` 非剑装备必带**(刀/鞭/防具/饰品/角色/场景/UI)
- **印章接受作国画落款**(不再加 --no seal stamp)
- **Riverpod / Isar / Flutter 代码层不动**(美术 PoC 与代码无关)
- **每批次跑图前**:我在对话里完整展开该批次所有 prompt(参 memory `feedback_prompt_inline_ready_to_paste`),不让用户去 spec 拼

---

## §9 验证清单(本 spec 落地)

- [x] 本 spec doc 起草完(本 commit)
- [x] 28 件装备 yaml 真实名清单(7 阶分布)
- [x] 3 角色 + 5 场景 + UI 模板规划
- [x] 6 周批次规划 + Fast time 预算
- [x] 5 类装备 + 角色 + 场景 + UI prompt 模板库
- [ ] [等用户] Stage 2 W1 第 1 批跑图(寻常货剩 4 件 8 张)
- [ ] 每批次后:我评 + 沉淀 + commit

---

## §10 下波候选(Stage 2 完工后,1.0 远期)

| # | 任务 | 触发 |
|---|---|---|
| 1 | 把 ~88 张 PoC + 量产产物归位 `assets/equipment/` 等 game asset 路径 | Stage 2 完工 |
| 2 | Flutter UI 接入装备图(equipment_widget icon + detail page)| asset 归位后 |
| 3 | 后续 1.0 阶段扩 35 → 100+ 件装备出图 | Stage 2 完工 + 1.0 启动 |
| 4 | 考虑转 fal.ai Flux + LoRA 训练锁死风格(当 1.0 100+ 件不想再依赖 MJ 月费时)| 1.0 启动 |
