# W15 DeepSeek 派单 · 35 装备 lore 文案补写(销账 #35)

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows DeepSeek
> 创建日期:2026-05-15
> 关联挂账:PROGRESS.md §22 #35(GDD §6.6 Demo 50-80 段典故目标,当前 0 段)
> 上游 audit:`docs/handoff/deepseek_audit_w14_4_2026-05-15.md`(W14-4 暴露命名失联)

---

## 1. 一句话目标

为 `data/equipment.yaml` 全 35 件装备补 lore 典故文案,按 GDD §6.6 / WINDOWS_DEEPSEEK_GUIDE.md §6.3 规范,落地 `data/lore/<equipment_id>.yaml`,**Demo §6.6 典故量 0 → 35 段起步**(可冲 70+ 段上限)。

---

## 2. 背景与命名失联说明

### 2.1 为什么有这次派单

W14-4 audit 发现 `data/lore/` 主目录 45 段全 orphan:旧 id `sheng_xiu_jian` / `qing_feng_jian` 等 vs equipment.yaml 新 id `weapon_xunchang_tie_jian` / `weapon_haojiahuo_qing_feng_jian` **完全不通**,加载层 0 命中。当前已全部归档 `data/lore/_archive/`。

### 2.2 新命名约定(Mac 端已锁死,不动)

equipment.yaml 全 35 件用 `<slot>_<tier>_<拼音>` 命名:
- slot:`weapon` / `armor` / `accessory`
- tier:`xunChang`(寻常货) / `xiangYang`(像样货) / `haoJiaHuo`(好家伙) / `liQi`(利器) / `zhongQi`(重器) / `baoWu`(宝物) / `shenWu`(神物)
- 例:`weapon_haojiahuo_qing_feng_jian` = 第 3 阶武器 · 青锋剑

**你写的 lore 文件名必须 100% 对齐这套 id**,不要用旧命名。

### 2.3 旧 `_archive/` 45 段是宝藏可参考

虽然命名失联,但其中 2 段**装备中文名完全同名**,文案可直接迁用(改 id 即可):
- `_archive/qing_feng_jian.yaml`(青锋剑)→ 迁到 `lore/weapon_haojiahuo_qing_feng_jian.yaml`
- `_archive/jin_si_jia.yaml`(金丝甲)→ 迁到 `lore/armor_baowu_jin_si_jia.yaml`

另有近义题材可参考重写(粗铁剑 vs 铁剑 / 玄铁重剑 vs 玄铁甲 / 雪莲花 vs 血莲鞭),由你自行判断。`_archive/` 全 45 文件名见 §6.2。

---

## 3. 输入清单 · 35 件装备 metadata

> 字段说明:tier 阶位(中文)/ slot(武器或防具)/ school 流派偏向(刚猛/灵巧/阴柔)/ baseAttack 攻击范围 / baseHealth 血量范围 / baseSpeed 速度范围 / 师承 = 师承遗物(GDD §6.1 + §7.1)/ 段数 = 按 §4.2 规则
>
> 数值仅供你**判断稀有度气质**用,**禁止**写到文案里(GDD §5.6 红线)。

### 3.1 第 1 阶 · 寻常货(学徒境界开放,主线 ch1)· 各 1 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 |
|---|---|---|---|---|---|
| `weapon_xunchang_tie_jian` | 铁剑 | weapon | 灵巧 | 100-150 / 0 / 0-10 | 1 |
| `weapon_xunchang_zhe_dao` | 折刀 | weapon | 刚猛 | 100-150 / 0 / 0-10 | 1 |
| `weapon_xunchang_ruan_bian` | 软鞭 | weapon | 阴柔 | 100-150 / 0 / 0-10 | 1 |
| `armor_xunchang_bu_yi` | 粗布衣 | armor | — | 0 / 100-200 / 0-5 | 1 |
| `accessory_xunchang_yu_pei` | 玉佩 | accessory | — | 20-40 / 50-100 / 0-8 | 1 |

