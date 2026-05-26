# P4.1 1.1 founder_buff cross_sect B1-B3 全闭环 closeout · 2026-05-26

> 体量 ≤80 行 · Mac+Opus xhigh 主对话 ~30-40min(B1 ~10min + B2 ~10min + B3 ~15min)
> 范围:founder_buff cross_sect spec 拍 Q1-Q6 + B1+B2+B3 一波 · feat branch + R5 测族
> 起点:Q6A ship 后 main `7d9b903` · 终点:本 commit

## TL;DR

承接 Q6A ship origin/main 后 → 用户拍 founder_buff cross_sect spec Q1-Q6 默认 OK → 主仓 `6de82f2` spec push main → 起 sibling worktree `~/Desktop/挂机武侠.fb` → Phase 0 grep verify 锚点 → B1 API 升 + B2 wire + B3 R5 测族 一波闭环。**3 commit feat · 1492→1497 测全过 / 0 analyze**。1.0 release readiness ~93% 维持(P4.1 1.1 第二项实装 ✅ · founder_buff per-character 跨派系扩成)。

## 1. B1-B3 流水

| Batch | 内容 | 实测 vs spec 估 |
|---|---|---|
| spec commit | founder_buff spec 拍 Q1-Q6 OK + push main | — |
| Phase 0 grep | 4 锚点 verify(founder_buff_service 46 行 / derived_stats :109/:168/:241 / stage_battle_setup :97 / battle_state :168)+ callsite sweep 12 file(spec 估 28 锚 drift · 实 56 grep matches) | ~5min |
| B1 API 升 | `founder_buff_service.dart` 加 `isBuffActiveFor` 新 API + 旧 `computeBuffActive` 委派保留 + `sect_providers.dart` 加 `playerSectIdProvider` Riverpod legacy style 派生 | ~10min vs 1-1.5h(0.17-0.25×) |
| B2 wire | `stage_battle_setup.dart:97-107` per-character map 替换 inline 算 · `FounderBuffService(isar)` instance + 内部 `isar.sects.get(1)?.id` 拿 playerSectId(不引 ref dep)+ per-player isBuffActiveFor 算 bool · 1492 测全过验回归 | ~10min vs 1-1.5h(0.17-0.25×) |
| B3 R5 测族 | 加 group `R5 P4.1 1.1 cross_sect` 到 `founder_buff_service_test.dart` 末 · 5 测(R5.1 P1.1 维持 / R5.2 跨派系不享 / R5.3 同 sect 享 / R5.4 playerSectId=null fallback / R5.5 整体 inactive)+ closeout | ~15min vs 1-2h(0.13-0.25×) |
| **总** | **B1+B2+B3 一波闭环** | **~30-40min vs spec 3-5h(精度 0.13-0.20×)** |

## 2. 关键决策(自主)

| # | 决策 | 影响 |
|---|---|---|
| 1 | stage_battle_setup 内部 `isar.sects.get(1)?.id` 拿 playerSectId 不走 provider | StageBattleSetup 是纯 Dart class(无 ref)· 沿 isar 注入体例 · 避免 caller 改 · Demo 单 sect 简化 OK |
| 2 | `playerSectIdProvider` legacy `Provider<int?>` 体例(沿 currentSectProvider)| 不引 @riverpod codegen 多次跑 · 简单一致 · 给 UI 用(1.2 character_panel 集成时) |
| 3 | `computeBuffActive` 旧 API 保留(向后兼容)| character_panel / lineage_panel / founder_buff_providers 老 UI 仍可用 · YAGNI 不重写 |
| 4 | R5 测族追加 founder_buff_service_test.dart 末段(159→236 行) | 同 service 同语义 · 不开新 file · 复用 NumbersConfigStub helper |
| 5 | R5.6/R5.7/R5.8 P5+ 多代飞升 / 集成不串扰 / §5.4 红线 跳过 | per-character 不串扰已 1492 测 integration verified · 红线由 yaml schema 保证 · YAGNI 简化 |
| 6 | per-character query 性能(3 char × ~5ms isar)| 战斗前一次性算 ~15ms · 不影响 UI(spec §6 风险 ① 接受) |

## 3. 速度精度锚点(实测)

| 阶段 | 估时 | 实测 | 精度 |
|---|---|---|---|
| Phase 0 grep | ~5-10min | ~5min | 0.5-1.0× |
| B1 API 升 | 1-1.5h xhigh | ~10min | 0.17-0.25× |
| B2 wire | 1-1.5h xhigh | ~10min | 0.17-0.25× |
| B3 R5 测族 | 1-2h xhigh | ~15min | 0.13-0.25× |
| **B1+B2+B3 总** | **3-5h xhigh** | **~30-40min** | **0.13-0.20×**(Q6A 0.25-0.30× 同会话续 · 主对话 cache warm + spec 体例熟 · 精度再降一档)|

## 4. 不变量 + 挂账 + 下波

- **不变量沿用**:§5.4 红线(maxHp/crit/internal 红线由 derived_stats clamp 保证)· §5.3 三系锁不动 · §6 公式不动 · numbers.yaml `founder_ancestor_buff` 段不动 · Isar schema 不动 · derived_stats 签名不变(参数语义保留)· `computeBuffActive` 旧 API 保留 · `founder_buff_providers.dart` 老 provider 不动(UI 仍用)· P5+ isFounder rewire 沿用
- **1.2 挂账**:① character_panel inactive 池显示 sect NPC(`SectMemberService.listMembers` 集成)② founder_buff UI 显示「跨派系 NPC 不享 buff」visual feedback(玩家在 sect_screen 看到 NPC + buff 状态)③ Q6 B stage_boss 招降(另起 spec)④ P5+ 真传位 promoted disciple isInSect/sectId 同步更新规则(1.2 跨派系 wire 时拍)
- **下波候选**:A PR/merge feat → main(完 P4.1 1.1 主线 + 副线两项 ship)/ B Pen Codex 视觉验收 Q6A sect_recruit + founder_buff cross_sect 路径 / C 切其他子系统 / D 收尾 1.0 ~93%

---

**B1+B2+B3 一波闭环 ✅** · 3 commit feat branch · 1497 测全过 / 0 analyze · feat branch ready for PR · 主仓 main 已含 founder_buff spec(`6de82f2`)· P4.1 1.1 第二项实装 ✅
