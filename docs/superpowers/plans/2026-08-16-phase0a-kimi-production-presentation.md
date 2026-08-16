# Phase 0A 第七批 debug 正式表现层首切片：Kimi 执行计划

> 基线：第六批 `[READY] 2e688b08`；分支 `feat/phase0a-kimi-production-presentation`，独立 worktree。
> 上游口径（冻结，不再扩展调查）：
> - 派单：`docs/dispatch/packages/2026-08-16_phase0a_kimi_production_presentation.md`
> - 主计划：`docs/superpowers/plans/2026-08-16-phase0a-production-batch7-presentation.md`（切片 1–3 已完成）
> - 实装审计：`docs/audit/phase0a-production-presentation-implementation-audit-2026-08-16.md`（下称审计档，含全部 file:line 证据）
>
> 本档只做 Kimi 侧执行切片与恢复点；视觉方向/事件映射/验收以上游两档为准，不复述。

## 目标

新增仅 debug/profile 可达的纯 Flutter 单角色水墨 ARPG 战斗屏（`VisualRoute.phase0aBattlePlayable`），真实调用 `Phase0aProductionFlowAssembler` 生成 flow、真实消费 `Phase0aWaveBattleFlow.state/events`；禁止假战斗状态/假伤害/定时脚本演出；不切任何生产入口。

## 验收标准（源自派单，逐条对应验证命令）

1. `data/phase0a_debug_battle.yaml`：仅 debug fixture 用，typed loader 启动期 fail-fast；不进 `numbers.yaml`，不新增存档/schema。
2. `lib/features/battle/presentation/phase0a/` 首切片：controller 固定拍 + 事件 seq 去重；stage 双视口（1280×720 / 1440×900）安全区无裁切；actor 正式立绘 + 接地阴影 + 名称 + 持续血条 + 玩家真气；VFX 全事件只读不重算；HUD 等宽 Q/R 五态印；波次横幅 + 唯一终局封签。
3. debug fixture：真实 `BattleCharacter` / 真实 `NumbersConfig` / 显式 `Random(seed)` / 真实 assembler；visual roster 独立于 domain。
4. `VisualRoute.phase0aBattlePlayable` + host switch；release 仍由 `main.dart:38-45` `!kReleaseMode` 门控；不接 `stage_entry_flow` 或其他生产入口。
5. 中文 UI 文案集中 `UiStrings`；布局/颜色/时长 token 集中 presentation tokens/fixture。
6. 红测先行并单独 commit，覆盖派单「测试与证伪」1–7 全部项。

## 禁止项（执行全程有效）

不改 GDD/CLAUDE/PROGRESS、不改 probe、不生成/重绘/转码资产；不切生产路由；不接奖励/掉落/成长/伤势/存档；不删旧 3v3；不新增依赖；不复制公式；不在 Dart 硬编码战斗调优数值或中文文案；不 push/部署；新表现层不得 import 旧 `battle_state.dart`、`BattleAI`、`DefaultGroundStrategy`、`BattleScreen`、probe/Flame；debug fixture 之外不得 import YAML loader/GameRepository。

## 任务切片与 commit 节奏

### 切片 A：红测（commit 2，单独保留）

红测先行，只写测试不实装，全部应红：

| 测试文件 | 覆盖派单证伪项 |
|---|---|
| `test/features/battle/presentation/phase0a/phase0a_stage_transform_test.dart` | ① world→screen 双视口安全区、y 深度 scale/排序确定性 |
| `test/features/battle/presentation/phase0a/phase0a_event_mapping_test.dart` | ② 事件 seq 去重/乱序按 seq 消费/终局后不新增反馈 |
| `test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart` | ③ 真实 flow：移动/血条来自 state/伤害数字等于 event/Q 拉怪/R 群伤/两波横幅/唯一终局；④ 全体存活敌人名称血条常显、非零伤害必有 popup、不以 widget 自算血量 |
| `test/features/battle/presentation/phase0a/phase0a_skill_seals_test.dart` | ⑤ 技能五态亮暗/CD/真气原因可读、禁用语义、Tab/Enter/Space、WASD/普攻/Q/R |
| `test/features/debug/visual_route_phase0a_test.dart` | ⑥ route parse/host 注册；生产入口文件无 `phase0aBattlePlayable`/新屏引用 |
| 源码契约断言（并入上述文件或独立 contract 测试） | ⑦ 禁用 import 清单 grep 守卫 |

### 切片 B：fixture + loader + controller（commit 3）

- `data/phase0a_debug_battle.yaml`：竞技场边界、固定拍长、玩家/AI 射程/角度/CD、Q/R 半径/气耗/CD、角色初态、两波敌人、显式 seed。竞技场调优取值缺口已登记（审计档 §4 末），取值由主窗口拍板后再填，本切片先用占位待拍板标记不私自定值。
- debug fixture + typed YAML loader（启动期 fail-fast 校验）：YAML→真实 `BattleCharacter` + 真实 `NumbersConfig` + 显式 `Random(seed)` → `Phase0aProductionFlowAssembler.assemble`。
- `lib/features/battle/presentation/phase0a/phase0a_tick_controller.dart`：固定拍自驱循环调 `flow.advance`、按键快照→`Phase0aPlayerCommand`、事件按 seq 单调消费去重、终局停止；测试可手动单步、不依赖真实计时。
- 对应红测转绿：event_mapping（seq 去重部分）+ controller 单步。

