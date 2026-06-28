# 挂机武侠 · 阶段性全量审查报告（2026-06-28）

> 分支：`codex/audit-review-fixes-2026-06-28`  
> 阶段：1.0 长线打磨期  
> 方法：读取 `CLAUDE.md` / `GDD.md` / `PROGRESS.md` / 近期审计报告，结合 CodeGraph、全文扫描、工具审计、本地 targeted 验证与全量测试。  
> 结论口径：本报告继承 2026-06-24 全系统审计与 2026-06-25 健康复盘的已收口项，只记录本轮仍成立的阶段风险与本轮修复结果。

## 1. 本轮已处理

### 测试锚点漂移

- `test/balance/cycle_evolution_redline_test.dart` 不再硬编码爬塔 30 层旧 `baseHp=15000` / `baseAttack=2250`，改为从生产 `towers.yaml` 读当前数值后验证 scale。
- `test/features/battle/application/master_disciple_battle_test.dart` 与 `test/features/battle/application/stage_battle_setup_test.dart` 不再假设 `stage_01_01` 右队固定 3 人，改为跟随当前 YAML 的 `enemyTeam.length`。

### 颜色 token 收敛

- 已将本轮审计命中的 medium 级硬编码色迁入 `WuxiaColors` 用途 token。
- `test/tools/output/art_tone_audit.md` 当前结果：high=0、medium=0、low=42、saturatedHardcodedColor=0。

### 审计结论同步

- `docs/audit/tower_structure_review_2026-06-28.md` 已同步当前爬塔 Boss 数值与 §5.4 Boss HP 红线口径。
- 本报告已修正桃花岛、江湖恩怨、颜色审计与全量测试结果的陈旧表述。

## 2. 问题与风险

### P0/P1：未发现当前阻断级功能缺陷

本轮未发现会导致启动失败、红线破防、核心战斗结算错误、资源丢失或生产入口误暴露的高优先级缺陷。`flutter analyze` 与 `flutter test --no-pub -j1` 均通过，生产 PVP 路径仍未恢复，仅保留旧档兼容 schema/enum/fallback。

### P2-1：真机/动态体验校值债集中，headless 全绿不能替代实玩

证据：

- `PROGRESS.md` 记录祖师回归学徒、空手、入门功后，仍需真机确认 `stage_01_01` 早期平衡。
- 命中特写/题字分级的字号、辉光、缩放、脉冲 ms 仍待 `flutter run -d macos` 目检。
- 战斗节奏、周目奖励、出售/分解、升级曲线等 balance 初值仍待真机校。

影响：自动化能证明规则与回归安全，但不能证明“学徒空手开局是否顺”、“命中特写是否抢戏”、“战斗节奏是否可读”、“经济回报是否有体感”。

建议：单独开一次“真机体验校值批”，只做 macOS 实玩 + 参数微调，不混入新功能。优先顺序：新档 01_01 → 常速战斗节奏 → 命中峰值演出 → 周目/出售/分解/升级曲线。

### P2-2：桃花岛疗伤丹已闭环，但部分加工产物仍缺终端用途

证据：`PROGRESS.md` 已记录“疗伤丹消费 + 药材丹药闭环”完成；但锻材、开锋辅材、行囊补给等加工产物仍属于生产端先行，终端消耗与经济权重还需要继续拍板。

影响：这不是当前 bug，离线=在线与供应链自洽已有测试守住；但持续生产如果缺少消耗出口，会削弱桃花岛作为养成经营支柱的动机。

建议：不要先扩更多建筑或产物。下一步优先把锻材/开锋辅材接装备强化或开锋，把行囊补给接主线/扫荡续航或离线收益解释。

### P2-3：江湖恩怨战斗乘区已接入，不再是 0 caller；风险转为覆盖面

证据：

- `StageBattleSetup` 已通过 `stage.npcId` 烘焙江湖恩怨 APM。
- `test/features/battle/application/stage_battle_setup_test.dart` 已覆盖“带 npcId 的 Boss 关进战斗时烘焙 APM 与来源”。

影响：此前“战斗乘区 0 caller / 1.1 延期”的结论已过期。当前更准确的风险是覆盖面：哪些关卡、Boss、奇遇或 NPC 关系会生产并消费这条链，还需要按 1.0 体验目标继续梳理。

建议：如果江湖恩怨要成为 1.0 可感知体验点，下一步应扩展关系写入来源与 `npcId` 覆盖清单，而不是再讨论是否接入 battle setup。

