# 新会话开局清单

> 更新时间：2026-08-23 · Route C 双平台 Gate 收口后
> 当前主线：`main` 已含 Gate commit `597a243b2506610b5cbb74e2919be79bbf99e283`

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
0. Q/R typed binding 收口：loader 拒绝 Q/R 任一缺失或空白，mapper 只保留显式旧 fixture 的双空逃生口；legacy interrupt/qi-drain fail-closed 分支已有直接回归。targeted **42/42**、analyze 0、最终全量 **4223/4223**、diff check 通过。DeepSeek 审计判定 D3-A/D4-A 完整，D2-A 仅剩受内容能力矩阵约束的 legacy fallback 删除，不在本批强拆。
1. Route C 后加固批：Boss 双视口反馈链与 cycle-2 vulnerability 真实伤害覆盖 targeted **15/15**；全量 **4221/4221**、`flutter analyze --no-pub lib test tool` 0 issue、diff check 通过。Route C Gate commit `597a243b` 的 Mac/Windows 矩阵仍各 **6/6 PASS**；新 commit 不沿用该二进制 Gate 冒签。

2. 08-21 起手 powerSkill：旧行为红测命中；focused **23/23**、`flutter analyze` 0 issue；1500 局 evidence 全部完成；最终全量 **5278/0**。
3. 08-21 玩家 neutral builder：逐字段/roster/主线真实 Isar/远征/断魂庄 targeted **83/83**；最终全量 **5265/0**。
4. 08-21 生产预检：10-seed **3420 runs** = 555 胜/2865 负/0 timeout，最大单击 2056；最终全量 **5261/0**。
5. 视觉证据：`build/visual_acceptance/phase0a_0821_closeout/`（gitignored）含双视口 PNG/log/manifest，两路均为原生 window-id 截图。

## 下一步任务（需人类判断优先）

### P0 · 已拍方案继续落地

1. D1-A 与 Q/R typed behavior 纵切及 D2-A/D3-A/D4-A 审计已完成；legacy fixed adapter 删除仍受内容 Q/R capability matrix 前置约束，未满足前不得强拆。
2. Boss 蓄力预警、破招/踉跄与脆弱窗口已有双视口动态 Gate，并已补真实 fixture widget 回归；后续只处理新的可复现缺口。
3. 高周目 `cycleVulnerability` 生产链与 cycle-2 实际伤害回归均已覆盖，禁止重复实现。
4. 禁止据 bot 单点全局削弱敌人；任何玩法数值调整仍需用户明确授权。

### 后续工程

1. `tower_49` guardian、`tower_42` 协同、`stage_21_05` survive condition、远征/断魂庄续传与扫荡 headless 均已完成，禁止按旧 TODO 重做。
2. 先做表现可读性与高周期 vulnerability 覆盖的只读审计，再选择一个零数值、可自动验收的最小优化切片。
3. Phase 0B MANUAL_RIG 保持独立历史口径，不得用于签署 Route C 或新的生产 Gate。
