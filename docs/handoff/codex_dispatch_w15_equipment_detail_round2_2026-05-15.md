# Codex 派单 · W15 装备详情屏 round2 视觉验收(3 段 lore + 实际强化)

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows Codex 桌面
> 创建日期:2026-05-15
> 关联上游:HEAD `93288ec`(本派单 fixture 全部已在 main 上)
> round1:`codex_dispatch_w15_equipment_detail_2026-05-15.md` 已 7/7 PASS(2026-05-15 反审纠正)

---

## 1. 一句话目标

补 round1 留挂账:**3 段 lore 渲染(重器/宝物/神物 tier 5-7)+ 实际强化 +1 动画流程**。round1 已验 tier 1-4 的 1-2 段排版,本次用 Mac 端新增的 `seedVisualCheckW15R2` fixture 入 6 件 tier 5-7 装备到背包,Codex 进装备详情屏验 3 段排版 + 点强化 +1 看实际动画。

---

## 2. 背景

### 2.1 round1 留挂账(已纠正)

round1 验收 tier 1-4(P5 起手装):**7/7 PASS**(反审纠正后,详情屏 04 像样货钢刀 1 段是 W15 #35 派单 §3.2 规定非漏配)。**3 段 lore(tier 5-7 重器/宝物/神物)** + **实际强化流程** + **共鸣度阶段切换** + **师承遗物 chip** 共 4 项留下波,本派单解前 2 项硬目标 + 后 2 项捎带观察。

### 2.2 Mac 端 round2 fixture 已落

- `seedVisualCheckW15R2`(`lib/services/phase2_seed_service.dart`):基于 `seedVisualCheckW7W11`(P5 + Ch1 cleared)额外入 **6 件 tier 5-7** 装备到背包(祖师 owner 但不入 equippedXxxId — GDD §5.3 境界一流锁死,tier 5-7 只能背包看,不可装备到角色)
- Phase2TestMenu 第 9 按钮「**VC15-r2 · tier 5-7 装备入背包**」push 直进 InventoryScreen
- 6 件覆盖 weapon/armor/accessory × tier 5/6/7:
  - 重器(tier 5):`weapon_zhongqi_qing_xu_jian`(青虚剑)/ `armor_zhongqi_yin_lin_jia`(银鳞甲)
  - 宝物(tier 6):`weapon_baowu_chang_hong_jian`(长虹剑)/ `armor_baowu_jin_si_jia`(金丝甲)
  - 神物(tier 7):`weapon_shenwu_tian_wen_jian`(天问剑)/ `accessory_shenwu_kun_lun_pei`(昆仑佩)
- 633/633 测试 + analyze 0 issues

### 2.3 为什么仍需真机视觉验收

3 段 lore 排版只有 真机 + lore yaml `default_lore` 多段长度跑通才看得到「◇ 典故 ◇」标题 + 段间「· · ·」分隔 + 段落字号 + scroll 流畅度。强化 +1 动画也是真机才有的视觉(widget test 只验逻辑)。

---

## 3. 任务清单

### 3.1 启动准备(沿用 round1 工程教训)

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
# 应到 HEAD 93288ec 或更新

dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug
```

### 3.2 启 GUI(round1 验证成功路径)

```powershell
Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe
```

启后 `Get-Process wuxia_idle` 拿 `MainWindowHandle` 非 0 = GUI 可见。窗口固定 `1280 × 900`,截图前 `SetWindowPos(HWND_TOPMOST)` 防抢前台。

### 3.3 种 9 + 6 件装备(VC15-r2)

主菜单 → **Phase 2 调试场景** → **VC15-r2 · tier 5-7 装备入背包**(第 9 按钮,最下方)

按完直接 push 到 **InventoryScreen**(装备仓库),不再回主菜单。

应见 ExpansionTile 按 tier 分组:**神物(2)/ 宝物(2)/ 重器(2)/ 利器(1)/ 好家伙(3)/ 像样货(3)/ 寻常货(2)** 共 15 件。

**截图 1**:仓库列表(全部 tier 分组展开,可滚动到底见 7 阶分组),`docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png`

如 tier 分组未自动展开,手动逐个点开 expand。

### 3.4 进 6 件 tier 5-7 装备详情屏(6 张主截图)

**重点:tier 5-7 lore 段数 GDD §6.6 标准为 3 段**,本批主验 3 段排版完整性。

逐个点击 row 进详情屏,每件拍 1 张主截图(信息卡 + 典故段顶部 + 至少看到「◇ 典故 ◇」+ 段一前几行):

| # | tier | slot | 装备 id | 预期段数 | 截图路径 |
|---|---|---|---|---|---|
| 2 | 神物 | weapon | weapon_shenwu_tian_wen_jian(天问剑)| 3 段 | `02_shenwu_tian_wen_jian.png` |
| 3 | 神物 | accessory | accessory_shenwu_kun_lun_pei(昆仑佩)| 3 段 | `03_shenwu_kun_lun_pei.png` |
| 4 | 宝物 | weapon | weapon_baowu_chang_hong_jian(长虹剑)| 3 段 | `04_baowu_chang_hong_jian.png` |
| 5 | 宝物 | armor | armor_baowu_jin_si_jia(金丝甲)| 3 段 | `05_baowu_jin_si_jia.png` |
| 6 | 重器 | weapon | weapon_zhongqi_qing_xu_jian(青虚剑)| 3 段 | `06_zhongqi_qing_xu_jian.png` |
| 7 | 重器 | armor | armor_zhongqi_yin_lin_jia(银鳞甲)| 3 段 | `07_zhongqi_yin_lin_jia.png` |

**截图要求**(每张):
- 详情屏 1280×900 内完整可见(AppBar + 信息卡 + 典故段 + 底部按钮)
- 如典故段需要 scroll,主截图取顶部「◇ 典故 ◇」标题 + 段一前几行,**可选**:对天问剑/长虹剑神物级 3 段 lore 额外拍 1 张 scroll 到底的截图看完整 3 段渲染(命名 `02b_shenwu_tian_wen_jian_scroll.png` 等,**不强制**)
- 段间「· · ·」分隔符出现在视野内拍到即好

存 `docs/screenshots/w15_equipment_detail_round2/`(新建目录),命名按上表。

### 3.5 实际强化流程(2 张验证截图)

回任一详情屏(推荐 **重器·青虚剑**,tier 5 是 P5 玩家 `realmTier=erLiu` 二流境界**最大可装备阶**,如果 GDD 锁死 OK 则锁死,如果走不通直接拍 SnackBar 报错也算 PASS):

| # | 操作 | 预期 | 截图 |
|---|---|---|---|
| 8 | 点底部「强化」按钮 | EnhanceDialog 弹起,**强化** Tab 高亮 | `08_enhance_open.png` |
| 9 | dialog 内点「+1 强化」 | 成功:enhanceLevel 0→1 + 数值变化 + 动画;失败:墨剑石不够 SnackBar | `09_enhance_plus1.png` |

**预期**:**P5 已含 2000 墨剑石 + 200 心血结晶**,+1 强化消耗 ~10-30 墨剑石,**正常成功路径**(若 round1 fixture seed 完整运转)。如失败,拍下错误状态即可,不视为 FAIL。

### 3.6 共鸣度 chip / 师承遗物 chip 观察(顺手)

- **共鸣度阶段**:P5 起手 battleCount=0,详情屏共鸣度 chip 应显示「生疏」起步阶段。看到拍下来,信息卡中能见即好,**不专门拍**。
- **师承遗物 chip**:`weapon_liqi_long_quan`(龙泉剑)和 `armor_haojiahuo_jin_pao`(锦袍)是 W15 #35 派单 §3.4 明文师承遗物。如详情屏信息卡显示 `isLineageHeritage` chip(可能叫「师承」「遗物」「传承」之类),回 round1 的 龙泉剑/锦袍 详情屏拍 1 张额外截图 `10_lineage_chip.png`。**找不到的话写 N/A 不强求**。

### 3.7 评级标准

按 round1 体例,每张主截图 `PASS / WARN / FAIL`:

| 评级 | 标准 |
|---|---|
| PASS | 视觉成立、无截字、信息层级清晰、tier 颜色明显、3 段 lore 完整 + 分隔符成立 |
| WARN | 排版小瑕(段间距不对 / chip 挤 / 按钮过宽过窄 / 3 段中第 3 段截字 scroll 后才可见),功能不影响 |
| FAIL | 截字 / 文字溢出容器 / 按钮 unclickable / lore 段不渲染 / 颜色错乱 / 强化 +1 无反应 |

6 张 tier 5-7 主截图 + 1 张仓库列表 + 2 张强化流程 = **9 张目标**。可选 +3 张 scroll/lineage = 12 张上限。

---

## 4. 红线 · 不要做的事

- ❌ 不动 `lib/` `data/` `test/` 任何文件(本派单纯 GUI 验收)
- ❌ 不跑 widget test / unit test(Mac 端已 633/633 通过)
- ❌ 不改截图分辨率(固定 1280×900)
- ❌ 不评论 lore 文案质量(那是 DeepSeek 领地,本派单只验视觉/布局)
- ❌ 不装备 tier 5-7 装备到 P5 角色(境界一流锁死 GDD §5.3,fixture 已遵守)
- ❌ 不跑 +2 / +3 多次强化(只看 0→1 第一档动画即停)
- ❌ 不评论装备数值是否合理(GDD §5.4 红线,本派单只验渲染)

---

## 5. closeout 模板(完成后写)

文件:`docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md`

```markdown
# Codex W15 装备详情屏 round2 视觉验收 closeout

## 1. 一句话结论
N 张主截图完成,M/N PASS,K WARN,L FAIL(给出概况)。

## 2. 环境与启动记录
- HEAD: <hash>
- git pull/build/启动 详细命令与结果
- GUI 可见性确认(MainWindowHandle)

## 3. 截图清单与 PASS/FAIL 评级
| # | tier/操作 | 装备/按钮 | 截图路径 | 评级 | 备注 |
| 1 | 仓库列表 | 15 件 | docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png | PASS | 7 tier 分组... |
| 2 | 神物·天问剑 | 3 段 | 02_shenwu_tian_wen_jian.png | PASS | 神物级 3 段排版... |
| ... | ... | ... | ... | ... | ... |
| 8 | 强化按钮 tap | EnhanceDialog 弹起 | 08_enhance_open.png | PASS | Tab 高亮 |
| 9 | +1 强化 | 0→1 动画 | 09_enhance_plus1.png | PASS | 墨剑石扣 N 颗 |

## 4. 3 段 lore 排版反馈(本批重点)
- 段一/段二/段三视觉成立否
- 段间「· · ·」分隔符位置合理否
- 神物级 vs 宝物级 vs 重器级有无视觉差异(理论上同样 3 段,字数可能不同)
- scroll 流畅否

## 5. 强化流程反馈
- 强化按钮 → EnhanceDialog 弹起动画
- +1 强化数值变化是否 animation(还是 jump)
- 墨剑石 / 心血结晶扣除可见性

## 6. 共鸣度 chip / 师承遗物 chip(顺手)
- 信息卡共鸣度阶段 chip 是否 visible
- 师承遗物 chip 找到否(在哪件装备上)

## 7. 工程教训(本会话产)
- 路径上踩了什么坑(GUI 启动 / 截图 / 鼠标点击坐标等)

## 8. 下次推荐
- 是否可收口
- 共鸣度阶段切换 / 多次强化 / 开锋槽 build 留挂账
```

---

## 6. 不在本派单处理的事项

- **共鸣度阶段切换**(生疏 → 顺手 → 默契)需要 battleCount 累计跑战斗,本派单不跑(挂账)
- **+2 → +19 多次强化动画**(挂账,本批只看 0→1)
- **开锋 Tab 槽 build 流程**(round1 仅看 Tab 弹起,本派单也不深入)
- **stage drop 视觉验收**(#34,Pen 屏幕高度问题挂账)
- **lore 文学性 polish**(DeepSeek 领地,本派单不评)

---

**派单结束。完成后写 closeout + push 即结束。不联系派单方。Mac 端会在下次同步拉到 closeout + 截图,看视觉评级决定 polish 还是收口。**
