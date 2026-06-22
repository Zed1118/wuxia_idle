# Suno V2 音乐音效生成方案

> 日期：2026-06-10
> 目标：第二版素材要区别于 V1 的常规古琴 / 箫 / 琵琶古风路线，更特别、更有识别度，但仍契合写实武侠、水墨克制、挂机长听。

## V2 总方向

关键词：

- cold ink-wash wuxia
- broken string texture
- stone chime
- bowed metal
- paper friction
- distant temple woodblock
- dry low drum
- sword resonance
- mountain wind
- breath-like silence
- minimal rhythm

避免：

- 传统古风模板化旋律
- 仙侠大气合唱
- 热血二次元战斗曲
- EDM / rock / trailer orchestra
- 过甜的中国风 pop
- casino / gacha / reward sparkle

## V2 BGM Prompt

### mainMenu_v2

```text
Instrumental only, no vocals. A distinctive cold ink-wash wuxia main menu loop for a realistic idle martial arts game. Not a typical pretty ancient Chinese melody. Use sparse guqin harmonics, broken-string textures, distant stone chimes, dry mountain wind, and a very low pulse that appears only occasionally. Mood: an old sect gate after rain, paper lanterns almost out, quiet ambition. Minimal, elegant, lonely, mature. Seamless loop, long-listening, no pop, no cinematic trailer, no heroic fanfare.
```

### battle_v2

```text
Instrumental only, no vocals. A distinctive restrained wuxia combat loop, not heroic, not anime, not orchestral. Use dry low frame drum, muted pipa taps, bowed metal, short sword-resonance hits, and tense pauses. Mood: two martial artists measuring distance before a decisive exchange. Minimal rhythm, sharp negative space, controlled pressure. Leave room for hit and UI sound effects. Seamless loop. No EDM, no rock, no trailer drums, no big melody.
```

### seclusion_v2

```text
Instrumental only, no vocals. A minimal cultivation and seclusion loop for a realistic wuxia idle game. Avoid spa music and normal meditation clichés. Use breath-like silence, distant water in a cave, soft stone chimes, guqin harmonics, paper talisman rustle, and very faint mountain wind. Mood: sitting alone behind a closed stone door, internal force slowly settling. Almost no melody, low fatigue, seamless loop.
```

### mainline_v2

```text
Instrumental only, no vocals. A cold road-through-jianghu story loop for a realistic wuxia idle game. Avoid sentimental TV-drama melody. Use guqin fragments, dry ruan plucks, distant rain on paper umbrellas, low wooden percussion, and empty-space pauses. Mood: a young sect founder walking into a morally grey martial world. Restrained, weathered, narrative, not sad, not heroic. Seamless loop.
```

### tower_v2

```text
Instrumental only, no vocals. A distinctive challenge-tower loop for a realistic wuxia idle game. Use repeated stone-chime patterns, low dry drums, muted strings, and blade-like high accents. Mood: climbing cold stone floors one by one, pressure rising without becoming epic. Minimal, ritualistic, tense, disciplined. Seamless loop. No orchestral trailer, no rock, no anime battle music.
```

### boss_v2

```text
Instrumental only, no vocals. A boss battle loop for a realistic wuxia game with manual interrupt timing. Not bombastic. Use low bowed metal, dry war drum, sparse guqin strikes, breath-like silence before impacts, and short sword resonance. Mood: a dangerous master gathers force; the player waits for the break point. Dark, focused, controlled, high tension with lots of space. Seamless loop.
```

### innerDemon_v2

```text
Instrumental only, no vocals. A psychological inner-demon trial loop for a realistic wuxia idle game. Not horror, not supernatural cliché. Use detuned guqin harmonics, reversed breath textures, hollow wooden knocks, distant dark bell, and slow cold wind. Mood: facing your own martial shadow in an empty ink-black mind realm. Minimal, tense, introspective, sober. Seamless loop.
```

## V2 Sounds / One-Shot Prompt

### victory_sfx_v2

```text
One-shot game victory sound effect, 1 to 2 seconds. Distinctive restrained wuxia. A quick upward sword chime, guqin snap, and small stone bell hit. Short, strong, clear success signal. No melody, no song, no long tail, no sparkle, no casino sound.
```

### defeat_sfx_v2

```text
One-shot game defeat sound effect, 1 to 2 seconds. Distinctive restrained wuxia. A low snapped guqin string, muted wooden impact, and short falling stone bell. Clear negative signal: failed, stop, adjust. No sad music, no horror, no long tail, no melody.
```

### ui_tap_sfx_v2

```text
One-shot UI click sound effect, under 1 second. Restrained wuxia interface. Dry bamboo tap mixed with very soft paper contact. Clean, short, tactile, not electronic, not cartoon.
```

### ui_paper_open_sfx_v2

```text
One-shot UI panel open sound effect, under 1 second. Restrained wuxia interface. Rice paper unfolds with a tiny wooden frame creak and soft air movement. Clear but gentle. No magic whoosh, no cartoon.
```

### battle_hit_sfx_v2

```text
One-shot combat hit sound effect, under 1 second. Realistic wuxia. Short cloth impact plus dull weapon contact and a tiny breath of force. Clear hit confirmation, not bloody, not cinematic explosion.
```

### battle_crit_sfx_v2

```text
One-shot combat critical hit sound effect, under 1 second. Realistic wuxia. Sharp sword resonance, quick metal chime, and tight low impact. Stronger than normal hit, clear and decisive, no long tail, no arcade sparkle.
```

### battle_interrupt_sfx_v2

```text
One-shot boss interrupt sound effect, 1 to 2 seconds. Realistic wuxia. Momentum breaks: snapped string, blocked blade ring, short stone bell, and sudden silence. Powerful and clear, not explosive, no music phrase.
```

### rare_drop_sfx_v2

```text
One-shot rare drop sound effect, 1 to 2 seconds. Restrained wuxia. Jade token touch, soft guqin harmonic, tiny stone chime. Precious but quiet. No gacha, no casino, no sparkle rain.
```

### realm_advance_sfx_v2

```text
One-shot realm advancement sound effect, 2 to 3 seconds. Restrained wuxia cultivation. Deep breath, low bell, guqin harmonic bloom, short internal-force swell. Clear breakthrough signal, not epic, no choir, no fireworks.
```

