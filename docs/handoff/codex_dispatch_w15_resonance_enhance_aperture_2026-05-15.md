# Codex 派单 · W15 共鸣度 / 强化里程碑 / 开锋槽 build 视觉验收

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows Codex 桌面
> 创建日期:2026-05-15
> 关联上游:本派单 fixture 与 spec 同一 commit 落 main(派单 push 后告知 HEAD)
> 前序:`codex_dispatch_w15_equipment_detail_round2_2026-05-15.md` 已 9/9 闭环(round2 closeout §8 留挂账 → 本派单)

---

## 1. 一句话目标

补 round2 留挂账三项硬目标:**共鸣度阶段切换 / 多次强化里程碑 / 开锋槽 build**。Mac 端已落 `seedVisualCheckW15Resonance` fixture(6 件武器覆盖 4 共鸣阶段 + 5 强化等级 + 4 开锋槽数),Codex 进 InventoryScreen + 装备详情屏验视觉。

---

## 2. 背景

### 2.1 round2 留挂账(3 项)

round2 闭环时挂账(closeout §8):
1. **共鸣度阶段切换**(生疏/趁手/默契/心剑通灵)— round2 fixture 全是 battleCount=0 起步,看不到非「生疏」chip
2. **多次强化里程碑**(+0/+5/+10/+15/+19)— round2 仅看 0→1 第一档,中段不可视
3. **开锋槽 build**(0/1/2/3 槽)— round2 仅看 Tab 弹起,槽位 unlocked/locked 区分未验

本派单一次性覆盖三维度 + 顺手验师承遗物 chip。

### 2.2 Mac 端 fixture 已落

- `seedVisualCheckW15Resonance`(`lib/services/phase2_seed_service.dart`):基于 `seedVisualCheckW7W11`(P5 + Ch1 cleared)额外入 **6 件武器**到背包(`ownerCharacterId=1` 祖师持有但**不入 equippedXxxId** — 与 W15-r2 体例延续)
- Phase2TestMenu 第 10 按钮「**VC15-res · 共鸣/强化/开锋光谱**」push 直进 InventoryScreen
- 637/637 测试(W15-r2 基础 633 → +4),analyze 0 issues

### 2.3 6 件覆盖矩阵

| # | tier | defId | battleCount | enhance | 开锋槽 | 共鸣段 | 师承遗物 |
|---|---|---|---|---|---|---|---|
| 1 | 寻常货 | weapon_xunchang_tie_jian | 0 | 0 | 0 | 生疏 | 否 |
| 2 | 像样货 | weapon_xiangyang_chang_jian | 200 | 5 | 0 | 趁手 +10% | 否 |
| 3 | 好家伙 | weapon_haojiahuo_xuan_hua_fu | 800 | 10 | 1(attack) | 默契 +20% | 否 |
| 4 | 利器 | weapon_liqi_pan_long_dao | 2500 | 15 | 2(attack/speed) | 心剑通灵 +30% | **是** |
| 5 | 重器 | weapon_zhongqi_qing_xu_jian | 1500 | 19 | 3(attack/speed/specialSkill) | 默契 | 否 |
| 6 | 神物 | weapon_shenwu_tian_wen_jian | 5000 | 0 | 0 | 心剑通灵 | 否 |

**defId 避坑**:6 件全部与 P5 师徒 `starting_equipment` 不重复,InventoryScreen 不会显示同 defId 两件造成 Codex 困惑。

### 2.4 共鸣度阶段定义(numbers.yaml `equipment.resonance.stages`)

| 阶段 | battleCount 区间 | bonus | 备注 |
|---|---|---|---|
| 生疏 shengShu | [0, 100) | 1.0× | 起步 |
| 趁手 chenShou | [100, 500) | 1.10× | +10% |
| 默契 moQi | [500, 2000) | 1.20× | +20%,解锁人剑合一 |
| 心剑通灵 xinJianTongLing | [2000, ∞) | 1.30× | +30%,剑鸣特效 |

### 2.5 开锋槽配置(numbers.yaml `equipment.forging.slots`)

- slot1 解锁 at +10:type=attack,bonus=15
- slot2 解锁 at +15:type=speed,bonus=20(与 slot1 不同 type)
- slot3 解锁 at +19:type=specialSkill,bonus=1(`specialSkillId=null`,仅看槽位 unlocked + chip)

---

## 3. 任务清单

### 3.1 启动准备

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
# 应到 HEAD <派单方告知>

dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug
```

### 3.2 启 GUI

```powershell
Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe
```

启后 `Get-Process wuxia_idle` 拿 `MainWindowHandle` 非 0 = GUI 可见。窗口 1280×900。

### 3.3 种 fixture(VC15-res)

主菜单 → **Phase 2 调试场景** → **VC15-res · 共鸣/强化/开锋光谱**(第 10 按钮,最下方)

按完直接 push 到 **InventoryScreen**。

应见 ExpansionTile 按 tier 分组:**神物(1)/ 重器(1)/ 利器(1)/ 好家伙(1)/ 像样货(1)/ 寻常货(1) + P5 起手 9 件** = 15 件武器/防具/饰品合计(P5 起手 9 件 + fixture 6 件武器)。

**截图 1**:仓库列表(滚动到底见 7 阶分组),`docs/screenshots/w15_resonance/01_inventory_15_eq.png`

### 3.4 6 件武器详情屏 · 共鸣度 / 强化等级 chip(6 张主截图)

逐个 row tap 进详情屏。**信息卡区域必须能看到 3 个关键 chip**:
- **强化等级**:`+N`(N=0/5/10/15/19)
- **共鸣度阶段**:中文 chip(「生疏」「趁手」「默契」「心剑通灵」)
- **战斗次数**:`战斗 N 次`(N=0/200/800/1500/2500/5000)

| # | 装备 | 预期 chip 组合 | 截图 |
|---|---|---|---|
| 2 | 寻常货·铁剑(weapon_xunchang_tie_jian)| +0 / 生疏 / 0 次 | `02_xunchang_shengshu_plus0.png` |
| 3 | 像样货·长剑(weapon_xiangyang_chang_jian)| +5 / 趁手 / 200 次 | `03_xiangyang_chenshou_plus5.png` |
| 4 | 好家伙·宣花斧(weapon_haojiahuo_xuan_hua_fu)| +10 / 默契 / 800 次 | `04_haojiahuo_moqi_plus10.png` |
| 5 | 利器·蟠龙刀(weapon_liqi_pan_long_dao)| +15 / 心剑通灵 / 2500 次 + **师承遗物 chip** | `05_liqi_xinjian_plus15_heritage.png` |
| 6 | 重器·青虚剑(weapon_zhongqi_qing_xu_jian)| +19 / 默契 / 1500 次 | `06_zhongqi_moqi_plus19.png` |
| 7 | 神物·天问剑(weapon_shenwu_tian_wen_jian)| +0 / 心剑通灵 / 5000 次 | `07_shenwu_xinjian_plus0.png` |

**截图要求**(每张):
- 详情屏 1280×900 完整可见(AppBar + 信息卡含 chip 区 + 典故段顶部)
- chip 区清晰可读 — 这是本批主要验收目标
- 5 号截图额外标记师承遗物 chip(命名含 `_heritage`)

存 `docs/screenshots/w15_resonance/`(新建目录)。

### 3.5 开锋槽 build · forging Tab(4 张验证截图)

回 4 件不同开锋槽数装备的详情屏,点底部「**开锋**」按钮 → EnhanceDialog 弹起,**开锋** Tab 高亮(`initialTab=1`),Tab 内应看到 3 槽列表(slot1/slot2/slot3 各占一行,unlocked/locked 状态分明)。

| # | 装备 | 预期开锋槽显示 | 截图 |
|---|---|---|---|
| 8 | 寻常货·铁剑(0 槽,+0) | slot1/2/3 **全锁**(灰 + 提示「强化到 +N 解锁」) | `08_aperture_zero_slots.png` |
| 9 | 好家伙·宣花斧(1 槽,+10) | slot1 **unlocked + attack +15%** chip;slot2/3 锁 | `09_aperture_one_slot_attack.png` |
| 10 | 利器·蟠龙刀(2 槽,+15) | slot1 attack / slot2 **unlocked + speed +20%**;slot3 锁 | `10_aperture_two_slots.png` |
| 11 | 重器·青虚剑(3 槽,+19) | slot1 attack / slot2 speed / slot3 **unlocked + specialSkill** | `11_aperture_three_slots_full.png` |

**截图要求**:
- 开锋 Tab 弹起 dialog 完整可见,3 槽行清晰
- 已 unlocked 槽与 locked 槽视觉对比(灰 vs 高亮 + type chip + bonus 数值)
- slot3 specialSkill 槽不要求显具体 skill 名(`specialSkillId=null`),只看槽位 unlocked + chip 标签

### 3.6 共鸣度阶段切换横向对比(1 张总览截图,可选)

如果 InventoryScreen 在 row 上能看到共鸣度 chip(不进详情屏就能看),拍 1 张能同时看到 4 种共鸣 chip(生疏/趁手/默契/心剑通灵)的列表截图,`12_inventory_resonance_overview.png`。

**找不到 row 上的 chip 写 N/A 不强求** — 详情屏 6 张已覆盖横向。

### 3.7 评级标准

每张主截图 `PASS / WARN / FAIL`:

| 评级 | 标准 |
|---|---|
| PASS | chip 组合视觉成立、无截字、共鸣度文案对、强化等级 +N 数字对、开锋槽 unlocked/locked 区分明显 |
| WARN | chip 排版小瑕(挤 / 截字 / 颜色不分),但语义正确 |
| FAIL | chip 缺失 / 共鸣度阶段文案与 battleCount 不匹配 / 强化等级 chip 缺失 / 开锋 Tab 槽位状态错乱 / 师承遗物 chip 完全没渲染 |

**11 张主截图**(1 仓库 + 6 详情屏 chip + 4 开锋槽)+ 可选 1 张共鸣 overview = 11-12 张目标。

### 3.8 GUI 鼠标 row click 不稳定的 fallback(round2 教训沿用)

round2 closeout §7 工程教训记:**Pen Windows 真 GUI 鼠标 row click 在 InventoryScreen ExpansionTile 内不稳定**。

如本派单 row click 也走不通,Codex 可走 round2 同款 **widget 视觉捕获 fallback** 路径:
- 临时写一个简易 widget host,直接 push EquipmentDetailScreen + 强化 Tab,绕过 GUI 路径
- 截图用 widget pump + CopyFromScreen 兜底
- closeout 章节注明走 fallback(不视为 FAIL,本批接受 widget 捕获)

但**首选**真 GUI 路径,fallback 是兜底。

---

## 4. 红线 · 不要做的事

- ❌ 不动 `lib/` `data/` `test/` 任何文件(纯 GUI 验收)
- ❌ 不跑 widget test / unit test(Mac 端 637/637)
- ❌ 不改截图分辨率(固定 1280×900)
- ❌ 不评论 lore 文案 / 数值平衡(那不是本派单范围)
- ❌ 不装备 fixture 6 件到 P5 角色(本批只看背包 + 详情屏)
- ❌ 不真跑强化 +1 操作(强化里程碑用 fixture 直接预设,**不点强化按钮触发实际 +1**)
- ❌ 不真跑开锋 build(开锋槽 build 用 fixture 直接预设,**不点开锋按钮触发实际开锋**)
- ❌ 不破坏 fixture seed(VC15-res 是只读视觉验收,不要 navigator pop 回主菜单再 reseed 别的)

---

## 5. closeout 模板(完成后写)

文件:`docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md`

```markdown
# Codex W15 共鸣/强化/开锋视觉验收 closeout

