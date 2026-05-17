# DeepSeek 派单 · W18-A3 lore +5 段达 GDD §7 上限(2026-05-17)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Windows DeepSeek
> 沟通契约:DeepSeek 全程不联系派单方,文案 commit + push 后 Mac 端拉自审
> 预计耗时:20-30min

---

## 0. 必读清单

1. **本派单**
2. `WINDOWS_DEEPSEEK_GUIDE.md`(内容生产规范,DeepSeek 主指引)
3. `GDD.md` §6.6 典故系统(每件装备 1-3 段预设典故,Demo 50-80 段)+ §7 内容总量表(典故 50-80 段)
4. **3 段体例参考**(已落地的 3 段范例,沿格式 + 字数 + 文学气质):
   - `data/lore/weapon_shenwu_tian_wen_jian.yaml`(神物·天问剑,书生铸剑 → 剑客来访 → 第十八问)
   - `data/lore/weapon_baowu_chang_hong_jian.yaml`(宝物·长虹剑,洞庭画虹 → 雾散虹现 → 岳阳楼女子)
   - `data/lore/armor_zhongqi_yin_lin_jia.yaml`(重器·银鳞甲,苏州银匠 → 妻亡留甲 → 贼字条)

---

## 1. 任务一句话

**给 5 件寻常货装备各补 1 段 anecdote(append 到 `default_lore[]`),共 +5 段,把 lore 总段数从 75 推到 80(GDD §7 上限)**。

**Why**:当前 lore 段数等差递增(寻常 5×1 / 像样 5×1 / 好家伙 5×2 / 利器 5×2 / 重器 5×3 / 宝物 5×3 / 神物 5×3 = 75 段),寻常货 1 段最薄。**Demo 早期玩家最先接触寻常货装备,典故文案最薄反而出戏感弱**,补到 2 段刚好达 GDD §7 上限 + 补低阶厚度。

---

## 2. 5 件 id 清单 + 当前状态

| # | id | name | 当前段数 | 目标段数 | 第 1 段已有主题(避免重复) |
|---|---|---|---|---|---|
| 1 | `weapon_xunchang_tie_jian` | 铁剑 | 1 | 2 | 洛阳老周记铁铺三代人,"够用,不贵,不折"招牌 |
| 2 | `weapon_xunchang_zhe_dao` | 折刀 | 1 | 2 | 河西马帮通用,老马帮的话"好刀不在长在手边" |
| 3 | `weapon_xunchang_ruan_bian` | 软鞭 | 1 | 2 | 牛皮三股并一,洞庭渔家女抽蝇子 |
| 4 | `armor_xunchang_bu_yi` | 粗布衣 | 1 | 2 | 靛青粗麻,练武场弟子衣,师父说"衣破可补功破不补" |
| 5 | `accessory_xunchang_yu_pei` | 玉佩 | 1 | 2 | 寻常青玉平安扣,妻系/师赠的念想 |

---

## 3. 文学体例硬约束(沿 3 段范例)

### 3.1 三段式叙事节奏(已落地的 3 段范例都符合)

| 段 | 角色 | 内容方向 |
|---|---|---|
| 第 1 段(已有) | 出处/铸造 | 物件本身的来历、材质、地点、人物初识 |
| **第 2 段(本批新加)** | **流传/插曲** | **一个小故事 / 一个人物的瞬间 / 一句话或一个动作的沉淀** |
| 第 3 段(后续不在本批) | 转折/沉淀 | 多年后的回响、物件易主、空椅子或空酒壶的余韵 |

**本批 5 件每件只补第 2 段**——不要写第 3 段(留给未来扩展),也不要重写第 1 段。

### 3.2 字数与排版

- **每段 5-7 行**(与现有体例齐,不要明显短/长)
- 一段一个故事单元,不分小标题
- 用 yaml block scalar `text: |` + 缩进 6 空格(完全沿现有 yaml 格式)

### 3.3 文学气质硬约束(沿 3 段范例)

- **古风、克制、不堆华丽词藻**(参 tian_wen_jian 第 2 段"剑前站了一个时辰"、yin_lin_jia 第 2 段"做完那年他妻子去世了"——一句话带过的留白)
- **写人不写物**:第 2 段重点写"用这件物的人"或"见过这件物的人",物件本身退到背景
- **寻常货 = 寻常人**:不要写传奇人物或江湖大派,写市井、走镖、家人、徒弟、铁匠、邮差这类层次
- **可重复地点延续第 1 段**:如 tie_jian 第 1 段写洛阳,第 2 段可继续写洛阳但人物换;但**不强求**,换地点也行

### 3.4 红线(违规会被退回重写)

- ❌ **不写数值**(攻击 +N、血量 +N、暴击 +N% 等)
- ❌ **不写招式名**(招式名在 `data/lore/` 之外的层管理)
- ❌ **不写 UI 名词**(背包/装备/装备槽/强化等系统词汇)
- ❌ **不写网游词汇**(legendary / epic / 史诗 / 神话级 等,本项目 7 阶用境界词,见 GDD §5.2)
- ❌ **不引入境界级别比寻常货更高的物件人物**(寻常货段不要写宗师 / 武圣 / 神物级别人物登场)
- ❌ **不写大场面战斗**(刀光剑影、千军万马等)——寻常货段调子是"日常 / 凡人 / 微小"

