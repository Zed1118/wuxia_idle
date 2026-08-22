# 新会话开局清单

> 更新时间：2026-08-23 · Route C 双平台 Gate 收口后
> 当前主线：`main` 已包含最终 release 门禁 commit `451bc883975dbbb737d0f4cd72251f1c5379d8f3`

## 当前结论

- Phase 1 Ch1 内容/live/headless/真实结算链、neutral snapshot 与正式桌面控制均已成立。
- 正式输入：鼠标左键 click/hold 普攻，J 兼容；数字/小键盘 1–6 对应真实装配技能，第七 key 破招槽独立。
- D1-A / D2-A / D3-A / D4-A 已按用户推荐组合拍板；决策单见 `docs/spec/2026-08-21-phase0a-founder-skill-qr-decision-sheet.md`。
- D1 已实现：三本创建页入门心法以显式 `skillUnlockLayers` 只将第 2 招 powerSkill 提前至初窥；祖师修炼层、大招门槛、全局 threshold、敌人与伤害均不动。
- 修复校准逮到的接线问题：autoFill 的 normalAttack 不再同时进入鼠标 basic 与数字 1，旧 3v3 autoFill 语义不改。
- 08-21 表现层三批已在 main：演员位移插值/局部重绘、分类 VFX 生命期、飘字居民上限、命中/出手微动作、落地墨印与敌/我/精英可读性均成立。
- 08-21 debug fixture 与敌方生产装配器已改为直接构造 `CombatantSnapshot`，不再内部绕旧 `BattleCharacter`；旧消费接口保持不变。
- 生产预检 manifest 已覆盖 Ch2–Ch21 主线 100 关与塔 49 层；Boss phase/charge、vulnerability、guardian 与 survive condition 补齐后达到 **149/149 eligible、0 skipped**，全部进入同核 headless。
- 玩家生产装配已直接使用 `PlayerCombatantSnapshotBuilder`；最后一处 `BattleCharacter.fromCharacter → toSnapshot` 内部中转及 neutral roster 的 3-slot 泄漏已清除，旧消费接口保持兼容。
- 1280×720/1440×900 实窗口截图与 W/D/J/Q/R 动态 smoke 通过；无布局溢出、运行异常或缺图。
- 正式替换、旧 3v3 原子删除与双平台 Gate 均已完成并合入 `main`；六人主观 Gate 已取消，Windows 结果不代表产品最低配置。

## 画像结论

- timeout 0/1500；最大单击 2446，红线安全。
- 08-21 刷新画像：timeout 0/1500，最大单击 2446；三流派 main1 均为真实 powerSkill，ultimate 仍空。
- numeric 1–6 总出手 500 次且仅刚猛触发，命中伤害为 0；灵巧/阴柔仍未出手，说明 D1 解决可见性但未解决固定 Q/R 的资源/策略循环。
- 当前最低点为灵巧 `stage_01_05` bot 胜率 4%；基线已包含后续 Boss phase 能力，禁止把与 08-20 的差值全部归因于 D1 或据此调敌。
- Q gather 每场一次且零伤，R clear 0 次；现有资源循环不支持长期固定 Q/R 战术印。

