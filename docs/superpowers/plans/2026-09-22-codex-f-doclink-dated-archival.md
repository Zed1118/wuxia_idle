# 派单 F：日期归档规则恢复点

- 目标：按来源文件 basename 日期扩归档类，补两层固定样例并处置五条活文档引用。
- 分支：codex/doclink-dated-archival-20260922
- 基线：8d8ae91951950d0fa8113e689491061da8047783
- 状态：BLOCKED；基线和两层测试通过，明细核对发现派单差一条。
- 最后完成：对 225 条 dead 逐条核对日期判据与剩余目标，独立核查删除提交及素材历史；仅写阻塞台账和本恢复点。
- 下一步：协调者补授权 docs/phase0/route-c-external-gate-preflight.md:13 的引用串处置，并把归档预期从 1802 更正为 1801 后重新派单；随后才实施规则、补 7+1 例、修引用和做提交后证红。
- 阻塞项：上述来源 basename 无日期，其 data/app.so 引用仍计 dead，文件又在禁改范围。触发派单第 0/5 节白名单停线条件。

## 验收标准与任务切片

1. 开局核对分支、完整基线、工作树以及三条 Python 命令；已通过。
2. 按 --rows 明细验证分类守恒；发现带日期者仅 219，原派单预期不可达，停止实现。
3. 若获修订派单，再做 basename 判据接入真实 scan 分类点、两层 26/21 例与提交后 remove_implementation 证红，保留 JSON key 和明细列结构。
4. 冻结实质提交 S，再以仅收据和恢复点的包装提交 R 交付；本次两提交均标 BLOCKED。

## 已跑验证（三条命令原文）

```text
python3 tools/doc_link_scan.py
============================================================
docs/ 内部引用死链扫描报告
============================================================

汇总:
  扫描 md 文件数:  1830
  引用总数(存活+死+ignored+归档):  12372
  ├─ 存活(已跟踪):  9784
  ├─ ignored(gitignored,不计死链):  781
  ├─ 归档类(归档文档内的失效引用,不进修复清单):  1582
  └─ 死链(未跟踪且未被 ignore):  225
  跳过类(通配/模板/worktree 名等):  607
    (其中出 repo 边界:  102)
  已跟踪文件总数(参考):  5546

python3 tools/test_doc_link_scan.py
Ran 19 tests in 0.025s
OK

python3 tools/test_doc_link_scan_gitfixture.py
Ran 20 tests in 1.256s
OK
```

三条命令退出码均为 0；没有运行 flutter、dart、游戏 GUI 或正式 Gate。

## 明细复核与影响说明

- 基线 --rows 的 225 条与 --json rows 一一对应；按来源 basename 的短横日期分组，docs/spec 205、docs/phase0 7、docs/art 7，总计 219。
- 其余六条是派单五条活文档引用，加 docs/phase0/route-c-external-gate-preflight.md:13 → data/app.so。仅按原范围实施会得 dead 1 / archival 1801，这是明细推算，未冒充实装复测。
- 新增台账和恢复点入库会使扫描 md 1830→1832；两份均无可提取路径引用，四分类与明细应保持基线完全相同。包装收据目录本就排除。
- 生产接线：未实施；因明确的停线条件，不提交不可满足原验收的部分实现。
- 定向测试：基线 19/20 全绿；新增 7+1 例及证红均未执行，收据 break_red 留空，不能捏造失败记录。
- 红线影响：仅新增 Markdown 阻塞证据，不触及游戏数值、三系锁死、在线离线、反主流约束或 Dart 文案配置。
- 残留风险：任务未实现、dead 仍为 225；本交付不能作为 READY 或 Gate 通过证据。
