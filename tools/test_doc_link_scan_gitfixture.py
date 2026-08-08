#!/usr/bin/env python3
"""真实 git 仓 fixture 的 doc_link_scan 回归测试(不 mock 任何 git 调用)。

与同目录 `test_doc_link_scan.py` 的分工:

| 文件 | git 层 | 覆盖 |
|---|---|---|
| `test_doc_link_scan.py` | **mock** 掉 `git_ls_files`/`git_check_ignore`,临时目录无 `git init` | 解析层(采集→清洗→跳过→分类) |
| 本文件 | **真起临时 git 仓**(`git init` + 真 `.gitignore` + 真 commit),只替换 `REPO_ROOT` | git 交互层(`ls-files` 真跟踪判定、`check-ignore` 真模式匹配) |

**为什么必须单独有这层**:2026-08-08 P6 标注验证查出的两个系统性假阳
(Bug A 工作树漂移 / Bug B `:` 后缀剥不掉),恰恰活在被 mock 掉的那层真实 git 行为里
——沿用 mock 体例加再多样例也测不出,加了还是假绿。
详 `docs/dispatch/reports/2026-08-08_scanner_fp_fix_proposal.md`「四、未做/待补」。

**`expectedFailure` 的用法约定(重要)**:
下方 `KnownFalsePositiveTest` 里带 `@unittest.expectedFailure` 的用例断言的是
**修复后应有的正确行为**,在补丁未合并的当下必然红,故标为预期失败以保持主干绿。
**P7 补丁一旦合并,这些用例会变成 unittest 的 "unexpected success",整个套件随即报失败**
——那不是回归,是提醒你把装饰器删掉、让它们转为正式回归防线。

跑法(与既有体例一致,无需第三方依赖):
    python3 tools/test_doc_link_scan_gitfixture.py
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import doc_link_scan

# 提交身份与签名设置只作用于 fixture 仓自身,避免依赖用户全局 git 配置。
_GIT_IDENTITY = (
    "-c", "user.email=fixture@example.invalid",
    "-c", "user.name=fixture",
    "-c", "commit.gpgsign=false",
)


class RealGitRepo:
    """一个真实的临时 git 仓,供扫描器在其上跑真 git 命令。

    与 mock 体例的关键差别:`git_ls_files` / `git_check_ignore` **原样保留**,
    只把模块级 `REPO_ROOT` 指向本仓——这正是两个已知假阳的活动区。
    """

    def __init__(self) -> None:
        # macOS 的 /var 是 /private/var 的软链;不 resolve 会与扫描器内部
        # 已 resolve 的路径口径不一致。
        self.root = Path(tempfile.mkdtemp(prefix="doclinkscan-")).resolve()
        self._git("init", "-q")
        # 屏蔽用户全局 excludesFile,保证 check-ignore 只看本仓 .gitignore。
        self._git("config", "core.excludesFile", "/dev/null")

    def _git(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["git", *_GIT_IDENTITY, *args],
            cwd=self.root, check=True, capture_output=True, text=True,
        )

    # -- 建仓 ---------------------------------------------------------------

    def write(self, rel: str, content: str = "x\n") -> Path:
        """只写工作树,不 git add(即"存在于磁盘但未被 git 跟踪")。"""
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def mkdir(self, rel: str) -> Path:
        """只建空目录(git 不跟踪空目录,故这是纯工作树状态)。"""
        path = self.root / rel
        path.mkdir(parents=True, exist_ok=True)
        return path

    def track(self, rel: str, content: str = "x\n") -> Path:
        """写文件并 git add(尚未 commit 也已进 index,`git ls-files` 即可见)。"""
        path = self.write(rel, content)
        self._git("add", "--", rel)
        return path

    def commit(self, message: str = "fixture") -> None:
        self._git("commit", "-q", "-m", message)

    def gitignore(self, *patterns: str) -> None:
        """写 .gitignore 并跟踪它(否则它自己会被扫描器当未跟踪文件)。"""
        self.track(".gitignore", "".join(p + "\n" for p in patterns))

    # -- 跑扫描器 -----------------------------------------------------------

    def scan(self) -> dict:
        """只替换 REPO_ROOT,git_ls_files / git_check_ignore 全部真跑。"""
        with mock.patch.object(doc_link_scan, "REPO_ROOT", self.root):
            return doc_link_scan.scan()

    def cleanup(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)


class RealGitFixtureTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.repo = RealGitRepo()
        self.addCleanup(self.repo.cleanup)

    def doc(self, body: str, rel: str = "docs/source.md") -> None:
        """写一篇被扫描的源文档(必须被 git 跟踪才会进扫描源)。"""
        self.repo.track(rel, body if body.endswith("\n") else body + "\n")

    def verdict(self, result: dict) -> str:
        """把单条引用的判定压成一个词,便于断言与报错阅读。"""
        self.assertEqual(
            result["refs_total"], 1,
            f"期望恰好采集到 1 条引用,实得 {result['refs_total']} 条"
            f"(skipped={result['skipped']} reasons={result['skipped_reasons']})",
        )
        for name in ("alive", "dead", "ignored"):
            if result[name] == 1:
                return name
        raise AssertionError(f"引用未落入 alive/dead/ignored 任一类:{result}")


# ---------------------------------------------------------------------------
# 一、harness 自证:证明这层测试真的在跑 git,而不是又一层 mock
# ---------------------------------------------------------------------------

class RealGitHarnessTest(RealGitFixtureTestCase):
    """这三条的作用是**证明 fixture 有负载**。

    若哪天有人把 git 调用重新 mock 掉,或 fixture 建仓失败退化成空跑,
    这三条会立刻红——它们的结论在 mock 体例下无法得出。
    """

    def test_untracked_file_on_disk_is_dead_not_alive(self) -> None:
        """文件真实存在于磁盘、但未被 git 跟踪 → 死链。

        证明存在性判定走的是 `git ls-files` 而非文件系统。
        """
        self.repo.write("lib/on_disk_only.dart")  # 只写盘,不 add
        self.doc("`lib/on_disk_only.dart`")
        self.assertEqual(self.verdict(self.repo.scan()), "dead")

    def test_real_gitignore_pattern_is_honoured(self) -> None:
        """`.gitignore` 的通配模式由真 `git check-ignore` 解释 → ignored 而非死链。"""
        self.repo.gitignore("*.log")
        self.doc("`tools/debug.log`")
        self.assertEqual(self.verdict(self.repo.scan()), "ignored")

    def test_untracked_source_doc_is_not_scanned(self) -> None:
        """源文档未被 git 跟踪 → 根本不进扫描源(scanned_files 为 0)。

        证明 `collect_scan_files` 吃的是真 `git ls-files` 输出。
        """
        self.repo.write("docs/untracked.md", "`lib/whatever.dart`\n")
        # 仓里得有至少一个 tracked 文件,否则 ls-files 为空无从区分
        self.repo.track("docs/other.md", "无引用\n")
        result = self.repo.scan()
        self.assertEqual(result["scanned_files"], 1)
        self.assertEqual(result["refs_total"], 0)


# ---------------------------------------------------------------------------
# 二、当前已正确的行为:锁住,防 P7 补丁或后续改动把它们改坏
# ---------------------------------------------------------------------------

class RealGitVerdictRegressionTest(RealGitFixtureTestCase):
    def test_tracked_file_reference_is_alive(self) -> None:
        self.repo.track("lib/main.dart")
        self.doc("`lib/main.dart`")
        self.assertEqual(self.verdict(self.repo.scan()), "alive")

    def test_missing_file_reference_is_dead(self) -> None:
        self.doc("`lib/nope.dart`")
        self.assertEqual(self.verdict(self.repo.scan()), "dead")

    def test_tracked_directory_reference_is_alive(self) -> None:
        """引用一个目录,只要其下有已跟踪文件即算存活。"""
        self.repo.track("lib/features/battle/engine.dart")
        self.doc("`lib/features/battle/`")
        self.assertEqual(self.verdict(self.repo.scan()), "alive")

    def test_path_under_gitignored_dir_is_ignored(self) -> None:
        """`build/` 目录型模式对**其下的路径**本就正常命中,与目录是否存在无关。

        这是 Bug A 的对照组:同一条 `.gitignore` 规则,写成 `build/outputs/x.png`
        正常归 ignored,写成裸 `build` 才出问题(见下一个 TestCase)。
        """
        self.repo.gitignore("build/")
        self.doc("`build/outputs/x.png`")
        self.assertEqual(self.verdict(self.repo.scan()), "ignored")

    def test_plain_lineno_suffix_is_stripped(self) -> None:
        """`文件:行号`(冒号后是纯数字且到行尾)当前已能正确剥掉。

        这是 Bug B 的对照组:证明问题只出在「行号后还跟内容」与「冒号后是符号名」
        两类,不是整个剥行号逻辑失效。
        """
        self.repo.track("data/numbers.yaml")
        self.doc("`data/numbers.yaml:130`")
        self.assertEqual(self.verdict(self.repo.scan()), "alive")


# ---------------------------------------------------------------------------
# 三、两个已知系统性假阳(P7 补丁的验收面)
# ---------------------------------------------------------------------------

class KnownFalsePositiveTest(RealGitFixtureTestCase):
    """P6 查出、协调者独立复现成立的两个假阳。

    每个 bug 配两条用例:
      - `..._reference_is_collected`(**不带**装饰器)——只断言引用被采集进判定环节。
        它的作用是防止 `expectedFailure` 把「fixture 或解析层坏掉」也一并吞掉:
        真出那种问题时,这条会红在明面上。
      - `..._should_be_...`(**带** `@unittest.expectedFailure`)——断言修复后的正确判定。
        P7 合并后它会变成 unexpected success,套件报失败,提醒删掉装饰器。
    """

    # -- Bug A:裸目录引用的判定随工作树漂移 --------------------------------

    def _bare_build_repo(self, *, create_dir: bool) -> RealGitRepo:
        self.repo.gitignore("build/")
        self.doc("`build`")
        if create_dir:
            self.repo.mkdir("build")
        return self.repo

    def test_bare_gitignored_dir_reference_is_collected(self) -> None:
        self._bare_build_repo(create_dir=False)
        result = self.repo.scan()
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual([r["target"] for r in result["rows"]] or
                         [r["target"] for r in result["ignored_rows"]], ["build"])

    @unittest.expectedFailure
    def test_bare_gitignored_dir_is_ignored_when_directory_absent(self) -> None:
        """裸写 `build` 且工作树上没有 build/ 目录时,应判 ignored。

        当前实际:`git check-ignore build`(无尾斜杠)对 `build/` 这类目录型模式
        只在该目录物理存在时才命中 → 判成死链。
        修法见提案「改动 2(Bug A2)」:查询侧额外补 `target + "/"` 变体。
        """
        self._bare_build_repo(create_dir=False)
        self.assertEqual(self.verdict(self.repo.scan()), "ignored")

    @unittest.expectedFailure
    def test_bare_gitignored_dir_verdict_is_worktree_independent(self) -> None:
        """同一份 git 内容,判定不应随工作树上是否存在 build/ 目录而变。

        这条直指 `tools/README.md:12` 自述的「任何 worktree 结果一致」。
        当前实际:目录不存在 → dead,目录存在 → ignored,两地不一致。
        """
        self._bare_build_repo(create_dir=False)
        without_dir = self.verdict(self.repo.scan())
        self.repo.mkdir("build")
        with_dir = self.verdict(self.repo.scan())
        self.assertEqual(
            without_dir, with_dir,
            f"判定随工作树漂移:无 build/ 目录时={without_dir},有 build/ 目录时={with_dir}",
        )

    # -- Bug B:`:` 后缀剥不掉 ----------------------------------------------

    def test_colon_symbol_suffix_reference_is_collected(self) -> None:
        self.repo.track("lib/features/sect/presentation/sect_screen.dart")
        self.doc("`lib/features/sect/presentation/sect_screen.dart:_MemberRow`")
        self.assertEqual(self.repo.scan()["refs_total"], 1)

    @unittest.expectedFailure
    def test_colon_symbol_suffix_is_stripped(self) -> None:
        """`文件.dart:_Symbol` 的基底文件存在时应判存活。

        当前实际:`_RE_STRIP_LINENO` 只剥「锚定行尾的纯数字」,冒号后是符号名时
        整串拿去查 → 死链。修法见提案「改动 1(Bug B)」。
        """
        self.repo.track("lib/features/sect/presentation/sect_screen.dart")
        self.doc("`lib/features/sect/presentation/sect_screen.dart:_MemberRow`")
        self.assertEqual(self.verdict(self.repo.scan()), "alive")

    def test_colon_lineno_with_trailing_content_reference_is_collected(self) -> None:
        self.repo.track("data/numbers.yaml")
        self.doc("`data/numbers.yaml:130 combined_rate_cap: 0.95`")
        self.assertEqual(self.repo.scan()["refs_total"], 1)

    @unittest.expectedFailure
    def test_colon_lineno_with_trailing_content_is_stripped(self) -> None:
        """`文件.yaml:130 字段: 值` 的基底文件存在时应判存活。

        当前实际:行号后还跟内容,`:\\d+$` 的行尾锚定失效 → 整串查 → 死链。
        """
        self.repo.track("data/numbers.yaml")
        self.doc("`data/numbers.yaml:130 combined_rate_cap: 0.95`")
        self.assertEqual(self.verdict(self.repo.scan()), "alive")


if __name__ == "__main__":
    unittest.main()