### 3.2 第 2 阶 · 像样货(三流境界开放,主线 ch2)· 各 1 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 |
|---|---|---|---|---|---|
| `weapon_xiangyang_gang_dao` | 钢刀 | weapon | 刚猛 | 180-280 / 0-50 / 5-20 | 1 |
| `weapon_xiangyang_chang_jian` | 长剑 | weapon | 灵巧 | 180-280 / 0-50 / 5-20 | 1 |
| `weapon_xiangyang_jiu_jie_bian` | 九节鞭 | weapon | 阴柔 | 180-280 / 0-50 / 5-20 | 1 |
| `armor_xiangyang_pi_jia` | 皮甲 | armor | — | 0 / 250-450 / 0-10 | 1 |
| `accessory_xiangyang_yin_jie` | 银戒 | accessory | — | 50-90 / 100-200 / 5-15 | 1 |

### 3.3 第 3 阶 · 好家伙(二流境界开放,主线 ch3 + tower_15)· 各 2 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 | 备注 |
|---|---|---|---|---|---|---|
| `weapon_haojiahuo_qing_feng_jian` | 青锋剑 | weapon | 灵巧 | 320-450 / 0-100 / 10-30 | 2 | **可迁用 `_archive/qing_feng_jian.yaml`** |
| `weapon_haojiahuo_xuan_hua_fu` | 玄花斧 | weapon | 刚猛 | 320-450 / 0-100 / 10-30 | 2 | — |
| `weapon_haojiahuo_chan_si_suo` | 缠丝索 | weapon | 阴柔 | 320-450 / 0-100 / 10-30 | 2 | — |
| `armor_haojiahuo_jin_pao` | 锦袍 | armor | — | 0 / 450-750 / 5-15 | 2 | **师承遗物**(祖师传家护甲),写传承味 |
| `accessory_haojiahuo_yu_pei_lao` | 古玉佩 | accessory | — | 100-160 / 200-350 / 10-25 | 2 | — |

### 3.4 第 4 阶 · 利器(一流境界 / Demo 主线最高级,tower_25 + yiLiu_quest)· 各 2 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 | 备注 |
|---|---|---|---|---|---|---|
| `weapon_liqi_long_quan` | 龙泉剑 | weapon | 灵巧 | 480-650 / 0-150 / 20-45 | 2 | **师承遗物**(祖师传家武器),写传承味 |
| `weapon_liqi_pan_long_dao` | 盘龙刀 | weapon | 刚猛 | 480-650 / 0-150 / 20-45 | 2 | — |
| `weapon_liqi_lian_zi_bian` | 链子鞭 | weapon | 阴柔 | 480-650 / 0-150 / 20-45 | 2 | — |
| `armor_liqi_xuan_tie_jia` | 玄铁甲 | armor | — | 0 / 700-1100 / 10-25 | 2 | _archive/xuan_tie_zhong_jian 是玄铁重剑,题材近义可参考"玄铁"气质 |
| `accessory_liqi_fei_yu_pei` | 翡玉佩 | accessory | — | 180-280 / 350-550 / 20-35 | 2 | — |

### 3.5 第 5 阶 · 重器(绝顶境界 / tower_30 + jueDing_unlock)· 各 3 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 |
|---|---|---|---|---|---|
| `weapon_zhongqi_po_zhen_chui` | 破阵锤 | weapon | 刚猛 | 700-950 / 50-250 / 30-60 | 3 |
| `weapon_zhongqi_qing_xu_jian` | 青虚剑 | weapon | 灵巧 | 700-950 / 50-250 / 30-60 | 3 |
| `weapon_zhongqi_du_long_suo` | 毒龙索 | weapon | 阴柔 | 700-950 / 50-250 / 30-60 | 3 |
| `armor_zhongqi_yin_lin_jia` | 银鳞甲 | armor | — | 0 / 1100-1600 / 15-35 | 3 |
| `accessory_zhongqi_qing_yu_huan` | 青玉环 | accessory | — | 280-420 / 550-850 / 30-50 | 3 |

