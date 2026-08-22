# macOS release 干净构建验签门禁计划

## 目标

把本夜实测的增量 release 外层签名陈旧风险固化为可重复门禁：只允许干净
工作区，从 `flutter clean` 开始构建 release，随后执行 deep codesign、双架构、
体积与二进制哈希检查。脚本不启动 GUI、不打包发布。

## 分支

`main`（夜班直接收口、提交并推送）。

## 验收标准

- [x] 脚本拒绝脏工作区，输出被验证的 commit。
- [x] 构建前执行 `flutter clean`，杜绝外层签名沿用旧产物。
- [x] release 构建使用锁定依赖，并从 fresh checkout 重建 gitignored 生成文件。
- [x] `codesign --verify --deep --strict` 必须通过。
- [x] 主启动器必须同时含 x86_64 与 arm64，并输出体积/AOT/launcher SHA-256。
- [x] 契约测试防止 clean、deep verify 或双架构检查被静默删除。
- [x] 不启动 GUI、不 deploy、不修改玩法代码或数据。

## 任务切片

1. 新增 release 验证脚本与源码契约测试。
2. 运行契约测试、analyze、format/shell syntax。
3. 提交推送，使工作区恢复 clean。
4. 从已提交 clean tree 实跑脚本并记录证据。

## 当前恢复点

- 状态：已完成，fresh checkout 自举证据已收齐。
- 最后完成：普通增量 release 构建成功但 deep verify 因外层签名时间 03:03、
  AOT 时间 03:48 而失败；`flutter clean` 后从零重建，deep verify 通过，
  universal x86_64+arm64、169M。
- 下一步：更新总账并提交推送。
- 已跑验证：脚本从 clean commit `20874398` 自举通过，输出
  `MACOS_RELEASE_VERIFY_PASS`；deep codesign valid、x86_64+arm64、169M，
  launcher SHA-256 `fd82e843…b33dd`，AOT SHA-256 `b6f74ab4…2fb80`。
  契约测试 1/1、无参数 analyze 0 issue、`bash -n`、format/diff check 通过。
- 后审发现：本机已有 64 个 gitignored `.g.dart`，首版脚本缺 build_runner，
  fresh checkout 不自足；已补生成步骤。全新 detached worktree 起始 0 个
  `.g.dart`，脚本生成 126 outputs 后完整 PASS：commit `c0fec07c`、
  x86_64+arm64、169M、launcher `1da2d4ac…431d9`、AOT
  `e9293f98…769f4`；临时 worktree 已删除。
- 阻塞项：无。
