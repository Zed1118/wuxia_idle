# 通宵修复与数值/可玩性审查 · 2026-07-08

> 目标:接手 Claude Code 中断后的审查修复;高优先级修复完成后,继续围绕数值平衡/可玩性做测试和审查,供 9:00 检查。

## 结论

- 外部代码审查「第 1 批速修」已落地:战斗结算胜负单一事实源、`interveneNow` 空值边界、招式倍率 8000 硬编码。
- 外部文档审查高误导项已降风险:过时 schema 标历史快照、content guide 清退役协作引用、GDD/CLAUDE/README/AGENTS/IDS 口径同步。
- `flutter analyze` 与 macOS debug build 均通过。
- 新增/复跑的平衡审查发现 4 个需要后续拍板的可玩性风险,其中 2 个建议优先处理:单人主线 `stage_04_05` 硬卡、群战 `stage_mass_battle_05` 红线失败。

## 2026-07-08 三批执行后更新

本节为执行后的最新结论；下方“新发现的数值/可玩性风险”保留原始审查记录,其中 P1 与机制口径问题已按本节结果收口。

### 第一批: P1 推进硬卡修复

- `stage_04_05` 已从突然硬墙调整为生产单人连续整备路径可通:
  - Boss `enemy_jueDing_xiliangbazhu` `baseHp 14000 -> 11200`,`baseAttack 1000 -> 860`。
  - 复跑 `test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart` 通过。
- `stage_mass_battle_05` 已从 14/36 红线失败调回边界可接受:
  - 三个残部模板 HP/attack 下调,最终波人数 `[6,6,7,7] -> [6,6,6,6]`。
  - 复跑 `test/balance/p3_2_mass_battle_redline_test.dart`:前 4 关稳定,`stage_mass_battle_05 = leftWins 25 / rightWins 25 / draws 0`,刚好满足 `leftWins + draws >= rightWins`。
  - 后续建议:该关目前是临界点,若后续新增敌方 buff 或 AI 强化,优先给玩家 wave 间恢复或把末关目标从 25/25 提升到约 30/20。

### 第二批: 机制型 Boss gate 口径统一

- `floor25` 定为 soft gate:
  - `outOfWindowDamageMult 0.10 -> 0.12`,二周目 `0.06 -> 0.07`,首个相位阈值 `0.70 -> 0.80`。
  - 复跑 `vulnerability_window_diagnostic_test.dart`:A/B 耗时比 `1.87x`,满配 `20/20`,mid `12/20`,under `0/20`。
- `floor30` 定为终局 hard gate,不再用 soft gate 命名误导:
  - 复跑 `floor30_soft_gate_diagnostic_test.dart`:onLevel `100%`,underGear `0%`,护法墙 taunt 正常。
  - 已同步测试与输出文案为“终局硬门槛”。

### 第三批: 心魔高层 build 空间修复

- 机制心魔 05/06/07 从“纯爆发固定失败”调为“爆发有攻略窗口,龟缩仍稳定”:
  - `stage_inner_demon_05/06` 镜像 buff 收到 `0.14`,窗口外承伤统一 `0.16`。
  - `stage_inner_demon_07` 镜像 buff `0.40 -> 0.25`,窗口外承伤 `0.08 -> 0.14`。
  - 新增机制镜像专用旋钮:`mechanic_mirror_attack_multiplier: 0.75`,`mechanic_mirror_start_action_point: -2000`。
- 复跑结果:
  - `stage_inner_demon_05/06`:普通满配 A 臂 `20/20`,A/B 耗时 `2.09x`;高爆发 BiS `19/20`,不再稳定秒穿。
  - `stage_inner_demon_07`:on-level 击败通道 `20/20`;turtle survive 通道 `20/20`;高爆发 BiS `10/20`,形成非平凡战败但不是硬墙。
  - 心魔 R5 红线仍稳定:7 关均 `49/50`。

### 本次执行验证

通过:

