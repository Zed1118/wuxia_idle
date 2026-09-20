# E 单黄金文件搬迁与审计空登记清理

- 目标：将六个黄金文件原样搬到 `test/tools/golden/`，同步三条测试与两份审计文档的路径，删除扫描器对已删公式段的三处空登记。
- 分支：`codex/golden-relocate-20260920`。
- 工作区：`/Users/a10506/Codex/2026-09-20/golden-relocate/wt`。
- 基线：`b99cfa72da23b088d9d98891458d270b1028814a`。
- 边界：严格遵守派单路径白名单；不改黄金文件内容、测试断言、判零口径、配置或生产代码，不安装软件、不启动游戏、不碰真实存档、不推送或合并。

## 验收标准与任务切片

1. 干净基线逐文件运行三条 diagnostic 测试并通过。
2. 六个文件通过 `git mv` 搬迁，逐字节一致且显示六个 `100%` 重命名；旧目录无跟踪文件，新目录六个跟踪文件且不被忽略，保留旧目录供产物写入。
3. 三条测试仅替换路径；idle 与 full 两条刷新分支各补父目录创建。断言、刷新开关、比对逻辑全部保持原样。两份文档仅替换路径。
4. 扫描器仅清三处空登记；重扫及逐叶核对，确认零引用与标记计数无回归，`tools` 下旧登记零命中。
5. 改后逐文件运行三条 diagnostic 与资产审计；临时改一个 CSV 字节证红，精确还原后复跑绿。
6. 完成指定范围 analyze、全仓只读 format、共享锁保护的前台全量测试；保存原始输出并提取收据。
7. 提交实质 S 与紧邻包装 R，核对白名单、六个纯重命名、收据 SHA、包装文件范围及工作区状态。

## 当前恢复点

- 状态：`[BLOCKED]`，授权范围内实现及全部既定验证已完成，因 tools 零命中要求与冻结文件边界冲突而停止扩改。
- 最后完成：实质提交 S = `f56ea20d4c132f77771c3903a53305489cb98a9c`；全部验证通过，已生成指向 S 的阻塞收据，包装 R 仅提交本恢复点与收据。
- 下一步：由协调者处理冻结残留的验收范围或另单授权，并处理本派单与现版 Gate 收据结构的差异；本单不扩改、不合并、不推送。
- 已跑验证：基线三条与改后三条 diagnostic 各通过一项，资产审计通过四项；一字节证红失败一项，精确还原后通过；analyze 0 issue，全仓 format 0 changed，全量 7030 项通过且 `[E]` 块数为 0；六个黄金文件均与基线逐字节相同、六个 `100%` 重命名。
- 目录检查：`git ls-files test/tools/output` 为空，`test/tools/golden` 跟踪数为 6；`git check-ignore test/tools/golden/x.csv` 无输出、退出 1；旧 output 目录仍保留。
- 阻塞项：`git grep -n final_damage_formula -- tools` 实测退出 0，有且仅有 `tools/audit/numbers_unused_keys_review.py:49` 一处 `"combat|final_damage_formula"` 命中。该路径被本派单明确冻结只读，达到 tools 零命中需要白名单外修改，故按指定出口标记 `[BLOCKED]`。指定可写扫描器的三处登记已全部删除。
- 冻结文件保全：`numbers_unused_keys_review.py` 与基线逐字节一致，前后 SHA-256 均为 `02826706eeaded5cacc3299af997de7eecb06b26f6de08430662a8210b7744ef`；白名单外改动为 0。
- 计数结论：零引用 14 叶且该集合全部已标记；全表标记为 74 叶，基线同样为 74。额外 60 叶已逐叶解释如下，不冒充全表标记数 14。
- 收据：`docs/dispatch/reports/2026-09-20_codex_E_receipt.yaml`。
- 原始证据目录：`/Users/a10506/Codex/2026-09-20/golden-relocate/evidence/`；扫描输出：`/Users/a10506/Codex/2026-09-20/golden-relocate/usage_after.json`。

