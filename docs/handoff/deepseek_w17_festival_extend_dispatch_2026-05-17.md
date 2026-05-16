# DeepSeek W17 节日 encounter 扩 chuXi/qingMingJie 派单(2026-05-17)

> 项目:挂机武侠 (F:\Projects\wuxia_idle 或 Pen 端等价路径)
>
> 派单方:Mac Opus
> 接单方:DeepSeek @ Pen Windows
> 派单 commit:本文档 push 后即派
> 预计工作量:DeepSeek ~30-45 分钟(沿 W16 已验证体例,只 +2 节日)
>
> **背景**:W16 节日 framework + DeepSeek 6 节日文案 + Codex 视觉验收 7 PASS 已全链闭环(详 PROGRESS.md `2026-05-16` 段)。W17 framework 层扩 `Festival` enum 6→8 加 **除夕(chuXi)** + **清明(qingMingJie)**(commit `9b795a0`),numbers.yaml 公历日期 + EnumL10n 中文映射 + 测试同步落地。本派单纯文案补 2 节日 encounter,**zero 代码改 / zero 数值红线撞击**。

---

## 0. 派单前必做

```powershell
# Pen 工作目录
Set-Location F:\Projects\wuxia_idle

# 拉最新代码(应到 HEAD 包含本派单 commit 或更新)
git pull --rebase --autostash

# 自检状态
git log --oneline -5
git status -s
```

预期 HEAD 包含 W17 framework commit `9b795a0` 与本派单 commit。工作树 clean。

---

## 1. 必读清单

| 文件 | 用途 |
|---|---|
| `WINDOWS_DEEPSEEK_GUIDE.md` §6 | 文案规范总则(基调 / 词汇 / 红线) |
| `CLAUDE.md` §5.6 / §9 | 不写数值 / 不写网游词汇 / 不写 UI 名词 红线 |
| `data/encounters.yaml` 末段(31-36) | W16 6 节日 entry 体例,W17 接 37/38 |
| `data/events/chun_jie_shou_sui.yaml` | 春节文案体例参考(同 chuXi 时段意象族,差异化对照) |
| `data/events/zhong_qiu_yue_xia_du.yaml` | 单独酌型文案体例(qingMingJie 雨中思故同基调) |
| `data/numbers.yaml` line 968-977 | 8 节日 enum 名 + 公历日期(W17 加的 chuXi 2026-02-16 / qingMingJie 2026-04-05) |
| `lib/core/domain/enums.dart` line 256-266 | Festival enum 8 项定义 + 双重身份注释(清明既节气又节日) |

**不要读 / 不要动**:
- `lib/` 下任何 Dart 文件(代码 zero 改)
- `data/numbers.yaml` 数值层(节日表 W17 已落 8 项)
- `data/encounter_skills.yaml` 35 招池(本批不解锁新招)
- `GDD.md` / `CLAUDE.md` / `IDS_REGISTRY.md`(我端在 closeout 时更新)

---

## 2. 任务清单

### 任务 A · `data/encounters.yaml` 加 2 节日 entry(36 → 38)

**目标**:文件末尾接 W16 第 36 条 chong_yang_deng_gao 后追加 2 个 encounter,绑 chuXi/qingMingJie 节日,纯 fortune 软门槛 + 节日维度,outcome 全 `attributeBonus`(zero 新解锁招式)。

**2 节日 entry 表**(严格按下表写,id / festivalRequired / attributeKey 锁死):

| 节日 | encounter id | festivalRequired | fortuneRequired | baseProbability | outcome A (key + delta) | outcome B (key + delta) |
|---|---|---|---|---|---|---|
| 除夕 | `chu_xi_ci_sui` | `chuXi` | 4 | 0.5 | `fortune` +1 | `enlightenment` +1 |
| 清明 | `qing_ming_yu_si` | `qingMingJie` | 4 | 0.5 | `enlightenment` +1 | `constitution` +1 |

**outcome 命名规则**(outcomeMapping key + events choices outcome_id 必须一致):

- 除夕 outcome key:`ci_sui_path_a` / `ci_sui_path_b`(去 id 前缀 `chu_xi_`)
- 清明 outcome key:`yu_si_path_a` / `yu_si_path_b`(去 id 前缀 `qing_ming_`)
- skip:**不在 outcomeMapping 配**,events 文件 choices 写 `outcome_id: skip`(framework 默认 `OutcomeType.none`)

**type 字段**:统一 `fortuneEvent`(与 W16 6 节日体例一致)。

**entry yaml 体例样例**(除夕,完整样例):

```yaml
  # ───────────────────────────────────────────────
  # 37. chu_xi_ci_sui · 辞岁
  #    fortuneEvent · 除夕(2026-02-16)当日 + fortune 软门槛
  # ───────────────────────────────────────────────
  - id: chu_xi_ci_sui
    type: fortuneEvent
    trigger:
      festivalRequired: chuXi
      fortuneRequired: 4
    baseProbability: 0.5
    outcomeMapping:
      ci_sui_path_a:
        type: attributeBonus
        attributeKey: fortune
        attributeDelta: 1
      ci_sui_path_b:
        type: attributeBonus
        attributeKey: enlightenment
        attributeDelta: 1
```

