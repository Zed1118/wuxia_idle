# 派单包 · E2 真机打局录屏验收管线(2026-08-28)

## §0 身份与总纪律

把 D1 单里已验证的 CGEvent 驱动能力**沉淀成仓内工具**,补上录屏与关键帧,首用例跑通一局真实战斗。

- **唯一基线**:`1ba913a633beb0fd8f9b47764161f47c54260707`
- 分支 `codex/p2-e2-playtest-capture-pipeline-20260828`,worktree `/Users/a10506/Desktop/Projects/挂机武侠-e2-capture`
- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **不得修改 `~/.claude/skills/` 下任何文件**
- commit message **中文动宾**;tip 前缀 `[READY]` 或真实 `[BLOCKED]`
- **本单零 `lib/` 改动**,只写 `tools/` 与 `docs/`。需要改生产才能推进 → 停下报告。

## §1 为什么派这个

真人试玩当前被挂账(输入现象未定性,见 `docs/audit/playtest_input_blocker_diagnosis_20260828.md`)。
有了自动打局 + 录屏,执行端可以产出可回放证据,协调者看录像做验收,不必阻塞在真人手打。

## §2 事实底座(2026-08-28 协调者实测,别转抄,自己复核)

- `tools/visual_capture/` 已有 **17 个文件**的成熟**静态截图**管线:
  `visual_capture.sh`(多分辨率 `1280x720,1440x900,1920x1080,2560x1080`、`--route`、
  `--existing-window`、ready 等待、lock state)、`window_id.swift`、`crop_window_content.py`、
  `write_visual_capture_manifest.py` 及各自的 `*_test`。
  **这套不要重造,能复用的一律复用**(窗口定位、裁剪、manifest、锁)。
- 实测 `grep -rln "screencapture -v|录屏|video|\.mov" tools/` 对本管线**零命中** → **确实没有录屏能力**。
- `tools/playtest/` 下当前只有 `decision_session.sh`(25KB)。
- D1 单分支 `codex/p2-d1-input-blocker-diagnosis-20260828` 里已实测跑通:
  CGEvent 发键与发鼠标、每次动作前用 `CGWindowListCopyWindowInfo` 重读 bounds、
  跨屏 scale 变化(实测窗口从 `(320,139) scale=2` 移到 `(2880,195) scale=1`)。
  **那是临时脚本,未入仓**;本单要把它做成正式工具。

## §3 任务

### E2-1 打局驱动工具入仓

`tools/playtest/` 下新增驱动脚本,能力至少覆盖:

- 按脚本化动作序列发键/发鼠标(CGEvent),动作间可指定间隔
- **每次动作前重读窗口 bounds 与 scale**,不得缓存(跨屏会变,D1 已实测)
- 启动/等待 app ready、结束时干净退出
- 失败可诊断:每步落日志(时间戳、动作、当时 bounds)

### E2-2 录屏 + 关键帧

- 全程录屏落文件
- 按动作序列的时间戳抽关键帧(至少覆盖:入关、首次接敌、技能释放、结算)
- 产物写进 manifest(沿用 `write_visual_capture_manifest.py` 的体例,含 sha256、tree、dirty 标记)

### E2-3 首用例跑通

首用例 = **`stage_01_03` 黑风岭**一局真实战斗,从生产入口进(主菜单 → 继续江湖/章节地图 → 第一章),
**不走 debug/demo 路由**。产出录屏 + 关键帧 + manifest。

塔的用例本单不做(塔当前层数与 `data/towers.yaml` 结构需另行确认,不在本单范围)。

## §4 存档保护(第一步,不做完不许往下)

app 是**沙盒**应用 `com.pen.wuxia.wuxiaIdle`,**所有 build 共享同一存档容器**:
`~/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/Documents/wuxia_save_slot{1,2,3}.isar`

`slot1` 是用户第 8 章真实存档。开工基准 sha256 前缀 `9a79f3e1`(协调者 2026-08-28 实测)。

1. `pkill -f "wuxia_idle.app/Contents/MacOS/wuxia_idle"`,确认进程退干净
2. 做**冷备**并记三个 slot 的完整 sha256
3. 每轮驱动后停进程、从冷备精确恢复、`cmp` 校验
4. 收工前后各核一次,**任何残留差异必须在 receipt 与报告里显式声明**

D1 单已经完整跑通这套恢复流程并做到收工 SHA 与开工完全一致,照做。

## §5 边界

- **只写 `tools/` 与 `docs/`**,零 `lib/` 改动
- 不改 `tools/visual_capture/` 现有脚本的既有行为(可新增文件、可复用其函数;
  若必须改共用文件,只允许**纯增量**,且不得改变现有调用方的行为)
- 不把驱动脚本接进 CI
- 证据产物(录屏/截图)**不进 git**,只进 `build/` 并在 manifest 里登记

## §6 `[BLOCKED]` 出口

- 需要改生产 `lib/` 才能驱动
- 录屏需要的系统权限拿不到(屏幕录制授权)→ 说明缺什么权限,不要硬绕
- 存档恢复失败或出现无法解释的残差
- 首用例进不去黑风岭(例如存档进度不满足)→ 报告实际卡点,不要改存档凑条件

## §7 收工流程

1. commit(中文动宾)
2. 工具必须有自测:`tools/` 下新增脚本需配 `*_test`(沿用现有 `*_test.py` / `*_test.sh` 体例),
   并做**双向破坏证红**(删实现支点 / 强制退化值),两向实测变红并记失败数,
   随后精确反向补丁还原;禁 `git reset --hard` / `checkout --` / `revert`
3. `flutter analyze --no-pub lib test tool`
4. `dart format --output=none --set-exit-if-changed .`(整仓 `.`)
5. 全量 `flutter test --no-pub`。**跑前建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除;
   发现锁存在就等**——本批有另一道单(E1)在并行,两道不得同时跑全量
6. `git diff --check <base>..<head>`
7. 写 `receipt.yaml` 并 commit,tip 打标记,worktree clean

**退出码 0 不算成功**:逐条读 reporter 最后一行原文与 `[E]` 块计数。
**receipt 类型**:零 `lib/` 路径 → **审计单**(`break_red` 留空 + 恰好一个 `audit_verification` 块)。

## §8 环境

```bash
export LC_ALL=en_US.UTF-8      # 设成 C 会让 CocoaPods 在中文路径崩(D1 实测)
# 不要设 DEVELOPER_DIR
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <worktree>/
cd <worktree> && flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter build macos --debug
```

## §9 并发约束

本批 E1/E2 两道并行,域不相交(E1 = `docs/audit` + `test/`;E2 = `tools/playtest` + `docs`)。
**同一时刻只允许一道跑全量**(§7 的锁)。`build_runner`、全量测试、`flutter build macos` 三者不并行。
你不得去动 E1 的 worktree 或分支。

## §10 我会怎么验收

独立复跑工具自测 + 自己再做一次破坏证红;
**亲自用你的工具跑一次首用例**,核录屏与关键帧是否真的产出、manifest 是否自洽;
核存档三个 slot 的 sha256;核零 `lib/` 改动与禁区零 diff。
工具跑不起来、或只在你那台环境的特定状态下能跑,直接打回。
