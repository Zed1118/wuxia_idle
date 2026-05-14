# W14-3-A C 任务 奇遇专属 skill 池 + 战斗消费 + 装备 UI closeout(2026-05-14)

> 写给下一会话开局者(Mac Opus)+ W14-3-B/C 继续推进的人。
> 单 commit + **607/607** + analyze 0 issues。

---

## 1. 一句话结论

W14-1 留尾 `EncounterProgress.unlockedSkillIds` 战斗系统 0 调用 → 闭环。
新建独立 yaml(35 招 / 7 阶覆盖)+ Character 单 slot + 战斗 4 招装载 + 角色面板装备 UI。
GDD §5.3 三系锁死沿用(境界 ≥ skill.tier-1 才可装)。

---

## 2. 决策点 lock(本会话开局问完,沿用 W14-1 体例)

| # | 决策点 | 选项 | 备注 |
|---|---|---|---|
| Q1 | tier 锁死 | **完整 7 阶 + 境界锁死** | encounter_skills.yaml 每招 tier 1-7,canEquip 检查境界 ≥ tier。沿 GDD §5.3 |
| Q2 | 战斗 slot 设计 | **独立 slot(1 个奇遇槽,与主修 3 招并存,共 4 招)** | BattleCharacter.availableSkills 无硬限制,growable 加 1 |
| Q3 | 与 skills.yaml 关系 | **完全独立池** | encounter_skills.yaml 独立 yaml + skill_encounter_ 前缀;runtime SkillDef 同型,合并到同 Map 减少改动 |

---

## 3. 实现栈

### 3.1 数据层

| 文件 | 改动 |
|---|---|
| `data/encounter_skills.yaml` | **新文件**,35 招(7 阶 × 5)。含 W14-1/W14-2 已引用 6 招(★) |
| `lib/data/defs/skill_def.dart` | 加 nullable `tier: int?` 字段 + `isEncounterSkill` getter(parent==null && tier!=null) |
| `lib/data/models/character.dart` | 加 `equippedEncounterSkillId: String?` 字段(角色级,与 equippedWeaponId 并列) |
| `lib/data/isar_setup.dart` | schema 0.6.0 → **0.7.0** |
| `lib/data/game_repository.dart` | _loadAllDefs 加载 encounter_skills.yaml 合并到 skillDefs Map + encounterSkillIds Set + `_enforceEncounterSkillRedLines` + `allEncounterSkills` getter + `isEncounterSkill(id)` helper |

### 3.2 服务层

`lib/services/encounter_service.dart`:
- 新 sealed `EquipEncounterSkillResult` { EquipSucceeded / EquipNotUnlocked / EquipTierLocked / EquipNotFound }
- `equipEncounterSkill({characterId, skillDef, saveDataId})` writeTxn:校验 isEncounterSkill / Character 存在 / progress 存在 / unlocked / 境界锁死,通过则写 character.equippedEncounterSkillId
- `unequipEncounterSkill({characterId})` 返回 `hadEquipped` bool
- static `canEquipEncounterSkillByTier({realmTier, skillTier})` UI 用纯函数
- import flutter foundation debugPrint(catch 块沿用 W13 教训)

### 3.3 战斗层

`lib/combat/battle_state.dart` `BattleCharacter.fromCharacter`:
```dart
final skills = <SkillDef>[
  ...techDef.skillIds.map((id) => GameRepository.instance.getSkill(id)),
];
final encSkillId = character.equippedEncounterSkillId;
if (encSkillId != null) {
  skills.add(GameRepository.instance.getSkill(encSkillId));
}
```
skill list 改 growable;getSkill 复用同一 Map 透明加载。

### 3.4 UI 层

`lib/ui/character_panel/encounter_skill_section.dart` **新 widget**:
- `EncounterSkillSection extends ConsumerWidget` 挂 CharacterPanelScreen `_Body` 心法段与师承段之间
- `_SlotDisplay` 展示当前装备 skill(name + tier + 倍率 + type)
- `_PickerSheet` modal bottom sheet 列出所有 unlocked skill,按 tier 排序,境界不足 disabled + lock icon
- 装备 / 卸下走 EncounterService API,完成 invalidate `characterByIdProvider` + `currentEncounterProgressProvider`
- 未 unlock 任何奇遇 skill 时按钮 disabled 显示"尚无可装备奇遇招式"

