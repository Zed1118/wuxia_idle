# visual_capture

本工具用于 Flutter macOS 视觉验收截图。它会对每个 `VISUAL_ROUTE`
启动 macOS debug app，等待 `VISUAL_ROUTE_READY` 后截图，并输出到指定目录。

当前截图链路：

1. 启动前传入 `VISUAL_WINDOW_W/H`，由 `macos/Runner/MainFlutterWindow.swift`
   锁定原生窗口逻辑尺寸。
2. 用 `tools/visual_capture/window_id.swift` 通过 CGWindowList 获取 app 主窗口
   CGWindowID。
3. 用 `screencapture -x -o -l<window_id>` 截干净窗口。
4. 若窗口截图失败，先用 `lock_state.py` 判定会话锁屏态并把
   锁屏态、`window_id` 返回值、窗口截图退出码/字节数写进 route log
   （前缀 `VISUAL_CAPTURE_DIAG:`）。**锁屏时不走区域 fallback 直接硬失败**
   （记 `VISUAL_CAPTURE: all_failed:lock=locked`）：`screencapture -R` 锁屏时必死
   （2026-08-12 audit 8 采样完美相关），且锁屏下 osascript 摆不了窗口，
   `(0,0,W,H)` 几何前提不成立——救不出正确画面，明着失败优于错图。
   未锁时才退回区域截图，成功记 `VISUAL_CAPTURE: fallback_region`；
   两者都失败则记 `VISUAL_CAPTURE: all_failed:lock=<unlocked|unknown>` 并以非零码
   硬失败，**不再进入 `crop_window_content.py`**（避免 PNG 不存在时 PIL
   `FileNotFoundError` 盖住真实原因）。锁屏下窗口截图本身照常成功，
   无人值守时段应优先依赖窗口路径（如 `--background`）。
   锁屏判定：`ioreg -n Root -d1 -w0` 的 `IOConsoleUsers` 字典是否含键
   `CGSSessionScreenIsLocked`（未锁时该键整个不存在，只能判有无，不能比值；
   ioreg 失败/空输出一律判 `unknown`，绝不错报未锁）。
5. 截图结束后默认生成 `<output>/fidelity_manifest.json`（`schema_version: 3`），记录
   commit、**tree/dirty**、route、seed/tick、逻辑视口、DPR、原生窗口 ID、截图方式及
   PNG/log SHA-256。

   **为什么单有 commit 不够**：抓图几乎总发生在「改完但还没 commit」的时刻，
   此时 `git rev-parse HEAD` 指的是**上一个**代码态。2026-08-02 的
   `battle_ui_user_revision_production_boss_v5` 就是实例——manifest 记 `558885f7`，
   而图里的四项视觉改动是 7 分钟后才落成 `680ea698` 的，只能靠人眼逐像素补证。
   现在 `tree` 是工作树的真实 git tree id（`build/` 等 gitignored 产物不计入），
   `dirty` 表示它是否偏离 `HEAD^{tree}`；两者都拿不到时记为 `null`，
   **不会把「未知」写成「干净」**。计算走一次性临时 index，不动你的暂存区。

## 用法

```bash
tools/visual_capture/visual_capture.sh
tools/visual_capture/visual_capture.sh --suite full
tools/visual_capture/visual_capture.sh --route main_menu
tools/visual_capture/visual_capture.sh --suite full --resolutions 1280x720,1440x900,1920x1080
tools/visual_capture/visual_capture.sh --route phase0a_battle_playable --hitbox
tools/visual_capture/visual_capture.sh --route phase0a_battle_playable --existing-window --all-spaces --resolutions 1440x900
tools/visual_capture/visual_capture.sh --dry-run
```

常用参数：

