# Phase 2 六项桌面修复集成验收（2026-09-05）

## 核心结果

- 用户批准后，候选 `0784c7acdfca377b2b2c0c11d4ecce4df5c79e59` 经 **no-ff merge `af5cedf81445ca2bf41cac852e404a515c9ee700`** 合入 main；随后补齐两处验收缺口，最终受检代码提交 **`35e738c9b2fd02f1a1c9ba1193d0f08c0d8ac372`** 已 push。
- 六项产品修复不变：地图标题、六地点详情对比度、空技能槽误报、塔败绩刷新、人物视口/底部 HUD 边界、存活终局 Q/R 误报。生产消费为地图及真实塔入口、各战斗宿主共用的 `Phase0aBattleScreen → Phase0aStage`。未动数值、奖励、schema/saveVersion、迁移集合或既定产品决策。
- **本地整仓 6031/6031 PASS，exit 0、`[E]`=0**；最终 analyze 无问题、format 1646 文件/0 changed、测试契约迁移 Gate PASS。正式 M0–M9 仍 **1/10 = 10%**；主线目录 105/105、塔迁移 0/49 不变。
- **代码 exact-SHA CI：[33949516783](https://github.com/Zed1118/wuxia_idle/actions/runs/33949516783) 已核对 headSha=`35e738c9b2fd02f1a1c9ba1193d0f08c0d8ac372`，`completed/success`。** test job（含覆盖率门槛）14:19:57–14:41:26 CST，约 21 分 29 秒；macOS 构建 2 分 18 秒，均成功。原 merge `af5cedf8` 存在已知审计失败，没有单独推送它来冒领绿色 CI。代码集成验收通过；本报告等治理尾只改文档，最终治理 HEAD 与其 exact-SHA CI 在任务收工记录另行核对。
- 合并版本从生产根实际运行：地图/塔详情可读；塔战败原页 **59/2→60/3**；主线 05 可见胜利时气血 **6070/6070**、Q/R 无倒地误报。实机是 AI 受托执行，不是自然人听感或 Windows 代签。

## 验证与集成返工

| 检查 | 结果与精确边界 |
| --- | --- |
| main 初始定向 | `af5cedf8`：战斗 presentation、地图、塔 presentation、主线接线、断魂庄入口、G2 生产验收合计 **376 PASS** |
| 全局纸面对比度与地图 | `13504129`：**33 PASS**。深色地图上 8% paper 覆层被静态审计当浅纸面；依照扫描器既有规则增加两处带原因的局部说明，同时补实际合成底色的对比度断言，不关闭/修改扫描器。将覆层改成不透明，断言得到 **1 FAIL（对比度 1.358 < 4.5）**，恢复后通过 |
| 密度夹具/屏外/解码 | `35e738c9`：**26 PASS**。仍逐个要求 24 名敌人挂载，另检查镜头内绘制、镜头外隐藏，不以减少角色数量迁就界面；强制绘制屏外 actor 得到 **1 FAIL**，精确恢复后通过 |
| 最终持锁全量 | `35e738c9`，14:11:22–14:19:40 CST，约 **8 分 17 秒**；末行 `08:15 +6031: All tests passed!`，exit 0、`[E]`=0；自有锁已验证并释放 |
| analyze / format / diff | `flutter analyze --no-pub`：No issues；`dart format --output=none --set-exit-if-changed lib test docs`：1646/0 changed；`git diff --check` 通过 |
| 测试契约迁移 | `b13a0094..35e738c9`：expect 删 1/增 34，用例删 0/增 5，登记 1；原双轴 `1e-9` 迁移保持。密度检查只改 finder 的屏外搜索范围并增加断言，没有删除负载断言 |
| 生产包 | 冻结 `13504129` 的 macOS Profile 203.6 MB；后续 `35e738c9` 只改测试和计划，lib/data/assets/pubspec/macos 与该包版本完全一致 |

上述定向组有重叠，**不相加为独立测试总数**。本轮按 CLAUDE §8.2 checklist 和单独迁移 Gate 验收，未声称通用 afk `gate.sh` 原生全绿。

两次失败历史不抹去：第一轮 `af5cedf8` 发现纸面审计 1 FAIL 后约 74 秒主动中止，Flutter 返回 0 且有 shutdown 错误，**不算全量 PASS**；第二轮 `13504129` 完整 **6030 PASS/1 FAIL**，仅密度夹具，实际约 9 分 20 秒。最终独立完整复跑才为 6031 PASS。原定向集遗漏 `test/tools` 的全局纸面门和 debug density 夹具是返工原因；后续同类 UI 验收应纳入这两处生产检查，不削弱它们。

### 可复跑命令

```sh
flutter test --no-pub --reporter expanded \
  test/features/battle/presentation/phase0a \
  test/features/jianghu_map/presentation \
  test/features/tower/presentation \
  test/features/mainline/presentation/phase0a_mainline_wiring_test.dart \
  test/features/boss_gauntlet/gauntlet_entry_flow_test.dart \
  test/features/mainline/application/phase0a_mainline_g2_production_acceptance_test.dart

flutter test --no-pub --reporter expanded \
  test/tools/audit_paper_text_contrast_test.dart \
  test/features/jianghu_map/presentation/jianghu_map_screen_test.dart

flutter test --no-pub --reporter expanded \
  test/features/debug/application/phase0a_debug_battle_fixture_test.dart \
  test/features/battle/presentation/phase0a/phase0a_offscreen_indicator_test.dart \
  test/features/battle/presentation/phase0a/phase0a_actor_image_decode_budget_test.dart

# 仅在共享锁空闲且成功取得自有锁后执行；不要占用/删除他人锁。
flutter test --no-pub --reporter expanded
```

ignored 原始日志及锁运行结果：`build/phase2_desktop_integration_20260905/`。`full-af5cedf8-interrupted*`、`full-13504129-failed*`、最终 `full.log/full-result.json` 分开保留；锁路径为 `/Users/a10506/.claude/locks/wuxia_full_test.lock`。没有把生成文件、日志或截图库提交。

## 实机及存档边界

冻结包 `build/phase2_human_acceptance/135041291672/`：AOT SHA256 `7530fd2c4f4aa9539c8009d081df83a9a1280d51df34974ee8303dae31cf313a`；archive SHA256 `ac87b5dcf615c82cac9a3511757f1603689a4638c36c89d30bfa039ff265657f`；fixture SHA256 `becb25943a9f455e77ed1fead7432a6568411b745232600ea12e36a7d94a10fd`（未用于代替 GUI）。

实际运行 `build/phase2-main-integration-review-20260905.lvEAmg/wuxia_main_review.app`，仅换独立 bundle ID、沿原 entitlement 本地签名；AOT 与冻结包逐字节相同、`codesign --verify --deep --strict` 通过。签名和 bundle ID 与正式 archive 不同，不能据此宣告分发签名验收完成。

原生截图/AX 在本任务工具记录：“复验合并后的地图标题对比度”“复验塔地点详情的浅纸面文字”“记录集成版本塔挑战前的计数”“检查合并版战场边界和空槽显示”“确认塔战败后原页计数更新”“复验集成版存活胜利时的Q/R文案”。1280×720 塔入口/战斗、目标 1440×900 扩展窗口的主线战斗/胜利实际执行；工具把后者缩为 1229×768，**没有精确原生 frame 读回证据**，不冒充精确尺寸正式签字。主线胜利真气 0/100，不影响气血存活与 Q/R 禁用语义；结算后返回关卡，应用已退出。

所有试玩写入仅在 `com.pen.wuxia.acceptance20260905` 隔离容器。测试前备份旧隔离 slot1 为 `build/phase2_desktop_integration_20260905/isolated-slot1-before-main-review.isar`，再复制同编号冷备份；未打开/覆盖原用户容器。三份原档哈希在本轮 GUI 前后均与[上一轮报告](phase2_battle_visibility_repair_2026-09-05.md)一致。没有删除分支、worktree 或用户存档。

## 剩余风险与成本

1. 近身人物重叠、完整五武器手感/Boss 应对/长时输入及新叙事链仍有验收缺口；本轮不是所有模式在最终 SHA 的整体验收。
2. 实际听感、Windows 实机及精确原生尺寸读回仍缺证据；AI 受托画面观察不解除这些能力边界。
3. 代码 exact-SHA CI 已通过，剩余工作仅治理尾提交、最终 exact-SHA CI 和工作树 clean 核对；未启动塔楼层、legacy 退役、M8/M9 或其他内容工程。

结果驱动成本记录：13:54 CST 起，代码 CI 于 14:41:26 完成，约 48 分钟；首个检查点 14:54，治理尾远端验证可能越过该检查点，仅延长既有等待，不增施工范围。主成本是墙钟，不伪称 token 归因。本地全量成本为一次提前中止、一次完整失败、一次完整通过；集成返工两处验收覆盖缺口，生产行为没有因此增加第七项改动。正式 Gate 增量 0；本批代码集成验收通过，无新产品决策需重投票。
