#!/usr/bin/env bash
# 预编验收包:debug 档 + VISUAL_ROUTE=hub。Codex `open` 即用,零编译切路由。
# 用法:./tool/build_acceptance.sh   (代码改动后重跑刷新)
set -euo pipefail
cd "$(dirname "$0")/.."

SHA=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
echo "==> 编译验收包 @ $SHA (debug · VISUAL_ROUTE=hub) ..."
flutter build macos --debug --dart-define=VISUAL_ROUTE=hub

APP="$(pwd)/build/macos/Build/Products/Debug/wuxia_idle.app"
echo ""
echo "✓ 验收包就绪 @ commit $SHA"
echo "  $APP"
echo ""
echo "── 交给 Codex(零编译验收)──"
echo "  open \"$APP\""
echo "  窗口显示「验收总入口」→ 点路由进屏截图 → 左上返回 → 下一个。"
echo "  注:此包 = commit $SHA 的快照;代码再改需重跑本脚本。"
