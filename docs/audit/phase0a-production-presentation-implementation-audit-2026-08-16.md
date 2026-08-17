# Phase 0A 生产表现层首切片实装审计（2026-08-16 · Kimi 只读 · 第七批切片 3）

> 基线：第六批 READY `2e688b08`，分支 `codex/phase0a-production-batch7-presentation`。范围：`lib/features/battle`、`lib/features/debug`、`lib/shared`、`assets`、`pubspec.yaml`、相关 tests。口径对齐 `docs/superpowers/plans/2026-08-16-phase0a-production-batch7-presentation.md`（下称计划档）。所有路径/计数/行号本会话实测，复现命令见文末。本文只读，未改任何生产代码/资产/probe/GDD/CLAUDE。

## 1. 可复用根资产与 pubspec 声明

pubspec 资产段 `pubspec.yaml:55-84` **全为目录声明**（不递归子目录）；首切片相关：`assets/characters/`(:69)、`assets/ui/`(:71)、`assets/ui/mj/`(:72)、`assets/enemies/`(:78)、`assets/scenes/`(:79)、`assets/audio/bgm/`(:83)、`assets/audio/sfx/`(:84)。**无 fonts 段**（`grep -n fonts pubspec.yaml` 0 命中）。

| 用途 | 精确路径（实测尺寸） | pubspec 覆盖 |
|---|---|---|
| 战斗背景 | `assets/scenes/battle_mountain_pass_stage_v2.png` 1672×941（+冷色 `_cool_v3`） | ✅ :79 |
| 祖师立绘 | `assets/characters/battle_founder_v2.png` 1024×1536（全身 `founder.png` 896×1344） | ✅ :69 |
| 山贼立绘 | `assets/enemies/battle_bandit_{blade,archer,head,b,c}.png`（965–1024×1536–1672） | ✅ :78 |
| 精英立绘 | `assets/enemies/battle_hidden_elder.png`（probe manifest 登记的精英身份源） | ✅ :78 |
| 宣纸/印面/卷轴 | `assets/ui/paper_bg.png`、`seal_red.png` 1024×1024、`ink_divider.png`、`scroll_horizontal.png` 1904×640 | ✅ :71 |
| 特效混合层 | `assets/ui/mj/fx_*_blend.png`×8、`caption_ink_blob`、`ui_boss_frame_blend`、`overlay_*_blend` | ✅ :72 |
| 战斗 SFX | `assets/audio/sfx/`：`battleHit`+6 变体、`battleCrit`、`battleUlt`、`battleChargeStart`、`battleInterrupt`、`battleStagger`、`victory`、`defeat`、`uiPaperOpen`（19 个 sfx 全列实测） | ✅ :84 |
| 战斗 BGM | `assets/audio/bgm/{battle,mainline,boss}.mp3`（bgm 共 11） | ✅ :83 |

**缺口（首切片不生成资产，登记后续资产批）**：
- 根 assets **无 3600×720 长卷**（`find assets -iname '*panorama*'` 0 命中）；probe 的 `scroll_panorama_mountain_to_gate_v1.png` 为 probe 专属，首切片用 `battle_mountain_pass_stage_v2.png` 替代。
- 根 assets **无任何姿势图集/切件**（`find assets -name '*pose*' -o -name '*atlas*' -o -name '*cutout*'` 0 命中），只有整身立绘；probe manifest 标注自动切件方案已 rejected。
- 音频：`battleUlt`/`battleChargeStart` 为 temporaryBorrowed（`lib/shared/audio/dedicated_audio_assets.dart:30-41`，借自 realmAdvance/defeat）；`battleDeath` 槽位留位无文件（`lib/shared/audio/audio_assets.dart:48-63` 枚举内注释预留）。SFX 映射可直接复用 `sfxForAction`（`audio_assets.dart:79-86`）与 `chargeTransitionSfx`（:94-121）。

## 2. 水墨组件/token/旧战斗绘制件复用判定

实测 `lib/features/battle/presentation/` 共 **45 个** .dart；`grep` 旧 domain/application import：**18 个有、27 个无**（其中 `battle_playback_view.dart` 是 `part of battle_playback_controller.dart`，视同耦合，干净件实为 26）。presentation 内 **0 文件引用 phase0a**，新旧表现层零交集。

