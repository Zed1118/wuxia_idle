# M4 PoC #46 美术 Stage 2 W5 第 5 批 closeout(2026-05-20)

> **批次**:宝物 4 件(玄天斧/长虹剑/血莲鞭/金丝甲)+ 神物 5 件(破军刀/天问剑/幻梦鞭/玄黄袍/昆仑佩)= 9 件 × 2 张 = **18 张**(玉龙佩已 Stage 1 PoC 跑过,W5 跳过)
> **节奏**:主对话 opus xhigh + 用户主导 MJ,~50min Fast(含 3 张 v1→v2 重抽 + 30 金丝甲 Moderator 触发 v5 绕过)
> **产物**:`~/Desktop/MJ_Stage2_W5/` 18 张 1024×1024 PNG 全规范命名
> **状态**:✅ 18/18 完工,**平均 8.5/10**(与 W3+W4 持平 · Stage 2 维持高水准)/ 风格一致度 ~90% / 类型识别度 ~90% / 宝物→神物精致度梯度可读 / 异色防红橙油画事故全生效(血莲鞭/长虹剑/玄黄袍/昆仑佩) / GDD §1 水墨克制守住 / 无失败品归档(3 张 v1 占位删除)

---

## §1 时间线

| 时刻 | 事件 |
|---|---|
| T0 | 用户拍板 W5 第 5 批起手,升档 opus xhigh |
| T+5min | yaml grep + 9 件 lore + 玉龙佩查 Stage 1 PoC 已跑过跳过,对话展开 6 个关键异色 prompt + Write 完整 18 个 prompt 双轨 |
| T+15min | W5 第 1 批 6 张 icon 到位(27/28/29/33/34/35 icon),Read 验证 + 归位 — **异色防护全部生效**(血莲鞭红色严格局限 / 玄黄袍 dual-tone 完美 / 昆仑墨玉) |
| T+20min | W5 第 2 批 9 张到位,Read 验证发现 **3 张失败/borderline**:① 29 血莲鞭 detail v1 = 5/10(黑色普通绳子,无赤红) ② 33 幻梦鞭 detail v1 = 5/10(普通棕绳,无半透明月光) ③ 35 昆仑佩 detail v1 = 6/10 borderline(水滴/葫芦形,山影不显) |
| T+25min | 标 v1 FAILED/borderline,对话出 v2 修正 prompt(强主体特征 + NOT 否定形式 + 大扩黑名单) |
| T+28min | 用户跑 30 金丝甲 detail v1/v2/v3/v4 全部触发 **MJ AI Moderator 写实图过滤**:"AI Moderation is cautious with realistic images"。沟通后定位根因:`armor / defensive / protective / Yanmenguan veteran / Song dynasty keepsake` 等军事/历史身份词 + sref 写实风组合触发 |
| T+32min | 对话出 v5 绕过 prompt:去 `--sref`(写实风源头)+ 去所有军事/护甲/身份词,改 `a traditional Chinese ink wash painting depicting an antique embroidered silk piece...`(描述"一幅画"不是"物体"),stylize 200→150。**v5 终于通过 Moderator** ✅ |
| T+35min | 3 张 v2 重抽到位 + 30 金丝甲 v5 到位 + 31 破军刀 detail v2 + 32 天问剑 icon v2 同期跑出 = W5 第 3 批 6 张 |
| T+40min | Read 全 6 张视觉对照:**29 血莲鞭 v2 = 9/10 / 35 昆仑佩 v2 = 9/10 / 32 天问剑 v2 = 9/10 ⭐⭐ 跃升,33 幻梦鞭 v2 = 7.5/10 borderline,31 破军刀 detail = 8.5/10,30 金丝甲 v5 = 8/10 borderline** |
| T+45min | 18/18 全归位 + 删除 3 张 v1 占位 |
| T+50min | 本 closeout + memory 16+17 + PROGRESS + commit |

---

## §2 18 张产物清单 + 评分

### 宝物 4 件 × 2 张 = 8 张