### 3.6 第 6 阶 · 宝物(宗师境界 / zongShi_unlock)· 各 3 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 | 备注 |
|---|---|---|---|---|---|---|
| `weapon_baowu_xuan_tian_fu` | 玄天斧 | weapon | 刚猛 | 1000-1400 / 100-400 / 45-75 | 3 | — |
| `weapon_baowu_chang_hong_jian` | 长虹剑 | weapon | 灵巧 | 1000-1400 / 100-400 / 45-75 | 3 | — |
| `weapon_baowu_xue_lian_bian` | 血莲鞭 | weapon | 阴柔 | 1000-1400 / 100-400 / 45-75 | 3 | — |
| `armor_baowu_jin_si_jia` | 金丝甲 | armor | — | 0 / 1600-2300 / 25-50 | 3 | **可迁用 `_archive/jin_si_jia.yaml`** |
| `accessory_baowu_yu_long_pei` | 玉龙佩 | accessory | — | 420-600 / 850-1300 / 45-70 | 3 | — |

### 3.7 第 7 阶 · 神物(武圣境界 / wuSheng_unlock,Demo 顶阶占位)· 各 3 段

| id | 中文名 | slot | school | 攻 / 血 / 速 | 段数 |
|---|---|---|---|---|---|
| `weapon_shenwu_po_jun_dao` | 破军刀 | weapon | 刚猛 | 1500-2000 / 200-500 / 65-100 | 3 |
| `weapon_shenwu_tian_wen_jian` | 天问剑 | weapon | 灵巧 | 1500-2000 / 200-500 / 65-100 | 3 |
| `weapon_shenwu_huan_meng_bian` | 幻梦鞭 | weapon | 阴柔 | 1500-2000 / 200-500 / 65-100 | 3 |
| `armor_shenwu_xuan_huang_pao` | 玄黄袍 | armor | — | 0 / 2300-3000 / 40-70 | 3 |
| `accessory_shenwu_kun_lun_pei` | 昆仑佩 | accessory | — | 600-850 / 1300-1800 / 65-95 | 3 |

---

## 4. 输出规范

### 4.1 文件路径

每件装备一个 yaml,路径:`data/lore/<equipment_id>.yaml`(不进子目录,不进 `_archive/`)。

### 4.2 段数规则(对齐 WINDOWS_DEEPSEEK_GUIDE.md §6.3)

| 阶位 | 段数 | 单段字数 |
|---|---|---|
| 寻常货 / 像样货 | 1 段 | 60-150 字 |
| 好家伙 / 利器 | 2 段 | 60-150 字 |
| 重器 / 宝物 / 神物 | 3 段 | 60-150 字 |

**总计目标**:5×1 + 5×1 + 5×2 + 5×2 + 5×3 + 5×3 + 5×3 = **65 段**(超过 Demo §6.6 下限 50 段,落 §6.6 上限 80 内)。

### 4.3 yaml 结构(完全对齐既有 `_archive/qing_feng_jian.yaml` 体例)

```yaml
id: weapon_haojiahuo_qing_feng_jian      # 必须与 equipment.yaml 完全一致
name: 青锋剑                              # 必须与 equipment.yaml 完全一致
default_lore:
  - text: |
      <第 1 段,60-150 字>
  - text: |
      <第 2 段,可选>
  - text: |
      <第 3 段,可选>
```

### 4.4 字段红线

- `id` / `name` 必须与 `data/equipment.yaml` 字面**完全一致**(加载层会强校验,失联抛错)
- `default_lore` 列表项数严格按 §4.2 段数规则,**不要超 3 段**
- **禁止**在 yaml 里加 schema 没列的字段(如 `damage` / `rarity` / `tier`),那些是 equipment.yaml 的数值字段

### 4.5 风格红线(沿用 WINDOWS_DEEPSEEK_GUIDE.md §4-§5)

✅ 金庸气质 / 写实武侠 / 长短句交错 / 物候实 / 器物实 / 行话实 / 地理实
❌ 不写数值(不要"加血 +100""攻击 +500")
❌ 不写网游词("传说""史诗""稀有")—— 用"难得一见""百年遗珍""昔年宫造"等替代
❌ 不写当前主人(玩家),只写**前任 / 制器人 / 流转传闻**
❌ 不写"你"(装备 lore 是博物式陈述,不带玩家视角)
❌ 不写本项目的系统术语外壳(不要写"二流境界""寻常货阶""共鸣度",改用"小有名气""寻常铁器""与人渐熟")

