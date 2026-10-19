import AppKit
import ApplicationServices

/// 把光标往左挪几格。
///
/// `IMKTextInput` 只能读选区（`selectedRange()`），**没有**设置选区的方法，
/// 所以补完右括号后没法直接告诉输入框「光标退一格」。通行做法是补发一个左方向键事件，
/// 搜狗、百度这些输入法补全括号时也是这么干的。
///
/// 合成事件需要「辅助功能」权限，没有权限时系统会静默丢弃（不报错、也不动）。
/// 所以调用前先问 `isTrusted`，没权限就别补括号——补了却把光标留在右括号后面更难受。
enum CaretMover {
    /// 左方向键的虚拟键码。
    private static let leftArrow: CGKeyCode = 0x7B

    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// - Returns: 事件是否真的发出去了。
    @discardableResult
    static func moveLeft(_ count: Int = 1) -> Bool {
        guard count > 0, isTrusted else { return false }
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

    /// 打开「系统设置 › 隐私与安全性 › 辅助功能」，让用户授权。
    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
