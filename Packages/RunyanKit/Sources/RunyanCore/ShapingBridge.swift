public import Foundation

/// 设置面板与输入法进程之间关于「文本整形」的两条约定。
///
/// 两边是两个独立的 App：权限判定必须在输入法进程里做（TCC 按进程记），
/// 设置只负责把结果读出来显示。跨进程可用的轻量通道只有分布式通知 + 共用偏好域，
/// 名字写在这里，免得两边各写一份字符串对不上。
public enum ShapingBridge {
    /// 输入法上一次把光标退回去用的哪条路：`client` / `event` / `none`。
    public static let caretStateKey = "RunyanCaretMove"

    /// 设置请求输入法弹「辅助功能」授权提示。
    public static let requestAccessibility = Notification.Name("app.runyan.ime.requestAccessibility")

    /// 设置读输入法偏好的域（输入法的 bundle id）。两个 App 都没有沙箱，读得到。
    public static let imeDefaultsSuite = "app.runyan.inputmethod.zh"
}
