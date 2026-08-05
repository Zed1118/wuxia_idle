// 取指定 owner name 的 macOS 窗口 id(给 screencapture -l 用)。
// 零安装(CommandLineTools swift)、零辅助功能权限(CGWindowList 列窗口不需权限)。
// 用法: swift window_id.swift <ownerNameSubstring> [--all-spaces] [--pid <n>]
//   stdout: 每行 "num<TAB>layer<TAB>owner<TAB>ownerPid<TAB>x,y,w,h"
//   stderr 末行: BEST=<id>  (layer 0 面积最大的主窗;无则 BEST=-1)
//   --pid: 只认该 owner 进程的窗口。同名多进程(前序 route 残留未退净)时,
//   按名匹配会把面积并列的旧窗当 BEST 截出前一 route 的画面(2026-08-04 批 C
//   cycle 720 错拍实锤),调用方传本次启动的 pid 即可根除。
import CoreGraphics
import Foundation

var target = ""
var includeAllSpaces = false
var pidFilter: Int? = nil
var it = CommandLine.arguments.dropFirst().makeIterator()
while let arg = it.next() {
    if arg == "--all-spaces" {
        includeAllSpaces = true
    } else if arg == "--pid" {
        if let v = it.next(), let p = Int(v) { pidFilter = p }
    } else if !arg.hasPrefix("--"), target.isEmpty {
        target = arg
    }
}
let opts = includeAllSpaces
    ? CGWindowListOption(arrayLiteral: .optionAll, .excludeDesktopElements)
    : CGWindowListOption(arrayLiteral: .optionOnScreenOnly)
guard let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    FileHandle.standardError.write("ERR: no window list (permission?)\n".data(using: .utf8)!)
    exit(2)
}
var best = -1, bestArea = -1.0
for w in list {
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let ownerPid = w[kCGWindowOwnerPID as String] as? Int ?? -1
    let num = w[kCGWindowNumber as String] as? Int ?? -1
    let layer = w[kCGWindowLayer as String] as? Int ?? -1
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let x = b["X"] as? Double ?? 0, y = b["Y"] as? Double ?? 0
    let ww = b["Width"] as? Double ?? 0, hh = b["Height"] as? Double ?? 0
    let nameOk = target.isEmpty || owner.range(of: target, options: .caseInsensitive) != nil
    let pidOk = pidFilter == nil || ownerPid == pidFilter
    if nameOk && pidOk {
        print("\(num)\t\(layer)\t\(owner)\t\(ownerPid)\t\(Int(x)),\(Int(y)),\(Int(ww)),\(Int(hh))")
        if layer == 0 && ww*hh > bestArea { bestArea = ww*hh; best = num }
    }
}
FileHandle.standardError.write("BEST=\(best)\n".data(using: .utf8)!)
