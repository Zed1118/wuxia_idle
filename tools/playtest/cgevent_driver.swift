import Cocoa
import CoreGraphics
import Foundation

private struct Scenario: Decodable {
    let schemaVersion: Int
    let id: String
    let recordingMaxSeconds: Int
    let actions: [ScriptedAction]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case id
        case recordingMaxSeconds = "recording_max_seconds"
        case actions
    }
}

private struct ScriptedAction: Decodable {
    let id: String
    let type: String
    let x: Double?
    let y: Double?
    let key: String?
    let keyCode: UInt16?
    let holdMs: UInt32?
    let durationMs: UInt32?
    let deltaY: Int32?
    let label: String?
    let delayAfterMs: UInt32?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case x
        case y
        case key
        case keyCode = "key_code"
        case holdMs = "hold_ms"
        case durationMs = "duration_ms"
        case deltaY = "delta_y"
        case label
        case delayAfterMs = "delay_after_ms"
    }
}

private struct TargetWindow {
    let app: NSRunningApplication
    let windowId: CGWindowID
    let bounds: CGRect
    let scale: CGFloat
}

private struct ParsedArguments {
    let command: String
    let scenarioPath: String?
    let appPath: String?
    let pid: pid_t?
    let logPath: String?
}

private let keyCodes: [String: CGKeyCode] = [
    "a": 0,
    "s": 1,
    "d": 2,
    "f": 3,
    "z": 6,
    "q": 12,
    "w": 13,
    "e": 14,
    "r": 15,
    "1": 18,
    "2": 19,
    "3": 20,
    "4": 21,
    "5": 23,
    "6": 22,
    "j": 38,
    "return": 36,
    "enter": 36,
    "tab": 48,
    "space": 49,
    "escape": 53,
    "left": 123,
    "right": 124,
    "down": 125,
    "up": 126,
]

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("ERROR: \(message)\n").utf8))
    exit(2)
}

private func parseArguments() -> ParsedArguments {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first, ["validate", "bounds", "run"].contains(command) else {
        fail(
            "usage: cgevent_driver validate --scenario FILE | "
                + "bounds --pid PID --app-path APP | "
                + "run --pid PID --app-path APP --scenario FILE --log FILE"
        )
    }
    var values: [String: String] = [:]
    var index = 1
    while index < args.count {
        let flag = args[index]
        guard flag.hasPrefix("--"), index + 1 < args.count else {
            fail("missing value for \(flag)")
        }
        values[flag] = args[index + 1]
        index += 2
    }
    let pid = values["--pid"].flatMap(Int32.init)
    return ParsedArguments(
        command: command,
        scenarioPath: values["--scenario"],
        appPath: values["--app-path"],
        pid: pid,
        logPath: values["--log"]
    )
}

private func loadScenario(path: String?) -> Scenario {
    guard let path else { fail("--scenario is required") }
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(Scenario.self, from: data)
    } catch {
        fail("unable to decode scenario \(path): \(error)")
    }
}

private func validate(_ scenario: Scenario) {
    guard scenario.schemaVersion == 1 else {
        fail("scenario schema_version must be 1")
    }
    guard !scenario.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        fail("scenario id must not be empty")
    }
    guard scenario.recordingMaxSeconds > 0 else {
        fail("recording_max_seconds must be positive")
    }
    guard !scenario.actions.isEmpty else { fail("scenario actions must not be empty") }

    var actionIds = Set<String>()
    var checkpointLabels = Set<String>()
    for action in scenario.actions {
        guard actionIds.insert(action.id).inserted else {
            fail("duplicate action id: \(action.id)")
        }
        switch action.type {
        case "click":
            guard let x = action.x, let y = action.y,
                  (0 ... 1).contains(x), (0 ... 1).contains(y)
            else {
                fail("click \(action.id) requires x/y in 0...1")
            }
        case "key":
            if let key = action.key?.lowercased() {
                guard keyCodes[key] != nil else {
                    fail("key \(action.id) has unsupported key name: \(key)")
                }
            } else if action.keyCode == nil {
                fail("key \(action.id) requires key or key_code")
            }
        case "scroll":
            guard let delta = action.deltaY, delta != 0 else {
                fail("scroll \(action.id) requires non-zero delta_y")
            }
        case "wait":
            guard let duration = action.durationMs, duration > 0 else {
                fail("wait \(action.id) requires positive duration_ms")
            }
        case "checkpoint":
            guard let label = action.label, !label.isEmpty else {
                fail("checkpoint \(action.id) requires label")
            }
            guard checkpointLabels.insert(label).inserted else {
                fail("duplicate checkpoint label: \(label)")
            }
        default:
            fail("action \(action.id) has unsupported type: \(action.type)")
        }
    }
}

