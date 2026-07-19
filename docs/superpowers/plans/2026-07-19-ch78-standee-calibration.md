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

## C3 · 群战墨影队列递补修复（2026-07-19）

### 目标与边界

- 在纯表现层回放右队击杀顺序，把三个可见战位从“固定队列前三项”改为“首发占位，阵亡后后备补同一空位”。
- 战斗引擎全员同时参战语义不变；禁止修改 `battle_state` / strategy / 结算 / `damage_calculator` / `numbers.yaml` / schema。
- 保留 `battle_field.dart` 已有 `stackShift` 错层逻辑原样；无新音效、无大特效。

### 实施切片

1. [x] 合入 `main`；`ort` 零冲突，merge commit 保留主线 K1/C2/spread 等变更。
2. [x] 新增递补契约红测：首发三人阵亡→后备入场、墨影 4→1→0、全队 7→0；场外目标不借 slot 5。
3. [x] 新增 `BattleVisualRoster`，只读 `BattleState.actionLog` 回放击杀顺序，为人物、漂字、受击闪、弹道与特效提供同一战位映射。
4. [x] `BattleField` 以 characterId 持有可见人物；用既有 `damagePopupMs` 留出阵亡灰化/归零拍，拍后才递补；widget key 按 characterId。
5. [x] 共用路径契约：标准 3v3、轻功、心魔均保持原三战位映射。
6. [x] 固定 seed 20260719 真机重跑 7→0，录制动态帧/视频并复制到主 checkout 防蒸发目录。
7. [x] 回填 §8.2 四证据、五项恢复点，新鲜 analyze/targeted 后冻结 `[READY]`。

### 破坏证红留档

- 命令：`flutter test --no-pub test/features/battle/presentation/battle_field_repaint_test.dart test/features/battle/battle_playback_controller_test.dart`
- 修复前结果：**29 pass / 2 fail**。失败均命中旧缺陷：①场外第四敌受击后 `popups[5]` 实际非空；②无 `battle.stageCharacterId.100` key。无编译/fixture 错误。

### 当前恢复点（C3 实施切片）

- 状态：生产表现层修复与契约测已落地；真机动态验收与最终冻结待做。
- 最后完成：可见队列回放、阵亡延时递补、characterId key，以及漂字/受击闪/弹道/特效 slot 映射收口。
- 下一步：跑 macOS Debug 固定 seed 20260719，采样 7→0 全程并逐帧判定标题与战位。
- 已跑验证：破坏证 29/31（红）；修复后核心两文件 31/31；扩展 targeted（含双视口、轻功/心魔、visual route）**90/90 pass**。
- 阻塞项：无。当前未完成项仅真机动态证据、最终 analyze 与交付恢复点。

### C3 目标 1 · 真机动态验收

| 证据 | 可观测状态 | 判定 |
|---|---|---|
| `count_7.png` | 标题 `3 v 7`，首发三敌 + 四名墨影 | PASS |
| `count_6.png` / `count_5.png` / `count_4.png` | 标题依次递减，死者灰化拍后后备补回同一空位，画面仍为三名存活敌人 | PASS |
| `count_3.png` / `count_2.png` / `count_1.png` | 标题与战位人数一致；队列用尽后按 3→2→1 收缩 | PASS |
| `count_0.png` / `04_result.png` | 标题 `3 v 0`，右队战位与墨影均清空，左胜结果一致 | PASS |
| `rotation_slow.mp4` / `contact_slow.png` / `rotation_key_counts.png` | 100 帧、0.3 秒间隔、30 秒全程；标题 7→6→5→4→3→2→1→0，四名后备全部轮换进场 | PASS |

工作树证据位于 `build/visual_acceptance/ch78_mass_battle_rotation_fixed/`；共 116 个文件（100 原始帧 + 视频 + contact sheet + 关键帧 + log），PNG 为 1280×720。`route_slow.log` 含 `VISUAL_ROUTE_READY: battle_mass_battle_stage` 与 `VISUAL_CAPTURE: window_id=25705`。同名 116 文件已复制到主 checkout `/Users/a10506/Desktop/Projects/挂机武侠/build/visual_acceptance/ch78_mass_battle_rotation_fixed/`，防蒸发对账通过。

### C3 目标 1 · §8.2 四证据

