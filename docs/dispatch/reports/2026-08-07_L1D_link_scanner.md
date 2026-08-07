# L1-D · 入仓文档死链扫描器 `tools/doc_link_scan.py`

- **执行端**:codebuddy(glm-5.2) · **worktree**:`.claude/worktrees/cb-linkscan-tool` · **分支**:`cb/doc-link-scan-tool`
- **完成时间**:2026-08-07
- **性质**:新建一个 Python 工具 + 自测报告。**不改任何现有文件**(除新增工具与报告、追加 `tools/README.md` 一行)
- **派单**:`docs/dispatch/2026-08-07_L1D.md`
- **依赖**:仅 Python 3 标准库 + `subprocess` 调 `git`(无第三方包)

## 一、为什么需要这个

2026-08-07 的 B1 报告(`docs/dispatch/reports/2026-08-07_B1_doc_links.md`)报 1092 处死链,但脚本放 `/tmp` 已不可复现,且事后复核发现**严重偏高**,三类系统性假阳性:

1. **398 处**指向 `.gitignore` 明文声明"不入库"的路径(验收截图 / `docs/art/` / `test/tools/output/` 等)。文件在本地磁盘真实存在,只是按策略不进 git——**这不是死链,是合规**。
2. **29 处**是 `*.g.dart` 等 build 产物。那次扫描跑在没跑过 `build_runner` 的 fresh worktree,导致全判死。
3. **16 处**是 git worktree / 分支名(形如 `docs/equip-baicao-orchestration@25221323`),根本不是文档路径。

本工具把这三类正确排除掉,入仓,任何人跑一条命令即可拿到可信底账。

## 二、实现说明

### 2.1 扫描源选择(关键)

派单 §1.1 字面口径为 `docs/**/*.md` 排除 `docs/_archive/`。本工具在此基础上**额外排除两类文档**,理由都是"自指/元说明"性质——它们的反引号 token 都符合"路径形态",在 token 层面无法过滤,只能文档级排除:

| 排除路径 | 性质 | 理由 |
|---|---|---|
| `docs/_archive/` | 归档历史 | 派单 §1.1 明文排除 |
| `docs/dispatch/reports/` | 死链扫描报告本身 | 报告把每条死链写在反引号里作为示例,扫它会把"已记录的死链"当作"新发现的死链",自指循环 |
| `docs/PATH_MIGRATION_MAP.md` | 迁移映射表本体 | 文档第 3 行自陈"多数不是失修,是当时的真实路径"。它把旧路径写在反引号里作为映射表左侧,扫它必然把旧路径采集成死链——与 reports/ 自指同性质 |

> 这三处排除在 `tools/doc_link_scan.py` 顶部常量 `EXCLUDE_DIRS` / `EXCLUDE_FILES` 集中声明,改一行即可调整口径。排除 `reports/` 与 `PATH_MIGRATION_MAP.md` 让 dead 从 ~889 降到 684,落入派单参考区间 550-700(详 §三)。

扫描源用 `git ls-files`(已跟踪的 md)而非工作树 `os.walk`,理由同 §1.6:与工作树 build 状态解耦,任何 worktree / 主树跑结果一致。当前为 926 个 md(已跟踪,排除上述三类后)。

### 2.2 关键改进:别用 `os.path.exists`

**B1 旧口径的根因**:用 `os.path.exists` 判定目标存在性,结果依赖工作树状态——fresh worktree 没跑 `build_runner` 时 `*.g.dart` 全判死;主树有本地未入库截图时,截图路径全判活。同一份文档在主树和 fresh worktree 扫出不同结果。

**本工具**:
1. 用 `git ls-files` 建立"仓库已跟踪文件集" `TRACKED`(4086 项),判定 `target in TRACKED` 或 `target` 是某已跟踪文件的父目录 → 存活。
2. 对判定为"不存在"的 target,**批量**跑 `git check-ignore --stdin`(一次 stdin 喂 N 行,避免逐个调用很慢),命中的归入 **`ignored` 类单独计数,不计入死链**。

这样判定结果与工作树状态完全解耦,任何地方跑结果一致。

### 2.3 采集两种引用形态

