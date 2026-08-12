# 派单 C · 死链扫描器范围收敛:归档类单列 + EXCLUDE_DIRS 接线(滚动池 P10)

- **执行端**:qoderclicn · **性质**:Python 工具层改动 + 测试,**只改 `tools/`**
- **worktree**:`/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/afk-c-scan-scope` · **分支**:`feat/doclink-scan-scope`
- **基线**:`480c0248`(= origin/main)· **日期**:2026-08-12 夜批
- **无需预热**:纯 Python,不需要 Flutter 构建。

## 一、任务背景(自包含,执行端无本方上下文)

本仓是 Flutter 武侠挂机游戏,文档量大。`tools/doc_link_scan.py` 是一个**文档内部引用死链扫描器**:扫 `docs/**/*.md` 里写在反引号或 md 链接里的仓内路径引用,判定每条引用指向的文件是否还存在,分三类计数——**存活**(git 已跟踪)/ **ignored**(被 .gitignore 命中,不算死链)/ **死链**(未跟踪且未被 ignore)。

配套已有两份测试:`tools/test_doc_link_scan.py`(单元层,mock git)与 `tools/test_doc_link_scan_gitfixture.py`(真起临时 git 仓的 fixture 层)。工具的准确率做过分层抽样验证(precision 95.0% / recall 100%)。

## 二、要解决的问题(派单方已实测,数字直接用)

### 问题一:`dead` 计数里 64.5% 是归档文档噪声

**派单方在本基线 `480c0248` 实跑 `python3 tools/doc_link_scan.py`,实测**:

```
扫描 md 文件数:  932
引用总数:        7445
├─ 存活:         5933
├─ ignored:      605
└─ 死链:         907
```

按 docs 一级子目录分布(同一次运行):

| 子目录 | 引用数 | 死链数 |
|---|---|---|
| (top) | 171 | 41 |
| art | 11 | 7 |
| art_ref | 1 | 0 |
| audit | 218 | 20 |
| dispatch | 261 | 60 |
| **handoff** | **2741** | **585** |
| phase0 | 39 | 0 |
| sessions | 28 | 4 |
| spec | 1120 | 84 |
| superpowers | 2855 | 106 |

**907 条死链里 585 条(64.5%)来自 `docs/handoff/`**。`docs/handoff/` 存的是历史交接文档——它们里面的路径引用**本来就指向写作当时的仓库状态**,后续重构把文件移走是正常演进,不是"文档失修"。拿这个 `dead` 数当修复清单,等于安排 585 条无意义的活。

⇒ **本单的目的**:把这类归档文档的失效引用**单列成一类**,与"真正该修的死链"分开计数,让 `dead` 恢复成可直接当修复清单用的数字。

**范围已由用户拍板取 (b)「单列一类」**——不是删掉不扫,不是排除出扫描源,是**照扫、单独归类、单独计数**。请严格照这个语义实现,不要自作主张改成"排除"。

### 问题二:`EXCLUDE_DIRS` 定义后全仓零消费

`tools/doc_link_scan.py:59`:

```python
EXCLUDE_DIRS = {"docs/_archive", "docs/dispatch/reports"}
```

**派单方实测 `grep -rn "EXCLUDE_DIRS" tools/` 只有这一行**——即它定义后**从未被任何代码读取**。真正生效的排除逻辑硬编码在 `collect_scan_files`(`tools/doc_link_scan.py:143-147`):

```python
if p.startswith("docs/_archive/"):
    continue
if p.startswith("docs/dispatch/reports/"):
    continue
if p in EXCLUDE_FILES:      # ← 注意:EXCLUDE_FILES 是被消费的,只有 EXCLUDE_DIRS 不是
    continue
```

⇒ 常量与实际行为是两份真相,改常量不产生任何效果。**本单顺带把它接上**,让 `collect_scan_files` 真正从 `EXCLUDE_DIRS` 派生排除逻辑。

## 三、要做的改动

### 3.1 归档类单列

1. 新增一个模块级常量(命名自定,建议 `ARCHIVAL_DIRS`),**初值只放 `docs/handoff`**。
   - **不要**顺手把 `docs/sessions`、`docs/dispatch` 或别的目录也塞进去。它们是否同属归档性质是**范围决策,不归你拍**;若你认为某目录同属此类,写进报告的「建议」节由派单方定夺。
2. 分类逻辑:一条引用若判定为死链,**且它所在的文档文件**位于 `ARCHIVAL_DIRS` 之下 → 归入新的 `archival` 类,不计入 `dead`。
   - **注意判据是「引用写在哪个文件里」,不是「引用指向哪个路径」**。这一点弄反了整个结果就是错的,请在测试里专门钉住。
3. 汇总输出增加该类,层级与既有 `ignored` 同级。示例(措辞自定,保持既有中文体例):

```
  引用总数(存活+死+ignored+归档):  7445
  ├─ 存活(已跟踪):  5933
  ├─ ignored(gitignored,不计死链):  605
  ├─ 归档类(归档文档内的失效引用,不进修复清单):  585
  └─ 死链(未跟踪且未被 ignore):  322
```

