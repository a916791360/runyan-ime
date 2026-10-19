import AppKit
import Foundation

// 生成应用内的品牌方块（侧栏、引导页、关于页的标识）：
// 品牌砖红圆角方块 + 白色「润」。
//
// 字形按**墨迹包围盒**居中，而不是按字体度量居中 —— 汉字带左右边距，
// 直接按 font bounding box 摆会明显偏左下。
//
// 用法：swift make-brand-mark.swift <输出.png>

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("用法: swift make-brand-mark.swift <输出.png>\n".data(using: .utf8)!)
    exit(1)
}

let outputPath = args[1]
let side = 1024
let brandRed = NSColor(srgbRed: 182.0 / 255.0, green: 64.0 / 255.0, blue: 50.0 / 255.0, alpha: 1)

_ = NSApplication.shared

func makeBitmap() -> NSBitmapImageRep? {
    NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )
}

let glyph = "润" as NSString
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: CGFloat(side) * 0.66, weight: .bold),
    .foregroundColor: NSColor.white,
]
let glyphSize = glyph.size(withAttributes: attributes)

// 第一遍：把字画在同样大小的空白位图上，量墨迹范围
guard let scratch = makeBitmap() else { exit(1) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: scratch)
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: side, height: side).fill()
let origin = NSPoint(x: (CGFloat(side) - glyphSize.width) / 2, y: (CGFloat(side) - glyphSize.height) / 2)
glyph.draw(at: origin, withAttributes: attributes)
NSGraphicsContext.restoreGraphicsState()

var minX = side, maxX = 0, minY = side, maxY = 0
for y in 0..<side {
    for x in 0..<side {
        if (scratch.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.35 {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
    }
}

let inkCenter = NSPoint(x: CGFloat(minX + maxX) / 2, y: CGFloat(minY + maxY) / 2)
let drift = NSPoint(x: CGFloat(side) / 2 - inkCenter.x, y: CGFloat(side) / 2 - inkCenter.y)

guard let bitmap = makeBitmap() else { exit(1) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: side, height: side).fill()

// macOS 应用图标的圆角约等于边长的 22.5%
let rect = NSRect(x: 0, y: 0, width: side, height: side)
brandRed.setFill()
NSBezierPath(roundedRect: rect, xRadius: CGFloat(side) * 0.225, yRadius: CGFloat(side) * 0.225).fill()

glyph.draw(at: NSPoint(x: origin.x + drift.x, y: origin.y + drift.y), withAttributes: attributes)
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("PNG 编码失败\n".data(using: .utf8)!)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("已生成品牌方块 \(side)×\(side)，墨迹居中偏移 (\(Int(drift.x)), \(Int(drift.y)))：\(outputPath)")
