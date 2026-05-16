# DeepSeek W16 节日 encounter 文案派单(2026-05-16)

> 项目:挂机武侠 (F:\Projects\wuxia_idle 或 Pen 端等价路径)
>
> 派单方:Mac Opus
> 接单方:DeepSeek @ Pen Windows
> 派单 commit:本文档 push 后即派
> 预计工作量:DeepSeek ~1-1.5h
>
> **背景**:W16 GDD §12.4 节日活动 framework 已 0→1 落地(commit `5ea1f60`,详 `PROGRESS.md` 当前阶段)。代码层 `Festival` enum 6 节日 + `EncounterTrigger.festivalRequired` 字段 + `encounter_hook` 维度审核全通,**主菜单 `_TodayFestivalChip` 已在等节日 encounter 真触发后落地视觉验收**。本批派单纯文案补内容(zero 代码改),让 6 节日各 1 条 encounter 在节日日有效。

---

## 0. 派单前必做

```powershell
# Pen 工作目录
Set-Location F:\Projects\wuxia_idle

# 拉最新代码(应到 HEAD 包含本派单文件的 commit 或更新)
git pull --rebase --autostash

# 自检状态
git log --oneline -5
git status -s
```

预期 HEAD 包含本派单 commit `docs(w16): DeepSeek 节日 encounter 派单`。工作树 clean。

---

## 1. 必读清单

| 文件 | 用途 |
|---|---|
| `WINDOWS_DEEPSEEK_GUIDE.md` §6 | 文案规范总则(基调 / 词汇 / 红线) |
| `CLAUDE.md` §5.6 / §9 | 不写数值 / 不写网游词汇 / 不写 UI 名词 红线 |
| `data/encounters.yaml` (头 100 行) | encounter entry yaml schema + 现有 30 条体例 |
| `data/events/du_ke_wen_dao.yaml` | **双 `attributeBonus` + skip 文案体例参考**(本派单 6 节日同结构) |
| `data/events/bamboo_listen_rain.yaml` | 单 `unlockSkill` + 单 `attributeBonus` + skip 文案体例参考(对照差异) |
| `data/numbers.yaml` line 966-976 | 6 节日 enum 名 + 公历日期对照(`chunJie` `yuanXiao` `duanWu` `qiXi` `zhongQiu` `chongYang`) |
| `lib/features/festival/application/festival_service.dart` | framework service 文档注释,确认 `Festival.values.byName(...)` 加载体例 |

**不要读 / 不要动**:
- `lib/` 下任何 Dart 文件(代码 zero 改)
- `data/numbers.yaml` 数值层(节日表已落)
- `data/encounter_skills.yaml` 35 招池(本批不解锁新招)
- `GDD.md` / `CLAUDE.md` / `IDS_REGISTRY.md`(我端在派单 closeout 时更新)

---

## 2. 任务清单

### 任务 A · `data/encounters.yaml` 加 6 节日 entry(30 → 36)

**目标**:文件末尾追加 6 个 encounter,每个绑一个节日,纯 fortune 软门槛 + 节日维度,outcome 全部 `attributeBonus`(zero 新解锁招式,zero 数值红线撞击)。

**6 节日 entry 表**(严格按下表写,id / festivalRequired / attributeKey 锁死):

| 节日 | encounter id | festivalRequired | fortuneRequired | baseProbability | outcome A (key + delta) | outcome B (key + delta) |
|---|---|---|---|---|---|---|
| 春节 | `chun_jie_shou_sui` | `chunJie` | 4 | 0.5 | `fortune` +1 | `enlightenment` +1 |
| 元宵 | `yuan_xiao_guan_deng` | `yuanXiao` | 4 | 0.5 | `fortune` +1 | `agility` +1 |
| 端午 | `duan_wu_du_long_zhou` | `duanWu` | 4 | 0.5 | `constitution` +1 | `enlightenment` +1 |
| 七夕 | `qi_xi_xi_qiao` | `qiXi` | 4 | 0.5 | `agility` +1 | `enlightenment` +1 |
| 中秋 | `zhong_qiu_yue_xia_du` | `zhongQiu` | 4 | 0.5 | `enlightenment` +1 | `agility` +1 |
| 重阳 | `chong_yang_deng_gao` | `chongYang` | 4 | 0.5 | `constitution` +1 | `fortune` +1 |

