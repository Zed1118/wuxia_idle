# 设计：闭关非阻塞 + 出战锁 + 仪式感 + 快捷键

> 2026-06-14 · UX 审查 L3 衍生。来源：用户反馈「闭关被困在界面、不能退出」。
> 调研结论：闭关**技术上已非阻塞**（数据实时落盘、后台计时、装备/仓库/角色面板零耦合），
> 唯一缺口是 `active_retreat_screen` 顶栏无返回按钮（桌面端无硬件返回 = 被困），
> 且闭关期间战斗未被锁（与用户预期相反）。本设计补齐缺口 + 加禁战逻辑 + 轻仪式感 + 快捷键。

## 范围

- ✅ 闭关屏返回出口 / 主菜单常驻横幅 / 出战锁（主线·爬塔·群战·轻功）/ 提前出关 / 开始闭关过场 / 桌面快捷键
- ❌ 0 改 numbers.yaml / data_schema / 数值红线（纯表现层 + 状态读 + 轻导航）
- ❌ 不引实时 Timer（剩余时间为快照，返回主菜单重算，够用）
- ❌ 不锁 PVP（§7 标注未启用，不碰）

## 组件（单一职责）

### 1. active session 读取 provider
- 现状：`_SeclusionMenuButton` 已用 `ref.watch(seclusionServiceProvider)` + `svc.getActiveSession(IsarSetup.currentSlotId)`（FutureBuilder）。
- 新增 `activeRetreatSessionProvider`（FutureProvider.autoDispose）暴露当前 active session，供横幅响应式显示。
- start / completeRetreat 后 `ref.invalidate(activeRetreatSessionProvider)` 刷新横幅与菜单。

### 2. 主菜单常驻横幅 `MainMenuRetreatBanner`
- 有 active session → 主菜单顶部一条水墨横幅：「闭关中 · {地图名} · 剩 {时长}」，tap → push `ActiveRetreatScreen`。无 session 隐藏。
- 复用 `_StateSeal` 印章体例（绛/青）。剩余时间快照，无 Timer。

### 3. 闭关屏返回出口
- `active_retreat_screen.dart` AppBar `automaticallyImplyLeading: false` → 加返回按钮（leading）。
- 返回仅 `Navigator.pop`，**不** abandon，session 后台继续。

### 4. 出战锁守卫 `guardBattleEntry(ctx, ref, onAllowed)`
- 单一守卫函数，包裹主菜单 4 个战斗入口 onTap：主线（chapter_list）、爬塔（tower_floor_list）、群战（mass_battle）、轻功（light_foot）。
- tap 时 `await svc.getActiveSession()` 读最新态：
  - 有 active session → 弹水墨 dialog「闭关修行中，无法出战」+ 两选项：「静微入场（返回）」/「提前出关」。
  - 「提前出关」→ 复用既有 `completeRetreat`（按已挂时长发奖）→ RetreatResultScreen → 回菜单，锁自然解除。**不自动续进战斗。**
  - 无 session → 直接 `onAllowed()`。

### 5. 开始闭关过场（克制版）
- `seclusion_setup` 启动闭关时，一段简短淡入题字「闭关」过场（复用项目过场体例，约 1.5s）。
- 收功侧已有 RetreatResultScreen + cross-tier jingle，不加。

### 6. 桌面键盘快捷键（限闭关相关屏）
- `ActiveRetreatScreen`：`Esc` = 返回、`Enter` = 收功（可收功时）。
- 出战锁 dialog：`Esc` = 关闭。
- 用 `Shortcuts`/`Actions` + `CallbackAction`，**不做全局 ESC**（避免与其他屏/对话框冲突）。

## 文案（UiStrings · §5.6）

新增常量：横幅文案 + 剩余时间格式、出战锁 dialog 标题/正文/「静微入场」/「提前出关」、开始过场题字「闭关」。

## 测试

- `guardBattleEntry` 逻辑：有/无 active session → 拦/放（纯逻辑走 plain `test()`，避开 Isar widget test 死锁）。
- 横幅可见性 widget test：有 session 现、无则隐。
- 提前出关复用既有 `completeRetreat` 测，不重写。
- 闸门：analyze 0 / 全量测试零回归。

## 风险 / 注记

- 剩余时间快照非实时：返回主菜单时重算，分钟粒度足够。
- 出战锁在 onTap 异步读 session：tap 到弹窗有极短延迟，可接受（本地 Isar 读 < 1ms）。
- 群战/轻功入口锁同主线/爬塔，守卫函数统一复用，不各写一份。
