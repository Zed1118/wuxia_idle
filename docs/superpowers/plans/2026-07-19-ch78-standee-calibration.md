# Ch7/Ch8 立绘校准与验收遗留清理

> 日期：2026-07-19
>
> 基点：`main@db9151d1`
>
> 分支：`codex/ch78-standee-calibration`
>
> worktree：`.worktrees/ch78-standee-calibration`

## 目标序列

1. 为 Ch7/Ch8 新增 10 敌补齐战斗立绘脚底锚点与光学校准，并完成 10 条 battle audit route 的 1280×720 / 1440×900 真机验收。
2. 仅在目标 1 `[READY]` 后，调整 `!kReleaseMode` 验收 seed/route，使群战墨影队列全量递补并动态确认。
3. 仅在前两目标完成且时间富余时，逐张静态目检剩余 74 张 WebP 转码立绘；纯只读。

未开始的后续目标不算欠账；每个目标独立冻结、独立 `[READY]`。

## 验收标准（CLAUDE.md §8.2）

### 目标 1

- [x] 10 个敌 id 逐个进入 `_battleStandeeOverrides`、`_stageStandeeFootFraction` 与 `_stageStandeeOpticalProfile`；无默认值豁免。
- [x] 生产接线证据：记录 `_StageCharacterStandee` → `_resolvedStageIconPath` → 脚底/光学校准映射的真实入口与消费方式。
- [x] 10 条 `battle_audit_stage_07_01..08_05` 均在 1280×720、1440×900 真机截图验收，逐图记录 PASS/FAIL、脚底贴地、悬浮/陷地与同屏光学尺寸；最终证据已复制到主 checkout `build/visual_acceptance/ch78_standee_calibration/`。
- [x] targeted：`character_avatar_test.dart` 单文件 15/15；battle presentation + visual route 套件 289/289。
- [x] `flutter analyze` 为 0 issue。
- [x] 编辑过的 Dart 文件已 `dart format`。
- [x] 红线影响：未触 numbers/data/schema/saveVersion/公式/结算，布局像素不属于游戏数值红线；无新增中文 UI 文案或游戏数值。
- [x] 残留风险列明。
- [x] 工作区干净，目标 1 tip commit 前缀为 `[READY]`。

### 目标 2（目标 1 `[READY]` 后）

- [x] 只修改 `!kReleaseMode` gate 内群战验收 route/seed，不改生产战斗逻辑。
- [x] 已取得完整动态帧/短视频并判定 **异常**：首发三敌阵亡后，四名存活后备未递补至三个战位；用户留置证据已复制到主 checkout `build/visual_acceptance/ch78_mass_battle_rotation/`。
- [x] targeted 39/39 + `flutter analyze` 0 issue，命令与通过数见下。
- [x] §8.2 四证据、红线说明、残留风险齐全；生产 bug 仅登记，未越界修复。
- [x] 工作区干净，tip commit 前缀为 `[BLOCKED]`。

### 目标 3（弹性尾，未开始）

- [ ] 74 张逐张合成战斗深底读图，记录压缩伪影、白边、透明边损伤判定。
- [ ] 纯只读，零资产与代码改动；逐张清单写入本计划并独立冻结。

## 任务切片

1. [完成] 预热并建立计划、盘点校准映射与可复用验收驱动。
2. [完成] 目标 1：取得校准前双视口证据，测量并写入 10 敌 override。
3. [完成] 目标 1：双视口复验、targeted、analyze、四证据与 `[READY]` 冻结。
4. [完成] 目标 2：固定 debug-only seed、构造耐打左队与低输出七敌，自动播放并捕获完整轮换窗口。
5. [完成] 目标 2：确认生产表现层未递补，登记复现、targeted、analyze 与四证据，以 `[BLOCKED]` 冻结。
6. [未开始] 目标 3：因目标 2 未达 `[READY]`，按序列纪律停止；74 图目检不算欠账。

## 目标 1 · 10 敌校准记录