**可直接复用（A 类，零旧 battle domain import，grep 实证）**：
- 血条：`hp_bar.dart:10` `HpBar` + 墨轨 painter :142（import 仅 flutter/wuxia_tokens/battle_typography_tokens）。
- 伤害飘字：`damage_popup.dart:44` `DamagePopup`（白/旧金暴击/灰闪避，colors.dart:86-88 token）。
- 受击/全屏闪：`hit_flash.dart:6`、`screen_flash.dart:5`（均仅 import flutter）。
- 弹道：`projectile_trail.dart:10` 水墨笔触弹道 + `projectile_trail_style.dart`；VFX 载体 `battle_vfx_entries.dart:7-57`、分层 `widgets/battle_vfx_layers.dart:11/44`。
- 场景/氛围：`battle_scene_background.dart:37`（背景图+scrim+水墨兜底 painter :373-491）、`battle_atmosphere_overlay.dart:7`。
- 题字：`impact_glyph_overlay.dart:12`（斩/震/断单字）、`ultimate_caption_overlay.dart:23`（大招题字，依赖 data SkillDef/core enums，非 battle domain）。
- 技能印表面件：`widgets/battle_skill_slip.dart:29` 冷却批注牌 `BattleSkillCooldownMark`（纯表面，内容注入）。
- token：`shared/theme/colors.dart:12-96` `WuxiaColors`（HP 三段色/飘字三色）、`wuxia_tokens.dart:15-75` `WuxiaUi`（纸/墨/绛/金 + battle* 专区色，仅命名前缀无代码耦合）、`battle_typography_tokens.dart:9` `BattleTypography`。
- 通用件：`meridian_bar.dart:9` `MeridianBar`（真气条/CD 轨，替 LinearProgressIndicator）、`portrait_frame.dart:18`、`wuxia_image.dart:13`、`asset_fallback.dart:25`、`shared/effects/screen_shake.dart:6`（9 行纯函数屏震）。
- 攻击位移包装：`attack_animation.dart:19`（controller 外注，无状态）。

**可参考需改写（B 类）**：`battle_charge_seal.dart`（painter 可留，入参挂 `battle_state.dart` import :7）、`avatar_status_tags.dart:33`、`impact_profile.dart:8`（打击感画像，入参 `BattleAction` :4）、`boss_phase_presentation.dart`、`battle_visual_roster.dart:9`（击杀序 roster 概念可参考，实现绑 `BattleState` :1）。

**不能复用（C 类，强耦合旧 3v3）**：`battle_screen.dart:61`、`battle_playback_controller.dart:51`（+part view）、`character_avatar.dart:66`（2400+ 行，入参全程 `BattleCharacter`，painter 技法可借鉴不可搬）、`widgets/battle_field.dart:22`（3v3 槽位编排）、`widgets/battle_header.dart:22`、`widgets/battle_bottom_bar.dart:1054` `SkillCommandButton`、`widgets/battle_banners.dart`、`widgets/battle_target_chips.dart:12`、`victory_overlay.dart`/`victory_ceremony.dart:50`、`cycle_select_control.dart`、`battle_stage_geometry.dart:5`（无 domain import 但锚点数值自述按"标准 3v3 非对称舞台"调校）。耦合根源：旧 `BattleState` 左右两队 List（`battle_state.dart:783`）、`BattleCharacter`(:129)、`BattleAction`(:51)。

**文案注意**：`shared/strings.dart` `UiStrings` 通用但含旧 3v3 专用串（如 `battleTitle(N v M)` :31 编码两队格式），引用前逐条甄别；新文案走 `UiStrings` 增补，不散写中文（CLAUDE.md 红线）。

## 3. visual_route 最小接线点

路由名计划档已冻结：`VisualRoute.phase0aBattlePlayable`。最小必改 **2 处**：

