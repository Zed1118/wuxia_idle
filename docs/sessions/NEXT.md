# 新会话开局清单

> 更新时间：2026-08-20 · engine-neutral CombatantSnapshot seam 收账
> 在途分支：`codex/combatant-snapshot-neutral-0820`（READY，待合并）

## 当前结论

- 战斗终态不变：Phase 0A 单角色 ARPG 按路线 C 替换旧 3v3，不做长期双轨。
- Phase 1 Mac 工程纵切成立：Ch1 五关可经 0A live/headless 同核运行，并接通真实结算、奖励、成长、伤势和进度。
- 开战装配公共类型已改为 engine-neutral `CombatantSnapshot`；Phase 0A application/presentation/主线宿主不再依赖 `BattleCharacter` 或 `battle_state.dart`。
- 旧 3v3 容量、team/slot 和运行态全部收口 `Legacy3v3CombatantAdapter`；旧主线/塔/远征/断魂庄行为保持。
- 正式替换仍锁六人主观 Gate、Windows 实机 Gate 与其余消费面迁移；dead link 基线仍为 65。

## 本批完成

1. 新增不可变 `CombatantSnapshot` Module：保留身份、境界、HP/Qi/内力、派生攻防、技能/熟练度与稳定机制配置；集合含 Boss phase 嵌套均防御性深不可变。
2. neutral Interface 明确禁止 `teamSide/slotIndex/actionPoint/isAlive/charging/stagger/bossPhaseIndex/coop` 等旧运行态。
3. 新增 `Legacy3v3CombatantAdapter`：独占 player/enemy team 容量、team/slot 注入与初始运行态；动态旧状态转 neutral fail-fast。
4. 玩家/敌方 assembler 改产 neutral；Phase 0A factory/mapper/visual/settlement/主线宿主直接消费 neutral。
5. source-contract 反转：Phase 0A 禁 `BattleCharacter`、`battle_state.dart` 和 legacy Adapter 回流。

## 验证快照

- `flutter analyze`：0 issue。
- neutral/legacy/Phase 0A/远征/断魂庄 targeted：410/410。
- cycle、synergy、主线、塔、扫荡扩展回归：153/153。
- 最终全量：`flutter test --no-pub --reporter=compact` = **5219 pass / 0 fail**。
- 文档扫描：1315 个 md、8340 引用、dead 65，基线守恒。

## 下一步任务（依赖顺序）

### P0 · 合并与清理

1. `--no-ff` 合入 `main`；合并态复跑 analyze、关键 targeted 与文档扫描；删除已合 worktree/分支。

### P1 · 路线 C 后续工程前置

1. 设计并落地真实玩家技能到 J/Q/R 的映射；内部 move id 继续不得污染心法熟练度。
2. 用 headless 胜率画像与真人试玩校准 Ch1；“五关全胜”只证明链路，不等于难度已定。
3. 按内容迁移 ADR 将远征、断魂庄改为单主角 0A headless 续传，扫荡改 headless 直结。
4. 消费面稳定后机械映射其余 117 关与塔 49 层，再做 γ 后置校准。

### 依赖锁死 · 不提前执行

1. Phase 0A 六人主观 Gate：与 BACKLOG 一#19/#4/#5/#6 合并试玩局，需用户排期。
2. Windows 实机 Gate：正式替换前必须人工完成。
3. 旧 3v3/65 路由原子拆除：消费面迁移、六人 Gate、Windows Gate 全过后同次 merge，保持零空窗。
4. Phase 0B `MANUAL_RIG_PENDING`：人工美术工作。
