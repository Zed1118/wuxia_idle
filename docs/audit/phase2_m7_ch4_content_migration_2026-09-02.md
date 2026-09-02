# Phase 2 M7 第四章生产内容迁移审计

## 核心结论

- 开工前复核 `main == origin/main == 9efcdeb6f7147070be891b2c2e08138651267317` 且主 checkout clean；第三章 exact-SHA CI run `33630424378` 为 `completed/success`。
- 有时限只读审计确认按主线顺序第一个不完整章节是第四章，而不是直接假定下一章：`stage_04_01` 已迁移，`stage_04_02..05` 的 `StageDef` 完整但 assignment、encounter 与 runtime binding 为 `0/4`，生产 factory 返回 null 后落回 legacy mapper。
- 本候选把第四章从 `1/5` 推至 `5/5`，全主线 typed production catalog 候选从 `19/105` 达 `23/105`；`origin/main` 的集成事实仍为 `19/105`，塔仍为 `0/49`。正式 M7 继续开放，Phase 2 仍为 `1/10`。
- 只复用已集成的 `ch4_xiliang` 生态、production factory、runtime binding、目标原语和 Phase 0A reducer/flow；没有修改 `stages.yaml`、`numbers.yaml`、生产 Dart、敌人/玩家数值、Boss 招式、掉落、奖励、经济、叙事、解锁、周目、结算 owner、Isar、`schemaVersion` 或 `saveVersion`。

## 生产路径证据

| 关卡 | encounter | 基敌（沿用 StageDef） | 编成 / 激活 | 目标 |
|---|---|---|---:|---|
| `stage_04_01` | `ch4_encounter_01_xiliang_crossing` | `enemy_yiLiu_liukou_a` | 25 / 10 | 全歼 |
| `stage_04_02` | `ch4_encounter_02_yumen_caravan` | `enemy_yiLiu_guard_a` | 3 / 3 | 全歼 |
| `stage_04_03` | `ch4_encounter_03_desert_maze` | `enemy_yiLiu_shafei_a` | 25 / 10 | 全歼 |
| `stage_04_04` | `ch4_encounter_04_xiliang_duel` | `enemy_yiLiu_xiliangboss` | 3 / 3 | 斩将且清除两名必杀随从 |
| `stage_04_05` | `ch4_encounter_05_yangguan_finale` | `enemy_jueDing_xiliangbazhu` | 2 / 2 | 仅斩指定 commander |

- `CombatCatalogRepository.loadProduction()` 读取 manifest、assignment、encounter 与 runtime binding；`createFreshPhase0aMainlineEncounter()` 经 production factory 为五关创建真实 actor roster、enemy AI、director、objective 和 token binding。
- 动态合同以真实 bot、host 和 reducer 连续推进五关，逐关验证实际击杀事件、胜利终局、玩家存活、非 timeout 与生产最大 tick 约束；fixture 或字符串存在不计通过。
- `stage_04_04` 只保留 `ch4_s04_commander_01` 的 Boss 身份；`stage_04_05` 只保留 `ch4_s05_commander_01` 的 Boss 身份，并从既有 `StageDef` 继承西凉霸主的招式、蓄力技与阶段配置。随从均不冒充 Boss。

## RED、破坏证与测试契约

- fresh worktree 首次运行因 `.g.dart` 被 gitignore 而编译失败；按 `CLAUDE.md §9.1` 跑 build runner 后，才取得可归因的有效初始 RED `0/6`：分别暴露 assignment/catalog、identity、factory/runtime、objective、Boss identity 与动态 route 缺口。环境失败没有冒充产品 RED。
- 方向一 `remove_implementation`：临时删除 `stage_04_03` assignment，repository fail-closed，精确 `1` 条失败；反向补丁还原后 assignment SHA-256 回到 `701bd6fab67b8537d9993e01e32637f819a49a07156a1c275fd7f003270327a4`，定向恢复 `6/6`。
- 方向二 `force_degenerate_value`：临时把 `stage_04_05` commander objective 改为普通随从，objective 与 Boss identity 精确 `2` 条失败；反向补丁还原后 encounter SHA-256 回到 `fa3935f4c21b2c2d8ae28481996808cd61c50a97b6a5b1118635b350e1c626ea`，定向恢复 `6/6`。
- 第三章测试原先把全局 catalog 水位写死为 `19`，本批改为保留 `>=19` 的第三章下限，第四章新合同另钉精确 `23`。登记表仅含这一条删除；专用校验器实测 `expect 删 1 / 增 38`、用例 `删 0 / 增 6`、登记 `1`，输出 `PASS: test_contract_migration`。

## 验证收据

- 直接定向：`flutter test --no-pub test/data/phase2/ch4_content_migration_test.dart -r expanded` → `6/6`。
- 主线应用相邻回归：`flutter test --no-pub test/features/mainline/application -r expanded` → `183/183`。
- Phase 2 相邻回归：`flutter test --no-pub test/data/phase2 -r expanded` → `84/84`。
- `flutter analyze --no-pub lib test tool`：`No issues found!`；`dart format .`：`1718 files (0 changed)`；`git diff --check` 通过。
- 首轮持锁整仓 `flutter test --no-pub -r expanded`：`5893/5893`、`[E]` 块 `0`、退出码 `0`；token 校验后锁精确释放。
- 标准 Gate 对八文件实现范围 `9efcdeb6..7cded518` 在独立 detached worktree 持锁复跑：full `5893/5893`、`[E]` 0、analyze 0 issue、format `1718 files (0 changed)`；`forbidden_files`、白名单、commit message、worktree clean、full、analyze、format 均 PASS，receipt 因零 `lib/` 改动按规则 SKIP，原始 Gate 唯一红项为 `test_deletions=1`。结合上述专用测试契约迁移 PASS，按唯一例外口径 Gate 通过。
- Gate 实现范围不含随后明确要求的 PROGRESS、registry 与审计治理尾提交；这些文件另经 YAML 解析、`git diff --check`、状态与人工 diff 审阅，不冒充自动 Gate 覆盖。

## 状态边界与挂账

- 已实现、已验证不等于已进入 main/origin。本候选位于 `codex/p2-m7-ch4-content-migration-20260902`；未经用户再次授权不 merge、不 push，因此没有第四章候选的远端 CI。
- 第三章 exact-SHA CI 成功只闭合第三章工程集成，不替代第四章候选 CI。
- 普通存档平衡、真人手感、视觉、音频、桌面操作与 Windows 全部 `DEFERRED`；`stage_02_05` 高基础随从风险继续挂账，本候选未处理。
- M7 目标仍为主线 `105/105`、塔 `49/49`、legacy runtime consumers `0`；第四章 `5/5` 仅增加候选分子，不关闭正式 M7，也不改变 Phase 2 `1/10`。
