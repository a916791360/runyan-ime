import AppKit
import Foundation

// 生成输入法图标位图。三种模式：
//
//   template（默认）—— 实心圆角方块，字形是**挖空**的（alpha 0），黑色作为遮罩。
//     系统按模板图渲染：菜单栏（深色）染成白方块、字透出壁纸；下拉列表（浅色）
//     染成黑方块、字是浅色。就是搜狗 / 百度那种一摸一样的效果，
//     两份界面共用同一张图，不用各存一张。
//
//   boxed —— 深灰圆角方块 + 白色字形，按原色渲染。给「不认模板」的场合兜底。
//
//   glyph —— 只有字形，底色全透明。系统会整块染白，字就没了，一般不要用。
//
// 尺寸规则：搜狗的菜单图标是 16×16 pt 的矢量 PDF。这里给 16×16 的位图，
// 1x/2x 各一张（16 / 32 px）——画布等于方块，系统缩放到槽位时不会因为留白显得小。
//
// 用法：swift make-menubar-icon.swift <输出.png> <宽> <高> [template|boxed|glyph]

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("用法: swift make-menubar-icon.swift <输出.png> <宽> <高> [boxed|glyph]\n".data(using: .utf8)!)
    exit(1)
}

let outputPath = args[1]
let width = Int(args[2]) ?? 16
let height = Int(args[3]) ?? 16
let mode = args.count >= 5 ? args[4] : "template"

_ = NSApplication.shared

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write("无法创建位图\n".data(using: .utf8)!)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

// 正方形区域：高度撑满、水平居中
let square = CGFloat(height)
let rect = NSRect(x: (CGFloat(width) - square) / 2, y: 0, width: square, height: square)

let glyph = "润" as NSString

switch mode {
case "template":
    // 方块铺满画布（留 0.5pt 给抗锯齿），圆弧占 28%——搜狗那个方块量出来就是这个比例。
    let inset: CGFloat = 0.5
    let plate = rect.insetBy(dx: inset, dy: inset)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: plate, xRadius: plate.width * 0.28, yRadius: plate.width * 0.28).fill()

    // 字形挖空：只扣 alpha，颜色留给系统染。
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square * 0.66, weight: .bold),
        .foregroundColor: NSColor.black,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    NSGraphicsContext.current?.compositingOperation = .destinationOut
    glyph.draw(
        at: NSPoint(
            x: rect.midX - glyphSize.width / 2,
            y: rect.midY - glyphSize.height / 2
        ),
        withAttributes: attributes
    )
    NSGraphicsContext.current?.compositingOperation = .sourceOver

case "glyph":
    // 只有字形。黑色是给「亮色菜单栏」用的；暗色菜单栏系统会自动染白。
    // 字号略小于方块，留一点呼吸，避免和高分屏抗锯齿打架。
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square * 0.9, weight: .semibold),
        .foregroundColor: NSColor.black,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(
            x: rect.midX - glyphSize.width / 2,
            y: rect.midY - glyphSize.height / 2
        ),
        withAttributes: attributes
    )
default:
    NSColor.black.setFill()
    NSBezierPath(
        roundedRect: rect,
        xRadius: square * 0.22,
        yRadius: square * 0.22
    ).fill()

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square * 0.74, weight: .bold),
        .foregroundColor: NSColor.white,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(
            x: rect.midX - glyphSize.width / 2,
            y: rect.midY - glyphSize.height / 2
        ),
        withAttributes: attributes
    )
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("PNG 编码失败\n".data(using: .utf8)!)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("已生成 \(width)×\(height) [\(mode)]：\(outputPath)")
