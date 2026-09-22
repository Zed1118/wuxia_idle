# M7 塔全层迁移与主线兼容入口退役

日期：2026-09-22。统一分支：`codex/review-followthrough-20260922`；本批父提交：`00982ba029e2164c342f73c37eb36cae4d4faa97`。最终提交、完整测试与 clean 收据位于 `/Users/a10506/Documents/Codex/2026-09-22/wuxia-review-followthrough/tower/delivery.json`，不能用本说明中的定向结果代替该收据。

## 结果与边界

生产 authority 覆盖塔 1–49 层，三入口继续共用 typed session factory；主线 105 条现有 migrated assignment 保持。生产 `lib` 不再调用 generic `Phase0aStageContentMapper.map` / `mapTower`。旧塔装配正文原样搬到测试支持层，用于与真实 production defaults 对照。

主线生产加载必须具备 combat 根 manifest，并为实际 mainline StageDef 集合逐项提供 migrated assignment。factory 在缺目录、缺 assignment 或 legacy authority/assignment 时明确失败；可视与扫荡也不允许 null 回退。孤立 fixture 可显式省略 catalog，但不能因此恢复主线战斗旧路由。校验是逐项覆盖，不声称反向集合封闭。

心魔、轻功、守城的专用 mapper 保留；远征、断魂庄独立 `mapExpedition` 保留。本次“旧入口退役”仅指主线与塔的通用兼容消费，不是全产品零 legacy flow，更不是再次删除旧 3v3。

未修改楼层 YAML、敌人数值、同时出场数、技能、AI、token 节流、奖励、解锁或存档 schema。未合并 main、push、发布或访问真实存档。

## 定向验证

| 验证 | 实测结果 |
|---|---|
| 迁移前行为反例 | 主线 6 项 RED；塔 3 项 RED，原 reporter 与自然退出保留 |
| 主线、严格加载、扫荡、表现设置与特殊活动准入 | 6 文件，114 PASS / 0 FAIL / 0 SKIP，退出 0 |
| 塔核心与 foundation | 2 文件，141 PASS / 0 FAIL / 0 SKIP，退出 0 |
| 三真实入口、机制与错误目标拒绝 | 111 PASS，退出 0；含 1–49 × C1/C2、14/32/42/49 × C3，visible / immediate / close-reopen durable |
| 首通及持久结算 | 4 PASS，退出 0；原 P3 1–7 两项保留，新增合法终局 1–49 两项 |
| 生产代码独立静态复核 | 7 文件未发现阻断；全套分析、测试和覆盖率以最终候选收据为准 |

全 49 层与旧参考比较 combat state、事件和 settlement；原 1–7 的胜利要求保留。通用耐久夹具有 27 个高层场景新旧均败，只证明迁移等价，不证明所有构筑可通关。42/49 的 guardian 引用按 session 的唯一 source/runtime 映射规范化，全部 45 个 actor 字段仍参与比较；reducer 已有精确 ID 或波次前缀兼容语义。

49 复合机制使用合成耐久快照及真实破招输入，观察活护法期间命中、脆弱窗口开启和恢复；逐拍状态与事件对照旧参考。该快照不是生产成长画像，不用于评判难度。

持久化验证使用临时 Isar 库，逐层实际战斗后调用真实奖励/进度 owner；验证首通经验、装备/物品、里程碑凭证、个人纪录、first-clear receipts、终层边界、重打零首通奖励、重开恢复及 settled dispatch 不重复结算。装备战斗计数按实际参战递增，其余字段继续比较。独立随机典故文本先校验正确装备、Boss、层号与 authored 文案池，再仅归一文本；获取时间也按既有规则归一，不能称全部 JSON 逐字相等。

终局画像复用生产创建、升级、学习和穿戴，战斗前通过 `ForgingService` 重建合法开锋并真实扣除测试材料：槽一/二异类，槽三仅在存在 authored skill candidates 时开放。强化、共鸣与材料预算属于显式测试准备，不是自然成长或经济可达性验收。原极值 oracle 未修改。

P3 诊断在第 22 层出现重伤准入拒绝，真实疗养后仍败北。最终终局测试保留按需生产疗养和单调时钟，等待所得被动收益与首通奖励分别核对；不声称最终绿色测试强制经历了重伤或证明玩家可以无休息连通 49 层。

## 正式状态

依据 `M7-DEPENDENCY-SEMANTICS-01`，本批是工程迁移，正式 M7 仍依赖 M2–M6。主 WIP 仍为 M2，正式 M0–M9 仍为 **1/10，仅 M1**；同版本真人、合格 M4 环境与物理 Windows 证据未补齐，不启动 M8/M9。

原始日志、失败诊断、承重断言迁移解释和保护文件哈希：`/Users/a10506/Documents/Codex/2026-09-22/wuxia-review-followthrough/tower/`。
