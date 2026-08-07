# 死链扫描器两处系统性假阳 · 修复提案(2026-08-08 夜批 · 协调者)

> **状态:🟡 已验证未合并,等用户拍板。** 本文含可直接 `git apply` 的完整补丁。
> 上游:P6 标注验证报告 `2026-08-08_P6_link_scanner_labeling.md`(pi 出,precision 95%/recall 100%)。
> P6 只报告不修(派单包边界),本文是协调者对其两条发现的独立复现 + 最小修复 + 验证。

## 一、两个 bug 均已独立复现成立

### Bug A(工作树漂移)—— 比 P6 描述的更严重

P6 报「裸目录引用被误判死链,其中 9 条随工作树漂移」。**复现确认,且根因不是 P6 说的那个**:

```
主 checkout(有 build/ 目录):  git check-ignore -v build   → .gitignore:10:build/  命中
fresh worktree(无 build/):    git check-ignore -v build   → 不命中
fresh worktree(无 build/):    git check-ignore -v build/  → .gitignore:10:build/  命中
```

即 `git check-ignore` 对 `build/` 这类**目录型模式**,在参数不带尾斜杠时会退化成
「该路径必须真是个目录」——于是**同一份代码在不同 worktree 给出不同答案**。

这直接推翻 `tools/README.md:12` 对该工具的自述:

> 只用标准库+`git ls-files`/`git check-ignore`,**任何 worktree 结果一致**

实测基线两地差异:ignored 592(主) vs 575(worktree),**17 条漂移**。

### Bug B(`:` 后缀剥不掉)

`_RE_STRIP_LINENO`(`doc_link_scan.py:245`)只剥**锚定行尾的纯数字**,漏两类真实写法:

| 文档里的写法 | 基底文件是否存在 | 现判定 |
|---|---|---|
| `data/numbers.yaml:130 combined_rate_cap: 0.95` | ✅ tracked | ❌ 死链 |
| `lib/features/sect/presentation/sect_screen.dart:_MemberRow` | ✅ tracked | ❌ 死链 |
| `lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart:_CandidateInfo` | ✅ tracked | ❌ 死链 |

四个基底文件本会话 `git ls-files --error-unmatch` 逐个实测全部 tracked。

## 二、修复方案(**2 处改动,49 行 diff**)

### ⚠ P6 建议的修法「保留尾斜杠」既不必要也不充分,已否决

P6 报告末尾建议「规范化保留尾斜杠 + `:` 后缀先剥扩展名」。本会话实测:

- **不充分**:保留尾斜杠只救「文档里原本就写了 `build/`」那批。文档里**裸写 `build`**
  的仍然漂移 —— 实测漂移只从 17 降到 **8**,残余 8 条 target 全部是裸写的 `build`。
- **不必要**:改用下面的 A2 方案(查询侧补斜杠)后,再把「保留尾斜杠」那处加回去,
  两地结果**逐值不变**(alive 5926 / dead 909 / ignored 605)→ 该改动零贡献,不收。

### 采纳方案

**改动 1(Bug B)**:新增 `_RE_STRIP_COLON_SUFFIX`,规则=「已知扩展名 + 冒号」即在冒号处截断,
并接进 `clean_target` 的第 2b 步(**定义了必须接线**,否则又是一个采而不用的字段)。

**改动 2(Bug A2)**:`git_check_ignore` 查询侧对每个 target **额外补一个 `target + "/"` 变体**,
命中任一即算 ignored。目录型模式对带斜杠路径是纯模式匹配,与物理存在无关 → 与工作树彻底解耦。

## 三、验证(全部本会话实测)

| 验证项 | 基线 | 修复后 | 判定 |
|---|---|---|---|
| 引用总数 | 7440 | **7440** | ✅ 守恒,无引用丢失 |
| 存活 | 5908 | **5926**(+18) | Bug B 救回 |
| ignored | 592 | **605**(+13) | Bug A2 救回 |
| 死链 | 940 | **909**(−31) | — |
| 主 checkout vs worktree | ignored 592 vs 575(**差 17**) | **两地逐值相同** | ✅ 漂移归零 |
| `tools/test_doc_link_scan.py` | 10/10 OK | **10/10 OK** exit 0 | ✅ 解析层零回归 |

