# W15 DeepSeek 派单 · encounter_skills 剩余 34 招 narrativeInsightId 映射

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows DeepSeek
> 创建日期:2026-05-15
> 关联挂账:PROGRESS.md「下一步」· encounter_skills.yaml 剩余 34 招 narrativeInsightId 内容映射
> 上游 audit:`docs/handoff/deepseek_audit_w14_4_2026-05-15.md`(insights vs encounter_skills 命名失联结论)
> 上游销账:`#36 SkillDef.narrativeInsightId nullable 字段已落`(ting_yu_jian 首条映射已填)

---

## 1. 一句话目标

为 `data/encounter_skills.yaml` 剩余 34 招(`ting_yu_jian` 已映射)填 `narrativeInsightId: <insight_id>` 字段,把 35 招奇遇专属招式与 35 篇 武学领悟 insights 做**显式语义映射**(允许部分招式留空保留 2 体系独立性)。

---

## 2. 背景

### 2.1 为什么需要这次派单

W14-4 audit 发现:
- **35 篇 insights** 在 `data/narratives/techniques/insights/<id>.yaml`,中文诗意命名(`ting_yu_jian` / `can_juan_can_zhao` 等),含 description + prerequisite_hint
- **35 招 encounter skills** 在 `data/encounter_skills.yaml`,拼音功能命名(`skill_encounter_xxx`),仅 1/35 巧合命中(`ting_yu_jian`)
- **2 体系平行存在,语义关联缺失**

Mac 端 W15 销账 #36 时已落 `SkillDef.narrativeInsightId: String?` nullable 字段,并填 `ting_yu_jian` 首条映射作样例。剩余 34 招需要你基于**招式名/描述 + insight 名/描述**做语义判断填入。

### 2.2 为什么"允许留空"

W14-4 audit 推荐保留 2 体系独立 — 不强求 1:1 必映:
- **明显语义对接**的招式必填(例:招式名包含 insight 关键字 / 主题完全一致)
- **勉强凑对**的招式宁可留空,不要硬塞(保留 narrative 系统的设计空间)
- 允许**多招映射同一 insight**(若有多招主题都贴近某一篇,可重复指向)
- 允许**某 insight 不被任何招式引用**

---

## 3. 输入清单 · 35 招 vs 35 insights

### 3.1 35 招 encounter skills(tier 1 → 7)

> 来源:`data/encounter_skills.yaml`。**只读 name / description / tier / visualEffect 判断语义**,**不要碰数值字段**(powerMultiplier / internalForceCost / cooldownTurns / requiresManualTrigger)。

| tier | id | name | visualEffect 提示 |
|---|---|---|---|
| 1 | skill_encounter_jichu_buxi | 基础步息 | footwork_basic |
| 1 | skill_encounter_pu_xi_tu | 朴息图 | breathing_basic |
| 1 | skill_encounter_jian_bu | 渐步 | lightfoot_step |
| 1 | skill_encounter_qi_yu_jue | 起欲诀 | focus_strike |
| 1 | skill_encounter_tun_tu | 吞吐 | breathing_basic |
| 2 | skill_encounter_jian_yi | 剑意萌芽 | sword_intent_sprout |
| 2 | skill_encounter_qiu_quan | 求拳 | fist_seek |
| 2 | skill_encounter_an_qi | 暗器初探 | dart_basic |
| 2 | skill_encounter_pai_yun_zhang | 排云掌 | palm_cloud_break |
| 2 | skill_encounter_huo_du | 火毒 | poison_burn |
| 3 | skill_encounter_ting_yu_jian | 听雨剑 | sword_rain_listen | **★ 已映射 ting_yu_jian,不动** |
| 3 | skill_encounter_drill_strike | 凿击 | drill_thrust |
| 3 | skill_encounter_wu_xia_yi | 无瑕意 | flawless_intent |
| 3 | skill_encounter_huo_quan | 火拳 | fist_flame |
| 3 | skill_encounter_xuan_jian | 玄剑 | sword_mystery |
| 4 | skill_encounter_relic_blade | 遗刃 | blade_relic |
| 4 | skill_encounter_qing_feng_jian | 青锋剑 | sword_emerald |
| 4 | skill_encounter_lie_huo | 烈火 | flame_blaze |
| 4 | skill_encounter_xuan_yin | 玄阴 | yin_freeze |
| 4 | skill_encounter_fei_xian | 飞仙 | flight_celestial |
| 5 | skill_encounter_water_qi | 水气 | water_qi_flow |
| 5 | skill_encounter_night_strike | 夜袭 | night_strike_shadow |
| 5 | skill_encounter_lei_dian | 雷电 | thunder_strike |
| 5 | skill_encounter_jin_gang | 金刚 | adamantine_body |
| 5 | skill_encounter_shan_he | 山河 | landscape_force |
| 6 | skill_encounter_ice_break | 冰破 | ice_shatter |
| 6 | skill_encounter_xuan_bing | 玄冰 | ice_mystery |
| 6 | skill_encounter_lie_yan | 烈焰 | flame_intense |
| 6 | skill_encounter_qian_kun | 乾坤 | cosmos_pivot |
| 6 | skill_encounter_chen_xin | 沉心 | heart_settle |
| 7 | skill_encounter_long_yin | 龙吟 | dragon_roar |
| 7 | skill_encounter_feng_qi | 风起 | wind_arise |
| 7 | skill_encounter_yi_jian | 一剑 | sword_one |
| 7 | skill_encounter_wu_ming | 无名 | nameless |
| 7 | skill_encounter_tian_dao | 天道 | celestial_dao |

