# 第十三章生产合同修复验收（2026-09-05）

## 核心结论

本批修复身份/技能、数值保真、分层入场三类已证实缺陷；用户已追加集成授权，固定修复合同 `3/3` 已合入并推送 main，本地验证及 merge exact-SHA CI 全部通过。主线目录仍为 `105/105`、塔为 `0/49`，正式里程碑仍为 `1/10 = 10%`，不以工程修复或 CI 替代正式/真人验收。

开工基线为 clean 的 `main == origin/main == 2d254abdf9bd841730acc301867c1249dde2ebc4`；[基线 CI](https://github.com/Zed1118/wuxia_idle/actions/runs/33901066970) 为 `completed/success`。原修复候选 `21ad6e60b075751f42c090ef87a998a8186c1c0a` 保留；为遵守禁改门，将 PROGRESS 同步移至授权治理尾，受检候选为 `cb824b534e7b4ed9e59ef21379eae8ca5846df9a`，其 `lib/data/test` 与原候选逐字一致。no-ff merge 为 `261f2daf17e4357aaf12a04b86775dc64aa1164a`，[merge exact-SHA CI](https://github.com/Zed1118/wuxia_idle/actions/runs/33935197099) 已核验 `completed/success`，test 与 macos-build 两个 job 均成功。未新增持久 worktree、未删除原分支，Gate 自建的临时 detached worktree 已自动回收。

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
| 原候选预检 | `21ad6e60` 原始判决 `FAIL: forbidden_files (full_test SKIPPED)`，仅命中 PROGRESS；未直接放行或修改 Gate |
| 完整标准 Gate | `cb824b53` 原生 `PASS`，6017/6017、analyze、1741/0 format、白名单/无测试删除/commit/clean/receipt 全通过，exit 0 |
| 提交后双向 mutation | 删除依赖守卫及强制关闭源保真分别 1 FAIL；反向 patch 后 git diff 为空、SHA-256 恢复，Ch13 11/11 |
| main 合并验证 | analyze 0 issue；定向 288/288；format 1742/0；全量 6017/6017、exit 0；代码/数据/测试与受检候选一致 |
| merge exact-SHA CI | `33935197099` / `261f2daf`：`completed/success`；测试与覆盖率门槛通过，test job 09:07:38–09:34:22 CST，macOS debug 构建通过 |

初次修复的 analyze/format/full 原始日志保留在 ignored 的 `build/phase2_ch13_contract_fix/`，初始 RED 与三个 mutation 的原始执行输出亦提取至该处，不提交日志或生成文件。只记录实际可观测墙钟，不以 reporter 时间推算整批工时；当时一轮新增持锁全量预算已使用 1/1。正式 Gate 增量为 0，候选合同增量为 3/3，尚未开始 main 集成。测试退出清理曾用错 unlink 路径，已核对 token 和退出 PID 后仅释放自身锁，不影响测试结果，未删除他人锁。

上段为初次本地交付成本。追加集成授权后，为同时满足候选 Gate 与批末 main 规则，又跑 2 轮全量：Gate 墙钟 08:36:34–08:53:28（1014 秒，包含隔离环境准备及检查）；main 全量 08:54:44–09:07:20（756 秒）。两次锁均仅由所有者释放。集成阶段发生 1 次治理分离，生产改动返工/合并冲突为 0；工程修复 3/3 进入 main，正式增量仍为 0。main 格式计数多 1 源于原有 ignored `lib/features/battle/application/battle_providers.g.dart`，未动或提交。后续治理尾只同步事实，不重复本地全量，其最终 SHA 的 CI 在交付时另行核验。

## 残留风险与下一步

- no-ff 集成、main 验证、push 及 merge exact-SHA CI 已完成；治理尾仅同步以上事实，其最终 SHA/CI 与 clean 证据以交付记录为准。
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
