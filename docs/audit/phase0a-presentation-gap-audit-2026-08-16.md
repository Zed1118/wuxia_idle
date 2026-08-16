# Phase 0A 表现层缺口审计（2026-08-16 · Kimi 只读）

> 基线：切片验收 commit `5a107a5b`，本 worktree HEAD `8e1a23ab`。范围：`tools/phase0minus_probe/`（下称 probe）、`assets/`、`lib/features/battle/`、`lib/shared/audio/`。所有计数/路径本会话实测，复现命令见文末。行内路径未注明者相对仓库根；`gameplay_game.dart` 等均指 `tools/phase0minus_probe/lib/gameplay/` 下文件。

## 总览

- 切片运行时仅消费 4 张图（生产方 `gameplay_art.dart:21-31`）：长卷 `scroll_panorama_mountain_to_gate_v1.png` + 祖师/山贼/精英三张姿势图集，均在 `tools/phase0minus_probe/assets/phase0b/runtime/`（实测在列）。
- 动作 = 每帧按状态取格 `drawImageRect`（`gameplay_art.dart:66-73`），无序列帧/骨骼（grep `SpriteAnimation|Skeleton|spine` 0 命中）；受击 = `ColorFilter` 闪白（`gameplay_art.dart:106-111`）；特效全部为 Canvas 直绘占位；greybox 回退仍内联（`gameplay_game.dart:719-722,1201-1205,1590-1598`）。
- probe 音频为零：pubspec 无音频依赖、`AudioPlayer` 0 命中；隔离守卫 `test/phase0b/feedback/feedback_isolation_guard_test.dart:18-21` 黑名单 audioplayers/flame_audio/just_audio；`phase0b/feedback/feedback_cues.dart:5-6` 明示静音契约、真音频另行 gate。
- 主仓音频全链路可复用：`lib/shared/audio/` 三件套（`AudioBackend`/`AudioPlayersBackend`/单例 `SoundManager`）+ 声明式 `BgmScope`；`assets/audio` 30 个 mp3 实测 30/30 有消费点；`battleUlt`/`battleChargeStart` 为借用素材（`dedicated_audio_assets.dart:29-42` 标 temporaryBorrowed）；`battleDeath` 槽位预留、无资产未接线（`audio_assets.dart:47,55`）。
- 生产战斗 `lib/features/battle/` 与 probe 完全独立、零共享代码；其演出层完整（38 个 presentation 文件）且已消费场景/立绘资产（stages.yaml/towers.yaml 实测 sceneBackgroundPath 122/49 条、iconPath 135/116 条）并触发全部战斗 SFX。**返修口径**：probe 从此仅作手感/图像/性能参考与验收对照，不再是表现层实装目标；根应用仍是旧战斗形态，表现层缺口需随 Qoder 生产接线在根应用纯 Flutter 战斗表现层 + 根 `assets/` 补齐。

## 七类反馈缺口

> 返修口径：本节保留事实盘点，「缺失/规格」作为根应用补齐时的资产与效果规格参考；probe renderer 不再改动，缺失资产（含 battleDeath/battleUlt 与 Q/R 专用音效）入根 `assets/`。

**1. 普攻/掌风 — P0**
- 可复用：命中停顿 22ms（`assets/probe_scenarios.yaml:144`）、掌风 540 判定（`gameplay_game.dart:1003-1035`）、主仓 battleHit_0_0..1_2 六变体（消费链 `lib/shared/audio/audio_assets.dart:71-75`）。占位：掌风 = 贝塞尔色块（`gameplay_game.dart:2026-2058`，填充 `0xff355B52`）；普攻墨迹 = drawLine 线段（`:2010-2025`）；动作 = 祖师 6 姿势取格（映射 `:1191-1198`）。
- 缺失：挥击/掌风序列帧或骨骼动画、水墨贴图 sprite、切片内攻击音效。规格：祖师攻击 4–6 帧序列帧（底材 `runtime/founder_cutout_parts_v1.png` 已在库）；掌风 Path 换水墨贴图；音效复用 battleHit 变体。

**2. Q 聚怪 — P0**
- 可复用：拉拢/失衡 3.2s/停顿 1.35s 数值链（`probe_scenarios.yaml:92-93`、`combat_rules.dart`）。占位：双描边椭圆环（`gameplay_game.dart:1162-1184`）、32 粒内向短线（`:2059-2067`）、失衡土色脚环（`:1512-1524`）、准星双圈（`:1653-1686`）。
- 缺失：水墨涡旋正式特效、聚怪音效（主仓无对应资产）。规格：多层旋转墨环 sprite + 拉拢轨迹线；音效为新资产（方向待拍板）。

**3. R 清场 — P0**
- 可复用：65ms 停顿 + 相机震动（`probe_scenarios.yaml:145,147-148`）、群体飘字链（`gameplay_game.dart:1688-1792`）、主仓 battleUlt.mp3（借用中）。占位：3 圈扩散墨环（`:1167-1184`）、128 粒墨线+红痣点（`:2068-2083`）。
- 缺失：全屏径向墨迹 sprite、battleUlt 专属最终资产。规格：径向墨迹 sprite 序列替换 Canvas 环；音效重制专属 ult。

**4. 敌人命中/死亡 — P0**
- 可复用：闪白（`gameplay_art.dart:106-111`）、血条显示规则与样式（`gameplay_game.dart:1617-1649`）、48 标签池分色（`:1743-1747`）、死亡错峰移除（`:1443`）。占位：死亡 = 姿势帧透明度 0.62→0.08 渐出（`:1585-1587`）。
- 缺失：死亡墨散特效/倒地帧、敌人受击与死亡音效（`battleDeath` 无资产未接线）。规格：墨散粒子 + 倒地帧；新增 battleDeath 资产接线或复用 battleStagger.mp3。

