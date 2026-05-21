# P1.1 候选 4 A4 开锋 build 内容扩 · Phase 0 audit

> 2026-05-21 主对话 Mac+Opus xhigh ~25min。本 audit 在 HEAD `8b64390`(候选 1+2+3 收口后)起跑。
> 输入:`p1_1_a3_resonance_closeout_2026-05-21.md` §7 候选 4(35 件装备开锋方案 audit + 可能需要 grill 设计)。
> 输出:本 audit doc + grill 拍板 → 后续 spec(若需) → 实装。

## §1 4 维 grep audit 结论一句话

**架构 0 改动,代码 0 改动,纯 yaml 内容扩。** 开锋系统的 schema / service / UI / test 全部已在,唯一缺的是 `equipment.yaml` 35 件 `specialSkillCandidates` 字段(0 件配置)。 sleeping_yaml 占位格子典型(memory `feedback_phase0_grep_two_axes` A.5 子格活实例)。

## §2 4 维 grep 详条

### §2.1 A 维 schema(全已落)

| 文件 | 字段/类 | 状态 |
|---|---|---|
| `lib/data/defs/equipment_def.dart:28` | `final List<String> specialSkillCandidates` | ✅ 已存,默认 `const []` |
| `equipment_def.dart:83-86` | `fromYaml` 已读 `y['specialSkillCandidates']` | ✅ 默认空 list 兜底 |
| `lib/core/domain/forging_slot.dart:20` | `String? specialSkillId` (Isar 持久化) | ✅ 已存 |
| `lib/core/domain/enums.dart:90-95` | `enum ForgingSlotType { ..., specialSkill }` | ✅ 已存 |
| `lib/data/numbers_config.dart:544-596` | `ForgingConfig` + `ForgingSlotConfig.fromYaml` | ✅ 完整 |
| `data/numbers.yaml:550-573` | 3 槽配置(+10/+15/+19 unlock,slot 3 仅 `specialSkill`) | ✅ 已落 |
| `lib/features/battle/domain/enum_localizations.dart:153` | `ForgingSlotType.specialSkill => '专属技能'` | ✅ 中文已落 |

### §2.2 B 维 caller(全已落)

| 文件 | 用途 | 状态 |
|---|---|---|
| `lib/features/equipment/application/forging_service.dart:76-128` | `forge` 含 4 道 specialSkill 校验 | ✅ missing/noCandidates/invalidId/OK 路径全覆盖 |
| `forging_service.dart:130-136` | `persistResult` Isar writeTxn | ✅ 已落 |
| `forging_service.dart:49-68` | `availableTypesForSlot` 槽 2 互斥过滤 | ✅ 已落 |
| `lib/features/battle/domain/derived_stats.dart:196-225` | `_forgingBonusPct` 消费 attack/speed | ✅ 进派生属性 |
| `lib/features/equipment/application/equipment_factory.dart:22` | 自动填齐 3 个空槽 | ✅ 已落 |
| `lib/features/debug/application/phase2_seed_service.dart:467` | debug seed 已可种 forging 槽 | ✅ 已落 |

### §2.3 C 维 邻近目录(全已落)

- `lib/features/equipment/application/forging_service.dart` (137 行)
- `lib/features/equipment/presentation/forging_panel.dart` (312 行)
- `test/features/equipment/application/forging_service_test.dart`
- `test/features/equipment/presentation/forging_panel_test.dart`

### §2.4 D 维 UI(全已落)

- `forging_panel.dart` 3 槽卡片完整渲染:未解锁灰显 / 已解锁未开锋词条 list / 已开锋显「+X%」灰显
- `forging_panel.dart:161-165` specialSkill 候选空兜底「该装备无专属技能」**已实装**
- `forging_panel.dart:294-296` 已开锋时显示 `specialSkillId` 文案
- 二次确认 dialog 已落,specialSkill 二次确认走同路径

### §2.5 A.5 子格(yaml-unread,核心缺口)

- `grep -c "specialSkillCandidates" data/equipment.yaml` = **0**
- 35 件装备全部 yaml 未配 → Dart 读为空 list → 槽 3 +19 解锁但 UI 显示「无专属技能」
- **唯一缺口 = 内容数据**

