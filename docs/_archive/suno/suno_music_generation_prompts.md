# Suno 音乐生成提示词清单

> 用途：在 Suno Pro / Premier 下生成本项目可商用的 BGM 与短音乐 jingle。
> 注意：本文件只覆盖适合 Suno 的“音乐类素材”。按钮、翻页、命中、破招、装备替换等短 SFX 不建议用 Suno 生成，应改用专门 SFX 工具或素材库。
> 当前工程直接接线的 BGM 文件：`assets/audio/bgm/mainMenu.mp3`、`assets/audio/bgm/battle.mp3`、`assets/audio/bgm/seclusion.mp3`。

## 通用设置

生成时优先使用：

- Mode：Custom 或支持填写详细 prompt 的模式。
- Vocals：Instrumental / no vocals。
- Lyrics：留空，或明确 `instrumental only, no lyrics`。
- Style / Prompt：使用下表 prompt。
- 每个素材建议先生成 2-4 个候选，再下载试听筛选。

通用负面约束可追加在每条 prompt 末尾：

```text
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

## Batch A：当前工程优先 BGM

### 1. mainMenu

目标文件：

```text
assets/audio/bgm/mainMenu.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping background track for a realistic Chinese wuxia idle game main menu. Mood: quiet mountain sect at dusk, ink-wash, restrained, lonely but not sad. Instruments: guqin as the lead, soft xiao flute, very subtle distant bell, faint mountain wind ambience. Slow tempo, sparse arrangement, lots of silence and breathing room. Mature martial arts atmosphere, calm and elegant, suitable for listening for a long time on a game menu.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

筛选标准：

- 第一印象像“山门 / 江湖入口”，不是悲情电视剧。
- 旋律存在但不抢注意力。
- 循环播放 5 分钟不疲劳。

### 2. battle

目标文件：

```text
assets/audio/bgm/battle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping combat background track for a realistic Chinese wuxia idle game. Mood: restrained martial tension, blades about to meet, focused and grounded. Instruments: pipa and ruan plucked rhythm, low muted drums, short xiao phrases, occasional guqin accents. Medium-slow tempo with steady pulse, tense but not explosive, no modern action trailer sound. Leave space for sword hit sound effects and UI feedback. Mature ink-wash wuxia battle atmosphere.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

筛选标准：

- 有战斗节奏，但不“热血番”。
- 鼓点低调，不压过战斗音效。
- 适合普通 3v3 自动战斗长期循环。

### 3. seclusion

目标文件：

```text
assets/audio/bgm/seclusion.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping meditation and cultivation background track for a realistic Chinese wuxia idle game. Mood: silent seclusion, inner cultivation, pine wind, distant waterfall, empty mountain temple. Instruments: very sparse xiao flute, guqin harmonics, soft distant bell, natural water drops and wind ambience. Very slow tempo, almost no melody, low dynamics, peaceful and focused. Designed for long idle gameplay and offline cultivation screens.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

筛选标准：

- 几乎不打扰玩家操作。
- 水声、风声不能太吵。
- 更像“闭关 / 入定”，不是 spa 音乐。

## Batch B：扩展 BGM

### 4. mainline

建议文件：

```text
assets/audio/bgm/mainline.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping story background track for a realistic Chinese wuxia idle game mainline journey. Mood: walking through rivers and mountains, inns, rain roads, first steps into the martial world. Instruments: guqin, dizi, soft xiao, light ruan plucks, subtle rain and wind ambience. Slow to medium-slow tempo, atmospheric, restrained, narrative but not melodramatic. Feels like a young martial artist leaving the mountain and entering jianghu.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 5. tower

建议文件：

```text
assets/audio/bgm/tower.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping challenge tower background track for a realistic Chinese wuxia idle game. Mood: climbing toward the top of jianghu, disciplined pressure, repeated trials, cold stone stairs. Instruments: low muted drums, pipa ostinato, guqin accents, distant bell, restrained xiao. Medium tempo, steady forward motion, tense but elegant, not epic trailer music. Suitable for a 30-floor martial challenge mode.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 6. boss

建议文件：

```text
assets/audio/bgm/boss.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping boss battle background track for a realistic Chinese wuxia idle game with manual interrupt mechanics. Mood: focused pressure, a dangerous master charging a decisive move, one correct decision can change the fight. Instruments: deep muted drum, tense pipa and ruan pulses, low guqin, short xiao phrases, sparse gong accents. Medium tempo, dark and controlled, leaves space for charge and interrupt sound effects. No bombastic orchestra, no rock, no electronic action music.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 7. innerDemon

建议文件：

```text
assets/audio/bgm/innerDemon.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping inner demon trial background track for a realistic Chinese wuxia idle game. Mood: facing one's own shadow, restrained psychological pressure, empty inner realm, cold breath, self-reflection. Instruments: low guqin, sparse xiao, distant bell, subtle reversed breath-like ambience, dark string texture. Slow tempo, tense and hollow, not horror, not supernatural cliché. Mature ink-wash martial arts atmosphere.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 8. lightFoot