| # | 文件 | 评分 | 关键观察 |
|---|---|---|---|
| 27 | `27_xuan_tian_fu_icon.png` | **8.5/10** ⭐⭐ | 单端长柄 + 刻字明显(W4 zhanchui 教训完美应用),但斧刃幽蓝不显 |
| 27 | `27_xuan_tian_fu_detail.png` | **9/10** ⭐⭐ | **斧刃幽蓝完美呈现** + 水墨远山 + 印章 |
| 28 | `28_chang_hong_jian_icon.png` | **9/10** ⭐⭐ | **虹光彩虹反射完美**(蓝紫粉橙折射) |
| 28 | `28_chang_hong_jian_detail.png` | **8/10** | 双刃 jian + 岳阳楼场景,虹光弱(detail 类可接受) |
| 29 | `29_xue_lian_bian_icon.png` | **9/10** ⭐⭐ | **完美防红橙事故** 深暗赤红严格局限鞭身,背景纯白 |
| 29 | `29_xue_lian_bian_detail.png` (v2) | **9/10** ⭐⭐ | v1 5/10 → v2 9/10 跃升 · 深暗赤红 + 水墨远山 + 印章 |
| 30 | `30_jin_si_jia_icon.png` | **9/10** ⭐⭐ | **muted pale gold + 锦绣纹路完美** |
| 30 | `30_jin_si_jia_detail.png` (v5) | **8/10** | borderline 接受 · v5 去 sref + 去军事词改"绘画作品"终通过 Moderator |

**宝物 8 张平均 8.7/10**(本批最佳)。

### 神物 5 件 × 2 张 = 10 张

| # | 文件 | 评分 | 关键观察 |
|---|---|---|---|
| 31 | `31_po_jun_dao_icon.png` | **7.5/10** | dao 单刃 + 黑铁感 OK,陨铁一线白不显 borderline |
| 31 | `31_po_jun_dao_detail.png` | **8.5/10** | 4 尺漆黑 dao + 城楼远山场景,陨铁线白仍弱 |
| 32 | `32_tian_wen_jian_icon.png` (v2) | **9/10** ⭐⭐ | **剑身篆字密集刻可见** + 剑锷纹饰 + 木柄(v2 大写强化生效) |
| 32 | `32_tian_wen_jian_detail.png` | **8.5/10** | 书生书桌场景 + 双刃 jian 立姿 + 题字(17 字不显) |
| 33 | `33_huan_meng_bian_icon.png` | **7.5/10** | 黑底非白底 borderline,但半透明月光质感呈现 OK |
| 33 | `33_huan_meng_bian_detail.png` (v2) | **7.5/10** | v1 5→v2 7.5(改善但月光质感弱,borderline 接受) |
| 34 | `34_xuan_huang_pao_icon.png` | **9/10** ⭐⭐ | **dual-tone 玄黄相融完美** 玄黑 + 土黄交融 |
| 34 | `34_xuan_huang_pao_detail.png` | **8/10** | 玄黑主调 + 松树场景,土黄弱(dual-tone 减弱 borderline) |
| 35 | `35_kun_lun_pei_icon.png` | **9/10** ⭐⭐ | **墨玉深沉**(深绿黑)+ 雕龙(borderline 不是山影) |
| 35 | `35_kun_lun_pei_detail.png` (v2) | **9/10** ⭐⭐ | v1 6→v2 9 跃升 · **墨玉里山影轮廓清晰可见** + 椭圆玉佩 + 茶碗笔 |

**神物 10 张平均 8.35/10**。

---

## §3 总评

- **W5 18 张总均 8.5/10**(宝物 8 张 8.7 + 神物 10 张 8.35),与 **W3+W4 持平**(Stage 2 维持高水准)
- **风格一致度 ~90%**(异色防护点全部生效 · 9 件 7 种异色全部局部锁定无背景污染)
- **类型识别度 ~90%**(失败品全部 v2 修正,无残留)
- **宝物 → 神物 精致度梯度可读**:宝物 `exquisite/treasured/ceremonial silk wrap/masterpiece-level` / 神物 `divine/mythical relic/otherworldly aura/sacred artifact`,7 阶最顶档完整呈现
- **水墨克制基调** GDD §1 守住(7 种异色全部局部单点不蔓延)
- **W3+W4 教训彻底落地**:detail 类主体强可见性 + 中文音译锚定 + ONE 量词 + NOT 否定 + 大扩黑名单全用上
- **W5 新沉淀 2 条教训**(详 §4):
  - 第 16 条:**MJ AI Moderator 写实图过滤陷阱**(30 金丝甲 v1-v4 全拒,v5 绕过)
  - 第 17 条:**detail 类特征 token 大写 + MUST 强化实战有效**(29/35 v2 跃升)

---

## §4 教训沉淀(本批次新增,补 memory 第 16+17 条)

