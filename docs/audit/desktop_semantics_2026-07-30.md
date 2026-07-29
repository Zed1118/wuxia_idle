# 桌面语义专项量测（semantics / 键盘 / focus / cursor）

**日期**：2026-07-30 · **基线**：`09c44486` · **触发**：battle-ui-v2 阶段 5 终验一票否决 6 条中
唯一「有实现但未做专项量测」的一条销账。

## 判据来源

CLAUDE.md §8.2：「改交互组件（按钮/输入等）须验 semantics / 键盘激活 / focus / mouse cursor
（`InkWell`→`GestureDetector` 一类改动易丢这些桌面语义）」。发布目标是 **Windows**，
只用键盘/读屏的玩家必须能触达每个交互点。

## 扫描面收敛：为什么只扫 GestureDetector

| 组件 | Semantics | 焦点 | 键盘激活 | 光标 |
|---|---|---|---|---|
| `InkWell` / Material 按钮（Filled/Text…） | 内建 | 内建 | 内建 | 内建 |
| **`GestureDetector`** | **无** | **无** | **无** | **无** |

存量实测：`InkWell` 57 处、`GestureDetector` 19 处。前者四项天然齐全，
**风险面 100% 落在后 19 处**，故扫描面收敛到 GestureDetector。

## 量测结果（19 处逐个分类）

| 类 | 数量 | 说明 | 处置 |
|---|---|---|---|
| 复用基元·四项俱全 | 4 | PlaqueButton / WuxiaIconButton / PlaqueTab / WuxiaInkButton | 已达标，不动 |
| 真控件·缺键盘+焦点+光标 | 2 | GlossaryTip「?」标记、TowerFloorCard 掉落传闻图标 | **本批修** |
| 纯点击遮罩·零键盘等价物 | 6 | 见下表 | **本批修** |
| 便利遮罩·真操作在内部按钮上 | 4 | 内部另有键盘可达按钮 | 登记 allowlist |
| 吞点无操作 | 1 | `onTap: () {}` 阻止冒泡 | 登记 allowlist |
| 已有 Escape 处理 | 1 | `battle_screen` 外层 `Focus` + Esc | 已达标 |
| DismissLayer 自身 | 1 | 本批新增基元 | 已达标 |

### 真缺口 ①：两处真控件读屏可达但键盘不可达

两处都写成 `Semantics(button:true, onTap:, excludeSemantics:true) > GestureDetector`。
读屏软件能点，**但键盘 Tab 到不了、鼠标也不给 click 光标**。
补 `FocusableActionDetector(mouseCursor: click, ActivateIntent)` 后三项齐。

### 真缺口 ②：6 处过场/浮层只能点，不能按键

| 站点 | 内部有键盘可达按钮？ |
|---|---|
| `victory_ceremony` VictorySealFlash | 无（doc 自述「无按钮」） |
| `hero_camera_overlay` | 无 |
| `skill_treasure_overlay` | 无 |
| `disciple_join_overlay` | 无 |
| `seclusion_enter_caption` | 无 |
| `splash_screen` | 无 |

统一换成新基元 `DismissLayer`（`Focus(autofocus) + onKeyEvent` 收
Esc / Enter / NumpadEnter / Space，点击行为原样保留）。

**刻意不加**语义与光标：整屏遮罩报成 `button` 会污染无障碍树，
整屏给 click 光标是噪音——这类层要补的只有「键盘可达」这一维。

## 两处自我证伪（避免把非缺陷报成缺陷）

初版用「行窗口启发式」（GestureDetector 上下若干行找标记），产出 15 处缺项。
逐个查真实用途后**推翻 4 处**：

- `battle_header` PauseOverlay —— 同屏有 `FilledButton(onPressed: onResume)`，键盘本就能恢复。
- `battle_header` LogDrawer scrim —— 抽屉内有 `WuxiaIconButton(Icons.close)`（四项俱全）。
- `encounter_dialog` —— `_ChoiceButton` 走 `InkWell(canRequestFocus)`、
  `_ConfirmButton` 走 `PlaqueButton(autofocus: true)`。**此处一度已改成 DismissLayer，
  发现会与确认键抢焦点后回退**——加 autofocus 在这里是净回归。
- `narrative_reader_screen` —— 同屏有「继续」按钮与 AppBar「跳过」TextButton。

教训：判「键盘不可达」不能只查该 widget 有没有键盘处理器，
**必须查同屏有没有别的键盘可达控件承载同一操作**。

## 门禁（防回归）

`test/tools/desktop_semantics_audit.dart` + `desktop_semantics_audit_test.dart`
+ `test/fixtures/desktop_semantics_allowlist.txt`，沿中文散写门禁的三件套体例。

规则：`lib/` 下每个 `GestureDetector` 要么祖先链上有
`DismissLayer` / `FocusableActionDetector` / `Focus` / `InkWell`，要么在 allowlist 里
登记分类与理由。三条断言构成双向棘轮：① 拦新增未覆盖站点；② 拦 allowlist 失效条目
（修好了忘销账 / 行号漂移）；③ `lib/shared/` 复用基元**不给豁免通道**（一处失守会扩散到全部调用点）。

**实现坑留档**：`parseString` 出的是未解析 AST，`Foo(...)` 不带 `new`/`const` 时解析成
`MethodInvocation` 而非 `InstanceCreationExpression`。只认后者会一个站点都扫不到
（实测 TOTAL=0）。两种都要认。

## 剩余未覆盖维度（本批不做，如实记账）

- **真机键盘走查**未做：本批是静态量测 + widget 测，没在真机上逐屏 Tab 一遍看焦点环是否可见、
  顺序是否合理。焦点**可视化**（focus ring 对比度）属视觉验收范畴，需另起一批。
- **读屏软件实测**未做：Semantics 树的断言只到「节点存在且标注正确」，
  没用 VoiceOver/NVDA 真听一遍朗读顺序。
- Windows 端未验：开发/验收在 macOS，`SystemMouseCursors` 与 Tab 遍历在 Windows 的实际表现待 ship 前实机验。
