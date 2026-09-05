# 第十三章生产合同修复验收（2026-09-05）

## 核心结论

本批修复身份/技能、数值保真、分层入场三类已证实缺陷，固定合同已达本地候选 `3/3`；独立复核和最终持锁全量通过，交付为 `[READY]` 本地候选。主线目录仍为 `105/105`、塔为 `0/49`，正式里程碑仍为 `1/10 = 10%`。不把目录覆盖、候选或绿测写成 main 已修复。

基线为 clean 的 `main == origin/main == 2d254abdf9bd841730acc301867c1249dde2ebc4`；已重新核对 [该 SHA 的 CI](https://github.com/Zed1118/wuxia_idle/actions/runs/33901066970) 为 `completed/success`。修复分支 `codex/p2-m7-ch13-contract-fix-20260905` 复用既有工作树，未合入/push main，未新增 worktree 或删除旧分支。

| 已证实问题 / 根因 | 本批措施 | 验证标准与边界 |
| --- | --- | --- |
| 13-01/03 的 StageDef 姓名、立绘及技能被生态 variant 替换 | 单敌数据显式启用 `preserve_source_contract`，适配器保留原 assembled snapshot | 精确比较名字、图标、全部技能 ID、基础攻击及技能绑定；其他章节不开启 |
| 13-03/05 即使保留 identity 仍套用 variant 数值倍率 | 四场单敌战直接保留对应周目的原 snapshot，不修改源数值或周目公式 | 13-01/03/04/05 × cycle 1/2 比较 HP、速度、攻击、防御、内力与真气；既有 Boss 合同回归保留 |
| 知客僧仅在 YAML 排末，director 按 ID 排序后仍提前出现 | commander 显式依赖其余 24 个 entry 被击败，真实 flow 的击败事件驱动解除依赖 | 预警与入场均不得早于第 24 次击败；保留最后一人跨多次补兵检查，并运行真实工厂的动态胜利事件断言 |

## 生产接线与独立复核

`GameRepository → typed catalog/loader → mainline runtime adapter → encounter factory → runtime contract mapper → SpawnDirector → encounter flow` 已逐段检查实际 diff。新增保真开关只出现在 Ch13 四个 singleton；数据构造拒绝多敌保真配置。依赖在 typed definition 与 director 两层拒绝空白、重复、悬空、自引用及循环；`allActive` 拒绝绕过依赖。生产代码唯一 `markExited` 消费点位于 `phase0a_encounter_flow.dart` 的 `Phase0aEnemyDefeated` 循环，因此本批配置的“击败后入场”不是仅凭列表位置或人数猜测。

主窗口已独立复核实际生产代码、测试断言和共享影响，未发现新增阻断项。25 人、10 active、2/1/1/1 token、all 目标组合、非 Boss commander 与原 Boss 机制保持不变。动态胜利测试覆盖五关 cycle 1；双周目覆盖的是原始数值保真，不外推为双周目整场 parity。

## 验证证据

| 检查 | 结果 |
| --- | --- |
| 初始 RED | 已复核原始执行日志：原 8 项仍过，新增身份、数值、提前入场 3 项失败 |
| Ch13 / loader / director | `68/68 PASS` |
| 相邻及共享回归 | `288/288 PASS`，含 Ch3/12/14、M4 生态、主线 application、director、catalog/schema/runtime mapper |
| 三向 mutation | 保真开关、Boss 数值保留、依赖守卫分别破坏后各出现 1 项失败，原始日志已复核；反向 patch 后主窗口重算三份 SHA-256 与冻结值一致，恢复后定向重绿 |
| 独立代码复核 | 生产消费者、失败路径、默认行为、测试强度与保护边界已核对 |
| analyze | `flutter analyze --no-pub lib test tool`：0 issue，exit 0 |
| format | `dart format --output=none --set-exit-if-changed .`：1741 files，0 changed，exit 0 |
| 最终持锁全量 | `flutter test --no-pub --reporter expanded`：`6017/6017 PASS`，exit 0；08:16:20–08:25:12 CST，实际 8 分 52 秒；08:25:22 自有锁释放后主窗口复查锁不存在 |
| 测试删除审计 | 三个测试文件均为纯新增，0 行删除，新增 7 用例、22 处 expect；迁移删除登记门不适用 |
| 标准合并 Gate | 本批未运行，也不声称通过；main 合入授权及合并前 Gate/新 exact-SHA CI 留待后续 |

最终 analyze/format/full 原始日志保留在 ignored 的 `build/phase2_ch13_contract_fix/`，初始 RED 与三个 mutation 的原始执行输出亦提取至该处，不提交日志或生成文件。只记录实际可观测墙钟，不以 reporter 时间推算整批工时；一轮新增持锁全量预算已使用 1/1。正式 Gate 增量为 0，候选合同增量为 3/3，main 集成返工尚未发生。测试退出清理曾用错 unlink 路径，已核对 token 和退出 PID 后仅释放自身锁，不影响测试结果，未删除他人锁。

## 残留风险与下一步

- 本地修复不等于 main 修复；须获授权后做 no-ff 集成、适配风险的合并验证、push 和 merge exact-SHA CI。
- 未跑本批可见桌面 smoke、真人手感/视觉/音频或 Windows，均不代签。未改源敌人数值、奖励、经济、解锁、叙事、存档 schema/saveVersion；本批没有新增平衡值，但会纠正错误倍率造成的实战偏差。
- 塔仍需先补目标 allowlist/完整击杀集合、三入口行为验证与完整 parity，再谈 49 层迁移；M0 接线/实测和 M2–M6 真人门仍挂账。本批不开始这些施工，也不退役 legacy 接缝。

恢复入口：[修复计划](../superpowers/plans/2026-09-05-p2-m7-ch13-contract-fix.md)。历史 Ch13 与塔审计、M0 候选 SHA 已同批纠偏，不抹掉原验收记录。

## 附录：定向复现命令

```sh
flutter test --no-pub --reporter expanded \
  test/data/phase2/ch13_content_migration_test.dart \
  test/data/phase2/ch3_content_migration_test.dart \
  test/data/phase2/ch12_content_migration_test.dart \
  test/data/phase2/ch14_content_migration_test.dart \
  test/data/phase2/m4_remaining_ecologies_production_test.dart \
  test/features/mainline/application \
  test/features/battle/domain/phase0a/spawn_director_test.dart \
  test/data/combat_encounter_catalog_loader_test.dart \
  test/data/defs/combat_catalog_schema_gateway_test.dart \
  test/data/validation/combat_encounter_runtime_contract_mapper_test.dart
```

初始 RED 为单独运行 Ch13 文件；三次 mutation 用该文件的 `--plain-name` 分别定位 `authored singleton identities retain icons and complete skills`、`all four singleton routes preserve source numbers in both cycles`、`real factory withholds the usher until all 24 examiners exit`。未删除原测试或放宽预期。
