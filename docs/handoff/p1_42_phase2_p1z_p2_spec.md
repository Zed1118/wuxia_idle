# P1 #42 Phase 2 §10 P1.z P2 扩段 spec · 11 lore 入库

> 2026-05-18,Mac + Opus 4.7 起草。**接** Phase 0 reality check(`p1_42_phase2_p1z_p2_reality_check_2026-05-18.md`)+ 用户拍板 Q1-Q3。
> P1.z 主线收口后 P2 滚动扩段:**11 lore 全入 + CodexIndex 8→19 entry + CodexCategory 扩 `lore` 值**。

## 0. 必读清单(开工前)

1. **本 spec**(本文)
2. **Phase 0 reality check**(`p1_42_phase2_p1z_p2_reality_check_2026-05-18.md` 193 行,含 18 md 字数/主题/方案对比/3 拍板项)
3. **P1.z 主 spec**(`p1_42_phase2_p1z_codex_spec.md` §12 方案 B 调整)+ **P1.z closeout**(`p1_42_phase2_p1z_codex_closeout_2026-05-18.md`)
4. **现有 CodexCategory enum**(`lib/features/codex/domain/codex_category.dart` 53 行)
5. **现有 CodexTab UI**(`lib/features/codex/presentation/codex_tab.dart` 176 行)
6. **现有 CodexIndex.entries**(`lib/features/codex/domain/codex_index.dart` 52 行)
7. memory:`feedback_listview_widget_test_viewport` / `feedback_phase0_grep_two_axes` / `feedback_red_line_test_semantics` / `feedback_avoid_over_engineer_abstraction` / `feedback_opus_xhigh_interactive_duration`

## 1. 任务一句话

`CodexCategory` enum 加 `lore` 值(step 改 nullable)+ `CodexIndex.entries` 扩 8→19 条(A 组 4 挂现有机制 category 作补充阅读,B 组 7 全挂 lore)+ CodexTab UI 加段分隔(8 档机制段 + 江湖背景段)+ codexUnlockedCount 仅算 8 档机制段 + 测试更新(含 viewport 扩到 800x2000)。

## 2. 用户拍板决议(P2 Q1-Q3)

| # | 拍板项 | 决议 |
|---|---|---|
| Q1 | 入库范围 | **11 lore 全入**(A 组 4 + B 组 7) |
| Q2 | lore 段 UI 排序 | **按 CodexIndex 登记顺序**(spec 里手动排,代码 0 排序逻辑) |
| Q3 | lore 段 gating | **不 gate**(自由查阅,跟 GDD §10.2「永久可查」定位一致) |

## 3. 实装拆分

### Phase 1 · enum + entries(基础层)

#### 1.1 `lib/features/codex/domain/codex_category.dart`

```dart
enum CodexCategory {
  combat,        // 档 1
  enhancement,   // 档 2
  techniques,    // 档 3
  schoolCounter, // 档 4
  seclusion,     // 档 5
  lineage,       // 档 6
  encounter,     // 档 7
  advanced,      // 档 8
  lore,          // 江湖背景(无 tutorialStep,永久可查)
}

extension CodexCategoryStep on CodexCategory {
  /// 8 档机制返回 1-8;lore 返回 null(永久可查不 gate)。
  int? get step {
    switch (this) {
      case CodexCategory.combat: return 1;
      case CodexCategory.enhancement: return 2;
      case CodexCategory.techniques: return 3;
      case CodexCategory.schoolCounter: return 4;
      case CodexCategory.seclusion: return 5;
      case CodexCategory.lineage: return 6;
      case CodexCategory.encounter: return 7;
      case CodexCategory.advanced: return 8;
      case CodexCategory.lore: return null;
    }
  }

  bool get isMechanic => step != null;
  bool get isLore => this == CodexCategory.lore;
}
```

#### 1.2 `lib/features/codex/domain/codex_entry.dart`

`final int step` → `final int? step`(改 nullable)。
所有 step 引用点过 grep:CodexEntry 构造 / fromMd / step getter。lore 条目 step = null。

#### 1.3 `lib/features/codex/domain/codex_index.dart`

`CodexIndexEntry.step` getter 改 `int? get step => category.step;`。

`CodexIndex.entries` 8→19 条(顺序固定,Q2 拍板按登记顺序):

