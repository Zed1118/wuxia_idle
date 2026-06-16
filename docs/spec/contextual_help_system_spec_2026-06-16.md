# 上下文帮助系统 · Spec(2026-06-16)

> 源:桌面《上下文帮助系统_修订版_对齐现状.md》。本 spec 是实装契约。
> 范围(用户拍板):阶段一~三扎实 + 阶段四留 handoff。纪律:TDD + 分阶段 commit/push。

## 设计锚(防双真相源)

- **短释义/标签**:全进 `UiStrings`(既有 sink,§5.6 合法)。`HelpCatalog` 只存结构,不抄中文。
- **step/category**:从既有 `CodexIndex` / `CodexCategory.step` 派生,不重新声明。
- **导航**:复用既有 `CodexEntryDetail(entry:)` + `codexListItemsProvider` + `currentTutorialStepProvider`。

## 架构(分层)

- `GlossaryLabel`(shared/widgets/wuxia_ui)**不改签名**——叶子层不可依赖 features。
- 新建 `lib/features/help/`:
  - `domain/help_topic.dart`:`HelpTopic` enum + `HelpBinding(label, shortText, codexEntryId)` + `HelpCatalog`(topic→binding,label/shortText 引用 UiStrings 常量)。
  - `presentation/glossary_topic_label.dart`:`GlossaryTopicLabel({topic, style})` 薄包装,解析 binding 委托 shared `GlossaryLabel`。纯 Stateless,无 provider 依赖,只出 tooltip。
  - `presentation/context_help_button.dart`:`ContextHelpButton({topic})` ConsumerWidget,页面级 `?`。codexEntryId!=null 时 watch codexListItems+tutorialStep 判解锁:解锁→点击 `Navigator.push(CodexEntryDetail)`;未解锁→灰显「阅历未至」;codexEntryId==null→仅 tooltip。

## codexEntryId 取值(必须命中 CodexIndex 19 条登记 id)

realm / resonance / techniques_and_styles / three_styles_detail / retreat / master_disciple / encounter_system / combat_advanced / equipment_tiers / strengthening / weapon_forging / lost_techniques + 7 lore。

## 阶段一 · 薄基础设施(本批)

1. `HelpTopic` enum(先覆盖角色/装备/心法批所需）+ `HelpBinding` + `HelpCatalog`。
2. `GlossaryTopicLabel` + `ContextHelpButton`。
3. UiStrings 补缺失 glossary 常量(装备侧:强化/开锋/心血结晶/品阶/师承遗物;心法侧:主修/辅修/流派/相生)。
4. 测:
   - `help_catalog_test`:每 HelpTopic 有 binding;每非空 codexEntryId 命中 `CodexIndex.byId`(**防 drift 核心测**)。
   - `glossary_topic_label_test`:渲染 label + `?` marker + tooltip 含 shortText。
   - `context_help_button_test`:解锁→可跳;未解锁→灰显;codexEntryId==null→仅 tooltip。

## 阶段二 · 核心页接入

- 角色面板:11 个现有 GlossaryLabel 不动(已工作,行为不变,留原样以零风险);新增页面级 `ContextHelpButton`(realm/attributes)。
  - (注:迁现有到 GlossaryTopicLabel 收益低风险高,本批跳过,见阶段四 backlog。)
- 装备详情/仓库:品阶/强化/开锋/心血结晶/师承遗物 接 `GlossaryTopicLabel`;页面级 `ContextHelpButton(equipment_tiers/strengthening/weapon_forging)`。
- 心法页:主修/辅修/流派/相生 接 `GlossaryTopicLabel`;页面级 `ContextHelpButton(techniques_and_styles/three_styles_detail)`。

## 阶段三 · 战斗+成长

- 战斗(破招/蓄势/内伤/克制/大招 → combat_advanced)、闭关(时辰/节气/领悟点 → retreat)、主线爬塔(周目/Boss/掉落)。各补 UiStrings + 接入 + 页面级 ?。

## 阶段四(留 handoff,不做)

- 后期系统(奇遇/江湖恩怨/心魔/帮派/轻功/群战/飞升/真传位)+ step gating 灰显。
- 「首次遇到金色提示点」净新发现感基建(单列 scope)。
- 角色面板现有 11 处迁 GlossaryTopicLabel(纯收口,可选)。

## 验收

每阶段:`flutter analyze` 0 + 全量测零回归 + UI 屏 CLI 自截视觉验收。合 main 前全量(非 scoped)。
