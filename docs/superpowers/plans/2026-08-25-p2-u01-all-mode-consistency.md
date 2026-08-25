# P2-M2-M6-U01-ALL-MODE-CONSISTENCY 结果合同

- 唯一目标：让主线首推手动、可见真人重打、可见前台 bot 重打、快速 headless 重打、即时扫荡五种已冻结模式，共用明确参与请求、实际参与者快照、Phase 0A reducer/event、共享结算与实际参与者归属。
- 固定验收门：生产模式 `2/5 → 5/5`。当前仅首推手动与可见真人重打完整连接；前台 bot 设置断线，快速 headless 无生产入口，扫荡未消费 typed 参与合同且可战门不完整。
- 顶层口径：M0–M9 仍 `1/10`；本任务关闭前 U01、M2、M6 和 Phase 2 均保持 WIP。
- 已冻结政策：首推固定当前掌门；可见真人/前台 bot 重打可选 eligible 空闲角色；无人值守 headless/扫荡固定当前掌门；记录、成长、伤势归实际参与者；重打不重复唯一首通奖励与随行听剑。
- 生产路径：`StageList/ContinueJianghu → typed request → exact participant snapshot → visible human/bot or headless/sweep → existing Phase0a encounter/reducer/event → existing shared settlement → actual participant report/record`。
- fail closed：无效/悬空掌门、死亡、疗养、无主修、活动占用、悬空装备/心法、stale snapshot、错人 settlement、未通关自动化和模式字段组合不合法。
- 成本上限：主成本读数为墙钟；90 分钟无模式验收门变化即停线重评。先 RED 合同，再逐模式转绿；不重复跑五小时全量，候选稳定后以风险匹配定向、主线/扫荡域、analyze 与一次受控生产 smoke 验收。
- 非目标：schema/saveVersion、YAML、TUNING/candidate、奖励数量/概率、经济、解锁阈值、叙事、战斗规则、新 reducer/session/headless/provider/settlement 真相源、main 修改/合并/push。

## 验收顺序

1. RED：锁定全局自动设置断线、headless 无入口、扫荡绕过 request/占用，以及错人/悬空/未通关零写入。
2. visible bot：已通关重打读取全局自动设置，同一 exact snapshot 驱动既有 `Phase0aPlayerBotAdapter`，首推仍强制人控。
3. headless replay：已通关单关显式入口，固定当前掌门、同核确定性模拟、复用既有重打结算，不消费 sweep readiness。
4. sweep：显式 `sweep` request 固定当前掌门，完整可战/占用复核后复用既有 runner 与结算；readiness 原语义不变。
5. 联合验证：五模式同 seed/装配终局与实际参与者归属矩阵、相关主线/扫荡/占用/结算域、`flutter analyze --no-pub lib test`、diff/白名单/语义复核、文档与 registry、clean READY。

## 收口结果

- 验收门已由 `2/5` 提升为 `5/5`：首推手动、可见真人重打、可见前台 bot 重打、快速 headless 重打、即时扫荡均连入 typed request、exact participant snapshot、既有 Phase 0A reducer/event 与共享 settlement。
- 主线+扫荡域 `470/470 PASS`，相邻活动/设置/bot/headless/结算域 `146/146 PASS`，`flutter analyze --no-pub lib test` 0 issue。
- 遵守 90 分钟成本停止线，未重复执行已知约 5 小时的整仓全量；本结果只关闭 U01 生产子门，M2、M6 和 Phase 2 仍 WIP。
