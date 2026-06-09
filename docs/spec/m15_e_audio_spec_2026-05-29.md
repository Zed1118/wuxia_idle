> **⚠️ SUPERSEDED(2026-06-09)**：本 spec 已被 `docs/audio_asset_generation_guide.md` 取代。音频系统已实装(`lib/shared/audio/`),素材生成/入库以该指南为准。

# M15-16 E 段:音频 spec

> 起草:2026-05-29 · 目标 M15-16 · 对应 RELEASE_CHECKLIST §E · ROADMAP P5.3
> 关联 Q1-Q5 拍板:**Q2 购买授权站 + 关键剧情 CC0 mix** / **Q3 关键 ~10 段配音**

## 1. 目标

CHECKLIST E 4 子项 0/4 → 4/4。BGM 主线/战斗/闭关 3 套 + SFX 战斗(7 阶递进)+ SFX UI + 关键剧情配音 ~10 段。基调:水墨克制,丝竹箫笛优先,克制电子合成器。

## 2. 拆 Batch(Claude 推占比 + 用户决策点)

| Batch | 内容 | Claude 推 | 用户办 | 估时 |
|---|---|---|---|---|
| **E1 SoundManager 架构** | `lib/core/audio/sound_manager.dart` + `audioplayers` 接入 + volume control(BGM/SFX/Master)+ Riverpod provider + 静音状态持久化 | 100% | — | ~2h |
| **E2 BGM cue point 接入** | 主菜单 / 主线战斗 / 闭关 3 cue point + 章节切歌 hook + 战斗胜利 / 失败 jingle + crossfade | 100% | — | ~2h |
| **E3 SFX 7 阶战斗** | 攻击 / 命中 / 暴击 / 死亡 各 7 阶递进 = 28 SFX + 招式特效音(普攻 / 大招 / 共鸣 / 飞升)| 100% | — | ~3h |
| **E4 SFX UI** | 按钮 click / 翻页 turn / 装备 swap / 心法学习 / 商店购买 / 升级 ding / 错误 buzz = 8 SFX | 100% | — | ~1h |
| **E5 BGM 素材外采** | 购买授权站(Audiojungle / Pond5 / Epidemic Sound)选 3 套 + 水墨基调 + 试听挑选 + 授权下载 + 文件归位 `assets/audio/bgm/` | 30% | **用户操作:挑+买+下** | ~4h(挑选) |
| **E6 SFX 素材** | CC0 站(freesound / opengameart)挑 36 SFX + 鉴权 / 改名 / 归位 `assets/audio/sfx/`| 70% | 用户最终挑(Claude 提候选)| ~3h |
| **E7 关键剧情配音** | 师父三句遗言 + Ch4-6 主敌登场 ~10 段 + 找配音员(Fiverr / 自荐)+ 录制 / 后期 / 接入 | 40% | **用户操作:找人+录** | ~5h(等录)|

**总 Claude 推:~10-12h · 用户操作:BGM 挑选+采买 ~4h / SFX 终挑 ~1h / 配音员找+录 ~5h**

## 3. 决策点(Phase 0 拍)

| # | 问题 | 推荐默认 | 影响 |
|---|------|---------|------|
| E-Q1 | 授权站选哪家:Audiojungle / Pond5 / Epidemic Sound? | **Epidemic Sound 月订($15/月)** | 预算 + 授权范围 |
| E-Q2 | BGM 战斗用 1 套还是按章节切歌 3 套? | **1 套战斗 BGM 全场景**(Demo 简化 · 1.x 扩 3 套) | E5 采购量 |
| E-Q3 | SFX 7 阶递进真做 28 SFX 还是 1 套通用? | **1 套通用 4 SFX(攻击 / 命中 / 暴击 / 死亡)+ 7 阶 pitch shift 程序化** | E3 工作量 ÷ 7 |
| E-Q4 | 配音语言:中文普通话 only / 中文 + 英文? | **中文普通话 only**(Q1 海外 only 但目标华人玩家)| E7 成本 + 演员池 |
| E-Q5 | 配音风格:专业播音腔 / 影视配音员 / 业余热血? | **影视配音员**(沉浸感 vs 价格平衡)| E7 单价 ¥500-1500 / 段 |
| E-Q6 | audio 文件格式:wav / ogg / mp3? | **ogg**(Flutter 通用 + 体积 vs 质量平衡) | E1 SoundManager + assets 体积 |

