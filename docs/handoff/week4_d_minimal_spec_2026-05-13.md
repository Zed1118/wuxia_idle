# Phase 3 Week 4 · D 师徒系统 — 最小决策版本草案

> 写给 Mac Opus + 用户讨论 Week 4 起手方向时拍板。
> 本草案的目的：在不解 §12 #10 / #11 全部子问题的前提下，找到一条"Demo 不返工 + 起手最小"的路径。
> 拍板后再拆 T53+ 任务，本草案不落代码。

---

## 1. 核心观察：Demo 不做飞升 → §10 / §11 大部分子问题可推迟

GDD §7.1 把"传位 / 祖师 buff"明确绑定在**飞升后**：

> 飞升渡劫后 → 传位给大徒弟，前任成为祖师爷提供门派 buff

GDD §12（CLAUDE.md §7 的"Demo 不做"清单也再次确认）已写明 **Demo 阶段不做飞升**。

由此推出：

| §12 待决子问题 | Demo 是否发生 | 决议 |
|---|---|---|
| #10 (a) 师承遗物传递时机 | ❌（无飞升 → 无传位） | **Demo 推迟到 1.0 版本** |
| #10 (b) 多徒弟谁继承 | ❌（无传位动作） | **Demo 推迟到 1.0 版本** |
| #10 (c) 传承 buff 是否累代叠加 | ❌（最多 1 代师徒可见） | **Demo 推迟到 1.0 版本** |
| #10 (d) 同部位装备冲突处理 | ❌（无传递则无冲突） | **Demo 推迟到 1.0 版本** |
| #11 祖师 buff 内容 | ❌（`enabled_when_alive: false` 已锁） | **Demo 不实现，保留占位 key** |

**结论**：D 起手不需要等 #10/#11 4 项决策定稿。Demo 阶段 D 的真实工作量是「3 角色种子 + 师徒关系展示 + 师承遗物作为静态装备 fixture」。

---

## 2. Demo 阶段 D 实际要做什么（最小可交付）

### 2.1 三角色种子（必做）

- 新建 `data/masters.yaml`，定义 **祖师 + 大弟子 + 二弟子** 3 个角色模板：
  - `id` / `lineage_role`（founder / first_disciple / second_disciple）
  - `default_realm` / `default_layer`（祖师宗师初期，大弟子一流初期，二弟子绝顶初期，**全部 < 武圣**避免触碰飞升锚点）
  - `attribute_profile`（4 项属性固定模板，不走 CharacterGenerator roll，确保 Demo 体验一致）
  - `starting_technique_ids`（每人 1 主修 + 1 辅修）
  - `starting_equipment_ids`（每人 3 件，祖师含 1 件 `isLineageHeritage = true`）
- `Phase2SeedService.seedP1` 改造（与挂账 #25 同期处理，**或者**新增 `seedMasterDisciple` 专项）：调用方主菜单一键种子 3 角色 → 写入 `Character` 表 + 设 `masterId / discipleIds / lineageRole / isFounder` 关系字段
- **`founder = 玩家`**：祖师就是玩家自己，不再单独建一个 "founder" 角色；二弟子/大弟子是玩家收的两个徒弟。这个判定**必须先和用户确认**——见下方 ⚠ 决策点 1

### 2.2 师承遗物（静态 fixture，不做传递）

- `equipment.yaml` 标记 **2-3 件**装备 `is_lineage_heritage: true`（祖师初始装备里挑 1-2 件即可）
- `Equipment.isLineageHeritage = true` 时，**境界达标即可装备**，自动享 +5% 内力上限（已配 `numbers.yaml lineage_heritage.internal_force_max_bonus: 0.05`）
- **Demo 不做"传递"动作**：遗物就是普通带 buff 的装备，玩家用祖师角色穿就行
- 三系锁死继续硬约束（`canEquip` 已实现，无需新代码）

### 2.3 师徒关系展示 UI（必做）

- 角色页签加「师承」段：
  - 显示「师父：XX（境界）」/「徒弟：[XX, XX]（境界）」
  - 祖师页签显示 `isFounder` 标识 + 简短传记（DeepSeek 写 `data/lore/masters/<id>.yaml` 文案？需先和 DeepSeek 协调，**或者** Demo 阶段先用占位「[传记待补]」）
- main_menu 增加「师徒」入口？**或者** 在「角色」面板里平铺 3 角色，不开新入口

### 2.4 3v3 上阵（留接口，不做 UI）

- `Character` 字段已支持，`SaveData.activeCharacterIds` 直接放 3 个 id 就能上阵
- **Demo 阶段 seed 默认就把 3 师徒放入 activeCharacterIds**，玩家进战斗就是师徒同阵
- **不做换人 UI**——留 Phase 4 一并处理

### 2.5 祖师 buff 接口占位（不实现）

- `numbers.yaml founder_ancestor_buff.enabled_when_alive: false` 已锁，**不动**
- 不写任何 buff 应用代码；保留 key 表明 1.0 版本接入点

---

## 3. 不做清单（明确划掉）

❌ 飞升机制 / 渡劫场景
❌ 传位动作（任何"师父境界到 X → 自动把装备移交给徒弟"逻辑）
❌ 祖师 buff 应用（sect_wide_buff: null 保持）
❌ 收徒 UI（GDD §7.1 一流可收徒，但 Demo 3 角色固定，不开放）
❌ 徒孙（GDD §7.1 绝顶可收徒孙，Demo 不做）
❌ 师承遗物在角色之间转移（玩家手动装备/卸下走普通装备路径即可）
❌ 多代师徒树（Demo 只 1 代：玩家=祖师，2 徒弟）

