# 2026-06-29 visual battle scene depth

## 目标

在战斗页增加水墨背景层次:远山、雾气、地面纹理、压暗/光晕层次。复用现有 `BattleSceneBackground`、`BattleAtmosphereOverlay`、`WuxiaColors`,不引入外部依赖或真实图片资产。

## 分支

- worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/visual-battle-scene-depth`
- branch: `codex/visual-battle-scene-depth`

## 验收标准

1. 生产接线证据: `BattleScreen` 继续通过真实 `sceneBackgroundPath` 渲染 `BattleSceneBackground`;新增背景风格只从已有 `bgmTrack` 映射,不接触 `StageDef` 战斗结算或引擎。
2. 无背景图兜底: `path == null` 或空路径时仍渲染水墨底、远山、雾气、地面纹理、光晕/暗角,不再是空 widget。
3. 有背景图行为: 保留原 `Image.asset(path, fit: BoxFit.cover)` 和 `WuxiaColors.battleSceneScrim` 压暗遮罩;asset 加载失败仍不黑屏/白屏。
4. 关卡氛围: 主线、塔、Boss、心魔、轻功、群战通过表现层 style 使用不同墨色/雾气/光晕参数;无显式 style 时按资源路径兜底推断。
5. 红线影响: 只改 presentation/widget test/计划文件;不改 battle engine、damage calculator、数值、技能、掉落、结算、save/schema/numbers;不新增中文 UI 文案。
6. 验证: 跑 `dart run build_runner build --delete-conflicting-outputs`;相关 battle presentation tests;`flutter analyze`;`git diff --check`。
7. 交付: 所有改动 commit,工作区干净;tip commit message 按要求为 `[READY] feat(battle): add layered ink scene background`。

## 任务切片

1. 读取 `AGENTS.md`、`CLAUDE.md` 相关约束、`docs/spec/rejected_task_registry.md`。
2. 梳理 `BattleSceneBackground`、`BattleAtmosphereOverlay`、`BattleScreen` 生产接线和既有测试。
3. 在 `BattleSceneBackground` 内增加水墨层次和资源路径兜底风格推断。
4. 在 `BattleScreen` 用既有 `bgmTrack` 做必要表现层 wiring。
5. 更新 widget test 覆盖有图/无图/不同 style。
6. 跑格式化、生成、targeted tests、analyze、diff check。
7. 更新恢复点并提交。

## 当前恢复点

- 状态: ready for review。
- 最后完成: 已实现 `BattleSceneBackground` 分层兜底、`BattleScreen` bgmTrack→style wiring、背景 widget tests 和常规桌面视口 smoke。
- 下一步: 等待 Claude 合并审核。
- 已跑验证:
  - `dart format lib/features/battle/presentation/battle_scene_background.dart lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_scene_background_test.dart` 通过。
  - `dart run build_runner build --delete-conflicting-outputs` 通过;build_runner 提示该参数已被忽略,但生成成功且无生成文件进入 git 状态。
  - `flutter test test/features/battle/presentation/battle_scene_background_test.dart` 通过,4 tests。
  - `flutter test test/features/battle/presentation` 通过,130 tests。
  - `flutter analyze` 通过,No issues found。
  - `git diff --check` 通过。
- 阻塞项: 无。