- **生产接线**：`BattleScreen` 生产 `ref.listen(battleProvider)` 把 prev/next 交给 `BattlePlaybackController.playActions`；controller 与 `BattleField` 共用 `BattleVisualRoster`。它只读真实 `BattleState.actionLog` 回放可见队列，人物、漂字、受击闪、弹道、效果坐标同源；场外人物不伪造 slot 反馈。非 fixture/孤立组件。
- **Targeted**：①破坏证旧实现 **29 pass / 2 fail**；②修复后核心两文件 **31/31 pass**；③ `flutter test --no-pub test/features/battle/presentation/battle_field_repaint_test.dart test/features/battle/battle_playback_controller_test.dart test/features/battle/presentation/battle_playback_interface_test.dart test/features/battle/presentation/battle_stage_geometry_test.dart test/features/battle/presentation/character_avatar_test.dart test/features/debug/visual_route_test.dart` → **90/90 pass**，含 1280×720 / 1440×900、标准 3v3、轻功、心魔与 visual route。④ `flutter analyze --no-pub` → **No issues found**。⑤ `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_mass_battle_stage` 产出可运行 Debug app，真机路由 READY。
- **红线影响**：零修改战斗引擎、结算、`BattleState`、strategy、`damage_calculator`、`data/*.yaml`、schema/saveVersion；零新数值、音效或玩家文案。数值硬红线、三系锁死、在线=离线、§5.1 反主流项均零影响；`stackShift` spread 逻辑未改。
- **残留风险**：可见队列每次 state 边沿回放本场 actionLog，群战队伍仅 5–7 人，本批未做独立性能 profile；原始帧为 ignored `build/`，已按防蒸发条款双份留存。无数据迁移风险。

## C3 目标 2（弹性尾）· 74 张转码敌人立绘逐张静态目检

方法：从 `2026-07-19-assets-webp-batch2.md` 的 82 张转码 enemies 清单中排除已抽验 8 张，得 74 张。每张统一合成到生产 `battle_mountain_pass_stage_v2` 压暗战斗底图，保留 74 张独立读图与 8 张高分辨率 contact sheet；专检块状/色带伪影、白边、透明边破口、细线断裂与暗部糊损。对观感最易误判的 12 张低 PSNR 样本另做转码前/后并排读图；74/74 alpha 通道与 Git 转码前基线逐像素完全一致。

