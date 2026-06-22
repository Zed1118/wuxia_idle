# Suno 平A 兵刃打击音 Prompt：battleHit v3（+配套 battleCrit）

> 日期：2026-06-11
> 目标：重生成 `battleHit`（普通命中），用户反馈 v2 两候选（01 在用 / 02 备选）**不像兵刃**，偏闷响/拳风系。
> 方向：真实钢刃质感——挥砍破风 + 金属触击，短、干、利落。不要乐器、不要音乐性。
> 模式：Suno `Sounds` / `One-Shot`。目标时长 ≤1s（落位裁切到 0.12-0.30s，battleHit 每回合高频触发，宁短勿长）。
> 配套：battleCrit 2 条同批生成保质感一致（接不接后筛再定）。

## battleHit（平A 普通命中）

### battlehit_blade_v3_01 — 剑刃挥砍命中

```text
Create a very short sword strike sound effect for a martial arts game, under 1 second. One single hit: a steel sword blade slicing through air and landing with a crisp metallic edge contact. Real weapon foley, dry and clean, no ring tail. It plays on every normal attack, so it must be short, restrained, satisfying, never annoying. No music, no instruments, no melody, no explosion, no gore, no scream, no cartoon whoosh, no long reverb.
```

### battlehit_blade_v3_02 — 兵刃轻碰（金属对金属）

```text
Very short metal-on-metal weapon impact, under 1 second, one-shot. A light steel blade tap against another blade: sharp, thin, precise metallic click with a tiny scrape, like two swords briefly touching in a duel. Realistic Chinese wuxia weapon foley. Dry, clean, fast decay. No music, no bell, no chime melody, no anime exaggeration, no explosion, no long metallic ringing.
```

### battlehit_blade_v3_03 — 破风入肉感（衣袂+刃风+触击）

```text
One-shot sword attack hit for a wuxia game, under 1 second. Sequence in one sound: a fast blade swish cutting air, then a muted sharp impact as the strike lands on cloth and body. Mostly air-cut and edge contact, slightly metallic, not bloody, not wet. Short, dry, controlled. No music, no instruments, no gore squelch, no scream, no cinematic boom, no tail.
```

### battlehit_blade_v3_04 — 利落剑锋（偏脆单击）

```text
Ultra short game hit sound, 0.3 to 0.8 seconds, single strike only. A crisp steel sword edge impact: bright thin metallic snap with a hint of blade swish before it. Feels like a clean precise sword cut connecting. Real weapon recording style, restrained, immediate, dry. No melody, no chime, no bell, no whoosh-only, no fantasy magic shimmer, no reverb tail.
```

## battleCrit（暴击 · 配套候选，后筛再定接不接）

### battlecrit_blade_v3_01 — 重斩+短余响

```text
Short critical hit sword sound for a martial arts game, under 1.5 seconds, one-shot. A heavier steel blade strike: strong metallic clash with a brief sharp ring that decays fast. Clearly more powerful than a normal hit but same realistic weapon family, not magical. Dry, decisive, restrained. No music, no instruments, no explosion, no gacha sparkle, no long ringing tail, no slow motion drama.
```

### battlecrit_blade_v3_02 — 双段重击

```text
One-shot heavy sword critical strike, under 1.5 seconds. A fast blade swish into a hard metallic impact with a tiny secondary crunch, like a sword biting deep through a guard. Realistic wuxia weapon foley, powerful but controlled, quick decay. No music, no bell melody, no explosion, no gore, no scream, no cinematic riser, no long reverb.
```

## 回收与落位

1. 生成后下载到 `~/Desktop/挂机武侠_音乐音效素材_V2_20260610/` 同级新建 `V3_battleHit_20260611/`（或任意位置告诉我路径）。
2. 我做静音裁切体检（沿 v2 技术处理体例：响度/峰值/头尾静音）+ afplay AB 筛选。
3. 选定后替换 `assets/audio/sfx/battleHit.mp3`（文件名即接线，零 Dart 改动），重编 release 包真玩复验。
