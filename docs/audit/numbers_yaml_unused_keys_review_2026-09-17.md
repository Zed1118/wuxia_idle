# numbers.yaml 零引用 key 逐条复核（B2 · 2026-09-17）

基线：`c64b165938d948a24ab64c7c71de950eea466758`。输入联合 SHA-256：`5d33b4eb3473ae49278ce9e4bb5a6c38678033b781cd12fa1cc633547c869a60`；配置 SHA-256：`229dfd701b134b9165d6e65313584d2cd4f83afc3381eeee0d12bc6ce8c76297`。

## B2-1 基线与本次计数

```sh
python3 tools/audit/numbers_key_usage.py --baseline c64b165938d948a24ab64c7c71de950eea466758
python3 tools/audit/numbers_unused_keys_review.py --check --include-pool
```

标量叶子 **1796**；归一路径 **847**；末段名 **497**。
基线保护：exit_code `0` / tracked_paths_match `true` / passed `true`。

| 判定 | 本次标量叶子 |
|---|---:|
| 生产消费 | 234 |
| 仅测试消费 | 0 |
| 零引用 | 202 |
| 疑似间接消费需人判 | 1360 |

原表对照仅从原表逐条表重新提取 key 集合计数，未转抄原表头部数字；当前判定由扫描器重新实跑。

| 零引用口径 | 原表逐条重计 | 本次 | 新增 | 移出 |
|---|---:|---:|---:|---:|
| 标量叶子 | 202 | 202 | 0 | 0 |
| 归一路径 | 87 | 87 | 0 | 0 |
| 末段名 | 51 | 51 | 0 | 0 |

新增零引用清单：无。移出零引用清单：无。
未发现新守卫消费、lib 新引用或排除理由失效导致集合变化。缺值 fail-fast 仍只约束原先显式读取字段；没有把整个父 Map 的所有叶子纳入守卫。

## B2-2 建议汇总

| 建议 | 归一路径 | 标量叶子 |
|---|---:|---:|
| 删除候选 | 0 | 0 |
| 头注 UNUSED | 42 | 53 |
| 保留（有合同） | 22 | 106 |
| 待拍板 | 23 | 43 |

下表每格为“归一路径 / 标量叶子”；数组索引折叠为 []，null 与数组叶子的归一路径分别保留。

| 顶级段 | 删除候选 | 头注 UNUSED | 保留（有合同） | 待拍板 | 合计 |
|---|---:|---:|---:|---:|---:|
| meta | 0 / 0 | 1 / 1 | 0 / 0 | 0 / 0 | 1 / 1 |
| combat | 0 / 0 | 6 / 6 | 0 / 0 | 0 / 0 | 6 / 6 |
| equipment | 0 / 0 | 0 / 0 | 16 / 94 | 0 / 0 | 16 / 94 |
| techniques | 0 / 0 | 0 / 0 | 1 / 7 | 0 / 0 | 1 / 7 |
| skills | 0 / 0 | 8 / 16 | 0 / 0 | 0 / 0 | 8 / 16 |
| character | 0 / 0 | 2 / 2 | 5 / 5 | 2 / 2 | 9 / 9 |
| retreat | 0 / 0 | 2 / 5 | 0 / 0 | 0 / 0 | 2 / 5 |
| tower | 0 / 0 | 0 / 0 | 0 / 0 | 9 / 29 | 9 / 29 |
| inheritance | 0 / 0 | 3 / 3 | 0 / 0 | 2 / 2 | 5 / 5 |
| synergies | 0 / 0 | 0 / 0 | 0 / 0 | 10 / 10 | 10 / 10 |
| validation_examples | 0 / 0 | 20 / 20 | 0 / 0 | 0 / 0 | 20 / 20 |

### 命中口径与动态消费结论

所有命中数均为命令输出行数，含注释；不是出现次数、文件数或运行消费数。①列为 Dart/Python/Shell 末段匹配和路径片段匹配，逐条证据另给不限制扩展名的最低检索。③原始匹配包含 numbers.yaml 自身、历史记录和同名异义项；补充合同检索与原文片段用于区分规则、文档锚和冲突。不能把③任何一行命中都解释为有效合同。
②列给公共搜索 / 父级搜索的原始行数；当前目标路径的实际动态玩法消费未发现（0），证据见十四组 parser 片段。NumbersConfig.raw 只在里程碑授予取值，numbersRaw 另外只交给 realms；其他 raw 局部变量分属动作链与周目等类型，不属于本表候选。插值诊断字符串不当读取。
泛型消费需披露：deepConvertYaml 会递归转换整表；审计脚本会枚举叶子；测试有 loadTestNumbersSection 和 path.split('.')。这些是转换/审计/显式路径测试，当前路径列表不含本表字段，未发现把本表字段接入玩法或守卫的证据。不将泛型搬运等同生产数值消费。
历史首次 SHA 指当前 data/numbers.yaml 路径首次包含完整归一路径；初始化提交从旧位置迁入，不能声称设计首次发明。git log -S 不能排除同数替换或所有历史动态消费；只报告固定基线可达历史的实际检索结果。
审计脚本自身出现 key 会计入①，报告自身按要求排除于③，避免报告生成后污染复跑。新增的恢复点和收据不含候选末段，复跑不变。

公共动态命令：[Q001](#q001)=63；[Q002](#q002)=22；[Q003](#q003)=187；[Q004](#q004)=37。完整工厂：[Q005](#q005)=198。
泛型读取原文：`lib/data/yaml_loader.dart:8-19` [Q006](#q006)=12；`test/support/test_data.dart:1-18` [Q007](#q007)=18；`test/data/numbers_config_required_keys_test.dart:113-130` [Q008](#q008)=18；`tools/audit/q2_leaf_extract.py:22-70` [Q009](#q009)=49；`tools/audit/run_all.py:69-76` [Q010](#q010)=8。

## 逐条表（按 YAML 行号升序）

| 归一路径 | 叶子数 | 值（多叶给首→尾） | YAML 行 | ①末段 / 路径 | ②公共 / 父级 | ③原始 / 合同（文件:行） | ④提交数 / lib 数；首次加入 | 建议 | 理由 |
|---|---:|---|---|---|---|---|---|---|---|
| `meta.last_updated` | 1 | "2026-05-10" | 34 | [Q077](#q077)=3 / [Q079](#q079)=0 | [Q001](#q001)=63 / [Q017](#q017)=2 | [Q080](#q080)=4 / [Q085](#q085)=5；`data/numbers.yaml:31`; `data/numbers.yaml:32`; `data/numbers.yaml:34`; `data/numbers.yaml:106`; `data/numbers.yaml:1666` | [Q081](#q081)=2 / [Q082](#q082)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 存档时间戳，不是运行配置；已有纯文档说明。 |
| `combat.damage_formula.skill_multiplier_added` | 1 | true | 106 | [Q087](#q087)=4 / [Q089](#q089)=1 | [Q001](#q001)=63 / [Q021](#q021)=1 | [Q090](#q090)=2 / [Q094](#q094)=16；`GDD.md:268`; `GDD.md:316`; `GDD.md:319`; `GDD.md:341`; `GDD.md:344`; `GDD.md:814`; `data/numbers.yaml:23`; `data/numbers.yaml:24`; `data/numbers.yaml:31`; `data/numbers.yaml:100`; `data/numbers.yaml:101`; `data/numbers.yaml:102`; `data/numbers.yaml:106`; `data/numbers.yaml:108`; `data/numbers.yaml:109`; `data/numbers.yaml:1666` | [Q091](#q091)=1 / [Q092](#q092)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 公式结构文档；布尔字段不是运行时开关，保留说明锚。 |
| `combat.final_damage_formula.apply_cultivation_multiplier` | 1 | true | 113 | [Q097](#q097)=2 / [Q099](#q099)=0 | [Q001](#q001)=63 / [Q024](#q024)=106 | [Q100](#q100)=1 / [Q094](#q094)=16；`GDD.md:268`; `GDD.md:316`; `GDD.md:319`; `GDD.md:341`; `GDD.md:344`; `GDD.md:814`; `data/numbers.yaml:23`; `data/numbers.yaml:24`; `data/numbers.yaml:31`; `data/numbers.yaml:100`; `data/numbers.yaml:101`; `data/numbers.yaml:102`; `data/numbers.yaml:106`; `data/numbers.yaml:108`; `data/numbers.yaml:109`; `data/numbers.yaml:1666` | [Q101](#q101)=1 / [Q102](#q102)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 公式结构文档；布尔字段不是运行时开关，保留说明锚。 |
| `combat.final_damage_formula.apply_school_counter` | 1 | true | 114 | [Q104](#q104)=2 / [Q106](#q106)=0 | [Q001](#q001)=63 / [Q024](#q024)=106 | [Q107](#q107)=1 / [Q094](#q094)=16；`GDD.md:268`; `GDD.md:316`; `GDD.md:319`; `GDD.md:341`; `GDD.md:344`; `GDD.md:814`; `data/numbers.yaml:23`; `data/numbers.yaml:24`; `data/numbers.yaml:31`; `data/numbers.yaml:100`; `data/numbers.yaml:101`; `data/numbers.yaml:102`; `data/numbers.yaml:106`; `data/numbers.yaml:108`; `data/numbers.yaml:109`; `data/numbers.yaml:1666` | [Q108](#q108)=1 / [Q109](#q109)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 公式结构文档；布尔字段不是运行时开关，保留说明锚。 |
| `combat.final_damage_formula.apply_critical` | 1 | true | 115 | [Q111](#q111)=0 / [Q113](#q113)=0 | [Q001](#q001)=63 / [Q024](#q024)=106 | [Q114](#q114)=1 / [Q094](#q094)=16；`GDD.md:268`; `GDD.md:316`; `GDD.md:319`; `GDD.md:341`; `GDD.md:344`; `GDD.md:814`; `data/numbers.yaml:23`; `data/numbers.yaml:24`; `data/numbers.yaml:31`; `data/numbers.yaml:100`; `data/numbers.yaml:101`; `data/numbers.yaml:102`; `data/numbers.yaml:106`; `data/numbers.yaml:108`; `data/numbers.yaml:109`; `data/numbers.yaml:1666` | [Q115](#q115)=1 / [Q116](#q116)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 公式结构文档；布尔字段不是运行时开关，保留说明锚。 |
| `combat.final_damage_formula.apply_defense` | 1 | true | 116 | [Q118](#q118)=0 / [Q120](#q120)=0 | [Q001](#q001)=63 / [Q024](#q024)=106 | [Q121](#q121)=1 / [Q094](#q094)=16；`GDD.md:268`; `GDD.md:316`; `GDD.md:319`; `GDD.md:341`; `GDD.md:344`; `GDD.md:814`; `data/numbers.yaml:23`; `data/numbers.yaml:24`; `data/numbers.yaml:31`; `data/numbers.yaml:100`; `data/numbers.yaml:101`; `data/numbers.yaml:102`; `data/numbers.yaml:106`; `data/numbers.yaml:108`; `data/numbers.yaml:109`; `data/numbers.yaml:1666` | [Q122](#q122)=1 / [Q123](#q123)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 公式结构文档；布尔字段不是运行时开关，保留说明锚。 |
| `combat.final_damage_formula.apply_realm_diff` | 1 | true | 117 | [Q125](#q125)=0 / [Q127](#q127)=0 | [Q001](#q001)=63 / [Q024](#q024)=106 | [Q128](#q128)=1 / [Q094](#q094)=16；`GDD.md:268`; `GDD.md:316`; `GDD.md:319`; `GDD.md:341`; `GDD.md:344`; `GDD.md:814`; `data/numbers.yaml:23`; `data/numbers.yaml:24`; `data/numbers.yaml:31`; `data/numbers.yaml:100`; `data/numbers.yaml:101`; `data/numbers.yaml:102`; `data/numbers.yaml:106`; `data/numbers.yaml:108`; `data/numbers.yaml:109`; `data/numbers.yaml:1666` | [Q129](#q129)=1 / [Q130](#q130)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 公式结构文档；布尔字段不是运行时开关，保留说明锚。 |
| `equipment.tiers[].tier_name` | 7 | "寻常货" → "神物" | 681,688,695,702,709,718,727 | [Q132](#q132)=0 / [Q134](#q134)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q135](#q135)=15 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q136](#q136)=1 / [Q137](#q137)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].weapon.attack_min` | 7 | 100 → 1500 | 682,689,696,703,710,719,728 | [Q142](#q142)=1 / [Q144](#q144)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q145](#q145)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q146](#q146)=1 / [Q147](#q147)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].weapon.hp_min` | 7 | 0 → 150 | 682,689,696,703,710,719,728 | [Q149](#q149)=0 / [Q151](#q151)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q152](#q152)=26 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q153](#q153)=1 / [Q154](#q154)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].weapon.speed_max` | 7 | 10 → 100 | 682,689,696,703,710,719,728 | [Q156](#q156)=0 / [Q158](#q158)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q159](#q159)=21 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q160](#q160)=1 / [Q161](#q161)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].weapon.speed_min` | 7 | 0 → 65 | 682,689,696,703,710,719,728 | [Q163](#q163)=0 / [Q165](#q165)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q166](#q166)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q167](#q167)=1 / [Q168](#q168)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].armor.attack_min` | 7 | 0 → 0 | 683,690,697,704,711,720,729 | [Q142](#q142)=1 / [Q170](#q170)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q145](#q145)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q146](#q146)=1 / [Q147](#q147)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].armor.hp_min` | 7 | 100 → 1750 | 683,690,697,704,711,720,729 | [Q149](#q149)=0 / [Q171](#q171)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q152](#q152)=26 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q153](#q153)=1 / [Q154](#q154)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].armor.speed_max` | 7 | 5 → 70 | 683,690,697,704,711,720,729 | [Q156](#q156)=0 / [Q172](#q172)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q159](#q159)=21 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q160](#q160)=1 / [Q161](#q161)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].armor.speed_min` | 7 | 0 → 40 | 683,690,697,704,711,720,729 | [Q163](#q163)=0 / [Q173](#q173)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q166](#q166)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q167](#q167)=1 / [Q168](#q168)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].accessory.attack_min` | 7 | 20 → 600 | 684,691,698,705,712,721,730 | [Q142](#q142)=1 / [Q174](#q174)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q145](#q145)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q146](#q146)=1 / [Q147](#q147)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].accessory.hp_min` | 7 | 50 → 1000 | 684,691,698,705,712,721,730 | [Q149](#q149)=0 / [Q175](#q175)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q152](#q152)=26 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q153](#q153)=1 / [Q154](#q154)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].accessory.speed_max` | 7 | 8 → 95 | 684,691,698,705,712,721,730 | [Q156](#q156)=0 / [Q176](#q176)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q159](#q159)=21 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q160](#q160)=1 / [Q161](#q161)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].accessory.speed_min` | 7 | 0 → 65 | 684,691,698,705,712,721,730 | [Q163](#q163)=0 / [Q177](#q177)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q166](#q166)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q167](#q167)=1 / [Q168](#q168)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.enhancement.max_level_formula` | 1 | "absolute_level" | 735 | [Q178](#q178)=1 / [Q180](#q180)=0 | [Q001](#q001)=63 / [Q033](#q033)=22 | [Q181](#q181)=1 / [Q185](#q185)=1；`GDD.md:429` | [Q182](#q182)=1 / [Q183](#q183)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | GDD 强化上限合同仍存在；生产用角色层数实现，该字符串未被读取。 |
| `equipment.enhancement.success_curve[].success_formula` | 1 | "max(0.30, 0.50 - 0.02 * (level - 19))" | 757 | [Q187](#q187)=0 / [Q189](#q189)=0 | [Q001](#q001)=63 / [Q033](#q033)=22 | [Q190](#q190)=2 / [Q194](#q194)=9；`GDD.md:445`; `GDD.md:465`; `GDD.md:517`; `GDD.md:605`; `GDD.md:626`; `GDD.md:647`; `GDD.md:760`; `GDD.md:798`; `GDD.md:802` | [Q191](#q191)=1 / [Q192](#q192)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | GDD 明定高段成功曲线以该段为准；当前解析器使用独立公式实现，不能直接删设计公式。 |
| `equipment.resonance.new_owner_retention` | 1 | 0.0 | 837 | [Q196](#q196)=4 / [Q198](#q198)=1 | [Q001](#q001)=63 / [Q039](#q039)=51 | [Q199](#q199)=2 / [Q203](#q203)=5；`GDD.md:469`; `data/numbers.yaml:837`; `docs/audit/full_audit_2026-06-16.md:12`; `docs/audit/full_audit_2026-06-16.md:65`; `docs/audit/full_audit_2026-06-16.md:66` | [Q200](#q200)=1 / [Q201](#q201)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 换主清零仍是 GDD 合同，原注释明确预埋勿删；字段本身未读取。 |
| `techniques.tiers[].tier_name` | 7 | "入门功" → "传说神功" | 898,904,910,916,922,928,934 | [Q132](#q132)=0 / [Q206](#q206)=0 | [Q001](#q001)=63 / [Q044](#q044)=45 | [Q135](#q135)=15 / [Q207](#q207)=9；`GDD.md:174`; `GDD.md:175`; `GDD.md:180`; `GDD.md:186`; `GDD.md:187`; `GDD.md:192`; `data_schema.md:182`; `data_schema.md:183`; `data_schema.md:188` | [Q136](#q136)=1 / [Q137](#q137)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 七阶名称有 GDD 与 schema 合同；解析器只取阶枚举与速度，阶名是设计锚。 |
| `skills.reference_multipliers.power_skill.tier_1_2_range[]` | 2 | 1000 → 1800 | 1065 | [Q210](#q210)=0 / [Q212](#q212)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q213](#q213)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q214](#q214)=1 / [Q215](#q215)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.power_skill.tier_3_4_range[]` | 2 | 1500 → 2500 | 1066 | [Q219](#q219)=0 / [Q221](#q221)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q222](#q222)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q223](#q223)=1 / [Q224](#q224)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.power_skill.tier_5_6_range[]` | 2 | 2000 → 3000 | 1067 | [Q226](#q226)=0 / [Q228](#q228)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q229](#q229)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q230](#q230)=1 / [Q231](#q231)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.power_skill.tier_7_range[]` | 2 | 2500 → 3500 | 1068 | [Q233](#q233)=0 / [Q235](#q235)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q236](#q236)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q237](#q237)=1 / [Q238](#q238)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.ultimate.tier_1_2_range[]` | 2 | 3000 → 4500 | 1070 | [Q210](#q210)=0 / [Q240](#q240)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q213](#q213)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q214](#q214)=1 / [Q215](#q215)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.ultimate.tier_3_4_range[]` | 2 | 4500 → 6000 | 1071 | [Q219](#q219)=0 / [Q241](#q241)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q222](#q222)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q223](#q223)=1 / [Q224](#q224)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.ultimate.tier_5_6_range[]` | 2 | 5500 → 7000 | 1072 | [Q226](#q226)=0 / [Q242](#q242)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q229](#q229)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q230](#q230)=1 / [Q231](#q231)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `skills.reference_multipliers.ultimate.tier_7_range[]` | 2 | 6500 → 8000 | 1073 | [Q233](#q233)=0 / [Q243](#q243)=0 | [Q001](#q001)=63 / [Q047](#q047)=40 | [Q236](#q236)=2 / [Q217](#q217)=14；`data/numbers.yaml:901`; `data/numbers.yaml:907`; `data/numbers.yaml:913`; `data/numbers.yaml:919`; `data/numbers.yaml:925`; `data/numbers.yaml:931`; `data/numbers.yaml:937`; `data/numbers.yaml:1053`; `data/numbers.yaml:1054`; `data/numbers.yaml:1059`; `data/numbers.yaml:1144`; `CLAUDE.md:164`; `CLAUDE.md:296`; `CLAUDE.md:343` | [Q237](#q237)=1 / [Q238](#q238)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。 |
| `character.attributes.point_per_attribute_min` | 1 | 1 | 1087 | [Q244](#q244)=0 / [Q246](#q246)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q247](#q247)=2 / [Q251](#q251)=8；`CLAUDE.md:564`; `GDD.md:209`; `GDD.md:224`; `docs/spec/rarity_wiring_gap_2026-08-07.md:52`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115`; `docs/spec/rarity_wiring_gap_2026-08-07.md:119`; `docs/spec/rarity_wiring_gap_2026-08-07.md:121`; `docs/spec/rarity_wiring_gap_2026-08-07.md:146` | [Q248](#q248)=1 / [Q249](#q249)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。 |
| `character.attributes.point_per_attribute_max` | 1 | 10 | 1088 | [Q254](#q254)=0 / [Q256](#q256)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q257](#q257)=2 / [Q251](#q251)=8；`CLAUDE.md:564`; `GDD.md:209`; `GDD.md:224`; `docs/spec/rarity_wiring_gap_2026-08-07.md:52`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115`; `docs/spec/rarity_wiring_gap_2026-08-07.md:119`; `docs/spec/rarity_wiring_gap_2026-08-07.md:121`; `docs/spec/rarity_wiring_gap_2026-08-07.md:146` | [Q258](#q258)=1 / [Q259](#q259)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。 |
| `character.attributes.total_points_min` | 1 | 16 | 1089 | [Q261](#q261)=0 / [Q263](#q263)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q264](#q264)=2 / [Q251](#q251)=8；`CLAUDE.md:564`; `GDD.md:209`; `GDD.md:224`; `docs/spec/rarity_wiring_gap_2026-08-07.md:52`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115`; `docs/spec/rarity_wiring_gap_2026-08-07.md:119`; `docs/spec/rarity_wiring_gap_2026-08-07.md:121`; `docs/spec/rarity_wiring_gap_2026-08-07.md:146` | [Q265](#q265)=1 / [Q266](#q266)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。 |
| `character.attributes.total_points_max` | 1 | 24 | 1090 | [Q268](#q268)=0 / [Q270](#q270)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q271](#q271)=1 / [Q251](#q251)=8；`CLAUDE.md:564`; `GDD.md:209`; `GDD.md:224`; `docs/spec/rarity_wiring_gap_2026-08-07.md:52`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115`; `docs/spec/rarity_wiring_gap_2026-08-07.md:119`; `docs/spec/rarity_wiring_gap_2026-08-07.md:121`; `docs/spec/rarity_wiring_gap_2026-08-07.md:146` | [Q272](#q272)=1 / [Q273](#q273)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。 |
| `character.attributes.distribution_mean` | 1 | 5.5 | 1092 | [Q275](#q275)=0 / [Q277](#q277)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q278](#q278)=2 / [Q282](#q282)=7；`GDD.md:209`; `CLAUDE.md:564`; `data/numbers.yaml:1091`; `data/numbers.yaml:1092`; `data/numbers.yaml:1112`; `data/numbers.yaml:1113`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115` | [Q279](#q279)=1 / [Q280](#q280)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定是否保留未来随机生成参数：GDD 正态生成意图与当前静态 profile 分叉。 |
| `character.attributes.distribution_stddev` | 1 | 1.5 | 1093 | [Q286](#q286)=0 / [Q288](#q288)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q289](#q289)=1 / [Q282](#q282)=7；`GDD.md:209`; `CLAUDE.md:564`; `data/numbers.yaml:1091`; `data/numbers.yaml:1092`; `data/numbers.yaml:1112`; `data/numbers.yaml:1113`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115` | [Q290](#q290)=1 / [Q291](#q291)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定是否保留未来随机生成参数：GDD 正态生成意图与当前静态 profile 分叉。 |
| `character.attributes.rerollable` | 1 | false | 1094 | [Q293](#q293)=1 / [Q295](#q295)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q296](#q296)=5 / [Q251](#q251)=8；`CLAUDE.md:564`; `GDD.md:209`; `GDD.md:224`; `docs/spec/rarity_wiring_gap_2026-08-07.md:52`; `docs/spec/rarity_wiring_gap_2026-08-07.md:115`; `docs/spec/rarity_wiring_gap_2026-08-07.md:119`; `docs/spec/rarity_wiring_gap_2026-08-07.md:121`; `docs/spec/rarity_wiring_gap_2026-08-07.md:146` | [Q297](#q297)=1 / [Q298](#q298)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。 |
| `character.adventure_attribute_bonus.bonus_per_event_min` | 1 | 1 | 1145 | [Q300](#q300)=0 / [Q302](#q302)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q303](#q303)=3 / [Q307](#q307)=96；`data/numbers.yaml:1143`; `data/numbers.yaml:1144`; `data/numbers.yaml:1145`; `data/numbers.yaml:1146`; `data/encounters.yaml:43`; `data/encounters.yaml:63`; `data/encounters.yaml:67`; `data/encounters.yaml:82`; `data/encounters.yaml:86`; `data/encounters.yaml:118`; `data/encounters.yaml:135`; `data/encounters.yaml:139`; `data/encounters.yaml:160`; `data/encounters.yaml:164`; `data/encounters.yaml:183`; `data/encounters.yaml:205`; `data/encounters.yaml:227`; `data/encounters.yaml:250`; `data/encounters.yaml:254`; `data/encounters.yaml:271`; `data/encounters.yaml:293`; `data/encounters.yaml:297`; `data/encounters.yaml:316`; `data/encounters.yaml:340`; `data/encounters.yaml:344`; `data/encounters.yaml:363`; `data/encounters.yaml:367`; `data/encounters.yaml:401`; `data/encounters.yaml:424`; `data/encounters.yaml:428`; `data/encounters.yaml:447`; `data/encounters.yaml:451`; `data/encounters.yaml:470`; `data/encounters.yaml:496`; `data/encounters.yaml:515`; `data/encounters.yaml:519`; `data/encounters.yaml:554`; `data/encounters.yaml:577`; `data/encounters.yaml:597`; `data/encounters.yaml:614`; `data/encounters.yaml:639`; `data/encounters.yaml:656`; `data/encounters.yaml:676`; `data/encounters.yaml:697`; `data/encounters.yaml:718`; `data/encounters.yaml:737`; `data/encounters.yaml:741`; `data/encounters.yaml:757`; `data/encounters.yaml:761`; `data/encounters.yaml:777`; `data/encounters.yaml:781`; `data/encounters.yaml:797`; `data/encounters.yaml:801`; `data/encounters.yaml:817`; `data/encounters.yaml:821`; `data/encounters.yaml:837`; `data/encounters.yaml:841`; `data/encounters.yaml:857`; `data/encounters.yaml:861`; `data/encounters.yaml:877`; `data/encounters.yaml:881`; `data/encounters.yaml:902`; `data/encounters.yaml:925`; `data/encounters.yaml:949`; `data/encounters.yaml:972`; `data/encounters.yaml:995`; `data/encounters.yaml:1018`; `data/encounters.yaml:1038`; `data/encounters.yaml:1042`; `data/encounters.yaml:1068`; `data/encounters.yaml:1085`; `data/encounters.yaml:1102`; `data/encounters.yaml:1119`; `data/encounters.yaml:1136`; `data/encounters.yaml:1152`; `data/encounters.yaml:1156`; `data/encounters.yaml:1172`; `data/encounters.yaml:1176`; `data/encounters.yaml:1192`; `data/encounters.yaml:1196`; `data/encounters.yaml:1212`; `data/encounters.yaml:1216`; `data/encounters.yaml:1238`; `data/encounters.yaml:1257`; `data/encounters.yaml:1276`; `data/encounters.yaml:1302`; `data/encounters.yaml:1318`; `data/encounters.yaml:1337`; `data/encounters.yaml:1356`; `data/encounters.yaml:1372`; `data/encounters.yaml:1389`; `data/encounters.yaml:1405`; `data/encounters.yaml:1423`; `data/encounters.yaml:1440`; `data/encounters.yaml:1458`; `data/encounters.yaml:1476` | [Q304](#q304)=2 / [Q305](#q305)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 原注释已说明仅设计参考，单次加点由独立奇遇 outcome 配置承担。 |
| `character.adventure_attribute_bonus.bonus_per_event_max` | 1 | 3 | 1146 | [Q309](#q309)=0 / [Q311](#q311)=0 | [Q001](#q001)=63 / [Q052](#q052)=25 | [Q312](#q312)=2 / [Q307](#q307)=96；`data/numbers.yaml:1143`; `data/numbers.yaml:1144`; `data/numbers.yaml:1145`; `data/numbers.yaml:1146`; `data/encounters.yaml:43`; `data/encounters.yaml:63`; `data/encounters.yaml:67`; `data/encounters.yaml:82`; `data/encounters.yaml:86`; `data/encounters.yaml:118`; `data/encounters.yaml:135`; `data/encounters.yaml:139`; `data/encounters.yaml:160`; `data/encounters.yaml:164`; `data/encounters.yaml:183`; `data/encounters.yaml:205`; `data/encounters.yaml:227`; `data/encounters.yaml:250`; `data/encounters.yaml:254`; `data/encounters.yaml:271`; `data/encounters.yaml:293`; `data/encounters.yaml:297`; `data/encounters.yaml:316`; `data/encounters.yaml:340`; `data/encounters.yaml:344`; `data/encounters.yaml:363`; `data/encounters.yaml:367`; `data/encounters.yaml:401`; `data/encounters.yaml:424`; `data/encounters.yaml:428`; `data/encounters.yaml:447`; `data/encounters.yaml:451`; `data/encounters.yaml:470`; `data/encounters.yaml:496`; `data/encounters.yaml:515`; `data/encounters.yaml:519`; `data/encounters.yaml:554`; `data/encounters.yaml:577`; `data/encounters.yaml:597`; `data/encounters.yaml:614`; `data/encounters.yaml:639`; `data/encounters.yaml:656`; `data/encounters.yaml:676`; `data/encounters.yaml:697`; `data/encounters.yaml:718`; `data/encounters.yaml:737`; `data/encounters.yaml:741`; `data/encounters.yaml:757`; `data/encounters.yaml:761`; `data/encounters.yaml:777`; `data/encounters.yaml:781`; `data/encounters.yaml:797`; `data/encounters.yaml:801`; `data/encounters.yaml:817`; `data/encounters.yaml:821`; `data/encounters.yaml:837`; `data/encounters.yaml:841`; `data/encounters.yaml:857`; `data/encounters.yaml:861`; `data/encounters.yaml:877`; `data/encounters.yaml:881`; `data/encounters.yaml:902`; `data/encounters.yaml:925`; `data/encounters.yaml:949`; `data/encounters.yaml:972`; `data/encounters.yaml:995`; `data/encounters.yaml:1018`; `data/encounters.yaml:1038`; `data/encounters.yaml:1042`; `data/encounters.yaml:1068`; `data/encounters.yaml:1085`; `data/encounters.yaml:1102`; `data/encounters.yaml:1119`; `data/encounters.yaml:1136`; `data/encounters.yaml:1152`; `data/encounters.yaml:1156`; `data/encounters.yaml:1172`; `data/encounters.yaml:1176`; `data/encounters.yaml:1192`; `data/encounters.yaml:1196`; `data/encounters.yaml:1212`; `data/encounters.yaml:1216`; `data/encounters.yaml:1238`; `data/encounters.yaml:1257`; `data/encounters.yaml:1276`; `data/encounters.yaml:1302`; `data/encounters.yaml:1318`; `data/encounters.yaml:1337`; `data/encounters.yaml:1356`; `data/encounters.yaml:1372`; `data/encounters.yaml:1389`; `data/encounters.yaml:1405`; `data/encounters.yaml:1423`; `data/encounters.yaml:1440`; `data/encounters.yaml:1458`; `data/encounters.yaml:1476` | [Q313](#q313)=1 / [Q314](#q314)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 原注释已说明仅设计参考，单次加点由独立奇遇 outcome 配置承担。 |
| `retreat.time_of_day_bonus[].time_range[]` | 4 | "23:00" → "13:00" | 1377,1381 | [Q316](#q316)=2 / [Q318](#q318)=0 | [Q001](#q001)=63 / [Q056](#q056)=20 | [Q319](#q319)=8 / [Q323](#q323)=14；`data/numbers.yaml:1371`; `data/numbers.yaml:1372`; `data/numbers.yaml:1374`; `data/numbers.yaml:1376`; `data/numbers.yaml:1377`; `data/numbers.yaml:1380`; `data/numbers.yaml:1381`; `data/numbers.yaml:1384`; `data/numbers.yaml:1388`; `GDD.md:546`; `GDD.md:547`; `data_schema.md:283`; `data_schema.md:284`; `data_schema.md:1128` | [Q320](#q320)=2 / [Q321](#q321)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 固定传统时辰的文档锚；代码按 period 与时钟规则实现，不读取该时间数组或 null。 |
| `retreat.time_of_day_bonus[].time_range` | 1 | null | 1388 | [Q316](#q316)=2 / [Q318](#q318)=0 | [Q001](#q001)=63 / [Q056](#q056)=20 | [Q319](#q319)=8 / [Q323](#q323)=14；`data/numbers.yaml:1371`; `data/numbers.yaml:1372`; `data/numbers.yaml:1374`; `data/numbers.yaml:1376`; `data/numbers.yaml:1377`; `data/numbers.yaml:1380`; `data/numbers.yaml:1381`; `data/numbers.yaml:1384`; `data/numbers.yaml:1388`; `GDD.md:546`; `GDD.md:547`; `data_schema.md:283`; `data_schema.md:284`; `data_schema.md:1128` | [Q320](#q320)=2 / [Q321](#q321)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 固定传统时辰的文档锚；代码按 period 与时钟规则实现，不读取该时间数组或 null。 |
| `tower.daily_attempts` | 1 | 5 | 1496 | [Q326](#q326)=2 / [Q328](#q328)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q329](#q329)=8 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q330](#q330)=2 / [Q331](#q331)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.refresh_at` | 1 | "00:00" | 1497 | [Q337](#q337)=2 / [Q339](#q339)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q340](#q340)=5 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q341](#q341)=1 / [Q342](#q342)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.difficulty_curve[].difficulty_range[]` | 12 | 1.0 → 4.2 | 1510,1514,1520,1524,1530,1534 | [Q344](#q344)=0 / [Q346](#q346)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q347](#q347)=6 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q348](#q348)=1 / [Q349](#q349)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.difficulty_curve[].recommended_realm` | 6 | "erLiu" → "jueDing" | 1512,1516,1522,1526,1532,1536 | [Q351](#q351)=0 / [Q353](#q353)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q354](#q354)=7 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q355](#q355)=1 / [Q356](#q356)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.boss_layers.small_boss_layers[]` | 3 | 5 → 25 | 1541 | [Q358](#q358)=0 / [Q360](#q360)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q361](#q361)=1 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q362](#q362)=1 / [Q363](#q363)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.boss_layers.big_boss_layers[]` | 3 | 10 → 30 | 1542 | [Q365](#q365)=0 / [Q367](#q367)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q368](#q368)=1 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q369](#q369)=1 / [Q370](#q370)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.boss_layers.small_boss_multiplier` | 1 | 1.5 | 1543 | [Q372](#q372)=0 / [Q374](#q374)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q375](#q375)=1 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q376](#q376)=1 / [Q377](#q377)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.boss_layers.big_boss_multiplier` | 1 | 2.0 | 1544 | [Q379](#q379)=0 / [Q381](#q381)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q382](#q382)=1 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q383](#q383)=1 / [Q384](#q384)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `tower.leaderboard.sync_to_supabase` | 1 | true | 1554 | [Q386](#q386)=2 / [Q388](#q388)=0 | [Q001](#q001)=63 / [Q061](#q061)=57 | [Q389](#q389)=9 / [Q333](#q333)=9；`GDD.md:15`; `GDD.md:46`; `GDD.md:603`; `GDD.md:604`; `GDD.md:606`; `GDD.md:607`; `data_schema.md:1255`; `data/numbers.yaml:1486`; `data/numbers.yaml:1491` | [Q390](#q390)=1 / [Q391](#q391)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。 |
| `inheritance.unlock_rules.can_take_disciple_at` | 1 | "yiLiu" | 1579 | [Q393](#q393)=1 / [Q395](#q395)=0 | [Q001](#q001)=63 / [Q066](#q066)=22 | [Q396](#q396)=6 / [Q400](#q400)=21；`data/recruit_candidates.yaml:2`; `GDD.md:137`; `GDD.md:138`; `GDD.md:154`; `GDD.md:189`; `GDD.md:190`; `GDD.md:361`; `GDD.md:503`; `GDD.md:504`; `GDD.md:572`; `GDD.md:573`; `GDD.md:574`; `GDD.md:575`; `GDD.md:576`; `GDD.md:577`; `GDD.md:583`; `GDD.md:589`; `GDD.md:598`; `GDD.md:599`; `GDD.md:604`; `GDD.md:782` | [Q397](#q397)=2 / [Q398](#q398)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。 |
| `inheritance.unlock_rules.disciple_can_take_grand_disciple_at` | 1 | "jueDing" | 1580 | [Q404](#q404)=1 / [Q406](#q406)=0 | [Q001](#q001)=63 / [Q066](#q066)=22 | [Q407](#q407)=3 / [Q400](#q400)=21；`data/recruit_candidates.yaml:2`; `GDD.md:137`; `GDD.md:138`; `GDD.md:154`; `GDD.md:189`; `GDD.md:190`; `GDD.md:361`; `GDD.md:503`; `GDD.md:504`; `GDD.md:572`; `GDD.md:573`; `GDD.md:574`; `GDD.md:575`; `GDD.md:576`; `GDD.md:577`; `GDD.md:583`; `GDD.md:589`; `GDD.md:598`; `GDD.md:599`; `GDD.md:604`; `GDD.md:782` | [Q408](#q408)=2 / [Q409](#q409)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。 |
| `inheritance.unlock_rules.can_pass_legacy_at` | 1 | "wuSheng" | 1581 | [Q411](#q411)=1 / [Q413](#q413)=0 | [Q001](#q001)=63 / [Q066](#q066)=22 | [Q414](#q414)=3 / [Q418](#q418)=7；`data/numbers.yaml:834`; `data/numbers.yaml:872`; `data/numbers.yaml:1574`; `data/numbers.yaml:1576`; `data/numbers.yaml:1581`; `data/numbers.yaml:1595`; `data/numbers.yaml:1596` | [Q415](#q415)=2 / [Q416](#q416)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。 |
| `inheritance.heritage_items.auto_buff_internal_force_max` | 1 | 0.05 | 1595 | [Q422](#q422)=1 / [Q424](#q424)=0 | [Q001](#q001)=63 / [Q066](#q066)=22 | [Q425](#q425)=2 / [Q418](#q418)=7；`data/numbers.yaml:834`; `data/numbers.yaml:872`; `data/numbers.yaml:1574`; `data/numbers.yaml:1576`; `data/numbers.yaml:1581`; `data/numbers.yaml:1595`; `data/numbers.yaml:1596` | [Q426](#q426)=1 / [Q427](#q427)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。 |
| `inheritance.heritage_items.resonance_retention` | 1 | 0.7 | 1596 | [Q429](#q429)=1 / [Q431](#q431)=0 | [Q001](#q001)=63 / [Q066](#q066)=22 | [Q432](#q432)=3 / [Q418](#q418)=7；`data/numbers.yaml:834`; `data/numbers.yaml:872`; `data/numbers.yaml:1574`; `data/numbers.yaml:1576`; `data/numbers.yaml:1581`; `data/numbers.yaml:1595`; `data/numbers.yaml:1596` | [Q433](#q433)=1 / [Q434](#q434)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。 |
| `synergies.effect_values.yin_yang_he.effect_type` | 1 | "all_attr_pct" | 1636 | [Q436](#q436)=0 / [Q438](#q438)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q439](#q439)=5 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q440](#q440)=1 / [Q441](#q441)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.yin_yang_he.effect_value` | 1 | 0.2 | 1637 | [Q447](#q447)=0 / [Q449](#q449)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q450](#q450)=9 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q451](#q451)=2 / [Q452](#q452)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.gai_bang_chuan_cheng.effect_type` | 1 | "unlock_skill_crit" | 1641 | [Q436](#q436)=0 / [Q454](#q454)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q439](#q439)=5 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q440](#q440)=1 / [Q441](#q441)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.gai_bang_chuan_cheng.target_skill_id` | 1 | "skill_kang_long_you_hui" | 1642 | [Q455](#q455)=0 / [Q457](#q457)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q458](#q458)=1 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q459](#q459)=1 / [Q460](#q460)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.shao_lin_zheng_zong.effect_type` | 1 | "internal_force_growth_pct" | 1647 | [Q436](#q436)=0 / [Q462](#q462)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q439](#q439)=5 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q440](#q440)=1 / [Q441](#q441)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.shao_lin_zheng_zong.effect_value` | 1 | 0.3 | 1648 | [Q447](#q447)=0 / [Q463](#q463)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q450](#q450)=9 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q451](#q451)=2 / [Q452](#q452)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.wu_dang_yuan_rong.effect_type` | 1 | "reflect_pct" | 1652 | [Q436](#q436)=0 / [Q464](#q464)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q439](#q439)=5 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q440](#q440)=1 / [Q441](#q441)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.wu_dang_yuan_rong.effect_value` | 1 | 0.15 | 1653 | [Q447](#q447)=0 / [Q465](#q465)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q450](#q450)=9 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q451](#q451)=2 / [Q452](#q452)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.hua_shan_he_bi.effect_type` | 1 | "crit_dmg_pct" | 1657 | [Q436](#q436)=0 / [Q466](#q466)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q439](#q439)=5 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q440](#q440)=1 / [Q441](#q441)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `synergies.effect_values.hua_shan_he_bi.effect_value` | 1 | 0.5 | 1658 | [Q447](#q447)=0 / [Q467](#q467)=0 | [Q001](#q001)=63 / [Q071](#q071)=10 | [Q450](#q450)=9 / [Q443](#q443)=30；`GDD.md:278`; `GDD.md:279`; `GDD.md:280`; `GDD.md:281`; `GDD.md:282`; `data_schema.md:1701`; `data_schema.md:1704`; `data_schema.md:1705`; `data_schema.md:1714`; `data_schema.md:1715`; `data_schema.md:1721`; `data_schema.md:1725`; `data_schema.md:1728`; `data_schema.md:1729`; `data/synergies.yaml:28`; `data/synergies.yaml:32`; `data/synergies.yaml:38`; `data/synergies.yaml:52`; `data/synergies.yaml:63`; `data/synergies.yaml:73`; `data/synergies.yaml:85`; `data/synergies.yaml:90`; `data/synergies.yaml:101`; `data/synergies.yaml:115`; `data/synergies.yaml:123`; `data/synergies.yaml:134`; `data/synergies.yaml:152`; `data/synergies.yaml:167`; `data/synergies.yaml:183`; `data/synergies.yaml:198` | [Q451](#q451)=2 / [Q452](#q452)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 待拍板 | 未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。 |
| `validation_examples.example_a.attacker.cultivation_multiplier` | 1 | 1.0 | 1682 | [Q468](#q468)=6 / [Q470](#q470)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q471](#q471)=17 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q472](#q472)=5 / [Q473](#q473)=3；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_a.attacker.school_counter` | 1 | 1.0 | 1683 | [Q477](#q477)=8 / [Q479](#q479)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q480](#q480)=11 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q481](#q481)=1 / [Q482](#q482)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_a.calculated_damage` | 1 | "(600*0.4 + 130*1.0 + 500) * 1.0 * 1.0 * 1.0 * (1-0.05) * 1.0 = 826" | 1689 | [Q484](#q484)=2 / [Q486](#q486)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q487](#q487)=7 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q488](#q488)=1 / [Q489](#q489)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_a.expected_outcome` | 1 | "约 4 击致死，节奏适合新手期教学战斗 ✓" | 1690 | [Q491](#q491)=0 / [Q493](#q493)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q494](#q494)=5 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q495](#q495)=1 / [Q496](#q496)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_b.attacker.cultivation_multiplier` | 1 | 1.75 | 1701 | [Q468](#q468)=6 / [Q498](#q498)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q471](#q471)=17 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q472](#q472)=5 / [Q473](#q473)=3；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_b.attacker.school_counter` | 1 | 1.0 | 1702 | [Q477](#q477)=8 / [Q499](#q499)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q480](#q480)=11 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q481](#q481)=1 / [Q482](#q482)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_b.calculated_damage` | 1 | "(3000*0.4 + 580 + 1500) * 1.75 * 1.0 * 1.0 * 0.85 * 1.0 = 4889" | 1708 | [Q484](#q484)=2 / [Q500](#q500)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q487](#q487)=7 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q488](#q488)=1 / [Q489](#q489)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_b.expected_outcome` | 1 | "在 2000-8000 红线内 ✓；约 2 击致死，强力技能节奏合理" | 1709 | [Q491](#q491)=0 / [Q501](#q501)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q494](#q494)=5 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q495](#q495)=1 / [Q496](#q496)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_c.attacker.cultivation_multiplier` | 1 | 1.3 | 1720 | [Q468](#q468)=6 / [Q502](#q502)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q471](#q471)=17 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q472](#q472)=5 / [Q473](#q473)=3；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_c.attacker.school_counter` | 1 | 1.0 | 1721 | [Q477](#q477)=8 / [Q503](#q503)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q480](#q480)=11 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q481](#q481)=1 / [Q482](#q482)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_c.attacker.realm_diff_modifier` | 1 | 0.7 | 1723 | [Q504](#q504)=0 / [Q506](#q506)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q507](#q507)=2 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q508](#q508)=1 / [Q509](#q509)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_c.calculated_damage` | 1 | "(2000*0.4 + 280 + 1500) * 1.30 * 1.0 * 1.0 * 0.85 * 0.7 = 1972" | 1728 | [Q484](#q484)=2 / [Q511](#q511)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q487](#q487)=7 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q488](#q488)=1 / [Q489](#q489)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_c.expected_outcome` | 1 | "勉强达到普通伤害下限 2000；约 4 击致死，三流挑战二流确实吃力 ✓" | 1729 | [Q491](#q491)=0 / [Q512](#q512)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q494](#q494)=5 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q495](#q495)=1 / [Q496](#q496)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_d.attacker.cultivation_multiplier` | 1 | 1.75 | 1740 | [Q468](#q468)=6 / [Q513](#q513)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q471](#q471)=17 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q472](#q472)=5 / [Q473](#q473)=3；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_d.attacker.school_counter` | 1 | 1.25 | 1741 | [Q477](#q477)=8 / [Q514](#q514)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q480](#q480)=11 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q481](#q481)=1 / [Q482](#q482)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_d.calculated_damage` | 1 | "(5000*0.4 + 600 + 5500) * 1.75 * 1.25 * 2.0 * 0.80 * 1.0 = 28525" | 1747 | [Q484](#q484)=2 / [Q515](#q515)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q487](#q487)=7 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q488](#q488)=1 / [Q489](#q489)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_d.expected_outcome` | 1 | "破万达成（28525），符合 GDD §5.2 大招暴击'上万'目标 ✓；一击秒杀" | 1748 | [Q491](#q491)=0 / [Q516](#q516)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q494](#q494)=5 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q495](#q495)=1 / [Q496](#q496)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_e.attacker.cultivation_multiplier` | 1 | 3.0 | 1760 | [Q468](#q468)=6 / [Q517](#q517)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q471](#q471)=17 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q472](#q472)=5 / [Q473](#q473)=3；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_e.attacker.school_counter` | 1 | 1.0 | 1761 | [Q477](#q477)=8 / [Q518](#q518)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q480](#q480)=11 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q481](#q481)=1 / [Q482](#q482)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |
| `validation_examples.example_e.expected_outcome` | 1 | "约 19500 / 19500 几乎一击致死，符合武圣对决'电光石火'氛围 ✓；血量未超 20000 红线 ✓" | 1768 | [Q491](#q491)=0 / [Q519](#q519)=0 | [Q001](#q001)=63 / [Q074](#q074)=88 | [Q494](#q494)=5 / [Q475](#q475)=23；`data/numbers.yaml:22`; `data/numbers.yaml:31`; `data/numbers.yaml:106`; `data/numbers.yaml:1661`; `data/numbers.yaml:1663`; `data/numbers.yaml:1664`; `data/numbers.yaml:1666`; `data/numbers.yaml:1667`; `data/numbers.yaml:1668`; `data/numbers.yaml:1670`; `data/numbers.yaml:1671`; `data/numbers.yaml:1673`; `data/numbers.yaml:1692`; `data/numbers.yaml:1711`; `data/numbers.yaml:1731`; `data/numbers.yaml:1750`; `data/numbers.yaml:1767`; `docs/_archive/phase1_tasks.md:21`; `docs/_archive/phase1_tasks.md:506`; `docs/_archive/phase1_tasks.md:575`; `docs/_archive/phase1_tasks.md:576`; `docs/_archive/phase1_tasks.md:948`; `docs/_archive/phase1_tasks.md:1012` | [Q495](#q495)=1 / [Q496](#q496)=0；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 头注 UNUSED | 手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。 |

## 对 B-2 原表的更正

“误判：实际消费”共 **0 个归一路径 / 0 个叶子**；没有证据支持伪造更正。原表零引用集合保持一致。
建议口径需要更正：原表部分行只依据静态零命中提出删除候选，本表增加合同、设计锚、历史意图后重新分类；建议变化逐行列于下表。旧历史 handoff 将传承旧字段说成活配置，不能据此认定当前实际消费；当前活源在装备或飞升段。

| 原表归类 | 本表建议 | 归一路径 | 标量叶子 |
|---|---|---:|---:|
| 保留理由 | 头注 UNUSED | 29 | 32 |
| 删除候选 | 保留（有合同） | 21 | 105 |
| 待拍板 | 保留（有合同） | 1 | 1 |
| 删除候选 | 头注 UNUSED | 13 | 21 |
| 删除候选 | 待拍板 | 23 | 43 |

## 删除候选

本次 **0 条** 满足无规则合同、无设计锚、无待决冲突的删除条件；因此没有可随机抽取的 8 条删除候选，不能为了抽样数量制造候选。
假如未来用户另行批准，当前可下发的 [schema] 删除位置清单为空：yaml 行、data_schema.md 同步段、测试 fixture 引用均无本次获准候选。塔与相生等待决项必须先澄清合同，不能把这一节当作删除授权。

## 历史加入与后续意图

初始迁入之后未见这些字段的直接消费撤销证据。以下关键 patch 原文可复跑；它们支持设计锚、替代配置与待拍板边界。

- 初始化迁入 data/；本表各完整路径在该文件中首次出现，不能当作设计最初产生时间。 [Q011](#q011)=1146。
- 明确元数据和战例为纯文档、收徒门槛设计与实装分叉、传位门槛存在替代配置。 [Q012](#q012)=75。
- 明确公式开关与固定传统时辰仅作说明，不作为可调运行参数。 [Q013](#q013)=69。
- 明确单次奇遇属性范围仅供设计参考，实际增量由 outcome 承担。 [Q014](#q014)=50。
- 明确旧塔段和相生段 UNUSED；保留设计锚，接线或删除需拍板。 [Q015](#q015)=46。

唯一非零 lib 历史末段检索为 cultivation_multiplier（3 个提交），实际 patch 都是心魔 main_cultivation_multiplier / sub_cultivation_multiplier 子串，与战例无关：[Q016](#q016)=478。

## 十四组人工排除证据（链 tip 真实行号）

### 元数据

本次 1 叶子。NumbersConfig 只从 meta 取 version；未增加 meta 逐键守卫，其余未透传到字段。 父级复搜：[Q017](#q017)=2。

`lib/data/numbers_config.dart:346`；`sed -n 346,346p lib/data/numbers_config.dart`；输出 1 行。

```dart
    final meta = y['meta'] as Map<String, dynamic>;
```

`lib/data/numbers_config.dart:353`；`sed -n 353,353p lib/data/numbers_config.dart`；输出 1 行。

```dart
      version: meta['version'] as String,
```

`lib/data/numbers_config.dart:345-354`；`sed -n 345,354p lib/data/numbers_config.dart`；输出 10 行。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
    final meta = y['meta'] as Map<String, dynamic>;
    final combat = y['combat'] as Map<String, dynamic>;
    final realms = y['realms'] as Map<String, dynamic>;
    final equipment = y['equipment'] as Map<String, dynamic>;
    final techniques = y['techniques'] as Map<String, dynamic>;

    return NumbersConfig(
      version: meta['version'] as String,
      combat: CombatNumbers.fromYaml(combat),
```

### 基础公式文档开关

本次 1 叶子。DamageFormula 只按字段取两个系数，没有整表遍历或额外逐键守卫。 父级复搜：[Q021](#q021)=1。

`lib/data/numbers_config.dart:2429`；`sed -n 2429,2429p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory DamageFormula.fromYaml(Map<String, dynamic> y) {
```

`lib/data/numbers_config.dart:2429-2435`；`sed -n 2429,2435p lib/data/numbers_config.dart`；输出 7 行。

```dart
  factory DamageFormula.fromYaml(Map<String, dynamic> y) {
    return DamageFormula(
      internalForceFactor: (y['internal_force_factor'] as num).toDouble(),
      equipmentAttackFactor: (y['equipment_attack_factor'] as num).toDouble(),
    );
  }
}
```

### 最终公式文档开关

本次 5 叶子。CombatNumbers 构造器逐段解析，没有 final_damage_formula 入口或该段逐键守卫。 父级复搜：[Q024](#q024)=106。

`lib/data/numbers_config.dart:1361`；`sed -n 1361,1361p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory CombatNumbers.fromYaml(Map<String, dynamic> y) {
```

`lib/data/numbers_config.dart:1361-1398`；`sed -n 1361,1398p lib/data/numbers_config.dart`；输出 38 行。

```dart
  factory CombatNumbers.fromYaml(Map<String, dynamic> y) {
    return CombatNumbers(
      qi: QiConfig.fromYaml(
        (y['qi'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      damageFormula: DamageFormula.fromYaml(
        y['damage_formula'] as Map<String, dynamic>,
      ),
      maxHpFormula: MaxHpFormula.fromYaml(
        y['max_hp_formula'] as Map<String, dynamic>,
      ),
      speedFormula: SpeedFormula.fromYaml(
        y['speed_formula'] as Map<String, dynamic>,
      ),
      critical: CriticalConfig.fromYaml(y['critical'] as Map<String, dynamic>),
      evasion: EvasionConfig.fromYaml(y['evasion'] as Map<String, dynamic>),
      enemyDefaults: EnemyDefaults.fromYaml(
        y['enemy_defaults'] as Map<String, dynamic>,
      ),
      readableFirstClear: ReadableFirstClearConfig.fromYaml(
        y['readable_first_clear'] as Map?,
      ),
      redLines: RedLinesConfig.fromYaml(
        y['red_lines'] as Map<String, dynamic>? ?? const {},
      ),
      bossCharge: BossChargeConfig.fromYaml(
        y['boss_charge'] as Map? ?? const {},
      ),
      impactFeedback: ImpactFeedbackConfig.fromYaml(
        y['impact_feedback'] as Map? ?? const {},
      ),
      posture: PostureNumbersConfig.fromYaml(y['posture']),
      defenseBreak: DefenseBreakConfig.fromYaml(
        y['defense_break'] as Map? ?? const {},
      ),
      weakness: WeaknessConfig.fromYaml(y['weakness'] as Map? ?? const {}),
    );
  }
```

### 装备阶模板

本次 91 叶子。NumbersConfig 的 equipment 读取是强化、开锋、共鸣、遗物与处置；实装装备定义来自独立 equipment.yaml。 父级复搜：[Q027](#q027)=119。

`lib/data/numbers_config.dart:376`；`sed -n 376,376p lib/data/numbers_config.dart`；输出 1 行。

```dart
      enhancementBonusPerLevel:
```

`lib/data/game_repository.dart:220`；`sed -n 220,220p lib/data/game_repository.dart`；输出 1 行。

```dart
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
```

`lib/data/game_repository.dart:228`；`sed -n 228,228p lib/data/game_repository.dart`；输出 1 行。

```dart
    final equipmentDefs = _parseDefMap(
```

`lib/data/numbers_config.dart:376-386`；`sed -n 376,386p lib/data/numbers_config.dart`；输出 11 行。

```dart
      enhancementBonusPerLevel:
          ((equipment['enhancement'] as Map<String, dynamic>)['bonus_per_level']
                  as num)
              .toDouble(),
      enhancement: EnhancementConfig.fromYaml(
        enhancement: equipment['enhancement'] as Map<String, dynamic>,
        xinxueJiejing: equipment['xinxue_jiejing'] as Map<String, dynamic>,
      ),
      forging: ForgingConfig.fromYaml(
        equipment['forging'] as Map<String, dynamic>,
      ),
```

`lib/data/game_repository.dart:219-232`；`sed -n 219,232p lib/data/game_repository.dart`；输出 14 行。

```dart
    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
    final equipmentDefs = _parseDefMap(
      equipmentRaw['equipment'] as List,
      EquipmentDef.fromYaml,
      idOf: (d) => d.id,
    );
```

### 强化公式文档

本次 2 叶子。强化入口逐字段解析；success_curve 循环只取 level_range/success_rate/material_penalty，公式走 _fallbackFormula。 父级复搜：[Q033](#q033)=22。

`lib/data/numbers_config.dart:922`；`sed -n 922,922p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory EnhancementConfig.fromYaml({
```

`lib/data/numbers_config.dart:995`；`sed -n 995,995p lib/data/numbers_config.dart`；输出 1 行。

```dart
  static double _fallbackFormula(int targetLevel) {
```

`lib/data/numbers_config.dart:1000`；`sed -n 1000,1000p lib/data/numbers_config.dart`；输出 1 行。

```dart
  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
```

`lib/data/numbers_config.dart:922-940`；`sed -n 922,940p lib/data/numbers_config.dart`；输出 19 行。

```dart
  factory EnhancementConfig.fromYaml({
    required Map<String, dynamic> enhancement,
    required Map<String, dynamic> xinxueJiejing,
  }) {
    return EnhancementConfig(
      successCurve: _parseSuccessCurve(enhancement['success_curve'] as List),
      mojianshiCost: _parseMaterialCost(enhancement['mojianshi_cost'] as List),
      duancaiCost: _parseMaterialCost(
        enhancement['duancai_cost'] as List? ?? const [],
      ),
      crystalGuarantees: _parseCrystalGuarantees(
        xinxueJiejing['guaranteed_success_costs'] as List,
      ),
      crystalGainPerFailure: (xinxueJiejing['gain_per_failure'] as num).toInt(),
      neverDegrade:
          enhancement['never_degrade'] as bool? ??
          _missingRequiredValue('equipment.enhancement.never_degrade'),
    );
  }
```

`lib/data/numbers_config.dart:990-1010`；`sed -n 990,1010p lib/data/numbers_config.dart`；输出 21 行。

```dart
    }
    throw StateError('success_curve 缺少 targetLevel=$targetLevel 的覆盖区间');
  }

  /// GDD §12 #3 决议：+20-49 段公式 `max(0.30, 0.50 - 0.02 × (level - 19))`。
  static double _fallbackFormula(int targetLevel) {
    final raw = 0.50 - 0.02 * (targetLevel - 19);
    return raw < 0.30 ? 0.30 : raw;
  }

  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
    return [
      for (final e in raw)
        EnhanceLevelBracket(
          minLevel: ((e['level_range'] as List)[0] as num).toInt(),
          maxLevel: ((e['level_range'] as List)[1] as num).toInt(),
          successRate: (e['success_rate'] as num?)?.toDouble(),
          materialPenalty: _parsePenalty(e['material_penalty'] as String),
        ),
    ];
  }
```

### 共鸣换主预留

本次 1 叶子。共鸣只取 stages、inheritance_retention、seclusion_battle_count_per_hour；stages 新增缺值报错仍只校验显式读取字段。 父级复搜：[Q039](#q039)=51。

`lib/data/numbers_config.dart:404`；`sed -n 404,404p lib/data/numbers_config.dart`；输出 1 行。

```dart
      resonanceStages: _parseResonanceStages(
```

`lib/data/numbers_config.dart:619`；`sed -n 619,619p lib/data/numbers_config.dart`；输出 1 行。

```dart
  static List<ResonanceStageConfig> _parseResonanceStages(
```

`lib/data/numbers_config.dart:404-419`；`sed -n 404,419p lib/data/numbers_config.dart`；输出 16 行。

```dart
      resonanceStages: _parseResonanceStages(
        equipment['resonance'] as Map<String, dynamic>,
      ),
      resonanceInheritanceRetention:
          ((equipment['resonance']
                      as Map<String, dynamic>)['inheritance_retention']
                  as num)
              .toDouble(),
      resonanceSeclusionBattleCountPerHour:
          ((equipment['resonance']
                      as Map<
                        String,
                        dynamic
                      >)['seclusion_battle_count_per_hour']
                  as num)
              .toInt(),
```

`lib/data/numbers_config.dart:619-645`；`sed -n 619,645p lib/data/numbers_config.dart`；输出 27 行。

```dart
  static List<ResonanceStageConfig> _parseResonanceStages(
    Map<String, dynamic> resonance,
  ) {
    final stages = resonance['stages'] as List;
    return [
      for (final s in stages)
        ResonanceStageConfig(
          stage: ResonanceStage.values.byName(s['stage'] as String),
          minBattleCount: ((s['battle_count_range'] as List)[0] as num).toInt(),
          maxBattleCount: ((s['battle_count_range'] as List)[1] as num?)
              ?.toInt(),
          bonusMultiplier: (s['bonus_multiplier'] as num).toDouble(),
          unlocksJointSkill:
              (s['unlocks_joint_skill'] as bool?) ??
              _missingRequiredValue(
                'equipment.resonance.stages[].unlocks_joint_skill',
              ),
          hasSwordSongEffect:
              (s['has_sword_song_effect'] as bool?) ??
              _missingRequiredValue(
                'equipment.resonance.stages[].has_sword_song_effect',
              ),
        ),
    ];
  }
}
```

### 心法阶名称

本次 7 叶子。tiers 遍历只取 tier 和 speed_bonus；不遍历行内所有 key/value。 父级复搜：[Q044](#q044)=45。

`lib/data/numbers_config.dart:553`；`sed -n 553,553p lib/data/numbers_config.dart`；输出 1 行。

```dart
  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
```

`lib/data/numbers_config.dart:553-561`；`sed -n 553,561p lib/data/numbers_config.dart`；输出 9 行。

```dart
  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
    final m = <TechniqueTier, int>{};
    for (final t in tiers) {
      final tier = TechniqueTier.values.byName(t['tier'] as String);
      m[tier] = (t['speed_bonus'] as num).toInt();
    }
    return m;
  }
```

### 招式参考倍率

本次 16 叶子。NumbersConfig 无 skills 入口；实装 SkillDef 来自独立 skills.yaml。 父级复搜：[Q047](#q047)=40。

`lib/data/numbers_config.dart:345`；`sed -n 345,345p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`lib/data/game_repository.dart:222`；`sed -n 222,222p lib/data/game_repository.dart`；输出 1 行。

```dart
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
```

`lib/data/game_repository.dart:238`；`sed -n 238,238p lib/data/game_repository.dart`；输出 1 行。

```dart
    final skillDefs = _parseDefMap(
```

`lib/data/game_repository.dart:219-240`；`sed -n 219,240p lib/data/game_repository.dart`；输出 22 行。

```dart
    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
    final equipmentDefs = _parseDefMap(
      equipmentRaw['equipment'] as List,
      EquipmentDef.fromYaml,
      idOf: (d) => d.id,
    );
    final techniqueDefs = _parseDefMap(
      techniquesRaw['techniques'] as List,
      TechniqueDef.fromYaml,
      idOf: (d) => d.id,
    );
    final skillDefs = _parseDefMap(
      skillsRaw['skills'] as List,
      SkillDef.fromYaml,
```

### 角色设计与事件范围

本次 9 叶子。character 只取 lifetime_cap_per_character 和 rarity_distribution；新增缺值报错仅守卫前者，未整表或动态读取零命中字段。 父级复搜：[Q052](#q052)=25。

`lib/data/numbers_config.dart:492`；`sed -n 492,492p lib/data/numbers_config.dart`；输出 1 行。

```dart
      adventureAttributeLifetimeCap:
```

`lib/data/numbers_config.dart:504`；`sed -n 504,504p lib/data/numbers_config.dart`；输出 1 行。

```dart
      rarityTiers: _parseRarityTiers(
```

`lib/data/numbers_config.dart:492-507`；`sed -n 492,507p lib/data/numbers_config.dart`；输出 16 行。

```dart
      adventureAttributeLifetimeCap:
          (((y['character']
                          as Map<
                            String,
                            dynamic
                          >?)?['adventure_attribute_bonus']
                      as Map<String, dynamic>?)?['lifetime_cap_per_character']
                  as num?)
              ?.toInt() ??
          _missingRequiredValue(
            'character.adventure_attribute_bonus.lifetime_cap_per_character',
          ),
      rarityTiers: _parseRarityTiers(
        (y['character'] as Map<String, dynamic>?)?['rarity_distribution']
            as List?,
      ),
```

### 时段文档锚

本次 5 叶子。按 period 选行后只读 multiplier/target_attribute/applies_to_school；没有读取 time_range。 父级复搜：[Q056](#q056)=20。

`lib/data/numbers_config.dart:2847`；`sed -n 2847,2847p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory RetreatConfig.fromYaml(Map<String, dynamic> y) {
```

`lib/data/numbers_config.dart:2912`；`sed -n 2912,2912p lib/data/numbers_config.dart`；输出 1 行。

```dart
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
```

`lib/data/numbers_config.dart:2847-2868`；`sed -n 2847,2868p lib/data/numbers_config.dart`；输出 22 行。

```dart
  factory RetreatConfig.fromYaml(Map<String, dynamic> y) {
    final rawMaps = y['maps'] as List;
    final rawSolar = y['solar_term_bonus'] as Map<String, dynamic>;
    final rawTimeOfDay = y['time_of_day_bonus'] as List;
    // 提取子时（period=ziShi）的 multiplier，effect=internal_force_growth
    final ziShi =
        rawTimeOfDay.firstWhere(
              (e) => (e as Map)['period'] == 'ziShi',
              orElse: () => <String, dynamic>{'multiplier': 1.0},
            )
            as Map;
    // 正午(period=zhengWu)v1.4 加成定向落到 internal_force_points + 仅 gangMeng 触发。
    final zhengWu =
        rawTimeOfDay.firstWhere(
              (e) => (e as Map)['period'] == 'zhengWu',
              orElse: () => <String, dynamic>{
                'multiplier': 1.0,
                'target_attribute': 'internal_force_points',
                'applies_to_school': 'gangMeng',
              },
            )
            as Map;
```

`lib/data/numbers_config.dart:2912-2918`；`sed -n 2912,2918p lib/data/numbers_config.dart`；输出 7 行。

```dart
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
      zhengWuYangSchoolMultiplier: (zhengWu['multiplier'] as num).toDouble(),
      zhengWuTargetAttribute: zhengWu['target_attribute'] as String,
      zhengWuAppliesToSchool: TechniqueSchool.values.byName(
        zhengWu['applies_to_school'] as String,
      ),
    );
```

### 旧塔配置段

本次 29 叶子。NumbersConfig 无 tower 入口；实际楼层由独立 towers.yaml 读取，原始 Map 未被遍历消费。 父级复搜：[Q061](#q061)=57。

`lib/data/numbers_config.dart:345`；`sed -n 345,345p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`lib/data/game_repository.dart:224`；`sed -n 224,224p lib/data/game_repository.dart`；输出 1 行。

```dart
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));
```

`lib/data/game_repository.dart:270`；`sed -n 270,270p lib/data/game_repository.dart`；输出 1 行。

```dart
    final towerFloors =
```

`lib/data/game_repository.dart:219-227`；`sed -n 219,227p lib/data/game_repository.dart`；输出 9 行。

```dart
    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
```

`lib/data/game_repository.dart:270-277`；`sed -n 270,277p lib/data/game_repository.dart`；输出 8 行。

```dart
    final towerFloors =
        ((towersRaw['floors'] as List?) ?? const [])
            .map(
              (e) =>
                  TowerFloorDef.fromYaml(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false)
          ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));
```

### 传承预留字段

本次 5 叶子。inheritance 只接祖师 buff 和 HeritageItems；后者仍逐个读取六个字段，缺值报错未扩展字段集合，没有通用 Map 遍历。 父级复搜：[Q066](#q066)=22。

`lib/data/numbers_config.dart:428`；`sed -n 428,428p lib/data/numbers_config.dart`；输出 1 行。

```dart
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
```

`lib/data/numbers_config.dart:807`；`sed -n 807,807p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory HeritageItems.fromYaml(Map<String, dynamic> y) {
```

`lib/data/numbers_config.dart:428-437`；`sed -n 428,437p lib/data/numbers_config.dart`；输出 10 行。

```dart
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['founder_ancestor_buff']
                as Map<String, dynamic>?) ??
            const {},
      ),
      heritageItems: HeritageItems.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['heritage_items']
                as Map<String, dynamic>?) ??
            const {},
      ),
```

`lib/data/numbers_config.dart:807-833`；`sed -n 807,833p lib/data/numbers_config.dart`；输出 27 行。

```dart
  factory HeritageItems.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return defaults;
    return HeritageItems(
      piecesPerGenerationMin:
          (y['pieces_per_generation_min'] as num?)?.toInt() ??
          _missingRequiredValue(
            'inheritance.heritage_items.pieces_per_generation_min',
          ),
      piecesPerGenerationMax:
          (y['pieces_per_generation_max'] as num?)?.toInt() ??
          _missingRequiredValue(
            'inheritance.heritage_items.pieces_per_generation_max',
          ),
      transferTrigger:
          (y['transfer_trigger'] as String?) ?? 'ascend_to_wusheng',
      multiDiscipleAllocation:
          (y['multi_disciple_allocation'] as String?) ?? 'player_pick',
      stackAcrossGenerations:
          (y['stack_across_generations'] as bool?) ??
          _missingRequiredValue(
            'inheritance.heritage_items.stack_across_generations',
          ),
      conflictSlotResolution:
          (y['conflict_slot_resolution'] as String?) ?? 'auto_swap',
    );
  }
}
```

### 旧相生数值段

本次 10 叶子。NumbersConfig 无 synergies 入口；实际相生定义来自独立 synergies.yaml，原始 Map 未被遍历消费。 父级复搜：[Q071](#q071)=10。

`lib/data/numbers_config.dart:345`；`sed -n 345,345p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`lib/data/game_repository.dart:373`；`sed -n 373,373p lib/data/game_repository.dart`；输出 1 行。

```dart
      'data/synergies.yaml',
```

`lib/data/game_repository.dart:369-382`；`sed -n 369,382p lib/data/game_repository.dart`；输出 14 行。

```dart
    // W18-A1:心法相生 yaml(允许 test fixture 不带,空 list)。生产路径
    // 红线校验在 enforceSynergyRedLines(validation/) 强制 ≥ 5 + multiplier 范围。
    final synergies = await _loadOptionalAsset(
      load,
      'data/synergies.yaml',
      (raw) {
        final synergiesRaw = parseYamlMap(raw);
        return ((synergiesRaw['synergies'] as List?) ?? const [])
            .map(
              (e) => SynergyDef.fromYaml(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false);
      },
      strict: strict,
```

### 手工公式战例

本次 20 叶子。NumbersConfig 无 validation_examples 解析入口；raw 仅持有数据不构成消费。 父级复搜：[Q074](#q074)=88。

`lib/data/numbers_config.dart:345`；`sed -n 345,345p lib/data/numbers_config.dart`；输出 1 行。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`lib/data/numbers_config.dart:540`；`sed -n 540,540p lib/data/numbers_config.dart`；输出 1 行。

```dart
      raw: y,
```

`lib/data/numbers_config.dart:537-542`；`sed -n 537,542p lib/data/numbers_config.dart`；输出 6 行。

```dart
      phase0aArena: Phase0aArenaConfig.fromYaml(
        (y['phase0a_arena'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      raw: y,
    );
  }
```

## 逐条证据索引

### `meta.last_updated`

① [Q077](#q077)=3；分目录 {'tools': 3}；不限制扩展名 [Q078](#q078)=3；完整/后缀片段 [Q079](#q079)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q017](#q017)=2。
③ 原始 [Q080](#q080)=4；合同补查 [Q085](#q085)=5；原文 `data/numbers.yaml:28-34` [Q086](#q086)=7。
④ [Q081](#q081)=2；仅 lib [Q082](#q082)=0；当前路径首次查询 [Q083](#q083)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:30 核验。

### `combat.damage_formula.skill_multiplier_added`

① [Q087](#q087)=4；分目录 {'tools': 4}；不限制扩展名 [Q088](#q088)=4；完整/后缀片段 [Q089](#q089)=1。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q021](#q021)=1。
③ 原始 [Q090](#q090)=2；合同补查 [Q094](#q094)=16；原文 `data/numbers.yaml:99-118` [Q095](#q095)=20；`GDD.md:319-349` [Q096](#q096)=31。
④ [Q091](#q091)=1；仅 lib [Q092](#q092)=0；当前路径首次查询 [Q093](#q093)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:47 核验。

### `combat.final_damage_formula.apply_cultivation_multiplier`

① [Q097](#q097)=2；分目录 {'tools': 2}；不限制扩展名 [Q098](#q098)=2；完整/后缀片段 [Q099](#q099)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q024](#q024)=106。
③ 原始 [Q100](#q100)=1；合同补查 [Q094](#q094)=16；原文 `data/numbers.yaml:99-118` [Q095](#q095)=20；`GDD.md:319-349` [Q096](#q096)=31。
④ [Q101](#q101)=1；仅 lib [Q102](#q102)=0；当前路径首次查询 [Q103](#q103)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:52 核验。

### `combat.final_damage_formula.apply_school_counter`

① [Q104](#q104)=2；分目录 {'tools': 2}；不限制扩展名 [Q105](#q105)=2；完整/后缀片段 [Q106](#q106)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q024](#q024)=106。
③ 原始 [Q107](#q107)=1；合同补查 [Q094](#q094)=16；原文 `data/numbers.yaml:99-118` [Q095](#q095)=20；`GDD.md:319-349` [Q096](#q096)=31。
④ [Q108](#q108)=1；仅 lib [Q109](#q109)=0；当前路径首次查询 [Q110](#q110)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:53 核验。

### `combat.final_damage_formula.apply_critical`

① [Q111](#q111)=0；分目录 {}；不限制扩展名 [Q112](#q112)=0；完整/后缀片段 [Q113](#q113)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q024](#q024)=106。
③ 原始 [Q114](#q114)=1；合同补查 [Q094](#q094)=16；原文 `data/numbers.yaml:99-118` [Q095](#q095)=20；`GDD.md:319-349` [Q096](#q096)=31。
④ [Q115](#q115)=1；仅 lib [Q116](#q116)=0；当前路径首次查询 [Q117](#q117)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:54 核验。

### `combat.final_damage_formula.apply_defense`

① [Q118](#q118)=0；分目录 {}；不限制扩展名 [Q119](#q119)=0；完整/后缀片段 [Q120](#q120)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q024](#q024)=106。
③ 原始 [Q121](#q121)=1；合同补查 [Q094](#q094)=16；原文 `data/numbers.yaml:99-118` [Q095](#q095)=20；`GDD.md:319-349` [Q096](#q096)=31。
④ [Q122](#q122)=1；仅 lib [Q123](#q123)=0；当前路径首次查询 [Q124](#q124)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:55 核验。

### `combat.final_damage_formula.apply_realm_diff`

① [Q125](#q125)=0；分目录 {}；不限制扩展名 [Q126](#q126)=0；完整/后缀片段 [Q127](#q127)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q024](#q024)=106。
③ 原始 [Q128](#q128)=1；合同补查 [Q094](#q094)=16；原文 `data/numbers.yaml:99-118` [Q095](#q095)=20；`GDD.md:319-349` [Q096](#q096)=31。
④ [Q129](#q129)=1；仅 lib [Q130](#q130)=0；当前路径首次查询 [Q131](#q131)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:56 核验。

### `equipment.tiers[].tier_name`

① [Q132](#q132)=0；分目录 {}；不限制扩展名 [Q133](#q133)=0；完整/后缀片段 [Q134](#q134)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q135](#q135)=15；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q136](#q136)=1；仅 lib [Q137](#q137)=0；当前路径首次查询 [Q138](#q138)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:404,411,418,425,432,439,446 核验。

### `equipment.tiers[].weapon.attack_min`

① [Q142](#q142)=1；分目录 {'test': 1}；不限制扩展名 [Q143](#q143)=1；完整/后缀片段 [Q144](#q144)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q145](#q145)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q146](#q146)=1；仅 lib [Q147](#q147)=0；当前路径首次查询 [Q148](#q148)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:405,412,419,426,433,440,447 核验。

### `equipment.tiers[].weapon.hp_min`

① [Q149](#q149)=0；分目录 {}；不限制扩展名 [Q150](#q150)=0；完整/后缀片段 [Q151](#q151)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q152](#q152)=26；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q153](#q153)=1；仅 lib [Q154](#q154)=0；当前路径首次查询 [Q155](#q155)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:405,412,419,426,433,440,447 核验。

### `equipment.tiers[].weapon.speed_max`

① [Q156](#q156)=0；分目录 {}；不限制扩展名 [Q157](#q157)=0；完整/后缀片段 [Q158](#q158)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q159](#q159)=21；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q160](#q160)=1；仅 lib [Q161](#q161)=0；当前路径首次查询 [Q162](#q162)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:405,412,419,426,433,440,447 核验。

### `equipment.tiers[].weapon.speed_min`

① [Q163](#q163)=0；分目录 {}；不限制扩展名 [Q164](#q164)=0；完整/后缀片段 [Q165](#q165)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q166](#q166)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q167](#q167)=1；仅 lib [Q168](#q168)=0；当前路径首次查询 [Q169](#q169)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:405,412,419,426,433,440,447 核验。

### `equipment.tiers[].armor.attack_min`

① [Q142](#q142)=1；分目录 {'test': 1}；不限制扩展名 [Q143](#q143)=1；完整/后缀片段 [Q170](#q170)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q145](#q145)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q146](#q146)=1；仅 lib [Q147](#q147)=0；当前路径首次查询 [Q148](#q148)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:406,413,420,427,434,441,448 核验。

### `equipment.tiers[].armor.hp_min`

① [Q149](#q149)=0；分目录 {}；不限制扩展名 [Q150](#q150)=0；完整/后缀片段 [Q171](#q171)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q152](#q152)=26；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q153](#q153)=1；仅 lib [Q154](#q154)=0；当前路径首次查询 [Q155](#q155)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:406,413,420,427,434,441,448 核验。

### `equipment.tiers[].armor.speed_max`

① [Q156](#q156)=0；分目录 {}；不限制扩展名 [Q157](#q157)=0；完整/后缀片段 [Q172](#q172)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q159](#q159)=21；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q160](#q160)=1；仅 lib [Q161](#q161)=0；当前路径首次查询 [Q162](#q162)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:406,413,420,427,434,441,448 核验。

### `equipment.tiers[].armor.speed_min`

① [Q163](#q163)=0；分目录 {}；不限制扩展名 [Q164](#q164)=0；完整/后缀片段 [Q173](#q173)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q166](#q166)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q167](#q167)=1；仅 lib [Q168](#q168)=0；当前路径首次查询 [Q169](#q169)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:406,413,420,427,434,441,448 核验。

### `equipment.tiers[].accessory.attack_min`

① [Q142](#q142)=1；分目录 {'test': 1}；不限制扩展名 [Q143](#q143)=1；完整/后缀片段 [Q174](#q174)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q145](#q145)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q146](#q146)=1；仅 lib [Q147](#q147)=0；当前路径首次查询 [Q148](#q148)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:407,414,421,428,435,442,449 核验。

### `equipment.tiers[].accessory.hp_min`

① [Q149](#q149)=0；分目录 {}；不限制扩展名 [Q150](#q150)=0；完整/后缀片段 [Q175](#q175)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q152](#q152)=26；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q153](#q153)=1；仅 lib [Q154](#q154)=0；当前路径首次查询 [Q155](#q155)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:407,414,421,428,435,442,449 核验。

### `equipment.tiers[].accessory.speed_max`

① [Q156](#q156)=0；分目录 {}；不限制扩展名 [Q157](#q157)=0；完整/后缀片段 [Q176](#q176)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q159](#q159)=21；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q160](#q160)=1；仅 lib [Q161](#q161)=0；当前路径首次查询 [Q162](#q162)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:407,414,421,428,435,442,449 核验。

### `equipment.tiers[].accessory.speed_min`

① [Q163](#q163)=0；分目录 {}；不限制扩展名 [Q164](#q164)=0；完整/后缀片段 [Q177](#q177)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q166](#q166)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q167](#q167)=1；仅 lib [Q168](#q168)=0；当前路径首次查询 [Q169](#q169)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:407,414,421,428,435,442,449 核验。

### `equipment.enhancement.max_level_formula`

① [Q178](#q178)=1；分目录 {'tools': 1}；不限制扩展名 [Q179](#q179)=1；完整/后缀片段 [Q180](#q180)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q033](#q033)=22。
③ 原始 [Q181](#q181)=1；合同补查 [Q185](#q185)=1；原文 `GDD.md:429-429` [Q186](#q186)=1。
④ [Q182](#q182)=1；仅 lib [Q183](#q183)=0；当前路径首次查询 [Q184](#q184)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:454 核验。

### `equipment.enhancement.success_curve[].success_formula`

① [Q187](#q187)=0；分目录 {}；不限制扩展名 [Q188](#q188)=0；完整/后缀片段 [Q189](#q189)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q033](#q033)=22。
③ 原始 [Q190](#q190)=2；合同补查 [Q194](#q194)=9；原文 `GDD.md:431-445` [Q195](#q195)=15；`lib/data/numbers_config.dart:990-1010` [Q035](#q035)=21。
④ [Q191](#q191)=1；仅 lib [Q192](#q192)=0；当前路径首次查询 [Q193](#q193)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:476 核验。

### `equipment.resonance.new_owner_retention`

① [Q196](#q196)=4；分目录 {'tools': 4}；不限制扩展名 [Q197](#q197)=4；完整/后缀片段 [Q198](#q198)=1。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q039](#q039)=51。
③ 原始 [Q199](#q199)=2；合同补查 [Q203](#q203)=5；原文 `GDD.md:469-469` [Q204](#q204)=1；`data/numbers.yaml:832-837` [Q205](#q205)=6。
④ [Q200](#q200)=1；仅 lib [Q201](#q201)=0；当前路径首次查询 [Q202](#q202)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:537 核验。

### `techniques.tiers[].tier_name`

① [Q132](#q132)=0；分目录 {}；不限制扩展名 [Q133](#q133)=0；完整/后缀片段 [Q206](#q206)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q044](#q044)=45。
③ 原始 [Q135](#q135)=15；合同补查 [Q207](#q207)=9；原文 `GDD.md:170-180` [Q208](#q208)=11；`data_schema.md:180-190` [Q209](#q209)=11。
④ [Q136](#q136)=1；仅 lib [Q137](#q137)=0；当前路径首次查询 [Q138](#q138)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:586,592,598,604,610,616,622 核验。

### `skills.reference_multipliers.power_skill.tier_1_2_range[]`

① [Q210](#q210)=0；分目录 {}；不限制扩展名 [Q211](#q211)=0；完整/后缀片段 [Q212](#q212)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q213](#q213)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q214](#q214)=1；仅 lib [Q215](#q215)=0；当前路径首次查询 [Q216](#q216)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:711 核验。

### `skills.reference_multipliers.power_skill.tier_3_4_range[]`

① [Q219](#q219)=0；分目录 {}；不限制扩展名 [Q220](#q220)=0；完整/后缀片段 [Q221](#q221)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q222](#q222)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q223](#q223)=1；仅 lib [Q224](#q224)=0；当前路径首次查询 [Q225](#q225)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:712 核验。

### `skills.reference_multipliers.power_skill.tier_5_6_range[]`

① [Q226](#q226)=0；分目录 {}；不限制扩展名 [Q227](#q227)=0；完整/后缀片段 [Q228](#q228)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q229](#q229)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q230](#q230)=1；仅 lib [Q231](#q231)=0；当前路径首次查询 [Q232](#q232)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:713 核验。

### `skills.reference_multipliers.power_skill.tier_7_range[]`

① [Q233](#q233)=0；分目录 {}；不限制扩展名 [Q234](#q234)=0；完整/后缀片段 [Q235](#q235)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q236](#q236)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q237](#q237)=1；仅 lib [Q238](#q238)=0；当前路径首次查询 [Q239](#q239)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:714 核验。

### `skills.reference_multipliers.ultimate.tier_1_2_range[]`

① [Q210](#q210)=0；分目录 {}；不限制扩展名 [Q211](#q211)=0；完整/后缀片段 [Q240](#q240)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q213](#q213)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q214](#q214)=1；仅 lib [Q215](#q215)=0；当前路径首次查询 [Q216](#q216)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:716 核验。

### `skills.reference_multipliers.ultimate.tier_3_4_range[]`

① [Q219](#q219)=0；分目录 {}；不限制扩展名 [Q220](#q220)=0；完整/后缀片段 [Q241](#q241)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q222](#q222)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q223](#q223)=1；仅 lib [Q224](#q224)=0；当前路径首次查询 [Q225](#q225)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:717 核验。

### `skills.reference_multipliers.ultimate.tier_5_6_range[]`

① [Q226](#q226)=0；分目录 {}；不限制扩展名 [Q227](#q227)=0；完整/后缀片段 [Q242](#q242)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q229](#q229)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q230](#q230)=1；仅 lib [Q231](#q231)=0；当前路径首次查询 [Q232](#q232)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:718 核验。

### `skills.reference_multipliers.ultimate.tier_7_range[]`

① [Q233](#q233)=0；分目录 {}；不限制扩展名 [Q234](#q234)=0；完整/后缀片段 [Q243](#q243)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q047](#q047)=40。
③ 原始 [Q236](#q236)=2；合同补查 [Q217](#q217)=14；原文 `data/numbers.yaml:1051-1073` [Q218](#q218)=23。
④ [Q237](#q237)=1；仅 lib [Q238](#q238)=0；当前路径首次查询 [Q239](#q239)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:719 核验。

### `character.attributes.point_per_attribute_min`

① [Q244](#q244)=0；分目录 {}；不限制扩展名 [Q245](#q245)=0；完整/后缀片段 [Q246](#q246)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q247](#q247)=2；合同补查 [Q251](#q251)=8；原文 `CLAUDE.md:564-564` [Q252](#q252)=1；`docs/spec/rarity_wiring_gap_2026-08-07.md:115-121` [Q253](#q253)=7。
④ [Q248](#q248)=1；仅 lib [Q249](#q249)=0；当前路径首次查询 [Q250](#q250)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:733 核验。

### `character.attributes.point_per_attribute_max`

① [Q254](#q254)=0；分目录 {}；不限制扩展名 [Q255](#q255)=0；完整/后缀片段 [Q256](#q256)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q257](#q257)=2；合同补查 [Q251](#q251)=8；原文 `CLAUDE.md:564-564` [Q252](#q252)=1；`docs/spec/rarity_wiring_gap_2026-08-07.md:115-121` [Q253](#q253)=7。
④ [Q258](#q258)=1；仅 lib [Q259](#q259)=0；当前路径首次查询 [Q260](#q260)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:734 核验。

### `character.attributes.total_points_min`

① [Q261](#q261)=0；分目录 {}；不限制扩展名 [Q262](#q262)=0；完整/后缀片段 [Q263](#q263)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q264](#q264)=2；合同补查 [Q251](#q251)=8；原文 `CLAUDE.md:564-564` [Q252](#q252)=1；`docs/spec/rarity_wiring_gap_2026-08-07.md:115-121` [Q253](#q253)=7。
④ [Q265](#q265)=1；仅 lib [Q266](#q266)=0；当前路径首次查询 [Q267](#q267)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:735 核验。

### `character.attributes.total_points_max`

① [Q268](#q268)=0；分目录 {}；不限制扩展名 [Q269](#q269)=0；完整/后缀片段 [Q270](#q270)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q271](#q271)=1；合同补查 [Q251](#q251)=8；原文 `CLAUDE.md:564-564` [Q252](#q252)=1；`docs/spec/rarity_wiring_gap_2026-08-07.md:115-121` [Q253](#q253)=7。
④ [Q272](#q272)=1；仅 lib [Q273](#q273)=0；当前路径首次查询 [Q274](#q274)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:736 核验。

### `character.attributes.distribution_mean`

① [Q275](#q275)=0；分目录 {}；不限制扩展名 [Q276](#q276)=0；完整/后缀片段 [Q277](#q277)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q278](#q278)=2；合同补查 [Q282](#q282)=7；原文 `GDD.md:209-213` [Q283](#q283)=5；`CLAUDE.md:564-564` [Q252](#q252)=1；`data/numbers.yaml:1111-1114` [Q284](#q284)=4；`docs/spec/rarity_wiring_gap_2026-08-07.md:113-121` [Q285](#q285)=9。
④ [Q279](#q279)=1；仅 lib [Q280](#q280)=0；当前路径首次查询 [Q281](#q281)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:738 核验。

### `character.attributes.distribution_stddev`

① [Q286](#q286)=0；分目录 {}；不限制扩展名 [Q287](#q287)=0；完整/后缀片段 [Q288](#q288)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q289](#q289)=1；合同补查 [Q282](#q282)=7；原文 `GDD.md:209-213` [Q283](#q283)=5；`CLAUDE.md:564-564` [Q252](#q252)=1；`data/numbers.yaml:1111-1114` [Q284](#q284)=4；`docs/spec/rarity_wiring_gap_2026-08-07.md:113-121` [Q285](#q285)=9。
④ [Q290](#q290)=1；仅 lib [Q291](#q291)=0；当前路径首次查询 [Q292](#q292)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:739 核验。

### `character.attributes.rerollable`

① [Q293](#q293)=1；分目录 {'tools': 1}；不限制扩展名 [Q294](#q294)=1；完整/后缀片段 [Q295](#q295)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q296](#q296)=5；合同补查 [Q251](#q251)=8；原文 `CLAUDE.md:564-564` [Q252](#q252)=1；`docs/spec/rarity_wiring_gap_2026-08-07.md:115-121` [Q253](#q253)=7。
④ [Q297](#q297)=1；仅 lib [Q298](#q298)=0；当前路径首次查询 [Q299](#q299)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:740 核验。

### `character.adventure_attribute_bonus.bonus_per_event_min`

① [Q300](#q300)=0；分目录 {}；不限制扩展名 [Q301](#q301)=0；完整/后缀片段 [Q302](#q302)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q303](#q303)=3；合同补查 [Q307](#q307)=96；原文 `data/numbers.yaml:1140-1149` [Q308](#q308)=10。
④ [Q304](#q304)=2；仅 lib [Q305](#q305)=0；当前路径首次查询 [Q306](#q306)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:768 核验。

### `character.adventure_attribute_bonus.bonus_per_event_max`

① [Q309](#q309)=0；分目录 {}；不限制扩展名 [Q310](#q310)=0；完整/后缀片段 [Q311](#q311)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q052](#q052)=25。
③ 原始 [Q312](#q312)=2；合同补查 [Q307](#q307)=96；原文 `data/numbers.yaml:1140-1149` [Q308](#q308)=10。
④ [Q313](#q313)=1；仅 lib [Q314](#q314)=0；当前路径首次查询 [Q315](#q315)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:769 核验。

### `retreat.time_of_day_bonus[].time_range[]`

① [Q316](#q316)=2；分目录 {'tools': 2}；不限制扩展名 [Q317](#q317)=2；完整/后缀片段 [Q318](#q318)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q056](#q056)=20。
③ 原始 [Q319](#q319)=8；合同补查 [Q323](#q323)=14；原文 `data/numbers.yaml:1371-1388` [Q324](#q324)=18；`GDD.md:542-547` [Q325](#q325)=6。
④ [Q320](#q320)=2；仅 lib [Q321](#q321)=0；当前路径首次查询 [Q322](#q322)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:854,858 核验。

### `retreat.time_of_day_bonus[].time_range`

① [Q316](#q316)=2；分目录 {'tools': 2}；不限制扩展名 [Q317](#q317)=2；完整/后缀片段 [Q318](#q318)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q056](#q056)=20。
③ 原始 [Q319](#q319)=8；合同补查 [Q323](#q323)=14；原文 `data/numbers.yaml:1371-1388` [Q324](#q324)=18；`GDD.md:542-547` [Q325](#q325)=6。
④ [Q320](#q320)=2；仅 lib [Q321](#q321)=0；当前路径首次查询 [Q322](#q322)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:862 核验。

### `tower.daily_attempts`

① [Q326](#q326)=2；分目录 {'tools': 2}；不限制扩展名 [Q327](#q327)=2；完整/后缀片段 [Q328](#q328)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q329](#q329)=8；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q330](#q330)=2；仅 lib [Q331](#q331)=0；当前路径首次查询 [Q332](#q332)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:890 核验。

### `tower.refresh_at`

① [Q337](#q337)=2；分目录 {'tools': 2}；不限制扩展名 [Q338](#q338)=2；完整/后缀片段 [Q339](#q339)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q340](#q340)=5；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q341](#q341)=1；仅 lib [Q342](#q342)=0；当前路径首次查询 [Q343](#q343)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:891 核验。

### `tower.difficulty_curve[].difficulty_range[]`

① [Q344](#q344)=0；分目录 {}；不限制扩展名 [Q345](#q345)=0；完整/后缀片段 [Q346](#q346)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q347](#q347)=6；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q348](#q348)=1；仅 lib [Q349](#q349)=0；当前路径首次查询 [Q350](#q350)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:904,908,914,918,924,928 核验。

### `tower.difficulty_curve[].recommended_realm`

① [Q351](#q351)=0；分目录 {}；不限制扩展名 [Q352](#q352)=0；完整/后缀片段 [Q353](#q353)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q354](#q354)=7；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q355](#q355)=1；仅 lib [Q356](#q356)=0；当前路径首次查询 [Q357](#q357)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:906,910,916,920,926,930 核验。

### `tower.boss_layers.small_boss_layers[]`

① [Q358](#q358)=0；分目录 {}；不限制扩展名 [Q359](#q359)=0；完整/后缀片段 [Q360](#q360)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q361](#q361)=1；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q362](#q362)=1；仅 lib [Q363](#q363)=0；当前路径首次查询 [Q364](#q364)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:935 核验。

### `tower.boss_layers.big_boss_layers[]`

① [Q365](#q365)=0；分目录 {}；不限制扩展名 [Q366](#q366)=0；完整/后缀片段 [Q367](#q367)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q368](#q368)=1；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q369](#q369)=1；仅 lib [Q370](#q370)=0；当前路径首次查询 [Q371](#q371)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:936 核验。

### `tower.boss_layers.small_boss_multiplier`

① [Q372](#q372)=0；分目录 {}；不限制扩展名 [Q373](#q373)=0；完整/后缀片段 [Q374](#q374)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q375](#q375)=1；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q376](#q376)=1；仅 lib [Q377](#q377)=0；当前路径首次查询 [Q378](#q378)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:937 核验。

### `tower.boss_layers.big_boss_multiplier`

① [Q379](#q379)=0；分目录 {}；不限制扩展名 [Q380](#q380)=0；完整/后缀片段 [Q381](#q381)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q382](#q382)=1；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q383](#q383)=1；仅 lib [Q384](#q384)=0；当前路径首次查询 [Q385](#q385)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:938 核验。

### `tower.leaderboard.sync_to_supabase`

① [Q386](#q386)=2；分目录 {'tools': 2}；不限制扩展名 [Q387](#q387)=2；完整/后缀片段 [Q388](#q388)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q061](#q061)=57。
③ 原始 [Q389](#q389)=9；合同补查 [Q333](#q333)=9；原文 `GDD.md:603-607` [Q334](#q334)=5；`data_schema.md:1253-1255` [Q335](#q335)=3；`data/numbers.yaml:1487-1497` [Q336](#q336)=11。
④ [Q390](#q390)=1；仅 lib [Q391](#q391)=0；当前路径首次查询 [Q392](#q392)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:948 核验。

### `inheritance.unlock_rules.can_take_disciple_at`

① [Q393](#q393)=1；分目录 {'tools': 1}；不限制扩展名 [Q394](#q394)=1；完整/后缀片段 [Q395](#q395)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q066](#q066)=22。
③ 原始 [Q396](#q396)=6；合同补查 [Q400](#q400)=21；原文 `data/recruit_candidates.yaml:1-4` [Q401](#q401)=4；`GDD.md:499-505` [Q402](#q402)=7；`data/numbers.yaml:1565-1581` [Q403](#q403)=17。
④ [Q397](#q397)=2；仅 lib [Q398](#q398)=0；当前路径首次查询 [Q399](#q399)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:961 核验。

### `inheritance.unlock_rules.disciple_can_take_grand_disciple_at`

① [Q404](#q404)=1；分目录 {'tools': 1}；不限制扩展名 [Q405](#q405)=1；完整/后缀片段 [Q406](#q406)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q066](#q066)=22。
③ 原始 [Q407](#q407)=3；合同补查 [Q400](#q400)=21；原文 `data/recruit_candidates.yaml:1-4` [Q401](#q401)=4；`GDD.md:499-505` [Q402](#q402)=7；`data/numbers.yaml:1565-1581` [Q403](#q403)=17。
④ [Q408](#q408)=2；仅 lib [Q409](#q409)=0；当前路径首次查询 [Q410](#q410)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:962 核验。

### `inheritance.unlock_rules.can_pass_legacy_at`

① [Q411](#q411)=1；分目录 {'tools': 1}；不限制扩展名 [Q412](#q412)=1；完整/后缀片段 [Q413](#q413)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q066](#q066)=22。
③ 原始 [Q414](#q414)=3；合同补查 [Q418](#q418)=7；原文 `data/numbers.yaml:1574-1577` [Q419](#q419)=4；`data/numbers.yaml:1591-1600` [Q420](#q420)=10；`lib/data/numbers_config.dart:404-437` [Q421](#q421)=34；`lib/data/numbers_config.dart:807-833` [Q068](#q068)=27。
④ [Q415](#q415)=2；仅 lib [Q416](#q416)=0；当前路径首次查询 [Q417](#q417)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:963 核验。

### `inheritance.heritage_items.auto_buff_internal_force_max`

① [Q422](#q422)=1；分目录 {'tools': 1}；不限制扩展名 [Q423](#q423)=1；完整/后缀片段 [Q424](#q424)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q066](#q066)=22。
③ 原始 [Q425](#q425)=2；合同补查 [Q418](#q418)=7；原文 `data/numbers.yaml:1574-1577` [Q419](#q419)=4；`data/numbers.yaml:1591-1600` [Q420](#q420)=10；`lib/data/numbers_config.dart:404-437` [Q421](#q421)=34；`lib/data/numbers_config.dart:807-833` [Q068](#q068)=27。
④ [Q426](#q426)=1；仅 lib [Q427](#q427)=0；当前路径首次查询 [Q428](#q428)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:972 核验。

### `inheritance.heritage_items.resonance_retention`

① [Q429](#q429)=1；分目录 {'tools': 1}；不限制扩展名 [Q430](#q430)=1；完整/后缀片段 [Q431](#q431)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q066](#q066)=22。
③ 原始 [Q432](#q432)=3；合同补查 [Q418](#q418)=7；原文 `data/numbers.yaml:1574-1577` [Q419](#q419)=4；`data/numbers.yaml:1591-1600` [Q420](#q420)=10；`lib/data/numbers_config.dart:404-437` [Q421](#q421)=34；`lib/data/numbers_config.dart:807-833` [Q068](#q068)=27。
④ [Q433](#q433)=1；仅 lib [Q434](#q434)=0；当前路径首次查询 [Q435](#q435)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:973 核验。

### `synergies.effect_values.yin_yang_he.effect_type`

① [Q436](#q436)=0；分目录 {}；不限制扩展名 [Q437](#q437)=0；完整/后缀片段 [Q438](#q438)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q439](#q439)=5；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q440](#q440)=1；仅 lib [Q441](#q441)=0；当前路径首次查询 [Q442](#q442)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:990 核验。

### `synergies.effect_values.yin_yang_he.effect_value`

① [Q447](#q447)=0；分目录 {}；不限制扩展名 [Q448](#q448)=0；完整/后缀片段 [Q449](#q449)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q450](#q450)=9；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q451](#q451)=2；仅 lib [Q452](#q452)=0；当前路径首次查询 [Q453](#q453)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:991 核验。

### `synergies.effect_values.gai_bang_chuan_cheng.effect_type`

① [Q436](#q436)=0；分目录 {}；不限制扩展名 [Q437](#q437)=0；完整/后缀片段 [Q454](#q454)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q439](#q439)=5；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q440](#q440)=1；仅 lib [Q441](#q441)=0；当前路径首次查询 [Q442](#q442)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:995 核验。

### `synergies.effect_values.gai_bang_chuan_cheng.target_skill_id`

① [Q455](#q455)=0；分目录 {}；不限制扩展名 [Q456](#q456)=0；完整/后缀片段 [Q457](#q457)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q458](#q458)=1；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q459](#q459)=1；仅 lib [Q460](#q460)=0；当前路径首次查询 [Q461](#q461)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:996 核验。

### `synergies.effect_values.shao_lin_zheng_zong.effect_type`

① [Q436](#q436)=0；分目录 {}；不限制扩展名 [Q437](#q437)=0；完整/后缀片段 [Q462](#q462)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q439](#q439)=5；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q440](#q440)=1；仅 lib [Q441](#q441)=0；当前路径首次查询 [Q442](#q442)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1001 核验。

### `synergies.effect_values.shao_lin_zheng_zong.effect_value`

① [Q447](#q447)=0；分目录 {}；不限制扩展名 [Q448](#q448)=0；完整/后缀片段 [Q463](#q463)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q450](#q450)=9；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q451](#q451)=2；仅 lib [Q452](#q452)=0；当前路径首次查询 [Q453](#q453)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1002 核验。

### `synergies.effect_values.wu_dang_yuan_rong.effect_type`

① [Q436](#q436)=0；分目录 {}；不限制扩展名 [Q437](#q437)=0；完整/后缀片段 [Q464](#q464)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q439](#q439)=5；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q440](#q440)=1；仅 lib [Q441](#q441)=0；当前路径首次查询 [Q442](#q442)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1006 核验。

### `synergies.effect_values.wu_dang_yuan_rong.effect_value`

① [Q447](#q447)=0；分目录 {}；不限制扩展名 [Q448](#q448)=0；完整/后缀片段 [Q465](#q465)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q450](#q450)=9；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q451](#q451)=2；仅 lib [Q452](#q452)=0；当前路径首次查询 [Q453](#q453)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1007 核验。

### `synergies.effect_values.hua_shan_he_bi.effect_type`

① [Q436](#q436)=0；分目录 {}；不限制扩展名 [Q437](#q437)=0；完整/后缀片段 [Q466](#q466)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q439](#q439)=5；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q440](#q440)=1；仅 lib [Q441](#q441)=0；当前路径首次查询 [Q442](#q442)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1011 核验。

### `synergies.effect_values.hua_shan_he_bi.effect_value`

① [Q447](#q447)=0；分目录 {}；不限制扩展名 [Q448](#q448)=0；完整/后缀片段 [Q467](#q467)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q071](#q071)=10。
③ 原始 [Q450](#q450)=9；合同补查 [Q443](#q443)=30；原文 `GDD.md:272-282` [Q444](#q444)=11；`data_schema.md:1700-1705` [Q445](#q445)=6；`data/numbers.yaml:1623-1629` [Q446](#q446)=7。
④ [Q451](#q451)=2；仅 lib [Q452](#q452)=0；当前路径首次查询 [Q453](#q453)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1012 核验。

### `validation_examples.example_a.attacker.cultivation_multiplier`

① [Q468](#q468)=6；分目录 {'test': 2, 'tools': 4}；不限制扩展名 [Q469](#q469)=6；完整/后缀片段 [Q470](#q470)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q471](#q471)=17；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q472](#q472)=5；仅 lib [Q473](#q473)=3；当前路径首次查询 [Q474](#q474)=4；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1031 核验。

### `validation_examples.example_a.attacker.school_counter`

① [Q477](#q477)=8；分目录 {'tools': 8}；不限制扩展名 [Q478](#q478)=8；完整/后缀片段 [Q479](#q479)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q480](#q480)=11；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q481](#q481)=1；仅 lib [Q482](#q482)=0；当前路径首次查询 [Q483](#q483)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1032 核验。

### `validation_examples.example_a.calculated_damage`

① [Q484](#q484)=2；分目录 {'test': 2}；不限制扩展名 [Q485](#q485)=2；完整/后缀片段 [Q486](#q486)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q487](#q487)=7；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q488](#q488)=1；仅 lib [Q489](#q489)=0；当前路径首次查询 [Q490](#q490)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1038 核验。

### `validation_examples.example_a.expected_outcome`

① [Q491](#q491)=0；分目录 {}；不限制扩展名 [Q492](#q492)=0；完整/后缀片段 [Q493](#q493)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q494](#q494)=5；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q495](#q495)=1；仅 lib [Q496](#q496)=0；当前路径首次查询 [Q497](#q497)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1039 核验。

### `validation_examples.example_b.attacker.cultivation_multiplier`

① [Q468](#q468)=6；分目录 {'test': 2, 'tools': 4}；不限制扩展名 [Q469](#q469)=6；完整/后缀片段 [Q498](#q498)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q471](#q471)=17；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q472](#q472)=5；仅 lib [Q473](#q473)=3；当前路径首次查询 [Q474](#q474)=4；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1050 核验。

### `validation_examples.example_b.attacker.school_counter`

① [Q477](#q477)=8；分目录 {'tools': 8}；不限制扩展名 [Q478](#q478)=8；完整/后缀片段 [Q499](#q499)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q480](#q480)=11；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q481](#q481)=1；仅 lib [Q482](#q482)=0；当前路径首次查询 [Q483](#q483)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1051 核验。

### `validation_examples.example_b.calculated_damage`

① [Q484](#q484)=2；分目录 {'test': 2}；不限制扩展名 [Q485](#q485)=2；完整/后缀片段 [Q500](#q500)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q487](#q487)=7；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q488](#q488)=1；仅 lib [Q489](#q489)=0；当前路径首次查询 [Q490](#q490)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1057 核验。

### `validation_examples.example_b.expected_outcome`

① [Q491](#q491)=0；分目录 {}；不限制扩展名 [Q492](#q492)=0；完整/后缀片段 [Q501](#q501)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q494](#q494)=5；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q495](#q495)=1；仅 lib [Q496](#q496)=0；当前路径首次查询 [Q497](#q497)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1058 核验。

### `validation_examples.example_c.attacker.cultivation_multiplier`

① [Q468](#q468)=6；分目录 {'test': 2, 'tools': 4}；不限制扩展名 [Q469](#q469)=6；完整/后缀片段 [Q502](#q502)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q471](#q471)=17；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q472](#q472)=5；仅 lib [Q473](#q473)=3；当前路径首次查询 [Q474](#q474)=4；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1069 核验。

### `validation_examples.example_c.attacker.school_counter`

① [Q477](#q477)=8；分目录 {'tools': 8}；不限制扩展名 [Q478](#q478)=8；完整/后缀片段 [Q503](#q503)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q480](#q480)=11；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q481](#q481)=1；仅 lib [Q482](#q482)=0；当前路径首次查询 [Q483](#q483)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1070 核验。

### `validation_examples.example_c.attacker.realm_diff_modifier`

① [Q504](#q504)=0；分目录 {}；不限制扩展名 [Q505](#q505)=0；完整/后缀片段 [Q506](#q506)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q507](#q507)=2；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q508](#q508)=1；仅 lib [Q509](#q509)=0；当前路径首次查询 [Q510](#q510)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1072 核验。

### `validation_examples.example_c.calculated_damage`

① [Q484](#q484)=2；分目录 {'test': 2}；不限制扩展名 [Q485](#q485)=2；完整/后缀片段 [Q511](#q511)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q487](#q487)=7；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q488](#q488)=1；仅 lib [Q489](#q489)=0；当前路径首次查询 [Q490](#q490)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1077 核验。

### `validation_examples.example_c.expected_outcome`

① [Q491](#q491)=0；分目录 {}；不限制扩展名 [Q492](#q492)=0；完整/后缀片段 [Q512](#q512)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q494](#q494)=5；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q495](#q495)=1；仅 lib [Q496](#q496)=0；当前路径首次查询 [Q497](#q497)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1078 核验。

### `validation_examples.example_d.attacker.cultivation_multiplier`

① [Q468](#q468)=6；分目录 {'test': 2, 'tools': 4}；不限制扩展名 [Q469](#q469)=6；完整/后缀片段 [Q513](#q513)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q471](#q471)=17；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q472](#q472)=5；仅 lib [Q473](#q473)=3；当前路径首次查询 [Q474](#q474)=4；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1089 核验。

### `validation_examples.example_d.attacker.school_counter`

① [Q477](#q477)=8；分目录 {'tools': 8}；不限制扩展名 [Q478](#q478)=8；完整/后缀片段 [Q514](#q514)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q480](#q480)=11；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q481](#q481)=1；仅 lib [Q482](#q482)=0；当前路径首次查询 [Q483](#q483)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1090 核验。

### `validation_examples.example_d.calculated_damage`

① [Q484](#q484)=2；分目录 {'test': 2}；不限制扩展名 [Q485](#q485)=2；完整/后缀片段 [Q515](#q515)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q487](#q487)=7；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q488](#q488)=1；仅 lib [Q489](#q489)=0；当前路径首次查询 [Q490](#q490)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1096 核验。

### `validation_examples.example_d.expected_outcome`

① [Q491](#q491)=0；分目录 {}；不限制扩展名 [Q492](#q492)=0；完整/后缀片段 [Q516](#q516)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q494](#q494)=5；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q495](#q495)=1；仅 lib [Q496](#q496)=0；当前路径首次查询 [Q497](#q497)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1097 核验。

### `validation_examples.example_e.attacker.cultivation_multiplier`

① [Q468](#q468)=6；分目录 {'test': 2, 'tools': 4}；不限制扩展名 [Q469](#q469)=6；完整/后缀片段 [Q517](#q517)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q471](#q471)=17；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q472](#q472)=5；仅 lib [Q473](#q473)=3；当前路径首次查询 [Q474](#q474)=4；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1109 核验。

### `validation_examples.example_e.attacker.school_counter`

① [Q477](#q477)=8；分目录 {'tools': 8}；不限制扩展名 [Q478](#q478)=8；完整/后缀片段 [Q518](#q518)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q480](#q480)=11；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q481](#q481)=1；仅 lib [Q482](#q482)=0；当前路径首次查询 [Q483](#q483)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1110 核验。

### `validation_examples.example_e.expected_outcome`

① [Q491](#q491)=0；分目录 {}；不限制扩展名 [Q492](#q492)=0；完整/后缀片段 [Q519](#q519)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q074](#q074)=88。
③ 原始 [Q494](#q494)=5；合同补查 [Q475](#q475)=23；原文 `data/numbers.yaml:1661-1671` [Q476](#q476)=11。
④ [Q495](#q495)=1；仅 lib [Q496](#q496)=0；当前路径首次查询 [Q497](#q497)=1；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:1117 核验。

### `equipment.tiers[].weapon.attack_max`

① [Q522](#q522)=7；分目录 {'lib': 2, 'test': 3, 'tools': 2}；不限制扩展名 [Q523](#q523)=7；完整/后缀片段 [Q524](#q524)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q525](#q525)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q526](#q526)=3；仅 lib [Q527](#q527)=2；当前路径首次查询 [Q528](#q528)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:405,412,419,426,433,440,447 核验。

### `equipment.tiers[].armor.attack_max`

① [Q522](#q522)=7；分目录 {'lib': 2, 'test': 3, 'tools': 2}；不限制扩展名 [Q523](#q523)=7；完整/后缀片段 [Q529](#q529)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q525](#q525)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q526](#q526)=3；仅 lib [Q527](#q527)=2；当前路径首次查询 [Q528](#q528)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:406,413,420,427,434,441,448 核验。

### `equipment.tiers[].accessory.attack_max`

① [Q522](#q522)=7；分目录 {'lib': 2, 'test': 3, 'tools': 2}；不限制扩展名 [Q523](#q523)=7；完整/后缀片段 [Q530](#q530)=0。
② 公共 [Q001](#q001)=63、[Q002](#q002)=22、[Q003](#q003)=187、[Q004](#q004)=37；父级 [Q027](#q027)=119。
③ 原始 [Q525](#q525)=22；合同补查 [Q139](#q139)=27；原文 `data/equipment.yaml:1-10` [Q140](#q140)=10；`GDD.md:153-168` [Q141](#q141)=16。
④ [Q526](#q526)=3；仅 lib [Q527](#q527)=2；当前路径首次查询 [Q528](#q528)=2；原文件 [Q084](#q084)=1121，完整路径已在该提交的 data/numbers.yaml:407,414,421,428,435,442,449 核验。

## 附录：待人判池补捞（B2-3）

在 B2-2 READY 提交 `c579d0766159d4bf875295e1b573bad074750a97` 之后执行。筛选按 lib 末段精确字面量 0、同末段仅一个顶级段、该顶级段已有主体零引用；满足 28 路径 / 72 叶子，本次挑选并复核 3 路径 / 21 叶子，其余候选未扩审。正式四类计数完全不变。
三条均保留（有合同），不新增删除候选。lib 原文命中来自红线上限字段的同名后缀，解析的是另一路径；装备阶模板本身仍没有读取入口。补充排除：[Q520](#q520)=2；[Q521](#q521)=11。本附录不把有注释或子串命中的待人判条目提升为正式零引用。

| 归一路径 | 叶子数 | 值（多叶给首→尾） | YAML 行 | ①末段 / 路径 | ②公共 / 父级 | ③原始 / 合同（文件:行） | ④提交数 / lib 数；首次加入 | 建议 | 理由 |
|---|---:|---|---|---|---|---|---|---|---|
| `equipment.tiers[].weapon.attack_max` | 7 | 150 → 2000 | 682,689,696,703,710,719,728 | [Q522](#q522)=7 / [Q524](#q524)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q525](#q525)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q526](#q526)=3 / [Q527](#q527)=2；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].armor.attack_max` | 7 | 0 → 0 | 683,690,697,704,711,720,729 | [Q522](#q522)=7 / [Q529](#q529)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q525](#q525)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q526](#q526)=3 / [Q527](#q527)=2；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |
| `equipment.tiers[].accessory.attack_max` | 7 | 40 → 850 | 684,691,698,705,712,721,730 | [Q522](#q522)=7 / [Q530](#q530)=0 | [Q001](#q001)=63 / [Q027](#q027)=119 | [Q525](#q525)=22 / [Q139](#q139)=27；`data/equipment.yaml:7`; `data/equipment.yaml:14`; `data/equipment.yaml:15`; `data/equipment.yaml:17`; `data/equipment.yaml:18`; `data/equipment.yaml:24`; `data/equipment.yaml:109`; `data/equipment.yaml:280`; `data/equipment.yaml:546`; `data/equipment.yaml:641`; `data/equipment.yaml:739`; `data/equipment.yaml:935`; `data/equipment.yaml:1241`; `GDD.md:162`; `GDD.md:163`; `GDD.md:165`; `GDD.md:168`; `GDD.md:186`; `GDD.md:187`; `GDD.md:189`; `GDD.md:192`; `GDD.md:312`; `GDD.md:581`; `GDD.md:582`; `GDD.md:583`; `GDD.md:589`; `GDD.md:710` | [Q526](#q526)=3 / [Q527](#q527)=2；`fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4` | 保留（有合同） | 独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。 |

## 命令原文、命中数与完整结果

以下输出不截断。rg 退出 1 表示零命中，其他错误直接终止生成；sed 行号由命令及引用给出，git 输出为 commit 证据。含行尾空白的输出以 JSON 字符串数组逐行无损表示，避免把历史 patch 的空白变成本单补丁格式错误；命中数仍按原始输出计。

<a id="q001"></a>
### Q001

```sh
rg -n --with-filename --no-heading --sort path -- 'raw\[|\.raw\b|\.entries|\.keys|\.values|forEach\(' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：63；退出码：0。

```text
lib/data/numbers_config.dart:333:    required this.raw,
lib/data/numbers_config.dart:340:    final m = raw['milestone_equipment_grants'] as Map?;
lib/data/numbers_config.dart:547:      final tier = RealmTier.values.byName(t['tier'] as String);
lib/data/numbers_config.dart:556:      final tier = TechniqueTier.values.byName(t['tier'] as String);
lib/data/numbers_config.dart:568:      final layer = CultivationLayer.values.byName(l['layer'] as String);
lib/data/numbers_config.dart:580:      final fromLayer = CultivationLayer.values.byName(
lib/data/numbers_config.dart:595:          tier: RarityTier.values.byName((e as Map)['rarity'] as String),
lib/data/numbers_config.dart:626:          stage: ResonanceStage.values.byName(s['stage'] as String),
lib/data/numbers_config.dart:877:        : RealmTier.values.byName(realm['tier'] as String);
lib/data/numbers_config.dart:880:        : RealmLayer.values.byName(realm['layer'] as String);
lib/data/numbers_config.dart:1138:        ForgingSlotType.values.byName(t as String),
lib/data/numbers_config.dart:1142:      for (final e in bonusRaw.entries)
lib/data/numbers_config.dart:1143:        ForgingSlotType.values.byName(e.key): (e.value as num).toInt(),
lib/data/numbers_config.dart:1231:      final atk = TechniqueSchool.values.byName(r['attacker'] as String);
lib/data/numbers_config.dart:1232:      final t = TechniqueSchool.values.byName(r['target'] as String);
lib/data/numbers_config.dart:2222:  List<String> get segmentIds => List.unmodifiable(_segments.keys);
lib/data/numbers_config.dart:2240:    for (final entry in raw.entries) {
lib/data/numbers_config.dart:2268:    final attackRange = (raw['attack_range'] as num).toDouble();
lib/data/numbers_config.dart:2269:    final attackHalfArcRadians = (raw['attack_half_arc_radians'] as num)
lib/data/numbers_config.dart:2271:    final maxTargets = (raw['max_targets'] as num).toInt();
lib/data/numbers_config.dart:2272:    final advanceDistance = (raw['advance_distance'] as num).toDouble();
lib/data/numbers_config.dart:2273:    final aimAssistRadians = (raw['aim_assist_radians'] as num).toDouble();
lib/data/numbers_config.dart:2370:    }.entries) {
lib/data/numbers_config.dart:2915:      zhengWuAppliesToSchool: TechniqueSchool.values.byName(
lib/data/numbers_config.dart:2934:      if (row.values.any((value) => value < 0) ||
lib/data/numbers_config.dart:3031:      final festival = Festival.values.byName(entry['festival'] as String);
lib/data/numbers_config.dart:3227:/// 替原 `numbers.raw['sect_event']` dynamic map(沿 P3.4 spec §9 简化路径,
lib/data/numbers_config.dart:3665:    return TreasureDropConfig(minTier: EquipmentTier.values.byName(name));
lib/data/numbers_config.dart:3883:    for (final tableEntry in raw.entries) {
lib/data/numbers_config.dart:3887:      for (final cycleEntry in tableMap.entries) {
lib/data/numbers_config.dart:4073:    role: LineageRole.values.byName(y['role'] as String),
lib/data/game_repository.dart:134:  /// 从 `data/narratives/codex/<id>.md` 加载,id 由 [CodexIndex.entries] 登记。
lib/data/game_repository.dart:258:    for (final id in encounterSkills.keys) {
lib/data/game_repository.dart:264:    final encounterSkillIds = encounterSkills.keys.toSet();
lib/data/game_repository.dart:312:        for (final candidate in loaded.values) {
lib/data/game_repository.dart:339:        for (final candidate in loaded.values) {
lib/data/game_repository.dart:427:      for (final def in factionDefs.values) def.id: def.alignment,
lib/data/game_repository.dart:613:      for (final e in factionAlignments.entries)
lib/data/game_repository.dart:633:    for (final def in equipmentDefs.values) {
lib/data/game_repository.dart:670:    for (final def in encounterDefs.values) {
lib/data/game_repository.dart:712:    for (final entry in factionAlignments.entries) {
lib/data/game_repository.dart:722:      for (final s in stageDefs.values) {
lib/data/game_repository.dart:731:      for (final e in encounterDefs.values) {
lib/data/game_repository.dart:742:    for (final t in territoryDefs.values) {
lib/data/game_repository.dart:757:      final tier = RealmTier.values.byName(t['tier'] as String);
lib/data/game_repository.dart:758:      final eqCap = EquipmentTier.values.byName(
lib/data/game_repository.dart:761:      final techCap = TechniqueTier.values.byName(
lib/data/game_repository.dart:768:            layer: RealmLayer.values.byName(l['layer'] as String),
lib/data/game_repository.dart:830:    for (final s in stageDefs.values) {
lib/data/game_repository.dart:898:      existingStageIds: stageDefs.keys.toSet(),
lib/data/game_repository.dart:922:      equipmentIds: equipmentDefs.keys.toSet(),
lib/data/game_repository.dart:932:      skillDefs.keys.toSet(),
lib/data/game_repository.dart:943:    for (final s in stageDefs.values) {
lib/data/game_repository.dart:1058:      for (final entry in enemy.cycleBossPhases.entries) {
lib/data/game_repository.dart:1064:    for (final s in stages.values) {
lib/data/game_repository.dart:1093:    for (final s in stages.values) {
lib/data/game_repository.dart:1097:        for (final entry in mults.entries) {
lib/data/game_repository.dart:1113:        for (final entry in mults.entries) {
lib/data/game_repository.dart:1198:    final skillIdSet = skillDefs.keys.toSet();
lib/data/game_repository.dart:1210:    for (final teamEntry in config.enemyTeams.entries) {
lib/data/game_repository.dart:1248:          for (final ps in e.cycleBossPhases.values) ...ps,
lib/data/game_repository.dart:1305:    if (!schools.containsAll(TechniqueSchool.values)) {
lib/data/game_repository.dart:1421:    final list = encounterDefs.values.toList(growable: false);
```

<a id="q002"></a>
### Q002

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' -- '\.raw\b|raw\[|numbersRaw\b' lib
```

命中/输出行数：22；退出码：0。

```text
lib/data/combat_runtime_binding_loader.dart:416:    final map = _map(raw[i], '$sourceName.runtime_bindings[$index].$field[$i]');
lib/data/combat_runtime_binding_loader.dart:456:      raw[i],
lib/data/combat_runtime_binding_loader.dart:504:      raw[i],
lib/data/combat_runtime_binding_loader.dart:574:      raw[i],
lib/data/combat_runtime_binding_loader.dart:617:      raw[i],
lib/data/game_repository.dart:219:    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
lib/data/game_repository.dart:226:    final numbers = NumbersConfig.fromYaml(numbersRaw);
lib/data/game_repository.dart:227:    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
lib/data/numbers_config.dart:333:    required this.raw,
lib/data/numbers_config.dart:340:    final m = raw['milestone_equipment_grants'] as Map?;
lib/data/numbers_config.dart:2268:    final attackRange = (raw['attack_range'] as num).toDouble();
lib/data/numbers_config.dart:2269:    final attackHalfArcRadians = (raw['attack_half_arc_radians'] as num)
lib/data/numbers_config.dart:2271:    final maxTargets = (raw['max_targets'] as num).toInt();
lib/data/numbers_config.dart:2272:    final advanceDistance = (raw['advance_distance'] as num).toDouble();
lib/data/numbers_config.dart:2273:    final aimAssistRadians = (raw['aim_assist_radians'] as num).toDouble();
lib/data/numbers_config.dart:3227:/// 替原 `numbers.raw['sect_event']` dynamic map(沿 P3.4 spec §9 简化路径,
lib/features/debug/application/phase0a_debug_battle_fixture.dart:592:    final behavior = raw['phase0a_behavior'];
lib/features/debug/application/phase0a_debug_battle_fixture.dart:597:      type: SkillType.values.byName(raw['type'] as String),
lib/features/debug/application/phase0a_debug_battle_fixture.dart:606:      source: raw['source'] == null
lib/features/debug/application/phase0a_debug_battle_fixture.dart:608:          : SkillSource.values.byName(raw['source'] as String),
lib/features/debug/application/phase0a_debug_battle_fixture.dart:609:      targetType: raw['target_type'] == null
lib/features/debug/application/phase0a_debug_battle_fixture.dart:611:          : TargetType.values.byName(raw['target_type'] as String),
```

<a id="q003"></a>
### Q003

```sh
rg -n --with-filename --no-heading --sort path -- '\$\{|\$[a-zA-Z_]|\.join\(|\[[a-zA-Z_]\w*\]|_requireKeys' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：187；退出码：0。

```text
lib/data/numbers_config.dart:23:/// Phase 1 仅强类型化战斗会用到的 [combat] 与 [levelDiffModifier]，
lib/data/numbers_config.dart:25:/// inheritance / synergies / validation_examples）保留 [raw] 原始 Map，
lib/data/numbers_config.dart:51:  /// 单独按 [RealmTier] 索引）。
lib/data/numbers_config.dart:89:  /// 顺序：生疏 → 趁手 → 默契 → 心剑通灵；最后一段 [maxBattleCount] 为 null（无上限）。
lib/data/numbers_config.dart:121:  /// [multiDiscipleAllocation]=player_pick 走 UI 玩家分配 + [stackAcrossGenerations]=false
lib/data/numbers_config.dart:229:  /// [rarityForTotalPoints] 派生,不得在创建点写死(2026-08-07 N1:此前三处
lib/data/numbers_config.dart:265:  /// 开局单人，弟子按主线关卡节点拜入。空段兜底 [LineageOnboardingConfig]（discipleJoins 空）。
lib/data/numbers_config.dart:337:  /// `milestone_equipment_grants` 段)。从 [raw] 读,缺段兜底空 map。
lib/data/numbers_config.dart:548:      m[tier] = (t['defense_rate'] as num).toDouble();
lib/data/numbers_config.dart:557:      m[tier] = (t['speed_bonus'] as num).toInt();
lib/data/numbers_config.dart:569:      m[layer] = (l['bonus_multiplier'] as num).toDouble();
lib/data/numbers_config.dart:583:      m[fromLayer] = (e['progress_required'] as num).toInt();
lib/data/numbers_config.dart:589:  /// [rarityForTotalPoints] 退化为 §5.4 default 兜底。
lib/data/numbers_config.dart:608:  /// [rarityTiers] 为空(fixture 未配该段)时兜底 [RarityTier.biaoZhun]。
lib/data/numbers_config.dart:768:///   - [transferTrigger] = "ascend_to_wusheng":仅本批触发(non-trigger 路径不传)
lib/data/numbers_config.dart:769:///   - [multiDiscipleAllocation] = "player_pick":玩家逐件选 disciple(UI 下拉)
lib/data/numbers_config.dart:770:///   - [stackAcrossGenerations] = false:不累代叠加(derived_stats §244 按
lib/data/numbers_config.dart:773:///   - [conflictSlotResolution] = "auto_swap":P5+ 真实装(AscendService.performAscend
lib/data/numbers_config.dart:778:///   - [piecesPerGenerationMin] = 1 / [piecesPerGenerationMax] = 2:每代传 1-2 件
lib/data/numbers_config.dart:839:/// [clearedStagesRequired] 空 + [requiredRealmTier]/[requiredRealmLayer] null
lib/data/numbers_config.dart:893:///   - [successCurve]：成功率 + 失败惩罚（按 targetLevel 区间）
lib/data/numbers_config.dart:894:///   - [mojianshiCost]：每次强化消耗（按 targetLevel 区间）
lib/data/numbers_config.dart:895:///   - [crystalGuarantees]：心血结晶保底消耗（按 targetLevel 区间，部分段无保底）
lib/data/numbers_config.dart:897:/// `successRate == null` 表示该段走 [_fallbackFormula]（GDD +20-49 段
lib/data/numbers_config.dart:942:  /// 取 [targetLevel]（=enhanceLevel + 1）的成功率。yaml `success_rate: null`
lib/data/numbers_config.dart:943:  /// 段走 [_fallbackFormula]（+20-49 段公式）。
lib/data/numbers_config.dart:949:  /// 取 [targetLevel] 的失败惩罚类型。
lib/data/numbers_config.dart:953:  /// 取 [targetLevel] 的磨剑石消耗。
lib/data/numbers_config.dart:960:    throw StateError('mojianshi_cost 缺少 targetLevel=$targetLevel 的覆盖区间');
lib/data/numbers_config.dart:963:  /// 取 [targetLevel] 的锻材附加消耗。老 fixture 没有 `duancai_cost` 时为 0。
lib/data/numbers_config.dart:971:    throw StateError('duancai_cost 缺少 targetLevel=$targetLevel 的覆盖区间');
lib/data/numbers_config.dart:974:  /// 取 [targetLevel] 的心血结晶保底消耗，null 表示该段无保底（+1-13）。
lib/data/numbers_config.dart:991:    throw StateError('success_curve 缺少 targetLevel=$targetLevel 的覆盖区间');
lib/data/numbers_config.dart:1043:        throw StateError('未知 material_penalty: $s');
lib/data/numbers_config.dart:1107:  /// 按 [slotIndex]（1/2/3）取槽配置。越界抛 [StateError]。
lib/data/numbers_config.dart:1112:    throw StateError('ForgingConfig 缺少 slotIndex=$slotIndex 的配置');
lib/data/numbers_config.dart:1186:/// - attacker 克 defender → [counter]（1.25）
lib/data/numbers_config.dart:1187:/// - attacker 被 defender 克 → [countered]（0.75）
lib/data/numbers_config.dart:1188:/// - 同流派或非克制关系 → [neutral]（1.00）
lib/data/numbers_config.dart:1193:  /// `_counterTarget[A] == B` 表示 A 单向克制 B。
lib/data/numbers_config.dart:1196:  /// `_extraEffect[A]` 是 A 触发克制时附带的额外效果字符串（如 `extra_quake_dmg`）。
lib/data/numbers_config.dart:1233:      tgt[atk] = t;
lib/data/numbers_config.dart:1234:      eff[atk] = r['extra_effect'] as String;
lib/data/numbers_config.dart:1255:    if (_counterTarget[attacker] == defender) return counter;
lib/data/numbers_config.dart:1256:    if (_counterTarget[defender] == attacker) return countered;
lib/data/numbers_config.dart:1262:    if (_counterTarget[attacker] == defender) return _extraEffect[attacker];
lib/data/numbers_config.dart:1482:  final value = yaml[key];
lib/data/numbers_config.dart:1484:    throw StateError('combat.posture.$key must be a finite number');
lib/data/numbers_config.dart:1490:  final value = yaml[key];
lib/data/numbers_config.dart:1492:    throw StateError('combat.posture.$key must be an integer');
lib/data/numbers_config.dart:1586:      throw StateError('combat.qi 配置越界: $y');
lib/data/numbers_config.dart:1659:      throw StateError('conditions.inner_breath_disorder 配置越界: $y');
lib/data/numbers_config.dart:1764:/// 当前 Phase0A 生产 reducer 不消费 [windowTicks];per-skill
lib/data/numbers_config.dart:1956:/// 敌人不持装备/心法，[EnemyDef] → BattleCharacter 时这些字段用统一默认；
lib/data/numbers_config.dart:2146:      final value = moves[key];
lib/data/numbers_config.dart:2227:    final tuning = _segments[segmentId];
lib/data/numbers_config.dart:2229:      throw StateError('missing basic attack segment tuning: $segmentId');
lib/data/numbers_config.dart:2246:      segments[id] = Phase0aBasicAttackSegmentTuning.fromYaml(value);
lib/data/numbers_config.dart:2372:        throw StateError('phase0a_arena.defense ${entry.key} 越界');
lib/data/numbers_config.dart:2577:/// 所有时间单位 ms，位移单位逻辑像素。提供 [defaults] 常量供测试和 fallback 使用。
lib/data/numbers_config.dart:2613:  /// [fastForwardIntervalMs] 快进，本字段只是两场之间喘口气的短停。
lib/data/numbers_config.dart:2674:  /// 飘字有效时长:不超过当前播放拍间隔 [intervalMs],防快档(rapid/快进)下
lib/data/numbers_config.dart:2675:  /// 固定 [damagePopupMs](1000)> 拍长致跨拍重叠。慢档(1000 ≤ 拍长)返回原值,
lib/data/numbers_config.dart:2748:/// Demo 阶段统一固定值，按 [TechniqueRole] 区分主修 / 辅修。领悟点来源待
lib/data/numbers_config.dart:2763:  /// 按 [role] 取消耗。
lib/data/numbers_config.dart:2930:      final row = weights[i];
lib/data/numbers_config.dart:2963:  /// 仅闭关经验产出用；银两/材料/心法/内力仍走 [realmScaleFor]。
lib/data/numbers_config.dart:3014:/// [festivalOn] 永远返回 null（无任何节日触发），不破坏既有 fixture。
lib/data/numbers_config.dart:3400:/// 4 子段聚合:[memberCap](Q2=C member 上限沿 sectLevel)+
lib/data/numbers_config.dart:3401:/// [rankPromoteThreshold](Q5=A 三阶单向阈值)+ [recruit](Q6=D 三维 trigger 概率)+
lib/data/numbers_config.dart:3402:/// [territory](Q4=A territory cap)。fixture / 老存档 yaml 无 `sect_management`
lib/data/numbers_config.dart:3403:/// 段时走 [empty] 兜底,数值与 yaml 默认值同(不破任何运行时行为)。
lib/data/numbers_config.dart:3611:      if (stages[i].minUses <= stages[i - 1].minUses) {
lib/data/numbers_config.dart:3614:      if (stages[i].damageMult < stages[i - 1].damageMult) {
lib/data/numbers_config.dart:3804:/// [traitsFor] 纯函数（无 I/O），根据 (cycle, isBoss, isTower) 查 assignment 表
lib/data/numbers_config.dart:3828:  /// assignment 表：`{ tableKey → { cycle → [traitId] } }`。
lib/data/numbers_config.dart:3895:        cycleMap[cycleKey] = traitList;
lib/data/numbers_config.dart:3897:      result[tableKey] = cycleMap;
lib/data/numbers_config.dart:3916:    return _assignment[tableKey]?[cycle] ?? const {};
lib/data/numbers_config.dart:3925:/// [tiersFor] 后 clamp 武圣，带动敌内力派生 / 防御率档 / 境界差修正三轴。
lib/data/numbers_config.dart:4009:      throw ArgumentError('passive_idle 数值非法: $y');
lib/data/numbers_config.dart:4036:    double pct(String k) => (y[k] as num).toDouble();
lib/data/numbers_config.dart:4043:      throw ArgumentError('battle_report 阈值须在 (0,1]: $y');
lib/data/game_repository.dart:52:/// 红线校验在 [loadAllDefs] 末尾执行；任何越界（装备攻击 > 2000、
lib/data/game_repository.dart:53:/// 内力上限不在 [500, 15000]）直接抛 [StateError]，启动失败。
lib/data/game_repository.dart:57:  /// 已初始化的全局实例。未调用 [loadAllDefs] 直接访问会抛 [StateError]。
lib/data/game_repository.dart:79:  /// 爬塔全部层，按 floorIndex 升序（1..[towerMaxFloor]）。
lib/data/game_repository.dart:94:  /// 索引方式：`masters[slotIndex]`（红线校验保证 0-2 连续唯一）。
lib/data/game_repository.dart:117:  /// events 文案走 [EncounterEventLoader] 按需 load(narrative_loader 体例)。
lib/data/game_repository.dart:121:  /// 与 [skillDefs] 共享 runtime 类型 [SkillDef],但通过此 set 可快速筛
lib/data/game_repository.dart:123:  /// `skillDefs[id]!.isEncounterSkill` 等价判断。
lib/data/game_repository.dart:204:  /// [loader] 可注入：生产用 [rootBundle.loadString]，测试可传内存字符串
lib/data/game_repository.dart:260:        throw StateError('encounter_skills.yaml 与 skills.yaml id 冲突: $id');
lib/data/game_repository.dart:557:        throw FormatException('Failed to load $assetPath: $e');
lib/data/game_repository.dart:576:      throw FormatException('Failed to parse $assetPath: $e');
lib/data/game_repository.dart:591:          '$assetPath id=$id startingTechniqueIds references missing '
lib/data/game_repository.dart:592:          'data/techniques.yaml id=$techniqueId',
lib/data/game_repository.dart:599:          '$assetPath id=$id startingEquipmentIds references missing '
lib/data/game_repository.dart:600:          'data/equipment.yaml id=$equipmentId',
lib/data/game_repository.dart:606:  /// 查 [factionId] 的对立阵营所有 faction id。
lib/data/game_repository.dart:609:    final alignment = factionAlignments[factionId];
lib/data/game_repository.dart:638:            '装备 ${def.id} presetLoreIds 引用 $loreId,'
lib/data/game_repository.dart:639:            'data/lore/$loreId.yaml 缺失或解析失败',
lib/data/game_repository.dart:644:            '装备 ${def.id} presetLore $loreId yaml 内 id=${content.id} 不自洽',
lib/data/game_repository.dart:648:          throw StateError('装备 ${def.id} presetLore $loreId default_lore 段为空');
lib/data/game_repository.dart:655:  /// [_validatePresetLoreReferences] 体例,兑现 GDD §8.1「任一端缺失直接抛错」)。
lib/data/game_repository.dart:657:  /// 对每条 [EncounterDef] await [EncounterEventLoader.load]:
lib/data/game_repository.dart:674:          'encounter ${def.id} 缺 data/events/${def.id}.yaml 或解析失败 (GDD §8.1)',
lib/data/game_repository.dart:679:          'encounter ${def.id} events yaml 内 id=${content.id} 不自洽 (GDD §8.1)',
lib/data/game_repository.dart:686:            'encounter ${def.id} events choice outcome_id="${choice.outcomeId}" '
lib/data/game_repository.dart:701:  /// **graceful**:test fixture 不带 factions.yaml 时 [factionAlignments] 空 →
lib/data/game_repository.dart:715:          'faction ${entry.key} alignment="${entry.value}" 非法'
lib/data/game_repository.dart:726:            'stage ${s.id} factionId="$fid" 不在 factions.yaml,'
lib/data/game_repository.dart:735:            'encounter ${e.id} affectsReputation.factionId="$fid" '
lib/data/game_repository.dart:745:          'territory ${t.id} baseDefenseLevel=${t.baseDefenseLevel} '
lib/data/game_repository.dart:752:  /// 把 numbers.yaml 嵌套的 `realms.tiers[].layers[]` 展平为 49 行 [RealmDef]。
lib/data/game_repository.dart:791:        throw StateError('重复 def id: $id');
lib/data/game_repository.dart:793:      m[id] = def;
lib/data/game_repository.dart:801:      throw StateError('RealmDef 行数应为 49，实际 ${realms.length}');
lib/data/game_repository.dart:809:          '红线越界：${r.tier.name}/${r.layer.name} '
lib/data/game_repository.dart:810:          'internalForceMax=${r.internalForceMax}，应 ∈ [500, $ifMax]',
lib/data/game_repository.dart:833:      final prevDef = stageDefs[prev];
lib/data/game_repository.dart:835:        throw StateError('stage ${s.id} prevStageId=$prev 引用不存在的关卡');
lib/data/game_repository.dart:841:          'stage ${s.id} (ch=${s.chapterIndex}) 与 prevStageId=$prev '
lib/data/game_repository.dart:842:          '(ch=${prevDef.chapterIndex}) 跨章引用',
lib/data/game_repository.dart:944:      enforceGuardianWardReferences(s.enemyTeam, location: 'stage ${s.id} ');
lib/data/game_repository.dart:949:        location: 'tower floor ${f.floorIndex} ',
lib/data/game_repository.dart:1027:  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配置了
lib/data/game_repository.dart:1029:  /// 中的每个 id 须在 [skillIdSet] 内存在。
lib/data/game_repository.dart:1044:              '$label bossPhase hpThresholdPct='
lib/data/game_repository.dart:1045:              '${phase.hpThresholdPct} unlockSkillIds 引用 $sid '
lib/data/game_repository.dart:1059:        checkPhases(phases: entry.value, label: '$label cycle ${entry.key}');
lib/data/game_repository.dart:1066:        checkEnemy(enemy: e, label: 'stage ${s.id} enemy ${e.id}');
lib/data/game_repository.dart:1074:          label: 'tower floor ${f.floorIndex} enemy ${e.id}',
lib/data/game_repository.dart:1082:  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配了
lib/data/game_repository.dart:1084:  /// 乘子 ∈ [[minMult], [maxMult]]，越界 throw 含敌人 id + 流派 + 值。
lib/data/game_repository.dart:1085:  /// 静态方法便于单元测试独立调用（沿 [enforceBossPhaseSkillIds] 体例）。
lib/data/game_repository.dart:1101:              'stage ${s.id} 敌人 ${e.id} schoolDamageTakenMult '
lib/data/game_repository.dart:1102:              '${entry.key.name}=$v 越界，应 ∈ [$minMult, $maxMult]（批二②红线）',
lib/data/game_repository.dart:1117:              'tower floor ${f.floorIndex} 敌人 ${e.id} schoolDamageTakenMult '
lib/data/game_repository.dart:1118:              '${entry.key.name}=$v 越界，应 ∈ [$minMult, $maxMult]（批二②红线）',
lib/data/game_repository.dart:1129:  ///   - [EquipmentDrop.equipmentDefId] 必须在 [equipmentIds]
lib/data/game_repository.dart:1136:  /// [_enforceRedLines] 启动期统一调用。
lib/data/game_repository.dart:1150:  /// [enforceWeaknessRedLines] 体例);[location] 非空时前缀进 StateError 便于定位
lib/data/game_repository.dart:1151:  /// (如 `'stage foo '` / `'tower floor 30 '`),启动期 [_enforceRedLines] 传入。
lib/data/game_repository.dart:1161:        throw StateError('$location敌人 ${e.id} guardianWard.guardianIds 为空');
lib/data/game_repository.dart:1165:          '$location敌人 ${e.id} guardianWard.damageTakenMult='
lib/data/game_repository.dart:1166:          '${w.damageTakenMult} 越界(须 ∈ (0,1])',
lib/data/game_repository.dart:1172:            '$location敌人 ${e.id} guardianWard 引用自身 $gid'
lib/data/game_repository.dart:1178:            '$location敌人 ${e.id} guardianWard 引用 $gid 不在本队 enemyTeam',
lib/data/game_repository.dart:1193:  ///   ⑤ guardianWard 引用完整性/值域/自引用（复用 [enforceGuardianWardReferences]）。
lib/data/game_repository.dart:1204:          'boss_gauntlets: 关次 enemy_team_id=${stage.enemyTeamId} '
lib/data/game_repository.dart:1213:      final loc = 'boss_gauntlets team $teamId ';
lib/data/game_repository.dart:1218:            '$loc敌人 ${e.id} baseHp=${e.baseHp} 越界 '
lib/data/game_repository.dart:1219:            '(cap=${redLines.bossHpMax})',
lib/data/game_repository.dart:1225:            '$loc敌人 ${e.id} baseAttack=${e.baseAttack} 越界 '
lib/data/game_repository.dart:1226:            '(cap=${redLines.equipmentBaseAttackMax})',
lib/data/game_repository.dart:1230:          throw StateError('$loc敌人 ${e.id} baseSpeed 必须为正');
lib/data/game_repository.dart:1235:            throw StateError('$loc敌人 ${e.id} skillId=$sid 未在 skills.yaml 存在');
lib/data/game_repository.dart:1242:            '$loc敌人 ${e.id} chargeSkillId=$cs 不在其 skillIds（破招红线①）',
lib/data/game_repository.dart:1253:                '$loc敌人 ${e.id} bossPhase unlockSkillIds 引用 $sid '
lib/data/game_repository.dart:1269:        '${config.firstClearRewardSkillId} 未在 skills.yaml 存在（§8.2 引用悬空）',
lib/data/game_repository.dart:1275:          'boss_gauntlets: reward_candidate_equipment_id=$eqId '
lib/data/game_repository.dart:1295:        'hp=${curve.hpValueCap}/${redLines.bossHpMax} '
lib/data/game_repository.dart:1296:        'attack=${curve.attackValueCap}/${redLines.equipmentBaseAttackMax}',
lib/data/game_repository.dart:1310:        throw StateError('expeditions: ${enemy.id} baseHp 越界 ${enemy.baseHp}');
lib/data/game_repository.dart:1314:          'expeditions: ${enemy.id} baseAttack 越界 ${enemy.baseAttack}',
lib/data/game_repository.dart:1318:        throw StateError('expeditions: ${enemy.id} skillIds 不得为空');
lib/data/game_repository.dart:1321:        final skill = skillDefs[skillId];
lib/data/game_repository.dart:1324:            'expeditions: ${enemy.id} skillId=$skillId 未在 skills.yaml 存在',
lib/data/game_repository.dart:1329:            'expeditions: ${enemy.id} school=${enemy.school.name} '
lib/data/game_repository.dart:1330:            '与 skillId=$skillId style=${skill.style?.name} 不一致',
lib/data/game_repository.dart:1349:      orElse: () => throw StateError('境界 ${tier.name}/${layer.name} 未配置'),
lib/data/game_repository.dart:1355:      throw RangeError('absoluteLevel 必须 ∈ [1, 49]，实际 $level');
lib/data/game_repository.dart:1361:      equipmentDefs[defId] ?? (throw StateError('EquipmentDef 未配置: $defId'));
lib/data/game_repository.dart:1364:      techniqueDefs[defId] ?? (throw StateError('TechniqueDef 未配置: $defId'));
lib/data/game_repository.dart:1367:      skillDefs[defId] ?? (throw StateError('SkillDef 未配置: $defId'));
lib/data/game_repository.dart:1370:      stageDefs[defId] ?? (throw StateError('StageDef 未配置: $defId'));
lib/data/game_repository.dart:1372:  /// 取第 N 层爬塔（1..[towerMaxFloor]）。越界抛 [RangeError]。
lib/data/game_repository.dart:1375:      throw RangeError('爬塔 floorIndex 必须 ∈ [1, $towerMaxFloor]，实际 $floorIndex');
lib/data/game_repository.dart:1380:  /// 按地图类型取闭关地图定义。未配置时抛 [StateError]。
lib/data/game_repository.dart:1384:        orElse: () => throw StateError('SeclusionMapDef 未配置: ${mapType.name}'),
lib/data/game_repository.dart:1388:  /// 越界抛 [RangeError]。
lib/data/game_repository.dart:1391:      throw RangeError('师徒 slotIndex 必须 ∈ [0, 2]，实际 $slotIndex');
lib/data/game_repository.dart:1393:    return masters[slotIndex];
lib/data/game_repository.dart:1400:  EncounterDef? findEncounter(String id) => encounterDefs[id];
lib/data/game_repository.dart:1428:    final list = encounterSkillIds.map((id) => skillDefs[id]!).toList();
```

<a id="q004"></a>
### Q004

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' -- 'loadTestNumbersSection|path.split|red_lines|deepConvertYaml|extract_leaves' lib/data/yaml_loader.dart test tools/audit/q2_leaf_extract.py tools/audit/run_all.py
```

命中/输出行数：37；退出码：0。

```text
lib/data/yaml_loader.dart:8:dynamic deepConvertYaml(dynamic v) {
lib/data/yaml_loader.dart:12:        (e) => MapEntry(e.key.toString(), deepConvertYaml(e.value)),
lib/data/yaml_loader.dart:17:    return v.map(deepConvertYaml).toList();
lib/data/yaml_loader.dart:25:  final converted = deepConvertYaml(doc);
lib/data/yaml_loader.dart:33:  final converted = deepConvertYaml(doc);
test/data/animation_numbers_test.dart:26:      ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:49:      ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:80:      ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:99:      ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:126:      ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:151:      ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:183:        ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:206:        ...loadTestNumbersSection(['animation']),
test/data/animation_numbers_test.dart:239:      final yaml = loadTestNumbersSection(['animation'])..remove(key);
test/data/defense_break_schema_test.dart:53:      loadTestNumbersSection(['combat', 'defense_break']),
test/data/founder_school_uniqueness_redline_test.dart:4:import 'package:wuxia_idle/data/validation/lineage_recruit_red_lines_validator.dart';
test/data/hit_tier_config_test.dart:21:      loadTestNumbersSection(['animation', 'hit_tier']),
test/data/hit_tier_config_test.dart:34:      final yaml = loadTestNumbersSection(['animation', 'hit_tier'])
test/data/lineage_onboarding_redline_test.dart:4:import 'package:wuxia_idle/data/validation/lineage_recruit_red_lines_validator.dart';
test/data/milestone_grants_config_test.dart:7:/// 沿 numbers_config_red_lines_test 体例：loadAllDefs 真 numbers.yaml 后断言。
test/data/numbers_config_red_lines_test.dart:68:    test('R3 combat.red_lines 与 §5.4 红线一致(drift guard)', () {
test/data/numbers_config_required_keys_test.dart:10:    deepConvertYaml(loadYaml(File('data/numbers.yaml').readAsStringSync()))
test/data/numbers_config_required_keys_test.dart:117:  for (final segment in path.split('.')..removeLast()) {
test/data/numbers_config_required_keys_test.dart:132:    ((deepConvertYaml(loadYaml(File('data/stages.yaml').readAsStringSync()))
test/data/numbers_config_required_keys_test.dart:139:  final redLines = (production['combat'] as Map)['red_lines'] as Map;
test/data/numbers_config_required_keys_test.dart:165:    test('缺少 combat.red_lines.$key 时拒绝加载并报告路径', () {
test/data/numbers_config_required_keys_test.dart:167:      ((copy['combat'] as Map)['red_lines'] as Map).remove(key);
test/data/numbers_config_required_keys_test.dart:174:            contains('combat.red_lines.$key'),
test/data/numbers_config_required_keys_test.dart:185:        _containingMaps(copy, path)[index].remove(path.split('.').last);
test/data/skill_source_redline_test.dart:9:import 'package:wuxia_idle/data/validation/skill_red_lines_validator.dart';
test/data/validation/strict_red_lines_test.dart:6:import 'package:wuxia_idle/data/validation/economy_codex_red_lines_validator.dart';
test/data/validation/strict_red_lines_test.dart:7:import 'package:wuxia_idle/data/validation/encounter_red_lines_validator.dart';
test/data/validation/strict_red_lines_test.dart:8:import 'package:wuxia_idle/data/validation/lineage_recruit_red_lines_validator.dart';
test/data/validation/strict_red_lines_test.dart:9:import 'package:wuxia_idle/data/validation/progression_red_lines_validator.dart';
test/data/validation/strict_red_lines_test.dart:10:import 'package:wuxia_idle/data/validation/technique_equipment_red_lines_validator.dart';
test/features/tower/application/tower_progress_summary_test.dart:31:  // progression_red_lines_validator);顶层与里程碑断言从生产数据派生不写死。
test/support/test_data.dart:9:Map<String, dynamic> loadTestNumbersSection(List<String> path) {
```

<a id="q005"></a>
### Q005

```sh
sed -n 345,542p lib/data/numbers_config.dart
```

命中/输出行数：198；退出码：0。

```text
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
    final meta = y['meta'] as Map<String, dynamic>;
    final combat = y['combat'] as Map<String, dynamic>;
    final realms = y['realms'] as Map<String, dynamic>;
    final equipment = y['equipment'] as Map<String, dynamic>;
    final techniques = y['techniques'] as Map<String, dynamic>;

    return NumbersConfig(
      version: meta['version'] as String,
      combat: CombatNumbers.fromYaml(combat),
      attributeEffects: AttributeEffectRules.fromYaml(
        (y['attribute_effects'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      innerBreathDisorder: InnerBreathDisorderConfig.fromYaml(
        ((y['conditions'] as Map?)?['inner_breath_disorder'] as Map?)
                ?.cast<String, dynamic>() ??
            const {},
      ),
      skillProficiency: SkillProficiencyConfig.fromYaml(
        combat['skill_proficiency'] as Map<String, dynamic>?,
      ),
      skillUnlock: SkillUnlockConfig.fromYaml(
        (y['skill_unlock'] as Map?)?.cast<String, dynamic>(),
      ),
      treasureDrop: TreasureDropConfig.fromYaml(
        (y['treasure_drop'] as Map?)?.cast<String, dynamic>(),
      ),
      levelDiffModifier: LevelDiffModifier.fromYaml(
        realms['level_diff_modifier'] as Map<String, dynamic>,
      ),
      defenseRateByTier: _parseDefenseRates(realms['tiers'] as List),
      enhancementBonusPerLevel:
          ((equipment['enhancement'] as Map<String, dynamic>)['bonus_per_level']
                  as num)
              .toDouble(),
      enhancement: EnhancementConfig.fromYaml(
        enhancement: equipment['enhancement'] as Map<String, dynamic>,
        xinxueJiejing: equipment['xinxue_jiejing'] as Map<String, dynamic>,
      ),
      forging: ForgingConfig.fromYaml(
        equipment['forging'] as Map<String, dynamic>,
      ),
      techniqueSpeedBonus: _parseTechniqueSpeedBonus(
        techniques['tiers'] as List,
      ),
      cultivationMultiplier: _parseCultivationMultiplier(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      cultivationProgressToNext: _parseCultivationProgressToNext(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      insightToCultivationRatio:
          ((techniques['cultivation']
                      as Map<String, dynamic>)['insight_to_cultivation_ratio']
                  as num)
              .toDouble(),
      schoolCounter: SchoolCounterMatrix.fromYaml(
        techniques['schools'] as Map<String, dynamic>,
      ),
      resonanceStages: _parseResonanceStages(
        equipment['resonance'] as Map<String, dynamic>,
      ),
      resonanceInheritanceRetention:
          ((equipment['resonance']
                      as Map<String, dynamic>)['inheritance_retention']
                  as num)
              .toDouble(),
      resonanceSeclusionBattleCountPerHour:
          ((equipment['resonance']
                      as Map<
                        String,
                        dynamic
                      >)['seclusion_battle_count_per_hour']
                  as num)
              .toInt(),
      lineageInternalForceMaxBonus:
          ((equipment['lineage_heritage']
                      as Map<String, dynamic>)['internal_force_max_bonus']
                  as num)
              .toDouble(),
      disposal: EquipmentDisposalConfig.fromYaml(
        equipment['disposal'] as Map<String, dynamic>,
      ),
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['founder_ancestor_buff']
                as Map<String, dynamic>?) ??
            const {},
      ),
      heritageItems: HeritageItems.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['heritage_items']
                as Map<String, dynamic>?) ??
            const {},
      ),
      ascension: AscensionConfig.fromYaml(
        y['ascension'] as Map<String, dynamic>?,
      ),
      dispersionCultivationPenalty:
          ((techniques['dispersion']
                      as Map<String, dynamic>)['cultivation_penalty']
                  as num)
              .toDouble(),
      defeatBossCultivationPenalty:
          ((techniques['defeat']
                      as Map<String, dynamic>)['boss_cultivation_penalty']
                  as num)
              .toDouble(),
      learningCost: LearningCostConfig.fromYaml(
        techniques['learning_cost'] as Map<String, dynamic>,
      ),
      animation: AnimationNumbers.fromYaml(
        y['animation'] as Map<String, dynamic>,
      ),
      retreat: RetreatConfig.fromYaml(y['retreat'] as Map<String, dynamic>),
      festivals: FestivalConfig.fromYaml(
        y['festivals'] as Map<String, dynamic>?,
      ),
      rareBonusDrop: RareBonusDropConfig.fromYaml(
        (y['rare_bonus_drop'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      cycleDropBonus: CycleDropBonusConfig.fromYaml(
        (y['cycle_drop_bonus'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      injury: InjuryConfig.fromYaml(
        (y['injury'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      innerDemon: InnerDemonDef.fromYaml(
        y['inner_demon'] as Map<String, dynamic>?,
      ),
      progressionReleaseCap: ProgressionReleaseCap.fromYaml(
        (y['progression'] as Map?)?.cast<String, dynamic>(),
      ),
      lightFoot: LightFootDef.fromYaml(
        y['light_foot'] as Map<String, dynamic>?,
      ),
      massBattle: MassBattleDef.fromYaml(
        y['mass_battle'] as Map<String, dynamic>?,
      ),
      mainlineWave: MainlineWaveDef.fromYaml(
        y['mainline_wave'] as Map<String, dynamic>?,
      ),
      jianghu: JianghuConfig.fromYaml(y['jianghu'] as Map<String, dynamic>?),
      sectEvent: SectEventDef.fromYaml(
        y['sect_event'] as Map<String, dynamic>?,
      ),
      sectManagement: SectManagementConfig.fromYaml(
        y['sect_management'] as Map<String, dynamic>?,
      ),
      adventureAttributeLifetimeCap:
          (((y['character']
                          as Map<
                            String,
                            dynamic
                          >?)?['adventure_attribute_bonus']
                      as Map<String, dynamic>?)?['lifetime_cap_per_character']
                  as num?)
              ?.toInt() ??
          _missingRequiredValue(
            'character.adventure_attribute_bonus.lifetime_cap_per_character',
          ),
      rarityTiers: _parseRarityTiers(
        (y['character'] as Map<String, dynamic>?)?['rarity_distribution']
            as List?,
      ),
      loadoutUltimatePowerThreshold:
          ((y['skill_loadout']
                      as Map<String, dynamic>?)?['ultimate_power_threshold']
                  as num?)
              ?.toInt() ??
          _missingRequiredValue('skill_loadout.ultimate_power_threshold'),
      cycleEvolution: CycleEvolutionConfig.fromYaml(
        y['cycle_evolution'] as Map<String, dynamic>?,
      ),
      passiveIdle: PassiveIdleConfig.fromYaml(
        y['passive_idle'] as Map<String, dynamic>,
      ),
      sweepReadiness: SweepReadinessConfig.fromYaml(
        (y['sweep_readiness'] as Map?)?.cast<String, dynamic>(),
      ),
      taohuaIsland: TaohuaIslandConfig.fromYaml(
        (y['taohua_island'] as Map).cast<String, dynamic>(),
      ),
      battleReport: BattleReportConfig.fromYaml(
        y['battle_report'] as Map<String, dynamic>,
      ),
      heroCamera: HeroCameraConfig.fromYaml(
        ((y['post_battle'] as Map?)?.cast<String, dynamic>()['hero_camera']
                as Map?)
            ?.cast<String, dynamic>(),
      ),
      lineageOnboarding: LineageOnboardingConfig.fromYaml(
        y['lineage_onboarding'] as Map<String, dynamic>?,
      ),
      phase0aArena: Phase0aArenaConfig.fromYaml(
        (y['phase0a_arena'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      raw: y,
    );
  }
```

<a id="q006"></a>
### Q006

```sh
sed -n 8,19p lib/data/yaml_loader.dart
```

命中/输出行数：12；退出码：0。

```text
dynamic deepConvertYaml(dynamic v) {
  if (v is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      v.entries.map(
        (e) => MapEntry(e.key.toString(), deepConvertYaml(e.value)),
      ),
    );
  }
  if (v is YamlList) {
    return v.map(deepConvertYaml).toList();
  }
  return v;
```

<a id="q007"></a>
### Q007

```sh
sed -n 1,18p test/support/test_data.dart
```

命中/输出行数：18；退出码：0。

```text
import 'dart:io';

import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';

Future<String> loadTestAsset(String path) => File(path).readAsString();

/// 从生产数值表读取完整子段，测试仅覆盖自身需要变化的字段。
Map<String, dynamic> loadTestNumbersSection(List<String> path) {
  var section = parseYamlMap(File('data/numbers.yaml').readAsStringSync());
  for (final key in path) {
    section = Map<String, dynamic>.from(section[key] as Map);
  }
  return section;
}

Future<GameRepository> loadTestGameRepository() async {
  if (GameRepository.isLoaded) return GameRepository.instance;
```

<a id="q008"></a>
### Q008

```sh
sed -n 113,130p test/data/numbers_config_required_keys_test.dart
```

命中/输出行数：18；退出码：0。

```text
  Map<String, dynamic> root,
  String path,
) {
  var maps = <Map<String, dynamic>>[root];
  for (final segment in path.split('.')..removeLast()) {
    if (segment.endsWith('[]')) {
      final key = segment.substring(0, segment.length - 2);
      maps = [
        for (final map in maps)
          for (final entry in map[key] as List) entry as Map<String, dynamic>,
      ];
    } else {
      maps = [for (final map in maps) map[segment] as Map<String, dynamic>];
    }
  }
  return maps;
}
```

<a id="q009"></a>
### Q009

```sh
sed -n 22,70p tools/audit/q2_leaf_extract.py
```

命中/输出行数：49；退出码：0。

```text
def extract(path):
    """Yield (dotted_path, value, line_no) for scalar leaf keys in a YAML file."""
    stack = []  # list of (indent, key)
    leaves = []
    with open(path, encoding='utf-8') as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip('\n')
            stripped = line.strip()
            # skip blanks, comments, list items we handle loosely
            if not stripped or stripped.startswith('#'):
                continue
            indent = len(line) - len(line.lstrip(' '))
            # pop stack to current indent
            while stack and stack[-1][0] >= indent:
                stack.pop()
            # key: value
            m = re.match(r'^([^:#]+?):\s*(.*)$', stripped)
            if m:
                key = m.group(1).strip().strip('"\'')
                val = m.group(2).strip()
                path_ = '.'.join([k for _, k in stack] + [key])
                if val == '' or val.startswith('#'):
                    # branch node
                    stack.append((indent, key))
                else:
                    # leaf (could still be a list item value handled elsewhere)
                    # strip trailing comment
                    v = re.split(r'\s+#', val)[0].strip()
                    leaves.append((path_, v, lineno))
                continue
            # list item
            m2 = re.match(r'^-\s*(.*)$', stripped)
            if m2:
                content = m2.group(1).strip()
                # list item that is "key: value" inline
                m3 = re.match(r'^([^:#]+?):\s*(.*)$', content)
                parent = '.'.join([k for _, k in stack])
                if m3:
                    key = m3.group(1).strip().strip('"\'')
                    val = m3.group(2).strip()
                    v = re.split(r'\s+#', val)[0].strip()
                    leaves.append((f"{parent}[].{key}" if parent else f"[].{key}", v, lineno))
                else:
                    v = re.split(r'\s+#', content)[0].strip()
                    parent = '.'.join([k for _, k in stack])
                    leaves.append((f"{parent}[]" if parent else "[]", v, lineno))
    return leaves
```

<a id="q010"></a>
### Q010

```sh
sed -n 69,76p tools/audit/run_all.py
```

命中/输出行数：8；退出码：0。

```text
        if f.endswith('.yaml'))
    leaves_total = 0
    numbers_leaves = 0
    for y in yamls:
        n = len(q2_leaf_extract.extract(os.path.join(ROOT, y)))
        leaves_total += n
        if y.endswith('numbers.yaml'):
            numbers_leaves = n
```

<a id="q011"></a>
### Q011

```sh
git show --format=fuller --no-ext-diff --no-color fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 -- data/numbers.yaml
```

命中/输出行数：1146；退出码：0。

```json
[
  "commit fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Sun May 10 16:01:11 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Sun May 10 16:01:11 2026 +0800",
  "",
  "    [T01] 项目初始化与依赖配置",
  "    ",
  "    - flutter create macos+windows 平台（包名 wuxia_idle / org com.pen.wuxia）",
  "    - 依赖：Riverpod 2.5 / Isar 3.1 / yaml / intl 等",
  "    - numbers.yaml 移到 data/，pubspec 把 data/ 直接声明为 asset",
  "    - .gitignore 调整：去 *.lock 通配（保留 pubspec.lock），加 *.g.dart 不入库",
  "    - 砍 riverpod_lint（与 isar_generator 3.x 在 analyzer 版本互斥）",
  "    - 新增 PROGRESS.md 跟踪 Phase 1 进度与挂账事项",
  "    ",
  "    验收：flutter analyze 0 issues / flutter test 通过 / build_runner 跑通",
  "    ",
  "    Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>",
  "",
  "diff --git a/data/numbers.yaml b/data/numbers.yaml",
  "new file mode 100644",
  "index 000000000..c141800cd",
  "--- /dev/null",
  "+++ b/data/numbers.yaml",
  "@@ -0,0 +1,1121 @@",
  "+# =============================================================================",
  "+# numbers.yaml · 武侠挂机游戏数值总配置",
  "+# =============================================================================",
  "+#",
  "+# 文档地位：本文件包含所有可调数值。所有 Dart 代码不得硬编码数值，必须通过",
  "+#          GameRepository 从本文件加载。改数值不动代码、不动存档结构。",
  "+#",
  "+# 遵循文档：GDD.md v1.1、data_schema.md v1.1",
  "+# 维护者：Mac 端 Claude Code + Opus 4.7",
  "+#",
  "+# =============================================================================",
  "+# 重要：GDD 公式口误标注",
  "+# =============================================================================",
  "+#",
  "+# GDD §5.3 写\"装备攻击 × 8\"、§5.6 写\"内力 × 5\"，按字面公式会突破 §5.2",
  "+# 数值红线（伤害破万、武圣血量超 80000）。本文件采用经过平衡的系数：",
  "+#",
  "+#   装备攻击系数：1.0（GDD 字面值 8.0，平衡后调为 1.0）",
  "+#   内力血量系数：0.7（GDD 字面值 5.0，平衡后调为 0.7）",
  "+#",
  "+# 战例验证（二流·圆熟同境界普通攻击对决）：",
  "+#   GDD 字面公式：基础伤害 6340，最终 11095（破红线）",
  "+#   平衡后公式：基础伤害 2280，最终 3990（在 2000-8000 区间）✓",
  "+#",
  "+# =============================================================================",
  "+",
  "+meta:",
  "+  version: \"0.1.0\"             # 与 SaveData.saveVersion 对应；major.minor.patch",
  "+  description: \"Demo 阶段数值配置 · 覆盖学徒到武圣全程\"",
  "+  last_updated: \"2026-05-10\"",
  "+  notes: \"所有数值基于 GDD v1.1 §5.2 数值红线设计；公式系数见 combat 段\"",
  "+",
  "+# =============================================================================",
  "+# 1. 战斗公式系数",
  "+# =============================================================================",
  "+# 对应 GDD §5.3 / §5.4 / §5.6 三大公式。所有系数提取为可调参数，便于未来",
  "+# 整体平衡调整。",
  "+",
  "+combat:",
  "+",
  "+  # --- 基础伤害公式 ---",
  "+  # GDD §5.3：基础伤害 = (内力 × 0.4) + (装备攻击 × 8) + 招式倍率",
  "+  # 平衡后：    基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率",
  "+  damage_formula:",
  "+    internal_force_factor: 0.4       # 内力对伤害的系数（GDD 原值，未变）",
  "+    equipment_attack_factor: 1.0     # 装备攻击系数（GDD 原写 8，平衡后调为 1.0）",
  "+    skill_multiplier_added: true     # 招式倍率作为加项（不是乘项）",
  "+",
  "+  # --- 最终伤害公式（GDD §5.4）---",
  "+  # 最终伤害 = 基础伤害 × 修炼度加成 × 流派克制 × 暴击系数 × (1-防御率) × 境界差修正",
  "+  final_damage_formula:",
  "+    apply_cultivation_multiplier: true   # 应用心法修炼度（1.0~3.0）",
  "+    apply_school_counter: true           # 应用流派克制（0.75/1.0/1.25）",
  "+    apply_critical: true                 # 应用暴击（1.0 或 1.5~2.5）",
  "+    apply_defense: true                  # 应用防御率（1 - defense_rate）",
  "+    apply_realm_diff: true               # 应用境界差修正",
  "+",
  "+  # --- 最大血量公式 ---",
  "+  # GDD §5.6：血量 = 1000 + 内力 × 5 + 根骨 × 500 + 装备血量",
  "+  # 平衡后：   血量 = 1000 + 内力 × 0.7 + 根骨 × 500 + 装备血量",
  "+  # 设计目标：武圣·登峰满根骨 ≤ 20000（§5.2 玩家血量上限）",
  "+  max_hp_formula:",
  "+    base: 1000                       # 基础血量（GDD 原值）",
  "+    internal_force_factor: 0.7       # 内力系数（GDD 原写 5，平衡后调为 0.7）",
  "+    constitution_factor: 500         # 根骨系数（GDD 原值，每点 +500）",
  "+",
  "+  # --- 出手速度公式（GDD §5.6 原值，无需调整）---",
  "+  # 速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成",
  "+  speed_formula:",
  "+    base: 100",
  "+    agility_factor: 8",
  "+",
  "+  # --- 暴击率与暴击伤害 ---",
  "+  # 暴击率主要由身法和心法决定，灵巧流派额外 +20%（GDD §4.4）",
  "+  critical:",
  "+    base_rate: 0.05                  # 基础暴击率 5%",
  "+    agility_per_point_rate: 0.005    # 每点身法 +0.5% 暴击率",
  "+    max_rate: 0.50                   # 暴击率硬上限 50%",
  "+    base_damage_multiplier: 1.5      # 暴击伤害基础倍率",
  "+    max_damage_multiplier: 2.5       # 暴击伤害最高倍率（堆心法/装备后）",
  "+",
  "+  # --- 闪避率（由身法决定，与速度共享身法属性）---",
  "+  evasion:",
  "+    agility_per_point_rate: 0.003    # 每点身法 +0.3% 闪避率",
  "+    max_rate: 0.30                   # 闪避率硬上限 30%",
  "+",
  "+# =============================================================================",
  "+# 2. 49 级境界系统",
  "+# =============================================================================",
  "+# GDD §3.1：7 个大境界 × 7 层 = 49 级",
  "+# 关键约束：内力 500-15000（§5.2 红线）、装备/心法品阶随境界开放（§3.4）",
  "+",
  "+realms:",
  "+",
  "+  # --- 境界差距修正（GDD §5.5，强制规则不可调）---",
  "+  # 表中数字均从\"高境界视角\"看：你打对方时的伤害修正 / 对方打你时的伤害修正",
  "+  level_diff_modifier:",
  "+    same_tier:           # 同大境界",
  "+      attacker: 1.0",
  "+      defender: 1.0",
  "+    diff_1_tier:         # 差 1 大境界（你高对方低）",
  "+      attacker: 1.4      # 你打对方：×1.4",
  "+      defender: 0.7      # 对方打你：×0.7",
  "+    diff_2_tier:         # 差 2 大境界",
  "+      attacker: 2.5",
  "+      defender: 0.3",
  "+    diff_3_or_more:      # 差 3+ 大境界（基本免疫）",
  "+      attacker: null     # 已经是碾压，无需再放大；按 ×2.5 上限处理即可",
  "+      defender: 0.05     # 低境界打高境界仅 5% 伤害",
  "+",
  "+  # --- 49 级境界完整数值表 ---",
  "+  # 字段说明：",
  "+  #   absolute_level   : 总层数 1-49（强化等级上限 = 该值）",
  "+  #   internal_force_max: 该层内力上限（决定基础属性）",
  "+  #   experience_to_next: 突破到下一层所需经验",
  "+  #   defense_rate     : 该大境界基础防御率（同大境界内 7 层共用）",
  "+  #",
  "+  # 设计曲线：",
  "+  #   - 内力线性递增到一流，绝顶以上加速",
  "+  #   - 经验呈指数递增（每境界总经验约为前一境界 3-5 倍）",
  "+  #   - 总经验跨度 ~7,600,000（足够支撑数十至上百小时游戏时长）",
  "+",
  "+  tiers:",
  "+",
  "+    # === 学徒（1-7）：学武起步 ===",
  "+    # 防御率 5%，可用装备：寻常货，可修心法：入门功",
  "+    - tier: xueTu",
  "+      defense_rate: 0.05",
  "+      equipment_tier_cap: xunChang",
  "+      technique_tier_cap: ruMenGong",
  "+      layers:",
  "+        - layer: qiMeng    # 1 启蒙",
  "+          absolute_level: 1",
  "+          internal_force_max: 500",
  "+          experience_to_next: 50",
  "+        - layer: ruMen     # 2 入门",
  "+          absolute_level: 2",
  "+          internal_force_max: 600",
  "+          experience_to_next: 80",
  "+        - layer: shuLian   # 3 熟练",
  "+          absolute_level: 3",
  "+          internal_force_max: 700",
  "+          experience_to_next: 120",
  "+        - layer: jingTong  # 4 精通",
  "+          absolute_level: 4",
  "+          internal_force_max: 800",
  "+          experience_to_next: 170",
  "+        - layer: yuanShu   # 5 圆熟",
  "+          absolute_level: 5",
  "+          internal_force_max: 900",
  "+          experience_to_next: 230",
  "+        - layer: huaJing   # 6 化境",
  "+          absolute_level: 6",
  "+          internal_force_max: 1000",
  "+          experience_to_next: 300",
  "+        - layer: dengFeng  # 7 登峰",
  "+          absolute_level: 7",
  "+          internal_force_max: 1100",
  "+          experience_to_next: 400  # 突破到三流·启蒙",
  "+",
  "+    # === 三流（8-14）：江湖小卒 ===",
  "+    # 防御率 10%，装备升级到像样货，心法升级到常练功",
  "+    - tier: sanLiu",
  "+      defense_rate: 0.10",
  "+      equipment_tier_cap: xiangYang",
  "+      technique_tier_cap: changLianGong",
  "+      layers:",
  "+        - layer: qiMeng",
  "+          absolute_level: 8",
  "+          internal_force_max: 1200",
  "+          experience_to_next: 500",
  "+        - layer: ruMen",
  "+          absolute_level: 9",
  "+          internal_force_max: 1330",
  "+          experience_to_next: 700",
  "+        - layer: shuLian",
  "+          absolute_level: 10",
  "+          internal_force_max: 1460",
  "+          experience_to_next: 950",
  "+        - layer: jingTong",
  "+          absolute_level: 11",
  "+          internal_force_max: 1600",
  "+          experience_to_next: 1250",
  "+        - layer: yuanShu",
  "+          absolute_level: 12",
  "+          internal_force_max: 1740",
  "+          experience_to_next: 1600",
  "+        - layer: huaJing",
  "+          absolute_level: 13",
  "+          internal_force_max: 1870",
  "+          experience_to_next: 2000",
  "+        - layer: dengFeng",
  "+          absolute_level: 14",
  "+          internal_force_max: 2000",
  "+          experience_to_next: 2500  # 突破到二流·启蒙",
  "+",
  "+    # === 二流（15-21）：一方好手 ===",
  "+    # 防御率 15%，装备升级到好家伙，心法升级到名家功",
  "+    - tier: erLiu",
  "+      defense_rate: 0.15",
  "+      equipment_tier_cap: haoJiaHuo",
  "+      technique_tier_cap: mingJiaGong",
  "+      layers:",
  "+        - layer: qiMeng",
  "+          absolute_level: 15",
  "+          internal_force_max: 2200",
  "+          experience_to_next: 3000",
  "+        - layer: ruMen",
  "+          absolute_level: 16",
  "+          internal_force_max: 2400",
  "+          experience_to_next: 3700",
  "+        - layer: shuLian",
  "+          absolute_level: 17",
  "+          internal_force_max: 2600",
  "+          experience_to_next: 4500",
  "+        - layer: jingTong",
  "+          absolute_level: 18",
  "+          internal_force_max: 2800",
  "+          experience_to_next: 5500",
  "+        - layer: yuanShu",
  "+          absolute_level: 19",
  "+          internal_force_max: 3000",
  "+          experience_to_next: 6700",
  "+        - layer: huaJing",
  "+          absolute_level: 20",
  "+          internal_force_max: 3200",
  "+          experience_to_next: 8000",
  "+        - layer: dengFeng",
  "+          absolute_level: 21",
  "+          internal_force_max: 3500",
  "+          experience_to_next: 9500  # 突破到一流·启蒙",
  "+",
  "+    # === 一流（22-28）：名门高手 · Demo 主线终点 ===",
  "+    # 防御率 20%，装备升级到利器，心法升级到门派绝学",
  "+    - tier: yiLiu",
  "+      defense_rate: 0.20",
  "+      equipment_tier_cap: liQi",
  "+      technique_tier_cap: menPaiJueXue",
  "+      layers:",
  "+        - layer: qiMeng",
  "+          absolute_level: 22",
  "+          internal_force_max: 3800",
  "+          experience_to_next: 11000",
  "+        - layer: ruMen",
  "+          absolute_level: 23",
  "+          internal_force_max: 4100",
  "+          experience_to_next: 13000",
  "+        - layer: shuLian",
  "+          absolute_level: 24",
  "+          internal_force_max: 4400",
  "+          experience_to_next: 15500",
  "+        - layer: jingTong",
  "+          absolute_level: 25",
  "+          internal_force_max: 4700",
  "+          experience_to_next: 18500",
  "+        - layer: yuanShu",
  "+          absolute_level: 26",
  "+          internal_force_max: 5000",
  "+          experience_to_next: 22000",
  "+        - layer: huaJing",
  "+          absolute_level: 27",
  "+          internal_force_max: 5300",
  "+          experience_to_next: 26000",
  "+        - layer: dengFeng",
  "+          absolute_level: 28",
  "+          internal_force_max: 5700",
  "+          experience_to_next: 30000  # 突破到绝顶·启蒙",
  "+",
  "+    # === 绝顶（29-35）：当世高手 ===",
  "+    # 防御率 25%，装备升级到重器，心法升级到江湖秘传",
  "+    - tier: jueDing",
  "+      defense_rate: 0.25",
  "+      equipment_tier_cap: zhongQi",
  "+      technique_tier_cap: jiangHuMiChuan",
  "+      layers:",
  "+        - layer: qiMeng",
  "+          absolute_level: 29",
  "+          internal_force_max: 6000",
  "+          experience_to_next: 35000",
  "+        - layer: ruMen",
  "+          absolute_level: 30",
  "+          internal_force_max: 6500",
  "+          experience_to_next: 42000",
  "+        - layer: shuLian",
  "+          absolute_level: 31",
  "+          internal_force_max: 7000",
  "+          experience_to_next: 50000",
  "+        - layer: jingTong",
  "+          absolute_level: 32",
  "+          internal_force_max: 7500",
  "+          experience_to_next: 60000",
  "+        - layer: yuanShu",
  "+          absolute_level: 33",
  "+          internal_force_max: 8000",
  "+          experience_to_next: 72000",
  "+        - layer: huaJing",
  "+          absolute_level: 34",
  "+          internal_force_max: 8500",
  "+          experience_to_next: 86000",
  "+        - layer: dengFeng",
  "+          absolute_level: 35",
  "+          internal_force_max: 9000",
  "+          experience_to_next: 100000  # 突破到宗师·启蒙",
  "+",
  "+    # === 宗师（36-42）：一代宗师 ===",
  "+    # 防御率 30%，装备升级到宝物，心法升级到失传神功",
  "+    # 解锁断崖绝壁闭关地图",
  "+    - tier: zongShi",
  "+      defense_rate: 0.30",
  "+      equipment_tier_cap: baoWu",
  "+      technique_tier_cap: shiChuanShenGong",
  "+      layers:",
  "+        - layer: qiMeng",
  "+          absolute_level: 36",
  "+          internal_force_max: 9500",
  "+          experience_to_next: 120000",
  "+        - layer: ruMen",
  "+          absolute_level: 37",
  "+          internal_force_max: 10000",
  "+          experience_to_next: 145000",
  "+        - layer: shuLian",
  "+          absolute_level: 38",
  "+          internal_force_max: 10500",
  "+          experience_to_next: 175000",
  "+        - layer: jingTong",
  "+          absolute_level: 39",
  "+          internal_force_max: 11000",
  "+          experience_to_next: 210000",
  "+        - layer: yuanShu",
  "+          absolute_level: 40",
  "+          internal_force_max: 11500",
  "+          experience_to_next: 250000",
  "+        - layer: huaJing",
  "+          absolute_level: 41",
  "+          internal_force_max: 12000",
  "+          experience_to_next: 300000",
  "+        - layer: dengFeng",
  "+          absolute_level: 42",
  "+          internal_force_max: 12500",
  "+          experience_to_next: 360000  # 突破到武圣·启蒙",
  "+",
  "+    # === 武圣（43-49）：武林神话 · 终极境界 ===",
  "+    # 防御率 35%，装备升级到神物，心法升级到传说神功",
  "+    - tier: wuSheng",
  "+      defense_rate: 0.35",
  "+      equipment_tier_cap: shenWu",
  "+      technique_tier_cap: chuanShuoShenGong",
  "+      layers:",
  "+        - layer: qiMeng",
  "+          absolute_level: 43",
  "+          internal_force_max: 13000",
  "+          experience_to_next: 430000",
  "+        - layer: ruMen",
  "+          absolute_level: 44",
  "+          internal_force_max: 13400",
  "+          experience_to_next: 510000",
  "+        - layer: shuLian",
  "+          absolute_level: 45",
  "+          internal_force_max: 13700",
  "+          experience_to_next: 610000",
  "+        - layer: jingTong",
  "+          absolute_level: 46",
  "+          internal_force_max: 14000",
  "+          experience_to_next: 730000",
  "+        - layer: yuanShu",
  "+          absolute_level: 47",
  "+          internal_force_max: 14400",
  "+          experience_to_next: 870000",
  "+        - layer: huaJing",
  "+          absolute_level: 48",
  "+          internal_force_max: 14700",
  "+          experience_to_next: 1040000",
  "+        - layer: dengFeng",
  "+          absolute_level: 49",
  "+          internal_force_max: 15000",
  "+          experience_to_next: 0   # 满级，无下一层",
  "+",
  "+# =============================================================================",
  "+# 3. 装备系统",
  "+# =============================================================================",
  "+# GDD §3.2 7 阶装备 + §6.2 强化 + §6.3 心血结晶 + §6.4 共鸣 + §6.5 开锋",
  "+",
  "+equipment:",
  "+",
  "+  # --- 7 阶装备的基础数值范围 ---",
  "+  # 每件具体装备实例（如\"青锋剑\"）从 EquipmentDef 读取范围，生成时按",
  "+  # 范围 random 一次。范围内随机让\"同阶装备拉开个体差异\"，符合武侠\"宝兵",
  "+  # 各有特点\"的叙事。",
  "+  #",
  "+  # 设计原则：",
  "+  #   - 武器 → 主攻击/速度，少量血量（武器作用是杀敌）",
  "+  #   - 护甲 → 主血量，少量速度，无攻击",
  "+  #   - 饰品 → 中等血量，少量攻击/速度（小而全）",
  "+  #",
  "+  # 数值校验：",
  "+  #   - 装备攻击上限 2000（GDD §5.2 红线）→ 神物·武器 1500-2000 ✓",
  "+  #   - 装备血量贡献 ≤ 3000（避免单装备血量超过基础）→ 神物·护甲 2000-3000 ✓",
  "+  #   - 装备速度贡献 ≤ 100（避免速度膨胀）→ 神物·武器 65-100 ✓",
  "+",
  "+  tiers:",
  "+",
  "+    # === 第 1 阶 寻常货 · 学徒境界开放 ===",
  "+    - tier: xunChang",
  "+      tier_name: \"寻常货\"",
  "+      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}",
  "+      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}",
  "+      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}",
  "+",
  "+    # === 第 2 阶 像样货 · 三流境界开放 ===",
  "+    - tier: xiangYang",
  "+      tier_name: \"像样货\"",
  "+      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}",
  "+      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}",
  "+      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}",
  "+",
  "+    # === 第 3 阶 好家伙 · 二流境界开放 ===",
  "+    - tier: haoJiaHuo",
  "+      tier_name: \"好家伙\"",
  "+      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}",
  "+      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}",
  "+      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}",
  "+",
  "+    # === 第 4 阶 利器 · 一流境界开放 · Demo 主线最高级装备 ===",
  "+    - tier: liQi",
  "+      tier_name: \"利器\"",
  "+      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}",
  "+      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}",
  "+      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}",
  "+",
  "+    # === 第 5 阶 重器 · 绝顶境界开放 ===",
  "+    - tier: zhongQi",
  "+      tier_name: \"重器\"",
  "+      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}",
  "+      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}",
  "+      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}",
  "+",
  "+    # === 第 6 阶 宝物 · 宗师境界开放 ===",
  "+    - tier: baoWu",
  "+      tier_name: \"宝物\"",
  "+      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}",
  "+      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1600, hp_max: 2300, speed_min: 25, speed_max: 50}",
  "+      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 850,  hp_max: 1300, speed_min: 45, speed_max: 70}",
  "+",
  "+    # === 第 7 阶 神物 · 武圣境界开放 ===",
  "+    - tier: shenWu",
  "+      tier_name: \"神物\"",
  "+      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 200, hp_max: 500, speed_min: 65, speed_max: 100}",
  "+      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 2300, hp_max: 3000, speed_min: 40, speed_max: 70}",
  "+      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1300, hp_max: 1800, speed_min: 65, speed_max: 95}",
  "+",
  "+  # --- 强化系统（GDD §6.2）---",
  "+  enhancement:",
  "+    bonus_per_level: 0.05            # 每级 +5% 数值（GDD 原值）",
  "+    max_level_formula: \"absolute_level\"  # 强化上限 = 持有者境界总层数（最高 +49）",
  "+",
  "+    # 成功率与失败惩罚（GDD §6.2 表）",
  "+    # 失败惩罚 material_penalty 含义：",
  "+    #   \"half\"  → 仅扣半数磨剑石",
  "+    #   \"full\"  → 全扣磨剑石",
  "+    success_curve:",
  "+      - level_range: [1, 10]",
  "+        success_rate: 1.00",
  "+        material_penalty: \"none\"",
  "+      - level_range: [11, 13]",
  "+        success_rate: 0.90",
  "+        material_penalty: \"half\"",
  "+      - level_range: [14, 16]",
  "+        success_rate: 0.75",
  "+        material_penalty: \"full\"",
  "+      - level_range: [17, 19]",
  "+        success_rate: 0.50",
  "+        material_penalty: \"full\"",
  "+      # +20 及以上：每级成功率 -2%，最低 30%（武圣后期高难度强化）",
  "+      - level_range: [20, 49]",
  "+        success_rate: null           # 由代码按 max(0.30, 0.50 - 0.02*(level-19)) 计算",
  "+        success_formula: \"max(0.30, 0.50 - 0.02 * (level - 19))\"",
  "+        material_penalty: \"full\"",
  "+",
  "+    # 磨剑石消耗曲线（每级强化一次的消耗）",
  "+    # 设计原则：低强化便宜、高强化材料压力大，避免无脑强化",
  "+    mojianshi_cost:",
  "+      - level_range: [1, 5]",
  "+        cost: 1",
  "+      - level_range: [6, 10]",
  "+        cost: 2",
  "+      - level_range: [11, 13]",
  "+        cost: 4",
  "+      - level_range: [14, 16]",
  "+        cost: 7",
  "+      - level_range: [17, 19]",
  "+        cost: 12",
  "+      - level_range: [20, 30]",
  "+        cost: 18",
  "+      - level_range: [31, 49]",
  "+        cost: 25",
  "+",
  "+    # 关键设计：永不破防降级（GDD §6.2 红线）",
  "+    never_degrade: true              # 失败仅扣材料，不会从 +18 掉到 +12",
  "+",
  "+  # --- 心血结晶保底（GDD §6.3）---",
  "+  xinxue_jiejing:",
  "+    gain_per_failure: 1              # 每次强化失败必得 1 颗",
  "+    guaranteed_success_costs:",
  "+      - level_range: [14, 16]",
  "+        crystal_cost: 3              # +14~+16 段消耗 3 颗直接成功",
  "+      - level_range: [17, 19]",
  "+        crystal_cost: 5              # +17~+19 段消耗 5 颗直接成功",
  "+      - level_range: [20, 49]",
  "+        crystal_cost: 8              # +20+ 段消耗 8 颗（数值平衡，避免后期囤积无用）",
  "+",
  "+  # --- 共鸣度阶段（GDD §6.4，强制规则）---",
  "+  resonance:",
  "+    stages:",
  "+      - stage: shengShu              # 生疏",
  "+        battle_count_range: [0, 100]",
  "+        bonus_multiplier: 1.0",
  "+        unlocks_joint_skill: false",
  "+        has_sword_song_effect: false",
  "+      - stage: chenShou              # 趁手",
  "+        battle_count_range: [100, 500]",
  "+        bonus_multiplier: 1.10       # 装备数值 +10%",
  "+        unlocks_joint_skill: false",
  "+        has_sword_song_effect: false",
  "+      - stage: moQi                  # 默契",
  "+        battle_count_range: [500, 2000]",
  "+        bonus_multiplier: 1.20       # +20%",
  "+        unlocks_joint_skill: true    # 解锁人剑合一招式",
  "+        has_sword_song_effect: false",
  "+      - stage: xinJianTongLing       # 心剑通灵",
  "+        battle_count_range: [2000, null]   # 上不封顶",
  "+        bonus_multiplier: 1.30       # +30%",
  "+        unlocks_joint_skill: true",
  "+        has_sword_song_effect: true  # 暴击附带剑鸣特效",
  "+",
  "+    # 师承传承时的清零规则（GDD §6.4）",
  "+    inheritance_retention: 0.7       # 传给徒弟保留 70%（鼓励\"一柄剑用一辈子\"）",
  "+    new_owner_retention: 0.0         # 玩家间换主直接清零",
  "+",
  "+  # --- 开锋系统（GDD §6.5）---",
  "+  forging:",
  "+    slots:",
  "+      - slot_index: 1",
  "+        unlock_at_enhance_level: 10  # +10 解锁开锋一",
  "+        available_types: [attack, speed, lifesteal, pierce]",
  "+        bonus_value:",
  "+          attack: 15        # 攻击 +15%",
  "+          speed: 15         # 速度 +15%",
  "+          lifesteal: 10     # 吸血 10%（命中时回血百分比）",
  "+          pierce: 15        # 破甲 15%（无视目标 15% 防御）",
  "+      - slot_index: 2",
  "+        unlock_at_enhance_level: 15  # +15 解锁开锋二",
  "+        available_types: [attack, speed, lifesteal, pierce]",
  "+        bonus_value:",
  "+          attack: 20",
  "+          speed: 20",
  "+          lifesteal: 15",
  "+          pierce: 20",
  "+        constraint: \"不能与开锋一相同类型\"",
  "+      - slot_index: 3",
  "+        unlock_at_enhance_level: 19  # +19 解锁开锋三",
  "+        available_types: [specialSkill]   # 仅可解锁专属技能",
  "+        bonus_value:",
  "+          specialSkill: 1   # 解锁一个专属技能词条（具体技能由 EquipmentDef 定义）",
  "+",
  "+  # --- 师承遗物（GDD §6.1）---",
  "+  lineage_heritage:",
  "+    pieces_per_generation_min: 1     # 每代师父最少传 1 件",
  "+    pieces_per_generation_max: 2     # 每代师父最多传 2 件",
  "+    internal_force_max_bonus: 0.05   # 师承遗物自带内力上限 +5% buff",
  "+",
  "+# =============================================================================",
  "+# 4. 心法系统",
  "+# =============================================================================",
  "+# GDD §3.3 7 阶心法 + §4.3 9 层修炼度 + §4.4 三流派克制",
  "+",
  "+techniques:",
  "+",
  "+  # --- 7 阶心法的属性加成 ---",
  "+  # 设计原则：",
  "+  #   - 内力增长加成：影响挂机/闭关时内力恢复速率",
  "+  #   - 速度加成：直接进入速度公式（GDD §5.6）",
  "+  #   - 招式倍率上限：高阶心法的招式倍率封顶值",
  "+  tiers:",
  "+",
  "+    - tier: ruMenGong         # 1 入门功",
  "+      tier_name: \"入门功\"",
  "+      internal_force_growth_bonus: 1.05    # 内力增长 +5%",
  "+      speed_bonus: 0",
  "+      max_skill_multiplier: 1500            # 该阶心法招式倍率不超过 1500（普通-中级强力技能）",
  "+",
  "+    - tier: changLianGong     # 2 常练功",
  "+      tier_name: \"常练功\"",
  "+      internal_force_growth_bonus: 1.10",
  "+      speed_bonus: 5",
  "+      max_skill_multiplier: 2000",
  "+",
  "+    - tier: mingJiaGong       # 3 名家功",
  "+      tier_name: \"名家功\"",
  "+      internal_force_growth_bonus: 1.15",
  "+      speed_bonus: 10",
  "+      max_skill_multiplier: 2500",
  "+",
  "+    - tier: menPaiJueXue      # 4 门派绝学",
  "+      tier_name: \"门派绝学\"",
  "+      internal_force_growth_bonus: 1.25",
  "+      speed_bonus: 15",
  "+      max_skill_multiplier: 3000",
  "+",
  "+    - tier: jiangHuMiChuan    # 5 江湖秘传",
  "+      tier_name: \"江湖秘传\"",
  "+      internal_force_growth_bonus: 1.40",
  "+      speed_bonus: 25",
  "+      max_skill_multiplier: 4000",
  "+",
  "+    - tier: shiChuanShenGong  # 6 失传神功",
  "+      tier_name: \"失传神功\"",
  "+      internal_force_growth_bonus: 1.60",
  "+      speed_bonus: 40",
  "+      max_skill_multiplier: 5500",
  "+",
  "+    - tier: chuanShuoShenGong # 7 传说神功",
  "+      tier_name: \"传说神功\"",
  "+      internal_force_growth_bonus: 2.00",
  "+      speed_bonus: 60",
  "+      max_skill_multiplier: 8000           # 含大招（如九阳神功的\"龙吟九霄\"）",
  "+",
  "+  # --- 9 层修炼度（GDD §4.3，强制规则）---",
  "+  cultivation:",
  "+    layers:",
  "+      - layer: chuKui          # 1 初窥",
  "+        bonus_multiplier: 1.00",
  "+      - layer: xiaoCheng       # 2 小成",
  "+        bonus_multiplier: 1.15",
  "+      - layer: zhongCheng      # 3 中成",
  "+        bonus_multiplier: 1.30",
  "+      - layer: daCheng         # 4 大成",
  "+        bonus_multiplier: 1.50",
  "+      - layer: yuanMan         # 5 圆满",
  "+        bonus_multiplier: 1.75",
  "+      - layer: dianFeng        # 6 巅峰",
  "+        bonus_multiplier: 2.00",
  "+      - layer: tongShen        # 7 通神",
  "+        bonus_multiplier: 2.30",
  "+      - layer: wuXia           # 8 无瑕",
  "+        bonus_multiplier: 2.60",
  "+      - layer: jiJing          # 9 极境",
  "+        bonus_multiplier: 3.00",
  "+",
  "+    # 升级到下一层所需的招式使用次数",
  "+    # 设计：曲线接近指数（每层 ~1.6 倍），让高层修炼度成为长期目标",
  "+    progress_to_next:",
  "+      - from_layer: chuKui",
  "+        progress_required: 100        # 初窥 → 小成",
  "+      - from_layer: xiaoCheng",
  "+        progress_required: 250        # 小成 → 中成",
  "+      - from_layer: zhongCheng",
  "+        progress_required: 500",
  "+      - from_layer: daCheng",
  "+        progress_required: 900",
  "+      - from_layer: yuanMan",
  "+        progress_required: 1500",
  "+      - from_layer: dianFeng",
  "+        progress_required: 2500",
  "+      - from_layer: tongShen",
  "+        progress_required: 4000",
  "+      - from_layer: wuXia",
  "+        progress_required: 6500       # 极境最难达，是\"老玩家追求\"",
  "+",
  "+  # --- 散功代价（GDD §4.3，强制规则）---",
  "+  # 换主修时的双重惩罚（不可调，是设计底线条款）",
  "+  dispersion:",
  "+    internal_force_penalty: 0.50      # 当前内力 -50%（不归零）",
  "+    cultivation_penalty: 0.50         # 原主修心法修炼度 -50%",
  "+",
  "+  # --- 三流派克制（GDD §4.4，强制规则）---",
  "+  # 关系：刚猛 → 阴柔 → 灵巧 → 刚猛（成环）",
  "+  schools:",
  "+    counter_relations:",
  "+      - attacker: gangMeng              # 刚猛",
  "+        target: yinRou                  # 克阴柔",
  "+        damage_multiplier: 1.25         # +25% 伤害",
  "+        extra_effect: \"extra_quake_dmg\" # 每招额外震伤",
  "+      - attacker: lingQiao              # 灵巧",
  "+        target: gangMeng                # 克刚猛",
  "+        damage_multiplier: 1.25",
  "+        extra_effect: \"crit_rate_+0.20\" # 暴击率 +20%",
  "+      - attacker: yinRou                # 阴柔",
  "+        target: lingQiao                # 克灵巧",
  "+        damage_multiplier: 1.25",
  "+        extra_effect: \"internal_injury\" # 每招施加内伤 debuff",
  "+",
  "+    # 被克制系数",
  "+    countered_multiplier: 0.75          # 被克制时输出 ×0.75",
  "+    neutral_multiplier: 1.00            # 同流派或非克制关系时 ×1.0",
  "+",
  "+# =============================================================================",
  "+# 5. 招式倍率参考表",
  "+# =============================================================================",
  "+# GDD §5.3：招式倍率分三档。具体每招由 SkillDef 单独定义，本表是设计参考。",
  "+# 实际配置时各阶心法的招式倍率不得超过 techniques.tiers[*].max_skill_multiplier",
  "+",
  "+skills:",
  "+",
  "+  # 招式倍率参考范围（按招式类型）",
  "+  # 用于 SkillDef.powerMultiplier 字段配置时的指导值",
  "+  reference_multipliers:",
  "+    normal_attack:",
  "+      base: 500              # GDD §5.3 普通攻击固定倍率",
  "+      note: \"所有普通攻击统一 500，不随心法阶提升\"",
  "+    power_skill:",
  "+      tier_1_2_range: [1000, 1800]   # 1-2 阶心法的强力技能",
  "+      tier_3_4_range: [1500, 2500]   # 3-4 阶",
  "+      tier_5_6_range: [2000, 3000]   # 5-6 阶",
  "+      tier_7_range:   [2500, 3500]   # 7 阶（传说神功的强力技能）",
  "+    ultimate:",
  "+      tier_1_2_range: [3000, 4500]   # 1-2 阶心法的大招",
  "+      tier_3_4_range: [4500, 6000]",
  "+      tier_5_6_range: [5500, 7000]",
  "+      tier_7_range:   [6500, 8000]   # 7 阶大招（如九阳\"龙吟九霄\"）",
  "+    joint_skill:",
  "+      base: 4500             # 人剑合一招式，固定基础倍率（共鸣度默契阶段解锁）",
  "+      note: \"共鸣度 +20% 后解锁，不分心法阶\"",
  "+",
  "+# =============================================================================",
  "+# 6. 角色系统",
  "+# =============================================================================",
  "+# GDD §4.1 四属性 + 6 档稀有度",
  "+",
  "+character:",
  "+",
  "+  # --- 四项基础属性 ---",
  "+  attributes:",
  "+    point_per_attribute_min: 1        # 单项属性下限（GDD §4.1）",
  "+    point_per_attribute_max: 10       # 单项属性上限",
  "+    total_points_min: 16              # 总点数下限",
  "+    total_points_max: 24              # 总点数上限",
  "+    distribution: \"normal\"            # 正态分布（中段最常见）",
  "+    distribution_mean: 5.5            # 正态分布均值",
  "+    distribution_stddev: 1.5          # 标准差",
  "+    rerollable: false                 # 不可重 roll（GDD 强制规则）",
  "+",
  "+  # --- 6 档稀有度概率（GDD §4.1，强制规则）---",
  "+  # 总和必须为 100%",
  "+  rarity_distribution:",
  "+    - rarity: yongCai     # 庸才",
  "+      probability: 0.15   # 15%",
  "+      total_points_range: [16, 17]",
  "+    - rarity: xunChang    # 寻常",
  "+      probability: 0.35   # 35%",
  "+      total_points_range: [18, 19]",
  "+    - rarity: biaoZhun    # 标准",
  "+      probability: 0.25   # 25%",
  "+      total_points_range: [20, 20]",
  "+    - rarity: ziYou       # 资优",
  "+      probability: 0.18   # 18%",
  "+      total_points_range: [21, 22]",
  "+    - rarity: tianCai     # 天才",
  "+      probability: 0.05   # 5%",
  "+      total_points_range: [23, 23]",
  "+    - rarity: jueShi      # 绝世",
  "+      probability: 0.02   # 2%",
  "+      total_points_range: [24, 24]",
  "+",
  "+  # --- 奇遇属性加成（GDD §4.1）---",
  "+  # 后天弥补先天，但有硬上限",
  "+  adventure_attribute_bonus:",
  "+    lifetime_cap_per_character: 5     # 每个角色生涯总加成上限 +5",
  "+    bonus_per_event_min: 1            # 单次奇遇最少加 1 点",
  "+    bonus_per_event_max: 3            # 单次奇遇最多加 3 点",
  "+    distribution: \"weighted\"          # 大部分加 1，少数加 2-3",
  "+    weights: [0.65, 0.25, 0.10]      # 1 点/2 点/3 点的概率",
  "+",
  "+# =============================================================================",
  "+# 7. 闭关系统",
  "+# =============================================================================",
  "+# GDD §7.3 时间锚点闭关 + §8.3 五张地图",
  "+",
  "+retreat:",
  "+",
  "+  # --- 三档闭关时长（GDD §7.3）---",
  "+  durations:",
  "+    - hours: 1",
  "+      description: \"短闭关 · 适合短时间游玩场景\"",
  "+    - hours: 4",
  "+      description: \"中闭关 · 适合临睡前安排\"",
  "+    - hours: 12",
  "+      description: \"长闭关 · 适合工作日全天\"",
  "+",
  "+  # --- 五张闭关地图（GDD §8.3）---",
  "+  # 产出率字段：所有 _per_hour 字段是\"每小时基础产出\"，最终产出还会乘以",
  "+  # 时辰加成、节气加成、心法加成等",
  "+",
  "+  maps:",
  "+",
  "+    # === 山林：平均产出，新手地图 ===",
  "+    - map_type: shanLin",
  "+      map_name: \"山林\"",
  "+      required_realm: xueTu                  # 学徒即可进入",
  "+      base_outputs:",
  "+        experience_per_hour: 100",
  "+        mojianshi_per_hour: 1.0",
  "+        equipment_drop_rate: 1.0             # 基础掉率（无加成）",
  "+        technique_learn_rate: 1.0",
  "+        internal_force_growth: 1.0",
  "+",
  "+    # === 古剑冢：兵器掉率 +50% ===",
  "+    - map_type: guJianZhong",
  "+      map_name: \"古剑冢\"",
  "+      required_realm: sanLiu                 # 三流境界解锁",
  "+      base_outputs:",
  "+        experience_per_hour: 80",
  "+        mojianshi_per_hour: 0.8",
  "+        equipment_drop_rate: 1.5             # 兵器掉率 +50%（GDD §8.3）",
  "+        technique_learn_rate: 1.0",
  "+        internal_force_growth: 1.0",
  "+",
  "+    # === 藏经阁：心法领悟 +50% ===",
  "+    - map_type: cangJingGe",
  "+      map_name: \"藏经阁\"",
  "+      required_realm: sanLiu",
  "+      base_outputs:",
  "+        experience_per_hour: 90",
  "+        mojianshi_per_hour: 0.5",
  "+        equipment_drop_rate: 1.0",
  "+        technique_learn_rate: 1.5            # 心法领悟 +50%",
  "+        internal_force_growth: 1.0",
  "+",
  "+    # === 悬崖瀑布：内力增长 +50% ===",
  "+    - map_type: xuanYaPuBu",
  "+      map_name: \"悬崖瀑布\"",
  "+      required_realm: erLiu                  # 二流境界解锁",
  "+      base_outputs:",
  "+        experience_per_hour: 70",
  "+        mojianshi_per_hour: 0.5",
  "+        equipment_drop_rate: 1.0",
  "+        technique_learn_rate: 1.0",
  "+        internal_force_growth: 1.5           # 内力增长 +50%",
  "+",
  "+    # === 断崖绝壁：宗师专属，全维度高产出 ===",
  "+    - map_type: duanYaJueBi",
  "+      map_name: \"断崖绝壁\"",
  "+      required_realm: zongShi                # 仅宗师以上可去（GDD §8.3）",
  "+      base_outputs:",
  "+        experience_per_hour: 200",
  "+        mojianshi_per_hour: 2.0",
  "+        equipment_drop_rate: 1.5             # 全维度都加 50%",
  "+        technique_learn_rate: 1.5",
  "+        internal_force_growth: 1.5",
  "+",
  "+  # --- 时辰加成（GDD §7.3）---",
  "+  # 加成基于\"开始闭关时刻\"，不会因为跨时辰而动态切换",
  "+  time_of_day_bonus:",
  "+    - period: ziShi                          # 子时",
  "+      time_range: [\"23:00\", \"01:00\"]",
  "+      effect: \"internal_force_growth\"",
  "+      multiplier: 1.20                       # 内力增长 +20%",
  "+    - period: zhengWu                        # 正午",
  "+      time_range: [\"11:00\", \"13:00\"]",
  "+      effect: \"yang_school_techniques\"       # 阳刚类武学（刚猛流派）+20%",
  "+      multiplier: 1.20",
  "+    - period: other",
  "+      time_range: null                       # 其他时段无加成",
  "+      effect: null",
  "+      multiplier: 1.00",
  "+",
  "+  # --- 节气日加成（GDD §7.3）---",
  "+  solar_term_bonus:",
  "+    multiplier: 1.30                         # 节气日全属性 +30%",
  "+    # Demo 阶段支持的节气列表（按 2026 年公历日期；后续年份由代码动态计算）",
  "+    # 实际计算用农历库（如 chinese_lunar_calendar），yaml 这里只是参考",
  "+    days_2026:",
  "+      - {name: \"立春\", date: \"2026-02-04\"}",
  "+      - {name: \"清明\", date: \"2026-04-05\"}",
  "+      - {name: \"立夏\", date: \"2026-05-06\"}",
  "+      - {name: \"夏至\", date: \"2026-06-21\"}",
  "+      - {name: \"立秋\", date: \"2026-08-08\"}",
  "+      - {name: \"中秋\", date: \"2026-09-25\"}",
  "+      - {name: \"秋分\", date: \"2026-09-23\"}",
  "+      - {name: \"立冬\", date: \"2026-11-08\"}",
  "+      - {name: \"冬至\", date: \"2026-12-22\"}",
  "+",
  "+# =============================================================================",
  "+# 8. 30 层爬塔\"问鼎江湖\"",
  "+# =============================================================================",
  "+# GDD §8.2：每天 5 次挑战次数，通关层数决定排行榜位置",
  "+",
  "+tower:",
  "+",
  "+  # --- 每日挑战次数（GDD §8.2，强制规则）---",
  "+  daily_attempts: 5",
  "+  refresh_at: \"00:00\"                        # 本地时区午夜重置（详见 schema §4.10 时区规则）",
  "+",
  "+  # --- 30 层难度递增曲线 ---",
  "+  # difficulty_multiplier 影响敌人 HP / 攻击 / 速度",
  "+  # 设计原则：",
  "+  #   1-10 简单：玩家境界刚到二流即可挑战",
  "+  #   11-20 中等：需要二流圆熟 + 利器装备",
  "+  #   21-30 困难：需要一流境界 + 强化高的装备",
  "+  #   Boss 层（5/15/25 小，10/20/30 大）额外乘以 boss_multiplier",
  "+",
  "+  difficulty_curve:",
  "+    # === 简单段 (1-10) ===",
  "+    - layers: [1, 2, 3, 4, 5]",
  "+      difficulty_range: [1.00, 1.20]         # 线性 1.0/1.05/1.10/1.15/1.20",
  "+      tier: \"简单前段\"",
  "+      recommended_realm: erLiu               # 推荐境界：二流·圆熟",
  "+    - layers: [6, 7, 8, 9, 10]",
  "+      difficulty_range: [1.25, 1.50]         # 1.25/1.30/1.35/1.40/1.50",
  "+      tier: \"简单后段\"",
  "+      recommended_realm: erLiu               # 二流·登峰",
  "+",
  "+    # === 中等段 (11-20) ===",
  "+    - layers: [11, 12, 13, 14, 15]",
  "+      difficulty_range: [1.60, 2.00]         # 1.60/1.70/1.80/1.85/2.00",
  "+      tier: \"中等前段\"",
  "+      recommended_realm: yiLiu               # 一流·启蒙",
  "+    - layers: [16, 17, 18, 19, 20]",
  "+      difficulty_range: [2.10, 2.60]         # 2.10/2.20/2.30/2.45/2.60",
  "+      tier: \"中等后段\"",
  "+      recommended_realm: yiLiu               # 一流·圆熟",
  "+",
  "+    # === 困难段 (21-30) · Demo 顶级挑战 ===",
  "+    - layers: [21, 22, 23, 24, 25]",
  "+      difficulty_range: [2.80, 3.40]         # 2.80/2.95/3.10/3.25/3.40",
  "+      tier: \"困难前段\"",
  "+      recommended_realm: yiLiu               # 一流·登峰",
  "+    - layers: [26, 27, 28, 29, 30]",
  "+      difficulty_range: [3.55, 4.20]         # 3.55/3.70/3.85/4.00/4.20",
  "+      tier: \"困难后段\"",
  "+      recommended_realm: jueDing             # 绝顶·启蒙（Demo 不开放绝顶但供爬塔挑战）",
  "+",
  "+  # --- Boss 层配置（GDD §8.2）---",
  "+  # 6 个 Boss：3 小 + 3 大",
  "+  boss_layers:",
  "+    small_boss_layers: [5, 15, 25]           # 小 Boss",
  "+    big_boss_layers: [10, 20, 30]            # 大 Boss",
  "+    small_boss_multiplier: 1.5               # 小 Boss 数值 ×1.5",
  "+    big_boss_multiplier: 2.0                 # 大 Boss 数值 ×2.0",
  "+",
  "+  # --- Boss 血量校验（GDD §5.2 红线 50000+）---",
  "+  # 第 30 层大 Boss：base_hp 12000 × difficulty 4.20 × boss_mult 2.0 = 100,800 ✓",
  "+  # 第 10 层大 Boss：base_hp 5000 × difficulty 1.50 × 2.0 = 15,000（前期 Boss 较低）",
  "+  # 第 20 层大 Boss：base_hp 8500 × difficulty 2.60 × 2.0 = 44,200（接近 50000）",
  "+  # 注：以上 base_hp 由 StageDef 中的具体敌人配置决定，此处仅校验",
  "+",
  "+  # --- 排行榜配置 ---",
  "+  leaderboard:",
  "+    sync_to_supabase: true                   # 通关后同步到 Supabase",
  "+    sync_throttle_seconds: 60                # 节流：每 60 秒最多同步一次",
  "+    track_metrics: [\"highest_layer\", \"best_clear_time\", \"total_attempts\"]",
  "+",
  "+# =============================================================================",
  "+# 9. 师徒传承",
  "+# =============================================================================",
  "+# GDD §7.1 解锁节奏 + §6.4 装备共鸣传承",
  "+",
  "+inheritance:",
  "+",
  "+  # --- 解锁节奏（GDD §7.1）---",
  "+  unlock_rules:",
  "+    can_take_disciple_at: yiLiu              # 突破到一流可收徒",
  "+    disciple_can_take_grand_disciple_at: jueDing  # 弟子突破到绝顶可收徒孙",
  "+    can_pass_legacy_at: wuSheng              # 武圣后传位（飞升渡劫，Demo 不实现）",
  "+",
  "+  # --- Demo 简化（GDD §7.1）---",
  "+  demo_max_characters: 3                     # Demo 阶段最多 3 角色：祖师 + 大弟子 + 二弟子",
  "+",
  "+  # --- 师承遗物（GDD §6.1）---",
  "+  heritage_items:",
  "+    pieces_per_generation_min: 1             # 每代师父传 1-2 件",
  "+    pieces_per_generation_max: 2",
  "+    auto_buff_internal_force_max: 0.05       # 师承遗物自带 +5% 内力上限 buff",
  "+    resonance_retention: 0.7                 # 共鸣度保留 70%",
  "+",
  "+  # --- 祖师爷 buff（GDD §7.1，飞升后）---",
  "+  founder_ancestor_buff:",
  "+    enabled_when_alive: false                # Demo 阶段未实现飞升",
  "+    sect_wide_buff: null                     # 1.0 版本再设计",
  "+",
  "+# =============================================================================",
  "+# 10. 心法相生组合（GDD §4.5）",
  "+# =============================================================================",
  "+# 5 个隐藏组合的具体效果数值。组合判定逻辑见 SynergyDef，本段只给数值。",
  "+",
  "+synergies:",
  "+",
  "+  effect_values:",
  "+    # 阴阳调和（九阳 + 九阴）：全属性 +20%",
  "+    yin_yang_he:",
  "+      effect_type: \"all_attr_pct\"",
  "+      effect_value: 0.20",
  "+",
  "+    # 丐帮传承（降龙十八掌 + 打狗棒法）：解锁\"亢龙有悔\"暴击",
  "+    gai_bang_chuan_cheng:",
  "+      effect_type: \"unlock_skill_crit\"",
  "+      target_skill_id: \"skill_kang_long_you_hui\"",
  "+      crit_rate_bonus: 0.50",
  "+",
  "+    # 少林正宗（易筋经 + 少林外功）：内力增长 +30%",
  "+    shao_lin_zheng_zong:",
  "+      effect_type: \"internal_force_growth_pct\"",
  "+      effect_value: 0.30",
  "+",
  "+    # 武当圆融（太极拳 + 太极剑）：反伤 15%",
  "+    wu_dang_yuan_rong:",
  "+      effect_type: \"reflect_pct\"",
  "+      effect_value: 0.15",
  "+",
  "+    # 华山合璧（紫霞神功 + 华山剑法）：暴击伤害 +50%",
  "+    hua_shan_he_bi:",
  "+      effect_type: \"crit_dmg_pct\"",
  "+      effect_value: 0.50",
  "+",
  "+# =============================================================================",
  "+# 11. 战例验证",
  "+# =============================================================================",
  "+# 用具体战例反向验证上述数值是否合理。如果改动 combat 段的系数，",
  "+# 务必重新跑一遍这些战例确认未突破 GDD §5.2 红线。",
  "+",
  "+validation_examples:",
  "+",
  "+  # --- 战例 A：学徒新手关 ---",
  "+  # 验证目标：第一小时所有战斗让玩家轻松取胜（GDD §10.3）",
  "+  example_a:",
  "+    description: \"学徒·入门 主角 vs 学徒·启蒙 山贼\"",
  "+    attacker:",
  "+      realm: \"xueTu / ruMen (lv 2)\"",
  "+      internal_force: 600",
  "+      equipment_attack: 130              # 寻常货武器中段",
  "+      skill_multiplier: 500              # 普通攻击",
  "+      cultivation_multiplier: 1.00       # 初窥",
  "+      school_counter: 1.00               # 中性",
  "+      critical: 1.00                     # 无暴击",
  "+    defender:",
  "+      realm: \"xueTu / qiMeng (lv 1)\"",
  "+      max_hp: 3700                       # 1000 + 500*0.7 + 5*500 = 1000+350+2500 = 3850 → 估算 3700",
  "+      defense_rate: 0.05                 # 学徒 5%",
  "+    calculated_damage: \"(600*0.4 + 130*1.0 + 500) * 1.0 * 1.0 * 1.0 * (1-0.05) * 1.0 = 826\"",
  "+    expected_outcome: \"约 4 击致死，节奏适合新手期教学战斗 ✓\"",
  "+",
  "+  # --- 战例 B：二流圆熟同境界对决 ---",
  "+  # 验证目标：普通伤害落在 GDD §5.2 红线 2000-8000 区间",
  "+  example_b:",
  "+    description: \"二流·圆熟 主角 vs 二流·圆熟 对手\"",
  "+    attacker:",
  "+      realm: \"erLiu / yuanShu (lv 19)\"",
  "+      internal_force: 3000",
  "+      equipment_attack: 580              # 利器武器中段（其实利器是一流装备，二流主角用利器需通过奇遇）",
  "+      skill_multiplier: 1500             # 强力技能（中段）",
  "+      cultivation_multiplier: 1.75       # 圆满",
  "+      school_counter: 1.00",
  "+      critical: 1.00",
  "+    defender:",
  "+      realm: \"erLiu / yuanShu (lv 19)\"",
  "+      max_hp: 7500                       # 1000 + 3000*0.7 + 6*500 + 500(装备血量) = 6600",
  "+      defense_rate: 0.15                 # 二流 15%",
  "+    calculated_damage: \"(3000*0.4 + 580 + 1500) * 1.75 * 1.0 * 1.0 * 0.85 * 1.0 = 4889\"",
  "+    expected_outcome: \"在 2000-8000 红线内 ✓；约 2 击致死，强力技能节奏合理\"",
  "+",
  "+  # --- 战例 C：三流挑战二流（境界差吃亏）---",
  "+  # 验证目标：低境界打高境界吃亏明显（GDD §5.5 设计意图）",
  "+  example_c:",
  "+    description: \"三流·登峰 主角 vs 二流·入门 高手（差 1 大境界）\"",
  "+    attacker:",
  "+      realm: \"sanLiu / dengFeng (lv 14)\"",
  "+      internal_force: 2000",
  "+      equipment_attack: 280              # 像样货上段",
  "+      skill_multiplier: 1500             # 强力技能",
  "+      cultivation_multiplier: 1.30       # 中成",
  "+      school_counter: 1.00",
  "+      critical: 1.00",
  "+      realm_diff_modifier: 0.7           # 低境界打高境界（守方修正）",
  "+    defender:",
  "+      realm: \"erLiu / ruMen (lv 16)\"",
  "+      max_hp: 6800                       # 1000 + 2400*0.7 + 6*500 + 500 = 4180+500 ≈ 5180 → 估算",
  "+      defense_rate: 0.15                 # 二流",
  "+    calculated_damage: \"(2000*0.4 + 280 + 1500) * 1.30 * 1.0 * 1.0 * 0.85 * 0.7 = 1972\"",
  "+    expected_outcome: \"勉强达到普通伤害下限 2000；约 4 击致死，三流挑战二流确实吃力 ✓\"",
  "+",
  "+  # --- 战例 D：一流大招暴击 + 流派克制 ---",
  "+  # 验证目标：大招暴击应达到\"上万\"（GDD §5.2）",
  "+  example_d:",
  "+    description: \"一流·圆熟 主角刚猛流大招暴击 vs 一流·启蒙 阴柔流对手\"",
  "+    attacker:",
  "+      realm: \"yiLiu / yuanShu (lv 26)\"",
  "+      internal_force: 5000",
  "+      equipment_attack: 600              # 利器武器",
  "+      skill_multiplier: 5500             # 大招（刚猛 4 阶心法上限附近）",
  "+      cultivation_multiplier: 1.75       # 圆满",
  "+      school_counter: 1.25               # 刚猛克阴柔",
  "+      critical: 2.00                     # 暴击",
  "+    defender:",
  "+      realm: \"yiLiu / qiMeng (lv 22)\"",
  "+      max_hp: 7860                       # 1000 + 3800*0.7 + 6*500 + 1100 = 1000+2660+3000+1100 = 7760",
  "+      defense_rate: 0.20                 # 一流",
  "+    calculated_damage: \"(5000*0.4 + 600 + 5500) * 1.75 * 1.25 * 2.0 * 0.80 * 1.0 = 28525\"",
  "+    expected_outcome: \"破万达成（28525），符合 GDD §5.2 大招暴击'上万'目标 ✓；一击秒杀\"",
  "+",
  "+  # --- 战例 E：武圣 vs 武圣（终极对决）---",
  "+  # 验证目标：高境界数值不崩溃，仍在合理区间",
  "+  example_e:",
  "+    description: \"武圣·登峰 vs 武圣·登峰（神物 +49 强化）\"",
  "+    attacker:",
  "+      realm: \"wuSheng / dengFeng (lv 49)\"",
  "+      internal_force: 15000",
  "+      equipment_attack: 3920             # 神物 1750 × (1+49*0.05) = 1750*3.45 = 6037 × 1.30 共鸣 = 7848",
  "+                                          # 但平衡后我们用：1750 × 1.30 共鸣 × 1.0(已含强化) = 校验数据",
  "+      skill_multiplier: 8000             # 传说神功大招上限",
  "+      cultivation_multiplier: 3.00       # 极境",
  "+      school_counter: 1.00",
  "+      critical: 2.50                     # 顶级暴击",
  "+    defender:",
  "+      realm: \"wuSheng / dengFeng (lv 49)\"",
  "+      max_hp: 19500                      # 1000 + 15000*0.7 + 10*500 + 3000 = 19500（接近 20000 上限）",
  "+      defense_rate: 0.35                 # 武圣",
  "+    note: \"本战例数据用于压力测试，确保武圣境界数值不崩盘\"",
  "+    expected_outcome: \"约 19500 / 19500 几乎一击致死，符合武圣对决'电光石火'氛围 ✓；血量未超 20000 红线 ✓\"",
  "+",
  "+# =============================================================================",
  "+# 文件结束",
  "+# ============================================================================="
]
```

<a id="q012"></a>
### Q012

```sh
git show --format=fuller --no-ext-diff --no-color 13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9 -- data/numbers.yaml
```

命中/输出行数：75；退出码：0。

```json
[
  "commit 13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Fri Aug 7 16:36:21 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Fri Aug 7 16:36:21 2026 +0800",
  "",
  "    数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec",
  "",
  "diff --git a/data/numbers.yaml b/data/numbers.yaml",
  "index dd3e1913f..4a6c7f860 100644",
  "--- a/data/numbers.yaml",
  "+++ b/data/numbers.yaml",
  "@@ -28,6 +28,9 @@",
  " meta:",
  "   version: \"0.2.0\"             # 与 SaveData.saveVersion 对应；major.minor.patch",
  "   description: \"Demo 阶段数值配置 · 覆盖学徒到武圣全程\"",
  "+  # ⚠ 纯文档（2026-08-07 N1 处置）：NumbersConfig.fromYaml 只取 meta['version']",
  "+  #   （numbers_config.dart:316,323），meta 其余 key 无任何读取点。last_updated 已",
  "+  #   长期不随改动更新（本行值停留在 2026-05-10），当作时间戳会误导，仅存档用。",
  "   last_updated: \"2026-05-10\"",
  "   notes: \"所有数值基于 GDD v1.1 §5.2 数值红线设计；公式系数见 combat 段\"",
  " ",
  "@@ -939,6 +942,21 @@ character:",
  " ",
  "   # --- 6 档稀有度概率（GDD §4.1，强制规则）---",
  "   # 总和必须为 100%",
  "+  #",
  "+  # ❗ 未接线（2026-08-07 N1 实测，非\"未使用\"而是\"配了但不生效\"）：",
  "+  #   本表 6 档概率**从未被任何代码读取**。全部生产赋值点硬编码 RarityTier.biaoZhun：",
  "+  #     lib/features/recruitment/application/recruitment_service.dart:99",
  "+  #     lib/features/sect/presentation/sect_recruit_handler.dart:110",
  "+  #     lib/features/onboarding/application/master_builder.dart:53",
  "+  #   即游戏内招募/收徒得到的角色**永远是「标准」档**，6 档稀有度分布零生效。",
  "+  #   更进一步：Character.rarity 字段**从未被读取过**——全 lib（除 debug/codegen）",
  "+  #   仅 7 处引用，全是枚举定义/字段声明/构造参数/上述 3 处写死赋值，**零消费点**，",
  "+  #   无 UI 展示、无战斗影响、六档中文名只存在于 enums.dart:151-156 的行末注释里。",
  "+  #   所以这不是\"配了没 roll\"，而是**整套稀有度设计零实装**（配置在、枚举在、",
  "+  #   字段在、赋值写死、读取端为空）。改本表任何概率都不产生行为变化。",
  "+  #   ⚠ 接线 = 建整个功能（roll + 属性派生 + UI 展示 + 平衡验证），且各档",
  "+  #     total_points_range 16→24 是 ±25% 属性摆幅，属平衡改动需拍板，勿擅自实装。",
  "+  #     现状与选项详 docs/spec/rarity_wiring_gap_2026-08-07.md",
  "   rarity_distribution:",
  "     - rarity: yongCai     # 庸才",
  "       probability: 0.15   # 15%",
  "@@ -1386,6 +1404,18 @@ tower:",
  " inheritance:",
  " ",
  "   # --- 解锁节奏（GDD §7.1）---",
  "+  #",
  "+  # ❗ 未消费（2026-08-07 N1 实测）：本块三字段 lib/ 零读取点",
  "+  #   （NumbersConfig 解析 inheritance 仅取 founder_ancestor_buff（numbers_config.dart:399）",
  "+  #   与 heritage_items（:404））。逐字段现状：",
  "+  #   · can_take_disciple_at / disciple_can_take_grand_disciple_at",
  "+  #     ——描述的是\"按境界解锁收徒\"，而实装的收徒是一次性剧情事件",
  "+  #       （recruitment_service.dart:47,79,172 走 SaveData.recruitmentOffered flag），",
  "+  #       **完全没有境界门禁**。设计与实装分叉，不是失修。",
  "+  #   · can_pass_legacy_at ——与活配置 ascension.unlock_triggers.required_realm.tier",
  "+  #       （本文件 :1830-1832，AscendService 经 numbers.ascension 消费，",
  "+  #        ascend_service.dart:60）**重复声明同一门槛**，且本处是死的那份。",
  "+  #       改本行不生效；要改飞升境界门槛请改 ascension 段。",
  "   unlock_rules:",
  "     can_take_disciple_at: yiLiu              # 突破到一流可收徒",
  "     disciple_can_take_grand_disciple_at: jueDing  # 弟子突破到绝顶可收徒孙",
  "@@ -1474,6 +1504,11 @@ synergies:",
  " # 用具体战例反向验证上述数值是否合理。如果改动 combat 段的系数，",
  " # 务必重新跑一遍这些战例确认未突破 GDD §5.2 红线。",
  " ",
  "+# ⚠ 纯文档（2026-08-07 N1 处置）：本段 example_a..e 不进 NumbersConfig.fromYaml",
  "+#   解析（无 y['validation_examples'] 取值点），lib/data/validation/ 下的红线校验器",
  "+#   校验的是已解析的配置对象，不读本段战例。test/combat/damage_calculator_test.dart",
  "+#   的对照值为测试内手写，非从本段加载 —— 改本段数字不会让任何测试变红。",
  "+#   本段价值在于人工核对公式，改 combat 系数后请手工重算这些战例。",
  " validation_examples:",
  " ",
  "   # --- 战例 A：学徒新手关 ---"
]
```

<a id="q013"></a>
### Q013

```sh
git show --format=fuller --no-ext-diff --no-color 9f59ddc2b64faf28d06c52a26f70ea60e8014f3a -- data/numbers.yaml
```

命中/输出行数：69；退出码：0。

```json
[
  "commit 9f59ddc2b64faf28d06c52a26f70ea60e8014f3a",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Wed Jun 24 23:26:07 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Wed Jun 24 23:26:07 2026 +0800",
  "",
  "    chore: 审计 D+E 卫生批收口(D2 wire/D1·D3-D7 注释honest化/D8 改stale注释/E 迁UiStrings)",
  "    ",
  "    全系统审计 D 死字段+注释 drift 8 项 + E 散写中文 2 项。处置原则=让脱节的文档诚实。",
  "    ",
  "    D2 wire(唯一行为改·行为保持):",
  "    - tower_entry_flow + stage_entry_flow 两 caller 补传 numbers.skillUnlock.fragmentThreshold",
  "    - 此前硬编码默认 5(=配置值,行为保持),真 tunable 接通",
  "    ",
  "    D1/D3/D4/D5/D6/D7 注释 honest 化:",
  "    - D1 TechniqueDef internalForceGrowthBonus/speedBonus: 0 读取,镜像 numbers.yaml tiers 参考值",
  "    - D3 StageDef.npcId: UNUSED-PENDING-1.1(对齐 B3,1.1 双写真 NPC 关系激活)",
  "    - D4 Character.attributeBonusFromAdventure: READ-PENDING(写端已活/读端待接,延期非死·audit 误写 Bons)",
  "    - D5 心魔 subCultivationMultiplier/debuffId: 0 生产消费(main 真消费/sub 恒1.00/debuffId 仅 test 断言)",
  "    - D6 闭关 time_range: 固定传统时辰常量非可调,NumbersConfig 不解析,硬编码 _isZiShi/_isZhengWu",
  "    - D7 final_damage_formula/skill_multiplier_added: 纯公式文档,不解析,damage_calculator 恒应用",
  "    ",
  "    D8 改 3 处 stale 注释(实已实装却自称未接):",
  "    - 正午阳刚(seclusion zhengWuBonus:207) / stageBossFailRecoverProb(stage_boss_recruit_hook:36)",
  "    - light_foot damageMultiplier(light_foot_strategy:122)",
  "    ",
  "    E 散写中文迁 UiStrings:",
  "    - E1 '角色不存在'×3(character_panel/technique_panel/cangjingge)→ UiStrings.characterNotFound",
  "    - E2 narrative '跳过' → UiStrings.narrativeSkip;debug 标签+装饰字 '武' 故意留(dev-gated 非生产文案)",
  "    ",
  "    Phase0 纠 2 审计 drift:D4 字段名 Bons→Bonus 且已写活、E1 误计 4 实为 3。",
  "    0 改战斗数值。analyze 0 / 全量 2904+1skip(纯卫生行为保持·0 新测·0 回归)。",
  "    🎯 全系统审计(38 子系统)A-E 全闭环。",
  "    ",
  "    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>",
  "",
  "diff --git a/data/numbers.yaml b/data/numbers.yaml",
  "index b3ed384fc..00a0656ca 100644",
  "--- a/data/numbers.yaml",
  "+++ b/data/numbers.yaml",
  "@@ -55,12 +55,14 @@ combat:",
  "   # GDD §5.3：基础伤害 = (内力 × 0.4) + (装备攻击 × 8) + 招式倍率",
  "   # 平衡后：    基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率",
  "   damage_formula:",
  "-    internal_force_factor: 0.4       # 内力对伤害的系数（GDD 原值，未变）",
  "-    equipment_attack_factor: 1.0     # 装备攻击系数（GDD 原写 8，平衡后调为 1.0）",
  "-    skill_multiplier_added: true     # 招式倍率作为加项（不是乘项）",
  "+    internal_force_factor: 0.4       # 内力对伤害的系数（GDD 原值，未变）· 真消费(damage_calculator)",
  "+    equipment_attack_factor: 1.0     # 装备攻击系数（GDD 原写 8，平衡后调为 1.0）· 真消费(damage_calculator)",
  "+    skill_multiplier_added: true     # ⚠ 纯文档(审计 D7):NumbersConfig 不解析;招式倍率\"作为加项\"已硬编码在 damage_calculator",
  " ",
  "   # --- 最终伤害公式（GDD §5.4）---",
  "   # 最终伤害 = 基础伤害 × 修炼度加成 × 流派克制 × 暴击系数 × (1-防御率) × 境界差修正",
  "+  # ⚠ 以下 apply_* flags 为纯公式结构文档（审计 D7 2026-06-24）：NumbersConfig 不解析此块，",
  "+  #   damage_calculator.dart 恒应用全部乘子（非可关闭开关）。改这些 true→false 不生效，勿误用。",
  "   final_damage_formula:",
  "     apply_cultivation_multiplier: true   # 应用心法修炼度（1.0~3.0）",
  "     apply_school_counter: true           # 应用流派克制（0.75/1.0/1.25）",
  "@@ -1033,6 +1035,10 @@ retreat:",
  " ",
  "   # --- 时辰加成（GDD §7.3）---",
  "   # 加成基于\"开始闭关时刻\"，不会因为跨时辰而动态切换",
  "+  # ⚠ time_range 字段为固定时辰文档锚（审计 D6 2026-06-24）：NumbersConfig 只解析",
  "+  #   multiplier/effect/target_attribute/applies_to_school，**不解析 time_range**。",
  "+  #   实际时段判定硬编码在 seclusion_service.dart `_isZiShi`(h∈{23,0}) / `_isZhengWu`(h∈{11,12})。",
  "+  #   子时(23:00-01:00)/正午(11:00-13:00)是固定传统时辰常量、非可调平衡项，编辑此处 time_range 不生效。",
  "   time_of_day_bonus:",
  "     - period: ziShi                          # 子时",
  "       time_range: [\"23:00\", \"01:00\"]"
]
```

<a id="q014"></a>
### Q014

```sh
git show --format=fuller --no-ext-diff --no-color c1444c9a8f5a077639b2172ce7c3eb3553bff057 -- data/numbers.yaml
```

命中/输出行数：50；退出码：0。

```json
[
  "commit c1444c9a8f5a077639b2172ce7c3eb3553bff057",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Sat May 30 15:02:48 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Sat May 30 15:02:48 2026 +0800",
  "",
  "    [schema] #4③ wf_audit 数值迁 yaml:B2/B5 接线 + B6 对齐 + B7 注释",
  "    ",
  "    - B2: NumbersConfig.adventureAttributeLifetimeCap 接入 EncounterService.attributeGainCap",
  "      (numbers.yaml character.adventure_attribute_bonus.lifetime_cap_per_character 此前零消费)",
  "    - B5: numbers.yaml 新增 encounter.fortune_sensitivity,EncounterService 硬编码 20.0 外置",
  "      (3 gameplay 构造点 provider/seclusion/hook 从 NumbersConfig 注入,debug/test 保默认)",
  "    - B6: mass_battle_def residualHpThresholdPct 默认/fallback 0.05→0.30 对齐生产设计值",
  "    - B7: numbers.yaml bonus_per_event 段标注未运行时消费(设计参考)",
  "    - B9 已于 H2 audit S3 注释(跳过)· B1/B3/B4 已 2026-05-29 修 · B8/A1 cosmetic 跳过",
  "    ",
  "    1581 测全过 / 0 analyze",
  "    ",
  "    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>",
  "",
  "diff --git a/data/numbers.yaml b/data/numbers.yaml",
  "index 172a4d5f3..5c705d4f6 100644",
  "--- a/data/numbers.yaml",
  "+++ b/data/numbers.yaml",
  "@@ -839,12 +839,24 @@ character:",
  "   # --- 奇遇属性加成（GDD §4.1）---",
  "   # 后天弥补先天，但有硬上限",
  "   adventure_attribute_bonus:",
  "-    lifetime_cap_per_character: 5     # 每个角色生涯总加成上限 +5",
  "+    lifetime_cap_per_character: 5     # 每个角色生涯总加成上限 +5(#4③ B2 已接 EncounterService.attributeGainCap)",
  "+    # ⚠️ bonus_per_event_min/max/distribution/weights 未运行时消费(#4③ B7 核账):",
  "+    # applyOutcome 用各 data/encounters.yaml outcome 写死的 attributeDelta,以下为设计参考。",
  "     bonus_per_event_min: 1            # 单次奇遇最少加 1 点",
  "     bonus_per_event_max: 3            # 单次奇遇最多加 3 点",
  "     distribution: \"weighted\"          # 大部分加 1，少数加 2-3",
  "     weights: [0.65, 0.25, 0.10]      # 1 点/2 点/3 点的概率",
  " ",
  "+# =============================================================================",
  "+# 6b. 奇遇系统",
  "+# =============================================================================",
  "+# GDD §7.2 武学领悟 · fortune 软概率灵敏度",
  "+",
  "+encounter:",
  "+  # fortune 软概率灵敏度:p = baseProbability * (1 + fortune / fortune_sensitivity)",
  "+  # (C-W14-1 决策点 Q3 · #4③ B5 从 encounter_service.dart 硬编码 20.0 外置)",
  "+  fortune_sensitivity: 20",
  "+",
  " # =============================================================================",
  " # 7. 闭关系统",
  " # ============================================================================="
]
```

<a id="q015"></a>
### Q015

```sh
git show --format=fuller --no-ext-diff --no-color 93a8687c4a48a410717346c36fda2358aeba81f2 -- data/numbers.yaml
```

命中/输出行数：46；退出码：0。

```json
[
  "commit 93a8687c4a48a410717346c36fda2358aeba81f2",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Fri Jul 3 02:06:52 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Fri Jul 3 02:06:52 2026 +0800",
  "",
  "    清理批次2/3零引用资产与死配置 + ExactAssetImage 迁 WuxiaImage",
  "    ",
  "    - 删 59 零引用资产(17 MJ *_01 旧稿 + 42 敌人立绘,独立 grep+移除史双证废弃品)",
  "    - numbers.yaml tower/synergies 死配置段补 unused 头注(证实 NumbersConfig.fromYaml 不解析)",
  "    - ExactAssetImage ×5 迁 WuxiaImage(seclusion 4 屏+portrait_frame,获 cacheWidth 收益)",
  "    - backlog 订正:3「死文件」(battle_engine/battle_demo/stage_auto_play_control)证伪为",
  "      测试基础设施/未接入组件不删 + 44.9MB→实59文件8MB + 多处 P2 drift 修正",
  "    ",
  "    纯资产/注释/表现层·零碰 numbers 数值/结算/saveVer/schema",
  "    analyze lib/ test/ 0·全量 flutter test --no-pub -j1 3587 passed/1 skip/0 fail 零回归",
  "    ",
  "    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>",
  "",
  "diff --git a/data/numbers.yaml b/data/numbers.yaml",
  "index 843a4a2cb..7895dc377 100644",
  "--- a/data/numbers.yaml",
  "+++ b/data/numbers.yaml",
  "@@ -1254,6 +1254,11 @@ festivals:",
  " # 8. 30 层爬塔\"问鼎江湖\"",
  " # =============================================================================",
  " # GDD §8.2：每天 5 次挑战次数，通关层数决定排行榜位置",
  "+#",
  "+# ⚠️ UNUSED（2026-07-03 六维审查批次3 证实）：本 `tower:` 整段未被 NumbersConfig.fromYaml",
  "+# 解析为字段（见 numbers_config.dart:18-19「其余段…tower…保留 raw」），lib/ 无任何消费。",
  "+# daily_attempts / difficulty_curve / boss_multiplier 均为设计意图记录：爬塔实际难度走",
  "+# towers.yaml，每日 5 次限制未实装。保留作 GDD §8.2 设计锚，勿据此以为已生效；接线或删除需拍板。",
  " ",
  " tower:",
  " ",
  "@@ -1376,6 +1381,10 @@ inheritance:",
  " # 10. 心法相生组合（GDD §4.5）",
  " # =============================================================================",
  " # 5 个隐藏组合的具体效果数值。组合判定逻辑见 SynergyDef，本段只给数值。",
  "+#",
  "+# ⚠️ UNUSED（2026-07-03 六维审查批次3 证实）：本 `synergies:` 整段未被 NumbersConfig.fromYaml",
  "+# 解析，lib/ 无消费。相生组合真实数据源是独立文件 data/synergies.yaml（12 条目，multipliers",
  "+# 格式，game_repository.dart:341 解析）。此处 5 条 effect_values 为历史残留，勿在此维护；删除需拍板。",
  " ",
  " synergies:",
  " "
]
```

<a id="q016"></a>
### Q016

```sh
git log -p --format=fuller --no-ext-diff --no-color c64b165938d948a24ab64c7c71de950eea466758 -Scultivation_multiplier -- lib
```

命中/输出行数：478；退出码：0。

```json
[
  "commit c66e983b16dac56b560cc375161580ba229d026b",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Mon Aug 24 09:12:45 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Mon Aug 24 09:31:10 2026 +0800",
  "",
  "    [schema] 移除心魔主修修炼度失败惩罚",
  "",
  "diff --git a/lib/data/defs/inner_demon_def.dart b/lib/data/defs/inner_demon_def.dart",
  "index b264c0583..5a68ef146 100644",
  "--- a/lib/data/defs/inner_demon_def.dart",
  "+++ b/lib/data/defs/inner_demon_def.dart",
  "@@ -6,7 +6,6 @@ import 'boss_vulnerability_def.dart';",
  " /// 7 关心魔(stage_inner_demon_01..07)拦截配置的境界层突破：",
  " ///   - mirror_buff_per_stage：各关镜像玩家 character 强化比例",
  " ///   - mirror_caps：§5.4 数值红线 cap（防玩家 build 超时镜像也超）",
  "-///   - failure_penalty：主修修炼度惩罚（内息紊乱走独立配置）",
  " ///   - unlock_triggers：触发关 victory → 下一关 unlock 链",
  " ///   - required_realm_layer：玩家当前境界达到该 layer 才能进入",
  " ///",
  "@@ -19,9 +18,6 @@ class InnerDemonDef {",
  "   /// §5.4 数值红线 cap。",
  "   final InnerDemonMirrorCaps mirrorCaps;",
  " ",
  "-  /// 失败惩罚（主修修炼度系数）。",
  "-  final InnerDemonFailurePenalty failurePenalty;",
  "-",
  "   /// 触发关 victory → 下一关 unlock 链。",
  "   final Map<String, String> unlockTriggers;",
  " ",
  "@@ -53,7 +49,6 @@ class InnerDemonDef {",
  "   const InnerDemonDef({",
  "     required this.mirrorBuffPerStage,",
  "     required this.mirrorCaps,",
  "-    required this.failurePenalty,",
  "     required this.unlockTriggers,",
  "     required this.requiredRealmLayer,",
  "     this.mirrorVulnerabilityPerStage = const {},",
  "@@ -74,7 +69,6 @@ class InnerDemonDef {",
  "       internalForceMax: 15000,",
  "       attackPowerMax: 6000,",
  "     ),",
  "-    failurePenalty: InnerDemonFailurePenalty(mainCultivationMultiplier: 0.90),",
  "     unlockTriggers: {},",
  "     requiredRealmLayer: {},",
  "     mirrorVulnerabilityPerStage: {},",
  "@@ -86,6 +80,11 @@ class InnerDemonDef {",
  " ",
  "   factory InnerDemonDef.fromYaml(Map<String, dynamic>? y) {",
  "     if (y == null) return InnerDemonDef.empty();",
  "+    if (y.containsKey('failure_penalty')) {",
  "+      throw const FormatException(",
  "+        'inner_demon.failure_penalty is retired; remove the entire section',",
  "+      );",
  "+    }",
  " ",
  "     final mirror = <String, double>{};",
  "     final mirrorYaml = y['mirror_buff_per_stage'] as Map?;",
  "@@ -162,9 +161,6 @@ class InnerDemonDef {",
  "       mirrorCaps: InnerDemonMirrorCaps.fromYaml(",
  "         y['mirror_caps'] as Map<String, dynamic>? ?? const {},",
  "       ),",
  "-      failurePenalty: InnerDemonFailurePenalty.fromYaml(",
  "-        y['failure_penalty'] as Map<String, dynamic>? ?? const {},",
  "-      ),",
  "       unlockTriggers: unlocks,",
  "       requiredRealmLayer: required,",
  "       mirrorVulnerabilityPerStage: vuln,",
  "@@ -209,36 +205,3 @@ class InnerDemonMirrorCaps {",
  "         attackPowerMax: (y['attack_power_max'] as num?)?.toInt() ?? 6000,",
  "       );",
  " }",
  "-",
  "-/// 心魔失败惩罚：主修修炼度系数；内息紊乱由独立配置提供。",
  "-class InnerDemonFailurePenalty {",
  "-  /// 主修心法修炼度扣减比例（new = old × 此值；0.90 = 扣 10%）。",
  "-  final double mainCultivationMultiplier;",
  "-",
  "-  const InnerDemonFailurePenalty({required this.mainCultivationMultiplier});",
  "-",
  "-  factory InnerDemonFailurePenalty.fromYaml(Map<String, dynamic> y) {",
  "-    const legacyKeys = {",
  "-      'internal_force_multiplier',",
  "-      'internal_force_floor_pct',",
  "-      'sub_cultivation_multiplier',",
  "-      'debuff_id',",
  "-      'debuff_clear_via_retreat_hours',",
  "-    };",
  "-    for (final key in legacyKeys) {",
  "-      if (y.containsKey(key)) {",
  "-        throw FormatException(",
  "-          'inner_demon.failure_penalty contains retired key: $key',",
  "-        );",
  "-      }",
  "-    }",
  "-    final multiplier =",
  "-        (y['main_cultivation_multiplier'] as num?)?.toDouble() ?? 0.90;",
  "-    if (!multiplier.isFinite || multiplier <= 0 || multiplier > 1) {",
  "-      throw const FormatException(",
  "-        'inner_demon.failure_penalty.main_cultivation_multiplier must be in (0,1]',",
  "-      );",
  "-    }",
  "-    return InnerDemonFailurePenalty(mainCultivationMultiplier: multiplier);",
  "-  }",
  "-}",
  "",
  "commit f11183e40dc0ec2e2d38f17310f4a54c81f9495a",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Sun Aug 23 19:08:10 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Sun Aug 23 19:08:10 2026 +0800",
  "",
  "    清理心魔失败旧惩罚字段",
  "",
  "diff --git a/lib/data/defs/inner_demon_def.dart b/lib/data/defs/inner_demon_def.dart",
  "index 5f22b4e7f..01825bac2 100644",
  "--- a/lib/data/defs/inner_demon_def.dart",
  "+++ b/lib/data/defs/inner_demon_def.dart",
  "@@ -6,7 +6,7 @@ import 'boss_vulnerability_def.dart';",
  " /// 7 关心魔(stage_inner_demon_01..07)拦截配置的境界层突破：",
  " ///   - mirror_buff_per_stage：各关镜像玩家 character 强化比例",
  " ///   - mirror_caps：§5.4 数值红线 cap（防玩家 build 超时镜像也超）",
  "-///   - failure_penalty：散功 ×0.5 阉割版（GDD §6 半惩罚）",
  "+///   - failure_penalty：主修修炼度惩罚（内息紊乱走独立配置）",
  " ///   - unlock_triggers：触发关 victory → 下一关 unlock 链",
  " ///   - required_realm_layer：玩家当前境界达到该 layer 才能进入",
  " ///",
  "@@ -19,7 +19,7 @@ class InnerDemonDef {",
  "   /// §5.4 数值红线 cap。",
  "   final InnerDemonMirrorCaps mirrorCaps;",
  " ",
  "-  /// 失败惩罚（散功 ×0.5 阉割版）。",
  "+  /// 失败惩罚（主修修炼度系数）。",
  "   final InnerDemonFailurePenalty failurePenalty;",
  " ",
  "   /// 触发关 victory → 下一关 unlock 链。",
  "@@ -74,14 +74,7 @@ class InnerDemonDef {",
  "       internalForceMax: 15000,",
  "       attackPowerMax: 6000,",
  "     ),",
  "-    failurePenalty: InnerDemonFailurePenalty(",
  "-      internalForceMultiplier: 0.85,",
  "-      mainCultivationMultiplier: 0.90,",
  "-      subCultivationMultiplier: 1.00,",
  "-      debuffId: 'inner_demon_residue',",
  "-      debuffClearViaRetreatHours: 8,",
  "-      internalForceFloorPct: 0.50,",
  "-    ),",
  "+    failurePenalty: InnerDemonFailurePenalty(mainCultivationMultiplier: 0.90),",
  "     unlockTriggers: {},",
  "     requiredRealmLayer: {},",
  "     mirrorVulnerabilityPerStage: {},",
  "@@ -217,52 +210,37 @@ class InnerDemonMirrorCaps {",
  "       );",
  " }",
  " ",
  "-/// 失败惩罚（散功 ×0.5 阉割版，GDD §6 半惩罚）。",
  "+/// 心魔失败惩罚：主修修炼度系数；内息紊乱由独立配置提供。",
  " class InnerDemonFailurePenalty {",
  "-  /// 当前内力扣减比例（new = old × 此值；0.85 = 扣 15%）。",
  "-  final double internalForceMultiplier;",
  "-",
  "   /// 主修心法修炼度扣减比例（new = old × 此值；0.90 = 扣 10%）。",
  "   final double mainCultivationMultiplier;",
  " ",
  "-  /// 辅修不受影响（1.00 = 不动）。",
  "-  /// UNUSED(0 生产消费 · 审计 D5 2026-06-24):心魔惩罚仅扣主修",
  "-  /// (mainCultivationMultiplier 真消费),辅修恒不动语义已由\"不触碰辅修字段\"实现,",
  "-  /// 本字段从无读取方。保留作语义文档(显式声明辅修=1.00),真要分级扣辅修时再接。",
  "-  final double subCultivationMultiplier;",
  "-",
  "-  /// 心魔余毒 debuff id。",
  "-  /// UNUSED(0 生产消费 · 审计 D5 2026-06-24):仅 inner_demon_service_test 断言其值,",
  "-  /// 余毒 debuff 的实际施加/清解路径不读此字段。保留作配置锚,真要按 id 派发 debuff 时再接。",
  "-  final String debuffId;",
  "-",
  "-  /// 闭关 N 小时清解 debuff。",
  "-  final int debuffClearViaRetreatHours;",
  "-",
  "-  /// 内力扣减地板（new 内力不低于 internalForceMax × 此值；防无限重试归零）。",
  "-  final double internalForceFloorPct;",
  "-",
  "-  const InnerDemonFailurePenalty({",
  "-    required this.internalForceMultiplier,",
  "-    required this.mainCultivationMultiplier,",
  "-    required this.subCultivationMultiplier,",
  "-    required this.debuffId,",
  "-    required this.debuffClearViaRetreatHours,",
  "-    required this.internalForceFloorPct,",
  "-  });",
  "-",
  "-  factory InnerDemonFailurePenalty.fromYaml(Map<String, dynamic> y) =>",
  "-      InnerDemonFailurePenalty(",
  "-        internalForceMultiplier:",
  "-            (y['internal_force_multiplier'] as num?)?.toDouble() ?? 0.85,",
  "-        mainCultivationMultiplier:",
  "-            (y['main_cultivation_multiplier'] as num?)?.toDouble() ?? 0.90,",
  "-        subCultivationMultiplier:",
  "-            (y['sub_cultivation_multiplier'] as num?)?.toDouble() ?? 1.00,",
  "-        debuffId: y['debuff_id'] as String? ?? 'inner_demon_residue',",
  "-        debuffClearViaRetreatHours:",
  "-            (y['debuff_clear_via_retreat_hours'] as num?)?.toInt() ?? 8,",
  "-        internalForceFloorPct:",
  "-            (y['internal_force_floor_pct'] as num?)?.toDouble() ?? 0.50,",
  "+  const InnerDemonFailurePenalty({required this.mainCultivationMultiplier});",
  "+",
  "+  factory InnerDemonFailurePenalty.fromYaml(Map<String, dynamic> y) {",
  "+    const legacyKeys = {",
  "+      'internal_force_multiplier',",
  "+      'internal_force_floor_pct',",
  "+      'sub_cultivation_multiplier',",
  "+      'debuff_id',",
  "+      'debuff_clear_via_retreat_hours',",
  "+    };",
  "+    for (final key in legacyKeys) {",
  "+      if (y.containsKey(key)) {",
  "+        throw FormatException(",
  "+          'inner_demon.failure_penalty contains retired key: $key',",
  "+        );",
  "+      }",
  "+    }",
  "+    final multiplier = (y['main_cultivation_multiplier'] as num?)?.toDouble();",
  "+    if (multiplier == null ||",
  "+        !multiplier.isFinite ||",
  "+        multiplier <= 0 ||",
  "+        multiplier > 1) {",
  "+      throw const FormatException(",
  "+        'inner_demon.failure_penalty.main_cultivation_multiplier must be in (0,1]',",
  "       );",
  "+    }",
  "+    return InnerDemonFailurePenalty(mainCultivationMultiplier: multiplier);",
  "+  }",
  " }",
  "",
  "commit 4c17119d7228d5bf33cee0dac59546c295cfb6c0",
  "Author:     Zed1118 <1050613234@qq.com>",
  "AuthorDate: Fri May 22 22:07:52 2026 +0800",
  "Commit:     Zed1118 <1050613234@qq.com>",
  "CommitDate: Fri May 22 22:07:52 2026 +0800",
  "",
  "    feat(p2.2 心魔 Batch 2.2.A): InnerDemonDef + InnerDemonService.isLayerLocked + advancement_service hook",
  "    ",
  "    vertical slice 关键路径:hook 机制 + unit test 验证,production 3 callers wire 推 Batch 2.2.B 与 recordVictory + 镜像 enemy 一起。",
  "    ",
  "    新建文件:",
  "    - lib/features/inner_demon/domain/inner_demon_def.dart (206 行):InnerDemonDef + RealmCoord + MirrorCaps + FailurePenalty + ResidueDebuff;fromYaml 解析 numbers.yaml inner_demon 段 + empty fallback(fixture 兼容)",
  "    - lib/features/inner_demon/application/inner_demon_service.dart (55 行):isLayerLocked 静态方法 — 非 wuSheng 短路 / qiMeng 跨 tier 起步层放行 / wuSheng 内查 prev layer 拦截关 cleared 集",
  "    - test/features/inner_demon/application/inner_demon_service_test.dart (8 test):R1.1 非 wuSheng / R1.2 跨 tier qiMeng / R1.3 未通拦 / R1.4 已通放行 / R1.5 阶梯锁 / R1.6 empty def + fromYaml 完整+null",
  "    ",
  "    改动文件:",
  "    - lib/data/numbers_config.dart:加 innerDemon: InnerDemonDef field + fromYaml 调用(fixture 兼容走 InnerDemonDef.empty())",
  "    - lib/features/cultivation/application/character_advancement_service.dart:applyExperience 加 bool Function(RealmTier, RealmLayer)? isLayerLocked 可选参数;while-loop 内 next 算出后 hook 查询,拦截则 break(EXP 留账不消费,GDD §5.1 反留存焦虑)",
  "    - test/features/cultivation/application/character_advancement_service_test.dart:+R1 group 6 test(null=原行为 / 始终拦 / 选择性拦 / 信任完全 / 阶梯锁 / 拦截不动 cap)",
  "    ",
  "    验证:flutter analyze 0 issue / flutter test 1206 pass(原 1192 + 新 14)0 fail / production caller 0 改动(hook default null,Demo 路径同 1.0 前)",
  "    ",
  "    Batch 2.2.A 范围调整:spec doc Batch 2.2 列的 InnerDemonStrategy implements BattleStrategy 不建(YAGNI,memory feedback_avoid_over_engineer_abstraction;BattleStrategy 是 tick 层,enemy 构造在 setup 层职责)。InnerDemonScreen + BreakthroughBlocker UI 推 Batch 2.3 前(narrative 文案 ready 后 widget 才有内容)。",
  "    ",
  "    Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>",
  "",
  "diff --git a/lib/features/inner_demon/domain/inner_demon_def.dart b/lib/features/inner_demon/domain/inner_demon_def.dart",
  "new file mode 100644",
  "index 000000000..db76cc120",
  "--- /dev/null",
  "+++ b/lib/features/inner_demon/domain/inner_demon_def.dart",
  "@@ -0,0 +1,212 @@",
  "+import '../../../core/domain/enums.dart';",
  "+",
  "+/// 心魔系统配置（1.0 P2.2 §12.1，data/numbers.yaml `inner_demon` 段强类型化）。",
  "+///",
  "+/// 7 关心魔(stage_inner_demon_01..07)拦截 wuSheng 7 层突破：",
  "+///   - mirror_buff_per_stage：各关镜像玩家 character 强化比例",
  "+///   - mirror_caps：§5.4 数值红线 cap（防玩家 build 超时镜像也超）",
  "+///   - failure_penalty：散功 ×0.5 阉割版（GDD §6 半惩罚）",
  "+///   - residue_debuff：心魔余毒 buff 效果（闭关 8h 清）",
  "+///   - unlock_triggers：触发关 victory → 下一关 unlock 链",
  "+///   - required_realm_layer：玩家当前境界达到该 layer 才能进入",
  "+///",
  "+/// fixture 兼容：numbers.yaml 不含 inner_demon 段时走 [InnerDemonDef.empty]",
  "+/// （所有 Map 空、InnerDemonService.isLayerLocked 始终返 false → 行为同 1.0 前）。",
  "+class InnerDemonDef {",
  "+  /// stage_id → 镜像强化比例（如 stage_inner_demon_01 → 0.10）。",
  "+  final Map<String, double> mirrorBuffPerStage;",
  "+",
  "+  /// §5.4 数值红线 cap。",
  "+  final InnerDemonMirrorCaps mirrorCaps;",
  "+",
  "+  /// 失败惩罚（散功 ×0.5 阉割版）。",
  "+  final InnerDemonFailurePenalty failurePenalty;",
  "+",
  "+  /// 心魔余毒 buff 效果。",
  "+  final InnerDemonResidueDebuff residueDebuff;",
  "+",
  "+  /// 触发关 victory → 下一关 unlock 链（如 stage_06_05 → stage_inner_demon_01）。",
  "+  final Map<String, String> unlockTriggers;",
  "+",
  "+  /// stage_id → 玩家当前境界达到该 layer 才能进入（如 stage_inner_demon_01 →",
  "+  /// wuSheng·qiMeng）。",
  "+  final Map<String, RealmCoord> requiredRealmLayer;",
  "+",
  "+  const InnerDemonDef({",
  "+    required this.mirrorBuffPerStage,",
  "+    required this.mirrorCaps,",
  "+    required this.failurePenalty,",
  "+    required this.residueDebuff,",
  "+    required this.unlockTriggers,",
  "+    required this.requiredRealmLayer,",
  "+  });",
  "+",
  "+  /// numbers.yaml 不含 `inner_demon` 段时的空值（fixture 兼容 + Demo 路径无心魔）。",
  "+  ///",
  "+  /// 所有 Map 空 → InnerDemonService.isLayerLocked 始终返 false，不破现有",
  "+  /// applyExperience while-loop 升层行为。",
  "+  factory InnerDemonDef.empty() => const InnerDemonDef(",
  "+        mirrorBuffPerStage: {},",
  "+        mirrorCaps: InnerDemonMirrorCaps(",
  "+          hpMax: 20000,",
  "+          internalForceMax: 15000,",
  "+          attackPowerMax: 2000,",
  "+        ),",
  "+        failurePenalty: InnerDemonFailurePenalty(",
  "+          internalForceMultiplier: 0.85,",
  "+          mainCultivationMultiplier: 0.90,",
  "+          subCultivationMultiplier: 1.00,",
  "+          debuffId: 'inner_demon_residue',",
  "+          debuffClearViaRetreatHours: 8,",
  "+        ),",
  "+        residueDebuff: InnerDemonResidueDebuff(",
  "+          battleOutputMultiplier: 0.95,",
  "+          internalForceRecoveryMultiplier: 0.80,",
  "+        ),",
  "+        unlockTriggers: {},",
  "+        requiredRealmLayer: {},",
  "+      );",
  "+",
  "+  factory InnerDemonDef.fromYaml(Map<String, dynamic>? y) {",
  "+    if (y == null) return InnerDemonDef.empty();",
  "+",
  "+    final mirror = <String, double>{};",
  "+    final mirrorYaml = y['mirror_buff_per_stage'] as Map?;",
  "+    if (mirrorYaml != null) {",
  "+      for (final e in mirrorYaml.entries) {",
  "+        mirror[e.key as String] = (e.value as num).toDouble();",
  "+      }",
  "+    }",
  "+",
  "+    final unlocks = <String, String>{};",
  "+    final unlocksYaml = y['unlock_triggers'] as Map?;",
  "+    if (unlocksYaml != null) {",
  "+      for (final e in unlocksYaml.entries) {",
  "+        unlocks[e.key as String] = e.value as String;",
  "+      }",
  "+    }",
  "+",
  "+    final required = <String, RealmCoord>{};",
  "+    final requiredYaml = y['required_realm_layer'] as Map?;",
  "+    if (requiredYaml != null) {",
  "+      for (final e in requiredYaml.entries) {",
  "+        final v = e.value as Map;",
  "+        required[e.key as String] = RealmCoord(",
  "+          tier: RealmTier.values.byName(v['tier'] as String),",
  "+          layer: RealmLayer.values.byName(v['layer'] as String),",
  "+        );",
  "+      }",
  "+    }",
  "+",
  "+    return InnerDemonDef(",
  "+      mirrorBuffPerStage: mirror,",
  "+      mirrorCaps: InnerDemonMirrorCaps.fromYaml(",
  "+        y['mirror_caps'] as Map<String, dynamic>? ?? const {},",
  "+      ),",
  "+      failurePenalty: InnerDemonFailurePenalty.fromYaml(",
  "+        y['failure_penalty'] as Map<String, dynamic>? ?? const {},",
  "+      ),",
  "+      residueDebuff: InnerDemonResidueDebuff.fromYaml(",
  "+        y['residue_debuff'] as Map<String, dynamic>? ?? const {},",
  "+      ),",
  "+      unlockTriggers: unlocks,",
  "+      requiredRealmLayer: required,",
  "+    );",
  "+  }",
  "+}",
  "+",
  "+/// (tier, layer) record 别名 — 与 character_advancement_service.nextLayer 返回值",
  "+/// 同构（避免引入新结构）。",
  "+class RealmCoord {",
  "+  final RealmTier tier;",
  "+  final RealmLayer layer;",
  "+  const RealmCoord({required this.tier, required this.layer});",
  "+",
  "+  @override",
  "+  bool operator ==(Object other) =>",
  "+      other is RealmCoord && other.tier == tier && other.layer == layer;",
  "+",
  "+  @override",
  "+  int get hashCode => Object.hash(tier, layer);",
  "+}",
  "+",
  "+/// §5.4 数值红线 cap（防玩家 build 超时镜像也超）。",
  "+class InnerDemonMirrorCaps {",
  "+  final int hpMax;",
  "+  final int internalForceMax;",
  "+  final int attackPowerMax;",
  "+  const InnerDemonMirrorCaps({",
  "+    required this.hpMax,",
  "+    required this.internalForceMax,",
  "+    required this.attackPowerMax,",
  "+  });",
  "+",
  "+  factory InnerDemonMirrorCaps.fromYaml(Map<String, dynamic> y) =>",
  "+      InnerDemonMirrorCaps(",
  "+        hpMax: (y['hp_max'] as num?)?.toInt() ?? 20000,",
  "+        internalForceMax: (y['internal_force_max'] as num?)?.toInt() ?? 15000,",
  "+        attackPowerMax: (y['attack_power_max'] as num?)?.toInt() ?? 2000,",
  "+      );",
  "+}",
  "+",
  "+/// 失败惩罚（散功 ×0.5 阉割版，GDD §6 半惩罚）。",
  "+class InnerDemonFailurePenalty {",
  "+  /// 当前内力扣减比例（new = old × 此值；0.85 = 扣 15%）。",
  "+  final double internalForceMultiplier;",
  "+",
  "+  /// 主修心法修炼度扣减比例（new = old × 此值；0.90 = 扣 10%）。",
  "+  final double mainCultivationMultiplier;",
  "+",
  "+  /// 辅修不受影响（1.00 = 不动）。",
  "+  final double subCultivationMultiplier;",
  "+",
  "+  /// 心魔余毒 debuff id。",
  "+  final String debuffId;",
  "+",
  "+  /// 闭关 N 小时清解 debuff。",
  "+  final int debuffClearViaRetreatHours;",
  "+",
  "+  const InnerDemonFailurePenalty({",
  "+    required this.internalForceMultiplier,",
  "+    required this.mainCultivationMultiplier,",
  "+    required this.subCultivationMultiplier,",
  "+    required this.debuffId,",
  "+    required this.debuffClearViaRetreatHours,",
  "+  });",
  "+",
  "+  factory InnerDemonFailurePenalty.fromYaml(Map<String, dynamic> y) =>",
  "+      InnerDemonFailurePenalty(",
  "+        internalForceMultiplier:",
  "+            (y['internal_force_multiplier'] as num?)?.toDouble() ?? 0.85,",
  "+        mainCultivationMultiplier:",
  "+            (y['main_cultivation_multiplier'] as num?)?.toDouble() ?? 0.90,",
  "+        subCultivationMultiplier:",
  "+            (y['sub_cultivation_multiplier'] as num?)?.toDouble() ?? 1.00,",
  "+        debuffId: y['debuff_id'] as String? ?? 'inner_demon_residue',",
  "+        debuffClearViaRetreatHours:",
  "+            (y['debuff_clear_via_retreat_hours'] as num?)?.toInt() ?? 8,",
  "+      );",
  "+}",
  "+",
  "+/// 心魔余毒 buff 效果（闭关 8h 清）。",
  "+class InnerDemonResidueDebuff {",
  "+  /// 战斗输出乘数（0.95 = -5%）。",
  "+  final double battleOutputMultiplier;",
  "+",
  "+  /// 内力恢复乘数（0.80 = -20%）。",
  "+  final double internalForceRecoveryMultiplier;",
  "+",
  "+  const InnerDemonResidueDebuff({",
  "+    required this.battleOutputMultiplier,",
  "+    required this.internalForceRecoveryMultiplier,",
  "+  });",
  "+",
  "+  factory InnerDemonResidueDebuff.fromYaml(Map<String, dynamic> y) =>",
  "+      InnerDemonResidueDebuff(",
  "+        battleOutputMultiplier:",
  "+            (y['battle_output_multiplier'] as num?)?.toDouble() ?? 0.95,",
  "+        internalForceRecoveryMultiplier:",
  "+            (y['internal_force_recovery_multiplier'] as num?)?.toDouble() ??",
  "+                0.80,",
  "+      );",
  "+}"
]
```

<a id="q017"></a>
### Q017

```sh
rg -n --with-filename --no-heading --sort path -- meta lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：2；退出码：0。

```text
lib/data/numbers_config.dart:346:    final meta = y['meta'] as Map<String, dynamic>;
lib/data/numbers_config.dart:353:      version: meta['version'] as String,
```

<a id="q018"></a>
### Q018

```sh
sed -n 345,354p lib/data/numbers_config.dart
```

命中/输出行数：10；退出码：0。

```text
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
    final meta = y['meta'] as Map<String, dynamic>;
    final combat = y['combat'] as Map<String, dynamic>;
    final realms = y['realms'] as Map<String, dynamic>;
    final equipment = y['equipment'] as Map<String, dynamic>;
    final techniques = y['techniques'] as Map<String, dynamic>;

    return NumbersConfig(
      version: meta['version'] as String,
      combat: CombatNumbers.fromYaml(combat),
```

<a id="q019"></a>
### Q019

```sh
sed -n 346,346p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
    final meta = y['meta'] as Map<String, dynamic>;
```

<a id="q020"></a>
### Q020

```sh
sed -n 353,353p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      version: meta['version'] as String,
```

<a id="q021"></a>
### Q021

```sh
rg -n --with-filename --no-heading --sort path -- damage_formula lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
lib/data/numbers_config.dart:1367:        y['damage_formula'] as Map<String, dynamic>,
```

<a id="q022"></a>
### Q022

```sh
sed -n 2429,2435p lib/data/numbers_config.dart
```

命中/输出行数：7；退出码：0。

```text
  factory DamageFormula.fromYaml(Map<String, dynamic> y) {
    return DamageFormula(
      internalForceFactor: (y['internal_force_factor'] as num).toDouble(),
      equipmentAttackFactor: (y['equipment_attack_factor'] as num).toDouble(),
    );
  }
}
```

<a id="q023"></a>
### Q023

```sh
sed -n 2429,2429p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  factory DamageFormula.fromYaml(Map<String, dynamic> y) {
```

<a id="q024"></a>
### Q024

```sh
rg -n --with-filename --no-heading --sort path -- 'combat|final_damage_formula' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：106；退出码：0。

```text
lib/data/numbers_config.dart:23:/// Phase 1 仅强类型化战斗会用到的 [combat] 与 [levelDiffModifier]，
lib/data/numbers_config.dart:30:  final CombatNumbers combat;
lib/data/numbers_config.dart:39:  /// `combat.skill_proficiency`,全局阶段倍率(末阶 1.30 作综合 cap)。
lib/data/numbers_config.dart:207:  /// numbers.yaml `jianghu` 段:7 阶 reputation_tiers + enmity_combat_modifier + triggers。
lib/data/numbers_config.dart:281:    required this.combat,
lib/data/numbers_config.dart:347:    final combat = y['combat'] as Map<String, dynamic>;
lib/data/numbers_config.dart:354:      combat: CombatNumbers.fromYaml(combat),
lib/data/numbers_config.dart:364:        combat['skill_proficiency'] as Map<String, dynamic>?,
lib/data/numbers_config.dart:1267:/// 刚猛克阴柔额外震伤配置(numbers.yaml `combat.schools.gang_meng_quake`)。
lib/data/numbers_config.dart:1295:/// 阴柔克灵巧内伤 debuff 配置(numbers.yaml `combat.schools.yin_rou_internal_injury`)。
lib/data/numbers_config.dart:1327:/// 战斗段强类型（numbers.yaml `combat`）。
lib/data/numbers_config.dart:1403:/// Unified posture values from `combat.posture`.
lib/data/numbers_config.dart:1424:      throw StateError('combat.posture must be a map');
lib/data/numbers_config.dart:1437:        'combat.posture.recovery_policy must be reset or recover',
lib/data/numbers_config.dart:1449:      throw StateError('combat.posture.capacity must be positive');
lib/data/numbers_config.dart:1452:      throw StateError('combat.posture.vulnerability_ticks must be positive');
lib/data/numbers_config.dart:1457:        'combat.posture.post_vulnerability_accumulated must be within capacity',
lib/data/numbers_config.dart:1463:        'combat.posture.post_vulnerability_accumulated must be zero for reset',
lib/data/numbers_config.dart:1468:        'combat.posture.boss_conversion_factor must be positive',
lib/data/numbers_config.dart:1484:    throw StateError('combat.posture.$key must be a finite number');
lib/data/numbers_config.dart:1492:    throw StateError('combat.posture.$key must be an integer');
lib/data/numbers_config.dart:1497:/// Bounded per-battle qi economy (`combat.qi`).
lib/data/numbers_config.dart:1533:          _missingRequiredValue('combat.qi.base_max'),
lib/data/numbers_config.dart:1536:          _missingRequiredValue('combat.qi.opening_qi'),
lib/data/numbers_config.dart:1539:          _missingRequiredValue('combat.qi.enemy_opening_qi'),
lib/data/numbers_config.dart:1542:          _missingRequiredValue('combat.qi.boss_opening_bonus'),
lib/data/numbers_config.dart:1545:          _missingRequiredValue('combat.qi.tower_boss_opening_bonus'),
lib/data/numbers_config.dart:1548:          _missingRequiredValue('combat.qi.opening_cap'),
lib/data/numbers_config.dart:1551:          _missingRequiredValue('combat.qi.min_max'),
lib/data/numbers_config.dart:1554:          _missingRequiredValue('combat.qi.max_cap'),
lib/data/numbers_config.dart:1557:          _missingRequiredValue('combat.qi.school_bonus'),
lib/data/numbers_config.dart:1560:          _missingRequiredValue('combat.qi.chain_recovery_pct'),
lib/data/numbers_config.dart:1563:          _missingRequiredValue('combat.qi.gain_multiplier_cap'),
lib/data/numbers_config.dart:1566:          _missingRequiredValue('combat.qi.cost_reduction_cap'),
lib/data/numbers_config.dart:1569:          _missingRequiredValue('combat.qi.delta_abs_cap'),
lib/data/numbers_config.dart:1586:      throw StateError('combat.qi 配置越界: $y');
lib/data/numbers_config.dart:1690:          'combat.readable_first_clear.enemy_hp_multiplier',
lib/data/numbers_config.dart:1697:          'combat.readable_first_clear.enemy_attack_multiplier',
lib/data/numbers_config.dart:1702:          'combat.readable_first_clear.opening_auto_skill_cooldown_turns',
lib/data/numbers_config.dart:1707:          'combat.readable_first_clear.auto_skill_power_multiplier',
lib/data/numbers_config.dart:1710:      throw StateError('combat.readable_first_clear 倍率必须 > 0');
lib/data/numbers_config.dart:1713:      throw StateError('combat.readable_first_clear 开局冷却不能为负');
lib/data/numbers_config.dart:1716:      throw StateError('combat.readable_first_clear 自动技能倍率须在 (0, 1]');
lib/data/numbers_config.dart:1728:/// P0 破招:Boss 招牌技蓄力/被破招踉跄配置(numbers.yaml `combat.boss_charge`)。
lib/data/numbers_config.dart:1749:        _missingRequiredValue('combat.boss_charge.default_charge_ticks'),
lib/data/numbers_config.dart:1752:        _missingRequiredValue('combat.boss_charge.default_stagger_ticks'),
lib/data/numbers_config.dart:1755:        _missingRequiredValue('combat.boss_charge.stagger_defense_down'),
lib/data/numbers_config.dart:1758:        _missingRequiredValue('combat.boss_charge.interrupt_power_cap'),
lib/data/numbers_config.dart:1772:        _missingRequiredValue('combat.defense_break.window_ticks'),
lib/data/numbers_config.dart:1776:/// 第七阶段批二②:Boss 弱点/抗性乘子值域(numbers.yaml `combat.weakness`)。
lib/data/numbers_config.dart:1788:        _missingRequiredValue('combat.weakness.min_mult'),
lib/data/numbers_config.dart:1791:        _missingRequiredValue('combat.weakness.max_mult'),
lib/data/numbers_config.dart:1795:/// 批次 2.4 打击感表现层三档参数（numbers.yaml `combat.impact_feedback`）。
lib/data/numbers_config.dart:1890:/// 数值红线 cap 强类型（numbers.yaml `combat.red_lines`，GDD §5.4 硬上限）。
lib/data/numbers_config.dart:1926:          _missingRequiredValue('combat.red_lines.player_hp_max'),
lib/data/numbers_config.dart:1929:          _missingRequiredValue('combat.red_lines.internal_force_max'),
lib/data/numbers_config.dart:1932:          _missingRequiredValue('combat.red_lines.boss_hp_max'),
lib/data/numbers_config.dart:1935:          _missingRequiredValue('combat.red_lines.equipment_base_attack_max'),
lib/data/numbers_config.dart:1938:          _missingRequiredValue('combat.red_lines.skill_power_multiplier_max'),
lib/data/numbers_config.dart:1941:          _missingRequiredValue('combat.red_lines.damage_readability_max'),
lib/data/numbers_config.dart:1945:            'combat.red_lines.normal_damage_typical_target',
lib/data/numbers_config.dart:1949:          _missingRequiredValue('combat.red_lines.combined_rate_cap'),
lib/data/numbers_config.dart:1954:/// 敌人合成默认值（numbers.yaml `combat.enemy_defaults`，P2-a/b 外部 review）。
lib/data/numbers_config.dart:2457:          _missingRequiredValue('combat.max_hp_formula.realm_level_factor'),
lib/data/numbers_config.dart:2591:  /// 批次 2.4 后不再被消费：战斗屏震振幅改走 combat.impact_feedback 分档
lib/data/numbers_config.dart:3086:        (y['enmity_combat_modifier'] as Map?)?.cast<String, dynamic>() ??
lib/data/numbers_config.dart:3155:          _missingRequiredValue('jianghu.enmity_combat_modifier.threshold'),
lib/data/numbers_config.dart:3159:            'jianghu.enmity_combat_modifier.player_attack_power_mult',
lib/data/numbers_config.dart:3164:            'jianghu.enmity_combat_modifier.enemy_attack_power_mult',
lib/data/numbers_config.dart:3169:            'jianghu.enmity_combat_modifier.severe_threshold',
lib/data/numbers_config.dart:3173:          _missingRequiredValue('jianghu.enmity_combat_modifier.severe_mult'),
lib/data/numbers_config.dart:3176:          _missingRequiredValue('jianghu.enmity_combat_modifier.clamp_max'),
lib/data/numbers_config.dart:3592:/// `combat.skill_proficiency.stages`;末阶 damageMult 作综合加成 cap。
lib/data/game_repository.dart:28:import 'combat_catalog_repository.dart';
lib/data/game_repository.dart:29:import 'defs/combat_catalog_manifest_def.dart';
lib/data/game_repository.dart:30:import 'defs/combat_encounter_def.dart';
lib/data/game_repository.dart:31:import 'defs/combat_enemy_archetype_def.dart';
lib/data/game_repository.dart:32:import 'defs/combat_runtime_binding_def.dart';
lib/data/game_repository.dart:34:import 'combat_runtime_binding_loader.dart';
lib/data/game_repository.dart:135:  /// **graceful**:test fixture 不带 md 时为空 map;档 8 `combat_advanced.md`
lib/data/game_repository.dart:168:  final CombatCatalogManifestDef? combatCatalog;
lib/data/game_repository.dart:169:  final CombatRuntimeBindingCatalog? combatRuntimeBindings;
lib/data/game_repository.dart:197:    this.combatCatalog,
lib/data/game_repository.dart:198:    this.combatRuntimeBindings,
lib/data/game_repository.dart:478:    final combatCatalog = await loadProductionCombatCatalogIfPresent(load);
lib/data/game_repository.dart:479:    final combatRuntimeBindings = combatCatalog == null
lib/data/game_repository.dart:483:            manifest: combatCatalog,
lib/data/game_repository.dart:494:    final weaponAttackProfiles = combatCatalog == null
lib/data/game_repository.dart:523:      combatCatalog: combatCatalog,
lib/data/game_repository.dart:524:      combatRuntimeBindings: combatRuntimeBindings,
lib/data/game_repository.dart:803:    // §5.4 内力红线上界走单一真相源 numbers.combat.red_lines(2026-05-29 消
lib/data/game_repository.dart:805:    final ifMax = numbers.combat.redLines.internalForceMax;
lib/data/game_repository.dart:938:      numbers.combat.weakness.minMult,
lib/data/game_repository.dart:939:      numbers.combat.weakness.maxMult,
lib/data/game_repository.dart:1215:        final redLines = numbers.combat.redLines;
lib/data/game_repository.dart:1288:      throw StateError('expeditions: combat.depth_curve 未配置');
lib/data/game_repository.dart:1290:    final redLines = numbers.combat.redLines;
lib/data/game_repository.dart:1402:  /// 按显式 production combat catalog assignment 查询 stage。
lib/data/game_repository.dart:1403:  CombatStageEncounterAssignment? combatAssignmentForStage(String stageId) =>
lib/data/game_repository.dart:1404:      combatCatalog?.assignmentForStage(stageId);
lib/data/game_repository.dart:1407:  CombatEncounterDef? combatEncounterForStage(String stageId) =>
lib/data/game_repository.dart:1408:      combatCatalog?.encounterForStage(stageId);
lib/data/game_repository.dart:1411:  CombatEnemyArchetypeDef? combatArchetypeById(String archetypeId) =>
lib/data/game_repository.dart:1412:      combatCatalog?.archetypeById(archetypeId);
lib/data/game_repository.dart:1416:  CombatRuntimeStageBinding? combatRuntimeBindingForStage(String stageId) =>
lib/data/game_repository.dart:1417:      combatRuntimeBindings?.bindingForStage(stageId);
```

<a id="q025"></a>
### Q025

```sh
sed -n 1361,1398p lib/data/numbers_config.dart
```

命中/输出行数：38；退出码：0。

```text
  factory CombatNumbers.fromYaml(Map<String, dynamic> y) {
    return CombatNumbers(
      qi: QiConfig.fromYaml(
        (y['qi'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      damageFormula: DamageFormula.fromYaml(
        y['damage_formula'] as Map<String, dynamic>,
      ),
      maxHpFormula: MaxHpFormula.fromYaml(
        y['max_hp_formula'] as Map<String, dynamic>,
      ),
      speedFormula: SpeedFormula.fromYaml(
        y['speed_formula'] as Map<String, dynamic>,
      ),
      critical: CriticalConfig.fromYaml(y['critical'] as Map<String, dynamic>),
      evasion: EvasionConfig.fromYaml(y['evasion'] as Map<String, dynamic>),
      enemyDefaults: EnemyDefaults.fromYaml(
        y['enemy_defaults'] as Map<String, dynamic>,
      ),
      readableFirstClear: ReadableFirstClearConfig.fromYaml(
        y['readable_first_clear'] as Map?,
      ),
      redLines: RedLinesConfig.fromYaml(
        y['red_lines'] as Map<String, dynamic>? ?? const {},
      ),
      bossCharge: BossChargeConfig.fromYaml(
        y['boss_charge'] as Map? ?? const {},
      ),
      impactFeedback: ImpactFeedbackConfig.fromYaml(
        y['impact_feedback'] as Map? ?? const {},
      ),
      posture: PostureNumbersConfig.fromYaml(y['posture']),
      defenseBreak: DefenseBreakConfig.fromYaml(
        y['defense_break'] as Map? ?? const {},
      ),
      weakness: WeaknessConfig.fromYaml(y['weakness'] as Map? ?? const {}),
    );
  }
```

<a id="q026"></a>
### Q026

```sh
sed -n 1361,1361p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  factory CombatNumbers.fromYaml(Map<String, dynamic> y) {
```

<a id="q027"></a>
### Q027

```sh
rg -n --with-filename --no-heading --sort path -- 'equipment|tiers' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：119；退出码：0。

```text
lib/data/numbers_config.dart:8:import 'defs/equipment_disposal_def.dart';
lib/data/numbers_config.dart:24:/// 其余段（equipment / techniques / skills / character / retreat / tower /
lib/data/numbers_config.dart:54:  /// 装备强化每级加成系数（numbers.yaml `equipment.enhancement.bonus_per_level`，
lib/data/numbers_config.dart:58:  /// 强化系统配置（numbers.yaml `equipment.enhancement` + `equipment.xinxue_jiejing`，
lib/data/numbers_config.dart:62:  /// 开锋系统配置（numbers.yaml `equipment.forging`，T21 用）。
lib/data/numbers_config.dart:65:  /// 每阶心法的速度加成（numbers.yaml `techniques.tiers[].speed_bonus`，
lib/data/numbers_config.dart:88:  /// 4 段共鸣度配置（numbers.yaml `equipment.resonance.stages`，GDD §6.4）。
lib/data/numbers_config.dart:92:  /// 师承遗物的共鸣度保留比例（numbers.yaml `equipment.resonance.inheritance_retention`，
lib/data/numbers_config.dart:97:  /// `equipment.resonance.seclusion_battle_count_per_hour`，根因A 2026-05-29）。
lib/data/numbers_config.dart:101:  /// 师承遗物的内力上限加成（numbers.yaml `equipment.lineage_heritage.internal_force_max_bonus`，
lib/data/numbers_config.dart:107:  /// 装备出售/分解配置（numbers.yaml `equipment.disposal`，2026-06-26 红线推翻）。
lib/data/numbers_config.dart:207:  /// numbers.yaml `jianghu` 段:7 阶 reputation_tiers + enmity_combat_modifier + triggers。
lib/data/numbers_config.dart:337:  /// `milestone_equipment_grants` 段)。从 [raw] 读,缺段兜底空 map。
lib/data/numbers_config.dart:340:    final m = raw['milestone_equipment_grants'] as Map?;
lib/data/numbers_config.dart:349:    final equipment = y['equipment'] as Map<String, dynamic>;
lib/data/numbers_config.dart:375:      defenseRateByTier: _parseDefenseRates(realms['tiers'] as List),
lib/data/numbers_config.dart:377:          ((equipment['enhancement'] as Map<String, dynamic>)['bonus_per_level']
lib/data/numbers_config.dart:381:        enhancement: equipment['enhancement'] as Map<String, dynamic>,
lib/data/numbers_config.dart:382:        xinxueJiejing: equipment['xinxue_jiejing'] as Map<String, dynamic>,
lib/data/numbers_config.dart:385:        equipment['forging'] as Map<String, dynamic>,
lib/data/numbers_config.dart:388:        techniques['tiers'] as List,
lib/data/numbers_config.dart:405:        equipment['resonance'] as Map<String, dynamic>,
lib/data/numbers_config.dart:408:          ((equipment['resonance']
lib/data/numbers_config.dart:413:          ((equipment['resonance']
lib/data/numbers_config.dart:421:          ((equipment['lineage_heritage']
lib/data/numbers_config.dart:426:        equipment['disposal'] as Map<String, dynamic>,
lib/data/numbers_config.dart:544:  static Map<RealmTier, double> _parseDefenseRates(List tiers) {
lib/data/numbers_config.dart:546:    for (final t in tiers) {
lib/data/numbers_config.dart:553:  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
lib/data/numbers_config.dart:555:    for (final t in tiers) {
lib/data/numbers_config.dart:634:                'equipment.resonance.stages[].unlocks_joint_skill',
lib/data/numbers_config.dart:639:                'equipment.resonance.stages[].has_sword_song_effect',
lib/data/numbers_config.dart:889:/// 强化系统配置（numbers.yaml `equipment.enhancement` + `equipment.xinxue_jiejing`，
lib/data/numbers_config.dart:938:          _missingRequiredValue('equipment.enhancement.never_degrade'),
lib/data/numbers_config.dart:1088:/// 开锋系统配置（numbers.yaml `equipment.forging`，T21）。
lib/data/numbers_config.dart:1150:          _missingRequiredValue('equipment.forging.slots[].fucai_cost'),
lib/data/numbers_config.dart:1158:/// 单段共鸣度配置（numbers.yaml `equipment.resonance.stages[]`）。
lib/data/numbers_config.dart:1901:  final int equipmentBaseAttackMax;
lib/data/numbers_config.dart:1915:    required this.equipmentBaseAttackMax,
lib/data/numbers_config.dart:1933:      equipmentBaseAttackMax:
lib/data/numbers_config.dart:1934:          (y['equipment_base_attack_max'] as num?)?.toInt() ??
lib/data/numbers_config.dart:1935:          _missingRequiredValue('combat.red_lines.equipment_base_attack_max'),
lib/data/numbers_config.dart:2418:/// 基础伤害公式系数（GDD §5.3，平衡后 `equipment_attack_factor=1.0` /
lib/data/numbers_config.dart:2422:  final double equipmentAttackFactor;
lib/data/numbers_config.dart:2426:    required this.equipmentAttackFactor,
lib/data/numbers_config.dart:2432:      equipmentAttackFactor: (y['equipment_attack_factor'] as num).toDouble(),
lib/data/numbers_config.dart:2791:  /// 基础装备触发概率，与地图 equipmentDropRate 相乘后为最终掉落概率。
lib/data/numbers_config.dart:2795:  final int equipmentRollIntervalHours;
lib/data/numbers_config.dart:2798:  final int equipmentRollMaxCount;
lib/data/numbers_config.dart:2801:  final List<RetreatEquipmentTierWeights> equipmentTierWeights;
lib/data/numbers_config.dart:2834:    required this.equipmentRollIntervalHours,
lib/data/numbers_config.dart:2835:    required this.equipmentRollMaxCount,
lib/data/numbers_config.dart:2836:    required this.equipmentTierWeights,
lib/data/numbers_config.dart:2876:    final equipmentRollIntervalHours =
lib/data/numbers_config.dart:2877:        (y['equipment_roll_interval_hours'] as num).toInt();
lib/data/numbers_config.dart:2878:    final equipmentRollMaxCount = (y['equipment_roll_max_count'] as num)
lib/data/numbers_config.dart:2880:    final equipmentTierWeights = (y['equipment_tier_weights'] as List)
lib/data/numbers_config.dart:2888:      intervalHours: equipmentRollIntervalHours,
lib/data/numbers_config.dart:2889:      maxCount: equipmentRollMaxCount,
lib/data/numbers_config.dart:2890:      weights: equipmentTierWeights,
lib/data/numbers_config.dart:2903:      equipmentRollIntervalHours: equipmentRollIntervalHours,
lib/data/numbers_config.dart:2904:      equipmentRollMaxCount: equipmentRollMaxCount,
lib/data/numbers_config.dart:2905:      equipmentTierWeights: equipmentTierWeights,
lib/data/numbers_config.dart:3067:  /// reputation_tiers 空 + enmity 阈值 0 + triggers 0,Service 端表现为 noop。
lib/data/numbers_config.dart:3076:    final tiersRaw = (y['reputation_tiers'] as List?) ?? const [];
lib/data/numbers_config.dart:3077:    final tiers = <ReputationTierDef>[];
lib/data/numbers_config.dart:3078:    for (final raw in tiersRaw) {
lib/data/numbers_config.dart:3079:      tiers.add(
lib/data/numbers_config.dart:3084:      reputationTiers: List.unmodifiable(tiers),
lib/data/numbers_config.dart:3925:/// [tiersFor] 后 clamp 武圣，带动敌内力派生 / 防御率档 / 境界差修正三轴。
lib/data/numbers_config.dart:3928:  final int tiersPerCycle;
lib/data/numbers_config.dart:3944:    required this.tiersPerCycle,
lib/data/numbers_config.dart:3954:    tiersPerCycle: 0,
lib/data/numbers_config.dart:3964:      tiersPerCycle: (y['tiers_per_cycle'] as num).toInt(),
lib/data/numbers_config.dart:3976:  int tiersFor(int cycle) => cycle <= 1 ? 0 : tiersPerCycle * (cycle - 1);
lib/data/game_repository.dart:9:import 'defs/equipment_def.dart';
lib/data/game_repository.dart:45:import 'validation/technique_equipment_red_lines_validator.dart';
lib/data/game_repository.dart:74:  final Map<String, EquipmentDef> equipmentDefs;
lib/data/game_repository.dart:175:    required this.equipmentDefs,
lib/data/game_repository.dart:220:    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
lib/data/game_repository.dart:228:    final equipmentDefs = _parseDefMap(
lib/data/game_repository.dart:229:      equipmentRaw['equipment'] as List,
lib/data/game_repository.dart:317:            equipmentIds: candidate.startingEquipmentIds,
lib/data/game_repository.dart:319:            equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:344:            equipmentIds: candidate.startingEquipmentIds,
lib/data/game_repository.dart:346:            equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:501:      equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:528:    await _validatePresetLoreReferences(equipmentDefs, load);
lib/data/game_repository.dart:584:    required List<String> equipmentIds,
lib/data/game_repository.dart:586:    required Map<String, EquipmentDef> equipmentDefs,
lib/data/game_repository.dart:596:    for (final equipmentId in equipmentIds) {
lib/data/game_repository.dart:597:      if (!equipmentDefs.containsKey(equipmentId)) {
lib/data/game_repository.dart:600:          'data/equipment.yaml id=$equipmentId',
lib/data/game_repository.dart:626:  /// 仅在真实 equipment.yaml 引用 lore 时才异步校验。
lib/data/game_repository.dart:630:    Map<String, EquipmentDef> equipmentDefs,
lib/data/game_repository.dart:633:    for (final def in equipmentDefs.values) {
lib/data/game_repository.dart:752:  /// 把 numbers.yaml 嵌套的 `realms.tiers[].layers[]` 展平为 49 行 [RealmDef]。
lib/data/game_repository.dart:754:    final tiers = realmsSection['tiers'] as List;
lib/data/game_repository.dart:756:    for (final t in tiers) {
lib/data/game_repository.dart:759:        t['equipment_tier_cap'] as String,
lib/data/game_repository.dart:772:            equipmentTierCap: eqCap,
lib/data/game_repository.dart:817:      equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:877:      equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:883:      equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:889:      equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:907:      equipmentDefs: equipmentDefs,
lib/data/game_repository.dart:922:      equipmentIds: equipmentDefs.keys.toSet(),
lib/data/game_repository.dart:1129:  ///   - [EquipmentDrop.equipmentDefId] 必须在 [equipmentIds]
lib/data/game_repository.dart:1140:    required Set<String> equipmentIds,
lib/data/game_repository.dart:1144:    equipmentIds: equipmentIds,
lib/data/game_repository.dart:1223:            e.baseAttack > redLines.equipmentBaseAttackMax) {
lib/data/game_repository.dart:1226:            '(cap=${redLines.equipmentBaseAttackMax})',
lib/data/game_repository.dart:1265:    //    三选一命名装备候选在 equipment.yaml。
lib/data/game_repository.dart:1273:      if (!equipmentDefs.containsKey(eqId)) {
lib/data/game_repository.dart:1275:          'boss_gauntlets: reward_candidate_equipment_id=$eqId '
lib/data/game_repository.dart:1276:          '未在 equipment.yaml 存在（§8.2 引用悬空）',
lib/data/game_repository.dart:1292:        curve.attackValueCap > redLines.equipmentBaseAttackMax) {
lib/data/game_repository.dart:1296:        'attack=${curve.attackValueCap}/${redLines.equipmentBaseAttackMax}',
lib/data/game_repository.dart:1361:      equipmentDefs[defId] ?? (throw StateError('EquipmentDef 未配置: $defId'));
```

<a id="q028"></a>
### Q028

```sh
sed -n 376,386p lib/data/numbers_config.dart
```

命中/输出行数：11；退出码：0。

```text
      enhancementBonusPerLevel:
          ((equipment['enhancement'] as Map<String, dynamic>)['bonus_per_level']
                  as num)
              .toDouble(),
      enhancement: EnhancementConfig.fromYaml(
        enhancement: equipment['enhancement'] as Map<String, dynamic>,
        xinxueJiejing: equipment['xinxue_jiejing'] as Map<String, dynamic>,
      ),
      forging: ForgingConfig.fromYaml(
        equipment['forging'] as Map<String, dynamic>,
      ),
```

<a id="q029"></a>
### Q029

```sh
sed -n 219,232p lib/data/game_repository.dart
```

命中/输出行数：14；退出码：0。

```text
    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
    final equipmentDefs = _parseDefMap(
      equipmentRaw['equipment'] as List,
      EquipmentDef.fromYaml,
      idOf: (d) => d.id,
    );
```

<a id="q030"></a>
### Q030

```sh
sed -n 376,376p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      enhancementBonusPerLevel:
```

<a id="q031"></a>
### Q031

```sh
sed -n 220,220p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
```

<a id="q032"></a>
### Q032

```sh
sed -n 228,228p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
    final equipmentDefs = _parseDefMap(
```

<a id="q033"></a>
### Q033

```sh
rg -n --with-filename --no-heading --sort path -- 'enhancement|success_curve|_fallbackFormula' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：22；退出码：0。

```text
lib/data/numbers_config.dart:54:  /// 装备强化每级加成系数（numbers.yaml `equipment.enhancement.bonus_per_level`，
lib/data/numbers_config.dart:56:  final double enhancementBonusPerLevel;
lib/data/numbers_config.dart:58:  /// 强化系统配置（numbers.yaml `equipment.enhancement` + `equipment.xinxue_jiejing`，
lib/data/numbers_config.dart:60:  final EnhancementConfig enhancement;
lib/data/numbers_config.dart:289:    required this.enhancementBonusPerLevel,
lib/data/numbers_config.dart:290:    required this.enhancement,
lib/data/numbers_config.dart:376:      enhancementBonusPerLevel:
lib/data/numbers_config.dart:377:          ((equipment['enhancement'] as Map<String, dynamic>)['bonus_per_level']
lib/data/numbers_config.dart:380:      enhancement: EnhancementConfig.fromYaml(
lib/data/numbers_config.dart:381:        enhancement: equipment['enhancement'] as Map<String, dynamic>,
lib/data/numbers_config.dart:889:/// 强化系统配置（numbers.yaml `equipment.enhancement` + `equipment.xinxue_jiejing`，
lib/data/numbers_config.dart:897:/// `successRate == null` 表示该段走 [_fallbackFormula]（GDD +20-49 段
lib/data/numbers_config.dart:923:    required Map<String, dynamic> enhancement,
lib/data/numbers_config.dart:927:      successCurve: _parseSuccessCurve(enhancement['success_curve'] as List),
lib/data/numbers_config.dart:928:      mojianshiCost: _parseMaterialCost(enhancement['mojianshi_cost'] as List),
lib/data/numbers_config.dart:930:        enhancement['duancai_cost'] as List? ?? const [],
lib/data/numbers_config.dart:937:          enhancement['never_degrade'] as bool? ??
lib/data/numbers_config.dart:938:          _missingRequiredValue('equipment.enhancement.never_degrade'),
lib/data/numbers_config.dart:943:  /// 段走 [_fallbackFormula]（+20-49 段公式）。
lib/data/numbers_config.dart:946:    return bracket.successRate ?? _fallbackFormula(targetLevel);
lib/data/numbers_config.dart:991:    throw StateError('success_curve 缺少 targetLevel=$targetLevel 的覆盖区间');
lib/data/numbers_config.dart:995:  static double _fallbackFormula(int targetLevel) {
```

<a id="q034"></a>
### Q034

```sh
sed -n 922,940p lib/data/numbers_config.dart
```

命中/输出行数：19；退出码：0。

```text
  factory EnhancementConfig.fromYaml({
    required Map<String, dynamic> enhancement,
    required Map<String, dynamic> xinxueJiejing,
  }) {
    return EnhancementConfig(
      successCurve: _parseSuccessCurve(enhancement['success_curve'] as List),
      mojianshiCost: _parseMaterialCost(enhancement['mojianshi_cost'] as List),
      duancaiCost: _parseMaterialCost(
        enhancement['duancai_cost'] as List? ?? const [],
      ),
      crystalGuarantees: _parseCrystalGuarantees(
        xinxueJiejing['guaranteed_success_costs'] as List,
      ),
      crystalGainPerFailure: (xinxueJiejing['gain_per_failure'] as num).toInt(),
      neverDegrade:
          enhancement['never_degrade'] as bool? ??
          _missingRequiredValue('equipment.enhancement.never_degrade'),
    );
  }
```

<a id="q035"></a>
### Q035

```sh
sed -n 990,1010p lib/data/numbers_config.dart
```

命中/输出行数：21；退出码：0。

```text
    }
    throw StateError('success_curve 缺少 targetLevel=$targetLevel 的覆盖区间');
  }

  /// GDD §12 #3 决议：+20-49 段公式 `max(0.30, 0.50 - 0.02 × (level - 19))`。
  static double _fallbackFormula(int targetLevel) {
    final raw = 0.50 - 0.02 * (targetLevel - 19);
    return raw < 0.30 ? 0.30 : raw;
  }

  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
    return [
      for (final e in raw)
        EnhanceLevelBracket(
          minLevel: ((e['level_range'] as List)[0] as num).toInt(),
          maxLevel: ((e['level_range'] as List)[1] as num).toInt(),
          successRate: (e['success_rate'] as num?)?.toDouble(),
          materialPenalty: _parsePenalty(e['material_penalty'] as String),
        ),
    ];
  }
```

<a id="q036"></a>
### Q036

```sh
sed -n 922,922p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  factory EnhancementConfig.fromYaml({
```

<a id="q037"></a>
### Q037

```sh
sed -n 995,995p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  static double _fallbackFormula(int targetLevel) {
```

<a id="q038"></a>
### Q038

```sh
sed -n 1000,1000p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
```

<a id="q039"></a>
### Q039

```sh
rg -n --with-filename --no-heading --sort path -- 'resonance|stages' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：51；退出码：0。

```text
lib/data/numbers_config.dart:88:  /// 4 段共鸣度配置（numbers.yaml `equipment.resonance.stages`，GDD §6.4）。
lib/data/numbers_config.dart:90:  final List<ResonanceStageConfig> resonanceStages;
lib/data/numbers_config.dart:92:  /// 师承遗物的共鸣度保留比例（numbers.yaml `equipment.resonance.inheritance_retention`，
lib/data/numbers_config.dart:94:  final double resonanceInheritanceRetention;
lib/data/numbers_config.dart:97:  /// `equipment.resonance.seclusion_battle_count_per_hour`，根因A 2026-05-29）。
lib/data/numbers_config.dart:99:  final int resonanceSeclusionBattleCountPerHour;
lib/data/numbers_config.dart:126:  /// numbers.yaml `ascension.unlock_triggers`,3 条件并存:cleared_stages 2 关 +
lib/data/numbers_config.dart:271:  /// 把 stages.yaml 内容装配成 0A flow 时消费。fixture 不带该段时走
lib/data/numbers_config.dart:297:    required this.resonanceStages,
lib/data/numbers_config.dart:298:    required this.resonanceInheritanceRetention,
lib/data/numbers_config.dart:299:    required this.resonanceSeclusionBattleCountPerHour,
lib/data/numbers_config.dart:404:      resonanceStages: _parseResonanceStages(
lib/data/numbers_config.dart:405:        equipment['resonance'] as Map<String, dynamic>,
lib/data/numbers_config.dart:407:      resonanceInheritanceRetention:
lib/data/numbers_config.dart:408:          ((equipment['resonance']
lib/data/numbers_config.dart:412:      resonanceSeclusionBattleCountPerHour:
lib/data/numbers_config.dart:413:          ((equipment['resonance']
lib/data/numbers_config.dart:620:    Map<String, dynamic> resonance,
lib/data/numbers_config.dart:622:    final stages = resonance['stages'] as List;
lib/data/numbers_config.dart:624:      for (final s in stages)
lib/data/numbers_config.dart:634:                'equipment.resonance.stages[].unlocks_joint_skill',
lib/data/numbers_config.dart:639:                'equipment.resonance.stages[].has_sword_song_effect',
lib/data/numbers_config.dart:869:    final stages =
lib/data/numbers_config.dart:870:        (triggers['cleared_stages'] as List?)
lib/data/numbers_config.dart:882:      clearedStagesRequired: List.unmodifiable(stages),
lib/data/numbers_config.dart:1158:/// 单段共鸣度配置（numbers.yaml `equipment.resonance.stages[]`）。
lib/data/numbers_config.dart:1988:/// spec 2026-08-19 P1=α 拍板)。空间/能量/动作默认值;内容面(stages.yaml
lib/data/numbers_config.dart:3592:/// `combat.skill_proficiency.stages`;末阶 damageMult 作综合加成 cap。
lib/data/numbers_config.dart:3594:  final List<SkillProficiencyStageConfig> stages;
lib/data/numbers_config.dart:3595:  const SkillProficiencyConfig({required this.stages});
lib/data/numbers_config.dart:3598:      stages.map((s) => s.damageMult).reduce((a, b) => a > b ? a : b);
lib/data/numbers_config.dart:3601:    final raw = (y?['stages'] as List?) ?? const [];
lib/data/numbers_config.dart:3602:    final stages = raw
lib/data/numbers_config.dart:3610:    for (var i = 1; i < stages.length; i++) {
lib/data/numbers_config.dart:3611:      if (stages[i].minUses <= stages[i - 1].minUses) {
lib/data/numbers_config.dart:3612:        throw StateError('skill_proficiency.stages min_uses 必须严格递增');
lib/data/numbers_config.dart:3614:      if (stages[i].damageMult < stages[i - 1].damageMult) {
lib/data/numbers_config.dart:3615:        throw StateError('skill_proficiency.stages damage_mult 不可递减');
lib/data/numbers_config.dart:3618:    return SkillProficiencyConfig(stages: stages);
lib/data/game_repository.dart:223:    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
lib/data/game_repository.dart:266:      stagesRaw['stages'] as List,
lib/data/game_repository.dart:698:  ///  ② stages/encounters 引的 factionId 必须存在于 factions.yaml,否则
lib/data/game_repository.dart:848:    //   - mainline stages 总数 = 15，按 chapterIndex 分 3 章 × 5 关
lib/data/game_repository.dart:1027:  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配置了
lib/data/game_repository.dart:1032:    Map<String, StageDef> stages,
lib/data/game_repository.dart:1064:    for (final s in stages.values) {
lib/data/game_repository.dart:1082:  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配了
lib/data/game_repository.dart:1087:    Map<String, StageDef> stages,
lib/data/game_repository.dart:1093:    for (final s in stages.values) {
lib/data/game_repository.dart:1201:    for (final stage in config.stages) {
lib/data/game_repository.dart:1414:  /// Typed runtime binding for a migrated stage. Legacy stages return null;
```

<a id="q040"></a>
### Q040

```sh
sed -n 404,419p lib/data/numbers_config.dart
```

命中/输出行数：16；退出码：0。

```text
      resonanceStages: _parseResonanceStages(
        equipment['resonance'] as Map<String, dynamic>,
      ),
      resonanceInheritanceRetention:
          ((equipment['resonance']
                      as Map<String, dynamic>)['inheritance_retention']
                  as num)
              .toDouble(),
      resonanceSeclusionBattleCountPerHour:
          ((equipment['resonance']
                      as Map<
                        String,
                        dynamic
                      >)['seclusion_battle_count_per_hour']
                  as num)
              .toInt(),
```

<a id="q041"></a>
### Q041

```sh
sed -n 619,645p lib/data/numbers_config.dart
```

命中/输出行数：27；退出码：0。

```text
  static List<ResonanceStageConfig> _parseResonanceStages(
    Map<String, dynamic> resonance,
  ) {
    final stages = resonance['stages'] as List;
    return [
      for (final s in stages)
        ResonanceStageConfig(
          stage: ResonanceStage.values.byName(s['stage'] as String),
          minBattleCount: ((s['battle_count_range'] as List)[0] as num).toInt(),
          maxBattleCount: ((s['battle_count_range'] as List)[1] as num?)
              ?.toInt(),
          bonusMultiplier: (s['bonus_multiplier'] as num).toDouble(),
          unlocksJointSkill:
              (s['unlocks_joint_skill'] as bool?) ??
              _missingRequiredValue(
                'equipment.resonance.stages[].unlocks_joint_skill',
              ),
          hasSwordSongEffect:
              (s['has_sword_song_effect'] as bool?) ??
              _missingRequiredValue(
                'equipment.resonance.stages[].has_sword_song_effect',
              ),
        ),
    ];
  }
}
```

<a id="q042"></a>
### Q042

```sh
sed -n 404,404p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      resonanceStages: _parseResonanceStages(
```

<a id="q043"></a>
### Q043

```sh
sed -n 619,619p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  static List<ResonanceStageConfig> _parseResonanceStages(
```

<a id="q044"></a>
### Q044

```sh
rg -n --with-filename --no-heading --sort path -- 'techniques|tiers|_parseTechniqueSpeedBonus' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：45；退出码：0。

```text
lib/data/numbers_config.dart:24:/// 其余段（equipment / techniques / skills / character / retreat / tower /
lib/data/numbers_config.dart:65:  /// 每阶心法的速度加成（numbers.yaml `techniques.tiers[].speed_bonus`，
lib/data/numbers_config.dart:69:  /// 9 层修炼度对应的伤害倍率（numbers.yaml `techniques.cultivation.layers[].bonus_multiplier`，
lib/data/numbers_config.dart:74:  /// `techniques.cultivation.progress_to_next[].progress_required`，phase2_tasks T24 用）。
lib/data/numbers_config.dart:81:  /// `techniques.cultivation.insight_to_cultivation_ratio`，根因A 2026-05-29）。
lib/data/numbers_config.dart:85:  /// 3×3 流派克制矩阵（numbers.yaml `techniques.schools`，GDD §4.4 / §5.4，T10 用）。
lib/data/numbers_config.dart:131:  /// 散功代价：原主修心法修炼度保留比例（numbers.yaml `techniques.dispersion.cultivation_penalty`，
lib/data/numbers_config.dart:136:  /// `techniques.defeat.boss_cultivation_penalty`，Phase 4 W10 = 0.5）。
lib/data/numbers_config.dart:141:  /// 心法学习成本（numbers.yaml `techniques.learning_cost`，phase2_tasks T23）。
lib/data/numbers_config.dart:207:  /// numbers.yaml `jianghu` 段:7 阶 reputation_tiers + enmity_combat_modifier + triggers。
lib/data/numbers_config.dart:350:    final techniques = y['techniques'] as Map<String, dynamic>;
lib/data/numbers_config.dart:375:      defenseRateByTier: _parseDefenseRates(realms['tiers'] as List),
lib/data/numbers_config.dart:387:      techniqueSpeedBonus: _parseTechniqueSpeedBonus(
lib/data/numbers_config.dart:388:        techniques['tiers'] as List,
lib/data/numbers_config.dart:391:        techniques['cultivation'] as Map<String, dynamic>,
lib/data/numbers_config.dart:394:        techniques['cultivation'] as Map<String, dynamic>,
lib/data/numbers_config.dart:397:          ((techniques['cultivation']
lib/data/numbers_config.dart:402:        techniques['schools'] as Map<String, dynamic>,
lib/data/numbers_config.dart:442:          ((techniques['dispersion']
lib/data/numbers_config.dart:447:          ((techniques['defeat']
lib/data/numbers_config.dart:452:        techniques['learning_cost'] as Map<String, dynamic>,
lib/data/numbers_config.dart:544:  static Map<RealmTier, double> _parseDefenseRates(List tiers) {
lib/data/numbers_config.dart:546:    for (final t in tiers) {
lib/data/numbers_config.dart:553:  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
lib/data/numbers_config.dart:555:    for (final t in tiers) {
lib/data/numbers_config.dart:1182:/// 3×3 流派克制矩阵（numbers.yaml `techniques.schools`）。
lib/data/numbers_config.dart:2746:/// 心法学习成本（numbers.yaml `techniques.learning_cost`，phase2_tasks T23）。
lib/data/numbers_config.dart:3067:  /// reputation_tiers 空 + enmity 阈值 0 + triggers 0,Service 端表现为 noop。
lib/data/numbers_config.dart:3076:    final tiersRaw = (y['reputation_tiers'] as List?) ?? const [];
lib/data/numbers_config.dart:3077:    final tiers = <ReputationTierDef>[];
lib/data/numbers_config.dart:3078:    for (final raw in tiersRaw) {
lib/data/numbers_config.dart:3079:      tiers.add(
lib/data/numbers_config.dart:3084:      reputationTiers: List.unmodifiable(tiers),
lib/data/numbers_config.dart:3925:/// [tiersFor] 后 clamp 武圣，带动敌内力派生 / 防御率档 / 境界差修正三轴。
lib/data/numbers_config.dart:3928:  final int tiersPerCycle;
lib/data/numbers_config.dart:3944:    required this.tiersPerCycle,
lib/data/numbers_config.dart:3954:    tiersPerCycle: 0,
lib/data/numbers_config.dart:3964:      tiersPerCycle: (y['tiers_per_cycle'] as num).toInt(),
lib/data/numbers_config.dart:3976:  int tiersFor(int cycle) => cycle <= 1 ? 0 : tiersPerCycle * (cycle - 1);
lib/data/game_repository.dart:221:    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
lib/data/game_repository.dart:234:      techniquesRaw['techniques'] as List,
lib/data/game_repository.dart:592:          'data/techniques.yaml id=$techniqueId',
lib/data/game_repository.dart:752:  /// 把 numbers.yaml 嵌套的 `realms.tiers[].layers[]` 展平为 49 行 [RealmDef]。
lib/data/game_repository.dart:754:    final tiers = realmsSection['tiers'] as List;
lib/data/game_repository.dart:756:    for (final t in tiers) {
```

<a id="q045"></a>
### Q045

```sh
sed -n 553,561p lib/data/numbers_config.dart
```

命中/输出行数：9；退出码：0。

```text
  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
    final m = <TechniqueTier, int>{};
    for (final t in tiers) {
      final tier = TechniqueTier.values.byName(t['tier'] as String);
      m[tier] = (t['speed_bonus'] as num).toInt();
    }
    return m;
  }
```

<a id="q046"></a>
### Q046

```sh
sed -n 553,553p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
```

<a id="q047"></a>
### Q047

```sh
rg -n --with-filename --no-heading --sort path -- 'skills|skillDefs' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：40；退出码：0。

```text
lib/data/numbers_config.dart:24:/// 其余段（equipment / techniques / skills / character / retreat / tower /
lib/data/game_repository.dart:76:  final Map<String, SkillDef> skillDefs;
lib/data/game_repository.dart:120:  /// 奇遇专属招式 id 集合(C-W14-3-A,encounter_skills.yaml 加载)。
lib/data/game_repository.dart:121:  /// 与 [skillDefs] 共享 runtime 类型 [SkillDef],但通过此 set 可快速筛
lib/data/game_repository.dart:123:  /// `skillDefs[id]!.isEncounterSkill` 等价判断。
lib/data/game_repository.dart:177:    required this.skillDefs,
lib/data/game_repository.dart:222:    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
lib/data/game_repository.dart:238:    final skillDefs = _parseDefMap(
lib/data/game_repository.dart:239:      skillsRaw['skills'] as List,
lib/data/game_repository.dart:248:      'data/encounter_skills.yaml',
lib/data/game_repository.dart:250:        parseYamlMap(raw)['encounter_skills'] as List,
lib/data/game_repository.dart:259:      if (skillDefs.containsKey(id)) {
lib/data/game_repository.dart:260:        throw StateError('encounter_skills.yaml 与 skills.yaml id 冲突: $id');
lib/data/game_repository.dart:263:    skillDefs.addAll(encounterSkills);
lib/data/game_repository.dart:485:            skillDefs: skillDefs,
lib/data/game_repository.dart:503:      skillDefs: skillDefs,
lib/data/game_repository.dart:560:      if (e is StateError && assetPath == 'data/encounter_skills.yaml') {
lib/data/game_repository.dart:572:          assetPath == 'data/encounter_skills.yaml') {
lib/data/game_repository.dart:826:      skillDefs: skillDefs,
lib/data/game_repository.dart:866:      skillDefs: skillDefs,
lib/data/game_repository.dart:916:    enforceSkillDropRedLines(stageDefs: stageDefs, skillDefs: skillDefs);
lib/data/game_repository.dart:929:    // 批二①：Boss 阶段 unlockSkillIds 引用必须在 skills.yaml 中存在（含 tower floors）
lib/data/game_repository.dart:932:      skillDefs.keys.toSet(),
lib/data/game_repository.dart:961:    enforceInterruptSkillRedLines(skillDefs: skillDefs, numbers: numbers);
lib/data/game_repository.dart:966:      skillDefs: skillDefs,
lib/data/game_repository.dart:980:    enforceSkillTargetTypeRedLines(skillDefs: skillDefs);
lib/data/game_repository.dart:989:    // Phase 4 W14-3-A:encounter_skills.yaml 校验 + unlock 引用一致性
lib/data/game_repository.dart:991:      skillDefs: skillDefs,
lib/data/game_repository.dart:1046:              '未在 skills.yaml 中存在（批二①红线）',
lib/data/game_repository.dart:1190:  ///   ② 敌人 skillIds 全在 skillDefs（招式引用不悬空）；
lib/data/game_repository.dart:1192:  ///   ④ bossPhases/cycleBossPhases 的 unlockSkillIds 全在 skillDefs（批二①同口径）；
lib/data/game_repository.dart:1198:    final skillIdSet = skillDefs.keys.toSet();
lib/data/game_repository.dart:1235:            throw StateError('$loc敌人 ${e.id} skillId=$sid 未在 skills.yaml 存在');
lib/data/game_repository.dart:1254:                '未在 skills.yaml 存在（批二①红线）',
lib/data/game_repository.dart:1264:    // ⑥ 通关奖励引用不悬空（C2.4·§6.2/§8.2）：首通秘籍在 skills.yaml、
lib/data/game_repository.dart:1269:        '${config.firstClearRewardSkillId} 未在 skills.yaml 存在（§8.2 引用悬空）',
lib/data/game_repository.dart:1321:        final skill = skillDefs[skillId];
lib/data/game_repository.dart:1324:            'expeditions: ${enemy.id} skillId=$skillId 未在 skills.yaml 存在',
lib/data/game_repository.dart:1367:      skillDefs[defId] ?? (throw StateError('SkillDef 未配置: $defId'));
lib/data/game_repository.dart:1428:    final list = encounterSkillIds.map((id) => skillDefs[id]!).toList();
```

<a id="q048"></a>
### Q048

```sh
sed -n 219,240p lib/data/game_repository.dart
```

命中/输出行数：22；退出码：0。

```text
    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
    final equipmentDefs = _parseDefMap(
      equipmentRaw['equipment'] as List,
      EquipmentDef.fromYaml,
      idOf: (d) => d.id,
    );
    final techniqueDefs = _parseDefMap(
      techniquesRaw['techniques'] as List,
      TechniqueDef.fromYaml,
      idOf: (d) => d.id,
    );
    final skillDefs = _parseDefMap(
      skillsRaw['skills'] as List,
      SkillDef.fromYaml,
```

<a id="q049"></a>
### Q049

```sh
sed -n 345,345p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

<a id="q050"></a>
### Q050

```sh
sed -n 222,222p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
```

<a id="q051"></a>
### Q051

```sh
sed -n 238,238p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
    final skillDefs = _parseDefMap(
```

<a id="q052"></a>
### Q052

```sh
rg -n --with-filename --no-heading --sort path -- 'character|rarity|adventure_attribute_bonus' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：25；退出码：0。

```text
lib/data/numbers_config.dart:24:/// 其余段（equipment / techniques / skills / character / retreat / tower /
lib/data/numbers_config.dart:177:  /// 7 关镜像玩家 character +10-20% 强化 + §5.4 cap + 散功 ×0.5 阉割版失败惩罚。
lib/data/numbers_config.dart:222:  /// `character.adventure_attribute_bonus.lifetime_cap_per_character`,GDD §4.1)。
lib/data/numbers_config.dart:226:  /// 六档稀有度的总点数区间(numbers.yaml `character.rarity_distribution`,GDD §4.1)。
lib/data/numbers_config.dart:229:  /// [rarityForTotalPoints] 派生,不得在创建点写死(2026-08-07 N1:此前三处
lib/data/numbers_config.dart:237:  final List<RarityTierRange> rarityTiers;
lib/data/numbers_config.dart:305:    required this.rarityTiers,
lib/data/numbers_config.dart:493:          (((y['character']
lib/data/numbers_config.dart:497:                          >?)?['adventure_attribute_bonus']
lib/data/numbers_config.dart:498:                      as Map<String, dynamic>?)?['lifetime_cap_per_character']
lib/data/numbers_config.dart:502:            'character.adventure_attribute_bonus.lifetime_cap_per_character',
lib/data/numbers_config.dart:504:      rarityTiers: _parseRarityTiers(
lib/data/numbers_config.dart:505:        (y['character'] as Map<String, dynamic>?)?['rarity_distribution']
lib/data/numbers_config.dart:588:  /// 解析 `character.rarity_distribution`;缺段(fixture)→ 空表,
lib/data/numbers_config.dart:589:  /// [rarityForTotalPoints] 退化为 §5.4 default 兜底。
lib/data/numbers_config.dart:595:          tier: RarityTier.values.byName((e as Map)['rarity'] as String),
lib/data/numbers_config.dart:604:  /// 资质是出生属性,奇遇加点不重算(2026-08-08 拍板,详 [Character.rarity])。
lib/data/numbers_config.dart:608:  /// [rarityTiers] 为空(fixture 未配该段)时兜底 [RarityTier.biaoZhun]。
lib/data/numbers_config.dart:609:  RarityTier rarityForTotalPoints(int total) {
lib/data/numbers_config.dart:610:    if (rarityTiers.isEmpty) return RarityTier.biaoZhun;
lib/data/numbers_config.dart:611:    for (final r in rarityTiers) {
lib/data/numbers_config.dart:614:    return total < rarityTiers.first.minTotal
lib/data/numbers_config.dart:615:        ? rarityTiers.first.tier
lib/data/numbers_config.dart:616:        : rarityTiers.last.tier;
lib/data/numbers_config.dart:646:/// 一档稀有度对应的四项属性总点数区间(numbers.yaml `character.rarity_distribution`)。
```

<a id="q053"></a>
### Q053

```sh
sed -n 492,507p lib/data/numbers_config.dart
```

命中/输出行数：16；退出码：0。

```text
      adventureAttributeLifetimeCap:
          (((y['character']
                          as Map<
                            String,
                            dynamic
                          >?)?['adventure_attribute_bonus']
                      as Map<String, dynamic>?)?['lifetime_cap_per_character']
                  as num?)
              ?.toInt() ??
          _missingRequiredValue(
            'character.adventure_attribute_bonus.lifetime_cap_per_character',
          ),
      rarityTiers: _parseRarityTiers(
        (y['character'] as Map<String, dynamic>?)?['rarity_distribution']
            as List?,
      ),
```

<a id="q054"></a>
### Q054

```sh
sed -n 492,492p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      adventureAttributeLifetimeCap:
```

<a id="q055"></a>
### Q055

```sh
sed -n 504,504p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      rarityTiers: _parseRarityTiers(
```

<a id="q056"></a>
### Q056

```sh
rg -n --with-filename --no-heading --sort path -- 'timeOfDayBonus|time_of_day_bonus|ziShi|zhengWu' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：20；退出码：0。

```text
lib/data/numbers_config.dart:2817:  final double ziShiInternalForceMultiplier;
lib/data/numbers_config.dart:2820:  final double zhengWuYangSchoolMultiplier;
lib/data/numbers_config.dart:2823:  final String zhengWuTargetAttribute;
lib/data/numbers_config.dart:2826:  final TechniqueSchool zhengWuAppliesToSchool;
lib/data/numbers_config.dart:2841:    required this.ziShiInternalForceMultiplier,
lib/data/numbers_config.dart:2842:    required this.zhengWuYangSchoolMultiplier,
lib/data/numbers_config.dart:2843:    required this.zhengWuTargetAttribute,
lib/data/numbers_config.dart:2844:    required this.zhengWuAppliesToSchool,
lib/data/numbers_config.dart:2850:    final rawTimeOfDay = y['time_of_day_bonus'] as List;
lib/data/numbers_config.dart:2851:    // 提取子时（period=ziShi）的 multiplier，effect=internal_force_growth
lib/data/numbers_config.dart:2852:    final ziShi =
lib/data/numbers_config.dart:2854:              (e) => (e as Map)['period'] == 'ziShi',
lib/data/numbers_config.dart:2858:    // 正午(period=zhengWu)v1.4 加成定向落到 internal_force_points + 仅 gangMeng 触发。
lib/data/numbers_config.dart:2859:    final zhengWu =
lib/data/numbers_config.dart:2861:              (e) => (e as Map)['period'] == 'zhengWu',
lib/data/numbers_config.dart:2912:      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
lib/data/numbers_config.dart:2913:      zhengWuYangSchoolMultiplier: (zhengWu['multiplier'] as num).toDouble(),
lib/data/numbers_config.dart:2914:      zhengWuTargetAttribute: zhengWu['target_attribute'] as String,
lib/data/numbers_config.dart:2915:      zhengWuAppliesToSchool: TechniqueSchool.values.byName(
lib/data/numbers_config.dart:2916:        zhengWu['applies_to_school'] as String,
```

<a id="q057"></a>
### Q057

```sh
sed -n 2847,2868p lib/data/numbers_config.dart
```

命中/输出行数：22；退出码：0。

```text
  factory RetreatConfig.fromYaml(Map<String, dynamic> y) {
    final rawMaps = y['maps'] as List;
    final rawSolar = y['solar_term_bonus'] as Map<String, dynamic>;
    final rawTimeOfDay = y['time_of_day_bonus'] as List;
    // 提取子时（period=ziShi）的 multiplier，effect=internal_force_growth
    final ziShi =
        rawTimeOfDay.firstWhere(
              (e) => (e as Map)['period'] == 'ziShi',
              orElse: () => <String, dynamic>{'multiplier': 1.0},
            )
            as Map;
    // 正午(period=zhengWu)v1.4 加成定向落到 internal_force_points + 仅 gangMeng 触发。
    final zhengWu =
        rawTimeOfDay.firstWhere(
              (e) => (e as Map)['period'] == 'zhengWu',
              orElse: () => <String, dynamic>{
                'multiplier': 1.0,
                'target_attribute': 'internal_force_points',
                'applies_to_school': 'gangMeng',
              },
            )
            as Map;
```

<a id="q058"></a>
### Q058

```sh
sed -n 2912,2918p lib/data/numbers_config.dart
```

命中/输出行数：7；退出码：0。

```text
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
      zhengWuYangSchoolMultiplier: (zhengWu['multiplier'] as num).toDouble(),
      zhengWuTargetAttribute: zhengWu['target_attribute'] as String,
      zhengWuAppliesToSchool: TechniqueSchool.values.byName(
        zhengWu['applies_to_school'] as String,
      ),
    );
```

<a id="q059"></a>
### Q059

```sh
sed -n 2847,2847p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  factory RetreatConfig.fromYaml(Map<String, dynamic> y) {
```

<a id="q060"></a>
### Q060

```sh
sed -n 2912,2912p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
```

<a id="q061"></a>
### Q061

```sh
rg -n --with-filename --no-heading --sort path -- 'tower|towerDefs|towers' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：57；退出码：0。

```text
lib/data/numbers_config.dart:24:/// 其余段（equipment / techniques / skills / character / retreat / tower /
lib/data/numbers_config.dart:1504:    required this.towerBossOpeningBonus,
lib/data/numbers_config.dart:1519:  final int towerBossOpeningBonus;
lib/data/numbers_config.dart:1543:      towerBossOpeningBonus:
lib/data/numbers_config.dart:1544:          (y['tower_boss_opening_bonus'] as num?)?.toInt() ??
lib/data/numbers_config.dart:1545:          _missingRequiredValue('combat.qi.tower_boss_opening_bonus'),
lib/data/numbers_config.dart:1577:        config.towerBossOpeningBonus < 0 ||
lib/data/numbers_config.dart:3672:  final double towerFragmentDropProb;
lib/data/numbers_config.dart:3675:    required this.towerFragmentDropProb,
lib/data/numbers_config.dart:3680:    towerFragmentDropProb: 0.20,
lib/data/numbers_config.dart:3689:      towerFragmentDropProb:
lib/data/numbers_config.dart:3690:          (y['tower_fragment_drop_prob'] as num?)?.toDouble() ??
lib/data/numbers_config.dart:3691:          _missingRequiredValue('skill_unlock.tower_fragment_drop_prob'),
lib/data/numbers_config.dart:3829:  /// tableKey ∈ {'mainline', 'tower_normal', 'tower_boss'}。
lib/data/numbers_config.dart:3865:      maxCycleTower: (y['max_cycle_tower'] as num).toInt(),
lib/data/numbers_config.dart:3905:  /// - 查表顺序：isTower ? (isBoss ? 'tower_boss' : 'tower_normal') : 'mainline'
lib/data/numbers_config.dart:3914:        ? (isBoss ? 'tower_boss' : 'tower_normal')
lib/data/numbers_config.dart:3921:/// spec 2026-08-01-tower-extension 拍板 #5）。
lib/data/game_repository.dart:25:import 'defs/tower_floor_def.dart';
lib/data/game_repository.dart:79:  /// 爬塔全部层，按 floorIndex 升序（1..[towerMaxFloor]）。
lib/data/game_repository.dart:80:  /// 索引方式：`towerFloors[floorIndex - 1]`（红线校验保证连续唯一）。
lib/data/game_repository.dart:81:  final List<TowerFloorDef> towerFloors;
lib/data/game_repository.dart:85:  /// 层数由 `towers.yaml` 数据定义，不在代码里写死——
lib/data/game_repository.dart:88:  int get towerMaxFloor => towerFloors.length;
lib/data/game_repository.dart:179:    required this.towerFloors,
lib/data/game_repository.dart:224:    final towersRaw = parseYamlMap(await load('data/towers.yaml'));
lib/data/game_repository.dart:270:    final towerFloors =
lib/data/game_repository.dart:271:        ((towersRaw['floors'] as List?) ?? const [])
lib/data/game_repository.dart:505:      towerFloors: towerFloors,
lib/data/game_repository.dart:865:      towerFloors: towerFloors,
lib/data/game_repository.dart:918:    // F7（2026-06-23 掉落优化 配置卫生）：dropTable 引用完整性（stage + tower 全覆盖）。
lib/data/game_repository.dart:921:      towerFloors: towerFloors,
lib/data/game_repository.dart:929:    // 批二①：Boss 阶段 unlockSkillIds 引用必须在 skills.yaml 中存在（含 tower floors）
lib/data/game_repository.dart:933:      towerFloors: towerFloors,
lib/data/game_repository.dart:935:    // 批二②:弱点/抗性乘子值域红线（守 §5.4 弱点 ≤2.0；含 tower floors）。
lib/data/game_repository.dart:940:      towerFloors: towerFloors,
lib/data/game_repository.dart:942:    // floor30 护法结界:guardianWard 引用完整性 + 值域 + 自引用（stage + tower 全覆盖）。
lib/data/game_repository.dart:946:    for (final f in towerFloors) {
lib/data/game_repository.dart:949:        location: 'tower floor ${f.floorIndex} ',
lib/data/game_repository.dart:956:    // C1.3.2 断魂庄:敌队随 BossGauntletConfig 独立解析(非 stageDefs/towerFloors),
lib/data/game_repository.dart:968:      towerFloors: towerFloors,
lib/data/game_repository.dart:1027:  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配置了
lib/data/game_repository.dart:1034:    Iterable<TowerFloorDef> towerFloors = const [],
lib/data/game_repository.dart:1070:    for (final f in towerFloors) {
lib/data/game_repository.dart:1074:          label: 'tower floor ${f.floorIndex} enemy ${e.id}',
lib/data/game_repository.dart:1082:  /// 对所有关卡（[stages]）及爬塔楼层（[towerFloors]）内每个配了
lib/data/game_repository.dart:1090:    Iterable<TowerFloorDef> towerFloors = const [],
lib/data/game_repository.dart:1109:    for (final f in towerFloors) {
lib/data/game_repository.dart:1117:              'tower floor ${f.floorIndex} 敌人 ${e.id} schoolDamageTakenMult '
lib/data/game_repository.dart:1139:    required List<TowerFloorDef> towerFloors,
lib/data/game_repository.dart:1143:    towerFloors: towerFloors,
lib/data/game_repository.dart:1151:  /// (如 `'stage foo '` / `'tower floor 30 '`),启动期 [_enforceRedLines] 传入。
lib/data/game_repository.dart:1188:  /// towerFloors），故在此单独跑与主线/爬塔同口径的校验：
lib/data/game_repository.dart:1372:  /// 取第 N 层爬塔（1..[towerMaxFloor]）。越界抛 [RangeError]。
lib/data/game_repository.dart:1374:    if (floorIndex < 1 || floorIndex > towerMaxFloor) {
lib/data/game_repository.dart:1375:      throw RangeError('爬塔 floorIndex 必须 ∈ [1, $towerMaxFloor]，实际 $floorIndex');
lib/data/game_repository.dart:1377:    return towerFloors[floorIndex - 1];
```

<a id="q062"></a>
### Q062

```sh
sed -n 219,227p lib/data/game_repository.dart
```

命中/输出行数：9；退出码：0。

```text
    final numbersRaw = parseYamlMap(await load('data/numbers.yaml'));
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
    final techniquesRaw = parseYamlMap(await load('data/techniques.yaml'));
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
    final stagesRaw = parseYamlMap(await load('data/stages.yaml'));
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));

    final numbers = NumbersConfig.fromYaml(numbersRaw);
    final realms = _parseRealms(numbersRaw['realms'] as Map<String, dynamic>);
```

<a id="q063"></a>
### Q063

```sh
sed -n 270,277p lib/data/game_repository.dart
```

命中/输出行数：8；退出码：0。

```text
    final towerFloors =
        ((towersRaw['floors'] as List?) ?? const [])
            .map(
              (e) =>
                  TowerFloorDef.fromYaml(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false)
          ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));
```

<a id="q064"></a>
### Q064

```sh
sed -n 224,224p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));
```

<a id="q065"></a>
### Q065

```sh
sed -n 270,270p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
    final towerFloors =
```

<a id="q066"></a>
### Q066

```sh
rg -n --with-filename --no-heading --sort path -- 'inheritance|heritageItems|heritage_items' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：22；退出码：0。

```text
lib/data/numbers_config.dart:25:/// inheritance / synergies / validation_examples）保留 [raw] 原始 Map，
lib/data/numbers_config.dart:92:  /// 师承遗物的共鸣度保留比例（numbers.yaml `equipment.resonance.inheritance_retention`，
lib/data/numbers_config.dart:112:  /// numbers.yaml `inheritance.founder_ancestor_buff`,P1.1 阶段决议方案 E.5.A:
lib/data/numbers_config.dart:119:  /// numbers.yaml `inheritance.heritage_items`,P2.3 飞升 lib 端真消费。
lib/data/numbers_config.dart:123:  final HeritageItems heritageItems;
lib/data/numbers_config.dart:303:    required this.heritageItems,
lib/data/numbers_config.dart:409:                      as Map<String, dynamic>)['inheritance_retention']
lib/data/numbers_config.dart:429:        ((y['inheritance'] as Map<String, dynamic>?)?['founder_ancestor_buff']
lib/data/numbers_config.dart:433:      heritageItems: HeritageItems.fromYaml(
lib/data/numbers_config.dart:434:        ((y['inheritance'] as Map<String, dynamic>?)?['heritage_items']
lib/data/numbers_config.dart:659:/// 祖师爷 buff(P1.1 A1 E.5,GDD §7.1)。numbers.yaml `inheritance.founder_ancestor_buff`。
lib/data/numbers_config.dart:712:          'inheritance.founder_ancestor_buff.enabled_when_alive',
lib/data/numbers_config.dart:730:                    'inheritance.founder_ancestor_buff.sect_wide_buff.internal_force_max_pct',
lib/data/numbers_config.dart:736:                    'inheritance.founder_ancestor_buff.sect_wide_buff.max_hp_pct',
lib/data/numbers_config.dart:742:                    'inheritance.founder_ancestor_buff.sect_wide_buff.crit_rate_bonus',
lib/data/numbers_config.dart:748:                    'inheritance.founder_ancestor_buff.sect_wide_buff.cultivation_progress_pct',
lib/data/numbers_config.dart:754:            'inheritance.founder_ancestor_buff.sect_wide_buff.apply_to_disciples_only',
lib/data/numbers_config.dart:765:/// numbers.yaml `inheritance.heritage_items`,P2.3 飞升 lib 端真消费 6 字段。
lib/data/numbers_config.dart:796:  /// 默认值兜底(fixture 不带 `inheritance.heritage_items` 段时)。
lib/data/numbers_config.dart:813:            'inheritance.heritage_items.pieces_per_generation_min',
lib/data/numbers_config.dart:818:            'inheritance.heritage_items.pieces_per_generation_max',
lib/data/numbers_config.dart:827:            'inheritance.heritage_items.stack_across_generations',
```

<a id="q067"></a>
### Q067

```sh
sed -n 428,437p lib/data/numbers_config.dart
```

命中/输出行数：10；退出码：0。

```text
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['founder_ancestor_buff']
                as Map<String, dynamic>?) ??
            const {},
      ),
      heritageItems: HeritageItems.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['heritage_items']
                as Map<String, dynamic>?) ??
            const {},
      ),
```

<a id="q068"></a>
### Q068

```sh
sed -n 807,833p lib/data/numbers_config.dart
```

命中/输出行数：27；退出码：0。

```text
  factory HeritageItems.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return defaults;
    return HeritageItems(
      piecesPerGenerationMin:
          (y['pieces_per_generation_min'] as num?)?.toInt() ??
          _missingRequiredValue(
            'inheritance.heritage_items.pieces_per_generation_min',
          ),
      piecesPerGenerationMax:
          (y['pieces_per_generation_max'] as num?)?.toInt() ??
          _missingRequiredValue(
            'inheritance.heritage_items.pieces_per_generation_max',
          ),
      transferTrigger:
          (y['transfer_trigger'] as String?) ?? 'ascend_to_wusheng',
      multiDiscipleAllocation:
          (y['multi_disciple_allocation'] as String?) ?? 'player_pick',
      stackAcrossGenerations:
          (y['stack_across_generations'] as bool?) ??
          _missingRequiredValue(
            'inheritance.heritage_items.stack_across_generations',
          ),
      conflictSlotResolution:
          (y['conflict_slot_resolution'] as String?) ?? 'auto_swap',
    );
  }
}
```

<a id="q069"></a>
### Q069

```sh
sed -n 428,428p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
```

<a id="q070"></a>
### Q070

```sh
sed -n 807,807p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
  factory HeritageItems.fromYaml(Map<String, dynamic> y) {
```

<a id="q071"></a>
### Q071

```sh
rg -n --with-filename --no-heading --sort path -- 'synergies|synergyDefs' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：10；退出码：0。

```text
lib/data/numbers_config.dart:25:/// inheritance / synergies / validation_examples）保留 [raw] 原始 Map，
lib/data/game_repository.dart:127:  /// data/synergies.yaml 加载。test fixture 不带 yaml 时为空 list。
lib/data/game_repository.dart:130:  final List<SynergyDef> synergies;
lib/data/game_repository.dart:188:    required this.synergies,
lib/data/game_repository.dart:371:    final synergies = await _loadOptionalAsset(
lib/data/game_repository.dart:373:      'data/synergies.yaml',
lib/data/game_repository.dart:375:        final synergiesRaw = parseYamlMap(raw);
lib/data/game_repository.dart:376:        return ((synergiesRaw['synergies'] as List?) ?? const [])
lib/data/game_repository.dart:514:      synergies: synergies,
lib/data/game_repository.dart:1000:      synergies: synergies,
```

<a id="q072"></a>
### Q072

```sh
sed -n 369,382p lib/data/game_repository.dart
```

命中/输出行数：14；退出码：0。

```text
    // W18-A1:心法相生 yaml(允许 test fixture 不带,空 list)。生产路径
    // 红线校验在 enforceSynergyRedLines(validation/) 强制 ≥ 5 + multiplier 范围。
    final synergies = await _loadOptionalAsset(
      load,
      'data/synergies.yaml',
      (raw) {
        final synergiesRaw = parseYamlMap(raw);
        return ((synergiesRaw['synergies'] as List?) ?? const [])
            .map(
              (e) => SynergyDef.fromYaml(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false);
      },
      strict: strict,
```

<a id="q073"></a>
### Q073

```sh
sed -n 373,373p lib/data/game_repository.dart
```

命中/输出行数：1；退出码：0。

```text
      'data/synergies.yaml',
```

<a id="q074"></a>
### Q074

```sh
rg -n --with-filename --no-heading --sort path -- 'validation_examples|raw' lib/data/numbers_config.dart lib/data/game_repository.dart
```

命中/输出行数：88；退出码：0。

```text
lib/data/numbers_config.dart:25:/// inheritance / synergies / validation_examples）保留 [raw] 原始 Map，
lib/data/numbers_config.dart:277:  final Map<String, dynamic> raw;
lib/data/numbers_config.dart:333:    required this.raw,
lib/data/numbers_config.dart:337:  /// `milestone_equipment_grants` 段)。从 [raw] 读,缺段兜底空 map。
lib/data/numbers_config.dart:340:    final m = raw['milestone_equipment_grants'] as Map?;
lib/data/numbers_config.dart:540:      raw: y,
lib/data/numbers_config.dart:590:  static List<RarityTierRange> _parseRarityTiers(List? raw) {
lib/data/numbers_config.dart:591:    if (raw == null) return const [];
lib/data/numbers_config.dart:593:      for (final e in raw)
lib/data/numbers_config.dart:996:    final raw = 0.50 - 0.02 * (targetLevel - 19);
lib/data/numbers_config.dart:997:    return raw < 0.30 ? 0.30 : raw;
lib/data/numbers_config.dart:1000:  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
lib/data/numbers_config.dart:1002:      for (final e in raw)
lib/data/numbers_config.dart:1012:  static List<MaterialCostBracket> _parseMaterialCost(List raw) {
lib/data/numbers_config.dart:1014:      for (final e in raw)
lib/data/numbers_config.dart:1023:  static List<CrystalGuaranteeBracket> _parseCrystalGuarantees(List raw) {
lib/data/numbers_config.dart:1025:      for (final e in raw)
lib/data/numbers_config.dart:1422:  factory PostureNumbersConfig.fromYaml(Object? raw) {
lib/data/numbers_config.dart:1423:    if (raw is! Map) {
lib/data/numbers_config.dart:1426:    final yaml = raw.cast<Object?, Object?>();
lib/data/numbers_config.dart:2234:  factory Phase0aBasicAttackChainConfig.fromYaml(Object? raw) {
lib/data/numbers_config.dart:2235:    if (raw == null) return empty;
lib/data/numbers_config.dart:2236:    if (raw is! Map) {
lib/data/numbers_config.dart:2240:    for (final entry in raw.entries) {
lib/data/numbers_config.dart:2267:  factory Phase0aBasicAttackSegmentTuning.fromYaml(Map raw) {
lib/data/numbers_config.dart:2268:    final attackRange = (raw['attack_range'] as num).toDouble();
lib/data/numbers_config.dart:2269:    final attackHalfArcRadians = (raw['attack_half_arc_radians'] as num)
lib/data/numbers_config.dart:2271:    final maxTargets = (raw['max_targets'] as num).toInt();
lib/data/numbers_config.dart:2272:    final advanceDistance = (raw['advance_distance'] as num).toDouble();
lib/data/numbers_config.dart:2273:    final aimAssistRadians = (raw['aim_assist_radians'] as num).toDouble();
lib/data/numbers_config.dart:2558:    final raw3 = y['diff_3_or_more'] as Map<String, dynamic>;
lib/data/numbers_config.dart:2565:            (raw3['attacker'] as num?)?.toDouble() ??
lib/data/numbers_config.dart:2569:        defender: (raw3['defender'] as num).toDouble(),
lib/data/numbers_config.dart:2848:    final rawMaps = y['maps'] as List;
lib/data/numbers_config.dart:2849:    final rawSolar = y['solar_term_bonus'] as Map<String, dynamic>;
lib/data/numbers_config.dart:2850:    final rawTimeOfDay = y['time_of_day_bonus'] as List;
lib/data/numbers_config.dart:2853:        rawTimeOfDay.firstWhere(
lib/data/numbers_config.dart:2860:        rawTimeOfDay.firstWhere(
lib/data/numbers_config.dart:2869:    final solarDays = (rawSolar['days_2026'] as List)
lib/data/numbers_config.dart:2894:        for (final m in rawMaps)
lib/data/numbers_config.dart:2910:      solarTermMultiplier: (rawSolar['multiplier'] as num).toDouble(),
lib/data/numbers_config.dart:3026:    final rawDays = y['days_2026'] as List?;
lib/data/numbers_config.dart:3027:    if (rawDays == null) return empty;
lib/data/numbers_config.dart:3029:    for (final raw in rawDays) {
lib/data/numbers_config.dart:3030:      final entry = raw as Map;
lib/data/numbers_config.dart:3078:    for (final raw in tiersRaw) {
lib/data/numbers_config.dart:3080:        ReputationTierDef.fromYaml(Map<String, dynamic>.from(raw as Map)),
lib/data/numbers_config.dart:3227:/// 替原 `numbers.raw['sect_event']` dynamic map(沿 P3.4 spec §9 简化路径,
lib/data/numbers_config.dart:3456:    final raw = y['by_sect_level'] as List?;
lib/data/numbers_config.dart:3457:    if (raw == null || raw.isEmpty) return empty;
lib/data/numbers_config.dart:3459:      bySectLevel: raw.map((e) => (e as num).toInt()).toList(growable: false),
lib/data/numbers_config.dart:3560:    final raw = y['max_per_sect_by_level'] as List?;
lib/data/numbers_config.dart:3565:      maxPerSectByLevel: raw == null || raw.isEmpty
lib/data/numbers_config.dart:3567:          : raw.map((e) => (e as num).toInt()).toList(growable: false),
lib/data/numbers_config.dart:3601:    final raw = (y?['stages'] as List?) ?? const [];
lib/data/numbers_config.dart:3602:    final stages = raw
lib/data/numbers_config.dart:3880:    Map<String, dynamic> raw,
lib/data/numbers_config.dart:3883:    for (final tableEntry in raw.entries) {
lib/data/numbers_config.dart:4087:    final raw = (y['disciple_joins'] as List?) ?? const [];
lib/data/numbers_config.dart:4089:      discipleJoins: raw
lib/data/game_repository.dart:249:      (raw) => _parseDefMap(
lib/data/game_repository.dart:250:        parseYamlMap(raw)['encounter_skills'] as List,
lib/data/game_repository.dart:289:      (raw) => FounderCreationConfig.fromYaml(parseYamlMap(raw)),
lib/data/game_repository.dart:297:      (raw) => FounderNamesConfig.fromYaml(parseYamlMap(raw)),
lib/data/game_repository.dart:306:      (raw) {
lib/data/game_repository.dart:308:          parseYamlMap(raw)['recruit_candidates'] as List,
lib/data/game_repository.dart:333:      (raw) {
lib/data/game_repository.dart:335:          parseYamlMap(raw)['sect_candidates'] as List,
lib/data/game_repository.dart:359:      (raw) => _parseDefMap(
lib/data/game_repository.dart:360:        parseYamlMap(raw)['encounters'] as List,
lib/data/game_repository.dart:374:      (raw) {
lib/data/game_repository.dart:375:        final synergiesRaw = parseYamlMap(raw);
lib/data/game_repository.dart:396:      (raw) {
lib/data/game_repository.dart:397:        final territoriesRaw = parseYamlList(raw);
lib/data/game_repository.dart:413:      (raw) {
lib/data/game_repository.dart:414:        final factionsRaw = parseYamlMap(raw);
lib/data/game_repository.dart:435:      (raw) {
lib/data/game_repository.dart:436:        final shopRaw = parseYamlMap(raw);
lib/data/game_repository.dart:451:      (raw) {
lib/data/game_repository.dart:452:        final itemsRaw = parseYamlMap(raw);
lib/data/game_repository.dart:467:      (raw) => ExpeditionConfig.fromYaml(parseYamlMap(raw)),
lib/data/game_repository.dart:474:      (raw) => BossGauntletConfig.fromYaml(parseYamlMap(raw)),
lib/data/game_repository.dart:547:    T Function(String raw) parse, {
lib/data/game_repository.dart:552:    final String raw;
lib/data/game_repository.dart:554:      raw = await load(assetPath);
lib/data/game_repository.dart:566:      return parse(raw);
lib/data/game_repository.dart:787:    for (final raw in items) {
lib/data/game_repository.dart:788:      final def = parser(Map<String, dynamic>.from(raw as Map));
```

<a id="q075"></a>
### Q075

```sh
sed -n 537,542p lib/data/numbers_config.dart
```

命中/输出行数：6；退出码：0。

```text
      phase0aArena: Phase0aArenaConfig.fromYaml(
        (y['phase0a_arena'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      raw: y,
    );
  }
```

<a id="q076"></a>
### Q076

```sh
sed -n 540,540p lib/data/numbers_config.dart
```

命中/输出行数：1；退出码：0。

```text
      raw: y,
```

<a id="q077"></a>
### Q077

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- last_updated lib test tool tools
```

命中/输出行数：3；退出码：0。

```text
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:29:    (r"meta\.", "头注 UNUSED", "存档时间戳，不是运行配置；已有纯文档说明。", "last_updated|纯文档", ["data/numbers.yaml"], [("data/numbers.yaml", 28, 34)]),
```

<a id="q078"></a>
### Q078

```sh
rg -n --with-filename --no-heading --sort path -F -- last_updated lib test tool tools
```

命中/输出行数：3；退出码：0。

```text
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:29:    (r"meta\.", "头注 UNUSED", "存档时间戳，不是运行配置；已有纯文档说明。", "last_updated|纯文档", ["data/numbers.yaml"], [("data/numbers.yaml", 28, 34)]),
```

<a id="q079"></a>
### Q079

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'meta\.last_updated' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q080"></a>
### Q080

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- last_updated data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：4；退出码：0。

```text
data/numbers.yaml:32:  #   （numbers_config.dart:316,323），meta 其余 key 无任何读取点。last_updated 已
data/numbers.yaml:34:  last_updated: "2026-05-10"
docs/dispatch/reports/2026-08-07_PI1_yaml_consumption.md:42:| data/numbers.yaml:31 | `last_updated` | 0 | `meta` 元数据;NumbersConfig 只消费 `meta.version` |
docs/dispatch/reports/2026-08-07_Q1_field_verify.md:32:| 1 | `last_updated` | numbers.yaml:31(meta) | 真未消费 | `NumbersConfig.fromYaml` 只取 `meta['version']`(`numbers_config.dart:316,323`),meta 其余 key 无读取 |
```

<a id="q081"></a>
### Q081

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Slast_updated -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
13ce2300f 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q082"></a>
### Q082

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Slast_updated -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q083"></a>
### Q083

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Slast_updated -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
```

<a id="q084"></a>
### Q084

```sh
git show fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4:data/numbers.yaml
```

命中/输出行数：1121；退出码：0。

```text
# =============================================================================
# numbers.yaml · 武侠挂机游戏数值总配置
# =============================================================================
#
# 文档地位：本文件包含所有可调数值。所有 Dart 代码不得硬编码数值，必须通过
#          GameRepository 从本文件加载。改数值不动代码、不动存档结构。
#
# 遵循文档：GDD.md v1.1、data_schema.md v1.1
# 维护者：Mac 端 Claude Code + Opus 4.7
#
# =============================================================================
# 重要：GDD 公式口误标注
# =============================================================================
#
# GDD §5.3 写"装备攻击 × 8"、§5.6 写"内力 × 5"，按字面公式会突破 §5.2
# 数值红线（伤害破万、武圣血量超 80000）。本文件采用经过平衡的系数：
#
#   装备攻击系数：1.0（GDD 字面值 8.0，平衡后调为 1.0）
#   内力血量系数：0.7（GDD 字面值 5.0，平衡后调为 0.7）
#
# 战例验证（二流·圆熟同境界普通攻击对决）：
#   GDD 字面公式：基础伤害 6340，最终 11095（破红线）
#   平衡后公式：基础伤害 2280，最终 3990（在 2000-8000 区间）✓
#
# =============================================================================

meta:
  version: "0.1.0"             # 与 SaveData.saveVersion 对应；major.minor.patch
  description: "Demo 阶段数值配置 · 覆盖学徒到武圣全程"
  last_updated: "2026-05-10"
  notes: "所有数值基于 GDD v1.1 §5.2 数值红线设计；公式系数见 combat 段"

# =============================================================================
# 1. 战斗公式系数
# =============================================================================
# 对应 GDD §5.3 / §5.4 / §5.6 三大公式。所有系数提取为可调参数，便于未来
# 整体平衡调整。

combat:

  # --- 基础伤害公式 ---
  # GDD §5.3：基础伤害 = (内力 × 0.4) + (装备攻击 × 8) + 招式倍率
  # 平衡后：    基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
  damage_formula:
    internal_force_factor: 0.4       # 内力对伤害的系数（GDD 原值，未变）
    equipment_attack_factor: 1.0     # 装备攻击系数（GDD 原写 8，平衡后调为 1.0）
    skill_multiplier_added: true     # 招式倍率作为加项（不是乘项）

  # --- 最终伤害公式（GDD §5.4）---
  # 最终伤害 = 基础伤害 × 修炼度加成 × 流派克制 × 暴击系数 × (1-防御率) × 境界差修正
  final_damage_formula:
    apply_cultivation_multiplier: true   # 应用心法修炼度（1.0~3.0）
    apply_school_counter: true           # 应用流派克制（0.75/1.0/1.25）
    apply_critical: true                 # 应用暴击（1.0 或 1.5~2.5）
    apply_defense: true                  # 应用防御率（1 - defense_rate）
    apply_realm_diff: true               # 应用境界差修正

  # --- 最大血量公式 ---
  # GDD §5.6：血量 = 1000 + 内力 × 5 + 根骨 × 500 + 装备血量
  # 平衡后：   血量 = 1000 + 内力 × 0.7 + 根骨 × 500 + 装备血量
  # 设计目标：武圣·登峰满根骨 ≤ 20000（§5.2 玩家血量上限）
  max_hp_formula:
    base: 1000                       # 基础血量（GDD 原值）
    internal_force_factor: 0.7       # 内力系数（GDD 原写 5，平衡后调为 0.7）
    constitution_factor: 500         # 根骨系数（GDD 原值，每点 +500）

  # --- 出手速度公式（GDD §5.6 原值，无需调整）---
  # 速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成
  speed_formula:
    base: 100
    agility_factor: 8

  # --- 暴击率与暴击伤害 ---
  # 暴击率主要由身法和心法决定，灵巧流派额外 +20%（GDD §4.4）
  critical:
    base_rate: 0.05                  # 基础暴击率 5%
    agility_per_point_rate: 0.005    # 每点身法 +0.5% 暴击率
    max_rate: 0.50                   # 暴击率硬上限 50%
    base_damage_multiplier: 1.5      # 暴击伤害基础倍率
    max_damage_multiplier: 2.5       # 暴击伤害最高倍率（堆心法/装备后）

  # --- 闪避率（由身法决定，与速度共享身法属性）---
  evasion:
    agility_per_point_rate: 0.003    # 每点身法 +0.3% 闪避率
    max_rate: 0.30                   # 闪避率硬上限 30%

# =============================================================================
# 2. 49 级境界系统
# =============================================================================
# GDD §3.1：7 个大境界 × 7 层 = 49 级
# 关键约束：内力 500-15000（§5.2 红线）、装备/心法品阶随境界开放（§3.4）

realms:

  # --- 境界差距修正（GDD §5.5，强制规则不可调）---
  # 表中数字均从"高境界视角"看：你打对方时的伤害修正 / 对方打你时的伤害修正
  level_diff_modifier:
    same_tier:           # 同大境界
      attacker: 1.0
      defender: 1.0
    diff_1_tier:         # 差 1 大境界（你高对方低）
      attacker: 1.4      # 你打对方：×1.4
      defender: 0.7      # 对方打你：×0.7
    diff_2_tier:         # 差 2 大境界
      attacker: 2.5
      defender: 0.3
    diff_3_or_more:      # 差 3+ 大境界（基本免疫）
      attacker: null     # 已经是碾压，无需再放大；按 ×2.5 上限处理即可
      defender: 0.05     # 低境界打高境界仅 5% 伤害

  # --- 49 级境界完整数值表 ---
  # 字段说明：
  #   absolute_level   : 总层数 1-49（强化等级上限 = 该值）
  #   internal_force_max: 该层内力上限（决定基础属性）
  #   experience_to_next: 突破到下一层所需经验
  #   defense_rate     : 该大境界基础防御率（同大境界内 7 层共用）
  #
  # 设计曲线：
  #   - 内力线性递增到一流，绝顶以上加速
  #   - 经验呈指数递增（每境界总经验约为前一境界 3-5 倍）
  #   - 总经验跨度 ~7,600,000（足够支撑数十至上百小时游戏时长）

  tiers:

    # === 学徒（1-7）：学武起步 ===
    # 防御率 5%，可用装备：寻常货，可修心法：入门功
    - tier: xueTu
      defense_rate: 0.05
      equipment_tier_cap: xunChang
      technique_tier_cap: ruMenGong
      layers:
        - layer: qiMeng    # 1 启蒙
          absolute_level: 1
          internal_force_max: 500
          experience_to_next: 50
        - layer: ruMen     # 2 入门
          absolute_level: 2
          internal_force_max: 600
          experience_to_next: 80
        - layer: shuLian   # 3 熟练
          absolute_level: 3
          internal_force_max: 700
          experience_to_next: 120
        - layer: jingTong  # 4 精通
          absolute_level: 4
          internal_force_max: 800
          experience_to_next: 170
        - layer: yuanShu   # 5 圆熟
          absolute_level: 5
          internal_force_max: 900
          experience_to_next: 230
        - layer: huaJing   # 6 化境
          absolute_level: 6
          internal_force_max: 1000
          experience_to_next: 300
        - layer: dengFeng  # 7 登峰
          absolute_level: 7
          internal_force_max: 1100
          experience_to_next: 400  # 突破到三流·启蒙

    # === 三流（8-14）：江湖小卒 ===
    # 防御率 10%，装备升级到像样货，心法升级到常练功
    - tier: sanLiu
      defense_rate: 0.10
      equipment_tier_cap: xiangYang
      technique_tier_cap: changLianGong
      layers:
        - layer: qiMeng
          absolute_level: 8
          internal_force_max: 1200
          experience_to_next: 500
        - layer: ruMen
          absolute_level: 9
          internal_force_max: 1330
          experience_to_next: 700
        - layer: shuLian
          absolute_level: 10
          internal_force_max: 1460
          experience_to_next: 950
        - layer: jingTong
          absolute_level: 11
          internal_force_max: 1600
          experience_to_next: 1250
        - layer: yuanShu
          absolute_level: 12
          internal_force_max: 1740
          experience_to_next: 1600
        - layer: huaJing
          absolute_level: 13
          internal_force_max: 1870
          experience_to_next: 2000
        - layer: dengFeng
          absolute_level: 14
          internal_force_max: 2000
          experience_to_next: 2500  # 突破到二流·启蒙

    # === 二流（15-21）：一方好手 ===
    # 防御率 15%，装备升级到好家伙，心法升级到名家功
    - tier: erLiu
      defense_rate: 0.15
      equipment_tier_cap: haoJiaHuo
      technique_tier_cap: mingJiaGong
      layers:
        - layer: qiMeng
          absolute_level: 15
          internal_force_max: 2200
          experience_to_next: 3000
        - layer: ruMen
          absolute_level: 16
          internal_force_max: 2400
          experience_to_next: 3700
        - layer: shuLian
          absolute_level: 17
          internal_force_max: 2600
          experience_to_next: 4500
        - layer: jingTong
          absolute_level: 18
          internal_force_max: 2800
          experience_to_next: 5500
        - layer: yuanShu
          absolute_level: 19
          internal_force_max: 3000
          experience_to_next: 6700
        - layer: huaJing
          absolute_level: 20
          internal_force_max: 3200
          experience_to_next: 8000
        - layer: dengFeng
          absolute_level: 21
          internal_force_max: 3500
          experience_to_next: 9500  # 突破到一流·启蒙

    # === 一流（22-28）：名门高手 · Demo 主线终点 ===
    # 防御率 20%，装备升级到利器，心法升级到门派绝学
    - tier: yiLiu
      defense_rate: 0.20
      equipment_tier_cap: liQi
      technique_tier_cap: menPaiJueXue
      layers:
        - layer: qiMeng
          absolute_level: 22
          internal_force_max: 3800
          experience_to_next: 11000
        - layer: ruMen
          absolute_level: 23
          internal_force_max: 4100
          experience_to_next: 13000
        - layer: shuLian
          absolute_level: 24
          internal_force_max: 4400
          experience_to_next: 15500
        - layer: jingTong
          absolute_level: 25
          internal_force_max: 4700
          experience_to_next: 18500
        - layer: yuanShu
          absolute_level: 26
          internal_force_max: 5000
          experience_to_next: 22000
        - layer: huaJing
          absolute_level: 27
          internal_force_max: 5300
          experience_to_next: 26000
        - layer: dengFeng
          absolute_level: 28
          internal_force_max: 5700
          experience_to_next: 30000  # 突破到绝顶·启蒙

    # === 绝顶（29-35）：当世高手 ===
    # 防御率 25%，装备升级到重器，心法升级到江湖秘传
    - tier: jueDing
      defense_rate: 0.25
      equipment_tier_cap: zhongQi
      technique_tier_cap: jiangHuMiChuan
      layers:
        - layer: qiMeng
          absolute_level: 29
          internal_force_max: 6000
          experience_to_next: 35000
        - layer: ruMen
          absolute_level: 30
          internal_force_max: 6500
          experience_to_next: 42000
        - layer: shuLian
          absolute_level: 31
          internal_force_max: 7000
          experience_to_next: 50000
        - layer: jingTong
          absolute_level: 32
          internal_force_max: 7500
          experience_to_next: 60000
        - layer: yuanShu
          absolute_level: 33
          internal_force_max: 8000
          experience_to_next: 72000
        - layer: huaJing
          absolute_level: 34
          internal_force_max: 8500
          experience_to_next: 86000
        - layer: dengFeng
          absolute_level: 35
          internal_force_max: 9000
          experience_to_next: 100000  # 突破到宗师·启蒙

    # === 宗师（36-42）：一代宗师 ===
    # 防御率 30%，装备升级到宝物，心法升级到失传神功
    # 解锁断崖绝壁闭关地图
    - tier: zongShi
      defense_rate: 0.30
      equipment_tier_cap: baoWu
      technique_tier_cap: shiChuanShenGong
      layers:
        - layer: qiMeng
          absolute_level: 36
          internal_force_max: 9500
          experience_to_next: 120000
        - layer: ruMen
          absolute_level: 37
          internal_force_max: 10000
          experience_to_next: 145000
        - layer: shuLian
          absolute_level: 38
          internal_force_max: 10500
          experience_to_next: 175000
        - layer: jingTong
          absolute_level: 39
          internal_force_max: 11000
          experience_to_next: 210000
        - layer: yuanShu
          absolute_level: 40
          internal_force_max: 11500
          experience_to_next: 250000
        - layer: huaJing
          absolute_level: 41
          internal_force_max: 12000
          experience_to_next: 300000
        - layer: dengFeng
          absolute_level: 42
          internal_force_max: 12500
          experience_to_next: 360000  # 突破到武圣·启蒙

    # === 武圣（43-49）：武林神话 · 终极境界 ===
    # 防御率 35%，装备升级到神物，心法升级到传说神功
    - tier: wuSheng
      defense_rate: 0.35
      equipment_tier_cap: shenWu
      technique_tier_cap: chuanShuoShenGong
      layers:
        - layer: qiMeng
          absolute_level: 43
          internal_force_max: 13000
          experience_to_next: 430000
        - layer: ruMen
          absolute_level: 44
          internal_force_max: 13400
          experience_to_next: 510000
        - layer: shuLian
          absolute_level: 45
          internal_force_max: 13700
          experience_to_next: 610000
        - layer: jingTong
          absolute_level: 46
          internal_force_max: 14000
          experience_to_next: 730000
        - layer: yuanShu
          absolute_level: 47
          internal_force_max: 14400
          experience_to_next: 870000
        - layer: huaJing
          absolute_level: 48
          internal_force_max: 14700
          experience_to_next: 1040000
        - layer: dengFeng
          absolute_level: 49
          internal_force_max: 15000
          experience_to_next: 0   # 满级，无下一层

# =============================================================================
# 3. 装备系统
# =============================================================================
# GDD §3.2 7 阶装备 + §6.2 强化 + §6.3 心血结晶 + §6.4 共鸣 + §6.5 开锋

equipment:

  # --- 7 阶装备的基础数值范围 ---
  # 每件具体装备实例（如"青锋剑"）从 EquipmentDef 读取范围，生成时按
  # 范围 random 一次。范围内随机让"同阶装备拉开个体差异"，符合武侠"宝兵
  # 各有特点"的叙事。
  #
  # 设计原则：
  #   - 武器 → 主攻击/速度，少量血量（武器作用是杀敌）
  #   - 护甲 → 主血量，少量速度，无攻击
  #   - 饰品 → 中等血量，少量攻击/速度（小而全）
  #
  # 数值校验：
  #   - 装备攻击上限 2000（GDD §5.2 红线）→ 神物·武器 1500-2000 ✓
  #   - 装备血量贡献 ≤ 3000（避免单装备血量超过基础）→ 神物·护甲 2000-3000 ✓
  #   - 装备速度贡献 ≤ 100（避免速度膨胀）→ 神物·武器 65-100 ✓

  tiers:

    # === 第 1 阶 寻常货 · 学徒境界开放 ===
    - tier: xunChang
      tier_name: "寻常货"
      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}
      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}
      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}

    # === 第 2 阶 像样货 · 三流境界开放 ===
    - tier: xiangYang
      tier_name: "像样货"
      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}
      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}
      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}

    # === 第 3 阶 好家伙 · 二流境界开放 ===
    - tier: haoJiaHuo
      tier_name: "好家伙"
      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}
      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}
      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}

    # === 第 4 阶 利器 · 一流境界开放 · Demo 主线最高级装备 ===
    - tier: liQi
      tier_name: "利器"
      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}
      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}
      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}

    # === 第 5 阶 重器 · 绝顶境界开放 ===
    - tier: zhongQi
      tier_name: "重器"
      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}
      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}
      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}

    # === 第 6 阶 宝物 · 宗师境界开放 ===
    - tier: baoWu
      tier_name: "宝物"
      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}
      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1600, hp_max: 2300, speed_min: 25, speed_max: 50}
      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 850,  hp_max: 1300, speed_min: 45, speed_max: 70}

    # === 第 7 阶 神物 · 武圣境界开放 ===
    - tier: shenWu
      tier_name: "神物"
      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 200, hp_max: 500, speed_min: 65, speed_max: 100}
      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 2300, hp_max: 3000, speed_min: 40, speed_max: 70}
      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1300, hp_max: 1800, speed_min: 65, speed_max: 95}

  # --- 强化系统（GDD §6.2）---
  enhancement:
    bonus_per_level: 0.05            # 每级 +5% 数值（GDD 原值）
    max_level_formula: "absolute_level"  # 强化上限 = 持有者境界总层数（最高 +49）

    # 成功率与失败惩罚（GDD §6.2 表）
    # 失败惩罚 material_penalty 含义：
    #   "half"  → 仅扣半数磨剑石
    #   "full"  → 全扣磨剑石
    success_curve:
      - level_range: [1, 10]
        success_rate: 1.00
        material_penalty: "none"
      - level_range: [11, 13]
        success_rate: 0.90
        material_penalty: "half"
      - level_range: [14, 16]
        success_rate: 0.75
        material_penalty: "full"
      - level_range: [17, 19]
        success_rate: 0.50
        material_penalty: "full"
      # +20 及以上：每级成功率 -2%，最低 30%（武圣后期高难度强化）
      - level_range: [20, 49]
        success_rate: null           # 由代码按 max(0.30, 0.50 - 0.02*(level-19)) 计算
        success_formula: "max(0.30, 0.50 - 0.02 * (level - 19))"
        material_penalty: "full"

    # 磨剑石消耗曲线（每级强化一次的消耗）
    # 设计原则：低强化便宜、高强化材料压力大，避免无脑强化
    mojianshi_cost:
      - level_range: [1, 5]
        cost: 1
      - level_range: [6, 10]
        cost: 2
      - level_range: [11, 13]
        cost: 4
      - level_range: [14, 16]
        cost: 7
      - level_range: [17, 19]
        cost: 12
      - level_range: [20, 30]
        cost: 18
      - level_range: [31, 49]
        cost: 25

    # 关键设计：永不破防降级（GDD §6.2 红线）
    never_degrade: true              # 失败仅扣材料，不会从 +18 掉到 +12

  # --- 心血结晶保底（GDD §6.3）---
  xinxue_jiejing:
    gain_per_failure: 1              # 每次强化失败必得 1 颗
    guaranteed_success_costs:
      - level_range: [14, 16]
        crystal_cost: 3              # +14~+16 段消耗 3 颗直接成功
      - level_range: [17, 19]
        crystal_cost: 5              # +17~+19 段消耗 5 颗直接成功
      - level_range: [20, 49]
        crystal_cost: 8              # +20+ 段消耗 8 颗（数值平衡，避免后期囤积无用）

  # --- 共鸣度阶段（GDD §6.4，强制规则）---
  resonance:
    stages:
      - stage: shengShu              # 生疏
        battle_count_range: [0, 100]
        bonus_multiplier: 1.0
        unlocks_joint_skill: false
        has_sword_song_effect: false
      - stage: chenShou              # 趁手
        battle_count_range: [100, 500]
        bonus_multiplier: 1.10       # 装备数值 +10%
        unlocks_joint_skill: false
        has_sword_song_effect: false
      - stage: moQi                  # 默契
        battle_count_range: [500, 2000]
        bonus_multiplier: 1.20       # +20%
        unlocks_joint_skill: true    # 解锁人剑合一招式
        has_sword_song_effect: false
      - stage: xinJianTongLing       # 心剑通灵
        battle_count_range: [2000, null]   # 上不封顶
        bonus_multiplier: 1.30       # +30%
        unlocks_joint_skill: true
        has_sword_song_effect: true  # 暴击附带剑鸣特效

    # 师承传承时的清零规则（GDD §6.4）
    inheritance_retention: 0.7       # 传给徒弟保留 70%（鼓励"一柄剑用一辈子"）
    new_owner_retention: 0.0         # 玩家间换主直接清零

  # --- 开锋系统（GDD §6.5）---
  forging:
    slots:
      - slot_index: 1
        unlock_at_enhance_level: 10  # +10 解锁开锋一
        available_types: [attack, speed, lifesteal, pierce]
        bonus_value:
          attack: 15        # 攻击 +15%
          speed: 15         # 速度 +15%
          lifesteal: 10     # 吸血 10%（命中时回血百分比）
          pierce: 15        # 破甲 15%（无视目标 15% 防御）
      - slot_index: 2
        unlock_at_enhance_level: 15  # +15 解锁开锋二
        available_types: [attack, speed, lifesteal, pierce]
        bonus_value:
          attack: 20
          speed: 20
          lifesteal: 15
          pierce: 20
        constraint: "不能与开锋一相同类型"
      - slot_index: 3
        unlock_at_enhance_level: 19  # +19 解锁开锋三
        available_types: [specialSkill]   # 仅可解锁专属技能
        bonus_value:
          specialSkill: 1   # 解锁一个专属技能词条（具体技能由 EquipmentDef 定义）

  # --- 师承遗物（GDD §6.1）---
  lineage_heritage:
    pieces_per_generation_min: 1     # 每代师父最少传 1 件
    pieces_per_generation_max: 2     # 每代师父最多传 2 件
    internal_force_max_bonus: 0.05   # 师承遗物自带内力上限 +5% buff

# =============================================================================
# 4. 心法系统
# =============================================================================
# GDD §3.3 7 阶心法 + §4.3 9 层修炼度 + §4.4 三流派克制

techniques:

  # --- 7 阶心法的属性加成 ---
  # 设计原则：
  #   - 内力增长加成：影响挂机/闭关时内力恢复速率
  #   - 速度加成：直接进入速度公式（GDD §5.6）
  #   - 招式倍率上限：高阶心法的招式倍率封顶值
  tiers:

    - tier: ruMenGong         # 1 入门功
      tier_name: "入门功"
      internal_force_growth_bonus: 1.05    # 内力增长 +5%
      speed_bonus: 0
      max_skill_multiplier: 1500            # 该阶心法招式倍率不超过 1500（普通-中级强力技能）

    - tier: changLianGong     # 2 常练功
      tier_name: "常练功"
      internal_force_growth_bonus: 1.10
      speed_bonus: 5
      max_skill_multiplier: 2000

    - tier: mingJiaGong       # 3 名家功
      tier_name: "名家功"
      internal_force_growth_bonus: 1.15
      speed_bonus: 10
      max_skill_multiplier: 2500

    - tier: menPaiJueXue      # 4 门派绝学
      tier_name: "门派绝学"
      internal_force_growth_bonus: 1.25
      speed_bonus: 15
      max_skill_multiplier: 3000

    - tier: jiangHuMiChuan    # 5 江湖秘传
      tier_name: "江湖秘传"
      internal_force_growth_bonus: 1.40
      speed_bonus: 25
      max_skill_multiplier: 4000

    - tier: shiChuanShenGong  # 6 失传神功
      tier_name: "失传神功"
      internal_force_growth_bonus: 1.60
      speed_bonus: 40
      max_skill_multiplier: 5500

    - tier: chuanShuoShenGong # 7 传说神功
      tier_name: "传说神功"
      internal_force_growth_bonus: 2.00
      speed_bonus: 60
      max_skill_multiplier: 8000           # 含大招（如九阳神功的"龙吟九霄"）

  # --- 9 层修炼度（GDD §4.3，强制规则）---
  cultivation:
    layers:
      - layer: chuKui          # 1 初窥
        bonus_multiplier: 1.00
      - layer: xiaoCheng       # 2 小成
        bonus_multiplier: 1.15
      - layer: zhongCheng      # 3 中成
        bonus_multiplier: 1.30
      - layer: daCheng         # 4 大成
        bonus_multiplier: 1.50
      - layer: yuanMan         # 5 圆满
        bonus_multiplier: 1.75
      - layer: dianFeng        # 6 巅峰
        bonus_multiplier: 2.00
      - layer: tongShen        # 7 通神
        bonus_multiplier: 2.30
      - layer: wuXia           # 8 无瑕
        bonus_multiplier: 2.60
      - layer: jiJing          # 9 极境
        bonus_multiplier: 3.00

    # 升级到下一层所需的招式使用次数
    # 设计：曲线接近指数（每层 ~1.6 倍），让高层修炼度成为长期目标
    progress_to_next:
      - from_layer: chuKui
        progress_required: 100        # 初窥 → 小成
      - from_layer: xiaoCheng
        progress_required: 250        # 小成 → 中成
      - from_layer: zhongCheng
        progress_required: 500
      - from_layer: daCheng
        progress_required: 900
      - from_layer: yuanMan
        progress_required: 1500
      - from_layer: dianFeng
        progress_required: 2500
      - from_layer: tongShen
        progress_required: 4000
      - from_layer: wuXia
        progress_required: 6500       # 极境最难达，是"老玩家追求"

  # --- 散功代价（GDD §4.3，强制规则）---
  # 换主修时的双重惩罚（不可调，是设计底线条款）
  dispersion:
    internal_force_penalty: 0.50      # 当前内力 -50%（不归零）
    cultivation_penalty: 0.50         # 原主修心法修炼度 -50%

  # --- 三流派克制（GDD §4.4，强制规则）---
  # 关系：刚猛 → 阴柔 → 灵巧 → 刚猛（成环）
  schools:
    counter_relations:
      - attacker: gangMeng              # 刚猛
        target: yinRou                  # 克阴柔
        damage_multiplier: 1.25         # +25% 伤害
        extra_effect: "extra_quake_dmg" # 每招额外震伤
      - attacker: lingQiao              # 灵巧
        target: gangMeng                # 克刚猛
        damage_multiplier: 1.25
        extra_effect: "crit_rate_+0.20" # 暴击率 +20%
      - attacker: yinRou                # 阴柔
        target: lingQiao                # 克灵巧
        damage_multiplier: 1.25
        extra_effect: "internal_injury" # 每招施加内伤 debuff

    # 被克制系数
    countered_multiplier: 0.75          # 被克制时输出 ×0.75
    neutral_multiplier: 1.00            # 同流派或非克制关系时 ×1.0

# =============================================================================
# 5. 招式倍率参考表
# =============================================================================
# GDD §5.3：招式倍率分三档。具体每招由 SkillDef 单独定义，本表是设计参考。
# 实际配置时各阶心法的招式倍率不得超过 techniques.tiers[*].max_skill_multiplier

skills:

  # 招式倍率参考范围（按招式类型）
  # 用于 SkillDef.powerMultiplier 字段配置时的指导值
  reference_multipliers:
    normal_attack:
      base: 500              # GDD §5.3 普通攻击固定倍率
      note: "所有普通攻击统一 500，不随心法阶提升"
    power_skill:
      tier_1_2_range: [1000, 1800]   # 1-2 阶心法的强力技能
      tier_3_4_range: [1500, 2500]   # 3-4 阶
      tier_5_6_range: [2000, 3000]   # 5-6 阶
      tier_7_range:   [2500, 3500]   # 7 阶（传说神功的强力技能）
    ultimate:
      tier_1_2_range: [3000, 4500]   # 1-2 阶心法的大招
      tier_3_4_range: [4500, 6000]
      tier_5_6_range: [5500, 7000]
      tier_7_range:   [6500, 8000]   # 7 阶大招（如九阳"龙吟九霄"）
    joint_skill:
      base: 4500             # 人剑合一招式，固定基础倍率（共鸣度默契阶段解锁）
      note: "共鸣度 +20% 后解锁，不分心法阶"

# =============================================================================
# 6. 角色系统
# =============================================================================
# GDD §4.1 四属性 + 6 档稀有度

character:

  # --- 四项基础属性 ---
  attributes:
    point_per_attribute_min: 1        # 单项属性下限（GDD §4.1）
    point_per_attribute_max: 10       # 单项属性上限
    total_points_min: 16              # 总点数下限
    total_points_max: 24              # 总点数上限
    distribution: "normal"            # 正态分布（中段最常见）
    distribution_mean: 5.5            # 正态分布均值
    distribution_stddev: 1.5          # 标准差
    rerollable: false                 # 不可重 roll（GDD 强制规则）

  # --- 6 档稀有度概率（GDD §4.1，强制规则）---
  # 总和必须为 100%
  rarity_distribution:
    - rarity: yongCai     # 庸才
      probability: 0.15   # 15%
      total_points_range: [16, 17]
    - rarity: xunChang    # 寻常
      probability: 0.35   # 35%
      total_points_range: [18, 19]
    - rarity: biaoZhun    # 标准
      probability: 0.25   # 25%
      total_points_range: [20, 20]
    - rarity: ziYou       # 资优
      probability: 0.18   # 18%
      total_points_range: [21, 22]
    - rarity: tianCai     # 天才
      probability: 0.05   # 5%
      total_points_range: [23, 23]
    - rarity: jueShi      # 绝世
      probability: 0.02   # 2%
      total_points_range: [24, 24]

  # --- 奇遇属性加成（GDD §4.1）---
  # 后天弥补先天，但有硬上限
  adventure_attribute_bonus:
    lifetime_cap_per_character: 5     # 每个角色生涯总加成上限 +5
    bonus_per_event_min: 1            # 单次奇遇最少加 1 点
    bonus_per_event_max: 3            # 单次奇遇最多加 3 点
    distribution: "weighted"          # 大部分加 1，少数加 2-3
    weights: [0.65, 0.25, 0.10]      # 1 点/2 点/3 点的概率

# =============================================================================
# 7. 闭关系统
# =============================================================================
# GDD §7.3 时间锚点闭关 + §8.3 五张地图

retreat:

  # --- 三档闭关时长（GDD §7.3）---
  durations:
    - hours: 1
      description: "短闭关 · 适合短时间游玩场景"
    - hours: 4
      description: "中闭关 · 适合临睡前安排"
    - hours: 12
      description: "长闭关 · 适合工作日全天"

  # --- 五张闭关地图（GDD §8.3）---
  # 产出率字段：所有 _per_hour 字段是"每小时基础产出"，最终产出还会乘以
  # 时辰加成、节气加成、心法加成等

  maps:

    # === 山林：平均产出，新手地图 ===
    - map_type: shanLin
      map_name: "山林"
      required_realm: xueTu                  # 学徒即可进入
      base_outputs:
        experience_per_hour: 100
        mojianshi_per_hour: 1.0
        equipment_drop_rate: 1.0             # 基础掉率（无加成）
        technique_learn_rate: 1.0
        internal_force_growth: 1.0

    # === 古剑冢：兵器掉率 +50% ===
    - map_type: guJianZhong
      map_name: "古剑冢"
      required_realm: sanLiu                 # 三流境界解锁
      base_outputs:
        experience_per_hour: 80
        mojianshi_per_hour: 0.8
        equipment_drop_rate: 1.5             # 兵器掉率 +50%（GDD §8.3）
        technique_learn_rate: 1.0
        internal_force_growth: 1.0

    # === 藏经阁：心法领悟 +50% ===
    - map_type: cangJingGe
      map_name: "藏经阁"
      required_realm: sanLiu
      base_outputs:
        experience_per_hour: 90
        mojianshi_per_hour: 0.5
        equipment_drop_rate: 1.0
        technique_learn_rate: 1.5            # 心法领悟 +50%
        internal_force_growth: 1.0

    # === 悬崖瀑布：内力增长 +50% ===
    - map_type: xuanYaPuBu
      map_name: "悬崖瀑布"
      required_realm: erLiu                  # 二流境界解锁
      base_outputs:
        experience_per_hour: 70
        mojianshi_per_hour: 0.5
        equipment_drop_rate: 1.0
        technique_learn_rate: 1.0
        internal_force_growth: 1.5           # 内力增长 +50%

    # === 断崖绝壁：宗师专属，全维度高产出 ===
    - map_type: duanYaJueBi
      map_name: "断崖绝壁"
      required_realm: zongShi                # 仅宗师以上可去（GDD §8.3）
      base_outputs:
        experience_per_hour: 200
        mojianshi_per_hour: 2.0
        equipment_drop_rate: 1.5             # 全维度都加 50%
        technique_learn_rate: 1.5
        internal_force_growth: 1.5

  # --- 时辰加成（GDD §7.3）---
  # 加成基于"开始闭关时刻"，不会因为跨时辰而动态切换
  time_of_day_bonus:
    - period: ziShi                          # 子时
      time_range: ["23:00", "01:00"]
      effect: "internal_force_growth"
      multiplier: 1.20                       # 内力增长 +20%
    - period: zhengWu                        # 正午
      time_range: ["11:00", "13:00"]
      effect: "yang_school_techniques"       # 阳刚类武学（刚猛流派）+20%
      multiplier: 1.20
    - period: other
      time_range: null                       # 其他时段无加成
      effect: null
      multiplier: 1.00

  # --- 节气日加成（GDD §7.3）---
  solar_term_bonus:
    multiplier: 1.30                         # 节气日全属性 +30%
    # Demo 阶段支持的节气列表（按 2026 年公历日期；后续年份由代码动态计算）
    # 实际计算用农历库（如 chinese_lunar_calendar），yaml 这里只是参考
    days_2026:
      - {name: "立春", date: "2026-02-04"}
      - {name: "清明", date: "2026-04-05"}
      - {name: "立夏", date: "2026-05-06"}
      - {name: "夏至", date: "2026-06-21"}
      - {name: "立秋", date: "2026-08-08"}
      - {name: "中秋", date: "2026-09-25"}
      - {name: "秋分", date: "2026-09-23"}
      - {name: "立冬", date: "2026-11-08"}
      - {name: "冬至", date: "2026-12-22"}

# =============================================================================
# 8. 30 层爬塔"问鼎江湖"
# =============================================================================
# GDD §8.2：每天 5 次挑战次数，通关层数决定排行榜位置

tower:

  # --- 每日挑战次数（GDD §8.2，强制规则）---
  daily_attempts: 5
  refresh_at: "00:00"                        # 本地时区午夜重置（详见 schema §4.10 时区规则）

  # --- 30 层难度递增曲线 ---
  # difficulty_multiplier 影响敌人 HP / 攻击 / 速度
  # 设计原则：
  #   1-10 简单：玩家境界刚到二流即可挑战
  #   11-20 中等：需要二流圆熟 + 利器装备
  #   21-30 困难：需要一流境界 + 强化高的装备
  #   Boss 层（5/15/25 小，10/20/30 大）额外乘以 boss_multiplier

  difficulty_curve:
    # === 简单段 (1-10) ===
    - layers: [1, 2, 3, 4, 5]
      difficulty_range: [1.00, 1.20]         # 线性 1.0/1.05/1.10/1.15/1.20
      tier: "简单前段"
      recommended_realm: erLiu               # 推荐境界：二流·圆熟
    - layers: [6, 7, 8, 9, 10]
      difficulty_range: [1.25, 1.50]         # 1.25/1.30/1.35/1.40/1.50
      tier: "简单后段"
      recommended_realm: erLiu               # 二流·登峰

    # === 中等段 (11-20) ===
    - layers: [11, 12, 13, 14, 15]
      difficulty_range: [1.60, 2.00]         # 1.60/1.70/1.80/1.85/2.00
      tier: "中等前段"
      recommended_realm: yiLiu               # 一流·启蒙
    - layers: [16, 17, 18, 19, 20]
      difficulty_range: [2.10, 2.60]         # 2.10/2.20/2.30/2.45/2.60
      tier: "中等后段"
      recommended_realm: yiLiu               # 一流·圆熟

    # === 困难段 (21-30) · Demo 顶级挑战 ===
    - layers: [21, 22, 23, 24, 25]
      difficulty_range: [2.80, 3.40]         # 2.80/2.95/3.10/3.25/3.40
      tier: "困难前段"
      recommended_realm: yiLiu               # 一流·登峰
    - layers: [26, 27, 28, 29, 30]
      difficulty_range: [3.55, 4.20]         # 3.55/3.70/3.85/4.00/4.20
      tier: "困难后段"
      recommended_realm: jueDing             # 绝顶·启蒙（Demo 不开放绝顶但供爬塔挑战）

  # --- Boss 层配置（GDD §8.2）---
  # 6 个 Boss：3 小 + 3 大
  boss_layers:
    small_boss_layers: [5, 15, 25]           # 小 Boss
    big_boss_layers: [10, 20, 30]            # 大 Boss
    small_boss_multiplier: 1.5               # 小 Boss 数值 ×1.5
    big_boss_multiplier: 2.0                 # 大 Boss 数值 ×2.0

  # --- Boss 血量校验（GDD §5.2 红线 50000+）---
  # 第 30 层大 Boss：base_hp 12000 × difficulty 4.20 × boss_mult 2.0 = 100,800 ✓
  # 第 10 层大 Boss：base_hp 5000 × difficulty 1.50 × 2.0 = 15,000（前期 Boss 较低）
  # 第 20 层大 Boss：base_hp 8500 × difficulty 2.60 × 2.0 = 44,200（接近 50000）
  # 注：以上 base_hp 由 StageDef 中的具体敌人配置决定，此处仅校验

  # --- 排行榜配置 ---
  leaderboard:
    sync_to_supabase: true                   # 通关后同步到 Supabase
    sync_throttle_seconds: 60                # 节流：每 60 秒最多同步一次
    track_metrics: ["highest_layer", "best_clear_time", "total_attempts"]

# =============================================================================
# 9. 师徒传承
# =============================================================================
# GDD §7.1 解锁节奏 + §6.4 装备共鸣传承

inheritance:

  # --- 解锁节奏（GDD §7.1）---
  unlock_rules:
    can_take_disciple_at: yiLiu              # 突破到一流可收徒
    disciple_can_take_grand_disciple_at: jueDing  # 弟子突破到绝顶可收徒孙
    can_pass_legacy_at: wuSheng              # 武圣后传位（飞升渡劫，Demo 不实现）

  # --- Demo 简化（GDD §7.1）---
  demo_max_characters: 3                     # Demo 阶段最多 3 角色：祖师 + 大弟子 + 二弟子

  # --- 师承遗物（GDD §6.1）---
  heritage_items:
    pieces_per_generation_min: 1             # 每代师父传 1-2 件
    pieces_per_generation_max: 2
    auto_buff_internal_force_max: 0.05       # 师承遗物自带 +5% 内力上限 buff
    resonance_retention: 0.7                 # 共鸣度保留 70%

  # --- 祖师爷 buff（GDD §7.1，飞升后）---
  founder_ancestor_buff:
    enabled_when_alive: false                # Demo 阶段未实现飞升
    sect_wide_buff: null                     # 1.0 版本再设计

# =============================================================================
# 10. 心法相生组合（GDD §4.5）
# =============================================================================
# 5 个隐藏组合的具体效果数值。组合判定逻辑见 SynergyDef，本段只给数值。

synergies:

  effect_values:
    # 阴阳调和（九阳 + 九阴）：全属性 +20%
    yin_yang_he:
      effect_type: "all_attr_pct"
      effect_value: 0.20

    # 丐帮传承（降龙十八掌 + 打狗棒法）：解锁"亢龙有悔"暴击
    gai_bang_chuan_cheng:
      effect_type: "unlock_skill_crit"
      target_skill_id: "skill_kang_long_you_hui"
      crit_rate_bonus: 0.50

    # 少林正宗（易筋经 + 少林外功）：内力增长 +30%
    shao_lin_zheng_zong:
      effect_type: "internal_force_growth_pct"
      effect_value: 0.30

    # 武当圆融（太极拳 + 太极剑）：反伤 15%
    wu_dang_yuan_rong:
      effect_type: "reflect_pct"
      effect_value: 0.15

    # 华山合璧（紫霞神功 + 华山剑法）：暴击伤害 +50%
    hua_shan_he_bi:
      effect_type: "crit_dmg_pct"
      effect_value: 0.50

# =============================================================================
# 11. 战例验证
# =============================================================================
# 用具体战例反向验证上述数值是否合理。如果改动 combat 段的系数，
# 务必重新跑一遍这些战例确认未突破 GDD §5.2 红线。

validation_examples:

  # --- 战例 A：学徒新手关 ---
  # 验证目标：第一小时所有战斗让玩家轻松取胜（GDD §10.3）
  example_a:
    description: "学徒·入门 主角 vs 学徒·启蒙 山贼"
    attacker:
      realm: "xueTu / ruMen (lv 2)"
      internal_force: 600
      equipment_attack: 130              # 寻常货武器中段
      skill_multiplier: 500              # 普通攻击
      cultivation_multiplier: 1.00       # 初窥
      school_counter: 1.00               # 中性
      critical: 1.00                     # 无暴击
    defender:
      realm: "xueTu / qiMeng (lv 1)"
      max_hp: 3700                       # 1000 + 500*0.7 + 5*500 = 1000+350+2500 = 3850 → 估算 3700
      defense_rate: 0.05                 # 学徒 5%
    calculated_damage: "(600*0.4 + 130*1.0 + 500) * 1.0 * 1.0 * 1.0 * (1-0.05) * 1.0 = 826"
    expected_outcome: "约 4 击致死，节奏适合新手期教学战斗 ✓"

  # --- 战例 B：二流圆熟同境界对决 ---
  # 验证目标：普通伤害落在 GDD §5.2 红线 2000-8000 区间
  example_b:
    description: "二流·圆熟 主角 vs 二流·圆熟 对手"
    attacker:
      realm: "erLiu / yuanShu (lv 19)"
      internal_force: 3000
      equipment_attack: 580              # 利器武器中段（其实利器是一流装备，二流主角用利器需通过奇遇）
      skill_multiplier: 1500             # 强力技能（中段）
      cultivation_multiplier: 1.75       # 圆满
      school_counter: 1.00
      critical: 1.00
    defender:
      realm: "erLiu / yuanShu (lv 19)"
      max_hp: 7500                       # 1000 + 3000*0.7 + 6*500 + 500(装备血量) = 6600
      defense_rate: 0.15                 # 二流 15%
    calculated_damage: "(3000*0.4 + 580 + 1500) * 1.75 * 1.0 * 1.0 * 0.85 * 1.0 = 4889"
    expected_outcome: "在 2000-8000 红线内 ✓；约 2 击致死，强力技能节奏合理"

  # --- 战例 C：三流挑战二流（境界差吃亏）---
  # 验证目标：低境界打高境界吃亏明显（GDD §5.5 设计意图）
  example_c:
    description: "三流·登峰 主角 vs 二流·入门 高手（差 1 大境界）"
    attacker:
      realm: "sanLiu / dengFeng (lv 14)"
      internal_force: 2000
      equipment_attack: 280              # 像样货上段
      skill_multiplier: 1500             # 强力技能
      cultivation_multiplier: 1.30       # 中成
      school_counter: 1.00
      critical: 1.00
      realm_diff_modifier: 0.7           # 低境界打高境界（守方修正）
    defender:
      realm: "erLiu / ruMen (lv 16)"
      max_hp: 6800                       # 1000 + 2400*0.7 + 6*500 + 500 = 4180+500 ≈ 5180 → 估算
      defense_rate: 0.15                 # 二流
    calculated_damage: "(2000*0.4 + 280 + 1500) * 1.30 * 1.0 * 1.0 * 0.85 * 0.7 = 1972"
    expected_outcome: "勉强达到普通伤害下限 2000；约 4 击致死，三流挑战二流确实吃力 ✓"

  # --- 战例 D：一流大招暴击 + 流派克制 ---
  # 验证目标：大招暴击应达到"上万"（GDD §5.2）
  example_d:
    description: "一流·圆熟 主角刚猛流大招暴击 vs 一流·启蒙 阴柔流对手"
    attacker:
      realm: "yiLiu / yuanShu (lv 26)"
      internal_force: 5000
      equipment_attack: 600              # 利器武器
      skill_multiplier: 5500             # 大招（刚猛 4 阶心法上限附近）
      cultivation_multiplier: 1.75       # 圆满
      school_counter: 1.25               # 刚猛克阴柔
      critical: 2.00                     # 暴击
    defender:
      realm: "yiLiu / qiMeng (lv 22)"
      max_hp: 7860                       # 1000 + 3800*0.7 + 6*500 + 1100 = 1000+2660+3000+1100 = 7760
      defense_rate: 0.20                 # 一流
    calculated_damage: "(5000*0.4 + 600 + 5500) * 1.75 * 1.25 * 2.0 * 0.80 * 1.0 = 28525"
    expected_outcome: "破万达成（28525），符合 GDD §5.2 大招暴击'上万'目标 ✓；一击秒杀"

  # --- 战例 E：武圣 vs 武圣（终极对决）---
  # 验证目标：高境界数值不崩溃，仍在合理区间
  example_e:
    description: "武圣·登峰 vs 武圣·登峰（神物 +49 强化）"
    attacker:
      realm: "wuSheng / dengFeng (lv 49)"
      internal_force: 15000
      equipment_attack: 3920             # 神物 1750 × (1+49*0.05) = 1750*3.45 = 6037 × 1.30 共鸣 = 7848
                                          # 但平衡后我们用：1750 × 1.30 共鸣 × 1.0(已含强化) = 校验数据
      skill_multiplier: 8000             # 传说神功大招上限
      cultivation_multiplier: 3.00       # 极境
      school_counter: 1.00
      critical: 2.50                     # 顶级暴击
    defender:
      realm: "wuSheng / dengFeng (lv 49)"
      max_hp: 19500                      # 1000 + 15000*0.7 + 10*500 + 3000 = 19500（接近 20000 上限）
      defense_rate: 0.35                 # 武圣
    note: "本战例数据用于压力测试，确保武圣境界数值不崩盘"
    expected_outcome: "约 19500 / 19500 几乎一击致死，符合武圣对决'电光石火'氛围 ✓；血量未超 20000 红线 ✓"

# =============================================================================
# 文件结束
# =============================================================================
```

<a id="q085"></a>
### Q085

```sh
rg -n --with-filename --no-heading --sort path -- 'last_updated|纯文档' data/numbers.yaml
```

命中/输出行数：5；退出码：0。

```text
data/numbers.yaml:31:  # ⚠ 纯文档（2026-08-07 N1 处置）：NumbersConfig.fromYaml 只取 meta['version']
data/numbers.yaml:32:  #   （numbers_config.dart:316,323），meta 其余 key 无任何读取点。last_updated 已
data/numbers.yaml:34:  last_updated: "2026-05-10"
data/numbers.yaml:106:    skill_multiplier_added: true     # ⚠ 纯文档(审计 D7):NumbersConfig 不解析;招式倍率"作为加项"已硬编码在 damage_calculator
data/numbers.yaml:1666:# ⚠ 纯文档（2026-08-07 N1 处置）：本段 example_a..e 不进 NumbersConfig.fromYaml
```

<a id="q086"></a>
### Q086

```sh
sed -n 28,34p data/numbers.yaml
```

命中/输出行数：7；退出码：0。

```text
meta:
  version: "0.2.0"             # 与 SaveData.saveVersion 对应；major.minor.patch
  description: "Demo 阶段数值配置 · 覆盖学徒到武圣全程"
  # ⚠ 纯文档（2026-08-07 N1 处置）：NumbersConfig.fromYaml 只取 meta['version']
  #   （numbers_config.dart:316,323），meta 其余 key 无任何读取点。last_updated 已
  #   长期不随改动更新（本行值停留在 2026-05-10），当作时间戳会误导，仅存档用。
  last_updated: "2026-05-10"
```

<a id="q087"></a>
### Q087

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- skill_multiplier_added lib test tool tools
```

命中/输出行数：4；退出码：0。

```text
tools/audit/numbers_key_usage.py:336:                               "combat.damage_formula.skill_multiplier_added", "retreat.time_of_day_bonus")):
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:30:    (r"combat\.", "头注 UNUSED", "公式结构文档；布尔字段不是运行时开关，保留说明锚。", "纯文档|最终伤害|基础伤害|skill_multiplier_added", ["GDD.md", "data/numbers.yaml"], [("data/numbers.yaml", 99, 118), ("GDD.md", 319, 349)]),
```

<a id="q088"></a>
### Q088

```sh
rg -n --with-filename --no-heading --sort path -F -- skill_multiplier_added lib test tool tools
```

命中/输出行数：4；退出码：0。

```text
tools/audit/numbers_key_usage.py:336:                               "combat.damage_formula.skill_multiplier_added", "retreat.time_of_day_bonus")):
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:30:    (r"combat\.", "头注 UNUSED", "公式结构文档；布尔字段不是运行时开关，保留说明锚。", "纯文档|最终伤害|基础伤害|skill_multiplier_added", ["GDD.md", "data/numbers.yaml"], [("data/numbers.yaml", 99, 118), ("GDD.md", 319, 349)]),
```

<a id="q089"></a>
### Q089

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'combat\.damage_formula\.skill_multiplier_added|damage_formula\.skill_multiplier_added' lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_key_usage.py:336:                               "combat.damage_formula.skill_multiplier_added", "retreat.time_of_day_bonus")):
```

<a id="q090"></a>
### Q090

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- skill_multiplier_added data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:106:    skill_multiplier_added: true     # ⚠ 纯文档(审计 D7):NumbersConfig 不解析;招式倍率"作为加项"已硬编码在 damage_calculator
docs/audit/full_system_audit_2026-06-24.md:94:| D7 | `final_damage_formula`+`skill_multiplier_added` 死配置 | ✅ **注释**：纯公式结构文档,NumbersConfig 不解析,damage_calculator 恒应用全部乘子（非可关开关）,改 true→false 不生效（⚠ 注）|
```

<a id="q091"></a>
### Q091

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sskill_multiplier_added -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q092"></a>
### Q092

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sskill_multiplier_added -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q093"></a>
### Q093

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sskill_multiplier_added -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q094"></a>
### Q094

```sh
rg -n --with-filename --no-heading --sort path -- '纯文档|最终伤害|基础伤害|skill_multiplier_added' GDD.md data/numbers.yaml
```

命中/输出行数：16；退出码：0。

```text
GDD.md:268:**克制系数**：±25%（最终伤害公式中的 0.75 / 1.0 / 1.25）。
GDD.md:316:### 5.3 基础伤害公式
GDD.md:319:基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
GDD.md:341:### 5.4 最终伤害公式
GDD.md:344:最终伤害 = 基础伤害
GDD.md:814:- §6 核心公式**完全不动**:基础伤害 / 最大血量 / 出手速度 / 境界差距修正
data/numbers.yaml:23:#   GDD 字面公式：基础伤害 6340，最终 11095（破红线）
data/numbers.yaml:24:#   平衡后公式：基础伤害 2280，最终 3990（在 2000-8000 区间）✓
data/numbers.yaml:31:  # ⚠ 纯文档（2026-08-07 N1 处置）：NumbersConfig.fromYaml 只取 meta['version']
data/numbers.yaml:100:  # --- 基础伤害公式 ---
data/numbers.yaml:101:  # GDD §5.3：基础伤害 = (内力 × 0.4) + (装备攻击 × 8) + 招式倍率
data/numbers.yaml:102:  # 平衡后：    基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
data/numbers.yaml:106:    skill_multiplier_added: true     # ⚠ 纯文档(审计 D7):NumbersConfig 不解析;招式倍率"作为加项"已硬编码在 damage_calculator
data/numbers.yaml:108:  # --- 最终伤害公式（GDD §5.4）---
data/numbers.yaml:109:  # 最终伤害 = 基础伤害 × 修炼度加成 × 流派克制 × 暴击系数 × (1-防御率) × 境界差修正
data/numbers.yaml:1666:# ⚠ 纯文档（2026-08-07 N1 处置）：本段 example_a..e 不进 NumbersConfig.fromYaml
```

<a id="q095"></a>
### Q095

```sh
sed -n 99,118p data/numbers.yaml
```

命中/输出行数：20；退出码：0。

```text

  # --- 基础伤害公式 ---
  # GDD §5.3：基础伤害 = (内力 × 0.4) + (装备攻击 × 8) + 招式倍率
  # 平衡后：    基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
  damage_formula:
    internal_force_factor: 0.4       # 内力对伤害的系数（GDD 原值，未变）· 真消费(damage_calculator)
    equipment_attack_factor: 1.0     # 装备攻击系数（GDD 原写 8，平衡后调为 1.0）· 真消费(damage_calculator)
    skill_multiplier_added: true     # ⚠ 纯文档(审计 D7):NumbersConfig 不解析;招式倍率"作为加项"已硬编码在 damage_calculator

  # --- 最终伤害公式（GDD §5.4）---
  # 最终伤害 = 基础伤害 × 修炼度加成 × 流派克制 × 暴击系数 × (1-防御率) × 境界差修正
  # ⚠ 以下 apply_* flags 为纯公式结构文档（审计 D7 2026-06-24）：NumbersConfig 不解析此块，
  #   damage_calculator.dart 恒应用全部乘子（非可关闭开关）。改这些 true→false 不生效，勿误用。
  final_damage_formula:
    apply_cultivation_multiplier: true   # 应用心法修炼度（1.0~3.0）
    apply_school_counter: true           # 应用流派克制（0.75/1.0/1.25）
    apply_critical: true                 # 应用暴击（1.0 或 1.5~2.5）
    apply_defense: true                  # 应用防御率（1 - defense_rate）
    apply_realm_diff: true               # 应用境界差修正
```

<a id="q096"></a>
### Q096

```sh
sed -n 319,349p GDD.md
```

命中/输出行数：31；退出码：0。

```text
基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
```

> 注：装备攻击系数早期 v0.1 设为 8，Phase 1 平衡时为防装备轴数值膨胀调为 1.0，代码以 yaml 为准，详 numbers.yaml combat.damage_formula.equipment_attack_factor 注释。

伤害公式读取角色的**实际永久内力**；战斗中消耗的是真气，不会让后续招式因“内力见底”而掉伤害。

### 5.3.1 真气运转

- 玩家普通战斗基础开场真气 40；无心法普通敌人 20、主线 Boss 40、塔楼 Boss 60。普攻产气，强力技、绝招和合击分别耗气，溢出真气直接丢弃。
- 刚猛在命中/承伤、阴柔在施加控制/内伤/持续效果、灵巧在闪避/暴击/连击时可追加产气；同一行动每人最多触发一次。
- 心法可有界改变开场真气、气海、产气与减耗；增益不得超过气海 140、产气 1.5 倍和减耗 20% 上限。
- 多波战斗保留波次间真气，每波追加恢复 25% 气海。

招式倍率参考：

| 类型 | 倍率 |
|------|------|
| 普通攻击 | 500 |
| 强力技能 | 1,000 ~ 3,000 |
| 大招 | 5,000+ |

### 5.4 最终伤害公式

```
最终伤害 = 基础伤害
        × 心法修炼度加成 (1.0 ~ 3.0)
        × 流派克制 (0.75 / 1.0 / 1.25)
        × 暴击系数 (1.0 / 1.5 ~ 2.5)
        × (1 - 目标防御率)
        × 境界差距修正
```

<a id="q097"></a>
### Q097

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- apply_cultivation_multiplier lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q098"></a>
### Q098

```sh
rg -n --with-filename --no-heading --sort path -F -- apply_cultivation_multiplier lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q099"></a>
### Q099

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'combat\.final_damage_formula\.apply_cultivation_multiplier|final_damage_formula\.apply_cultivation_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q100"></a>
### Q100

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- apply_cultivation_multiplier data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:113:    apply_cultivation_multiplier: true   # 应用心法修炼度（1.0~3.0）
```

<a id="q101"></a>
### Q101

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_cultivation_multiplier -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q102"></a>
### Q102

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_cultivation_multiplier -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q103"></a>
### Q103

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sapply_cultivation_multiplier -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q104"></a>
### Q104

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- apply_school_counter lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q105"></a>
### Q105

```sh
rg -n --with-filename --no-heading --sort path -F -- apply_school_counter lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q106"></a>
### Q106

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'combat\.final_damage_formula\.apply_school_counter|final_damage_formula\.apply_school_counter' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q107"></a>
### Q107

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- apply_school_counter data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:114:    apply_school_counter: true           # 应用流派克制（0.75/1.0/1.25）
```

<a id="q108"></a>
### Q108

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_school_counter -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q109"></a>
### Q109

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_school_counter -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q110"></a>
### Q110

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sapply_school_counter -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q111"></a>
### Q111

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- apply_critical lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q112"></a>
### Q112

```sh
rg -n --with-filename --no-heading --sort path -F -- apply_critical lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q113"></a>
### Q113

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'combat\.final_damage_formula\.apply_critical|final_damage_formula\.apply_critical' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q114"></a>
### Q114

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- apply_critical data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:115:    apply_critical: true                 # 应用暴击（1.0 或 1.5~2.5）
```

<a id="q115"></a>
### Q115

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_critical -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q116"></a>
### Q116

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_critical -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q117"></a>
### Q117

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sapply_critical -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q118"></a>
### Q118

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- apply_defense lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q119"></a>
### Q119

```sh
rg -n --with-filename --no-heading --sort path -F -- apply_defense lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q120"></a>
### Q120

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'combat\.final_damage_formula\.apply_defense|final_damage_formula\.apply_defense' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q121"></a>
### Q121

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- apply_defense data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:116:    apply_defense: true                  # 应用防御率（1 - defense_rate）
```

<a id="q122"></a>
### Q122

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_defense -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q123"></a>
### Q123

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_defense -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q124"></a>
### Q124

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sapply_defense -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q125"></a>
### Q125

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- apply_realm_diff lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q126"></a>
### Q126

```sh
rg -n --with-filename --no-heading --sort path -F -- apply_realm_diff lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q127"></a>
### Q127

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'combat\.final_damage_formula\.apply_realm_diff|final_damage_formula\.apply_realm_diff' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q128"></a>
### Q128

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- apply_realm_diff data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:117:    apply_realm_diff: true               # 应用境界差修正
```

<a id="q129"></a>
### Q129

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_realm_diff -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q130"></a>
### Q130

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sapply_realm_diff -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q131"></a>
### Q131

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sapply_realm_diff -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q132"></a>
### Q132

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- tier_name lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q133"></a>
### Q133

```sh
rg -n --with-filename --no-heading --sort path -F -- tier_name lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q134"></a>
### Q134

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.tier_name|tiers\.tier_name' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q135"></a>
### Q135

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- tier_name data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：15；退出码：0。

```text
data/numbers.yaml:681:      tier_name: "寻常货"
data/numbers.yaml:688:      tier_name: "像样货"
data/numbers.yaml:695:      tier_name: "好家伙"
data/numbers.yaml:702:      tier_name: "利器"
data/numbers.yaml:709:      tier_name: "重器"
data/numbers.yaml:718:      tier_name: "宝物"
data/numbers.yaml:727:      tier_name: "神物"
data/numbers.yaml:898:      tier_name: "入门功"
data/numbers.yaml:904:      tier_name: "常练功"
data/numbers.yaml:910:      tier_name: "名家功"
data/numbers.yaml:916:      tier_name: "门派绝学"
data/numbers.yaml:922:      tier_name: "江湖秘传"
data/numbers.yaml:928:      tier_name: "失传神功"
data/numbers.yaml:934:      tier_name: "传说神功"
docs/audit/night_b_governance_recovery_2026-09-17.md:47:- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
```

<a id="q136"></a>
### Q136

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_name -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q137"></a>
### Q137

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_name -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q138"></a>
### Q138

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stier_name -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q139"></a>
### Q139

```sh
rg -n --with-filename --no-heading --sort path -- 'equipment.tiers|寻常货|像样货|利器|神物' data/equipment.yaml GDD.md
```

命中/输出行数：27；退出码：0。

```text
data/equipment.yaml:7:# 数值范围严格对齐 numbers.yaml `equipment.tiers` 段（每件 def 取 tier 全范围,
data/equipment.yaml:14:#   - 寻常货/像样货/好家伙 → mainline_ch1/2/3 + tower_5/15
data/equipment.yaml:15:#   - 利器/重器           → tower_25 + yiLiu_quest / jueDing_unlock
data/equipment.yaml:17:#   - 神物                → wuSheng_unlock（2026-07-28 Ch19 起**真投放**:发布上限抬至 45=武圣·熟练,
data/equipment.yaml:18:#                            三系锁死随之开放神物,首批 4 件挂 stage_19_01/02/04/05 dropTable。
data/equipment.yaml:24:  # === 第 1 阶 寻常货 · 学徒境界开放 ===
data/equipment.yaml:109:  # === 第 2 阶 像样货 · 三流境界开放 ===
data/equipment.yaml:280:  # === 第 4 阶 利器 · 一流境界开放 · Demo 主线最高级装备 ===
data/equipment.yaml:546:  # === 第 7 阶 神物 · 武圣境界开放（Demo 顶阶占位） ===
data/equipment.yaml:641:  # --- 寻常货扩充 ---
data/equipment.yaml:739:  # --- 像样货扩充 ---
data/equipment.yaml:935:  # --- 利器扩充 ---
data/equipment.yaml:1241:  # --- 神物扩充 ---
GDD.md:162:| 1 | 寻常货 | 铁剑、麻布袍 |
GDD.md:163:| 2 | 像样货 | 精铁刀、皮甲 |
GDD.md:165:| 4 | 利器 | 名匠铸刃 |
GDD.md:168:| 7 | 神物 | 传说中的兵器 |
GDD.md:186:| 学徒 | 寻常货 | 入门功 |
GDD.md:187:| 三流 | 像样货 | 常练功 |
GDD.md:189:| 一流 | 利器 | 门派绝学 |
GDD.md:192:| 武圣 | 神物 | 传说神功 |
GDD.md:312:- **软可读区间（极值满 build 实战可见值 · 保读得懂）**：普通伤害典型 build 落 2,000~8,000 设计目标；当前满强化神物极值 build（+49 ×3.45 × 共鸣 ×1.30 × 双攻击开锋 ×1.35 × 极境修炼 ×3.0）calculator 探针约 5.8 万（暴击约 8.7 万）。2026-06-14 旧 3v3 极值×周目诊断曾记录**真实普攻峰值约 13.5 万、大招约 21 万**（含满熟练 + 地形/阵型/恩怨 APM 末端乘 + 飞升 +1 阶差距），该诊断已随旧 3v3 于 2026-08-22 删除；13.5–21 万仅是**历史已退役测量记录，不是当前可重跑守卫**。核心是战力数字保持玩家一眼能读懂、唯一硬线 = 不进百万级膨胀（历史诊断后用户于 2026-06-14 将软线从「不进十万」放宽，6 位数仍可读）。当前守卫分两类：`test/balance/full_build_damage_redline_test.dart` 覆盖满 build `DamageCalculator` 极值探针；`test/tools/phase0a_full_content_balance_diagnostic_test.dart` 用 Ch1 祖师起手画像覆盖 3 流派 × 154 条生产主线/塔内容 × 5 熟练阶段 = 2310 次真实 Phase 0A headless reducer，并逐次断言单次 resolved damage 不进百万。后者不覆盖满 build、飞升阶差、周目或地形/阵型/恩怨极值，因此 Phase 0A 满 build 真实路径极值探针仍须另立后续任务，不能用起手画像伪替。**终局极值 build 一回合秒杀普通终局内容、周目进化对满配无效**仍属既有爽感意图。 **例外·终局机制型 Boss（2026-07-03 局部收口）**：配「脆弱窗口」承伤乘子（vulnerability 承伤 [0.05,1.0]）或「护法结界」减伤（ward 0.15）的终局机制型 Boss（爬塔 floor25/30 等），**有意让满配也不能纯 DPS 秒杀**——窗口外承伤大幅减免（floor30 复合 ward×vuln≈0.03），玩家须抓脆弱窗口（敌蓄招／破招踉跄／血阈相位开窗）集中输出。此为**减伤方向**的机制门槛，只压低有效伤害、不膨胀伤害数字，**不与「伤害不进百万」硬线冲突**；承伤乘子 schema 有界 [0.05,1.0]、非属性 buff（守本红线）。「满配秒杀爽感」仍适用普通终局内容（含周目膨胀），机制型 Boss 是刻意引入机制层的**局部**例外。**批次3 心魔追加（2026-07-04，2026-07-08 调优）**：心魔高层关（inner_demon 05/06/07）镜像同配脆弱窗口（承伤乘子 05=0.16/06=0.16/07=0.14，运劲蓄力开窗），机制镜像攻击乘 0.75；心魔终关 07 另配限时生存胜负条件（survive 20 tick 或击败镜像任一即胜，胜负与纯 DPS 脱钩）。均属**减伤方向/新胜负条件**，不膨胀伤害数字、不触「不进百万」硬线，承伤乘子 schema 同守 [0.05,1.0] 有界、非属性 buff。
GDD.md:581:| 19 | 旧路照人 | 武圣 | 黑石守镜人（黑石戈壁·守另半面镜几十年） | **回望弧开篇**·掉头东返、旧路重走·两半铜镜合一(兑现 Ch16 守镜人所立条件 + Ch18 霸主亲口相赠)·一镜双照真解**新写**(tier7 首门 drop 招)·接关人章中 Boss 复出(反向对称:由「够不够格进去」变「够不够格出来」)·**主线首次周目加压**(cycleVulnerability)·神物首批 4 件投放·发布上限抬至武圣熟练 45(**cross-tier**·releaseTier zongShi→wuSheng) |
GDD.md:582:| 20 | 东入阳关 | 武圣 | 守关老将（阳关关门·几十年只添不销的关册） | **回望弧第二拍**·东归入关、关册销账(留半行=章眼)·孤城开真解**新写**(与 Ch15 孤城闭成对·canon 自生长)·送关旧部章中 Boss 复出(送三十年头一回接)·章中 Boss 主线首带 vulnerability(复合化台阶)·神物第二批 4 件·发布上限抬至武圣圆熟 47(within-tier) |
GDD.md:583:| 21 | 绝顶交程 | 武圣 | 循符少年（无名绝顶·候峰翁旧位） | **主线终章**·东归回山、绝顶交程(交符=章眼)·山外无山真解**新写**(与 Ch13 一览众山成对·canon 自生长)·末 Boss 换胜负轴 **surviveTicks 主线首用**(并补该条件的顶栏条件条与结算文案——此前零玩家可见面)·神物第三批 3 件**11 件投放收口清零**·末 Boss school 转 lingQiao 打破连续四关 yinRou·发布上限抬至武圣登峰 **49 封顶**(within-tier·飞升条件③ 首次可达) |
GDD.md:589:> Ch4～6 原始内容制作时曾按一流至武圣标注叙事强度；2026-07-14 起，当前有效玩法数值统一重排到学徒 / 三流，旧高阶标注仅作历史创作记录，不再代表 `data/stages.yaml` 的需求境界。高阶数值空间留给未来副本与其他玩法。**2026-07-17 Ch7「北望」起主线正式进入二流段**（真传位新弧·继位大弟子·发布上限二流·熟练 = 绝对层 17；千钧坠岳真解 / 烛影摇红残页在 Ch7 章末 Boss 挂载）；**2026-07-18 Ch8「出塞」续二流段第 2 章**（追灰衣人·铜符北上；末 Boss 灰衣人本人逼出真正本命,新写独立真解「灰袖回风」chargeSkill=dropSkillManual 双用挂载 stage_08_05,不进 wave_b 配平池）；**2026-07-20 Ch9「碛北」续二流段第 3 章**（循符入无路碛北·末 Boss「那一位」铜符本主·沉默出手即决·独立真解「沉沙一诀」chargeSkill=dropSkillManual 双用挂载 stage_09_05·边塞三章弧收束、不抬发布上限）；**2026-07-20 Ch10「中州」一流段首章**（循符走完边塞、回身入中原江湖深处；末 Boss 守拙翁守道名宿·独立真解「止水诀」chargeSkill=dropSkillManual 双用挂载 stage_10_05·「循路→开路」一流拐点顿悟·发布上限抬至一流·熟练 = 绝对层 24；一流门派绝学敌招 + 利器装备复用既有储备，零新增）；**2026-07-21 Ch11「名门之虚」续一流段第 2 章**（踏中州名门·见名门之虚；末 Boss 鎏金公中州名宿·名震中州却虚有其表·独立真解「鎏金诀」chargeSkill=dropSkillManual 双用挂载 stage_11_05·「名≠本事」名门虚实之辨·求「实」Ch12 hook·发布上限抬至一流·圆熟 = 绝对层 26；一流门派绝学敌招 + 利器装备复用既有储备，零新增）；**2026-07-21 Ch12「名下之实」续一流段第 3 章·一流三章收官**（寻中州之实、见名下之实；末 Boss 无名客荒村野店无名真高手·绵里藏针实藏于内·独立真解「绵里藏针」chargeSkill=dropSkillManual 双用挂载 stage_12_05·「名≠本事·实至名归」收束守拙翁托付·承绝顶段 hook·发布上限抬至一流·登峰 = 绝对层 28；一流门派绝学敌招 + 利器装备复用既有储备，零新增）；**2026-07-22 Ch13「山外青山」绝顶段首章**（起脚往上、出中州向高处；末 Boss 候峰翁绝顶之上等人数十年的老者·守拙翁镜像倒置·独立真解「一览众山」chargeSkill=dropSkillManual 双用挂载 stage_13_05·「从看江湖到成为江湖」传承弧·主角从接符人变留符人·发布上限抬至绝顶·熟练 = 绝对层 31·cross-tier·releaseTier yiLiu→jueDing；绝顶江湖秘传敌招 + 重器装备复用既有储备，唯一新增 = 末 Boss 真解；shi_dang/yang_guan 补标 mount_deferred，jing_hong 挂 13_05 章末残页，ma_ta 挂塔 25 层，jin_gang/guan_shan 塔 20/15 层收编）；**2026-07-23 Ch14「山外来客」绝顶段第二章**（西凉马战宗师循名叩山、借绝顶一战；末 Boss 马战宗师·独立真解「十荡十决」收编挂载 stage_14_05（删 mount_deferred·[balance] mult 3600→4800 对齐绝顶真解档）·「成为江湖」第一课 = 接住循名而来的拳头·临行一句埋宗师段「阳关无故人」西凉霸主伏笔·发布上限抬至绝顶·圆熟 = 绝对层 33·within-tier·releaseTier 仍 jueDing；江湖秘传敌招（ult/fang 档）+ 重器装备复用既有储备，零新增招）；**2026-07-24 Ch15「关山一程」绝顶段收官章**（下山西行头一程、Ch4「西出阳关」旧路新走回旋，五程对称 Ch14 客上山五程；末 Boss 守关老将·镇阳关数十年的中原老将「借关一战」对称 Ch14 借山一战·独立真解「孤城闭」新写 chargeSkill=dropSkillManual 双用挂载 stage_15_05·佛门 fang 系明王拳三件套 stage_15_03 主线首用·绝顶三章真解三系各一（lingQiao/gangMeng/yinRou）收束·发布上限抬至绝顶·登峰 = 绝对层 35·within-tier·releaseTier 仍 jueDing·末 Boss 59500 守 60000 硬线头寸收官用尽、宗师段难度转机制层留议；江湖秘传敌招（ult/fang 档）+ 重器装备复用既有储备，唯一新增 = 末 Boss 真解）；**2026-07-24 Ch16「凉州词」宗师段首章**（出阳关入西凉头一程、西凉故人弧「旧路更远处」开篇；末 Boss 接关人·西凉门户关城霸主座下留关数十年·独立真解「铁马冰河」新写 chargeSkill=dropSkillManual 双用挂载 stage_16_05·黑石铜镜见镜不取 hook Ch18 霸主亲手相赠·发布上限抬至宗师·熟练 = 绝对层 38·cross-tier·releaseTier jueDing→zongShi；失传神功心法招三件套敌招换档（tier6 池已有、零新增敌招）+ 宝物装备复用既有储备，唯一新增 = 末 Boss 真解；月落无声挂 16_05 章末残页，夜雨十年灯补 mount_deferred 归 Ch17，feng_juan/yang_guan 仍 deferred 至 Ch17/18；难度走 cross-tier 层差+失传神功档，机制型 Boss 按段级拍板 6 留 Ch17/18 渐进）；**2026-07-26 Ch17「沙海纵深」宗师段第 2 章**（承 Ch16 章尾「下一程,沙海纵深」硬叙事锚;主题＝沙海里剑术不管用、天地才管用,兑现 Ch4 李寒「剑到了一处地方,就要听那处地方的风」;末 Boss 沙海领路人·霸主座下引路人·独立真解「平沙落雁」新写 chargeSkill=dropSkillManual 双用挂载 stage_17_05·风卷流沙删 mount_deferred 收编为 17_04 章中 Boss 掉落（[balance] mult 3200→4800·tier4 保收集向定位）·夜雨十年灯删 mount_deferred 挂 17_05 章末残页·**机制层首入主线**：17_05 单窗口 `vulnerability.outOfWindowDamageMult=0.20`（比照塔 floor30 同值宽松位,窗口外承伤 20%）+ 17_04 只配 chargeCounter 相位作破招前置教学,两级递进「先学打断蓄招→再学只有窗口能打」,cycleVulnerability 本章不配·发布上限抬至宗师·圆熟 = 绝对层 40·**within-tier**·releaseTier 仍 zongShi；失传神功 fang 防御变体敌招首次主线接线（17_03 阴柔 / 17_04 灵巧,tier6 池已有、零新增敌招）+ 宝物装备复用既有储备,唯一新增 = 末 Boss 真解；仅 yang_guan 仍 deferred 至 Ch18）；宗师以上境界/装备/心法仍留未来内容。
GDD.md:710:- **第一次的爽点要留足**：暴击 / 突破 / 拿到利器 / 心法升级。
```

<a id="q140"></a>
### Q140

```sh
sed -n 1,10p data/equipment.yaml
```

命中/输出行数：10；退出码：0。

```text
# =============================================================================
# equipment.yaml · 装备 fixture（P2.1 Batch 1 扩 80 件）
# =============================================================================
# 共 80 件：7 阶 × 11 件（weapon 5 + armor 3 + accessory 3）+ 3 跨阶特殊。
# P2.1 Batch 1(2026-05-28)扩 +45(双持/暗器/轻甲/重甲/玉佩/药囊 + 3 特殊)。
# 原 35 件：7 阶 × 5 件（weapon 3 三流派各 1 + armor 1 + accessory 1）。
# 数值范围严格对齐 numbers.yaml `equipment.tiers` 段（每件 def 取 tier 全范围,
# EquipmentFactory.fromDef 实例化时再 roll 个体差异）。
#
# 字段命名遵循 schema data_schema.md §5.1（camelCase），
```

<a id="q141"></a>
### Q141

```sh
sed -n 153,168p GDD.md
```

命中/输出行数：16；退出码：0。

```text

**UI 显示风格**：`二流·入门`、`一流·圆熟`、`宗师·化境`。

**命名约定**：境界 7 层（启蒙→登峰）描述"角色整体武学水平"；心法修炼度 9 层（初窥→极境）描述"单本心法精熟程度"。两套词汇严格不重叠，避免玩家混淆。

### 3.2 装备品阶（7 阶）

| 阶 | 名称 | 风格示例 |
|----|------|----------|
| 1 | 寻常货 | 铁剑、麻布袍 |
| 2 | 像样货 | 精铁刀、皮甲 |
| 3 | 好家伙 | 雁翎刀、锁子甲 |
| 4 | 利器 | 名匠铸刃 |
| 5 | 重器 | 古战场遗器 |
| 6 | 宝物 | 失传名兵 |
| 7 | 神物 | 传说中的兵器 |
```

<a id="q142"></a>
### Q142

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- attack_min lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
test/features/equipment/application/equipment_factory_test.dart:121:  // 3. armor slot：attack_min=attack_max=0 时返回恒 0
```

<a id="q143"></a>
### Q143

```sh
rg -n --with-filename --no-heading --sort path -F -- attack_min lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
test/features/equipment/application/equipment_factory_test.dart:121:  // 3. armor slot：attack_min=attack_max=0 时返回恒 0
```

<a id="q144"></a>
### Q144

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.weapon\.attack_min|tiers\.weapon\.attack_min|weapon\.attack_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q145"></a>
### Q145

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- attack_min data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：22；退出码：0。

```text
data/numbers.yaml:682:      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}
data/numbers.yaml:683:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}
data/numbers.yaml:684:      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}
data/numbers.yaml:689:      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}
data/numbers.yaml:690:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}
data/numbers.yaml:691:      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:696:      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}
data/numbers.yaml:697:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:698:      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}
data/numbers.yaml:703:      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}
data/numbers.yaml:704:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}
data/numbers.yaml:705:      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}
data/numbers.yaml:710:      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}
data/numbers.yaml:711:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}
data/numbers.yaml:712:      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}
data/numbers.yaml:719:      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}
data/numbers.yaml:720:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1400, hp_max: 2000, speed_min: 25, speed_max: 50}
data/numbers.yaml:721:      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 750,  hp_max: 1100, speed_min: 45, speed_max: 70}
data/numbers.yaml:728:      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 150, hp_max: 350, speed_min: 65, speed_max: 100}
data/numbers.yaml:729:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1750, hp_max: 2300, speed_min: 40, speed_max: 70}
data/numbers.yaml:730:      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1000, hp_max: 1400, speed_min: 65, speed_max: 95}
docs/audit/night_b_governance_recovery_2026-09-17.md:47:- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
```

<a id="q146"></a>
### Q146

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sattack_min -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q147"></a>
### Q147

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sattack_min -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q148"></a>
### Q148

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sattack_min -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q149"></a>
### Q149

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- hp_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q150"></a>
### Q150

```sh
rg -n --with-filename --no-heading --sort path -F -- hp_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q151"></a>
### Q151

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.weapon\.hp_min|tiers\.weapon\.hp_min|weapon\.hp_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q152"></a>
### Q152

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- hp_min data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：26；退出码：0。

```text
data/numbers.yaml:682:      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}
data/numbers.yaml:683:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}
data/numbers.yaml:684:      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}
data/numbers.yaml:689:      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}
data/numbers.yaml:690:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}
data/numbers.yaml:691:      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:696:      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}
data/numbers.yaml:697:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:698:      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}
data/numbers.yaml:703:      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}
data/numbers.yaml:704:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}
data/numbers.yaml:705:      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}
data/numbers.yaml:710:      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}
data/numbers.yaml:711:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}
data/numbers.yaml:712:      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}
data/numbers.yaml:719:      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}
data/numbers.yaml:720:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1400, hp_max: 2000, speed_min: 25, speed_max: 50}
data/numbers.yaml:721:      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 750,  hp_max: 1100, speed_min: 45, speed_max: 70}
data/numbers.yaml:728:      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 150, hp_max: 350, speed_min: 65, speed_max: 100}
data/numbers.yaml:729:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1750, hp_max: 2300, speed_min: 40, speed_max: 70}
data/numbers.yaml:730:      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1000, hp_max: 1400, speed_min: 65, speed_max: 95}
docs/handoff/p0_38_maxhp_rebalance_closeout_2026-05-17.md:81:3. `equipment.tiers.baoWu.armor.hp_min/max` 1600/2300 → 1400/2000
docs/handoff/p0_38_maxhp_rebalance_closeout_2026-05-17.md:82:4. `equipment.tiers.baoWu.accessory.hp_min/max` 850/1300 → 750/1100
docs/handoff/p0_38_maxhp_rebalance_closeout_2026-05-17.md:83:5. `equipment.tiers.shenWu.weapon.hp_min/max` 200/500 → 150/350
docs/handoff/p0_38_maxhp_rebalance_closeout_2026-05-17.md:84:6. `equipment.tiers.shenWu.armor.hp_min/max` 2300/3000 → 1750/2300
docs/handoff/p0_38_maxhp_rebalance_closeout_2026-05-17.md:85:7. `equipment.tiers.shenWu.accessory.hp_min/max` 1300/1800 → 1000/1400
```

<a id="q153"></a>
### Q153

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Shp_min -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q154"></a>
### Q154

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Shp_min -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q155"></a>
### Q155

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Shp_min -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q156"></a>
### Q156

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- speed_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q157"></a>
### Q157

```sh
rg -n --with-filename --no-heading --sort path -F -- speed_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q158"></a>
### Q158

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.weapon\.speed_max|tiers\.weapon\.speed_max|weapon\.speed_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q159"></a>
### Q159

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- speed_max data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：21；退出码：0。

```text
data/numbers.yaml:682:      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}
data/numbers.yaml:683:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}
data/numbers.yaml:684:      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}
data/numbers.yaml:689:      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}
data/numbers.yaml:690:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}
data/numbers.yaml:691:      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:696:      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}
data/numbers.yaml:697:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:698:      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}
data/numbers.yaml:703:      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}
data/numbers.yaml:704:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}
data/numbers.yaml:705:      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}
data/numbers.yaml:710:      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}
data/numbers.yaml:711:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}
data/numbers.yaml:712:      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}
data/numbers.yaml:719:      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}
data/numbers.yaml:720:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1400, hp_max: 2000, speed_min: 25, speed_max: 50}
data/numbers.yaml:721:      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 750,  hp_max: 1100, speed_min: 45, speed_max: 70}
data/numbers.yaml:728:      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 150, hp_max: 350, speed_min: 65, speed_max: 100}
data/numbers.yaml:729:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1750, hp_max: 2300, speed_min: 40, speed_max: 70}
data/numbers.yaml:730:      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1000, hp_max: 1400, speed_min: 65, speed_max: 95}
```

<a id="q160"></a>
### Q160

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sspeed_max -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q161"></a>
### Q161

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sspeed_max -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q162"></a>
### Q162

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sspeed_max -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q163"></a>
### Q163

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- speed_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q164"></a>
### Q164

```sh
rg -n --with-filename --no-heading --sort path -F -- speed_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q165"></a>
### Q165

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.weapon\.speed_min|tiers\.weapon\.speed_min|weapon\.speed_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q166"></a>
### Q166

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- speed_min data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：22；退出码：0。

```text
data/numbers.yaml:682:      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}
data/numbers.yaml:683:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}
data/numbers.yaml:684:      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}
data/numbers.yaml:689:      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}
data/numbers.yaml:690:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}
data/numbers.yaml:691:      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:696:      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}
data/numbers.yaml:697:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:698:      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}
data/numbers.yaml:703:      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}
data/numbers.yaml:704:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}
data/numbers.yaml:705:      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}
data/numbers.yaml:710:      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}
data/numbers.yaml:711:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}
data/numbers.yaml:712:      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}
data/numbers.yaml:719:      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}
data/numbers.yaml:720:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1400, hp_max: 2000, speed_min: 25, speed_max: 50}
data/numbers.yaml:721:      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 750,  hp_max: 1100, speed_min: 45, speed_max: 70}
data/numbers.yaml:728:      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 150, hp_max: 350, speed_min: 65, speed_max: 100}
data/numbers.yaml:729:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1750, hp_max: 2300, speed_min: 40, speed_max: 70}
data/numbers.yaml:730:      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1000, hp_max: 1400, speed_min: 65, speed_max: 95}
docs/audit/night_b_governance_recovery_2026-09-17.md:47:- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
```

<a id="q167"></a>
### Q167

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sspeed_min -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q168"></a>
### Q168

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sspeed_min -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q169"></a>
### Q169

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sspeed_min -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q170"></a>
### Q170

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.armor\.attack_min|tiers\.armor\.attack_min|armor\.attack_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q171"></a>
### Q171

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.armor\.hp_min|tiers\.armor\.hp_min|armor\.hp_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q172"></a>
### Q172

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.armor\.speed_max|tiers\.armor\.speed_max|armor\.speed_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q173"></a>
### Q173

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.armor\.speed_min|tiers\.armor\.speed_min|armor\.speed_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q174"></a>
### Q174

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.accessory\.attack_min|tiers\.accessory\.attack_min|accessory\.attack_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q175"></a>
### Q175

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.accessory\.hp_min|tiers\.accessory\.hp_min|accessory\.hp_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q176"></a>
### Q176

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.accessory\.speed_max|tiers\.accessory\.speed_max|accessory\.speed_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q177"></a>
### Q177

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.accessory\.speed_min|tiers\.accessory\.speed_min|accessory\.speed_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q178"></a>
### Q178

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- max_level_formula lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:32:    (r"equipment\.enhancement\.max_level_formula", "保留（有合同）", "GDD 强化上限合同仍存在；生产用角色层数实现，该字符串未被读取。", "强化等级上限", ["GDD.md"], [("GDD.md", 429, 429)]),
```

<a id="q179"></a>
### Q179

```sh
rg -n --with-filename --no-heading --sort path -F -- max_level_formula lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:32:    (r"equipment\.enhancement\.max_level_formula", "保留（有合同）", "GDD 强化上限合同仍存在；生产用角色层数实现，该字符串未被读取。", "强化等级上限", ["GDD.md"], [("GDD.md", 429, 429)]),
```

<a id="q180"></a>
### Q180

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.enhancement\.max_level_formula|enhancement\.max_level_formula' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q181"></a>
### Q181

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- max_level_formula data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:735:    max_level_formula: "absolute_level"  # 强化上限 = 持有者境界总层数（最高 +49）
```

<a id="q182"></a>
### Q182

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Smax_level_formula -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q183"></a>
### Q183

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Smax_level_formula -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q184"></a>
### Q184

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Smax_level_formula -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q185"></a>
### Q185

```sh
rg -n --with-filename --no-heading --sort path -- '强化等级上限' GDD.md
```

命中/输出行数：1；退出码：0。

```text
GDD.md:429:**强化等级上限** = 角色当前境界总层数（最高 +49）。
```

<a id="q186"></a>
### Q186

```sh
sed -n 429,429p GDD.md
```

命中/输出行数：1；退出码：0。

```text
**强化等级上限** = 角色当前境界总层数（最高 +49）。
```

<a id="q187"></a>
### Q187

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- success_formula lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q188"></a>
### Q188

```sh
rg -n --with-filename --no-heading --sort path -F -- success_formula lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q189"></a>
### Q189

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.enhancement\.success_curve\.success_formula|enhancement\.success_curve\.success_formula|success_curve\.success_formula' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q190"></a>
### Q190

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- success_formula data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:757:        success_formula: "max(0.30, 0.50 - 0.02 * (level - 19))"
docs/dispatch/reports/2026-08-07_Q2_config_bypass.md:181:- **合理硬编码 / 测试兜底**:`EncounterService.fortuneSensitivity=20.0`(仅旧测试 fixture,生产注入 `attributeEffects`)、injury 展示层 `?? 3/0.85/0.15`(与 yaml 同值的防御回退,真行为走 injury_service)、强化 `_fallbackFormula`(+20-49 段 yaml 以 `success_formula` 显式授权)。
```

<a id="q191"></a>
### Q191

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssuccess_formula -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q192"></a>
### Q192

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssuccess_formula -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q193"></a>
### Q193

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Ssuccess_formula -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q194"></a>
### Q194

```sh
rg -n --with-filename --no-heading --sort path -- 'success_curve|0.30|0.02' GDD.md
```

命中/输出行数：9；退出码：0。

```text
GDD.md:445:> +20~+49 段以 `numbers.yaml equipment.enhancement.success_curve` 为准；材料消耗随高段增加，心血结晶保底消耗维持高段兜底语义。
GDD.md:465:> 注（根因A 2026-05-29）：默契边界 500→300，并让闭关挂机折算 battleCount
GDD.md:517:**Demo 内容量**：30-50 招武功 + 20-30 个领悟触发条件。
GDD.md:605:- 断魂帖里程碑：第 16/33/49 层首通各一张（2026-08-04 拍板保持 3 张、约三等分、经济总量不变；旧位 10/20/30 已领记录永久保留）。
GDD.md:626:| 爬塔 Boss | 6（3 小 3 大，分别在第 5/15/25 层和第 10/20/30 层） |
GDD.md:647:> **奇遇三通道独立计算**（v1.2 拆分）：原 v1.1「奇遇事件 20-30 + 节日 6」混算
GDD.md:760:> **v1.18 导语更新**：本节原为 Demo 期「不实现、留接口」清单；1.0 内容周期已把多数系统实装（各行内有 ✅ 实装注）。**已实装**：心魔（§12.1）/ 帮派门派（§12.2）/ 江湖恩怨+声望（§12.1/§12.2，P1.2）/ 轻功对决+群战（§12.3）/ 第二条主线 Ch4-6（§12.4）/ 节日 encounter 内容层 / 门派事件（P3.4 比武·危机·任务，`numbers.yaml sect_event` + `lib/features/sect/`，2026-07-02 审查订正：原误列「不启动」）/ **桃花岛养成支柱一期+二期**（saveVer 0.30，藏卷阁 Hub，`lib/features/taohua_island/`，2026-06-27/28 合 main，2026-07-02 审查补记——此前本文档 0 记载）。**已切除 / 不启动**：PVP（不保留入口、service、UI、玩法配置;仅保旧档 schema 兼容）/ 婚姻后代 / 节日活动系统级框架 / MOD / §12.5 长期愿景——动这些前必须先回到本文档讨论。
GDD.md:798:| **武学领悟触发** | 20-30(实测 20) | **30-40** | 1.5-2× | — |
GDD.md:802:| **心法** | 20-30(实测 21) | **50** | 2.5× | 全 7 阶 × 3 流派 × ~2 心法(每阶每流派 2-3 本) |
```

<a id="q195"></a>
### Q195

```sh
sed -n 431,445p GDD.md
```

命中/输出行数：15；退出码：0。

```text
**强化数值**：每级 +5%。

**成功率与失败惩罚**：

| 等级区间 | 成功率 | 失败惩罚 |
|---------|-------|---------|
| +1 ~ +10 | 100% | — |
| +11 ~ +13 | 90% | 仅扣半数材料 |
| +14 ~ +16 | 75% | 全扣材料 |
| +17 ~ +19 | 50% | 全扣材料 |
| +20 ~ +49 | `max(30%, 50% - 2% × (level - 19))` | 全扣材料 |

**关键设计**：**不会破防降级**。最坏结果只是"白扣材料"，不会出现 +18 掉到 +12 的崩溃感。

> +20~+49 段以 `numbers.yaml equipment.enhancement.success_curve` 为准；材料消耗随高段增加，心血结晶保底消耗维持高段兜底语义。
```

<a id="q196"></a>
### Q196

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- new_owner_retention lib test tool tools
```

命中/输出行数：4；退出码：0。

```text
tools/audit/numbers_key_usage.py:338:            elif key.startswith("equipment.resonance.new_owner_retention"):
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:34:    (r"equipment\.resonance\.", "保留（有合同）", "换主清零仍是 GDD 合同，原注释明确预埋勿删；字段本身未读取。", "换主清零|new_owner_retention", ["GDD.md", "data/numbers.yaml", "docs/audit/full_audit_2026-06-16.md"], [("GDD.md", 469, 469), ("data/numbers.yaml", 832, 837)]),
```

<a id="q197"></a>
### Q197

```sh
rg -n --with-filename --no-heading --sort path -F -- new_owner_retention lib test tool tools
```

命中/输出行数：4；退出码：0。

```text
tools/audit/numbers_key_usage.py:338:            elif key.startswith("equipment.resonance.new_owner_retention"):
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:34:    (r"equipment\.resonance\.", "保留（有合同）", "换主清零仍是 GDD 合同，原注释明确预埋勿删；字段本身未读取。", "换主清零|new_owner_retention", ["GDD.md", "data/numbers.yaml", "docs/audit/full_audit_2026-06-16.md"], [("GDD.md", 469, 469), ("data/numbers.yaml", 832, 837)]),
```

<a id="q198"></a>
### Q198

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.resonance\.new_owner_retention|resonance\.new_owner_retention' lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_key_usage.py:338:            elif key.startswith("equipment.resonance.new_owner_retention"):
```

<a id="q199"></a>
### Q199

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- new_owner_retention data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:837:    new_owner_retention: 0.0         # 玩家间换主直接清零
docs/audit/full_audit_2026-06-16.md:66:- **位置**:`data/numbers.yaml:584`(`resonance.new_owner_retention: 0.0`,§6.4 玩家间换主清零)
```

<a id="q200"></a>
### Q200

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Snew_owner_retention -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q201"></a>
### Q201

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Snew_owner_retention -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q202"></a>
### Q202

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Snew_owner_retention -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q203"></a>
### Q203

```sh
rg -n --with-filename --no-heading --sort path -- '换主清零|new_owner_retention' GDD.md data/numbers.yaml docs/audit/full_audit_2026-06-16.md
```

命中/输出行数：5；退出码：0。

```text
GDD.md:469:**清零规则**：换主清零；师徒传承只清 70%（鼓励"一柄剑用一辈子"，并支持师承叙事）。
data/numbers.yaml:837:    new_owner_retention: 0.0         # 玩家间换主直接清零
docs/audit/full_audit_2026-06-16.md:12:| **Medium** | 7 | M1-M5 代码内玩家可见中文(§5.6①)· M6 心魔失败惩罚配置零消费 · M7 共鸣换主清零配置零消费 |
docs/audit/full_audit_2026-06-16.md:65:### M7 · 共鸣换主清零配置零消费(配置-行为脱节)
docs/audit/full_audit_2026-06-16.md:66:- **位置**:`data/numbers.yaml:584`(`resonance.new_owner_retention: 0.0`,§6.4 玩家间换主清零)
```

<a id="q204"></a>
### Q204

```sh
sed -n 469,469p GDD.md
```

命中/输出行数：1；退出码：0。

```text
**清零规则**：换主清零；师徒传承只清 70%（鼓励"一柄剑用一辈子"，并支持师承叙事）。
```

<a id="q205"></a>
### Q205

```sh
sed -n 832,837p data/numbers.yaml
```

命中/输出行数：6；退出码：0。

```text

    # 师承传承时的清零规则（GDD §6.4）
    inheritance_retention: 0.7       # 传给徒弟保留 70%（鼓励"一柄剑用一辈子"）
    # ⚠️ 未消费(2026-06-16 审计 M7):当前无玩家间换主路径,lib 无读取。
    # GDD §6.4 预埋字段,实装换主功能时再接;保留勿删(语义锚)。
    new_owner_retention: 0.0         # 玩家间换主直接清零
```

<a id="q206"></a>
### Q206

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'techniques\.tiers\.tier_name|tiers\.tier_name' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q207"></a>
### Q207

```sh
rg -n --with-filename --no-heading --sort path -- '入门功|常练功|传说神功' GDD.md data_schema.md
```

命中/输出行数：9；退出码：0。

```text
GDD.md:174:| 1 | 入门功 | 县衙捕快教的拳脚 |
GDD.md:175:| 2 | 常练功 | 镖局通用心法 |
GDD.md:180:| 7 | 传说神功 | 九阳、九阴这种级别 |
GDD.md:186:| 学徒 | 寻常货 | 入门功 |
GDD.md:187:| 三流 | 像样货 | 常练功 |
GDD.md:192:| 武圣 | 神物 | 传说神功 |
data_schema.md:182:  ruMenGong,        // 1 入门功
data_schema.md:183:  changLianGong,    // 2 常练功
data_schema.md:188:  chuanShuoShenGong,// 7 传说神功
```

<a id="q208"></a>
### Q208

```sh
sed -n 170,180p GDD.md
```

命中/输出行数：11；退出码：0。

```text
### 3.3 心法品阶（7 阶）

| 阶 | 名称 | 风格示例 |
|----|------|----------|
| 1 | 入门功 | 县衙捕快教的拳脚 |
| 2 | 常练功 | 镖局通用心法 |
| 3 | 名家功 | 中等门派招牌 |
| 4 | 门派绝学 | 七大派看家本领 |
| 5 | 江湖秘传 | 失传几十年的功法 |
| 6 | 失传神功 | 失传数百年的功法 |
| 7 | 传说神功 | 九阳、九阴这种级别 |
```

<a id="q209"></a>
### Q209

```sh
sed -n 180,190p data_schema.md
```

命中/输出行数：11；退出码：0。

```text
/// 心法品阶（7 阶，GDD §3.3）
enum TechniqueTier {
  ruMenGong,        // 1 入门功
  changLianGong,    // 2 常练功
  mingJiaGong,      // 3 名家功
  menPaiJueXue,     // 4 门派绝学
  jiangHuMiChuan,   // 5 江湖秘传
  shiChuanShenGong, // 6 失传神功
  chuanShuoShenGong,// 7 传说神功
}
```

<a id="q210"></a>
### Q210

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- tier_1_2_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q211"></a>
### Q211

```sh
rg -n --with-filename --no-heading --sort path -F -- tier_1_2_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q212"></a>
### Q212

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.power_skill\.tier_1_2_range|reference_multipliers\.power_skill\.tier_1_2_range|power_skill\.tier_1_2_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q213"></a>
### Q213

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- tier_1_2_range data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1065:      tier_1_2_range: [1000, 1800]   # 1-2 阶心法的强力技能
data/numbers.yaml:1070:      tier_1_2_range: [3000, 4500]   # 1-2 阶心法的大招
```

<a id="q214"></a>
### Q214

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_1_2_range -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q215"></a>
### Q215

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_1_2_range -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q216"></a>
### Q216

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stier_1_2_range -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q217"></a>
### Q217

```sh
rg -n --with-filename --no-heading --sort path -- '设计参考|指导值|全局.*8,000|max_skill_multiplier' data/numbers.yaml GDD.md CLAUDE.md
```

命中/输出行数：14；退出码：0。

```text
data/numbers.yaml:901:      max_skill_multiplier: 1500            # 该阶心法招式倍率不超过 1500（普通-中级强力技能）
data/numbers.yaml:907:      max_skill_multiplier: 2000
data/numbers.yaml:913:      max_skill_multiplier: 2500
data/numbers.yaml:919:      max_skill_multiplier: 3000
data/numbers.yaml:925:      max_skill_multiplier: 4000
data/numbers.yaml:931:      max_skill_multiplier: 5500
data/numbers.yaml:937:      max_skill_multiplier: 8000           # 含大招（如九阳神功的"龙吟九霄"）
data/numbers.yaml:1053:# GDD §5.3：招式倍率分三档。具体每招由 SkillDef 单独定义，本表是设计参考。
data/numbers.yaml:1054:# 实际配置时各阶心法的招式倍率不得超过 techniques.tiers[*].max_skill_multiplier
data/numbers.yaml:1059:  # 用于 SkillDef.powerMultiplier 字段配置时的指导值
data/numbers.yaml:1144:    # applyOutcome 用各 data/encounters.yaml outcome 写死的 attributeDelta,以下为设计参考。
CLAUDE.md:164:> v1.21 变更摘要(2026-06-24 全系统审计 C 组设计冲突拍板 · 0 改战斗数值):三项文档 vs 代码 drift 收口(用户逐项拍板)。① **C1 §6.1 商店经验丹「ETL 恒定兑换率动态标价」明文授权**:经验丹标价随祖师境界 ETL 上涨锁定兑换率恒定(防囤丹套利),明确区分「进度锚定动态标价」≠ §5.1 废除的「机缘定价」(后者按机缘属性变价制留存焦虑),材料类仍固定价;② **C3 §5.4 招式倍率改「全局 ≤8,000 单线」**:旧「强力 1,000–3,000 / 大招 5,000+」per-type 分档是 7 阶系统铺开前早期参考值,与 §5.2 锁死七阶缩放矛盾(实测 powerSkill 32/73 超 3000、ultimate 41/55 低于 5000,低阶大招＜高阶强力是曲线必然),schema 唯一真 sink 本就只全局 enforce ≤8000,改单线消除 drift;③ **C2 奇遇 events 加载层强校验实装(代码)**:仿 lore `_validatePresetLoreReferences` 在 `loadAllDefs` 末尾加 `_validateEncounterEventReferences`,缺 events 文件 / id 不自洽 / 越界 outcome_id 启动期 fail-fast,兑现 §8.1「任一端缺失直接抛错」(此前 catch 全吞静默降级);57/57 现状干净不误报。详 `docs/audit/full_system_audit_2026-06-24.md` C 组 + PROGRESS。
CLAUDE.md:296:| 招式倍率 | **全局 ≤8,000 单线**（schema 唯一真 sink = `lib/data/validation/encounter_red_lines_validator.dart` 公名 `enforceEncounterSkillRedLines`(由 `GameRepository.loadAllDefs` 消费·v1.40 迁位订正)全局 enforce ≤8000）。per-type 数值按 §5.2 七阶缩放（普攻~500 基准；强力/大招随阶 1,500→6,400，低阶大招＜高阶强力是 7 阶曲线必然），**不按招式类型钉固定区间**——旧「强力 1,000–3,000 / 大招 5,000+」per-type 分档是 7 阶系统铺开前的早期参考值，与锁死的七阶哲学矛盾，2026-06-24 拍板改全局单线消除 drift |
CLAUDE.md:343:**招式倍率**：硬约束 = **全局 ≤8,000 单线**（schema 真 sink，见 §5.4）。普攻~500 为基准，强力/大招按 §5.2 七阶随阶缩放（实测 1,500→6,400，均 ≤8000），不按类型钉固定区间。
```

<a id="q218"></a>
### Q218

```sh
sed -n 1051,1073p data/numbers.yaml
```

命中/输出行数：23；退出码：0。

```text
# 5. 招式倍率参考表
# =============================================================================
# GDD §5.3：招式倍率分三档。具体每招由 SkillDef 单独定义，本表是设计参考。
# 实际配置时各阶心法的招式倍率不得超过 techniques.tiers[*].max_skill_multiplier

skills:

  # 招式倍率参考范围（按招式类型）
  # 用于 SkillDef.powerMultiplier 字段配置时的指导值
  reference_multipliers:
    normal_attack:
      base: 500              # GDD §5.3 普通攻击固定倍率
      note: "所有普通攻击统一 500，不随心法阶提升"
    power_skill:
      tier_1_2_range: [1000, 1800]   # 1-2 阶心法的强力技能
      tier_3_4_range: [1500, 2500]   # 3-4 阶
      tier_5_6_range: [2000, 3000]   # 5-6 阶
      tier_7_range:   [2500, 3500]   # 7 阶（传说神功的强力技能）
    ultimate:
      tier_1_2_range: [3000, 4500]   # 1-2 阶心法的大招
      tier_3_4_range: [4500, 6000]
      tier_5_6_range: [5500, 7000]
      tier_7_range:   [6500, 8000]   # 7 阶大招（如九阳"龙吟九霄"）
```

<a id="q219"></a>
### Q219

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- tier_3_4_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q220"></a>
### Q220

```sh
rg -n --with-filename --no-heading --sort path -F -- tier_3_4_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q221"></a>
### Q221

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.power_skill\.tier_3_4_range|reference_multipliers\.power_skill\.tier_3_4_range|power_skill\.tier_3_4_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q222"></a>
### Q222

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- tier_3_4_range data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1066:      tier_3_4_range: [1500, 2500]   # 3-4 阶
data/numbers.yaml:1071:      tier_3_4_range: [4500, 6000]
```

<a id="q223"></a>
### Q223

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_3_4_range -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q224"></a>
### Q224

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_3_4_range -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q225"></a>
### Q225

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stier_3_4_range -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q226"></a>
### Q226

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- tier_5_6_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q227"></a>
### Q227

```sh
rg -n --with-filename --no-heading --sort path -F -- tier_5_6_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q228"></a>
### Q228

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.power_skill\.tier_5_6_range|reference_multipliers\.power_skill\.tier_5_6_range|power_skill\.tier_5_6_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q229"></a>
### Q229

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- tier_5_6_range data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1067:      tier_5_6_range: [2000, 3000]   # 5-6 阶
data/numbers.yaml:1072:      tier_5_6_range: [5500, 7000]
```

<a id="q230"></a>
### Q230

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_5_6_range -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q231"></a>
### Q231

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_5_6_range -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q232"></a>
### Q232

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stier_5_6_range -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q233"></a>
### Q233

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- tier_7_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q234"></a>
### Q234

```sh
rg -n --with-filename --no-heading --sort path -F -- tier_7_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q235"></a>
### Q235

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.power_skill\.tier_7_range|reference_multipliers\.power_skill\.tier_7_range|power_skill\.tier_7_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q236"></a>
### Q236

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- tier_7_range data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1068:      tier_7_range:   [2500, 3500]   # 7 阶（传说神功的强力技能）
data/numbers.yaml:1073:      tier_7_range:   [6500, 8000]   # 7 阶大招（如九阳"龙吟九霄"）
```

<a id="q237"></a>
### Q237

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_7_range -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q238"></a>
### Q238

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stier_7_range -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q239"></a>
### Q239

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stier_7_range -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q240"></a>
### Q240

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.ultimate\.tier_1_2_range|reference_multipliers\.ultimate\.tier_1_2_range|ultimate\.tier_1_2_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q241"></a>
### Q241

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.ultimate\.tier_3_4_range|reference_multipliers\.ultimate\.tier_3_4_range|ultimate\.tier_3_4_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q242"></a>
### Q242

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.ultimate\.tier_5_6_range|reference_multipliers\.ultimate\.tier_5_6_range|ultimate\.tier_5_6_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q243"></a>
### Q243

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'skills\.reference_multipliers\.ultimate\.tier_7_range|reference_multipliers\.ultimate\.tier_7_range|ultimate\.tier_7_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q244"></a>
### Q244

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- point_per_attribute_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q245"></a>
### Q245

```sh
rg -n --with-filename --no-heading --sort path -F -- point_per_attribute_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q246"></a>
### Q246

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.point_per_attribute_min|attributes\.point_per_attribute_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q247"></a>
### Q247

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- point_per_attribute_min data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1087:    point_per_attribute_min: 1        # 单项属性下限（GDD §4.1）
docs/spec/rarity_wiring_gap_2026-08-07.md:115:`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。
```

<a id="q248"></a>
### Q248

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Spoint_per_attribute_min -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q249"></a>
### Q249

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Spoint_per_attribute_min -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q250"></a>
### Q250

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Spoint_per_attribute_min -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q251"></a>
### Q251

```sh
rg -n --with-filename --no-heading --sort path -- '单项属性范围|rerollable|16-24|1-10|不可重 roll' CLAUDE.md GDD.md docs/spec/rarity_wiring_gap_2026-08-07.md
```

命中/输出行数：8；退出码：0。

```text
CLAUDE.md:564:| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
GDD.md:209:**生成规则**：四项总和 16-24 浮动，**单项数值范围 1-10**，按**正态分布**生成（中段最常见，两端罕见）。
GDD.md:224:**关键约束**：**不可重 roll**。出生即命运，但奇遇可微弱后天弥补（**每个角色整个生涯内**最多 +3~5 点）。
docs/spec/rarity_wiring_gap_2026-08-07.md:52:GDD §4.1(`GDD.md:224`)原文:「**不可重 roll**。出生即命运,但奇遇可微弱后天弥补
docs/spec/rarity_wiring_gap_2026-08-07.md:115:`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。
docs/spec/rarity_wiring_gap_2026-08-07.md:119:**16-24 / 1-10 的规则确实在执行,但硬编码在校验器里不读配置**:`lineage_recruit_red_lines_validator.dart:81`(单项 1-10)、`:88,230,289,366`(total 16-24,四处重复字面量)。这本身又是一条「配置声明 vs 生产硬编码」背离。
docs/spec/rarity_wiring_gap_2026-08-07.md:121:结果:GDD §4.1 的核心约束「**不可重 roll。出生即命运**」与设计理由「**拒绝洗练-保底循环,让'投胎'本身具有意义**」——**零实装**。所有角色资质都是设计师手写的静态值,创建路径上零 `Rng` 调用。
docs/spec/rarity_wiring_gap_2026-08-07.md:146:| 5 | 守卫 | 红线测试:rarity 恒等于 total 派生值(防再被写死);契约测试:新增 def 的 attributeProfile 总和必须 16-24、单项 1-10(GDD 强制规则) | 零 |
```

<a id="q252"></a>
### Q252

```sh
sed -n 564,564p CLAUDE.md
```

命中/输出行数：1；退出码：0。

```text
| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
```

<a id="q253"></a>
### Q253

```sh
sed -n 115,121p docs/spec/rarity_wiring_gap_2026-08-07.md
```

命中/输出行数：7；退出码：0。

```text
`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。

> ⚠ 勿与顶层 `attribute_effects:`(`numbers.yaml:37-48`)混淆——**那块是活的**(`numbers_config.dart:325-327` 解析,7 处消费)。两块名字近、语义完全不同。

**16-24 / 1-10 的规则确实在执行,但硬编码在校验器里不读配置**:`lineage_recruit_red_lines_validator.dart:81`(单项 1-10)、`:88,230,289,366`(total 16-24,四处重复字面量)。这本身又是一条「配置声明 vs 生产硬编码」背离。

结果:GDD §4.1 的核心约束「**不可重 roll。出生即命运**」与设计理由「**拒绝洗练-保底循环,让'投胎'本身具有意义**」——**零实装**。所有角色资质都是设计师手写的静态值,创建路径上零 `Rng` 调用。
```

<a id="q254"></a>
### Q254

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- point_per_attribute_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q255"></a>
### Q255

```sh
rg -n --with-filename --no-heading --sort path -F -- point_per_attribute_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q256"></a>
### Q256

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.point_per_attribute_max|attributes\.point_per_attribute_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q257"></a>
### Q257

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- point_per_attribute_max data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1088:    point_per_attribute_max: 10       # 单项属性上限
docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md:62:**GDD 合规**:fortuneEvent 基础 16→17 仍在 GDD §8.4 范围(15-25);红线 fortune+1 不超 §5.4 属性上限(point_per_attribute_max=10)。
```

<a id="q258"></a>
### Q258

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Spoint_per_attribute_max -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q259"></a>
### Q259

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Spoint_per_attribute_max -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q260"></a>
### Q260

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Spoint_per_attribute_max -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q261"></a>
### Q261

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- total_points_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q262"></a>
### Q262

```sh
rg -n --with-filename --no-heading --sort path -F -- total_points_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q263"></a>
### Q263

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.total_points_min|attributes\.total_points_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q264"></a>
### Q264

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- total_points_min data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1089:    total_points_min: 16              # 总点数下限
docs/spec/rarity_wiring_gap_2026-08-07.md:115:`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。
```

<a id="q265"></a>
### Q265

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stotal_points_min -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q266"></a>
### Q266

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stotal_points_min -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q267"></a>
### Q267

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stotal_points_min -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q268"></a>
### Q268

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- total_points_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q269"></a>
### Q269

```sh
rg -n --with-filename --no-heading --sort path -F -- total_points_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q270"></a>
### Q270

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.total_points_max|attributes\.total_points_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q271"></a>
### Q271

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- total_points_max data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1090:    total_points_max: 24              # 总点数上限
```

<a id="q272"></a>
### Q272

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stotal_points_max -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q273"></a>
### Q273

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stotal_points_max -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q274"></a>
### Q274

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stotal_points_max -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q275"></a>
### Q275

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- distribution_mean lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q276"></a>
### Q276

```sh
rg -n --with-filename --no-heading --sort path -F -- distribution_mean lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q277"></a>
### Q277

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.distribution_mean|attributes\.distribution_mean' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q278"></a>
### Q278

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- distribution_mean data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1092:    distribution_mean: 5.5            # 正态分布均值
docs/spec/rarity_wiring_gap_2026-08-07.md:115:`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。
```

<a id="q279"></a>
### Q279

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdistribution_mean -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q280"></a>
### Q280

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdistribution_mean -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q281"></a>
### Q281

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sdistribution_mean -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q282"></a>
### Q282

```sh
rg -n --with-filename --no-heading --sort path -- '正态|character.attributes|未来程序化|静态 profile' GDD.md CLAUDE.md data/numbers.yaml docs/spec/rarity_wiring_gap_2026-08-07.md
```

命中/输出行数：7；退出码：0。

```text
GDD.md:209:**生成规则**：四项总和 16-24 浮动，**单项数值范围 1-10**，按**正态分布**生成（中段最常见，两端罕见）。
CLAUDE.md:564:| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
data/numbers.yaml:1091:    distribution: "normal"            # 正态分布（中段最常见）
data/numbers.yaml:1092:    distribution_mean: 5.5            # 正态分布均值
data/numbers.yaml:1112:  #     （2026-08-08）：本仓角色资质为逐个手写的静态 profile，点数服务剧情人设，
data/numbers.yaml:1113:  #     **不受本概率表约束**，不要拿它去「修正」角色数值。本列仅作未来程序化生成
docs/spec/rarity_wiring_gap_2026-08-07.md:115:`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。
```

<a id="q283"></a>
### Q283

```sh
sed -n 209,213p GDD.md
```

命中/输出行数：5；退出码：0。

```text
**生成规则**：四项总和 16-24 浮动，**单项数值范围 1-10**，按**正态分布**生成（中段最常见，两端罕见）。

**换算规则**：属性基准值为 5，低于基准不施加惩罚。武学领悟概率为 `base × (1 + 悟性/20)`，其他奇遇为 `base × (1 + 机缘/20)`。招式存档只记录真实使用次数，悟性加成在战斗与界面派生，不改旧档数值或存档结构。

**6 档稀有度**：
```

<a id="q284"></a>
### Q284

```sh
sed -n 1111,1114p data/numbers.yaml
```

命中/输出行数：4；退出码：0。

```text
  #   ❗ probability 列（15/35/25/18/5/2）**无运行时消费者，且这是拍板结果不是欠账**
  #     （2026-08-08）：本仓角色资质为逐个手写的静态 profile，点数服务剧情人设，
  #     **不受本概率表约束**，不要拿它去「修正」角色数值。本列仅作未来程序化生成
  #     时的分布指引保留。
```

<a id="q285"></a>
### Q285

```sh
sed -n 113,121p docs/spec/rarity_wiring_gap_2026-08-07.md
```

命中/输出行数：9；退出码：0。

```text
### 补2 · 生成端全死,GDD 的「投胎」从未兑现

`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。

> ⚠ 勿与顶层 `attribute_effects:`(`numbers.yaml:37-48`)混淆——**那块是活的**(`numbers_config.dart:325-327` 解析,7 处消费)。两块名字近、语义完全不同。

**16-24 / 1-10 的规则确实在执行,但硬编码在校验器里不读配置**:`lineage_recruit_red_lines_validator.dart:81`(单项 1-10)、`:88,230,289,366`(total 16-24,四处重复字面量)。这本身又是一条「配置声明 vs 生产硬编码」背离。

结果:GDD §4.1 的核心约束「**不可重 roll。出生即命运**」与设计理由「**拒绝洗练-保底循环,让'投胎'本身具有意义**」——**零实装**。所有角色资质都是设计师手写的静态值,创建路径上零 `Rng` 调用。
```

<a id="q286"></a>
### Q286

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- distribution_stddev lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q287"></a>
### Q287

```sh
rg -n --with-filename --no-heading --sort path -F -- distribution_stddev lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q288"></a>
### Q288

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.distribution_stddev|attributes\.distribution_stddev' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q289"></a>
### Q289

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- distribution_stddev data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1093:    distribution_stddev: 1.5          # 标准差
```

<a id="q290"></a>
### Q290

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdistribution_stddev -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q291"></a>
### Q291

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdistribution_stddev -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q292"></a>
### Q292

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sdistribution_stddev -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q293"></a>
### Q293

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- rerollable lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:38:    (r"character\.attributes\.", "保留（有合同）", "属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。", "单项属性范围|rerollable|16-24|1-10|不可重 roll", ["CLAUDE.md", "GDD.md", "docs/spec/rarity_wiring_gap_2026-08-07.md"], [("CLAUDE.md", 564, 564), ("docs/spec/rarity_wiring_gap_2026-08-07.md", 115, 121)]),
```

<a id="q294"></a>
### Q294

```sh
rg -n --with-filename --no-heading --sort path -F -- rerollable lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:38:    (r"character\.attributes\.", "保留（有合同）", "属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。", "单项属性范围|rerollable|16-24|1-10|不可重 roll", ["CLAUDE.md", "GDD.md", "docs/spec/rarity_wiring_gap_2026-08-07.md"], [("CLAUDE.md", 564, 564), ("docs/spec/rarity_wiring_gap_2026-08-07.md", 115, 121)]),
```

<a id="q295"></a>
### Q295

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.attributes\.rerollable|attributes\.rerollable' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q296"></a>
### Q296

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- rerollable data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：5；退出码：0。

```text
data/numbers.yaml:1094:    rerollable: false                 # 不可重 roll（GDD 强制规则）
CLAUDE.md:564:| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
docs/handoff/week15_30_phase3_advancement_2026-05-16.md:117:- `attributes`(根骨/身法/悟性/机缘)是 character base 属性,GDD §4.1 加点机制定义"属性可重置(rerollable: false)",升层不变更
docs/handoff/week15_section12_closeout_2026-05-15.md:37:| 2 | 单项属性范围 | `numbers.yaml:749-755` 单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
docs/spec/rarity_wiring_gap_2026-08-07.md:115:`data/numbers.yaml:933-941` 的 `character.attributes` 块(`point_per_attribute_min/max`、`total_points_min/max`、`distribution: normal`、`distribution_mean/stddev`、`rerollable`)**全仓零引用**(实测 `grep -rn` 在 lib/ tool/ tools/ test/ bin/ 全空)。`numbers_config.dart` 只从 `y['character']` 取 `adventure_attribute_bonus.lifetime_cap_per_character`(:460-466),`character.attributes` 子 map 从未被读。
```

<a id="q297"></a>
### Q297

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srerollable -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q298"></a>
### Q298

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srerollable -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q299"></a>
### Q299

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Srerollable -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q300"></a>
### Q300

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- bonus_per_event_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q301"></a>
### Q301

```sh
rg -n --with-filename --no-heading --sort path -F -- bonus_per_event_min lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q302"></a>
### Q302

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.adventure_attribute_bonus\.bonus_per_event_min|adventure_attribute_bonus\.bonus_per_event_min' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q303"></a>
### Q303

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- bonus_per_event_min data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：3；退出码：0。

```text
data/numbers.yaml:1143:    # ⚠️ bonus_per_event_min/max/distribution/weights 未运行时消费(#4③ B7 核账):
data/numbers.yaml:1145:    bonus_per_event_min: 1            # 单次奇遇最少加 1 点
docs/handoff/wf_audit_pilot_2026-05-29.md:52:7. **`lib/data/numbers_config.dart:1`** — `numbers.yaml character.adventure_attribute_bonus.bonus_per_event_min/max/distribution/weights`（每次奇遇属性加成范围/分布权重）完全未被 `lib/` 加载消费；`applyOutcome` 用的是各 encounter yaml outcome 写死的 `attributeDelta`，与通用范围约束脱节。
```

<a id="q304"></a>
### Q304

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbonus_per_event_min -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
c1444c9a8 [schema] #4③ wf_audit 数值迁 yaml:B2/B5 接线 + B6 对齐 + B7 注释
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q305"></a>
### Q305

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbonus_per_event_min -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q306"></a>
### Q306

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sbonus_per_event_min -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
c1444c9a8f5a077639b2172ce7c3eb3553bff057 [schema] #4③ wf_audit 数值迁 yaml:B2/B5 接线 + B6 对齐 + B7 注释
```

<a id="q307"></a>
### Q307

```sh
rg -n --with-filename --no-heading --sort path -- 'bonus_per_event|attributeDelta' data/numbers.yaml data/encounters.yaml
```

命中/输出行数：96；退出码：0。

```text
data/numbers.yaml:1143:    # ⚠️ bonus_per_event_min/max/distribution/weights 未运行时消费(#4③ B7 核账):
data/numbers.yaml:1144:    # applyOutcome 用各 data/encounters.yaml outcome 写死的 attributeDelta,以下为设计参考。
data/numbers.yaml:1145:    bonus_per_event_min: 1            # 单次奇遇最少加 1 点
data/numbers.yaml:1146:    bonus_per_event_max: 3            # 单次奇遇最多加 3 点
data/encounters.yaml:43:        attributeDelta: 1
data/encounters.yaml:63:        attributeDelta: 1
data/encounters.yaml:67:        attributeDelta: 1
data/encounters.yaml:82:        attributeDelta: 1
data/encounters.yaml:86:        attributeDelta: 1
data/encounters.yaml:118:        attributeDelta: 1
data/encounters.yaml:135:        attributeDelta: 1
data/encounters.yaml:139:        attributeDelta: 1
data/encounters.yaml:160:        attributeDelta: 1
data/encounters.yaml:164:        attributeDelta: 1
data/encounters.yaml:183:        attributeDelta: 1
data/encounters.yaml:205:        attributeDelta: 1
data/encounters.yaml:227:        attributeDelta: 1
data/encounters.yaml:250:        attributeDelta: 1
data/encounters.yaml:254:        attributeDelta: 1
data/encounters.yaml:271:        attributeDelta: 1
data/encounters.yaml:293:        attributeDelta: 1
data/encounters.yaml:297:        attributeDelta: 1
data/encounters.yaml:316:        attributeDelta: 1
data/encounters.yaml:340:        attributeDelta: 1
data/encounters.yaml:344:        attributeDelta: 1
data/encounters.yaml:363:        attributeDelta: 1
data/encounters.yaml:367:        attributeDelta: 1
data/encounters.yaml:401:        attributeDelta: 1
data/encounters.yaml:424:        attributeDelta: 1
data/encounters.yaml:428:        attributeDelta: 1
data/encounters.yaml:447:        attributeDelta: 1
data/encounters.yaml:451:        attributeDelta: 1
data/encounters.yaml:470:        attributeDelta: 1
data/encounters.yaml:496:        attributeDelta: 2
data/encounters.yaml:515:        attributeDelta: 1
data/encounters.yaml:519:        attributeDelta: 1
data/encounters.yaml:554:        attributeDelta: 1
data/encounters.yaml:577:        attributeDelta: 1
data/encounters.yaml:597:        attributeDelta: 1
data/encounters.yaml:614:        attributeDelta: 1
data/encounters.yaml:639:        attributeDelta: 1
data/encounters.yaml:656:        attributeDelta: 1
data/encounters.yaml:676:        attributeDelta: 1
data/encounters.yaml:697:        attributeDelta: 1
data/encounters.yaml:718:        attributeDelta: 1
data/encounters.yaml:737:        attributeDelta: 1
data/encounters.yaml:741:        attributeDelta: 1
data/encounters.yaml:757:        attributeDelta: 1
data/encounters.yaml:761:        attributeDelta: 1
data/encounters.yaml:777:        attributeDelta: 1
data/encounters.yaml:781:        attributeDelta: 1
data/encounters.yaml:797:        attributeDelta: 1
data/encounters.yaml:801:        attributeDelta: 1
data/encounters.yaml:817:        attributeDelta: 1
data/encounters.yaml:821:        attributeDelta: 1
data/encounters.yaml:837:        attributeDelta: 1
data/encounters.yaml:841:        attributeDelta: 1
data/encounters.yaml:857:        attributeDelta: 1
data/encounters.yaml:861:        attributeDelta: 1
data/encounters.yaml:877:        attributeDelta: 1
data/encounters.yaml:881:        attributeDelta: 1
data/encounters.yaml:902:        attributeDelta: 1
data/encounters.yaml:925:        attributeDelta: 1
data/encounters.yaml:949:        attributeDelta: 1
data/encounters.yaml:972:        attributeDelta: 1
data/encounters.yaml:995:        attributeDelta: 1
data/encounters.yaml:1018:        attributeDelta: 1
data/encounters.yaml:1038:        attributeDelta: 1
data/encounters.yaml:1042:        attributeDelta: 1
data/encounters.yaml:1068:        attributeDelta: 1
data/encounters.yaml:1085:        attributeDelta: 1
data/encounters.yaml:1102:        attributeDelta: 1
data/encounters.yaml:1119:        attributeDelta: 2
data/encounters.yaml:1136:        attributeDelta: 2
data/encounters.yaml:1152:        attributeDelta: 2
data/encounters.yaml:1156:        attributeDelta: 1
data/encounters.yaml:1172:        attributeDelta: 2
data/encounters.yaml:1176:        attributeDelta: 2
data/encounters.yaml:1192:        attributeDelta: 2
data/encounters.yaml:1196:        attributeDelta: 1
data/encounters.yaml:1212:        attributeDelta: 2
data/encounters.yaml:1216:        attributeDelta: 1
data/encounters.yaml:1238:        attributeDelta: 1
data/encounters.yaml:1257:        attributeDelta: 1
data/encounters.yaml:1276:        attributeDelta: 1
data/encounters.yaml:1302:        attributeDelta: 1
data/encounters.yaml:1318:        attributeDelta: 1
data/encounters.yaml:1337:        attributeDelta: 1
data/encounters.yaml:1356:        attributeDelta: 1
data/encounters.yaml:1372:        attributeDelta: 1
data/encounters.yaml:1389:        attributeDelta: 1
data/encounters.yaml:1405:        attributeDelta: 1
data/encounters.yaml:1423:        attributeDelta: 1
data/encounters.yaml:1440:        attributeDelta: 1
data/encounters.yaml:1458:        attributeDelta: 1
data/encounters.yaml:1476:        attributeDelta: 1
```

<a id="q308"></a>
### Q308

```sh
sed -n 1140,1149p data/numbers.yaml
```

命中/输出行数：10；退出码：0。

```text
  # 后天弥补先天，但有硬上限
  adventure_attribute_bonus:
    lifetime_cap_per_character: 5     # 每个角色生涯总加成上限 +5(#4③ B2 已接 EncounterService.attributeGainCap)
    # ⚠️ bonus_per_event_min/max/distribution/weights 未运行时消费(#4③ B7 核账):
    # applyOutcome 用各 data/encounters.yaml outcome 写死的 attributeDelta,以下为设计参考。
    bonus_per_event_min: 1            # 单次奇遇最少加 1 点
    bonus_per_event_max: 3            # 单次奇遇最多加 3 点
    distribution: "weighted"          # 大部分加 1，少数加 2-3
    weights: [0.65, 0.25, 0.10]      # 1 点/2 点/3 点的概率
```

<a id="q309"></a>
### Q309

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- bonus_per_event_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q310"></a>
### Q310

```sh
rg -n --with-filename --no-heading --sort path -F -- bonus_per_event_max lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q311"></a>
### Q311

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'character\.adventure_attribute_bonus\.bonus_per_event_max|adventure_attribute_bonus\.bonus_per_event_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q312"></a>
### Q312

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- bonus_per_event_max data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1146:    bonus_per_event_max: 3            # 单次奇遇最多加 3 点
docs/handoff/wf_audit_pilot_2026-05-29.md:53:   - **建议**: 明确这批字段是「设计参考」还是「运行时约束」。若是后者，`NumbersConfig` 解析并在 `GameRepository` 红线校验中验证各 outcome delta ≤ `bonus_per_event_max`；若仅文档性，yaml 加注释。
```

<a id="q313"></a>
### Q313

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbonus_per_event_max -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q314"></a>
### Q314

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbonus_per_event_max -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q315"></a>
### Q315

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sbonus_per_event_max -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q316"></a>
### Q316

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- time_range lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:41:    (r"retreat\.time_of_day_bonus\[", "时段文档锚", "按 period 选行后只读 multiplier/target_attribute/applies_to_school；没有读取 time_range。", ["lib/data/numbers_config.dart:2847", "lib/data/numbers_config.dart:2912"]),
tools/audit/numbers_unused_keys_review.py:40:    (r"retreat\.", "头注 UNUSED", "固定传统时辰的文档锚；代码按 period 与时钟规则实现，不读取该时间数组或 null。", "time_range|子时|正午", ["data/numbers.yaml", "GDD.md", "data_schema.md"], [("data/numbers.yaml", 1371, 1388), ("GDD.md", 542, 547)]),
```

<a id="q317"></a>
### Q317

```sh
rg -n --with-filename --no-heading --sort path -F -- time_range lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:41:    (r"retreat\.time_of_day_bonus\[", "时段文档锚", "按 period 选行后只读 multiplier/target_attribute/applies_to_school；没有读取 time_range。", ["lib/data/numbers_config.dart:2847", "lib/data/numbers_config.dart:2912"]),
tools/audit/numbers_unused_keys_review.py:40:    (r"retreat\.", "头注 UNUSED", "固定传统时辰的文档锚；代码按 period 与时钟规则实现，不读取该时间数组或 null。", "time_range|子时|正午", ["data/numbers.yaml", "GDD.md", "data_schema.md"], [("data/numbers.yaml", 1371, 1388), ("GDD.md", 542, 547)]),
```

<a id="q318"></a>
### Q318

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'retreat\.time_of_day_bonus\.time_range|time_of_day_bonus\.time_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q319"></a>
### Q319

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- time_range data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：8；退出码：0。

```text
data/numbers.yaml:1371:  # ⚠ time_range 字段为固定时辰文档锚（审计 D6 2026-06-24）：NumbersConfig 只解析
data/numbers.yaml:1372:  #   multiplier/effect/target_attribute/applies_to_school，**不解析 time_range**。
data/numbers.yaml:1374:  #   子时(23:00-01:00)/正午(11:00-13:00)是固定传统时辰常量、非可调平衡项，编辑此处 time_range 不生效。
data/numbers.yaml:1377:      time_range: ["23:00", "01:00"]
data/numbers.yaml:1381:      time_range: ["11:00", "13:00"]
data/numbers.yaml:1388:      time_range: null                       # 其他时段无加成
docs/audit/full_system_audit_2026-06-24.md:93:| D6 | 闭关 `time_range` 配而不用（时段硬编码 dart）| ✅ **注释**：子时(23-01)/正午(11-13)是固定传统时辰常量非可调平衡项,NumbersConfig 不解析 time_range,实际硬编码 `_isZiShi`/`_isZhengWu`,编辑 yaml 不生效（块头 ⚠ 注）|
docs/handoff/week15_section12_7_school_extra_effects_2026-05-16.md:43:  time_range: ["11:00", "13:00"]
```

<a id="q320"></a>
### Q320

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stime_range -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
9f59ddc2b chore: 审计 D+E 卫生批收口(D2 wire/D1·D3-D7 注释honest化/D8 改stale注释/E 迁UiStrings)
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q321"></a>
### Q321

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Stime_range -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q322"></a>
### Q322

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Stime_range -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
9f59ddc2b64faf28d06c52a26f70ea60e8014f3a chore: 审计 D+E 卫生批收口(D2 wire/D1·D3-D7 注释honest化/D8 改stale注释/E 迁UiStrings)
```

<a id="q323"></a>
### Q323

```sh
rg -n --with-filename --no-heading --sort path -- 'time_range|子时|正午' data/numbers.yaml GDD.md data_schema.md
```

命中/输出行数：14；退出码：0。

```text
data/numbers.yaml:1371:  # ⚠ time_range 字段为固定时辰文档锚（审计 D6 2026-06-24）：NumbersConfig 只解析
data/numbers.yaml:1372:  #   multiplier/effect/target_attribute/applies_to_school，**不解析 time_range**。
data/numbers.yaml:1374:  #   子时(23:00-01:00)/正午(11:00-13:00)是固定传统时辰常量、非可调平衡项，编辑此处 time_range 不生效。
data/numbers.yaml:1376:    - period: ziShi                          # 子时
data/numbers.yaml:1377:      time_range: ["23:00", "01:00"]
data/numbers.yaml:1380:    - period: zhengWu                        # 正午
data/numbers.yaml:1381:      time_range: ["11:00", "13:00"]
data/numbers.yaml:1384:      # CLAUDE.md §12.1 #7 收口 v1.4(2026-05-16):正午阳刚 +20% 加成定向落地。
data/numbers.yaml:1388:      time_range: null                       # 其他时段无加成
GDD.md:546:| 子时 | 23:00 ~ 1:00 | 内力增长 +20% |
GDD.md:547:| 正午 | 11:00 ~ 13:00 | 阳刚类武学 +20% |
data_schema.md:283:  ziShi,           // 子时 23:00-1:00
data_schema.md:284:  zhengWu,         // 正午 11:00-13:00
data_schema.md:1128:**JSON 示例**（古剑冢闭关 4 小时，子时开始）：
```

<a id="q324"></a>
### Q324

```sh
sed -n 1371,1388p data/numbers.yaml
```

命中/输出行数：18；退出码：0。

```text
  # ⚠ time_range 字段为固定时辰文档锚（审计 D6 2026-06-24）：NumbersConfig 只解析
  #   multiplier/effect/target_attribute/applies_to_school，**不解析 time_range**。
  #   实际时段判定硬编码在 seclusion_service.dart `_isZiShi`(h∈{23,0}) / `_isZhengWu`(h∈{11,12})。
  #   子时(23:00-01:00)/正午(11:00-13:00)是固定传统时辰常量、非可调平衡项，编辑此处 time_range 不生效。
  time_of_day_bonus:
    - period: ziShi                          # 子时
      time_range: ["23:00", "01:00"]
      effect: "internal_force_growth"
      multiplier: 1.20                       # 内力增长 +20%
    - period: zhengWu                        # 正午
      time_range: ["11:00", "13:00"]
      effect: "yang_school_techniques"       # 阳刚类武学（刚猛流派）+20%
      multiplier: 1.20
      # CLAUDE.md §12.1 #7 收口 v1.4(2026-05-16):正午阳刚 +20% 加成定向落地。
      target_attribute: "internal_force_points"  # 加成乘到 internalForcePoints(刚猛=内力外放对应)
      applies_to_school: "gangMeng"          # 仅主修刚猛流派 character 触发,非刚猛 character 不加成
    - period: other
      time_range: null                       # 其他时段无加成
```

<a id="q325"></a>
### Q325

```sh
sed -n 542,547p GDD.md
```

命中/输出行数：6；退出码：0。

```text
**时辰加成**：

| 时辰 | 现实时间 | 加成 |
|------|---------|------|
| 子时 | 23:00 ~ 1:00 | 内力增长 +20% |
| 正午 | 11:00 ~ 13:00 | 阳刚类武学 +20% |
```

<a id="q326"></a>
### Q326

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- daily_attempts lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q327"></a>
### Q327

```sh
rg -n --with-filename --no-heading --sort path -F -- daily_attempts lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q328"></a>
### Q328

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.daily_attempts' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q329"></a>
### Q329

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- daily_attempts data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：8；退出码：0。

```text
data/numbers.yaml:1490:# daily_attempts / difficulty_curve / boss_multiplier 均为设计意图记录：爬塔实际难度走
data/numbers.yaml:1496:  daily_attempts: 5
docs/audit/orphan_doc_branches_triage_2026-09-17.md:390:仍成立的窄事实：`rg -n daily_attempts lib`、`rg -n refresh_at lib` 各 0 命中/退出 1；定义在 `data/numbers.yaml:1496-1497`，UNUSED 段注释在 `:1488`。旧六个 PNG `assets/enemies/{shiye,fu_zhaizhu,shidi_b,killer_a,killer_b,wulin_bazhu}.png` 都存在，对每条完整路径在 lib/data 精确搜索均 0；没有据此排除动态拼接，所以不能直接授权删除。其余逐字段动态接线总量没有完整重审，**未能判定**今日精确死字段总数；numbers 反向引用由本夜 B-2 的独立实测清单负责。
docs/dispatch/2026-09-16_night_B_治理审计.md:31:**现状**：审查报告称 `numbers.yaml` 约 460 个叶子 key 中约 74 个在 `lib/` 零引用（含标 UNUSED 两个月的 `tower.daily_attempts` / `refresh_at`、`leaderboard.sync_to_supabase`、`combat.final_damage_formula.apply_*`、`validation_examples` 段）。这些数字来自只读快照，**未复跑**。
docs/dispatch/reports/2026-08-07_PI1_yaml_consumption.md:47:| data/numbers.yaml:1319 | `daily_attempts` | 0 | tower 段;1311-1314 自证 UNUSED:「每日 5 次限制未实装」 |
docs/dispatch/reports/2026-08-07_Q1_field_verify.md:37:| 6 | `daily_attempts` | numbers.yaml:1319 | 真未消费 | `tower:` 整段不进 `NumbersConfig.fromYaml`(无 `y['tower']` 取值);yaml :1311-1314 注释自证 UNUSED;每日次数限制未实装 |
docs/sessions/2026-07-03_0256_批次123清理.md:23:- numbers.yaml `tower.daily_attempts` 每日5次限制（GDD §8.2 称强制规则）实际未实装，lib/ 零消费——已在死配置头注标注，未擅自加限制功能。
docs/spec/full_review_2026-07-02_followup_backlog.md:21:- [x] numbers.yaml `tower` 段 + `synergies` 段 **✅已补 unused 头注(2026-07-03·batch-123)**——证实 0 消费:`NumbersConfig.fromYaml`(numbers_config.dart:322+)不解析 `y['tower']`/`y['synergies']`(头注 L18-19「保留 raw」),lib/ 无 raw 访问。synergies 真实源=独立 `data/synergies.yaml`(12 条·multipliers 格式·game_repository:341)。两段各加醒目 UNUSED 头注(保留 tower 段作 GDD §8.2 设计锚·标注 daily_attempts 每日 5 次限制**未实装**)。删除仍需拍板,故留注不删。
```

<a id="q330"></a>
### Q330

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdaily_attempts -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
93a8687c4 清理批次2/3零引用资产与死配置 + ExactAssetImage 迁 WuxiaImage
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q331"></a>
### Q331

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdaily_attempts -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q332"></a>
### Q332

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sdaily_attempts -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
93a8687c4a48a410717346c36fda2358aeba81f2 清理批次2/3零引用资产与死配置 + ExactAssetImage 迁 WuxiaImage
```

<a id="q333"></a>
### Q333

```sh
rg -n --with-filename --no-heading --sort path -- '每天 5 次|每日 5 次|1:1 锚死|Boss 位 14|当前本地榜|接线或删除需拍板' GDD.md data_schema.md data/numbers.yaml
```

命中/输出行数：9；退出码：0。

```text
GDD.md:15:> - 爬塔:**49 层 1:1 锚死**(floor N ↔ abs N·14 Boss 位·spec 2026-08-01,批 A 2026-08-04 实装;真相源 `data/towers.yaml`)
GDD.md:46:| **联网形式** | 纯单机（云端排行榜为未来方向；当前本地榜 + Noop 同步抽象，零网络依赖） |
GDD.md:603:- **1:1 锚死**（spec 2026-08-01 拍板）：floor N ↔ 境界绝对层 N，共 49 层与主线 cap abs 49 对齐；断档结构上不存在。敌人数值对齐主线同境界层实测中位。requiredRealm = 该层境界，掉落阶随之（加载期校验钉死，防提前发放）。
GDD.md:604:- **Boss 位 14 个**：每 tier 中点（4/11/18/25/32/39/46）小 Boss、tier 末层（7/14/21/28/35/42/49）大 Boss。塔顶 49 = 九霄魔尊（护法墙 + 脆弱窗机制门槛，§5.4 机制型例外条款）；32 = 绝顶剑魔（脆弱窗，血量-乘子联动校准，名义血刻意低于曲线、窗口外有效血远超）。
GDD.md:606:- 不做“每天 5 次”自然日挑战次数；若后续需要限制高价值塔层 / 强力副本重复收益，改用 §2.3 的副本凭证或劳损调息，并保持在线=离线、可囤积、非日课
GDD.md:607:- 通关层数决定排行榜位置（当前本地榜；云同步为未来方向）
data_schema.md:1255:> 爬塔每日 5 次（GDD §8.2）。每天首次进入主界面时检查是否需要新建一行。
data/numbers.yaml:1486:# GDD §8.2：每天 5 次挑战次数，通关层数决定排行榜位置
data/numbers.yaml:1491:# towers.yaml，每日 5 次限制未实装。保留作 GDD §8.2 设计锚，勿据此以为已生效；接线或删除需拍板。
```

<a id="q334"></a>
### Q334

```sh
sed -n 603,607p GDD.md
```

命中/输出行数：5；退出码：0。

```text
- **1:1 锚死**（spec 2026-08-01 拍板）：floor N ↔ 境界绝对层 N，共 49 层与主线 cap abs 49 对齐；断档结构上不存在。敌人数值对齐主线同境界层实测中位。requiredRealm = 该层境界，掉落阶随之（加载期校验钉死，防提前发放）。
- **Boss 位 14 个**：每 tier 中点（4/11/18/25/32/39/46）小 Boss、tier 末层（7/14/21/28/35/42/49）大 Boss。塔顶 49 = 九霄魔尊（护法墙 + 脆弱窗机制门槛，§5.4 机制型例外条款）；32 = 绝顶剑魔（脆弱窗，血量-乘子联动校准，名义血刻意低于曲线、窗口外有效血远超）。
- 断魂帖里程碑：第 16/33/49 层首通各一张（2026-08-04 拍板保持 3 张、约三等分、经济总量不变；旧位 10/20/30 已领记录永久保留）。
- 不做“每天 5 次”自然日挑战次数；若后续需要限制高价值塔层 / 强力副本重复收益，改用 §2.3 的副本凭证或劳损调息，并保持在线=离线、可囤积、非日课
- 通关层数决定排行榜位置（当前本地榜；云同步为未来方向）
```

<a id="q335"></a>
### Q335

```sh
sed -n 1253,1255p data_schema.md
```

命中/输出行数：3；退出码：0。

```text
### 4.10 DailyChallenge · 每日挑战次数

> 爬塔每日 5 次（GDD §8.2）。每天首次进入主界面时检查是否需要新建一行。
```

<a id="q336"></a>
### Q336

```sh
sed -n 1487,1497p data/numbers.yaml
```

命中/输出行数：11；退出码：0。

```text
#
# ⚠️ UNUSED（2026-07-03 六维审查批次3 证实）：本 `tower:` 整段未被 NumbersConfig.fromYaml
# 解析为字段（见 numbers_config.dart:18-19「其余段…tower…保留 raw」），lib/ 无任何消费。
# daily_attempts / difficulty_curve / boss_multiplier 均为设计意图记录：爬塔实际难度走
# towers.yaml，每日 5 次限制未实装。保留作 GDD §8.2 设计锚，勿据此以为已生效；接线或删除需拍板。

tower:

  # --- 每日挑战次数（GDD §8.2，强制规则）---
  daily_attempts: 5
  refresh_at: "00:00"                        # 本地时区午夜重置（详见 schema §4.10 时区规则）
```

<a id="q337"></a>
### Q337

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- refresh_at lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:348:                     "refresh_at", "sync_to_supabase"):
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q338"></a>
### Q338

```sh
rg -n --with-filename --no-heading --sort path -F -- refresh_at lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:348:                     "refresh_at", "sync_to_supabase"):
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q339"></a>
### Q339

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.refresh_at' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q340"></a>
### Q340

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- refresh_at data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：5；退出码：0。

```text
data/numbers.yaml:1497:  refresh_at: "00:00"                        # 本地时区午夜重置（详见 schema §4.10 时区规则）
docs/audit/orphan_doc_branches_triage_2026-09-17.md:390:仍成立的窄事实：`rg -n daily_attempts lib`、`rg -n refresh_at lib` 各 0 命中/退出 1；定义在 `data/numbers.yaml:1496-1497`，UNUSED 段注释在 `:1488`。旧六个 PNG `assets/enemies/{shiye,fu_zhaizhu,shidi_b,killer_a,killer_b,wulin_bazhu}.png` 都存在，对每条完整路径在 lib/data 精确搜索均 0；没有据此排除动态拼接，所以不能直接授权删除。其余逐字段动态接线总量没有完整重审，**未能判定**今日精确死字段总数；numbers 反向引用由本夜 B-2 的独立实测清单负责。
docs/dispatch/2026-09-16_night_B_治理审计.md:31:**现状**：审查报告称 `numbers.yaml` 约 460 个叶子 key 中约 74 个在 `lib/` 零引用（含标 UNUSED 两个月的 `tower.daily_attempts` / `refresh_at`、`leaderboard.sync_to_supabase`、`combat.final_damage_formula.apply_*`、`validation_examples` 段）。这些数字来自只读快照，**未复跑**。
docs/dispatch/reports/2026-08-07_PI1_yaml_consumption.md:48:| data/numbers.yaml:1320 | `refresh_at` | 0 | 同上,「UNUSED…保留作 GDD §8.2 设计锚」 |
docs/dispatch/reports/2026-08-07_Q1_field_verify.md:38:| 7 | `refresh_at` | numbers.yaml:1320 | 真未消费 | 同上(tower 段整段未解析) |
```

<a id="q341"></a>
### Q341

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srefresh_at -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q342"></a>
### Q342

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srefresh_at -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q343"></a>
### Q343

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Srefresh_at -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q344"></a>
### Q344

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- difficulty_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q345"></a>
### Q345

```sh
rg -n --with-filename --no-heading --sort path -F -- difficulty_range lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q346"></a>
### Q346

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.difficulty_curve\.difficulty_range|difficulty_curve\.difficulty_range' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q347"></a>
### Q347

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- difficulty_range data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：6；退出码：0。

```text
data/numbers.yaml:1510:      difficulty_range: [1.00, 1.20]         # 线性 1.0/1.05/1.10/1.15/1.20
data/numbers.yaml:1514:      difficulty_range: [1.25, 1.50]         # 1.25/1.30/1.35/1.40/1.50
data/numbers.yaml:1520:      difficulty_range: [1.60, 2.00]         # 1.60/1.70/1.80/1.85/2.00
data/numbers.yaml:1524:      difficulty_range: [2.10, 2.60]         # 2.10/2.20/2.30/2.45/2.60
data/numbers.yaml:1530:      difficulty_range: [2.80, 3.40]         # 2.80/2.95/3.10/3.25/3.40
data/numbers.yaml:1534:      difficulty_range: [3.55, 4.20]         # 3.55/3.70/3.85/4.00/4.20
```

<a id="q348"></a>
### Q348

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdifficulty_range -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q349"></a>
### Q349

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdifficulty_range -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q350"></a>
### Q350

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sdifficulty_range -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q351"></a>
### Q351

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- recommended_realm lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q352"></a>
### Q352

```sh
rg -n --with-filename --no-heading --sort path -F -- recommended_realm lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q353"></a>
### Q353

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.difficulty_curve\.recommended_realm|difficulty_curve\.recommended_realm' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q354"></a>
### Q354

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- recommended_realm data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：7；退出码：0。

```text
data/numbers.yaml:1512:      recommended_realm: erLiu               # 推荐境界：二流·圆熟
data/numbers.yaml:1516:      recommended_realm: erLiu               # 二流·登峰
data/numbers.yaml:1522:      recommended_realm: yiLiu               # 一流·启蒙
data/numbers.yaml:1526:      recommended_realm: yiLiu               # 一流·圆熟
data/numbers.yaml:1532:      recommended_realm: yiLiu               # 一流·登峰
data/numbers.yaml:1536:      recommended_realm: jueDing             # 绝顶·启蒙（Demo 不开放绝顶但供爬塔挑战）
docs/audit/night_b_governance_recovery_2026-09-17.md:47:- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
```

<a id="q355"></a>
### Q355

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srecommended_realm -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q356"></a>
### Q356

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srecommended_realm -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q357"></a>
### Q357

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Srecommended_realm -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q358"></a>
### Q358

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- small_boss_layers lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q359"></a>
### Q359

```sh
rg -n --with-filename --no-heading --sort path -F -- small_boss_layers lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q360"></a>
### Q360

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.boss_layers\.small_boss_layers|boss_layers\.small_boss_layers' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q361"></a>
### Q361

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- small_boss_layers data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1541:    small_boss_layers: [5, 15, 25]           # 小 Boss
```

<a id="q362"></a>
### Q362

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssmall_boss_layers -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q363"></a>
### Q363

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssmall_boss_layers -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q364"></a>
### Q364

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Ssmall_boss_layers -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q365"></a>
### Q365

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- big_boss_layers lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q366"></a>
### Q366

```sh
rg -n --with-filename --no-heading --sort path -F -- big_boss_layers lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q367"></a>
### Q367

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.boss_layers\.big_boss_layers|boss_layers\.big_boss_layers' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q368"></a>
### Q368

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- big_boss_layers data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1542:    big_boss_layers: [10, 20, 30]            # 大 Boss
```

<a id="q369"></a>
### Q369

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbig_boss_layers -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q370"></a>
### Q370

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbig_boss_layers -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q371"></a>
### Q371

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sbig_boss_layers -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q372"></a>
### Q372

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- small_boss_multiplier lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q373"></a>
### Q373

```sh
rg -n --with-filename --no-heading --sort path -F -- small_boss_multiplier lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q374"></a>
### Q374

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.boss_layers\.small_boss_multiplier|boss_layers\.small_boss_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q375"></a>
### Q375

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- small_boss_multiplier data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1543:    small_boss_multiplier: 1.5               # 小 Boss 数值 ×1.5
```

<a id="q376"></a>
### Q376

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssmall_boss_multiplier -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q377"></a>
### Q377

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssmall_boss_multiplier -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q378"></a>
### Q378

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Ssmall_boss_multiplier -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q379"></a>
### Q379

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- big_boss_multiplier lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q380"></a>
### Q380

```sh
rg -n --with-filename --no-heading --sort path -F -- big_boss_multiplier lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q381"></a>
### Q381

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.boss_layers\.big_boss_multiplier|boss_layers\.big_boss_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q382"></a>
### Q382

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- big_boss_multiplier data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1544:    big_boss_multiplier: 2.0                 # 大 Boss 数值 ×2.0
```

<a id="q383"></a>
### Q383

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbig_boss_multiplier -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q384"></a>
### Q384

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sbig_boss_multiplier -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q385"></a>
### Q385

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sbig_boss_multiplier -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q386"></a>
### Q386

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- sync_to_supabase lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:348:                     "refresh_at", "sync_to_supabase"):
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q387"></a>
### Q387

```sh
rg -n --with-filename --no-heading --sort path -F -- sync_to_supabase lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
tools/audit/numbers_key_usage.py:348:                     "refresh_at", "sync_to_supabase"):
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q388"></a>
### Q388

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'tower\.leaderboard\.sync_to_supabase|leaderboard\.sync_to_supabase' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q389"></a>
### Q389

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- sync_to_supabase data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：9；退出码：0。

```text
data/numbers.yaml:1554:    sync_to_supabase: true                   # 通关后同步到 Supabase
docs/dispatch/2026-09-16_night_B_治理审计.md:31:**现状**：审查报告称 `numbers.yaml` 约 460 个叶子 key 中约 74 个在 `lib/` 零引用（含标 UNUSED 两个月的 `tower.daily_attempts` / `refresh_at`、`leaderboard.sync_to_supabase`、`combat.final_damage_formula.apply_*`、`validation_examples` 段）。这些数字来自只读快照，**未复跑**。
docs/handoff/p0_40_local_leaderboard_closeout_2026-05-17.md:60:**未改动**(spec §2.3 决议:配置保留,Noop 实现下 `sync_to_supabase=true` 等同 `false` 行为)。
docs/handoff/p0_40_local_leaderboard_closeout_2026-05-17.md:70:| numbers.yaml leaderboard.sync_to_supabase 配置保语义 | Noop 实现下 0 network call(reportClear 内 intentionally noop) | ✅ |
docs/handoff/p0_40_local_leaderboard_spec.md:15:- `data/numbers.yaml line 1054-1058` `leaderboard.sync_to_supabase: true` + 3 字段配置(死配置,0 读取)
docs/handoff/p0_40_local_leaderboard_spec.md:55:  sync_to_supabase: true                   # 通关后同步到 Supabase
docs/handoff/p0_40_local_leaderboard_spec.md:60:**本 spec 处理**:配置保留不改(本会话 placeholder 实现读取后 noop,sync_to_supabase: true 在 NoopSync 下不触发任何网络调用,等同 false 行为但保配置语义)。
docs/handoff/p0_40_local_leaderboard_spec.md:391:| numbers.yaml leaderboard.sync_to_supabase 配置保语义 | Noop 实现下 sync_to_supabase=true 等同 sync_to_supabase=false 行为(0 network call) |
docs/phase0/p3_3_pvp_phase0_2026-05-24.md:18:| C 邻近系统 | **底座 ready**:`battle_strategy.dart:14` 注释 `PvpStrategy(异步快照对战,Supabase 接入)` + `leaderboard_sync_service.dart:11` 抽象 + `NoopLeaderboardSync:29` 注入 + `numbers.yaml:1060 leaderboard.sync_to_supabase: true` 配置(D 方案 future-proof,**真 Supabase 包未引**) | ⚠ 既有底座可挂 · PVP 实装直接 implements `BattleStrategy` + 新 `PvpSyncService implements LeaderboardSyncService` 同体例 |
```

<a id="q390"></a>
### Q390

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssync_to_supabase -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q391"></a>
### Q391

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Ssync_to_supabase -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q392"></a>
### Q392

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Ssync_to_supabase -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q393"></a>
### Q393

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- can_take_disciple_at lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:42:    (r"inheritance\.unlock_rules\.(can_take_disciple_at|disciple_can_take_grand_disciple_at)", "待拍板", "未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。", "can_take_disciple_at|徒孙|一流|绝顶", ["data/recruit_candidates.yaml", "GDD.md"], [("data/recruit_candidates.yaml", 1, 4), ("GDD.md", 499, 505), ("data/numbers.yaml", 1565, 1581)]),
```

<a id="q394"></a>
### Q394

```sh
rg -n --with-filename --no-heading --sort path -F -- can_take_disciple_at lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:42:    (r"inheritance\.unlock_rules\.(can_take_disciple_at|disciple_can_take_grand_disciple_at)", "待拍板", "未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。", "can_take_disciple_at|徒孙|一流|绝顶", ["data/recruit_candidates.yaml", "GDD.md"], [("data/recruit_candidates.yaml", 1, 4), ("GDD.md", 499, 505), ("data/numbers.yaml", 1565, 1581)]),
```

<a id="q395"></a>
### Q395

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'inheritance\.unlock_rules\.can_take_disciple_at|unlock_rules\.can_take_disciple_at' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q396"></a>
### Q396

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- can_take_disciple_at data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：6；退出码：0。

```text
data/numbers.yaml:1570:  #   · can_take_disciple_at / disciple_can_take_grand_disciple_at
data/numbers.yaml:1579:    can_take_disciple_at: yiLiu              # 突破到一流可收徒
data/recruit_candidates.yaml:2:# GDD §7.1「突破到一流可收徒」+ inheritance.unlock_rules.can_take_disciple_at: yiLiu
docs/audit/night_b_governance_recovery_2026-09-17.md:47:- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
docs/handoff/p1_1_a1_recruitment_audit_2026-05-21.md:21:| `numbers.yaml inheritance.unlock_rules.can_take_disciple_at: yiLiu` | `data/numbers.yaml:1074` | ✅ 已配 |
docs/handoff/phase5_master_disciple_spec_2026-05-20.md:18:| 一流 / 结丹 | `can_take_disciple_at: yiLiu` | 大弟子 / 二弟子 yaml 直挂 active | (已实装,无需新增) |
```

<a id="q397"></a>
### Q397

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scan_take_disciple_at -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
13ce2300f 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q398"></a>
### Q398

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scan_take_disciple_at -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q399"></a>
### Q399

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Scan_take_disciple_at -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
```

<a id="q400"></a>
### Q400

```sh
rg -n --with-filename --no-heading --sort path -- 'can_take_disciple_at|徒孙|一流|绝顶' data/recruit_candidates.yaml GDD.md
```

命中/输出行数：21；退出码：0。

```text
data/recruit_candidates.yaml:2:# GDD §7.1「突破到一流可收徒」+ inheritance.unlock_rules.can_take_disciple_at: yiLiu
GDD.md:137:| 4 | 一流 | 名门高手 |
GDD.md:138:| 5 | 绝顶 | 当世高手 |
GDD.md:154:**UI 显示风格**：`二流·入门`、`一流·圆熟`、`宗师·化境`。
GDD.md:189:| 一流 | 利器 | 门派绝学 |
GDD.md:190:| 绝顶 | 重器 | 江湖秘传 |
GDD.md:361:**设计理由**：境界差是武侠世界的"硬天花板"。三流挑战一流可能赢一次，但挑战绝顶就是送死。这强迫玩家**修炼境界**而非堆砌装备。
GDD.md:503:| 一流（结丹） | 收徒 |
GDD.md:504:| 绝顶（化神） | 徒弟可以收徒孙 |
GDD.md:572:| 10 | 中州 | 一流 | 守拙翁（止水潭守道名宿） | 循符走完边塞入中原·止水诀真解·循路→开路顿悟·发布上限抬至一流熟练 |
GDD.md:573:| 11 | 名门之虚 | 一流 | 鎏金公（问鼎台中州名宿） | 踏中州名门·名门虚实之辨·鎏金诀真解·名≠本事·求「实」Ch12 hook·发布上限抬至一流圆熟 |
GDD.md:574:| 12 | 名下之实 | 一流 | 无名客（荒村野店无名真高手） | 寻中州之实·名下之实收一流三章·绵里藏针真解·名≠本事实至名归·承绝顶段 hook·发布上限抬至一流登峰 |
GDD.md:575:| 13 | 山外青山 | 绝顶 | 候峰翁（绝顶之上等人数十年的老者） | 起脚往上·从看江湖到成为江湖传承弧·一览众山真解·接符人变留符人·发布上限抬至绝顶熟练 |
GDD.md:576:| 14 | 山外来客 | 绝顶 | 马战宗师（西凉万里叩山的骑战名家） | 循名而来的远客·十荡十决真解收编·成为江湖第一课·阳关无故人宗师段伏笔·发布上限抬至绝顶圆熟 |
GDD.md:577:| 15 | 关山一程 | 绝顶 | 守关老将（镇阳关数十年的中原老将） | 下山西行头一程·Ch4 西出阳关旧路新走回旋·孤城闭真解新写·借关一战对称借山一战·绝顶段收束·发布上限抬至绝顶登峰 |
GDD.md:583:| 21 | 绝顶交程 | 武圣 | 循符少年（无名绝顶·候峰翁旧位） | **主线终章**·东归回山、绝顶交程(交符=章眼)·山外无山真解**新写**(与 Ch13 一览众山成对·canon 自生长)·末 Boss 换胜负轴 **surviveTicks 主线首用**(并补该条件的顶栏条件条与结算文案——此前零玩家可见面)·神物第三批 3 件**11 件投放收口清零**·末 Boss school 转 lingQiao 打破连续四关 yinRou·发布上限抬至武圣登峰 **49 封顶**(within-tier·飞升条件③ 首次可达) |
GDD.md:589:> Ch4～6 原始内容制作时曾按一流至武圣标注叙事强度；2026-07-14 起，当前有效玩法数值统一重排到学徒 / 三流，旧高阶标注仅作历史创作记录，不再代表 `data/stages.yaml` 的需求境界。高阶数值空间留给未来副本与其他玩法。**2026-07-17 Ch7「北望」起主线正式进入二流段**（真传位新弧·继位大弟子·发布上限二流·熟练 = 绝对层 17；千钧坠岳真解 / 烛影摇红残页在 Ch7 章末 Boss 挂载）；**2026-07-18 Ch8「出塞」续二流段第 2 章**（追灰衣人·铜符北上；末 Boss 灰衣人本人逼出真正本命,新写独立真解「灰袖回风」chargeSkill=dropSkillManual 双用挂载 stage_08_05,不进 wave_b 配平池）；**2026-07-20 Ch9「碛北」续二流段第 3 章**（循符入无路碛北·末 Boss「那一位」铜符本主·沉默出手即决·独立真解「沉沙一诀」chargeSkill=dropSkillManual 双用挂载 stage_09_05·边塞三章弧收束、不抬发布上限）；**2026-07-20 Ch10「中州」一流段首章**（循符走完边塞、回身入中原江湖深处；末 Boss 守拙翁守道名宿·独立真解「止水诀」chargeSkill=dropSkillManual 双用挂载 stage_10_05·「循路→开路」一流拐点顿悟·发布上限抬至一流·熟练 = 绝对层 24；一流门派绝学敌招 + 利器装备复用既有储备，零新增）；**2026-07-21 Ch11「名门之虚」续一流段第 2 章**（踏中州名门·见名门之虚；末 Boss 鎏金公中州名宿·名震中州却虚有其表·独立真解「鎏金诀」chargeSkill=dropSkillManual 双用挂载 stage_11_05·「名≠本事」名门虚实之辨·求「实」Ch12 hook·发布上限抬至一流·圆熟 = 绝对层 26；一流门派绝学敌招 + 利器装备复用既有储备，零新增）；**2026-07-21 Ch12「名下之实」续一流段第 3 章·一流三章收官**（寻中州之实、见名下之实；末 Boss 无名客荒村野店无名真高手·绵里藏针实藏于内·独立真解「绵里藏针」chargeSkill=dropSkillManual 双用挂载 stage_12_05·「名≠本事·实至名归」收束守拙翁托付·承绝顶段 hook·发布上限抬至一流·登峰 = 绝对层 28；一流门派绝学敌招 + 利器装备复用既有储备，零新增）；**2026-07-22 Ch13「山外青山」绝顶段首章**（起脚往上、出中州向高处；末 Boss 候峰翁绝顶之上等人数十年的老者·守拙翁镜像倒置·独立真解「一览众山」chargeSkill=dropSkillManual 双用挂载 stage_13_05·「从看江湖到成为江湖」传承弧·主角从接符人变留符人·发布上限抬至绝顶·熟练 = 绝对层 31·cross-tier·releaseTier yiLiu→jueDing；绝顶江湖秘传敌招 + 重器装备复用既有储备，唯一新增 = 末 Boss 真解；shi_dang/yang_guan 补标 mount_deferred，jing_hong 挂 13_05 章末残页，ma_ta 挂塔 25 层，jin_gang/guan_shan 塔 20/15 层收编）；**2026-07-23 Ch14「山外来客」绝顶段第二章**（西凉马战宗师循名叩山、借绝顶一战；末 Boss 马战宗师·独立真解「十荡十决」收编挂载 stage_14_05（删 mount_deferred·[balance] mult 3600→4800 对齐绝顶真解档）·「成为江湖」第一课 = 接住循名而来的拳头·临行一句埋宗师段「阳关无故人」西凉霸主伏笔·发布上限抬至绝顶·圆熟 = 绝对层 33·within-tier·releaseTier 仍 jueDing；江湖秘传敌招（ult/fang 档）+ 重器装备复用既有储备，零新增招）；**2026-07-24 Ch15「关山一程」绝顶段收官章**（下山西行头一程、Ch4「西出阳关」旧路新走回旋，五程对称 Ch14 客上山五程；末 Boss 守关老将·镇阳关数十年的中原老将「借关一战」对称 Ch14 借山一战·独立真解「孤城闭」新写 chargeSkill=dropSkillManual 双用挂载 stage_15_05·佛门 fang 系明王拳三件套 stage_15_03 主线首用·绝顶三章真解三系各一（lingQiao/gangMeng/yinRou）收束·发布上限抬至绝顶·登峰 = 绝对层 35·within-tier·releaseTier 仍 jueDing·末 Boss 59500 守 60000 硬线头寸收官用尽、宗师段难度转机制层留议；江湖秘传敌招（ult/fang 档）+ 重器装备复用既有储备，唯一新增 = 末 Boss 真解）；**2026-07-24 Ch16「凉州词」宗师段首章**（出阳关入西凉头一程、西凉故人弧「旧路更远处」开篇；末 Boss 接关人·西凉门户关城霸主座下留关数十年·独立真解「铁马冰河」新写 chargeSkill=dropSkillManual 双用挂载 stage_16_05·黑石铜镜见镜不取 hook Ch18 霸主亲手相赠·发布上限抬至宗师·熟练 = 绝对层 38·cross-tier·releaseTier jueDing→zongShi；失传神功心法招三件套敌招换档（tier6 池已有、零新增敌招）+ 宝物装备复用既有储备，唯一新增 = 末 Boss 真解；月落无声挂 16_05 章末残页，夜雨十年灯补 mount_deferred 归 Ch17，feng_juan/yang_guan 仍 deferred 至 Ch17/18；难度走 cross-tier 层差+失传神功档，机制型 Boss 按段级拍板 6 留 Ch17/18 渐进）；**2026-07-26 Ch17「沙海纵深」宗师段第 2 章**（承 Ch16 章尾「下一程,沙海纵深」硬叙事锚;主题＝沙海里剑术不管用、天地才管用,兑现 Ch4 李寒「剑到了一处地方,就要听那处地方的风」;末 Boss 沙海领路人·霸主座下引路人·独立真解「平沙落雁」新写 chargeSkill=dropSkillManual 双用挂载 stage_17_05·风卷流沙删 mount_deferred 收编为 17_04 章中 Boss 掉落（[balance] mult 3200→4800·tier4 保收集向定位）·夜雨十年灯删 mount_deferred 挂 17_05 章末残页·**机制层首入主线**：17_05 单窗口 `vulnerability.outOfWindowDamageMult=0.20`（比照塔 floor30 同值宽松位,窗口外承伤 20%）+ 17_04 只配 chargeCounter 相位作破招前置教学,两级递进「先学打断蓄招→再学只有窗口能打」,cycleVulnerability 本章不配·发布上限抬至宗师·圆熟 = 绝对层 40·**within-tier**·releaseTier 仍 zongShi；失传神功 fang 防御变体敌招首次主线接线（17_03 阴柔 / 17_04 灵巧,tier6 池已有、零新增敌招）+ 宝物装备复用既有储备,唯一新增 = 末 Boss 真解；仅 yang_guan 仍 deferred 至 Ch18）；宗师以上境界/装备/心法仍留未来内容。
GDD.md:598:| 22-28 | 一流 |
GDD.md:599:| 29-35 | 绝顶 |
GDD.md:604:- **Boss 位 14 个**：每 tier 中点（4/11/18/25/32/39/46）小 Boss、tier 末层（7/14/21/28/35/42/49）大 Boss。塔顶 49 = 九霄魔尊（护法墙 + 脆弱窗机制门槛，§5.4 机制型例外条款）；32 = 绝顶剑魔（脆弱窗，血量-乘子联动校准，名义血刻意低于曲线、窗口外有效血远超）。
GDD.md:782:- **第二条主线**：承接前三章的后续剧情（Ch4～6）。当前发布版玩法数值统一在三流内，原一流～武圣标注只保留为历史创作强度记录；有效境界与掉落以 §8.1 和生产 YAML 为准。
```

<a id="q401"></a>
### Q401

```sh
sed -n 1,4p data/recruit_candidates.yaml
```

命中/输出行数：4；退出码：0。

```text
# 收徒候选 NPC 配置(P1.1 A1 师徒 E.1 · 1.0 路线图 P1.1 系统纵深)
# GDD §7.1「突破到一流可收徒」+ inheritance.unlock_rules.can_take_disciple_at: yiLiu
# 决策:audit doc `p1_1_a1_recruitment_audit_2026-05-21.md` 方案 3 + D2.b 3 NPC
#
```

<a id="q402"></a>
### Q402

```sh
sed -n 499,505p GDD.md
```

命中/输出行数：7；退出码：0。

```text
**解锁节奏**：

| 突破到 | 解锁内容 |
|--------|---------|
| 一流（结丹） | 收徒 |
| 绝顶（化神） | 徒弟可以收徒孙 |
| 飞升渡劫后 | 传位给大徒弟，前任成为**祖师爷**提供门派 buff |
```

<a id="q403"></a>
### Q403

```sh
sed -n 1565,1581p data/numbers.yaml
```

命中/输出行数：17；退出码：0。

```text
  # --- 解锁节奏（GDD §7.1）---
  #
  # ❗ 未消费（2026-08-07 N1 实测）：本块三字段 lib/ 零读取点
  #   （NumbersConfig 解析 inheritance 仅取 founder_ancestor_buff（numbers_config.dart:399）
  #   与 heritage_items（:404））。逐字段现状：
  #   · can_take_disciple_at / disciple_can_take_grand_disciple_at
  #     ——描述的是"按境界解锁收徒"，而实装的收徒是一次性剧情事件
  #       （recruitment_service.dart:47,79,172 走 SaveData.recruitmentOffered flag），
  #       **完全没有境界门禁**。设计与实装分叉，不是失修。
  #   · can_pass_legacy_at ——与活配置 ascension.unlock_triggers.required_realm.tier
  #       （本文件 :1830-1832，AscendService 经 numbers.ascension 消费，
  #        ascend_service.dart:60）**重复声明同一门槛**，且本处是死的那份。
  #       改本行不生效；要改飞升境界门槛请改 ascension 段。
  unlock_rules:
    can_take_disciple_at: yiLiu              # 突破到一流可收徒
    disciple_can_take_grand_disciple_at: jueDing  # 弟子突破到绝顶可收徒孙
    can_pass_legacy_at: wuSheng              # 武圣后传位（飞升渡劫）。2026-07-28 订正:旧注「Demo 不实现」已被推翻——多代飞升/真传位/遗物 transfer 在 P2.3+P5+ 早已完整实装,一直缺的只是 cap;发布上限 Ch19 抬至 45(武圣·熟练),Ch21 抬到 49 时飞升条件③(founder abs 49)首次可达。
```

<a id="q404"></a>
### Q404

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- disciple_can_take_grand_disciple_at lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:42:    (r"inheritance\.unlock_rules\.(can_take_disciple_at|disciple_can_take_grand_disciple_at)", "待拍板", "未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。", "can_take_disciple_at|徒孙|一流|绝顶", ["data/recruit_candidates.yaml", "GDD.md"], [("data/recruit_candidates.yaml", 1, 4), ("GDD.md", 499, 505), ("data/numbers.yaml", 1565, 1581)]),
```

<a id="q405"></a>
### Q405

```sh
rg -n --with-filename --no-heading --sort path -F -- disciple_can_take_grand_disciple_at lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:42:    (r"inheritance\.unlock_rules\.(can_take_disciple_at|disciple_can_take_grand_disciple_at)", "待拍板", "未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。", "can_take_disciple_at|徒孙|一流|绝顶", ["data/recruit_candidates.yaml", "GDD.md"], [("data/recruit_candidates.yaml", 1, 4), ("GDD.md", 499, 505), ("data/numbers.yaml", 1565, 1581)]),
```

<a id="q406"></a>
### Q406

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'inheritance\.unlock_rules\.disciple_can_take_grand_disciple_at|unlock_rules\.disciple_can_take_grand_disciple_at' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q407"></a>
### Q407

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- disciple_can_take_grand_disciple_at data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：3；退出码：0。

```text
data/numbers.yaml:1570:  #   · can_take_disciple_at / disciple_can_take_grand_disciple_at
data/numbers.yaml:1580:    disciple_can_take_grand_disciple_at: jueDing  # 弟子突破到绝顶可收徒孙
docs/handoff/phase5_master_disciple_spec_2026-05-20.md:19:| 绝顶 / 化神 | `disciple_can_take_grand_disciple_at: jueDing` | 未实装 | **新增** `LineageRole.grandDisciple` 枚举值 + `MasterRepository.unlockGrandDisciple()` + masters.yaml 扩 2 角色 |
```

<a id="q408"></a>
### Q408

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdisciple_can_take_grand_disciple_at -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
13ce2300f 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q409"></a>
### Q409

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sdisciple_can_take_grand_disciple_at -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q410"></a>
### Q410

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sdisciple_can_take_grand_disciple_at -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
```

<a id="q411"></a>
### Q411

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- can_pass_legacy_at lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:43:    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
```

<a id="q412"></a>
### Q412

```sh
rg -n --with-filename --no-heading --sort path -F -- can_pass_legacy_at lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:43:    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
```

<a id="q413"></a>
### Q413

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'inheritance\.unlock_rules\.can_pass_legacy_at|unlock_rules\.can_pass_legacy_at' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q414"></a>
### Q414

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- can_pass_legacy_at data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：3；退出码：0。

```text
data/numbers.yaml:1574:  #   · can_pass_legacy_at ——与活配置 ascension.unlock_triggers.required_realm.tier
data/numbers.yaml:1581:    can_pass_legacy_at: wuSheng              # 武圣后传位（飞升渡劫）。2026-07-28 订正:旧注「Demo 不实现」已被推翻——多代飞升/真传位/遗物 transfer 在 P2.3+P5+ 早已完整实装,一直缺的只是 cap;发布上限 Ch19 抬至 45(武圣·熟练),Ch21 抬到 49 时飞升条件③(founder abs 49)首次可达。
docs/handoff/phase5_master_disciple_spec_2026-05-20.md:20:| 武圣 / 飞升 | `can_pass_legacy_at: wuSheng` | 不实装(`§3`) | **新增** `AscendService` + `AncestorBuffService` + `enabled_when_alive: true` |
```

<a id="q415"></a>
### Q415

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scan_pass_legacy_at -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
13ce2300f 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q416"></a>
### Q416

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scan_pass_legacy_at -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q417"></a>
### Q417

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Scan_pass_legacy_at -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9 数值: N1 numbers.yaml 疑似未消费字段处置(4 段注释)+稀有度未实装 spec
```

<a id="q418"></a>
### Q418

```sh
rg -n --with-filename --no-heading --sort path -- 'can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention' data/numbers.yaml
```

命中/输出行数：7；退出码：0。

```text
data/numbers.yaml:834:    inheritance_retention: 0.7       # 传给徒弟保留 70%（鼓励"一柄剑用一辈子"）
data/numbers.yaml:872:    internal_force_max_bonus: 0.05   # 师承遗物自带内力上限 +5% buff
data/numbers.yaml:1574:  #   · can_pass_legacy_at ——与活配置 ascension.unlock_triggers.required_realm.tier
data/numbers.yaml:1576:  #        ascend_service.dart:60）**重复声明同一门槛**，且本处是死的那份。
data/numbers.yaml:1581:    can_pass_legacy_at: wuSheng              # 武圣后传位（飞升渡劫）。2026-07-28 订正:旧注「Demo 不实现」已被推翻——多代飞升/真传位/遗物 transfer 在 P2.3+P5+ 早已完整实装,一直缺的只是 cap;发布上限 Ch19 抬至 45(武圣·熟练),Ch21 抬到 49 时飞升条件③(founder abs 49)首次可达。
data/numbers.yaml:1595:    auto_buff_internal_force_max: 0.05       # 师承遗物自带 +5% 内力上限 buff
data/numbers.yaml:1596:    resonance_retention: 0.7                 # 共鸣度保留 70%
```

<a id="q419"></a>
### Q419

```sh
sed -n 1574,1577p data/numbers.yaml
```

命中/输出行数：4；退出码：0。

```text
  #   · can_pass_legacy_at ——与活配置 ascension.unlock_triggers.required_realm.tier
  #       （本文件 :1830-1832，AscendService 经 numbers.ascension 消费，
  #        ascend_service.dart:60）**重复声明同一门槛**，且本处是死的那份。
  #       改本行不生效；要改飞升境界门槛请改 ascension 段。
```

<a id="q420"></a>
### Q420

```sh
sed -n 1591,1600p data/numbers.yaml
```

命中/输出行数：10；退出码：0。

```text
  # Q4 同部位冲突:自动卸下原装入背包 + 新遗物入槽(sane default,不做装备分解违反 §5.1)
  heritage_items:
    pieces_per_generation_min: 1             # 每代师父传 1-2 件
    pieces_per_generation_max: 2
    auto_buff_internal_force_max: 0.05       # 师承遗物自带 +5% 内力上限 buff
    resonance_retention: 0.7                 # 共鸣度保留 70%
    transfer_trigger: "ascend_to_wusheng"    # v1.5:仅武圣飞升触发(P2.3 已实装)
    multi_disciple_allocation: "player_pick" # v1.5:玩家逐件选分配(P2.3 已实装)
    stack_across_generations: false          # v1.5:只取当代不累代叠加(derived_stats 按 instance count 不按 prev len · spec p5_lineage_full §Q4 加 R5.8 防回退测)
    conflict_slot_resolution: "auto_swap"    # v1.5:同部位自动 swap(P5+ 真实装 · AscendService.performAscend 副作用 4:disciple.equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包 · spec §Q3)
```

<a id="q421"></a>
### Q421

```sh
sed -n 404,437p lib/data/numbers_config.dart
```

命中/输出行数：34；退出码：0。

```text
      resonanceStages: _parseResonanceStages(
        equipment['resonance'] as Map<String, dynamic>,
      ),
      resonanceInheritanceRetention:
          ((equipment['resonance']
                      as Map<String, dynamic>)['inheritance_retention']
                  as num)
              .toDouble(),
      resonanceSeclusionBattleCountPerHour:
          ((equipment['resonance']
                      as Map<
                        String,
                        dynamic
                      >)['seclusion_battle_count_per_hour']
                  as num)
              .toInt(),
      lineageInternalForceMaxBonus:
          ((equipment['lineage_heritage']
                      as Map<String, dynamic>)['internal_force_max_bonus']
                  as num)
              .toDouble(),
      disposal: EquipmentDisposalConfig.fromYaml(
        equipment['disposal'] as Map<String, dynamic>,
      ),
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['founder_ancestor_buff']
                as Map<String, dynamic>?) ??
            const {},
      ),
      heritageItems: HeritageItems.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['heritage_items']
                as Map<String, dynamic>?) ??
            const {},
      ),
```

<a id="q422"></a>
### Q422

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- auto_buff_internal_force_max lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:43:    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
```

<a id="q423"></a>
### Q423

```sh
rg -n --with-filename --no-heading --sort path -F -- auto_buff_internal_force_max lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:43:    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
```

<a id="q424"></a>
### Q424

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'inheritance\.heritage_items\.auto_buff_internal_force_max|heritage_items\.auto_buff_internal_force_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q425"></a>
### Q425

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- auto_buff_internal_force_max data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1595:    auto_buff_internal_force_max: 0.05       # 师承遗物自带 +5% 内力上限 buff
docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md:41:  auto_buff_internal_force_max: 0.05       # ✅ 代码层已消费
```

<a id="q426"></a>
### Q426

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sauto_buff_internal_force_max -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q427"></a>
### Q427

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sauto_buff_internal_force_max -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q428"></a>
### Q428

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sauto_buff_internal_force_max -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q429"></a>
### Q429

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- resonance_retention lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:43:    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
```

<a id="q430"></a>
### Q430

```sh
rg -n --with-filename --no-heading --sort path -F -- resonance_retention lib test tool tools
```

命中/输出行数：1；退出码：0。

```text
tools/audit/numbers_unused_keys_review.py:43:    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
```

<a id="q431"></a>
### Q431

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'inheritance\.heritage_items\.resonance_retention|heritage_items\.resonance_retention' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q432"></a>
### Q432

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- resonance_retention data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：3；退出码：0。

```text
data/numbers.yaml:1596:    resonance_retention: 0.7                 # 共鸣度保留 70%
docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md:33:| 11 | 师承共鸣保留 70%(resonance_retention) | `numbers.yaml inheritance.heritage_items.resonance_retention: 0.7` + DispelService 等链路已落 | ✅ |
docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md:42:  resonance_retention: 0.7                 # ✅ 代码层已消费
```

<a id="q433"></a>
### Q433

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sresonance_retention -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q434"></a>
### Q434

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sresonance_retention -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q435"></a>
### Q435

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sresonance_retention -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q436"></a>
### Q436

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- effect_type lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q437"></a>
### Q437

```sh
rg -n --with-filename --no-heading --sort path -F -- effect_type lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q438"></a>
### Q438

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.yin_yang_he\.effect_type|effect_values\.yin_yang_he\.effect_type|yin_yang_he\.effect_type' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q439"></a>
### Q439

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- effect_type data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：5；退出码：0。

```text
data/numbers.yaml:1636:      effect_type: "all_attr_pct"
data/numbers.yaml:1641:      effect_type: "unlock_skill_crit"
data/numbers.yaml:1647:      effect_type: "internal_force_growth_pct"
data/numbers.yaml:1652:      effect_type: "reflect_pct"
data/numbers.yaml:1657:      effect_type: "crit_dmg_pct"
```

<a id="q440"></a>
### Q440

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Seffect_type -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q441"></a>
### Q441

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Seffect_type -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q442"></a>
### Q442

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Seffect_type -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q443"></a>
### Q443

```sh
rg -n --with-filename --no-heading --sort path -- '阴阳调和|丐帮传承|少林正宗|武当圆融|华山合璧|effectType|effectValue|multipliers' GDD.md data_schema.md data/synergies.yaml
```

命中/输出行数：30；退出码：0。

```text
GDD.md:278:| 阴阳调和 | 九阳 + 九阴 | 全属性 +20% |
GDD.md:279:| 丐帮传承 | 降龙十八掌 + 打狗棒法 | 解锁"亢龙有悔"暴击 |
GDD.md:280:| 少林正宗 | 易筋经 + 少林外功 | 内力增长 +30% |
GDD.md:281:| 武当圆融 | 太极拳 + 太极剑 | 反伤 15% |
GDD.md:282:| 华山合璧 | 紫霞神功 + 华山剑法 | 暴击伤害 +50% |
data_schema.md:1701:| name | String | ❌ | 组合名（如"阴阳调和"） |
data_schema.md:1704:| effectType | String | ❌ | 效果类型：`all_attr_pct` / `crit_dmg_pct` / `reflect_pct` / `unlock_skill_crit` |
data_schema.md:1705:| effectValue | double | ❌ | 效果数值 |
data_schema.md:1714:  final String effectType;
data_schema.md:1715:  final double effectValue;
data_schema.md:1721:**JSON 示例**（阴阳调和）：
data_schema.md:1725:  "name": "阴阳调和",
data_schema.md:1728:  "effectType": "all_attr_pct",
data_schema.md:1729:  "effectValue": 0.20,
data/synergies.yaml:28:  # ── 1. 阴阳调和:刚阳与阴柔相济,内息圆融(攻速防血 4 维中等 buff) ──────────
data/synergies.yaml:32:    name: 阴阳调和
data/synergies.yaml:38:    multipliers:
data/synergies.yaml:52:    multipliers:
data/synergies.yaml:63:    multipliers:
data/synergies.yaml:73:    multipliers:
data/synergies.yaml:85:    multipliers:
data/synergies.yaml:90:  # 与第 1「阴阳调和」(主刚辅阴 atk+spd+def+hp 4 维)互为反向,本组 def+hp 2 维
data/synergies.yaml:101:    multipliers:
data/synergies.yaml:115:    multipliers:
data/synergies.yaml:123:  # sameSchool > sameTier),避免被 synergy 1「阴阳调和」(gangMeng+yinRou
data/synergies.yaml:134:    multipliers:
data/synergies.yaml:152:    multipliers:
data/synergies.yaml:167:    multipliers:
data/synergies.yaml:183:    multipliers:
data/synergies.yaml:198:    multipliers:
```

<a id="q444"></a>
### Q444

```sh
sed -n 272,282p GDD.md
```

命中/输出行数：11；退出码：0。

```text
### 4.5 心法相生（5-8 个隐藏组合）

主修 + 辅修达到特定组合时，触发**隐藏彩蛋 buff**。Demo 阶段至少 5 个：

| 组合名 | 心法搭配 | 效果 |
|--------|---------|------|
| 阴阳调和 | 九阳 + 九阴 | 全属性 +20% |
| 丐帮传承 | 降龙十八掌 + 打狗棒法 | 解锁"亢龙有悔"暴击 |
| 少林正宗 | 易筋经 + 少林外功 | 内力增长 +30% |
| 武当圆融 | 太极拳 + 太极剑 | 反伤 15% |
| 华山合璧 | 紫霞神功 + 华山剑法 | 暴击伤害 +50% |
```

<a id="q445"></a>
### Q445

```sh
sed -n 1700,1705p data_schema.md
```

命中/输出行数：6；退出码：0。

```text
| id | String | ❌ | 唯一 id |
| name | String | ❌ | 组合名（如"阴阳调和"） |
| requiredMainTechniqueDefId | String | ❌ | 必需的主修心法 |
| requiredAssistTechniqueDefIds | List\<String\> | ❌ | 必需的辅修心法（任意一项满足即可） |
| effectType | String | ❌ | 效果类型：`all_attr_pct` / `crit_dmg_pct` / `reflect_pct` / `unlock_skill_crit` |
| effectValue | double | ❌ | 效果数值 |
```

<a id="q446"></a>
### Q446

```sh
sed -n 1623,1629p data/numbers.yaml
```

命中/输出行数：7；退出码：0。

```text
# 10. 心法相生组合（GDD §4.5）
# =============================================================================
# 5 个隐藏组合的具体效果数值。组合判定逻辑见 SynergyDef，本段只给数值。
#
# ⚠️ UNUSED（2026-07-03 六维审查批次3 证实）：本 `synergies:` 整段未被 NumbersConfig.fromYaml
# 解析，lib/ 无消费。相生组合真实数据源是独立文件 data/synergies.yaml（12 条目，multipliers
# 格式，game_repository.dart:341 解析）。此处 5 条 effect_values 为历史残留，勿在此维护；删除需拍板。
```

<a id="q447"></a>
### Q447

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- effect_value lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q448"></a>
### Q448

```sh
rg -n --with-filename --no-heading --sort path -F -- effect_value lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q449"></a>
### Q449

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.yin_yang_he\.effect_value|effect_values\.yin_yang_he\.effect_value|yin_yang_he\.effect_value' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q450"></a>
### Q450

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- effect_value data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：9；退出码：0。

```text
data/numbers.yaml:1629:# 格式，game_repository.dart:341 解析）。此处 5 条 effect_values 为历史残留，勿在此维护；删除需拍板。
data/numbers.yaml:1633:  effect_values:
data/numbers.yaml:1637:      effect_value: 0.20
data/numbers.yaml:1648:      effect_value: 0.30
data/numbers.yaml:1653:      effect_value: 0.15
data/numbers.yaml:1658:      effect_value: 0.50
docs/audit/full_project_review_2026-07-02.md:42:- **P1-10 numbers.yaml 两段 0 消费死配置**:`tower` 段(:1258 起,真值在 towers.yaml)与 `synergies.effect_values`(:1380 起,真值在 synergies.yaml),均无 unused 头注,双源 drift 风险,违反「配置而不消费必须标注或砍」约定。
docs/dispatch/reports/2026-08-07_PI1_yaml_consumption.md:52:| data/numbers.yaml:1444 | `effect_values` | 0 | synergies 段;1438-1440 自证 UNUSED:「真实数据源是 data/synergies.yaml…此处 5 条为历史残留」 |
docs/dispatch/reports/2026-08-07_Q1_field_verify.md:42:| 11 | `effect_values` | numbers.yaml:1444(synergies) | 真未消费 | `synergies:` 段不进解析;真实数据源 data/synergies.yaml(`game_repository.dart:375-379`);yaml :1438-1440 自证历史残留 |
```

<a id="q451"></a>
### Q451

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Seffect_value -- lib data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
93a8687c4 清理批次2/3零引用资产与死配置 + ExactAssetImage 迁 WuxiaImage
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q452"></a>
### Q452

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Seffect_value -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q453"></a>
### Q453

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Seffect_value -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
93a8687c4a48a410717346c36fda2358aeba81f2 清理批次2/3零引用资产与死配置 + ExactAssetImage 迁 WuxiaImage
```

<a id="q454"></a>
### Q454

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.gai_bang_chuan_cheng\.effect_type|effect_values\.gai_bang_chuan_cheng\.effect_type|gai_bang_chuan_cheng\.effect_type' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q455"></a>
### Q455

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- target_skill_id lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q456"></a>
### Q456

```sh
rg -n --with-filename --no-heading --sort path -F -- target_skill_id lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q457"></a>
### Q457

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.gai_bang_chuan_cheng\.target_skill_id|effect_values\.gai_bang_chuan_cheng\.target_skill_id|gai_bang_chuan_cheng\.target_skill_id' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q458"></a>
### Q458

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- target_skill_id data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：1；退出码：0。

```text
data/numbers.yaml:1642:      target_skill_id: "skill_kang_long_you_hui"
```

<a id="q459"></a>
### Q459

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Starget_skill_id -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q460"></a>
### Q460

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Starget_skill_id -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q461"></a>
### Q461

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Starget_skill_id -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q462"></a>
### Q462

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.shao_lin_zheng_zong\.effect_type|effect_values\.shao_lin_zheng_zong\.effect_type|shao_lin_zheng_zong\.effect_type' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q463"></a>
### Q463

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.shao_lin_zheng_zong\.effect_value|effect_values\.shao_lin_zheng_zong\.effect_value|shao_lin_zheng_zong\.effect_value' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q464"></a>
### Q464

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.wu_dang_yuan_rong\.effect_type|effect_values\.wu_dang_yuan_rong\.effect_type|wu_dang_yuan_rong\.effect_type' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q465"></a>
### Q465

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.wu_dang_yuan_rong\.effect_value|effect_values\.wu_dang_yuan_rong\.effect_value|wu_dang_yuan_rong\.effect_value' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q466"></a>
### Q466

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.hua_shan_he_bi\.effect_type|effect_values\.hua_shan_he_bi\.effect_type|hua_shan_he_bi\.effect_type' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q467"></a>
### Q467

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'synergies\.effect_values\.hua_shan_he_bi\.effect_value|effect_values\.hua_shan_he_bi\.effect_value|hua_shan_he_bi\.effect_value' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q468"></a>
### Q468

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- cultivation_multiplier lib test tool tools
```

命中/输出行数：6；退出码：0。

```text
test/data/inner_demon_dead_config_test.dart:18:      expect(numbers, isNot(contains('main_cultivation_multiplier:')));
test/features/inner_demon/domain/inner_demon_def_test.dart:9:          'failure_penalty': {'main_cultivation_multiplier': 0.90},
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:173:                                   "-Scultivation_multiplier", "--", "lib"])
tools/audit/numbers_unused_keys_review.py:347:    lines += ["", "唯一非零 lib 历史末段检索为 cultivation_multiplier（3 个提交），实际 patch 都是心魔 main_cultivation_multiplier / sub_cultivation_multiplier 子串，与战例无关：" + ref(result["historical_substrings"]) + "。",
```

<a id="q469"></a>
### Q469

```sh
rg -n --with-filename --no-heading --sort path -F -- cultivation_multiplier lib test tool tools
```

命中/输出行数：6；退出码：0。

```text
test/data/inner_demon_dead_config_test.dart:18:      expect(numbers, isNot(contains('main_cultivation_multiplier:')));
test/features/inner_demon/domain/inner_demon_def_test.dart:9:          'failure_penalty': {'main_cultivation_multiplier': 0.90},
tools/audit/numbers_key_usage.py:346:    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
tools/audit/numbers_unused_keys_review.py:173:                                   "-Scultivation_multiplier", "--", "lib"])
tools/audit/numbers_unused_keys_review.py:347:    lines += ["", "唯一非零 lib 历史末段检索为 cultivation_multiplier（3 个提交），实际 patch 都是心魔 main_cultivation_multiplier / sub_cultivation_multiplier 子串，与战例无关：" + ref(result["historical_substrings"]) + "。",
```

<a id="q470"></a>
### Q470

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_a\.attacker\.cultivation_multiplier|example_a\.attacker\.cultivation_multiplier|attacker\.cultivation_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q471"></a>
### Q471

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- cultivation_multiplier data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：17；退出码：0。

```text
data/numbers.yaml:113:    apply_cultivation_multiplier: true   # 应用心法修炼度（1.0~3.0）
data/numbers.yaml:1682:      cultivation_multiplier: 1.00       # 初窥
data/numbers.yaml:1701:      cultivation_multiplier: 1.75       # 圆满
data/numbers.yaml:1720:      cultivation_multiplier: 1.30       # 中成
data/numbers.yaml:1740:      cultivation_multiplier: 1.75       # 圆满
data/numbers.yaml:1760:      cultivation_multiplier: 3.00       # 极境
docs/audit/phase2_g0_decision_packet_2026-08-23.md:270:- 当前参数为 `main_cultivation_multiplier: 0.90`：`data/numbers.yaml:1746-1747`。
docs/audit/phase2_g1_production_batch1_2026-08-23.md:21:- C17B 初版要求 `main_cultivation_multiplier` 必填，联合测试发现会破坏只配置脆弱窗口的兼容 fixture；主审恢复缺省 `0.90`，并保留五个退役 key 的 fail-fast。
docs/audit/phase2_m0_implementation_gap_evidence_2026-08-23.md:208:   - 另三个自标 UNUSED：`sub_cultivation_multiplier: 1.00` / `debuff_id: inner_demon_residue` / `debuff_clear_via_retreat_hours: 8`
docs/dispatch/phase0a_overhaul/task_registry.yaml:374:      - preserve main_cultivation_multiplier at 0.90
docs/dispatch/reports/2026-08-07_Q2_config_bypass.md:154:| 5 | `inner_demon.failure_penalty.sub_cultivation_multiplier` | numbers.yaml:1701 | 同上 | 代码内自标 UNUSED;只扣主修(`mainCultivationMultiplier` 被消费,:183) |
docs/dispatch/reports/2026-08-08_P4_audit_scripts.md:139:| `inner_demon…sub_cultivation_multiplier` | :1660 | :1701 |
docs/handoff/p2_x_inner_demon_spec_2026-05-22.md:53:    main_cultivation_multiplier: 0.90
docs/handoff/p2_x_inner_demon_spec_2026-05-22.md:54:    sub_cultivation_multiplier: 1.0
docs/superpowers/plans/2026-08-23-p2-g1-c17b-inner-demon-legacy-cleanup.md:5:在 INNER-DEMON-FAILURE-CORE-01 已冻结后，清除 5 个零生产读方 legacy 字段：`internal_force_multiplier`、`internal_force_floor_pct`、`sub_cultivation_multiplier`、`debuff_id`、`debuff_clear_via_retreat_hours`。保留并校验 `main_cultivation_multiplier`，当前 safe_default 仍为 `0.90`；不拍板 `INNER-DEMON-CULTIVATION-01`。
docs/superpowers/plans/2026-08-23-p2-g1-production-batch1.md:37:- 主审修正：联合回归发现 C17B 曾把缺省 `main_cultivation_multiplier` 改为报错；已恢复缺省 0.90，同时继续拒绝五个退役 key。
docs/superpowers/plans/2026-08-24-p2-m5-batch1-inner-demon-cultivation-closeout.md:19:1. 删除 `failure_penalty.main_cultivation_multiplier` 的生产配置与类型入口。
```

<a id="q472"></a>
### Q472

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scultivation_multiplier -- lib data/numbers.yaml
```

命中/输出行数：5；退出码：0。

```text
c66e983b1 [schema] 移除心魔主修修炼度失败惩罚
f11183e40 清理心魔失败旧惩罚字段
4c17119d7 feat(p2.2 心魔 Batch 2.2.A): InnerDemonDef + InnerDemonService.isLayerLocked + advancement_service hook
d28e16ef8 feat(p2.2 心魔 Batch 2.1) [schema]: enums 扩 2 项 + numbers.yaml inner_demon 段 + stages.yaml 7 entries 占位
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q473"></a>
### Q473

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scultivation_multiplier -- lib
```

命中/输出行数：3；退出码：0。

```text
c66e983b1 [schema] 移除心魔主修修炼度失败惩罚
f11183e40 清理心魔失败旧惩罚字段
4c17119d7 feat(p2.2 心魔 Batch 2.2.A): InnerDemonDef + InnerDemonService.isLayerLocked + advancement_service hook
```

<a id="q474"></a>
### Q474

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Scultivation_multiplier -- data/numbers.yaml
```

命中/输出行数：4；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
d28e16ef8d64813e80c8268633ce48db5d269360 feat(p2.2 心魔 Batch 2.1) [schema]: enums 扩 2 项 + numbers.yaml inner_demon 段 + stages.yaml 7 entries 占位
f11183e40dc0ec2e2d38f17310f4a54c81f9495a 清理心魔失败旧惩罚字段
c66e983b16dac56b560cc375161580ba229d026b [schema] 移除心魔主修修炼度失败惩罚
```

<a id="q475"></a>
### Q475

```sh
rg -n --with-filename --no-heading --sort path -- 'validation_examples|战例|纯文档' data/numbers.yaml docs/_archive/phase1_tasks.md
```

命中/输出行数：23；退出码：0。

```text
data/numbers.yaml:22:# 战例验证（二流·圆熟同境界普通攻击对决）：
data/numbers.yaml:31:  # ⚠ 纯文档（2026-08-07 N1 处置）：NumbersConfig.fromYaml 只取 meta['version']
data/numbers.yaml:106:    skill_multiplier_added: true     # ⚠ 纯文档(审计 D7):NumbersConfig 不解析;招式倍率"作为加项"已硬编码在 damage_calculator
data/numbers.yaml:1661:# 11. 战例验证
data/numbers.yaml:1663:# 用具体战例反向验证上述数值是否合理。如果改动 combat 段的系数，
data/numbers.yaml:1664:# 务必重新跑一遍这些战例确认未突破 GDD §5.2 红线。
data/numbers.yaml:1666:# ⚠ 纯文档（2026-08-07 N1 处置）：本段 example_a..e 不进 NumbersConfig.fromYaml
data/numbers.yaml:1667:#   解析（无 y['validation_examples'] 取值点），lib/data/validation/ 下的红线校验器
data/numbers.yaml:1668:#   校验的是已解析的配置对象，不读本段战例。test/combat/damage_calculator_test.dart
data/numbers.yaml:1670:#   本段价值在于人工核对公式，改 combat 系数后请手工重算这些战例。
data/numbers.yaml:1671:validation_examples:
data/numbers.yaml:1673:  # --- 战例 A：学徒新手关 ---
data/numbers.yaml:1692:  # --- 战例 B：二流圆熟同境界对决 ---
data/numbers.yaml:1711:  # --- 战例 C：三流挑战二流（境界差吃亏）---
data/numbers.yaml:1731:  # --- 战例 D：一流大招暴击 + 流派克制 ---
data/numbers.yaml:1750:  # --- 战例 E：武圣 vs 武圣（终极对决）---
data/numbers.yaml:1767:    note: "本战例数据用于压力测试，确保武圣境界数值不崩盘"
docs/_archive/phase1_tasks.md:21:   - 每次改公式后跑 numbers.yaml §11 的 5 个 validation_examples 校验
docs/_archive/phase1_tasks.md:506:- [ ] 单元测试对照 numbers.yaml §11 五个 validation_examples 的 HP 数字，**误差 ≤ 5%**（浮点精度）
docs/_archive/phase1_tasks.md:575:- [ ] 单元测试覆盖 numbers.yaml §11 五个战例（A/B/C/D/E），每个的 `calculated_damage` 应当与代码计算结果**误差 ≤ 5%**（浮点 + roll 随机性，固定 seed 后一致）
docs/_archive/phase1_tasks.md:576:- [ ] 武圣 vs 武圣战例 E，最终伤害 ≤ 100000（公式真实值 ~52000，留 2× buffer 防数值崩盘；实际是否一击致死取决于守方血量，与本伤害上限无关）
docs/_archive/phase1_tasks.md:948:   - 数值校验（5 个 validation_examples 实测 vs 预期对照表）
docs/_archive/phase1_tasks.md:1012:- [ ] **G3** 跑 numbers.yaml §11 的 5 个 validation_examples，实测伤害与预期 calculated_damage 误差 ≤ 5%
```

<a id="q476"></a>
### Q476

```sh
sed -n 1661,1671p data/numbers.yaml
```

命中/输出行数：11；退出码：0。

```text
# 11. 战例验证
# =============================================================================
# 用具体战例反向验证上述数值是否合理。如果改动 combat 段的系数，
# 务必重新跑一遍这些战例确认未突破 GDD §5.2 红线。

# ⚠ 纯文档（2026-08-07 N1 处置）：本段 example_a..e 不进 NumbersConfig.fromYaml
#   解析（无 y['validation_examples'] 取值点），lib/data/validation/ 下的红线校验器
#   校验的是已解析的配置对象，不读本段战例。test/combat/damage_calculator_test.dart
#   的对照值为测试内手写，非从本段加载 —— 改本段数字不会让任何测试变红。
#   本段价值在于人工核对公式，改 combat 系数后请手工重算这些战例。
validation_examples:
```

<a id="q477"></a>
### Q477

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- school_counter lib test tool tools
```

命中/输出行数：8；退出码：0。

```text
tools/audit/audit_anchors.py:129:        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.pierces_defense",
tools/audit/audit_anchors.py:135:        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.pierces_critical",
tools/audit/audit_anchors.py:141:        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.follows_main_hit",
tools/audit/audit_anchors.py:147:        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.pierces_defense",
tools/audit/audit_anchors.py:153:        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.stack_rule",
tools/audit/audit_anchors.py:159:        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.follows_main_hit",
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q478"></a>
### Q478

```sh
rg -n --with-filename --no-heading --sort path -F -- school_counter lib test tool tools
```

命中/输出行数：8；退出码：0。

```text
tools/audit/audit_anchors.py:129:        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.pierces_defense",
tools/audit/audit_anchors.py:135:        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.pierces_critical",
tools/audit/audit_anchors.py:141:        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.follows_main_hit",
tools/audit/audit_anchors.py:147:        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.pierces_defense",
tools/audit/audit_anchors.py:153:        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.stack_rule",
tools/audit/audit_anchors.py:159:        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.follows_main_hit",
tools/audit/numbers_key_usage.py:347:                     "apply_school_counter", "new_owner_retention", "daily_attempts",
tools/audit/numbers_key_usage.py:450:              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
```

<a id="q479"></a>
### Q479

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_a\.attacker\.school_counter|example_a\.attacker\.school_counter|attacker\.school_counter' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q480"></a>
### Q480

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- school_counter data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：11；退出码：0。

```text
data/numbers.yaml:114:    apply_school_counter: true           # 应用流派克制（0.75/1.0/1.25）
data/numbers.yaml:1683:      school_counter: 1.00               # 中性
data/numbers.yaml:1702:      school_counter: 1.00
data/numbers.yaml:1721:      school_counter: 1.00
data/numbers.yaml:1741:      school_counter: 1.25               # 刚猛克阴柔
data/numbers.yaml:1761:      school_counter: 1.00
docs/dispatch/reports/2026-08-07_Q2_config_bypass.md:128:### P2. `combat.school_counter.gang_meng_quake` 三语义布尔 —— 震伤语义结构性写死
docs/dispatch/reports/2026-08-07_Q2_config_bypass.md:135:### P3. `combat.school_counter.yin_rou_internal_injury` 三标志 —— 内伤叠加/穿透写死
docs/handoff/p1_42_phase2_p1z_codex_spec.md:79:| 4 | codex_school_counter | 三流派相克 | schoolCounter | 刚猛/灵巧/阴柔克制环(0.75/1.0/1.25)|
docs/handoff/week15_section12_7_school_extra_effects_2026-05-16.md:75:| `test/data/school_counter_v14_config_test.dart` | **新建** +3 红线 test(`gang_meng_quake` 4 字段值锁 / `yin_rou_internal_injury` 5 字段值锁 / `zhengWu` 3 字段值锁)|
docs/handoff/week15_section12_7_school_extra_effects_2026-05-16.md:186:`test/data/school_counter_v14_config_test.dart` 是「决议落地红线」类型:不验代码逻辑,只验 numbers.yaml 加载后字段值 = §12.1 #7 决议。改 yaml 数值需要同步改 test + CLAUDE.md + PROGRESS,**三方互锁防漂移**。沿 `feedback_red_line_test_semantics` 但加了"v1.x 决议锁"维度。
```

<a id="q481"></a>
### Q481

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sschool_counter -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q482"></a>
### Q482

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sschool_counter -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q483"></a>
### Q483

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sschool_counter -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q484"></a>
### Q484

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- calculated_damage lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
test/combat/damage_calculator_test.dart:18:///    误差 ≤ 5%（A/B/C/D，战例 E 无 calculated_damage 字段，单独压力测试）。
test/combat/damage_calculator_test.dart:105:      // yaml 战例 E 无 calculated_damage 字段，公式真实值 ~52416。
```

<a id="q485"></a>
### Q485

```sh
rg -n --with-filename --no-heading --sort path -F -- calculated_damage lib test tool tools
```

命中/输出行数：2；退出码：0。

```text
test/combat/damage_calculator_test.dart:18:///    误差 ≤ 5%（A/B/C/D，战例 E 无 calculated_damage 字段，单独压力测试）。
test/combat/damage_calculator_test.dart:105:      // yaml 战例 E 无 calculated_damage 字段，公式真实值 ~52416。
```

<a id="q486"></a>
### Q486

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_a\.calculated_damage|example_a\.calculated_damage' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q487"></a>
### Q487

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- calculated_damage data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：7；退出码：0。

```text
data/numbers.yaml:1689:    calculated_damage: "(600*0.4 + 130*1.0 + 500) * 1.0 * 1.0 * 1.0 * (1-0.05) * 1.0 = 826"
data/numbers.yaml:1708:    calculated_damage: "(3000*0.4 + 580 + 1500) * 1.75 * 1.0 * 1.0 * 0.85 * 1.0 = 4889"
data/numbers.yaml:1728:    calculated_damage: "(2000*0.4 + 280 + 1500) * 1.30 * 1.0 * 1.0 * 0.85 * 0.7 = 1972"
data/numbers.yaml:1747:    calculated_damage: "(5000*0.4 + 600 + 5500) * 1.75 * 1.25 * 2.0 * 0.80 * 1.0 = 28525"
docs/_archive/phase1_tasks.md:575:- [ ] 单元测试覆盖 numbers.yaml §11 五个战例（A/B/C/D/E），每个的 `calculated_damage` 应当与代码计算结果**误差 ≤ 5%**（浮点 + roll 随机性，固定 seed 后一致）
docs/_archive/phase1_tasks.md:1012:- [ ] **G3** 跑 numbers.yaml §11 的 5 个 validation_examples，实测伤害与预期 calculated_damage 误差 ≤ 5%
docs/dispatch/reports/2026-08-07_Q1_field_verify.md:47:| 16 | `example_e` | numbers.yaml(validation_examples) | 真未消费 | 同 example_a(战例 E 无 calculated_damage,test 单列压力测试) |
```

<a id="q488"></a>
### Q488

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scalculated_damage -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q489"></a>
### Q489

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Scalculated_damage -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q490"></a>
### Q490

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Scalculated_damage -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q491"></a>
### Q491

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- expected_outcome lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q492"></a>
### Q492

```sh
rg -n --with-filename --no-heading --sort path -F -- expected_outcome lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q493"></a>
### Q493

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_a\.expected_outcome|example_a\.expected_outcome' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q494"></a>
### Q494

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- expected_outcome data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：5；退出码：0。

```text
data/numbers.yaml:1690:    expected_outcome: "约 4 击致死，节奏适合新手期教学战斗 ✓"
data/numbers.yaml:1709:    expected_outcome: "在 2000-8000 红线内 ✓；约 2 击致死，强力技能节奏合理"
data/numbers.yaml:1729:    expected_outcome: "勉强达到普通伤害下限 2000；约 4 击致死，三流挑战二流确实吃力 ✓"
data/numbers.yaml:1748:    expected_outcome: "破万达成（28525），符合 GDD §5.2 大招暴击'上万'目标 ✓；一击秒杀"
data/numbers.yaml:1768:    expected_outcome: "约 19500 / 19500 几乎一击致死，符合武圣对决'电光石火'氛围 ✓；血量未超 20000 红线 ✓"
```

<a id="q495"></a>
### Q495

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sexpected_outcome -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q496"></a>
### Q496

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sexpected_outcome -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q497"></a>
### Q497

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sexpected_outcome -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q498"></a>
### Q498

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_b\.attacker\.cultivation_multiplier|example_b\.attacker\.cultivation_multiplier|attacker\.cultivation_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q499"></a>
### Q499

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_b\.attacker\.school_counter|example_b\.attacker\.school_counter|attacker\.school_counter' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q500"></a>
### Q500

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_b\.calculated_damage|example_b\.calculated_damage' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q501"></a>
### Q501

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_b\.expected_outcome|example_b\.expected_outcome' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q502"></a>
### Q502

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_c\.attacker\.cultivation_multiplier|example_c\.attacker\.cultivation_multiplier|attacker\.cultivation_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q503"></a>
### Q503

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_c\.attacker\.school_counter|example_c\.attacker\.school_counter|attacker\.school_counter' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q504"></a>
### Q504

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- realm_diff_modifier lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q505"></a>
### Q505

```sh
rg -n --with-filename --no-heading --sort path -F -- realm_diff_modifier lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q506"></a>
### Q506

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_c\.attacker\.realm_diff_modifier|example_c\.attacker\.realm_diff_modifier|attacker\.realm_diff_modifier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q507"></a>
### Q507

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- realm_diff_modifier data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：2；退出码：0。

```text
data/numbers.yaml:1723:      realm_diff_modifier: 0.7           # 低境界打高境界（守方修正）
docs/audit/night_b_governance_recovery_2026-09-17.md:47:- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
```

<a id="q508"></a>
### Q508

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srealm_diff_modifier -- lib data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q509"></a>
### Q509

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Srealm_diff_modifier -- lib
```

命中/输出行数：0；退出码：0。

```text
（无输出）
```

<a id="q510"></a>
### Q510

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Srealm_diff_modifier -- data/numbers.yaml
```

命中/输出行数：1；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
```

<a id="q511"></a>
### Q511

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_c\.calculated_damage|example_c\.calculated_damage' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q512"></a>
### Q512

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_c\.expected_outcome|example_c\.expected_outcome' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q513"></a>
### Q513

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_d\.attacker\.cultivation_multiplier|example_d\.attacker\.cultivation_multiplier|attacker\.cultivation_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q514"></a>
### Q514

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_d\.attacker\.school_counter|example_d\.attacker\.school_counter|attacker\.school_counter' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q515"></a>
### Q515

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_d\.calculated_damage|example_d\.calculated_damage' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q516"></a>
### Q516

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_d\.expected_outcome|example_d\.expected_outcome' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q517"></a>
### Q517

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_e\.attacker\.cultivation_multiplier|example_e\.attacker\.cultivation_multiplier|attacker\.cultivation_multiplier' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q518"></a>
### Q518

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_e\.attacker\.school_counter|example_e\.attacker\.school_counter|attacker\.school_counter' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q519"></a>
### Q519

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'validation_examples\.example_e\.expected_outcome|example_e\.expected_outcome' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q520"></a>
### Q520

```sh
rg -n --with-filename --no-heading --sort path -F -- attack_max lib
```

命中/输出行数：2；退出码：0。

```text
lib/data/numbers_config.dart:1934:          (y['equipment_base_attack_max'] as num?)?.toInt() ??
lib/data/numbers_config.dart:1935:          _missingRequiredValue('combat.red_lines.equipment_base_attack_max'),
```

<a id="q521"></a>
### Q521

```sh
sed -n 1928,1938p lib/data/numbers_config.dart
```

命中/输出行数：11；退出码：0。

```text
          (y['internal_force_max'] as num?)?.toInt() ??
          _missingRequiredValue('combat.red_lines.internal_force_max'),
      bossHpMax:
          (y['boss_hp_max'] as num?)?.toInt() ??
          _missingRequiredValue('combat.red_lines.boss_hp_max'),
      equipmentBaseAttackMax:
          (y['equipment_base_attack_max'] as num?)?.toInt() ??
          _missingRequiredValue('combat.red_lines.equipment_base_attack_max'),
      skillPowerMultiplierMax:
          (y['skill_power_multiplier_max'] as num?)?.toInt() ??
          _missingRequiredValue('combat.red_lines.skill_power_multiplier_max'),
```

<a id="q522"></a>
### Q522

```sh
rg -n --with-filename --no-heading --sort path -F --glob '*.dart' --glob '*.py' --glob '*.sh' -- attack_max lib test tool tools
```

命中/输出行数：7；退出码：0。

```text
lib/data/numbers_config.dart:1934:          (y['equipment_base_attack_max'] as num?)?.toInt() ??
lib/data/numbers_config.dart:1935:          _missingRequiredValue('combat.red_lines.equipment_base_attack_max'),
test/data/numbers_config_red_lines_test.dart:19:        'equipment_base_attack_max': 2000,
test/data/numbers_config_red_lines_test.dart:40:        'equipment_base_attack_max': 2000,
test/features/equipment/application/equipment_factory_test.dart:121:  // 3. armor slot：attack_min=attack_max=0 时返回恒 0
tools/audit/numbers_unused_keys_review.py:25:POOL_PATHS = {f"equipment.tiers[].{slot}.attack_max" for slot in ("weapon", "armor", "accessory")}
tools/audit/numbers_unused_keys_review.py:250:        pool_evidence = [ev.rg("attack_max", ["lib"], fixed=True), ev.sed(NC, 1928, 1938)]
```

<a id="q523"></a>
### Q523

```sh
rg -n --with-filename --no-heading --sort path -F -- attack_max lib test tool tools
```

命中/输出行数：7；退出码：0。

```text
lib/data/numbers_config.dart:1934:          (y['equipment_base_attack_max'] as num?)?.toInt() ??
lib/data/numbers_config.dart:1935:          _missingRequiredValue('combat.red_lines.equipment_base_attack_max'),
test/data/numbers_config_red_lines_test.dart:19:        'equipment_base_attack_max': 2000,
test/data/numbers_config_red_lines_test.dart:40:        'equipment_base_attack_max': 2000,
test/features/equipment/application/equipment_factory_test.dart:121:  // 3. armor slot：attack_min=attack_max=0 时返回恒 0
tools/audit/numbers_unused_keys_review.py:25:POOL_PATHS = {f"equipment.tiers[].{slot}.attack_max" for slot in ("weapon", "armor", "accessory")}
tools/audit/numbers_unused_keys_review.py:250:        pool_evidence = [ev.rg("attack_max", ["lib"], fixed=True), ev.sed(NC, 1928, 1938)]
```

<a id="q524"></a>
### Q524

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.weapon\.attack_max|tiers\.weapon\.attack_max|weapon\.attack_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q525"></a>
### Q525

```sh
rg -n --with-filename --no-heading --sort path -F --glob '!docs/audit/numbers_yaml_unused_keys*' -- attack_max data GDD.md CLAUDE.md data_schema.md docs
```

命中/输出行数：22；退出码：0。

```text
data/numbers.yaml:174:    equipment_base_attack_max: 2000  # 装备基础攻击红线（§5.4，配置基础表值，不含强化/共鸣/开锋派生）
data/numbers.yaml:682:      weapon:    {attack_min: 100, attack_max: 150, hp_min: 0,    hp_max: 0,    speed_min: 0,  speed_max: 10}
data/numbers.yaml:683:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 100,  hp_max: 200,  speed_min: 0,  speed_max: 5}
data/numbers.yaml:684:      accessory: {attack_min: 20,  attack_max: 40,  hp_min: 50,   hp_max: 100,  speed_min: 0,  speed_max: 8}
data/numbers.yaml:689:      weapon:    {attack_min: 180, attack_max: 280, hp_min: 0,    hp_max: 50,   speed_min: 5,  speed_max: 20}
data/numbers.yaml:690:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 250,  hp_max: 450,  speed_min: 0,  speed_max: 10}
data/numbers.yaml:691:      accessory: {attack_min: 50,  attack_max: 90,  hp_min: 100,  hp_max: 200,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:696:      weapon:    {attack_min: 320, attack_max: 450, hp_min: 0,    hp_max: 100,  speed_min: 10, speed_max: 30}
data/numbers.yaml:697:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 450,  hp_max: 750,  speed_min: 5,  speed_max: 15}
data/numbers.yaml:698:      accessory: {attack_min: 100, attack_max: 160, hp_min: 200,  hp_max: 350,  speed_min: 10, speed_max: 25}
data/numbers.yaml:703:      weapon:    {attack_min: 480, attack_max: 650, hp_min: 0,    hp_max: 150,  speed_min: 20, speed_max: 45}
data/numbers.yaml:704:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 700,  hp_max: 1100, speed_min: 10, speed_max: 25}
data/numbers.yaml:705:      accessory: {attack_min: 180, attack_max: 280, hp_min: 350,  hp_max: 550,  speed_min: 20, speed_max: 35}
data/numbers.yaml:710:      weapon:    {attack_min: 700, attack_max: 950, hp_min: 50,   hp_max: 250,  speed_min: 30, speed_max: 60}
data/numbers.yaml:711:      armor:     {attack_min: 0,   attack_max: 0,   hp_min: 1100, hp_max: 1600, speed_min: 15, speed_max: 35}
data/numbers.yaml:712:      accessory: {attack_min: 280, attack_max: 420, hp_min: 550,  hp_max: 850,  speed_min: 30, speed_max: 50}
data/numbers.yaml:719:      weapon:    {attack_min: 1000, attack_max: 1400, hp_min: 100, hp_max: 400, speed_min: 45, speed_max: 75}
data/numbers.yaml:720:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1400, hp_max: 2000, speed_min: 25, speed_max: 50}
data/numbers.yaml:721:      accessory: {attack_min: 420,  attack_max: 600,  hp_min: 750,  hp_max: 1100, speed_min: 45, speed_max: 70}
data/numbers.yaml:728:      weapon:    {attack_min: 1500, attack_max: 2000, hp_min: 150, hp_max: 350, speed_min: 65, speed_max: 100}
data/numbers.yaml:729:      armor:     {attack_min: 0,    attack_max: 0,    hp_min: 1750, hp_max: 2300, speed_min: 40, speed_max: 70}
data/numbers.yaml:730:      accessory: {attack_min: 600,  attack_max: 850,  hp_min: 1000, hp_max: 1400, speed_min: 65, speed_max: 95}
```

<a id="q526"></a>
### Q526

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sattack_max -- lib data/numbers.yaml
```

命中/输出行数：3；退出码：0。

```text
4b18c4c67 收口数值红线缺项为立即报错并补逐键守卫
7e8849de4 feat(debug): add redline audit view
fb99985ae [T01] 项目初始化与依赖配置
```

<a id="q527"></a>
### Q527

```sh
git log --oneline c64b165938d948a24ab64c7c71de950eea466758 -Sattack_max -- lib
```

命中/输出行数：2；退出码：0。

```text
4b18c4c67 收口数值红线缺项为立即报错并补逐键守卫
7e8849de4 feat(debug): add redline audit view
```

<a id="q528"></a>
### Q528

```sh
git log --reverse '--format=%H %s' c64b165938d948a24ab64c7c71de950eea466758 -Sattack_max -- data/numbers.yaml
```

命中/输出行数：2；退出码：0。

```text
fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4 [T01] 项目初始化与依赖配置
7e8849de46e00286f1c4c5757618070d9421396e feat(debug): add redline audit view
```

<a id="q529"></a>
### Q529

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.armor\.attack_max|tiers\.armor\.attack_max|armor\.attack_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

<a id="q530"></a>
### Q530

```sh
rg -n --with-filename --no-heading --sort path --glob '*.dart' --glob '*.py' --glob '*.sh' -- 'equipment\.tiers\.accessory\.attack_max|tiers\.accessory\.attack_max|accessory\.attack_max' lib test tool tools
```

命中/输出行数：0；退出码：1。

```text
（无输出）
```

## 验证与限制

报告只写建议，没有删除或修改任何配置。Flutter test / analyze / format 均 NOT_RUN；本单验证为 Python 实跑、命令证据、确定性复生成及 Git 白名单/补丁检查。
静态检索不能给出所有历史动态执行路径的绝对否定证明；存在规则分叉或未来参数意图的条目已标“未能判定”并留待拍板。本单 READY 仅表示审计产出可独立复核，不表示建议获准实施。
