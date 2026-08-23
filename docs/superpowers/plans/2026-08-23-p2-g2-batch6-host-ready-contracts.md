# P2 G2 Batch6：Host-ready Contracts

## 目标

从 READY `27c9777c` 出发，在不切换主线宿主、不猜黑风岭内容语义的前提下，补齐动态遭遇进入生产宿主前的三个纯合同：typed encounter mapping、全量动态 visual roster 工厂、显式 `legacy | migrated` 路由解析器。

## 切片

1. D09（Pi + DeepSeek `deepseek-v4-flash`）：新增不可变 `Phase0aEncounterMapping`，并提供 production assembler 的 typed bridge；只组合已冻结的 encounter runtime 输入。
2. D10（Qoder CLI + `Qwen3.8-Max`）：为 `Phase0aVisualRoster` 增加从全量 combatants 构造的工厂，覆盖 pending / warning / active 全 roster；既有 stage mapping 委托该工厂。
3. E05（Codex 子 agent）：新增纯 `legacy | migrated` migration resolver 合同，显式 allowlist、单 encounter 和 legacy-content 互斥校验；不读取真实文件、不切 host。
4. Codex 主控：复审三路真实 diff、整合、补缺口、运行范围回归和独立终审。

## 冻结合同

- 本批不修改 production host routing、stage/encounter 数据、tuning、objective、AttackToken enforce、UI/VFX、reward、save。
- mapping 只携带已经由 Batch5 assembler 接受的初态、director、roster、combatants、move bindings 和输入 adapters；集合防御性不可修改。
- mapping/bridge 不复制伤害、AI、移动、spawn、终局或 RNG 规则；caller 继续显式提供 `NumbersConfig` 与单一 `Random`。
- visual roster 必须覆盖传入的每个 combatant；玩家使用既有 founder fallback，敌人使用 snapshot `iconPath`，空 asset、重复 actor、玩家缺失/重复均 fail closed。
- migration resolver 是纯结构合同：`migrated` 必须恰有一个 encounter、不在 legacy allowlist、无 legacy content；`legacy` 必须在显式 allowlist、零 encounter、存在 legacy content；both/neither fail closed。
- resolver 不硬编码任何 stage id，不推断黑风岭 active count、伏击目标、阈值或令牌语义。

## 验收 checklist

- [x] typed mapping 防御性持有全部动态 runtime 输入，并通过真实 production assembler bridge 生成 encounter flow。
- [x] visual roster 覆盖 reserve/warning/active 在内的全量 combatants，既有 `fromMapping` 行为保持兼容。
- [x] migration resolver 对 legacy/migrated 合法路径及 allowlist、count、both/neither 冲突稳定 fail closed。
- [x] targeted tests 给出命令与通过数；assembler/mainline/visual 相关回归继续通过。
- [x] 不触及数值硬红线、三系锁死、在线=离线、反主流机制或 Dart 中文文案/数值散写。
- [x] 生产接线证据明确：本批只到 production assembler typed bridge；主线 host 仍走 legacy `assemble`，不伪称已切生产。
- [x] 主控 diff 复审、`git diff --check`、scoped analyze 与至少两路独立审查通过。
- [x] 所有任务分支 worktree clean 且 tip 为 `[READY]`；集成分支最终生成 Batch6 READY 恢复点。

## 当前恢复点

- 状态：Batch6 已完成实现、历史集成回归修复、主控复审和独立终审，准备以 `[READY][CODEX][P2-G2-BATCH6]` 封签。
- 最后完成：最终集成态 `flutter test --no-pub` 4599/4599；`flutter analyze --no-pub lib test` 0 issue；所有独立审查 P0/P1/P2 为 0。
- 下一步：从本 READY 恢复点启动数据合同、loader/validator 与黑风岭非生产诊断批；继续禁止未冻结的 production host switch。
- 已跑验证：新合同与关键消费者 266/266；回归修复集成专项 143/143；全量 4599/4599；scoped analyze 0 issue；`git diff --check` 通过。
- 阻塞项：黑风岭 encounter 内容、伏击 objective、AttackToken enforce 与预警表现语义未冻结；不阻塞本批纯合同。
