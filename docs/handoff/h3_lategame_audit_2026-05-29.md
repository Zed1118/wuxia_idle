# H3 后期挑战(Ch4-6 + 心魔/群战/轻功/飞升)流畅度 + 难度曲线 audit

> 起草:2026-05-29 · H 段 Batch H3 · 4 并行子 agent Phase 0 grep + 主控对 A2 🔴 断言独立 grep 复核
> **本 doc 0 代码改** · 范围:后期玩家路径**流畅度 + 难度曲线 + 系统衔接**(非"是否实装" — 各后期系统此前已各自闭环验过)
> 沿 H2 audit 体例(`h2_midgame_audit_2026-05-29.md`)· load-bearing 断言 grep 实测核验

## 0. 一句话结论

后期路径整体**远比中期健康**:难度曲线 / 红线合规 / 叙事接线大面积 🟢(Ch4-6 35 个关内 narrative + 3 章 prologue/epilogue 全真接线 0 dangling,跨章衔接平滑,心魔自缩放镜像公平,群战/轻功有产出驱动重玩)。**唯一 🔴 = A2 多代飞升 endgame 循环断裂**(规则文档 v1.10/v1.15 宣称"已闭环",实际 `performAscend` 漏写 1 行,被测试手动 setup 掩盖)。其余为 🟡 节奏 / 接线 polish。**与 H2 不同:H2 是"中期循环品类级硬伤",H3 是"后期已成熟,1 个正确性 bug + 几处节奏 polish"。**

## 1. Ch4-6 主线(难度曲线 + 叙事流畅度)

| # | 维度 | 现状(grep 实测) | 严重度 | 文件:行 |
|---|---|---|---|---|
| M1 | 难度曲线·章内+跨章 | Ch4 hp 7200→11500(章末 Boss 跨阶 jueDing 15625-19375);Ch5 13500→24000(Boss zongShi 33800-41600);Ch6 28000→40000(终 Boss wuSheng 52000)。章末 Boss 全 qiMeng-of-next-tier 跨阶,Boss 后回落普通关=合理节奏重置,无断崖/无平坦 | 🟢 | stages.yaml:996-2050 |
| M2 | 数值红线 | 最高 Boss 血 52000(stage_06_05,Boss「50000+ 不进百万」✅);敌人 baseAttack 最高 2700(敌人攻击轴,非「装备攻击≤2000」轴)。无红线突破 | 🟢 | stages.yaml:1969 |
| M3 | 章节 prologue/epilogue 接线 | `chapter_04/05/06.yaml` 真加载:`ChapterTransitionScreen → NarrativeLoader.loadChapter`,入口 chapter_list_screen `_chapters=[1..6]` 全覆盖。**Ch4-6 与 Ch1-3 同已接,非 dead content**(H2 已同步修) | 🟢 | chapter_transition_screen.dart:36 / chapter_list_screen.dart:97 |
| M4 | 关内 opening/victory/defeat | `stage_entry_flow.dart:75/115/174` 三段真 wire;Ch4-6 全 35 个 narrativeId **0 dangling**;章末 Boss 全配 defeat + boss_recruit + boss_fail_recover | 🟢 | stage_entry_flow.dart:74-174 |
| M5 | 叙事道具跨章贯穿 | 小铜镜 Ch1→Ch2→Ch4 epilogue→Ch5/6;剑鞘 06_05 victory 收束;师父三句遗言弧 Ch4 起、Ch6 终 victory 闭环。全闭环 ✅ | 🟢 | chapter_04.yaml / stage_06_05_victory.yaml |
| M6 | Ch6 通关→飞升路标 | 06_05 victory 文案点出「化境的门开了」呼应飞升,但飞升机制仅经师徒传承面板可达,**通关 Ch6 无显性"去飞升"路标**。属 GDD「飞升留 P5+」边界,非 dead end;1.0 可在 06_05 victory 末加弱提示 | 🟡 | stage_entry_flow.dart(无 hook)/ lineage_panel_screen.dart |

## 2. 心魔系统(inner_demon)

