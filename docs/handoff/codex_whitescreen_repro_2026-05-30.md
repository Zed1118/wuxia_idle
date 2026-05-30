# 主线白屏复现/证伪记录（Pen Windows）

结论：实验 A clean 存档未复现白屏；实验 B dirty seed 连续 3 轮未复现白屏。当前 HEAD `a39e1d2b4039c75f9272960a035d300db365e569` 下，现象更倾向于已由 debug seed provider invalidate 加固消除，未拿到 runtime 渲染/导航 bug 证据。

## 环境信息

| 项 | 记录 |
|---|---|
| 时间 | 2026-05-30 10:28-10:34（Asia/Shanghai） |
| 路径 | `F:\Projects\wuxia_idle` |
| Git HEAD | `a39e1d2b4039c75f9272960a035d300db365e569` |
| Flutter | `Flutter 3.41.5 stable` / `Dart 3.11.3` |
| build | `flutter clean` -> `dart run build_runner build --delete-conflicting-outputs` -> `flutter build windows --debug` 均完成 |
| build_runner 注意 | 当前版本提示 `--delete-conflicting-outputs` 已被移除并忽略，但 codegen 成功写入 84 个 outputs |
| git pull 注意 | 初次 `git pull` 被本地未跟踪旧 handoff 截图阻挡；为避免覆盖，已用 `stash@{0}: codex pre-whitescreen untracked handoff backup` 保存后 fast-forward 到 HEAD |

## 实验 A：clean 存档

| 步骤 | 实际执行 |
|---|---|
| 关旧进程 | 已执行 `Get-Process flutter,dart,wuxia_idle ... | Stop-Process -Force` |
| 删除存档 | 在 `C:\Users\Administrator\Documents` 删除 `wuxia_save_slot1.isar`、`wuxia_save_slot1.isar-lck`、`wuxia_save_slot1.isar.acceptance_backup_20260527_133532` |
| 启动 | `flutter run -d windows`，stdout/stderr 重定向到 `.dart_tool\whitescreen_run.*.log`，并复制到本目录 |
| 操作路径 | 首屏 `直入江湖` -> 主菜单 -> `主线` |
| 结果 | `ChapterListScreen` 正常 paint；未白屏 |
| 交互性 | 未白屏，交互异常项不适用；页面可正常返回主菜单 |

## 实验 B：dirty seed 路径

| 轮次 | seed | 操作路径 | 结果 |
|---|---|---|---|
| B1 | `VC · W7-W11 视觉验收预设` | Phase 2 调试场景 -> seed 后进入角色面板 -> 返回主菜单 -> 主线 | 正常 paint，未白屏 |
| B2 | `VC · W7-W11 视觉验收预设` | 重复 seed -> 返回主菜单 -> 主线 | 正常 paint，未白屏 |
| B3 | `P3 · 散功代价` | Phase 2 调试场景 -> seed 后进入心法面板 -> 返回主菜单 -> 主线 | 正常 paint，未白屏 |

未出现白屏，因此未执行“白屏后返回/重启能否恢复”的恢复性验证。

## 日志扫描

日志已归档：

- `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.out.log`
- `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.err.log`

扫描关键词：`exception`、`RenderFlex`、`assertion`、`FlutterError`、`Navigator`、`Error`、`failed`、`失败`。

结果：stdout/stderr 均无匹配；日志无 exception / RenderFlex / assertion / FlutterError / Navigator 报错。

stderr 仅有：

```text
Flutter assets will be downloaded from https://storage.flutter-io.cn. Make sure you trust this source!
```

stdout 仅包含依赖解析、debug build、Isar inspector、VM Service / DevTools 地址等正常启动信息。

## 截图清单

| 文件 | 场景 | 观察 |
|---|---|---|
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_start.png` | clean 存档首次启动首屏 | 正常 paint |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_main_menu.png` | clean 存档主菜单 | 正常 paint |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A1_chapterlist.png` | 实验 A 主线章节列表 | 正常 paint，未白屏 |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_top.png` | dirty seed 前主菜单顶部 | 正常 paint |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_scrolled.png` | 主菜单滚动到 Phase 2 入口 | 正常 paint |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_phase2_menu.png` | Phase 2 调试场景菜单 | 正常 paint |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_after_seed_target.png` | B1 seed 后目标角色面板 | 正常 paint |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_chapterlist.png` | B1 seed 后进入主线章节列表 | 正常 paint，未白屏 |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B2_chapterlist.png` | B2 seed 后进入主线章节列表 | 正常 paint，未白屏 |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B3_chapterlist.png` | B3 seed 后进入主线章节列表 | 正常 paint，未白屏 |

