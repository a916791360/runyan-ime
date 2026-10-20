import AppKit
import ApplicationServices
import InputMethodKit
import RunyanCore

/// 把光标往左挪几格。
///
/// `IMKTextInput` 只能读选区（`selectedRange()`），**没有**设置选区的方法，
/// 所以补完右括号后没法直接告诉输入框「光标退一格」。两条路，按可靠程度排：
///
///   1. `doCommandBySelector:` —— NSTextInputClient 的标准方法，把 `moveLeft:`
///      交给输入框自己执行。不需要任何权限，Cocoa 的原生输入框基本都收。
///   2. 合成一个左方向键事件 —— 有些输入框（网页、Electron）不转这条命令，
///      只能补发按键。合成事件需要「辅助功能」权限，没有权限时系统静默丢弃。
///
/// 两条都不通时**不要补括号**：补了却把光标留在右括号后面比不补更难受。
enum CaretMover {
    /// 左方向键的虚拟键码。
    private static let leftArrow: CGKeyCode = 0x7B
    private static let doCommand = NSSelectorFromString("doCommandBySelector:")

    /// 少一次 `AXIsProcessTrusted()` 调用（它每次都走一遍 TCC 判定）。
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// 上一次把光标挪回去用的哪条路：`client` / `event` / `none`。
    /// 设置面板据此决定要不要提示「去开辅助功能」——判定必须看输入法进程的权限，
    /// 而设置是另一个 App，自己查到的权限说明不了问题。
    static let stateKey = ShapingBridge.caretStateKey

    /// 这个输入框能不能把光标退回去。能在插入括号之前先问清楚。
    static func canMoveLeft(_ client: any IMKTextInput) -> Bool {
        supportsDoCommand(client) || isTrusted
    }

    private static func supportsDoCommand(_ client: any IMKTextInput) -> Bool {
        (client as AnyObject).responds(to: doCommand)
    }

    /// - Returns: 光标是否真的挪了。
    @discardableResult
    static func moveLeft(_ count: Int = 1, client: (any IMKTextInput)? = nil) -> Bool {
        guard count > 0 else { return false }
        // 有权限时先用合成按键：这条路每个 App 都认，是确定能动的。没有权限才试
        // `doCommandBySelector:` —— 它不需要授权，但个别输入框收了不办事。
        if isTrusted, postLeftArrow(count) {
            note("event")
            return true
        }
        if let client, supportsDoCommand(client) {
            for _ in 0..<count {
                (client as AnyObject).perform(doCommand, with: #selector(NSResponder.moveLeft(_:)))
            }
            note("client")
            return true
        }
        note("none")
        return false
    }

    private static func postLeftArrow(_ count: Int) -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)
        for _ in 0..<count {
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: leftArrow, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: leftArrow, keyDown: false)
            else { return false }
            // 上一个组合键的修饰位可能还挂着，清掉再发，免得变成 ⌥← 跳词。
            down.flags = []
            up.flags = []
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
        return true
    }

    /// 只在结果变了时写一次偏好，避免每一笔都落到磁盘。
    private static func note(_ path: String) {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: stateKey) != path else { return }
        defaults.set(path, forKey: stateKey)
    }

    /// 让系统弹出「授权辅助功能」的提示。
    ///
    /// 必须由输入法进程自己调用：TCC 按进程记权限，设置面板替它要没用。
    /// 设置面板发一条分布式通知过来，这里收到再弹。
    static func requestAccessibility() {
        guard !isTrusted else { return }
        // 这里用字面量而不是 `kAXTrustedCheckOptionPrompt`：那是全局 var，
        // Swift 6 的严格并发不允许在 MainActor 之外直接引用。
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 设置面板请求输入法要权限用的通知名。
    static let requestNotification = ShapingBridge.requestAccessibility

    /// 打开「系统设置 › 隐私与安全性 › 辅助功能」，让用户授权。
    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
