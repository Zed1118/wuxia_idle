# Phase 2 M7 第九章内容迁移审计（2026-09-03）

## 结论

第九章 `stage_09_01..05` 的 StageDef 与 13 份正文原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批将实际缺口由 `0/5 → 5/5`，接入真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链，全主线 typed catalog 形成 `41/105 → 46/105` 的工程候选。

候选尚未独立复核、未合并、未 push；main 与 origin/main 仍为 `972bc6d413b7c7d2dbf911467b076bdb5c4781b7`，工程集成水位仍是 `41/105`。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。

## 生产接线与语义边界

| stage | encounter | StageDef 基敌 | 目标 | 正文阵容 / 同时上限 |
| --- | --- | --- | --- | --- |
| `stage_09_01` | `ch9_encounter_01_pass_bandits` | `enemy_erLiu_qibei_guanmazei` | defeat all | 4 / 3 |
| `stage_09_02` | `ch9_encounter_02_bone_dunes` | `enemy_erLiu_qibei_baiguo_shadao` | defeat all | 3 / 1 |
| `stage_09_03` | `ch9_encounter_03_mirage` | `enemy_erLiu_qibei_shenlou_huanjing` | defeat target | 1 / 1 |
| `stage_09_04` | `ch9_encounter_04_cliff_guardian` | `enemy_erLiu_qibei_aikou_shouwei` | defeat commander | 1 / 1 |
| `stage_09_05` | `ch9_encounter_05_old_master` | `enemy_erLiu_qibei_nayiwei` | defeat commander | 1 / 1 |

正文保守名单冻结为 `4 / 3 / 1 / 1 / 1`：09-01 是刀疤首领与三个最低复数随从，09-02 是双刀首领与两个最低复数侧翼，09-03 是单一无形蜃影，09-04/05 均为单 Boss。灰衣人只作为幻象线索，没有凭空加入敌方阵容。

09-01 复用刀匪近战生态，09-02 复用西凉沙刀，09-03/05 复用基础近战，09-04 复用军阵盾卫；复用层只提供 AI、姿态与表现资源。五组 `base_enemy_id` 精确等于各自 `StageDef.enemyTeam.single`，09-04/05 的名称、原图、全技能、蓄力技、Boss 阶段与 `createActor` 身份均保持原值。未改 `stages.yaml`、`numbers.yaml`、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。

动态探针显示 09-01 四人同屏会战败、三人可胜；09-02 的轻功模板在并发 3/2/1 均战败，换成语义更贴近沙盗双刀的沙刀模板后并发 3/2 仍战败，单人轮换可胜。最终只调整 encounter 同时上场节奏，未修改敌我数值。

## RED 与变异证明

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均未闭环。
- 删除 `stage_09_01` assignment，loader 精确拒绝未被任何 stage 引用的 encounter。
- 将 `stage_09_05.base_enemy_id` 错绑为 09-04 基敌，loader 精确拒绝与唯一 `StageDef.enemyTeam` 不一致。
- 将 `ch9_s03_mirage` 在 manifest、spawn 与 objective 中同步改名，结构闭包仍成立，但 exact actor-set 语义断言精确转红。
- 三次均以反向补丁恢复。SHA-256：manifest `95c487e2a5cc3f54061f3a0852804efcbb123b0cd8e67d38c641fff6cfea23f4`、assignments `bc644dec9c40923103456081c05e831c0eb79f1286fcc496b28958f89f5ef34e`、encounter `0c6a375f86c36693cbce20d6e62cd56be09bcd28e27ba161b49a1bd8a06f3a49`、runtime `3f751bc4d8ae38838d12f79a15d2fd6c590a8f3750bd7889a6950f9e9dddff8a`、test `41bd765b4c89718bb550f7d68af9f4753c0e8fd862ff0b7b9042da540692305d`；恢复后 targeted 再次 `6/6`。

## 验证结果

| 门 | 结果 |
| --- | --- |
| 第九章 targeted | `6/6` |
| 第八、九章 adjacent | 各 `6/6`，合计 `12/12` |
| Phase 2 data adjacent | `114/114` |
| mainline application adjacent | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1723 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub -r expanded` | `5923/5923`，`All tests passed!` |
| full-test lock | 首次 trap 使用不存在的 `/usr/bin/unlink` 留下空锁；随后以系统 `/bin/unlink` 精确释放并确认不存在 |
| 测试契约迁移门 | `expect 删 1 / 增 29；用例删 0 / 增 6；登记 1`；`PASS` |

第八章旧测试的全局精确水位 `41` 改为已集成下限 `>=41`，第九章新测试以精确 `46` 守住本批增量。删除已逐条登记在 `p2-m7-ch9-content-migration-20260903.yaml`，专用机器门核对通过。

## Gate 与挂账

实现提交为 `2d3e31a37029941afe9c4a4065205143aec3e9c4`，相邻测试契约提交为 `43243b339dd7ee480d275a7277557dfcf4de2d3b`。最终 `[READY]` tip 必须在评审时由 `git rev-parse HEAD` 实时解析，并以该 exact tip 复跑标准 Gate；文档不会预写尚未发生的 PASS。

预计标准 Gate 原生会拒绝项目要求更新的 `PROGRESS.md` 与已由专用门登记的单条测试断言删除；原始判决必须保留，不能改写为脚本原生 PASS。只有 full test、analyze、format、commit message、clean 等其余项全部通过，测试删除才能按项目唯一例外单独组合判断。

工程候选不等于正式 M7 或真人验收；桌面实战、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
