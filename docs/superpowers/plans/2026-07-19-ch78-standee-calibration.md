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

- [ ] 只修改 `!kReleaseMode` gate 内群战验收 route/seed，不改生产战斗逻辑。
- [ ] 墨影队列全部轮换入场，动态帧/短视频观察结论与复现证据写入本计划；用户留置证据复制到主 checkout `build/visual_acceptance/`。
- [ ] targeted + `flutter analyze`，记录命令与通过数。
- [ ] §8.2 四证据、红线说明、残留风险齐全；生产 bug 只登记不修。
- [ ] 工作区干净，tip commit 前缀为 `[READY]` 或 `[BLOCKED]`。

### 目标 3（弹性尾，未开始）

- [ ] 74 张逐张合成战斗深底读图，记录压缩伪影、白边、透明边损伤判定。
- [ ] 纯只读，零资产与代码改动；逐张清单写入本计划并独立冻结。

## 任务切片

1. [完成] 预热并建立计划、盘点校准映射与可复用验收驱动。
2. [完成] 目标 1：取得校准前双视口证据，测量并写入 10 敌 override。
3. [完成] 目标 1：双视口复验、targeted、analyze、四证据与 `[READY]` 冻结。
4. [待办] 目标 2：定位 debug-only 群战 seed，调整并验证全量轮换。
5. [待办] 目标 2：targeted、analyze、四证据与 `[READY]` 冻结。
6. [待办] 目标 3：若时间富余，完成 74 图逐张静态清单并冻结。

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

## 当前恢复点

- 状态：目标 1 已完成，待本次 `[READY]` commit 后冻结；目标 2 尚未开始。
- 最后完成：10 敌 identity override、透明立绘识别、脚底 fraction、光学 scale/shift 全部接入；20 张校准后真机图逐图 PASS 并留置主 checkout；targeted 289/289、analyze 0。
- 下一步：提交目标 1 `[READY]`、确认工作区干净；随后按序开始目标 2，定位 `!kReleaseMode` 群战验收 seed 并使四名后备墨影全量轮换。
- 已跑验证：`flutter pub get`（exit 0，lock 无漂移）；`dart run build_runner build --delete-conflicting-outputs`（exit 0，参数被当前 build_runner 忽略）；`dart format`；单文件 15/15；battle/route targeted 289/289；`flutter analyze` 0；macOS Debug build exit 0；20/20 route screenshot READY + CGWindowID。
- 阻塞项：无。
