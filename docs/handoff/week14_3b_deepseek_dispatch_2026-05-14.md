# W14-3-B DeepSeek 派单 · 补 12 条奇遇 events 文案(2026-05-14)

> 写给 Windows 端 DeepSeek。Mac 端 (Opus) 派单,完工后 Mac 端跑测试 + commit + push。
> **DeepSeek 写 `data/events/<id>.yaml` 12 个新文件,不要动 `data/encounters.yaml`、`lib/`、`test/` 或其他 yaml**。

---

## 1. 背景

Phase 4 W14-2 在 `data/encounters.yaml` 扩了 12 条 biome/weather 多维度 encounter(见 §3 清单),但 `data/events/<id>.yaml` 文案全缺。当前加载层(`encounter_event_loader.dart`)走 placeholder 兜底,**不会崩**,但玩家进 dialog 看到的是 `[文案待补:<id>]` 占位文字 + 一个"继续"按钮。

W14-3-B 目的:DeepSeek 补完 12 个 events yaml,让玩家在闭关挂机触发奇遇时能看到真实文案 + 有意义的选项分支。

W14-3-A(奇遇专属 skill 池 + 装备 UI)Mac 端已闭环(commit `9320286`)。W14-3-B 完成后,W14-3-C(dialog 节奏精修 + Codex Pen 视觉验收)才有实质内容可验。

---

## 2. 工作规范(必读)

### 2.1 文件位置 + 命名

- 12 个新文件,路径 `data/events/<id>.yaml`,文件名严格等于 §3 表中 id 列。
- DeepSeek **不动**:`data/encounters.yaml`、`data/narratives/`、`data/lore/`、`lib/`、`test/`、任何根目录 yaml。
- 已有的 26 个 events yaml(W14-1 + 既有)**不动**。

### 2.2 schema(参考 `data/events/bamboo_listen_rain.yaml`)

```yaml
id: <encounter_id>             # 严格等于文件名,严格等于 encounters.yaml 中 id
title: <中文标题>              # 5-7 字为佳,不要带书名号
opening: |                     # 进入 dialog 时玩家看到的"场景描写",建议 3-5 行
  <场景文字,水墨克制,不教程化,见 §4 文风>

choices:
  - text: <2-5 字动作短语>     # 玩家点击按钮上的文字
    outcome_id: <outcome_id>   # 严格匹配 encounters.yaml outcomeMapping 中的 key,或 skip
    body: |                    # 玩家选了之后看到的"结果叙述",建议 3-5 行
      <叙事性结果文字,不要写"获得 X 属性 +1",数值反馈走 UI banner>

  # ... 重复
```

### 2.3 choices 数量与覆盖

- **每条 event 的 choices 数量 = encounters.yaml `outcomeMapping` 中 outcome 数 + 1 个 skip 选项**(沿 W14-1 体例,见 `bamboo_listen_rain.yaml` / `du_ke_wen_dao.yaml`)
- skip 选项的 outcome_id 固定写 `skip`,body 写"放弃此次机缘"型文字(可以是"转身离去""不感兴趣""默念离开"等)
- skip 之外的 outcome_id 必须**严格匹配** §3 表中对应 event 的 outcomeMapping key,大小写、下划线全对齐

### 2.4 红线(加载层强校验)

- yaml 顶层 `id` 字段必须等于文件名(不带 .yaml 后缀)
- choices 中每个 `outcome_id`(除 `skip` 外)必须在 encounters.yaml 该 event 的 outcomeMapping 中存在 — **写错 outcome_id 会导致游戏启动失败(StateError)**,这是 Mac 端红线
- 加载失败(yaml 解析错误 / 文件读不到)→ 加载层回 placeholder,**运行期不会崩**,但视觉验收会暴露

---

## 3. 12 条 events 待补清单

> trigger 列写的是触发条件(给 DeepSeek 理解场景),DeepSeek 不需要在 events yaml 中复述 trigger。
> outcome 列写 outcome_id → 效果,**DeepSeek 用 outcome_id 命名 choice、用效果方向写 body 文字**,不写"属性 +1"这种 UI 语言。

### #4 古剑冢拾遗 `gu_jian_zhong_yin`(techniqueInsight)

