# 挂机武侠 · 开发进度

> 1.0 长线打磨期，质量优先、不设上线时间压力。操作规则见 CLAUDE.md；产品权威见 GDD.md。
> 本页只保留当前摘要；历史快照由 git、对应 audit 与 dispatch 报告追溯。

## 当前状态（2026-10-12）

- **正式 Gate：M0–M9 为 1/10，仅 M1。主 WIP 为 M2。** M0 的20项数值方向已选，等待验证，不重投票；心魔逐身份签认仍缺。M2–M6 人工/平台门未关闭，M7 工程迁移不能代签，M8/M9 尚未解锁。
- **已合 main（2026-10-12）**：候选 `codex/review-followthrough-20260922` @ `c46a769e0` 经协调者独立 Gate 后 `--no-ff` 合入 main 与集成链（GDD v1.79，saveVersion 0.52.0）。外部证据目录 `/Users/a10506/Documents/Codex/2026-09-22/wuxia-review-followthrough/`；收账见 `docs/dispatch/reports/2026-09-19_afk_report.md` 第五轮。
- **已连接能力**：G 单断魂庄跨关冷却/参战装备锁已在基线；R1 拒绝同角色闭关双占用、R2/R3 逐角色真实时间疗养及0.52存档加法、R4 Boss首胜按实际参战者记录均已合 main。塔49层已使用 typed 工厂，主线105与塔通用旧路由消费归零，特殊活动专用路径保留。详 `docs/audit/phase2_m7_tower_full_migration_2026-09-22.md`。
- **验证口径**：协调者独立 Gate 全量 `08:35 +7340` 全绿、analyze 0、format 1884/0；R1 占用与 R2/R3 疗养两向证红（2/3、5/9 红，还原绿）。远端 CI 以合入 commit 为准；物理 Windows、真人与真实存档 0.40→0.52 迁移仍未验收。
- **前三阻塞**：①合法新档第一章连续体验：两条固定脚本均未通过黑风岭，04/05未进入，真人容错待验；②M4同版本合格生产矩阵与历史长帧定位；③同冻结版M2–M6真人及物理Windows。各项不能以自动诊断、Mac短样本或UI smoke替代。
- **M4实测边界**：`29d2fb009` 双视口塔6轮帧/RSS均通过，3轮静默基线合格，矩阵另28格未采；历史01_05@1440的59.678ms raster根因未定。后台干扰后已结束本批采样，不结束用户应用或放宽阈值。证据见外部 `m4/性能采样结果.md`。
- **待决与下一步**：R5奇遇击杀账需明确真实击杀或旧通关配额口径；不先改经济倍率。完成本轮工具/状态收口与统一回归后，准备同一候选的人工验收入口；M2/M4反馈与Windows条件就绪后按依赖继续。真人待决不视为默认批准。
- **时间与保护**：约90分钟无权威Gate变化时按CLAUDE §8.4重评路线。四个用户原有文件及真实存档保持保护；不清理历史分支/worktree。

## 已完成事项与恢复入口

- 09-22只读远端核对：main和集成链均为 `02994529f80953a56172725aa04febbfaf1144da`；旧“main仍342d…”/“主目录落后20提交”仅属历史。5A五段、满build 924轮探针、旧3v3删除、黄金文件搬迁均已完成，不重新派单。
- 满build边界见 `docs/audit/phase0a_full_build_extreme_probe_2026-09-19.md`；M0已批准映射见 `docs/audit/phase2_m0_production_mapping_2026-09-11.md`；正式Gate和历史集成证据见 `docs/dispatch/phase0a_overhaul/task_registry.yaml`。
- 真实三档未经本轮候选打开或迁移；历史副本0.49/0.40→0.50记录见 `docs/audit/save_migration_050_verification_2026-09-16.md`，不覆盖本轮0.52或真实存档验收。
- 本轮唯一外部恢复目录：`/Users/a10506/Documents/Codex/2026-09-22/wuxia-review-followthrough/`；恢复点 `execution-checkpoint.json`，人读结果 `本轮推进与验收接续.md`。旧29d2原生包与人工单只对29d2有效。
- 当前任务储备见 BACKLOG.md；已否任务见 `docs/spec/rejected_task_registry.md`；会话入口见 `docs/sessions/NEXT.md`。
