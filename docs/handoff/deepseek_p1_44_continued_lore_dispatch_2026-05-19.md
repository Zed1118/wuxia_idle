# DeepSeek 派单 · P1 #44 延续典故 yaml 池补齐(2026-05-19)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Windows DeepSeek
> 沟通契约:DeepSeek 全程不联系派单方,文案 commit + push 后 Mac 端拉自审
> 预计耗时:3-5h(35 件 × 2 池 × 3-5 条 ≈ 210-350 条文案,按 60-90 条/h 计含校稿),**可分批提交**

---

## 0. 必读清单

1. **本派单**
2. `docs/handoff/p1_44_deepseek_continued_lore_spec.md`(Mac 端起手 spec,本派单是它的执行版)
3. `WINDOWS_DEEPSEEK_GUIDE.md`(内容生产规范,DeepSeek 主指引)
4. `GDD.md` §6.6 典故系统(每件装备 1-3 段预设典故 + 延续典故体系) + §10.2 江湖见闻录百科
5. **体例参考**(已落地的优秀范例,沿气质 / 字数 / 留白):
   - `data/lore/weapon_shenwu_tian_wen_jian.yaml`(神物·天问剑,书生铸剑 → 剑客来访 → 第十八问)
   - `data/lore/weapon_xunchang_tie_jian.yaml`(寻常货·铁剑,洛阳老周记 → 雪夜少年取剑)
   - `data/lore/accessory_xunchang_yu_pei.yaml`(寻常货·玉佩,妻系平安扣 → 三月归乡)

---

## 1. 任务一句话

**给 `data/lore/` 下 35 件装备 yaml 每个加 2 个延续典故池(`continued_lore_obtained` / `continued_lore_boss_defeated`),每池 3-5 条文案,共 ≥210 / ≤350 条**。

**Why**:
- P1 #44 Mac 端 wire 已就位(LoreContent schema + GameEventService 抽样 + 占位符替换 + fallback)
- 当前 Mac 端走 Dart 模板 fallback(网游味重),DeepSeek 池一就位即切到正式文案
- GDD §6.6:装备典故个性化是本作差异化卖点,「玩家见证装备打过哪场战 / 在哪一刻获得」要写进物件

---

## 2. 35 件 id 清单(按 tier 分组,全部位于 `data/lore/` 根目录)

> 不含 `_archive/` 和 `_templates/`。

### 寻常货(xunchang)· 5 件

- `weapon_xunchang_ruan_bian.yaml`(软鞭)
- `weapon_xunchang_tie_jian.yaml`(铁剑)
- `weapon_xunchang_zhe_dao.yaml`(折刀)
- `armor_xunchang_bu_yi.yaml`(粗布衣)
- `accessory_xunchang_yu_pei.yaml`(玉佩)

### 像样货(xiangyang)· 5 件

- `weapon_xiangyang_chang_jian.yaml`
- `weapon_xiangyang_gang_dao.yaml`
- `weapon_xiangyang_jiu_jie_bian.yaml`
- `armor_xiangyang_pi_jia.yaml`
- `accessory_xiangyang_yin_jie.yaml`

### 好家伙(haojiahuo)· 5 件

- `weapon_haojiahuo_chan_si_suo.yaml`
- `weapon_haojiahuo_qing_feng_jian.yaml`
- `weapon_haojiahuo_xuan_hua_fu.yaml`
- `armor_haojiahuo_jin_pao.yaml`
- `accessory_haojiahuo_yu_pei_lao.yaml`

### 利器(liqi)· 5 件

- `weapon_liqi_lian_zi_bian.yaml`
- `weapon_liqi_long_quan.yaml`
- `weapon_liqi_pan_long_dao.yaml`
- `armor_liqi_xuan_tie_jia.yaml`
- `accessory_liqi_fei_yu_pei.yaml`

### 重器(zhongqi)· 5 件

- `weapon_zhongqi_du_long_suo.yaml`
- `weapon_zhongqi_po_zhen_chui.yaml`
- `weapon_zhongqi_qing_xu_jian.yaml`
- `armor_zhongqi_yin_lin_jia.yaml`
- `accessory_zhongqi_qing_yu_huan.yaml`

### 宝物(baowu)· 5 件

- `weapon_baowu_chang_hong_jian.yaml`
- `weapon_baowu_xuan_tian_fu.yaml`
- `weapon_baowu_xue_lian_bian.yaml`
- `armor_baowu_jin_si_jia.yaml`
- `accessory_baowu_yu_long_pei.yaml`

### 神物(shenwu)· 5 件

- `weapon_shenwu_huan_meng_bian.yaml`
- `weapon_shenwu_po_jun_dao.yaml`
- `weapon_shenwu_tian_wen_jian.yaml`
- `armor_shenwu_xuan_huang_pao.yaml`
- `accessory_shenwu_kun_lun_pei.yaml`