```dart
static const List<CodexIndexEntry> entries = [
  // 8 档机制(P1.z 已入,顺序 = step 升序)
  CodexIndexEntry(id: 'realm', category: CodexCategory.combat),                     // 档 1
  CodexIndexEntry(id: 'resonance', category: CodexCategory.enhancement),            // 档 2
  CodexIndexEntry(id: 'techniques_and_styles', category: CodexCategory.techniques), // 档 3
  CodexIndexEntry(id: 'three_styles_detail', category: CodexCategory.schoolCounter),// 档 4
  CodexIndexEntry(id: 'retreat', category: CodexCategory.seclusion),                // 档 5
  CodexIndexEntry(id: 'master_disciple', category: CodexCategory.lineage),          // 档 6
  CodexIndexEntry(id: 'encounter_system', category: CodexCategory.encounter),       // 档 7
  CodexIndexEntry(id: 'combat_advanced', category: CodexCategory.advanced),         // 档 8

  // A 组 · 与机制档相关的补充阅读(挂现有 category)
  CodexIndexEntry(id: 'equipment_tiers', category: CodexCategory.combat),           // 档 1 装备细节
  CodexIndexEntry(id: 'strengthening', category: CodexCategory.enhancement),        // 档 2 强化扩展
  CodexIndexEntry(id: 'weapon_forging', category: CodexCategory.enhancement),       // 档 2 铸造流派
  CodexIndexEntry(id: 'lost_techniques', category: CodexCategory.techniques),       // 档 3 失传神功

  // B 组 · 江湖背景(挂 lore,按主题密度手动排:战斗→规则→门派→历史)
  CodexIndexEntry(id: 'hidden_weapons', category: CodexCategory.lore),              // 战斗背景
  CodexIndexEntry(id: 'battle_taboos', category: CodexCategory.lore),               // 武斗禁忌
  CodexIndexEntry(id: 'jianghu_medicine', category: CodexCategory.lore),            // 治伤背景
  CodexIndexEntry(id: 'jianghu_rules', category: CodexCategory.lore),               // 江湖规矩
  CodexIndexEntry(id: 'jianghu_ranks', category: CodexCategory.lore),               // 民间九流
  CodexIndexEntry(id: 'major_sects', category: CodexCategory.lore),                 // 三大派
  CodexIndexEntry(id: 'famous_battles', category: CodexCategory.lore),              // 历史名战
];
```

**注释口径调整**:文件头 docstring「首批 8 条对齐 §10.1 8 档」改为「19 条:8 档机制 + 4 机制补充阅读 + 7 江湖背景 lore」。

### Phase 2 · Application + UI 分组

#### 2.1 `lib/features/codex/application/codex_providers.dart`

**`codexUnlockedCountProvider` 仅算 8 档机制段(lore 不算 unlocked count)**:

```dart
@riverpod
Future<int> codexUnlockedCount(Ref ref) async {
  final items = ref.watch(codexListItemsProvider);
  final step = await ref.watch(currentTutorialStepProvider.future);
  // lore 永远 unlocked 但不计入"已解锁 N/8"分子分母(只算 8 档机制)。
  return items.where((it) {
    final s = it.indexEntry.step;
    return s != null && s <= step;
  }).length;
}
```

**`codexMechanicTotal` 新增 getter / provider**(分母,固定 8):
```dart
// 简单起见 inline 在 UI / 或 provider 里 hard-code 8。
// 推荐:用 CodexIndex.entries.where((e) => e.category.isMechanic).length 动态算,避免改 enum 后忘改。
```

#### 2.2 `lib/features/codex/presentation/codex_tab.dart`

**改造点**:

1. **headerText 改口径**:`UiStrings.codexUnlockedHint(unlocked, items.length)`
   → `UiStrings.codexUnlockedHint(unlocked, mechanicTotal)`(分母从 19 变 8)

2. **ListView 加段分隔**:
   - 上半段:8 档机制(step 升序,沿用现有 _CodexListTile)
   - SectionHeader「江湖背景」(新建 inline 子 widget,不抽 shared/,memory feedback_avoid_over_engineer_abstraction)
   - 下半段:11 lore(按 entries 登记顺序,不 gate,永远 unlocked tile)

3. **_CodexListTile 解锁判断改**:`item.indexEntry.step` 为 null(lore)时永远 unlocked:
```dart
final s = item.indexEntry.step;
final unlockedItem = (s == null || s <= step) && item.isLoaded;
```

**伪代码骨架**(itemBuilder 逻辑):
```dart
// items 按 entries 登记顺序;先 8 档机制 + 后 11 lore(entries 顺序已对齐)。
// index 0: headerText(unlocked N/8)
// index 1..8: 8 档机制 tile
// index 9: SectionHeader「江湖背景」
// index 10..20: 11 lore tile
final mechanicCount = items.where((it) => it.indexEntry.category.isMechanic).length; // 8
final loreCount = items.length - mechanicCount;                                       // 11
itemCount: items.length + 2;  // +1 headerText + 1 SectionHeader
```

