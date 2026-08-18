# visual_capture 锁屏 fallback 修法(BACKLOG 二#11 剩余实装)

- **日期**:2026-08-18 · **分支**:`fix/visual-capture-lock-fallback-0818`
- **协议**:CLAUDE.md §8.0 可恢复任务协议 · 纯 shell 批(零 `.dart`),免全量 Flutter 测试

## 目标

`visual_capture.sh` 的 `capture_visual_window`:窗口截图主路径失败后,**若会话处于锁屏态,
跳过区域 `-R` fallback 直接硬停报失败**。根因(2026-08-12 audit 定谳):锁屏时
`screencapture -R` 必死;即使侥幸出图也只拍得到锁屏画面(锁屏时 osascript 摆不了窗口,
`(0,0,W,H)` 几何前提不成立),属错内容——本仓有过整张错拍事故,明着失败优于假成功。
E 批已落「诊断」(`VISUAL_CAPTURE_DIAG:` + 双失败硬停),本批落「决策」。

## 设计决策(冻结)

1. **锁屏判定复用既有 `lock_state.py`**(判 `ioreg` 的 `CGSSessionScreenIsLocked` 键有无,
   unknown 判据保守)。判定时点 = 主路径失败之后(既有 DIAG 位置),不新增预检。
2. **保留项**:① 未锁时区域 fallback 不动(实测有效兜底);② 窗口截图成功路径不动
   (锁屏下窗口截图照常成功 ⇒ `--background`/窗口路径的无人值守采集不受本修法影响,
   这正是「夜批无人值守视觉证据解锁」的正解:窗口路径才是锁屏下的活路);
   ③ `VISUAL_CAPTURE:`/`VISUAL_CAPTURE_FAIL:`/`VISUAL_CAPTURE_DIAG:` 前缀与写日志位置不动
   (下游与 4 份终拍日志按此解析)。
3. **被否方向留痕**:「锁屏时改用全屏截图裁剪替代 -R」已于 audit §六被推翻(几何前提不成立,
   裁出错内容),不再重提。
4. **可测性重构(先于修法,纯重排零行为变化)**:把窗口/区域截图与锁屏判定相关函数抽到
   `tools/visual_capture/visual_capture_lib.sh`,新增行为测 `lock_fallback_behavior_test.sh`
   (PATH stub 注入 `screencapture`/`swift`/`python3`,锁屏态经 `--ioreg-file` 注入)。
   抽 lib 是修法的可测性前置,不抽则分支逻辑只能真机锁屏手验、留不下回归资产。

## 验收标准

- [x] 锁屏 + 窗口截图失败 ⇒ 不再走区域 fallback;`capture_visual_window` 返回
      `all_failed:lock=locked` 且非零退出;日志含 DIAG 与 FAIL 人话结论
- [x] 未锁 + 窗口截图失败 + 区域成功 ⇒ 仍 `fallback_region` 返回 0(回归不破)
- [x] 窗口截图成功 ⇒ 仍 `window_id:<wid>` 返回 0(不查锁，快路径不变)
- [x] 行为测锁屏 case 在修法前红、修法后绿;RP2 反向还原修法复红再还原
- [x] `bash -n` 全部脚本过 · dry-run 可跑 · README 同步锁屏语义 · 行为测接入 final_gate_check.sh
- [ ] CI:纯 shell 批，flutter test 计数应保持 5160 不变

## 任务切片

1. RP0:本计划档冻结 commit
2. RP1-a:抽 `visual_capture_lib.sh`(capture_region/window_id/capture_visual_window/
   focus/terminate/stop_pid/wait_for_route_ready 与锁屏判定),主脚本 source;
   新增行为测(先钉现状:含「锁屏仍走区域 fallback」的现状 case)+ `bash -n` 回归
3. RP1-b:修法——主路径失败且 `lock_state=locked` 时跳区域 fallback 硬停;
   行为测改断言目标行为,锁屏 case 红→绿
4. RP2:破坏证红(反向还原修法 → 锁屏 case 应红 → 还原复绿)
5. GATE:全套验证 + README 补锁屏语义说明
6. 收账:merge main · PROGRESS 登记(守 100 行)· BACKLOG 二#11 销行 · push · CI 盯守

## 当前恢复点

- **状态**:GATE 全绿，待合入收账
- **最后完成**:修法实装 + 破坏证红(反向还原 case 3 精确红，还原复绿)+ GATE 全套绿
  (bash -n ×4 / lock_state_test 6 例 / 行为测 3 例 / dry-run / __pycache__ 清零)
- **commit 链**:`9c5def22` RP0 → `9c900256` 抽 lib+行为测钉现状 →
  `3854cf66` 红测 → `8346575d` 实装 → GATE/README 批
- **下一步**:merge main · PROGRESS 登记 · BACKLOG 二#11 销行 · push · CI 盯守
- **阻塞项**:无
