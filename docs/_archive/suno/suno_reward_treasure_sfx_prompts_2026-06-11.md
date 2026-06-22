# Suno reward 爆品音效重做 Prompt：reward v2（得宝质感）

> 日期：2026-06-11
> 目标:重生成 `reward`(高阶爆品 jingle)。用户真玩反馈旧 reward 与 `victory` 风格太像、听感重叠。
> 病因:旧 reward 与 victory 同为上扬「赢了」感 jingle。reward 现已**门槛化**(只重器/宝物/神物爆品才响,配印章盖落动画),需要专属的「**得珍宝**」质感。
> 方向:**珍稀、庄重、有价值感的「得宝」音,不是胜利欢腾**。武侠玉磬/古琴泛音/铜铃余韵,内敛清越,一缕余韵收束。明确区别 victory 的明亮决断上扬。
> 模式:Suno `Sounds` / `One-Shot`。目标 ≤1.5s(落位裁切 + 归一到与 victory 同产线响度)。
> 落位:替换 `assets/audio/sfx/reward.mp3`(文件名即接线,零 Dart 改动)。动画 wiring 已用旧 reward 占位跑通,新素材到位后直接替换。

## reward（高阶爆品「得宝」jingle）

### reward_treasure_v2_01 — 玉磬清越

```text
Create a short rare-treasure acquisition sound for a martial arts game, under 1.5 seconds. NOT a victory fanfare. A single clear jade chime / stone qing strike, bright and pure, with a brief elegant resonance that settles. It should feel like obtaining a precious rare artifact: valuable, restrained, dignified, a moment of quiet awe — not cheering, not triumphant, no upward winning melody. Real wuxia instrument timbre. No drums, no vocals, no orchestral fanfare, no casino or gacha sparkle, no long tail.
```

### reward_treasure_v2_02 — 古琴泛音得宝

```text
Very short wuxia treasure-get stinger, 1 to 1.5 seconds, one-shot. A clear guqin harmonic pluck over a soft low resonance, like a rare relic revealing itself. Refined, precious, calm, slightly mysterious. Clearly different from a battle-victory sound: no rising triumphant phrase, no bright fanfare, no bell celebration. Just one elegant plucked harmonic that blooms and fades. No melody development, no vocals, no drums, no reverb wash.
```

### reward_treasure_v2_03 — 铜铃 + 磬庄重

```text
Short one-shot sound for receiving a high-tier treasure in a wuxia game, under 1.5 seconds. A small bronze bell tap layered with a stone chime, giving a dignified, ceremonial "rare item obtained" feel. Restrained and weighty, a sense of value and significance — not happy, not victorious, no fanfare. Traditional Chinese percussion/metal timbre, dry and clean with a short controlled ring. No song, no rhythm, no vocals, no orchestral swell, no long tail.
```

### reward_treasure_v2_04 — 玉磬+泛音叠层（神物级，最华）

```text
A short, rich rare-artifact acquisition sound for a martial arts game, 1 to 1.5 seconds. Layer a jade chime, a guqin harmonic, and a faint shimmering resonance into one elegant strike that signals obtaining a legendary treasure. Precious, awe-inspiring, refined and restrained — dignified wonder, NOT a victory cheer or fanfare, no rising triumphant melody. Real wuxia instrument timbres, clean attack, graceful short decay. No drums, no vocals, no casino sparkle, no cinematic riser, no long reverb tail.
```

## 回收与落位

1. 生成后下载到桌面任意文件夹(如 `~/Desktop/reward_treasure_v2_20260611/`),把路径告诉我。
2. 我做静音裁切体检(沿 v2 技术处理体例:响度/峰值/头尾静音)+ afplay AB 筛选,并与现有 `victory.mp3` 对放确认「听感已区别开」。
3. 选定后替换 `assets/audio/sfx/reward.mp3`,重编 release 包真玩复验(打高阶爆品 → 印章动画 + 新得宝音)。