### 3.2 35 篇 insights(完整列表)

> 来源:`data/narratives/techniques/insights/<id>.yaml`。完整列表 35 个 id(按字母序):

```
can_bei_zhang_feng    残碑掌风
can_juan_can_zhao     残卷残照
can_yang_ru_xue       残阳如血
cang_long_zhua        苍龙爪
du_jiang_bei_wang     渡江北望
feng_zhong_can_zhu    风中残烛
gu_dao_xi_feng        古道西风
gu_miao_zhong_sheng   古庙钟声
han_feng_che_gu       寒风彻骨
han_ya_du_jiang       寒鸦渡江
huang_sha_bi_ri       黄沙蔽日
jing_di_wang_yue      井底望月
ku_chan_bu_dong       枯禅不动
liu_shui_wu_qing      流水无情
long_yin_shen_jian    龙吟深涧
luo_ye_gui_gen        落叶归根
ming_deng_zhi_yin     明灯指引
po_feng_yi_ji         破封一击
po_lang_yi_dao        破浪一刀
qi_mai_tong_shen      奇脉通神
qiu_shui_tian_ya      秋水天涯
shan_quan_ji_jian     山泉急溅
shuang_dong_qian_li   霜冻千里
shuang_jiang_man_tian 霜降满天
tie_suo_heng_jiang    铁索横江
ting_yu_jian          听雨剑          ★ 已被 skill_encounter_ting_yu_jian 引用
wu_hen_zhi_ji         无痕之机
xiao_xiang_ye_yu      潇湘夜雨
xing_luo_qi_qi        星罗棋栖
xue_ye_wu_hen        雪夜无痕
yan_hui_xu_ying       烟回虚影
ye_luo_wu_sheng      叶落无声
yi_dian_qian_jun      一点千钧
yi_qi_jue_chen       一气绝尘
yue_xia_du_ying      月下独影
```

**判断依据**:不只看名字,**必须打开每篇 insight 的 yaml 读 description**(50-100 字描述武学领悟的意境)。**招式 name + visualEffect 与 insight 描述的主题/意象是否吻合**,是关键判断点。

### 3.3 已知贴近候选(参考,不强制)

不动脑就能看出贴近的几条,供你校准判断尺度:
- `skill_encounter_long_yin`(龙吟,tier 7)↔ `long_yin_shen_jian`(龙吟深涧)— 名字 + 主题双重命中,推荐填
- `skill_encounter_ice_break`(冰破,tier 6)/ `skill_encounter_xuan_bing`(玄冰)↔ `shuang_dong_qian_li` / `shuang_jiang_man_tian`(霜冻/霜降题材)— 主题吻合
- `skill_encounter_qing_feng_jian`(青锋剑,tier 4)↔ `qiu_shui_tian_ya`(秋水天涯,剑客孤旅意象)— 主题相邻
- `skill_encounter_jian_yi`(剑意萌芽,tier 2)↔ 选哪篇你判断
- `skill_encounter_yi_jian`(一剑,tier 7)↔ `yi_dian_qian_jun`(一点千钧)— 凝练一击主题

剩余的你看 insight 描述判断。**勉强凑的宁可留空**,留空在 Mac 端是合法的(`narrativeInsightId` 是 nullable)。

---

## 4. 工作流

### 4.1 拉最新代码

```bash
cd F:\Projects\wuxia_idle  # 或你的项目路径
git pull --rebase --autostash
```

应到 HEAD `c718a60` 或更新。

### 4.2 编辑 `data/encounter_skills.yaml`

唯一编辑文件:`data/encounter_skills.yaml`(35 招)。**其他文件全部禁动**(Mac 端领地)。

