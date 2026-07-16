# 江湖远行 #2 — 发布上限 10→17 + Lv100 解锁触发（里程碑批·选项 A）

**Goal:** 落地「Lv100 里程碑」——发布上限绝对层 10→17（打开二流名义空间，配合远征无尽深入作成长通道）+ Lv100→`jianghuJourneyUnlocked` 触发接线。2 二流孤儿招（千钧坠岳/烛影摇红）用红线⑦「未发布挂载」显式豁免（`SkillDef.mountDeferred`）解阻塞，正式挂载留 batch3 远征掉落/Phase C 断魂庄。

**用户拍板（2026-07-16）:** 选项 A（提 cap + 豁免 2 招）+ 升 xhigh。

**分支:** `feat/baicao-duanhun-phase-b`（worktree·**未 push·push 是用户的活**）。**无 schema/saveVersion 改动**（`jianghuJourneyUnlocked` 字段 A1 已建）。

## Phase 0 结论（2026-07-16 本会话现查·file:line）
- cap 现值 10：`data/numbers.yaml:206 max_absolute_realm_level: 10`；溢出探针已在 phase-b（`test/tools/overflow_layer_jump_probe_test.dart`·A2 T2 已判定一次性兑现安全）。
- 红线⑦：`lib/data/game_repository.dart:1852 _enforceSkillSourceRedLines`；`releaseSkillTierCap = releaseRealm.tier.index+1`（:1856）；cap 10→17 使发布境界三流→二流、tier cap 2→3；`tier≤cap` 的 mainlineDrop/fragment 招必须恰 1 个 **stage/tower** 挂载（:1919-1944 orphan 抛错）。**远征节点不在扫描范围**（故不能靠挂远征解）。
- 2 孤儿招（stages/towers **零挂载**·grep 确认）：
  - `skill_qian_jun_zhui_yue`（`skills.yaml:2907`·tier 3·mainline_drop·刚猛·powerMult 2800）
  - `skill_zhu_ying_yao_hong`（`skills.yaml:3027`·fragment·配秘籍 `items.yaml:20 item_scroll_zhu_ying_yao_hong`）
  - 原挂 stage_03_05/tower f15 被 Codex Lv100 批 re-tier 到学徒 → 现零挂载。
- `SkillDef`：`lib/data/defs/skill_def.dart:32`（class）；`source` :65/:151、`tier` :95/:141；`enum SkillSource` :6。
- **Lv100 触发设计**（companion:79）：任一角色首次达 Lv100（绝对层 10 顶）后永久置 `jianghuJourneyUnlocked=true`；旧档升级已有角色 ≥Lv100 也补解锁（companion:259 不重复）。
- `jianghuJourneyUnlocked`：`lib/core/domain/save_data.dart:120`（字段已存在）；gate 消费 `lib/features/main_menu/presentation/main_menu.dart:295`；**无 setter**（触发未接线）。

## 切片

### 切片 1: 红线⑦「未发布挂载」豁免机制（先做·解 cap 阻塞）
- TDD 红：在 red-line 测族加用例——cap=17（或直接构造 releaseSkillTierCap=3 场景）下，标记 `mountDeferred` 的 tier-3 drop 招不触发 orphan；未标记的孤儿仍抛（保护语义不被豁免吞掉）。定位现有红线⑦测：`git grep -ln "_enforceSkillSourceRedLines\|挂载不完备\|波B 红线" test/`。
- 绿：`SkillDef` 加 `final bool mountDeferred`（默认 false）+ fromYaml 解析 `mount_deferred`（`skill_def.dart:141` 邻近）；`game_repository.dart:1920-1935` 构建 `manualSkills`/`fragmentSkills` 集合处加 `&& !(skillDefs[...]?.mountDeferred ?? false)` 排除。红线⑥（style+tier 必备）**不豁免**——2 招仍是合法定义。
- skills.yaml 给 2 招加 `mount_deferred: true` + 头注（挂载留 batch3/Phase C，挂载时删标记=发布）。

### 切片 2: 发布上限 10→17
- 依赖切片 1（否则 loadAllDefs 抛错）。
- TDD 红：`test/data/numbers_config_progression_release_cap_test.dart:35` 断言 10→17（标题同步）；`fromYaml(const {})` 默认全 49、越界拒收两用例不动。
- 绿：`data/numbers.yaml:206 max_absolute_realm_level: 17`。
- 核放宽非破坏：`test/data/mainline_stage_curve_redline_test.dart` + `test/balance/inner_demon_r5_redline_test.dart`（敌人绝对层 ≤cap，现有 ≤Lv100 仍满足）。

### 切片 3: Lv100→`jianghuJourneyUnlocked` 触发接线 + 旧档补触发
- 触发点：角色经验/升境统一入口 `CharacterAdvancementService`（现查具体方法）——任一角色 `absoluteLevel` 首次达 10 → 置 `save.jianghuJourneyUnlocked=true`（幂等·已 true 跳过·永久不可逆）。写路径需在既有事务边界内（勿新开嵌套 writeTxn）。
- 旧档补触发：启动流程（`MainMenuStartupGate` 或存档加载）若已有 active 角色 ≥Lv100 且标志未置 → 补置。复用 settle-on-open 体例挂载点。
- TDD：角色升到绝对层 10 触发解锁；<10 不触发；已解锁不重复写；旧档 ≥Lv100 启动补解锁。轻量测优先（避 GameRepository 依赖崩），必要时真 Isar。

### 切片 4: 批末验证（§8.0 跨切面必全量）
- `flutter analyze --no-pub lib test` 0；A2 T1 targeted（cap 测 + 红线⑦测 + 触发测）；**全量 `flutter test --no-pub`**（改了 numbers/红线/触发·跨切面）0 fail；macOS debug build 成功。
- 目检：Lv100 触发后主菜单江湖远行入口出现（生产存档现在可达·可 seed 一个 ≥Lv100 角色验 visual_route）。

## 恢复点（2026-07-16·plan 就绪·未动实装）
- 状态：Phase 0 完成、设计拍板（选项 A + xhigh）、plan 固化。**下一步：切片 1**（红线⑦豁免）。
- 已跑验证：analyze `lib test` 0（本会话·#1 收尾后）。
- 阻塞/待决：无（2 招 phasing 已拍板豁免）。D2（Lv100→170 经济节奏·快/中/慢档）留 batch3 联合经济探针，不在本批。

## 验收标准
- cap=17 下 `loadAllDefs` 不抛错（2 招豁免生效）；2 招定义保留、零挂载、mount_deferred 留痕。
- 任一角色达 Lv100 永久解锁江湖远行；旧档 ≥Lv100 升级补解锁；均幂等不重复。
- analyze 0 + 全量 0 fail + macOS build 成功；无 schema/saveVer 改动。
