# tools/ — 本地开发辅助脚本

> 与 `tool/`(CI 消费的仓库级工具,路径被 workflows 引用)职责区分,见其 README。
> 本目录**不进 CI**,均为本地手动/会话内工具。

| 条目 | 用途 |
|---|---|
| `visual_capture/` | 视觉验收截图工具链(多分辨率 seed/驱动运行中 app 截图) |
| `audit_paper_text_contrast.py` | 宣纸底文字对比度审计 |
| `run_asset_webp_pilot.sh` | webp 转码试点脚本(正式批量转码用 `tool/convert_assets_webp.py`) |
| `pen_screen/` | 历史 Pen Windows 截图遗留(2026-06-11 该路径已下线) |
| `doc_link_scan.py` | docs/ 内部引用死链扫描器:跑 `python3 tools/doc_link_scan.py` 出「存活/死链/ignored」分类底账(`--json` 供 diff,`--rows`/`--ignored` 看明细;只用标准库+`git ls-files`/`git check-ignore`;详 `docs/dispatch/reports/2026-08-07_L1D_link_scanner.md`)。⚠ **原自述「任何 worktree 结果一致」已于 2026-08-08 实测证伪**:文档里裸写目录名(如 `build`,无尾斜杠)时 ignored 判定随工作树上该目录是否物理存在而翻转,主 checkout 与 fresh worktree 实测差 17 条(证伪范围仅限 `check-ignore` 一步;扫描源收集确实与工作树解耦)。**当前定位=可试用,非终审事实源**(该定位是否升级属待拍板项):标注验证已由 P6 完成(90 条分层抽样 → precision 95.0% / recall 100%),两处系统性假阳已定位、修复补丁已备待拍板(滚动池 P7);引用其输出时须标「含两处已知假阳,修复未合」 |
| `test_doc_link_scan.py` / `test_doc_link_scan_gitfixture.py` | 扫描器的两层测试,均 `python3 tools/<文件>.py` 直接跑(**不进 CI**)。前者 10 例覆盖**解析层**(采集→清洗→跳过→分类),把 `git_ls_files`/`git_check_ignore` mock 掉;后者 15 例真起临时 git 仓覆盖**git 交互层**——两处已知假阳恰活在这层,mock 体例加样例测不出。后者含 4 条 `expectedFailure`(断言 P7 修复后的正确判定),**P7 补丁合并后它们会转成 unexpected success 使套件退出码变 1**,以此提醒删掉装饰器转为正式回归防线 |