| 敌 id | 路由 | 脚底 fraction | optical scale / shift | 豁免理由或校准依据 |
|---|---|---:|---|---|
| `monan_mazei` | `battle_audit_stage_07_01` | 0.988 | 1.00 / +0.060 | alpha 脚底与水平重心实测；双视口贴地，长枪与全身完整 |
| `hanhai_shadao` | `battle_audit_stage_07_02` | 0.974 | 1.02 / -0.015 | 有效人物高度略短，补 1.02；双视口贴地 |
| `gucheng_shuwei` | `battle_audit_stage_07_03` | 0.977 | 0.98 / +0.010 | 有效人物高度略长，收至 0.98；双脚与状态牌基准一致 |
| `beidi_shuzu` | `battle_audit_stage_07_05` | 0.975 | 0.98 / 0 | 宽体构图完整，双视口无陷地 |
| `fengxue_shaoqi` | `battle_audit_stage_08_01` | 0.964 | 1.03 / +0.020 | 有效人物高度偏短，补 1.03；脚底贴地 |
| `beipai_youshao` | `battle_audit_stage_08_02` | 0.965 | 1.01 / -0.040 | alpha 重心偏右，左移校正；双视口贴地 |
| `beipai_zongjiang` | `battle_audit_stage_08_04` | 0.970 | 1.00 / 0 | 原有效高度在目标带内；双视口贴地 |
| `huiyiren_beijing` | `battle_audit_stage_07_04` | 0.981 | 0.99 / -0.030 | 同源三态统一近 1.0 尺度，按各自重心微移；遮脸构图完整 |
| `huiyiren_saibei` | `battle_audit_stage_08_03` | 0.976 | 1.00 / -0.050 | 同源三态统一近 1.0 尺度；披风与双脚完整 |
| `huiyiren_final` | `battle_audit_stage_08_05` | 0.991 | 0.99 / -0.035 | 同源三态统一近 1.0 尺度；最终态下摆与脚底完整 |

脚底 fraction 取原 1024×1536 RGBA alpha 非零包围盒底边除以画布高度，并按旧 79 图体例保留三位小数。水平 shift 取 alpha 包围盒重心相对画布中心的补偿；scale 将有效人物高度收敛到旧敌约 0.94–0.95 的光学带，再由真机目检确认。

## 目标 1 · 双视口判定表

