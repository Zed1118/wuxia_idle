# W15 #30 P3 后续 A · InventoryScreen 物料 Tab closeout

> 2026-05-16 / Mac · opus 4.7 / 单会话 ~1h / 零回退 / 待 commit

## 1. 一句话

InventoryScreen 加 `DefaultTabController` 2 Tab(装备 / 物料),物料 Tab 0→1 落地,Codex F #34 closeout §7 暴露的第 2 UI 缺口闭环(磨剑石 / 心血结晶 不再需要绕到强化弹层才看见)。**#34 完整闭环**(victory drop banner 1/2 上一批 + 物料 Tab 2/2 本批)。

## 2. Phase 0 grep 结论(2 维度法)

| 项 | 状态 |
|---|---|
| `ItemType` enum 5 值 | ✅ 已存在(`lib/core/domain/enums.dart:257`):moJianShi / xinXueJieJing / jingYanDan / techniqueScroll / miscMaterial |
| `InventoryItem` Isar schema | ✅ 完整(W6 落):defId(unique) + itemType + quantity + 2 timestamps |
| `EnumL10n.itemType` 映射 | ❌ **不存在**(grep 0 命中,需新建) |
| `allInventoryItemsProvider` 全表 provider | ❌ **不存在**(仅 `inventoryQuantityByType(type)` 单查 family) |
| `ItemDef` class / `items.yaml` | ❌ 完全不存在(defId 全靠生产路径 hardcode 字符串`item_mojianshi` / `item_xinxuejiejing`) |
| 实际生产路径 caller | ✅ moJianShi + xinXueJieJing 有 seed/seclusion/drop/消费链;jingYanDan / techniqueScroll / miscMaterial **0 生产路径**(纯 reserved enum) |

**两维矩阵**:`InventoryItem` schema 已落(维度 A ✓)+ 全表 provider 0 caller(维度 B ❌)→ **半完成模式**。改动小:加 provider + UI + EnumL10n + test,**0 schema 改动 + 0 saveVersion bump**。

`feedback_avoid_over_engineer_abstraction` 落地:**不抽 ItemDef class**(0 现存 + 1 caller + 5 短映射够用 + Demo 阶段 5 enum 中 3 个无生产路径,YAGNI)。

## 3. 拍板决策

- **Q1 Tab 切换**:`DefaultTabController + AppBar.bottom: TabBar + TabBarView`(标准方案)
- **Q2 物料分组方案**:按 `ItemType` enum 顺序排(`moJianShi → ... → miscMaterial`),实际 0 行的 itemType 不显示(避免 reserved enum 露出 0 quantity 占位)
- **Q3 ItemDef 抽象**:不抽(`feedback_avoid_over_engineer_abstraction`)
- **Q4 quantity==0 过滤**:物料行 quantity > 0 才显;全部过滤后整 Tab 显空态「暂无物料」
- **scope 边界**:UI Tab 重构 + provider + EnumL10n + UiStrings + test;**不动 enhance_dialog / seed / drop 路径**

## 4. 代码改动清单

3 文件 modified + 2 文件 new + 1 .g.dart regen = 6 文件:

| 文件 | 改动 |
|---|---|
| `lib/features/battle/domain/enum_localizations.dart` | 加 `itemType(ItemType t)` 5 映射 |
| `lib/ui/strings.dart` | 加 `inventoryTabEquipment / inventoryTabMaterial / inventoryMaterialEmpty` + `materialQuantity(name, qty)` helper |
| `lib/core/application/inventory_providers.dart` | 加 `@riverpod allInventoryItems` 全表 findAll + 按 enum 顺序排 |
| `lib/core/application/inventory_providers.g.dart` | `dart run build_runner build` regen,新 `allInventoryItemsProvider` 入 generated code |
| `lib/features/inventory/presentation/inventory_screen.dart` | 重构 `DefaultTabController(length: 2)` 包 Scaffold + AppBar.bottom 挂 TabBar + TabBarView(`_EquipmentTab` / `_MaterialTab`);**保留** `_List / _TierGroup / _Row` 原装备链路 0 修改;**新增** `_MaterialList / _MaterialGroup / _MaterialRow` 沿装备 ExpansionTile 体例;`_Row.onTap` close 时多 invalidate 一个 `allInventoryItemsProvider`(强化后物料数量同步刷新) |
| `test/features/battle/domain/enum_localizations_item_type_test.dart` | **新建** 6 单测:5 单映射 + 1 全覆盖红线(防新增 enum 漏映射) |
| `test/features/inventory/presentation/inventory_screen_test.dart` | 原 2 用例加 `allInventoryItemsProvider.overrideWith((ref) async => [])` 防 IsarSetup 触达;新增 **5 widget test**:物料 Tab 空 / 单行 / 2 行按 enum 顺序 / quantity==0 过滤 / TabBar 2 个 tab 渲染 + 默认装备 Tab |

## 5. 关键决策细节

### 5.1 `allInventoryItemsProvider` 排序策略

`findAll` 整表后 `sort((a, b) { final cmp = a.itemType.index.compareTo(b.itemType.index); if (cmp != 0) return cmp; return b.quantity.compareTo(a.quantity); })` —— 主排 itemType enum 顺序(让 UI 分组顺序确定),次排 quantity 倒序(同类型多行时高数量在前;Demo 同 itemType 期望只 1 行,但 schema 不限唯一只 defId unique)。

