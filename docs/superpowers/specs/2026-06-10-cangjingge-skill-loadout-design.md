# 藏经阁 + 技能装配系统设计（P1b）

- **日期**：2026-06-10
- **状态**：brainstorm 定稿，待 writing-plans
- **前置**：P1a 养成内核（解锁态 / 熟练度 / 残页后端已实装合 main · feat/p1a-cultivation-core）
- **关联缺口**：playability_phase2_backlog.md「一·P1a 内推迟项」+「六·解锁态消费 #52」

## 1. 目标

把 P1a「后端做好了但玩家看不见 / 用不上」的三样接到玩家可见可操作：① 技能装配（6 槽）② 熟练度可见 ③ 残页进度可见。新建藏经阁 screen 聚合。

## 2. 已敲定决策（brainstorm）

- 布局 **A 角色武学手册** 为主 + 残页收集融入
- 装配模型：**自动配 + 玩家可调**（不强迫操作，符合 idle 基调）
- **6 槽**：主修×2 / 辅修×1 / 共鸣×1 / 大招×1 / 奇遇×1（奇遇独立，复用现有单槽）
- 破招技 build gate（§9.1）**留 backlog**（依赖装配成立 + 碰破招机制，本波不动）
- 熟练度行：阶段 + 进度 + 当前加成 + 还需次数 + 装配态
- 残页账号级，集齐自动解锁

## 3. 数据模型（方案① 独立字段 · 沿 equippedWeaponId 体例）

`lib/core/domain/character.dart` 加 5 字段（`String?`）：
- `mainSkillId1` / `mainSkillId2` / `assistSkillId` / `resonanceSkillId` / `ultimateSkillId`
- 奇遇槽：复用现有 `equippedEncounterSkillId`（不动）
- `Character.create` 工厂 + `copyWith` 同步加参（memory：late 字段必走工厂，不裸 ctor）
- `IsarSetup._currentSaveVersion` 升一版 + `isar_setup_test` 期待值同步改
- 红线：装配时校验 `SkillDef.canEquipAtRealm(realmTier)`（低境界装不进高 tier）

## 4. 自动填充策略（纯域 SkillLoadout）

- 触发：学新技能 / 换主辅修心法 / 首次进战斗 → 补满空槽
- 规则：主修2 = 主修心法下技能按熟练度高→低取前 2；辅修1；共鸣1 = 解锁 joint_skill 才填；大招1 = powerSkill 类取 1
- 玩家手动调过的槽标 `manual`，不被自动覆盖（尊重玩家 build）
- 纯 Dart：`SkillLoadout.autoFill(...)` 返回 6 槽，无副作用可单测；持久化经 `SkillLoadoutService`（Isar，caller 持锁 writeTxn 体例）

## 5. 解锁注入战斗（backlog #52）

- 装配 6 槽技能 → `BattleCharacter.availableSkills`（`stage_battle_setup.dart` wire）
- `SkillUnlockService.isUnlocked` 过滤：未解锁不进池
- 破招技维持现状广发（gate 留 backlog · 不碰破招机制 · Codex 刚验收）

## 6. 入口 + 交互

- 入口：主菜单木牌「藏经阁」（§5.7 门控，学了技能才亮；沿 main_menu debugItems / 系统入口体例）
- 换招：点槽位 → bottom sheet picker（沿 `encounter_skill_section.dart _PickerSheet` 体例），列该槽类型可装技能 + 境界锁灰显不可点

## 7. UI 组件（lib/features/cangjingge/presentation/）

- `CangJingGeScreen`：顶角色 tab + 出战配置栏(6 槽) + 武学库(按主/辅修心法分组) + 残页收集区
- `SkillSlotRow` / `SkillSlotPicker`：6 槽展示 + 换招
- `SkillProficiencyRow`：阶段 + 进度 + 加成 + 还需次数 + 装配态（复用 `MeridianBar`）
- `FragmentProgressRow`：残页 ▣▣▣▢▢ N/M
- 文案全走 `UiStrings`（§5.6 不硬编码中文）；视觉沿 WuxiaUi 宣纸 token

## 8. 测试（红线 · TDD 先红后绿）

- 装配 gate：低境界装不进高 tier（`canEquipAtRealm`）
- 自动填充幂等 + manual 槽不被覆盖
- 解锁注入：只注入「已装 ∩ 已解锁」
- 残页集齐自动解锁（已有 `SkillUnlockService` 测，补 UI wire）
- 全量回归 baseline + delta（不写死期望，算式）

## 9. 范围边界

- **本波做**：6 槽装配 + 自动填充 + 藏经阁 screen + 熟练度/残页可见 + 解锁注入战斗
- **留 backlog**：破招技 build gate(§9.1) / 24 招全内容(§16 #1) / 166 招 source tag / 统一进度组件四系统全 wire

## 10. 风险 / 依赖

- Isar saveVersion 升 → 旧存档迁移：新字段默认 null，首次进藏经阁/战斗时 autoFill 补满
- 不碰破招机制（Codex 刚验收收口）+ 不碰战斗 UI 技能栏（破招 gate 留 backlog，装配栏只在藏经阁内）
- 共鸣槽依赖 joint_skill 解锁状态（共鸣度系统），未解锁则槽空不报错