---

## 3. yaml schema(扩既有字段,与 default_lore 共存)

### 3.1 改前(35 件当前都长这样)

```yaml
id: weapon_xunchang_tie_jian
name: 铁剑
default_lore:
  - text: |
      (既有 preset 段,不动)
```

### 3.2 改后(append 2 池,与 default_lore 同级)

```yaml
id: weapon_xunchang_tie_jian
name: 铁剑
default_lore:
  - text: |
      (既有 preset 段,完全不动)

# ── P1 #44 新增 ──
continued_lore_obtained:        # 首次获得触发池,3-5 条
  - text: |
      于「{source}」初见此铁剑,剑身粗糙,刃口未开。
      握在掌中沉甸,像一截还未开声的钝铁。
  - text: |
      初遇于{source}。是把寻常的铁剑,
      但用过的人都知道——寻常之物,反而经得住磨。
  # ... 3-5 条
continued_lore_boss_defeated:   # 击败 Boss 见证池,3-5 条
  - text: |
      于「{stage_name}」一战,此剑斩 {boss_name}。
      剑身上多了一道豁口,豁口的形状像 {boss_name} 最后一招的轨迹。
  - text: |
      {stage_name}一战,此剑虽寻常,
      但你将 {boss_name} 的来路看清了,剑就稳得住。这一次它没有崩。
  # ... 3-5 条
```

### 3.3 严格规则

- **字段名锁死**:`continued_lore_obtained` / `continued_lore_boss_defeated`,改名 Mac 端 wire break
- **不动 `default_lore`**:preset 池 W15 #35 / W18-A3 已交付定稿,本批一字不改
- **不动 `id` / `name`**:本批不涉及
- 池条目之间不必空行(可空可不空,沿 default_lore 既有体例)
- 缩进:`- text: |` 用 2 空格,内容用 6 空格(同 default_lore)
- yaml 末尾保留一个换行符(POSIX 文件惯例)

---

## 4. 占位符约定(硬纪律)

### 4.1 仅支持 3 个变量

| 变量 | 触发池 | 含义 | 样例 |
|---|---|---|---|
| `{source}` | `continued_lore_obtained` | 装备来源(关卡名 / 爬塔层名) | 「夜袭山贼营」/「试炼塔 5 层」 |
| `{boss_name}` | `continued_lore_boss_defeated` | Boss 名 | 「黑面阎罗」/「无影刀客」 |
| `{stage_name}` | `continued_lore_boss_defeated` | 关卡名(主线 stage / 塔层) | 「夜袭山贼营」/「试炼塔 10 层」 |

### 4.2 红线

- ❌ **不识别其他模板语法**:`{{var}}` / `<var>` / `${var}` 都不替换,会原样保留出毛刺
- ❌ **不写未约定的占位符**:`{equip_name}` / `{boss_realm}` / `{weather}` / `{date}` 等会原样保留出 bug;若需提到装备形态直接写「此剑」/「此鞭」(yaml 按装备拆池,即知形态)
- ❌ **不硬编码具体关卡 / Boss 名**:用占位符,让 Mac 端从战斗上下文注入
- ✅ **池内不强制每条都用占位符**:可有的条用变量、有的条纯静态文案(留白)
- ✅ **占位符可零次、一次或多次出现**:由文案需要决定

### 4.3 池-占位符匹配表(防错池)

- `continued_lore_obtained` 池 → **只**用 `{source}`(不要用 `{boss_name}` / `{stage_name}` — 获得装备时无 Boss 上下文)
- `continued_lore_boss_defeated` 池 → 用 `{boss_name}` / `{stage_name}`(不要用 `{source}` — 这里 source 概念已被 stage_name 替代)

**违规示例(会被 Mac 端红线 case 拦下退回重写)**:

```yaml
continued_lore_obtained:
  - text: 斩 {boss_name} 于 {stage_name}, 此剑沾血。  # ❌ obtained 池不许用 boss_name/stage_name
```

---

## 5. 文学体例硬约束(沿 default_lore 优秀范例)

### 5.1 字数与排版

- **每条 1-3 行**(延续典故是「短叙述+情绪点」,与 default_lore 5-7 行的「完整故事」不同)
- **每条 ≤ 300 字**(Mac 端有 soft warning 长度审计 ≤300)
- 一条一个画面 / 一个动作 / 一句话,**不写完整故事**(完整故事归 default_lore)
- 用 yaml block scalar `text: |` + 缩进 6 空格

### 5.2 文学气质硬约束

