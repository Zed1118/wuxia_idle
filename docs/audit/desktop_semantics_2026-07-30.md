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

## 六、真机键盘走查（本批已做，结论如下）

在真 app 上跑了 Tab 走查（CGEvent 直投 pid，`frontmost_before_send=wuxia_idle` 自检通过），
路由取 `main_menu` 与 `shop_buy_confirm`（后者确有两个真 `PlaqueButton`：取消 / 购买）。

**实拍结果**：按 Tab ×3 后，**窗口内容区零像素变化**——差异全部落在逻辑 y≤83 的标题栏带
（窗口激活导致的红绿灯出现），基线帧的两个木牌按钮上也**看不到任何金色焦点环**。

**根因用对照实验定死**（`test/shared/widgets/plaque_button_focus_ring_test.dart`）：

| 条件 | 金边环 |
|---|---|
| `FocusHighlightStrategy.alwaysTraditional` + autofocus | **画** |
| `alwaysTraditional` + Tab traversal | **画** |
| **默认 `automatic`** + 仅 autofocus（无键盘事件） | **不画** |
| 默认 `automatic` + Tab traversal | 画 |

即 **`PlaqueButton` 的实现是对的**（有焦点必画环，已由 4 条断言钉住），
问题出在 Flutter 默认 `FocusHighlightStrategy.automatic` **开局处于 touch 模式**，
`onShowFocusHighlight` 不回调 true。

**可操作结论**：像 `_ConfirmButton` 那样用 `PlaqueButton(autofocus: true)` 的确认弹窗，
玩家**在按下第一个键之前看不出回车会落到哪**。若要让自动聚焦的主按钮起手就可见，
需在桌面端把策略钉成 `alwaysTraditional`（一行，全局）——**属设计拍板，本批不改**。

**未能证伪的一点**：真机 Tab 之所以零变化，可能是键事件未真正进入 Flutter 引擎
（bg 会话投递），也可能是该路由的复刻件没进遍历组。两者无法从截图区分，
故**不据此断言产品缺陷**；上面的结论只建立在可复现的 widget 层对照实验上。

## 剩余未覆盖维度（本批不做，如实记账）
- **读屏软件实测**未做：Semantics 树的断言只到「节点存在且标注正确」，
  没用 VoiceOver/NVDA 真听一遍朗读顺序。
- Windows 端未验：开发/验收在 macOS，`SystemMouseCursors` 与 Tab 遍历在 Windows 的实际表现待 ship 前实机验。