### 切片 C：stage + HUD + VFX（commit 4）

新文件（落 `lib/features/battle/presentation/phase0a/`，命名可对齐审计档 §6 建议微调）：

- `phase0a_stage.dart`：world bounds→双视口安全区显式映射、y 越大越靠前 + scale 越大、按脚底 y 稳定排序、接地阴影。
- `phase0a_actor_standee.dart`：正式立绘（`WuxiaImage`+`asset_fallback`，玩家=`assets/characters/battle_founder_v2.png`，敌人=根 `assets/enemies/` 正式资产）+ 名称 + 全体持续 `HpBar` + 玩家真气 `MeridianBar`；不用几何人形。
- `phase0a_vfx_controller.dart`：seq 去重事件分发 → `DamagePopup`（所有非零 HitLanded/Q/R outcomes，暴击更高层级）/ `HitFlash` / `ScreenFlashOverlay` / 远距命中 `ProjectileTrail` 掌风（按事件 actor/target 位置差阈值纯视觉分支）/ Q 涡旋拉拢 / R 径向墨爆 / `Phase0aEnemyDefeated` 墨散（精英更重）；池化沿用 ≤48 伤害标签 / ≤160 反馈上限；禁逐标签 `saveLayer`。
- `phase0a_skill_seals.dart`：等宽 Q/R 印，ready/cooldown/qi/casting/down 五态全渲染（生产只会出三态，防御渲染），CD 秒数/真气门槛从事件载荷取，鼠标 + Tab/Enter/Space + 键盘 Q/R + semantics。
- `phase0a_wave_banner.dart`、`phase0a_outcome_seal.dart`：波次横幅（1-based，state 无波次字段由 UI 从事件维护）、全场唯一胜/败封签。
- `phase0a_visual_roster.dart`：actor id→UiStrings 名称/正式资产/精英语义，不污染 domain。
- `phase0a_presentation_tokens.dart`：集中布局/颜色/时长 token，零魔法数散落。
- `UiStrings` 增补全部新中文文案（引用前甄别旧 3v3 专用串）。
- 复用白名单：`BattleSceneBackground`、`HpBar`、`DamagePopup`、`WuxiaImage`、`MeridianBar`、`HitFlash`、`ScreenFlashOverlay`、`ProjectileTrail`、水墨 token、`screen_shake`；禁用清单见上。
- 对应红测转绿：stage_transform + skill_seals + battle_screen 主体。

### 切片 D：visual route 接线（commit 5）

- `lib/features/debug/application/visual_route.dart:3`：`VisualRoute` 枚举追加 `phase0aBattlePlayable`（parse 往返回归自动覆盖）。
- `lib/features/debug/presentation/visual_route_host.dart:278`：`buildVisualTarget` 穷举 switch 加 case（漏加 analyze 报错 = 编译期强制接线）。
- `phase0a_battle_screen.dart` 组装完整屏：键盘 WASD/普攻/Q/R + 鼠标印按钮 + 键位提示 + semantics + 波次横幅/终局封签挂载。
- 确认 `lib/main.dart:38-45` 门控不动；生产入口文件无新屏引用。
- 对应红测转绿：visual_route_phase0a。

### 切片 E：全验证（commit 6 → `[READY]`）

- `flutter test --no-pub test/features/battle/domain/phase0a test/features/battle/application/phase0a test/features/battle/presentation/phase0a`（基线 150/150 不回归 + 新测全绿；红测 commit 保留证据）。
- `test/features/debug/visual_route*` targeted。
- `flutter test --no-pub test/combat/damage_calculator_test.dart`。
- nested probe 8/8 只回归不改。
- `flutter analyze --no-pub` 0 issue、`git diff --check` 干净、禁用依赖/import 搜索复核。
- 不自行声称视觉终验通过；1280×720 / 1440×900 真机抓图与目检由主窗口执行返修。
- 交付按 §8.2 四项证据（生产接线 / targeted test / 红线影响 / 残留风险）写进恢复点，tip 打 `[READY]`。

## 当前恢复点

- **状态**：计划档已创建并 commit（本 commit），等待进入红测。
- **最后完成**：读取派单 + 主计划 + 审计档 + CLAUDE.md；切片 A–E 划分与文件/测试清单冻结于上文。
- **下一步**：切片 A——按上表新建 5+ 个红测文件并单独 commit（全部应红）。
- **已跑验证**：无（仅文档切片；`git status` 干净）。
- **阻塞项**：`data/phase0a_debug_battle.yaml` 竞技场调优取值（射程/半径/CD/气耗等）无生产配置源，需主窗口拍板（审计档 §4 已登记）；取值到位前红测与 loader 结构可先行，具体数值字段待填。
