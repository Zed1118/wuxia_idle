# M4 PoC #46 美术 Stage 2 W2 第 2 批 closeout(2026-05-20)

> **批次**:像样货 5 件(钢刀 / 长剑 / 九节鞭 / 皮甲 / 银戒 × 2 张 = 10 张)
> **节奏**:主对话 opus xhigh + 用户主导 MJ,~55min(含九节鞭 V1→V5 演进 5 轮)
> **产物**:`~/Desktop/MJ_Stage2_W2/` 10 张 1024×1024 PNG 全规范命名 + `failed/` 3 张失败品归档
> **状态**:✅ 10/10 完工,**风格一致度 ~85% / 类型识别度 ~85%(九节鞭拖整体)/ 像样货精致度梯度可读 / GDD §1 水墨克制守住**

---

## §1 时间线

| 时刻 | 事件 |
|---|---|
| T0 | 用户拍板 W2 第 2 批起手,升档 opus xhigh |
| T+5min | yaml grep + 5 件 lore 视觉锚点 + 数值上下文,对话展开 10 个完整可贴 prompt(像样货 plain/sturdy/no-frills) |
| T+10min | 用户给 Codex 跑撞 terminal reflow + scroll buffer corruption(同一标题反复粘贴,各段穿插混杂)→ 切用户手动 |
| T+15min | Write `~/Desktop/MJ_Stage2_W2_prompts.txt`(纯 ASCII 单行 + [01]-[10] 编号 + 九节鞭 V2 修正),用户 open 复制 |
| T+25min | 第一波 8 张到位:钢刀 ×2 / 长剑 ×2 / 皮甲 ×2 / 九节鞭 V1 ×2(扭绞金属绳/螺旋链 — `iron-ring segments` 让 MJ 误识) |
| T+28min | Read 视觉对照 mv 归位,九节鞭 V1 进 `failed/` |
| T+32min | 4 张待跑 prompt 对话输出(银戒 + 九节鞭 V3 加 nunchaku 屏蔽) |
| T+38min | V3 跑出:`0_2`(双节棍 nunchaku)+ `jiu_j_22952a15`(齿轮串环 + dart borderline 7/10)+ 银戒 ✅ 9/10 / 8/10 |
| T+40min | V3 双节棍进 `failed/`,银戒 2 张归位,九节鞭 detail 齿轮串环 borderline 待拍板 |
| T+42min | 用户接受 detail 7/10 归位,V4 重抽 icon(加 Bruce Lee chain whip 历史锚定) |
| T+48min | V4 grid 12 张:R1C2 单柄 + 长链 + dart 平铺圆环 ⭐ 8.5/10 最佳;Row 2 偏色 dart 束 + 戟头跑偏 |
| T+50min | 用户继续不满,V5 强化版(强调 ONE piece + 单柄单 dart + laid flat + 大扩 `--no` 黑名单) |
| T+52min | V5 跑 8 张全是"单柄 + 长鞭 + dart"基本款,R1C2 ⭐ 8/10 最佳 |
| T+55min | U R1C2 下载,Read 验证 单柄 + 长链 + dart 链节均匀(9 节不显)接受 borderline 7.5/10 归位 |
| T+60min | 10/10 全归位,本 closeout + memory + PROGRESS + commit |

---

## §2 10 张产物清单 + 评分

