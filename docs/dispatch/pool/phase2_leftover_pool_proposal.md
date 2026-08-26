# N12 · 二阶段遗留工作转可派任务池（只读提案）

> 状态：**PROPOSAL ONLY**。本文件不代表已写入 `BACKLOG.md`，不替用户拍板任何产品、数值、schema、迁移、删除或 UI 方案。
>
> 事实源：`docs/audit/phase2_spec_reality_audit_20260826.md`（N2，当前分支基线 `0ec0280a`）与 `/Users/a10506/Desktop/二阶段优化方案.md`（方案行号以本次现取的 1,568 行版本为准）。

## 1. 口径与覆盖

- 本次从 N2 表格现取 `39` 行、`236` 组：偏差 `52`、未实装 `163`、无法判定 `21`；没有只取“未实装”。
- 任务池共 `39` 条，严格一条承接一行 N2，不拆分或重复计算组数：可派 `8` 条 / `26` 组（🟢 `7` 条 / `25` 组，🟡 `1` 条 / `1` 组），待拍板 `31` 条 / `210` 组（🔴）。`26 + 210 = 236`。
- 同一 N2 行横跨多个既有 §20 任务时，`§20 任务 ID` 并列全部对应的 canonical ID；不生成别名。方案 §20 当前文本另有 `A10`–`A13`，六槽与旧槽迁移只使用其中已明载的 `A11`，不另起编号。
- `NEW-*` 条目数为 `0`：39 行均能映射到 §20 既有 ID。
- “域”只表示未来任务可能写入的目录，用于判定并行冲突；不是本提案已经授权这些目录发生改动。
- 验收判据只定义“什么证据算关”，不指定“怎么实现”。🔴 条目在签字前不得进入可派；🟡 条目进入可派，但必须先出方案。
- M3 / M4 / M7 范围均显式带 `G2 试玩通过` 前置。全量内容项还保留对应 M4/M5 子 Gate，未把 G2 误写成“105 关全部开写”。

## 2. 已解锁可派

| N2 # | §20 任务 ID | 单名 | 来源（双锚） | 承载组数 | 域 | 决策级别 | 前置依赖 | 验收判据 | 备注 |
|---:|---|---|---|---:|---|---|---|---|---|
| 1 | C02 | 校准六几何现状 | N2 L18；方案 L40 | 1 | `docs/dispatch/` | 🟢 | 无 | grep 守卫证明权威现状表为 6 种 `GeometryScopeKind`，旧“仅 radial + caster”只允许出现在历史审计引用中。 | 只纠正过时现状锚，不改变六几何目标。 |
| 2 | C15 | 校准换波冷却现状 | N2 L19；方案 L41、L835 | 1 | `docs/dispatch/` | 🟢 | 无 | grep 守卫证明权威现状表不再声称生产为 `preserve_cooldowns: false`，并保留现有跨波冷却测试锚。 | 只纠正过时现状锚，不改冷却规则。 |
| 3 | A05 | 校准掌门解析现状 | N2 L20；方案 L43 | 1 | `docs/dispatch/` | 🟢 | 无 | `git grep` 证明生产 resolver 的首角色回退为 0，权威现状表同步记录空值/悬空 fail closed。 | 只纠正过时现状锚，不改参与者规则。 |
| 4 | C17 | 校准心魔惩罚现状 | N2 L21；方案 L49、L360、L839 | 1 | `docs/dispatch/` | 🟢 | 无 | grep 守卫证明权威现状表记录主修 progress/layer 当前不变，同时保留该产品规则的待决状态。 | 不把当前实现反推为产品签字。 |
| 35 | A05 | 统一资格检查边界 | N2 L52；方案 L885 | 1 | `lib/features/*/application/`；`lib/shared/battle_shared/`；`test/` | 🟡（先出方案） | A01、A03、A04 合同冻结 | 方案获批后，静态守卫列出的生产活动入口 100% 经过同一资格边界，且破坏任一入口检查时定向测试转红。 | 跨模块重构；只先出边界/调用面方案。 |
| 37 | P09 + P10 | 补齐性能矩阵证据 | N2 L54；方案 L1434–L1440 | 7 | `test/`；`docs/audit/` | 🟢 | 无 | 证据矩阵逐组覆盖 p99/severe、8/12/16/14/18/24、50/150、双视口×3、headless、RSS、Windows，并为每格记录命令、退出码和可复跑结果。 | 只补证据；若发现失败，另回红/黄分流，不在本条改产品。 |
| 38 | P08 + P09 + P10 | 补齐密度视效证据 | N2 L55；方案 L800–L802、L1420–L1428 | 7 | `test/`；`docs/audit/` | 🟢 | 无 | 证据矩阵 7/7 覆盖 LOD、低特效领域 hash、塔 14、群战 18/24 与双视口 UI 可读性，每格都有可复跑断言或明确 FAIL。 | 只把“无法判定”转为机器证据。 |
| 39 | C12 + C14 | 补齐同核奖励证据 | N2 L56；方案 L338–L343、L517 | 7 | `test/`；`docs/audit/` | 🟢 | 无 | 固定 seed 的模式矩阵逐项给出 manual/bot/headless tick/hash 与重复掉落 profile 证据，7/7 断言均有可复跑 PASS/FAIL。 | 不把黑风岭单关结果外推到全模式。 |

