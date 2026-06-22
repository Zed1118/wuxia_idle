# Codex 派单：Suno SFX 批量生成 + 下载（uiPaperOpen / reward / battleHit·Crit）

> 日期：2026-06-12 · 执行方：Mac 本地 Codex（浏览器操作 suno.com）
> 你的职责**只到「生成 + 下载到桌面」为止**。裁切体检 / 响度归一 / 落位 `assets/audio/sfx/` / 接线 / 重编包，全部由 Claude 回收时做（文件名即接线，零 Dart 改）。你**不要**碰仓库代码或 assets 目录。

## 前提
- suno.com 已用用户账号登录（若未登录，停下来报告，不要自行注册/登录）。
- 用 **Sounds / sound-effect / one-shot** 这类音效模式（不是写歌模式），instrumental，**无人声、无旋律、无长混响尾**。每条 prompt 已自带 "no music/no vocals/no tail" 约束，照贴即可。
- 每条 prompt **生成 1 次即可**（suno 通常一次出 2 个变体，两个都下载，Claude 后筛）。
- 时长目标见每组标题；suno 出来偏长无妨，Claude 落位时会裁切。

## 下载落位（统一）
全部下到一个父文件夹，按组分子文件夹，文件名保留 suno 默认名即可（能区分先后就行）：

```
~/Desktop/挂机武侠_suno_sfx_20260612/
├── uiPaperOpen/      ← 4 条 prompt 的产物
├── reward/           ← 4 条
└── battleHit/        ← battleHit 4 条 + battleCrit 2 条 全放这里，文件名带 hit / crit 区分
```

完成后报告：**父文件夹绝对路径** + 每组实际下载到几个文件。把路径发回给 Claude，Claude 做 afplay AB 筛 + 落位。

---

## 组 1 · uiPaperOpen（弹窗/面板展开 UI 音）· 目标 0.25–0.55s · 极短极轻

uipaperopen_v1_01 — 宣纸轻展
```
A very short, soft UI sound of a sheet of rice paper (xuan paper) being gently unfolded, under half a second. A single subtle paper rustle with a light airy texture, delicate and restrained — a quiet, tasteful interface feedback for opening a panel in a Chinese wuxia game. Soft, low-presence, not attention-grabbing. No music, no melody, no chime, no vocals, no reverb tail, no drums.
```

uipaperopen_v1_02 — 卷轴轻开
```
A tiny one-shot interface sound of a small paper scroll opening, 0.3 to 0.5 seconds. A brief, soft paper slide / unroll with a faint air movement, elegant and minimal — the sound of a wuxia menu or dialog sliding open. Gentle and unobtrusive, clean and dry. No musical notes, no bell, no whoosh sweep, no vocals, no long tail.
```

uipaperopen_v1_03 — 纸页翻动（脆而短）
```
A crisp, very short page-turn UI sound for a wuxia game menu, about 0.3 seconds. A single light paper flip with a soft papery snap, refined and quiet, used as feedback when a panel appears. Subtle and low in level, not startling. Real paper texture, dry and clean. No music, no chime, no vocal, no reverb, no rhythm, no long decay.
```

uipaperopen_v1_04 — 宣纸 + 微气感（最含蓄）
```
An extremely subtle UI feedback sound for opening a paper panel in a calligraphy-themed wuxia game, under 0.5 seconds. A faint xuan-paper unfold layered with a barely-there breath of air, soft, refined, almost ambient — a whisper of paper, not a loud effect. Should sit quietly under the interface, low presence, tasteful. No melody, no chime, no bell, no drums, no vocals, no reverb wash, no long tail.
```

---

## 组 2 · reward（高阶爆品「得宝」jingle）· 目标 ≤1.5s · 珍稀庄重，明确区别 victory 的欢腾上扬

reward_treasure_v2_01 — 玉磬清越
```
Create a short rare-treasure acquisition sound for a martial arts game, under 1.5 seconds. NOT a victory fanfare. A single clear jade chime / stone qing strike, bright and pure, with a brief elegant resonance that settles. It should feel like obtaining a precious rare artifact: valuable, restrained, dignified, a moment of quiet awe — not cheering, not triumphant, no upward winning melody. Real wuxia instrument timbre. No drums, no vocals, no orchestral fanfare, no casino or gacha sparkle, no long tail.
```