**SectionHeader 实现**(inline,不抽 shared/):
```dart
class _LoreSectionHeader extends StatelessWidget {
  const _LoreSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        UiStrings.codexLoreSectionTitle,  // 「江湖背景」新增 const
        style: const TextStyle(
          color: WuxiaColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
```

#### 2.3 `lib/shared/strings.dart`

新增 1 const:
```dart
static const String codexLoreSectionTitle = '江湖背景';
```

`codexUnlockedHint` 分母改 8(若是字符串模板含变量则不动,UI 端传 mechanicTotal=8 即可)。

### Phase 3 · 测试更新

#### 3.1 现有测试 grep 改

`test/features/codex/` 下所有 `step` 断言全过一遍:
- 改 nullable 后,期望 step=null 的 lore 条目断言不能写 `expect(step, isPositive)`,改 `expect(step, isNull)` 或 `expect(category.isLore, isTrue)`
- 期望 8 档断言改语义化(memory feedback_red_line_test_semantics):不写"entries.length == 8"写"机制条目数 == 8"(`entries.where((e) => e.category.isMechanic).length == 8`)

#### 3.2 新增测试

| 测试 | 目的 |
|---|---|
| `CodexCategory.lore.step` returns null | enum step nullable 锚定 |
| `CodexIndex.entries.where(isLore).length == 7` | B 组 7 条全登记(语义化,不写具体 id 列表) |
| `CodexIndex.entries.where(isMechanic).length == 8` | 8 档机制不变(语义化) |
| `CodexIndex.entries.length == 19` | 总数(可接受具体数,GDD §10.1 8 + 4 补充 + 7 lore 都是设计锚) |
| CodexTab widget test:11 lore tile 永远 unlocked(不管 currentStep) | gating 豁免 |
| CodexTab widget test:headerText 分母 = 8(不算 lore) | unlockedCount 口径 |
| CodexTab widget test:SectionHeader「江湖背景」存在且位于第 9 个 tile 后 | UI 分段渲染 |
| `_enforceCodexRedLines` 11 lore md 全过 ≤ 550 | 已验证(reality check §1),冗余兜底测试 |

#### 3.3 widget test viewport 必扩

**P1.z CodexTab widget test 默认 800x600 viewport 装不下 19 + headerText + SectionHeader ≈ 21 个虚拟 item**(memory `feedback_listview_widget_test_viewport` 本会话沉淀)。

**改造**:
```dart
testWidgets('CodexTab 19 条全部 render', (tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // ... build + pump + expectations
});
```

或用 `tester.scrollUntilVisible` 滚动验底部 tile —— 二选一,推荐 setSurfaceSize 简洁。

## 4. Phase 0 摸底回顾(reality check 已落)

| 项 | 现状 | 影响 |
|---|---|---|
| 18 md 字数 | 全过 ≤ 550 红线 | `_enforceCodexRedLines` 自动校验,P2 入库 0 触发 |
| 11 lore md | 2026-05-10 已落(W18-A3 lore 时期) | **0 文案工程量**,DeepSeek 端不需重写 |
| step 使用点 | 6 文件(codex_entry / codex_index / codex_providers / codex_tab + 2 codegen) | 改 nullable 全过 grep,codegen 文件 build_runner 重生 |
| CodexLoader graceful | 缺 md 跳过 + warn | P2 入库后若用户删某 md 不爆 test |
| Isar widget test | 用 `test()` 不 `testWidgets()` | 本批 CodexTab UI 测试不涉 Isar writeTxn,继续用 testWidgets 安全 |

## 5. 红线与硬约束

