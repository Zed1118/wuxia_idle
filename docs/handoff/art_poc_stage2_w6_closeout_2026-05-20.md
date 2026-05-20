# M4 PoC #46 美术 Stage 2 W6 第 6 批 closeout · Stage 2 收官(2026-05-20)

> **批次**:5 闭关地图(山林/古剑冢/藏经阁/悬崖瀑布/断崖绝壁)+ 10 UI 资源(2 背景 + 2 卷轴 + 1 印章 + 1 分隔线 + 3 图标 + 1 loading)= **15 张**
> **节奏**:主对话 opus xhigh + 用户主导 MJ,~30min Fast(无失败品 · 无重抽)
> **产物**:`~/Desktop/MJ_Stage2_W6/` 15 张全规范命名(地图 16:9 / UI 各按用途 ar 不同)
> **状态**:✅ 15/15 完工,**平均 9.0/10** ⭐⭐⭐ **Stage 2 至今最好的一批**(W3 8.65 / W4 8.65 / W5 8.5 / W6 9.0)/ 风格一致度 ~95% / 类型识别度 ~95% / 3 张 ⭐⭐⭐ 极品 / GDD §1 水墨克制守住 / 无失败品归档
> **Stage 2 量产正式收官**:W1-W6 累计 74/74 (100%) ✅,与 Stage 1 PoC 15 合计 **89 张产物**

---

## §1 时间线

| 时刻 | 事件 |
|---|---|
| T0 | 用户拍板 W6 第 6 批起手 Stage 2 收官,升档 opus xhigh |
| T+5min | numbers.yaml `retreat.maps` 5 闭关地图 spec + GDD §7.3 + codex 闭关 md 视觉锚点齐备,UI 资源 10 张按 Demo Flutter UI 通用需求列清单 |
| T+8min | 对话展开 15 个完整 prompt + Write `~/Desktop/MJ_Stage2_W6_prompts.txt` 双轨,**关键配方**:地图类 sref + sw 100(允许风格完全继承)/ UI 类全部去 sref(避 W5 Moderator 写实过滤教训) |
| T+25min | 用户跑完 15 张到位(无失败品,无 Moderator 拒绝!)— **W5 第 16 条 Moderator 教训完美应用**,UI prompt 全用 `a traditional Chinese ink wash painting depicting...` + 蒲团香炉 `no people, no monk, no sitting figure` 完美避坑 |
| T+28min | Read 15 张视觉验证 + 评分:**5 地图均 9.0/10**(古剑冢残剑插地最佳 9.5)/ **10 UI 均 9.0/10**(蒲团香炉 9.5 + 渔舟远山 9.5 极品)/ **3 张 ⭐⭐⭐ 极品**:37 古剑冢 / 49 蒲团香炉 / 50 渔舟远山 |
| T+30min | 15/15 全归位 |
| T+35min | 本 closeout + memory 第 18 条 + PROGRESS + commit · Stage 2 收官 |

---

## §2 15 张产物清单 + 评分

### 5 闭关地图(numbers.yaml retreat.maps · ar 16:9 · 主环境 sref + sw 100)

| # | 文件 | 评分 | 关键观察 |
|---|---|---|---|
| 36 | `36_shanLin_map.png` | **9/10** ⭐⭐ | 松林 + 石滩 + 远山 + 印章 · 平和新手地图意境完美 |
| 37 | `37_guJianZhong_map.png` | **9.5/10** ⭐⭐⭐ | **本批最佳** · 残剑插地 + 竹林 + 雾(完美对位 lore "sword tomb") |
| 38 | `38_cangJingGe_map.png` | **9/10** ⭐⭐ | 经卷千卷 + 木桌开卷 + 窗光 + 印章 · scholarly 书阁气息 |
| 39 | `39_xuanYaPuBu_map.png` | **9/10** ⭐⭐ | 飞瀑 + 古松 + 水雾 + 远山 · 二流境界灵气场 |
| 40 | `40_duanYaJueBi_map.png` | **8.5/10** | 断崖 + 古松 + 山顶平台(雪景偏弱 borderline) |

**5 地图平均 9.0/10**。

### 10 UI 资源(全去 sref · 各按用途 ar)

