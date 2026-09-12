# 塔机制等价性与首批1–7层迁移（2026-09-12）

## 当前结果

用户授权依次完成候选提交、机制等价性补强、首批迁层。统一候选已提交 `8bb82d2c42ca4b93502b5aafa6ac918d70c08c68`，其 tree `37e7dbaefb878d528f8d4576dffff69a33725c3c` 与先前917文件/6527 PASS的154文件清单完全相同。

本批生产路由集合已从空集改为精确 `{1,2,3,4,5,6,7}`；其余42层保留兼容路由。本地统一候选已通过最终回归；main仍0/49，正式M7未关闭。

## 实现与真实路径

- 唯一生产改动为 `Phase0aTowerEncounterRouteAuthority.production` 的集合。复用已集成的 derived encounter、runtime binding、defeat-all objective 与 director，不复制楼层、敌人或技能配置。
- 可见挑战、即时挂机、持久差遣恢复共用factory。首批三入口测试保留入口传来的真实production authority；后续代表层仅在测试中显式选择typed，不能计入迁移分子。
- 首批完整七层×周目1/2逐个比较真实战斗/结算；扫描49层确认范围。迁移层缺definition/runtime时必须报错，第8层继续兼容且不读取typed来源。
- 数值、技能、奖励经济、解锁、schema/saveVersion、AI与attack-token策略、事务owner均未修改。迁层回退边界是仅撤回本批production集合变更；本批没有存档格式迁移。

## 等价性补强与反向验证

旧审计所述字段和三入口缺口多数已由9月11日候选补齐，本批按当前实现复核，避免重复施工。

- 完整三入口矩阵扩至1–7/14/32/42/49×周目1/2共22组；比较不可变snapshot、actor逐tick状态、全部规范化战斗事件与结算。只规范化legacy波次记录的seq与护法ID表示差异。
- SkillDef比较同源不可变对象，覆盖全部技能参数；补透传M0新增basicAction/qiLedger/killQiGain/killQiWindowCap/qiWindowSerial。actor构造45字段全部透传。
- 第42层的护法代吃/合击、蓄招、两次相位变化维持实触发；新增第32层脆弱机制探针，正常攻击开窗、窗口内R产生伤害、活体停手恢复，逐tick与legacy一致。fixture调整的是测试玩家输出/防御，生产敌人和机制原样。
- 路由迁移前新守卫19处预期RED，均为运行断言；原始证据 `migration-red.jsonl`。新增奖励链也曾因production仍legacy而预期RED。
- 临时把typed actor的vulnerabilityMult改为1，窗口测试两周目均在实际状态对比中失败；按原始字节恢复并核对SHA。第一次尝试写入不支持的copyWith参数只产生编译错误，单独保留为compile-only，不能算有效mutation。
- 新机制测试最初的No element是终局空敌队观察错误；随后只有PostureChanged却没有开窗的失败促成独立真实窗口探针。原始失败均保留，没有改生产来逼绿。

## 验证与边界

最终冻结源码验证：

| 检查 | 结果 |
| --- | --- |
| 全项目 analyze | 0 issues |
| 本批5个Dart文件格式 | 0 changed |
| 相关定向 | 43/43文件，290 PASS；无失败/跳过/遗漏 |
| 持锁全量 | 919/919文件，6561 PASS；无失败/跳过/遗漏 |
| 全量起止 | 2026-09-12T08:31:46.726061+08:00 → 2026-09-12T08:40:56.465662+08:00 |
| 源码冻结 | 定向与全量哈希完全相同，运行中无修改，提交前再次核对 |
| 测试契约迁移 | PASS；2条登记，expect删1增89，用例删1增9 |
| 独立复核 | 无阻断发现；主端复核生产diff、关键测试及最终日志 |

首通验证使用临时Isar与P3工程画像，逐层真实战斗进入原子owner：1–7首通经验、必掉物品、装备、个人记录、receipt与legacy一致，重开后保留；七层真实即时重打和第7层durable重开执行不重复授予首通奖励，重复事务被拒绝。玩家没有被改为更强数值来使这组测试通过。

独立测试数据库有获取时间戳和GameEventService自有随机装备典故差异：先验证典故属于对应YAML允许池，再规范化这项文本及纯时间字段；装备数值、词缀、归属、触发身份和奖励记录仍比较。不是把随机文本差异当生产迁移缺陷，也没有改变生产随机源。

最终提交SHA、9文件清单、patch与哈希见证据目录 `delivery.json` / `candidate-manifest.json` / `tower-first-seven.patch`。

证据目录：`/Users/a10506/Documents/Codex/2026-09-12/tower-first-batch/`。

用户原有AGENTS.md、CLAUDE.md、.qoder/settings.json及CLAUDE历史冻结文件单独保留。没有启动游戏、访问玩家存档、合main、push、发布或清理worktree。正式M0–M9仍1/10；M4、真人/Windows、原主线点击超时根因继续开放。主线105/105与五处legacy入口退役状态不受本批影响。
