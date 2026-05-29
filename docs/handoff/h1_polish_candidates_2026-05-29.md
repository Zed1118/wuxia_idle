# H1 卡点候选清单(不实装 · 用户拍后再 apply)

> 起草:2026-05-29 · H 段 Batch H1.3 · 来源 `h1_onboarding_audit_2026-05-29.md` 8 gap
> **本 doc 不动代码** · 4 级修复方案候选,用户拍后我按需实装

## G1 🔴 MainMenu 标题硬编码「调试主菜单」(P0 ship blocker · 必修)

**位置**:`lib/shared/strings.dart:39`
```dart
static const String mainMenuTitle = '挂机武侠 · 调试主菜单';
```

### 候选 1A · 改纯产品名(强推荐 · ~5min)
```dart
static const String mainMenuTitle = '挂机武侠';
```
**优点**:0 风险,production / debug 同一标题 · debug 按钮已用 kDebugMode 守(P1-1 release 2026-05-25 决议)区分,不会与"产品名"冲突。

### 候选 1B · 改产品名 + tier 显示
```dart
static const String mainMenuTitle = '挂机武侠 · 江湖';  // 副标隐喻
```
**优点**:产品名 + 副标隐喻氛围。**风险**:增加文字长度可能影响 UI 布局。

### 候选 1C · 全 polish 标题字号 + 字距
连 G5 一起做 · `main_menu.dart:111-119` 主标题 Text style 调整:
- fontSize 24 → 28
- letterSpacing 4(沿 splash_screen 体例)
- fontWeight w600

**推荐 1A + 顺手 1C**(最低风险 + 最高 polish ROI · ~15min 实装)

---

## G2 🟡 step 1-5 上手期 0 banner 引导(P1)

**位置**:`tutorial_hint_def.dart:34-56` 只有 step 6/7/8 三档 · step 1-5 没有 def

### 候选 2A · 补 step 1-5 5 个引导 banner(沿 step 6/7/8 体例 · ~1h)
新增 5 个 hint def:
- step 1(stage_01_01 通关): "首战告捷 · 装备已入背包 · 继续往前"
- step 2(stage_01_02): "二关清场 · 心法将解锁"
- step 3(stage_01_03): "心法面板已开 · 试试主修招式"
- step 4(stage_01_04): "章末前夕 · 摸索装备搭配"
- step 5(stage_01_05): "Ch1 已通 · 江湖之路才刚启"

**优点**:覆盖上手 30min 全程引导 · 玩家有明确 next step
**风险**:文案需仔细打磨(古风 + 克制 + 不啰嗦)· UiStrings 5+ 段 + TutorialHintDef.all 数组扩

### 候选 2B · 只补 step 1 + step 3 关键节点(~30min · 轻量)
- step 1 = 首胜 + 首装备(玩家最需要的反馈)
- step 3 = 心法解锁(系统门槛锚点)
其它走自然发现。

**推荐 2A**(若选 H1 全 polish)或 **2B**(若 ship 时间紧)· 用户拍

---

## G3 🟡 HomeFeed 空 feed 占位无 CTA 引导(P1)

**位置**:`home_feed_screen.dart:84-103`

### 候选 3A · 加首次启动占位文案 + 显式箭头指向 QuickClaim(~20min)
- _EmptyHint 占位文案后加箭头 ↓ 或 "新到此界?点底部按钮开始"
- 文案走 UiStrings · 古风克制

### 候选 3B · 首次启动直接 skip HomeFeed → MainMenu(~10min)
检测 feed 为空 → 自动 navigator.pushReplacement(MainMenu)。**风险**:破现有"事件流为家"设计哲学,可能影响后续 feed 引导用户回放历史。

**推荐 3A**(保留设计 + 微 polish)

---

## G4 🟡 stage_01_01 opening 后 CTA 不直觉(P1)

**位置**:`stage_01_01_opening.yaml` + NarrativeReaderScreen

### 候选 4A · 末段补 1 行隐含提示(~5min)
```yaml
paragraphs:
  - 山门已经看不见了。路两侧是半人高的野蒿，露水还没干。
  - 你背上那柄剑很沉，不是剑重，是师父的话重。山风从背后吹来，像是推了你一把。
  - （轻按屏幕 · 继续）  # 新增
```
**风险**:破 narrativeReader 默认 CTA 体例(查看其它 opening 是否有类似引导)。

### 候选 4B · NarrativeReaderScreen 通用 footer 加 hint(~30min)
统一所有 narrative 末尾加 "轻按屏幕继续" 之类小 hint · 玩家上手期看到 · 后续可控不显。

**推荐 4B**(产品体验一致性)· 需 Pen 实机验证当前是否真的不直觉

---

## G5 🟢 MainMenu 标题 polish(连 G1 · ~10min)

见 G1 候选 1C(连做)

---

## G6 🟢 首次装备掉落额外特效(P2 · ~2h xhigh)

**复杂度高,留 1.1 P2 polish 段** · Demo 不实装

---

## G7-G8 🟢 step 6/7/8 早期触发 + step 1-5 banner

G7 是 30min audit 覆盖不到的观察,无 actionable 项。
G8 与 G2 同源 · 候选 2A/2B 已覆盖。

---

## 推荐套餐(用户拍其一)

| 套餐 | 内容 | 估时 | ROI |
|---|---|---|---|
| **小套餐**(推荐 · 必修)| G1 候选 1A + G5 1C(改产品名 + polish 字号) | ~15min | ⭐⭐⭐⭐⭐ |
| **中套餐**(全 polish)| 小套餐 + G2 候选 2B(2 banner)+ G4 候选 4B(narrative footer)| ~1.5h | ⭐⭐⭐⭐ |
| **大套餐**(全 H1 一波)| 小套餐 + G2 候选 2A(5 banner)+ G3 候选 3A + G4 候选 4B | ~3h | ⭐⭐⭐ |

## 起床决策点

| # | 问题 | 推荐 |
|---|------|------|
| **H1-Q1** | 套餐选哪个? | **小套餐**(P0 ship blocker 修 + 顺手 polish · 立即可见效果)|
| **H1-Q2** | G6 首次装备掉落特效 1.1 启动? | 留 1.1 · 不影响 1.0 ship |
| **H1-Q3** | H1 后续 batch 启动顺序? | H2 中期 audit(下一步)→ H3 后期 → H4 数据驱动 → H5 UX → H6 文案 |

---

**不实装动作清单**:
- ❌ 不动 numbers.yaml / stages.yaml
- ❌ 本 doc 0 代码改动 · 仅候选方案 doc
- ✅ 用户拍 H1-Q1 后我按套餐 apply
