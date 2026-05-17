# DeepSeek 派单 · W18-A2 副产物 4 event yaml 文案(2026-05-17)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Windows DeepSeek
> 沟通契约:DeepSeek 全程不联系派单方,文案 commit + push 后 Mac 端拉自审

---

## 0. 必读清单

1. **本派单**
2. `WINDOWS_DEEPSEEK_GUIDE.md`(内容生产规范,DeepSeek 主指引)
3. `data/encounters.yaml`(本批 4 encounter 的触发条件 + outcomeMapping key,**outcome_id 必须严格对齐**)
4. `data/events/bamboo_listen_rain.yaml` + `data/events/duan_ya_chui_lian.yaml`(2 个老 techniqueInsight event 范例,沿格式 + 字数 + 文学气质)

---

## 1. 任务一句话

**写 4 个 event yaml(W18-A2 副产物),`data/events/{jiao_chang_chu_wu,an_xiang_xi_zhe,tie_pu_lian_quan,liu_zhi_jian_ying}.yaml`,每个 1 opening + 3 choices,outcome_id 严格对齐 encounters.yaml outcomeMapping key。**

Mac 端 2026-05-17 W18-A2 已 push 4 个 `techniqueInsight` encounter 到 `data/encounters.yaml`(commit `1e96cf6`),触发条件 + outcome 数值层完整,但 `data/events/<id>.yaml` 缺文案 — 按需 load 不阻塞启动/测试,但实战触发后 dialog 文案空。DeepSeek 端补 4 文件后 W18-A2 闭环 100% 收口。

---

## 2. 4 event 触发场景 + outcome 锚点表

每个 event 对应 `encounters.yaml` 一个 encounter(详 §3-§6 各 event 单独表)。**核心规则**:event yaml 的 `choices[].outcome_id` 必须严格 == encounters.yaml 该 encounter 的 `outcomeMapping` key,**少 1 个或拼错 1 个加载会失败**(GameRepository 红线校验)。

| event id | 触发场景一句话 | unlock skill | 3 outcome_id |
|---|---|---|---|
| jiao_chang_chu_wu | 校场练武 30min + 击败 50 刚猛敌后,玩家在校场某处见到一个练武老者(或感悟到一种朴拙的呼吸法) | 朴息图(tier 1)| `forge_basics` / `observe_stance` / `skip` |
| an_xiang_xi_zhe | 巷弄 45min + 夜 20min + fortune ≥ 4,玩家在某条暗巷夜行时见到一个练暗器的人/影 | 暗器初探(tier 2)| `ambush_practice` / `hide_stance` / `skip` |
| tie_pu_lian_quan | 铸剑铺 60min + 击败 200 刚猛敌 + fortune ≥ 4,玩家在某铸剑铺看到/参与一种锻造与拳法结合的练法 | 火拳(tier 3)| `forge_punch` / `hammer_grip` / `skip` |
| liu_zhi_jian_ying | 瀑布悬崖 75min + 击败 300 灵巧敌 + fortune ≥ 6,玩家在瀑布悬崖看到柳影/剑影/水势某种合一 | 清风剑(tier 4)| `wind_sword` / `river_step` / `skip` |

**校验**:每个 event 有 **3 个 choice**,outcome_id 设计:
- choice 1 outcome_id = encounters.yaml 中该 encounter outcomeMapping 第 1 key(unlockSkill 触发,如 `forge_basics`)
- choice 2 outcome_id = 第 2 key(attributeBonus 触发,如 `observe_stance`)
- choice 3 outcome_id = `skip`(outcomeMapping 不显式映射 → Mac 端 fallback `OutcomeType.none`,沿 `bamboo_listen_rain.yaml` 体例)

任一前 2 choice outcome_id 拼错会被 GameRepository 红线 fail-fast 卡住启动;第 3 choice 写 `skip` 即可。

---

## 3. event #1 · jiao_chang_chu_wu(校场初悟)

### 3.1 encounter 锚点(读自 encounters.yaml,**不要改**)