**漂移归零的验证方式**:同一份修复版分别在主 checkout 与 `afk-coordinator-0808` worktree
跑 `--json`,四个计数(refs_total/alive/dead/ignored)逐值比对相同。

## 四、未做 / 待补

- **未加新测试**。现有 10 类样例 mock 了 `git_ls_files`/`git_check_ignore`,
  而这两个 bug 恰恰活在**未被 mock 的真实 git 行为**里 —— 沿用同一体例加样例
  **测不出这两个 bug**(加了也是假绿)。要真守住得引真实 git fixture,属另一个单。
  这是本提案最大的缺口,合并前请知悉。
- **未升级 `tools/README.md` 的「可试用·非终审事实源」定位**。P6 结论是「作为分类底账
  可升终审,作为修复清单暂不能」,该定位调整是 🔴 级(改变工具在流程中的权威),留用户拍。
- **未修 dead 池的语义问题**:17 条 dead mdlink 里仅 1 条真死链,其余是散文伪链接与夹具,
  这不是 bug 是范围问题(P6 报告 §结论),需要单独的范围决策。

## 五、补丁(可直接 `git apply`)

```diff
--- a/tools/doc_link_scan.py
+++ b/tools/doc_link_scan.py
@@ -246,6 +246,14 @@
     r":\d+(?:[-,+]\d+)*$"  # :12 / :12-30 / :12,30 / :12+ / :12,30-50
 )
 
+# Bug B 修复(2026-08-08):上面那条只剥「锚定行尾的纯数字」,漏两类真实写法——
+#   data/numbers.yaml:130 combined_rate_cap: 0.95   (行号后还跟内容)
+#   lib/.../sect_screen.dart:_MemberRow             (冒号后是符号名不是数字)
+# 两类的基底文件都真实存在却被判死链。改为:只要「已知扩展名 + 冒号」就在冒号处截断。
+_RE_STRIP_COLON_SUFFIX = re.compile(
+    r"^(.*?\.(?:" + _EXT_ALT + r")):.*$"
+)
+
 # 剥字段后缀:已知扩展名后再有 .xxx 的剥掉
 # data/skills.yaml.powerMultiplier → data/skills.yaml
 # 注意只剥 1 段,若有 .a.b.c 多段后缀也只剥尾段(更通用做法递归剥)。
@@ -290,6 +298,11 @@
     target = _RE_STRIP_ANCHOR.sub("", target)
     # 2) 剥 :行号
     target = _RE_STRIP_LINENO.sub("", target)
+    # 2b) Bug B 修复:「已知扩展名 + 冒号」一律在冒号处截断,覆盖 :Symbol 与
+    #     :行号+内容 两类((2) 只处理锚定行尾的纯数字,这两类漏网)。
+    m_colon = _RE_STRIP_COLON_SUFFIX.match(target)
+    if m_colon:
+        target = m_colon.group(1)
     # 3) 剥字段后缀(已知扩展名后的 .xxx)
     # 递归剥(最多剥 3 段,避免死循环)
     for _ in range(3):
@@ -524,7 +537,18 @@
 
     # 第三遍:批量 check-ignore 过滤
     not_alive_targets = {r["target"] for r in not_alive}
-    ignored_targets = git_check_ignore(not_alive_targets)
+    # Bug A2 修复(2026-08-08):文档里裸写目录名(如 `build`,无尾斜杠)时,
+    # `git check-ignore build` 对 `build/` 这类目录型模式**只在该目录物理存在时**
+    # 才命中 → 扫描结果随工作树漂移,违反 tools/README 自述的「任何 worktree 结果一致」。
+    # 故对每个 target 额外用 `target + "/"` 再查一次:目录型模式对带斜杠的路径
+    # 是纯模式匹配,与物理存在无关。
+    probe_targets = set(not_alive_targets)
+    probe_targets |= {t + "/" for t in not_alive_targets if not t.endswith("/")}
+    _ignored_raw = git_check_ignore(probe_targets)
+    ignored_targets = {
+        t for t in not_alive_targets
+        if t in _ignored_raw or (t + "/") in _ignored_raw
+    }
     ignored_count = 0
     ignored_rows: list[dict] = []
     dead_rows: list[dict] = []
```
