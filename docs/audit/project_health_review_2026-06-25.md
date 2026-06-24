# 挂机武侠 · 全项目健康度阶段性复盘（2026-06-25）

> **基线**：HEAD `d0dd7205`（main）· 阶段：1.0 长线打磨期
> **方法**：5 个只读 subagent code-grounded 扇出审查（测试构建 / 红线合规 / 子系统 game-loop 接通 / 技术债 backlog / 内容量达标），结论均带 file:line 或实测数字，禁凭记忆。
> **触发**：全系统审计 A-E 全闭环 + 战斗节奏真机初校认可后的阶段性复盘。

## 执行摘要

项目整体**健康**。analyze 0、全量 **2904 测 +1 skip** 全绿、五条红线全合规、game-loop 接通无遗漏（唯一 dormant=江湖恩怨为故意延期且标注齐全）、真技术债 **0 处**、Demo §8.4 内容量 **14/14 全达标**且多数远超。唯一结构性隐患是**无 CI**（全绿依赖本地手动验证）。另发现 5 处长寿文档 drift（不影响功能，建议顺手收口），其中 1 处值得拍板确认（11 招未接线）。

---

## 1. 测试与构建健康度 —— 健康

- **analyze**：`No issues found`（0 issue）@ d0dd7205。
- **测试规模**：414 个 `*_test.dart`，全量 **2904 passed + 1 skip**（本会话实测）。密度最高=战斗系统（test/features/battle 合计 85）+ test/data 48。
- **红线测抽查**：`full_build_damage_redline_test.dart` 全绿，第六阶段探针峰值 **136261**（破绽窗口爆发暴击），落在 §5.4 软线「真实峰值 ~13.5 万、不进百万」内。
- **唯一 skip**：`game_event_service_lineage_routing_edge_test.dart:53`——`recordLineageInherited` 待 Phase 5+ 师徒升级实装，登记在册的占位，非破测。
- **⚠ 无 CI**：`.github/` 不存在，全仓无 workflow。无 flutter version pin / 无自动 test / 无远程红绿信号。符合 Mac 单端买断制定位，但全绿无自动化回归兜底——**最大结构性隐患**。

## 2. 红线合规 —— 全合规

| 红线 | 状态 | 证据 |
|---|---|---|
| 硬·装备攻击 ≤2000 | ✅ schema enforce | `game_repository.dart:1053` fail-fast；yaml 实测 max=2000（贴线不越）|
| 硬·招式倍率全局 ≤8000 | ✅ schema enforce | `game_repository.dart:864` 遍历全 skillDefs；yaml max=8000 |
| 硬·血20000/内力15000/Boss60000 | ✅ config 单一真相源 + enforce | `numbers.yaml:123-125` + `game_repository.dart:544/1158` |
| 软·不进百万膨胀 | ✅ 两道测兜底 | `full_build_damage_redline_test:174` + `balance_simulator_test:308` 均硬断言 `<1000000` |
| §5.1 反主流不做清单 | ✅ 无实装 | grep 命中全是否定语境注释（"不做装备分解"等），0 机制 |
| §5.3 三系锁死 | ✅ 硬门控 | `equipment.dart:107` `isEquippableAtRealm` / `skill_def.dart:112` / `technique_learning.dart:61`（含师承遗物不例外）|
| §5.5 在线=离线 | ✅ 无加速 | `fast_forward` 仅 UI 观看快进（不改结果/产出），无挂机加速/快进券 |

启动期 `_enforceRedLines()`（`game_repository.dart:538`）在 `loadAllDefs` 末尾统一调度全部子校验，任一越界 fail-fast。

## 3. 子系统 game-loop 接通状态 —— 接通无遗漏

51 个 Service/Coordinator 逐一查生产 caller。

| 子系统 | 状态 | 关键 caller |
|---|---|---|
| 战斗·开锋吸血/破甲（A1）| ✅ 接通 | `damage_calculator.dart:185/243` 真消费 pierce/lifesteal → `default_ground_strategy.dart:493` 回血写 currentHp |
| 闭关装备掉落（B2）| ✅ 接通 | `seclusion_service.dart:262` rollOneWeighted → `:366` isar.equipments.put |
| 门派事件+声望衰减（B1）| ✅ 接通 | `home_feed_screen.dart:39` 首帧 maybeRunSectMonthlyTick → `sect_providers.dart:104` writeTxn 落库 |
| 江湖恩怨（B3）| ⏸ pending-1.1 | **故意 dormant**：`bakeEnmityMultipliers`/`upsert` 0 生产 caller，`UNUSED-PENDING-1.1` 头注齐全（battle_providers/npc_relation_service/stage_def），1.1 接 npcId schema 即激活 |
| 心魔 / 师徒飞升 / 爬塔周目 / 主线首通门控 / 商店材料经济 | ✅ 接通 | applyFailurePenalty / performAscend / cycle scale / firstClear gating / ShopService.purchase 全有真 UI/loop caller |

**判定**：唯一 dormant=B3，故意延期标注齐全（非误删死码）。A1/B1/B2 本批刚接通项全部 code-grounded 复核通过。