**outcome 命名规则**(outcomeMapping key + events choices outcome_id 必须一致):

- outcome A key:`{节日 id 短名}_path_a`(如 `shou_sui_path_a` / `guan_deng_path_a` / `du_long_zhou_path_a` / `xi_qiao_path_a` / `yue_xia_du_path_a` / `deng_gao_path_a`)
- outcome B key:`{节日 id 短名}_path_b`
- skip:**不在 outcomeMapping 配**,events/<id>.yaml choices 写 `outcome_id: skip`(framework 默认 `OutcomeType.none`)

**type 字段**:统一用 `fortuneEvent`(纯属性提升 + 应景文案,符合 `fortuneEvent` 语义;techniqueInsight 用于 unlockSkill,本批不涉及)。

**entry yaml 体例样例**(春节,作为完整样例,其余 5 节日比照写):

```yaml
  # ───────────────────────────────────────────────
  # 31. chun_jie_shou_sui · 守岁夜
  #    fortuneEvent · 春节(2026-02-17)当日 + fortune 软门槛
  # ───────────────────────────────────────────────
  - id: chun_jie_shou_sui
    type: fortuneEvent
    trigger:
      festivalRequired: chunJie
      fortuneRequired: 4
    baseProbability: 0.5
    outcomeMapping:
      shou_sui_path_a:
        type: attributeBonus
        attributeKey: fortune
        attributeDelta: 1
      shou_sui_path_b:
        type: attributeBonus
        attributeKey: enlightenment
        attributeDelta: 1
```

**注意**:
- entry 序号注释(`# 31.` 等)递增,从 31 接到 36
- 加在文件末尾(现有 30 条之后,**不要插入中间**)
- 缩进对齐现有 encounters(list 缩进 `  - id:`,trigger 字段缩进 4 空格)
- **节日维度独立通道**(GDD §8.4 上限 20-30 是基础奇遇内容总量,节日 encounter 仅节日日触发 < 全年 6 天概率窗口,不挤占基础池容量)

---

### 任务 B · `data/events/<id>.yaml` 加 6 文案文件

**目标**:为任务 A 6 个 encounter 各写 1 个对应 events 文件,文件名严格等于 encounter id(加载层强校验,失联抛错)。

**6 文件清单**:

1. `data/events/chun_jie_shou_sui.yaml`
2. `data/events/yuan_xiao_guan_deng.yaml`
3. `data/events/duan_wu_du_long_zhou.yaml`
4. `data/events/qi_xi_xi_qiao.yaml`
5. `data/events/zhong_qiu_yue_xia_du.yaml`
6. `data/events/chong_yang_deng_gao.yaml`

**文案 schema 硬约束**:
- 顶层 `id` 字段值必须等于文件名(去 `.yaml`)
- `title`:中文 3-5 字标题,武学/江湖气质(不用「活动」「庆典」「奖励」等网游词汇)
- `opening`:5-7 行场景铺垫,**点出节日意象但不报节日名**(让玩家从月圆/灯火/龙舟看出来,沉浸感优先),不写数值,不写 UI 名词
- `choices`:**严格 3 个**,顺序:path_a → path_b → skip
  - 每个 choice 由 `text`(选项文字,8-12 字)+ `outcome_id` + `body`(2-4 行选项后果文案)组成
  - `outcome_id` 与 任务 A 配置严格一致(`shou_sui_path_a` 等;skip 用字面 `skip`)
- **不写具体数值**(不写「机缘 +1」「身法 +1」字眼,语义上让玩家感觉到收获即可,数值由代码层 apply)
- **不写网游词汇**:legendary / epic / 史诗 / 传说级 / 任务 / 奖励 / 副本 / 经验 等
- **不写 UI 名词**:slot / cooldown / 属性面板 / 数值 等
- 武学气质浓厚,基调对齐现有 30 条 events 体例(水墨克制,青墨宣纸黄,不浓艳)

---