### P3-1：颜色审计 medium 已清零，仍有 low 级 token 债

证据：`test/tools/output/art_tone_audit.md` 当前 high=0、medium=0、low=42；剩余均为低优先级硬编码 UI 色。

影响：没有 Material 默认主题/默认色高危项，也没有 saturated hardcoded 色；但低优先级 token 漂移仍会让后续页面统一成本变高。

建议：不阻断功能。后续随页面重构继续把 low 项迁入用途 token，不建议单独大批量改动所有低风险颜色。

### P3-2：PVP 功能已剔除，仅剩历史文档残留

证据：生产功能路径已按 `CLAUDE.md` / `GDD.md` 口径切除 PVP；当前扫描只剩 legacy schema/enum/fallback 与旧档兼容语义。仍需注意的是 `docs/phase0/p3_3_pvp_phase0_2026-05-24.md`、`docs/spec/p3_3_pvp_spec_2026-05-24.md`、旧 ROADMAP 段还有大量 PVP 历史方案。

影响：这不是功能残留，也不表示 PVP 仍在 1.0 范围内。风险只在文档层：后续如果只读旧 spec，可能误判项目范围。

建议：保持现状也可接受；更稳的做法是在旧 PVP spec 顶部加醒目“历史作废，PVP 已切除，仅供考古”标记，或迁到 `_archive`。

## 3. 健康项

### 验证结果

- `flutter analyze`：No issues found。
- `flutter test test/balance/cycle_evolution_redline_test.dart --reporter expanded`：25 passed。
- `flutter test test/features/battle/application/master_disciple_battle_test.dart test/features/battle/application/stage_battle_setup_test.dart --reporter expanded`：39 passed。
- `flutter test test/tools/art_tone_audit_test.dart --reporter expanded`：3 passed。
- `flutter test --no-pub -j1`：3304 passed / 1 skip / 0 failed。

### 红线状态

- §5.1 反主流：未发现生产实现体力、每日、登录奖励、战令、抽卡、VIP、挂机加速、在线 buff、快进券。
- §5.3 三系锁死：装备/心法/招式 gate 均有测试与 schema 红线覆盖；师承遗物例外已被取消，逻辑统一。
- §5.4 数值：配置基础表值走 `GameRepository.loadAllDefs()` fail-fast；软线“不进百万”由 `full_build_damage_redline_test` 与相关 balance 红线覆盖。
- §5.5 在线=离线：离线挂机、桃花岛 settle、扫荡等均走真实时间/确定性结算；未发现加速券或在线加成。
- §5.6 文案/数值：中文字符串仍大量存在于允许 sink（`UiStrings`、`EnumL10n`、`BattleLog`、错误信息、debug、注释）。未发现本轮必须立即迁移的生产 UI 散写中文。

### 内容与资产

- 资产审计在既有报告中已显示引用缺失 0。
- 内容量仍远超 Demo 目标：主线 30 关、爬塔 30 层、装备 80、心法 49、典故 80 等结论与 2026-06-25 健康复盘一致。
- 祖师新档强度、弟子终局拜入、多存档、PVP 切除等 6/27 大批变更已进入全量测试基线。

## 4. 覆盖盲区

- 本轮没有启动 `flutter run -d macos` 做人工目检。
- 没有做 Windows 端复验；上一次 Windows SSH 验收见 `docs/audit/windows_acceptance_2026-06-25.md`。
- 没有做长时间真实存档游玩，只依赖单元/Widget/模拟器与历史真机记录。
- 没有对所有历史 spec 做文档归档清理，只标出当前误导风险。

## 5. 阶段判断

项目当前不是“功能未闭环”状态，而是“功能量已足、需要实玩调味”的打磨期状态。自动化质量网很强，红线守得住，资产缺口清零；当前主要风险集中在实玩手感、经济初值、动态演出、部分生产/消费闭环和历史文档误导。

## 6. 建议下一步

1. 做一次真机体验校值批：新档 01_01、战斗节奏、命中特写、周目奖励、出售/分解/升级曲线。
2. 继续补桃花岛剩余加工产物的终端用途，优先锻材、开锋辅材、行囊补给。
3. 扩展江湖恩怨的关系写入来源与 `npcId` 覆盖清单，让战斗乘区在 1.0 中更可感知。
4. 给旧 PVP spec 加作废标记或迁档；这是文档清理，不是功能剔除工作。
5. 随页面重构继续收敛 low 级颜色 token，不必为此暂停功能打磨。