- `--suite smoke|full`：使用 `tool/visual_acceptance.dart` 的 route suite。
- `--route <id>`：只截单个 route。
- `--resolutions <csv>`：窗口逻辑尺寸，例如 `1280x720,1920x1080`。
- `--output <dir>`：输出目录，默认 `build/visual_acceptance`。
- `--hitbox`：启用 debug-only hitbox overlay。
- `--wait <seconds>`：READY 后等待资源稳定再截图。
- `--ready-timeout <seconds>`：等待 `VISUAL_ROUTE_READY` 的最长秒数。
- `--all-spaces`：跨 macOS Space 枚举应用窗口。
- `--existing-window`：只截已运行窗口，不启动、不聚焦、不缩放、不关闭应用；与
  `--all-spaces` 合用可在桌面 1 后台截取桌面 2 的目检窗口。
- `--no-manifest`：仅在临时探针中关闭默认 manifest 输出；正式验收不得使用。

输出结构：

```text
<output>/<suite-or-route>/<resolution>/<route>.png
<output>/<suite-or-route>/<resolution>/<route>.log
<output>/fidelity_manifest.json
```

route log 中应至少包含：

```text
VISUAL_ROUTE_READY: <route>
VISUAL_CAPTURE: window_id:<id>
```

`VISUAL_CAPTURE:` 状态串有三种，用于区分截图结果：

```text
VISUAL_CAPTURE: window_id:<id>                 # 窗口截图成功（主路径，锁屏下也可用）
VISUAL_CAPTURE: fallback_region                 # 未锁时走区域 fallback 且成功
VISUAL_CAPTURE: all_failed:lock=<locked|unlocked|unknown>   # 硬失败（锁屏时跳过区域 fallback 也记此串）
```

窗口截图失败时（无论 fallback 成败）会额外写入诊断行：

```text
VISUAL_CAPTURE_DIAG: lock_state=<locked|unlocked|unknown>
VISUAL_CAPTURE_DIAG: window_id=<id|<empty>>
VISUAL_CAPTURE_DIAG: window_capture_rc=<n> bytes=<n>   # 仅当拿到 window id
```

全失败时还会追加一行 `VISUAL_CAPTURE_FAIL:`（含锁屏态与重跑建议），并以非零码
结束该路由采集。

启用 `--hitbox` 时还应包含：

```text
HITBOX_DEBUG enabled=true debug=true
```

## route 清单

route id 见 `lib/features/debug/application/visual_route.dart` 的 `VisualRoute`。
固定验收计划由 `lib/features/debug/application/visual_acceptance_plan.dart`
生成：

- `smoke`：快验入口，覆盖主菜单、心法、战斗、商店、闭关、塔、百科等高频视觉面。
- `full`：全部 `VisualRoute.values`（排除 `hub`），用于大改 UI 后完整回收。

查看计划：

```bash
flutter pub run tool/visual_acceptance.dart dry-run --suite smoke
flutter pub run tool/visual_acceptance.dart checklist --suite smoke
flutter pub run tool/visual_acceptance.dart routes --suite full --format ids
```

新增验收屏：加 `VisualRoute` 枚举值 + `VisualRouteHost` 映射。若需纳入快验，
再把 route 加进 `visual_acceptance_plan.dart` 的 `smoke` 清单。

## 固定 seed

清单中的 seed 为 `visual-route-host-fixture-20260627`。它表示 route 由
`VisualRouteHost` 里的固定 seed service / fixture 构造，同一 route 在同一代码版本下
应稳定复现。

## 依赖

- macOS `screencapture`。
- Command Line Tools 的 `swift`，用于执行 `window_id.swift`。
- Flutter macOS desktop。
- Screen Recording 权限：`screencapture`/CGWindowID 捕获需要该权限；无权限时可能失败或退回兜底。
- Python 侧只需 Pillow，用于读取截图像素尺寸并推导 DPR。

旧 Battle UI V2 的 3v3 reference/current 专用分析器、配置和测试已随路线 C 删除。
历史报告及截图仍留在 `docs/` 追溯，但不能再作为当前 Phase 0A 验收工具。

