# P2-M0-QODER-BASELINE 计划 · 性能与测试基线地图

> 日期:2026-08-23 · 协议:CLAUDE.md §8.0 可恢复任务 + §8.3 就绪信号

## 目标

建立 M0 性能与测试基线地图:**只读盘点,不改生产代码**。产出
`docs/audit/phase2_m0_performance_and_test_baseline_2026-08-23.md`,覆盖
Phase 0A 确定性、同核(手动/bot/headless)、生产路由、帧性能、内存、战斗时长、
双视口、群战高密度、既有 diagnostic/fixture 的真实文件、入口、命令、可复用证据与缺口。

- tool / model:`Qoder CLI` + `Qwen3.8-Max`

## 分支 / 工作区

- 分支:`codex/phase2-m0-qoder-baseline-20260823`(worktree 即本仓)。
- 起点:`e292d3a0`;工作区干净;文件白名单仅两份新增文档,无其他改动。

## 验收标准

1. audit 报告区分【已验证事实/历史记录/待测项】,数字均有出处或标注待测。
2. 给出四小时批可执行的精确命令与 L0–L4 资源锁顺序。
3. `git diff --check` 空;白名单外零改动;工作区干净。
4. tip commit 恰为 `[READY][QODER][P2-M0] 完成性能与测试基线主审`(由 Codex 主审完成权限受限的提交收尾)。
5. 不 push、不合并 main、不升级依赖、不删除文件、不跑全量测试、不开视觉窗口。

## 任务切片(S1–S6 完成)

- [x] S1 读取 AGENTS/CLAUDE/已否清单/二阶段方案(桌面文件被权限拦截,记缺口 G1)。
- [x] S2 三路并行盘点:同核/bot/确定性;帧/内存/路由/视口/群战;测试资产与历史数字。
- [x] S3 亲验关键事实:651 测试、0 个 `.g.dart`、无 `libisar.dylib`、VisualRoute 77、
      `numbers.yaml` 时长预算与 `mainline_wave` 2/3/4、Gate 脚本复合门原文、
      `phase0a_debug_battle.yaml` fixture 原文、hd900=1600×900 vs Gate 1440×900 差异。
- [x] S4 探针执行尝试:`flutter`/Bash 被环境权限拦截(无交互通道),
      未自行绕开;全部动态项按待测登记,命令进 §5 批计划。
- [x] S5 撰写 audit 报告 + 本计划落盘;白名单校验与 `git diff --check` 通过。
- [x] S6 Qoder CLI 因权限层无法提交；Codex 主审复核内容、修正命令与状态后完成提交收尾。

## 主要结论(详 audit 报告)

- 基建完备:同核 reducer + headless runner + 玩家 bot + `BattleFrameProfileProbe`
  (帧 p99/RSS/GC 遥测)+ 双平台 Gate 脚本,已有 2026-08-23 实机证据(历史口径)。
- 缺口十条:高密度实时群战无压测场景、战斗耗时无回归守卫、内存无长跑基线、
  `balance_simulator_test` 文档漂移、无 `integration_test`/benchmark、
  Isar IO 压测未实装、生产 1600×900 不在 Gate 视口白名单等。

## 当前恢复点

- **状态**:Qoder 静态基线已由 Codex 主审收尾；性能实机数据仍待执行。
- **最后完成**:修正 fresh-worktree 命令、无效 harness 直跑命令和 Gate 重复构建；登记 Codex 已补的 77/77 targeted 与全仓 analyze 0。
- **下一步**:合入候选整合分支；按 audit §5 的 B1–B8 串行补动态性能/压力/全量证据。
- **已跑验证**:Qoder 只读亲验 + Codex 主审 `git diff --check`、文件白名单、动态候选联合测试与 analyze。
- **阻塞项**:无文档交付阻塞；真窗口性能 Gate 需 L4 前台独占，留待后续批次。