| # | 资产 | 判定 | 备注 |
|---:|---|---|---|
| 01 | `battle_anye.png` | PASS | 无伪影/白边/alpha 损伤 |
| 02 | `battle_balian.png` | PASS | 同上 |
| 03 | `battle_bandit_b.png` | PASS | 同上 |
| 04 | `battle_bandit_blade.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 05 | `battle_bandit_c.png` | PASS | 无伪影/白边/alpha 损伤 |
| 06 | `battle_black_killer.png` | PASS | 同上 |
| 07 | `battle_caobang_duozhu.png` | PASS | 同上 |
| 08 | `battle_elder_grey.png` | PASS | 同上 |
| 09 | `battle_fu_zhaizhu.png` | PASS | 同上 |
| 10 | `battle_guard_a.png` | PASS | 同上 |
| 11 | `battle_guntou.png` | PASS | 同上 |
| 12 | `battle_guntou_zhu.png` | PASS | 同上 |
| 13 | `battle_huiyi.png` | PASS | 同上 |
| 14 | `battle_jianghu_a.png` | PASS | 同上 |
| 15 | `battle_jianghu_b.png` | PASS | 同上 |
| 16 | `battle_jianghu_qianbei.png` | PASS | 同上 |
| 17 | `battle_kunlun_waimen_shouguan.png` | PASS | 同上 |
| 18 | `battle_lightfoot_changfeng_a.png` | PASS | 同上 |
| 19 | `battle_lightfoot_changfeng_b.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 20 | `battle_lightfoot_changfeng_c.png` | PASS | 无伪影/白边/alpha 损伤 |
| 21 | `battle_lightfoot_pubu_a.png` | PASS | 同上 |
| 22 | `battle_lightfoot_pubu_b.png` | PASS | 同上 |
| 23 | `battle_lightfoot_pubu_c.png` | PASS | 同上 |
| 24 | `battle_lightfoot_shuikou_a.png` | PASS | 同上 |
| 25 | `battle_lightfoot_shuikou_b.png` | PASS | 同上 |
| 26 | `battle_lightfoot_shuikou_c.png` | PASS | 同上 |
| 27 | `battle_lightfoot_yexun_a.png` | PASS | 同上 |
| 28 | `battle_lightfoot_yexun_b.png` | PASS | 同上 |
| 29 | `battle_lightfoot_yexun_c.png` | PASS | 同上 |
| 30 | `battle_lightfoot_zhuke_a.png` | PASS | 最低 PSNR 并排复核无可见退化 |
| 31 | `battle_lightfoot_zhuke_b.png` | PASS | 无伪影/白边/alpha 损伤 |
| 32 | `battle_liukou_a.png` | PASS | 同上 |
| 33 | `battle_lunjian_sanchang_xunluo.png` | PASS | 同上 |
| 34 | `battle_massbattle_canbu_a.png` | PASS | 同上 |
| 35 | `battle_massbattle_canbu_b.png` | PASS | 同上 |
| 36 | `battle_massbattle_canbu_c.png` | PASS | 较小有效边界为原图构图，非转码损伤 |
| 37 | `battle_massbattle_cunfei_b.png` | PASS | 无伪影/白边/alpha 损伤 |
| 38 | `battle_massbattle_cunfei_c.png` | PASS | 同上 |
| 39 | `battle_massbattle_guanqi_a.png` | PASS | 同上 |
| 40 | `battle_massbattle_guanqi_b.png` | PASS | 同上 |
| 41 | `battle_massbattle_guanqi_c.png` | PASS | 同上 |
| 42 | `battle_massbattle_xianjie_a.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 43 | `battle_massbattle_xianjie_b.png` | PASS | 无伪影/白边/alpha 损伤 |
| 44 | `battle_massbattle_xianjie_c.png` | PASS | 同上 |
| 45 | `battle_massbattle_zhenkou_a.png` | PASS | 同上 |
| 46 | `battle_massbattle_zhenkou_b.png` | PASS | 较小有效边界为原图构图，非转码损伤 |
| 47 | `battle_massbattle_zhenkou_c.png` | PASS | 无伪影/白边/alpha 损伤 |
| 48 | `battle_mingmen_a.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 49 | `battle_qingshan.png` | PASS | 无伪影/白边/alpha 损伤 |
| 50 | `battle_ruffian_a.png` | PASS | 同上 |
| 51 | `battle_seng_huiyi.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 52 | `battle_shafei_a.png` | PASS | 无伪影/白边/alpha 损伤 |
| 53 | `battle_shaonian.png` | PASS | 同上 |
| 54 | `battle_shiye.png` | PASS | 同上 |
| 55 | `battle_songshan_daozong_dizi.png` | PASS | 同上 |
| 56 | `battle_songshan_shouguan.png` | PASS | 同上 |
| 57 | `battle_thug_a.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 58 | `battle_thug_b.png` | PASS | 无伪影/白边/alpha 损伤 |
| 59 | `battle_thug_c.png` | PASS | 同上 |
| 60 | `battle_tongguan_shoujiang.png` | PASS | 同上 |
| 61 | `battle_tower_boss_05.png` | PASS | 同上 |
| 62 | `battle_tower_boss_10.png` | PASS | 同上 |
| 63 | `battle_tower_boss_15.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 64 | `battle_tower_boss_20.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 65 | `battle_tower_boss_25.png` | PASS | 无伪影/白边/alpha 损伤 |
| 66 | `battle_tower_boss_30_v2.png` | PASS | 同上 |
| 67 | `battle_umbrella.png` | PASS | 原图即为低饱和半透观感；并排确认非转码泛白 |
| 68 | `battle_wulin_bazhu.png` | PASS | 无伪影/白边/alpha 损伤 |
| 69 | `battle_xiliang_bazhu.png` | PASS | 同上 |
| 70 | `battle_xiliang_sandizi.png` | PASS | 同上 |
| 71 | `battle_xiliangbazhu.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 72 | `battle_xiliangboss.png` | PASS | 无伪影/白边/alpha 损伤 |
| 73 | `battle_zhongzhou_lunjian_xianfeng.png` | PASS | 低 PSNR 并排复核无可见退化 |
| 74 | `battle_zuo_hufa.png` | PASS | 无伪影/白边/alpha 损伤 |

证据位于 ignored `build/visual_acceptance/ch78_assets_webp_74_inspection/`：74 张独立合成图、8 张 contact sheet、2 张低 PSNR before/after 对照、manifest。结论：**74/74 PASS，0 WARN，0 FAIL**；未发现压缩伪影、白边或透明边损伤。本目标纯只读 `assets/`，零生产资产改动。

### C3 目标 2 · §8.2 四证据

- **生产接线**：目检对象是 `assets/enemies/` 下被真实 `EnemyDef.iconPath` → `CharacterAvatar` 生产战场路径消费的同路径资产；合成底图为生产山口战场资产，不是重画 fixture。本目标只读，因而生产接线不发生新改动。
- **Targeted**：`flutter test --no-pub test/data/webp_in_png_decode_test.dart test/tools/asset_audit_test.dart test/data/pubspec_asset_declaration_test.dart` → **9/9 pass**；清单对账 82-8=74，独立合成图 74/74，alpha 逐像素对账 74/74 完全相同。
- **红线影响**：纯只读检查，`assets/` 与一切生产文件零 diff；数值硬红线、三系锁死、在线=离线、§5.1、schema/saveVersion 均零影响。
- **残留风险**：判定针对战斗实际显示尺度与深底；未做像素级放大印刷用途评估（超出游戏战场资产口径）。目检证据位于 ignored `build/`，不入库。

## C3 最终恢复点

- **状态**：目标 1 生产表现层递补修复完成；目标 2 弹性尾 74 张逐张目检完成；plan 与实现已全部提交，分支 tip 以 `[READY]` 冻结。
- **最后完成**：固定 seed 20260719 真机 7→0 全程通过且证据已复制主 checkout；74/74 转码立绘 PASS、0 WARN、0 FAIL。
- **下一步**：Claude 按 §8.2 合并 Gate 审核 `codex/ch78-standee-calibration` tip；本分支冻结后不再写入。
- **已跑验证**：破坏证 29 pass / 2 fail；最终 battle/visual targeted 90/90 pass；资产 targeted 9/9 pass；`flutter analyze --no-pub` 0 issue；macOS 真机 100 帧/30 秒动态验收 PASS；74/74 静态目检 PASS。
- **阻塞项**：无。残留风险已分别写入两目标 §8.2，无需人类拍板点。
