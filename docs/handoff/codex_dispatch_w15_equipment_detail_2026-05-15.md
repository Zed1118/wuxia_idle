# Codex 派单 · W15 装备详情屏视觉验收(EquipmentDetailScreen)

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows Codex 桌面
> 创建日期:2026-05-15
> 关联挂账:PROGRESS.md「下一步」· Pen 端视觉验收装备详情屏
> 上游产出:HEAD `d12774c`(本派单的代码改动全部已在 main 上)
> 上游派单同主题前序:`codex_dispatch_w15_dialog_round3_2026-05-15.md`(已 6/6 PASS,工程教训沿用)

---

## 1. 一句话目标

验证本会话 Mac 端新增的 `EquipmentDetailScreen`(W15 LoreLoader 接入下一步)在 Pen 真机渲染下的视觉效果:**信息卡 + 典故段 + 强化/开锋按钮分流** 三栏布局成立,1 段/2 段 lore 文学性可读,tier 差异化视觉区分明显。

---

## 2. 背景

### 2.1 本会话 Mac 端做了什么

- 新建 `lib/ui/inventory/equipment_detail_screen.dart`:Scaffold + AppBar + 信息卡(tier/slot/school chip + 三围 + +N + 共鸣度阶段 + 战斗次数)+ FutureBuilder 包 `LoreLoader.load` + ListView 段落 scroll(「◇ 典故 ◇」标题 + 段间「· · ·」分隔)+ 底部 [强化] / [开锋] 按钮分流
- 改 `lib/ui/enhancement/enhance_dialog.dart` 加 `initialTab` 可选参数(0=强化 / 1=开锋)
- 改 `lib/ui/inventory/inventory_screen.dart` row.onTap def 非空时 `Navigator.push(EquipmentDetailScreen)`(原 showDialog 路径仅 fixture/未知 defId 时兜底)
- **lore 消费纯 UI 层**:`Equipment.defId → EquipmentDef.presetLoreIds.first → LoreLoader.load`,不写 Isar(W15 LoreLoader 接入纪律延续)
- Mac 端 widget test 5 个通过,**626/626** 后续又跑了 DeepSeek 34 招映射验收 **627/627**

### 2.2 为什么需要真机视觉验收

Mac 无 Xcode → 跑不了 `flutter run -d macos`,widget test 只验逻辑(渲染 / FutureBuilder / 按钮 tap),**真机段落排版 / scroll 流畅度 / chip 间距 / 按钮间距 / 信息卡视觉层级** 必须 Pen 真机看。

### 2.3 抽样覆盖 tier 1-4(段数 1+2),tier 5-7 留挂账

W15 #35 DeepSeek 交付的 lore 按 tier 差异化:
- 寻常货 → 1 段
- 像样货 / 好家伙 / 利器 → 2 段
- 重器 / 宝物 / 神物 → 3 段

**本派单只验 1 段 + 2 段**,因 P5 seedMasterDisciple 起手装备最高到利器,**3 段渲染留下波 stage drop / craft 路径打通后再验**(挂账)。

---

## 3. 任务清单

### 3.1 启动准备(沿用 round3 工程教训)

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
# 应到 HEAD d12774c 或更新

dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug
```

### 3.2 启 GUI(round3 工程教训:schtasks 不通 → Start-Process)

**首选 Start-Process(round3 验证成功)**:
```powershell
Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe
```
启后用 `Get-Process wuxia_idle` 拿 `MainWindowHandle`,非 0 = GUI 可见。

**备选 schtasks(round1/2 路径,本环境 Access denied)**:仅当 Start-Process 也失败时尝试。

窗口固定 `1280 × 900`,截图前 `SetWindowPos(HWND_TOPMOST)` 防抢前台。

### 3.3 种 9 件装备(P5 seedMasterDisciple)

主菜单 → **Phase 2 调试场景** → **P5 · 师徒种子**(按钮文字 `P5 · 师徒种子`)

P5 一键种 3 师徒 + 9 件起手装备:
- 祖师:`weapon_liqi_long_quan`(利器,龙泉剑)+ `armor_haojiahuo_jin_pao`(好家伙,锦袍)+ `accessory_haojiahuo_yu_pei_lao`(好家伙,古玉佩)
- 大弟子:`weapon_haojiahuo_qing_feng_jian`(好家伙,青锋剑)+ `armor_xiangyang_pi_jia`(像样货,皮甲)+ `accessory_xiangyang_yin_jie`(像样货,银戒)
- 二弟子:`weapon_xiangyang_gang_dao`(像样货,钢刀)+ `armor_xunchang_bu_yi`(寻常货,布衣)+ `accessory_xunchang_yu_pei`(寻常货,玉佩)

种完弹 SnackBar / 自动返回主菜单,**点回主菜单**(不必等)。

### 3.4 进装备仓库

主菜单 → **装备仓库**(按钮文字 `装备仓库`)

应见 ExpansionTile 按 tier 分组:利器(1)/ 好家伙(3)/ 像样货(3)/ 寻常货(2),每行 `+0 武器名 · 共鸣阶段` 这种结构。

**截图 1**:仓库列表全展开(ExpansionTile 都展开),`docs/screenshots/w15_equipment_detail/01_inventory.png`

如 tier 分组未自动展开,手动逐个点开 expand。

### 3.5 进 4 件装备详情屏(各 tier 1 件,共 4 张主截图)

逐个点击 row 进详情屏,每件拍 1 张主截图(信息卡 + 典故段 + 底部按钮全可见):

| # | tier | 装备 id | 预期段数 | 截图路径 |
|---|---|---|---|---|
| 2 | 利器 | weapon_liqi_long_quan(龙泉剑)| 2 段 | `02_liqi_long_quan.png` |
| 3 | 好家伙 | weapon_haojiahuo_qing_feng_jian(青锋剑)| 2 段 | `03_haojiahuo_qing_feng_jian.png` |
| 4 | 像样货 | weapon_xiangyang_gang_dao(钢刀)| 2 段 | `04_xiangyang_gang_dao.png` |
| 5 | 寻常货 | armor_xunchang_bu_yi(布衣)| 1 段 | `05_xunchang_bu_yi.png` |

**截图要求**(每张):
- 详情屏 1280×900 内完整可见(AppBar + 信息卡 + 典故段 + 底部按钮)
- 如典故段需要 scroll,**不需要展开拍多张**,主截图取顶部能看到「◇ 典故 ◇」+ 段一前几行即可
- 如有「· · ·」段间分隔符出现在主屏内,拍到即好

存 `docs/screenshots/w15_equipment_detail/`(新建目录),命名按上表。

### 3.6 验按钮分流(任选 1 件,2 张验证截图)

回到任一详情屏(推荐龙泉剑),拍:

| # | 操作 | 预期 | 截图 |
|---|---|---|---|
| 6 | 点底部「强化」按钮 | EnhanceDialog 弹起,**强化** Tab 高亮(Tab 0) | `06_enhance_tab.png` |
| 7 | 关闭 dialog,回详情屏,点底部「开锋」按钮 | EnhanceDialog 弹起,**开锋** Tab 高亮(Tab 1) | `07_forging_tab.png` |

### 3.7 评级标准

按 round1/2/3 体例,每张主截图给 **PASS / WARN / FAIL**:

| 评级 | 标准 |
|---|---|
| PASS | 视觉成立、无截字、信息层级清晰、tier 颜色明显、文案文学性可读 |
| WARN | 排版有小瑕(段间距不对 / chip 挤 / 按钮过宽过窄),但不影响功能 |
| FAIL | 截字 / 文字溢出容器 / 按钮 unclickable / lore 段不渲染 / 颜色错乱 |

5-7 共 6 张主截图(2-5 详情屏 + 6-7 按钮分流);加 1 张仓库列表(3.4)= **7 张目标**。

---

## 4. 红线 · 不要做的事

- ❌ 不动 `lib/` `data/` `test/` 任何文件(本派单纯 GUI 验收)
- ❌ 不跑 widget test / unit test(Mac 端已 627/627 通过,Pen 不必复跑)
- ❌ 不改截图分辨率(固定 1280×900)
- ❌ 不评论 lore 文案质量(那是 DeepSeek 领地,本派单只验视觉/布局)
- ❌ 不评论装备数值是否合理(GDD §5.6 红线,本派单只验渲染)
- ❌ 不打开装备 + 强化按钮 + 实际跑强化(强化 dialog 弹起即停,看到 Tab 高亮就关)

---

## 5. closeout 模板(完成后写)

文件:`docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md`

```markdown
# Codex W15 装备详情屏视觉验收 closeout

## 1. 一句话结论
N 张主截图完成,M/N PASS,K WARN,L FAIL(给出概况)。

## 2. 环境与启动记录
- HEAD: <hash>
- git pull/build/启动 详细命令与结果
- GUI 可见性确认(MainWindowHandle)

## 3. 截图清单与 PASS/FAIL 评级
| # | tier/操作 | 装备/按钮 | 截图路径 | 评级 | 备注 |
| 1 | 仓库列表 | - | docs/screenshots/w15_equipment_detail/01_inventory.png | PASS | 4 tier 分组清晰 |
| 2 | 利器详情 | weapon_liqi_long_quan | 02_liqi_long_quan.png | PASS | 2 段 lore 排版稳... |
| ... | ... | ... | ... | ... | ... |

## 4. 视觉层问题反馈(给 Mac)
- 信息卡 chip 间距 / 颜色 / 排版有无问题
- 典故段段落字号 / 行间距 / 段间「· · ·」分隔效果
- 按钮 [强化]/[开锋] 视觉层级清楚否
- AppBar tier 颜色映射对否

## 5. 节奏层问题反馈(给 Mac)
- Navigator.push 详情屏过渡动画自然否
- 详情屏 → EnhanceDialog 弹起切 Tab 是否顺
- scroll lore 段是否流畅(有无卡顿)

## 6. 工程教训(本会话产)
- 路径上踩了什么坑(GUI 启动 / 截图 / 鼠标点击坐标等)

## 7. 下次推荐
- 是否可收口
- 3 段(重器/宝物/神物)挂账下波 stage drop / craft 验证补
```

---

## 6. 不在本派单处理的事项

- **3 段 lore 渲染验收**(重器/宝物/神物)— P5 不种 tier 5-7,留下波 stage drop / craft 路径打通后再补
- **EquipmentDetailScreen 实际强化 + 开锋流程验收**(本派单只看 Tab 弹起,不操作强化)
- **共鸣度阶段切换可视化**(目前固定 battleCount=0 看不到趁手/默契段,挂账)
- **师承遗物 chip 显示**(P5 起手装备有无 isLineageHeritage 标记,看到拍下来即可,没看到不强求)
- **lore 文学性 polish**(DeepSeek 领地,本派单不评)

---

**派单结束。完成后写 closeout + push 即结束。不联系派单方。Mac 端会在下次同步拉到 closeout + 截图,看视觉评级决定 polish 还是收口。**
