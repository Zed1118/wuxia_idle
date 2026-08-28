# 表现层测试反模式清账（2026-08-27）

## 结论

审计基线为 `51aa958c`，范围固定为 `test/features/**/presentation/**`：共 **130 个文件、939 个注册用例**（780 `testWidgets` + 159 `test`）。本文件 helper 可达分析结果：

- 779 条可达 `pumpWidget`。
- 160 条不可达 widget pump/painter，分布在 28 个文件；逐条人工复核后，**154 条是守卫自身声称层的合法纯合同，6 条存在过度声称或确定假绿**。
- 另确认 2 个不在“160 条现有用例”分母里的高风险缺口：`E/F/Z` 键盘入口零覆盖；通用水墨 painter 可零像素而整组表现测试仍绿。
- 本报告不修改测试或生产代码，不提升 Phase 2 顶层 Gate。

交接单列出的防御样例已过期：当前 `phase0a_defense_presentation_test.dart:165/176` 已有两条真实 `pumpWidget` 测试，验证开始/结算反馈不是 `SizedBox`、尺寸非零且文案存在。`:146` 的 controller 映射测试仍不守渲染，但已由相邻渲染测试补强，**不再记作当前假绿**。

## 发现与优先级

| ID | 级别 | 当前锚点 | 声称行为与实际断言 | 破坏实验 / 风险 | 推荐补强 |
|---|---|---|---|---|---|
| F1 | P0 | `phase0a_battle_screen.dart:635/638/641` | 生产键盘入口把 `E/F/Z` 映射为 shield/parry/dodge；全仓测试对 `LogicalKeyboardKey.keyE/keyF/keyZ` 均为 0 命中 | 临时让三键直接 `handled` 且不 enqueue，整个 `test/features/battle/presentation/phase0a` **153 项仍全绿** | 三条 screen widget 测试真实 `sendKeyEvent`，分别断言 `Phase0aDefenseStarted.action`、可观测 state/result 与对应可见反馈；不要只测 reducer 或手造事件 |
| F2 | P0 | `phase0a_battle_screen.dart:2568/2582`；`phase0a_ink_vfx_test.dart:5/23/35` | 三条名为 painter/绘制/笔锋的测试只断言 `vfxReveal/vfxFade/vfxStrokeAlpha` 与常量；战斗 screen 测试只守 key、尺寸、坐标 | 临时令 `_InkEffectPainter.paint()` 立即 `return`，melee/palm/gather/clear/defeat 全部零像素；`phase0a_ink_vfx_test.dart` + `phase0a_battle_screen_test.dart` **31 项仍全绿** | 建共享 picture-recorder 像素 harness，五种 `_InkEffect` 至少各断言一帧非透明像素；保留现有 key/坐标测试作为布局合同 |
| F3 | P1 | `baike_screen_test.dart:91`；生产分支 `baike_screen.dart:183-184` | 用例名声称“Repository 未加载显占位”，实际不 pump、不切 tab，只断言 `GameRepository.isLoaded == true`，即验证了相反前提 | 临时把未加载分支改成 `SizedBox.shrink()`，同名测试仍 **1/1 绿** | 让 loaded 状态可注入或隔离单例，pump `BaikeScreen`、切典故 tab，断言 `baikeLoreEmpty` 实际上屏 |
| F4 | P1 | `mainline_all_mode_consistency_test.dart:136` | 声称生产入口接通自动设置、前台 bot、快速重演；实际只对三个源码文件做 `contains('symbol')` | 回调可不消费这些值、或代码可不可达，只要字符串保留就绿 | 从 `StageListScreen` 生产入口点击进入，以 provider override 选择 bot/headless，断言真实 host/controller/clock |
| F5 | P1 | `mainline_ch1_continuous_run_test.dart:87` | 声称首次可挑战门与锁定快照进入宿主；实际只检查五段源码字符串 | 条件分支、参数传递或 host 消费可坏而字符串仍在 | widget/integration 驱动 available 首通入口，断言 `continueFirstClearRun` 与同一 participant snapshot 被宿主消费 |