1. `lib/features/debug/application/visual_route.dart:3` 枚举 `VisualRoute` 追加值（构造 `(id, label)`，:390-396）；`parseVisualRoute`(:453-463) 遍历枚举自动识别，无需改。
2. `lib/features/debug/presentation/visual_route_host.dart:278` `buildVisualTarget` 穷举 switch 加 case（无 default，漏加即 analyze 报错 = 编译期强制接线）。

自动生效（不用改）：hub 路由列表（`visual_route_host.dart:1721-1763` 取 `VisualRoute.values`）、full 验收 suite（`visual_acceptance_plan.dart:141`）、parse 往返回归（`test/features/debug/visual_route_test.dart:119-123` 循环自动覆盖新值）。

按需可选：READY 门控 `controlsReadiness`（`visual_route.dart:399-413`，战斗冻结到目标拍时用 `onTargetReady`，host :248-273）；`kind` 分类（:417-447，默认 productionShell）；smoke suite `_smokeRoutes`（`visual_acceptance_plan.dart:39-61`）。

隔离证据：`lib/main.dart:38-45` 唯一入口，`!kReleaseMode` 门控（debug+profile 可达、release 短路），输入 `--dart-define=VISUAL_ROUTE=`（`visual_route.dart:510-518`）；Isar 隔离目录 `visual_route_isar_directory.dart:27-37`（systemTemp 每次重建，绝不碰生产 documents）。可仿照体例：`battleTapLive`（`visual_route_host.dart:664-686`，"可操作战斗预览"先例，但首切片不经 3v3 `ScenarioLauncher`，直接私有 preview widget 消费 `Phase0aWaveBattleFlow`）。

## 4. state/events → 表现逐项映射

消费形态：`flow.advance({deltaSeconds, command})` 同步返回本拍 `List<Phase0aEvent>`（`phase0a_wave_battle_flow.dart:60-63,149`），状态 getter 拉取（:55-56）；**无 Stream/定时器/内置拍频** → 表现层自驱固定拍循环。事件契约：按 `seq` 单调消费、重复丢弃、**禁止据事件重算数值**（`phase0a_combat_events.dart:5-6`）。终局后 advance 幂等（`phase0a_wave_battle_flow.dart:64-66`），"终局后输入无效"天然成立。

| 表现需求 | 生产数据源（file:line） | 消费要点 |
|---|---|---|
| 角色位移 | `state.player/enemies[].position: ArenaVector{x,y}`（`phase0a_combat_model.dart:51`；`arena_vector.dart:8,12-13` y 向下为正、无 lane）；`facing` :52；`Phase0aMoveIntent`（`phase0a_combat_intent.dart:17-21`） | 连续坐标 → world→screen 纵深变换 + 按脚底 y 排序新写；位移只读 state，不回写 |
| 血条 | `currentHealth/maxHealth`（model :53-54）；`isAlive` :65 | 全体常显，复用 `HpBar`；表现层不自行扣血 |
| 敌人移除/死亡 | `Phase0aEnemyDefeated`（events :91-112，`defeatKind{normal,elite}` model :10,63）；state.enemies 只存活敌（model :169-170 注释） | 事件驱动墨散（精英更重），不得重复移除 |
| 真气条 | `qiCurrent/qiMax`（model :56-57） | 复用 `MeridianBar`；qi 不足态联动技能印 |
| 伤害数字 | `Phase0aHitLanded`（events :42-88：`resolvedDamage/isCritical/remainingHealth`） | 复用 `DamagePopup`；所有非零伤害出数字；暴击高克制层级 |
| 普攻 | `Phase0aAttackStarted`（events :15-36，`moveKind{light,heavy}`；heavy 无产生方）；扇区参数在 `Phase0aAttackIntent`（intent :25-40） | 出手前摇/墨锋起笔；命中反馈只挂在 HitLanded，不伪造伤害 |
| 远程/掌风 | **无独立远程 intent**（intent 全文实测仅 move/attack/gather/clear 4 种） | 计划档"玩家远距命中显示掌风轨迹"= 表现层按 HitLanded 的 actor/target 位置差阈值显示 `ProjectileTrail`，纯视觉分支，不改 domain、不重算 |
| Q 聚怪 | `Phase0aGatherStarted/Applied`（events :154-196；`outcomes[].statusApplied{pulled,staggered}` model :16） | 涡旋→拉拢轨迹；只读 outcomes/status |
| R 清场 | `Phase0aClearStarted/Applied`（events :199-241） | 题字/径向墨爆→逐目标伤害数字；`isUltimate` 当前恒 false（reducer :181 硬写），R 的视觉层级由事件类型区分 |
| 波次 | `Phase0aWaveStarted/Cleared`（events :291-334，**1-based**）；flow 内部游标 0-based（`phase0a_wave_battle_flow.dart:51`） | **state 无波次字段**，当前第几波由 UI 从事件维护；宣纸横幅+短转场 |
| 终局 | `Phase0aBattleVictory/Defeat`（events :338-360）；`flow.outcome{ongoing,victory,defeat}`（`phase0a_wave.dart:4`，getter `wave_battle_flow:56`） | 全场唯一封签；终局后 advance 幂等 |
| 技能五态 | 枚举五态齐全 `Phase0aSkillAvailability{ready,cooldown,qi,casting,down}`（model :13）；**生产推导只出 ready/cooldown/qi**（`phase0a_combat_reducer.dart:413-421`，casting/down 全目录无产生方）；`Phase0aSkillAvailabilityChanged`（events :247-285 带 `cooldownRemaining/qiCurrent/qiRequired`）；`state.skillSlots`（model :188） | 等宽 Q/R 印按枚举全五态防御渲染，实测只会收三态；CD 秒数/真气门槛文案从事件载荷取 |
| 精英破招窗口 | `isEliteBreakWindowOpen`（`realtime_combat_rules.dart:56-61`）**无任何调用方，预留** | 首切片不做破招表现，登记后续批 |

