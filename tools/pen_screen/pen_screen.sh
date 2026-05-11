#!/usr/bin/env bash
# pen_screen.sh — 远程触发 Pen Windows 桌面截屏 + scp 拉到 Mac
#
# 用法：
#   pen_screen.sh                           → 输出到 /tmp/pen_screen_<ts>.png
#   pen_screen.sh /path/to/output.png       → 输出到指定路径
#
# 依赖（Pen 端一次性配好）：
#   C:\screenshots\screencap.ps1            PowerShell 截屏脚本
#   C:\screenshots\screencap_hidden.vbs     VBS 静默包装
#
# 流程：
#   1. SSH schtasks /Create + /Run 触发 wscript → vbs → PowerShell hidden 截屏
#   2. PowerShell 截 PrimaryScreen 全屏 → 写 C:\screenshots\screen_<ts>.png
#   3. SSH 拉最新文件名
#   4. scp 拉到 Mac
#   5. echo Mac 本地路径供 Read 用
set -e

REMOTE="Administrator@100.73.91.112"
OUT="${1:-/tmp/pen_screen_$(date +%Y%m%d_%H%M%S).png}"

ssh_q() { ssh -q "$REMOTE" "$@" 2>&1 | grep -v "WARNING\|store now\|upgraded\|post-quantum" || true; }

ssh_q "schtasks /Create /TN pen_screencap /TR \"wscript.exe C:\\screenshots\\screencap_hidden.vbs\" /SC ONCE /ST 23:59 /F /RL HIGHEST /RU Administrator" >/dev/null
ssh_q "schtasks /Run /TN pen_screencap" >/dev/null
sleep 3
ssh_q "schtasks /Delete /TN pen_screencap /F" >/dev/null

latest=$(ssh -q "$REMOTE" 'powershell -NoProfile -Command "(Get-ChildItem C:\\screenshots\\screen_*.png | Sort-Object LastWriteTime -Desc | Select-Object -First 1).Name"' 2>/dev/null | tr -d '\r\n')

if [ -z "$latest" ]; then
  echo "ERROR: 未在 C:\\screenshots\\ 找到截图文件" >&2
  exit 1
fi

scp -q "${REMOTE}:C:/screenshots/${latest}" "$OUT"
echo "$OUT"
