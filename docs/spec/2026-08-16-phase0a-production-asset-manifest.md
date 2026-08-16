# Phase 0A 根应用生产资产清单与规格（2026-08-16 · Kimi 规格）

> 配套：`docs/spec/2026-08-16-phase0a-production-feedback-contract.md`（事件→视觉/音频映射）。本清单只写规格，不产资产。落点为**建议目录**，实际接线切片落地时须在 `pubspec.yaml` 逐目录声明（本单禁改 pubspec，列为前置依赖）；大图遵循 webp-in-png 约定（`assets/README.md`，`tool/convert_assets_webp.py` 幂等转码）。probe 资产不进生产，仅作规格对照样本；命名一律 snake_case + `_v<N>` 版本尾。所有尺寸用**比例/安全区**表述——仓库无既有战斗序列帧图集可反推精确像素基准，不伪造数字。

## 通用交付规格（各组共用，不重复列）

- 帧格：图集按等大方格排布，单帧内角色/特效主体高度占帧格高约 2/3～3/4，四周透明边留 ≥ 帧格边长 5% 的安全区，杜绝相邻帧渗色。
- 锚点：一律**脚底锚点** = 帧格底边中点（允许上移一个固定小比例，同一张图集内所有帧一致，规格表随图集附锚点比例说明）。
- 方向：出招朝向统一（建议面向右），反向由表现层镜像，不出双方向资产。
- 循环：idle 可循环；attack / hit / death / telegraph 单次播放；特效默认单次，循环类另行标注。
- 色板：水墨克制（青、墨、宣纸黄，绛红仅破招/预告语义点缀），禁 Material 默认饱和色。
- 验收公共项：资产清单对照事件契约逐事件有归属 + 双视口（1280×720 / 1440×900）目检 + 水墨色板目检。

## 1. 祖师动作（P0）

- 现状：`assets/characters/founder.png`、`battle_founder_v2.png` 为立绘，非动作帧；probe `founder_pose_atlas_v1.png`（6 姿势取格）与 `founder_cutout_parts_v1.png` 仅对照样本。
- 缺失：idle / attack（4–6 帧）/ hit / death 序列帧图集。
- 落点：`assets/characters/anim/founder_<action>_atlas_v1.png`。
- 优先级：attack P0，idle/hit P0，death P1。依赖：战斗表现层接线切片。验收：对照 attack_started/hit_landed/enemy_defeated 事件消费链 + 目检。

## 2. 山贼动作（P0）

- 现状：`assets/enemies/bandit_b.png`、`bandit_c.png`、`bandit_head.png` 及 `battle_bandit_blade.png`、`battle_bandit_archer.png` 等均为立绘（265 文件实测在列），无动作帧。
- 缺失：attack / hit / death 序列帧（可一套骨架多套皮，spec 不锁数量）。
- 落点：`assets/enemies/anim/bandit_<action>_atlas_v1.png`。
- 依赖/验收：同祖师组。

## 3. 精英动作（P1）

- 现状：probe `elite_pose_atlas_v1.png`（4 姿势）仅对照；根应用精英为立绘（如 `battle_elder_grey.png`）。
- 缺失：精英 6 姿势图集（受击/倒地拆分）+ telegraph 蓄招姿势。
- 落点：`assets/enemies/anim/elite_<action>_atlas_v1.png`。
- 优先级：P1（破招链路可读依赖 telegraph 姿势，可先用变色预告环兜底）。验收：对照 elite_telegraph_started/elite_broken 事件。

## 4. 掌风（P0）

- 现状：无资产；probe 为贝塞尔色块占位（`gameplay_game.dart:2026-2058`）。
- 缺失：掌风水墨贴图 sprite（含飞行中拉伸变形容差，spec 只要求横向主图一张）。
- 落点：`assets/ui/battle_fx/palm_wind_v1.png`。
- 规格：横向长条构图，主体占高度约 1/2，首尾透明淡出；单次播放，由表现层按弹道缩放。验收：projectile_launched 事件消费 + 不遮主角目检。

## 5. Q 聚怪（P0）

- 现状：无资产；probe 双描边椭圆环 + 内向短线占位。
- 缺失：多层旋转墨环 sprite（2–3 层可叠加旋转）+ 拉拢轨迹线贴图。
- 落点：`assets/ui/battle_fx/gather_ring_<n>_v1.png`、`gather_trail_v1.png`。
- 规格：环形主体居中、外缘透明淡出；循环（旋转由表现层驱动，贴图本身单帧）。音效：新资产（见 §10），缺失期静音不借用。
- 验收：gather_started/applied 事件消费 + 受影响单位可辨目检。

## 6. R 清场（P0）