---

## 5. 师承遗物 2 件特殊处理

**`armor_haojiahuo_jin_pao`(锦袍)** + **`weapon_liqi_long_quan`(龙泉剑)** 是 GDD §6.1 + §7.1 师承遗物(`isLineageHeritage: true`)。文案需含"前任=祖师"的传承气质。

参考既有 `data/lore/_templates/master_legacy.yaml`:

```yaml
{season}，此物由{master_name}亲手交予{disciple_name}。
交予之际，师父只说一言。一言之后，此物便不再属于他了。
此后经年，握住它的人总觉得柄上还有前人的余温。
```

**要求**:
- 锦袍:第 1 段写来历(谁所赠 / 何时锻造),第 2 段写传承(交予徒儿那一刻 / 或交予仪轨)
- 龙泉剑:第 1 段写铸剑(铸者 / 出炉时令 / 名字由来),第 2 段写传承(配剑者一代代的更迭 / 或剑鞘已不是原配的细节)

师承遗物**禁忌**:不要写"传承 buff +5%"或具体数值(GDD §5.3 已锁,数值层 Mac 端管)。

---

## 6. 参考素材索引

### 6.1 完全同名可直接迁用(2 件)

```
data/lore/_archive/qing_feng_jian.yaml   → 改 id 为 weapon_haojiahuo_qing_feng_jian
data/lore/_archive/jin_si_jia.yaml       → 改 id 为 armor_baowu_jin_si_jia
```

**迁用步骤**:复制旧文件 → 新文件名 → 仅改 `id:` 行,`name:` 保持中文一致 → `default_lore:` 段数若超新规则上限,**砍最弱一段**;若不足,**补齐**。

### 6.2 `_archive/` 全 45 段名单(供近义参考)

可参考的旧 lore(题材近义,DeepSeek 自由判断是否借用某段叙事 / 物候 / 物候细节):

```
cang_ming_gu_jian (沧溟古剑)        - 重剑题材
chen_tie_mian_ju (沉铁面具)         - 防具题材
chi_huo_lian (赤火链)               - 鞭索阴柔
cu_tie_jian (粗铁剑)                - 寻常铁剑
duan_shui (断水剑)                  - 高阶剑
gui_tou_dao (鬼头刀)                - 刚猛刀
han_jiu_dai (寒酒袋)                - 配饰
han_shuang_jian (寒霜剑)            - 中阶剑
han_ya_suo (寒鸦索)                 - 阴柔索
hu_po_jian (琥珀剑)                 - 剑
jin_chan_jia (金蚕甲)               - 护甲
jin_que_shan (金阙扇)               - 配饰/武器
jin_si_jia (金丝甲) ★               - 完全同名,直接迁
jing_hong_gong (惊鸿弓)             - 远程(本项目不开远程,可参考"惊鸿"意象)
jingang_zhuo (金刚镯)               - 配饰
liu_ye_dao (柳叶刀)                 - 灵巧刀
ma_an_xue (马鞍鞋)                  - 配饰
mo_dao (墨刀)                       - 刚猛刀
niu_jin_gong (牛筋弓)               - 同惊鸿弓注
nu_ma_qiang (驽马枪)                - 枪(本项目无,可参考器物气质)
pan_long_zhang (盘龙杖)             - 杖,可参考用于盘龙刀
pi_li_wan (霹雳丸)                  - 暗器(本项目无)
po_feng_quan_tao (破风拳套)         - 拳套(可参考刚猛气质)
qing_feng_jian (青锋剑) ★           - 完全同名,直接迁
qing_guang_ling (青光铃)            - 配饰
ri_yue_shuang_ren (日月双刃)        - 双刀
sha_ying (沙鹰索)                   - 阴柔索
she_gu_chang_bian (蛇骨长鞭)        - 阴柔鞭
sheng_xiu_jian (生锈剑)             - 入门剑
shi_mian_jian (十面剑)              - 高阶剑
shu_pi_dun (树皮盾)                 - 盾(本项目无,参考粗糙护具气质)
tian_chan_shou_tao (天蚕手套)       - 拳套
tian_que (天阙)                     - 神物级题材
tie_gu_shan (铁骨扇)                - 配饰
wu_gou (吴钩)                       - 刀
xing_chen_jian (星辰剑)             - 神物级剑题材
xuan_tie_zhong_jian (玄铁重剑)      - 玄铁气质,可参考玄铁甲
xue_chi_jian (雪池剑)               - 高阶剑
xue_lian_hua (雪莲花)               - 阴柔素材,可参考血莲鞭
xue_po_bi_shou (血魄匕首)           - 暗器(本项目无)
yan_ling_dao (雁翎刀)               - 灵巧刀
yue_ya_chan (月牙铲)                - 重武器,可参考玄天斧
yun_ji_guang (云霁光)               - 配饰
zhu_gan_qiang (竹竿枪)              - 同驽马枪注
zhui_feng_yue (追风月)              - 速度配饰
```

