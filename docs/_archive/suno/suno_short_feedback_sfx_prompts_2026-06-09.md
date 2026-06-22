# Suno 短反馈音效 Prompt：胜利 / 失败

> 日期：2026-06-09
> 目标：重新生成“短暂、有力、有明确信号”的胜利 / 失败音效。
> 原因：上一批 jingle 更像短音乐片段，时长和信号密度不合格。

## 生成策略

优先使用 Suno 的 `Sounds` 模式。如果只能用音乐生成模式，则仍使用以下 prompt，但必须明确：

- very short
- under 2 seconds
- one-shot game UI feedback
- no melody development
- no background music
- no long intro
- no long tail

## Victory SFX

### victory_sfx_sharp_01

```text
Create a very short game victory sound effect, under 2 seconds. It must be a one-shot success signal, not a music track. Style: restrained realistic Chinese wuxia. Sound: clear guqin upward pluck, small bronze bell hit, quick confident impact. Short, bright, decisive, satisfying. No melody development, no vocals, no drums loop, no long tail, no background music, no casino or gacha sound, no cartoon sound.
```

### victory_sfx_sharp_02

```text
Create a short and powerful victory confirmation sound for a martial arts game, under 2 seconds. One clear signal only. Use a crisp guqin sweep, a light sword chime, and a small bell resonance. It should feel like winning a fight cleanly: firm, elegant, restrained, unmistakable. No song, no rhythm loop, no long ambience, no cinematic fanfare, no vocals, no casino reward sound.
```

### victory_sfx_sharp_03

```text
Very short wuxia victory UI stinger, 1 to 1.5 seconds. A decisive upward musical hit: guqin pluck plus clean metal chime, fast fade. Clear positive feedback for battle victory. Minimal, strong, elegant. No background music, no melody, no long reverb, no orchestral fanfare, no pop, no vocals, no cartoon sparkle.
```

## Defeat SFX

### defeat_sfx_sharp_01

```text
Create a very short game defeat sound effect, under 2 seconds. It must be a one-shot failure signal, not a music track. Style: restrained realistic Chinese wuxia. Sound: low guqin pluck, muted woodblock hit, small dark bell falling quickly. Short, clear, firm, not scary, not sad music. No melody development, no vocals, no long tail, no background music, no horror, no cinematic drama.
```

### defeat_sfx_sharp_02

```text
Create a short and powerful defeat confirmation sound for a martial arts game, under 2 seconds. One clear negative signal only. Use a low plucked guqin note, a soft dull drum hit, and a quick fading bell. It should say: failed, stop, adjust. Restrained and serious. No song, no rhythm loop, no long ambience, no horror sound, no vocals, no melodrama.
```

### defeat_sfx_sharp_03

```text
Very short wuxia defeat UI stinger, 1 to 1.5 seconds. A decisive downward musical hit: low guqin note plus muted wooden impact, fast fade. Clear negative feedback for battle defeat. Minimal, strong, sober. No background music, no melody, no long reverb, no orchestral drama, no vocals, no cartoon failure sound.
```

