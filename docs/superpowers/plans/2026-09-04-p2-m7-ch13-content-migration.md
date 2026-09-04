# P2 M7 第十三章分层考校内容迁移计划

## 结果合同

- 单一结果：把 `stage_13_01..05` 五关完整接入 typed production catalog；保留 `stage_13_02` 的 25 人寺院生态，并将最后一名护院客僧明确为非 Boss commander“半山知客僧”。
- 固定分母：第十三章 `1/5 → 5/5`，全主线 typed production catalog `101/105 → 105/105`；塔保持 `0/49`，五处 legacy 接缝另行处理，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch13-content-migration-20260904` 建于 `HEAD == main == origin/main == 571708a7ddb5c5eb23a197b0b4e52ca3ec95145f`，开工前工作树 clean。
- 关键阻塞：既有 runtime adapter 只为 Boss commander/pursuit target 保留 StageDef identity，非 Boss commander 会退化为生态 role 的泛化姓名、图标与技能壳。
- 成本边界：无可靠 token/用量读数，按真实墙钟观察；约 90 分钟无 `101 → 105` 可验证增量则停线重评。

## 用户拍板语义

1. `stage_13_02` 保留 25 个寺院生态角色、`active_limit: 10` 与既有四类 token budget。
2. `ch13_s02_guard_02` 作为最后入场的非 Boss commander，保留 StageDef 的“半山知客僧”姓名、图标、流派与完整技能；其余 24 人继续使用生态变体。
3. objective 使用 `all` 组合：24 人 defeat-targets + 知客僧 defeat-commander。
4. `stage_13_02` opening/victory 只做分层考校所需的最小一致性改写，保留“半山也很好”“留字”“继续往上”的主题。
5. `stage_13_01/03` 保持单敌，`stage_13_04/05` 保持原 Boss 身份、技能、阶段、掉落与数值。

## 非目标与保护边界

- 不改玩家/敌人数值、奖励、经济、解锁、周目、结算 owner、`schemaVersion` 或 `saveVersion`。
- 不修改无关章节，不处理塔与 legacy 接缝，不启动 M8/M9，不 merge/push。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. 先以 Ch13 精确测试记录 assignment、encounter、runtime、factory、objective、dynamic victory 与非 Boss identity 的真实 RED。
2. 四条剩余关卡按 StageDef/正文迁移，`stage_13_02` 保持 25/10/token budget 与 24+1 分层考校。
3. runtime adapter 只增加“commander 保留 base StageDef identity”的通用规则；普通杂兵、Boss commander 与 Boss pursuit 合同不变。
4. 回归 M4 remaining ecologies、Ch3/Ch12/Ch14；至少两向可逆 mutation 精确证红并恢复。
5. 运行 Ch13 targeted、Phase 2 adjacent、mainline application、`flutter analyze --no-pub lib test tool`、`dart format .`、持锁 full suite、测试契约迁移门与标准 Gate，并如实记录原始结果。
6. 登记 decision/task registry，形成 `[READY]` 本地候选提交并保持工作树 clean。

## 当前恢复点

- 状态：`READY_LOCAL_CANDIDATE`；最终 `[READY]` tip 固化后写 ignored receipt 并自跑标准 Gate，结果只在外部 receipt/终端与最终交付中登记，避免 Gate 后再改候选树。
- 已完成：第十三章 `1/5 → 5/5`，本地全主线 typed catalog 候选 `101/105 → 105/105`；`main/origin/main` 仍为 `101/105`，塔 `0/49`、legacy 接缝 `5`、正式 Phase 2 `1/10` 均未改变。
- 生产实现：四关 assignment/encounter/runtime binding 接齐；`stage_13_02` 保持 `25/10` 与原 token budget，以 `24 defeat-targets + 1 非 Boss commander` 的 `all` objective 完成分层考校；adapter 只泛化 commander identity 保留规则。
- 已跑验证：有效 RED `0/8`；Ch13 `8/8`；M4 `3/3`；Ch3/12/14 `18/18`；Phase 2 adjacent `188/188`；mainline application `183/183`；三向 mutation 均证红并以 SHA-256 复原；测试契约迁移门 PASS；analyze 0 issue；format `1737` files 0 changed；持锁全量 `6001/6001`。
- 下一步：固化 `[READY]`、生成 ignored receipt、自跑标准 Gate；不 merge/push，等待独立审查与用户授权集成。
- 阻塞项：工程候选无本地阻塞；正式进度仍等待候选审查/授权集成、塔与 legacy 退役，以及真人桌面/视觉/音频/手感/Windows 验收。