★ = 完全同名,直接迁用

---

## 7. 抽样验收标准(commit 前自查)

每件装备 lore 写完抽 3 件读一遍,自查:

1. **字数纪律**:每段是否在 60-150 字内?超 20% 必砍
2. **段数对齐**:阶位 → 段数(寻常/像样 1 / 好家伙/利器 2 / 重器/宝物/神物 3)
3. **id/name 一致**:与 equipment.yaml 字面完全一致
4. **风格统一**:同一阶位 5 件读下来"调子"是否一致?(寻常货应素朴,神物应有传奇感)
5. **无数值**:grep 看是否混入"+10""5%""3 成"等数字描述(描述性"三成""数尺"等武侠化数字 OK)
6. **无玩家视角**:是否出现"你"字?(装备 lore 禁用)
7. **师承 2 件特殊**:锦袍 / 龙泉剑是否写出师徒传承气质?

---

## 8. 交付与协作

### 8.1 commit 规范

分两批 commit:

**第一批 · 寻常货 5 件**(抽审用):
```
content(W15 #35 batch1): 寻常货 5 件 lore 落地
```
首 5 件落完先 push,通知 Mac 端抽审 1-2 件,确认风格 / 字数 / id 对齐无误后再开后续 30 件。

**第二批 · 像样货~神物 30 件**(批量):
```
content(W15 #35 batch2): 像样货~神物 30 件 lore 补齐(累计 65 段)
```
30 件一次性 commit,不要再细拆(同批文案同审稿更稳)。

### 8.2 推送顺序提醒

- Mac 端这一波还会动 `lib/` 下 SkillDef schema(W15 B #36 任务,与 lore 0 冲突)
- 你 push 前先 `git pull --rebase --autostash`,大概率无冲突(文件领地完全隔离)

### 8.3 Mac 端校验入口(你写完通知,Mac 跑)

- `flutter test test/data/lore_yaml_test.dart`(若存在,看 id 是否齐全)—— 暂未创建,Mac 端**可能本波加**
- `dart analyze` 不验 yaml,纯 schema 用 Mac 端 grep 校验
- 如果加载层报"lore id orphan",Mac 端自查 equipment.yaml id 是否漂移,**不是你的问题**

### 8.4 卡住怎么办

- 某件装备命名古怪不知道怎么写(如"幻梦鞭""玄黄袍"):放占位 `TODO: 待补` 先 commit,标 `[draft]`,Mac 端会回看讨论
- 字数压不下来:砍内容,不放宽字数
- 不确定师承气质怎么写:看 `_templates/master_legacy.yaml`,模仿那个调子

---

## 9. 收尾后挂账消解

派单完成后(35 yaml + commit + push),PROGRESS.md 挂账 #35 由 Mac 端销账。这也是 GDD §6.6 Demo 50-80 段目标的第一次硬性达标(0 → 65)。

---

**派单结束。开工时间预估 4-8 小时(35 件 × 平均 10 min,师承 2 件加长)。请按 §3 阶位顺序铺,先寻常货 5 件起步,头 5 件 commit 一次给 Mac 端抽审,审过再批量推。**