| # | 文件 | 类型 | 评分 | 关键观察 |
|---|---|---|---|---|
| 09 | `09_gang_dao_icon.png` | 钢刀 icon · 白底 | ✅ 7/10 | 单刃 + 桐油麻绳柄 + 锤纹未磨 + dart 系绳;**形态偏短**像柴刀/胁差(三尺钢刀略缩) |
| 09 | `09_gang_dao_detail.png` | 钢刀 detail · 水墨 | ✅ 8/10 | 单刃 + 水墨远山 + 印章作落款,主体清晰;**形态仍偏短** |
| 10 | `10_chang_jian_icon.png` | 长剑 icon · 白底 | ✅ 8/10 | 双刃直剑 + 略长 + 细长 + 鞘暗纹微显 |
| 10 | `10_chang_jian_detail.png` | 长剑 detail · 水墨 | ✅ 9/10 | **极佳**:双刃直剑 + 水墨远山 + 印章 + 江南气,剑身飞白笔触到位 |
| 11 | `11_jiu_jie_bian_icon.png` | 九节鞭 icon · 白底(V5) | ⚠️ 7.5/10 | 单柄 + 长链 + dart + 盘成圆环展示全长;**9 节不显**(链节均匀)接受 borderline |
| 11 | `11_jiu_jie_bian_detail.png` | 九节鞭 detail · 水墨(V3) | ⚠️ 7/10 | 齿轮串环 + dart + 水墨远山 + 印章;**非 9 节棒**但水墨意境到位 borderline |
| 12 | `12_pi_jia_icon.png` | 皮甲 icon · 白底 | ✅ 8/10 | 棕色双层皮甲 + 缝线 + 磨损质感;**形态偏 vest 短款**(jianghu 走镖披甲应略长) |
| 12 | `12_pi_jia_detail.png` | 皮甲 detail · 水墨 | ✅ 9/10 | **极佳**:磨损牛皮 + 草地 + 水墨远山 + 印章悬挂,jianghu 流落感到位 |
| 13 | `13_yin_jie_icon.png` | 银戒 icon · 白底 | ✅ 9/10 | **极佳**:素面 + 光滑 + 银色哑光(完美对位 lore "素面无字无石") |
| 13 | `13_yin_jie_detail.png` | 银戒 detail · 水墨 | ✅ 8/10 | 戒 + 水墨远山 + 印章;**色调偏暗**像铁不像银(瑕疵接受) |

**总评**:平均 **~7.9/10**,**风格一致度 ~85%**(超 80% 验收线)/ **类型识别度 ~85%**(九节鞭 V5 拖整体 ~75%,其他 4 件 ≥ 90%)/ **像样货精致度梯度** 视觉读得出来 / **水墨克制基调** GDD §1 守住。

**主要瑕疵接受不重抽**:九节鞭 V1-V5 全失败接受 borderline(MJ 训练数据缺,ROI 不值得) + 钢刀形态偏短(单刃主体清晰可读) + 皮甲 icon 偏 vest(双层结构可读)。

---

## §3 教训沉淀(本批次新增,补 memory)

### 教训 1:**MJ 九节鞭训练数据严重不足,V1→V5 演进 5 轮失败诊断**

九节鞭(中国武术武器,9 节金属棒中间用短链节连接,末端 dart 配重 + 木柄)在 MJ v7 + sumi-e ink wash 下**无法稳定跑出 9 节棒形态**:

| 版本 | 关键 token | 跑出结果 |
|---|---|---|
| V1 | `nine interlocking iron-ring segments chained together` | **扭绞金属绳 / 螺旋链** |
| V3 | `nine short cylindrical metal rod segments... like nine short steel batons` | **双节棍 + 齿轮串环** |
| V4 | `Bruce Lee chain whip... long thin chain... wooden handle... dart tip` | **一束 dart / 戟头 / 短链项链**(R1C2 最佳 8.5/10) |
| V5 | `single long flexible chain whip... ONE piece... laid flat` + 大 `--no` 黑名单 | **通用链鞭基本款**,9 节不显 7.5/10 接受 |

**根因**:MJ 训练数据**九节鞭原型样本严重不足**,token "nine-section / segments / rod" 被拉去匹配近义概念(nunchaku 双节棍 / 三节棍 / 项链 / 链锯 / dart 束)。

**Stage 2 期决议**:接受**通用链鞭基本款**(单柄 + 长链 + dart) borderline 7-8/10,不强求严格 9 节棒。**1.0 远期方案**:转 fal.ai Flux + LoRA 训练时**九节鞭样本额外补 50+ 张**(Google 图搜 "九节鞭" / "Chinese chain whip" / "wushu chain whip"),与 jian/dao/sabre 同等 LoRA 锁形。