### 3.5 Provider

`lib/providers/isar_provider.dart`:
- 新 `currentEncounterProgressProvider` family(无 args,走 IsarSetup.currentSlotId)→ `Future<EncounterProgress?>`

---

## 4. 配置映射(encounter_skills.yaml 35 招)

| tier | 数量 | cap | 含 ★ unlock outcome 引用招 |
|---|---|---|---|
| 1 | 5 | 1500 | (无,留扩) |
| 2 | 5 | 2000 | (无,留扩) |
| 3 | 5 | 2500 | **ting_yu_jian**(2300) / **drill_strike**(2100) |
| 4 | 5 | 3000 | **relic_blade**(2800) |
| 5 | 5 | 4000 | **water_qi**(3700) / **night_strike**(3500) |
| 6 | 5 | 5500 | **ice_break**(4500) |
| 7 | 5 | 8000 | (无,留 W14-3 后续 encounter 引用) |

**未来扩点**:tier 1-2 + tier 7 招式 30 招总暂无 encounter outcome 引用(玩家无路径 unlock),建议 W14-3 后续 encounter 数量从 15 → 25 扩 10 条覆盖。

---

## 5. 测试增量

| 文件 | +case | 覆盖 |
|---|---|---|
| `test/data/encounter_skills_yaml_test.dart` | +9(新文件) | 35 招总数 / 6 ★ id 必含 / isEncounterSkill / 7 阶覆盖 / tier cap 红线 / id 前缀 / 抽样 ting_yu_jian + ice_break / encounters.yaml unlock 引用一致性 |
| `test/services/encounter_service_test.dart` | +7 | EquipSucceeded / EquipNotUnlocked / EquipTierLocked / EquipNotFound (character / 非奇遇 skill) / canEquipEncounterSkillByTier / unequipEncounterSkill |
| `test/combat/battle_state_test.dart` | +1 | equippedEncounterSkillId 非空 → availableSkills.length==4 + 末尾 skill 是奇遇 |
| `test/data/game_repository_test.dart` | 1 修 | skillDefs.length 63 → 98(63+35) + 新增 encounterSkillIds.length==35 |
| `test/data/isar_setup_test.dart` | 1 修 | saveVersion 0.6.0 → 0.7.0 |

**590 → 607(+17 net),analyze 0 issues**。

---

## 6. 关键挂账(W14-3-B/C 待处理)

- **B - DeepSeek 补 W14-2 新 12 events 文案**:`data/events/<id>.yaml` 全 placeholder,id 列见 week14_2 closeout §4.2
- **C - dialog 节奏精修 + Codex Pen 视觉验收**:依赖 B。**新**:CharacterPanelScreen EncounterSkillSection 装备 UI 也建议视觉验收(bottom sheet 列表 + lock icon + slot 展示)
- **W14-3-A 收尾候选**:
  - tier 1-2 + tier 7 招式无 outcome 引用 → 玩家无 unlock 路径。考虑扩 encounter 引用补全
  - 战斗结束装备奇遇 skill 是否 NarrativeReader topBanner 提示(类似散功 banner)
  - 主修可有 3 招 normalAttack/powerSkill/ultimate,奇遇 slot 默认是 powerSkill 居多。战斗 AI 是否给奇遇 slot 特殊优先级?(当前默认与主修招式同 priority)
- **挂账 #34 / #30 / #28 / #31**:沿用 W13/W14-2 未变
- **奇遇 skill 装备屏的占位文案**:`encounter_skill_section.dart` 用了少量中文字串(如"奇遇招式" "选择招式" "已装备" "卸下" "尚无可装备奇遇招式"),与既有 UI 体例对齐(W14-1 EncounterDialog 也是直写),后续 Phase 5 统一迁 `lib/ui/strings.dart`

---

## 7. 工程教训

### 7.1 SkillDef 复用 vs 新类

