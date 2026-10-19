import Foundation
import Testing
@testable import RunyanCore

@Suite struct TextShapingTests {
    @Test func spacesOnlyWhereTheTwoScriptsMeet() {
        // 中文后面打英文：前面补一个
        #expect(TextShaping.shape(commit: "hello", previous: "我", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == " hello")
        // 英文后面打中文：前面也补一个
        #expect(TextShaping.shape(commit: "你好", previous: "o", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == " 你好")
        // 这一笔结尾是英文、后面接中文：补在后面
        #expect(TextShaping.shape(commit: "OK", previous: "好", next: "吗",
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == " OK ")
        // 同类之间不加：中文接中文、英文接英文
        #expect(TextShaping.shape(commit: "世界", previous: "好", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "世界")
        #expect(TextShaping.shape(commit: "world", previous: "o", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "world")
    }

    @Test func neverDoublesAnExistingSpace() {
        #expect(TextShaping.shape(commit: "hello", previous: " ", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "hello")
        #expect(TextShaping.shape(commit: " hello", previous: "我", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == " hello")
    }

    @Test func punctuationAndEmojiDoNotTriggerSpaces() {
        #expect(TextShaping.shape(commit: "。", previous: "好", next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "。")
        #expect(TextShaping.shape(commit: "🙂", previous: "好", next: "吗",
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "🙂")
    }

    @Test func documentEdgesAddNothing() {
        #expect(TextShaping.shape(commit: "hello", previous: nil, next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "hello")
        #expect(TextShaping.shape(commit: "你好", previous: nil, next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "你好")
    }

    @Test func pairsEveryOpeningBracketAndMovesTheCaretBack() {
        for (open, close) in TextShaping.pairs {
            let result = TextShaping.shape(commit: String(open), previous: nil, next: nil,
                                           spaceBetweenCJKAndLatin: true, autoPair: true)
            #expect(result.text == String(open) + String(close), "\(open)")
            #expect(result.caretBack == 1, "\(open)")
        }
    }

    @Test func pairsOnlyAnOpeningBracketOnItsOwn() {
        // 不是单个字符不补
        #expect(TextShaping.shape(commit: "（）", previous: nil, next: nil,
                                  spaceBetweenCJKAndLatin: false, autoPair: true).caretBack == 0)
        // 右括号不补
        #expect(TextShaping.shape(commit: "）", previous: nil, next: nil,
                                  spaceBetweenCJKAndLatin: false, autoPair: true).caretBack == 0)
        // 右括号已经在后面了，就别再补一个
        #expect(TextShaping.shape(commit: "（", previous: nil, next: "）",
                                  spaceBetweenCJKAndLatin: false, autoPair: true).text == "（")
    }

    @Test func pairingRespectsTheSwitches() {
        #expect(TextShaping.shape(commit: "（", previous: nil, next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: false).text == "（")
        // 没有辅助功能权限时外壳传 allowPair: false —— 宁可只打左括号，也不要光标留在外面
        #expect(TextShaping.shape(commit: "（", previous: nil, next: nil,
                                  spaceBetweenCJKAndLatin: true, autoPair: true, allowPair: false).text == "（")
    }

    @Test func spacingCanBeTurnedOff() {
        #expect(TextShaping.shape(commit: "hello", previous: "我", next: nil,
                                  spaceBetweenCJKAndLatin: false, autoPair: false).text == "hello")
    }

    @Test func scriptDetectionCoversTheCommonRanges() {
        #expect(TextShaping.isLatin("a") && TextShaping.isLatin("Z") && TextShaping.isLatin("7"))
        #expect(!TextShaping.isLatin("你") && !TextShaping.isLatin("，") && !TextShaping.isLatin("あ"))
        #expect(TextShaping.isWide("你") && TextShaping.isWide("，") && TextShaping.isWide("あ"))
        #expect(!TextShaping.isWide("a") && !TextShaping.isWide(" "))
    }
}
