# Phase 2 M7 第九章内容迁移审计（2026-09-03）

## 结论

第九章 `stage_09_01..05` 的 StageDef 与 13 份正文原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批将实际缺口由 `0/5 → 5/5`，接入真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链，全主线 typed catalog 工程集成水位由 `41/105 → 46/105`。

修复后内容 tip `b353002df3cf95aa58144890e20c5d0a9f738af3` 已 fast-forward 进入 `main` 与 `origin/main`；exact-SHA CI run `33726947681` 明确为 `completed/success`。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。

## 生产接线与语义边界

| stage | encounter | StageDef 基敌 | 目标 | 正文阵容 / 同时上限 |
| --- | --- | --- | --- | --- |
| `stage_09_01` | `ch9_encounter_01_pass_bandits` | `enemy_erLiu_qibei_guanmazei` | defeat all | 4 / 3 |
| `stage_09_02` | `ch9_encounter_02_bone_dunes` | `enemy_erLiu_qibei_baiguo_shadao` | defeat all | 3 / 3 |
| `stage_09_03` | `ch9_encounter_03_mirage` | `enemy_erLiu_qibei_shenlou_huanjing` | defeat target | 1 / 1 |
| `stage_09_04` | `ch9_encounter_04_cliff_guardian` | `enemy_erLiu_qibei_aikou_shouwei` | defeat commander | 1 / 1 |
| `stage_09_05` | `ch9_encounter_05_old_master` | `enemy_erLiu_qibei_nayiwei` | defeat commander | 1 / 1 |

正文保守名单冻结为 `4 / 3 / 1 / 1 / 1`：09-01 是刀疤首领与三个最低复数随从，09-02 是双刀首领与两个最低复数侧翼，09-03 是单一无形蜃影，09-04/05 均为单 Boss。灰衣人只作为幻象线索，没有凭空加入敌方阵容。

09-01 复用刀匪近战生态，09-02 复用西凉沙刀，09-03 复用与 StageDef 阴柔流派一致的轻功生态，09-04 复用军阵盾卫，09-05 的基础近战角色仅提供行为壳；复用层只提供 AI、姿态与表现资源。五组 `base_enemy_id` 精确等于各自 `StageDef.enemyTeam.single`，09-04/05 的名称、原图、全技能、蓄力技、Boss 阶段与 `createActor` 身份均保持原值。未改 `stages.yaml`、`numbers.yaml`、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。

动态探针显示 09-01 四人同屏会战败、三人可胜。09-02 的轻功模板在并发 3/2/1 均战败，换成语义更贴近沙盗双刀的沙刀模板后，近战令牌为 3 时并发 3/2 仍战败、单人轮换可胜。合入复核指出单人轮换与正文“三人散开、前后合围”冲突；修复后保持三人同场，将近战攻击令牌收为 1、入场攻击宽限由 10 调为 30 拍，动态胜利与正文阵形同时成立。09-03 同步从刚猛基础近战改为阴柔轻功生态。以上均只调整本批 encounter/runtime 编排，未修改 StageDef、敌我基础数值或技能定义。

## RED 与变异证明

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均未闭环。
- 删除 `stage_09_01` assignment，loader 精确拒绝未被任何 stage 引用的 encounter。
- 将 `stage_09_05.base_enemy_id` 错绑为 09-04 基敌，loader 精确拒绝与唯一 `StageDef.enemyTeam` 不一致。
- 将 `ch9_s03_mirage` 在 manifest、spawn 与 objective 中同步改名，结构闭包仍成立，但 exact actor-set 语义断言精确转红。
- 三次均以反向补丁恢复；合入复核修复后的 SHA-256：manifest `95c487e2a5cc3f54061f3a0852804efcbb123b0cd8e67d38c641fff6cfea23f4`、assignments `bc644dec9c40923103456081c05e831c0eb79f1286fcc496b28958f89f5ef34e`、encounter `bfd0856bb2f59d803041a51650ae81c5efa4f913ff232f777bfb842537aec68d`、runtime `6d68f76b50421d01b17457f6e2d987ffd2e10b85e14b362fe6557f098cd3054f`、test `9f8d30b597a57be5568565d9574289b589eb4a7b071ec7d11d9714af215424d2`；修复后 targeted 再次 `6/6`。

## 验证结果

| 门 | 结果 |
| --- | --- |
| 第九章 targeted | `6/6` |
| 第八、九章 adjacent | 各 `6/6`，合计 `12/12` |
| Phase 2 data adjacent | `114/114` |
| mainline application adjacent | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1723 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub -r expanded` | 合入复核修复后重跑 `5923/5923`，`[E] 0`，`All tests passed!` |
| full-test lock | 修复后以独占目录锁执行并自动释放，结束后确认锁不存在 |
| 测试契约迁移门 | `expect 删 1 / 增 35；用例删 0 / 增 6；登记 1`；`PASS` |

第八章旧测试的全局精确水位 `41` 改为已集成下限 `>=41`，第九章新测试以精确 `46` 守住本批增量。删除已逐条登记在 `p2-m7-ch9-content-migration-20260903.yaml`，专用机器门核对通过。

## Gate 与挂账

实现提交为 `2d3e31a37029941afe9c4a4065205143aec3e9c4`，相邻测试契约提交为 `43243b339dd7ee480d275a7277557dfcf4de2d3b`，修复后 `[READY]` 内容 tip 为 `b353002df3cf95aa58144890e20c5d0a9f738af3`。

该 exact tip 的标准 Gate 实测 full `5923/5923`、`[E] 0`、analyze、format、commit message 与 clean 均通过，receipt 因零 `lib/` 改动按规则跳过；原始终行如实为 `FAIL: forbidden_files,test_deletions`，分别对应项目要求更新的 `PROGRESS.md` 与已由专用门登记的单条测试断言删除，不改写成脚本原生 PASS。专用迁移门为 `PASS`。内容 tip 的 exact-SHA CI run `33726947681` 中 test、macOS build 及所有子步骤均成功；随后治理尾只同步已发生事实，其 exact-SHA CI 必须在推送后实时核验。

合入复核结论：发现 1 个 P1 叙事并发偏差并在候选内修复，复核后无剩余 P0/P1；本轮为主代理的独立审计维度复核，未冒充独立 agent 或真人验收。工程候选不等于正式 M7；桌面实战、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