- **trigger**:古剑冢闭关 ≥ 60min + 雾日 ≥ 30min + 机缘 ≥ 4
- **场景**:玩家在古剑冢(swordTomb)沉浸于雾日剑意,偶得遗物
- **outcome_id**:
  - `find_relic_sword` → 领悟招式 `skill_encounter_relic_blade`(剑冢遗剑,3 阶,GDD §5.3)
  - `polish_sword` → 根骨 +1(打磨剑器,体魄渐厚)
  - `skip`

### #5 藏经阁悟道 `cang_jing_ge_wu`(techniqueInsight)

- **trigger**:藏经阁累计 ≥ 120min + 机缘 ≥ 3
- **场景**:玩家在藏经阁(temple)长时间研读古籍,有所悟道
- **outcome_id**:
  - `deep_meditation` → 悟性 +1(深度禅定)
  - `read_classic` → 机缘 +1(读到秘传典籍)
  - `skip`

### #6 山林奇遇 `shan_lin_qi_yu`(fortuneEvent)

- **trigger**:山林累计 ≥ 90min + 机缘 ≥ 2(早期门槛低,新手友好)
- **场景**:玩家在山林(mountainForest)行走时遇到事件(行人 / 野兽 / 其他)
- **outcome_id**:
  - `help_traveller` → 机缘 +1(助人为乐)
  - `hunt_beast` → 根骨 +1(猎兽得肉)
  - `skip`

### #7 悬崖瀑布历练 `xuan_ya_pu_bu_li_lian`(techniqueInsight)

- **trigger**:悬崖瀑布(cliffWaterfall)≥ 60min + 雨 ≥ 60min + 机缘 ≥ 5
- **场景**:玩家在瀑布下经雨水冲淋,体悟水气流转之意
- **outcome_id**:
  - `withstand_water` → 根骨 +1(抗住寒水)
  - `merge_with_water` → 领悟招式 `skill_encounter_water_qi`(水气合一,5 阶高门槛)
  - `skip`

### #8 断崖锤炼 `duan_ya_chui_lian`(techniqueInsight)

- **trigger**:断崖(cliff)≥ 60min + 雪 ≥ 60min + 机缘 ≥ 7(后期高门槛)
- **场景**:玩家在断崖雪中长时间苦修,顿悟破冰之道
- **outcome_id**:
  - `endure_cold` → 根骨 +1(抗住雪寒)
  - `shatter_ice` → 领悟招式 `skill_encounter_ice_break`(碎冰破雪,6 阶后期)
  - `skip`

### #9 山道雾遮 `shan_dao_wu_zhe`(fortuneEvent)

- **trigger**:山道(mountainPath)≥ 30min + 雾 ≥ 30min + 机缘 ≥ 3
- **场景**:玩家在雾中山道上遇到迷途路人
- **outcome_id**:
  - `help_lost` → 机缘 +1(指路得善缘)
  - `ignore_passerby` → 无效果(none — 但仍要写 body,玩家选了"绕过"也要有叙事感)
  - `skip`(注意:`ignore_passerby` 与 `skip` 在游戏机制上都是 none,但叙事可不同,DeepSeek 自由发挥)

### #10 小镇问翳 `xiao_zhen_wen_yi`(fortuneEvent)

- **trigger**:客栈(inn)累计 ≥ 60min + 机缘 ≥ 4
- **场景**:玩家在客栈与江湖人物饮酒,听闻江湖密辛
- **outcome_id**:
  - `share_drink` → 机缘 +1(酒逢知己)
  - `eavesdrop` → 悟性 +1(偷听到武学心得)
  - `skip`

### #11 夜行寻道 `ye_xing_xun_dao`(techniqueInsight)

- **trigger**:夜(night,跨地图)累计 ≥ 60min + 机缘 ≥ 5
- **场景**:玩家在夜色中行走,月下顿悟夜战之妙
- **outcome_id**:
  - `moonlight_practice` → 身法 +1(月下练功)
  - `hidden_battle` → 领悟招式 `skill_encounter_night_strike`(夜袭杀招,5 阶)
  - `skip`

### #12 渡口春雨 `du_kou_chun_yu`(fortuneEvent)