**编辑规则**:
- 在每招的 yaml block 末尾(`tier:` 之后)按需追加一行:
  ```yaml
      narrativeInsightId: <insight_id>   # <可选简注>
  ```
- **空格缩进 4 个**(yaml block 内对齐 name/description/type 等字段)
- **注释可选**(单行说明你的判断理由,例:`# 命中:名字 + 主题双重命中`)
- **不映射的招式不填字段**(不写 `narrativeInsightId: null`,直接不写这行)
- **ting_yu_jian 已有映射不动**(已是 `narrativeInsightId: ting_yu_jian`)

### 4.3 校验

#### 4.3.1 yaml 解析(Mac 端会跑,但你本地 yamllint 一下更稳)

如 Windows 端有 Python:
```bash
python -c "import yaml; yaml.safe_load(open('data/encounter_skills.yaml', encoding='utf-8'))"
```
无错误 = 解析通过。

#### 4.3.2 insight_id 自洽

填的每个 `narrativeInsightId` 值必须**完整出现在 §3.2 的 35 个 id 列表中**。手动核对一遍:
```bash
grep "narrativeInsightId:" data/encounter_skills.yaml | awk '{print $2}' | sort -u
```
打印出来的 id 应是 §3.2 列表的子集。

### 4.4 commit + push

```bash
git add data/encounter_skills.yaml
git commit -m "feat(W15): encounter_skills 34 招 narrativeInsightId 内容映射

W15 #36 销账后剩余 34 招(ting_yu_jian 已映射)填 narrativeInsightId 字段。
基于招式 name/visualEffect 与 insight description 语义匹配,N 招填 / N 招留空保留 2 体系独立。

引用 35 insights 中 N 个(M 个 insight 未被引用,1 个被多招引用如适用)。
"
git push
```

替换 N / M 为实际数字。

---

## 5. 红线 · 不要做的事

- ❌ 改 yaml 任何数值字段(powerMultiplier / internalForceCost / cooldownTurns / requiresManualTrigger / tier 等)
- ❌ 改任何招式的 id / name / type / visualEffect
- ❌ 删除 ting_yu_jian 现有 narrativeInsightId(W15 #36 销账锚点)
- ❌ 动 Mac 端代码 / 数值 yaml / 其他 data 文件
- ❌ 编辑 `data/narratives/techniques/insights/` 下 insight 文件本身(只读引用)
- ❌ 自创新 insight_id(35 篇之外的不存在,Mac 端不接)
- ❌ 跨越 `data/narratives/` `data/lore/` `data/events/` 写新文件(本派单只动 1 个 yaml)
- ❌ 在 yaml 注释里写数值(GDD §5.6 红线,文案不带数值)

---

## 6. 范围预期

- **必映**:贴近度极高的 5-10 招(§3.3 已列样本)
- **可选映**:中等贴近的 10-15 招(看主题/意象/兵器风格)
- **不映**:剩余 10+ 招留空,保留 2 体系独立性

预计**最终映射 15-25 招**,不必追求 34 全填。质量优于数量。

---

## 7. closeout 模板(完成后写)

文件:`docs/handoff/deepseek_w15_34_insight_mapping_closeout_2026-05-15.md`

```markdown
# W15 DeepSeek 34 招 narrativeInsightId closeout

## 1. 总览
- 总映射:N / 34 招(ting_yu_jian 已映,本次新增 N)
- 引用 insights 数:M / 35 (X 个 insight 被多招引用)
- 留空招式:Y / 34(保留 2 体系独立性,W14-4 audit 推荐)

## 2. 映射决策表

| 招式 id | insight_id | 判断依据 |
|---|---|---|
| skill_encounter_long_yin | long_yin_shen_jian | 名字 + 主题双重命中 |
| skill_encounter_yi_jian | yi_dian_qian_jun | 一招制敌主题 |
| ... | ... | ... |

## 3. 故意留空的招式(N 条)

- skill_encounter_xxx — 理由:35 insights 无任何主题贴近,强填会破坏 narrative 独立性
- ...

## 4. 风险与挂账

- [可选]发现 insight 描述空 / 占位 / 不一致的情况

## 5. 提交

- commit: <hash>
- 推送 push 完
```

---

## 8. 不在本派单处理的事项

- **insight 本身的描述补全 / 修订** — DeepSeek 后续独立工作,本派单只做映射
- **encounter_skills 招式 description(TODO_NARRATIVE)** — 全部 35 招仍占位,后续 DeepSeek 独立派单补
- **新增 encounter skill / 新增 insight** — 不在本派单范围

---

**派单结束。完成后写 closeout + push 即结束。不联系派单方。Mac 端会在下次同步时拉到映射,跑测试 + analyze 验通,有问题再追派。**