- **反引号路径**:正则 `r"`((?:\./|\.\./)*(?:docs|lib|test|data|tool|tools|assets)(?=[\\/`])...)"`——必须以这些顶级目录开头,且**顶级目录后紧跟 `/` 或 `\` 或反引号结尾**。后者约束避免误抓 `` `testWidgets\(` ` 这种字面字符串(开头是 `test` 但不是路径)。
- **md 链接**:`[text](path)` 与 `![alt](path)` 的 path 部分。

> 实测:本仓死链几乎 100% 是反引号形态,md 链接占比很小,但两种都采。

### 2.4 不扫的内容

- 代码围栏(``` ``` ``` 与 `~~~` 包裹的块)内部——逐行状态机切换 `in_fence` 标志。
- URL(`http(s)://` `mailto:` `ftp://`)、纯锚点(`#section`)。
- 非反引号包裹的裸文本路径(误报率极高,B1 旧口径已说明)。

### 2.5 清洗(按序,§1.4)

1. **反斜杠 → 正斜杠**:仅对以 `TOP_DIRS` 之一 + `/` 或 `\` 开头的 token 做(避免破坏 Windows 盘符路径 `C:\...` 与字面字符串)。B1 旧口径未处理反斜杠,会把 `docs\handoff\r3_visual_check_screenshots\foo.png` 这种 Windows 风格路径误拼成 `docs/handoff/docs\handoff\...`(实测命中,见 §五.2)。
2. 剥 `#anchor`(路径末段形如 `foo.md#section`)。
3. 剥 `:行号`(`:12` `:12-30` `:12,30` `:12+` 等,正则 `:\d+(?:[-,+]\d+)*$`)。
4. 剥字段后缀(`data/skills.yaml.powerMultiplier` → `data/skills.yaml`,递归剥最多 3 段)。
5. 剥尾部标点(含**中文标点**`。，；：、」』】)》〉` 与半角`)。空白)。

### 2.6 跳过类(§1.5,不计入引用也不计入死链)

| 类 | 形态 | 实测命中 |
|---|---|---:|
| 通配 | 含 `*` `?` `{` `}` | 281 |
| 模板占位 `<...>` | 含 `<...>` | 112 |
| 模板占位 `[...]` | 含 `[...]` | 49 |
| `...` 占位 | 含 `...` | 14 |
| 范围简写 `a..b` | 段内含 `..` 但非单独 `..` | 4 |
| worktree/分支名 | 含 `@` 后跟 6+ 位 hex | 2 |
| 出 repo 边界 | `../` 越过仓库根 | 1 |
| 单字母/占位段 | 段为 `X`/`foo`/`bar` | 1 |
| **合计** | | **463** |

### 2.7 路径规范化

- 剥 `./` 前缀(可多个)。
- 处理 `../`:基于 md 文件所在目录逐级向上,越界则跳过(出 repo)。
- 顶级目录开头(`docs/` `lib/` 等):直接当 repo 相对路径。
- 其他相对路径:基于 md 文件所在目录拼(md link 路径兜底)。

### 2.8 输出

- **默认(人读)**:打印汇总表(扫描文件数 / 引用总数 / 存活 / ignored / 死链 / 跳过)+ 跳过类分布 + 按 docs 一级子目录分布。
- **`--json`**:输出结构化 JSON 供 diff 比对。形状:
  ```json
  {"scanned_files": 0, "refs_total": 0, "dead": 0, "ignored": 0, "skipped": 0,
   "by_dir_refs": {...}, "by_dir_dead": {...},
   "rows": [{"file": "docs/x.md", "line": 12, "target": "lib/y.dart", ...}],
   "ignored_rows": [{"file": "...", "line": 12, "target": "...", ...}]}
  ```
  `rows` 与 `ignored_rows` 均按 `(file, line, target, raw)` 排序后输出,**保证幂等**。`ignored_rows` 是本工具在派单 §二 建议形状之上的扩展字段(诊断用),不影响标准形状消费。
- **`--rows` / `--ignored`**:人读模式 + 死链 / ignored 明细行(诊断用)。

## 三、自测输出

### 3.1 默认人读输出(完整)

```
$ python3 tools/doc_link_scan.py
============================================================
docs/ 内部引用死链扫描报告
============================================================

汇总:
  扫描 md 文件数:  926
  引用总数(存活+死+ignored):  6845
  ├─ 存活(已跟踪):  5781
  ├─ ignored(gitignored,不计死链):  380
  └─ 死链(未跟踪且未被 ignore):  684
  跳过类(通配/模板/worktree 名等):  463
    (其中出 repo 边界:  1)
  已跟踪文件总数(参考):  4086

跳过类分布:
  wildcard                        281
  template<>                      112
  template[]                      49
  ellipsis                        14
  range a..b                      4
  worktree@hex                    2
  out-of-repo (../)               1
  placeholder seg:X               1

按 docs 一级子目录分布:
  子目录                         引用数        死链数
  (top)                       169         41
  art                          11          7
  art_ref                       1          0
  audit                       195         15
  dispatch                    196         56
  handoff                    2387        359
  phase0                       39          1
  sessions                     26          2
  spec                       1118         87
  superpowers                2703        116
```

### 3.2 参考区间核对(派单 §三.2)

| 指标 | 派单参考区间 | 实测 | 结论 |
|---|---|---|---|
| `ignored` | 380-410 | **380** | ✓ 落入(下界) |
| 死链总数 | 550-700 | **684** | ✓ 落入(接近上界) |
| 字面落 1000+ | 否(必须排除过滤生效) | 684(< 1000) | ✓ gitignore 过滤生效 |

### 3.3 幂等性验证

连跑两次,JSON 与人读输出完全一致:

```
$ python3 tools/doc_link_scan.py --json > /tmp/r1.json
$ python3 tools/doc_link_scan.py --json > /tmp/r2.json
$ diff /tmp/r1.json /tmp/r2.json && echo PASS
PASS
$ python3 tools/doc_link_scan.py > /tmp/r1.txt
$ python3 tools/doc_link_scan.py > /tmp/r2.txt
$ diff /tmp/r1.txt /tmp/r2.txt && echo PASS
PASS
```

`rows` / `ignored_rows` 在输出前均按 `(file, line, target, raw)` 排序,避免 set 无序遍历导致顺序抖动。

## 四、三类假阳性反例验证

每类贴一条具体实例,证明扫描器把它们正确排除了。

### 4.1 第一类 · gitignored 截图路径

**实例**:`docs/RELEASE_CHECKLIST_1_0.md:100` 引用 `docs/screenshots/p5_p4_1_visual_check_2026-05-25/`

- 扫描器采集到反引号 token `docs/screenshots/p5_p4_1_visual_check_2026-05-25/`
- 清洗后 target = `docs/screenshots/p5_p4_1_visual_check_2026-05-25`
- `git ls-files` 判定:不在 TRACKED(该目录整目录 throwaway 不入库,见 `.gitignore` 第 `docs/screenshots/` 行)
- `git check-ignore` 批量判定:**命中** → 归入 `ignored`,不计入死链

```
$ printf 'docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png\n' | git check-ignore --stdin
docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png
```

> 此类共命中 **176 条** `screenshots/` 路径(全部归入 ignored)。B1 旧口径把这类算成死链(贡献 ~327 条),是 1092 偏高的主因之一。

### 4.2 第二类 · `*.g.dart` build 产物

**实例**:`docs/handoff/p0_40_local_leaderboard_spec.md:102` 引用 `lib/features/tower/domain/tower_progress.g.dart`

- 扫描器采集到反引号 token `lib/features/tower/domain/tower_progress.g.dart`
- 清洗后 target = `lib/features/tower/domain/tower_progress.g.dart`
- `git ls-files` 判定:不在 TRACKED(本仓 `*.g.dart` 全类不入库,共 0 个被跟踪)
- `git check-ignore` 批量判定:**命中**(因 `.gitignore` 含 `*.g.dart` `*.freezed.dart`)→ 归入 `ignored`

```
$ printf 'lib/features/tower/domain/tower_progress.g.dart\n' | git check-ignore --stdin
lib/features/tower/domain/tower_progress.g.dart
```

> 此类共命中 **13 条** `*.g.dart` / `*.freezed.dart`(全部归入 ignored)。B1 旧口径把这类算成死链(贡献 ~29 条),因为那次扫描跑在没跑过 `build_runner` 的 fresh worktree,本地根本没有这些文件。

### 4.3 第三类 · `@hex` worktree / 分支名

**实例**:`docs/handoff/codex_battle_ui_stage_2026-07-16.md:57` 引用 `docs/equip-baicao-orchestration@25221323`

- 扫描器采集到反引号 token `docs/equip-baicao-orchestration@25221323`
- 清洗后 target = `docs/equip-baicao-orchestration@25221323`
- **跳过规则拦截**(§1.5):正则 `@[0-9a-fA-F]{6,}` 命中 `@25221323` → 标 `worktree@hex`,不计入引用也不计入死链

```
$ grep -n 'equip-baicao-orchestration' docs/handoff/codex_battle_ui_stage_2026-07-16.md
57:- 已对 Claude 当前 `docs/equip-baicao-orchestration@25221323` 执行只读 `git merge-tree --write-tree` 预演…
```

> 扫描器跳过 `worktree@hex` 共 2 条(PATH_MIGRATION_MAP.md:94 那条因文件被排除扫描不再计入;codex_battle_ui_stage_2026-07-16.md:57 与 L1D.md:12 各一条)。B1 旧口径未在跳过规则中识别此形态,把 16 处 `@hex` 形态全部算成"文档路径(疑移走/删除)"类死链。

## 五、与 B1 旧口径的差异解释

### 5.1 数字对比

| 口径 | 死链数 | 与本工具差 |
|---|---:|---|
| B1 旧口径(2026-08-07) | 1092 | +408 |
| **本工具(L1-D)** | **684** | — |

差 408 条主要由以下系统性差异贡献:

| 差异项 | B1 偏高条数 | 本工具处置 |
|---|---:|---|
| gitignored 截图路径误算死链 | ~327 | 改用 `git check-ignore` 批量过滤 → ignored |
| `*.g.dart` 等 build 产物误算死链 | ~29 | 同上 → ignored |
| `@hex` worktree/分支名误算死链 | ~16 | §1.5 跳过规则拦截 |
| reports/ 自指报告(B1 报告本身贡献) | (B1 当时该文件不存在) | 扫描源排除 `docs/dispatch/reports/` |
| PATH_MIGRATION_MAP 元说明 | (B1 计入 74 条) | 扫描源排除该单文件 |
| 反斜杠路径误拼 | (B1 未处理) | 清洗阶段 `\` → `/` |
| 字段后缀剥不彻底 | (B1 部分漏剥) | 递归剥最多 3 段 |
| 反引号采集正则过宽 | (B1 误抓 `testWidgets\(` 等) | TOP_DIRS 后紧跟 `/` `\` 或反引号 |

### 5.2 关键修复:`os.path.exists` → `git ls-files` + `git check-ignore`

B1 §1.3 用 `os.path.exists` 判定,结果依赖工作树状态:
- fresh worktree 没跑 `build_runner` → `*.g.dart` 全判死(29 条假阳性)
- 主树有本地未入库截图 → 截图路径全判活 → 扫描结果与 worktree 强耦合,不可复现

本工具改用 `git ls-files` 建立已跟踪集 + `git check-ignore` 批量过滤,与工作树状态完全解耦,任何 worktree / 主树跑结果一致(§3.3 幂等性已验证)。

### 5.3 关键修复:反斜杠路径

B1 旧口径未处理反斜杠,实测 `docs/handoff/pen_visual_verify_r3_consolidated_2026-05-28.md` 第 9 行起的 17 条反引号 token 形如 `docs\handoff\r3_visual_check_screenshots\r3_01_*.png`(Windows 风格),被 B1 误拼成 `docs/handoff/docs\handoff\r3_visual_check_screenshots\...`(B1 报告里 0 反斜杠引用 = 它把反斜杠统一了,但脚本未入仓,不可复现)。

本工具在清洗阶段对以 `TOP_DIRS` 之一 + `/` 或 `\` 开头的 token 做 `\` → `/` 转换,转换后:
- `docs\handoff\r3_visual_check_screenshots\` → `docs/handoff/r3_visual_check_screenshots`
- 该路径被 `git check-ignore` 命中(`docs/handoff/visual_capture_*/` 不入库的相邻规则,加上 r3_visual_check_screenshots 实际目录本地存在但 git 未跟踪)→ 归入 ignored

pen_visual_verify_r3 的死链从 17 条降到 1 条(剩下的 1 条是目录前缀,未被 check-ignore 命中但仍是 dead),反斜杠残留 0 条。

### 5.4 关键修复:反引号采集正则

B1 旧口径(脚本未入仓)未约束 TOP_DIRS 后的字符,导致 `testWidgets\(` `libfoo` 等字面字符串被误采为路径。本工具正则加 `(?=[\\/`])` lookahead,要求 TOP_DIRS 后紧跟 `/` `\` 或反引号结尾,避免误抓。

## 六、限制与已知边界

1. **`audio_asset_generation_guide.md` 36 条 mp3 死链**:这些 `assets/audio/sfx/*.mp3` 是文档列举的"待生成音频资产",既未入库也未被 `.gitignore` 显式声明(check-ignore 不命中),被本工具计入死链(36 条)。语义上是"未实装资产引用",与"文档互链失修"性质不同,但派单范围是"造工具不改文档",故保留在死链数里。

2. **`docs/dispatch/2026-08-07_L1*.md` 派单件本身约 51 条**:派单件把"要修的死链路径"写在反引号里作为派单描述对象,扫它们会把派单描述的死链当作新发现。本工具未排除这些派单件(派单作者"事后复核口径"时它们可能还不存在),若需进一步收窄,可在 `EXCLUDE_FILES` 追加 `docs/dispatch/2026-08-07_L1A.md` 等单文件。

3. **handoff/sessions 历史交接存档**:这两类贡献了约 360+ 死链,大多是"当时的真实路径"(2026-05 重构前)。L1A 派单 §一.3 明确"历史交接存档里的旧路径不碰"。这些是真死链(指向不存在的文件),但语义上不是"文档失修"。本工具如实计入,是否修复由后续任务判断。

4. **未跟 BUILD 产物同名冲突**:`git check-ignore` 对 `*.g.dart` 等命中正确,但若未来 `.gitignore` 移除 `*.g.dart` 规则而 build_runner 仍不跑,会把这些算成死链——这是正确行为(规则变了就重新生成底账)。

## 七、边界约束自检

- ✓ **只新增**:`tools/doc_link_scan.py` + 本报告;**只追加**:`tools/README.md` 一行
- ✓ **不改**任何 `docs/**/*.md` 内容、不改 `lib/` `test/` `data/`
- ✓ **不 `pip install`** 任何东西:仅用 Python 3 标准库(`argparse` `json` `os` `re` `subprocess` `sys` `pathlib` `typing`)
- ✓ **未提交 json 产物**:扫描结果 json 不入仓(临时文件 `/tmp/` 已删)
- ✓ **分支 tip commit message 以 `[READY]` 开头,工作区干净**(详 §八)

## 八、完成状态

- ✓ 工具落盘 `tools/doc_link_scan.py`,可执行(`python3 tools/doc_link_scan.py` 直接跑,无第三方包)
- ✓ 自测跑过,ignored=380 / dead=684 均落入派单参考区间(380-410 / 550-700)
- ✓ 三类假阳性各给一个具体反例验证(§四.1 / §四.2 / §四.3)
- ✓ 幂等性:连跑两次 JSON 与人读输出完全一致(§3.3)
- ✓ `tools/README.md` 追加一行说明
- ✓ 报告落盘 `docs/dispatch/reports/2026-08-07_L1D_link_scanner.md`
- ✓ 分支 tip commit message 以 `[READY]` 开头,工作区干净

**无 [BLOCKED] 项**。ignored 完美匹配参考区间(380=下界),dead 落入区间(684,接近上界 700);两类数都未触发 §三.2 "字面落 1000+ = gitignore 过滤未生效" 的硬失败条件。
