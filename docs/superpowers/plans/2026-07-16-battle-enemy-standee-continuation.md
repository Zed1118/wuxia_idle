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

- [ ] **生产接线证据**：旧 `iconPath` 由生产 `CharacterAvatar` 战场路径解析到专属透明立绘；验收路由消费真实 `stages.yaml` / `towers.yaml` 敌队。
- [ ] **targeted tests**：`character_avatar_test.dart` 与对应真实数据视觉路由测试通过，并记录命令与通过数。
- [x] **红线影响**：仅表现层资产、映射与视觉验收；零数值、零三系锁死、零在线/离线、零反主流机制；无新增中文 UI 文案和战斗常量。
- [ ] **桌面视口**：每批至少覆盖 1280×720 / 1440×900；日志无 overflow、exception、route error。
- [ ] **残留风险**：逐项记录仍属过渡复用、尚未目检和风格待重做的敌人。
- [x] **并行隔离**：不提交到 Claude 正在审查的原 Codex 分支；不碰共享热点文件。

## 当前恢复点

- **状态**：进行中。
- **最后完成**：第二章 `elder_grey` 竹杖灰须老者、`shaonian` 春水堂拳掌青年与 `guntou` 光头长棍客均已完成生成、抠图、alpha 技术检查和生产映射，覆盖提升至 45 / 79 种、86 / 120 次出场。
- **下一步**：运行第二章映射回归并提交 `guntou` 小切片；继续补第三章 `guntou_zhu` / `seng_huiyi` / `balian` / `huiyi`，随后集中跑第一至三章和低层塔真实冻结路由双视口验收。
- **已跑验证**：三个资产切片提交前均为 `character_avatar_test.dart` 14 pass + `flutter analyze --no-pub` 0 issue。吸收新 main 并重跑 build_runner 后，战斗立绘/视觉路由/远征配置 49 项通过，Claude 新增角色占用服务 3 项通过，`flutter analyze --no-pub` 0 issue；首次占用服务运行因新 worktree 缺 `libisar.dylib` 失败，补本地忽略软链后同命令通过。三图均为 RGBA、alpha `0–255`、四角透明；脚底比例依次为 `0.928385` / `0.943322` / `0.957031`。
- **阻塞项**：无。Claude 若完成稳定检查点合并，后续在本分支批末吸收新 `main`，不在当前资产切片中途改基线。
