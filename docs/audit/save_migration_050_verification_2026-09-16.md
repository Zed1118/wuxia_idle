# 存档迁移 0.50.0 复验记录（2026-09-16 整理）

> 目的：把 09-13 修复 `54aed6b51`（主页启动挂起 + 战备刷新覆盖收益账本）之后已经做过、但未写进仓库的原生迁移复验记录下来，并明确它对真实存档的证据边界。整理者未启动任何游戏、未打开/复制/修改任何真实存档；真实三档只做了一次只读 sha256。

## 结论（分两层，不得混用）

| 层 | 结论 | 依据 |
|---|---|---|
| 候选迁移逻辑（0.49→0.50、0.40→0.50） | **PASS** | 两套夹具各做「冷开→退出→再开→退出」，规则化字段审计 4/4 PASS、`unexpectedDifferences=[]`；原件与被保护文件哈希不变 |
| 用户真实三档迁移 | **未验证** | 真实三档为 `0.40.0`，且 09-13 误启事故后字节已变；两套夹具都不是真实档文件 |

## 复验事实（证据根目录 `~/Documents/Codex/2026-09-13/p2-ci-recovery/resume-native/`）

- 代码：`54aed6b51`（`fixed-package-production-evidence.json` 记 `changedProductionSourcesPresentInKernel=true`，AOT 内核哈希 `a0de5026…`）。当前链 `522c3ad40` 的 `_currentSaveVersion` 仍为 `0.50.0`（`lib/data/isar_setup.dart:252`），修复后未再升版。
- 输入 A「049」：由独立旧版（0.49 生产菜单）新建的工程档，sha256 `c7f319ed…`，独立容器 `com.pen.wuxia.migrationfix04920260913`。
- 输入 B「Legacy」：桌面备份 `~/Desktop/wuxia_save_backup_20260828/wuxia_save_slot1.isar`，`0.40.0`，sha256 `9a79f3e1…`，6 角色 / 97 装备 / 76 心法 / 105 事件 / 13 结算日志，独立容器 `com.pen.wuxia.migrationfixlegacy20260913`。
- 四个阶段的 `field-audit.json`（26 个集合，`ignoredFields=[]`）：

| 阶段 | saveVersion | 原始差异数 | 规则归因 | 审计判定 |
|---|---|---|---|---|
| 049 首开→退出 | 0.49.0→0.50.0 | 21 | 版本/锚点/余数迁移 + 3 条装备图鉴骨架 + 6.30h 离线结清（+18 EXP、+1 磨剑石）+ 7 条解锁基线 | PASS |
| 049 再开→退出 | 0.50.0 | 14 | 0.03h 离线结清（+1 EXP）；身份/首次时间保持，观察时间前进 | PASS |
| Legacy 首开→退出 | 0.40.0→0.50.0 | 88 | 51 条 tombstone 与哨兵默认值、桃花岛产物余额 + 392.98h 离线结清（+3018 EXP、+251 磨剑石）+ 7 条解锁基线 | PASS |
| Legacy 再开→退出 | 0.50.0 | 12 | 0.025h 离线结清（0 EXP）；仅祖师伤势恢复 | PASS |

- `all-differences.json` 是原始逐字段 diff，判定字段固定为 `REVIEW_REQUIRED`（它不带规则）；`field-audit.json` 是对同一差异集的规则归因，两者差异数一致。集合计数在全部阶段前后相同。
- 每个 receipt 均记 `protectedOriginalsUnchanged=true`、`originalInputUnchanged=true`、`coldCopy=true`。

## 真实存档现状（只读，2026-09-16）

| 档 | 文件 mtime | 当前 sha256 | 版本 | 事故前精确备份 |
|---|---|---|---|---|
| slot1 | 09-13 16:40 | `509be321…` | 0.40.0 | 有（`native-incident/verified-before/`，逐记录零差异） |
| slot2 | 09-13 16:40 | `7d623e76…` | 0.40.0 | 无 |
| slot3 | 09-13 16:40 | `cbfc2298…` | 0.40.0 | 无 |

事故经过与处置见 `native-incident/report.md`：旧 schema 打开导致物理文件变化，slot1 已证明逻辑数据无差异，slot2/3 无法证明无损但也无证据受损。

## 把真档搬上新候选前必须做的事（待用户授权）

1. 用同一管线对**当前**真实 slot1/2/3 的冷副本各跑一遍「首开→退出→再开→退出」+ 26 集合字段审计，输出与上表同格式的 PASS/REVIEW。管线只打开临时副本，原档不动，但复制原档本身需要用户明确授权。
2. 三档全 PASS 后，先冷备份三档（sha256 入册），再用正式 bundle id 打开一次；打开后立即再做一次前后字段审计。
3. 任一档 REVIEW_REQUIRED 中出现规则外差异 → 停，不得靠「可读」代替无损。

## 本记录不代表

- 不代表 M2/M8/M9 任何门关闭；正式 M0–M9 仍 1/10。
- 不代表 Windows 平台迁移；不代表 slot2/3 事故前后无损。