reward_treasure_v2_02 — 古琴泛音得宝
```
Very short wuxia treasure-get stinger, 1 to 1.5 seconds, one-shot. A clear guqin harmonic pluck over a soft low resonance, like a rare relic revealing itself. Refined, precious, calm, slightly mysterious. Clearly different from a battle-victory sound: no rising triumphant phrase, no bright fanfare, no bell celebration. Just one elegant plucked harmonic that blooms and fades. No melody development, no vocals, no drums, no reverb wash.
```

reward_treasure_v2_03 — 铜铃 + 磬庄重
```
Short one-shot sound for receiving a high-tier treasure in a wuxia game, under 1.5 seconds. A small bronze bell tap layered with a stone chime, giving a dignified, ceremonial "rare item obtained" feel. Restrained and weighty, a sense of value and significance — not happy, not victorious, no fanfare. Traditional Chinese percussion/metal timbre, dry and clean with a short controlled ring. No song, no rhythm, no vocals, no orchestral swell, no long tail.
```

reward_treasure_v2_04 — 玉磬+泛音叠层（神物级，最华）
```
A short, rich rare-artifact acquisition sound for a martial arts game, 1 to 1.5 seconds. Layer a jade chime, a guqin harmonic, and a faint shimmering resonance into one elegant strike that signals obtaining a legendary treasure. Precious, awe-inspiring, refined and restrained — dignified wonder, NOT a victory cheer or fanfare, no rising triumphant melody. Real wuxia instrument timbres, clean attack, graceful short decay. No drums, no vocals, no casino sparkle, no cinematic riser, no long reverb tail.
```

---

## 组 3 · battleHit + battleCrit（平A 兵刃打击）· 目标 ≤1s · 真实钢刃，短干利落，不要乐器

battlehit_blade_v3_01 — 剑刃挥砍命中
```
Create a very short sword strike sound effect for a martial arts game, under 1 second. One single hit: a steel sword blade slicing through air and landing with a crisp metallic edge contact. Real weapon foley, dry and clean, no ring tail. It plays on every normal attack, so it must be short, restrained, satisfying, never annoying. No music, no instruments, no melody, no explosion, no gore, no scream, no cartoon whoosh, no long reverb.
```

battlehit_blade_v3_02 — 兵刃轻碰（金属对金属）
```
Very short metal-on-metal weapon impact, under 1 second, one-shot. A light steel blade tap against another blade: sharp, thin, precise metallic click with a tiny scrape, like two swords briefly touching in a duel. Realistic Chinese wuxia weapon foley. Dry, clean, fast decay. No music, no bell, no chime melody, no anime exaggeration, no explosion, no long metallic ringing.
```

battlehit_blade_v3_03 — 破风入肉感（衣袂+刃风+触击）
```
One-shot sword attack hit for a wuxia game, under 1 second. Sequence in one sound: a fast blade swish cutting air, then a muted sharp impact as the strike lands on cloth and body. Mostly air-cut and edge contact, slightly metallic, not bloody, not wet. Short, dry, controlled. No music, no instruments, no gore squelch, no scream, no cinematic boom, no tail.
```

battlehit_blade_v3_04 — 利落剑锋（偏脆单击）
```
Ultra short game hit sound, 0.3 to 0.8 seconds, single strike only. A crisp steel sword edge impact: bright thin metallic snap with a hint of blade swish before it. Feels like a clean precise sword cut connecting. Real weapon recording style, restrained, immediate, dry. No melody, no chime, no bell, no whoosh-only, no fantasy magic shimmer, no reverb tail.
```

battlecrit_blade_v3_01 — 重斩+短余响
```
Short critical hit sword sound for a martial arts game, under 1.5 seconds, one-shot. A heavier steel blade strike: strong metallic clash with a brief sharp ring that decays fast. Clearly more powerful than a normal hit but same realistic weapon family, not magical. Dry, decisive, restrained. No music, no instruments, no explosion, no gacha sparkle, no long ringing tail, no slow motion drama.
```

battlecrit_blade_v3_02 — 双段重击
```
One-shot heavy sword critical strike, under 1.5 seconds. A fast blade swish into a hard metallic impact with a tiny secondary crunch, like a sword biting deep through a guard. Realistic wuxia weapon foley, powerful but controlled, quick decay. No music, no bell melody, no explosion, no gore, no scream, no cinematic riser, no long reverb.
```

---

源文档（如需更多背景）：`docs/suno_uipaperopen_sfx_prompts_2026-06-12.md` / `docs/suno_reward_treasure_sfx_prompts_2026-06-11.md` / `docs/suno_battlehit_blade_sfx_prompts_2026-06-11.md`