## 交付与验收边界

- 真实消费方为三条现有 diagnostic 测试，均直接读取新的黄金文件路径；证红复跑 idle 的完整 CSV 比对分支。
- 本单不涉及数值红线、三系锁死、在线离线结算、反主流限制或文案数值配置的行为修改；无界面验收项。
- 现版外部 `gate.sh` 将零 `lib/` 改动判为审计单，并要求 `break_red` 为空（第 267–269、828–832 行）；本派单明确要求一组证红，按本派单优先保留，并附实测审计补丁校验。此项需协调者按派单处理，不宣称现版 Gate 已通过。
- 本派单要求收据列出重命名新旧共十二个路径，因此名单使用 `git -c diff.renames=false diff --name-only 基线..S`。现版 Gate 的普通名单命令未关闭重命名检测，可在运行 Gate 的进程中设置 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=diff.renames GIT_CONFIG_VALUE_0=false` 对齐，不修改 Git 持久配置。
- `test_deletions` 还会命中六个已授权路径常量替换的旧行；协调者应结合六个纯重命名与逐行 diff 豁免，确认断言未变。
- 实现、自动测试、协调者 Gate、合并和人工验收分开登记；本单不执行合并或发布。

## 实跑验证记录

以下结果对应 S 的实质文件内容，定向测试后到 S 仅补充恢复点；analyze、全仓 format、证红及全量在 S 上运行。未启用任何 `UPDATE…=1` 刷新。

| 检查 | 命令 | 原始末行或实测结果 |
|---|---|---|
| 基线 | `flutter test --no-pub test/tools/phase0a_idle_island_parity_diagnostic_test.dart` | `00:00 +1: All tests passed!` |
| 基线 | `flutter test --no-pub test/tools/phase0a_full_content_balance_diagnostic_test.dart` | `00:02 +1: All tests passed!` |
| 基线 | `flutter test --no-pub test/tools/phase0a_ch1_real_skill_profile_diagnostic_test.dart` | `00:01 +1: All tests passed!` |
| 改后定向 | `flutter test --no-pub test/tools/phase0a_idle_island_parity_diagnostic_test.dart` | `00:00 +1: All tests passed!` |
| 改后定向 | `flutter test --no-pub test/tools/phase0a_full_content_balance_diagnostic_test.dart` | `00:02 +1: All tests passed!` |
| 改后定向 | `flutter test --no-pub test/tools/phase0a_ch1_real_skill_profile_diagnostic_test.dart` | `00:01 +1: All tests passed!` |
| 改后定向 | `flutter test --no-pub test/tools/asset_audit_test.dart` | `00:00 +4: All tests passed!` |
| 证红 | idle CSV 首字节 `r → R`，复跑 idle 测试 | `00:00 +0 -1: Some tests failed.`；退出 1，差异位于第 0 字节 |
| 还原复跑 | `git checkout -- test/tools/golden/phase0a_idle_island_parity_diagnostic.csv` 后复跑 idle | `00:00 +1: All tests passed!`；文件哈希与基线相同 |
| 静态分析 | `flutter analyze --no-pub lib test tool` | `No issues found! (ran in 18.0s)` |
| 全仓格式 | `NO_COLOR=1 dart format --output=none --set-exit-if-changed .` | `Formatted 1866 files (0 changed) in 4.33 seconds.` |
| 前台全量 | `flutter test --no-pub` | `07:53 +7030: All tests passed!`；退出 0，`[E]` 块数 0 |
| 扫描器 | `python3 tools/audit/numbers_key_usage.py --baseline b99cfa72d --format json > /Users/a10506/Codex/2026-09-20/golden-relocate/usage_after.json` | 退出 0；零引用 14、其中已标记 14、全表已标记 74 |
| 补丁格式 | `git diff --check b99cfa72da23b088d9d98891458d270b1028814a..f56ea20d4c132f77771c3903a53305489cb98a9c` | 退出 0 |

全量使用既有 `~/.claude/locks/wuxia_full_test.lock`，正常获取与释放，未删除锁文件；墙钟 476.368 秒。收据三条末行来自保留的原始输出，按 CR/LF 分行并去 ANSI SGR；`error_block_count` 来自原始日志的 `grep -c '^\[E\]'`。补丁按 receipt schema 固定的无重命名、完整索引、二进制 diff 命令计算，SHA-256 为 `dde054fe13a70fff11ad8c2d436c31a0cc61f99441037eaf5b560e0aadde428c`。

## 标记计数逐叶解释

原版扫描器、原版 `lib/test/data/numbers.yaml` 均取自完整基线 `b99cfa72d`（通过 `git archive` 在内存读取，不切换工作区）。1693 个叶子的值、YAML 行号、判定、`unused_marked` 和 `unused_comments` 逐叶比较均无变化。

| 计数口径 | 基线 | 改后 |
|---|---:|---:|
| 全部标量叶 | 1693 | 1693 |
| `verdict == 零引用` | 14 | 14 |
| 零引用集合内 `unused_marked == true` | 14 | 14 |
| 全表 `unused_marked == true` | 74 | 74 |
| 已标记但判定为疑似间接消费需人判 | 60 | 60 |

额外 60 叶的原因：扫描器按行内注释、紧邻前置注释及祖先段注释登记 UNUSED，标记与消费判定独立。`validation_examples` 的 57 叶继承第 1556 行段头；角色两叶分别来自第 1135、1139 行；收徒资格一叶继承第 1499 行。其判定仍因字面量命中、同名歧义或缺少完整消费者证据保留为待人判。下表逐叶列出来源；每行均为“基线 = 改后、已标记 = true、判定 = 疑似间接消费需人判”。未修改判零口径或任何 UNUSED 注释。

| 叶路径 | YAML 行 | UNUSED 注释行 | lib/test 字面量次数 |
|---|---:|---|---|
| `character.adventure_attribute_bonus.bonus_per_event_max` | 1139 | 1139 | 1/3 |
| `character.adventure_attribute_bonus.bonus_per_event_min` | 1138 | 1135 | 1/3 |
| `inheritance.unlock_rules.can_take_disciple_at` | 1503 | 1499 | 1/1 |
| `validation_examples.example_a.attacker.critical` | 1575 | 1556 | 3/5 |
| `validation_examples.example_a.attacker.cultivation_multiplier` | 1573 | 1556 | 0/4 |
| `validation_examples.example_a.attacker.equipment_attack` | 1571 | 1556 | 1/6 |
| `validation_examples.example_a.attacker.internal_force` | 1570 | 1556 | 3/8 |
| `validation_examples.example_a.attacker.realm` | 1569 | 1556 | 3/10 |
| `validation_examples.example_a.attacker.school_counter` | 1574 | 1556 | 0/2 |
| `validation_examples.example_a.attacker.skill_multiplier` | 1572 | 1556 | 0/5 |
| `validation_examples.example_a.defender.defense_rate` | 1579 | 1556 | 2/4 |
| `validation_examples.example_a.defender.max_hp` | 1578 | 1556 | 0/2 |
| `validation_examples.example_a.defender.realm` | 1577 | 1556 | 3/10 |
| `validation_examples.example_a.description` | 1567 | 1556 | 7/24 |
| `validation_examples.example_b.attacker.critical` | 1594 | 1556 | 3/5 |
| `validation_examples.example_b.attacker.cultivation_multiplier` | 1592 | 1556 | 0/4 |
| `validation_examples.example_b.attacker.equipment_attack` | 1590 | 1556 | 1/6 |
| `validation_examples.example_b.attacker.internal_force` | 1589 | 1556 | 3/8 |
| `validation_examples.example_b.attacker.realm` | 1588 | 1556 | 3/10 |
| `validation_examples.example_b.attacker.school_counter` | 1593 | 1556 | 0/2 |
| `validation_examples.example_b.attacker.skill_multiplier` | 1591 | 1556 | 0/5 |
| `validation_examples.example_b.defender.defense_rate` | 1598 | 1556 | 2/4 |
| `validation_examples.example_b.defender.max_hp` | 1597 | 1556 | 0/2 |
| `validation_examples.example_b.defender.realm` | 1596 | 1556 | 3/10 |
| `validation_examples.example_b.description` | 1586 | 1556 | 7/24 |
| `validation_examples.example_c.attacker.critical` | 1613 | 1556 | 3/5 |
| `validation_examples.example_c.attacker.cultivation_multiplier` | 1611 | 1556 | 0/4 |
| `validation_examples.example_c.attacker.equipment_attack` | 1609 | 1556 | 1/6 |
| `validation_examples.example_c.attacker.internal_force` | 1608 | 1556 | 3/8 |
| `validation_examples.example_c.attacker.realm` | 1607 | 1556 | 3/10 |
| `validation_examples.example_c.attacker.realm_diff_modifier` | 1614 | 1556 | 0/5 |
| `validation_examples.example_c.attacker.school_counter` | 1612 | 1556 | 0/2 |
| `validation_examples.example_c.attacker.skill_multiplier` | 1610 | 1556 | 0/5 |
| `validation_examples.example_c.defender.defense_rate` | 1618 | 1556 | 2/4 |
| `validation_examples.example_c.defender.max_hp` | 1617 | 1556 | 0/2 |
| `validation_examples.example_c.defender.realm` | 1616 | 1556 | 3/10 |
| `validation_examples.example_c.description` | 1605 | 1556 | 7/24 |
| `validation_examples.example_d.attacker.critical` | 1633 | 1556 | 3/5 |
| `validation_examples.example_d.attacker.cultivation_multiplier` | 1631 | 1556 | 0/4 |
| `validation_examples.example_d.attacker.equipment_attack` | 1629 | 1556 | 1/6 |
| `validation_examples.example_d.attacker.internal_force` | 1628 | 1556 | 3/8 |
| `validation_examples.example_d.attacker.realm` | 1627 | 1556 | 3/10 |
| `validation_examples.example_d.attacker.school_counter` | 1632 | 1556 | 0/2 |
| `validation_examples.example_d.attacker.skill_multiplier` | 1630 | 1556 | 0/5 |
| `validation_examples.example_d.defender.defense_rate` | 1637 | 1556 | 2/4 |
| `validation_examples.example_d.defender.max_hp` | 1636 | 1556 | 0/2 |
| `validation_examples.example_d.defender.realm` | 1635 | 1556 | 3/10 |
| `validation_examples.example_d.description` | 1625 | 1556 | 7/24 |
| `validation_examples.example_e.attacker.critical` | 1653 | 1556 | 3/5 |
| `validation_examples.example_e.attacker.cultivation_multiplier` | 1651 | 1556 | 0/4 |
| `validation_examples.example_e.attacker.equipment_attack` | 1648 | 1556 | 1/6 |
| `validation_examples.example_e.attacker.internal_force` | 1647 | 1556 | 3/8 |
| `validation_examples.example_e.attacker.realm` | 1646 | 1556 | 3/10 |
| `validation_examples.example_e.attacker.school_counter` | 1652 | 1556 | 0/2 |
| `validation_examples.example_e.attacker.skill_multiplier` | 1650 | 1556 | 0/5 |
| `validation_examples.example_e.defender.defense_rate` | 1657 | 1556 | 2/4 |
| `validation_examples.example_e.defender.max_hp` | 1656 | 1556 | 0/2 |
| `validation_examples.example_e.defender.realm` | 1655 | 1556 | 3/10 |
| `validation_examples.example_e.description` | 1644 | 1556 | 7/24 |
| `validation_examples.example_e.note` | 1658 | 1556 | 0/1 |

完整逐叶核对、原版扫描输出与复现脚本分别保存在外置证据目录的 `unused_markers_reconciliation.json`、`baseline_usage.json`、`verify_unused_markers.py`；范围和断言独立复核见 `scope_and_assertion_review.json`。
