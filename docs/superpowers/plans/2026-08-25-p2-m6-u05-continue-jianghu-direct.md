# P2 M6 U05 “继续江湖”直达当前主线纵切

## 任务包

- taskId：`P2-M6-U05-CONTINUE-JIANGHU-DIRECT`
- milestone：M6
- owner：`codex_root`
- baseCommit：`3fbf945a5d89648b5c4bced3802e20f333b53636`
- branch：`codex/phase2-m6-u05-continue-jianghu-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-continue-jianghu`
- status：`ready_reviewed`
- codeCandidateCommit：`39b15a11e9dd1e9296f4fa59f471da101a1ab173`

## 已确认生产缺口

二阶段方案 §11.1 冻结四个一级入口，第一项“继续江湖”应直接进入当前下一主线关。
当前主菜单仍显示“主线”，点击只 push `ChapterListScreen`；状态与目标解析还硬编码
只扫描前 15 章，真实 21 章存档在第 15 章后会误报“主线已通”。

本纵切只关闭“继续江湖”入口的动态 21 章解析与当前关直达；宗门、武学与行囊、
江湖纪事三个一级 Hub 及整个 U05 继续开放。

## 文件白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/shared/strings.dart`
- `test/features/main_menu/presentation/main_menu_continue_jianghu_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u05-continue-jianghu-direct.md`
- `docs/audit/phase2_m6_u05_continue_jianghu_direct_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 生产合同

1. 主菜单首要入口显示“继续江湖”。
2. 进度加载完成且仍有首次推进关时，按生产 stage 链解析唯一当前关，点击经既有
   战斗入口守卫后直接调用 `runStageFlow(... continueFirstClearRun: true)`。
3. 章节集合从生产 21 章数据动态派生，不写死 15/21；状态与目标提示同源。
4. 进度未加载或全部主线已通时保留章节地图回退，继续支持重打，不制造死入口。
5. 不改变主线准入、参与者、结算、奖励、解锁、数值、schema 或叙事。

## TDD 与验收

- 红测：第 1 章进度点击当前入口应捕获 `stage_01_02`，现状只 push 章节列表；前
  15 章已通时应解析 `stage_16_01`，现状误报主线完成。
- 定向：解析首关/跨第 15 章/全通，UI 点击真实 stage ID、双视口无 overflow，
  fallback 仍 push 章节地图，既有 main_menu 族回归。
- Gate：format、作用域/root analyze、`git diff --check`、YAML、白名单、独立复核
  P0/P1=0、最终一次全量、clean READY。

## 停止边界

若需要改渐进解锁、四 Hub 信息架构或其他模式入口，只记录后续任务，不混入本纵切。

## 收口证据

- 新增纵切测试：7/7 PASS；主菜单与相邻导航联合回归：93/93 PASS。
- 根应用 `flutter analyze --no-pub lib test tool`：0 issue；变更文件分析：0 issue。
- 最终全量：5329/5329 PASS。
- 独立语义审查：P0/P1/P2 = 0/0/0，确认生产分支真实调用 `runStageFlow`。
- 无参数 `flutter analyze --no-pub` 会进入退役独立子包 `tools/phase0minus_probe`，因该
  子包未安装自身依赖产生 1943 条基线问题；不冒充通过，根应用边界按既有 CI 口径验收。
- 无 schema/saveVersion、数值、概率、奖励、解锁或叙事变化；U05/M6/二阶段仍开放。
