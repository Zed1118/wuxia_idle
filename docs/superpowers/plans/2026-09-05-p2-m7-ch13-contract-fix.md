# 第十三章生产合同修复（2026-09-05）

## 结果合同

- 授权：用户在审查后明确要求开始第十三章修复；本批不合入或推送 main，不迁塔层，不启动 M8/M9，不做批量清理。
- 分支：`codex/p2-m7-ch13-contract-fix-20260905`；复用 `/Users/a10506/.codex/worktrees/a0d7/挂机武侠`，保留原候选分支。
- 基线：`main == origin/main == 2d254abdf9bd841730acc301867c1249dde2ebc4`，clean，exact-SHA CI `33901066970` 成功。
- 唯一主 WIP：关闭 Ch13 三类生产合同缺陷：单敌身份/技能、保留数值、知客僧后置入场。
- 分母：修复合同 `0/3 → 3/3`；主线目录仍为 `105/105`、塔 `0/49`；正式 M0–M9 仍为 `1/10`，候选修复不冒充正式验收。
- 成本：按实际墙钟记录；无可靠 token 使用读数。开发期定向验证，最终一轮持锁全量；约 90 分钟无合同进展则重评，不扩大范围。

## 验收标准

1. 先取得有效 RED：`stage_13_01/03` 精确身份、立绘、完整技能；`stage_13_01/03/04/05` 原始数值在适用周目一致；真实生成事件证明 24 人考校结束后知客僧才入场。
2. 修复真实 repository → runtime adapter → encounter factory → director/flow 生产链，不以修改测试期望或仅调整 YAML 列表顺序掩盖问题。
3. 保留 25 人、10 active、原 token budgets、目标 all 组合、非 Boss commander 和既有 Boss 机制；不改 StageDef 基础数值、奖励、经济、周目、持久化 schema/saveVersion。
4. 共享适配器/生成器若改变，运行 Ch13、邻章、受影响主线与 director 回归；破坏身份、数值或入场条件分别应有测试失败并精确恢复。
5. 收口 analyze、format、持锁全量，检查实际 diff 与工作树；生产 smoke/真人手感/Windows 继续独立挂账。未满足验证不得标 READY。
6. 同批修正本任务相关 SHA/状态事实，明确历史审计结论被本次发现补充；不把未集成候选写成 main 已修复。

## 切片与恢复点

- 状态：`READY_LOCAL_CANDIDATE`，三类合同 `3/3` 已修复；就绪 SHA 以包含本记录的 `[READY]` 分支 tip 与 clean 工作树为准。main 仍是未含本修复的原绿色基线。
- 已完成：四个 singleton 保留源 snapshot；知客僧由其余 24 项击败依赖控制预警/入场；解析及运行层拒绝异常依赖和 all-active 绕门。主窗口独立复核实际 diff、生产唯一击败消费点、保护边界和原始验证日志。
- 已跑验证：初始 RED 8 PASS/3 FAIL；定向 68/68；邻接/共享 288/288；三 mutation 各 1 FAIL 后精确恢复；analyze 0 issue，format 1741/0 changed；唯一一轮持锁全量 6017/6017、exit 0（08:16:20–08:25:12 CST，8 分 52 秒），08:25:22 自有锁已释放。测试文件零删除；完整命令与日志见本批审计。
- 下一步：用户授权 main 集成后，再进入合并 Gate、no-ff、push 与 merge exact-SHA CI。本批未执行这些操作，不启动塔或 M8/M9。
- 成本/状态：一轮新增持锁全量预算已使用 1/1；正式 Gate 增量 0，本地合同增量 3/3，main 集成返工未发生；不伪造整批起止或 token 使用量。
- 阻塞：仅 main 集成授权及独立真人/Windows 验收；无待拍板的新设计决策。上轮只读 Ch13/M0 12/12、塔 9/9 不冒充本候选验收。

交付证据：`docs/audit/phase2_m7_ch13_contract_fix_2026-09-05.md`。
