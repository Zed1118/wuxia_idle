# 挂机武侠音乐与音效素材生成指南

> 用途：指导音乐 / 音效生成、外采、后期整理与入库。
> 依据：`GDD.md`、`docs/spec/m15_e_audio_spec_2026-05-29.md`、`docs/superpowers/specs/2026-06-09-audio-system-design.md`、`docs/handoff/audio_slot_manifest.md`、`docs/spec/playability_upgrade_master_spec_2026-06-09.md`。
> 当前工程状态：音频引擎已按 `BgmTrack` / `SfxId` 槽位接线，现阶段文件格式和命名以 `lib/shared/audio/audio_assets.dart` 为准。
>
> **2026-06-09 Claude 校订(据工程现状）**：
> - **已接线、丢 mp3 即响**：Batch A 11 槽位（BGM `mainMenu`/`battle`/`seclusion` + SFX `uiTap`/`uiTabSwitch`/`uiPaperOpen`/`battleHit`/`battleCrit`/`battleUlt`/`battleDeath`/`reward`）+ **破招 3 SFX `battleChargeStart`/`battleInterrupt`/`battleStagger`**（已接线,表现层状态边沿 `chargeTransitionSfx`）。
> - **需先写代码(加 enum + hook)才播**：§4 其余全部扩展槽位（mainline/tower/boss/各 jingle/系统/氛围/流派/养成/环境 SFX）。生成后先存档,接线后入库,否则是死素材。
> - `battleDeath`/`reward` enum 在但暂未触发(留位),`battleChargeRelease` 由 Boss 招牌技命中走 `battleHit/Crit` 覆盖,无需单独槽。
> - 旧 `docs/spec/m15_e_audio_spec_2026-05-29.md` 已被本指南取代(superseded)。

## 1. 总体声音方向

本游戏是写实武侠挂机游戏，声音必须服务于“水墨、宣纸、竹影、雨夜、青衫、断剑、孤灯”的气质。音乐和音效都应克制、留白、低侵扰，适合玩家长时间挂机时循环播放。

### 1.1 必须遵守

- 风格：写实武侠、沉郁、克制、东方器乐、低密度编曲。
- 核心乐器：古琴、箫、笛、琵琶、阮、低鼓、钟磬、木鱼、竹板、风声、雨声、水声、纸张声。
- 音量体感：BGM 不抢 UI 和战斗反馈；SFX 短促、轻、不刺耳。
- 循环：BGM 必须可无缝循环，结尾不能有明显断点。
- 情绪：主菜单清寂，战斗紧而不炸，闭关安静，Boss 压迫但不摇滚化。
- 版权：每个素材必须记录来源、授权类型、生成工具或外采站点。

### 1.2 禁止方向

- 不要 J-pop、摇滚、金属、EDM、赛博、二次元热血、手游抽卡音效。
- 不要过度电影预告片式大鼓、铜管、合唱、爆炸低频。
- 不要卡通 UI 音效、金币雨、老虎机、抽奖提示、登录奖励类“叮叮叮”。
- 不要恐怖尖叫、血腥惨叫、夸张砍杀声。

## 2. 文件格式与入库规则

### 2.1 当前工程已接线格式

当前代码按 `.mp3` 查找素材：

```text
assets/audio/bgm/<BgmTrack>.mp3
assets/audio/sfx/<SfxId>.mp3
```

因此本轮素材请优先导出为 `.mp3`，文件名大小写必须严格一致。旧规划曾建议 `.ogg`，但工程当前槽位是 `.mp3`；如未来改为 `.ogg`，需同步修改 `audio_assets.dart` 和测试。

### 2.2 建议导出参数

| 类型 | 格式 | 采样率 | 码率 | 声道 | 响度建议 |
|---|---|---:|---:|---|---|
| BGM | mp3 | 44.1 kHz | 192-256 kbps | Stereo | 约 -18 LUFS |
| Jingle | mp3 | 44.1 kHz | 192 kbps | Stereo | 约 -16 LUFS |
| SFX | mp3 | 44.1 kHz | 128-192 kbps | Mono 或 Stereo | 峰值不超过 -3 dB |

### 2.3 命名规则

- 已接线素材：必须使用当前 enum 名称，例如 `mainMenu.mp3`、`battleHit.mp3`。
- 规划素材：使用 lowerCamelCase，等接线时再加入 enum。
- 不要在文件名里写中文、空格、版本号或情绪词。

## 3. 当前必须生成的素材

以下 11 个素材是当前工程可直接识别的槽位。放入对应路径后即可触发播放。

### 3.1 BGM

| 优先级 | 槽位 | 文件路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---|---:|---|
| P0 | `mainMenu` | `assets/audio/bgm/mainMenu.mp3` | 主菜单 / 山门入口 | 90-150s | 悠远古琴主导，少量箫，远山风声，慢速，无鼓或极轻低鼓，清寂、有留白，适合长时间循环 |
| P0 | `battle` | `assets/audio/bgm/battle.mp3` | 普通战斗 / 当前战斗统一曲 | 90-150s | 克制武侠战斗，琵琶拨弦 + 低鼓 + 短箫句，节奏紧但不炸，不能像动作片预告，不能电音 |
| P0 | `seclusion` | `assets/audio/bgm/seclusion.mp3` | 闭关修炼 / 离线挂机 | 120-180s | 极简箫声、古琴泛音、松风、水滴、远处钟磬，几乎无旋律，冥想感，低动态，适合挂机循环 |

#### BGM 通用负面提示

```text
no EDM, no rock, no metal, no pop vocal, no anime style, no orchestral trailer, no heroic brass, no loud cymbal crash, no modern synth lead, no casino reward sound, no cartoon mood
```

### 3.2 SFX

| 优先级 | 槽位 | 文件路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---|---:|---|
| P0 | `uiTap` | `assets/audio/sfx/uiTap.mp3` | 通用按钮点击 | 0.08-0.18s | 轻木鱼或竹板“嗒”一声，干净短促，低音量，不要电子 click |
| P0 | `uiTabSwitch` | `assets/audio/sfx/uiTabSwitch.mp3` | 标签页切换 | 0.15-0.35s | 竹简或薄纸轻翻，柔和，尾音短，比 uiTap 更轻 |
| P0 | `uiPaperOpen` | `assets/audio/sfx/uiPaperOpen.mp3` | 弹窗 / 面板展开 | 0.25-0.55s | 宣纸展开、卷轴轻开，带一点空气感，不要夸张 whoosh |
| P0 | `battleHit` | `assets/audio/sfx/battleHit.mp3` | 普通命中 | 0.12-0.30s | 兵刃轻击或拳风闷响，克制、清楚，不血腥 |
| P0 | `battleCrit` | `assets/audio/sfx/battleCrit.mp3` | 暴击命中 | 0.20-0.45s | 更清脆的金属碰撞 + 轻微回响，可带短促金光感，但不能像抽卡 |
| P0 | `battleUlt` | `assets/audio/sfx/battleUlt.mp3` | 大招 / 绝技释放 | 0.8-1.8s | 古琴扫弦、沉厚钟磬、短促气劲，仪式感强，不能爆炸化 |
| P1 留位 | `battleDeath` | `assets/audio/sfx/battleDeath.mp3` | 单位倒地，当前暂未接线 | 0.25-0.60s | 闷响 + 短气息收尾，不惨叫、不血腥 |
| P1 留位 | `reward` | `assets/audio/sfx/reward.mp3` | 获得奖励，当前暂未接线 | 0.35-0.80s | 清越小铃或玉石轻碰，稀有但克制，不要手游领奖音 |

## 4. Demo 建议补齐素材

以下素材来自旧音频规划和当前可玩性加强方案。它们不一定已经接线，但建议作为 Demo 完整体验的生成目标。生成后可先存档，待代码增加 enum / hook 后入库。

### 4.1 BGM 扩展

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `mainline` | `assets/audio/bgm/mainline.mp3` | 主线剧情 / 江湖路 | 90-150s | 古琴 + 笛，带行路感，轻剧情，少鼓，像山路、客栈、雨后江湖 |
| `tower` | `assets/audio/bgm/tower.mp3` | 问鼎九霄 / 爬塔 | 90-150s | 比普通战斗更紧，低鼓稳定推进，琵琶短句，层层上行的压迫感 |
| `boss` | `assets/audio/bgm/boss.mp3` | Boss / 手动破招战 | 90-150s | 低鼓、弦拨、短促箫句，留出蓄力与破招音效空间，压迫但不炸 |
| `innerDemon` | `assets/audio/bgm/innerDemon.mp3` | 心魔境 | 90-150s | 古琴低音、反向气息、远钟、暗色氛围，心理压力，不恐怖化 |
| `lightFoot` | `assets/audio/bgm/lightFoot.mp3` | 轻功试炼 | 90-150s | 轻鼓点、笛、风声，速度感和腾挪感，不能欢快卡通 |
| `massBattle` | `assets/audio/bgm/massBattle.mp3` | 守城 / 群战 | 90-150s | 低鼓更厚，号角可极轻，队伍推进感，避免史诗大片化 |
| `lineage` | `assets/audio/bgm/lineage.mp3` | 师徒传承 / 飞升仪式 | 90-150s | 古琴、钟磬、长箫，庄重、淡，不要悲情过满 |
| `baike` | `assets/audio/bgm/baike.mp3` | 江湖见闻录 / 藏经阁类界面 | 120-180s | 书卷、古琴泛音、室内安静感，低存在感 |

### 4.2 Jingle 扩展

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `victoryJingle` | `assets/audio/sfx/victoryJingle.mp3` | 战斗胜利 | 1.2-2.5s | 古琴上行 + 小钟，沉稳胜利，不要庆典感 |
| `defeatJingle` | `assets/audio/sfx/defeatJingle.mp3` | 战斗失败 | 1.2-2.5s | 古琴低落 + 远鼓，失败复盘感，不要恐怖 |
| `bossBreakJingle` | `assets/audio/sfx/bossBreakJingle.mp3` | 破招成功 | 0.8-1.4s | 兵刃断势 + 短钟 + 气劲散开，强调“破!” |
| `rareDropJingle` | `assets/audio/sfx/rareDropJingle.mp3` | 珍稀掉落 / 真解 / 神物 | 1.0-2.0s | 玉石轻响 + 古琴泛音，珍贵但不抽卡化 |
| `realmAdvanceJingle` | `assets/audio/sfx/realmAdvanceJingle.mp3` | 境界突破 | 1.5-3.0s | 深呼吸感、钟磬、古琴长音，修行突破，不要烟花 |

### 4.3 UI / 系统 SFX 扩展

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `uiError` | `assets/audio/sfx/uiError.mp3` | 不可操作 / 条件不足 | 0.15-0.35s | 低木声或短促沉闷音，提示但不烦 |
| `uiConfirm` | `assets/audio/sfx/uiConfirm.mp3` | 确认 / 保存设置 | 0.15-0.35s | 轻玉声或木声，比 reward 更朴素 |
| `pageTurn` | `assets/audio/sfx/pageTurn.mp3` | 剧情翻页 / 百科翻页 | 0.20-0.45s | 宣纸轻翻，细腻，不要硬纸板 |
| `equipSwap` | `assets/audio/sfx/equipSwap.mp3` | 装备穿戴 / 替换 | 0.25-0.55s | 皮革、布料、轻金属组合，真实克制 |
| `techniqueLearn` | `assets/audio/sfx/techniqueLearn.mp3` | 学习心法 / 领悟招式 | 0.8-1.6s | 古琴泛音 + 轻风，像灵光一现，不要魔法音 |
| `shopBuy` | `assets/audio/sfx/shopBuy.mp3` | 江湖商店购买 | 0.20-0.45s | 铜钱极轻碰撞，不能像金币奖励 |
| `levelUp` | `assets/audio/sfx/levelUp.mp3` | 小阶段提升 / 熟练度提升 | 0.5-1.0s | 短钟 + 琴泛音，低调成长反馈 |
| `lockDisabled` | `assets/audio/sfx/lockDisabled.mp3` | 未解锁按钮 | 0.15-0.35s | 轻闷木声，克制 |

### 4.4 战斗 SFX 扩展

> ✅ `battleChargeStart` / `battleInterrupt` / `battleStagger` **已于 2026-06-09 接线**(drop-in,丢 mp3 即响);本节其余槽位仍需代码 hook。

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `battleAttack` | `assets/audio/sfx/battleAttack.mp3` | 出招 / 挥击 | 0.10-0.25s | 短促衣袂与气劲，不能盖过命中声 |
| `battleDodge` | `assets/audio/sfx/battleDodge.mp3` | 闪避 | 0.15-0.35s | 轻风掠过、脚步一滑，灵巧但不卡通 |
| `battleGuard` | `assets/audio/sfx/battleGuard.mp3` | 格挡 / 护盾 | 0.18-0.40s | 兵刃被挡的钝响，短 |
| `battleInterrupt` | `assets/audio/sfx/battleInterrupt.mp3` | 破招命中 | 0.35-0.80s | 金属断势 + 气劲散开，比 crit 更有结构感 |
| `battleStagger` | `assets/audio/sfx/battleStagger.mp3` | Boss 踉跄 / 破绽 | 0.25-0.60s | 脚步失衡、衣袂乱、短闷响 |
| `battleChargeStart` | `assets/audio/sfx/battleChargeStart.mp3` | Boss 开始蓄力 | 0.50-1.20s | 低频气息聚集、弦音绷紧，给玩家预警 |
| `battleChargeRelease` | `assets/audio/sfx/battleChargeRelease.mp3` | Boss 蓄力释放 | 0.8-1.6s | 压迫性气劲释放，重但不爆炸 |
| `battleHeal` | `assets/audio/sfx/battleHeal.mp3` | 回复 | 0.5-1.0s | 箫声上行 + 轻风，非魔幻治疗音 |
| `battleShield` | `assets/audio/sfx/battleShield.mp3` | 护盾 | 0.4-0.9s | 低钟 + 气息围合 |
| `internalWound` | `assets/audio/sfx/internalWound.mp3` | 内伤 debuff | 0.3-0.8s | 暗色气息、低弦颤动，阴柔但不恐怖 |

### 4.5 三流派差异 SFX

这些素材用于强化 GDD §4.4 的三流派克制辨识度，可作为 battle SFX 的分层或替换版本。

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `styleRigidHit` | `assets/audio/sfx/styleRigidHit.mp3` | 刚猛命中 / 震伤 | 0.18-0.45s | 低沉钝击 + 短震波，力量感，不要爆炸 |
| `styleAgileCrit` | `assets/audio/sfx/styleAgileCrit.mp3` | 灵巧暴击 / 残影 | 0.18-0.45s | 清脆刃响 + 轻风掠过，快而亮 |
| `styleSinisterWound` | `assets/audio/sfx/styleSinisterWound.mp3` | 阴柔内伤 | 0.25-0.70s | 低弦、气息缠绕、微弱回响，不要鬼怪感 |

### 4.6 装备 / 心法 / 养成 SFX

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `equipmentStrengthen` | `assets/audio/sfx/equipmentStrengthen.mp3` | 强化成功 | 0.6-1.2s | 铁器淬炼 + 小钟，工艺感，不要领奖感 |
| `equipmentStrengthenFail` | `assets/audio/sfx/equipmentStrengthenFail.mp3` | 强化失败但不降级 | 0.4-0.9s | 炉火低落、钝响，轻挫败但不刺耳 |
| `resonanceUp` | `assets/audio/sfx/resonanceUp.mp3` | 装备共鸣阶段提升 | 1.0-2.0s | 剑鸣、古琴泛音、长尾，表现“人剑合一” |
| `weaponOpenEdge` | `assets/audio/sfx/weaponOpenEdge.mp3` | 开锋槽解锁 | 0.8-1.5s | 磨刃、清脆剑鸣、短停顿 |
| `cultivationProgress` | `assets/audio/sfx/cultivationProgress.mp3` | 心法修炼度阶段提升 | 0.8-1.6s | 气息流转、琴泛音，安静成长 |
| `dispelCultivation` | `assets/audio/sfx/dispelCultivation.mp3` | 散功 / 换主修 | 1.0-2.0s | 低弦下行、气息散开，重大决策感 |
| `insightTrigger` | `assets/audio/sfx/insightTrigger.mp3` | 武学领悟事件触发 | 1.0-2.0s | 雨声或风声中一记清亮泛音，“灵光一现” |

### 4.7 闭关 / 环境 SFX

| 建议槽位 | 建议路径 | 用途 | 时长 | 生成提示 |
|---|---|---|---:|---|
| `ambientForest` | `assets/audio/sfx/ambientForest.mp3` | 山林闭关底噪 | 30-60s | 松风、虫鸣极少、远鸟，低存在感 |
| `ambientSwordTomb` | `assets/audio/sfx/ambientSwordTomb.mp3` | 古剑冢 | 30-60s | 风过残剑、远处金属轻颤，冷清 |
| `ambientScriptureHall` | `assets/audio/sfx/ambientScriptureHall.mp3` | 藏经阁 | 30-60s | 室内风、纸页、木梁，安静 |
| `ambientWaterfall` | `assets/audio/sfx/ambientWaterfall.mp3` | 悬崖瀑布 | 30-60s | 远瀑布，不要白噪过大 |
| `ambientCliff` | `assets/audio/sfx/ambientCliff.mp3` | 断崖绝壁 | 30-60s | 高处风声、空旷感、远钟极轻 |

## 5. 一次性生成批次建议

为了降低返工，建议按以下批次生成。

### Batch A：当前工程可接入

目标：生成并放入当前已接线的 11 个文件。

```text
assets/audio/bgm/mainMenu.mp3
assets/audio/bgm/battle.mp3
assets/audio/bgm/seclusion.mp3
assets/audio/sfx/uiTap.mp3
assets/audio/sfx/uiTabSwitch.mp3
assets/audio/sfx/uiPaperOpen.mp3
assets/audio/sfx/battleHit.mp3
assets/audio/sfx/battleCrit.mp3
assets/audio/sfx/battleUlt.mp3
assets/audio/sfx/battleDeath.mp3
assets/audio/sfx/reward.mp3
```

### Batch B：战斗参与感

目标：服务 Boss 蓄力、破招、胜负反馈。

```text
battleChargeStart
battleChargeRelease
battleInterrupt
battleStagger
bossBreakJingle
victoryJingle
defeatJingle
rareDropJingle
```

### Batch C：系统操作

目标：补齐装备、心法、商店、错误反馈。

```text
uiError
uiConfirm
pageTurn
equipSwap
techniqueLearn
shopBuy
levelUp
equipmentStrengthen
equipmentStrengthenFail
```

### Batch D：长期氛围

目标：补齐主线、爬塔、Boss、心魔、轻功、守城和界面氛围。

```text
mainline
tower
boss
innerDemon
lightFoot
massBattle
lineage
baike
ambientForest
ambientSwordTomb
ambientScriptureHall
ambientWaterfall
ambientCliff
```

## 6. 音乐生成 Prompt 模板

### 6.1 BGM 模板

```text
Create a seamless looping instrumental background music track for a realistic Chinese wuxia idle game.
Mood: <清寂 / 紧张 / 静谧 / 压迫 / 庄重>.
Instrumentation: guqin, xiao flute, dizi, pipa, ruan, subtle low drum, distant bell, natural ambience.
Style: restrained ink-wash wuxia, mature, minimal, atmospheric, no vocals.
Tempo: <slow / medium-slow / steady>.
Duration: <90-180 seconds>.
Mix: soft dynamics, low fatigue for long listening, leave space for UI and combat sound effects.
Must loop seamlessly.
Avoid: EDM, rock, metal, pop, anime, trailer orchestra, loud cymbals, heroic brass, modern synth, casino reward sounds.
```

### 6.2 SFX 模板

```text
Create a short sound effect for a realistic Chinese wuxia idle game.
Event: <事件名>.
Sound source: <竹板 / 宣纸 / 兵刃 / 古琴扫弦 / 钟磬 / 风声 / 气劲>.
Mood: restrained, tactile, elegant, not cartoonish.
Duration: <0.1-2.0 seconds>.
Mix: clean transient, not harsh, peak below -3 dB, suitable for repeated playback.
Avoid: electronic UI beeps, casino sounds, gore, screams, explosions, exaggerated magic sounds.
```

## 7. 验收清单

每个素材入库前检查：

- [ ] 文件名与槽位完全一致。
- [ ] 当前已接线素材使用 `.mp3`。
- [ ] BGM 可无缝循环，没有明显断尾。
- [ ] BGM 听 5 分钟不疲劳。
- [ ] SFX 连续触发 20 次不刺耳。
- [ ] 战斗 SFX 不遮盖 UI 操作声。
- [ ] 素材没有现代电子、抽卡、摇滚、二次元热血感。
- [ ] 已记录来源、授权、生成工具、生成日期。
- [ ] 总体积控制：Demo 音频目标小于 50MB。

## 8. 授权记录模板

素材归位时，同步维护授权记录。可用独立 `LICENSE_AUDIO.md`，每条按以下格式：

```text
id: mainMenu
file: assets/audio/bgm/mainMenu.mp3
type: bgm
source: <生成工具 / 外采网站 / 作者>
license: <商业授权 / CC0 / 自有生成>
created_or_downloaded_at: YYYY-MM-DD
prompt_or_search_terms: <简述>
notes: <是否后期剪辑、混音、降噪、循环处理>
```