**5. 精英破招 — P1**
- 可复用：预告环窗口变色（`gameplay_game.dart:1525-1540`）、commit 红圈（`:1541-1550`）、破招点→1.8s 失衡 + 80ms 停顿 + 回气（`:1455-1471`）、主仓 battleInterrupt.mp3（已接线 `lib/features/battle/presentation/battle_screen.dart:747-748`）。占位：破招成功无特效，仅 staggered 姿势格；精英仅 4 姿势（`:1569-1577`）。
- 缺失：破招瞬间墨爆反馈、精英图集扩姿势。规格：小爆发墨粒 + 精英 6 姿势（受击/倒地拆分）；音效复用 battleInterrupt。

**6. 波次转场 — P1**
- 可复用：YAML 分批入场驱动（`gameplay_game.dart:468-491`）、波间 5s 回气窗（`probe_scenarios.yaml:120`）。占位：无——仅 HUD 文本（`gameplay_game.dart:453,199`）与顶栏 `WAVE x/3`（`tools/phase0minus_probe/lib/main.dart:689`）。
- 缺失：波次横幅/敌人入场效果/转场音效。规格：宣纸横幅（第 N 波）+ 敌人墨入淡入；音效可复用 uiPaperOpen.mp3 或新资产。

**7. HUD 状态 — P2**
- 可复用：等宽技能印 `_SkillSeal` 五态 READY/CD/QI/CASTING/DOWN（`main.dart:853-972,741-779`）、10Hz `ValueNotifier` 数据源（`gameplay_game.dart:243-247`）。占位：Material `LinearProgressIndicator` + 英文串；指令缓冲 0.42s 无可视化（`gameplay_game.dart:904-919`）。
- 缺失：中文状态文案（生产接线时须走 data 文案守不硬编码红线）、缓冲指示、水墨印面样式。规格：印面水墨化 + 中文五态 + 缓冲微光。

## 双视口验收要点与不得回退约束

- 视口：1280×720 与 1440×900 均可操作、HUD 可读、20+1 同屏主角/精英长血条/飘字可辨、主角与精英不被特效遮挡（沿用切片既有目检口径）。
- 性能基线（恢复点记录，LG 60Hz/DPR 1，`phase0a_replay` Profile 6/6 PASS）：720p p99 6.258–9.099ms、900p p99 8.023–8.105ms、最大帧 ≤12.730ms、超预算帧 0、连续严重帧 0；任何补齐不得回退。
- 资源约束：反馈池 ≤160、伤害标签池 ≤48 且溢出 0（峰值基线 136/22）；`_painterCache` ≤16（`gameplay_game.dart:1790`）；禁逐标签 `saveLayer`；热路径禁 debug 日志。
- 风格：水墨克制色板，禁 Material 默认饱和色；新资产入根 `assets/`（战斗音效入根 `assets/audio/`），不再新增 probe 资产；probe readability 五帧（`assets/readability/manifest.json` sha256 校验）与双视口基线仅作验收对照，正式验收对象为根应用真实入口。

## 后续小切片（P0→P2 · 返修口径）

硬口径：probe 仅为手感/图像/性能参考与验收证据，不再扩展其美术、HUD、音频依赖或实现；表现层实装域 = 根应用纯 Flutter 战斗表现层 + 根 `assets/`；音效走根 `lib/shared/audio` 现有后端，专用资产入根 `assets/audio/`；实际文件名待 Qoder 生产接线路线冻结后再定，本节不虚构。

- P0-1 资产规格固化与制作（不改 probe renderer、不改根应用代码）：祖师/山贼/精英攻击·受击·倒地序列帧，掌风/聚怪涡旋/清场墨迹/死亡墨散贴图，破招墨爆、波次横幅与 HUD 印面水墨化样式，规格以七类缺口节为准；产出入根 `assets/`；验收：资产清单对照七类规格 + 水墨克制色板目检。
- P0-2 战斗音效资产补齐（根应用链路）：复用根 `lib/shared/audio` 现有后端，不引入 probe 音频依赖；battleDeath 接线、battleUlt 专属资产及 Q 聚怪/R 清场音效入根 `assets/audio/`；验收：`test/shared/audio/` + 真机听验。
- P0-3 根应用接线前置：配合 Qoder 冻结 deterministic simulation core 与 input adapter 边界，产出根应用表现层接线清单（实际文件名届时再定）；本片只产清单，不写实现。
- P1 纯 Flutter 动作/特效/HUD 实装（根应用）：必须排在 Qoder deterministic simulation core 与 input adapter 边界确立之后；序列帧动作、水墨特效、波次横幅、HUD 中文五态 + 指令缓冲可视化在根应用战斗表现层实装；验收：根应用真实入口双视口 smoke + 性能/可读性对照 probe 基线不回退。
- P2 验收对照：正式验收对象 = 根应用真实入口；probe 已有双视口 Profile 与 readability 五帧基线仅作对照，probe 本体不改。

## 核心复现命令

```sh
find assets/audio -type f -name "*.mp3" | wc -l                      # 30
grep -rn "AudioPlayer\|audioplayers" tools/phase0minus_probe/lib     # 0 命中
grep -rn "SpriteAnimation\|Skeleton\|spine" tools/phase0minus_probe/lib  # 0 命中
grep -c "sceneBackgroundPath" data/stages.yaml data/towers.yaml      # 122 / 49
grep -c "iconPath: assets/enemies" data/stages.yaml data/towers.yaml # 135 / 116
ls tools/phase0minus_probe/assets/phase0b/runtime/                   # 4 张消费图在列
grep -n "temporaryBorrowed\|battleDeath" lib/shared/audio/*.dart     # 借用/预留登记
```
