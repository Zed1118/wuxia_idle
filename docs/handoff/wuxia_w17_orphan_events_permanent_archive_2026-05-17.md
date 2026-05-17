# W17 #37 6 events orphan 永久封档(2026-05-17)

> Nightshift T01 产出。决议锁定:6 件 events orphan 留 `data/events/_archive/` **永久不挂回**,不再扫描不再评估。

## 1. 背景

W14-3 派 DeepSeek 23 events 时,因主题与 GDD §8.4 武学 / 心境 skill 池不匹配,6 件被归入 `_archive/`。W17 polish-C 挂回 2 件(`huang_yuan_yi_zhong → qiu_quan` / `jiang_xin_ye_hua → wu_xia_yi`),余 6 件评估后仍不挂回。

原始 23 件处理路径:第 1 批 6 件(W14-3 同批评估)+ 第 2 批 7 件(W15 挂回)+ C-1 收尾 2 件 + W17 polish-C 2 件 = 18 件挂回,本批 6 件永封档。

## 2. 6 文件逐文件分析

### 2.1 duan_qiao_can_yue(断桥残月)

- **主题**:等待与别离——老妪在断桥边守候离家未归的儿子,等桥修好等人回
- **不挂回理由**:纯粹的人情悲欢故事,触发情感是「思念 / 等待」而非武学领悟或心境突破。GDD §8.4 奇遇类型枚举中无「等待」「离别」锚点,强行匹配武学触发会污染 `encounter_type` 语义

### 2.2 gu_chuan_deng_ying(孤船灯影)

- **主题**:漂泊隐居——病恹恹的中年人二十年未离旧船,记录所有上船过客
- **不挂回理由**:调子偏「江湖见闻 / 隐士孤独」,无战斗或悟道契机。若强挂 `technique_insight`,缺乏练功/战斗/自然意象等触发前提(`trigger.biome` / `trigger.kill_count_threshold` 等字段无法合理填写)

### 2.3 huang_cun_yao_ren(荒村咬人)

- **主题**:邪门怪病——荒村怪病令人疯癫互咬,最后一个清醒老人独守废村
- **不挂回理由**:恐怖 / 邪异调子,与 GDD §1「写实武侠」基调相悖。「咬人」「怪病」语义无法对应任何武学 / 心境 / 心法类目,且 PROGRESS 已标注「邪门调子」与项目基调不符

### 2.4 qing_lou_can_meng(青楼残梦)

- **主题**:音律知音——青楼女子弹琵琶断弦,以「弦断有知音」为引子的短暂相遇
- **不挂回理由**:音律 / 知音主题,GDD §8.4 无「音律感悟」类奇遇锚点。`encounters.yaml` 现有 `type` 枚举为 `technique_insight / fortuitous_encounter / trial / karma`,均无法自然承载琴音意象。强挂会造成触发条件(`enemy_class` / `kill_count_threshold`)与文案完全脱节

### 2.5 lao_jing_hui_xiang(老井回响)

- **主题**:神秘探秘——枯井底有奇响,摸到断剑;井壁「记住」历史人声
- **不挂回理由**:虽有「断剑」元素,但叙事核心是「记忆 / 悬疑」而非武学领悟。断剑无 `unlock_technique_id` 对应物;若作 `fortuitous_encounter` 挂回,则物品奖励需在 `equipment.yaml` 中新建断剑条目,代价超过文案本身价值。主体调子偏「神秘志怪」,与武侠节奏不搭

### 2.6 yu_zhong_qiao_men(雨中敲门)

- **主题**:江湖过客册——老妇人记录历代躲雨江湖人名字门派目的地的旧簿子
- **不挂回理由**:「江湖故事」型叙事,无奖励 / 领悟 / 属性收益钩子。PROGRESS 已标注「江湖故事 / 无对应武学」。文案价值在于世界观渲染,但 `encounters.yaml` 架构要求奇遇必须有明确的 `outcome`(技能解锁 / 物品 / 属性加成),此文件无法提供有意义的机制产出

## 3. 决议

所有 6 件留 `data/events/_archive/`,**永久不挂回**。

后续 W18+ 若 GDD §8.4 新增以下类目,可重开评估:
- 「江湖见闻」型奇遇(纯世界观叙事,无机制产出)
- 「音律 / 艺道」心境类目
- 「志怪悬疑」副线(Demo 阶段明确不做,GDD §12)

在此之前不再扫描这 6 个文件。CI / 扫描脚本如有 `_archive/` 检查逻辑,可安全跳过此目录。

## 4. PROGRESS 销账建议

以下文字可直接替换 PROGRESS.md 中 `#37` 条目原文:

```
- ~~37. **6 events orphan 剩余可后续挂回**~~  
  2026-05-17 W17 长期挂账冲刺永封档收尾(Nightshift T01)。  
  6 件(duan_qiao_can_yue / gu_chuan_deng_ying / huang_cun_yao_ren / qing_lou_can_meng / lao_jing_hui_xiang / yu_zhong_qiao_men)主题分属「等待别离 / 漂泊隐居 / 邪门怪病 / 音律知音 / 悬疑探秘 / 江湖过客」,均无 GDD §8.4 武学 / 心境锚点对应。永留 `data/events/_archive/`,不再扫描不再评估。详见 `docs/handoff/wuxia_w17_orphan_events_permanent_archive_2026-05-17.md`。**#37 销账。**
```