### 教训第 16 条:**MJ AI Moderator 写实图过滤陷阱(30 金丝甲 v1-v4 全拒,v5 绕过)**

**症状**:MJ 报错 `"Sorry! The AI Moderator is unsure about this prompt. AI Moderation is cautious with realistic images, especially of people. Please try adjusting your prompt or trying a different idea."`,4 次修改 prompt 全部被拒。

**v1-v4 失败 prompt 共同特征**:
- 包含军事/护甲身份词:`armor, defensive, protective, military, plate armor, dragon scale`
- 包含历史身份/出处:`Yanmenguan veteran's keepsake, Song dynasty imperial workshop, jianghu`
- 仍带写实风 sref:`--sref [套 C 雪景古松写实风]`
- stylize 200(中等真实感)
- ar 1:1 + 主体物 detail 类组合

**根因**:MJ AI Moderator 对**真实生活物品(尤其涉及军事/暴力含义 + 人物身份)+ 写实风格 sref 组合**触发"过于真实可能涉及现实暴力或敏感场景"过滤。`armor + battle wound + veteran + sref` 组合命中过滤红线。

**v5 绕过 prompt 5 条关键改动**:
- ① **去 `--sref`**(sref 套 C 雪景写实风是触发源头,去掉后从"模拟现实"回到"水墨绘画")
- ② **去所有军事/护甲/身份词**:`armor → garment / silk piece / ceremonial silk garment`;`Yanmenguan veteran's keepsake → peaceful old Chinese craftsman atmosphere`;`Song dynasty imperial workshop → quiet workshop with bolts of silk`;删 `jianghu, defensive, protective, military`
- ③ **改"绘画作品"描述**:`a traditional Chinese ink wash painting depicting an antique embroidered silk piece...`(描述"画"而不是"物体")
- ④ **stylize 200 → 150 → 100**(降真实感)
- ⑤ **加 `--no photograph, realistic photo, modern`**(显式反写实)

**v5 实战**:4 次拒绝 → 5 次通过,产出 8/10 borderline(描述为"丝织品"游戏内可作"金丝甲"用)。

**Stage 2 后续批次纪律**(W6 + 1.0):
- 涉及军事/护甲/暴力含义装备:**去 sref + 改"画作描述"** + 去身份词
- 角色立绘:**不沾军事身份**(W4 角色立绘没碰这条线 OK)
- 任何 Moderator 拒绝后:**第一反应去 sref + 第二反应改"painting depicting" 词** + 第三反应缩短 prompt
- prompt 长度过长(>800 token)也可能触发,缩短不丢关键 token

详 memory `feedback_mj_wuxia_prompt_pitfalls` 第 16 条。

### 教训第 17 条:**detail 类特征 token 大写 + MUST 强化实战有效**

**症状**(W5 v1 失败 + v2 成功对比):
- ❌ v1 不大写 + 列举 token 优先级低:`subtle iridescent rainbow shimmer reflected along the blade edge` / `the captured shadow of Kunlun mountain inside the jade` / `inscribed with 17 ancient Chinese seal-script characters` → MJ 忽略关键特征,出图无该特征
- ✅ v2 大写 + MUST + key feature 优先级提升:`CLEARLY VISIBLE dense ancient Chinese seal-script characters` / `the seal-script inscriptions are the key defining visual feature and MUST be clearly visible` / `the captured shadow of Kunlun mountain inside the jade is the key feature` → MJ 锁定特征,出图完整

**实战对比**(同 grid 一次 v2 重抽即过):
- **29 血莲鞭 detail v1 5/10(黑色普通绳) → v2 9/10 ⭐⭐**(强调 `DISTINCTIVELY deep dark crimson... NOT black, NOT brown, NOT gray... the whip MUST be dark red color`)
- **35 昆仑佩 detail v1 6/10(水滴/葫芦形) → v2 9/10 ⭐⭐**(强调 `properly carved oval-shaped... NOT teardrop shape, NOT gourd shape... the captured shadow of Kunlun mountain inside the jade is the key feature`)
- **32 天问剑 icon v1 无字 → v2 9/10 ⭐⭐**(强调 `CLEARLY VISIBLE dense ancient Chinese seal-script characters... MUST be clearly visible on the blade surface`)