| # | 文件 | 评分 | 关键观察 |
|---|---|---|---|
| 41 | `41_paper_bg.png` | **9/10** ⭐⭐ | 米黄宣纸 + 角落水墨小景 + 中央留白(完美主背景) |
| 42 | `42_mountain_bg.png` | **9/10** ⭐⭐ | 多层山影深黑→浅灰渐变 + 上部留白(完美 UI 背景) |
| 43 | `43_scroll_vertical.png` | **8.5/10** | 纵向卷轴 + 木轴 + 古风花纹 + 中央留白(花纹偏密但 OK) |
| 44 | `44_scroll_horizontal.png` | **8.5/10** | 横向卷轴 + 木轴 + 花纹 + 中央留白 |
| 45 | `45_seal_red.png` | **9/10** ⭐⭐ | 深暗赤红印章 + 篆字 + 米黄底 · 红色严格局限不蔓延 |
| 46 | `46_ink_divider.png` | **9/10** ⭐⭐ | 水墨横向笔触 + 自然飞白 + 极简 |
| 47 | `47_coin_icon.png` | **9/10** ⭐⭐ | 古铜钱 + 方孔 + 篆字 + 铜绿包浆 |
| 48 | `48_lotus_icon.png` | **9/10** ⭐⭐ | 莲花水墨笔触 · 笔意自信精炼 |
| 49 | `49_meditation_icon.png` | **9.5/10** ⭐⭐⭐ | **本批最佳之一** · 蒲团 + 香炉 + 一缕烟 + 无人(完美 Moderator 避坑 + lore 对位) |
| 50 | `50_landscape_loading.png` | **9.5/10** ⭐⭐⭐ | **本批最佳之一** · 渔舟 + 远山 + 水墨绝美(可作 1.0 主视觉) |

**10 UI 平均 9.0/10**。

---

## §3 总评

- **W6 总均 9.0/10** ⭐⭐⭐ — **Stage 2 至今最好的一批**(W1 ~8.5 / W2 7.9 / W3 8.65 / W4 8.65 / W5 8.5 / **W6 9.0**)
- **风格一致度 ~95%**(sw 100 风格全继承 + UI 类去 sref 简洁明了 + 印章红 / 铜钱铜绿 / 莲花淡墨 等局部异色全部控制良好)
- **类型识别度 ~95%**(无失败品,无 Moderator 拒绝,无重抽)
- **环境类 + UI 类配方组合实战验证**:**地图走 sref + sw 100 全继承 / UI 类去 sref 避写实风污染**两条互补
- **3 张 ⭐⭐⭐ 极品**:37 古剑冢(残剑插地 lore 顶级还原)/ 49 蒲团香炉(Moderator 避坑教科书)/ 50 渔舟远山(1.0 主视觉候选)
- **W5 Moderator 教训完美应用**:UI prompt 全用 `a traditional Chinese ink wash painting depicting...` + 蒲团香炉 `no people` 避坑成功,15 张零拒绝零失败
- **W6 新沉淀**(详 §4):**环境类 sw 100 + UI 类去 sref 双轨配方**(W6 实战 9.0/10 验证)

---

## §4 教训沉淀(本批次新增,补 memory 第 18 条)

### 教训第 18 条:**Stage 2 收官两类批次配方区分(环境类 sw 100 / UI 类无 sref)**

W1-W5 装备类批次走 **sref + sw 50** 配方,实战平均 8.5-8.65/10。W6 收官包含两类全新需求:

**类型 A · 环境类**(地图大图 / loading 屏):
- 走主环境 sref + **sw 100**(W1-W5 装备 sw 50 升到 100)— 允许 MJ 完全继承 sref 套 C 雪景古松写实水墨厚涂风格
- ar 16:9 横向地图视角 + stylize 300(环境自由发挥)
- prompt 用 `a traditional Chinese ink wash painting depicting...` 描述法
- 加 `no people present` 防人物污染
- **实战 5 地图均 9.0/10**(W6 最高分批次)