F2 对应 3 条确定假绿；F3 对应 1 条；F4/F5 各 1 条，合计即上述 6 条。F1 是缺失用例，不计入 939/160 分母。

## 通用 painter 风险边界

当前已有像素级守卫的两类 painter：

- `_SkillVfxPainter`：`phase0a_numeric_skill_screen_integration_test.dart:106`，picture → raw RGBA 非透明像素。
- `_PostureBreakPainter`：`phase0a_mechanics_presentation_test.dart:216`，picture → raw RGBA 非透明像素。

同文件另有以下 painter 未检索到非透明像素断言：

| painter | 当前生产锚点 | 当前主要守卫 | 结论 |
|---|---:|---|---|
| `_InkEffectPainter` | `:2568/2582` | helper 数值 + widget key/尺寸/坐标 | 已由 F2 破坏实验确认假绿 |
| `_GatherPullPainter` | `:2836/2843` | key、中心与领域拉近结果 | 静态高风险，未逐类破坏 |
| `_GuardianWardRingPainter` | `:1475/1479` | CustomPaint 节点存在 | 静态高风险，未逐类破坏 |
| `_GuardianMechanicPainter` | `:2949/2963` | 节点与文案存在 | 线条可空但文案仍在 |
| `_StageWashPainter` | `:2992/2996` | 常规视口无异常 | 审美层缺口，不阻断交互 |
| `_PaperBannerPainter` | `:3015/3019` | banner/文案存在 | 背纸可空但文字仍在 |
| `_OutcomeSealPainter` | `:3045/3049` | seal/文案存在 | 印章底可空但文字仍在 |

本批未把后六类升级为“已证假绿”，因为未逐类做 mutation；它们作为后续像素 harness 可复用的剩余风险记录。

## 破坏实验记录

所有临时生产改动均在实验后用反向补丁恢复，并以对应 `git diff --quiet` 退出 0 确认无残留。

1. 水墨零像素：`_InkEffectPainter.paint` 首行临时 `return`。
   - 命令：`flutter test --no-pub phase0a_ink_vfx_test.dart phase0a_battle_screen_test.dart --reporter compact`
   - 结果：exit 0，两个文件均实际加载，`+31 All tests passed!`。
2. 防御键吞掉：`E/F/Z` 临时只返回 `KeyEventResult.handled`，不 enqueue。
   - 命令：`flutter test --no-pub test/features/battle/presentation/phase0a --reporter compact`
   - 结果：exit 0，`+153 All tests passed!`。
3. Baike 占位消失：未加载分支临时返回 `SizedBox.shrink()`。
   - 命令：`flutter test --no-pub baike_screen_test.dart --plain-name '典故 tab Repository 未加载显占位'`
   - 结果：exit 0，`+1 All tests passed!`。

恢复后逐文件重跑：`phase0a_ink_vfx_test.dart` 3 项、`phase0a_battle_screen_test.dart` 28 项、`phase0a_defense_presentation_test.dart` 3 项、`baike_screen_test.dart` 5 项均各自出现 `All tests passed!`。`flutter analyze --no-pub lib test` exit 0、无问题。

广域 `flutter analyze --no-pub` 不可作为本分支绿证据：它会把独立的 `tools/phase0minus_probe` 当主包分析，该工具缺自己的 Flame/package 配置，当前返回 1943 项、exit 1；错误路径均落在该工具树的返回输出中。本批只改文档且未触碰该工具，故将其记录为既有基线/工具包配置债，不冒充已解决，也不归因于本报告。

## 160 条无 pump 用例的完整分组复核

分类说明：`C` = 用例会因其明确声称的纯合同被破坏而红；`F` = 已确认或静态确定不会因所声称生产行为被破坏而红。文件内混合时分别计数。