SkillDef 已经支持 `parentTechniqueDefId: String?`(注释明确:"为空表示武学领悟独立产出")。原本以为要新 EncounterSkillDef 类 — 实际只加 nullable `tier` 字段就够了:既有 63 心法招式 tier 留 null,encounter_skills.yaml 35 招 tier 必填,`isEncounterSkill` getter 单点判断。

**取舍**:战斗系统 BattleCharacter.availableSkills: List<SkillDef> 无改动(getSkill 复用同 Map),改动量最小。

### 7.2 EncounterProgress 是账号级,equippedSkillId 是角色级

unlockedSkillIds 在 EncounterProgress(saveDataId 单行),所有角色共享 unlock 池。equipped slot 必须在 Character(每角色独立 slot),与 equippedWeaponId 并列。**两层职责分清**,避免 Phase 2+ 多角色串味。

### 7.3 红线层 unlock 引用一致性

`_enforceEncounterSkillRedLines` 在加载完成后扫 encounters.yaml 所有 unlockSkill outcome 的 skillId,**必须在 encounter skill 池里找到**,否则启动失败抛 StateError。这绑死了 W14-1/W14-2/W14-3 yaml 联结,防止后续 encounter 写 outcome 时手滑引用不存在的 skill_encounter_ id。

### 7.4 enum RealmTier 7 值与 tier 1-7 映射

```
RealmTier.xueTu (0)   ↔ tier 1
RealmTier.sanLiu(1)   ↔ tier 2
RealmTier.erLiu (2)   ↔ tier 3
...
RealmTier.wuSheng(6)  ↔ tier 7
```
`canEquip = character.realmTier.index >= skill.tier - 1`。三系锁死沿用 GDD §5.3。

### 7.5 build_runner 在 Mac 端可跑

Character 加字段 / 加 riverpod provider 后 build_runner 各跑 1s 成功生成 .g.dart。**沿用 feedback_wuxia_pen_build_runner 教训**:`*.g.dart` 全 gitignored,本地跑过即可,git 不带走;DeepSeek/Pen 端拉代码后需自跑。

### 7.6 测试 RarityTier 命名陷阱

写 test 时手滑用 `RarityTier.common`(网游词汇),实际 enum 是 `yongCai/xunChang/biaoZhun/ziYou/tianCai/jueShi`(GDD §4.1 锁死)。CLAUDE.md §4 "枚举命名锁死 GDD 词汇" 教训沿用。

---

## 8. 数据快照

- main HEAD:(本次 commit 待打)
- tag:`v0.4.0-w11` 仍是 W14-1 的(W14-2 / W14-3-A 不打新 tag,留 W14-3 整体闭环后打 `v0.5.0-w14`)
- 测试:**607/607** 全过,analyze 0 issues
- Demo 内容量:奇遇招式 35/30-50 ✅(7 阶 × 5 全覆盖)/ 武学领悟 unlock 路径 6/30-50(W14-3-B/C 补 outcome)
- 关键架构:在 W14-2 基础上 + **奇遇 skill 独立池 + Character 单 slot + 4 招战斗 + 装备 UI**(W14-3-A)
- accumulated commits:~98 commits(W14-3-A 单 commit)

---

## 9. 下次开局必读

1. `PROGRESS.md` 「当前阶段」段 + 「已完成」首条(W14-3-A)+ 「下一步」 W14-3-B/C 候选
2. 本文档 §3 实现栈 + §6 挂账(W14-3 收尾候选)
3. **W14-3-B 起手**(medium):派 DeepSeek 补 12 个 W14-2 events 文案(id 列见 week14_2 closeout §4.2)。纯协调,Mac 端无代码改动
4. **W14-3-C 起手**(medium,依赖 B):EncounterDialog 节奏精修 + 派 Codex Pen Windows 视觉验收。**新**:CharacterPanelScreen EncounterSkillSection 装备 UI 也建议视觉验收(bottom sheet + lock icon)

CLAUDE.md / GDD.md / numbers.yaml 数值层不动(W14-3-A 在 SkillDef 加 nullable tier 字段是 schema 扩展,数值未动)。Mac 端写 `lib/` `data/encounter_skills.yaml`(新顶层)`test/` `docs/handoff/`;DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`;Codex 桌面 @ Pen 写 `docs/screenshots/` + `docs/handoff/codex_*.md`。
