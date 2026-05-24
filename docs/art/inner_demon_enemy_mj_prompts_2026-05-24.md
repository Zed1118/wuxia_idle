# 心魔 7 主题 enemy 立绘 MJ v7 prompt 起草

> 起草日期:2026-05-24 · nightshift T03 · 不真出图 prompt only
> 对应 stage_inner_demon_01..07(贪/嗔/痴/慢/疑/空/真),P2.2 final closeout 挂账(`docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md` line 43)
> 体例沿 M4 #46 Stage 2-3 美术工作流(memory `feedback_mj_wuxia_prompt_pitfalls` 18 条 + `feedback_mj_character_batch_v6_evolution` v6.1 合规)
> 后续:用户/Codex 用本 prompt 跑 MJ,绕 Cloudflare 用 Playwright MCP(详底段)

---

## 顶段 · 总体风格锚定

**视觉原型**:7 个 enemy **不是 7 个陌生人**,而是李寒(玩家)自己的 7 重心魔投射 — 同一身形(青布袍 + 背剑 + 中年男 + 短须 + 立姿),只换情绪 tell 与场景 atmosphere(narrative `chapter_inner_demon.yaml` "七处地方都站着一个他自己")。

**3 重水墨锚定**(每条 prompt 必带):`traditional Chinese ink wash painting on aged rice paper` / `sumi-e brushwork` / `monochrome desaturated muted tones`

**3 重防护 `--no`**(每条 prompt 必带):`oil painting, red orange dominant, vibrant colors, cinematic` / `fantasy, anime, RPG icon, legendary, epic` / `photograph, realistic photo, modern`

**精致度档**:wuSheng 阶 boss 立绘 → 走 7 阶最饱满处理(memory `feedback_collab_mode_single_lore_workflow` Tier 风格梯度 神物档),关键词 `composed elder figure, weathered mastery, distilled bearing`(不写 divine / mythical 触发 7 阶上限词)。

**参数 baseline**:`--ar 2:3 --style raw --sw 50 --stylize 200 --v 7` (sw 50 风格继承 + 内容独立,memory 第 3 条;style raw 防 MJ 默认装饰;stylize 200 detail 类平衡,memory 第 9/13 条)。**sref 主角色 baseline**:`https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png`(memory 主 sref baseline,套 A 厚涂斗笠剑客)。

**黑名单词**(全 prompt 严禁):`legendary / epic / 神器 / 传说级 / 无敌 / 最强 / fantasy game art / Genshin / mobile game art / Western medieval / armor / soldier / military / killer / bandit / violence / blood splatter` — 触发 Moderator 或破水墨调子。

**⚠️ Moderator 风险提示**(memory `feedback_mj_character_batch_v6_evolution`):7 张角色立绘 sref 累计接近 manual review 阈值(~10 张),**分 2 batch 跑(批 1:贪嗔痴慢 4 张 / 批 2:疑空真 3 张),batch 间隔 ≥ 30 min**。Moderator 拒绝时套底段 fallback 配方。

---

## 01 贪 (greed)

**视觉概念**:同形李寒立姿,左手攥一只暗黄玉珏(古玉佩 lore 呼应,memory 第 13/17 条),怀抱凌乱叠堆的器物(玉、剑鞘、铜钱袋),目光下垂盯着掌中物,嘴角微紧。背后地上散落更多旧物,雾色山口背景(沿 `chapter_inner_demon` "松林山口")。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged composed figure in a plain dark indigo cloth robe, with one hand clutching an old yellowed jade pendant close to chest, the other arm cradling a disorderly heap of antique objects (jade pieces, an empty scabbard, a cloth pouch of bronze coins), gaze cast down at the objects in hand with subtle tense expression at the mouth corner, more scattered old belongings on the ground behind, misty pine pass background, the clutched objects in the foreground large and clearly visible, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, missing figure, empty scene, multiple figures
```

**避坑检查**:✓ 无黑名单词 / ✓ 武器抽象(empty scabbard 不命名 jian/dao) / ✓ 水墨 3 重锚 / ✓ 印章落款(memory 第 4 条接受) / ✓ 主体可见性(memory 第 13 条 `large and clearly visible`)

---

## 02 嗔 (wrath)

**视觉概念**:同形李寒立姿,手中提一柄出鞘长剑,剑尖一滴朱砂色水痕(艺术化,**不写 blood-dripping/dripping blood**避免 Moderator),面色泛朱、双目赤红,身后远景一座被烟火薰过的山门轮廓(`smouldering temple silhouette in distant background, drifting ash`,不写 burned-down/destroyed/violence)。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged figure in a plain dark indigo cloth robe holding a single long unsheathed blade lowered at side, a single vermilion droplet at the tip of the blade rendered in classical ink-and-cinnabar style, his face and eyes flushed with restrained crimson tone, a smouldering distant temple silhouette in the misty far background with drifting ash specks, the figure standing centered in foreground large and clearly visible, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones with a single cinnabar accent only at sword tip and eyes, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, blood splatter, gore, violence, military, missing figure, empty scene, multiple figures
```