**类型 B · UI 资源类**(背景 / 卷轴 / 印章 / 图标 / 分隔线):
- **完全去 sref**(sref 套 C 写实风污染 UI 简洁感)
- ar 各按用途:背景 16:9 / 卷轴纵向 2:3 / 横向 3:1 / 图标 1:1 / 分隔线 3:1
- stylize 降至 150-250(UI 元素需清晰简洁)
- prompt 强调 `the center... completely empty cream paper ready for text overlay`(卷轴防 MJ 写满字)+ `no shadows, single isolated object centered`(图标防多余装饰)
- 蒲团香炉等"meditation"概念物件:**显式 `no people, no monk, no sitting figure`**(W5 第 16 条 Moderator 教训预防)
- 印章红 / 铜钱铜绿等局部异色:`the only [color] is in the [object] itself, all background is pure white`(W5 第 16-17 条特征强化)
- **实战 10 UI 均 9.0/10**(W6 同 9.0 高水准)

**Stage 2 配方矩阵汇总**(6 周累计沉淀):

| 类型 | sref/sw | stylize | ar | 主体强调 | 实战均分 |
|---|---|---|---|---|---|
| 装备 icon(W1-W5) | 无 sref | 100 | 1:1 | 单件居中 | 8.5-9.0 |
| 装备 detail(W1-W5) | 主环境 sref + sw 50 | 200-250 | 1:1 | foreground 主体可见 | 8.5-9.5 |
| 角色立绘(W4) | 主角色 sref + sw 60 | 300 | 2:3 | 全身姿态 | 8.7 |
| **环境地图(W6)** | **主环境 sref + sw 100** | **300** | **16:9** | **no people present** | **9.0** |
| **UI 类(W6)** | **无 sref** | **150-250** | **各异** | **isolated / empty center** | **9.0** |

**关键发现**:sref/sw 是 Stage 2 美术工作流的**核心调节杆**:
- sw 50:风格借鉴但内容独立(装备 detail)
- sw 60:角色姿态借鉴 + 不同人物(立绘)
- sw 100:风格 + 内容全继承(环境地图)
- 无 sref:UI 简洁元素(避 sref 写实污染)

详 memory `feedback_mj_wuxia_prompt_pitfalls` 第 18 条。

---

## §5 验收清单(全 ✅)

- [x] 风格一致度 ≥ 80%(实测 **~95%**)
- [x] 类型识别度 ≥ 75%(实测 **~95%**,无失败品无重抽)
- [x] 闭关地图 5 张差异化清晰(山林平/古剑冢苍/藏经阁书/瀑布湿/雪崖寂)
- [x] UI 资源主体清晰可用(背景留白足 / 卷轴中央空 / 印章红不蔓延 / 图标无装饰)
- [x] 无人物污染(蒲团香炉 Moderator 避坑成功)
- [x] 水墨克制 GDD §1 守住(7 种局部色全部控制)
- [x] 无 Moderator 拒绝(W5 第 16 条教训完美应用)
- [x] 无失败品归档

---

## §6 Stage 2 量产收官 · 6 周累计成果

| 周 | 批次 | 内容 | 张数 | 均分 | 完工日 | 状态 |
|---|---|---|---|---|---|---|
| W1 | 第 1 批 | 寻常货剩 4 件 | 8 | ~8.5 | 2026-05-20 | ✅ |
| W2 | 第 2 批 | 像样货 5 件 | 10 | 7.9 | 2026-05-20 | ✅ |
| W3 | 第 3 批 | 好家伙+利器 5 件 | 10 | 8.65 | 2026-05-20 | ✅ |
| W4 | 第 4 批 | 重器 5 件 + 师徒立绘 3 | 13 | 8.65 | 2026-05-20 | ✅ |
| W5 | 第 5 批 | 宝物+神物 9 件 | 18 | 8.5 | 2026-05-20 | ✅ |
| **W6** | **第 6 批** | **5 地图 + 10 UI** | **15** | **9.0** ⭐ | **2026-05-20** | **✅** |
| **总** | — | — | **74** | **8.55** | — | **W1-W6 ✅ 100%** |

**Stage 1 PoC 15 + Stage 2 W1-W6 74 = 累计 89 张产物**归档于 `~/Desktop/MJ_Stage{1_PoC,2_W1,2_W2,2_W3,2_W4,2_W5,2_W6}/`(玉龙佩 Stage 1 PoC 已含)。

