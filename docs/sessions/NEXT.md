# 新会话开局清单

> 更新时间：2026-08-20 · 战斗角色快照 seam 深化收账
> 在途分支：`codex/stage-snapshot-seam-0820`（READY，待合并）

## 当前结论

- 战斗终态不变：Phase 0A 单角色 ARPG 按路线 C 替换旧 3v3，不做长期双轨。
- Phase 1 的 Mac 工程纵切已经成立：Ch1 五关真实内容可经 0A live/headless 同核运行，并接通结算、奖励、成长、伤势和进度。
- 本批已解除 Phase 0A 对 `StageBattleSetup` 的直接依赖；玩家/敌人开战装配集中到两个深 Module，旧 3v3 只保留 orchestration 与 legacy Adapter。
- 正式替换尚未开始：六人主观 Gate、Windows 实机 Gate、其余消费面迁移仍是硬前提。
- 死链基线仍为 65（B 23 + D 42 已接受残余），不是机械清零任务。

## 本批完成

1. 新增 `PlayerBattleCharacterAssembler`：active roster 保留占用过滤与 seed fallback；exact roster 严格保序，空、重复、缺失均 fail-fast。
2. 新增 `EnemyBattleCharacterAssembler`：集中周目、境界、词条、Boss 机制、真气与首通可读调节等 implementation。
3. 可复用敌方装配返回完整输入；旧 3 人 cap 留在 `StageBattleSetup` legacy Adapter，不污染 Phase 0A。
4. Phase 0A mapper/host、远征、断魂庄改走新 seam；源码契约禁止 Phase 0A 回引 `StageBattleSetup`。
5. `StageBattleSetup` 降为旧主线/塔/心魔/恩怨 orchestration 与兼容委托；零 YAML、公式、数值及玩家可见行为改动。

## 验证快照

- `flutter analyze`：0 issue。
- targeted：selection、enemy parity、Phase 0A Ch1、远征、断魂庄、主线/塔/扫荡全部通过。
- 最终全量：`flutter test --no-pub --reporter=compact` = **5213 pass / 0 fail**。
- 源码删除 Gate：Phase 0A application/host 禁 `StageBattleSetup`；4 敌输入在新 seam 保持 4，legacy wrapper 明确截为 3。
- 文档扫描：1314 个 md、8340 引用、dead 65，基线守恒。

## 下一步任务（依赖顺序）

### P0 · 合并与清理

1. 走合并 Gate 把 READY 分支 `--no-ff` 合入 `main`，合并态复跑 analyze、关键 targeted 与文档扫描；删除已合本地分支/worktree。

### P1 · 路线 C 后续工程前置

1. 引入 engine-neutral `CombatantSnapshot`，让 0A seam 摆脱旧 `BattleCharacter` 类型；legacy 3v3 与 0A 各自适配。
2. 设计真实玩家技能到 J/Q/R 的映射；当前内部 move id 有意不记心法熟练度，避免污染账本。
3. 用 headless 胜率画像与真人试玩校准 Ch1；“五关全胜”只证明链路，不等于难度已定。
4. 按内容迁移 ADR 处理远征、断魂庄托管与扫荡 headless 直结，再扩 122 关及塔 49 层。

### 依赖锁死 · 不提前执行

1. Phase 0A 六人主观 Gate：与 BACKLOG 一#19/#4/#5/#6 合并试玩局，需用户排期。
2. Windows 实机 Gate：正式替换前必须人工完成。
3. 旧 3v3/65 路由原子拆除：只在消费面迁移、六人 Gate、Windows Gate 全过后同次 merge，保持零空窗。
4. Phase 0B `MANUAL_RIG_PENDING`：人工美术工作。
