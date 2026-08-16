# Kimi 派单：Phase 0A 第七批 debug 正式表现层首切片

## 基线与目标

- 基线：协调分支 `23835cba`（第六批装配器 + 第七批边界与只读审计）。
- 在独立 worktree 实现 `VisualRoute.phase0aBattlePlayable`，仅 debug/profile 可达。
- 必须真实调用 `Phase0aProductionFlowAssembler`，消费 `Phase0aWaveBattleFlow.state/events`；禁止另造假战斗状态、假伤害或定时脚本演出。
- 视觉方向、事件映射与验收以：
  - `docs/superpowers/plans/2026-08-16-phase0a-production-batch7-presentation.md`
  - `docs/audit/phase0a-production-presentation-implementation-audit-2026-08-16.md`
  为准。

## 必须交付

1. `data/phase0a_debug_battle.yaml`（已由 `data/` asset 声明覆盖）：
   - 仅 debug fixture 使用；承载竞技场边界、固定拍长、玩家/AI 射程/角度/CD、Q/R 半径/气耗/CD、角色初态、两波敌人和显式 seed。
   - 数值不写进 Dart，不复制 probe 配置；字段由 typed loader 启动期 fail-fast 校验。
   - 不进入 `numbers.yaml`，不新增存档/schema。
2. `lib/features/battle/presentation/phase0a/` 正式首切片：
   - controller：固定拍、按键快照、事件 seq 去重、终局停止；测试可手动单步，不依赖真实计时。
   - stage transform：显式 world bounds→安全区；y 越大越靠前、scale 越大、按脚底 y 稳定排序；1280×720/1440×900 均无裁切。
   - actor standee：正式资产、接地阴影、名称、全体持续血条、玩家真气；不使用几何人形。
   - VFX：所有非零 `HitLanded`/Q/R outcomes 生成伤害数字；暴击层级更高；玩家远距命中显示水墨掌风轨迹；Q 涡旋/拉拢、R 径向墨爆、死亡墨散、命中闪/轻震；所有事件只读、不重算伤害。
   - HUD：等宽 Q/R 技能印，ready/cooldown/qi/casting/down 五态全渲染；CD/气耗原因可读；鼠标、Tab/Enter/Space 与键盘 Q/R 可操作。
   - 波次横幅、唯一胜/败终局封签；终局后输入不再产生事件或重播反馈。
3. debug fixture/application：
   - YAML→typed fixture；真实 `BattleCharacter`、真实 `NumbersConfig`、显式 `Random(seed)`、真实 assembler。
   - visual roster 独立于 domain：玩家=祖师正式战斗立绘；普通/远程/精英使用根 `assets/enemies/` 正式资产与 UiStrings 名称。
4. visual route：
   - 增加 `phase0a_battle_playable`；host switch 接新屏。
   - release 仍由现有 `!kReleaseMode` 门控；不得接 `stage_entry_flow` 或其他生产入口。
5. 文案与 token：
   - 所有新增中文 UI 文案集中到 `UiStrings`；布局/颜色/时长 token 集中到 presentation token/fixture，不散落魔法数。
   - 可复用 `BattleSceneBackground`、`HpBar`、`DamagePopup`、`WuxiaImage`、`MeridianBar`、水墨 token；不得复用强耦合 3v3 的 `BattleScreen/BattleState/CharacterAvatar/BattleField/BattleBottomBar`。

## 测试与证伪

红测先行并单独 commit，至少覆盖：

1. world→screen 双视口安全区、y 深度 scale/排序与确定性。
2. 同一事件 seq 重复输入不重播；乱序输入按 seq 消费；终局后不再新增反馈。
3. 真实 flow：移动改变屏幕脚底点；命中后血条来自 state、伤害数字等于 event；Q 拉怪、R 群伤、两波横幅和唯一终局全到 UI。
4. 所有存活敌人持续拥有名称/血条；所有非零伤害均有 popup；不得以 widget 自算血量替代 state。
5. 技能五态亮暗/CD/真气原因、按钮禁用语义、Tab/Enter/Space、WASD/普攻/Q/R。
6. visual route parse/host 注册；生产入口文件无 `phase0aBattlePlayable`/新屏引用。
7. 源码契约：新表现层不得 import 旧 `battle_state.dart`、`BattleAI`、`DefaultGroundStrategy`、`BattleScreen`、probe/Flame；debug fixture 之外不得 import YAML loader/GameRepository。

## 验证

- 新 tests 红→绿证据；红测 commit 保留。
- `flutter test --no-pub test/features/battle/domain/phase0a test/features/battle/application/phase0a test/features/battle/presentation/phase0a`
- 相关 `test/features/debug/visual_route*` targeted。
- `flutter test --no-pub test/combat/damage_calculator_test.dart`
- nested probe 8/8（只回归，不改）。
- `flutter analyze --no-pub`、`git diff --check`、禁用依赖搜索。
- 先不自行声称视觉终验通过；主窗口将启动真机抓 1280×720 / 1440×900 并目检返修。

## 禁止项

- 不改 GDD/CLAUDE/PROGRESS，不改 probe，不生成/重绘/转码资产。
- 不切生产路由，不接奖励/掉落/成长/伤势/存档，不删旧 3v3。
- 不新增依赖，不复制公式，不在 Dart 硬编码战斗调优数值或中文文案。
- 不 push/部署。

## 提交流程

计划档 commit → 红测 commit → YAML/loader+controller commit → stage/HUD/VFX commit → route/fixture commit → 全验证 → `[READY]`。每步保持可恢复，最终 worktree 干净。