## §3 设计待决项(grill 候选)

### §3.1 G1: armor / accessory 是否参与 specialSkill ?

GDD §6.5 三槽 build 设计语义是**武器导向**(specialSkill = 武器招式)。当前 35 件分布:
- weapon × 21(7 阶 × 3 流派)有 `schoolBias`
- armor × 7 + accessory × 7 = 14 件 `schoolBias: null`(无流派)

**选项**:
- **G1.a 不参与(推荐)** ⭐:armor / accessory 留空 → 槽 3 +19 时 UI 显「无专属技能」兜底(已实装)。语义清晰、工作量小。
- **G1.b 参与但跨流派**:玩家可选 3 流派任一招(`specialSkillCandidates` 列 ~9 招)。给玩家更多 build 自由度,但语义弱(护甲为何配剑法?)。
- **G1.c 全新类型"内功外化"招**:skills.yaml 新增 14 招"防御/辅助"型(护甲 +反震 / 配饰 +回复 等)。工作量大,Demo 不必。

**推荐 G1.a**:armor / accessory 走 attack/speed/lifesteal/pierce 槽 1+2 就够,槽 3 留空。

### §3.2 G2: weapon 21 件 candidates 数 N ?

**选项**:
- **G2.a N=1**:21 招,每件 1 个固定专属。玩家无选择,但读体例最干净。
- **G2.b N=2(推荐)** ⭐:42 招,每件 2 个候选(skill + ult)。玩家在 +19 时可选 1 个,有微决策但不烦。
- **G2.c N=3**:63 招,每件 skill/ult/basic 全列。选择爆炸,无效。
- **G2.d 同阶全流派 9 招池**:每件给同阶 3 流派 × 3 type 全候选。打破流派锁,有违 §5.3。**否定**。

**推荐 G2.b**:每件 weapon 配 2 个同流派同阶招(`skill` + `ult`),让玩家在中规模(skill)/大招(ult)间二选一。

### §3.3 G3: 复用 skills.yaml vs 新增专属招?

**选项**:
- **G3.a 纯复用 skills.yaml**(推荐) ⭐:21 件 × 2 = 42 个 candidates 全部从 skills.yaml 已有 63 通用招中映射。**0 新增 skills.yaml**,纯 equipment.yaml 改动。工作量 30-45min。
- **G3.b 新增 21-42 件专属招**:命名带装备名,如 `skill_signature_xunchang_tie_jian_chu_jian` 出剑式。需要 skills.yaml +21-42 招 + 数值平衡 + 文案。工作量 2-3h。
- **G3.c 混合(weapon 专属 / armor 通用)**:G3.b 但 armor/accessory 复用。G1.a 已决"不参与"则等同 G3.b。

**推荐 G3.a**:复用现成,先打通 build 体验;1.0 阶段美术 + 内容产线启动后再升级 G3.b。

### §3.4 G4: lore yaml `skill_signature` 段是否同步?

`data/lore/*.yaml` 35 个,候选 4 未确认是否要同步加「专属技能名」段(让 UI 显示典故里招式名而非通用 skill id)。

**选项**:
- **G4.a 不动 lore**(推荐) ⭐:UI 显示 specialSkillId 直接走 enum 本地化 + skills.yaml `name`(若 skills.yaml 没 name 字段则用 id 本身)。 G3.a 复用现成 skills 已有 name,够用。
- **G4.b lore yaml 加 `signature_skill: <skill_id> | <局部别名>` 段**:UI 在该装备开锋时显示典故风格招式名(如「出剑式」而非 `skill_lingqiao_jichu_skill`)。沉浸感 +,工作量 +30min。

**推荐 G4.a**:1.0 阶段再升,Demo 不必。

### §3.5 G5: 数值红线复查

- numbers.yaml `forging.slots[3].bonus_value.specialSkill: 1` → 解锁词条而非数值加成,**无数值红线问题**
- skills.yaml 复用现成招,数值早 W18 平衡过,**无 §5.4 红线越界**
- 共鸣度 joint_skill(4500 mult)候选 3 已收口,与 specialSkill 槽**正交**(joint_skill 独立通道,不入 forging slot 3)

