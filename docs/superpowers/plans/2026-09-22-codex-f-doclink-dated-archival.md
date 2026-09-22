# 派单 F-续：日期归档规则恢复点

- 目标：落实来源 basename 短横日期归档规则、两层固定样例及六处活文档引用处置。
- 分支：codex/doclink-dated-archival-20260922
- 基线：8d8ae91951950d0fa8113e689491061da8047783
- 续办起点：0b3b4d905；前轮阻塞台账提交 7d403d76f 保留在历史中。
- 状态：READY（实现、定向验证、S′ 提交后证红和还原复测完成；收据与本恢复点由 R′ 包装）。
- 最后完成：219 条失效引用按来源文件名转归档，六条活文档引用串改为附证据的纯文本，台账重写为 RESIDUE_CLOSED（57 行），README 仅更新第 13/14 行。
- 下一步：协调者以本次 F-续白名单对 S′ / R′ 执行 Gate 与独立证红；执行端完成包装后冻结分支，不推送或合并。
- 阻塞项：无；原包计数差额已由本次补授权及归档预期 1801 更正解决。

## 验收标准与任务切片

1. 已核对分支、tip 与 clean 工作树，续办基线扫描 dead 225 / archival 1582 / md 1832，两层测试 19 / 20 通过。
2. 已接入 scan 唯一归档分类点：五目录或来源 basename 短横日期任一命中，活文档、八位无横日期与目录日期边界保留；不改排除、清洗、JSON key 或明细列结构。
3. 已新增固定样例 7+1，两层合计 26 / 21 通过；既有 39 例无删除或放宽。S′ 提交后须验证去掉日期判据时前缀/后缀/中缀三例及真 git 新例必红，还原后重跑绿。
4. 六处改文严格锁定原行与引用串；全部任务文件受 F-续白名单限制，最终 S′ 与 R′ 均用 [READY] 中文动宾消息，R′ 父提交必须是 S′，结束工作树 clean。

## 已跑验证（三条命令原文）

```text
python3 tools/doc_link_scan.py
============================================================
docs/ 内部引用死链扫描报告
============================================================

汇总:
  扫描 md 文件数:  1832
  引用总数(存活+死+ignored+归档):  12366
  ├─ 存活(已跟踪):  9784
  ├─ ignored(gitignored,不计死链):  781
  ├─ 归档类(归档文档内的失效引用,不进修复清单):  1801
  └─ 死链(未跟踪且未被 ignore):  0
  跳过类(通配/模板/worktree 名等):  607
    (其中出 repo 边界:  102)
  已跟踪文件总数(参考):  5549

跳过类分布:
  wildcard                        445
  template<>                      125
  absolute                        101
  ellipsis                        21
  template[]                      8
  range a..b                      3
  out-of-repo                     2
  worktree@hex                    2
  out-of-repo (../)               1
  placeholder seg:X               1

按 docs 一级子目录分布:
  子目录                         引用数        死链数        归档类
  (top)                       103          0          0
  art                          11          0          7
  art_ref                       1          0          0
  audit                      2835          0        130
  dispatch                   1048          0        120
  handoff                    2760          0        700
  phase0                       74          0          7
  sessions                    371          0         60
  spec                       1304          0        205
  superpowers                3859          0        572

python3 tools/test_doc_link_scan.py
..........................
----------------------------------------------------------------------
Ran 26 tests in 0.022s

OK

python3 tools/test_doc_link_scan_gitfixture.py
.....................
----------------------------------------------------------------------
Ran 21 tests in 0.919s

OK
```

三条命令退出码均为 0；没有运行 flutter、dart、游戏 GUI 或正式 Gate。

## 明细复核与影响说明

- 规则单独生效时：dead 225→6、archival 1582→1801；逐条对应 docs/spec 205、docs/phase0 7、docs/art 7，恰为 219 条。其余 JSON 字段与原 1582 条归档明细不变。
- 六处纯文本处置后：dead 6→0、refs_total 12372→12366；存活 9784、ignored 781、md 1832 及跳过类均不变。两份台账/恢复点已在续办起点跟踪，本轮不增加扫描源。
- 生产接线：tools/doc_link_scan.py 的 scan 第三遍分类在存在性与 ignored 判定之后消费 ARCHIVAL_DATED_NAME；两层测试均调用真实 scan，真 git 新例实际跟踪并提交文档。
- 证据：ca548a3a7 删除两测试文件；d3cde5a33 删除七张心法 cover 与 .gitkeep；截图目录与 inner_demon 素材目录在当前可达全部 Git 历史查询无记录；Windows Profile 脚本第 94/97 行定位并散列 data/app.so 构建载荷。
- 红线影响：只改 Python 工具/测试和 Markdown/YAML 交付文件，不触及游戏数值、三系锁死、在线离线、反主流约束或 Dart 文案配置。
- 残留风险：归档保留历史失效引用；此候选仅证明扫描分类与文档处置完成，协调者正式 Gate、集成与人类验收未执行。

## S′ 提交后证红与包装

- S′：cd913f0f4c83de1b508fa3c8d30d9358376e5671，消息为 [READY] 落实带日期文档归档并处置六处活文档引用；本轮实质改动 10 文件，相对 base 累计 11 文件（包含前轮已添加的收据），均在 F-续白名单内。
- 证红时 HEAD 已等于 S′，工作树 clean；只摘掉 scan 分类点的 or _has_archival_dated_name(ref["file"])，未改常量、目录判据或测试。以下为原始失败摘要，两条命令均退出 1：

```text
python3 tools/test_doc_link_scan.py
FAIL: test_dead_reference_in_date_infix_doc_is_archival
FAIL: test_dead_reference_in_date_prefix_doc_is_archival
FAIL: test_dead_reference_in_date_suffix_doc_is_archival
Ran 26 tests in 0.022s
FAILED (failures=3)

python3 tools/test_doc_link_scan_gitfixture.py
FAIL: test_missing_reference_in_tracked_dated_doc_is_archival
Ran 21 tests in 0.924s
FAILED (failures=1)
```

- 随后从证红前保存的字节精确还原生产文件，并与 git show S′:tools/doc_link_scan.py 对照相等；工作树恢复 clean。重新扫描的 JSON 与实质提交前逐字段完全一致（dead 0 / archival 1801），两层完整复跑原文如下，均退出 0：

```text
python3 tools/test_doc_link_scan.py
..........................
----------------------------------------------------------------------
Ran 26 tests in 0.021s

OK

python3 tools/test_doc_link_scan_gitfixture.py
.....................
----------------------------------------------------------------------
Ran 21 tests in 0.946s

OK
```

- 收据 head_sha 绑定 S′，changed_files 由 base..S′ 全部路径生成；三个 last_line 为 NOT_RUN，error_block_count 为 0，break_red 一组 remove_implementation，实测 failed_count 4 / RED_CONFIRMED。
- audit_verification：git diff --check base..S′ 退出 0；按固定 binary/full-index/no-renames 命令所得 patch SHA-256 为 7e4748f10877878fddbf85805118c92ba0bbaf42cceec3808c62c184aaa903e6。
- R′ 仅包装收据与本恢复点，父提交为 S′；不触碰实质文件。正式 Gate、Flutter/Dart 与 GUI 均未运行。
- 仅提取现行 gate.sh 内嵌 Python 收据校验器做对撞，实测 matched; full_test fields skipped; doc-only audit: NOT_RUN accepted for analyze_last_line,format_last_line (Gate's own run is authoritative)；未执行 Gate 主流程及其 Flutter 命令。