### 5.2 quantity==0 行的处理

provider 仍返回(由 `findAll` 决定),UI 层 `.where((it) => it.quantity > 0)` 过滤。理由:如果有日后"消费完归 0 不删行"模式,数据层不该静默吞,但 UI 不展示;空态判断走过滤后的 list。

### 5.3 invalidate 路径扩展

`_Row.onTap` close 后原本只 `ref.invalidate(allEquipmentsProvider)`,本批多 invalidate 一个 `allInventoryItemsProvider`。理由:强化成功 / 失败都会改 InventoryItem.quantity(扣磨剑石 / 加心血结晶),Tab 切回物料时应看到最新数值。即使当前 Tab 是装备,下次切到物料也是新数据。

### 5.4 TabBarView 与 lazy build

新 widget test 默认 surfaceSize=1280×720 装得下 TabBar + TabBarView。物料 Tab 不在视口时 PageView 会延迟构建,但部分 Flutter 实现仍会预渲染相邻 tab,因此**所有现有 widget test 都加了 `allInventoryItemsProvider.overrideWith((ref) async => [])`** 防止 `IsarSetup.instance` 触达(test 环境无真 Isar)。

### 5.5 reserved enum 不显示

`jingYanDan / techniqueScroll` 当前 0 生产路径,`miscMaterial` 是 drop 兜底但 0 实际 defId 落入。即使日后接入也无所谓 — 物料 Tab 走 `groups.keys` 按表数据动态决定显示哪些 group,不预设 enum 全列。**避免 UI 暴露未实装功能**(GDD §10 反主流不做清单的"不写教程弹窗"延伸:未解锁系统的菜单按钮直接隐藏)。

## 6. 测试与验证

| 阶段 | 命令 | 结果 |
|---|---|---|
| 新 test | `flutter test test/features/battle/domain/enum_localizations_item_type_test.dart test/features/inventory/presentation/inventory_screen_test.dart` | 13/13 |
| 全仓回归 | `flutter test` | **701/701** 全过(原 690 + 11 新增) |
| analyze | `flutter analyze` | **0 issues** |

## 7. 销账

- ✅ PROGRESS §65 下一步候选 A · InventoryScreen 物料 Tab
- ✅ Codex F #34 closeout §7 暴露 UI 缺口 2/2(物料 Tab,完整闭环)
- ✅ PROGRESS 挂账 #34 完全销账(已在 P3 后续 A victory dialog 1/2 落地,本批 2/2 完成,可改 ~~)

## 8. 下次开局必读

### 8.1 状态快照

- 待 commit(feat/test/docs)
- 701/701 + analyze 0 issues
- 物料 Tab 0→1 落地,Codex F #34 完整闭环
- `_EquipmentTab` / `_MaterialTab` 双 Consumer Tab,默认装备 Tab
- jingYanDan / techniqueScroll / miscMaterial 5 enum 中 3 个 0 生产路径,UI 不显示
- Codex E 派单(victory dialog 视觉验收)仍异步等 closeout 回

### 8.2 下波 4 候选(W15 #30 P3 后续 A.3 物料 Tab 销账后)

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| B | §12.1 #7 三流派 extra_effect 数值拍板 | sonnet | 30-60min | 老挂账,讨论型 |
| C | §12.1 #10 师承遗物规则拍板 | sonnet | 30-60min | 老挂账,讨论型 |
| D | mainline / tower victory 写回 widget integration test | sonnet | 1-2h | 本批新 dialog 单元 test 已覆盖,e2e 收口可选 |
| E | 主线 victory dialog Codex 视觉验收(派单已发) | Codex Pen | - | **异步监控**,本会话期间若 closeout 回则销账候选 E |
| F | 主线 victory dialog + 物料 Tab Codex 视觉验收(本批新 UI 拿真硬截图) | Codex Pen | - | 派单(并入候选 E 或单独) |

### 8.3 硬约束沿用

- `feedback_phase0_grep_two_axes`:本批 schema 半完成模式判定准确(0 schema 改),后续 cross-system task 继续两维度法
- `feedback_avoid_over_engineer_abstraction`:不抽 ItemDef class 是合理决定,Demo 物料 5 enum 中 3 个无生产路径,过早抽抽象会暴露未实装功能
- `feedback_red_line_test_semantics`:本批红线测试用"所有 ItemType 都有非空映射"(EnumL10n 全覆盖)+ "默认 Tab 是装备" + "quantity==0 不显示"等约束语义,不写瞬时数值
- `feedback_model_selection`:本批用 opus(用户指定),原 closeout §8.2 估 sonnet 2-3h,实际 opus ~1h 完工 — 改动量比预估小是 Phase 0 grep 两维度精准判定的红利

## 9. 经验沉淀

无新教训。本批是 `feedback_phase0_grep_two_axes` + `feedback_avoid_over_engineer_abstraction` 两条 memory 落地的标准实践:Phase 0 grep 暴露半完成模式 → 改动小 → 不抽过早抽象 → 1h 闭环。