建议文件：

```text
assets/audio/bgm/lightFoot.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping light-foot trial background track for a realistic Chinese wuxia idle game. Mood: agile movement over water, rooftops and bamboo forests, precise footwork, wind passing sleeves. Instruments: dizi, light pipa plucks, small hand drum, subtle guqin accents, wind ambience. Medium tempo, nimble and elegant, not cheerful, not cartoonish. Feels like martial artists testing movement and timing.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 9. massBattle

建议文件：

```text
assets/audio/bgm/massBattle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping defensive mass battle background track for a realistic Chinese wuxia idle game. Mood: holding a town gate with a small martial sect, disciplined formation, pressure from many enemies, restrained heroism. Instruments: low drums, pipa rhythm, ruan, distant war bell, very subtle horn-like texture without western brass dominance. Medium tempo, weighty but not cinematic trailer music, grounded and mature.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 10. lineage

建议文件：

```text
assets/audio/bgm/lineage.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping lineage and ascension background track for a realistic Chinese wuxia idle game. Mood: master and disciples, inheritance of a sect, old weapons passed down, quiet ceremony, farewell without melodrama. Instruments: solemn guqin, long xiao notes, soft bell and stone chime, very sparse low drum. Slow tempo, dignified, restrained, spiritual but grounded. Feels like martial lineage continuing across generations.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

### 11. baike

建议文件：

```text
assets/audio/bgm/baike.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A seamless looping background track for a martial encyclopedia and scripture hall screen in a realistic Chinese wuxia idle game. Mood: quiet reading room, old books, equipment lore, martial records, dust in afternoon light. Instruments: guqin harmonics, soft ruan, faint page-turn ambience, distant wood and bell. Very slow tempo, minimal melody, low presence, elegant and calm.
Avoid EDM, rock, metal, pop vocals, anime style, trailer orchestra, heroic brass, loud cymbal crashes, modern synth leads, casino reward sounds, cartoon sound effects.
```

## Batch C：短音乐 Jingle

### 12. victoryJingle

建议文件：

```text
assets/audio/sfx/victoryJingle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A very short victory jingle for a realistic Chinese wuxia idle game. Duration around 2 seconds. Mood: calm martial victory, earned but restrained. Instruments: guqin upward phrase, small bell, soft final resonance. No fanfare, no casino reward, no cartoon sound. Elegant ink-wash wuxia tone.
```

### 13. defeatJingle

建议文件：

```text
assets/audio/sfx/defeatJingle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A very short defeat jingle for a realistic Chinese wuxia idle game. Duration around 2 seconds. Mood: quiet setback, reflect and adjust, not tragic. Instruments: low guqin descending note, distant muted drum, short fading bell. Restrained, mature, no horror, no melodrama.
```

### 14. bossBreakJingle

建议文件：

```text
assets/audio/sfx/bossBreakJingle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A short musical sting for successfully interrupting a boss's charged move in a realistic Chinese wuxia idle game. Duration around 1 second. Mood: decisive martial timing, the enemy's momentum breaks. Instruments: sharp guqin sweep, small gong or stone chime, quick breath of impact. Restrained but satisfying, no explosion, no cartoon.
```

### 15. rareDropJingle

建议文件：

```text
assets/audio/sfx/rareDropJingle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A short rare drop jingle for a realistic Chinese wuxia idle game, used for martial manuals, relic weapons, and precious discoveries. Duration around 2 seconds. Mood: quiet wonder, precious but not flashy. Instruments: jade-like bell, guqin harmonics, soft airy tail. No slot machine, no gacha, no casino reward sound.
```

### 16. realmAdvanceJingle

建议文件：

```text
assets/audio/sfx/realmAdvanceJingle.mp3
```

Suno prompt：

```text
Instrumental only, no vocals. A short realm advancement jingle for a realistic Chinese wuxia idle game. Duration around 3 seconds. Mood: inner force breakthrough, breath settles, martial realm rises. Instruments: deep bell, guqin harmonic swell, long xiao breath, subtle low resonance. Spiritual but grounded, no fireworks, no epic trailer, no choir.
```

## 下载与筛选记录模板

生成后建议先下载到：

```text
assets/audio/_suno_candidates/<slot>/
```

每个候选用：

```text
<slot>_candidate_01.mp3
<slot>_candidate_02.mp3
```

筛选记录：

```text
slot:
chosen_file:
suno_generation_date:
prompt_version:
why_chosen:
reject_notes:
```