## 最新验证
- CI 同口径：`flutter test --coverage --no-pub` **4230/4230 PASS**；line coverage **83.66%（32921/39351）≥81.25%**，coverage ratchet 通过。
- macOS release 门禁：增量构建曾复现外层签名陈旧、deep verify 失败；`tool/verify_macos_release.sh` 强制 clean tree/锁文件依赖/代码生成/clean build/deep codesign/双架构/哈希，并在构建后复核 tracked tree。最终 clean `main` commit `451bc883` 完整 PASS：生成 126 outputs、x86_64+arm64、169M、launcher `2a4ed520…46ac9`、AOT `722f39ee…16f35`；工作区仍 clean，不启动 GUI、不发布。
- mapping 防回流：Route C 类体级源码门禁禁止重新声明 `winCondition` / `numericSkillBindings` 镜像，并要求 `initialState` / `playerAdapter` 单一来源存在；临时回添字段精确 1 红，还原复绿。Route C 契约 **8/8**、Phase 0A application **139/139**、无参数 analyze 0 issue；父提交全量 **4228/4228**。
- analyzer 边界：Route C 删除旧 runner 后，唯一一次性历史 `.dart` 探针使无参数 analyze 报 12 个旧符号错误；现仅精确排除该附件，不扩大目录豁免。`flutter analyze --no-pub` 与 `flutter analyze --no-pub lib test tool` 均 0 issue。
- 数字技能绑定单一来源：删除 `Phase0aStageMapping.numericSkillBindings` 镜像，主线/塔/断魂庄宿主与测试统一从 `playerAdapter.numericSkillBindings` 读取；对象实例与行为不变。目标独立文件 **36/36**、Phase 0A application **139/139**、`flutter analyze --no-pub lib test` 0 issue、format/diff check 通过。
- 胜负条件单一来源：删除生产零读取且与初始状态必然同值的 `Phase0aStageMapping.winCondition` 镜像，survive-ticks 与主线接线回归统一读取 `initialState.winCondition`。目标三文件 **24/24**、Phase 0A application **139/139**、`flutter analyze --no-pub lib test` 0 issue、format/diff check 通过。
- 敌方行动有效战斗兼容：`EnemySkillStarted` / `BossChargeStarted` 现与旧 runner 任一单位 actionLog 语义一致，玩家只移动/闪避且敌方 skill-only 时不再漏掉战后内息调息。其余 19 类事件的伤害、AOE、截招、多波、数字技已逐类证伪无迁移漏计。targeted **156/156**、analyze 0、format/diff check 通过。
0. 护法合击战后统计兼容：旧 runner 的总伤害既定为双方完整 actionLog，普通敌伤计入不是 bug；Phase 0A 合击无伴随 HitLanded 才是唯一漏项。事件现保存主护法单次 damage/critical，settlement 按历史 `attackResult=r1` 精确恢复统计；双护法合计仍只供实际扣血/VFX。targeted **186/186**、analyze 0、diff check 通过；父提交全量 **4226/4226**、macOS release 174.1MB 构建成功。
1. 结算玩家身份守卫：终态玩家 id/side 必须与映射一致，映射恰有一个玩家 combatant；玩家缺失不再静默回填 HP=0 后误加伤势。结算全消费面 **59/59**、两条守卫直测所在文件 **4/4**、analyze 0、diff check 通过。断魂庄恒定 seed 差异登记 BACKLOG #21，未改随机性口径。
2. Q/R adapter 构造收口：production mapper 的 slot/radius/qi/cooldown 必填镜像改由真实 typed binding 派生，不再读取 legacy player Q/R 数值；`numbers.yaml` 与低层 fixture 均未改。mapper + preflight + Route C 契约 **28/28**，preflight **149/149 eligible、447 runs、0 timeout、maxDamage 2044**，analyze 0、diff check 通过。
3. production basic 收口：五消费面 assembler 保证真实 basic，mapper 缺 basic fail-closed；9 个 mapper fixture 已迁仓库真实技能，最后一个 synthetic `_moveSkill` 删除。production preflight **149/149 eligible、447 runs、0 timeout、maxDamage 2044**；mapper 全消费面 **82/82**、装配器/Route C 契约 **8/8**、analyze 0、最终全量 **4224/4224**、diff check 通过。真实 basic `qiDelta=20` 与 Phase 0A adapter 配置 0 的差异登记 BACKLOG #20，未改值。
4. Q/R typed binding 收口：loader 拒绝 Q/R 任一缺失或空白；legacy interrupt/qi-drain fail-closed 分支已有直接回归。随后 DeepSeek 与主 agent 双重可达性审计证明 mapper 双空逃生口及 synthetic clear 分支对 production、测试与 debug fixture 全部不可达，已删除并把 mapper 内 Q/R 类型收紧为非空；低层隔离 Adapter fixture 兼容不变。前批 targeted **42/42**、最终全量 **4223/4223**；删除批 production preflight **149/149 eligible、447 runs、0 timeout、maxDamage 2044**，联合 targeted/route contract **43/43**、analyze 0、diff check 通过。
5. Route C 后加固批：Boss 双视口反馈链与 cycle-2 vulnerability 真实伤害覆盖 targeted **15/15**；全量 **4221/4221**、`flutter analyze --no-pub lib test tool` 0 issue、diff check 通过。Route C Gate commit `597a243b` 的 Mac/Windows 矩阵仍各 **6/6 PASS**；新 commit 不沿用该二进制 Gate 冒签。

6. 08-21 起手 powerSkill：旧行为红测命中；focused **23/23**、`flutter analyze` 0 issue；1500 局 evidence 全部完成；最终全量 **5278/0**。
7. 08-21 玩家 neutral builder：逐字段/roster/主线真实 Isar/远征/断魂庄 targeted **83/83**；最终全量 **5265/0**。
8. 08-21 生产预检：10-seed **3420 runs** = 555 胜/2865 负/0 timeout，最大单击 2056；最终全量 **5261/0**。
9. 视觉证据：`build/visual_acceptance/phase0a_0821_closeout/`（gitignored）含双视口 PNG/log/manifest，两路均为原生 window-id 截图。

## 下一步任务（需人类判断优先）

### P0 · 已拍方案继续落地

1. D1-A 与 Q/R typed behavior 纵切及 D2-A/D3-A/D4-A 审计已完成；production mapper 的 legacy fixed clear fallback 已删除。低层隔离 Adapter fixture 仍保留兼容，不得误当 production 路径。
2. Boss 蓄力预警、破招/踉跄与脆弱窗口已有双视口动态 Gate，并已补真实 fixture widget 回归；后续只处理新的可复现缺口。
3. 高周目 `cycleVulnerability` 生产链与 cycle-2 实际伤害回归均已覆盖，禁止重复实现。
4. 禁止据 bot 单点全局削弱敌人；任何玩法数值调整仍需用户明确授权。

### 后续工程

1. `tower_49` guardian、`tower_42` 协同、`stage_21_05` survive condition、远征/断魂庄续传与扫荡 headless 均已完成，禁止按旧 TODO 重做。
2. 先做表现可读性与高周期 vulnerability 覆盖的只读审计，再选择一个零数值、可自动验收的最小优化切片。
3. Phase 0B MANUAL_RIG 保持独立历史口径，不得用于签署 Route C 或新的生产 Gate。
