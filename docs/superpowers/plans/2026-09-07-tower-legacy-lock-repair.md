# 修复老档爬塔锁死

候选分支：`codex/fix-tower-legacy-lock-20260907`；基线 `c890208e526f49dc391f12478f6ea53eae464afd`。本文件所在提交就是统一候选，精确 SHA 同步到外部交付报告。主仓 HEAD 与既有 AGENTS.md、CLAUDE.md、冻结归档、.qoder/ 均保留。data/*.yaml 未改；未合并、push 或发布。

已完成：0.42 墓碑回填按 highestClearedFloor 收口，已完成周目循环跳过当前周目，当前周目单独回填；新增 0.46 数据修复，严格匹配指定 a–d 条件且不跨槽；五处结算入口统一首通与重复/成长两批判重，仍处于同一 Isar 写事务。首通已领不能否决进度或重复奖励，重放与异常回滚维持原有边界。

验证：生成成功；flutter analyze 0 issue；全量 flutter test --coverage --reporter json 6114/6114，0 failure、0 skip，891/891 文件且声明数与完成数一致，实际 937.89 秒；覆盖率 47524/55325（85.90%，门槛 81.25%）；dart format . 完成，后续 CI 范围格式检查 1657 files / 0 changed；flutter build macos 生成 Release/wuxia_idle.app（177.2 MB）。未设置 DEVELOPER_DIR。全量正常等待并取得现有共享锁，没有夺锁或删除锁。独立源代码复核未发现新增阻断问题；首次新 worktree 缺失的独立 probe 包依赖已补齐。

变异：仅还原 (1) 仍 5/5，因为 (2) 清理兜底；隔离后续清理的 0.42 对照为正确循环 1/1，旧循环 0/1（坏墓碑未消失）；禁用 (2) 的 0.45 坏档回归为 0/1；将 (3) 恢复单批后生产结算复现 Tower reward settlement was already applied。全部恢复后 5/5，所有临时生产变异逐字节恢复。不能宣称只还原 (1) 就使最终进度断言变红。

已知口径限制：highestClearedFloor 仅在当前周目单调，advanceCycle 会清零。按用户指定 a–d 清理可能删除已完成旧周目的合法迁移墓碑；本次不按 cycle 精分。当前入口只结算当前周目，未发现旧周目重放入口，但不宣称历史清理零误删。该事实已反馈用户并写入代码注释。

生产回归使用临时 Isar 与已完成战斗快照进入真实结算入口，没有手设结算后进度，未操作用户真实存档。macOS 构建与自动化不等于 Windows、真人桌面或正式 Phase 2 验收。未运行远程 CI。

完整交付报告、22 文件行号清单、命令输出、全量 manifest、变异日志和覆盖率：[/Users/a10506/.codex/outputs/tower-p0-20260907/交付报告.md](/Users/a10506/.codex/outputs/tower-p0-20260907/交付报告.md)。本轮没有待实施项；后续合并/推送/发布另行授权。
