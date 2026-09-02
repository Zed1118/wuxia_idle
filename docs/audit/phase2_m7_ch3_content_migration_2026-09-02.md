# Phase 2 M7 第三章生产内容迁移审计

## 核心结论

- 开局只读复核：`main == origin/main == 52a4255fd74d1c7d86f43f846a536e52cfdec1b6`，主 checkout clean；P0 exact-SHA CI run `33578580680` 为 `completed/success`。
- 实时分母：第二章 `5/5`、全主线 typed production catalog `14/105`、塔 `0/49`。只读审计确认第一个按主线顺序完整未迁移的章节是第三章：`stage_03_01..05` 的 `StageDef` 均存在，但 assignment、encounter 与 runtime binding 为 `0/5`，生产 factory 返回 null 后由 legacy mapper 消费。
- 本批把第三章推进至 `5/5`；随后经用户授权快进合入并 push，`main == origin/main == 9efcdeb6f7147070be891b2c2e08138651267317`，全主线 typed catalog 的集成事实为 `19/105`。M7 仍开放，Phase 2 仍为 `1/10`。
- 五关只复用现有门派、寺院、山匪生态与既有目标原语；没有修改 `stages.yaml`、`numbers.yaml`、生产 Dart、玩家/敌人数值、Boss 招式、掉落、奖励、经济、叙事、解锁、周目、结算 owner、Isar、`schemaVersion` 或 `saveVersion`。

## 生产路径证据

| 关卡 | encounter | 基敌（沿用 StageDef） | 编成 / 激活 | 目标 |
|---|---|---|---:|---|
| `stage_03_01` | `ch3_encounter_01_martial_gathering` | `enemy_erLiu_master_a` | 25 / 10 | 全歼 |
| `stage_03_02` | `ch3_encounter_02_xuchang_arena` | `enemy_erLiu_guntou_zhu` | 3 / 3 | 全歼 |
| `stage_03_03` | `ch3_encounter_03_night_temple` | `enemy_erLiu_seng_huiyi` | 25 / 10 | 全歼 |
| `stage_03_04` | `ch3_encounter_04_yanmen_past` | `enemy_erLiu_balian` | 3 / 3 | 斩将且清除两名必杀随从 |
| `stage_03_05` | `ch3_encounter_05_named_sword` | `enemy_erLiu_huiyi` | 2 / 2 | 仅斩指定 commander |

- `CombatCatalogRepository.loadProduction()` 读取 manifest、assignment、encounter 与 runtime binding；`Phase0aEncounterRuntimeFactory.tryCreate()` 为五关均返回真实 runtime，并创建 AI、director、objective、token budget 与 actor roster。
- 新合同以真实 reducer 连续推进全部五关，检查实际敌人生成、敌方 intent、击杀事件、目标终局、Boss 身份、玩家存活及生产上限内无 timeout；fixture、字符串存在或 legacy mapper 均不计通过。
- `stage_03_04` 只把 `ch3_s04_commander_01` 标记为 Boss；`stage_03_05` 只把 `ch3_s05_commander_01` 标记为 Boss，外门随从不冒充 commander。

## RED 与破坏证

- 初始有效 RED：新增六项生产合同在零接线基线上为 `0/6`，分别暴露缺失 assignment、catalog identity、factory/runtime、objective、Boss identity 与动态 route。
- 方向一 `remove_implementation`：临时删除 `stage_03_03` assignment，repository fail-closed 于 `setUpAll`，精确 `1` 条失败；反向补丁还原后文件 SHA-256 回到 `51b67a5c0c2b9aa2bd40a37e8e43eb7342dd75fb7ec96b9f34019ea33e55bf16`，定向恢复 `6/6`。
- 方向二 `force_degenerate_value`：临时把 `stage_03_05` objective commander 改为外门随从，目标合同与 Boss 身份精确 `2` 条失败；反向补丁还原后 encounter SHA-256 回到 `60f4e38c5bd908d6d87c6eafb458127620f79d59bde24757530a30bf24bd9294`，定向恢复 `6/6`。

## 验证收据

- 直接定向：`flutter test --no-pub test/data/phase2/ch3_content_migration_test.dart -r expanded` → `6/6`。
- Phase 2 相邻回归：`flutter test --no-pub test/data/phase2 -r expanded` → `78/78`。
- 主线应用相邻回归：`flutter test --no-pub test/features/mainline/application -r expanded` → `183/183`。
- `flutter analyze --no-pub lib test tool`：`No issues found!`。
- `dart format .`：`1717 files (0 changed)`；`git diff --check` 通过。
- 持锁整仓 `flutter test --no-pub -r expanded`：`5887/5887`、`[E]` 块 `0`、退出码 `0`；令牌校验后锁已精确释放。
- 标准 Gate 对六文件实现范围 `52a4255f..f979e82a` 在独立 detached worktree 复跑：full `5887/5887`、analyze 0 issue、format `1717 files (0 changed)`、receipt matched，最终 `PASS`。
- Gate 的内建 `forbidden_files` 规则排除 `PROGRESS.md`。因此用户明确要求的 PROGRESS、registry、P0 远端事实刷新作为随后治理尾提交处理；这些文档经 YAML 解析、`git diff --check`、最终状态与人工 diff 审阅验证，但不冒充已被上述自动 Gate 覆盖。

## 状态边界与挂账

- 第三章已进入 main/origin：精确 SHA 为 `9efcdeb6f7147070be891b2c2e08138651267317`；exact-SHA CI run `33630424378` 已实时确认为 `completed/success`，`macos-build`、格式、analyze、coverage tests 与 ratchet 均成功。
- 上述集成与 CI 只闭合第三章工程事实，不替代后续章节候选 CI，也不代签真人验收。
- 普通存档平衡、真人手感、视觉、音频、桌面操作与 Windows 全部 `DEFERRED`；`stage_02_05` 高基础随从风险继续挂账，本候选未处理。
- M7 的验收目标仍为主线 `105/105`、塔 `49/49`、legacy runtime consumers `0`；第三章 `5/5` 仅增加候选分子，不关闭正式 M7，也不改变 Phase 2 `1/10`。
