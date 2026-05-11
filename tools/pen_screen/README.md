# Pen Windows 远程截屏工具

Mac 端一句话触发 Pen Windows 桌面截屏 + scp 拉到 Mac，全自动无 console 闪现。

> 跨项目通用：wuxia_idle / lifetime_app / 任何 Pen 端 GUI 应用视觉验收都可用。
> 落地于 2026-05-11 Phase 3 Week 1 收尾。

---

## 文件清单

| 文件 | 部署位置 | 作用 |
|---|---|---|
| `pen_screen.sh` | Mac `~/scripts/` | Mac 端入口 helper |
| `screencap.ps1` | Pen Windows `C:\screenshots\` | PowerShell 截屏脚本 |
| `screencap_hidden.vbs` | Pen Windows `C:\screenshots\` | VBS 静默包装（避免 console 闪现） |

---

## 用法

```bash
~/scripts/pen_screen.sh                        # 默认输出 /tmp/pen_screen_<ts>.png
~/scripts/pen_screen.sh /path/to/out.png       # 指定输出
```

返回值是 Mac 本地路径，可直接 `Read` 看截图。**端到端约 8 秒**（含 ssh 握手 + 3s sleep + scp）。

---

## 部署

### Mac 端（一次性）

```bash
mkdir -p ~/scripts
cp tools/pen_screen/pen_screen.sh ~/scripts/
chmod +x ~/scripts/pen_screen.sh
```

`pen_screen.sh` 默认连 `Administrator@100.73.91.112`（与 saibandao 共用 Pen 机器）。换机器改脚本顶部 `REMOTE` 变量。

### Pen Windows 端（一次性）

```powershell
# 1. 创建截图目录
New-Item -ItemType Directory -Path C:\screenshots -Force

# 2. 用 scp 从 Mac 推（推荐）
# Mac 端跑：
# scp tools/pen_screen/screencap.ps1 Administrator@100.73.91.112:C:/screenshots/
# scp tools/pen_screen/screencap_hidden.vbs Administrator@100.73.91.112:C:/screenshots/
```

确认两个文件就位：

```powershell
dir C:\screenshots\
# 应有 screencap.ps1 + screencap_hidden.vbs
```

---

## 工作原理

```
Mac: pen_screen.sh
 │
 ├─ ssh schtasks /Create + /Run pen_screencap
 │    └─ Console Session 1 触发 wscript.exe screencap_hidden.vbs
 │         └─ WScript.Shell.Run "powershell ... -WindowStyle Hidden", 0, True
 │              └─ powershell 跑 screencap.ps1
 │                   └─ Add-Type System.Drawing
 │                       CopyFromScreen → C:\screenshots\screen_<ts>.png
 │
 ├─ ssh schtasks /Delete pen_screencap
 ├─ ssh PowerShell Get-ChildItem | Sort LastWriteTime → 最新文件名
 └─ scp ${REMOTE}:C:/screenshots/${latest} → Mac 本地路径
```

---

## 关键技术坑（部署其他机器时记得）

1. **必须经 schtasks**：直接 SSH 跑 PowerShell 会在 Service Session 0，`CopyFromScreen` 截到的是黑屏（无桌面 surface）。schtasks 默认调度到 Console Session 1（user 已登录 session），才能截到真实桌面。

2. **必须 VBS 包装**：直接 schtasks 跑 powershell.exe 即使加 `-WindowStyle Hidden` 也会在启动瞬间闪一下黑窗。VBS 通过 `wscript.exe` 启动（无 console），再用 `Run windowStyle=0` 调 powershell —— 双静默才完全无闪。

3. **截全屏，不能指定窗口**：当前是 `Screen.PrimaryScreen.Bounds` 全屏截图。要游戏画面完整需用户先把窗口拉前台 + 关闭遮挡窗口（如代码编辑器 popup）。Phase 4+ 如有特殊需求可加 `FindWindow` + `GetWindowRect` 截特定窗口。

4. **schtasks /Run 是异步的**：脚本里 `sleep 3` 等 PowerShell 真正完成截屏并写文件，太短会拿到旧文件。如截屏极慢可加大 sleep。

---

## 适用与不适用场景

✅ Pen 端 Flutter Desktop / Native Windows GUI 应用视觉验收
✅ 调试时远程看 Pen 当前桌面状态
✅ 双机协作中替代用户来回传图

❌ Web 应用（Mac 端 Playwright MCP 更顺手 + 能跑 E2E）
❌ 截特定窗口而非全屏（当前实现限制）
❌ Pen 端无 user 登录的纯 service 场景（需 Console Session 1 active）
