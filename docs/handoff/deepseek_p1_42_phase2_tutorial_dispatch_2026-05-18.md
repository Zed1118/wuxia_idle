# DeepSeek 派单 · P1 #42 Phase 2 §10 P1.x 主线 Ch1 mandatory 标注 + 教学包装

> 2026-05-18,Mac + Opus 4.7 起草。**接 spec** `docs/handoff/p1_42_phase2_p1x_tutorial_spec.md` Phase 4。
> 配合 Mac 端 Phase 1-3 实装(已收口):tutorialStep 业务读写 + MainMenu 灰显 + NarrativeContent.mandatory wire。

## 0. 必读清单(派单前)

1. **本派单 spec**(本文)
2. `GDD.md` §10 新手引导(8 档解锁节奏 + 三种引导方式 + 设计哲学)
3. `WINDOWS_DEEPSEEK_GUIDE.md`(文学体例 + DeepSeek 端纪律)
4. 现有 Ch1 5 stage opening 体例参考:`data/narratives/stages/stage_01_0{1..5}_opening.yaml`(古风克制 + 场景白描 + 配角短语)
5. **memory `feedback_codex_backup`**:DeepSeek 文案体例硬约束(不写数值 / 招式名 / 网游词 / 大场面)

## 1. 任务一句话

主线 Ch1 5 个 stage opening yaml(`data/narratives/stages/stage_01_0{1..5}_opening.yaml`)**全部加 `mandatory: true` 字段**;**可选扩段**(2-3 段 → 5-7 段)通过"师父留下的叮嘱""你心中想起师父说过"等回忆/心境插入,加入 §10.1 8 档对应的教学要点暗喻(不直接讲数值,不破坏既有叙事逻辑)。

## 2. 5 个 stage opening 现状与扩段锚点

### 2.1 stage_01_01_opening 山门之外 · 启

**现有**(2 段,完整):
```yaml
id: stage_01_01_opening
title: 山门之外 · 启
paragraphs:
  - 山门已经看不见了。路两侧是半人高的野蒿，露水还没干。
  - 你背上那柄剑很沉，不是剑重，是师父的话重。山风从背后吹来，像是推了你一把。
```

**改动**:加 `mandatory: true`。**可选扩段锚点(§10.1 档 1:战斗 + 装备掉落)**:加 1-2 段插入师父叮嘱"剑握紧 / 看清招式"(暗喻招式倍率)+ "胜了便有所得"(暗喻装备掉落机制)。

### 2.2 stage_01_02_opening 荒山野店 · 启

**现有**(3 段,完整):
```yaml
id: stage_01_02_opening
title: 荒山野店 · 启
paragraphs:
  - 午时已过，日头正毒。山道边挑出一面破旗，上头歪歪扭扭写着「茶」字。
  - 旗杆下坐着一个独臂的老汉，正拿蒲扇赶苍蝇。他看见你，扇子停了。
  - 「客官，这大晌午的——赶路还是等人？」
```

**改动**:加 `mandatory: true`。**可选扩段锚点(§10.1 档 2:装备强化 + 共鸣)**:加 1-2 段独臂老汉的旁白或玩家心理,提点"器物用得久了便有灵性 / 磨砺方见锋芒"(暗喻装备共鸣 + 强化)。

### 2.3 stage_01_03_opening 黑风岭 · 启

**现有**(3 段):
```yaml
id: stage_01_03_opening
title: 黑风岭 · 启
paragraphs:
  - 山道转过一道弯，风声忽止。三十余条汉子从两侧的乱石后站起身来。
  - 当中一个独眼大汉提了把鬼头刀，咧嘴笑道：
  - 「这位小哥，山高路远，留下些买路钱再走。」
```

**改动**:加 `mandatory: true`。**可选扩段锚点(§10.1 档 3:心法主修)**:加 1-2 段玩家心境/呼吸调匀,联想"师父教过的运气法门"(暗喻心法主修)。

### 2.4 stage_01_04_opening 洛阳城外 · 启

**现有**(3 段):
```yaml
id: stage_01_04_opening
title: 洛阳城外 · 启
paragraphs:
  - 洛阳的城墙在暮色里是青灰色的。护城河上漂着几片柳叶，城门口的兵丁正在收吊桥。
  - 一个穿青衫的汉子靠在城门洞下，手里捏着一枚铜钱。他看见你背上的剑，把铜钱翻了个面。
  - 「出城的还是进城的？」
```

**改动**:加 `mandatory: true`。**可选扩段锚点(§10.1 档 4:三流派克制)**:加 1-2 段青衫汉子的暗语或玩家观察,提及"江湖路上招式各有所长,刚遇柔有刚的弱处"(暗喻三流派克制)。

### 2.5 stage_01_05_opening 风雨渡口 · 启

**现有**(3 段):
```yaml
id: stage_01_05_opening
title: 风雨渡口 · 启
paragraphs:
  - 渡口的风雨说来就来。黄河水翻着浊浪，摆渡的老艄公蹲在船舷上抽烟，斗笠上雨水成串。
  - 对岸码头上站了五个人，当中一个撑着油纸伞，看不清脸。
  - 老艄公吐了口烟：「那几位爷，等你半天了。」
```

**改动**:加 `mandatory: true`。**可选扩段锚点(§10.1 档 5-6:闭关 + 师徒)**:加 1-2 段老艄公的话或风雨意境,提及"江湖路远,需得静坐养气 / 来日方长,自有传承"(暗喻闭关 + 师徒)。