## 3. 待拍板

| N2 # | §20 任务 ID | 单名 | 来源（双锚） | 承载组数 | 域 | 决策级别 | 前置依赖 | 验收判据 | 备注 / 拍板点 |
|---:|---|---|---|---:|---|---|---|---|---|
| 5 | A11 | 冻结六槽输入 | N2 L22；方案 L114–L121 | 12 | `lib/features/battle/presentation/`；`lib/shared/battle_shared/`；`lib/core/domain/`；`test/` | 🔴 | 无 | 已签输入表对应的键鼠 widget/semantics 测试与装配槽合同测试全绿，旧键位只在明确兼容 allowlist 命中。 | 玩家可见输入与 UI，并牵涉装配 schema。 |
| 6 | C11 | 迁移冷却秒权威 | N2 L23；方案 L132–L133、L935 | 4 | `lib/data/defs/`；`data/`；`lib/features/`；`test/` | 🔴 | C01 冻结秒映射与退役边界 | `git grep 'cooldownTurns' -- lib` 的 Phase 0A 生产读方为 0，秒字段解析、量化与旧档兼容测试全绿。 | schema、迁移及旧字段退役。 |
| 7 | C03 + C07 | 闭合真气取消合同 | N2 L24；方案 L135 | 2 | `lib/features/battle/domain/phase0a/`；`lib/features/battle/application/phase0a/`；`test/features/battle/` | 🔴 | 无 | 定向测试精确断言起手锁气、首效扣气，以及生效前取消/打断的退还与失败冷却，任一分支破坏即转红。 | 战斗资源规则玩家可见。 |
| 8 | C08 + C09 | 接通五武器三特性 | N2 L25；方案 L162–L207 | 18 | `lib/features/battle/`；`lib/data/defs/`；`data/combat/`；`test/` | 🔴 | G2 试玩通过；C02、C03、C07 合同关闭 | 生产装配测试覆盖 5 种武器形态 × 3 种主修特性共 15 组合，且每种均有清杂/精英/Boss 可复跑画像。 | M3；玩家可见战斗规则与数值。 |
| 9 | C05 + C06 | 统一姿态状态合同 | N2 L26；方案 L294–L320 | 14 | `lib/features/battle/domain/phase0a/`；`lib/features/battle/application/phase0a/`；`data/combat/`；`test/features/battle/` | 🔴 | C03 合同关闭 | 状态机测试逐项覆盖姿态阈值、Boss 控制折算、持续/刷新/叠层/fixed tick/换波清理，14/14 断言可独立转红。 | 战斗控制与状态规则玩家可见。 |
| 10 | A09 | 闭合随行听剑幂等 | N2 L27；方案 L45、L77 | 8 | `lib/features/mainline/`；`lib/core/`；`test/features/mainline/` | 🔴 | A03、A05 合同关闭 | 持久化重启与重复提交测试证明同一首通 claim 恰好一次，重打/自动/扫荡为 0 次，参与/受伤/掉落边界均与签字合同一致。 | 成长与唯一领取规则。 |
| 11 | C13 + C14 | 统一失败收益结算 | N2 L28；方案 L351–L363 | 7 | `lib/shared/battle_shared/`；`lib/features/*/application/`；`test/` | 🔴 | A01 合同关闭 | 模式矩阵测试精确守普通/特殊失败、同 session 一次伤势与已签部分收益，重复/崩溃恢复不重复写入。 | 伤势、收益与模式规则。 |
| 12 | A02 + A11 | 决定角色装配方案 | N2 L29；方案 L371–L374 | 5 | `lib/core/domain/`；`lib/shared/battle_shared/`；`lib/features/*/presentation/`；`test/` | 🔴 | C01 重新拍板装配方案数量 | registry 有明确签字；schema/迁移、UI 与活动快照测试只守签字后的单套或双套口径，旧槽无静默丢失。 | 与已否清单“每角色一套持久装配”冲突，禁止按旧方案直接恢复双方案。 |
| 13 | A06 | 冻结当值历练槽 | N2 L30；方案 L381 | 1 | `lib/shared/battle_shared/`；`lib/features/seclusion/`；`lib/core/`；`test/` | 🔴 | A03 合同关闭 | 并发准入测试证明已签槽位口径下第二个冲突请求 fail closed，完成/取消/恢复后占用释放幂等。 | 活动占用与宗门产出规则。 |
| 14 | A08 | 决定离线报告口径 | N2 L31；方案 L387–L393 | 8 | `lib/features/main_menu/`；`lib/features/seclusion/`；`lib/features/expedition/`；`lib/shared/`；`test/` | 🔴 | C01 重新拍板归来报告口径 | registry 有明确签字；时间切片、checkpoint、恢复 hash 与报告呈现测试精确守签字后的统一或独立口径。 | 与已否清单“保留各活动独立摘要”冲突，禁止直接做统一报告。 |
| 15 | U01 + U02 + U13 | 扩展主线连续流程 | N2 L32；方案 L82、L401–L404 | 3 | `lib/features/mainline/`；`test/features/mainline/` | 🔴 | G2 试玩通过 | 105/105 关生产路由测试证明胜利结算后下一关/终章行为可达，普通关 opening/victory/defeat 强制 push 为 0。 | 全 21 章扩面属 M7，且是玩家可见流程。 |
| 16 | T01–T07 + T11 | 迁移第一章遭遇 | N2 L33；方案 L1025–L1026 | 6 | `data/combat/`；`test/data/phase2/`；`test/features/mainline/` | 🔴 | G1 合同通过 | Ch1 五关 assignment 守卫为 5/5 migrated，并逐关匹配已签模板序列；legacy 命中为 0。 | M2 内容与数量规则。 |
| 17 | E03 | 校准黑风岭令牌 | N2 L34；方案 L1025 | 1 | `data/combat/`；`test/data/phase2/` | 🔴 | N2 #18 攻击令牌口径拍板 | 黑风岭 production catalog 测试精确等于签字后的总令牌与分类预算，配置和验收记录同值。 | 数值/战斗公平性；当前 6 与方案 2–4 冲突。 |
| 18 | E03 | 统一攻击令牌口径 | N2 L35；方案 L617、L1025、L1534 | 1 | `docs/dispatch/`；`data/combat/`；`test/` | 🔴 | 无 | registry 明确区分总令牌与近战令牌并获签字；静态校验拒绝超出签字范围或歧义字段。 | 方案内部数值口径歧义，必须先拍板。 |
| 19 | C01 | 清理调参来源矛盾 | N2 L36；方案 L31、L34 | 2 | `docs/spec/`；`docs/dispatch/` | 🔴 | 无 | registry 每个 TUNING 状态都有可追溯原会话依据与批准记录；无依据的 `frozen/用户拍板` grep 命中为 0。 | 决策来源链互相矛盾，不替用户补签。 |
| 20 | T09 | 迁移塔七层循环 | N2 L37；方案 L413 | 3 | `lib/features/tower/`；`data/combat/`；`test/features/tower/` | 🔴 | G2 试玩通过；T01–T07 目标合同关闭 | 49 层内容守卫逐层匹配已签七层循环、Boss 分布与目标引用，旧 1–3 敌队伍 fallback 命中为 0。 | M5 内容与塔规则玩家可见。 |
| 21 | M-TOWER + U14 | 决定塔自动参与者 | N2 L38；方案 L414、L416、L473 | 4 | `lib/features/tower/`；`lib/features/jianghu_map/`；`test/features/tower/` | 🔴 | G2 试玩通过；A01、A03、A05 合同关闭 | 塔入口矩阵对首通/重打、manual/bot/headless/当值与签字参与者资格逐格断言，越权组合全部 fail closed。 | 玩家可见参与者与自动化规则。 |
| 22 | M-LF + M-MASS + U14 | 接通轻功群战自动化 | N2 L39；方案 L425、L474–L475 | 6 | `lib/features/light_foot/`；`lib/features/mass_battle/`；`test/` | 🔴 | G2 试玩通过；A01、A03、A05 合同关闭 | 两模式入口矩阵逐格验证首次门槛及已签 bot/headless/差遣组合，未解锁与无资格请求均 fail closed。 | M5；玩家可见自动化与模式规则。 |
| 23 | M-EXP | 冻结远征里程碑门 | N2 L40；方案 L461–L462、L478 | 4 | `lib/features/expedition/`；`test/features/expedition/` | 🔴 | G2 试玩通过；A03、A07、A08 合同关闭 | 固定路线测试证明未解锁里程碑不被 headless 越过，离线自动返程原因与完成节点账本可机器断言。 | M5；远征进度与离线规则。 |
| 24 | U14 | 统一模式自动策略 | N2 L41；方案 L482、L486 | 5 | `lib/shared/battle_shared/`；`lib/features/tower/`；`lib/features/light_foot/`；`lib/features/mass_battle/`；`lib/features/boss_gauntlet/`；`lib/features/expedition/`；`test/` | 🔴 | A01、A03、A05 合同关闭 | 签字后的模式矩阵测试逐项覆盖 5 个 automation 维度与每模式 unlock key，非法组合和错 key 全部 fail closed。 | 跨模式产品规则与持久化 key。 |
| 25 | C14 + U09 | 统一三层奖励闭环 | N2 L42；方案 L509–L539 | 4 | `lib/shared/battle_shared/`；`lib/features/*/application/`；`data/`；`test/` | 🔴 | A01、C13 合同关闭 | 全模式矩阵精确守签字后的固定/重复/个人落点，重启、重试和事务失败均不重复发唯一奖励。 | 奖励与经济规则。 |
| 26 | C14 + U09 | 决定残页自动转换 | N2 L43；方案 L536 | 1 | `lib/features/cultivation/`；`data/`；`test/features/cultivation/` | 🔴 | 无 | registry 有转换目标与比例签字；已解锁后的重复残页测试精确守签字结果且总账守恒。 | 经济/成长数值，不能自行选择转换物。 |
| 27 | U11 | 冻结地点解锁三态 | N2 L44；方案 L580 | 4 | `lib/features/jianghu_map/`；`lib/core/`；`test/features/jianghu_map/` | 🔴 | C01 冻结精确解锁章点与持久化边界 | hidden/heard/open 与一次蜡封的状态矩阵、存档恢复和 widget 路由测试逐格通过。 | 玩家可见 UI、解锁规则与 schema。 |
| 28 | E02 + E03 | 冻结模式密度预算 | N2 L45；方案 L603–L612 | 8 | `lib/features/battle/domain/phase0a/`；`data/combat/`；`test/` | 🔴 | G2 试玩通过 | 已签各模式总量/活跃区间及补兵阈值均由配置校验，边界内通过、越界 fixture 精确失败。 | M4；数值与战斗密度规则。 |
| 29 | E05–E10 | 扩齐六生态包 | N2 L46；方案 L638–L649 | 8 | `data/combat/archetypes/`；`lib/features/battle/`；`assets/`；`test/` | 🔴 | G2 试玩通过；E01–E04 合同关闭 | manifest 守卫精确计数 6 包、24 canonical logical IDs，并逐 ID 验证定义、攻击标签、姿态、掉落和生产引用。 | M4；玩家可见敌人内容，约 48 变体仍按方案目标而非擅升硬红线。 |
| 30 | T12 | 冻结生态内容分配 | N2 L47；方案 L657–L664 | 7 | `data/combat/manifest/`；`data/combat/encounters/`；`test/data/phase2/` | 🔴 | G2 试玩通过；E05–E10 对应生态子 Gate；M-TOWER production policy Gate | 章节/塔分配 validator 对签字矩阵逐项全等，未知生态、随机替换固定构成或缺引用时精确失败。 | M7；不会因 G2 通过就绕过 M4/M5 子 Gate。 |
| 31 | T01–T07 | 扩齐七遭遇模板 | N2 L48；方案 L670–L715 | 8 | `lib/features/battle/domain/phase0a/`；`data/combat/encounters/`；`test/features/battle/` | 🔴 | G2 试玩通过；C02、C03、E02、E03 合同关闭 | 八目标原语与七模板均有胜/负/超时/残敌机器断言，七模板至少各有一个 production consumer。 | M4；目标与终局行为玩家可见。 |
| 32 | T12 | 扩齐二十一章编排 | N2 L49；方案 L721–L745 | 21 | `data/combat/encounters/`；`data/combat/manifest/`；`test/data/phase2/` | 🔴 | G2 试玩通过；T01–T07 与对应 E05–E10 子 Gate | 21×5 编排守卫与签字矩阵 105/105 全等，所有 stage 引用存在且无 legacy fallback。 | M7；只唤醒依赖已关闭的章节包。 |
| 33 | C10 + P01 + P02 + P03 | 重构战斗信息层级 | N2 L50；方案 L759–L806、L1028 | 13 | `lib/features/battle/presentation/phase0a/`；`lib/features/battle/domain/phase0a/`；`test/features/battle/` | 🔴 | C10 表现 feed 合同关闭 | widget/golden/事件聚合测试精确守层级、Boss 顶条唯一、伤害组上限、屏外方向上限、HUD 与战后统计字段。 | 玩家可见 UI 与表现。 |
| 34 | C02 + C03 + C04 + C05 + C06 + C10 + E02 + E03 + T01–T07 + T11 + A01 + A03 + A04 | 收口遭遇单一来源 | N2 L51；方案 L848–L858、L891–L927 | 13 | `lib/data/`；`lib/features/battle/`；`data/combat/`；`test/` | 🔴 | G2 试玩通过；T12 的 105/49 迁移完成 | §17.3 的 11 个领域边界均有 production consumer；每个生产战斗恰好一个 encounter，冲突/缺失 fail fast，`legacyStageCount == 0` 且生产 fallback grep 命中为 0。 | M7 收口含删除生产 fallback，属红级。 |
| 36 | C08 + C11 + A11 | 迁移武器六槽冷却 | N2 L53；方案 L931–L935 | 9 | `lib/data/defs/`；`lib/core/domain/`；`data/`；`lib/features/`；`test/` | 🔴 | C01 冻结 schema 与迁移边界 | schema/迁移 fixture 覆盖 weapon form、六槽、旧槽与秒冷却；所有生产消费方读签字字段，旧读方 grep 达签字后的 0/allowlist 目标。 | schema、存档迁移和玩家装配语义。 |

## 4. 覆盖与围栏复核

- N2 行覆盖：可派 `1–4、35、37–39`；待拍板 `5–34、36`；并集恰为 `1–39`，交集为空。
- 组数守恒：可派 `1+1+1+1+1+7+7+7 = 26`；待拍板 `236-26 = 210`；总计 `236`。
- M3：N2 #8；M4：N2 #28、#29、#31；M7：N2 #15、#30、#32、#34。以上每条前置栏均含 `G2 试玩通过`。
- 已否边界：N2 #12 与“每角色只保留一套持久装配”、N2 #14 与“保留各活动独立摘要”存在直接冲突，均保留为 🔴 且明确要求重新拍板；未重开章节回顾一级入口、Boss 技能预兆图标或其他已否方向。
- 本提案不估工时，不修改 `BACKLOG.md`、`docs/dispatch/pool/README.md`、`PROGRESS.md`、`lib/`、`test/`、`data/`、`GDD.md`、`CLAUDE.md` 或任何执行端禁区文件。
