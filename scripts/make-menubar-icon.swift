import AppKit
import Foundation

// 生成菜单栏输入法图标：固定黑底白字，不参与系统主题反色。
//
// 和 template 的区别：
//   · template（文件名带 Template）只保留 alpha，系统按菜单栏明暗反色 ——
//     在部分机器上会反成「白底 + 透出壁纸色」，很难看
//   · 这里输出彩色位图，颜色固定，和搜狗/百度那种 1:1 黑底图标一致
//
// 尺寸规则（macOS 菜单栏）：
//   1x: 22×16 px，方块 16×16 水平居中
//   2x: 44×32 px，方块 32×32 水平居中
// 两个文件都提供，系统在高分屏自动选 @2x。
//
// 用法：swift make-menubar-icon.swift <输出.png> <宽> <高>

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("用法: swift make-menubar-icon.swift <输出.png> <宽> <高>\n".data(using: .utf8)!)
    exit(1)
}

let outputPath = args[1]
let width = Int(args[2]) ?? 22
let height = Int(args[3]) ?? 16

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

// 正方形黑底，高度撑满、水平居中
let square = CGFloat(height)
let rect = NSRect(x: (CGFloat(width) - square) / 2, y: 0, width: square, height: square)

NSColor.black.setFill()
NSBezierPath(
    roundedRect: rect,
    xRadius: square * 0.22,
    yRadius: square * 0.22
).fill()

let glyph = "润" as NSString
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

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("PNG 编码失败\n".data(using: .utf8)!)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("已生成 \(width)×\(height)：\(outputPath)")
