# 夜批·测试覆盖补强续单（kimi-night worktree）

## 目标

挖 lib 低覆盖的 application/service/handler 层行为测试（真实入口驱动，非 fixture 孤测）。
目标序列制：lcov 定基线 → application/ 下 service/handler/provider <60% 行覆盖升序 → 从最低逐文件补测，
每文件独立中文动宾 commit（先红→补测→targeted 绿 + analyze 0→commit）。

## 分支

`kimi/night-coverage`，worktree `.worktrees/kimi-night`。

## 禁区

- 只碰 test/；不改生产逻辑（发现生产 bug → 记本文件「发现项」+ [BLOCKED] 冻结）。
- 不碰 data/ 数值、schema、saveVersion、红线、共享热点（strings/numbers/GDD/PROGRESS/pubspec）。
- 不碰 battle 域（codex 并行在改）。

## 验收

- 每文件：改前→改后行覆盖率实测数字写入恢复点。
- `flutter analyze --no-pub` 0 issue。
- 交付：worktree 干净 + tip `[READY] 夜批测试覆盖续批交付` + §8.2 四证据。

## 恢复点

- 状态：<60% 候选池**已清空**（19/19 + 命名 panel，window_controller 有据跳过）；交付前全量验证中。
- 基线（2026-07-19 全量 `flutter test --no-pub --coverage` 实测，4503 过 1 败；败者重跑未复现=既有并发 flaky）。

### 完成清单（基线 → 补后，均为该文件 targeted 单跑实测）

| # | 文件 | 基线 | 补后 | commit |
|---|---|---|---|---|
| 1 | slot_list_provider | 0/2 | 2/2 | e07b1b31 |
| 2 | dispel_service_providers | 0/3 | 3/3 | 26039f23 |
| 3 | insight_exchange_service_providers | 0/3 | 3/3 | cc592a3b |
| 4 | technique_learn_flow_service_providers | 0/3 | 3/3 | 49f6d43f |
| 5 | recruitment_providers | 0/9 | 9/9 | 778af8d5 |
| 6 | lineage_info_provider | 0/24 | 24/24 | 55b57697+9a10b0cd |
| 7 | encounter_service_providers | 2/17 | 17/17 | 576daeea |
| 8 | window_controller | 1/6 | **跳过** | — |
| 9 | audio_settings_provider | 3/15 | 15/15 | f0fc5e66 |
| 10 | sect_providers | 40/168 | 141/168 | aeabdf28 |
| 11 | sweep_settlement | 16/50 | 43/50 | 359265dd |
| 12 | post_battle_healing_panel（命名·presentation） | 12/70 | 70/70 | 1349093a |
| 13 | founder_buff_providers | 2/5 | 5/5 | f99161f8 |
| 14 | inner_demon_providers | 2/5 | 5/5 | a98dd027 |
| 15 | ascend_service_providers | 4/13 | 13/13 | 14b90d25 |
| 16 | resource_overview_providers | 2/4 | 4/4 | 2d7e8adc |
| 17 | tower_providers | 5/9 | 9/9 | e9028e14+b679330e |
| 18 | jianghu_providers | 9/18 | 18/18 | 787b976f |
| 19 | sweep_unit | 17/31 | 31/31 | 75d29b76 |
| 20 | gauntlet_providers | 57/99 | 99/99 | f81a42b6 |

- window_controller（1/6）**跳过**：windowManager 平台通道直调层（flutter test 无通道可测），
  其逻辑层（持久化顺序/apply 语义）已被 display_settings_controller_test 经 fake WindowController 覆盖。
- sect_providers 未达 100% 的余量：`debugSpawnSectEvent`/`maybeRunSectMonthlyTick` 两个
  WidgetRef 入口（~15 行），见发现项②；另有少量 rng 依赖分支。
- sweep_settlement 余量 7 行：skill 残页 hook 命中路径（Random 非确定性）。

## 发现项

1. **（疑似生产隐患·未修）StreamProvider `.future` 无监听读取**：Riverpod 3 下
   `ref.read(streamProvider.future)` 在 provider 无任何监听时，会被 dispose 在 Isar
   `watch` 流首发之前 → future 永不完成（测试实证 30s 超时）。`sect_providers.dart`
   `_runSectMonthlyTick` 正是裸 read 两个 StreamProvider.future（currentSect /
   activeSectEvents），生产上若调用时无 widget watch（主菜单首帧场景）疑似静默失败
   （coordinator try/catch 吞掉 + debugPrint）。**未动生产代码**；测试以「持订阅保活」
   对齐 sect screen 开着的有监听态。建议主窗口立项核：给 tick 路径加监听保证或改直查。
2. **widget + StreamProvider.future 死锁**：`debugSpawnSectEvent`/`maybeRunSectMonthlyTick`
   在 widget test 下四种体例（交替 pump / 预建档 / host watch 保活 / pumpWidget 进
   runAsync）均挂起，与项目 memory `feedback_isar_widget_test_deadlock` 同族。
   内核已由容器级测试覆盖（maybeRun 本体=一行转发），入口行留缺口。
3. **（教训）MainlineProgress 直接 put 新行造重复行**：getOrCreate 单行语义下直接
   `put(MainlineProgress())` 会 autoIncrement 出第二行，findFirst 命中成竞态
   （inner_demon_providers_test 并发联跑翻车一次）。正解：getOrCreate 后原地改再 put。
4. **（教训）每测试多次 pumpWidget = 新 ProviderScope 容器**：容器内状态（如
   battleProvider）随重泵全丢。sweep_unit startBattle 测曾读到空队。正解：一测试一容器，
   捕获 ref 复用。
5. **（机制）widget test 调真 Isar 的可行体例**：build/tap/Isar 全收进单个
   `tester.runAsync`（post_battle_healing_panel 实证 4 例全绿、70/70）；散在 fake 区的
   真 async 必挂。另 `tester.runAsync` 返回 `Future<T?>`，结果须判空或强转。
6. **（既有）`isar.saveDatas` 等集合扩展在 domain 文件 part**：直用 SaveData 集合须
   import `core/domain/save_data.dart`。

## 红线影响

零触及：未改生产代码/数值/schema/saveVersion/文案；测试断言的数值（疗伤丹 heal 4h、
mission_recruit_prob 0.5、win delta 等）全部读自 `GameRepository.instance.numbers`
或 production yaml def，不写死常量。

## 残留风险

- 发现项①的 StreamProvider.future 裸读疑似生产隐患**未经生产复现确认**，仅测试侧实证
  + 代码路径推理，待主窗口核。
- sect_providers 两 WidgetRef 入口 ~15 行未覆盖（发现项②）；sweep_settlement rng 分支 7 行。
- 基线全量 1 败（重跑未复现，隔离型 flaky），批末全量再验。