private func activeDisplayScale(for point: CGPoint) -> CGFloat {
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
        return 1
    }
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetActiveDisplayList(count, &displays, &count) == .success else {
        return 1
    }
    for display in displays.prefix(Int(count)) {
        let displayBounds = CGDisplayBounds(display)
        if displayBounds.contains(point), displayBounds.width > 0 {
            return CGFloat(CGDisplayPixelsWide(display)) / displayBounds.width
        }
    }
    return 1
}

private func targetWindow(pid: pid_t, expectedAppPath: String) -> TargetWindow {
    guard let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated else {
        fail("target app pid \(pid) is not running")
    }
    let expected = URL(fileURLWithPath: expectedAppPath).standardizedFileURL.path
    guard app.bundleURL?.standardizedFileURL.path == expected else {
        fail(
            "target pid \(pid) bundle mismatch: expected \(expected), "
                + "actual \(app.bundleURL?.path ?? "<nil>")"
        )
    }
    guard let rawWindows = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements],
        kCGNullWindowID
    ) as? [[String: Any]] else {
        fail("CGWindowListCopyWindowInfo returned no data")
    }
    let candidates: [(CGWindowID, CGRect)] = rawWindows.compactMap { info in
        guard
            let ownerPid = info[kCGWindowOwnerPID as String] as? Int,
            ownerPid == Int(pid),
            let layer = info[kCGWindowLayer as String] as? Int,
            layer == 0,
            let number = info[kCGWindowNumber as String] as? UInt32,
            let boundsValue = info[kCGWindowBounds as String],
            let bounds = CGRect(
                dictionaryRepresentation: boundsValue as! CFDictionary
            ),
            bounds.width > 100,
            bounds.height > 100
        else { return nil }
        return (CGWindowID(number), bounds)
    }
    guard let selected = candidates.max(by: {
        $0.1.width * $0.1.height < $1.1.width * $1.1.height
    }) else {
        fail("target app pid \(pid) has no on-screen layer-0 window")
    }
    let center = CGPoint(x: selected.1.midX, y: selected.1.midY)
    return TargetWindow(
        app: app,
        windowId: selected.0,
        bounds: selected.1,
        scale: activeDisplayScale(for: center)
    )
}

private func windowPayload(_ window: TargetWindow) -> [String: Any] {
    let bounds = window.bounds
    return [
        "pid": Int(window.app.processIdentifier),
        "window_id": Int(window.windowId),
        "bounds_points": [
            "x": bounds.origin.x,
            "y": bounds.origin.y,
            "width": bounds.width,
            "height": bounds.height,
        ],
        "backing_scale": window.scale,
        "bounds_pixels": [
            "width": bounds.width * window.scale,
            "height": bounds.height * window.scale,
        ],
    ]
}

private final class JsonLineLogger {
    private let handle: FileHandle

    init(path: String) {
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            guard FileManager.default.createFile(atPath: path, contents: nil) else {
                fail("unable to create log file \(path)")
            }
            handle = try FileHandle(forWritingTo: url)
        } catch {
            fail("unable to open log file \(path): \(error)")
        }
    }

    deinit {
        try? handle.close()
    }

    func write(_ payload: [String: Any]) {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: payload,
                options: [.sortedKeys]
            )
            handle.write(data)
            handle.write(Data("\n".utf8))
            try handle.synchronize()
        } catch {
            fail("unable to write action log: \(error)")
        }
    }
}

private func activate(_ window: TargetWindow) {
    _ = window.app.activate(options: [.activateIgnoringOtherApps])
    usleep(200_000)
}

private func sleepMilliseconds(_ milliseconds: UInt32) {
    var remaining = UInt64(milliseconds) * 1_000
    while remaining > 0 {
        let chunk = useconds_t(min(remaining, UInt64(UInt32.max)))
        usleep(chunk)
        remaining -= UInt64(chunk)
    }
}

private func click(window: TargetWindow, x: Double, y: Double) {
    activate(window)
    let point = CGPoint(
        x: window.bounds.minX + window.bounds.width * x,
        y: window.bounds.minY + window.bounds.height * y
    )
    let source = CGEventSource(stateID: .combinedSessionState)
    source?.localEventsSuppressionInterval = 0
    guard
        let down = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ),
        let up = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )
    else { fail("could not create mouse CGEvent") }
    down.post(tap: .cghidEventTap)
    usleep(80_000)
    up.post(tap: .cghidEventTap)
}

private func key(window: TargetWindow, code: CGKeyCode, holdMs: UInt32) {
    activate(window)
    let source = CGEventSource(stateID: .combinedSessionState)
    source?.localEventsSuppressionInterval = 0
    guard
        let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
        let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)
    else { fail("could not create keyboard CGEvent") }
    down.post(tap: .cghidEventTap)
    sleepMilliseconds(holdMs)
    up.post(tap: .cghidEventTap)
}

