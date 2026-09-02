# Phase 2 M7 第五章生产内容迁移审计

## 核心结论

- 开工前复核 `main == origin/main == 04276bdcebc33d123a3baafdd3cdbd5a7da81a17` 且主 checkout clean；第四章 exact-SHA CI run `33636410141` 为 `completed/success`。
- 有时限只读审计确认按主线顺序第一个不完整章节是第五章：`stage_05_01..05` 的 `StageDef` 与叙事三人阵容完整，但 assignment、encounter 与 runtime binding 均为 `0/5`，生产 factory 返回 null 后落回 legacy mapper。
- 本候选把第五章从 `0/5` 推至 `5/5`，全主线 typed production catalog 候选从 `23/105` 达 `28/105`；`origin/main` 的集成事实仍为 `23/105`，塔仍为 `0/49`。正式 M7 继续开放，Phase 2 仍为 `1/10`。
- 只复用已集成的军阵、门派、匪帮与西凉生态、production factory、runtime binding、目标原语和 Phase 0A reducer/flow；没有修改 `stages.yaml`、`numbers.yaml`、生产 Dart、敌人/玩家数值、Boss 招式、掉落、奖励、经济、叙事、解锁、周目、结算 owner、Isar、`schemaVersion` 或 `saveVersion`。

## 生产路径证据

| 关卡 | encounter | 基敌（沿用 StageDef） | 编成 / 激活 | 目标 |
|---|---|---|---:|---|
| `stage_05_01` | `ch5_encounter_01_weishui_crossing` | `enemy_jueDing_tongguan_shoujiang` | 3 / 3 | 全歼叙事三人 |
| `stage_05_02` | `ch5_encounter_02_songshan_temple` | `enemy_jueDing_songshan_daozong_dizi` | 3 / 3 | 全歼叙事三人 |
| `stage_05_03` | `ch5_encounter_03_yellow_river_ferry` | `enemy_jueDing_caobang_duozhu` | 3 / 3 | 全歼叙事三人 |
| `stage_05_04` | `ch5_encounter_04_zhongzhou_tournament` | `enemy_jueDing_zhongzhou_lunjian_xianfeng` | 3 / 3 | 斩将且清除两名必败副手 |
| `stage_05_05` | `ch5_encounter_05_songshan_finale` | `enemy_zongShi_xiliang_sandizi` | 3 / 3 | 斩将且清除中州、嵩山两名副手 |

- `CombatCatalogRepository.loadProduction()` 读取真实 manifest、assignment、encounter 与 runtime binding；`createFreshPhase0aMainlineEncounter()` 经 production factory 为五关创建 actor roster、enemy AI、director、objective 和 token binding。
- 动态合同以真实 bot、host 和 reducer 连续推进五关，逐关验证三次实际击杀、胜利终局、玩家存活、非 timeout 与生产最大 tick 约束；fixture 或字符串存在不计通过。
- `stage_05_04` 只保留 `ch5_s04_commander_01` 的 Boss 身份；`stage_05_05` 只保留 `ch5_s05_commander_01` 的 Boss 身份，并从既有 `StageDef` 原样继承西凉霸主三弟子的招式、蓄力技、Boss 阶段与周目阶段。四名 Boss 关副手均剥离 Boss 身份与机制。

## RED、破坏证与测试契约

- fresh worktree 首次运行因 gitignored `.g.dart` 缺失而编译失败，且新测试有一次 API 名称误用；两项均修复后才取得可归因的有效初始 RED `0/6`：分别暴露 assignment/catalog、identity、factory/runtime、objective、Boss identity 与动态 route 缺口。环境或测试自身错误没有冒充产品 RED。
- 方向一 `remove_implementation`：临时删除 `stage_05_01` assignment，repository fail-closed，精确 `1` 条失败；反向补丁还原后 assignment SHA-256 回到 `f3e2250f16a3debab19212dd81eb25327f58a6494af1be9ed43f88e7f24152db`。
- 方向二 `force_degenerate_value`：临时把 `stage_05_05` commander objective 指向嵩山副手，Boss 身份合同精确 `1` 条失败；反向补丁还原后 encounter SHA-256 回到 `040738cc986846f7dded9caf45dff90540b89db5a6dea9dfd13fae6c64c533b1`。
- 第四章测试原先把全局 catalog 水位写死为 `23`，本批改为保留 `>=23` 的第四章下限，第五章新合同另钉精确 `28`。专用校验器输出 `[migration] expect 删 1 / 增 36;用例 删 0 / 增 6;登记 1 条` 与 `PASS: test_contract_migration`。

## 验证收据

- 直接定向：`6/6`；Phase 2 相邻回归：`90/90`；主线应用相邻回归：`183/183`。
- `flutter analyze --no-pub lib test tool`：`No issues found!`；`dart format .`：`1719 files (0 changed)`；`git diff --check` 通过。
- 持锁整仓 `flutter test --no-pub -r compact`：`5899/5899`、`[E]` 块 `0`、退出码 `0`，末行 `11:19 +5899: All tests passed!`；锁精确释放。
- 标准 Gate 对八文件实现范围 `04276bdc..440defc1` 在独立 detached worktree 持锁复跑：full `5899/5899`、`[E]` 0、analyze 0 issue、format `1719 files (0 changed)`；`forbidden_files`、白名单、commit message、worktree clean、full、analyze、format 均 PASS，receipt 因零 `lib/` 改动按规则 SKIP，原始 Gate 唯一红项为 `test_deletions=1`。结合上述专用测试契约迁移 PASS，按唯一例外口径 Gate 通过。
- 效率样本：验收门变化为第五章 `0/5 → 5/5`、候选 catalog `23/105 → 28/105`；从首个实现提交至 Gate 返回约 31 分钟；主成本读数为首次全量 `11:19` 与 Gate 独立全量 `11:24`；集成返工仅 1 条第四章全局水位守卫迁移。

## 状态边界与挂账

- 已实现、已验证不等于已进入 main/origin。本候选位于 `codex/p2-m7-ch5-content-migration-20260902`；未经用户再次授权不 merge、不 push，因此没有第五章候选的远端 CI。
- 第四章 exact-SHA CI 成功只闭合第四章工程集成，不替代第五章候选 CI。
- 普通存档平衡、真人手感、视觉、音频、桌面操作与 Windows 全部 `DEFERRED`；`stage_02_05` 高基础随从风险继续挂账，本候选未处理。
- M7 目标仍为主线 `105/105`、塔 `49/49`、legacy runtime consumers `0`；第五章 `5/5` 仅增加候选分子，不关闭正式 M7，也不改变 Phase 2 `1/10`。