- **古风、克制、不堆华丽词藻**(参 tian_wen_jian「剑前站了一个时辰」、yu_pei「玉上还有他的体温」)
- **写感受不写战况**:不要写「血溅三尺」「刀光剑影」「千军万马」,要写「鞭身崭新一痕」「剑就稳得住」「沾血」「沉了几分」
- **延续典故的功能定位**:玩家在游戏中反复抽到 → 累积成「这件装备陪我经历过什么」的情感锚点。**不重复 default_lore 的来历叙事**,重「使用者的瞬间感受」

### 5.3 Tier 风格梯度建议

| Tier | 风格基调 | 用词倾向 |
|---|---|---|
| 寻常货(xunchang) | 朴素白描 / 凡人调子 | 「沉甸」「钝铁」「未开声」「沾着泥」 |
| 像样货 / 好家伙(xiangyang/haojiahuo) | 有故事感 / 走江湖味 | 「磨亮了」「认人」「跟着走过几个州」 |
| 利器 / 重器(liqi/zhongqi) | 沾血味重 / 经历感 | 「饮血」「鸣」「沉了几分」「裂痕」 |
| 宝物 / 神物(baowu/shenwu) | 含传说色彩 / 历史感 | 「应天而鸣」「壁画里的影」「问字比铁重」(参 tian_wen_jian 调子) |

### 5.4 红线(违规会被退回重写)

- ❌ **不写数值**(攻击 +N / 暴击 +N% / 血量 +N 等)
- ❌ **不写招式名**(招式归 `data/lore/_archive` 之外的层管理)
- ❌ **不写 UI 名词**(背包 / 装备槽 / 强化 / 共鸣度 等系统词汇)
- ❌ **不写网游词汇**(legendary / epic / 史诗 / 神话级 / 极品 / 神器 / 传说之剑 等)
- ❌ **不写大场面战斗**(刀光剑影 / 千军万马 / 血流成河)— 延续典故是「使用者的微小瞬间」
- ❌ **不在寻常货 / 像样货段引入境界更高的物件人物**(寻常货段不要写宗师 / 武圣 / 神物级别人物登场)
- ❌ **不重复 default_lore 已写过的故事**(延续典故是补「使用过程的瞬间」,不是 default_lore 的续集)

---

## 6. 量级与分批

- **每池 3-5 条**:池太少(< 3)玩家反复刷塔抽到同条频繁观感重复,池太多(> 5)文案量超工作量预算
- **均值 ≈ 4 条/池**:35 件 × 2 池 × 4 条 ≈ 280 条
- **可分批提交**(不必一次 35 件),按 tier 自然分批方便管理:
  - 批 1:寻常货 5 件 + 像样货 5 件(10 件 ≈ 80 条,1-1.5h)
  - 批 2:好家伙 5 件 + 利器 5 件(10 件 ≈ 80 条,1-1.5h)
  - 批 3:重器 5 件 + 宝物 5 件(10 件 ≈ 80 条,1-1.5h)
  - 批 4:神物 5 件(5 件 ≈ 40 条,0.5-1h)
- Mac 端等**全部 35 件到位**再做二阶段验收(中间批次可先 push 不验收)

---

## 7. 文件操作 schema

### 7.1 操作位置

35 个文件,**每个 append 2 池(`continued_lore_obtained` + `continued_lore_boss_defeated`)到 yaml 末尾**:

```
data/lore/<id>.yaml × 35
```

### 7.2 改前/改后 schema 范例(`accessory_xunchang_yu_pei.yaml`)

改前:
```yaml
id: accessory_xunchang_yu_pei
name: 玉佩
default_lore:
  - text: |
      (既有 2 段,完全不动)
```

改后:
```yaml
id: accessory_xunchang_yu_pei
name: 玉佩
default_lore:
  - text: |
      (既有 2 段,完全不动)

continued_lore_obtained:
  - text: |
      初得此玉于「{source}」,
      绳子是新的,还没沾上人的体温。
  - text: |
      于{source}得这块平安扣。
      握在掌中冰凉,要捂一会儿才能暖过来。
  - text: |
      {source}一遭,这块玉算是落到了你手里。
      青玉里的絮纹像云,你看着看着觉得它在动。

continued_lore_boss_defeated:
  - text: |
      斩 {boss_name} 于 {stage_name},
      玉佩在腰间撞了一下,凉了一下又暖回来。
  - text: |
      {stage_name}一战。{boss_name} 倒下时,
      你低头看玉,绳结松了半分——是被你的呼吸撑松的。
  - text: |
      胜 {boss_name} 后回身,玉还在。
      你忽然想起出门那天,有人给你系上它时打的那个结。
```

(寻常货风格朴素 / 凡人感 / 不沾血。神物 / 宝物 tier 可以写得更有历史感 + 传说色彩。)

---

## 8. 入场检查(必跑)

DeepSeek 端 pull 后开工前:

