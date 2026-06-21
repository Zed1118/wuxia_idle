# 奇遇录（江湖见闻录·第 4 tab「奇缘」）· 设计 spec

> 2026-06-22 · P4 长期档案子项 5/6（战绩册✅ 兵器谱✅ 材料经济✅ 门派谱1.1✅ 之后）
> brainstorm 拍板：奇遇补全=查看层（非机制/内容）· 模型=剪影藏名图鉴 · 位置=baike 第4 tab「奇缘」· 详情=回看 opening 故事 · §5.7 空态保护
> 阶段：1.0 长线打磨期 · opus xhigh

## 一、目标与定位

把已际遇的奇遇做成**可回看的剪影藏名图鉴**，挂进「江湖见闻录」第 4 tab「奇缘」，与 见闻(事件流)/典故(装备)/机制(百科) 并列。让 57 个现有奇遇从「触发即消即弃」变「可回看完成度 + 重温开场故事」，贴 §三可见养成 + §10.3「先感受问题」探索精神。

**核心红利：纯展示层**——零新 Isar collection、零 saveVer bump、零迁移，全派生现有 `EncounterProgress.triggeredEncounterIds` + `GameRepository.instance.encounterDefs` + events 文案。

**Phase 0 摸排结论**（已 file:line 复核）：内容量达标（57 奇遇 = 领悟 25/奇缘 24/节庆 8，events 一一对应）；触发因子 5 维已消费；`EncounterProgress`（`encounter_progress.dart:28`）已记 triggeredEncounterIds；**奇遇零查看 UI**（仅 `encounter_dialog.dart` 触发弹窗）。本子项只补查看层（机制层失败记录联动 = 方向 B 未选；内容覆盖 frontier/innerRealm = 方向 C 未选；均不在本范围）。

## 二、数据来源（全派生 · 零埋点）

| 要素 | 派生自 | 锚点 |
|---|---|---|
| 全集（57） | `GameRepository.instance.encounterDefs`（`Map<String, EncounterDef>`） | `game_repository.dart:81` |
| 已际遇 | `EncounterProgress.triggeredEncounterIds`（`List<String>`） | `encounter_progress.dart:28` |
| 类型分组 | `EncounterDef.type`（`EncounterType` techniqueInsight/fortuneEvent）+ `festivalRequired`（节庆 = fortuneEvent 且 festivalRequired != null） | `encounter_def.dart:7` |
| 文案 | `data/events/<id>.yaml` title + opening（`EncounterEventLoader`，title String? / opening String） | `encounter_event_loader.dart:24-25` |

EncounterProgress 读取走现有 provider（plan 阶段核实，沿 `encounter_service_providers.dart` 体例）。events 文案加载走现有 loader accessor（plan 核实是 async 按 id 加载还是预载 map）。

## 三、tab 结构（剪影藏名图鉴）

新 `_EncounterTab` widget（baike feature 下，沿 `_LoreTab` 体例：ListView + 分组 + tile）。

- 顶部进度行：「已际遇 X/57」
- 3 段分组（对齐 GDD §7，全派生）：**武学领悟**（type==techniqueInsight）/ **奇缘际遇**（type==fortuneEvent && festivalRequired==null）/ **节庆**（festivalRequired!=null）。每段段标 + 「X/N 已际遇」
- 卡片：已触发=点亮（显 title，来自 events 文案；events 无 title 则降级 def id）；未触发=剪影藏名（占位「？？？」，**不显触发条件**，守 §5.7）
- 段内排序：已触发在前 or 按 def 顺序（plan 定，倾向 def 声明序保稳定）
- **§5.7 空态保护**：triggeredEncounterIds 为空时整 tab 显空态「江湖路远，奇缘未至」，**不甩 57 剪影墙**（避免玩家未感受奇遇前摊开系统）；≥1 触发后才显完整剪影图鉴

视觉约束：水墨配色（WuxiaColors）；剪影沿兵器谱 `_LockedTile` 灰化体例；`Image.asset`（若有图）必带 errorBuilder；无散写中文（全 UiStrings/EnumL10n）。

## 四、详情屏（点已触发卡 → push）

新 `encounter_detail_screen.dart`（baike feature 下）。构造 `EncounterDetailScreen({required String encounterId})`（或直传 def + event，plan 定）。内容：
- 标题（events title / 降级 def id）+ 类型标（武学领悟/奇缘际遇/节庆，走 EnumL10n 或 UiStrings）
- opening 开场文案（回看那段际遇，纯展示 events yaml）
- 剪影（未触发）点击 → snackbar「尚未际遇」（沿兵器谱 `weaponCodexNotObtained` 体例），不进详情

## 五、入口 + 路由

- 无新主菜单入口（baike 已在主菜单）
- `baike_screen.dart`：`DefaultTabController(length: 3→4)`（`baike_screen.dart:30`）+ TabBar 加 `Tab(UiStrings.baikeTabEncounter)`（44-46 区）+ TabBarView 加 `_EncounterTab()`（52-54 区）
- 新增 VISUAL_ROUTE：`encounter_codex`（baike 默认开「奇缘」tab，seed 部分 triggered + 空态各一变体可二选）+ `encounter_codex_detail`（详情屏，seed 一条 triggered 真文案）

## 六、红线与约束

- **纯展示零数值改动**：不碰伤害/经济/掉落/触发逻辑（§5.4/§5.1）
- §5.5 离线无关（纯 UI）· §5.6 文案全进 UiStrings/EnumL10n（tab 名/进度/3 段名/空态/剪影占位/类型标/snackbar）· **§5.7 守住**（剪影不剧透触发条件 + 0 触发空态保护，不写教程）
- 零 saveVer / 零迁移（纯派生）；encounter 触发逻辑（encounter_service/hook）零改动

## 七、测试

- **派生纯函数测**：3 段分组（type + festivalRequired 派生）· 进度计数（X/57 + 段内 X/N）· triggered 过滤（点亮 vs 剪影）· 空态判定
- **widget 测**：tab 点亮+剪影混态渲染 · 空态（0 触发）· 点已触发卡 push 详情 · 点剪影 snackbar · 详情屏显 opening 文案 · baike 4 tab 切换不崩
- VISUAL_ROUTE parse 往返（encounter_codex / encounter_codex_detail）
- 全量零回归 + analyze 0（主 checkout 实测；fresh worktree 先拷 libisar.dylib + build_runner）

## 八、不做（YAGNI / 已弃 / 后置）

进度预览（「还差多少触发」· §5.7 敏感 · brainstorm C 弃）；招式来源回溯（skillId→encounterId 逆索引 · 需扩字段 · P2）；记录玩家选了哪个 choice / outcome（无数据，不引入埋点）；失败记录联动（方向 B 未选）；内容覆盖补全 frontier/innerRealm（方向 C 未选）。

## 九、实装顺序提示（交 writing-plans 细化）

派生层（分组/进度纯函数 + provider）→ 文案（UiStrings tab/段/空态/类型标 + 必要 EnumL10n）→ 详情屏 → `_EncounterTab` + baike 接 4th tab → VISUAL_ROUTE 双路由 → 全量回归。每 task implementer + spec/质量两阶段 review。
