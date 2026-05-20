# M4 PoC #46 美术 Stage 2 W3 第 3 批 closeout(2026-05-20)

> **批次**:好家伙+利器混选 5 件(玄花斧 / 古玉佩 / 链子鞭 / 玄铁甲 / 翡玉佩 × 2 张 = 10 张)
> **节奏**:主对话 opus xhigh + 用户主导 MJ,~25min Fast(含古玉佩 detail v1→v2 一轮重抽)
> **产物**:`~/Desktop/MJ_Stage2_W3/` 10 张 1024×1024 PNG 全规范命名
> **状态**:✅ 10/10 完工,**平均 8.65/10 · Stage 2 至今最好的一批**(W2 7.9 / W1 ~8.5)/ 风格一致度 ~90% / 类型识别度 ~90% / 精致度梯度可读 / GDD §1 水墨克制守住 / 无失败品归档

---

## §1 时间线

| 时刻 | 事件 |
|---|---|
| T0 | 用户拍板 W3 第 3 批起手,升档 opus xhigh |
| T+5min | yaml grep + 5 件 lore 视觉锚点,对话展开 10 个完整可贴 prompt(好家伙 well-made/sturdy + 利器 refined/well-crafted 精致度梯度) |
| T+8min | Write `~/Desktop/MJ_Stage2_W3_prompts.txt`(纯 ASCII 单行 + [01]-[10] 编号,继承 W2 双轨教训) |
| T+15min | 第一波 4 张到位:14 玄花斧 icon+detail / 17 玄铁甲 icon+detail 全归位 |
| T+20min | 第二波 6 张到位:15/16/18 各 icon+detail |
| T+22min | Read 视觉验证发现 **15 古玉佩 detail v1 玉佩主体缺失**(只有鹤 + 老檐 + 远山 + 印章,无玉佩本体)6/10 |
| T+23min | 对话出修正 prompt v2:`<item> in the foreground large and clearly visible` 强主体定位 + `--no missing X, no X` 黑名单 + stylize 250→200 |
| T+25min | v2 重抽完美:9.5/10 ⭐⭐⭐ 黄玉佩前景大 + 雕鹤清晰 + 老窗檐 + 远景水舟 + 题字 + 印章(本批最佳) |
| T+27min | 10/10 全归位,本 closeout + memory + PROGRESS + commit |

---

## §2 10 张产物清单 + 评分

| # | 文件 | 类型 | 评分 | 关键观察 |
|---|---|---|---|---|
| 14 | `14_xuan_hua_fu_icon.png` | 玄花斧 icon · 白底 | **9/10** ⭐⭐ | **斧面墨菊纹完美浮现** + 双手长柄 + 大斧头(W2 钢刀偏短教训成功补救) |
| 14 | `14_xuan_hua_fu_detail.png` | 玄花斧 detail · 水墨 | **8.5/10** | 黑斧主体清晰 + 工坊木桌 + 远山 + 印章 |
| 15 | `15_yu_pei_lao_icon.png` | 古玉佩 icon · 白底 | **8.5/10** | 黄玉色对位 + 雕立鹤(borderline 不是 lore 写的"回首鹤") |
| 15 | `15_yu_pei_lao_detail.png` | 古玉佩 detail · 水墨(v2) | **9.5/10** ⭐⭐⭐ | **本批最佳** · 黄玉佩前景大 + 雕鹤清晰 + 老窗檐 + 远景水舟 + 题字 + 印章 |
| 16 | `16_lian_zi_bian_icon.png` | 链子鞭 icon · 白底(V5 模板) | **8.5/10** | 单柄 + 长链 + 单 dart 标准款,V5 通用链鞭模板有效 |
| 16 | `16_lian_zi_bian_detail.png` | 链子鞭 detail · 水墨(V5 模板) | **7.5/10** | V5 通用链鞭 borderline,9 节不显 + 平铺地面 + 远山接受 |
| 17 | `17_xuan_tie_jia_icon.png` | 玄铁甲 icon · 白底 | **9/10** ⭐⭐ | **hip-length 串铆 lamellar 甲完美**(W2 皮甲 vest 教训成功补救) |
| 17 | `17_xuan_tie_jia_detail.png` | 玄铁甲 detail · 水墨 | **8.5/10** | 长款立姿 + 远山楼宇 + 印章 |
| 18 | `18_fei_yu_pei_icon.png` | 翡玉佩 icon · 白底 | **9/10** ⭐⭐ | **一缕翠绿 + 雕纹 + 绳挂**(完美对位 lore "活翠") |
| 18 | `18_fei_yu_pei_detail.png` | 翡玉佩 detail · 水墨 | **8.5/10** | 翠玉立姿 + 远山 + 印章 + 水墨气十足 |

**总评**:平均 **8.65/10**(W2 7.9 / W1 ~8.5),**Stage 2 至今最好的一批** ✅。**风格一致度 ~90%**(超 80% 验收线大幅)/ **类型识别度 ~90%**(链子鞭 borderline 拖整体)/ **好家伙 → 利器 精致度梯度可读**(玄花斧墨菊纹 / 玄铁甲串铆 / 翡玉佩活翠均显第 3-4 阶) / **水墨克制基调** GDD §1 守住 / **无失败品归档**(古玉佩 detail v1 主体缺失已 v2 替换)。

**W2 两大教训成功补救**:
- ① **玄花斧 long-haft 锁定** → 双手长柄 + 大斧头(防 W2 钢刀偏短复发)
- ② **玄铁甲 hip-length lamellar** → 长款全身甲完全不是 vest(防 W2 皮甲偏 vest 复发)
- ③ **链子鞭复用 W2 V5 通用链鞭模板** → 单柄 + 长链 + 单 dart 标准款,7.5/10 borderline 接受不再重抽

