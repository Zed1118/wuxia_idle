# M4 PoC #46 · Stage 1+1.5 PoC 全收官 Closeout(2026-05-20)

> 美术 PoC 5 大装备类型全覆盖验证通过,15 张产物,4 张 sref baseline 锁定,Stage 2 量产 spec 同步起草。
> Mac+Opus 4.7 主对话 opus xhigh ~6h 全程实战。

---

## §0 全程时间线

| 时间 | 阶段 | 内容 |
|---|---|---|
| ~09:30 | 主对话讨论 | 4 维度技术选型拍板(MJ Standard $30 + ChatGPT 副 + 混合双轨 + Stage 0→1→2 节奏)|
| ~10:00 | Stage 0 spec 起草 | 3 套候选 prompt(A 极致水墨 / B 暗黑沉郁 / C 山水意境) + MJ 操作手册 + 候选评估清单 + ChatGPT 11 张 baseline 归档 30MB,commit `b06834a` |
| ~11:30 | 用户订阅 MJ Standard $30 月付 | + Discord 关联 + Web app 入口 |
| ~12:00 | Stage 0 跑图 | 套 A 8 张 + 套 B **红橙油画事故** 8 张 + 修复版 B 8 张 + 套 C **山水大惊喜** 4 张 = ~28 张候选 |
| ~12:30 | Stage 0 收官 | 锁 4 张 sref(主角色 + 备用角色 + 主环境 ⭐ + 备用环境)|
| ~12:50 | Stage 1 spec 起草 | 5 件剑类跳采样 + 双轨 prompt 模板 + 验收标准,commit `3b4f628` |
| ~12:51-13:13 | Stage 1 跑图(剑类)| 铁剑(第一轮精致重剑误判 → jian 锁定修复)+ 青锋剑 8/8 jian + 龙泉剑 8/8 精致梯度 |
| ~13:30 | **PoC 设计偏差发现** | 用户问"游戏只有一种武器吗?"→ 35 件 = 武器 21(剑/刀/鞭) + 防具 7 + 饰品 7,5 件全选剑严重偏失,改方案 B |
| ~13:30-14:46 | Stage 1 改型 + Stage 1.5 | 盘龙刀(sref 污染 → **`--sw 50` 修复**) + 缠丝索(鞭索类一次过) + 锦袍(`no figure inside` 生效) + 玉龙佩(饰品 OK) |
| ~14:50 | Stage 1+1.5 收官 | 5 大类型全覆盖,15 张产物全规范命名 |
| ~15:00 | 本 closeout + Stage 2 spec + memory 沉淀 + commit + push | |

---

## §1 Stage 0 收官:4 张 sref baseline

| 用途 | URL | 内容 |
|---|---|---|
| 主角色 sref ⭐ | `https://cdn.midjourney.com/6077e344-b9fb-4804-96e5-83d816c84742/0_3.png` | 套 A 厚涂斗笠剑客侧立 + 红印章 + 米黄宣纸底 |
| 备用角色 sref | `https://cdn.midjourney.com/17373e56-b316-4694-bca9-a6d04eb87282/0_3.png` | 修复 B 全身 + 灯笼 + 暖橙点缀 |
| 主环境 sref ⭐⭐⭐ | `https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_0.png` | 套 C 雪景古松 + 远山,**与 ChatGPT baseline `04_xuezhong_tingge.png` 神还原**,装备详情大图主用 |
| 备用环境 sref | `https://cdn.midjourney.com/ae8355ca-7408-47af-84e4-74b2d698461e/0_2.png` | 套 C 远山栈道 + 双人 |

详 `art_poc_stage0_ref_exploration_2026-05-20.md`。

---

## §2 Stage 1+1.5 收官:15 张 PoC 产物(7 件 × 2 + 1 alt)

存储路径:`~/Desktop/MJ_Stage1_PoC/`

| # | yaml id | name | 类型 | icon | detail | 备注 |
|---|---|---|---|---|---|---|
| 01 | weapon_xunchang_tie_jian | 铁剑 | 剑 jian | ✅ 517KB | ✅ 1.91MB | + icon_alt 备用 |
| 02 | weapon_haojiahuo_qing_feng_jian | 青锋剑 | 剑 jian | ✅ 399KB | ✅ 1.82MB | |
| 03 | weapon_liqi_long_quan | 龙泉剑 | 剑 jian | ✅ 1.81MB | ⚠️ **211KB** | 偏小,Stage 2 量产时重新 Upscale |
| 04 | weapon_liqi_pan_long_dao | 盘龙刀 | **刀 dao** | ✅ 866KB | ✅ 1.13MB | `--sw 50` 修复后单刃 |
| 05 | weapon_haojiahuo_chan_si_suo | 缠丝索 | **鞭索** | ✅ 694KB | ✅ 2.01MB | PoC 最难类一次过 |
| 06 | armor_haojiahuo_jin_pao | 锦袍 | **防具** | ✅ 882KB | ✅ 1.83MB | `no figure inside` 生效 |
| 07 | accessory_baowu_yu_long_pei | 玉龙佩 | **饰品** | ✅ 810KB | ✅ 2.09MB | 细节略糊但风格 OK |

