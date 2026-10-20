import AppKit
import InputMethodKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var server: IMKServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        InputEngine.shared.start()
        // 设置面板没法替输入法要「辅助功能」权限（TCC 按进程记），只能由这里弹提示。
        DistributedNotificationCenter.default().addObserver(
            forName: CaretMover.requestNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in CaretMover.requestAccessibility() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        RimeKitShutdown.finalize()
    }
}

import RimeKit

enum RimeKitShutdown {
    @MainActor static func finalize() {
        RimeEngine.shared.cleanupAllSessions()
        RimeEngine.shared.finalize()
    }
}
