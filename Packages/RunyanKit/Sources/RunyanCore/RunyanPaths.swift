public import Foundation

/// Well-known locations. Everything Runyan writes lives under `userDataDir`; the
/// Squirrel directory is only ever read.
public struct RunyanPaths: Sendable, Equatable {
    public var userDataDir: URL
    public var logDir: URL
    /// Read-only shipped data (Runyan.app/Contents/SharedSupport). Needed to compose the
    /// `runyan/defaults` layer; nil in contexts that only touch user layers.
    public var sharedDataDir: URL?

    public init(userDataDir: URL, logDir: URL? = nil, sharedDataDir: URL? = nil) {
        self.userDataDir = userDataDir
        self.logDir = logDir ?? userDataDir.appendingPathComponent("logs", isDirectory: true)
        self.sharedDataDir = sharedDataDir
    }

    /// `~/Library/Runyan/Rime`, overridable with `RUNYAN_USER_DIR` for tests and scripting.
    public static var standard: RunyanPaths {
        let env = ProcessInfo.processInfo.environment
        if let override = env["RUNYAN_USER_DIR"], !override.isEmpty {
            return RunyanPaths(userDataDir: URL(fileURLWithPath: (override as NSString).expandingTildeInPath, isDirectory: true))
        }
        let library = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
        return RunyanPaths(
            userDataDir: library.appendingPathComponent("Runyan/Rime", isDirectory: true),
            logDir: library.appendingPathComponent("Logs/Runyan", isDirectory: true)
        )
    }

    /// The Squirrel (鼠须管) user directory, used as an import source only.
    public static var squirrelUserDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Rime", isDirectory: true)
    }

    public var stagingDir: URL { userDataDir.appendingPathComponent("build", isDirectory: true) }
    public var runyanDir: URL { userDataDir.appendingPathComponent("runyan", isDirectory: true) }
    public var importedDir: URL { runyanDir.appendingPathComponent("imported", isDirectory: true) }
    public var generatedDir: URL { runyanDir.appendingPathComponent("generated", isDirectory: true) }
    public var packagesDir: URL { runyanDir.appendingPathComponent("packages", isDirectory: true) }
    public var cacheDir: URL { runyanDir.appendingPathComponent("cache", isDirectory: true) }
    public var customPhraseFile: URL { userDataDir.appendingPathComponent("custom_phrase.txt") }

    public func builtConfig(_ configID: String) -> URL {
        stagingDir.appendingPathComponent("\(configID).yaml")
    }
}

/// Rime's own file-name convention for the configs Runyan manages.
public enum ConfigTarget: Sendable, Hashable, CustomStringConvertible {
    /// `default.yaml`
    case `default`
    /// `<id>.schema.yaml`
    case schema(String)
    /// `runyan.yaml` — the frontend config; same keys as Squirrel's `squirrel.yaml`.
    case frontend

    /// Config id as used by `config_open` / the `build/` directory.
    public var configID: String {
        switch self {
        case .default: "default"
        case let .schema(id): "\(id).schema"
        case .frontend: "runyan"
        }
    }

    /// Base name of the `*.custom.yaml` patch file Rime auto-applies.
    public var customName: String {
        switch self {
        case .default: "default"
        case let .schema(id): id
        case .frontend: "runyan"
        }
    }

    public var description: String { configID }

    public init?(file: String, schemaID: String?) {
        switch file {
        case "default": self = .default
        case "frontend", "runyan", "squirrel": self = .frontend
        case "schema":
            guard let schemaID else { return nil }
            self = .schema(schemaID)
        default: return nil
        }
    }
}