```powershell
cd <项目路径>
git pull --rebase --autostash
git log --oneline -5  # 应看到最近 commit 含 cc19a03 / 3609851 / cb3429b(P1 #44 spec + 红线 case 实装)
git status            # 应工作树干净
```

期望 HEAD ≈ `cc19a03` 或更新(若 Mac 端有新 commit pull 进来即可)。

---

## 9. 收尾

### 9.1 每批自审清单(每提交一批前跑一遍)

- [ ] 该批每个 yaml 都加了 2 池(`continued_lore_obtained` + `continued_lore_boss_defeated`)
- [ ] 每池 3-5 条(目测计数)
- [ ] grep 验证 yaml 解析(可用 Python `yaml.safe_load` 跑一下,或本机有 `yq` 工具)
- [ ] 占位符只用 `{source}` / `{boss_name}` / `{stage_name}`,无其他变量
- [ ] obtained 池只用 `{source}`,boss_defeated 池只用 `{boss_name}` / `{stage_name}`(不串池)
- [ ] 每条 ≤ 300 字 / 1-3 行
- [ ] 文学气质沿 default_lore 既有范例(不堆词藻 / 不写网游词 / 不写数值)
- [ ] 不动 `default_lore` 任何字符

### 9.2 提交 commit(可分批)

每批 commit message 体例:

```
content(p1-44): 延续典故 yaml 池补齐 · <tier 名> 5 件 · <批 N/4>
```

例:`content(p1-44): 延续典故 yaml 池补齐 · 寻常货+像样货 10 件 · 批 1/4`

push 到 main。

### 9.3 全部 35 件完工后写 closeout 报告

写 `docs/handoff/deepseek_p1_44_continued_lore_closeout_2026-05-19.md`,**≤ 80 行**,包含:

1. 35 件每件 2 池条数清单表(便于派单方快速验,例:`weapon_xunchang_tie_jian: obtained=4 / boss_defeated=4`)
2. 总条数 grep 实测:`grep -h "^  - text:" data/lore/*.yaml | wc -l` 实际值(应从 80 涨到 ≈ 360)
3. 文学气质自评(克制度 / 留白 / Tier 风格梯度执行)
4. 入场检查 git log 实际看到的 commit 列表
5. 自审清单逐项 ✅
6. **任一意外**(yaml 格式异常 / 字数没控住 / 主题撞车 / 想法分叉) → 明示

### 9.4 不动清单

- ❌ `lib/` 任何 Dart 代码
- ❌ `data/` 顶层 yaml(equipment.yaml / numbers.yaml / encounters.yaml / synergies.yaml / techniques.yaml / stages.yaml / towers.yaml 等)
- ❌ `data/lore/_archive/` / `data/lore/_templates/`(归档 + 模板,本批不涉及)
- ❌ `data/lore/<id>.yaml` 的 `default_lore` 字段(preset 池定稿,本批一字不改)
- ❌ `data/narratives/` `data/events/`(本批不涉及)
- ❌ `GDD.md` / `CLAUDE.md` / `WINDOWS_DEEPSEEK_GUIDE.md` / `IDS_REGISTRY.md` / `PROGRESS.md`
- ❌ `test/` 任何测试文件

---

## 10. 派单方 self-check(已做)

- [x] **35 件 id grep 实测**:`ls data/lore/*.yaml | grep -v _archive | grep -v _templates | wc -l` = 35
- [x] **现状检查**:35 件中 `continued_lore_obtained` / `continued_lore_boss_defeated` 出现次数 = 0,无遗留池,DeepSeek 从零起手
- [x] **schema wire 落地**:`lib/data/lore_loader.dart` 加 2 池字段解析 +`lib/features/event/application/game_event_service.dart` 走 LoreLoader 抽样 + 占位符替换 + fallback,HEAD `cc19a03`
- [x] **占位符 wire 落地**:`{source}` / `{boss_name}` / `{stage_name}` 三变量 GameEventService 注入(`{equip_name}` 不传,yaml 直写形态)
- [x] **Mac 端红线 case 已就位**:`test/data/lore_loader_test.dart` 加 5 strict + 1 soft 红线(默认 skip),DeepSeek 全部到位后 `sed -i "/skip: 'P1 #44/d" test/data/lore_loader_test.dart` 一键去 skip 启用
- [x] **GDD §6.6 锚定**:装备典故个性化 + 「随用随生」语义已对齐
- [x] **体例范例齐**:tian_wen_jian(神物)/ tie_jian(寻常货)/ yu_pei(寻常货)default_lore 3 段已落,DeepSeek 端可直接打开看气质

---

**端起来开工**。预计 3-5h,可分 4 批提交。全部到位后 Mac 端跑红线 case + closeout 二阶段验收。