- 现状：无资产；probe 3 圈扩散墨环 + 墨线红痣点占位。
- 缺失：全屏径向墨迹 sprite（序列 3–5 帧或单帧由表现层缩放）。
- 落点：`assets/ui/battle_fx/clear_burst_v1.png`（或 `_atlas`）。
- 规格：径向构图中心密外缘散，覆盖比 ≤ 视口短边为上限的安全区，不压 HUD。验收：clear_started/applied 事件消费 + 题字压制规则目检。

## 7. 命中 / 死亡（P0）

- 现状：闪白为 ColorFilter 直绘（无需资产）；死亡无资产，probe 透明度渐出占位。
- 缺失：死亡墨散粒子贴图（小粒多张合一图集）+ 倒地帧（并入 §1–§3 动作图集）；题字「破·斩·震·断」用字体/文案层，不出图片资产。
- 落点：`assets/ui/battle_fx/death_ink_scatter_v1.png`。
- 规格：粒子单体小（帧格占比低），单次播放，透明度渐出曲线归表现层。验收：enemy_defeated 事件消费 + 尸体不挡存活单位目检。

## 8. 破招（P1）

- 现状：无资产；预告环/窗口变色为 Canvas 直绘（probe 已验证可读）。
- 缺失：破招瞬间小爆发墨粒贴图。
- 落点：`assets/ui/battle_fx/break_burst_v1.png`。
- 规格：绛红点缀仅允许出现在破招/预告语义（对齐 probe 冻结视觉语言）；单次播放。验收：elite_broken 事件消费 + 预告环不被覆盖目检。

## 9. 波次 / HUD（P1/P2）

- 现状：无横幅资产；技能印 probe 为 Material 进度条 + 英文串占位。
- 缺失：波次宣纸横幅底图（「第 N 波」文字走 data 文案层 + 字体，不烘进图）；技能印五态（ready/cooldown/qi/casting/down）水墨印面样式——印面可为纯 Canvas 实现，贴图可选。
- 落点：`assets/ui/battle_fx/wave_banner_v1.png`（可选 `assets/ui/battle_hud/`）。
- 规格：横幅横向构图、高度 ≤ 视口高 1/8 安全区、不遮战斗主体；循环性无。优先级：横幅 P1、印面水墨化 P2。验收：wave_started/wave_cleared 与 skill_availability_changed 事件消费 + 双视口可读目检。

## 10. 音频（P0/P1）

> 播放一律走根 `lib/shared/audio` 现有后端（`SoundManager`/`AudioPlayersBackend`），不新增依赖；新槽位的 `SfxId` 枚举扩展属后续 Dart 接线切片，本清单只登记资产需求。

| 槽位/用途 | 现状（实测） | 处置 | 优先级 |
|---|---|---|---|
| battleHit 6 变体 | `assets/audio/sfx/battleHit_0_0..1_2.mp3` 在列，映射 `audio_assets.dart:71-75` | 直接复用 | P0 |
| battleCrit | `battleCrit.mp3` 在列 | 复用 | P0 |
| battleUlt（R 清场） | 文件在列但**借用** realmAdvance（`dedicated_audio_assets.dart:29-35`，目标时长 800–1600ms） | 重制专属资产同路径替换 | P0 |
| battleChargeStart（精英预告） | 文件在列但**借用** defeat（`dedicated_audio_assets.dart:36-41`，500–1200ms） | 重制专属资产同路径替换 | P1 |
| battleInterrupt（破招） | `battleInterrupt.mp3` 在列且已接线（`battle_screen.dart:747-748`） | 复用 | P0 |
| battleStagger | `battleStagger.mp3` 在列 | 复用（enemy_defeated 回退候选） | P0 |
| battleDeath（敌人死亡） | 槽位预留**无资产未接线**（`audio_assets.dart:47,55`） | 新资产 `assets/audio/sfx/battleDeath.mp3` + 后续切片接线；接线前回退 battleStagger 或静音 | P0 |
| Q 聚怪音效 | 无槽位无资产 | 新资产（命名随槽位定，方向待后续切片拍板；缺失期静音） | P1 |
| 波次横幅 | 无专用 | 复用 `uiPaperOpen.mp3`（临时借用，需登记）或新资产 | P1 |
| victory / defeat | `victory.mp3` / `defeat.mp3` 在列且生产已接线 | 复用 | P0 |

- 验收：`test/shared/audio/` 现有测试不红 + 借用登记表更新（后续接线切片）+ 真机听验。

## 复核命令

```sh
ls assets/audio/sfx/                                                # 19 个 mp3
grep -n "battleDeath\|SfxId" lib/shared/audio/audio_assets.dart     # 槽位全景 + battleDeath 预留
grep -n "temporaryBorrowed\|targetDurationMsRange" lib/shared/audio/dedicated_audio_assets.dart
ls assets/characters/ assets/enemies/ | wc -l                       # 立绘现状
find assets -name "*atlas*" -o -name "*anim*"                       # 0 命中：根应用无动作帧图集
```