---

## 4. ⚠ 起手前还需要用户拍板的 3 个最小决策点

> ✅ **已全部拍板（2026-05-13，按推荐方案 A）**。
> 决议下方逐条标 ✓，T53+ 任务按此推进。

> 这 3 点比 §12 #10/#11 4 问要小得多，但起手 T53 之前必须定。

### 决策点 1：祖师 = 玩家本人，还是另起一个角色？✓ 方案 A

- **方案 A（已选）**：祖师就是玩家。`SaveData` 创建时玩家的 Character 直接 `isFounder = true / lineageRole = founder`。大/二弟子是 2 个独立 Character。优点：玩家代入感强，省 1 个角色 schema；契合 GDD §7.1「玩家是开派祖师」。
- **方案 B（否决）**：祖师是 NPC，玩家扮演大弟子或新成员。与 GDD §7.1 直接冲突。
- **影响落地**：`masters.yaml` 共 3 条；T54 seed 时**复用玩家既有 Character**，仅追加 `isFounder = true / lineageRole = founder / discipleIds = [大弟子id, 二弟子id]`，不另建 founder Character

### 决策点 2：师承遗物 fixture 走 equipment.yaml 还是新拆 lineage_heritages.yaml？✓ 方案 A

- **方案 A（已选）**：继续挂在 `equipment.yaml`，新增 yaml key `isLineageHeritage: true`（内容 yaml 走 camelCase，对齐现有 `schoolBias` / `baseAttackMin` 命名）
- **方案 B（否决）**：新建 `data/lineage_heritages.yaml`。Demo 阶段不值得为概念清晰拆 schema
- **影响落地（已校准）**：现状 `Equipment` runtime 实例有 `isLineageHeritage` 字段，但 **`EquipmentDef` 还没有该字段，`equipment.yaml` 也没有该 key**。T55 需要：(a) `EquipmentDef` 加 `final bool isLineageHeritage` + fromYaml 读 key（缺省 false）；(b) `equipment.yaml` 标 2-3 件 `isLineageHeritage: true`；(c) `EquipmentFactory.generate` 把 def.isLineageHeritage 透传到 Equipment 实例。比草案初版预估略增工作量但仍在 0.5 天内

### 决策点 3：师徒传记文案是否本期上 DeepSeek？✓ 方案 A

- **方案 A（已选）**：本期不接 DeepSeek，UI 用「[传记待补]」占位；DeepSeek 端可并行启动 `data/lore/masters/<id>.yaml` 协作任务，不阻塞 Mac 端 T53-T58
- **方案 B（否决）**：阻塞等 DeepSeek，串行推迟
- **影响落地**：T56 师承 UI 用 placeholder 字符串；T58 视觉验收只看 schema/UI 不看文案；后续 DeepSeek 文案到位后 placeholder 自动替换（参考 P1 #1 narrative loader 子目录扫描套路）

---

## 5. 预估 T 任务拆分（拍板后再细化）

| T# | 任务 | 预估时长 | 依赖 |
|---|---|---|---|
| T53 | masters.yaml schema + MasterDef + GameRepository 加载 + 红线校验 | 0.5 天 | — |
| T54 | seedMasterDisciple 服务 + Phase2SeedService 入口（与挂账 #25 协调） | 0.5 天 | T53 |
| T55 | 师承遗物 fixture（equipment.yaml 标 2-3 件 + Equipment.fromYaml 适配） | 0.5 天 | T53 |
| T56 | 角色页签「师承」段 UI + 「师徒」入口 or 平铺 | 0.5-1 天 | T54 |
| T57 | activeCharacterIds 默认入阵 + 3v3 战斗 service 集成测试 | 0.5 天 | T54 |
| T58 | 全量 test + analyze 双绿 + Pen 视觉验收 + tag v0.3.0-w4 | 0.5 天 | T53-T57 |

**总计**：3-3.5 天。比 Week 3 闭关地图（5 天）短，但比 Week 1 主线闭环（3 天）相当。

---

## 6. 关联 / 接续

- **§12 #5 闭关公式收口**：已决（2026-05-13），3 维度扩展挂账 #30，详 `PROGRESS.md`
- **挂账 #25 P1 fixture 缺主修**：seedMasterDisciple 可顺手处理（3 师徒都默认主修就位 → P1 → 主线战斗不再 fail-fast）
- **挂账 #26 闭关入口硬编码 characterId=1**：与 #25 同源，T54 seed 改造后可一并修
- **GDD §7.1 / numbers.yaml `lineage_heritage` / `founder_ancestor_buff`**：本草案不改这 3 处，保持禁碰

---

## 7. 决策完成后的下一步

1. 用户对 §4 三个决策点逐一拍板（或者一句"按推荐方案 A"）
2. Mac Opus 拆 T53-T58 任务细节，落入 `phase3_tasks.md`
3. 起手 T53，按入场检查三件套（git log / analyze / test）+ 红线模板执行
4. Pen 端等 T58 visual check

---

> 拍板后，本草案归档；T53+ 起手只跟 `phase3_tasks.md` 走。
