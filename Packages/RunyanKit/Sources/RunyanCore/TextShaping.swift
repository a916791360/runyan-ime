public import Foundation

/// 中英混排与成对符号的文本整形。
///
/// 纯函数：只根据「这一笔要提交的文本」和「光标左右各一个字符」算出该插入什么，
/// 不碰输入框，也不决定光标怎么挪（那是输入法外壳的事）。
///
/// 两条规则：
///   1. 中文和英文挨在一起时补一个空格 —— 只在两边语言不同、且原本没有空白时补。
///   2. 打出左括号时补上右括号，光标停在中间。
///
/// 规则都在提交这一侧做，而不是改写 RIME 的方案配置：方案里的 punctuator 只能给出
/// 一个字符串，看不到光标前后是什么，也就没法判断该不该补空格。
public enum TextShaping {
    public struct Result: Equatable, Sendable {
        /// 实际要插入的文本：可能比提交的多一个空格，或者补上了右括号。
        public var text: String
        /// 插入后光标需要左移的字符数（UTF-16 位）。自动补括号时为 1。
        public var caretBack: Int

        public init(text: String, caretBack: Int = 0) {
            self.text = text
            self.caretBack = caretBack
        }
    }

    /// 会触发自动补全的左括号 → 右括号。
    public static let pairs: [Character: Character] = [
        "（": "）", "(": ")",
        "【": "】", "[": "]",
        "「": "」", "『": "』",
        "《": "》", "〈": "〉",
        "“": "”", "‘": "’",
    ]

    /// - Parameters:
    ///   - previous: 光标左边紧挨着的那个字符；文档开头为 nil。
    ///   - next: 光标右边紧挨着的那个字符；行尾为 nil。
    ///   - allowPair: 外壳能不能把光标移回去。没有辅助功能权限时传 false，
    ///     此时不补括号——补了却把光标留在右括号后面，比不补还难用。
    public static func shape(
        commit: String,
        previous: Character?,
        next: Character?,
        spaceBetweenCJKAndLatin: Bool,
        autoPair: Bool,
        allowPair: Bool = true
    ) -> Result {
        guard !commit.isEmpty else { return Result(text: commit) }

        if autoPair, allowPair, commit.count == 1, let open = commit.first,
           let close = pairs[open], next != close {
            return Result(text: String(open) + String(close), caretBack: 1)
        }

        guard spaceBetweenCJKAndLatin else { return Result(text: commit) }

        // 两个边界各自判断：前一个字和这一笔的开头、这一笔的结尾和后一个字。
        // 只要一边是拉丁字母/数字、另一边是中文，就补一个空格。
        var text = commit
        if let first = text.first, let previous, needsSpace(previous, first) {
            text = " " + text
        }
        if let last = text.last, let next, needsSpace(last, next) {
            text += " "
        }
        return Result(text: text)
    }

    /// 相邻两个字符之间该不该插空格：一个是拉丁，另一个是中文。
    /// 空格、标点、emoji 都不算，所以不会出现「空格前面再加一个空格」。
    static func needsSpace(_ left: Character, _ right: Character) -> Bool {
        (isLatin(left) && isWide(right)) || (isWide(left) && isLatin(right))
    }

    /// ASCII 字母与数字。全角字符不算——它们本来就属于中文排版。
    static func isLatin(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }

    /// 汉字、假名、谚文，以及它们常用的全角标点。
    static func isWide(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x3000...0x303F,     // 中文标点
             0x3040...0x30FF,     // 假名
             0x3400...0x4DBF,     // 汉字扩展 A
             0x4E00...0x9FFF,     // 汉字基本区
             0xAC00...0xD7AF,     // 谚文
             0xF900...0xFAFF,     // 兼容汉字
             0xFF00...0xFF60,     // 全角 ASCII / 标点
             0xFFE0...0xFFE6:
            return true
        default:
            return false
        }
    }
}
