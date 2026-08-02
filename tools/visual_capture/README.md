# visual_capture

本工具用于 Flutter macOS 视觉验收截图。它会对每个 `VISUAL_ROUTE`
启动 macOS debug app，等待 `VISUAL_ROUTE_READY` 后截图，并输出到指定目录。

当前截图链路：

1. 启动前传入 `VISUAL_WINDOW_W/H`，由 `macos/Runner/MainFlutterWindow.swift`
   锁定原生窗口逻辑尺寸。
2. 用 `tools/visual_capture/window_id.swift` 通过 CGWindowList 获取 app 主窗口
   CGWindowID。
3. 用 `screencapture -x -o -l<window_id>` 截干净窗口。
4. 若窗口 ID 捕获失败，退回区域截图并在 route log 中记录
   `VISUAL_CAPTURE: fallback_region`。
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
tools/visual_capture/visual_capture.sh --route battle_scene --hitbox
tools/visual_capture/visual_capture.sh --route battle_scene --existing-window --all-spaces --resolutions 1440x900
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
- Python 侧需要 Pillow、NumPy 与 OpenCV (`cv2`)；OpenCV Canny 固定使用 50/150 阈值，
  以复现报告中的边缘 IoU 基线。

## Battle UI 95+ reference/current 证据

`analyze_battle_v2_fidelity.py` 默认是严格 reference 模式：manifest 必须包含配置中的
`battle_tap_live`，母版 SHA 必须匹配，且 current 与 reference 若为同一 PNG 会直接失败。
它会把 Retina current 缩回逻辑视口、将唯一母版 cover-center 对齐，然后按母版
`y=60 / y=700` 等比切分顶栏、战场和案台。

```bash
python3 tools/visual_capture/analyze_battle_v2_fidelity.py \
  --manifest build/visual_acceptance/battle_sample_95/fidelity_manifest.json \
  --output build/visual_acceptance/battle_sample_95/analysis
```

标准输出包包括：

- `fidelity_manifest.json`：分析时消费的输入清单；
- `fidelity_metrics.json`：RGB/LAB、Delta E、MAE、Canny 边缘 IoU、结构锚点与 Gate；
- `fidelity_report.md`：机器证据与待填人工评分表；
- `diff_full.png`、`diff_header.png`、`diff_field.png`、`diff_desk.png`；
- `reference_current_side_by_side.png`；
- `comparisons/<capture>/`：每条 capture 的完整比较图及可选 before/after ROI 证据；
- `masks/`：人物与语义色诊断 mask。

纯生产路由若只做布局、人物层或 before/after 诊断，必须显式使用
`--diagnostics-only`；这不会关闭母版 SHA 校验，也不会跳过 manifest 中已有
`battle_tap_live` 的 reference/current 比较。

before/after 零回归使用 capture 条目的可选 `baseline` 字段，且 baseline 必须带 SHA：

```json
{
  "baseline": {
    "png": "/absolute/path/to/before.png",
    "sha256": "...",
    "allowed_change_mask": "/absolute/path/to/allowed.png",
    "rois": {
      "hud": {"x": 0, "y": 0, "width": 1672, "height": 60},
      "field": {"x": 0, "y": 60, "width": 1672, "height": 640}
    }
  }
}
```

报告会分别列出总变化、mask 内允许变化、mask 外意外变化以及各 ROI 计数；只有明确
不在改动影响域内的 ROI 才应要求 `unexpected_pixels == 0`。

## 验证建议

```bash
bash -n tools/visual_capture/visual_capture.sh
tools/visual_capture/visual_capture.sh --route main_menu --resolutions 1920x1080 --output /tmp/wuxia_visual_probe --wait 1 --ready-timeout 180
rg "VISUAL_ROUTE_READY|VISUAL_CAPTURE" /tmp/wuxia_visual_probe/main_menu/1920x1080/main_menu.log
file /tmp/wuxia_visual_probe/main_menu/1920x1080/main_menu.png
```

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
