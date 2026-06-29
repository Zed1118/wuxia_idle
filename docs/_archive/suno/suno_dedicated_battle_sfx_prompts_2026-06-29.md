# Suno / SFX 专属战斗音效 Prompt：battleUlt + battleChargeStart

> 日期：2026-06-29  
> 目标：重做 `assets/audio/sfx/battleUlt.mp3` 与 `assets/audio/sfx/battleChargeStart.mp3`。  
> 现状：两个槽位已接线，但当前素材是转用裁切版，不能当最终专属素材。  
> 模式：优先使用专门 SFX/foley 工具；若用 Suno，使用 `Sounds` / `One-Shot`，生成后必须裁切、响度统一、人工试听筛选。

## battleUlt（大招 / 绝技释放）

目标文件：

```text
assets/audio/sfx/battleUlt.mp3
```

听感目标：

- 0.8-1.6s，一次性释放提示。
- 明显区别普通命中、暴击和境界突破。
- 古琴扫弦、短钟磬、气劲推出，有“绝技出手”的仪式感。
- 不能像升级、胜利、抽卡、爆炸或影视预告片。

### battleult_dedicated_v1_01 — 琴弦聚势 + 短钟

```text
One-shot ultimate skill release sound for a realistic Chinese wuxia combat game, 0.8 to 1.6 seconds. A tight guqin string sweep gathers force, followed by a short deep stone chime and restrained internal-energy push. Ceremonial and decisive, clearly stronger than a normal hit, but grounded and elegant. No music phrase, no melody, no victory fanfare, no level-up sound, no explosion, no trailer boom, no anime magic, no casino sparkle, no long reverb tail.
```

### battleult_dedicated_v1_02 — 剑气破空 + 钟磬收束

```text
Short one-shot wuxia ultimate attack cue, under 1.5 seconds. A sharp blade-energy sweep through air, dry cloth movement, then a low temple chime that cuts off quickly. Feels like a martial master unleashing a decisive technique. Restrained, mature, ink-wash atmosphere. No orchestral hit, no rock, no EDM, no fireball, no explosion, no heroic brass, no long ringing, no gacha reward tone.
```

### battleult_dedicated_v1_03 — 内力一吐

```text
One-shot martial arts internal-force release sound, 0.9 to 1.4 seconds. A quiet breath-like swell, guqin snap, and compact low impact of qi leaving the body. Serious wuxia tone, strong but not loud, leaves room for battle hit sounds. No melody, no musical jingle, no victory cue, no magical shimmer, no thunder, no boom, no vocals, no long tail.
```

## battleChargeStart（Boss 蓄力预警）

目标文件：

```text
assets/audio/sfx/battleChargeStart.mp3
```

听感目标：

- 0.5-1.2s，开蓄力瞬间预警。
- 明显区别失败 jingle：这是“危险正在聚集”，不是“已经输了”。
- 低弦绷紧、气息聚拢、短促压力；不要过长，不要吓人。
- 可在 Boss 战里反复出现，不刺耳、不疲劳。

### battlechargestart_dedicated_v1_01 — 弦音绷紧

```text
One-shot boss charge warning sound for a realistic Chinese wuxia game, 0.5 to 1.2 seconds. A low guqin string tightens and bends, with a restrained breath of internal energy gathering. Clear danger anticipation: the boss is charging a powerful move. Dry, focused, tense, not a defeat sound. No sad falling tone, no victory cue, no explosion, no horror sting, no jump scare, no melody, no long reverb.
```

### battlechargestart_dedicated_v1_02 — 气劲聚拢

```text
Short combat warning cue, under 1 second. Subtle low air pressure pulls inward, cloth and sleeve movement, a muted wooden knock, and a tense string scrape. Realistic wuxia boss begins charging. Distinct, readable, restrained. No music, no drums roll, no alarm siren, no defeat jingle, no scream, no thunder, no cinematic riser, no long tail.
```

### battlechargestart_dedicated_v1_03 — 石磬压低

```text
One-shot martial arts charge-up warning sound, 0.6 to 1.1 seconds. A small dark stone chime hit, immediately damped, layered with low string tension and a short inhale of qi. Signals danger before an interrupt window. Serious and minimal, not scary. No melody, no sad failure cue, no reward sound, no explosion, no magic sparkle, no long resonance.
```

## 筛选与入库标准

1. 候选先放在非正式目录，例如 `assets/audio/_suno_candidates/battleUlt/` 与 `assets/audio/_suno_candidates/battleChargeStart/`，不要直接覆盖正式文件。
2. 用 `ffprobe` 记录时长、体积、码率；目标：`battleUlt` 0.8-1.6s，`battleChargeStart` 0.5-1.2s。
3. 人工 AB：分别对比 `battleCrit.mp3`、`realmAdvance.mp3`、`defeat.mp3`，确认不混淆。
4. 通过后覆盖正式路径，并把 `lib/shared/audio/dedicated_audio_assets.dart` 中对应状态改为 `finalAsset`。
5. 跑 audio targeted tests 与 `flutter analyze`。
