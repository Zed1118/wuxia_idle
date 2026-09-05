# Phase 2 六项桌面修复授权集成

## 结果合同与边界

- 用户批准上一轮提出的“六项修复合入 main、全量回归与 exact-SHA CI”。候选 `0784c7acdfca377b2b2c0c11d4ecce4df5c79e59`，来源分支 `codex/p2-delegated-desktop-acceptance-20260905`；执行在主 checkout 的 `main`。
- 13:54 CST 实时基线：main/origin/main `79adb840be807e0ef6af048b2f9deef0732bd0ab`，双方 clean，fetch 后未漂移；main 是候选祖先。
- 主目标是一个集成门 0/1→1/1：六项既定修复进入 main，风险匹配验证及精确 SHA CI 通过，工作树 clean。正式 M0–M9 仍 1/10；不扩充功能或借此关闭 M4。
- 首个成本检查点 14:54 CST，主成本为墙钟；计划一轮新增持锁全量。仅生产/测试修复可能影响全仓时复跑；治理尾不重复本地全量。预计至多两次 push（merge 与证据/治理尾），分别核对 exact-SHA CI。
- 不改领域坐标、数值、奖励、schema/saveVersion、迁移集合或已批准决策。原用户存档不进入实测；继续使用独立容器。保留当前任务 worktree 与测试恢复物，不做分支或 worktree 清理。

## 集成 checklist

1. 核对真实 diff、祖先、clean、授权、生产消费与失败行为；仅预定 lib/test 及治理文件，无生成文件/日志误提交。
2. no-ff 集成；候选 `lib/ data/ test/` 与 merge 保持一致，若冲突不得用旧状态覆盖当前账本。
3. main 上 analyze、format、覆盖本批全部改动的 targeted tests、持锁全量；测试契约迁移单独核对，既有断言迁移与治理更新不冒称未修改测试/治理。
4. 合并后构建真实 production-root Profile，独立存档复验代表路径及常规窗口。AI 实机、自动化、自然人听感、精确尺寸证据与 Windows 分开。
5. push 精确集成 SHA，核对 CI 的 headSha、最终 conclusion 及各 job；失败先定位修复，不提前放行。
6. 结果入审计与 PROGRESS，治理尾源码不变则不重复本地全量；最终确认 main==origin/main、双方 clean，输出精确 SHA/CI 与剩余风险。

## 当前恢复点

- no-ff 合并 `af5cedf81445ca2bf41cac852e404a515c9ee700` 无冲突，源码与候选一致；本文件及 PROGRESS 随 merge 登记授权状态。
- 生产差异复核：13 个 lib 文件，仅共享表现层、地图/六地点色板及塔败绩持久化后刷新；无 data/pubspec/CI 修改。地图浅/深色 token 分离、空槽/存活终局语义、屏外选取与绘制一致；塔失败记账 owner/次数未变。
- 测试契约迁移 Gate PASS：expect 删 1/增 30，用例删 0/增 5，登记 1；基础为该局部改动开始前的 `b13a0094`。不把它说成通用 afk/gate.sh 原生全绿；本轮按 CLAUDE §8.2 清单执行集成验收。
- 13:59：main analyze 无问题、format 1646/0 changed、targeted 376 PASS。初轮持锁全量发现 1 个真实审计失败（地图标题 8% paper tint 被扫描器当成不透明浅纸面），05:57:53–05:59:07 UTC 提前中止，日志留存；Flutter 中止时返回 0 并带 shutdown 错误，**不计全量 PASS**。
- 修正只加既有规则允许的两条局部审计说明，不改画面或扫描器规则；增强真实 map widget 的合成底色对比度断言。审计/地图 33 PASS；将覆层 alpha 临时改成 1，定向断言有效 RED，随后精确还原。下一步再跑增强定向与一轮完整持锁全量，然后冻结包实机及最终受检 HEAD CI；未单独推送已知审计失败的原 merge。
- 14:10 检查点：修正提交 `13504129` 的完整全量 6030 PASS/1 FAIL（9 分 20 秒），唯一失败为 debug density fixture 默认 finder 把 Offstage 当未挂载。现改为逐个核对 24 个 resident actor，同时分别核对镜头内可见、镜头外隐藏，断言未删除；密度/屏外/解码 26 PASS，强制绘制屏外角色得到 1 FAIL 后精确还原。最终将新增一次完整全量，成本从原计划一轮增至一次中止加两次完整执行；原因是全量发现的两处集成测试缺口，不扩产品范围。
- `13504129` Profile 已构建并从独立存档生产根实测：地图/塔详情可读；塔原页 59/2→60/3；主线 05 可见胜利气血 6070/6070、Q/R 无倒地。1280×720 及目标 1440×900 扩展窗口实走，精确尺寸读回仍未取得。应用已退出，原三档哈希前后不变。后续测试/文档修正不改变该冻结包的生产代码。
