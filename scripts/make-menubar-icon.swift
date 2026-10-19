import AppKit
import Foundation

// 生成输入法图标位图。两种模式：
//
//   boxed（默认）—— 深灰圆角方块 + 白色字形。
//     用于输入法菜单（下拉列表）里那一栏，和搜狗 / 百度那种 1:1 方块图标一致。
//     系统在下拉列表里按原色渲染，方块和字都能看见。
//
//   glyph —— 只有字形，底色全透明。
//     专供菜单栏（tsInputMethodIconFileKey）。菜单栏图标会被系统当模板图处理：
//     只取 alpha，再按菜单栏明暗染成白或黑。所以这一版**不能画底**——
//     一旦有实心方块，方块就会整块被染白，字反而糊在里头，看着像「白底 + 透出来的壁纸」。
//
// 尺寸规则（macOS 菜单栏）：1x 用 22×16，2x 用 44×32，系统自动挑。
//
// 用法：swift make-menubar-icon.swift <输出.png> <宽> <高> [boxed|glyph]

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("用法: swift make-menubar-icon.swift <输出.png> <宽> <高> [boxed|glyph]\n".data(using: .utf8)!)
    exit(1)
}

let outputPath = args[1]
let width = Int(args[2]) ?? 22
let height = Int(args[3]) ?? 16
let mode = args.count >= 5 ? args[4] : "boxed"

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
