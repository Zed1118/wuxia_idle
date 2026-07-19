# 夜批·测试覆盖补强续单（kimi-night worktree）

## 目标

挖 lib 低覆盖的 application/service/handler 层行为测试（真实入口驱动，非 fixture 孤测）。
目标序列制：lcov 定基线 → application/ 下 service/handler/provider <60% 行覆盖升序 → 从最低逐文件补测，
每文件独立中文动宾 commit（先红→补测→targeted 绿 + analyze 0→commit）。

## 分支

`kimi/night-coverage`，worktree `.worktrees/kimi-night`。

## 禁区

- 只碰 test/；不改生产逻辑（发现生产 bug → 记本文件「发现项」+ [BLOCKED] 冻结）。
- 不碰 data/ 数值、schema、saveVersion、红线、共享热点（strings/numbers/GDD/PROGRESS/pubspec）。
- 不碰 battle 域（codex 并行在改）。

## 验收

- 每文件：改前→改后行覆盖率实测数字写入恢复点。
- `flutter analyze --no-pub` 0 issue。
- 交付：worktree 干净 + tip `[READY] 夜批测试覆盖续批交付` + §8.2 四证据。

## 恢复点

- 状态：基线 coverage 运行中（task bash-uwpyw4c7）。
- 最后完成：计划文件建立。
- 下一步：解析 coverage/lcov.info，application/ 下 <60% 升序排名。
- 已跑验证：无。
- 阻塞项：无。

## 发现项

（空）