- `flutter test test/tools/inner_demon_vulnerability_diagnostic_test.dart test/tools/inner_demon_survive_diagnostic_test.dart test/balance/inner_demon_r5_redline_test.dart test/features/inner_demon/application/inner_demon_service_test.dart test/features/inner_demon/inner_demon_vulnerability_def_test.dart test/features/inner_demon/inner_demon_mirror_injection_test.dart --reporter expanded`
- `flutter test test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/balance/p3_2_mass_battle_redline_test.dart test/tools/vulnerability_window_diagnostic_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart test/data/tower_vulnerability_config_test.dart test/data/ngplus_boss_phase_config_test.dart test/data/stage_def_cycle_vulnerability_test.dart test/balance/cycle_evolution_redline_test.dart --reporter expanded`
- `flutter test test/features/inventory/presentation/inventory_screen_test.dart test/features/battle/presentation/projectile_trail_test.dart test/features/battle/presentation/battle_screen_log_test.dart test/features/battle/application/battle_resolution_test.dart test/features/battle/application/battle_resolution_inner_demon_test.dart test/data/p1a_redline_test.dart test/features/debug/application/redline_audit_test.dart --reporter expanded`
- `flutter analyze`
- `flutter build macos --debug`

剩余建议:

1. `stage_mass_battle_05` 仍是刚好压线,下次群战 AI/数值变动后优先复测。
2. `floor30` hard gate 口径应同步到玩家可见提示,避免玩家误判为技巧可破。
3. 心魔 07 当前 BiS 胜率 `10/20`,难度偏硬但可攻略;若后续反馈“过于惩罚爆发流”,优先把 `mechanic_mirror_attack_multiplier` 从 `0.75` 再降到 `0.70`,不要回退窗口机制。

## 已完成修复

1. `BattleResolutionService.resolve`
   - `isVictory` 改为可空参数,默认从 `finalState.result` 派生。
   - 修复生产调用未显式传参时,战败也可能走胜利掉落/惩罚分支的问题。
   - 新增战败默认不掉落测试。

2. `DefaultGroundStrategy.interveneNow`
   - 移除 `_findById(...)!` 裸断言。
   - 若请求后角色已不存在或已死亡,提前返回原状态。

3. `GameRepository._enforceEncounterSkillRedLines`
   - `8000` 改读 `numbers.combat.redLines.skillPowerMultiplierMax`。
   - 顺手把一处旧 `DeepSeek 派单前` 注释改成中性「内容补齐前」。

4. 文档 drift
   - `data_schema.md`:标注为 Demo 历史快照,避免误导为当前 schema 单一真相源。
   - `content_guide.md`:退役 `WINDOWS_DEEPSEEK_GUIDE.md` / `DeepSeek` 主流程引用,改成当前 GDD/CLAUDE 口径。
   - `GDD.md`:更新 W18 内容量、+20~+49 强化段、二周目跳过引导未实装、心魔惩罚已 wire。
   - `CLAUDE.md`:升 v1.32,登记本批修复。
   - `README.md`:当前实测 452 yaml / 553 个 `_test.dart`。
   - `AGENTS.md` / `IDS_REGISTRY.md`:同步红线与历史覆盖范围。

5. Analyze 清理
   - `docs/audit/early_difficulty_gate_probe_2026-07-05.dart` 改名为 `early_difficulty_gate_probe_2026_07_05.dart`。
   - 同步两处文档引用,消除 `file_names` info。

## 验证结果

通过:

- `flutter test test/features/battle/application/battle_resolution_test.dart test/features/battle/application/battle_resolution_inner_demon_test.dart`
- `flutter test test/data/p1a_redline_test.dart test/features/debug/application/redline_audit_test.dart`
- `flutter test test/features/inventory/presentation/inventory_screen_test.dart test/features/battle/presentation/projectile_trail_test.dart test/features/battle/presentation/battle_screen_log_test.dart test/features/battle/application/battle_resolution_test.dart test/features/battle/application/battle_resolution_inner_demon_test.dart test/data/p1a_redline_test.dart test/features/debug/application/redline_audit_test.dart`
- `flutter analyze`
- `flutter build macos --debug`

数值/可玩性审查复跑:

- `test/balance`:1 fail / 其余通过。失败为 `stage_mass_battle_05`。
- `solo_mainline_ch1_ch6_balance_test`:1 fail。失败为生产单人连续整备到 `stage_04_05`。
- `test/tools` 诊断组合:4 fail,均为机制软门槛转硬墙相关;同时产出 `test/tools/output/*.md` 诊断文件。

## 新发现的数值/可玩性风险

### P1 · 单人主线 `stage_04_05` 连续推进硬卡

复现:`test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart`。

