# GDD §10 教程引导审计 · 2026-05-24

> 基于实际代码 grep · `lib/features/tutorial/` + `main_menu.dart` 全读 · 0 code 改
> 与 `p5_1_tutorial_audit_2026-05-24.md` 互补（后者有 2 处偏差，见末段修正）

## TL;DR

§10.2 方式2气泡（TutorialBannerCard step 6/7/8）已实装但覆盖仅 3 个系统点；方式1「强制引导」无卡住流程；菜单灰显仅 2/9 系统做了 tutorialStep 门槛；§10.4 二周目字段预留未消费。

## 健康项 ✅

| 项 | 实装位置 | GDD 节点 |
|---|---|---|
| tutorialStep 1-8 完整链 | `tutorial_service.dart` stage_01_01-05→step1-5 / 一流→step6 / 首次奇遇→step7 / 强化≥10→step8 | §10.1 全档 |
| 气泡 hint(方式2) | `TutorialBannerCard` step 6/7/8 · 红点 + 50-100 字 · 文案走 strings.dart(§5.6 ✅) | §10.2 #2 部分 |
| 江湖见闻录百科(方式3) | `BaikeScreen` + `CodexTab` 8 档按 tutorialStep 解锁 · lore 永久可查 | §10.2 #3 |
| 心法按钮门槛 | `main_menu.dart:223` `step < _techniquesUnlockStep` → disabled + lockedHint | §10.3 灰显 |
| 闭关按钮门槛 | `main_menu.dart:174` `tutorialLocked: step < _seclusionUnlockStep` | §10.3 灰显 |
| 无教程弹窗 | TutorialBannerCard 是 InkWell Card · 非 showDialog/AlertDialog | §5.7 ✅ |
| 飞升入口 tooltip | `ascension_models.dart:44` 5 条件全 true 才 enable · 未满足显 missingReasons | §10.3 灰显 |

## 违规项 ⚠

| 项 | 实装位置 | 问题 |
|---|---|---|
| 7 个主菜单按钮无 tutorialStep 门槛 | `main_menu.dart:140-216` 爬塔/心魔/轻功/群战/排行榜/传承面板/角色面板/背包 = step 0 全可进 | §10.3「未解锁系统灰掉/隐藏」违规 |
| `isOnboardingCompleted` 声明无消费 | `save_data.dart:39` 有字段声明 · 无 setter · 无 consumer · 无 skip 路径 | §10.4 二周目跳引导接口空壳 |

## 未实装但 §10 要求 ❌

| 节点 | 缺什么 | 留何阶段 |
|---|---|---|
| §10.2 方式1 强制引导(前30min) | 无卡住玩家的强制流程；narrative 存在但玩家可绕过 Ch1 直进后续 | 1.0 P5.1 |
| §10.1 3-5h 辅修心法 | 无 tutorialStep 9 或 banner 提示 | 1.0 P5.1 |
| §10.1 5-8h 心血结晶/心法相生 | 无专属 tutorialStep 门槛或气泡 | 1.0 P5.1 |
| §10.4 快速开局(二周目跳引导) | `isOnboardingCompleted` 声明未消费 · 无 skip UI 入口 | 1.0 P5.2 |

## 修正 p5_1_tutorial_audit_2026-05-24 偏差

- **偏差①**(p5_1 line 34)：称「未解锁菜单隐藏完全实装」— 实测仅 2/9 主菜单按钮有 tutorialStep 门槛，7 个按钮 step 0 全可进。
- **偏差②**(p5_1 line 41)：称「SaveData 无 tutorialSkipped flag」— 实测 `save_data.dart:39` 有 `isOnboardingCompleted` 字段（语义等价），但未 wired（setter/consumer 均缺失）。

## 挂账

以上 ⚠ + ❌ 项留 1.0 P5.x 拍板实装 · 本 audit 不改代码 · 修留用户拍板