## 1. 一句话结论
N 张主截图完成,M/N PASS,K WARN,L FAIL(给出概况)。

## 2. 环境与启动记录
- HEAD: <hash>
- git pull/build/启动 详细命令与结果
- GUI 可见性确认(MainWindowHandle)
- 是否走 widget fallback(round2 教训)

## 3. 截图清单与 PASS/FAIL 评级
| # | 类别 | 装备/操作 | 预期 chip 组合 | 截图路径 | 评级 | 备注 |
| 1 | 仓库列表 | 15 件 | tier 7 分组可见 | 01_inventory_15_eq.png | PASS | ... |
| 2 | 详情屏 chip | 寻常货·铁剑 | +0 / 生疏 / 0 次 | 02_xunchang_shengshu_plus0.png | PASS | ... |
| ... | ... | ... | ... | ... | ... | ... |
| 8 | 开锋槽 | 铁剑 0 槽 | 3 槽全锁 | 08_aperture_zero_slots.png | PASS | ... |
| ... | ... | ... | ... | ... | ... | ... |

## 4. 共鸣度阶段切换反馈(本批重点 A)
- 4 阶段文案对得上 battleCount 吗(生疏[0,100)/ 趁手[100,500)/ 默契[500,2000)/ 心剑通灵[2000,∞))
- chip 颜色 / 字号 / 排版区分度
- 「战斗 N 次」数字 chip 与共鸣度 chip 同行成立否

## 5. 多次强化里程碑反馈(本批重点 B)
- +0/+5/+10/+15/+19 五档 chip 显示一致否
- 强化等级 chip 与 baseAttack/baseHealth/baseSpeed 数值是否联动可见
- (顺手)+19 装备 vs +0 装备的视觉对比

## 6. 开锋槽 build 反馈(本批重点 C)
- 0/1/2/3 槽四档 unlocked/locked 区分明显否
- attack/speed/specialSkill 三种 type chip 文案 + 颜色
- bonus 数值(+15% / +20% / specialSkill 占位)显示位置

## 7. 师承遗物 chip 顺手观察
- 5 号利器·蟠龙刀的师承遗物 chip 找到否
- chip 文案 / 颜色 / 位置(与共鸣度 chip 是同行还是同区)
- 是否有「内力上限 +5%」buff 行(若 UI 已渲染)

## 8. 工程教训(本会话产)
- GUI 启动 / 截图 / 鼠标点击坐标新踩坑
- 是否走 widget fallback(round2 教训沿用情况)

## 9. 下次推荐
- 是否可收口本批 3 项挂账
- 真 GUI 鼠标 row click 稳定化(round2 §7 + 本批观察)
- 其他余项
```

---

## 6. 不在本派单处理的事项

- **真跑强化 +1 → +N 多档动画**(挂账,本批用预设)
- **真跑开锋 build 操作**(挂账,本批用预设)
- **跨阶段 battleCount 累计真跑战斗**(挂账,本批用预设)
- **stage drop 视觉验收**(#34,Pen 屏幕高度问题挂账)
- **lore 文学性 polish**(DeepSeek 领地,本派单不评)

---

**派单结束。完成后写 closeout + push 即结束。不联系派单方。Mac 端会在下次同步拉到 closeout + 截图,看视觉评级决定 polish 还是收口。**