- **GDD §5.6 不硬编码**:UiStrings 新增 const(`codexLoreSectionTitle = '江湖背景'`)走 strings,不在 widget 内联中文
- **GDD §10.2 永久可查**:lore 段 0 gating(Q3 拍板)
- **memory feedback_red_line_test_semantics**:测试断言写语义(`where(isMechanic).length == 8` / `where(isLore).length == 7`)不写"entries.first.id == 'realm'"硬绑列表顺序的断言
- **memory feedback_listview_widget_test_viewport**:CodexTab widget test 必 setSurfaceSize 800x2000
- **memory feedback_avoid_over_engineer_abstraction**:`_LoreSectionHeader` inline 在 codex_tab.dart,不抽 shared/(仅 CodexTab 用)
- **不动 GDD.md / CLAUDE.md / numbers.yaml / WINDOWS_DEEPSEEK_GUIDE.md / data/narratives/**(Mac+Opus 红线)
- **不改 P1.x / P1.y 既存代码**(P2 仅扩 P1.z 收尾,前两块已收口)

## 6. 自审清单(交付前)

### 代码层
- [ ] `CodexCategory` 加 `lore` 值 + isMechanic/isLore 派生
- [ ] `CodexCategoryStep.step` 改 `int?` 返回(lore null)
- [ ] `CodexEntry.step` / `CodexIndexEntry.step` 全改 `int?`
- [ ] `CodexIndex.entries` 8→19 条(顺序按 spec §3.1.3)
- [ ] `codexUnlockedCountProvider` 仅算 isMechanic 条目
- [ ] `CodexTab` 加 SectionHeader + lore 段永远 unlocked + headerText 分母 8
- [ ] `UiStrings.codexLoreSectionTitle = '江湖背景'`

### 测试层
- [ ] 改:所有 step 断言适配 nullable(lore null / 机制 1-8)
- [ ] 改:所有"entries.length == 8"断言改语义化(`where(isMechanic).length == 8`)
- [ ] 新增:CodexCategory.lore.step == null
- [ ] 新增:CodexIndex 各 category 分组数(8 机制 / 7 lore / 总 19)
- [ ] 新增:CodexTab 11 lore 永远 unlocked(无视 currentStep)
- [ ] 新增:CodexTab headerText 分母 8
- [ ] 新增:CodexTab SectionHeader 渲染位置
- [ ] **viewport setSurfaceSize 800x2000 + addTearDown**(所有 CodexTab widget test 加)

### 工程层
- [ ] `dart run build_runner build --delete-conflicting-outputs`(codex_providers.g.dart 重生)
- [ ] `flutter analyze` 0 issues
- [ ] `flutter test` 1076 baseline + N 新增,0 回归
- [ ] commit 中文动宾:`[feat] P1.z P2 江湖见闻录扩段 11 lore 入库`
- [ ] push origin/main
- [ ] closeout 段挂回 P1.z 主 closeout 末段

## 7. 工程量估算

| Phase | 内容 | 模型 | sonnet 预估 | 备注 |
|---|---|---|---|---|
| Phase 1 | enum + entries(基础层) | sonnet | 20-30min | 改 nullable 波及 6 文件 grep |
| Phase 2 | Application + UI | sonnet | 30-45min | UI 分组 + provider 口径 + strings 加 const |
| Phase 3 | 测试更新 | sonnet | 30-45min | 改旧断言 + 新增 ~8 case + viewport |
| 工程 | build_runner + analyze + test + commit | sonnet | 10-15min | |
| **总** | | sonnet | **1.5-2.25h** | reality check §7 的 1-2h 区间 |

**模型建议**:sonnet 起手,若 Phase 3 测试 case 写得复杂或 nullable 改动 break 多个 test 可临时升 opus。按 `feedback_opus_xhigh_interactive_duration` 实测锚点,opus xhigh 比 sonnet 快 1.7-5×,本批属"批量改 step + 加 UI 段"非算法/schema,sonnet 即可。

## 8. 反例

❌ 把 lore step 硬设成 99 / 0 / -1(应该 null,语义最清晰;否则 ` <= step` 判断要特殊处理整数边界)
❌ lore 段做 gating(违反 Q3 拍板)
❌ `codexUnlockedCount` 把 lore 算入分子分母("19 中已解锁 N"会让玩家以为 lore 也是教学档)
❌ ListView 排序逻辑加复杂排序键(Q2 拍板 = entries 登记顺序,代码 0 排序)
❌ 抽 `LoreSectionHeader` 到 `lib/shared/widgets/`(memory feedback_avoid_over_engineer_abstraction,仅 CodexTab 用 inline)
❌ widget test 不扩 viewport 默认 800x600(尾部 lore tile lazy build 漏,memory feedback_listview_widget_test_viewport)
❌ 测试断言硬写"entries[0].id == 'realm'"(memory feedback_red_line_test_semantics,改语义化 `where(isMechanic).first.step == 1`)
❌ 改 codex_providers.g.dart 手动(codegen 文件,build_runner 重生即可)
❌ 动 GDD.md / CLAUDE.md / numbers.yaml / data/narratives/(Mac+Opus 红线)

## 9. 落实装顺序(开工后)

1. **DeepSeek combat_advanced 收口** + Mac 端 `git pull --rebase --autostash` 同步
2. **Phase 1** enum + entries + build_runner
3. **Phase 1 中途** flutter analyze(锁 nullable 改动正确)
4. **Phase 2** Application + UI(SectionHeader inline)+ strings 加 const
5. **Phase 3** 测试改 + 新增 + viewport
6. **flutter test 1076 + N pass + 0 回归 + 0 issues**
7. **commit + push**
8. **closeout 挂回 P1.z 主 closeout**
