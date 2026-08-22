# Phase 0A 断魂庄单角色续传主线计划

## 目标

在默认关闭灰度门后接通断魂庄单角色三连战的 Phase 0A live/headless 续传，跨关保留 HP、真气、补给与会话阶段，并保持失败、恢复、奖励选择、断魂帖事务不变量。

## 分支

`codex/phase0a-gauntlet-main-0822`

## 验收标准

1. 生产接线：真实断魂庄 entry/service 消费 Phase 0A；历史多人由兼容选择器回落 legacy。
2. targeted test：三关胜负、跨关 HP/真气、补给、相位、崩溃恢复、奖励与门票幂等均有证据。
3. 红线：不改战斗数值/YAML/schema/saveVersion；复用 neutral snapshot/mapper/reducer；不新增 Dart 中文散写。
4. UI：若改 live host，补键鼠/常规视口 widget smoke；不启动 GUI。
5. 整合后 analyze 0、相关族测试全绿、批末全量一次；工作树干净；tip `[READY]`。

## 任务切片

1. 建 Phase 0A 断魂庄 mapper/runner 与状态转换红测。
2. 接 service/headless，锁定三连战状态与事务。
3. 接 live host/entry，并保持 legacy 路径。
4. 审查兼容分支并整合。
5. 跑 targeted/analyze/full/build，更新 PROGRESS 与恢复点。

## 当前恢复点

- 状态：进行中。
- 最后完成：基线、现有断魂庄事务与远征 Phase 0A 模板已审计；兼容接口已冻结。
- 下一步：建立 Phase 0A 单关 runner 与快照转换测试。
- 已跑验证：上一批基线 5390/5390、analyze 0（继承事实，未在本 worktree 重跑）。
- 阻塞项：无。
