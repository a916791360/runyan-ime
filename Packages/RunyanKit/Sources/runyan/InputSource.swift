import Carbon
import Foundation
import RimeKit

enum RunyanIdentity {
    static let bundleID = "app.runyan.inputmethod.zh"
    static let inputModeID = "app.runyan.inputmethod.zh.hans"
    static var installedApp: URL {
        let user = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Input Methods/Runyan.app")
        let system = URL(fileURLWithPath: "/Library/Input Methods/Runyan.app")
        return FileManager.default.fileExists(atPath: user.path) || !FileManager.default.fileExists(atPath: system.path) ? user : system
    }
}

/// Text Input Sources registration (what System Settings › Keyboard › Input Sources lists).
enum InputSourceRegistrar {
    static func sources(includeAll: Bool = true) -> [TISInputSource] {
        let filter = [kTISPropertyBundleID as String: RunyanIdentity.bundleID] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, includeAll)?.takeRetainedValue() as? [TISInputSource] else { return [] }
        return list
    }

    static func property(_ source: TISInputSource, _ key: CFString) -> Any? {
        guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue()
    }

    static func status() -> String {
        let all = sources()
        guard !all.isEmpty else { return "not registered (run `runyan register`)" }
        func enabled(_ id: String) -> Bool? {
            all.first { property($0, kTISPropertyInputSourceID) as? String == id }
                .map { (property($0, kTISPropertyInputSourceIsEnabled) as? Bool) == true }
        }
        guard enabled(RunyanIdentity.inputModeID) == true else {
            return "registered (enable it in System Settings › Keyboard › Input Sources)"
        }
        // The mode alone reports enabled right after a first install; macOS lists and selects
        // Runyan only once its input method is enabled too, which takes a log out (#8).
        return enabled(RunyanIdentity.bundleID) == false
            ? "registered, pending (log out and back in once so macOS lists Runyan)" : "registered, enabled"
    }

    @discardableResult
    static func register(appURL: URL) -> OSStatus {
        TISRegisterInputSource(appURL as CFURL)
    }

    static func enable() -> Bool {
        var ok = false
        for source in sources() {
            let id = property(source, kTISPropertyInputSourceID) as? String
            if id == RunyanIdentity.inputModeID || id == RunyanIdentity.bundleID {
                ok = TISEnableInputSource(source) == noErr || ok
            }
        }
        return ok
    }
}

enum PluginLocator {
    @MainActor static func plugins() -> [String] { RimeEngine.shared.availablePlugins }
}