详 memory `feedback_mj_wuxia_prompt_pitfalls` 第 12 条。

### 教训 2:**复制粘贴 prompt 给 Codex 撞 terminal reflow / scroll buffer corruption**

**症状**:对话里 markdown 标题 + emoji 编号(① ② ...)+ fenced code block 的 prompt 输出,经 Codex 终端 reflow / 滚屏复制粘贴,**同一标题行反复重绘多次**,各段 prompt 内容**穿插混杂**(用户错觉"全是银戒")。

**解决**:**Write 单独纯 ASCII 文件**(`~/Desktop/MJ_Stage2_W2_prompts.txt`,单行 prompt + [01]-[10] ASCII 编号),Codex / 用户 `cat` / `open` 直接读,零终端 reflow 风险。

**Stage 2 后续批次**:**Write 文件 + 对话简报**双轨默认。

---

## §4 验收清单(全 ✅)

- [x] 风格一致度 ≥ 80%(实测 ~85%)
- [x] 类型识别度 ≥ 75%(实测 ~85%,九节鞭 ~75% 拖整体)
- [x] 7 阶视觉梯度可读(像样货 plain/sturdy 介于寻常货粗糙与好家伙精致之间)
- [x] 无明显 AI 瑕疵
- [x] 无人物 / sref 内容污染(印章作国画落款 ✅)
- [x] 水墨克制 GDD §1 守住(无 red / orange dominant / vibrant)

---

## §5 Stage 2 进度更新

| 周 | 批次 | 内容 | 张数 | 完工日 | 状态 |
|---|---|---|---|---|---|
| W1 | 第 1 批 | 寻常货剩 4 件 | 8 | 2026-05-20 | ✅ |
| **W2** | **第 2 批** | **像样货 5 件** | **10** | **2026-05-20** | **✅** |
| W3 | 第 3 批 | 好家伙+利器剩 5 件 | 10 | 2026-06-08 |  |
| W4 | 第 4 批 | 重器 5 件 + 3 师徒角色立绘 | 13 | 2026-06-15 |  |
| W5 | 第 5 批 | 宝物+神物 9 件 | 18 | 2026-06-22 |  |
| W6 | 第 6 批 | 5 闭关地图 + ~10 UI 资源 | ~15 | 2026-06-29 |  |
| **总** | — | — | **18/~75** | — | **W1+W2 ✅ 24%** |

**Stage 1 PoC 15 + Stage 2 W1 8 + Stage 2 W2 10 = 累计 33 张产物归档于 `~/Desktop/MJ_Stage{1_PoC,2_W1,2_W2}/`**。

**Fast time**:W1 ~20min + W2 ~30min(含九节鞭 V1→V5 多轮)= 累计 ~50min。**剩 Stage 2 ~150min 配额够 W3-W6**。

---

## §6 W2 触发的 memory 沉淀

- **补充 memory** `feedback_mj_wuxia_prompt_pitfalls`:加第 12 条(MJ 九节鞭训练数据严重不足,V1-V5 演进失败诊断 + 1.0 LoRA 补样本方案 + `--no` 黑名单大扩展)

---

## §7 下一步建议

| # | 任务 | 模型/时长 | 备注 |
|---|---|---|---|
| 1 ⭐ | Stage 2 W3 第 3 批 好家伙+利器剩 5 件 10 张(玄花斧/古玉佩/链子鞭/玄铁甲/翡玉佩) | opus xhigh + 用户主导 MJ ~30min Fast | W3 节奏继续;**链子鞭借用 W2 V5 通用链鞭模板**(已验证可接受) |
| 2 | 心法相生 §4.5 触上限 8 重设计(SynergyRequirementType 新枚举或 sameTier 高阶变体) | sonnet Phase 0 + opus 实装 1-2h | Stage 2 空档非阻塞代码任务 |
| 3 | Stage 2 完工后 assets 归位 + Flutter UI 接入装备图 | opus 1-2 工日 | 1.0 远期 |

---

**closeout 完结**。本批次产物 + 教训沉淀完毕,可 commit + push。
