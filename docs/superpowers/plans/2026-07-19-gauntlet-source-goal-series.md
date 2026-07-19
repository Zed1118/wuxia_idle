# 目标序列派单 · 断魂庄来源语义 + 测试补强（恢复点）

- 分支：kimi/gauntlet-source
- worktree：.worktrees/kimi-gauntlet-source
- 基线：4417 pass / 0 fail（分片全量实测一致，2026-07-19）
- 环境：flutter analyze 0 issues；build_runner 已跑
- **终态：4/4 目标全部完成；收官分片全量 4431 pass / 0 fail（= 基线 4417 + 新增 14）；analyze 0 issues；dart format 全仓 0 changed**

## 目标 1：断魂庄首通奖励招的来源语义转正
- 状态：✅ 完成（commit 630125e3 / 55d59b7a / 9de68b12）
- 关键改动：
  - lib/data/defs/skill_def.dart — SkillSource 新增 gauntlet 枚举 + 解析 'gauntlet'（未知值仍抛 StateError）
  - lib/data/validation/skill_red_lines_validator.dart — enforceSkillSourceRedLines 新增
    gauntletRewardSkillIds 参数（默认空·fixture 兼容）+ ⑤+ 挂载点 source 校验 + ⑥ style/tier
    扩 gauntlet + ⑦ gauntlet 孤儿/重复/错挂三分支；既有 mainline/fragment 断言语义未动，
    mountDeferred 豁免机制保留（合成 defs 单测证明豁免仍生效）
  - lib/data/game_repository.dart:856 调用点传 firstClearRewardSkillId
  - data/skills.yaml 锁脉针段：source mainline_drop→gauntlet、删 mount_deferred、注释更新；
    数值字段（powerMultiplier/qiDrainPct/qiDelta 等）diff 零命中（grep 核对）
  - 消费方：skill_loadout_service/resolver、cangjingge_screen 三处 drop 招过滤扩 gauntlet；
    martial_codex_provider 两个穷尽 switch 补 gauntlet 分支（归真解组 trueSolution），无 default 吞值
  - 测试：skill_source_redline_test（生产自洽 + loader 错挂/deferred 注错 + 7 个合成 defs 直接单测
    覆盖孤儿/重复/错挂/豁免/⑥）、gauntlet_enemies_test 断言转正、wave_b_drop_skill_wiring_test
    新增锁脉针装配 e2e（未解锁拦→grantManual→可装→入装配池）
- 破坏性证据：loader 注入「首通奖励指向非 gauntlet 招」→ ⑤+ 抛；注入 mount_deferred → ⑦ 错挂抛；
  单测「挂载引用缺失」→ ⑦ 孤儿抛（集成路径下引用悬空由既有 _enforceGauntletEnemyRedLines⑥ 先逮）
- 已跑验证：targeted 全绿；分片全量 4427 pass / 0 fail（= 基线 + 新增 10）
- 阻塞项：无

## 目标 2：阵型选择分支行为级测试覆盖
- 状态：✅ 完成（commit 「目标2:补阵型选择分支行为级测试」）
- 覆盖对象：stage_entry_flow.dart `_pickFormation`（L1199-1215）+ `_FormationPickerDialog`
  （L1217-1259）+ initState 群战分支（L512-531）
- wiring 方案（前序「真队伍装配成本高」的解法）：不注入 battle*ForTest 走真实 `_runBattle` →
  真实 `_StageBattleHost`；仅 override battleProvider 为录制 notifier——`startBattle` 是群战分支
  唯一出口，录制 strategy/teams 即行为级观测点；真 Isar（Phase2SeedService.seedP3 含主修种子，
  过 buildTeams 硬前置）+ SharedPreferences mock + runAsync 真时钟轮询（branches_test 体例）
- 行为断言：三阵型 tile 可选态（label+hint）/ 默认预选雁行阵（ListTile.selected）/
  点八卦阵 → MassBattleStrategy(baGua) 落装配 + stepOne 烘焙进玩家队（敌方不沾）/
  未选关闭 → 回退默认雁行阵
- 文件：test/features/mainline/presentation/stage_entry_flow_formation_test.dart（2 tests）
- 残留风险：对话框「未选关闭」路径生产仅可能系统返回（barrierDismissible=false），测试用
  Navigator.pop 模拟；阵型三选一以外语义（modifier 数值）不在本测族

## 目标 3：coverage 计时型 flaky 根治
- 状态：✅ 完成（commit 「目标3:改心跳计时测试为轮询等待根治coverage插桩flaky」）
- 定位：test/features/seclusion/application/online_presence_controller_test.dart R2
  （docs/sessions 2026-07-15 CI 红 + 2026-07-19 首跑记录同指 online_presence R2 先例）
- 根因：R2 用固定 150ms 墙钟等 40ms 心跳 Timer.periodic 首触发 + 500ms 上界断言；
  coverage 插桩拖慢事件循环时 Timer 回调落败于固定等待 → lastOnlineAt 仍 t0 → 偶发红
- 修法（仅动测试文件）：R2 改轮询等基准被推离 t0（5s 上限）+ 2s 宽限近端断言；
  R6 失焦 unawaited touch 同法改轮询等落地。断言语义（心跳在跑/基准贴近现在）不变
- 证据：flutter test --coverage 该文件连跑 3 轮全绿（10/10 × 3）；非 coverage 亦绿
- 残留风险：5s 轮询上限在极端机器上理论仍可超时（原 150ms 的 33 倍余量）；同文件其余
  时序点（R3/disposed 的负向等待）语义上不会因减速假红，未动

## 目标 4（弹性）：入场流未覆盖分支续推
- 状态：✅ 完成（commit 「目标4:补入场流轻功与默认地面strategy分支行为级测试」）
- 覆盖对象：initState 轻功分支（L532-544）+ 默认地面分支（L545-552）
- 文件：test/features/mainline/presentation/stage_entry_flow_strategy_branch_test.dart（2 tests）：
  轻功关(竹林) → LightFootStrategy 挂接 + 地形烘焙进装配 + config 来自 numbers.lightFoot；
  普通主线关 → 不传 strategy（DefaultGroundStrategy 兜底）+ winCondition 透传 + 右队非波次装配
- 复用目标 2 录制 notifier 配方；未做覆盖率数字测量（语义覆盖优先）
- 残留风险：initState 首通门控（_readablePacing/_mode 决策）与错误页（_setupError）分支
  仍未专项覆盖；victory/defeat 结算链其余 hook 由既有 branches/pure 测族覆盖