| # | 维度 | 现状(grep 实测) | 严重度 | 文件:行 |
|---|---|---|---|---|
| D1 | 解锁/触发节奏 | 7 关全门槛 `requiredRealm: wuSheng`,unlock 起点 stage_06_05 victory;武圣升各 layer 前真被拦截 → 自然触发不会错过。纯后期定位正确 | 🟢 | numbers.yaml:1318-1335 |
| D2 | 难度 / 红线 | 镜像玩家 build ×(1+buff 0.10→0.40),clamp HP≤20000/IF≤15000/atk≤6000(3件×2000)。自缩放=恒定公平,红线合规 | 🟢 | numbers.yaml:1293-1316 / inner_demon_service.dart:102 |
| D3 | 奖励 / payoff | payoff = 解锁下一关 + 武圣 layer 突破解禁(exp 留账后补升);无物品 drop(设计如此);失败 = 散功阉割版 + 8h 余毒 debuff。有意义不鸡肋 | 🟢 | numbers.yaml:1302-1316 / character_advancement_service.dart:72 |
| D4 | UI 接线 | 双入口实测均接线:main_menu:155 push + character_panel:348 reactive `_BreakthroughBlockerSection`(真 watch mainlineProgress)。**stale 注释**:breakthrough_blocker.dart:12-16 仍称"暂未集成 character_panel",实际已集成 | 🟡 | breakthrough_blocker.dart:12-16 |
| D5 | 主菜单入口未境界门控 | main_menu「心魔」按钮始终可见可点,pre-武圣玩家进去只见 7 行全 locked、无"境界未达"空态文案。**违反 GDD §5.7**(未解锁系统按钮应灰掉/隐藏) | 🟡 | main_menu.dart:152 / inner_demon_screen.dart:52 |

## 3. 群战(mass_battle)+ 轻功对决(light_foot)

| # | 维度 | 现状(grep 实测) | 严重度 | 文件:行 |
|---|---|---|---|---|
| GL1 | 解锁节奏(共性 gap) | 群战 + 轻功**同起点** stage_06_05 victory → 两支线 yiLiu 首关。主线一通关瞬间同时涌现两个新玩法,**节奏过晚且过集中**,中后期长时间无新挑战可碰 | 🟡 | numbers.yaml:1385/1438 |
| GL2 | 难度 / 红线 | 轻功:3 terrain modifier 双方对等(evasion/crit/dmg),敌 hp6700-17000/atk720-969。群战:wave 2→4 递增「3 vs 5-7 以少胜多」,死者满血复活平衡,最高 hp12920/atk1180。全红线合规 | 🟢 | numbers.yaml:1360/1416 / stages.yaml:2412/2718 |
| GL3 | 重玩价值 | 二者 cleared 可重入 + 每通必掉心血结晶(强化保底货币,_05 Boss 12-15)。**有产出驱动重玩,非一次性** | 🟢 | battle_resolution.dart:162 / light_foot_screen.dart:79 |
| GL4 | UI 接线 | LightFootScreen(main_menu:161)+ MassBattleScreen(main_menu:167)真 push,三态完整。**非 dead content** | 🟢 | main_menu.dart:161/167 |
| GL5 | 首次引导 + 入口门控 | 二者有专属 chapter 叙事但**无首次引导/气泡**,入口常驻主菜单无境界门控(同 D5 §5.7 问题),玩家可能注意不到入口已点亮 | 🟡 | chapter_light_foot.yaml / chapter_mass_battle.yaml |

## 4. 飞升(ascension)+ 后期成长闭环(inheritance/lineage)

| # | 维度 | 现状(grep 实测) | 严重度 | 文件:行 |
|---|---|---|---|---|
| **A2** | **endgame 多代循环** | **🔴 真 bug**:`performAscend` 漏写 `save.founderCharacterId = promotedDiscipleId`(详 §5 复核铁证)。首次飞升后第二代 `computeEligibility` 永返 blocked → 名义"多代循环"实为一次性终局。与规则文档 v1.10/v1.15「已闭环」脱节 | 🔴 | ascend_service.dart:262-294 / :50-56 |
| A1 | 飞升入口/门槛 | 入口链完整(main_menu「师徒名单」→ LineagePanel → AscensionScreen)。门槛 wuSheng·dengFeng(49级)+ cleared 06_05 + inner_demon_07,主线 Boss 天花板仅 jueDing → **Demo 范围基本到不了,飞升是远期 endgame**(设计取舍) | 🟡 | numbers.yaml:1467 / lineage_panel_screen.dart:177 |
| A3 | payoff·师承遗物+5% | 健康:`internalForceMaxWithLineage` 按 isLineageHeritage instance count×0.05 真进内力公式,battle+panel 双消费;stack_across_generations=false 防回退 | 🟢 | derived_stats.dart:243 / numbers.yaml:1095 |
| A4 | payoff·祖师 buff | 健康:maxHp/critRate/internalForce 三公式全消费 + per-character 注入。**死字段**:`cultivation_progress_pct:0.03` 0 公式消费(仅解析),lineage_panel 已移除误导行 — 已知已注释,非新增 | 🟡 | derived_stats.dart:118/175/246 / numbers.yaml:1114 |
| A5 | UI / 师徒中→后期衔接 | 全接通无 dead content:多徒弟 player_pick DropdownButton(:527)+ 真传位 _PromotedDiscipleRow(:577)+ 多代 chip + auto_swap 换装。inactive 池弟子→飞升 transfer/传位目标,衔接闭环成立 | 🟢 | ascension_screen.dart:527/577 |