- **trigger**:渡口(dock)≥ 45min + 雨 ≥ 60min + 机缘 ≥ 4
- **场景**:玩家在春雨渡口等船时遇到事件(船家 / 同行旅人 / 其他)
- **outcome_id**:
  - `wait_boatman` → 机缘 +1(耐心等船,船家相赠)
  - `help_stranger` → 根骨 +1(扛包搬物,身体渐壮)
  - `skip`

### #13 群侠图 `qun_xia_tu`(techniqueInsight)

- **trigger**:校场(drillGround)≥ 30min + 击败 5 名刚猛(gangMeng)流派敌人 + 机缘 ≥ 3
- **场景**:玩家在校场观摩或挑战刚猛流派高手
- **outcome_id**:
  - `admire_master` → 悟性 +1(观摩学艺)
  - `challenge_winner` → 领悟招式 `skill_encounter_drill_strike`(校场制胜,3 阶)
  - `skip`

### #14 路旁闲贤 `lu_pang_xian_xian`(fortuneEvent)

- **trigger**:镖路(escortRoad)累计 ≥ 60min + 机缘 ≥ 4
- **场景**:玩家在镖路上遇到隐居高人或江湖闲客
- **outcome_id**:
  - `listen_tale` → 机缘 +1(听江湖故事)
  - `share_food` → 悟性 +1(共享干粮,得到指点)
  - `skip`

### #15 古道雪迹 `gu_dao_xue_ji`(fortuneEvent)

- **trigger**:山道(mountainPath)≥ 30min + 雪 ≥ 30min + 机缘 ≥ 5
- **场景**:玩家在雪后山道上发现踪迹或寻到避雪处
- **outcome_id**:
  - `track_footprints` → 身法 +1(追踪雪迹,步法精进)
  - `rest_at_pavilion` → 根骨 +1(雪亭避寒,养精蓄锐)
  - `skip`

---

## 4. 文风约定(沿 W14-1 / WINDOWS_DEEPSEEK_GUIDE.md)

- **基调**:水墨克制,不渲染情绪,不夸张数值,玩家自行体悟
- **数值反馈**:不要在 body 写"获得机缘 +1""根骨提升"这种 UI 词汇,这些走 SnackBar
- **叙事密度**:opening 3-5 行,body 3-5 行,每行不超过 25 字
- **句尾标点**:`。` 或 `——` 或留白,不用 `!` `?` 之外的现代标点
- **意象参考**:GDD §1 (写实武侠基调) + W14-1 三个已交付 events(`bamboo_listen_rain` `cha_ting_dui_ju` `du_ke_wen_dao`)是文风标杆
- **避免**:网游词汇("解锁"换"领悟","奖励"换"机缘"等)、教程语言("点击 X 按钮""你需要先去做 Y")

---

## 5. 验收流程(DeepSeek 完工后通知 Mac)

DeepSeek 端完工后:

1. `git status` 应看到 12 个新文件 `data/events/<id>.yaml`(无其他改动)
2. `git add data/events/` + commit + push 到 main
3. 通知 Mac 端

Mac 端拉取后跑:

```bash
flutter test test/data/encounter_yaml_test.dart
flutter test test/data/         # 全 yaml 红线
flutter analyze
```

通过则 commit `feat(W14-3-B):` 描述,加 Mac 端的 placeholder 退场红线测试(可选,后补)。

任一测试失败 → 回 DeepSeek 修文案,**不要 Mac 端硬改 yaml 内容**(职责分清)。

---

## 6. 数据快照

- 涉及文件:12 个新 `data/events/<id>.yaml`(共 ~80-120 行 / 文件)
- 不涉及:`data/encounters.yaml`(已固定,Mac 端 W14-2 commit `d006670`)、`lib/` 全部、`test/` 全部
- 预期 commit:DeepSeek 1 个 commit(写文案);Mac 1 个 commit(跑测试 + 可能补红线 test)
- 验收完成后由 Mac 在 PROGRESS.md 标 W14-3-B 闭环,启动 W14-3-C

---

**文档结束。DeepSeek 看 §3 12 条清单 + §2 schema + §4 文风,逐条产出 yaml。**
