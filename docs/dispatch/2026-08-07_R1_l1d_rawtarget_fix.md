# R1 · L1-D 死链扫描器 raw/target 根因修 + 固定样例测试

**端**:codex · **worktree**:`.claude/worktrees/l1d-fix` · **分支**:`cb/doc-link-scan-fix`(基于 `cb/doc-link-scan-tool` @ `29c6f5c6`)
**派单**:2026-08-07 · **预估**:40-60min

## 一、背景

`tools/doc_link_scan.py`(667 行)是文档死链扫描器,已交付并自报 `[READY]`,报出「678 条死链」。但**所有 markdown 链接被静默漏扫** —— 它实际只扫了反引号引用。「678」落在验收区间内纯属巧合(本仓死链几乎全是反引号形态)。本单修根因,并补上真正能拦住这类失效的测试。

## 二、缺陷链路(Claude 已在本 worktree 实测定位;**请自行复现一次再动手**)

1. `tools/doc_link_scan.py:226-227` — mdlink 采集时存 `{"target": path, "raw": f"[{text}]({path})"}`
2. `:478` — 主流程 `raw = ref["raw"]`,**取 raw 不取 target**
3. `:276-300` `clean_target()` — 只剥 anchor / 行号 / 字段后缀 / 尾标点,**不剥方括号**
4. `:262` — `_RE_TEMPLATE_BRACKET = re.compile(r"\[[^\]]+\]")`
5. `:324` — `should_skip()` 命中该正则 → 返回 `(True, "template[]")`

**结论**:每条 md 链接的 raw 必然带 `[text]` → 必然被判模板占位跳过 → 采集的 `target` 字段全程从未被使用。

**实证**:当前跑批 skip 分布里 `template[]` 计数 49,而交付报告自称全仓 md 链接 43 处 —— 这个计数就是误杀的直接证据。

## 三、修复要求

1. 主流程改用 `ref["target"]`。注意 backtick 分支 `target == raw`,故该改动对反引号类**行为不变**;mdlink 类才开始真正参与扫描。
2. **不得放宽 `_RE_TEMPLATE_BRACKET`**。反引号路径里的真模板占位(如 `` `docs/[章节]/x.md` ``)必须仍被跳过。本单的修法是「不再把 md 链接的原始 token 喂给清洗器」,**不是**「让清洗器容忍方括号」。
3. 若发现 `target` 字段本身采集时就不干净(例如未剥 anchor),在 `clean_target` 里补,**不要回退到用 raw**。
4. 修完重跑全仓,报告**新旧分类计数对比**:引用总数 / 死链数 / 各 skip 类计数 / 按 docs 子目录分布,并逐项解释变化来源(哪些是 md 链接开始被扫进来的)。

## 四、固定样例测试(主判据 · 禁用总数区间验收)

新建 `tools/test_doc_link_scan.py`:纯 `python3 unittest`,**不引入第三方依赖**。本机 Python **3.9.6**;源文件首部有 `from __future__ import annotations`(`:31`),你的新文件若用 `X | None` 形态注解**必须同样加**,否则 3.9 直接崩。

逐类固定输入 + 期望输出,**至少**覆盖下表 10 类。每条必须断言到**具体分类归属**(计入引用 / 计入死链 / skip 及其 reason),**不许只断言「总数 > 0」**:

| # | 输入形态 | 样例 | 期望 |
|---|---|---|---|
| 1 | 反引号路径(存在) | `` `lib/main.dart` `` | 计入引用,非死链 |
| 2 | 反引号路径(不存在) | `` `lib/nope.dart` `` | 计入死链 |
| 3 | md 链接(存在) | `[说明](GDD.md)` | 计入引用 —— **当前漏扫,本单核心** |
| 4 | md 链接(不存在) | `[x](docs/nope.md)` | 计入死链 |
| 5 | 图片链接 | `![图](assets/x.png)` | 计入引用 |
| 6 | 代码围栏内的路径 | 三反引号围栏内含 `lib/a.dart` | 跳过,不计引用 |
| 7 | gitignored 目标 | `` `build/foo.txt` `` | 归 ignored,**不算死链** |
| 8 | 相对路径 | `` `../tools/x.py` `` | 正确解析为 repo 相对,或判越界 |
| 9 | 模板占位 `[]` 在反引号内 | `` `docs/[章节]/x.md` `` | 跳过 `template[]` —— **回归红线,修复不得放行** |
| 10 | md 链接 text 含路径样式 | `[见 lib/a.dart](docs/b.md)` | 只取 `docs/b.md`,**不得把 text 当路径** |

测试要能独立运行:用临时目录 / 内存字符串构造输入,不要依赖本仓当前的真实死链数。

## 五、验收(报告里逐条贴实跑输出)

1. `python3 tools/test_doc_link_scan.py -v` 全过,贴**完整输出**(含每个 test 名)
2. 修复前 / 修复后分类计数对比表 + 每项变化的来源解释
3. **破坏证红**(必须在 commit **之后**做):
   - 把主流程改回 `ref["raw"]` → 第 3/4/5/10 条必须红,贴红输出
   - 放宽 `_RE_TEMPLATE_BRACKET` → 第 9 条必须红,贴红输出
   - 两次破坏都**还原并重跑一次完整绿**(红 → 还原 → 绿三段缺一不可)
4. 报告落 `docs/dispatch/reports/2026-08-07_R1_l1d_fix.md`

## 六、硬约束

- **只动**:`tools/` 下文件 + `docs/dispatch/reports/` 下你的报告
- **禁碰**:`data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/**/strings.dart` / `pubspec.yaml`
- 完成后在**本 worktree** `commit`(消息前缀 `[READY]`),**不要 push,不要合并到 main**
- 拿不准 → 停下,写 `[BLOCKED]` + 原因,**禁硬做**
- **数字一律自己实跑得出**,禁复述本派单包里的数字(49 / 678 / 43 都要你自己复现)