**注意**:
- entry 序号注释递增:`# 37.` 除夕 + `# 38.` 清明
- 加在 W16 第 36 条 `chong_yang_deng_gao` 之后,**不要插入中间**
- 缩进对齐现有 encounters(list 缩进 `  - id:`,trigger 字段缩进 4 空格)

---

### 任务 B · `data/events/<id>.yaml` 加 2 文案文件

**目标**:为任务 A 2 个 encounter 各写 1 个 events 文件,文件名严格等于 encounter id。

**2 文件清单**:

1. `data/events/chu_xi_ci_sui.yaml`
2. `data/events/qing_ming_yu_si.yaml`

**文案 schema 硬约束**(沿 W16 派单):
- 顶层 `id` 字段值等于文件名(去 `.yaml`)
- `title`:中文 3-5 字标题,武学/江湖气质(不用「活动」「庆典」「奖励」)
- `opening`:5-7 行场景铺垫,**点出节日意象但不报节日名**(从烟火/纸钱/雨声/纸鸢看出来),不写数值,不写 UI 名词
- `choices`:**严格 3 个**,顺序 path_a → path_b → skip
  - 每个 choice:`text`(8-12 字)+ `outcome_id` + `body`(3-5 行)
  - `outcome_id` 与任务 A 配置严格一致(`ci_sui_path_a` / `yu_si_path_a` 等;skip 用字面 `skip`)
- **不写具体数值**(语义上玩家感觉到收获即可)
- **不写网游词汇**:legendary / epic / 史诗 / 传说级 / 任务 / 奖励 / 副本 / 经验
- **不写 UI 名词**:slot / cooldown / 属性面板 / 数值
- 武学气质浓厚,水墨克制,青墨宣纸黄

---

## 3. 2 节日文案主题建议(DeepSeek 自由发挥)

| 节日 | 主要意象 | path_a 主题方向 | path_b 主题方向 | 与 W16 同族节日差异化 |
|---|---|---|---|---|
| 除夕 | 守岁、烟火、辞旧、镜前换装、爆竹 | 长街烟火得 → fortune(辞岁机缘) | 镜前换岁拔剑悟变化 → enlightenment(辞旧顿悟) | 与春节 chun_jie_shou_sui「围炉/雪夜静观」差异化:除夕侧重「辞旧动作」与「夜烟火集」,春节侧重「围炉静守」 |
| 清明 | 春雨、扫墓、踏青、纸鸢、柳枝 | 雨中静思故人剑意 → enlightenment(雨中悟道) | 踏青郊野行 → constitution(春行健身) | 与中秋 zhong_qiu_yue_xia_du「月下独酌悟剑」差异化:清明侧重「春雨/纸鸢/踏青」自然清新,中秋侧重「月圆/独酌」清冷孤高 |

**自由发挥范围**:具体场景(地点 / 配角 / 物件)、对话措辞、武学呼应细节皆 DeepSeek 拿捏。主题方向可微调,但 **outcome_id 与任务 A attributeKey 严格对齐**(除夕 path_a 必走 fortune,清明 path_b 必走 constitution)。

**清明双重身份提示**:清明既是节气也是节日,**本派单只写节日意象**(春雨/纸鸢/扫墓/踏青/柳枝),不要写「节气」「24 节气」字眼;数值层节气加成(retreat.solar_term_bonus 闭关 +30%)与节日 encounter 是独立通道(GDD §8.4),互不影响。

---

## 4. 文案完整样例(除夕,DeepSeek 比照写清明)

**`data/events/chu_xi_ci_sui.yaml`**:

```yaml
id: chu_xi_ci_sui
title: 辞岁
opening: |
  入夜,街市上行人如织,远处不时炸起一束烟花。
  你独自走过长街,见户户门前挂起新换的桃符。
  路过镜店,橱窗里映出你一身风尘——
  店主见你立着看,推门出来道:「公子若不嫌弃,进来照照新岁的镜子吧。」
  你略一犹豫,踏门而入。

choices:
  - text: 取烟火一束,夜里走街
    outcome_id: ci_sui_path_a
    body: |
      你从店主案上取了一束未燃的烟火,辞别后走出长街。
      行至空旷处,一手执火一手挥之,夜空里炸开一束星雨。
      你低头看自己掌心的星光,忽觉这一年走过的关山道路,皆在这一闪而过的光里。
      仿佛多年的孤行,也并非全然无依。

  - text: 镜前换岁,缓拔一剑
    outcome_id: ci_sui_path_b
    body: |
      你立在镜前,见自己旧岁的眉眼。
      慢慢抽出腰间长剑,剑身在油灯下泛起一道幽光。
      你忽觉这一剑收得太满——满到不能再藏一丝旧念。
      指尖一松,剑势骤变。新岁的第一招,在镜中悄然成形。

  - text: 拱手谢过,雪夜赶路
    outcome_id: skip
    body: |
      你向店主拱手,转身出门。
      长街上脚印只你一行,雪还在落。
      远处镇外的官道,正等着你的剑。
```