**G5 无 grill,仅点检确认**。

## §4 工作量重估(audit 后)

| 方案 | 设计 grill | 实装 | 测试 | closeout | 总 |
|---|---|---|---|---|---|
| **乐观(G1.a+G2.b+G3.a+G4.a)** ⭐ | 10-15min | 30-45min | 10-15min | 15min | **65-90 min** |
| 中庸(G1.a+G2.b+G3.c) | 20min | 1.5-2h | 30min | 20min | ~2.5-3h |
| 完整(G1.a+G2.b+G3.b+G4.b) | 30min | 2.5-3.5h | 30-45min | 30min | ~4-5h |

**对比 closeout §7 候选 4 原估 2-3h**:乐观路径 < 1.5h 显著低于原估,因架构 0 改动 + skills.yaml 已齐。

## §5 推荐路径 + Mapping 草案

**走乐观(G1.a+G2.b+G3.a+G4.a)**,Mapping 草案:

```yaml
# 每件 weapon 的 specialSkillCandidates = 同流派同阶的 skill + ult
- id: weapon_xunchang_tie_jian       # 寻常货 · 剑 · 灵巧
  specialSkillCandidates: [skill_lingqiao_jichu_skill, skill_lingqiao_jichu_ult]
- id: weapon_xunchang_zhe_dao        # 寻常货 · 刀 · 刚猛
  specialSkillCandidates: [skill_gangmeng_jichu_skill, skill_gangmeng_jichu_ult]
- id: weapon_xunchang_ruan_bian      # 寻常货 · 鞭 · 阴柔
  specialSkillCandidates: [skill_yinrou_jichu_skill, skill_yinrou_jichu_ult]
# ... 7 阶 × 3 流派 = 21 件 weapon 全按此规则
# armor × 7 + accessory × 7 = 14 件 specialSkillCandidates 留空(yaml 不填)
```

**21 件 mapping 完整可机械推导**(阶 + 流派 → skill id 后缀),无需手工设计。

## §6 测试方案(乐观路径)

1. **yaml 加载 round-trip**:`flutter test test/data/equipment_def_test.dart`(若有)+ 新加 `specialSkillCandidates` round-trip 断言(2 case:weapon 已配/armor 留空)
2. **forging_service forge specialSkill 成功路径**:已有 test 覆盖,但需新加 case 用真 weapon yaml(`weapon_xunchang_tie_jian` + `skill_lingqiao_jichu_skill`)走通完整 forge
3. **forging_panel 选项显示**:已有 test 覆盖空状态,新加 1 case 用 `weapon_xunchang_tie_jian` 验证 2 个候选 显示

**预计 test +3-5 case**(已有 ~1170 → ~1173-1175)。

## §7 决策请求

请拍板 G1-G4 4 个 grill point(推荐路径 G1.a+G2.b+G3.a+G4.a),或提出其他设计偏好。

**若全部走推荐**:可直接进入实装,无需另起 spec doc(scope 小、机械映射、风险低)。
**若任一 grill 改方案**:重起 spec doc(尤其 G3.b/G4.b 工作量大,需 phase 切分)。

## §8 references

- `docs/handoff/p1_1_a3_resonance_closeout_2026-05-21.md` §7 候选表
- `GDD.md` §6.5 开锋(3 槽 build)+ §5.3 三系锁死 + §5.4 数值红线
- `data/numbers.yaml:549-573` forging 配置
- `data/equipment.yaml` 35 件 fixture
- `data/skills.yaml` 64 招(63 通用 + 1 joint)
- `lib/data/defs/equipment_def.dart:26-28,83-86` specialSkillCandidates schema
- `lib/features/equipment/application/forging_service.dart` 137 行 service
- `lib/features/equipment/presentation/forging_panel.dart` 312 行 UI
- memory `feedback_phase0_grep_two_axes` A.5 子格教训(本 audit 又一活实例)
