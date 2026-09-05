# 第十三章生产合同修复（2026-09-05）

## 结果合同

- 授权：初次修复只交付本地候选；用户随后于“日常沟通”明确批准本批 main 合并、push 与 exact-SHA CI，原项目任务收到该授权后执行。不迁塔层，不启动 M8/M9，不做批量清理。
- 分支：原候选 `codex/p2-m7-ch13-contract-fix-20260905` / `21ad6e60` 保留；受检集成候选 `codex/p2-m7-ch13-contract-integration-20260905` / `cb824b53` 复用同一工作树。两者仅 PROGRESS 不同，全部生产代码、数据和测试完全一致；PROGRESS 随授权治理尾同步。
- 基线：`main == origin/main == 2d254abdf9bd841730acc301867c1249dde2ebc4`，clean，exact-SHA CI `33901066970` 成功。
- 本批唯一工程目标（现已集成）：关闭 Ch13 三类生产合同缺陷：单敌身份/技能、保留数值、知客僧后置入场。
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

- 状态：`INTEGRATED_ORIGIN_MAIN_CI_SUCCESS`。修复 `3/3` 已由受检候选 `cb824b534e7b4ed9e59ef21379eae8ca5846df9a` 经 no-ff merge `261f2daf17e4357aaf12a04b86775dc64aa1164a` 合入并推送；对应 CI `33935197099` 已核验 `completed/success`，test 与 macos-build 两个 job 均成功。原始 READY 是交付历史，不再作为当前 main 状态。
- 已完成：四个 singleton 保留源 snapshot；知客僧由其余 24 项击败依赖控制预警/入场；解析及运行层拒绝异常依赖和 all-active 绕门。主窗口独立复核实际 diff、生产唯一击败消费点、保护边界和原始验证日志。
- 初次修复验证：初始 RED 8 PASS/3 FAIL；定向 68/68；邻接/共享 288/288；三 mutation 各 1 FAIL 后精确恢复；analyze 0 issue，format 1741/0 changed；一轮持锁全量 6017/6017、exit 0（08:16:20–08:25:12 CST，8 分 52 秒），08:25:22 自有锁已释放。测试文件零删除；完整命令与日志见本批审计。
- 集成验证：原候选预检只因 PROGRESS 禁改项失败（full 明确跳过），未直接放行。拆分后提交再做双向 mutation，各 1 FAIL 后精确还原，Ch13 11/11；完整标准 Gate 原生 PASS（全量 6017/6017、analyze、1741/0 format、receipt matched）；main 合并后 analyze、288/288 targeted、1742/0 format、全量 6017/6017 均通过。main 多出的 1 个格式文件是原有 ignored `battle_providers.g.dart`，未改动或提交。
- 治理收尾要求：只回填已发生事实，以最终治理提交的 exact-SHA CI 和 clean 核验交付；本批代码施工已结束，不启动塔或 M8/M9。
- 成本/状态：初次修复全量 1/1；新授权集成按硬门禁追加 2 轮（Gate + main），均已完成，不再增加本地全量。Gate 实际 08:36:34–08:53:28（16 分 54 秒）；main 全量 08:54:44–09:07:20（12 分 36 秒）。正式 Gate 增量 0，修复工程合同 3/3 已集成；发生 1 次治理分离，生产返工/合并冲突为 0；不伪造整批起止或 token 使用量。
- 残留：本批代码修复无待批权限或新设计决策；独立真人/Windows 验收仍挂账。上轮只读 Ch13/M0 12/12、塔 9/9 不冒充本批验收。

交付证据：`docs/audit/phase2_m7_ch13_contract_fix_2026-09-05.md`。
