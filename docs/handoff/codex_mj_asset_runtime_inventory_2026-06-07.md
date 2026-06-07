# Codex MJ asset runtime inventory (2026-06-07)

分支：`codex/t11-inventory-section-header`

## 结论

本轮 MJ 素材接入线已完成可用素材的主路径接入。当前 `assets/ui/mj/` + `assets/scenes/mj/` 共 57 张：

- 35 张：有运行时代码引用。
- 5 张：有 `WuxiaUi` token，但作为备用素材，当前不进入 UI。
- 17 张：处理前源图，无 token；对应 `_blend.png` / `_clean.png` 已进入运行时或备用 token。

素材源目录口径仍以 `/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07` 为准；旧目录 `/Users/a10506/Downloads/autojourney/筛选留用_2026-06-07` 不作为后续依据。

## 相关提交

- `338ca2e` 接入MJ主菜单与入口素材
- `fb51668` 接入MJ仪式页素材
- `d2f0b1f` 接入MJ战斗特效素材
- `4341eb6` 接入MJ首领头像框素材
- `2e7fa94` 接入MJ仪式红印素材
- `590c934` 接入MJ主菜单山门背景

## 运行时使用资产

### 主菜单 / 入口

| 资产 | token | 主要使用处 |
|---|---|---|
| `assets/ui/mj/menu_mountain_gate_clean_01.png` | `mainMenuBg` | `MainMenu` 背景 |
| `assets/ui/mj/entry_mainline_story_01.png` | `entryMainline` | 主线入口 |
| `assets/ui/mj/entry_character_profile_01.png` | `entryCharacter` | 角色 / 师徒入口 |
| `assets/ui/mj/entry_equipment_01.png` | `entryInventory` | 装备入口 |
| `assets/ui/mj/entry_technique_panel_01.png` | `entryTechnique` | 心法入口 |
| `assets/ui/mj/entry_seclusion_retreat_01.png` | `entrySeclusion` | 闭关入口 |
| `assets/ui/mj/entry_tower_challenge_01.png` | `entryTower` | 爬塔 / 部分后期入口 |
| `assets/ui/mj/entry_lightfoot_trial_01.png` | `entryLightFoot` | 轻功入口 |
| `assets/ui/mj/entry_city_defense_01.png` | `entryJianghu` | 江湖 / 门派 / PVP 等入口 |
| `assets/ui/mj/entry_jianghu_codex_01.png` | `entryCodex` | 江湖见闻录入口 |

### 仪式页

| 资产 | token | 主要使用处 |
|---|---|---|
| `assets/ui/mj/ceremony_realm_breakthrough_01.png` | `ceremonyRealmBreakthrough` | 升层 / 突破 banner |
| `assets/ui/mj/ceremony_boss_first_victory_01.png` | `ceremonyBossFirstVictory` | 首通封签 |
| `assets/ui/mj/ceremony_victory_tag_01.png` | `ceremonyVictoryTag` | 战斗胜利 overlay 卡面 |
| `assets/ui/mj/ceremony_red_seal_blend.png` | `ceremonyRedSeal` | 战斗胜利小印章 / 首通封签红印 |
| `assets/ui/mj/ceremony_equipment_resonance_01.png` | `ceremonyEquipmentResonance` | 共鸣晋阶 banner |
| `assets/ui/mj/ceremony_technique_scroll_01.png` | `ceremonyTechniqueScroll` | 心法凝练 / 领悟 |
| `assets/ui/mj/ceremony_offline_retreat_result_01.png` | `ceremonyRetreatResult` | 闭关收功 |
| `assets/ui/mj/ceremony_insight_bamboo_01.png` | `ceremonyInsightBamboo` | 奇遇 / 领悟 |
| `assets/ui/mj/ceremony_failure_ink_01.png` | `ceremonyFailureInk` | 战斗失败 overlay 卡面 |

### 战斗特效 / 氛围 / Boss