**输入**：`Phase0aPlayerCommand{left,right,up,down,attack,gather,clear}`（`phase0a_player_input_adapter.dart:6-30`）→ WASD+普攻+Q+R 一键一 flag，瞄准取玩家 facing（:94）。**数值源缺口（如实登记）**：射程/半径/CD/气耗等竞技场调优值无 yaml 配置源，全是 adapter 构造参数（`phase0a_player_input_adapter.dart:38-52`），assembler 无生产调用方 → debug fixture 需显式注入，数值取值待主窗口拍板（不迁 probe 固定数值）。

## 5. 1280×720 / 1440×900 布局风险

- **旧三段式不可照搬**：`battle_layout_tokens.dart:17-18` 案台高 172–241px，720 视口下占 24–33%，战场仅余 ~430–500px（实测旧基线 header 47 + battlefield 489 + desk 184 @1280×720，`analyze_battle_v2_fidelity_test.py:195-197` 镜像数据）。首切片若只要顶栏+Q/R 双印，应自定 token 而非复用 `BattleLayoutMetrics`。
- **安全区公式按 800px 基准**：`stageTopSafetyInset = (800-h)*0.5 clamp 0..40`（`battle_layout_tokens.dart:119-120`）→ 720 得 40、900 得 0，两视口安全区不一致；新舞台需自定义世界边界→屏幕安全区映射。
- **背景裁切差异**：1672×941（≈16:9）场景图 BoxFit.cover 在 1280×720 与 1440×900（16:10）纵向可视范围不同，900p 上下看到更多 → 站位/血条安全区按 16:9 下限设计，或用 `AssetFraming`（`shared/utils/asset_framing.dart:8`）钉焦点。
- **同屏密度**：计划档要求全体敌人血条常显+所有非零伤害出数字；probe 基线为 20+1 同屏、伤害标签池 ≤48、反馈池 ≤160、峰值 136/22（gap 审计 :47-49）。根应用 `DamagePopup` 无池化 → 新 VFX 层须自建池并沿用 ≤48/≤160 上限；禁逐标签 `saveLayer`、热路径禁 debug 日志。
- **技能印等宽**：`battle_skill_slip` 竖签 slot 150px（`battle_layout_tokens.dart:25`）按 3v3 案台设计，不适用横向等宽双印；新印面 token 集中到新 presentation tokens 文件。
- **性能不得回退**（probe Profile 基线，验收对照）：720p p99 6.258–9.099ms、900p p99 8.023–8.105ms、最大帧 ≤12.730ms、超预算帧 0。
- **字体**：pubspec 无 fonts 段，首切片用既有字体链路，不新增字体资产。

