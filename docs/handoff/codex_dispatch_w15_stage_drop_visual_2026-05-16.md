# Codex 派单 · W15 stage drop 视觉验收(#34 老挂账闭环)

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows Codex 桌面
> 创建日期:2026-05-16
> 关联挂账:`PROGRESS.md §已知偏差` #34 — 2026-05-14 Codex v4 跑 stage_01_01 victory 但 RDP/1280×900 主菜单底部「装备仓库」入口不稳定,没拍到新增装备
> 上游派单同类前序:`codex_dispatch_w15_equipment_detail_2026-05-15.md`(7/7 PASS,工程教训沿用)/ round2 `codex_dispatch_w15_equipment_detail_round2_2026-05-15.md`(widget capture fallback 实战)
> Mac 端环境:HEAD `c8dd787` 已 push,工作树 clean,**本派单不需要 Mac 再动代码**

---

## 1. 一句话目标

打通 **stage drop → InventoryScreen** 视觉验收链路,确认主线胜场结算后**新增装备 + 磨剑石**真的进库存。代码层 `game_repository_test.dart` 已兜底 `dropTable` 配置生效,本派单补 GUI 端硬截图。**#34 老挂账闭环本派单**。

---

## 2. 背景

### 2.1 上次失败原因(2026-05-14 Codex v4)

- RDP 高度 + 1280×900 窗口下主菜单底部「装备仓库」按钮被屏幕底挡 / 鼠标点不准
- 实际跑通了 stage_01_01 victory,但战后回主菜单 → 进装备仓库这一步失败
- 没拍到新增装备的硬证据,只能写"代码层兜底"挂账

### 2.2 这次的工程改善建议

**主菜单是 `SingleChildScrollView` 包 8 个 `_MenuButton`**(`lib/ui/main_menu.dart:47`),装备仓库是**第 7 个**。1280×900 下应能 scroll,但需要在按钮区域**鼠标滚轮向下滚** 2-3 格才能看到。

3 条路径任选其一,优先级 A > B > C:

**A. 真 GUI 路径(优先)**:窗口 1280×900 + 主菜单先滚轮下滚再点装备仓库
**B. widget 视觉捕获 fallback**(round2 实战路径):绕 GUI 链路,渲染层验 InventoryScreen 内容
**C. 反向利用 Phase2 直跳路径**:Phase2 → VC15-r2 / VC15-res 按钮种完会**直接 push InventoryScreen**(`phase2_test_menu.dart:170, 180`),不用经主菜单底部 — 但**问题:VC15-r2 / res 是种 fixture 装备直接入背包,不验 stage drop**。所以 C 不行,不要走。

### 2.3 不动 Mac 端

Mac 端**不加**专用 stage drop seed 也**不加**库存快捷入口。本派单纯 GUI 验收,让 Codex 在 Pen 端验证主菜单 scroll + 装备仓库链路是否真的有问题。

如果 A / B 都跑不通,closeout 详写卡点,再决定是否 Mac 端介入加 fixture。

---

## 3. 任务清单

### 3.1 启动准备(沿用 round3 教训)

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
# 应到 HEAD c8dd787 或更新

dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug
```

### 3.2 启 GUI(Start-Process 优先)

```powershell
# 清存档,确保从空白态起
Remove-Item -Recurse -Force "$env:APPDATA\wuxia_idle" -ErrorAction SilentlyContinue

Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe
```

启后用 `Get-Process wuxia_idle` 拿 `MainWindowHandle`,非 0 = GUI 可见。

窗口固定 `1280 × 900`,截图前 `SetWindowPos(HWND_TOPMOST)` 防抢前台。

如 1280×900 出现底部按钮被屏幕底挡(Pen 屏幕高度 < 900):**改成 1280×800** 也 OK,主菜单 SingleChildScrollView 会自动适配 scroll。

### 3.3 种 player + 师徒(P5 师徒种子)

主菜单 → **Phase 2 调试场景** → **P5 · 师徒种子**

P5 一键种 3 师徒(祖师=玩家本人 + 大弟子 + 二弟子)+ 9 件起手装备 + 基础物料(磨剑石 / 心血结晶若干起手量)。

种完会自动 push 角色面板,**Back 一下回 Phase2TestMenu,再 Back 一下回主菜单**。

### 3.4 进主线 stage_01_01 → victory

主菜单 → **主线江湖** → **第一章 山门下** → **stage_01_01 山门之外** → 战斗

P5 起手装备(利器龙泉剑等)对 xueTu 杂兵秒杀,victory 应该几秒内出。

**截图 1**:`01_stage_01_01_victory.png` — 拍 victory 屏(战斗结算屏),应能看到 drop banner / drop 列表:
- `armor_xunchang_bu_yi` 寻常货布衣(100% drop)
- `item_mojianshi` 磨剑石 × 1(100% drop)

**path**:`docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png`(新建目录)

如果 victory 屏没有显式 drop 列表(只显示 EXP / 战利品摘要):换拍 victory narrative 屏 + 一个箭头标注「需进库存验证」。

### 3.5 回主菜单 → 装备仓库(关键)

victory 屏点确定 → 应回主线章节列表或自动到下一关(`stage_01_02`)。

**Back 多次直到回主菜单**。

主菜单第 7 个按钮是「装备仓库」,1280×900 窗口高度刚好能看到第 1-6 个,**滚轮向下滚 1-2 格**让第 7-8 个按钮露出。点「装备仓库」进 `InventoryScreen`。

**截图 2**:`02_inventory_after_drop.png` — 拍装备 Tab 的 ExpansionTile 列表,**寻常货**分组应见:
- 既有装备:布衣 × 1(P5 二弟子起手,可能装备中,可能在背包,看 P5 实现)
- **新增装备:armor_xunchang_bu_yi 寻常货布衣 + 1 件**(从 stage_01_01 drop 来)

如果原本就有 1 件布衣,新增 1 件后应该看到 2 件布衣条目或同一条目数量 +1(取决于 InventoryScreen 是否合并同 def)。

### 3.6 切到物料 Tab 验磨剑石

InventoryScreen 应有 Tab 切换装备 / 物料(看 InventoryScreen 当前实现,若 Tab 不存在则统一在装备列表)。

**截图 3**:`03_materials_mojianshi.png` — 拍磨剑石条目,数量应比 P5 起手数 +1。

如果 InventoryScreen 没显示磨剑石(只显示装备),写在 closeout 「材料区 UI 不显数字」反馈给 Mac。

### 3.7 [可选] 额外 1-2 关验高 tier drop

时间允许时,再跑:
- `stage_01_05 山门之内`(章 1 终关,有装备 + 心血结晶 drop)
- `stage_03_05 一剑封名`(章 3 终关,大 Boss,有高阶 drop 推测)

每关 victory 后回主菜单 → 装备仓库,各拍 1 张验装备新增。

可选不强制。本派单**必收硬证据**就是 3.4 + 3.5 + 3.6 三张,**最低拿到 stage_01_01 victory + InventoryScreen 多 1 件布衣 = #34 闭环**。

---

## 4. 评级标准

| 评级 | 标准 |
|---|---|
| PASS | victory 屏拍到 drop banner / 列表 + InventoryScreen 看到新装备 + 物料增加 |
| WARN | victory 屏 drop 看不见但 InventoryScreen 确实多了装备 |
| FAIL | victory 屏没 drop 显示 + InventoryScreen 没新装备(说明 dropTable 配置可能未生效,需要 Mac 端排查) |

---

## 5. 红线 · 不要做的事

- ❌ 不动 `lib/` `data/` `test/` 任何文件(本派单纯 GUI 验收)
- ❌ 不跑 widget test / unit test(Mac 端已 661/661 通过)
- ❌ 不评论 lore 文案质量(DeepSeek 领地)
- ❌ 不评论 stage 数值是否合理(GDD §5.6 红线)
- ❌ 不修主菜单 _MenuButton 或 InventoryScreen 代码(Pen 端禁动 lib/)
- ❌ 不尝试 stage_01_05 一直打到失败(只验 victory drop)

---

## 6. fallback 路径(A 跑不通走 B)

### 6.1 真 GUI 路径(A)跑不通的判定

- 主菜单 scroll 不到「装备仓库」按钮(1280×800 也滚不到)
- 装备仓库按钮点不准(鼠标坐标偏)
- 战斗 victory 屏不出现 drop banner / 列表

### 6.2 widget 视觉捕获 fallback(B)

按 round2 体例,临时 Dart 脚本:
1. 初始化 ProviderScope + 一个 Isar(用 P5 已写的 fixture)
2. 模拟 stage_01_01 victory `DropService.rollDrops(stage_01_01)` 直接拿 drop result(`game_repository_test.dart:124+` 测试已用此路径,你照抄)
3. push InventoryScreen(`lib/features/inventory/presentation/inventory_screen.dart`)
4. 用 round2 的 PrintWindow / `Build > Image` 1280×900 PNG 落盘

**B 的缺点**:不验真 GUI 链路,只验渲染层。如果 victory drop banner 是 GUI-only(不是 InventoryScreen 内部 widget),B 验不到 victory 屏。closeout 标清「B 路径未验 victory banner」即可。

---

## 7. closeout 模板(完成后写)

文件:`docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md`

```markdown
# Codex W15 stage drop 视觉验收 closeout(#34 闭环)

