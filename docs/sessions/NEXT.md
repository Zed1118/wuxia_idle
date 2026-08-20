# 新会话开局清单

> 更新时间：2026-08-20 · Phase 0A Ch1 真实技能画像收账
> 在途分支：`codex/phase0a-ch1-skill-profile-0820`（READY，待合并）

## 当前结论

- Phase 1 Ch1 内容/live/headless/真实结算链、neutral snapshot 与正式桌面控制均已成立。
- 正式输入：鼠标左键 click/hold 普攻，J 兼容；数字/小键盘 1–6 对应真实装配技能，第七 key 破招槽独立。
- 本批建立 production 创建页三流派 × Ch1 五关 × 100 seeds = 1500 局观察基线；零 YAML、公式和数值调整。
- 修复校准逮到的接线问题：autoFill 的 normalAttack 不再同时进入鼠标 basic 与数字 1，旧 3v3 autoFill 语义不改。
- 正式替换仍锁六人主观 Gate、Windows 实机 Gate、其余消费面迁移。

## 画像结论

- timeout 0/1500；最大单击 2446，红线安全。
- 最低点：灵巧 `stage_01_05` bot 胜率 53%；刚猛/阴柔 Boss 均 100%。
- 阴柔 `stage_01_03` 为 98%；其余组合 100%。
- p50 约 13–43 ticks，即 1.3–4.3 秒；坡度不单调，bot 结果不能替代真人体感。
- 三流派 production 新档都只有 basic；排除重复 basic 后数字 1–6 cast 总数 0。
- Q gather 每场一次且零伤，R clear 0 次；现有资源循环不支持长期固定 Q/R 战术印。

## 本批完成

1. production founder profile helper：只走创建页 onboarding + production autoFill/assembler，禁 debug fixture 冒充。
2. event-driven observation/aggregate：胜负、ticks、HP/Qi、basic/Q/R/1–6 cast/hit/damage、暴击和最大单击。
3. diagnostic：默认 30 局 smoke；显式 UPDATE 跑 1500 局并重生 CSV/Markdown，降低日常全量成本。
4. audit 报告区分硬证据、观察项与真人后置，不锁脆弱胜率阈值。
5. analyze 0、targeted 36/36、最终全量 5251/0；文档扫描 1318 个 md、8344 引用、dead 65，基线守恒。

## 下一步任务（需人类判断优先）

### P0 · 合并与清理

1. `--no-ff` 合入 main；合并态 analyze、targeted、全量、doc scan；删除 worktree/分支。

### P1 · Ch1 真人小样与拍板

1. 刚猛/灵巧/阴柔各试玩 stage_01_01、01_03、01_05，记录耗时、受击、空技能栏理解和 Q/R 使用。
2. 拍板起手技能可见性：A 提前解锁一门 powerSkill / B 保持空槽并给成长预告 / C 调整全局 ultimate threshold（风险最高）。
3. 为 Q pull/R stagger 设计 `Phase0aSkillBehavior`/geometry schema；迁入真实技能后删除固定 Adapter。
4. 真人确认后才局部校准灵巧 Boss 分叉，禁止为 53% 单点全局削弱敌人。

### 后续工程

1. 按 ADR 迁远征、断魂庄单主角续传与扫荡 headless 直结。
2. 消费面稳定后扩其余 117 关与塔 49 层。
3. 六人主观 Gate、Windows 实机 Gate、Phase 0B MANUAL_RIG 继续依赖锁死。
