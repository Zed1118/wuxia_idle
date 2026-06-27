# 多存档槽（选择存档 / 新开存档 / 删除）· Design

> 日期：2026-06-27
> 阶段：1.0 长线打磨期
> 状态：用户已拍板方向（多 db 方案 · 固定 3 槽 · 启动先进存档选择屏）。本文只定设计与边界，不实现代码。

## 1. 目标

让玩家在 3 个固定存档槽间选择、新开、删除存档。启动先进「存档选择屏」，选中后进主菜单。现有玩家存档作为 slot 1 保留不动。

## 2. 现状（探查结论）

- **多 db 方案已是既定架构**：`IsarSetup.init(slotId: N)` 打开 `wuxia_save_slot{N}.isar`，每槽一个独立 db 文件。db 内 `SaveData` 固定 `id=0`。
- `IsarSetup.currentSlotId` 现为静态写死 `= 1`；`init()` 接受 `slotId` 但启动只传 1。
- `IsarSetup` 已留 3 个 Phase 5 TODO：`switchSlot` / `listAllSlots` / `deleteSlot`（占位未实装）。
- **天然隔离**：角色 / 装备 / 物品 / 心法在各自 db 文件内，**切 db = 切全部数据，无串档**（单 db 才会串，本项目不是）。进度类（Mainline/Tower 等）带 `saveDataId` 字段，在多 db 下冗余、不影响隔离。
- **完全缺失**：启动无「继续/新游戏/选档」分流（`SplashScreen` 固定 init(1)→主菜单）；无任何存档列表/删除/摘要 UI。

## 3. 设计（多 db · 固定 3 槽）

### 3.1 IsarSetup 实装 3 个 TODO + 摘要
- `switchSlot(int n)`：flush/关闭当前 Isar 实例 → 打开 `wuxia_save_slot{n}.isar` → `currentSlotId = n`。原子化。
- `slotHasSave(int n)` / `listSlots()`：遍历 1..3，db 文件存在且含 founder → 只读打开读轻量摘要 `SlotSummary`，否则标记空槽。读完即关只读实例。
- `deleteSlot(int n)`：若为当前槽先关闭 → 删除该槽 db 文件（含 `.isar` / `.isar.lock`）。
- 新增值对象 `SlotSummary { slotId, isEmpty, founderName, realm, mainlineProgress, lastPlayed? }`（纯只读快照，给选择屏用）。

### 3.2 启动流程
`SplashScreen`：加载 defs →（**不再自动 init slot1 / ensureFoundingMasters**）→ `SaveSelectScreen`。
- **有档槽**：点击 → `switchSlot(n)` → `ensureFoundingMasters`（幂等，已 founder 跳过）→ 主菜单。
- **空槽**：点击 → 确认「新开江湖」弹窗 → `switchSlot(n)` → `ensureFoundingMasters`（全新 onboarding）→ 主菜单。
- **删档**：长按 / 删除按钮 → 确认弹窗 → `deleteSlot(n)` → 刷新列表。

### 3.3 切档后 provider 刷新
`switchSlot` 换底层 Isar 实例后，invalidate Isar root provider，使所有 per-save provider（mainline/tower/character/equipment/inventory…）级联重读新 db。`GameRepository`（配置·与槽无关）**不重载**。切档前 flush 当前槽（结算挂机计时器，避免丢未落盘状态）。

### 3.4 槽位摘要卡内容
槽号 + 祖师名 + 境界 + 主线进度（第 N 章 / 已通关）+ 最后游玩（若 `SaveData` 有现成字段；**不为摘要新增 schema 字段**，没有就省略）。空槽显「空 · 新开江湖」。

### 3.5 旧档兼容
现有玩家存档本就是 `wuxia_save_slot1.isar`，选择屏直接显示其进度，**无迁移、不改 schema**。`currentSlotId` 从写死 1 改为运行时可变（默认无选中，由选择屏决定）。

### 3.6 游戏内返回选择屏（含）
设置面板加「切换存档」入口 → 确认后 popback 到 `SaveSelectScreen`（经 `switchSlot`）。低成本，避免只能重启切档。

## 4. 风险 / 边界

- **多 Isar 实例**：`listSlots` 摘要需同时短暂打开多个只读实例（按槽命名隔离），读完必须 close，避免句柄泄漏 / 锁冲突。
- **切档原子性**：`currentSlotId` 是全局静态，切换中途若有 provider 读旧 db → 脏读。切档顺序：flush 旧 → close 旧 → open 新 → set currentSlotId → invalidate providers。
- **挂机结算**：切档 / 删当前档前先跑离线结算或明确丢弃，避免计时器写回已关闭 db。
- **删当前档**：删后必须回选择屏（不能停在已删 db 的主菜单）。

## 5. 测试

- `IsarSetup.switchSlot` 隔离：slot1 写数据 → 切 slot2 → slot2 全新、slot1 不受影响 → 切回 slot1 数据还在。
- `deleteSlot`：删后 `slotHasSave=false`、文件移除。
- `listSlots`：混合有档 / 空槽 → 摘要正确。
- 空槽新开 → onboarding 跑、founder 建。
- `SaveSelectScreen` widget：列 3 槽、有档显摘要、空槽显新开、删除确认流。
- 启动分流 widget：Splash → 选择屏（不再直达主菜单）。

## 6. 不做（YAGNI）

- 不做云存档 / 跨设备同步。
- 不做槽重命名 / 复制槽 / 导入导出。
- 不做手动存档点（挂机游戏 Isar 持续自动持久化，槽即存档）。
- 不做无限槽（固定 3）。
- 不把进度类的冗余 `saveDataId` 字段在本次清理（多 db 下无害，单独评估）。

## 7. 影响文件清单（实现时核对）

- `lib/data/isar_setup.dart`（switchSlot / listSlots / deleteSlot / SlotSummary / currentSlotId 可变）
- `lib/features/splash/presentation/splash_screen.dart`（启动分流到选择屏）
- 新增 `lib/features/save_slot/...`（SaveSelectScreen + slot 列表/摘要卡/删除确认 + providers）
- `lib/data/isar_provider.dart`（切档 invalidate / 实例重建）
- `lib/shared/strings.dart`（选择屏 / 新开 / 删除 / 切换文案进 UiStrings）
- 设置面板（切换存档入口）
- 对应测试文件
- 验证：`flutter analyze` 0 issue + 全量 `flutter test`
