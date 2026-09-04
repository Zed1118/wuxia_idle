# Phase 2 M7 依赖语义与真人验收包收口计划

## 目标与结果合同

- 单一结果：消除 M7 `dependencies` 的执行/关闭歧义，并提供绑定最终 clean HEAD 的单人集中真人验收包。
- 分支：`codex/p2-m7-dependency-human-package-20260904`。
- 固定正式分母：Phase 2 保持 `1/10`；本任务不代签 M2–M6，不增加 M7 主线 `81/105` 或塔 `0/49` 分子。
- 解锁关系：M3/M4 已集成的工程基础允许 M7 内容工程继续；M2–M6 的真人/Windows 项仍阻断正式 M7 关闭和后续发布门。
- 非目标：不改玩法、数值、奖励、经济、schema/saveVersion、GDD/CLAUDE，不启动 M8/M9，不把 debug 路由或自动化当真人证据。

## 验收标准

1. decision registry 与 M7 顶层任务都明确区分 `engineering_progression` 和 `formal_close`，并保留 M2–M6 正式依赖。
2. 集中验收包从 clean、已检出的 exact HEAD 构建一个 macOS Profile 根应用，记录 commit、AOT SHA-256、fixture SHA-256 与应用包 SHA-256。
3. 包内清单覆盖 M2 战斗、M3 五武器、M4 视听/高密度、M5 六模式、M6 导航/叙事；每项只允许 `PASS / REWORK / BLOCKED / NOT_RUN`，默认均为 `NOT_RUN`。
4. 默认启动生产入口；视觉路由仅标为辅助定位，不得计入真人生产流签字。
5. 脚本合同测试、YAML 解析、targeted、analyze、format 与风险匹配回归通过；最终进入 main/origin/main、exact-SHA CI 成功且工作树 clean。

## 任务切片

1. 写回依赖语义、授权依据和正式关闭边界。
2. 新增可复现的集中验收包生成器、清单模板与合同测试。
3. 定向验证、冻结 READY、受控集成、回归和 exact-SHA CI。
4. 在最终 clean HEAD 运行生成器，留下本地可执行验收包；真人未实际操作前所有门保持开放。

## 当前恢复点

- 状态：依赖语义治理施工中。
- 最后完成：实时确认 `main == origin/main == 05d7bd29`、正式 `1/10`、M7 `81/105`、现有 Route C 六人包不适合作为本轮单人集中验收包。
- 下一步：更新 decision/task registry 与 PROGRESS，再实现验收包生成器。
- 已跑验证：开局工作树 clean；最新 exact-SHA CI run `33826562603` 为 success。
- 阻塞项：真人填写与 Windows 实机证据必须由后续真实操作产生，本任务不能自动关闭。
