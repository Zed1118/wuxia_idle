# tools/ — 本地开发辅助脚本

> 与 `tool/`(CI 消费的仓库级工具,路径被 workflows 引用)职责区分,见其 README。
> 本目录**不进 CI**,均为本地手动/会话内工具。

| 条目 | 用途 |
|---|---|
| `visual_capture/` | 视觉验收截图工具链(多分辨率 seed/驱动运行中 app 截图) |
| `audit_paper_text_contrast.py` | 宣纸底文字对比度审计 |
| `run_asset_webp_pilot.sh` | webp 转码试点脚本(正式批量转码用 `tool/convert_assets_webp.py`) |
| `pen_screen/` | 历史 Pen Windows 截图遗留(2026-06-11 该路径已下线) |
| `doc_link_scan.py` | docs/ 内部引用死链扫描器:跑 `python3 tools/doc_link_scan.py` 出「存活/ignored/归档类/死链」四分类底账(`--json` 供 diff,`--rows`/`--ignored`/`--archival` 看明细;只用标准库+`git ls-files`/`git check-ignore`;详 `docs/dispatch/reports/2026-08-07_L1D_link_scanner.md`)。**「任何 worktree 结果一致」现已成立**——该自述曾于 2026-08-08 被实测证伪(裸写目录名如 `build` 时 ignored 判定随工作树上该目录是否物理存在而翻转,两地差 17 条),P7 补丁修复后**同一份代码在有/无 `build/` 的两地跑出逐值相同结果**(`refs=7442 alive=5929 dead=908 ignored=605`),由 `test_doc_link_scan_gitfixture.py` 红线守住。**当前定位=可引用事实源(2026-08-12 用户拍板升级,原「可试用·非终审」退役)**:别处引用本工具输出**不再需要加免责标注**。升级依据四条齐备——① 标注验证 P6 完成(90 条分层抽样 → precision 95.0% / recall 100%);② 查出的两处系统性假阳已于 2026-08-11 修复合入并由 `test_doc_link_scan_gitfixture.py` 红线守住;③ 工作树漂移归零(同一份代码两地逐值相同);④ **原唯一反对理由「`dead` 含大量归档噪声,当修复清单不可用」已由本日归档类单列消除**(`dead` 907 → 322,可直接当修复清单)。**仍须注意**:`dead` 是「未跟踪且未被 ignore」的机械判定,个别条目仍可能是写法特殊而非真失修,逐条修时按需目检;precision 95% 意味着约 1/20 条需人工否决。**归档类单列(2026-08-12)**:`ARCHIVAL_DIRS`(现仅 `docs/handoff`)下的文档照扫,但其内部失效引用单列为「归档类」不计 `dead`——归档文档的引用本就指向写作当时的仓库状态,不是文档失修;实测 907 条死链中 585 条(64.5%)由此分出,`dead` 降至 322。判据是「引用写在哪个文件里」,不是「指向哪个路径」。**范围已拍板维持只含 `docs/handoff`(2026-08-12 用户决定)**:候选过的 `docs/sessions`(28 引用/4 死)与 `docs/dispatch`(261/60)不纳入——前者收益仅 4 条,后者的 60 条里可能混着真写错的路径,一并归档就再也不会被看见;先拿 322 这份清单去修,不够干净再议。扫描源排除项真从 `EXCLUDE_DIRS` 常量派生(此前该常量定义后零消费),按目录边界匹配 |
| `test_doc_link_scan.py` / `test_doc_link_scan_gitfixture.py` | 扫描器的两层测试,均 `python3 tools/<文件>.py` 直接跑(**不进 CI**)。前者 14 例覆盖**解析层**(采集→清洗→跳过→分类,含归档类判据:判据钉在「引用写在哪个文件里」,改坏 `ARCHIVAL_DIRS` 分类必红),把 `git_ls_files`/`git_check_ignore` mock 掉;后者 17 例真起临时 git 仓覆盖**git 交互层**——P6 查出的两处假阳恰活在这层,mock 体例加样例测不出、加了也是假绿。后者的 `FixedFalsePositiveTest` 现为**防复发红线**:改坏 `doc_link_scan.py` 里 P7 那两处修复(`_RE_STRIP_COLON_SUFFIX` / `check-ignore` 补斜杠变体)必红;`ScanSourceExclusionTest` 钉住 `EXCLUDE_DIRS` 真被消费(退回硬编码必红)与目录边界匹配(裸 startswith 必红) |