```yaml
- id: jiao_chang_chu_wu
  type: techniqueInsight
  trigger:
    biomeMinutes: { drillGround: 30 }
    schoolKillThreshold: { gangMeng: 50 }
    fortuneRequired: 3
  baseProbability: 0.45
  outcomeMapping:
    forge_basics:        # → unlockSkill 朴息图
      type: unlockSkill
      skillId: skill_encounter_pu_xi_tu
    observe_stance:      # → constitution +1
      type: attributeBonus
      attributeKey: constitution
    # outcomeMapping 仅 2 key,第 3 choice 用 outcome_id: skip(Mac 端 fallback OutcomeType.none)
```

### 3.2 招式 description(skill_encounter_pu_xi_tu)

「以最简单的一呼一吸调和周身气血,朴拙之中藏着吐纳法的本源。」

气质:**朴拙 + 校场气息 + 最早期 hook 心境**。

### 3.3 文案要求

- **title**:4-6 字中文,意境 ≈ 「校场初悟」/「老兵授息」/「拳脚之外」 任选(DeepSeek 自定)
- **opening**:4-7 行,描写校场的尘土 / 木桩 / 汗水 / 一个老者或一段呼吸节奏。**触发条件**(校场练武 30min + 击败 50 刚猛敌)**应在 opening 暗写**,如「你在校场已练了多日」「拳脚下的木桩裂了又换」。**避免**直白说时间或敌数。
- **choice 1**(对应 `forge_basics`)= 玩家选「学这朴息法」,**body 文案表达「悟」的瞬间**,**不**直说「学会了朴息图」(不剧透 skill name,unlock 提示走 UI banner)。3-5 行。
- **choice 2**(对应 `observe_stance`)= 玩家选「观摩 / 学姿不学息」,**body 文案表达「根骨增长」的体感**(不直说 `constitution +1`,体感如「肩沉了 / 站桩稳了 / 喘息长了」)。3-5 行。
- **choice 3**(`outcome_id: skip`,outcomeMapping 不显式映射 → Mac 端 fallback OutcomeType.none)= 玩家选「不学走开」,**body 文案表达「时机错过 / 心境不到」**。3-4 行。

格式范例参考 `data/events/bamboo_listen_rain.yaml`(范例 1)+ `data/events/duan_ya_chui_lian.yaml`(范例 2)。

---

## 4. event #2 · an_xiang_xi_zhe(暗巷习蛰)

### 4.1 encounter 锚点

```yaml
- id: an_xiang_xi_zhe
  type: techniqueInsight
  trigger:
    biomeMinutes: { alley: 45 }
    weatherMinutes: { night: 20 }
    fortuneRequired: 4
  baseProbability: 0.4
  outcomeMapping:
    ambush_practice:     # → unlockSkill 暗器初探
      type: unlockSkill
      skillId: skill_encounter_an_qi
    hide_stance:         # → agility +1
      type: attributeBonus
      attributeKey: agility
    # outcomeMapping 仅 2 key,第 3 choice 用 outcome_id: skip
```

### 4.2 招式 description(skill_encounter_an_qi)

「袖中藏刃,腕底翻花。江湖行走的第一课:明枪易挡,暗箭难防。」

气质:**夜行 + 阴影 + 江湖第一课**。

### 4.3 文案要求

- **title**:4-6 字,意境 ≈ 「暗巷一影」/「夜行袖间」 任选
- **opening**:4-7 行,描写巷弄的夜色 / 雨 / 灯 / 一个练暗器的人(或一段练招过程)。触发条件(巷弄 45min + 夜 20min)**应在 opening 暗写**,如「你在这巷子来回走了几次」「夜深了,提灯的人少」。
- **choice 1**(`ambush_practice`)= 玩家选「学这暗器」,body 表达「领会暗器之心」(不剧透「暗器初探」名字)。
- **choice 2**(`hide_stance`)= 玩家选「学藏不学打」,body 表达「身法增长」体感(脚步轻 / 影子稀 / 不直说 `agility +1`)。
- **choice 3**(`outcome_id: skip`)= 玩家选离开,body 表达江湖路远 / 暗器非正道之类。

