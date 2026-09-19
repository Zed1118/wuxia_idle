# C1 · numbers.yaml 零引用 key 删除批 恢复点

- 目标：按对照单 `docs/audit/numbers_unused_keys_round2_2026-09-19.md` §2 用户拍板结果，删除 A/B/D/G 段 26 叶零引用 key，C 段两叶改头注令牌，同步文档与审计工具登记项。
- 分支：`qoder/c1-delete-keys-20260919`；worktree `/Users/a10506/Qoder/2026-09-19/c1-delete-keys/wt`。
- 派单基线：`36781fbbf`（base_sha）。
- 写入范围：仅派单白名单（`data/numbers.yaml`、`data/skills.yaml`、`GDD.md`、`tools/audit/numbers_key_usage.py`、本恢复点、收据）；`lib/`、`test/`、`numbers_unused_keys_review.py`、`docs/audit/**` 等一律只读。
- 边界：不 push / merge / rebase / revert；不安装软件；不碰真实存档；不启动 GUI。

## 当前恢复点

- 状态：READY（全部目标完成，验证全绿；收据见 R commit）。
- 最后完成：全量 `flutter test --no-pub` 通过；收据字段从实跑输出提取完毕。
- 下一步：协调者 `gate.sh <worktree> 36781fbbf <S> --whitelist-from <派单包> --wrap-tip <R>` 验收；对撞 33/32 计数。
- 已跑验证：见下「验证结果」。
- 阻塞项：无。

## 提交清单

| commit | 内容 |
|---|---|
| `93dd15206` | [schema] 目标1：删 26 叶（A1+B6+D16+G3）及各自专属头注；G 段留墓碑指针注释 1 行 |
| `88c9606ea` | 目标2：C 段两保留叶头注令牌改/加 `UNUSED(`（max_level_formula 新增一行；new_owner_retention 首行改词，其余原文保留） |
| `b6f460140` | 目标3：`numbers_key_usage.py` 删 `:39` reference_multipliers 组 + `:346`/`:450` 终端名单 4 个已删末段名（附随 markdown 计数文字 8→4 同步） |
| S（本文件所在 commit） | [READY] 恢复点收口 |
| R | [READY] 仅含收据 `docs/dispatch/reports/2026-09-19_qoder_C1_receipt.yaml` |

## 执行决策记录（口径说明）

1. **A 段头注**：`meta.last_updated` 的 4 行专属头注块（UNUSED 行 + ⚠ 纯文档 3 行）随叶一并删除，依据派单 §0「删 26 叶及其专属头注」；对照单代价列只写「删 1 行」，从派单总则。
2. **D 段父键**：`power_skill:` / `ultimate:` 两个父键随 8 条 `tier_*_range` 一并删除——若只删子叶会留下 null 值空父键，被扫描器计为新增零引用叶、破坏 33 计数守恒；派单明示「保留 normal_attack 与 joint_skill 子块」，即其余子块整体消失。段头两行普通注释（`# 招式倍率参考范围…`）非 UNUSED 头注，保留。
3. **B 段保留行**：`# --- 最终伤害公式（GDD §5.4）---` 与其下一行公式说明注释保留；`final_damage_formula:` 块键 + 5 叶 + UNUSED/⚠ 专属头注 3 行删除。
4. **G 段墓碑**：`can_pass_legacy_at` 叶（含行尾 Ch19–21 史料注释）、其专属头注（`·can_pass_legacy_at` 三行 bullet + UNUSED 一行）删除；按派单在 `unlock_rules:` 上方留一行 `# can_pass_legacy_at 已于 2026-09-19 删除:飞升门槛唯一事实源 = ascension.unlock_triggers.required_realm`。
5. **`numbers_key_usage.py` 附加文字同步**：删除 `:346`/`:450` 名单中 4 个末段名后，同一登记项的 markdown 说明文字（「以下 8 个末段覆盖元数据、公式、换主预留与塔段」「8/8」「/8」）随名单同步为 4 个/换主预留与塔段/4/4/「/4」，避免生成的报告自相矛盾；判零口径（verdict 逻辑）、其余检查（生产样本 3 项、剩余 4 个末段 grep）均未动。无登记项删除后自检失败，无需回退。
6. **skills.yaml 未改**：`:8-12` 头注实测不引用 `skills.reference_multipliers`（引用的是 `techniques.tiers.max_skill_multiplier` 与 `combat.red_lines.skill_power_multiplier_max`），已符合全局单线口径，无需改写。`:1141` 引用的 `reference_multipliers.joint_skill.base` 属保留子块，不动。
7. **GDD §5.3 无分阶区间，无需同步**：`grep -n -E "1,?000.{0,6}1,?800|2,?500.{0,6}3,?500|6,?500.{0,6}8,?000" GDD.md` 退出 1 零命中；§5.3 只有按类型简表（普攻 500 / 强力技 1,000~3,000 / 大招 5,000+），非分阶区间，按派单口径不改、不出 `[GDD]` commit。
8. **白名单外登记项残留（无害，禁删）**：`numbers_key_usage.py:34`（final_damage_formula 组）、`:334-335`（suggestion 前缀）、`:418`（重点段交叉核对前缀）仍含已删 key 名——不在派单允许删除清单内且判零逻辑对其永不命中（对应叶已消失）；`numbers_unused_keys_review.py` 为 B2 冻结工具，全程只读。