- Ch1 到 Ch4-4 全部胜利。
- `stage_04_05` 失败:玩家 `jueDing.qiMeng` 约 7918 HP / 945 atk / 6300 IF / 4 skills,敌方 Boss 14000 HP / 1000 atk。
- 该测试模拟「生产单人连续整备路径」,失败说明章节末跨阶 Boss 对单人路径过陡。

建议:

- 不建议直接削全局公式。
- 优先检查 `stage_04_05` 是否应给更明确的整备门槛或掉落/装备提示。
- 若设计目标是单人不断档推进,小幅下调该 Boss HP/attack 或提高 Ch4 前置掉落/整备收益。
- 若设计目标是章节末必须挂机整备,则修改测试口径和 UI 提示,避免玩家理解成突然硬墙。

### P1 · 群战 `stage_mass_battle_05` 红线失败

复现:`test/balance/p3_2_mass_battle_redline_test.dart`。

- 50 seed 分布:玩家 14 胜 / 0 平 / 敌方 36 胜。
- 已不只是旧审查中的「draw 偏多」,而是玩家主导性断言失败。

建议:

- 优先做一个小型调参批:只动 `stage_mass_battle_05` 或群战 wave 间恢复/后波递减,不要改基础战斗公式。
- 推荐候选顺序:wave 间玩家 HP 部分恢复 > 后波敌人轻微递减 > maxTicks 放宽。
- 调参后必须复跑 `p3_2_mass_battle_redline_test.dart` 与 `battle_strategy_e2e_test.dart`。

### P2 · 机制型 Boss 软门槛过硬

复现:`vulnerability_window_diagnostic_test.dart` / `floor30_soft_gate_diagnostic_test.dart`。

- 脆弱窗口 mid 档 0/20,测试期望「同阶 0 强化仍偶尔通关」。
- floor30 欠配 0/30,护法墙软门槛变成绝杀门槛。
- on-level 满配仍能通,所以不是阻断性 bug,但“软门槛”文案与实际有偏差。

建议:

- 先统一设计口径:机制型 Boss 是允许硬装备门槛,还是应保留低概率技巧通关。
- 若保留软门槛,调低 floor25/30 外窗减伤或护法墙承伤组合,保持 5%-20% mid 档通关。
- 若改硬门槛,同步 GDD/测试命名,避免继续以 soft gate 描述。

### P2 · 心魔 05/06/07 对高爆发 BiS 反制过强

复现:`inner_demon_vulnerability_diagnostic_test.dart` / `inner_demon_survive_diagnostic_test.dart`。

- stage_inner_demon_05/06 高爆发 BiS 0/20。
- stage_inner_demon_07 高爆发 BiS 0/20,龟缩 survive build 20/20。
- 反爆发方向成立,但从“非平凡战败率”变成“固定失败”,可能过度强推单一龟缩解法。

建议:

- 若目标是 build 教学,保留龟缩最优,但给高爆发保留 20%-40% 攻略窗口。
- 调整项优先级:降低镜像脆弱窗口外减伤强度 / 拉长窗口 / 降低镜像开窗前爆发。
- 同步写入心魔面板或失败总结,让玩家知道需要“撑过 N tick”而非误以为纯输出不足。

## 已通过的正向信号

- 伤害极值仍远低于 1M:破绽窗口爆发暴击探针约 136261,满破甲约 134121。
- 经济关卡银两占比雷达仍在合理带:K30 约 1.8/3.0/3.0/4.8/7.7。
- 轻功对决 5 关 R5 分布基本稳定:4 关 50/50,末关 49/50。
- 心魔 R5 镜像压测基础红线仍稳定:7 关均 49/50。
- 早期 solo Ch1-2 中成 2 招无 0% 硬墙。
- 爬塔 on-level 机制 Boss 可通:floor30 onLevel 100%,floor25 ceiling 100%。

## 后续建议队列

1. P1 调参:修 `stage_mass_battle_05` 玩家主导性。
2. P1 决策:明确 `stage_04_05` 是章节末挂机整备门槛还是连续推进应通;据此改数值或改提示/测试。
3. P2 机制门槛:决定 floor25/30 与心魔高层是 soft gate 还是 hard gate,同步测试口径。
4. P2 工具口径:balance_simulator 仍有“全关过易候选”失真,建议加入 solo 连续整备剖面作为常驻读数。
5. P2 工程债:外部代码审查的架构解耦、ListView.builder、Semantics、Isar 哨兵值安全网适合拆成后续独立批次,不建议混在数值调参批里。