## 6. 推荐新文件与测试列表

新文件（全部落在计划档冻结的新增域；文件名为建议，实现批可微调）：

- `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart` — debug 战斗屏（键盘 WASD/普攻/Q/R + 鼠标印按钮 + 键位提示 + semantics）。
- `.../phase0a_tick_controller.dart` — 固定拍自驱循环，调 `flow.advance`。
- `.../phase0a_stage.dart` — world→screen 纵深变换、y 排序、接地阴影、舞台安全区。
- `.../phase0a_actor_standee.dart` — 立绘（`WuxiaImage`+`asset_fallback`）+名条+`HpBar`。
- `.../phase0a_vfx_controller.dart` — seq 去重事件分发 → `DamagePopup`/`HitFlash`/`ScreenFlashOverlay`/`ProjectileTrail`/涡旋/墨爆/墨散，池化。
- `.../phase0a_wave_banner.dart`、`.../phase0a_outcome_seal.dart` — 波次横幅、终局封签。
- `.../phase0a_skill_seals.dart` — 等宽 Q/R 印五态（表面可借 `BattleSkillCooldownMark` 思路）。
- `.../phase0a_visual_roster.dart` — actor id→名称/正式资产/精英语义 config（不污染 domain）。
- `.../phase0a_presentation_tokens.dart` — 集中布局/色/token。
- `lib/features/debug/` 侧：fixture（真实 `BattleCharacter`、真实 `NumbersConfig`、显式 seed → `Phase0aProductionFlowAssembler.assemble`，`phase0a_production_flow_assembler.dart:44-88`）+ host switch case；`UiStrings` 增补文案。

测试（红测先行，对齐计划档测试切片 1–4）：

- `test/features/battle/presentation/phase0a/phase0a_stage_transform_test.dart` — world→screen 纵深、y 排序、安全区。
- `.../phase0a_event_mapping_test.dart` — 事件→VFX 映射、seq 去重、不重播。
- `.../phase0a_battle_screen_test.dart` — 真实 flow 驱动血条/伤害/Q/R/波次/终局；断言表现层不改 state、不重算伤害。
- `.../phase0a_skill_seals_test.dart` — 五态亮暗、CD/真气文案、键鼠与桌面 semantics。
- `test/features/debug/visual_route_phase0a_test.dart` — 路由注册、parse 往返（自动覆盖）、不出现在生产路由（`main.dart:38-45` 门控回归）。
- 既有 9 个 phase0a domain/application 测试文件（150 项基线）不改动，实装后全套回归。

## 7. 禁止项执行声明确认

本切片全程只读：未改 `lib/`、`data/`、`pubspec.yaml`、`tools/phase0minus_probe`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`；未接生产路由、未生成/转码任何资产；仅新增本文档并同步计划档勾选。`git diff --check` 干净。

## 核心复现命令

```sh
find lib/features/battle/presentation -name '*.dart' | wc -l          # 45
grep -rlE "import '\.\.(\/\.\.)?\/(domain|application)\/" lib/features/battle/presentation | wc -l  # 18
grep -rln phase0a lib/features/battle/presentation | wc -l            # 0
grep -n "fonts" pubspec.yaml                                          # 0 命中
find assets -iname '*panorama*' -o -name '*pose*' -o -name '*atlas*' -o -name '*cutout*'  # 0 命中
ls assets/audio/sfx/ | wc -l                                          # 19
grep -n "temporaryBorrowed" lib/shared/audio/dedicated_audio_assets.dart  # :29-42 两条借用
grep -rn "casting" lib/features/battle/domain/phase0a lib/features/battle/application/phase0a  # 仅 model:13 枚举声明；down 另作移动键参数（realtime_combat_rules.dart:11），非技能态
grep -n "kReleaseMode\|visualRouteIdFromInputs" lib/main.dart         # :38-45 门控
```
