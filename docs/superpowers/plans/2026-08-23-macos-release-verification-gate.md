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
- [x] release 构建使用锁定依赖，不改依赖版本。
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

- 状态：脚本与契约已完成，待提交后从 clean tree 实跑。
- 最后完成：普通增量 release 构建成功但 deep verify 因外层签名时间 03:03、
  AOT 时间 03:48 而失败；`flutter clean` 后从零重建，deep verify 通过，
  universal x86_64+arm64、169M。
- 下一步：提交推送，随后从 clean tree 运行脚本并记录最终证据。
- 已跑验证：契约测试 1/1、无参数 analyze 0 issue、`bash -n`、format/
  diff check 通过；手工 clean build 的同等命令已 deep verify 通过。
- 阻塞项：无。
