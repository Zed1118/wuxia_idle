# Tier2:PanelSurface 背景自带文字色抽象 — 设计

**日期**:2026-07-06 · **状态**:设计定稿(用户已拍板)· **前置**:Tier1 面板重命名(合入 main `c9cad85a`)

## 背景与目标

「浅底×同色文字低对比」是长期困扰的**整类** bug。根因是结构性的(详 PROGRESS 2026-07-06 Tier1 条 + memory `feedback_paper_vs_dark_text_color_palette`):
- 两套裸 `Color` 色板(深 `WuxiaColors.text*` / 浅 `WuxiaUi.ink|muted|jiang|gold`),编译器不校验跨底混用;
- 共享组件硬编文字色,深/浅由调用方**手动记**,漏一处即低对比(今早 A1 的 `nextEffectColor` 散落失配即此机制)。

Tier1 已消除命名坑。**Tier2 从结构上消灭这一类**:让共享组件按所在面板底色**自动**取正确文字色,调用方无需决定、也就无从做错。

**目标**:引入 `PanelSurface`(InheritedWidget),两面板向下提供各自的「表面文字角色」;wuxia_ui/ 下所有硬编 **bg-dependent 文字色** 的共享组件改读 `PanelSurface`;废掉 `StageProgressRow.nextEffectColor` 手传参数。

## 非目标(明确不做)

- **不动结构/品牌色**:tier 金框、按钮绛红渐变、内息青 `qing`、稀有色、分隔描边——两底一致、与文字对比无关,原样保留。
- **不改战斗深底 UI**:battle_screen 等直接用 `WuxiaColors.text*` 且底色恒深,不在本批(它们不属「被搞混」的那类,无面板包裹)。
- **不做色板类型标签**(`OnLight`/`OnDark` 编译期拦):PanelSurface 已从结构上覆盖,类型标签过度工程,不做。
- **不改色值**:仅改「谁来选色」,不动 ink/muted/jiang/gold/textPrimary 等具体色值。

## 设计

### ① PanelSurface API(新文件 `lib/shared/widgets/wuxia_ui/panel_surface.dart`)

`InheritedWidget`,暴露 3 个语义文字角色:

| 角色 | light(LightPaperPanel) | dark(DarkParchmentPanel) | 用途 |
|---|---|---|---|
| `primary` | `WuxiaUi.ink` | `WuxiaColors.textPrimary` | 标题/正文 |
| `secondary` | `WuxiaUi.muted` | `WuxiaColors.textSecondary` | 次要/副描述/分隔线 |
| `accent` | `WuxiaUi.jiang` | `WuxiaUi.gold` | value 强调/下一阶(保留当前深底 gold 观感) |

```dart
class PanelSurface extends InheritedWidget {
  final Color primary, secondary, accent;
  const PanelSurface({required this.primary, required this.secondary,
      required this.accent, required super.child});
  const PanelSurface.light({required Widget child}) // ink/muted/jiang
  const PanelSurface.dark({required Widget child})   // textPrimary/textSecondary/gold
  static PanelSurface of(BuildContext c); // 无 ancestor 兜底 light(纸面 UI 占多数)
  static PanelSurface? maybeOf(BuildContext c);
  bool updateShouldNotify(old) => primary/secondary/accent 任一变;
}
```

- 3 角色为 MVP,覆盖实际用量;不够再扩,不预造(YAGNI)。
- `of()` 兜底 light:采纳组件绝大多数在纸面板内;万一裸用得 light 亦为安全默认。

### ② 面板提供 surface

三处在 `return` 前包一层(纯新增包裹,不改 DecoratedBox/纹理结构):
- `DarkParchmentPanel.build` → `PanelSurface.dark(child: <现有 return>)`
- `LightPaperPanel.build` → `PanelSurface.light(child: <现有 return>)`
- `PaperDialog`(恒浅底,内含 LightPaperPanel)→ 由内层 LightPaperPanel 自动提供,无需额外包。