## 4. 子任务粒度

- **E1.1**:`pubspec.yaml +audioplayers` + `lib/core/audio/sound_manager.dart` 单例 + Riverpod provider
- **E1.2**:`audio_settings.dart` BGM/SFX/Master 三轴 volume + Isar 持久化 + 设置面板 widget
- **E2.1**:主菜单 cue point `MainMenuScreen.initState`
- **E2.2**:战斗 cue point `BattleScreen` enter/exit + 胜利 / 失败 jingle hook
- **E2.3**:闭关 cue point `SeclusionScreen` enter/exit
- **E3.1**:`combat_sfx.dart` 注入 `damage_calculator` 4 SFX 触发点(命中 / 暴击 / 死亡 / 大招)
- **E3.2**:7 阶 pitch shift 程序化(`AudioPlayer.setPlaybackRate`)
- **E4.1**:`ui_sfx.dart` button / page / equip / learn / buy / levelup / error 7 触发点
- **E5.1**:Epidemic Sound 挑 3 BGM 候选 → 用户拍 → 下载归位
- **E6.1**:freesound 挑 36 SFX 候选清单(每 SFX 3 候选)→ 用户拍
- **E7.1**:配音 script 10 段(师父三句 + Ch4 公孙策 + Ch4 西门吹雪 + Ch5 段天涯 + Ch5 慕容白 + Ch6 玄音长老 + Ch6 飞升仪式 + 玩家飞升)
- **E7.2**:Fiverr / B 站语音工坊 找配音员 + 单价比对
- **E7.3**:录制 / 后期 / 接入 `assets/audio/voice/` + 剧情触发 hook

## 5. 红线 / 风险

- **基调克制**:水墨丝竹箫笛,不要电子合成器 / J-pop / 摇滚
- **音量默认值**:BGM 60% / SFX 80% / Master 100%,首次进游戏弹音量调节(避免炸耳)
- **授权清单**:每个素材附 LICENSE.txt 写明来源(G 段法律商业 doc 要用)
- **配音 ROI**:Q3 拍 ~10 段 不要膨胀到 30+(成本失控)
- **不阻塞主对话**:E5-E7 素材外采全异步,Claude 不卡这条线
- **风险:授权过期**:Epidemic Sound 月订断订后已发布游戏内素材需买永久授权 → 预算预留 + 文档清晰记录每首歌 LICENSE 类型
- **风险:SFX pitch shift 7 阶**听感可能不自然:fallback 录 7 套(成本 ×7)→ Demo 先用 pitch shift,玩家反馈差再补

## 6. 验收

- [ ] E1 SoundManager 单元测试 + volume 持久化测试
- [ ] E2 BGM 3 套 + crossfade + 胜利/失败 jingle
- [ ] E3 SFX 战斗 28 触发(或 4 通用 + 7 阶 pitch)
- [ ] E4 SFX UI 7-8 触发
- [ ] E5 BGM 文件归位 `assets/audio/bgm/{main,battle,seclusion}.ogg` + LICENSE
- [ ] E6 SFX 文件归位 `assets/audio/sfx/<id>.ogg` + LICENSE
- [ ] E7 ~10 段配音归位 `assets/audio/voice/<id>.ogg` + 剧情触发
- [ ] 全 audio 资源体积 < 50MB(Demo 体积控制)

## 7. 依赖 / 阻塞关系

- E1-E4 工程独立(Claude 主对话推)
- E5-E7 素材外采 lead time 1-2 周(用户异步办)
- E5 BGM 必须先于 E2 cue point 联调(否则只能用占位音)
- E7 配音前需 G 段「BGM/SFX 来源清单」起草锚定授权类型
- F 段 Steam Demo 上架前 E1-E4 工程必须完成(SoundManager 不全玩家差评)

## 8. closeout / 验收 doc

- 每 Batch 完成后:`docs/handoff/m15_e_<batch>_closeout_<date>.md` ≤80 行
- 最终段:`docs/handoff/m15_e_full_closeout_<date>.md` + CHECKLIST §E 4/4 全勾 + PROGRESS 顶段对齐