private func scroll(window: TargetWindow, deltaY: Int32) {
    activate(window)
    let point = CGPoint(x: window.bounds.midX, y: window.bounds.midY)
    let source = CGEventSource(stateID: .combinedSessionState)
    source?.localEventsSuppressionInterval = 0
    CGEvent(
        mouseEventSource: source,
        mouseType: .mouseMoved,
        mouseCursorPosition: point,
        mouseButton: .left
    )?.post(tap: .cghidEventTap)
    guard let event = CGEvent(
        scrollWheelEvent2Source: source,
        units: .line,
        wheelCount: 1,
        wheel1: deltaY,
        wheel2: 0,
        wheel3: 0
    ) else { fail("could not create scroll CGEvent") }
    event.post(tap: .cghidEventTap)
}

private func actionPayload(
    scenario: Scenario,
    action: ScriptedAction,
    index: Int,
    window: TargetWindow,
    startedUptime: TimeInterval
) -> [String: Any] {
    let now = Date()
    var payload: [String: Any] = [
        "event": "action",
        "scenario": scenario.id,
        "sequence": index,
        "id": action.id,
        "action_type": action.type,
        "timestamp": ISO8601DateFormatter().string(from: now),
        "epoch_ms": Int64((now.timeIntervalSince1970 * 1_000).rounded()),
        "elapsed_ms": Int64(
            ((ProcessInfo.processInfo.systemUptime - startedUptime) * 1_000).rounded()
        ),
        "window": windowPayload(window),
    ]
    if let label = action.label { payload["label"] = label }
    if let x = action.x { payload["x"] = x }
    if let y = action.y { payload["y"] = y }
    if let key = action.key { payload["key"] = key }
    if let keyCode = action.keyCode { payload["key_code"] = keyCode }
    if let holdMs = action.holdMs { payload["hold_ms"] = holdMs }
    if let durationMs = action.durationMs { payload["duration_ms"] = durationMs }
    if let deltaY = action.deltaY { payload["delta_y"] = deltaY }
    if let delayAfterMs = action.delayAfterMs { payload["delay_after_ms"] = delayAfterMs }
    return payload
}

private func runScenario(
    _ scenario: Scenario,
    pid: pid_t,
    appPath: String,
    logPath: String
) {
    let logger = JsonLineLogger(path: logPath)
    let startedUptime = ProcessInfo.processInfo.systemUptime
    for (index, action) in scenario.actions.enumerated() {
        // This lookup is intentionally inside the loop. Window position and screen
        // scale may change between any two actions, so no bounds are cached.
        let window = targetWindow(pid: pid, expectedAppPath: appPath)
        logger.write(
            actionPayload(
                scenario: scenario,
                action: action,
                index: index,
                window: window,
                startedUptime: startedUptime
            )
        )
        switch action.type {
        case "click":
            click(window: window, x: action.x!, y: action.y!)
        case "key":
            let code: CGKeyCode
            if let keyName = action.key?.lowercased() {
                code = keyCodes[keyName]!
            } else {
                code = CGKeyCode(action.keyCode!)
            }
            key(window: window, code: code, holdMs: action.holdMs ?? 80)
        case "scroll":
            scroll(window: window, deltaY: action.deltaY!)
        case "wait":
            sleepMilliseconds(action.durationMs!)
        case "checkpoint":
            break
        default:
            fail("unsupported action type after validation: \(action.type)")
        }
        sleepMilliseconds(action.delayAfterMs ?? 0)
    }
    logger.write([
        "event": "complete",
        "scenario": scenario.id,
        "action_count": scenario.actions.count,
        "timestamp": ISO8601DateFormatter().string(from: Date()),
    ])
}

private let parsed = parseArguments()
switch parsed.command {
case "validate":
    let scenario = loadScenario(path: parsed.scenarioPath)
    validate(scenario)
    print(
        "VALID scenario=\(scenario.id) actions=\(scenario.actions.count) "
            + "recording_max_seconds=\(scenario.recordingMaxSeconds)"
    )
case "bounds":
    guard let pid = parsed.pid, let appPath = parsed.appPath else {
        fail("bounds requires --pid and --app-path")
    }
    let window = targetWindow(pid: pid, expectedAppPath: appPath)
    let data = try! JSONSerialization.data(
        withJSONObject: windowPayload(window),
        options: [.prettyPrinted, .sortedKeys]
    )
    print(String(decoding: data, as: UTF8.self))
case "run":
    guard
        let pid = parsed.pid,
        let appPath = parsed.appPath,
        let logPath = parsed.logPath
    else {
        fail("run requires --pid, --app-path, --scenario, and --log")
    }
    let scenario = loadScenario(path: parsed.scenarioPath)
    validate(scenario)
    runScenario(scenario, pid: pid, appPath: appPath, logPath: logPath)
    print("COMPLETE scenario=\(scenario.id) actions=\(scenario.actions.count) log=\(logPath)")
default:
    fail("unreachable command")
}
