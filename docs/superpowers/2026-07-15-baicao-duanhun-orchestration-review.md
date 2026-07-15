# 百草岭／断魂庄 × 装备强化 文档编排审查报告

**日期：** 2026-07-15
**性质：** 批1–3 编排收尾审查（矛盾／决策／实施顺序／待拍板）；companion §8.5 交付物。
**产物分支：** `docs/equip-baicao-orchestration`（未 push／未 merge）。

## 1. 发现的矛盾（已解决）

| # | 矛盾 | 解决 |
|---|------|------|
| M1 | 强化「+10 唯一底线」与算法实际可达下限 +17 冲突（`enhancement_service` 只 +20 起掉级） | Q1：真实下限订正为 **+17**，不新增持久化让 +10 可达（批1 并回装备 design §8/plan） |
| M2 | 两个「17」易混：发布上限（境界层 10→17）vs 强化下限（+10→+17），语义无关 | 批2 澄清并分治：`max_absolute_realm_level` 进 Phase A2；强化 +17 进装备 plan |
| M3 | companion 荐新建 `JianghuJourneyProgress` collection vs 现有单一真相源模式 | Q3：**不采纳**新 collection，`SaveData` 加字段（仿 `grantedMilestoneEquipmentIds`） |
| M4 | 断魂庄命名装备「按来源永久保护」会锁死重复件助炼/分解 | Q6：重复未培养可助炼/分解；首破典故/培养/装备/占用/锁定受保护（批1 并回 baicao §6.2） |
| M5 | 仅锁角色不足以拦「会话中装备换下/出售/分解」 | Q5：`CharacterOccupancyService` 返 `reservedEquipmentIds`/`reservedTechniqueIds`，全入口消费（Phase A1 冻结） |
| M6 | Boss 胜利与三选一非同步动作，中途关闭无恢复态 | Q4：`awaitingRewardChoice` 会话阶段 + 原子固化候选/首通快照（A1 枚举锚 + C2.4 结算） |
| M7 | 补给「未用不消耗」被普通背包/战后治疗重复消费 | Q2：会话托管（`BossGauntletRun` 托管三列表，入场移入/关闭返还，C2.1/2.2） |

## 2. 采用的决策（编排层）

- **批次编排**（companion §6）：批1＝并回 Q1–Q7 拍板 + companion 去向；批2＝Phase A1/A2（冻结契约）；批3＝Phase B/C + 联合经济探针 + 本报告。
- **计划切分**：A 拆 **A1（持久化/占用契约）+ A2（上限/断魂帖/配置）** 两文件（§4.1「可独立恢复」）；**B1+B2 合「Phase B 百草岭」/ C1+C2 合「Phase C 断魂庄」**（companion §8.3 允许合并 + 说明理由：各为一边界清晰 feature，内部 B1/B2/C1/C2 仍独立 commit 检查点；贴项目「一 feature 一 plan」先例）。
- **B 与 C 独立**：均只依赖 Phase A（冻结后），互不依赖 → **可并行实施**（§6.6 判定：A 冻结 occupancy/reward DTO 后 B/C 并行）。

## 3. 实施顺序（推荐）

1. **Phase A1**（持久化/占用契约/schema 0.37）→ **Phase A2**（发布上限/溢出探针/断魂帖/配置校验）。A 是唯一强前置。
2. **联合经济探针**（Phase A 完成、B/C 填表前）→ 用户拍板目标天数 → 反推三份 YAML 初值。
3. **Phase B（百草岭）∥ Phase C（断魂庄）** 并行 → 各自填数值表（用探针初值）。
4. **装备批**（助炼/分解/高段强化）可在 A1 冻结 `reservedEquipmentIds` 后独立并行（`isCandidateEligible` 已接口）。
5. **联合验收**（baicao §5 矩阵 10 项 + §12.4 五 visual_route）一次性跨系统跑，而非各测 happy path。

## 4. 仍需用户拍板（DECISION REQUIRED）

| # | 事项 | 何时拍 | 默认 |
|---|------|--------|------|
| D1 | 存量溢出：一次性兑现 vs 分段抬升 10→13→17 | A2 溢出探针出连跳分布后 | 一次性（§3.1，连跳 ≤ ~4 层则维持） |
| D2 | Lv100→170 目标天数（快/中/慢三档） | 联合经济探针出三档后 | 无默认，须选一档反推 YAML |
| D3 | 断魂庄三档阵容目标胜率（入门不无脑过/推荐稳定/满配仍过机制窗口） | Phase C 战斗探针后 | 沿 §12.4 口径 |

> 以上均为**数值/体验拍板**，探针出数据前不预设；非阻塞 Phase A 实装（A 不含玩法数值）。

## 5. 明确不在本轮范围（沿 companion §7 / baicao §13）

断魂庄首破纳战绩册（后续独立小批）·逐战斗动作精确续打 v2·通用 Roguelike 框架·Lv171–490 内容·闭关/群战/桃花岛重构·每日/付费凭证。

## 6. 产物清单（分支 `docs/equip-baicao-orchestration`）

- 批1：装备 design/plan 修订 + baicao design 修订 + companion 去向（§9）。
- 批2：`plans/…phase-a1-persistence.md`（812 行）+ `plans/…phase-a2-cap-config.md`（670 行）。
- 批3：`plans/…phase-b-expedition.md` + `plans/…phase-c-gauntlet.md` + `plans/…joint-economy-probe.md` + 本报告。
- 全部**纯文档零代码**；计划内 file:line 锚点均本编排会话对真实代码 grep 实测。