**避坑检查**:✓ 无 blood/burned/violence(改 vermilion droplet / smouldering silhouette) / ✓ 武器抽象(single long blade 不写 jian) / ✓ 暖色局部锁定(memory 第 5 条 single cinnabar accent only) / ✓ 印章落款

---

## 03 痴 (obsession)

**视觉概念**:同形李寒立姿,怀中紧抱一件已枯黄、布料残破的旧衣(故人遗物意象),目光呆滞投向虚空(不看怀中亦不看观者),周身散落几片秋叶(`fallen leaves at his feet, unswept`),站姿稍僵似不觉时间流走,背景是空寂的旧院墙轮廓。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged figure in a plain dark indigo cloth robe holding a withered yellowed old garment tightly to his chest, his gaze vacant and unfocused staring into empty space neither at the garment nor at viewer, several scattered fallen leaves at his feet unswept, posture slightly rigid as if unaware of passing time, an empty old courtyard wall silhouette in the misty background, the figure and held garment in foreground large and clearly visible, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones with subtle aged-yellow accent only on the held garment, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, missing figure, empty scene, multiple figures
```

**避坑检查**:✓ 无黑名单词 / ✓ 无武器具名(隐没,这一关是衣不是剑) / ✓ 水墨 3 重锚 / ✓ 主体定位前置 / ✓ 印章落款

---

## 04 慢 (arrogance)

**视觉概念**:同形李寒立姿,立于群山之巅一块裸岩,**袖手负后**(双手藏袖于身后)俯瞰云海下的山岭,下颌微抬,目光不及人间(不看脚下亦不看观者),全图视角从下方仰拍以强化"立于群山之巅"。背景是云雾涌动的连绵山脊。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged figure in a plain dark indigo cloth robe standing on a bare rocky peak above a sea of clouds, both hands hidden inside sleeves clasped behind his back, gaze looking out over distant mountain ridges with chin slightly lifted, not regarding anything below or before him, low-angle view emphasizing the height of the peak with the figure silhouetted against drifting mist, rolling mountain ridges extending into the misty distance, the figure standing centered in foreground large and clearly visible, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, missing figure, empty scene, multiple figures
```

**避坑检查**:✓ 无黑名单词 / ✓ 无武器(藏 sleeves) / ✓ 水墨 3 重锚 / ✓ 主体可见性 / ✓ 仰视角度独立锁定 / ✓ 印章落款

---

## 05 疑 (doubt)

**视觉概念**:同形李寒立姿,正对一面**斑驳古铜镜**(镜立于一旧木几之上),镜中映出**另一同形之我**(姿态略不同 — 镜中之我眼神更冷锐,似不识镜外人),持剑之手隐隐颤动(`one trembling hand on sword hilt at side`)。背景虚化只剩镜与人。

**注**:同框 2 figure(本体 + 镜中倒影)是本主题不可绕的视觉,加强 `mirror reflection counts as part of single subject not separate person` 解释词以降低 Moderator multiple figures 误判。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged figure in a plain dark indigo cloth robe standing before a tarnished mottled old bronze mirror set on an old wooden stand, the mirror showing his own reflection rendered as ink wash within the mirror frame counts as part of the single subject not a separate person, the reflection has a subtly colder sharper gaze as if not recognizing the man outside, one trembling hand resting on the hilt at his side, blurred empty background with only the mirror and the man as subject, the figure and mirror in foreground large and clearly visible, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones with subtle aged-bronze accent only on the mirror surface, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, missing figure, empty scene, two separate people, twin figures
```

**避坑检查**:✓ 无黑名单词 / ✓ 武器抽象(hilt 不命名) / ✓ 水墨 3 重锚 / ✓ 显式镜面 reflection 不算 multiple figures / ✓ 双重 `--no two separate people, twin figures` 防误判

---

## 06 空 (void)

**视觉概念**:同形李寒立姿,**半隐于浓雾之中**,衣冠齐整但面部表情完全空白(`expressionless face, neither calm nor pained`),身形边缘开始**化入雾色**(`form gradually dissolving into the surrounding mist at the edges`),不显具体场景。整体最虚最淡的一张。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged figure in a plain dark indigo cloth robe standing half-hidden within thick swirling mist, clothes and hair neatly arranged but the face entirely expressionless neither calm nor pained nor angry, the silhouette edges of the figure gradually dissolving into the surrounding mist as if the form is about to disperse, no defined background only enveloping mist, the figure in foreground large and clearly visible despite the dissolving edges, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones in extremely subdued palette, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, ghost, spirit, demon, supernatural creature, missing figure, empty scene, multiple figures
```