## 3. 文案完整样例(春节,DeepSeek 比照写)

**`data/events/chun_jie_shou_sui.yaml`**:

```yaml
id: chun_jie_shou_sui
title: 守岁夜
opening: |
  小镇傍晚,家家门前挂起红灯。
  你独自走在长街上,远处不时传来零星爆竹声。
  路过一户人家,门内一桌酒菜,老老少少围坐谈笑。
  屋主见你独行,起身相邀,你略一犹豫,推门进去坐下。
  老人执壶斟酒,孩童递来一颗糖。

choices:
  - text: 举杯共饮,听一段陈年旧事
    outcome_id: shou_sui_path_a
    body: |
      老人话匣子打开,从年轻时走江湖的趣闻讲到这宅院修起来的来龙去脉。
      你听得入神,杯中酒空了又满,满了又空。
      子夜钟响时,你忽觉胸中一股暖意,仿佛多年的孤行也并非全然无依。

  - text: 默坐窗前,看新岁第一片雪落
    outcome_id: shou_sui_path_b
    body: |
      你推门到院中,雪落无声,屋檐下红灯在风里轻摇。
      檐下水珠成串而下,你忽然想起白日里练剑的某个细节——
      原来收势的那一刻,与这檐水落地的节奏,本是同一种道理。

  - text: 起身告辞,雪夜赶路
    outcome_id: skip
    body: |
      你拱手谢过,披衣出门。
      长街上脚印只你一行,雪还在落。
      远处镇外的官道,正等着你的剑。
```

**写作要点(从样例提炼)**:
- opening 没有出现「春节」「除夕」字眼,但「红灯」「爆竹」「围坐」「子夜钟响」让节日意象自然浮现
- 两个 outcome 主题对应:path_a(fortune 机缘)= 共饮听故事得人情温度;path_b(enlightenment 顿悟)= 静观自然得武学感悟
- skip body:角色仍走江湖路,不强行收奖,武侠味浓
- 武学元素自然融入(白日练剑的回忆 / 镇外官道等剑),不强突兀
- 每个 choice body 3-5 行,opening 5-7 行,字数均衡

---

## 4. 6 节日文案主题建议(DeepSeek 自由发挥,以下仅供参考)

| 节日 | 主要意象 | path_a 主题方向 | path_b 主题方向 |
|---|---|---|---|
| 春节 | 守岁、爆竹、红灯、围炉、雪 | 围炉听故事 → fortune(人情机缘) | 静观雪落 → enlightenment(自然顿悟) |
| 元宵 | 花灯、灯谜、人潮、月圆、汤圆 | 猜中灯谜得彩头 → fortune(灯下奇缘) | 穿巷追灯练身法 → agility(灯火身手) |
| 端午 | 龙舟、艾草、菖蒲、汨罗、雄黄 | 江岸搏浪扛船 → constitution(江风劲力) | 凭吊屈子悟刚直 → enlightenment(忠义悟道) |
| 七夕 | 鹊桥、银河、针线、乞巧、星 | 跨过桥心绕游人 → agility(穿梭灵动) | 借光穿针思剑指 → enlightenment(精微悟剑) |
| 中秋 | 月圆、桂花、清光、独酌、剑舞 | 月下顿悟剑意 → enlightenment(圆缺悟道) | 月光下舞剑成影 → agility(月剑流转) |
| 重阳 | 登高、菊酒、远眺、茱萸、山风 | 攀崖至顶练腿力 → constitution(登顶劲行) | 山顶遇异人得指点 → fortune(高处奇遇) |

**自由发挥范围**:具体场景(地点 / 配角 / 物件)、对话措辞、武学呼应细节皆 DeepSeek 拿捏。主题方向可微调(如端午 path_a 改成「岸上劲风磨身骨」也合理),但**outcome_id 与任务 A attributeKey 必须严格对齐**(端午 path_a 必走 constitution)。

---

## 5. 验收清单(DeepSeek 自检 + Mac 端复审)

DeepSeek 提交前自检:

- [ ] `data/encounters.yaml` 末尾追加 6 个 entry,序号 31-36,缩进对齐
- [ ] 每个 entry `id` / `festivalRequired` / `fortuneRequired` / `baseProbability` / `outcomeMapping` 完全等于任务 A 表
- [ ] 6 个 events 文件存在,文件名 = encounter id
- [ ] 每个 events 文件 `id` 字段值 = 文件名
- [ ] 每个 events 文件 choices 严格 3 个,顺序 path_a → path_b → skip
- [ ] 每个 outcome_id 与 encounters.yaml `outcomeMapping` key 严格对齐(skip 除外)
- [ ] 文案 grep 无:`机缘 +` / `身法 +` / `legendary` / `epic` / `史诗` / `传说级` / `任务奖励` / `副本` / `经验值` / `属性面板` / 具体数字(如「机缘 1 点」「身法值」)
- [ ] 6 节日 opening 不直接出现「春节」「元宵」「端午」「七夕」「中秋」「重阳」字眼(意象渗透)
- [ ] commit message 中文,体例对齐 W15 polish closeout(`docs(w16): DeepSeek 节日 encounter 6 文案落地`)

Mac 端复审后:
- 跑 `flutter test test/data/encounter_yaml_test.dart` 验加载层 30 → 36(数字断言可能要 Mac 端同期改 + 改 encounter_def loader test),**DeepSeek 不动 test 文件**
- 跑 `flutter test` 全测,verify 753 → 759/759(预期 +6 个 encounter_yaml_test 加载层 entry 计数)
- 跑 `flutter analyze` 0 issues
- 0 数值红线撞击 / 0 中文文案漏入 lib/ / 0 GDD 改

---

## 6. 与 Mac 端协作流程

1. Mac 端把本派单 commit 并 push(派单生效)
2. **DeepSeek 在 Pen Windows 端开新会话**接此派单,完成任务 A+B
3. DeepSeek commit + push(commit message:`docs(w16): DeepSeek 节日 encounter 6 文案落地`)
4. DeepSeek 写 closeout `docs/handoff/deepseek_w16_festival_closeout_2026-05-16.md`(沿 W15 polish closeout 体例:本派单完成项 / 自检结果 / 已知偏差 / 总文件改动行数)
5. Mac 端 pull,跑 test + analyze 复审,有问题反审 / 无问题 PROGRESS 更新 + commit 销账

---

## 7. 硬约束(沿 WINDOWS_DEEPSEEK_GUIDE.md / CLAUDE.md)

- **不动 lib/**(代码 zero 改)
- **不动 data/numbers.yaml / GDD.md / CLAUDE.md / IDS_REGISTRY.md**(我端在派单 closeout 时更新 PROGRESS + 可能加 GDD §8.4 备注)
- **不动 data/encounter_skills.yaml / data/skills.yaml**(本批不解锁新招)
- **不动其他 events/<id>.yaml**(本批只加 6 个新文件)
- 数值红线 / 词汇红线见 CLAUDE.md §5.4 / §9 / WINDOWS_DEEPSEEK_GUIDE.md §6

---

## 8. 已知边角问题(派单方预判,DeepSeek 可忽略)

- **GDD §8.4 总量上限 30**:本批 30 → 36 略超,但节日 encounter 是独立通道(全年 6 天概率窗口),实际玩家年内能触发的 base 池仍是 30。**Mac 端在派单 closeout 时备注 GDD §8.4 即可**,DeepSeek 不动 GDD。
- **chip 视觉验收**:`_TodayFestivalChip` 在节日日才显,目前(2026-05-16)非节日日,chip 不可见是预期。验收需 Mac 端加 debug override 或 Codex Pen 调系统时间到 `2026-02-17`(春节)/ `2026-09-25`(中秋)等。**本派单不涉及视觉验收,DeepSeek 文案交付后 Mac 端单独安排**。
- **encounter_yaml_test entry 计数**:Mac 端复审时若该 test 硬编码 30 条则需同步改到 36,**DeepSeek 不动 test**。

---

**派单文档结束。DeepSeek 接单后如有需要澄清,请在 Pen Windows 端开 issue 形式问 Mac 端**(本协作流程通过 GitHub 主分支 commit 同步)。