## 3. 文学体例硬约束(沿 W18-A3 lore 派单纪律)

| 红线 | 说明 |
|---|---|
| **古风克制** | 沿现有 chapter1 5 opening 范例,不堆砌华丽词藻 |
| **不写数值** | "招式倍率""装备强化""挂机时长"等机制名禁用,改暗喻表达 |
| **不写招式名** | "听雨剑""火焰拳"等具体招式名禁用 |
| **不写网游词** | "副本""boss""攻击力""暴击""装备词条"等禁用 |
| **不写大场面** | "魔教来袭""一招破天"等夸张场景禁用,保持寻常人调子 |
| **不破坏叙事逻辑** | 师父已留在山门内,玩家在山门外;师父教学**只能用回忆/叮嘱/心境**插入,不能让师父出现在场景中 |
| **段数 5-7 段** | 现有 2-3 段 + 扩 2-4 段,字数 50-80 字/段 |
| **mandatory 字段位置** | yaml 顶层第三行(`title` 后,`paragraphs` 前),保持文件可读性 |

## 4. 自审清单(交付前)

- [ ] 5 个 yaml 全部加 `mandatory: true`(grep 验证)
- [ ] yaml 解析仍可通过(`mandatory: true` 在 title 后 paragraphs 前)
- [ ] 段数 5-7 范围内(若扩段)/ 仅加 mandatory(若不扩段)
- [ ] 字数 50-80 字/段
- [ ] 文学气质对齐现有 5 opening(古风克制 / 寻常人调子 / 场景白描)
- [ ] 不出现数值 / 招式名 / 网游词 / 大场面
- [ ] 师父不在场景中(只用回忆 / 叮嘱 / 心境插入教学暗喻)
- [ ] 扩段后剧情仍能自然过渡到原 victory yaml(若有)

## 5. 范围拆解

### 5.1 最小动作(必做,~5min)

仅 5 个 yaml 加 `mandatory: true` 字段,**不改文案**:

```yaml
id: stage_01_01_opening
title: 山门之外 · 启
mandatory: true              # ← 加这一行
paragraphs:
  - 山门已经看不见了。路两侧是半人高的野蒿，露水还没干。
  - 你背上那柄剑很沉，不是剑重，是师父的话重。山风从背后吹来，像是推了你一把。
```

Mac 端 Phase 3 已落地 NarrativeContent.mandatory 解析 + Reader Skip 条件渲染。仅加字段即可生效"强制引导"行为。

### 5.2 推荐动作(可选,~30-60min)

5 yaml 扩段(2-3 段 → 5-7 段),加教学暗喻回忆/心境/旁白。每个 stage 按 §2 锚点提示扩段。

## 6. 与 Phase 1-3 Mac 端落地的联动

| Mac 端已落 | DeepSeek 端动作 | 玩家体验 |
|---|---|---|
| `NarrativeContent.mandatory` 字段 + `fromYaml` 解析 | yaml 加 `mandatory: true` | Ch1 opening 剧情不显跳过按钮 |
| `NarrativeReaderScreen` Skip 按钮条件渲染 | yaml 加 `mandatory: true` | 强制看完才能继续 |
| `MainMenu` 心法 step < 3 灰显 | 通 stage_01_03 自动解锁 | 玩家通过 3 关后心法面板按钮亮起 |
| `MainMenu` 闭关 step < 5 灰显 | 通 stage_01_05 自动解锁 | 通关 Ch1 后闭关按钮亮起 |
| `MainlineProgressService.recordVictory` 注入 TutorialService | (无需配合) | 通关 hook 自动递增 tutorialStep |

## 7. 交付流程

1. **DeepSeek 端在 Windows 完成 5 yaml 改动**(最小或推荐动作,二选一或部分扩段)
2. **commit 到 main 分支**(commit message 中文动宾:`[content] Ch1 opening 加 mandatory + 师父教学包装扩段`)
3. **push origin/main**
4. **Mac 端 git pull --rebase --autostash 同步**
5. **Mac 端跑全量 test 验证 yaml 解析无回归**(narrative_loader 现有 fixture 不变,只新增覆盖 mandatory 字段)
6. **Mac 端 closeout 段落引用本派单 SUMMARY**

## 8. 估时

| 范围 | 时长 | 备注 |
|---|---|---|
| 5.1 最小动作 | ~5min | 仅加 mandatory: true 字段 |
| 5.2 推荐动作 | ~30-60min | 5 yaml 扩段 + 文学体例自审 |
| 交付(commit/push) | ~5min | — |

**建议**:DeepSeek 端先做 5.1 最小动作 commit + push → Mac 端立即收口 closeout;DeepSeek 端**可选**在收口后另起 small 任务做 5.2 扩段(P1.y 滚动落地)。

## 9. 反例(W18-A3 lore 派单延续)

❌ 师父出现在场景中讲解机制(违反"师父留山门内"叙事逻辑)
❌ 句子里出现"招式倍率""装备强化""共鸣度""闭关时长"等机制词
❌ "魔教来袭""一招破天惊"等夸张大场面
❌ "听雨剑""龙形八卦掌"等具体招式名
❌ 字数超 100 字/段(寻常人调子要短句)
❌ mandatory 字段位置错(放 paragraphs 后导致 yaml 解析行为不变)
❌ Mac 端代码改动(本派单**完全文案层**,不动 lib/)