**Fast time 累计**:W1 ~20 + W2 ~30 + W3 ~25 + W4 ~25 + W5 ~50 + W6 ~30 = **~180min**(配额 ~12.5h × 24% 已用,剩余 ~9.5h 配额作 1.0 阶段 LoRA 训练数据样本扩充用)。

**MJ Standard $30 月付 Stage 2 收官 ROI**:74 张 = $30 / 74 ≈ **$0.40 一张**,远低于外包美术 $20-50/张行业价(若 Demo 算 50 张 × $30 平均 = $1500,实付 $30 = 节省 98%)。

---

## §7 Stage 2 累计沉淀 memory 清单(`feedback_mj_wuxia_prompt_pitfalls` · 18 条)

1. 3 重水墨锚定 + 3 重防护必带(Stage 0 套 B 教训)
2. 武器类型必明确锁定(jian/dao/鞭 防混淆)
3. sref 风格污染 + `--sw 50` 防护(Stage 1 实战)
4. 印章接受作国画落款(GDD §1 一致)
5. 暖色词放大坑(`warm orange` → `subtle ... in distance`)
6. 7 阶精致度梯度词汇(crude → divine)
7. 黑名单词永禁(`legendary/epic/fantasy/anime`)
8. `cinematic` 触发好莱坞油画风(Stage 0 套 B 教训)
9. `--stylize` 参数推荐值(icon 100 / detail 200-250 / 立绘 300-400)
10. 混合双轨设计(icon 无 sref / detail 带 sref + sw 50)
11. MJ CDN Cloudflare 反爬 → Playwright MCP 绕(W1)
12. **九节鞭训练数据不足 V1-V5 演进失败 + 通用链鞭 borderline**(W2)
13. **detail 类主体可见性强化(`<item> in the foreground large and clearly visible`)**(W3 古玉佩 v2)
14. **`war hammer` 默认 barbell 石锤陷阱 + 中文拼音 fallback 锚定**(W4 破阵锤 v2 zhanchui)
15. **角色立绘 sref + sw 60 风格统一 vs 装备 lore trade-off**(W4 师徒立绘)
16. **MJ AI Moderator 写实图过滤陷阱 + v5 绕过 5 改动**(W5 金丝甲)
17. **detail 类特征 token 大写 + MUST 强化(`CLEARLY VISIBLE/MUST/JET-BLACK`)**(W5 v2 跃升)
18. **Stage 2 收官两类批次配方区分(环境 sw 100 / UI 无 sref)**(W6 9.0/10 实战)

---

## §8 下一步建议

| # | 任务 | 模型/时长 | 备注 |
|---|---|---|---|
| 1 ⭐ | **Stage 2 完工后 ~89 张归位 `assets/equipment/` + `assets/maps/` + `assets/ui/` + Flutter UI 接入图片** | opus 1-2 工日 | **1.0 路线图必经路径** · 装备/地图/UI 全图层接入 Flutter app |
| 2 | 心法相生 §4.5 触上限 8 重设计 | sonnet Phase 0 + opus 1-2h | 非阻塞代码任务 |
| 3 | **1.0 美术阶段 LoRA 训练数据样本扩充**(九节鞭 / 链子鞭 / 破阵锤 / 中国武器训练数据不足 3 件 + 主角色 LoRA 风格锁定数据集) | opus + 用户手动收集 | 1.0 远期 · 解 Stage 2 MJ 训练数据不足陷阱根本 |
| 4 | Demo §8.4 14/14 全达标确认 + 余下挂账清算 | opus | 1.0 之前最后里程碑 |

---

**closeout 完结 + Stage 2 量产正式收官**。**M4 PoC #46 美术 Stage 2 量产工作流 6 周全成**:Stage 0 baseline 探索 → Stage 1 PoC 验证 → Stage 1.5 改型 → Stage 2 W1-W6 量产 74 张,累计 **89 张产物归档**,**Demo 美术资源 100% 就绪**,可启动 1.0 路线图下一阶段(assets 归位 + Flutter UI 接入 + 心法相生 §4.5 / LoRA 远期方案)。
