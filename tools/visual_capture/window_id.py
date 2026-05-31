#!/usr/bin/env python3
"""打印指定 app(owner name 含给定子串)的最大可见普通窗口 CGWindowID。
用 CoreGraphics CGWindowListCopyWindowInfo,需 Screen Recording 权限(screencapture
已具备),不需要 Accessibility。取不到则无输出并 exit 1。
用法: window_id.py wuxia_idle"""
import sys

try:
    import Quartz
except ImportError:
    sys.exit(2)


def main():
    needle = (sys.argv[1] if len(sys.argv) > 1 else "wuxia_idle").lower()
    opts = (Quartz.kCGWindowListOptionOnScreenOnly
            | Quartz.kCGWindowListExcludeDesktopElements)
    wins = Quartz.CGWindowListCopyWindowInfo(opts, Quartz.kCGNullWindowID)
    best = None
    for w in wins:
        owner = (w.get("kCGWindowOwnerName") or "").lower()
        if needle not in owner:
            continue
        if w.get("kCGWindowLayer", 0) != 0:   # 仅普通窗口层(排除菜单/浮层)
            continue
        b = w.get("kCGWindowBounds", {})
        area = b.get("Width", 0) * b.get("Height", 0)
        wid = w.get("kCGWindowNumber")
        if best is None or area > best[1]:
            best = (wid, area)
    if best is None:
        sys.exit(1)
    print(best[0])


if __name__ == "__main__":
    main()