**写作要点(从样例提炼)**:
- opening 没出现「除夕」字眼,但「桃符」「烟花」「新岁镜子」让节日意象浮现
- 两个 outcome 主题对应:path_a(fortune)= 街中烟火得机缘;path_b(enlightenment)= 镜前剑势顿悟
- skip body:沉默离去,武侠味浓,雪夜赶路体现节日离索感
- 武学元素自然融入(腰间长剑 / 收剑势如水 / 新岁第一招)

---

## 5. 验收清单(DeepSeek 自检 + Mac 端复审)

DeepSeek 提交前自检:

- [ ] `data/encounters.yaml` 末尾追加 2 个 entry,序号 37/38,缩进对齐
- [ ] 每个 entry `id` / `festivalRequired` / `fortuneRequired` / `baseProbability` / `outcomeMapping` 完全等于任务 A 表
- [ ] 2 个 events 文件存在,文件名 = encounter id
- [ ] 每个 events 文件 `id` 字段值 = 文件名
- [ ] 每个 events 文件 choices 严格 3 个,顺序 path_a → path_b → skip
- [ ] 每个 outcome_id 与 encounters.yaml `outcomeMapping` key 严格对齐(skip 除外)
- [ ] 文案 grep 无:`机缘 +` / `身法 +` / `legendary` / `epic` / `史诗` / `传说级` / `任务奖励` / `副本` / `经验值` / `属性面板` / 具体数字(如「机缘 1 点」)
- [ ] 2 节日 opening 不直接出现「除夕」「清明」字眼(意象渗透)
- [ ] 清明 opening 不出现「节气」「24 节气」字眼(节气节日独立通道,本派单只走节日)
- [ ] commit message 中文,体例对齐 W16:`docs(w17): DeepSeek 节日 encounter chuXi/qingMingJie 2 文案落地`

Mac 端复审后:
- 跑 `flutter test test/features/encounter/domain/encounter_yaml_test.dart` 验加载层 36→38(Mac 端会同期改 test 数字断言)
- 跑 `flutter test` 全测,verify 761→763/763(预期 +2 个 encounter_yaml_test 加载层 entry 计数)
- 跑 `flutter analyze` 0 issues
- 0 数值红线撞击 / 0 中文文案漏入 lib/ / 0 GDD 改

---

## 6. 与 Mac 端协作流程

1. Mac 端把本派单 commit 并 push(派单生效)
2. **DeepSeek 在 Pen Windows 端开新会话**接此派单,完成任务 A+B
3. DeepSeek commit + push(commit message:`docs(w17): DeepSeek 节日 encounter chuXi/qingMingJie 2 文案落地`)
4. DeepSeek 写 closeout `docs/handoff/deepseek_w17_festival_extend_closeout_2026-05-17.md`(沿 W16 closeout 体例)
5. Mac 端 pull,跑 test + analyze 复审,有问题反审 / 无问题 PROGRESS 更新 + 同期改 encounter_yaml_test 36→38 + commit 销账

---

## 7. 硬约束(沿 WINDOWS_DEEPSEEK_GUIDE.md / CLAUDE.md)

- **不动 lib/**(代码 zero 改)
- **不动 data/numbers.yaml / GDD.md / CLAUDE.md / IDS_REGISTRY.md**
- **不动 data/encounter_skills.yaml / data/skills.yaml**(本批不解锁新招)
- **不动其他 events/<id>.yaml**(本批只加 2 个新文件)
- 数值红线 / 词汇红线见 CLAUDE.md §5.4 / §9 / WINDOWS_DEEPSEEK_GUIDE.md §6

---

## 8. 已知边角问题(派单方预判,DeepSeek 可忽略)

- **GDD §8.4 总量上限 30**:W16 已 30→36 略超,W17 36→38 进一步超。节日 encounter 是独立通道(全年 8 天概率窗口),实际玩家年内能触发的 base 池仍是 30。**Mac 端 closeout 备注 GDD §8.4**,DeepSeek 不动 GDD。
- **chip 视觉验收**:`_TodayFestivalChip` 在节日日才显,本派单不涉及视觉验收,DeepSeek 文案交付后 Mac 端单独派 Codex Pen 截 chuXi/qingMingJie 2 张 chip 截图。
- **encounter_yaml_test entry 计数**:Mac 端复审时同步改 36→38,**DeepSeek 不动 test**。
- **chuXi 与 chunJie 相邻日(2026-02-16 与 2026-02-17)**:玩家在春节前一天与春节当天可分别触发不同 encounter,意象差异化已在 §3 表中说明。

---

**派单文档结束。DeepSeek 接单后如有需要澄清,请在 Pen Windows 端开 issue 形式问 Mac 端**(本协作流程通过 GitHub 主分支 commit 同步)。