---

## §3 5 大装备类型全覆盖验证

| 类型 | 代表 | 关键教训 | 验证状态 |
|---|---|---|---|
| 剑 jian | 铁/青锋/龙泉 | jian 锁定咒语 `Chinese double-edged straight sword, symmetrical blade both sides sharp` + `--no dao, sabre` + 印章作国画落款 | ✅ 通过(3 件梯度完整) |
| **刀 dao** | 盘龙刀 | dao 锁定咒语 `Chinese single-edged sabre with one sharp edge only, not jian` + `--no double-edged, jian, straight sword` + **`--sw 50` 防 sref 污染**(关键!) | ✅ 通过(`--sw 50` 修复) |
| **鞭/索/链** | 缠丝索 | `flexible coiled rope/chain weapon with metal weighted tip` + `--no sword, blade, rigid weapon, jian, dao` + **MJ 最难类型一次过** | ✅ 通过 |
| **防具** | 锦袍 | `Chinese traditional silk robe garment, hanging displayed empty garment, no figure inside` + `--no character, person, figure inside` + `--sw 50` | ✅ 通过 |
| **饰品** | 玉龙佩 | `jade ornament pendant with silk cord, ceremonial accessory` + `--no sword, weapon, robe` + `--sw 50` + 细节糊属可接受 | ✅ 通过 |

---

## §4 核心 10 条教训沉淀

详 memory `feedback_mj_wuxia_prompt_pitfalls`:

1. 3 重水墨锚定 + 3 重 `--no` 防护必带
2. 武器类型(剑/刀/鞭)必明确锁定(MJ 不区分)
3. **`--sw 50` 防 sref 风格污染**(非剑装备必带,关键!)
4. 印章接受作国画落款(GDD §1 一致,Stage 2 不再防护)
5. 暖色词(`warm orange accent`)放大成全图红坑
6. 7 阶精致度梯度词汇(crude → divine)
7. 黑名单词永禁(legendary/epic/fantasy/anime/...)
8. `cinematic` 触发好莱坞油画风(Stage 0 套 B 事故根因)
9. `--stylize` 100/200/250/400 分级
10. 混合双轨设计(icon 无 sref + 详情大图带 sref + sw 50)

---

## §5 ChatGPT Baseline 11 张归档

`docs/art_ref/chatgpt_baseline/` 30MB,**审美北极星**(不当 MJ sref,只作风格参照对照)。

| 类 | 张数 | 关键候选 |
|---|---|---|
| characters | 5 | 斗笠剑客 / 女剑客 / 流星锤客 / 武僧 / 老宗师(对应 3 师徒角色)|
| ui | 1 | 江湖行主菜单(结构参考)|
| environments | 5 | 山村客栈 / 水乡夜雨 / 山门寺庙 / **雪中亭阁 ⭐**(主环境 sref 与之神还原)/ 山岩栈道 |

---

## §6 已知问题(Stage 2 处理)

| 问题 | 影响 | 应对 |
|---|---|---|
| `03_long_quan_detail.png` 211KB 偏小(grid 缩略图非 Upscale)| 详情页效果可能差 | **用户决议接受当前版本,不重 Upscale**(2026-05-20 拍板)|
| 印章 MJ 无法 100% 根除 | 已决议接受作国画落款 | 不需要处理 |
| `01_tie_jian_icon_alt.png` 备用 | 第一轮 grid 缩略图,可保留可删 | 不阻塞,Stage 2 可清理 |

---

## §7 1.0 路线图加权

- **P0 阶段 100% + P1 阶段 100% + Demo §7 12/12 ✅ + Demo §8.4 14/14 ✅ + M4 美术 PoC 完工 4/4 ✅**
- **加权 ~25% → ~30%**(M4 PoC 完工占 5%)

下一硬门槛:**Stage 2 量产 ~88 张**(28 装备 + 3 角色 + 5 闭关地图 + UI ~10 张),预计 4-6 周完工。

---

## §8 验证清单

- [x] Stage 0 spec 落地(commit `b06834a`)
- [x] Stage 0 跑图 + 4 张 sref 锁定
- [x] Stage 1 spec 落地(commit `3b4f628`)
- [x] Stage 1 5 件跑图(剑/刀/鞭) + 1.5 防具+饰品追加
- [x] 15 张 PoC 产物全规范命名 + 5 大类型全验证
- [x] 本 closeout + Stage 2 spec + memory 沉淀(本 commit)
- [x] PROGRESS.md 更新
- [x] commit + push origin/main
- [x] 新会话提示词输出(用户通知后)

---

## §9 Stage 2 入口

详 `art_poc_stage2_full_production_2026-05-20.md`:
- 全 28 件待跑装备清单(yaml 真实名)
- 3 师徒角色立绘 / 5 闭关地图 / UI ~10 张
- 5 类装备 prompt 模板库(剑/刀/鞭/防具/饰品)+ 角色 + 场景 + UI 模板
- 6 周批次规划(W1-W6,每周 1 批 ~30min Fast)
- 验收标准 + Fast time 预算 + Cost cap