| 资产 | token | 主要使用处 |
|---|---|---|
| `assets/ui/mj/fx_gangmeng_strike_blend.png` | `fxGangmengStrike` | 刚猛普通命中 |
| `assets/ui/mj/fx_gangmeng_ultimate_blend.png` | `fxGangmengUltimate` | 刚猛大招 |
| `assets/ui/mj/fx_lingqiao_slash_blend.png` | `fxLingqiaoSlash` | 灵巧普通命中 |
| `assets/ui/mj/fx_lingqiao_ultimate_blend.png` | `fxLingqiaoUltimate` | 灵巧大招 |
| `assets/ui/mj/fx_yinrou_palm_blend.png` | `fxYinrouPalm` | 阴柔普通命中 |
| `assets/ui/mj/fx_yinrou_ultimate_blend.png` | `fxYinrouUltimate` | 阴柔大招 |
| `assets/ui/mj/fx_critical_hit_blend.png` | `fxCriticalHit` | 暴击 |
| `assets/ui/mj/fx_armor_break_blend.png` | `fxArmorBreak` | 高防命中表现 |
| `assets/ui/mj/fx_dodge_shadow_blend.png` | `fxDodgeShadow` | 闪避 |
| `assets/ui/mj/fx_internal_injury_blend.png` | `fxInternalInjury` | 内伤 |
| `assets/ui/mj/overlay_mist_layer_blend.png` | `overlayMistLayer` | 战斗雾层 |
| `assets/ui/mj/overlay_ink_cloud_blend.png` | `overlayInkCloud` | Boss 墨云 |
| `assets/ui/mj/overlay_lantern_glow_blend.png` | `overlayLanternGlow` | 远灯氛围 |
| `assets/ui/mj/overlay_low_health_blend.png` | `overlayLowHealth` | 低血暗角 |
| `assets/ui/mj/ui_big_boss_frame_blend.png` | `bossFrameLarge` | 战斗 Boss 头像外框 |
| `assets/scenes/mj/battle_boss_entrance_bg_01.png` | `battleBossEntranceBg` | Boss 战视觉路由背景 |

## 备用 token 资产

这些资产有 token，但当前没有运行时代码引用：

| 资产 | token | 不接原因 |
|---|---|---|
| `assets/ui/mj/menu_splash_pier_01.png` | `mainMenuPierBg` | 旧主菜单背景，已被 clean 山门图替代，保留备用 |
| `assets/ui/mj/menu_splash_pier_02.png` | `mainMenuPierAltBg` | 右下红色伪印和左下伪字明显，暂不进 UI |
| `assets/ui/mj/menu_mountain_gate_01.png` | `mainMenuMountainBg` | 原始山门图中上部有伪字，运行时用 clean 版 |
| `assets/ui/mj/menu_mountain_gate_wide_01.png` | `mainMenuMountainWideBg` | 中央大伪字明显，暂不进 UI |
| `assets/ui/mj/ui_boss_frame_blend.png` | `bossFrame` | 小 Boss 框备用；当前战斗头像用 `bossFrameLarge` |

## 源图保留资产

这些无 token，不应直接进入 UI；它们是处理版的源图，保留用于后续重做 mask / blend：

- `assets/ui/mj/ceremony_red_seal_01.png`
- `assets/ui/mj/fx_armor_break_01.png`
- `assets/ui/mj/fx_critical_hit_01.png`
- `assets/ui/mj/fx_dodge_shadow_01.png`
- `assets/ui/mj/fx_gangmeng_strike_01.png`
- `assets/ui/mj/fx_gangmeng_ultimate_01.png`
- `assets/ui/mj/fx_internal_injury_01.png`
- `assets/ui/mj/fx_lingqiao_slash_01.png`
- `assets/ui/mj/fx_lingqiao_ultimate_01.png`
- `assets/ui/mj/fx_yinrou_palm_01.png`
- `assets/ui/mj/fx_yinrou_ultimate_01.png`
- `assets/ui/mj/overlay_ink_cloud_01.png`
- `assets/ui/mj/overlay_lantern_glow_01.png`
- `assets/ui/mj/overlay_low_health_01.png`
- `assets/ui/mj/overlay_mist_layer_01.png`
- `assets/ui/mj/ui_big_boss_frame_01.png`
- `assets/ui/mj/ui_boss_frame_01.png`

## 后续建议

- 不建议继续为了“清零备用图”硬接 `menu_splash_pier_02.png` / `menu_mountain_gate_wide_01.png`。
- 如果后续要继续用备用门面图，先做伪字清理，再作为章节封面、活动门面或主菜单 A/B 候选。
- 后续新增 MJ 素材时，继续遵循：原图保留、处理版进入 token、实际 UI 只引用 token。
