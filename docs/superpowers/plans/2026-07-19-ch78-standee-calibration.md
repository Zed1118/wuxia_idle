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

- [ ] 10 个敌 id 逐个进入 `_stageStandeeFootFraction` / `_stageStandeeOpticalProfile` 等实际生产消费映射；默认值合格者须逐 id 在本计划写豁免理由。
- [ ] 生产接线证据：记录 `_StageCharacterStandee` → `_resolvedStageIconPath` → 脚底/光学校准映射的真实入口与消费方式。
- [ ] 10 条 `battle_audit_stage_07_01..08_05` 均在 1280×720、1440×900 真机截图验收，逐图记录 PASS/FAIL、脚底贴地、悬浮/陷地与同屏光学尺寸；需留置截图复制到主 checkout `build/visual_acceptance/`。
- [ ] targeted：至少 `test/features/battle/presentation/character_avatar_test.dart` 与直接相关 battle 视觉测试；记录完整命令与通过数。
- [ ] `flutter analyze` 为 0 issue。
- [ ] 编辑过的 Dart 文件已 `dart format`。
- [ ] 红线影响：说明未触 numbers/data/schema/saveVersion/公式/结算，布局像素不属于游戏数值红线；核对无中文文案与游戏数值散写。
- [ ] 残留风险列明。
- [ ] 工作区干净，tip commit 前缀为 `[READY]`；若需拍板则 `[BLOCKED]`。

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

1. [进行中] 预热并建立计划、盘点校准映射与可复用验收驱动。
2. [待办] 目标 1：取得校准前双视口证据，测量并写入 10 敌 override。
3. [待办] 目标 1：双视口复验、targeted、analyze、四证据与 `[READY]` 冻结。
4. [待办] 目标 2：定位 debug-only 群战 seed，调整并验证全量轮换。
5. [待办] 目标 2：targeted、analyze、四证据与 `[READY]` 冻结。
6. [待办] 目标 3：若时间富余，完成 74 图逐张静态清单并冻结。

## 目标 1 · 10 敌校准记录

| 敌 id | 路由 | 脚底 fraction | optical scale / shift | 豁免理由或校准依据 |
|---|---|---:|---|---|
| `monan_mazei` | `battle_audit_stage_07_01` | 待测 | 待测 | 待验 |
| `hanhai_shadao` | `battle_audit_stage_07_02` | 待测 | 待测 | 待验 |
| `gucheng_shuwei` | `battle_audit_stage_07_03` | 待测 | 待测 | 待验 |
| `beidi_shuzu` | `battle_audit_stage_07_05` | 待测 | 待测 | 待验 |
| `fengxue_shaoqi` | `battle_audit_stage_08_01` | 待测 | 待测 | 待验 |
| `beipai_youshao` | `battle_audit_stage_08_02` | 待测 | 待测 | 待验 |
| `beipai_zongjiang` | `battle_audit_stage_08_04` | 待测 | 待测 | 待验 |
| `huiyiren_beijing` | `battle_audit_stage_07_04` | 待测 | 待测 | 待验 |
| `huiyiren_saibei` | `battle_audit_stage_08_03` | 待测 | 待测 | 待验 |
| `huiyiren_final` | `battle_audit_stage_08_05` | 待测 | 待测 | 待验 |

## 目标 1 · 双视口判定表

| 路由 | 1280×720 | 异常点 | 1440×900 | 异常点 | 留置证据 |
|---|---|---|---|---|---|
| `battle_audit_stage_07_01` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_07_02` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_07_03` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_07_04` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_07_05` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_08_01` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_08_02` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_08_03` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_08_04` | 待验 | — | 待验 | — | 待生成 |
| `battle_audit_stage_08_05` | 待验 | — | 待验 | — | 待生成 |

## §8.2 四证据

### 生产接线证据

待目标完成后填写。

### Targeted 验证

待目标完成后填写命令、通过数与时间。

### 红线影响说明

目标 1 仅允许改战斗表现层立绘布局校准；不触 `numbers.yaml`、`data/*.yaml`、schema/saveVersion、结算与公式层。目标 2 仅允许改 `!kReleaseMode` 验收 seed/route。目标 3 纯只读。

### 残留风险

待目标完成后填写。

## 当前恢复点

- 状态：目标 1 进行中（WIP）。
- 最后完成：已核对 `main/origin/main/HEAD=db9151d1`，创建隔离 worktree 与分支；`flutter pub get` 成功且 `pubspec.lock` 无漂移；`dart run build_runner build --delete-conflicting-outputs` 成功（build_runner 提示该参数已移除并忽略，仍 exit 0，写出 128 outputs）。
- 下一步：盘点三份校准映射与现有视觉驱动，采集 10 敌校准前双视口证据并确定逐 id 参数。
- 已跑验证：`flutter pub get`（exit 0）；`dart run build_runner build --delete-conflicting-outputs`（exit 0）。
- 阻塞项：无。