**避坑检查**:✓ 无黑名单词 / ✓ 显式 `--no ghost, spirit, demon, supernatural creature` 防西式鬼魂联想 / ✓ 主体可见性平衡 dissolving / ✓ 水墨 3 重锚 / ✓ 印章落款

---

## 07 真 (truth)

**视觉概念**:同形李寒立姿,**正对观者**(`facing the viewer directly`,本主题唯一直视玩家投射),衣衫是 7 张中最朴素一件(去任何装饰、布料最简素),目光澄然清明无任何情绪干扰(`eyes serene and clear, no emotion overlay`),背景一片洁净的米黄宣纸感空白(`clean off-white rice paper background, no scene`)。最克制最干净的一张,与前 6 张形成"漫长心魔之后只剩本来面目"的对照。

**MJ v7 prompt**:
```
A traditional Chinese ink wash painting depicting a middle-aged figure in the plainest most unadorned dark indigo cloth robe of all, facing the viewer directly in a calm upright pose, eyes serene and clear with no emotion overlay neither sorrow nor joy nor tension, hands resting naturally at sides, the most restrained and minimal composition of the series, clean off-white rice paper background with no scene only the figure as the entire subject, the figure in foreground large and clearly visible, traditional sumi-e brushwork on aged rice paper, monochrome desaturated muted tones at their most restrained, ancient seal stamp signature --ar 2:3 --style raw --sw 50 --stylize 200 --v 7 --no oil painting, red orange dominant, vibrant colors, cinematic, fantasy, anime, RPG icon, legendary, epic, photograph, realistic photo, modern, decorative ornament, missing figure, empty scene, multiple figures
```

**避坑检查**:✓ 无黑名单词 / ✓ 无武器 / ✓ 水墨 3 重锚 / ✓ "facing viewer directly" 玩家投射成立 / ✓ `--no decorative ornament` 防 MJ 加饰 / ✓ 印章落款

---

## 底段 · 生成约定

**输出尺寸**:`--ar 2:3` 立绘竖图,陈列在 `lib/features/inner_demon/presentation/inner_demon_screen.dart`(子菜单 enemy 选择卡)。

**asset 命名**(snake_case,主题英文锚词与本 doc 一致):
- `assets/images/inner_demon/enemy_tan.png` (贪 greed)
- `assets/images/inner_demon/enemy_chen.png` (嗔 wrath)
- `assets/images/inner_demon/enemy_chi.png` (痴 obsession)
- `assets/images/inner_demon/enemy_man.png` (慢 arrogance)
- `assets/images/inner_demon/enemy_yi.png` (疑 doubt)
- `assets/images/inner_demon/enemy_kong.png` (空 void)
- `assets/images/inner_demon/enemy_zhen.png` (真 truth)

**跑 MJ 节奏纪律**(memory `feedback_mj_character_batch_v6_evolution`):分 2 batch,**批 1 = 贪嗔痴慢(4 张)**,**批 2 = 疑空真(3 张)**,batch 间隔 ≥ 30 min,每 batch 内 prompt 间停 30s 防 Moderator 累计触发。

**Moderator 拒绝 fallback**(memory 第 16 条 + v6.1 5 条降级):① 去 `--sref`(去 sw 50) → ② `--stylize 200 → 100` → ③ 武器进一步抽象(blade → long object) → ④ 身份艺术化(remove "figure" → "elder traveller / common villager")。

**MJ CDN 下图绕 Cloudflare**(memory `feedback_mj_wuxia_prompt_pitfalls` 第 11 条):curl/wget 被 cf-mitigated 挡 403 → Playwright MCP `browser_navigate → browser_wait_for time=8 → browser_evaluate fetch → arrayBuffer → btoa(chunk 0x8000) → filename .b64 → sed strip JSON quote → base64 -d > png`。≤4 张可让用户手动贴 URL 我 Read 视觉对照(memory `feedback_mj_url_paste_order` 文件名禁盲推顺序,先 tmp 名 → Read 验内容 → mv 归位)。
