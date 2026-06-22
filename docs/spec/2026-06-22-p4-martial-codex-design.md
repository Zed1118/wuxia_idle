# 藏经阁2.0（武学收录图鉴）· 设计

> P4 长期档案·子项6（最后1子项）。2026-06-22。brainstorm 拍板后落档。
> 形态：江湖见闻录(baike)第5 tab，与兵器谱/奇遇录完全对称的**纯派生展示图鉴**。
> 区别于「藏经阁1.0」(`lib/features/cangjingge/`，技能装配操作屏)：1.0=当前角色装配操作，2.0=账号级全局只读收藏册，职责互补不重叠。

## 决策锚点（brainstorm 已拍板）

| # | 决策 | 取值 |
|---|---|---|
| 1 | 收录范围 | **武学典籍 205 招**：心法147(technique) + 真解6(mainlineDrop) + 残页9(fragment) + 破招3(special∩canInterrupt) + 奇遇40(encounter)。**排除**轻功对决18 + joint共鸣1（special 非破招，minigame/系统招） |
| 2 | 详情屏文案 | **纯同步复用现有字段**：`skill.description` + 倍率/内力耗/冷却/来源/所属心法/熟练度。零新文案零async |
| 3 | 图鉴视角 | **账号级全局收藏册**：点亮=账号曾解锁/学过即永久点亮；熟练度=全队最高造诣。换角色图鉴不变 |
| 4 | 分组结构 | **方案 A 按来源分5组**（心法绝学/真解/残页/破招/奇遇）；心法大组内按「7阶×3流派」小标细分 |
| 5 | 剪影藏名 | 对称奇遇录：未点亮项藏名，**§5.7 不泄来源/触发条件** |

## 架构（对称 encounter_codex）

```
lib/features/baike/
├── application/martial_codex_provider.dart   # 纯函数 + @riverpod async provider
└── presentation/
    ├── martial_arts_tab.dart                 # baike 第5 tab
    └── skill_codex_detail_screen.dart        # 详情屏(纯同步派生)
```

改动既有：`baike_screen.dart`(4→5 tab) / `shared/strings.dart`(UiStrings 词条) / `features/debug/application/visual_route.dart`(双路由)。

**红线**：零新 Isar collection、零 saveVer 改、零数值改。纯派生展示层（对称奇遇录，区别于兵器谱——后者因记「首得历程」才用 collection）。

## 数据流（三纯函数 + 一 async provider）

### 收录池 205 — 纯函数 `isMartialCodexSkill(SkillDef) → bool`
从 `GameRepository.instance.skillDefs` 过滤：
`source ∈ {technique, mainlineDrop, fragment, encounter}` **或** `(source == special && canInterrupt)`。
> ⚠️ plan 阶段验证项：奇遇招（`data/encounter_skills.yaml`）是否已并入 `repo.skillDefs`。佐证「是」——`cangjingge_screen` `_pickEncounter` 用 `repo.skillDefs[id]` 取奇遇招名 + `repo.encounterSkillIds` 存在。实装前 grep 实证，避免奇遇40漏收。

### 点亮集 — 纯函数 `litSkillIds({pool, unlockedIds, activeTechniques, activeSchools}) → Set<String>`
账号级**三套口径**（破招技解锁机制特殊，2026-06-22 实证补：不走 unlockProgress、不属任何心法，按 style 默认可装配）：
- **稀有招**(真解/残页/奇遇 · source∈{mainlineDrop,fragment,encounter})：`unlockedIds`（= `unlockedSkillIdSetProvider`，单一真相源 `SaveData.skillUnlockProgress` 中 `unlocked==true`，「奇遇/真解/残页全走此池」`encounter_service_providers.dart:45`）
- **心法招**(technique)：account 下任一 active 角色的心法招并集（`repo.techniqueDefs[tech.defId].skillIds`）—— 学了该心法 ⇒ 该心法所有招点亮
- **破招技**(special∩canInterrupt · 3个)：`activeSchools`（active 角色 `character.school` 集）含该招 `style` ⇒ 点亮（门下有该流派弟子 → 该流派破招可见，对称「流派由所属心法承载」既有约定）
> 口径务实度：取 active 角色 techniques/schools，**不追飞升退场的历史角色**（对称兵器谱 isPreRecord 骨架的务实约定）。

### 全队最高熟练度 — 纯函数 `maxUsesOf(skillId, activeTechniques) → int`
遍历 active 角色所有 `Technique.skillUsageCount.countOf(skillId)` 取 max。
映射：`SkillProficiency.stageFor(maxUses, cfg)`（cfg = `NumbersConfig.skillProficiency`）→ 熟练阶/星级。心法招的 uses 落在所属心法 technique；稀有招（drop/奇遇）uses 落主修 technique（沿 1.0 武学库秘传组既有约定）。

### provider — `@riverpod Future<List<MartialCodexGroup>> martialCodex(Ref)`
拉 `SaveData.skillUnlockProgress` + active 角色 techniques，调三纯函数，返回 5 组（空段不产出，对称 `groupEncounters`）。

### 共享纯函数（防双份漂移 · 项目 rule-copy bug 史）
`martialSourceKindOf(SkillDef) → MartialGroupKind`（来源归类）、`labelForMartialGroupKind(kind) → String`（显示名）。provider 分组与详情屏来源标共用——对称 encounter_codex 的 `encounterGroupKindOf` / `labelForEncounterGroupKind`。

## 组件

- **MartialCodexEntry**：`{def, isLit, maxStage?}`（剪影时 maxStage 不显）
- **MartialCodexGroup**：`{kind, entries, litCount}`；心法组内再按 `(techDef.tier, skill.style)` 小标
- **martial_arts_tab**：5 组列表。点亮项显招名+倍率+来源标，可点 → 详情屏；剪影项 `▨▨▨` 藏名，点击 → snackbar「尚未习得」（§5.7）。组头 `X/N`
- **skill_codex_detail_screen**：纯同步派生——`description` + 倍率/内力耗/冷却 + 来源 label + 所属心法 + 全队最高熟练度星级（复用 `SkillProficiencyRow` 体例或 `StageProgressRow`）

## 空态守（对称奇遇录）
`GameRepository` 未加载 / 池空 / 全未点亮 → 空态提示，不甩剪影墙。注：心法招新角色自带 ⇒ 实务不会全剪影，但仍加守（测试旁路/极端档）。

## 测试

- 纯函数单测：`isMartialCodexSkill`(收录过滤含破招/不含轻功joint) · `litSkillIds`(三套口径:心法招学过/稀有招unlockProgress/破招按派) · `maxUsesOf`(全队聚合) · `groupMartialSkills`(分组序/计数/剪影藏名/空段不产出/心法小标)
- `baike_screen_test` 补第5 tab 断言（4→5 tab + tab 标题）
- tab widget 测：点亮/剪影/空态三态（ListView viewport 扩，addTearDown）
- VISUAL_ROUTE 双路由：`martial_codex`(混态seed：部分点亮+部分剪影) + `martial_codex_detail`

## 红线自检清单（实装收尾核）
- [ ] 零 saveVer / 零 collection / 零数值改（纯派生）
- [ ] 段标/进度/剪影/snackbar 进 UiStrings；招 flavor 复用 description；来源/阶/流派显示名走 EnumL10n；无散写中文
- [ ] §5.7：剪影藏名不泄来源/触发条件
- [ ] 空态保护到位
- [ ] 端到端类型连贯；收录池过滤一处真相源；来源归类/label 单一真相源（防漂移）