## 验证结果

- YAML 解析：`python3 -c "import yaml;yaml.safe_load(open('data/numbers.yaml'))"` 通过（每次 numbers.yaml commit 前各跑一次）。
- diff 纯净性：`git diff 36781fbbf..HEAD -- data/numbers.yaml | grep '^+' | grep -v '^+++'` 仅 3 行注释（墓碑 1 + C 段头注令牌 2），无任何 `key: value` 新增行。
- 计数守恒：`python3 tools/audit/numbers_key_usage.py --baseline 36781fbbf --format json > /Users/a10506/Qoder/2026-09-19/c1-delete-keys/usage_after.json` 退出 0；`verdict==零引用` = **33**（59−26），其中 `unused_marked=true` = **32**（56−26+2）；唯一未标零引用叶 = `equipment.enhancement.success_curve[4].success_formula`（C2 单接线，符合预期）。脚本内自检：zero_grep 4/4 通过、生产样本 3/3 通过。
- analyze：`flutter analyze --no-pub lib test tool` → `No issues found!`（0 issue）；收据口径 `flutter analyze --no-pub lib test` → 末行 `No issues found! (ran in 5.8s)`（收工 tip 复跑）。
- format：`dart format --output=none --set-exit-if-changed lib test docs` → `Formatted 1758 files (0 changed)` 退出 0；收据口径 `dart format --output=none --set-exit-if-changed .` → 末行 `Formatted 1860 files (0 changed) in 3.88 seconds.` 退出 0（收工 tip 复跑）。
- targeted（逐目录，均 `All tests passed!`）：
  - `test/data/` → `03:26 +1250: All tests passed!`
  - `test/combat/damage_calculator_test.dart` → `00:32 +51: All tests passed!`
  - `test/features/equipment/` → `00:31 +213: All tests passed!`
  - `test/features/inheritance/` → `00:11 +17: All tests passed!`
  - `test/features/ascension/` → `00:16 +39: All tests passed!`
  - `test/features/activity/durable_activity_automation_service_test.dart`（中断期全量红条单跑复验）→ `00:03 +5: All tests passed!`；判定：**争抢期 setUpAll 超时，单跑绿**（当时另一 worktree `c2-wiring` 全量并行，10 核 load 27，与删 key 无关）。
- 全量：`flutter test --no-pub`（收口续跑，等 c2-wiring 进程排空后启动，log `/Users/a10506/Qoder/2026-09-19/c1-delete-keys/full_test_2.log`，管道退出码 0）→ 末行 `17:40 +6976: All tests passed!`；`grep -c '^\[E\]'` = `0`。
- 破坏证红：本单为配置删除、无新增断言 → 收据 `break_red` 留空，改填 `audit_verification`（`git diff --check 36781fbbf..<S>` 退出码 + 固定命令 patch SHA-256）。

## 预检协调者验收口径

- 已删 key 四目录抽检（`grep -rn -F <key> data/ lib/ test/ tools/`，排除冻结工具 `numbers_unused_keys_review.py`）：`last_updated`/`apply_cultivation_multiplier`/`tier_*_range`/`auto_buff_internal_force_max`/`resonance_retention` 均 0 命中；`can_pass_legacy_at` 余 1 命中 = 派单明文要求的墓碑注释行（`data/numbers.yaml:1498`）；`skill_multiplier_added`/`final_damage_formula` 余命中均在 `numbers_key_usage.py` 白名单外登记项（见决策记录 8）。
- `data_schema.md` 无已删 key 记载（grep 零命中），无需协调者另行同步。
