# 目标序列派单 · 断魂庄来源语义 + 测试补强（恢复点）

- 分支：kimi/gauntlet-source
- worktree：.worktrees/kimi-gauntlet-source
- 基线：4417 pass / 0 fail（分片全量实测一致，2026-07-19）
- 环境：flutter analyze 0 issues；build_runner 已跑

## 目标 1：断魂庄首通奖励招的来源语义转正
- 状态：✅ 完成（3 commit：630125e3 / 55d59b7a / 9de68b12）
- 关键改动：
  - lib/data/defs/skill_def.dart — SkillSource 新增 gauntlet 枚举 + 解析 'gauntlet'（未知值仍抛）
  - lib/data/validation/skill_red_lines_validator.dart — enforceSkillSourceRedLines 新增
    gauntletRewardSkillIds 参数（默认空·fixture 兼容）+ ⑤+ 挂载点 source 校验 + ⑥ style/tier
    扩 gauntlet + ⑦ gauntlet 孤儿/重复/错挂三分支；既有 mainline/fragment 断言语义未动，
    mountDeferred 豁免机制保留
  - lib/data/game_repository.dart:856 调用点传 firstClearRewardSkillId
  - data/skills.yaml 锁脉针段：source mainline_drop→gauntlet、删 mount_deferred、注释更新；
    数值字段（powerMultiplier/qiDrainPct/qiDelta 等）diff 零命中
  - 消费方：skill_loadout_service/resolver、cangjingge_screen 三处 drop 招过滤扩 gauntlet；
    martial_codex_provider 两个穷尽 switch 补 gauntlet 分支（归真解组 trueSolution），无 default 吞值
  - 测试：skill_source_redline_test（生产自洽 + loader 错挂/deferred 注错 + 7 个合成 defs 直接单测
    覆盖孤儿/重复/错挂/豁免/⑥）、gauntlet_enemies_test 断言转正、wave_b_drop_skill_wiring_test
    新增锁脉针装配 e2e
- 破坏性证据：loader 注入「首通奖励指向非 gauntlet 招」→ ⑤+ 抛；注入 mount_deferred → ⑦ 错挂抛；
  单测「挂载引用缺失」→ ⑦ 孤儿抛（集成路径下引用悬空由既有 _enforceGauntletEnemyRedLines⑥ 先逮）
- 已跑验证：targeted 全绿；分片全量 4427 pass / 0 fail（= 基线 4417 + 新增 10）
- 阻塞项：无

## 目标 2：阵型选择分支行为级测试覆盖
- 状态：进行中
- 最后完成：目标 1 收尾
- 下一步：读 stage_entry_flow.dart _pickFormation 与群战 initState 触发链，找既有 runAsync/真 Isar 配方
- 已跑验证：—
- 阻塞项：无

## 目标 3：coverage 计时型 flaky 根治
- 状态：未开始

## 目标 4（弹性）：入场流未覆盖分支续推
- 状态：未开始
