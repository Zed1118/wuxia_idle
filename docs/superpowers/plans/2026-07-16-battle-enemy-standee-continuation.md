# 正式敌人立绘覆盖续作计划

> 分支：`codex/battle-enemy-coverage-continuation`  
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-enemy-coverage-continuation`  
> 起点：`80136768`（保留原 `codex/battle-ui-stage` 审查 tip 不漂移）

## 目标与边界

继续完成正式主线、爬塔、轻功与群战敌人的透明全身立绘覆盖，优先把身份冲突明显的过渡复用替换为专属画像，并在真实关卡生产路径完成 1280×720 / 1440×900 视觉验收。

本续作不改战斗数值、站位语义、技能释放规则、道具消费、schema/saveVersion，也不修改 Claude 合并期的共享热点 `GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。

## 任务切片

1. 盘点 79 种正式敌人、120 次出场的未覆盖项、过渡复用项与风格不匹配项。
2. 优先重做早期主线五名过渡敌人，再处理章节 Boss / 爬塔 Boss。
3. 补齐轻功与群战专属敌人，最后处理低复用普通敌人。
4. 每完成一支完整敌队，跑真实数据冻结路由的双视口验收，检查体量、脚底、遮挡、色温和状态牌边界。
5. 批次末运行映射回归、视觉路由测试、`flutter analyze --no-pub`、格式与 diff 检查。

## §8.2 验收清单

- [x] **生产接线证据**：旧 `iconPath` 由生产 `CharacterAvatar` 战场路径解析到专属透明立绘；验收路由消费真实 `stages.yaml` / `towers.yaml` 敌队。
- [x] **targeted tests**：`character_avatar_test.dart` 与对应真实数据视觉路由测试通过，并记录命令与通过数。
- [x] **红线影响**：仅表现层资产、映射与视觉验收；零数值、零三系锁死、零在线/离线、零反主流机制；无新增中文 UI 文案和战斗常量。
- [x] **桌面视口**：每批至少覆盖 1280×720 / 1440×900；日志无 overflow、exception、route error。
- [x] **残留风险**：正式 79 种敌人过渡复用、未目检与明确风格待重做项均已清零；动态战斗手感与 Windows 发布验收不属于本批静态视觉范围。
- [x] **并行隔离**：不提交到 Claude 正在审查的原 Codex 分支；不碰共享热点文件。

## 当前恢复点

- **状态**：READY；实现、双视口验收与最终门禁全部完成，可交 Claude 审查合并。
- **最后完成**：正式 79 种敌人均拥有独立透明全身战斗资源；70 个真实战斗目标完成 140 张双视口截图审计；Boss 矩形黄底已修复并全量复拍。
- **下一步**：Claude 只读审查本 READY tip；通过后按既定顺序合并，不在本分支继续扩 scope。
- **已跑验证**：最终门禁 `flutter test --no-pub test/features/battle/presentation test/features/debug/application/visual_acceptance_plan_test.dart test/features/debug/visual_route_test.dart` 为 **244 pass / 0 fail**；动态 `battle` 套件逐个构造 70 / 70 真敌队；`flutter analyze --no-pub` 为 **0 issue**；`flutter build macos --debug --no-pub` 成功；格式 10 文件 0 changed、`git diff --check` 通过。140 / 140 截图与日志齐全，尺寸正确，route error / overflow / exception / missing asset 均为 0。
- **阻塞项**：无。Claude 若完成稳定检查点合并，后续在本分支批末吸收新 `main`，不在当前资产切片中途改基线。