4. 结果字典(`main`/扫描函数返回的那个 `result`)补对应键(如 `archival` 计数与 `archival_rows` 明细),并与既有 `--ignored` 那类诊断开关**体例一致**地加一个明细开关(如 `--archival`)。
5. 目录分布表要能看出归档类的去向(如加一列,或在归档目录行上标注),具体呈现你定,但**不能让读者误以为 handoff 的 585 条凭空消失了**。

### 3.2 EXCLUDE_DIRS 接线

改 `collect_scan_files`,让排除项**真正从 `EXCLUDE_DIRS` 派生**(注意常量值不带尾斜杠,匹配时要按目录边界比,别写成裸 `startswith` 导致 `docs/_archiveXYZ/` 被误排除)。

**行为必须完全不变**:接线前后扫描源文件数、引用总数逐值相同。

## 四、守恒校验(硬要求,交付说明必须贴)

1. **引用总数守恒**:改动前 `7445` == 改动后 `存活 + ignored + 归档 + 死链`。
2. **重分类守恒**:改动前 `dead=907` == 改动后 `dead + archival`。
3. **扫描源守恒**:改动前后 `扫描 md 文件数` 均为 `932`。
4. 上述三条**都要贴改动前/改动后两次实跑的真实输出**,不许只贴一边然后说"另一边不变"。
   - 改动前的数字你自己在本 worktree 跑一次拿到(**不要转抄本派单包里的数字**——派单方的基线与你的 worktree 应当一致,但**你要自己证明它一致**;若不一致,说明有漂移,走 §七 [BLOCKED])。

## 五、测试(硬要求)

在既有两份测试(`tools/test_doc_link_scan.py`、`tools/test_doc_link_scan_gitfixture.py`)中**择合适的一份或两份**扩充,至少覆盖:

1. **归档分类正确性**:归档目录下的文档里的死引用 → 归 `archival`;非归档目录下的**指向归档目录的**死引用 → 仍归 `dead`(这条专钉 §3.1 第 2 点那个易反的判据)。
2. **守恒**:同一份 fixture 下 `dead + archival` 等于未分类前的死链总数。
3. **EXCLUDE_DIRS 真消费**:往 `EXCLUDE_DIRS` 加一个目录 → 该目录下的文档确实不再进扫描源(**这条是本单唯一能证明"接线成功"的断言**,必须有)。
4. **目录边界**:`docs/_archive` 不会误排除 `docs/_archiveXYZ/`(或同类边界样例)。

**破坏证红是交付条件**:每类新断言实测「改坏对应生产代码 → 必红 → 还原 → 复绿」,把三态实际输出贴进交付说明。自检判据:**「破坏那行,这条断言必然红吗?」**答不出"必然红"的断言不要写。

**测试不得绕开生产路径**——不许在测试里自己重算一遍分类逻辑再和自己比,必须调被测函数。

## 六、验收标准(派单方会逐项复跑,数字必须实测)

1. 两份测试套件**各自单独跑**并贴输出与通过数(禁一条命令塞多个路径然后只看末尾——本仓有批跑静默漏跑的实录)。
2. §四 三条守恒校验的前/后双侧输出。
3. `tools/README.md` 里若有对分类口径的描述,同步更新(**只改描述,不许改该文件里「可试用·非终审事实源」那句工具定位**——那是待用户拍板的红级条目,不归本单)。
4. 交付说明写清:改了哪些文件、新增几条断言、破坏证红的实际输出、残留风险。

## 七、边界约束(硬)

- **禁区文件,一个都不许碰**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **只改 `tools/` 下的文件**。不许改 `lib/`、`test/`、`data/`、`docs/`(除 §六 第 3 点允许的 `tools/README.md`)。
- **不许碰 `tools/visual_capture/`**——今晚有另一条并行任务在那个域作业,改它会撞车。
- **禁 push、禁 merge、禁碰 main、禁 revert**。只在本 worktree 的 `feat/doclink-scan-scope` 分支上 commit。
- **不许"顺手"清理任何一条死链**。本单只改分类口径,一条文档引用都不许改——修死链是另一件事,清单口径没定之前不能动手。
- **不许改扫描算法**(反引号正则、TOP_DIRS、KNOWN_EXTS、跳过类判定等一律不动)。本单只加分类维度 + 接线常量。
- **数字不许估算**,全部本会话实跑得出。
- commit message 用**中文动宾**结构(英文 conventional 前缀如 `feat:` 属违规,合并 Gate 会查)。
- 交付时:工作区必须干净(全 commit),分支 **tip commit 消息以 `[READY]` 开头**,例如 `[READY] 死链扫描归档类单列并接线 EXCLUDE_DIRS`。

## 八、[BLOCKED] 出口

以下任一情况,**立刻停下**,把分支 tip commit 消息前缀打成 `[BLOCKED]` 并写清困惑点与已掌握证据,**禁止硬做**:

- 你在本 worktree 实跑的基线数字与 §二 表格对不上(说明有漂移,先报告)
- 守恒校验任一条不成立,且原因你查不清
- 需要改扫描算法或改动文档内容才能推进
- 你认为 `ARCHIVAL_DIRS` 应当包含 `docs/handoff` 以外的目录(这是范围决策,写建议不要实装)
- 任何你拿不准是否越过 §七 边界的改动

拿不准就冻结,不要硬做——夜里没人能给你拍板。