| 路由 | 1280×720 | 异常点 | 1440×900 | 异常点 | 留置证据 |
|---|---|---|---|---|---|
| `battle_audit_stage_07_01` | PASS | 脚底贴地；长枪/头脚完整；与旧敌尺度协调 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_07_01/{1280x720,1440x900}/battle_audit_stage_07_01.png` |
| `battle_audit_stage_07_02` | PASS | 脚底贴地；刀客完整；无悬浮/陷地 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_07_02/{1280x720,1440x900}/battle_audit_stage_07_02.png` |
| `battle_audit_stage_07_03` | PASS | 双脚落位清楚；人物高度与左侧旧立绘参照协调 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_07_03/{1280x720,1440x900}/battle_audit_stage_07_03.png` |
| `battle_audit_stage_07_04` | PASS | 北京态遮脸符合设定；披风下摆与脚底完整 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_07_04/{1280x720,1440x900}/battle_audit_stage_07_04.png` |
| `battle_audit_stage_07_05` | PASS | 宽体人物不挤状态牌；双脚贴地 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_07_05/{1280x720,1440x900}/battle_audit_stage_07_05.png` |
| `battle_audit_stage_08_01` | PASS | 下摆/双脚完整；与旧敌光学高度协调 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_08_01/{1280x720,1440x900}/battle_audit_stage_08_01.png` |
| `battle_audit_stage_08_02` | PASS | 重心居中；脚底贴地；武器不裁切 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_08_02/{1280x720,1440x900}/battle_audit_stage_08_02.png` |
| `battle_audit_stage_08_03` | PASS | 塞北态遮脸符合设定；披风与双脚完整 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_08_03/{1280x720,1440x900}/battle_audit_stage_08_03.png` |
| `battle_audit_stage_08_04` | PASS | 总将站姿完整；脚底贴地；尺度协调 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_08_04/{1280x720,1440x900}/battle_audit_stage_08_04.png` |
| `battle_audit_stage_08_05` | PASS | 最终态露真容；下摆/双脚完整；无陷地 | PASS | 同左，无视口漂移 | `.../battle_audit_stage_08_05/{1280x720,1440x900}/battle_audit_stage_08_05.png` |

表中 `...` = 主 checkout `build/visual_acceptance/ch78_standee_calibration`。留置目录共 20 PNG、20 route log、2 张 contact sheet；每份 log 均含对应 `VISUAL_ROUTE_READY` 与 `VISUAL_CAPTURE: window_id`，PNG 实物尺寸为 1280×720 或 1440×900。

## §8.2 四证据

### 生产接线证据

目标 1 已接真实生产路径：`_StageCharacterStandee.build` 从 `_resolvedStageIconPath(character)` 取最终路径；10 个直用 RGBA 资产以 identity override 进入 `_battleStandeeOverrides`，`_isTransparentBattleStandee` 由同一映射识别后选择 `BoxFit.contain` 且不套旧图 `ShaderMask`。随后 `_stageStandeeFootFraction` 决定脚底到公共 0.95 基准线的纵向位移，`_stageStandeeOpticalProfile` 决定绕脚底缩放与水平重心补偿。动态 `battle_audit_stage_07_01..08_05` 由真实 `stages.yaml` 经 `StageBattleSetup.buildEnemyTeam` 消费上述路径，非 gallery/fixture 孤立组件。

### Targeted 验证

- `flutter test --no-pub test/features/battle/presentation/character_avatar_test.dart` → **15/15 pass**（24.0s）。
- `flutter test --no-pub test/features/battle/presentation test/features/debug/visual_route_test.dart test/features/debug/application/visual_acceptance_plan_test.dart` → **289/289 pass**（52s）。覆盖 battle presentation 全目录、双视口播放布局、standee 映射/光学 transform、动态 visual route 解析与验收计划。
- `flutter analyze` → **No issues found**（55.9s）。
- `flutter build macos --debug --dart-define=HITBOX_DEBUG=false` → exit 0，供最终真机矩阵使用。
- `dart format lib/features/battle/presentation/character_avatar.dart` → 1 file formatted。

### 红线影响说明

目标 1 仅改 `character_avatar.dart` 的资产身份与布局像素校准。未改 `numbers.yaml`、任何 `data/*.yaml`、schema/saveVersion、结算、伤害/血量/真气公式、三系门槛或在线/离线规则；无反主流机制影响。新增小数仅为 alpha 画布脚底 fraction、光学 scale/shift，属于表现布局，不是游戏数值；未新增中文 UI 文案（仅代码注释），未新增日志。

### 残留风险

- 本目标验证的是 10 条 route 的冻结开场帧；冲锋/受击动画沿用同一 standee transform，已有 battle presentation 套件覆盖结构，但未逐敌录制动态短视频。
- 截图与 route log 按要求留在主 checkout 的 ignored `build/visual_acceptance/ch78_standee_calibration/`，不进入 git；若主 checkout 的 `build/` 被人工清理，需按表中 route 重采。
- 10 图均为 1024×1536 RGBA，当前 identity override 是有意接入而非资产复制；未来若改名或替换画布，需同步重新测 alpha 包围盒。

## 目标 2 · 群战墨影队列动态判定

### 验收驱动调整

- `battle_mass_battle_stage` 固定 `seed: 20260719` 并设 `autoStart: true`，避免人工点击时序污染。
- 左队三人 `HP=20,000 / 内力=3,000 / 装备攻击=500`；右队七人 `HP=12,000 / attackPowerMultiplier=0.05`。左队足够耐打且输出留有观察窗口，右队七人能被逐个清完；所有字段均在正式红线内。
- 该路由由 `main.dart:32` 的 `if (!kReleaseMode)` 短路进入，release 不可达；未改任何生产策略、公式或队伍配置。

### 动态观察表

| 证据 | 画面状态 | 判定 |
|---|---|---|
| `01_initial_3v7.png` | 节拍 10，标题 `战斗 3 v 7`；首发三敌可见，右侧四名墨影排队 | PASS：验收初态正确 |
| `02_blocked_3v4.png` | 节拍 28，标题 `战斗 3 v 4`；画面中的三名首发敌均为 `0/12K` 灰态，四名存活后备无一进入战位 | **FAIL：递补未发生** |
| `03_offscreen_3v2.png` | 标题已降为 `战斗 3 v 2`，画面仍只显示三名死亡首发；战斗继续结算不可见后备 | **FAIL：后备在场外参与/被结算** |
| `04_result.png` | 标题 `战斗 3 v 0`，56 拍左胜 | PASS：七敌均被战斗层结算；不能证明表现层轮换 |
| `rotation_slow.mp4` / `contact_slow.png` | 约 30 秒全程；标题按 7→6→5→4→3→2→1→0 递减 | **异常**：全量结算正常，但四名后备从未替换死亡首发立绘 |

表中证据根目录 = 主 checkout `build/visual_acceptance/ch78_mass_battle_rotation/`；`route_slow.log` 含 `VISUAL_ROUTE_READY` 与 `VISUAL_CAPTURE: window_id=25480`。原始采样为 100 帧、0.3 秒间隔、Retina 实物 2560×1440（逻辑视口 1280×720）；留置四张关键帧、contact sheet、MP4 与 route log。

### 异常复现与定位

1. 启动 Debug app：`wuxia_idle --visual-route=battle_mass_battle_stage`。
2. 无需点击，固定 seed 自动开战；观察标题由 `3 v 7` 降至 `3 v 4`。
3. 此时三个可见敌均已死亡变灰，但四个存活后备没有进入战位；继续观察可见标题降至 `3 v 0` 并正常左胜。

生产表现层 `BattleField` 固定遍历 `state.rightTeam[0..2]`（`battle_field.dart:69-75`），没有按存活者筛选或重排；墨影数又固定取 `state.rightTeam.length - 3`（`:110-122`），不会随已阵亡人数减少。动态证据与这两处接线一致。按本单边界，本次只记录、不修改生产层。

## 目标 2 · §8.2 四证据

### 生产接线证据

运行入口为 `main.dart:32-38` 的 `!kReleaseMode` visual route gate，随后 `visual_route_host.dart:417-425` 以固定 seed / 自动开战调用 `BattleScenarioData.scenarioMassBattleStage`；该 fixture 进入真实 `ScenarioLauncher`、`BattleScreen` 和 `BattleField`。异常落点是生产 `BattleField` 对右队前三项的固定渲染，不是 gallery 假图或截图脚本误差。

### Targeted 验证

- `flutter test --no-pub test/features/debug/visual_route_test.dart test/features/battle/presentation/battle_field_repaint_test.dart` → **39/39 pass**。覆盖 visual route 构造以及群战 3v7 “六个完整人物 + 墨影队列”静态结构。
- `flutter analyze` → **No issues found**（19.6s）。
- `flutter build macos --debug` → exit 0，供动态验收使用。
- `dart format lib/features/debug/presentation/battle_test_menu.dart lib/features/debug/presentation/visual_route_host.dart` → 2 files，0 additional changes。

### 红线影响说明

目标 2 仅改 debug visual route fixture 与启动参数：未改 `numbers.yaml`、`data/*.yaml`、schema/saveVersion、生产结算或伤害公式。fixture 的 `HP=20,000`、内力 `3,000`、装备攻击 `500` 均不超过玩家红线；敌 HP `12,000` 低于 Boss 现行红线。`attackPowerMultiplier=0.05` 只用于不可由 release 到达的验收队伍，不改变正式数值。

### 残留风险 / 拍板点

- **阻塞结论**：目标要求“墨影队列全部轮换入场”，实测生产表现层没有递补语义，无法在只动 debug seed/route 的边界内达成，目标 2 冻结为 `[BLOCKED]`。
- **拍板点**：是否另开生产修复单，授权调整 `BattleField` 的可见存活者选择、战位索引/动效 key 与墨影剩余数；修复后应复用本固定 seed 重新跑 7→0 全程。
- 当前 targeted 只守静态 3v7 初态，未表达“首发阵亡后递补”契约；这是后续生产修复应补的回归测试。
- 用户证据位于 ignored `build/`，如被人工清理，需用上述固定 route 复采。

## 当前恢复点

- 状态：目标 1 已由 `f103acd5 [READY]` 冻结；目标 2 动态判定异常并由本次 `[BLOCKED]` commit 冻结；目标 3 未开始且不算欠账。
- 最后完成：debug-only 固定 seed / 耐打 seed / 自动开战接线；100 帧全程动态采样确认七敌均结算，但四名后备不递补；关键证据已复制到主 checkout。
- 下一步：停在目标 2，等待是否授权另开生产表现层修复单。未获拍板前不开始目标 3。
- 已跑验证：目标 1 的 15/15、289/289、analyze 0 与 20/20 双视口仍见上；目标 2 targeted 39/39、`flutter analyze` 0、macOS Debug build exit 0、动态 100 帧/30 秒并完成逐段判定。
- 阻塞项：`BattleField` 固定渲染右队前三项且墨影数固定为总长度减三，导致存活后备不进入战位；需生产层修改授权。