| 文件 | 无 pump 数 | 复核结果 |
|---|---:|---|
| `baike_screen_test.dart` | 1 | 1F（F3） |
| `phase0a_defense_presentation_test.dart` | 1 | 1C，entry/audio 映射；另有 2 条真实渲染伴随测试 |
| `phase0a_event_mapping_test.dart` | 43 | 43C，事件→typed entry/坐标/容量合同；不单独冒充像素 |
| `phase0a_ink_vfx_test.dart` | 3 | 3F（F2） |
| `phase0a_mechanics_presentation_test.dart` | 1 | 1C，debug driver 的姿态状态与冻结合同；另有 widget/像素伴随测试 |
| `phase0a_retry_test.dart` | 1 | 1C，controller restart 状态合同；另有 widget 重试测试 |
| `phase0a_sfx_test.dart` | 5 | 5C，事件→音频资产映射 |
| `phase0a_source_contract_test.dart` | 8 | 8C，测试名明确为源码/目录结构合同 |
| `phase0a_stage_transform_test.dart` | 6 | 6C，坐标、深度与纯排序合同 |
| `phase0a_visual_roster_test.dart` | 12 | 12C，typed roster 构造与 fail-closed 合同 |
| `phase0c_embed_verification_test.dart` | 1 | 1C，源码层零持久化依赖合同 |
| `skill_treasure_overlay_test.dart` | 11 | 11C，formatter/result 分类；同文件另有 widget 测试 |
| `milestone_grant_hook_test.dart` | 5 | 5C，文件注释明确限定为真 Isar 的纯 hook 测试 |
| `injury_status_view_test.dart` | 3 | 3C，`InjuryStatusFormatter` 输出合同；不声称 widget 上屏 |
| `bulk_disposal_dialog_test.dart` | 1 | 1C，确认后的服务/持久化结果；同文件另有 dialog widget 测试 |
| `jianghu_map_expedition_location_test.dart` | 1 | 1C，地点状态 selector 合同 |
| `jianghu_map_screen_test.dart` | 6 | 6C，地点状态/进度 selector；同文件另有 widget 测试 |
| `disciple_scheduling_production_route_test.dart` | 2 | 2C，明确为源码负向约束（旧 screen 不可引用、不可写阵容） |
| `main_menu_continue_jianghu_test.dart` | 3 | 3C，继续江湖目标 resolver 合同 |
| `mainline_all_mode_consistency_test.dart` | 4 | 3C participant service + 1F 源码字符串接线（F4） |
| `mainline_ch1_continuous_run_test.dart` | 2 | 1C coordinator + 1F 源码字符串接线（F5） |
| `mainline_narrative_deblocking_test.dart` | 3 | 3C，StageType 自动叙事 policy |
| `mainline_pending_jianghu_affair_recovery_test.dart` | 3 | 3C，事务计划、去重与顺序合同 |
| `mainline_visible_replay_participant_test.dart` | 5 | 5C，参与者选择 fail-closed 合同 |
| `phase0a_mainline_wiring_test.dart` | 11 | 11C，mapper/roster/live-vs-headless 合同；同文件有真实 host widget 集成测试 |
| `stage_entry_flow_pure_test.dart` | 12 | 12C，损失 entry 与掉落过滤纯函数合同 |
| `phase0a_tower_wiring_test.dart` | 1 | 1C，live controller 与 headless 末态一致 |
| `tutorial_banner_card_test.dart` | 5 | 5C，banner registry `byStep` 合同；同文件另有 widget 测试 |

合计：154C + 6F = 160。

## 建议修复顺序

1. 先补 F1 的 `E/F/Z` 三条真实键盘链测试；它直接守当前真人试玩第 4 项。
2. 再补 F2 的共享 painter 像素 harness，先覆盖 `_InkEffect` 五类；这能防止“节点存在但玩家看不到”。
3. 修 F3 Baike 伪用例；若未加载分支按产品保证不可达，可删测试并把不可达保证写成启动合同，不应保留同名假绿。
4. 将 F4/F5 从源码字符串升级为生产入口 widget/integration；原 source check 可保留为辅助，不再承担“已接线”结论。

无需改数值、schema、玩家规则、美术资产或禁区文件。下一批若实施，建议仍按一个修复主题一个分支/worktree，优先 F1，再做 F2。