---

## 4. 文件操作 schema

### 4.1 操作位置

5 个文件,**每个 append 1 段 text 到 `default_lore[]` 末尾**:

```
data/lore/weapon_xunchang_tie_jian.yaml
data/lore/weapon_xunchang_zhe_dao.yaml
data/lore/weapon_xunchang_ruan_bian.yaml
data/lore/armor_xunchang_bu_yi.yaml
data/lore/accessory_xunchang_yu_pei.yaml
```

### 4.2 改前/改后 schema 范例(`weapon_xunchang_tie_jian.yaml`)

改前(1 段):
```yaml
id: weapon_xunchang_tie_jian
name: 铁剑
default_lore:
  - text: |
      寻常铁铺里打出来的剑,铁是生铁,淬过一遍水,剑脊上留着锤印没磨平。
      ...(原 3 行)
```

改后(2 段):
```yaml
id: weapon_xunchang_tie_jian
name: 铁剑
default_lore:
  - text: |
      寻常铁铺里打出来的剑,铁是生铁,淬过一遍水,剑脊上留着锤印没磨平。
      ...(原 3 行,完全不改)

  - text: |
      <新加的第 2 段 5-7 行>
```

**严格规则**:
- 段与段之间**空一行**(沿 3 段范例 yaml 体例)
- 缩进:`- text: |` 用 2 空格,内容用 6 空格
- 不动 `id` / `name` / 第 1 段任何字符
- yaml 末尾保留一个换行符(POSIX 文件惯例)

---

## 5. 入场检查(必跑)

DeepSeek 端 pull 后开工前:

```powershell
cd <项目路径>
git pull --rebase --autostash
git log --oneline -5  # 应看到最近 commit 含 1207f49 销账 W18 起步段
# 应看到工作树干净,如有未提交改动停下来贴 git status
```

期望 HEAD ≈ `1207f49` 或更新(若 Mac 端有新 commit pull 进来即可)。

---

## 6. 收尾

### 6.1 自审清单(写完 5 段后跑一遍)

- [ ] 5 个 yaml 都改完,每个 `default_lore[]` 段数从 1→2
- [ ] grep 总段数:`grep -h "^  - text:" data/lore/*.yaml | wc -l` 应等于 **80**
- [ ] yaml 格式校验(可用 Python `yaml.safe_load` 跑一下,或本机有 `yq` 工具)
- [ ] 第 2 段字数 5-7 行(逐文件目测)
- [ ] 文学气质沿 3 段范例(不堆词藻 / 不写网游词 / 不写数值)

### 6.2 提交 commit

```
content(w18-a3): 寻常货 5 件各补 1 段 anecdote(lore 75→80 达 GDD §7 上限)
```

push 到 main。

### 6.3 closeout 报告

写 `docs/handoff/deepseek_w18_a3_lore_closeout_2026-05-17.md`,**≤ 80 行**,包含:

1. 5 件每件第 2 段标题/主题一句话总结(便于派单方快速验)
2. 文学气质自评(克制度 / 留白 / 寻常人调子)
3. 入场检查 git log 实际看到的 commit 列表
4. 自审清单逐项 ✅
5. **任一意外**(yaml 格式异常 / 字数没控住 / 主题撞车 / 想法分叉) → 明示

### 6.4 不动清单

- ❌ `lib/` 任何 Dart 代码
- ❌ `data/` 顶层 yaml(equipment.yaml / numbers.yaml / encounters.yaml / synergies.yaml / techniques.yaml 等)
- ❌ `data/lore/` 其他 30 个非本批 yaml
- ❌ `data/lore/_archive/` / `data/lore/_templates/`
- ❌ `data/narratives/` `data/events/`(本批不涉及)
- ❌ `GDD.md` / `CLAUDE.md` / `WINDOWS_DEEPSEEK_GUIDE.md` / `IDS_REGISTRY.md` / `PROGRESS.md`

---

## 7. 派单方 self-check(已做)

- [x] **数字 grep 实测**:`grep -h "^  - text:" data/lore/*.yaml | wc -l` = 75(memory `feedback_closeout_numbers_grep` 教训实战)
- [x] **schema 0 改**:`lib/data/lore_loader.dart:61` 已支持 `default_lore[]` N 段 list,DeepSeek 写完直接生效
- [x] **5 件 id 验证存在**:5 个 yaml 文件已在 `data/lore/` 下,默认走 EquipmentLoreDef pipeline
- [x] **GDD §6.6 / §7 锚定**:目标 80 段(§7 上限,§6.6 行 381 写 50-100 容许更高,80 是双重确认值)
- [x] **3 段范例齐**:tian_wen_jian / chang_hong_jian / yin_lin_jia 都已落地,DeepSeek 端可直接打开看

---

**端起来开工**。