## 验证建议

```bash
bash -n tools/visual_capture/visual_capture.sh
python3 tools/visual_capture/lock_state_test.py
bash tools/visual_capture/lock_fallback_behavior_test.sh
tools/visual_capture/visual_capture.sh --route main_menu --resolutions 1920x1080 --output /tmp/wuxia_visual_probe --wait 1 --ready-timeout 180
rg "VISUAL_ROUTE_READY|VISUAL_CAPTURE" /tmp/wuxia_visual_probe/main_menu/1920x1080/main_menu.log
file /tmp/wuxia_visual_probe/main_menu/1920x1080/main_menu.png
```

锁屏 fallback 分支行为由 `lock_fallback_behavior_test.sh` 钉死（PATH stub 注入
`screencapture`/`swift`/锁屏态，无需真锁屏），改 `capture_visual_window` 后必跑。

在 Retina 屏上，`1920x1080` 逻辑窗口通常输出 `3840 x 2160` PNG。

## 产物审计

视觉验收交付包可用 `audit_visual_acceptance.py` 重建 manifest、route 覆盖校验、
Markdown/HTML 本地资源链接检查和 `verification_summary.md`：

```bash
python3 tools/visual_capture/audit_visual_acceptance.py docs/handoff/visual_acceptance_2026-06-30
```

该脚本会更新：

- `artifact_manifest.csv`
- `markdown_link_check.csv`
- `route_coverage_check.csv`
- `issue_evidence_check.csv`
- `issue_quality_check.csv`
- `issue_traceability_check.csv`
- `hitbox_coverage_check.csv`
- `contact_sheet_check.csv`
- `required_artifact_check.csv`
- `screenshot_dimension_check.csv`
- `severity_consistency_check.csv`
- `line_reference_check.csv`
- `visual_acceptance_status.json`
- `verification_summary.md`

若发现断链、full route 覆盖缺失、1920 window-id 缺失、gallery 缺图、full matrix
截图尺寸错误、问题分级不一致、本地源码行号引用失效、必需问题证据缺失、
问题字段质量错误、问题追溯缺失、hitbox 覆盖缺失，或最终门禁核心产物缺失，
拼图缺失/不可读，脚本会以非 0 exit code 退出。

最终门禁可用脚本串联执行。它会检查审计结果、Python/shell 语法、截图命令
dry-run、纸底文字对比、残留 bytecode 和 `visual_acceptance_status.json` 的 `ok` 状态：

```bash
tools/visual_capture/final_gate_check.sh docs/handoff/visual_acceptance_2026-06-30
```

该脚本会打印当前 git 工作树，但不会提交、合并、推送或删除产物。若当前时间早于
2026-06-30 09:00 CST，即使机器检查通过，也只代表门禁可通过，不代表本线程目标可标记完成。

纸底文字对比门禁由项目级脚本执行：

```bash
python3 tools/audit_paper_text_contrast.py --root .
```

它会扫描 `LightPaperPanel` / `PaperDialog` / `CeremonyImagePanel` 和显式纸色填充容器，
禁止在这些浅底区域继续使用深色场景专用的 `WuxiaColors.textPrimary` /
`textSecondary` / `textMuted`。确实嵌套了深色遮罩的个别场景，需在同行或上一行写
`// paper-text-audit: allow <reason>` 并说明原因。

## 二轮机器辅助视觉指标

已有截图可用 `analyze_visual_density.py` 生成第二轮机器辅助验收信号：

```bash
python3 tools/visual_capture/analyze_visual_density.py docs/handoff/visual_acceptance_2026-06-30
```

该脚本只读取截图，不启动 Flutter。它会更新：

- `second_pass_visual_audit.md`
- `second_pass_visual_metrics.csv`
- `contact_sheets/second_pass_machine_flags.jpg`

这些信号用于安排追加目检，不能直接替代人工视觉结论。