## 1. 一句话结论
N 张主截图完成,M/N PASS,K WARN,L FAIL。#34 是否闭环。

## 2. 环境与启动记录
- HEAD: <hash>
- git pull/build/启动 详细命令与结果
- 走 A 还是 B 路径,卡点详细
- 1280×900 vs 1280×800 实际行为

## 3. 截图清单与 PASS/FAIL 评级
| # | 场景 | 截图路径 | 评级 | 备注 |
|---|---|---|---|---|
| 1 | stage_01_01 victory | docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png | PASS | drop banner 可见... |
| 2 | InventoryScreen 装备 Tab | 02_inventory_after_drop.png | PASS | 寻常货布衣 +1... |
| 3 | InventoryScreen 物料 Tab | 03_materials_mojianshi.png | PASS | 磨剑石 +1... |

## 4. 视觉层问题反馈(给 Mac)
- victory 屏 drop banner 视觉层级 / 字号 / 颜色
- InventoryScreen ExpansionTile 装备分组展开行为
- 物料 Tab 是否存在 / 数量是否实时更新

## 5. 节奏层问题反馈(给 Mac)
- victory → 主菜单 → InventoryScreen 切屏流畅度
- 大 Boss 关战斗时长(>30s 算太久)

## 6. 工程教训(本会话产)
- 1280×900 主菜单 scroll 是否真有问题
- 滚轮坐标 / SetCursorPos / mouse_event 的稳定性
- 截图 PrintWindow vs CopyFromScreen 行为差异

## 7. 下次推荐
- #34 是否闭环 / 是否需要 Mac 端再加 fixture
- 高 tier drop 验收建议
```

---

## 8. 不在本派单处理的事项

- **装备强化/开锋后的视觉变化**(round1/2 已验,不重复)
- **共鸣度阶段切换可视化**(挂账)
- **师承遗物 chip 显示**(W15 final commit `6db64c9` 已验,本派单不重复)
- **lore 文学性 polish**(DeepSeek 领地)
- **Pen 端跑 flutter test**(本会话 commit fix 了 T64 fail-fast CRLF normalize,Pen 端 git pull 后**可顺手跑 `flutter test` 验证**,如果还有 fail 标在 closeout)

---

**派单结束。完成后写 closeout + push 即结束。不联系派单方。Mac 端会在下次同步拉到 closeout + 截图,看视觉评级决定 #34 是否闭环。**
