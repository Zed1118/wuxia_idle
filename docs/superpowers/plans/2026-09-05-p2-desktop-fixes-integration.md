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

- 13:58：no-ff 合并无冲突，尚未提交；本文件及 PROGRESS 随本次 merge 登记授权状态。
- 生产差异复核：13 个 lib 文件，仅共享表现层、地图/六地点色板及塔败绩持久化后刷新；无 data/pubspec/CI 修改。地图浅/深色 token 分离、空槽/存活终局语义、屏外选取与绘制一致；塔失败记账 owner/次数未变。
- 测试契约迁移 Gate PASS：expect 删 1/增 30，用例删 0/增 5，登记 1；基础为该局部改动开始前的 `b13a0094`。不把它说成通用 afk/gate.sh 原生全绿；本轮按 CLAUDE §8.2 清单执行集成验收。
- 下一步：提交 merge，执行 main 的分析、格式、targeted 与一轮持锁全量，然后实机与 CI。
