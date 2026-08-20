# 新会话开局清单

> 更新时间：2026-08-20 · Phase 1 Ch1 纵切切片 2 收账
> 在途分支：`feat/phase1-vs-slice2-mainline-wiring-0820`（READY，待合并）

## 当前结论

- 战斗终态不变：Phase 0A 单角色 ARPG 按路线 C 替换旧 3v3，不做长期双轨。
- Phase 1 的 Mac 工程纵切已经成立：Ch1 五关真实内容可经 0A live/headless 同核运行，并接通结算、奖励、成长、伤势和进度。
- 正式替换尚未开始：六人主观 Gate、Windows 实机 Gate、其余消费面迁移仍是硬前提。
- 死链基线仍为 65（B 23 + D 42 已接受残余），不是机械清零任务。

## 本批完成

1. 新增引擎无关 `CombatSettlementSnapshot`；旧 3v3 与 Phase 0A 分别适配，0A 不再伪读旧 `battleProvider`。
2. live controller/headless 保留同源语义事件，宿主随胜负回传真实 HP、伤害、暴击和参战者快照。
3. 灰度门只放 `stage_01_01..05` 一周目；Ch2、塔、二周目继续旧入口。
4. fixed delta 及 300 秒预算迁入 `phase0a_arena.simulation`，加载期拒绝非正/非有限值；live/headless 同源。
5. 开场真气透传 `BattleCharacter.currentQi`；Boss elite/击败语义恢复；内部 Phase0A move id 不写入真实心法熟练度。
6. 胜利发奖励/经验/轻伤并只结算祖师；战败走真实末态；系统返回旁路所有奖励、惩罚和进度。
7. Q/R 群体技能 outcome 补暴击位，战后 `criticalCount` 不漏算。

## 验证快照

- `flutter analyze`：0 issue。
- 最终全量：`flutter test --no-pub --reporter=compact` = **5207 pass / 0 fail**。
- Ch1 五关同 seed：live controller/headless 胜负、事件、双方末态 HP 全等。
- 真实 Ch1 → headless → Isar：奖励、经验、伤势入库；未参战替补零污染。
- UI/工程：1280×720、1440×900 宿主与表现组通过；0C 50 次进退、暂停/恢复、三视口缩放通过。
- 文档扫描：1313 个 md、8340 引用、dead 65，基线守恒。

## 下一步任务（依赖顺序）

### P0 · 合并与清理

1. 走合并 Gate 把 READY 分支 `--no-ff` 合入 main，合并态复跑 analyze + 关键 targeted；删除已合本地分支。

### P1 · 路线 C 后续工程前置

1. 抽离 `StageBattleSetup.buildEnemyTeam` 等角色快照职责，解除 0A 对待退役 3v3 application 层的临时依赖。
2. 设计真实玩家技能到 J/Q/R 的映射；当前内部 move id 有意不记心法熟练度，避免污染账本。
3. 用 headless 胜率画像与真人试玩校准 Ch1；“五关全胜”只证明链路，不等于难度已定。
4. Phase 1 稳定后再扩 122 关，并按内容迁移 ADR 依次处理远征、断魂庄托管与扫荡 headless 直结。

### 依赖锁死 · 不提前执行

1. Phase 0A 六人主观 Gate：与 BACKLOG 一#19/#4/#5/#6 合并试玩局，需用户排期。
2. Windows 实机 Gate：正式替换前必须人工完成。
3. 旧 3v3/65 路由原子拆除：只在消费面迁移、六人 Gate、Windows Gate 全过后同次 merge，保持零空窗。
4. Phase 0B `MANUAL_RIG_PENDING`：人工美术工作。
