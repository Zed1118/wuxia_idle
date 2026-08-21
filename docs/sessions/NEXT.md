# 新会话开局清单

> 更新时间：2026-08-21 · Phase 0A 起手 powerSkill 批
> 在途分支：无（本批完成后合回 `main`；未授权不 push）

## 当前结论

- Phase 1 Ch1 内容/live/headless/真实结算链、neutral snapshot 与正式桌面控制均已成立。
- 正式输入：鼠标左键 click/hold 普攻，J 兼容；数字/小键盘 1–6 对应真实装配技能，第七 key 破招槽独立。
- D1-A / D2-A / D3-A / D4-A 已按用户推荐组合拍板；决策单见 `docs/spec/2026-08-21-phase0a-founder-skill-qr-decision-sheet.md`。
- D1 已实现：三本创建页入门心法以显式 `skillUnlockLayers` 只将第 2 招 powerSkill 提前至初窥；祖师修炼层、大招门槛、全局 threshold、敌人与伤害均不动。
- 修复校准逮到的接线问题：autoFill 的 normalAttack 不再同时进入鼠标 basic 与数字 1，旧 3v3 autoFill 语义不改。
- 08-21 表现层三批已在 main：演员位移插值/局部重绘、分类 VFX 生命期、飘字居民上限、命中/出手微动作、落地墨印与敌/我/精英可读性均成立。
- 08-21 debug fixture 与敌方生产装配器已改为直接构造 `CombatantSnapshot`，不再内部绕旧 `BattleCharacter`；旧消费接口保持不变。
- 生产预检 manifest 已覆盖 Ch2–Ch21 主线 100 关与塔 49 层：73+41 条 eligible 进入同核 headless；35 条动态机制 fail-closed skipped。
- 玩家生产装配已直接使用 `PlayerCombatantSnapshotBuilder`；最后一处 `BattleCharacter.fromCharacter → toSnapshot` 内部中转及 neutral roster 的 3-slot 泄漏已清除，旧消费接口保持兼容。
- 1280×720/1440×900 实窗口截图与 W/D/J/Q/R 动态 smoke 通过；无布局溢出、运行异常或缺图。
- 正式替换仍锁六人主观 Gate、Windows 实机 Gate、其余消费面迁移。

## 画像结论

- timeout 0/1500；最大单击 2446，红线安全。
- 08-21 刷新画像：timeout 0/1500，最大单击 2446；三流派 main1 均为真实 powerSkill，ultimate 仍空。
- numeric 1–6 总出手 500 次且仅刚猛触发，命中伤害为 0；灵巧/阴柔仍未出手，说明 D1 解决可见性但未解决固定 Q/R 的资源/策略循环。
- 当前最低点为灵巧 `stage_01_05` bot 胜率 4%；基线已包含后续 Boss phase 能力，禁止把与 08-20 的差值全部归因于 D1 或据此调敌。
- Q gather 每场一次且零伤，R clear 0 次；现有资源循环不支持长期固定 Q/R 战术印。

## 最新验证

1. 08-21 起手 powerSkill：旧行为红测命中；focused **23/23**、`flutter analyze` 0 issue；1500 局 evidence 全部完成，最终全量待批末核。
2. 08-21 玩家 neutral builder：逐字段/roster/主线真实 Isar/远征/断魂庄 targeted **83/83**；最终全量 **5265/0**。
3. 08-21 生产预检：10-seed **3420 runs** = 555 胜/2865 负/0 timeout，最大单击 2056；最终全量 **5261/0**。
4. 视觉证据：`build/visual_acceptance/phase0a_0821_closeout/`（gitignored）含双视口 PNG/log/manifest，两路均为原生 window-id 截图。

## 下一步任务（需人类判断优先）

### P0 · Ch1 真人小样与已拍方案落地

1. 刚猛/灵巧/阴柔各试玩 stage_01_01、01_03、01_05，记录耗时、受击、空技能栏理解和 Q/R 使用。
2. 起手技能可见性 D1-A 已完成；下一原子批按 D2-A/D3-A/D4-A 实装 typed `Phase0aSkillBehavior`/geometry 纵切。
3. 先各选一门真实 Q/R 技能贯通 YAML→loader→binding→intent→reducer→event/headless；coverage 未满前固定 Adapter 只作显式 fallback。
4. 真人确认后才局部校准灵巧 Boss 分叉，禁止据 bot 单点全局削弱敌人。

### 后续工程

1. 低消下一切片：对 24 条 Boss phase/charge skipped 内容先冻结 capability matrix，再选一个机制纵切接入 reducer/AI/headless；不得用降级运行冒充迁移。
2. 随后拆 vulnerability/guardian，`stage_21_05` survive condition 单列。
3. 按 ADR 迁远征、断魂庄单主角续传与扫荡 headless 直结；只消费 manifest eligible 内容。
4. 六人主观 Gate、Windows 实机 Gate、Phase 0B MANUAL_RIG 继续依赖锁死；未授权不 push。