---

## §3 教训沉淀(本批次新增,补 memory 第 13 条)

### 教训:**MJ detail 类 prompt 必须强化主体可见性**(古玉佩 v1→v2 实战)

**症状**(W3 古玉佩 detail v1):lore 上下文丰富的 detail prompt(`ancient aged yellow jade pendant resting on an old wooden window sill, sunlight filtering through revealing fine hairline crack along edge, carved crane looking back visible on the front face, jianghu hermit atmosphere of an old retired swordsman's window...`)被 MJ 解读为"重点画场景气氛",**主体玉佩缺失**,4 张 grid 全部只画了鹤 + 老檐 + 远山 + 印章意境,没有玉佩本体。评分 6/10。

**根因**:MJ v7 在 `stylize 250` + 长 lore 上下文 + `traditional Chinese sumi-e ink wash painting` 风格锚定下,优先表达"水墨意境",次要表达"物品主体"。lore 越丰富,主体反而越容易被环境吃掉。

**v2 修正 prompt 关键改动**(同 grid 一次重抽 4/4 都过):
- ① **强主体定位**:`<item> in the foreground large and clearly visible`(必须放 prompt 开头)
- ② **具体场景锚定**:把 lore "resting on window sill" 改写成 `hanging by a silk cord from an old wooden window sill, sunlight from window`(挂的位置 + 光源具体化,而不是泛泛 "resting")
- ③ **`--no` 主体缺失黑名单**:`--no missing jade, no jade, empty scene, scenery only`
- ④ **stylize 降一档**:`--stylize 250 → 200`(降一点防过度抽象)

**v2 实战**:6/10 → **9.5/10 ⭐⭐⭐**(本批最佳)。玉佩前景大 + 雕鹤清晰 + 老窗檐 + 远景水舟 + 题字 + 印章 全有。

**Stage 2 后续批次纪律**(W4-W6 装备 + 角色立绘 detail 类必带):
- `<item> in the foreground large and clearly visible` 主体定位前置
- `--no missing X, no X, empty scene, scenery only` 防主体缺失
- stylize ≤ 200 不要 250+

详 memory `feedback_mj_wuxia_prompt_pitfalls` 第 13 条。

---

## §4 验收清单(全 ✅)

- [x] 风格一致度 ≥ 80%(实测 **~90%**)
- [x] 类型识别度 ≥ 75%(实测 **~90%**,链子鞭 ~75% 拖整体但其他 ≥ 90%)
- [x] 7 阶视觉梯度可读(好家伙 well-made/sturdy 优于像样货,利器 refined/well-crafted 优于好家伙,梯度清晰)
- [x] 无明显 AI 瑕疵
- [x] 无人物 / sref 内容污染(印章作国画落款 ✅)
- [x] 水墨克制 GDD §1 守住(无 red / orange dominant / vibrant)
- [x] 无失败品归档(v1 重抽后零失败)

---

## §5 Stage 2 进度更新

| 周 | 批次 | 内容 | 张数 | 完工日 | 状态 |
|---|---|---|---|---|---|
| W1 | 第 1 批 | 寻常货剩 4 件 | 8 | 2026-05-20 | ✅ |
| W2 | 第 2 批 | 像样货 5 件 | 10 | 2026-05-20 | ✅ |
| **W3** | **第 3 批** | **好家伙+利器 5 件** | **10** | **2026-05-20** | **✅** |
| W4 | 第 4 批 | 重器 5 件 + 3 师徒角色立绘 | 13 | 2026-06-15 |  |
| W5 | 第 5 批 | 宝物+神物 9 件 | 18 | 2026-06-22 |  |
| W6 | 第 6 批 | 5 闭关地图 + ~10 UI 资源 | ~15 | 2026-06-29 |  |
| **总** | — | — | **28/~75** | — | **W1+W2+W3 ✅ 37%** |

**Stage 1 PoC 15 + Stage 2 W1 8 + W2 10 + W3 10 = 累计 43 张产物归档于 `~/Desktop/MJ_Stage{1_PoC,2_W1,2_W2,2_W3}/`**。

**Fast time**:W1 ~20min + W2 ~30min + W3 ~25min(含 v1→v2 一轮重抽)= 累计 ~75min。**剩 Stage 2 ~125min 配额仍够 W4-W6**(月配额 ~12.5h × 0.6h 已用 ~10%)。

---

## §6 W3 触发的 memory 沉淀

- **补充 memory** `feedback_mj_wuxia_prompt_pitfalls`:加第 13 条(MJ detail 类 prompt 必须强化主体可见性,v1→v2 实战 6/10 → 9.5/10 + 修正 prompt 4 条改动 + Stage 2 后续批次纪律)

---

## §7 下一步建议

| # | 任务 | 模型/时长 | 备注 |
|---|---|---|---|
| 1 ⭐ | Stage 2 W4 第 4 批 重器 5 件(玄武戟/白虹剑/朱雀刀/重铠甲/玄玉佩 等)+ 3 师徒角色立绘 = 13 张 | opus xhigh + 用户主导 MJ ~40min Fast | 重器精致度 `notable, distinctive, recognizable` 拐点;角色立绘走 `sref 主角色` + sw 60-70 |
| 2 | 心法相生 §4.5 触上限 8 重设计(SynergyRequirementType 新枚举或 sameTier 高阶变体) | sonnet Phase 0 + opus 实装 1-2h | 非阻塞代码任务,Stage 2 批次空档可插 |
| 3 | Stage 2 完工后 ~75 张归位 `assets/equipment/` + Flutter UI 接入装备图 | opus 1-2 工日 | 1.0 远期 |

---

**closeout 完结**。本批次产物 + 教训沉淀完毕,可 commit + push。
