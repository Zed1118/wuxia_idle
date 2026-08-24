# 二阶段 M6 U05 “继续江湖”直达纵切审计

## 结论

`P2-M6-U05-CONTINUE-JIANGHU-DIRECT` 为 `READY`。主菜单首要入口现在按生产
主线数据解析当前待首推关，经既有 `guardBattleEntry` 后真实调用
`runStageFlow(targetCycle: 1, continueFirstClearRun: true)`。全通或进度未决时回退
章节地图。本结论只关闭 U05 四个一级入口中的第一项，不代表 U05、M6 或二阶段完成。

## 身份与范围

- base：`3fbf945a5d89648b5c4bced3802e20f333b53636`
- registration：`4567fd1d4f5c66ba971acf64e4337ea7d12fb1c6`
- code candidate：`39b15a11e9dd1e9296f4fa59f471da101a1ab173`
- branch：`codex/phase2-m6-u05-continue-jianghu-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-continue-jianghu`
- 生产修改只有 `main_menu.dart` 与 `strings.dart`；无 schema/saveVersion、YAML、
  数值、概率、奖励、解锁或叙事修改。

## 红绿证据

红测先只引入预期合同，编译明确失败于缺少 `resolveContinueJianghuStage` 与
`continueJianghuRunnerForTest`；不是断言自造失败。实现后新增 7 项覆盖：第 1 章当前关、
跨 15→16 章、21 章全通、点击传递生产 stage、入口状态、全通回退与双视口无 overflow。

- 新增纵切：7/7 PASS。
- 主菜单、百科相邻导航、视觉路由与 truth source 联合：93/93 PASS，固定资源复跑同样通过。
- 变更文件 analyze：0 issue。
- 根应用 `flutter analyze --no-pub lib test tool`：0 issue。
- 最终全量 `flutter test --no-pub --no-test-assets --reporter compact`：5329/5329 PASS。
- `dart format --set-exit-if-changed`、`git diff --check`：PASS。

无参数 `flutter analyze --no-pub` 会额外分析退役独立子包
`tools/phase0minus_probe`；该子包在新 worktree 未安装自身依赖，产生 1943 条既有错误。
该命令明确记为 FAIL，不作为本切片绿灯；根应用边界按项目 CI 的 `lib test tool` 口径验收。

## 独立语义审查

独立审查对 `4567fd1d..39b15a11` 给出 P0/P1/P2 = 0/0/0、READY。审查确认：

- 章节索引来自生产 `GameRepository.stageDefs`，不是 15/21 常量或测试 fixture。
- 当前关由既有 `MainlineProgressService.availableStages` 链解析。
- 生产分支直接调用真实 `runStageFlow`，测试 seam 没有替代生产接线。
- 全通 fallback、战斗入口守卫、白名单与零 schema/tuning 边界成立。

非阻断剩余风险：加载中点击 fallback 未单列专测；既有 `VoidCallback` + `unawaited` 入口模式
理论上允许极快重复点击并发。二者不改变本纵切冻结合同，留后续菜单入口状态机任务处理。

## 未关闭边界

- U05 其余三个一级 Hub 与更完整的信息架构。
- U01 听剑生产接线及 headless/扫荡等全模式一致性。
- U05、M2、M6、M3/M4 与整个二阶段。
- 任何 `TUNE-*` 候选冻结、奖励/解锁/生态调优。