---

## 5. event #3 · tie_pu_lian_quan(铁铺炼拳)

### 5.1 encounter 锚点

```yaml
- id: tie_pu_lian_quan
  type: techniqueInsight
  trigger:
    biomeMinutes: { smithy: 60 }
    schoolKillThreshold: { gangMeng: 200 }
    fortuneRequired: 4
  baseProbability: 0.45
  outcomeMapping:
    forge_punch:         # → unlockSkill 火拳
      type: unlockSkill
      skillId: skill_encounter_huo_quan
    hammer_grip:         # → constitution +1
      type: attributeBonus
      attributeKey: constitution
    # outcomeMapping 仅 2 key,第 3 choice 用 outcome_id: skip
```

### 5.2 招式 description(skill_encounter_huo_quan)

「拳出如落日般炽烈,低光直射对方面门——灼热的拳风从暗处来,光明也有暗角。」

气质:**铸剑铺红炉 + 锻铁 + 拳风炽烈 + 中期境界**。

### 5.3 文案要求

- **title**:4-6 字,意境 ≈ 「炉前问拳」/「锤声入掌」 任选
- **opening**:4-7 行,描写铸剑铺的红炉 / 锤声 / 火星 / 一个老铁匠或一个练拳之人。触发条件(铸剑铺 60min + 击败 200 刚猛敌)暗写,如「你在这铺子里坐了好几日」「拳脚上的茧厚了又破了」。
- **choice 1**(`forge_punch`)= 玩家选「学这火拳」,body 表达「火气入掌」之瞬。
- **choice 2**(`hammer_grip`)= 玩家选「只学握锤之法」,body 表达「臂力 / 根骨」体感。
- **choice 3**(`outcome_id: skip`)= 玩家离开,body 表达「火气太燥」或「锻造非吾之道」。

---

## 6. event #4 · liu_zhi_jian_ying(柳枝剑影)

### 6.1 encounter 锚点

```yaml
- id: liu_zhi_jian_ying
  type: techniqueInsight
  trigger:
    biomeMinutes: { cliffWaterfall: 75 }
    schoolKillThreshold: { lingQiao: 300 }
    fortuneRequired: 6
  baseProbability: 0.4
  outcomeMapping:
    wind_sword:          # → unlockSkill 清风剑
      type: unlockSkill
      skillId: skill_encounter_qing_feng_jian
    river_step:          # → agility +1
      type: attributeBonus
      attributeKey: agility
    # outcomeMapping 仅 2 key,第 3 choice 用 outcome_id: skip
```

### 6.2 招式 description(skill_encounter_qing_feng_jian)

「剑尖自斜下掠向斜上,取的不是要害,是对手的下一招。秋水时至,一剑天涯。」

气质:**瀑布悬崖 + 水势剑势合一 + 中后期境界 + 飘逸**。

### 6.3 文案要求

- **title**:4-6 字,意境 ≈ 「瀑下问剑」/「水中剑影」 任选
- **opening**:4-7 行,描写瀑布悬崖的水势 / 柳枝 / 雾 / 一个剑客或一段悟道时刻。触发条件(瀑布悬崖 75min + 击败 300 灵巧敌)暗写,如「你在这悬崖看了多日水」「剑鞘上沾了几次雾」。
- **choice 1**(`wind_sword`)= 玩家选「悟这清风剑」,body 表达「剑势如水」之顿悟。
- **choice 2**(`river_step`)= 玩家选「学水势步法」,body 表达「身法 / 灵巧」体感。
- **choice 3**(`outcome_id: skip`)= 玩家离开,body 表达「剑道不到 / 水势难学」。

---

## 7. 体例锚点(每 event 通用)

读 `data/events/bamboo_listen_rain.yaml` + `data/events/duan_ya_chui_lian.yaml`,这两个是 W14 范例和近期范例,**沿:**

