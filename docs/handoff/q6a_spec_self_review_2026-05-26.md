# Q6A encounter recruit spec self-review · 2026-05-26

> 体量 ≤60 行 · Mac+Opus xhigh ~30min · devil's advocate 视角
> 范围:`docs/spec/p4_1_q6a_encounter_recruit_spec_2026-05-25.md`(159 行 · Q1-Q8 默认决议)
> 上游 Phase 0 grep 沉淀 + 跨 spec 联动审查(sect lazy-init / founder_buff / encounter_hook)
> 评级:🔴 spec 必改 / 🟡 用户拍板时建议明确 / 🟢 接受(已 OK 或 OUT 决议)

## TL;DR

11 风险点筛 6 关键(2 🔴 + 3 🟡 + 1 🟢)。**最严重 R3 race condition**(Sect lazy-init 未触发时 `playerSectId=null` Q6A 走 fallback,但 spec §3 当前没拍这个边界)+ **R8 founder_buff 跨派系拦截**(R5.8 测族依赖 P-C founder_buff 跨派系扩 spec 实装,本 spec 提前 ship 会让 R5.8 假阳性)。建议 Q6A spec 加 §3 race fallback + R5.8 延后到 founder_buff 跨派系扩 ship 后再加。

## 风险矩阵

| # | 风险点 | 等级 | 建议 |
|---|---|---|---|
| R1 | `AffectsSectMembership.candidateRef` 单一引用 · 同一 encounter 总同一 NPC(无随机性) | 🟡 | 用户拍板 Q1 时明确「Demo 单一引用 OK · 1.2 升 `candidateRefs: List<String>` rng pick」· 不改 spec |
| R2 | encounter.markTriggered 在 outcome 处理前调用 · 玩家拒绝 / cap 满后无法再遇同 NPC encounter | 🟡 | spec §3 改:**markTriggered 延后到 accept 成功 + sect.put 后**(拒绝 / fallback 路径不 markTriggered · 玩家可重遇)· 沿 W14 体例可改 |
| **R3** | **`playerSectId` race condition**:Sect lazy-init by `currentSectProvider` · 战斗 victory 在玩家从未访问 sect_screen 时 `isar.sects.get(1)` 返 null · Q6A spec §3 当前没拍此边界 | **🔴** | **spec §3 必改**:hook 内 `Sect.get(1)==null` → lazy-init 之(沿 `currentSectProvider:64-68` 体例)· 或 fallback outcome · 不让玩家「触发了招收但无 sect 招不进」 |
| R4 | confirm dialog async flow 3 await 点(applyOutcome / confirm / recruit)mounted check | 🟡 | spec §4 明示「每 await 后 `if (!context.mounted) return` 校验」· 沿 W14 体例 |
| R5 | fixture-friendly 红线:starting refs 不全静默清空 sectCandidates · 生产漏配也静默 → 隐藏 bug | 🟢 | 沿 P1.1 体例,production 漏配概率低(yaml schema 加载层已严)· 接受 |
| R6 | Q7=A 3 条 fortuneEvent encounter · 1.1 PoC 验链路够 · Demo 体验单调(同 NPC 同 encounter) | 🟡 | 用户拍板 Q7 时明确「3 条 PoC · 1.2 扩 6-8 条覆盖 biome」· 不改 spec |
| R7 | events 文案 3 条 Mac+Opus 单端写 ~10min/条 精度未验 | 🟢 | 风险段补「文案质量风险」· 接受 · 实装时实测 |
| **R8** | **R5.8 NPC isFounder=false 测族**:验招收的 NPC 不误激活 founder_buff · 但 founder_buff 当前不感知 isInSect(P-C `p4_1_founder_buff_cross_sect_spec_2026-05-26.md` 起草中)· R5.8 在 P-C 未 ship 前测族**假阳性**(实际逻辑不存在但测 pass) | **🔴** | **spec §7 R5.8 改**:标 「**delta 测族 · 依赖 P-C founder_buff 跨派系扩 ship**」· 或本 spec 实装时移除 R5.8 · 待 P-C ship 后另加 |
| R9 | schema 扩展性 — Q6 B stage_boss 招降复用 `AffectsSectMembership`? | 🟢 | spec §1 OUT 明示 Q6 B 1.1+ · 接受 minimal 设计 · Q6 B 真起 spec 时按需扩 |
| R10 | `playerSectId == null` 边界:玩家主动 dismiss 自己 / sect 不存在 | 🟢 | spec §4 UiStrings 已加 `sectRecruitNoSect`「尚未建派,无缘相邀」· 接受 |
| R11 | events.yaml `choices[].outcome_id` 漏 accept_recruit → encounter 卡死 | 🟢 | spec §6 「加载层强校验」已含 · sect_recruit_<biome>.yaml 加载抛 OK · 接受 |

## 推荐 spec 必改(用户起床拍板时一并改)

1. **§3 wire 路径** 加 `Sect.get(1)==null` lazy-init fallback(R3 修):
   ```dart
   final sect = await isar.sects.get(1);
   if (sect == null) {
     // lazy-init by currentSectProvider 沿用体例
     await isar.writeTxn(() => isar.sects.put(_defaultSect(now)));
   }
   ```
2. **§3 wire 路径** markTriggered 延后到 accept 成功 + sect.put 后(R2 修)· 拒绝 / cap 满不 markTriggered
3. **§7 R5.8** 改标「delta · 依赖 P-C ship」或 spec 实装时移除(R8 修)· 等 P-C founder_buff 跨派系扩 ship 后另加

## Q1-Q8 默认决议是否需要补 Q9 / Q10?

- **Q9 候选 pool 随机性**(R1):Demo 单一 OK / 1.2 List 升 · 建议加 Q9 明示「Q9 = Demo 单一 candidateRef · 不开新参数」让用户拍板 explicit OK
- **Q10 markTriggered 时机**(R2):建议加 Q10 「Q10 = 玩家拒绝 / cap 满不 markTriggered · 可重遇」明示

## 接受决议(不改 spec 的)

R5/R6/R7/R9/R10/R11 6 项:`fixture-friendly` / `Demo PoC 3 条` / `events 文案精度` / `Q6 B 1.1+` / `playerSectId null UiStrings 已加` / `events.yaml 加载层校验`。这些是 spec 当前 design choice 合理接受 · 风险等级 🟢 · 不阻塞 Q1-Q8 拍板。

---

**self-review 收口**:11 风险点 · 2 🔴 必改(R3 race condition + R8 R5.8 假阳性)· 3 🟡 用户拍板时一并 explicit OK(R1/R2/R6)· 6 🟢 接受。Q6A spec 修 3 处 + 加 Q9/Q10 后可启 B1 实装 · 当前 spec 不阻塞 1.1 起步路径。