## 5. A2 复核铁证(唯一 🔴,主控独立 grep)

- **读侧** `computeEligibility:50-56`:读 `save.founderCharacterId` → 拿 founder → `inActive = activeCharacterIds.contains(founderId)`,且 `realmAtPeak` 锚在该 founder 境界。
- **写侧** `performAscend:262-294`:founder `isActive=false` + 移出 `activeCharacterIds`、promoted `isFounder=true`、sect.founderId rewire 到新人 —— **全程无 `save.founderCharacterId = promotedDiscipleId`**。
- **后果**:飞升后 founderCharacterId 仍指旧退休 founder(已不在 active)→ 第二代 `inActive=false` + 境界检查锚旧人 → **永久 blocked**。
- **铁证**:R5.6/R5.8/R5.10 多代测试在首次飞升后**手动 setup `save.founderCharacterId = 2`**(`ascend_service_test.dart:387/576/635`,注释自述「gen2 setup」)→ 测试覆盖"机制能跑"却用手动 setup 绕过了 production 缺失的那行,bug 被掩盖(同 memory `feedback_layered_bugs`)。
- **修复**:`performAscend` 在 `promotedDiscipleId != null` 分支内加 `save.founderCharacterId = promotedDiscipleId; await isar.saveDatas.put(save);` + **删测试手动 setup 行让真实闸门路径暴露** + 加 R5 防回退测(连续两代经 computeEligibility 真闸门)。约 1 行 production + 测试调整。

## 6. 候选套餐(用户拍其一 · H3-Q1)

| 套餐 | 内容 | 估时 | ROI | 数值/schema |
|---|---|---|---|---|
| **微套餐 · A2 正确性修复**(强推荐) | performAscend 补 founderCharacterId wire + 删测试手动 setup 暴露真实路径 + R5 防回退测 | ~1h | ⭐⭐⭐⭐⭐ | 0 数值/schema · 1 行 production |
| **小套餐 · A2 + 后期接线 polish** | 微套餐 + D5/GL5 后期入口境界门控(§5.7)+ D4 stale 注释清 + M6 Ch6→飞升弱路标 + 死字段标注 | ~3-4h | ⭐⭐⭐⭐ | 0 数值改 |
| **中套餐 · + 后期节奏重排** | 小套餐 + GL1 轻功/群战解锁锚点错开(轻功挂 Ch5 末 / 群战挂 Ch6 末)+ 两支线首次入口高亮气泡 | ~6h | ⭐⭐⭐ | numbers.yaml unlock 锚点 + 叙事配合 + 测试 |

## 7. 决策点

| # | 问题 | 推荐 |
|---|---|---|
| **H3-Q1** | A2 1.0 必修 vs 标 P5+ 已知偏差? | **必修**(修复 1 行,成本极低;留着是规则文档"已闭环"宣称与行为脱节)。但 Demo 玩家到不了飞升 → 非体验 ship blocker,可排在根因A 之后 |
| **H3-Q2** | 轻功+群战解锁起点撞同一关,错开? | **错开**(轻功 Ch5 末 / 群战 Ch6 末),中后期玩法供给更平滑;需 unlock 锚点 + 叙事 + 测试调整 → 中套餐 |
| **H3-Q3** | 心魔/轻功/群战主菜单入口未境界门控(违 §5.7),统一加? | **加**(pre-武圣见全 locked 列表违反"未解锁灰掉")· 小套餐一并处理 |

---

**核心提示**:H3 与 H2 的诊断性质相反 —— 后期"骨架 + 接线 + 难度 + 红线"普遍成熟(大量 🟢),不存在 H2 那种品类级循环硬伤。**唯一真 bug 是 A2 多代飞升断裂**(规则文档宣称已闭环、被测试 setup 掩盖,1 行修复)。其余全是 🟡 节奏/接线 polish(后期入口境界门控 §5.7、轻功/群战解锁撞同关、Ch6→飞升路标)。建议:A2 微套餐随手修(无论后续走哪条路,正确性 bug 不该留),节奏/接线 polish 并入 H 段后续 polish 批;不构成独立大批。