- yaml 顶层字段:`id` / `title` / `opening` / `choices`
- `opening: |` 多行字符串,行宽 ≤ 60 字符,4-7 行
- `choices` 数组,**3 项**(顺序 unlock / attributeBonus / skip)
- 每 choice:`text`(4-6 字)+ `outcome_id`(严格匹配 §3-§6 表)+ `body: |`(3-5 行)
- 文学气质:**写实武侠**,避免「玄幻」「修仙」「灵气」「斗气」等词,贴近古龙 / 金庸早期短句
- **不堆叠数字 / 状态条 / 网游词汇**(避免「+1 根骨」「装备掉落」「buff」「debuff」「副本」)
- 避免「冒险」「副本」「BOSS」「关卡」等网游 UI 词,改用「行走江湖」「试招」「敌手」「关隘」

---

## 8. 硬约束

- 仅在 `data/events/` 新建 4 文件,**不要**动:
  - `data/encounters.yaml`(Mac 领地,本批已 push)
  - `data/encounter_skills.yaml`(Mac 领地,4 招 description 已 W14 落地)
  - `data/lore/` / `data/narratives/`(本派单不涉)
  - `data/*.yaml` 顶层(Mac 领地)
  - `lib/` 任何 Dart 代码(Mac 领地)
  - `GDD.md` / `CLAUDE.md` / `PROGRESS.md` / `IDS_REGISTRY.md`
- `outcome_id` 必须严格对齐 §3-§6 表,**全 4 文件加起来 12 个 outcome_id**(每 event 3 choice),其中 4 个是 `skip`(choice 3 fallback),8 个对应 encounters.yaml outcomeMapping(每 encounter 2 key × 4 encounter)。Mac 端 GameRepository 启动时自动校验前 8 个,`skip` 走 fallback OutcomeType.none。
- 文案不引入 Mac 端未定义的概念(新流派 / 新装备 tier / 新心法)。
- 单文件**字数控制**:总 yaml 体积 ≤ 50 行(opening + 3 body 不堆冗长)。

---

## 9. 交付 + 自检

1. 4 个新文件提交后,**自检**:
   - `ls data/events/ | grep -E "jiao_chang_chu_wu|an_xiang_xi_zhe|tie_pu_lian_quan|liu_zhi_jian_ying"` 应显 4 行
   - `grep "outcome_id:" data/events/{4 个新文件}.yaml` 列出 12 个 outcome_id,无拼写错
   - **可选**:Pen 端有 Flutter 跑 `flutter test test/data/encounter_yaml_test.dart` 拿 0 fail(red-line 加载校验通)
2. commit message 中文,format:`content(w18-a2): 4 event yaml(jiao_chang_chu_wu / an_xiang_xi_zhe / tie_pu_lian_quan / liu_zhi_jian_ying)`
3. push 到 `origin/main`
4. 若 Mac 端 ultrareview 或视觉验收发现文案问题,Mac 端会留 issue / closeout,DeepSeek 端按需补改

---

## 10. A3 典故扩展(可选,本批不强推)

GDD §7 「典故 50-80 段」当前 `data/lore/` 共 75 段(35 yaml,平均 2.14 段/件),**已超过下限 50,在 50-80 区间内**。A3 扩展可选方向:

- 给 1-2 段的装备补到 2-3 段(平均 → 2.3-2.5 段/件)
- 总段数从 75 → 80 上限(+5 段)
- 选哪几件装备 DeepSeek 自由发挥(优先选 tier 4-7 战略装备:利器 / 重器 / 宝物 / 神物,典故承载度高)

**优先级**:**4 event yaml 必做**,A3 +5 段为软目标,DeepSeek 时间允许时顺手做,不强推。若做 A3,单独 commit。

---

## 11. 与并行任务说明

本派单**独立**,与 Mac 端并行任务无冲突:
- Mac 端 Codex Pen 视觉验收 W18-A1 心法相生(~1h)正在 Pen 跑,**仅截图不动 yaml**,不冲突
- Mac 端可能 W18-A1.2 defensePct + growth hook 扩展(Mac lib/data/synergies.yaml),不涉 events/

---

**派单文档结束。DeepSeek 接单后无需联系派单方,完成后 commit + push 即可,Mac 端定期拉自审。**