**有效的 4 种强化模式**:
- ① **关键 token 大写**:`CLEARLY VISIBLE`、`MUST`、`JET-BLACK`、`DISTINCTIVELY`
- ② **显式优先级声明**:`the [feature] is the key defining visual feature`
- ③ **NOT 否定列举**(防误识):`NOT teardrop, NOT gourd, NOT brown, NOT black`
- ④ **MUST 命令式**:`the whip MUST be dark red`(MJ 对命令式响应明显)

**与第 13 条对比**:第 13 条(主体可见性)解决"主体缺失",第 17 条解决"主体有但特征缺失"。两条并用:
```
<item> in the foreground large and clearly visible, with [KEY FEATURE in caps] that is the key defining visual feature and MUST be clearly visible, NOT [常见误识 1], NOT [误识 2]
```

详 memory `feedback_mj_wuxia_prompt_pitfalls` 第 17 条。

---

## §5 验收清单(全 ✅)

- [x] 风格一致度 ≥ 80%(实测 **~90%**)
- [x] 类型识别度 ≥ 75%(实测 **~90%**,3 张 v1 失败 v2 全修正)
- [x] 7 阶视觉梯度可读(宝物 → 神物 顶档梯度清晰,与 W4 重器拐点 + W3 利器对比清晰)
- [x] 异色防红橙油画事故(7 种异色全部局部锁定无背景污染)✅
- [x] 无明显 AI 瑕疵
- [x] 无人物 / sref 内容污染
- [x] 水墨克制 GDD §1 守住
- [x] 无失败品归档(3 张 v1 占位删除)

---

## §6 Stage 2 进度更新

| 周 | 批次 | 内容 | 张数 | 完工日 | 状态 |
|---|---|---|---|---|---|
| W1 | 第 1 批 | 寻常货剩 4 件 | 8 | 2026-05-20 | ✅ |
| W2 | 第 2 批 | 像样货 5 件 | 10 | 2026-05-20 | ✅ |
| W3 | 第 3 批 | 好家伙+利器 5 件 | 10 | 2026-05-20 | ✅ |
| W4 | 第 4 批 | 重器 5 件 + 3 师徒立绘 | 13 | 2026-05-20 | ✅ |
| **W5** | **第 5 批** | **宝物 4 + 神物 5 件** | **18** | **2026-05-20** | **✅** |
| W6 | 第 6 批 | 5 闭关地图 + ~10 UI 资源 | ~15 | 2026-06-29 |  |
| **总** | — | — | **59/~74** | — | **W1-W5 ✅ 80%** |

**Stage 1 PoC 15 + Stage 2 W1 8 + W2 10 + W3 10 + W4 13 + W5 18 = 累计 74 张产物归档于 `~/Desktop/MJ_Stage{1_PoC,2_W1,2_W2,2_W3,2_W4,2_W5}/`**(玉龙佩 Stage 1 PoC 已含)。

**Fast time**:W1-W5 累计 = ~150min(W1 ~20 + W2 ~30 + W3 ~25 + W4 ~25 + W5 ~50)。**剩 ~50min 配额够 W6**。

---

## §7 W5 触发的 memory 沉淀

- **补充 memory** `feedback_mj_wuxia_prompt_pitfalls`:
  - 第 16 条(**MJ AI Moderator 写实图过滤陷阱** + 30 金丝甲 v1-v4 全拒 + v5 去 sref + 改"画作描述" + 去军事身份词 5 改动绕过 + Stage 2 后续批次纪律)
  - 第 17 条(**detail 类特征 token 大写 + MUST 强化实战有效** + 29/35/32 v1→v2 对比 + 4 种强化模式 + 与第 13 条配合使用)

---

## §8 下一步建议

| # | 任务 | 模型/时长 | 备注 |
|---|---|---|---|
| 1 ⭐ | Stage 2 W6 第 6 批 5 闭关地图 + ~10 UI 资源 = ~15 张 | opus xhigh + 用户主导 MJ ~30min Fast | **环境类批次**,走主环境 sref + sw 100(允许风格完全继承);Stage 2 最后一批 |
| 2 | 心法相生 §4.5 触上限 8 重设计(SynergyRequirementType 新枚举或 sameTier 高阶变体) | sonnet Phase 0 + opus 实装 1-2h | 非阻塞代码任务 |
| 3 | Stage 2 完工后 ~75 张归位 `assets/equipment/` + Flutter UI 接入装备图 | opus 1-2 工日 | 1.0 远期 |

---

**closeout 完结**。本批次产物 + 教训沉淀完毕,可 commit + push。