### ③ 逐组件迁移分类(只迁 bg-dependent 文字色)

对 wuxia_ui/ 每个组件:**bg-dependent 文字/分隔 → 读 `PanelSurface.of(context)`;结构/品牌色保留**。

| 组件 | → surface | 保留不动(结构/品牌) |
|---|---|---|
| `section_header` (:29,62,66) | 标题→primary·分隔线→secondary | — |
| `stage_progress_row` (:96,106,140,159,182 + accent 参数) | 标题→primary·stageName 沿用 qing·currentEffect/progress→secondary·nextEffect→accent | qing(内息辅色) |
| `glossary_tip` (:47,50,57,122) | 气泡正文→primary·标记→secondary | 气泡自有底则内部自洽(实装时按其 fillColor 判,拿不准实拍) |
| `meridian_bar` (:32,40) | 标签→primary | 进度条轨/描边(结构) |
| `error_fallback` (:47) | 文字→primary(ink2 归 primary) | 重试按钮走 PlaqueButton |
| `ink_empty_state` (:69,94,117,118) | 说明文字→primary/secondary | 图标/边框/jiang 行动色 |
| `wuxia_title_bar` (:52,63,74,96) | 返回箭头/标题→primary | jiang 强调·分隔描边 |
| `item_slot` (:75,85,91,97,143) | 物品名文字→primary | **tier 金框 gold / jiang 高亮(结构·保留)** |
| `plaque_button` (:64,131,184) | 标签文字(如硬编 ink)→primary | **绛红渐变/边框(品牌·保留)** |
| `paper_dialog` (:60-70,91,112) | 标题/正文→primary·表单 hint→secondary | jiang 行动色·恒浅底可暂留(低优先) |

> 每组件实装时先 grep 确认命中行仍在(行号会 drift),按「是不是随底色需翻转的文字」二分,不是就保留。

### ④ 废掉 StageProgressRow.nextEffectColor

删 `nextEffectColor` 参数 + 默认值,`nextEffect` 文字改读 `surface.accent`。3 个浅底调用点(`skill_codex_detail_screen`/`equipment_detail_screen`/`SkillProficiencyRow`)删掉手传的 `nextEffectColor: WuxiaUi.jiang`——深底(character_panel/technique_panel)自动 gold、浅底自动 jiang。**这是消灭 foot-gun 的端到端证明点。**

## 测试

- `panel_surface_test`:`of` 命中/兜底 light/`.light`/`.dark` 两工厂角色值/`updateShouldNotify`。
- 每迁移组件加「双底断言」widget 测:同组件包 `LightPaperPanel` 下取 ink、包 `DarkParchmentPanel` 下取 textPrimary(pump 两次断言 `Text.style.color`)。StageProgressRow 的双底测覆盖 accent(浅 jiang/深 gold)取代旧 `nextEffectColor` 测。
- 全量 `flutter test --no-pub` 零回归(基线 3692)。
- **视觉最终收口起游戏实拍**(两面板下各组件对比度)→ 归晚上目检工作流,非本批代码 gate。

## 验证 gate(worktree 实测)

`analyze lib/ test/` 0 · 全量 3692+ 零 fail · `audit_paper_text_contrast.py` 0 finding · 各组件双底测绿。

## 风险

- **角色不足**:3 角色可能不覆盖某组件的第 3 文字层(如深底 textMuted)。策略:遇到再扩角色,不预造。
- **裸用组件**:采纳组件若被用在无面板包裹处 → 兜底 light,深底处会错。实装时 grep 各采纳组件调用点确认都在面板内(或深底处显式包 `PanelSurface.dark`)。
- **分隔线/边框归 secondary 是近似**:若某分隔在深底 secondary 不够,单独处理。
- **blast radius 大**(用户拍板一次迁全):靠双底 widget 测 + 全量 + 晚上实拍三道兜。
