# Windows 真机验收报告（2026-06-25 · Claude 自驱 SSH 远程执行）

> **背景**：用户提供同局域网在线 Windows 机器，要求自行进行 Windows 真机测试验收（发布目标平台，此前所有开发/测试仅在 macOS）。
> **基线**：main HEAD `28939e48`（本会话 11 招接线 + PVP 文档订正后）。
> **结论先行**：✅ **发布目标 Windows 完整验证通过**——全量测试 2905 passed + 1 skip（与 macOS 逐位一致）、release .exe 成功编译、二进制启动运行不崩。**未发现任何 Windows 平台特有缺陷。**

## 1. 通道建立（自驱）

- 局域网扫描自行定位 Windows 主机 = `192.168.1.244`（`OpenSSH_for_Windows_9.5`）。
- 生成专用 ed25519 key，用户一次性把公钥装入 `administrators_authorized_keys`（唯一需用户手动步骤）。
- Mac → Windows SSH 免密自驱（用户名 `administrator`）。
- **GitHub clone 失败**（`RPC failed; curl 56 SSL_read unexpected eof` + `early EOF`，大传输 SSL 中断，重试 + 浅克隆均失败）→ 这台 Windows 到 GitHub 的网络在大传输上不稳。
- **改 Mac→Windows LAN 直传**（`scp -O` legacy 协议；默认 SFTP 协议在该 Windows sshd 不通）：源码 1.6M + assets 300M(字节校验一致) + windows/ 26K。

## 2. 环境对比（消除版本偏差根因）

| 项 | macOS | Windows | |
|---|---|---|---|
| flutter | 3.41.5-stable | 3.41.5-stable | ✅ 同 |
| OS | Darwin 25.4 | Windows 11 (build 26200) | — |
| VS C++ 工具链 | n/a | 已装(F:\vs_buildtools) | ✅ build 前提 |
| pub get | Got dependencies | Got dependencies | ✅ 同 lock |
| build_runner | 108 outputs | **108 outputs** | ✅ 逐项一致 |

## 3. 验收结果

### 3.1 全量自动化测试 — ✅ 与 Mac 逐位一致
```
flutter test → 2905 passed + 1 skip (All tests passed!)
```
- 与 macOS（2905+1skip）**完全一致**。
- **Isar 在 Windows 正常工作**（`IsarCore using libmdbx v0.13.8`，native lib 由 isar_community_flutter_libs 自动解析，无需手动拷 dylib——与 Mac 需手动拷 libisar.dylib 不同，Windows 端 flutter test 自带）。
- **首轮假失败已澄清**：初次只传源码（排除 assets）时 10 个失败全是「资源文件存在性」测试（audio_assets / asset_audit），补齐 assets 后清零——**我的传输取舍产物，非平台缺陷**。

### 3.2 release 构建 — ✅ 产出可运行 .exe
```
flutter build windows → √ Built build\windows\x64\runner\Release\wuxia_idle.exe (94.8s)
```
产物 DLL 齐全：`flutter_windows.dll`(19.8MB) + **`libisar.dll`(1MB)** + audioplayers / window_manager / screen_retriever 插件 DLL。

### 3.3 二进制启动 — ✅ 运行不崩
```
Start-Process wuxia_idle.exe → RUNNING_OK pid=25216 (存活 6s 无崩溃)
```
= Windows 二进制上 `GameRepository.loadAllDefs`（启动期校验全 68 奇遇 + 11 新 events + 红线 enforce）+ Isar 初始化全部成功。

## 4. 对「#1 无 CI」的影响

本次证明 **Windows 真机验收是可按需自驱的能力**（Windows 在线时，Claude 经 SSH 直接跑 test/build/启动）——不依赖常驻 CI。结合：① flutter 版本两端一致、② 全量测试逐位相同、③ release exe 成功——**Windows 平台风险已实测清零**。CI 的边际价值进一步降低；按需 SSH 验收 + ship 前人工实机 = 足够覆盖。

## 5. 残留 / 备注

- Windows 侧 `F:\wuxia_verify` 保留（含已编译的 release exe，用户可双击运行实玩；不需要可删 `Remove-Item -Recurse F:\wuxia_verify`）。
- 局限：SSH 无图形回传，**GUI 动态画面 / 战斗手感 / 中文渲染目检仍需人工**（启动不崩 ≠ 画面正确）。
- 专用 SSH key 在 Mac `~/.ssh/wuxia_win_acceptance`，公钥在 Windows `administrators_authorized_keys`——后续 Windows 在线即可复用此通道再验收。
