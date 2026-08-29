# M2 移动参照与进步斩手感修复计划

## 结果合同

- 单一目标：修复真人在 `stage_01_02` 观察到的两项 M2 手感阻断：
  世界中段角色与静态背景同时不动造成的“移动卡住”，以及进步斩同拍叠加
  普通移动并缺少 0.18 秒位移过程造成的“被敌人拉扯”。
- 权威验收门：生产战斗背景随 camera offset 产生视差；按住方向键 10 秒时
  玩家领域坐标逐 tick 单调变化；中轴区间角色屏幕位置或背景偏移至少一项
  持续变化；进步斩同拍总位移不出现 `21 + 120` 尖峰；进步斩渲染位置在
  0.18 秒内推进，单帧 camera center 变化不超过一拍普通移动量。
- 基线：`55d49c97d299301b3f484051d235077f8f97c1d8`；分支
  `codex/p2-m2-controls-feel-20260830`；独立 worktree
  `/Users/a10506/.codex/worktrees/p2-m2-controls-feel-20260830`。
- 预期增量：关闭两个新发现的 M2 真人手感阻断，但 G2 仍保持 FAIL，只有用户
  在 `stage_01_02` 真人复验后才能改判；M3/M4 不启动。
- 成本边界：仅保留本单一个主 WIP；约 90 分钟无验收门变化时暂停并重评。

## 授权与非目标

- 依据交接宪法 §11.1 预授权执行表现层方案。采用用户批准的推荐路线：现有
  `battle_mountain_pass_stage_v2.png` 以约 1.3 倍覆盖视口，并按
  `-cameraOffset × parallaxFactor` 平移。它直接补足世界移动参照且零新美术。
- 死区跟随本单不做：背景视差先独立关闭零参照根因，保持既有 camera、鼠标
  世界坐标映射与屏外提示语义不变。若真人复验后仍需调整，再按表现层授权处理。
- 地面参照物后置：需要正式美术资产，本单明确不做；不将该后置项计入本单完成。
- 进步斩领域位移继续一拍到位，`advance_distance=120.0` 不变；表现层复用
  `_actorRenderPosition` 管线完成 0.18 秒插值，camera 继续跟渲染位置。
- 不改 `fixed_delta_seconds`、`move_speed`、`attack_cooldown_seconds`、
  `max_targets`、`aim_assist`、任何 `numbers.yaml` 值；不改 schema/存档、
  checkpoint 移动归因守卫及测试、`lib/shared/strings.dart`、M3/M4。

## 实施与验证

1. 新增生产消费的背景视差组件和表现 token，接入正式
   `Phase0aBattleScreen` 静态背景位置。
2. 抽出可测试的 actor render motion；普通位移沿用 fixed delta，进步斩用
   0.18 秒优先 motion，期间后续普通位移排队，camera 继续读取该 render position。
3. reducer 在玩家当前段为进步斩且该拍可实际出手时，跳过同拍普通 move intent；
   held key 不清除，下一拍攻击进 CD 后恢复普通移动。
4. 新增持续移动、背景视差、中轴持续变化、同拍总位移与进步斩 camera 增量测试。
   若写像素断言，两次帧采样之间先 pump 空树；优先直接断言生产 Transform/motion，
   避免同型 widget 原地换参导致陈旧帧假绿。
5. 实现 commit 后按固定顺序完成两向破坏证红：
   `remove_implementation` 移除生产背景平移支点；
   `force_degenerate_value` 让进步斩退回同拍叠加或退化为单拍 render 跳变。
   两向同一 targeted 组必须变红，随后用精确反向补丁恢复。
6. 依次完成逐文件 targeted、analyze、整仓 format、持锁全量、diff check、
   receipt、`[READY]`、gate。若 gate 唯一剩余项为 `test_deletions`，按宪法
   唯一例外逐条登记并运行 `tools/test_contract_migration_gate.sh`；不得自造豁免。
7. gate 通过后按合并列车检查冲突/重叠，`--no-ff` 合入 main，重跑合并后
   analyze/format/持锁全量，push 并核 CI `conclusion` 与 `headSha`。

## 当前恢复点

- 状态：WIP，生产实现、提交后 targeted 与双向破坏证红已完成，正在进入
  analyze → format → 持锁 full → receipt/READY/gate。
- 最后完成：背景 1.3 倍视差、进步斩 0.18 秒表现插值、同拍移动仲裁均已
  接入生产战斗屏/reducer；整屏 camera 增量守卫与 1280×720、1440×900
  布局守卫已补齐。
- 初始 RED：同拍位移守卫实测 `Actual: 141.0`（预期 120）；actor motion 与
  parallax 生产类型不存在导致对应测试编译红。实现后新增三文件 targeted 全绿。
- 邻接回归：`phase0a_battle_screen_test.dart` 29 项、input feel 7 项、屏外提示
  11 项、既有三段 geometry 8 项、checkpoint 归因 1 项均已通过；analyze 为
  `No issues found!`。
- 测试契约迁移：旧“一步必须看到角色脚点移动”契约与新 camera 跟随 render
  position 的语义冲突，已替换为“领域坐标推进 + 角色或背景至少一个提供世界
  移动参照”；本次必然产生 test deletion，须在最终 gate 仅余该项时走 §8
  登记和机器校验。
- 实现提交：`b450a56096be78f7e39b90dca67c3f7348d6c32c`
  （`修复移动参照与进步斩手感`）。
- 双向破坏证红（同一组三个 targeted 文件）：
  - `remove_implementation`：将 `translationForCamera` 临时退化为
    `Offset.zero`，实测 4 项失败；中轴、相反视差、整屏 camera、10 秒移动
    参照守卫均红。
  - `force_degenerate_value`：临时令同拍仲裁返回 false 并将插值压为
    0.1 秒，实测 3 项失败；领域复现 `Actual: 141.0`，纯 motion 复现
    `24.0 > 21.0`，整屏 camera 复现 `5.76 > 5.04`。
  - 两向均用精确反向补丁恢复，`git diff --exit-code` 为 0。
- 提交后 targeted：新增 3 文件分别 `+1/+1/+5`；既有 geometry `+8`、
  checkpoint `+1`、battle screen `+29`、input feel `+7`、offscreen
  indicator `+11`，全部 `All tests passed!`。
- 测试迁移登记：
  `docs/dispatch/phase2_wiring/test_contract_migrations/p2-m2-controls-feel-20260830.yaml`；
  最终 tip 形成后运行专用机器校验并抄回原文。
- 下一步：提交登记与证据，跑 analyze、整仓 format、持锁 full、最终 tip
  双向证红、receipt、gate。
- 尚无结论：full、receipt、READY、gate、合并、push、CI 均未完成。
- 阻塞：无。
