# founder_buff 跨派系扩 spec self-review · 2026-05-26

> 体量 ≤50 行 · Mac+Opus xhigh ~30min · devil's advocate 视角
> 范围:`docs/spec/p4_1_founder_buff_cross_sect_spec_2026-05-26.md`(123 行 · Q1-Q5 默认决议)
> 上游 Phase 0 grep:founder_buff_service.dart 46 行 + derived_stats.dart 三处 founderBuffActive caller + stage_battle_setup.dart:97
> 评级:🔴 spec 必改 / 🟡 用户拍板时建议明确 / 🟢 接受

## TL;DR

8 风险点筛 4 关键(1 🔴 + 2 🟡 + 1 🟢)。**最严重 R1 P1.1 R5 红线回归**(B2 wire 改 per-character 后,跨 12+ test 文件 founderBuffActive 路径回归测族风险)+ **R3 playerSectIdProvider Sect race**(同 Q6A R3 race,本 spec 已 fallback isInSect=false 路径但需显式拍板)。建议 spec §7 R5.1 加「显式跨 callsite 回归扫描清单」+ §3 wire 加「Sect lazy-init 守同 Q6A R3 修体例」。

## 风险矩阵

| # | 风险点 | 等级 | 建议 |
|---|---|---|---|
| **R1** | **B2 wire 改 per-character map 后 · 跨 12+ test 文件回归**:`founderBuffActive` 当前是整队同一 bool · 改 per-character map 后所有 stage_battle_setup test 路径 + derived_stats 测族 + character_panel 显示 + lineage_panel 显示 都需 sweep · spec §5 风险段 ① 提性能但未列回归扫描清单 | **🔴** | spec §7 R5.1 改:列「显式回归 callsite 清单」(grep `founderBuffActive` 全仓 · 当前 15 锚)+ B2 spec 加「sweep checklist」step |
| **R2** | playerSectIdProvider Sect lazy-init race(同 Q6A R3) | 🟡 | spec §3 加「Sect lazy-init 守 · 沿 Q6A spec §3 R3 修体例」明示 · 不让 playerSectId null 走 fallback 单 founder 单代路径 |
| R3 | per-character async loop 性能(3 char × ~5ms isar query · 战斗前一次性算) | 🟢 | spec §5 风险 ① 已含 · 接受(战斗前 ~15ms 不影响 UI)|
| **R4** | founder.isInSect 默认值未明示:P5.0 seed 不设 isInSect=true → founder 默认 isInSect=false → fallback 单 founder 路径享 buff(P1.1 体例)· 但 P4.1 实装时 founder 是否自动加入 sect(sect.id=1 lazy-init 时同时更新 founder.{isInSect=true, sectId=1, sectRank=elder}?) | 🟡 | spec §3 加 「Q6:founder 是否在 sect lazy-init 时自动加入 sect(`sect_providers.dart:64-68` 路径扩 founder character update)」让用户拍板 |
| R5 | derived_stats 签名不变 · caller 端 per-character 传入 · 但 `battle_state.dart:168` 也有 `founderBuffActive: bool` 参数 · 实际 character build BattleCharacter 时是 per-character · 已对齐 spec §3 | 🟢 | 接受 · spec §3 已含 battle_state wire 路径 |
| R6 | R5.7 derived_stats per-character 不串扰测族:battle 中 player(isInSect=false 享)+ NPC(isInSect=true,sectId≠player 不享)同队 → derived_stats.maxHp 算分别正确 · 但 Q6A spec 自动 isInSect=true 招进 NPC 在 player sect → sectId==1 → 享 buff;真跨派系 NPC 招收路径 1.2 才有 · R5.7 当前测 force inject NPC sectId=2 模拟 | 🟢 | 测族注释加 「force inject sectId=2 mock 跨 sect」明示 · 不改 spec |
| R7 | P5+ 多代飞升兼容(R5.6):promoted disciple isFounder=true && isActive=true → 自身享 + 接管 isInSect=false 弟子享 · 当前 spec §3 isBuffActiveFor 逻辑覆盖,但「promoted disciple isInSect=true 接管 sect」边界未拍 | 🟡 | spec §3 加 「P5+ 真传位时 promoted disciple isInSect/sectId/sectRank 是否同步更新」明示 · 或留 1.2 跨派系 wire 时拍 |
| R8 | computeBuffActive 旧 API 保留 · 但若实装时所有 caller 都迁 isBuffActiveFor · 旧 API 几乎死代码 · YAGNI 风险 | 🟢 | 接受 · 旧 API 保留沿向后兼容 · 1.2 statement 可考虑 deprecate |

## 推荐 spec 改 ✅ 已应用(2026-05-26 self-review 直接修)

1. ✅ **🔴 R1** §7 R5.1 加 「显式 callsite 回归扫描清单」(grep `founderBuffActive` 全仓 **28 锚 · lib 15 + test 13** · 沿 P0.2 strategy 重构 sweep 体例)· B2 实装前必跑 callsite sweep
2. ✅ **🟡 R2** §3 wire 加 「Sect lazy-init 守」(playerSectIdProvider null → fallback target.isInSect=false → true · 沿 Q6A spec §3 R3 修体例)· 不让 race condition 破 buff
3. ✅ **🟡 R4** §0 加 Q6「**A 不动** founder 保持 isInSect=false · 1.2 跨派系 wire + NPC 招收路径配合时再拍 · 当前最小动作」
4. ✅ **🟡 R7** §3 加 「P5+ 真传位 promoted disciple isInSect/sectId 同步 — 1.2 跨派系 wire 时拍 · 本 spec 不动 founder 端 schema · 沿 P5+ v1.15 已实装路径」

## 接受决议

R3(性能 OK) / R5(battle_state 已对齐) / R6(R5.7 mock 注释加) / R8(旧 API 保留沿向后兼容) 4 项 🟢 · 不阻塞 Q1-Q5 拍板。

---

**self-review 收口**:8 风险点 · 1 🔴 必改(R1 回归扫描清单)· 3 🟡 用户拍板时一并明示(R2 Sect race / R4 founder isInSect / R7 P5+ 真传位)· 4 🟢 接受。**🔴 + 关键 🟡 4 处直接应用 spec(2026-05-26)** · 用户起床看到的是 self-review 后稳版本 · Q1-Q6 默认决议 OK 即可启 B1 实装 ~3-5h xhigh · 当前 spec 不阻塞 1.1 founder_buff 跨派系扩路径。
