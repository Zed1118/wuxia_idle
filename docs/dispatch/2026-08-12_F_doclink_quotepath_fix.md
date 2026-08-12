# 派单 F · 修复死链扫描器 git 转义致漏扫 291 篇中文名文档

- **执行端**:qoderclicn · **性质**:Python 缺陷修复 + 测试,**只改 `tools/`**
- **worktree**:待派单方创建后填入 · **分支**:`fix/doclink-quotepath`
- **日期**:2026-08-12
- **优先级说明**:本缺陷使扫描器**漏扫 23.7% 的应扫文档**,并直接推翻了同日「扫描器定位升级为可引用事实源」的拍板依据。属高优先级修复。

## 一、缺陷(派单方已实测定论,当判据锚点,不必重新论证)

`tools/doc_link_scan.py` 用 `git ls-files` 取已跟踪文件清单:

```python
def git_ls_files() -> list[str]:
    out = subprocess.check_output(
        ["git", "ls-files"], cwd=REPO_ROOT, text=True, encoding="utf-8"
    )
    return [line for line in out.splitlines() if line]
```

**git 对含非 ASCII 字符的文件名默认输出八进制转义并加引号**(`core.quotePath` 默认 true)。本仓实测:

```
$ git ls-files | grep '^"' | wc -l
292          ← 全部在 docs/ 下

$ git ls-files "docs/sessions/" | grep 2026-08-12
"docs/sessions/2026-08-12_001100_\350\265\204\350\264\250\344\270\211\350\277\236_p11-aptitude.md"
```

该文件真实存在且被跟踪(`ls -la` 实测 4430 字节),但记录进 `tracked` 集合的是那个**带引号的转义串**。后果有二:

1. **漏扫**:`collect_scan_files` 里 `p.startswith("docs/")` 对 `"docs/...` 恒为假 ⇒ **291 篇中文名文档从未进入扫描源**。
2. **误判死链**:别处引用这些文件时,`target` 是真实路径,在 `tracked` 里匹配不到那个转义串 ⇒ 归入 `dead`。

**`git_check_ignore` 同病**(`tools/doc_link_scan.py` 内):它读 `proc.stdout.splitlines()`,而 `git check-ignore --stdin` 回显命中路径时**同样会转义**。⇒ 中文名的 gitignored 文件会被误归 `dead` 而非 `ignored`。**两处必须一起修,只修一处等于留半个 bug。**

## 二、影响面(派单方隔离实验实测,直接引用)

方法:import 模块后猴补 `git_ls_files` 为 `git ls-files -z` 版本,前后各跑一次 `scan()`(**未改仓库文件**)。

| 指标 | 修复前 | 修复后 | Δ |
|---|---|---|---|
| 扫描源 md 文件数 | 938 | **1229** | **+291** |
| 引用总数 | 7564 | 7911 | +347 |
| 存活 | 6046 | 6266 | +220 |
| ignored | 607 | 686 | +79 |
| 归档类 | 585 | 593 | +8 |
| 死链 | 326 | **366** | **+40** |

> 注:`tracked` 条目数两侧都是 4134(条目数不变,变的是字符串内容)。上表基线取自分支 `afk/coordinator-0812` 的 `d78345b3`;**你在自己 worktree 跑出的绝对值可能因基线不同而略有出入,以「你自己前后两跑的差值」为准**,不要硬对上表数字。

## 三、要做的改动

### 3.1 `git_ls_files`

改用 **NUL 分隔**,git 在 `-z` 下不做转义:

```
git ls-files -z      → 按 \0 切分
```

**不要**用 `git -c core.quotePath=false ls-files` 作为唯一手段——它解决转义但仍以换行分隔,文件名含换行时会错(本仓当前没有,但 `-z` 一并解决,成本相同)。若你有更好的方案,在交付说明里写明理由。

### 3.2 `git_check_ignore`

`git check-ignore -z --stdin`:**`-z` 下输入与输出都改为 NUL 分隔**(git 文档明载)。请同时改输入拼接与输出切分,不要只改一边。

### 3.3 不要顺手做的事

- **不要改 `collect_scan_files` 的过滤逻辑去"兼容"带引号的路径**。根因是取数据的方式错了,不是过滤逻辑错了;在下游打补丁会把错误编码固化。
- **不要改扫描算法、正则、TOP_DIRS、归档分类判据**。
- **不要去修任何一条死链**。本单只修工具。

## 四、测试(硬要求)

在 `tools/test_doc_link_scan_gitfixture.py`(真起临时 git 仓那份)中扩充:

1. **中文名文件进得了扫描源**:在 fixture 仓里建一个**含非 ASCII 字符的 .md 文件**(如 `docs/测试_中文名.md`),`git add` 后断言它出现在 `collect_scan_files()` 的结果里。**这条是本单的核心闸门**——修复前它必红。
2. **指向中文名文件的引用判为存活**:另建一篇文档,内部用反引号引用上述中文名文件,断言该引用归 `alive` 而非 `dead`。
3. **`git_check_ignore` 对中文名生效**:在 fixture 的 `.gitignore` 里写一条能命中某中文名路径的规则,断言该路径被判 ignored。
4. 既有 17 例全部保持通过(零回归)。

**破坏证红是交付条件**:把 `-z` 改回原写法 → 上述新断言必红 → 还原 → 复绿。三态输出贴进交付说明。自检判据:**「破坏那行,这条断言必然红吗?」**

**测试不得绕开生产路径**:必须调真的 `git_ls_files` / `git_check_ignore` / `collect_scan_files` / `scan`,不许在测试里自己拼一份路径清单来比。

## 五、交付说明必须包含

1. 修复前/后**各跑一次** `python3 tools/doc_link_scan.py`,贴两份汇总块(扫描源文件数 + 四类计数),并给出差值。
2. 两份 python 套件**各自单独跑**的通过数(`test_doc_link_scan.py` 与 `test_doc_link_scan_gitfixture.py`)。
3. 破坏证红三态输出。
4. 更新 `tools/README.md` 中 `doc_link_scan.py` 那一行的数字与缺陷描述:该行现有一段以「⚠ **2026-08-12 用户曾拍板升级为「可引用事实源」,但同日随即发现新缺陷,升级暂缓待复评**」开头的文字,**把其中「修复前/修复后」的表述改成「已修复」并填入你实测的当前值**;**但「当前定位=可试用·非终审事实源(升级已暂缓)」这句定位本身不许改**——是否重新升级要用户看过修复后的重测数据再拍,不归本单。
5. 残留风险,尤其:**P6 那份 precision 95.0%/recall 100% 的标注验证是在漏扫样本上做的,修复后其结论是否仍成立你无法断言** —— 请如实写明「需重做标注验证才能支持定位升级」,不要替它背书。

## 六、边界约束(硬)

- **禁区文件,一个都不许碰**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **只改 `tools/` 下的文件**;**不许碰 `tools/visual_capture/`**(另一批刚改过)。
- **不许改 `lib/`、`test/`、`data/`、`docs/`**。
- **禁 push、禁 merge、禁碰 main、禁 revert**。
- commit message 用**中文动宾**结构。
- 交付时工作区干净,tip commit 消息以 `[READY]` 开头。

## 七、[BLOCKED] 出口

- `-z` 方案在你手上跑不通,或 `git check-ignore -z` 的行为与派单包描述不符(**先做最小隔离实验验证,再报告**,不要凭文档推断)
- 修复后既有 17 例出现回归且你查不清原因
- 差值与 §二 表格的**方向**不一致(如扫描源没有增加)——说明前提有变,停下报告
- 任何你拿不准是否越过 §六 边界的动作