## 4. 技术债 & backlog —— 债务可控

- **UNUSED/PENDING 标记 27 处**：全是带审计批次署名 + 不删理由 + 激活条件的**有意挂账**（B3 恩怨 / D1 心法镜像字段 / D3 npcId / D4 attributeBonus 读端待接 / D5 心魔字段 / Phase5+ 多存档槽等）。**真技术债 0 处**。
- **backlog 4 未完成项**（`playability_phase2_backlog.md`）：① 残页集齐数量初值 ② 转用素材听感复核 ③ **战斗节奏真机校值**（当前 1000/400/700，本会话真机初校认可，值暂定）④ P2③ 出战编成/换人 UI + Boss 协同窗口（待拍板）。均"待真机/待拍板"类，无偷懒遗留。
- **散写中文**：正式 UI **0 处**（E 组清理彻底），仅 debug 屏 13 处（不进 ship UI，可接受）。
- **死字段**：D 组 D1-D8 抽验改对（marker 未误伤同名被消费字段）。
- **生成文件**：54 个 `.g.dart` 齐全，build_runner 产物完整。

## 5. 内容量 & Demo §8.4 达标 —— 14/14 全达标

| 项目 | 目标 | 实测 | |
|---|---|---|---|
| 主线关卡 | 15-20 | **30**（Ch1-6 各 5）| ✅ 超 |
| 章节 | 3 | **6** + 3 扩展弧 | ✅ 超 |
| 主线剧情字数 | 3,000-7,000 | Ch1-3 ≈7,293 / 全 6 章 ≈23,990 | ✅ |
| 爬塔 | 30 层(小Boss5/15/25+大Boss10/20/30)| **30** 精确对位 | ✅ |
| 闭关地图 | 5 | **5** | ✅ |
| 武学领悟触发 | 20-30 | **25** | ✅ |
| 基础奇遇 | 15-25 | **24** | ✅ |
| 节日 encounter | 6-10 | **8** | ✅ |
| 装备 | 30-50 | **80**（7 阶各 11-12）| ✅ 超 |
| 心法 | 20-30 | **49**（7 阶×7）| ✅ 超 |
| 典故 | 50-80 | **80** | ✅ |
| 武学领悟招式 | 30-50 | **40** 池（29 已挂 encounter）| ✅ |
| 心法相生组合 | ≥5 | **12** | ✅ 超 |
| 师徒角色 | 3 | **3** | ✅ |

events ↔ encounters id 1:1 对齐（各 57，`comm -3` 差集空），符合 §8.1 强校验（C2 刚加启动期校验兜底）。

---

## 6. 新发现的文档 drift / 可关注点（不影响功能 · 建议收口）

| # | 项 | 性质 | 处置建议 |
|---|---|---|---|
| 1 | **无 CI** | 结构性隐患 | 1.0 后评估加最小 GitHub Actions（flutter analyze + test），给全绿自动化兜底 |
| 2 | CLAUDE.md §7「仍然不做」仍列 **PVP**，但 PvpService 已实装（`main_menu.dart:303` PvpScreen 可达 + NoopPvpSync 本地 mirror + ELO 持久化，P3.3）| 长寿文档状态 drift | §7 把 PVP 从「不做」移到「已实装」 |
| 3 | ~~40 招池仅 29 挂 encounter，11 招未引用~~ | ✅ **已收口(2026-06-25)** | 定性=漏接非预留(11 招全有完整文案/跨早期 tier/零延期标注)。处置=方案 A 接线:11 招各配 1 个 techniqueInsight 奇遇(encounters.yaml +11 块 + events/ +11 文案),新增 `encounter_skill_pool_wiring_test` 红线锁「池全接线」。详 `docs/spec/2026-06-25-wire-11-encounter-skills-design.md` |
| 4 | ~~encounter_skills.yaml 头注「35 招」实测 40~~ | ✅ **已订正(2026-06-25)** | 头注改「共 40 招(各阶 5/5/6/7/7/5/5)」 |
| 5 | `techniques.yaml:18` 头注引用已退役的 DeepSeek 文案流程 | stale 注释（留底）| 下次动该文件删一行 |

## 7. 风险评估

- **高**：无（红线/数据/接通/测试全绿）。
- **中**：无 CI（#1）——全绿依赖本地手动跑，重构期回归无自动兜底。
- **低**：#3 已收口(11 招接线) / #4 已订正；剩 #2 §7 PVP 文档 drift（需拍板:PVP 实装 vs 不做清单）+ #5 techniques stale 注释（纯卫生）。

## 8. 下一步建议

1. **#3 11 招未接线**先拍板（有意预留 vs 漏接）——唯一需决策项。
2. 文档 drift 卫生收口（#2/#4/#5）可随手批量清（sonnet ~20min）。
3. 战斗节奏值（1000/400/700）已真机初校认可，可继续观察实玩手感后定稿，或现在标 calibrated。
4. CI（#1）作为 1.0 后结构性改进登记 backlog。
5. 内容/打磨方向：项目内容量已远超 Demo，1.0 打磨可转向**实玩体验深度**（战斗手感细调 / 平衡 / 叙事 polish）。
