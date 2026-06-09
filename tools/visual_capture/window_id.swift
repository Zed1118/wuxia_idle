// 取指定 owner name 的 macOS 窗口 id(给 screencapture -l 用)。
// 零安装(CommandLineTools swift)、零辅助功能权限(CGWindowList 列窗口不需权限)。
// 用法: swift window_id.swift <ownerNameSubstring>
//   stdout: 每行 "num<TAB>layer<TAB>owner<TAB>x,y,w,h"
//   stderr 末行: BEST=<id>  (layer 0 面积最大的主窗;无则 BEST=-1)
import CoreGraphics
import Foundation

let opts = CGWindowListOption(arrayLiteral: .optionOnScreenOnly)
guard let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    FileHandle.standardError.write("ERR: no window list (permission?)\n".data(using: .utf8)!)
    exit(2)
}
let target = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
var best = -1, bestArea = -1.0
for w in list {
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let num = w[kCGWindowNumber as String] as? Int ?? -1
    let layer = w[kCGWindowLayer as String] as? Int ?? -1
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let x = b["X"] as? Double ?? 0, y = b["Y"] as? Double ?? 0
    let ww = b["Width"] as? Double ?? 0, hh = b["Height"] as? Double ?? 0
    if target.isEmpty || owner.range(of: target, options: .caseInsensitive) != nil {
        print("\(num)\t\(layer)\t\(owner)\t\(Int(x)),\(Int(y)),\(Int(ww)),\(Int(hh))")
        if layer == 0 && ww*hh > bestArea { bestArea = ww*hh; best = num }
    }
}
FileHandle.standardError.write("BEST=\(best)\n".data(using: .utf8)!)
